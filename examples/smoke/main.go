// This test harness builds Wasm32 structures from the checked-in public ABI
// catalogue. Every GPU call below crosses the guest import and plugin bridge.
package main

import (
	"context"
	_ "embed"
	"encoding/binary"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"math"
	"os"
	"runtime"
	"strings"

	vulkan "github.com/jtenner/wago-vulkan"
	wago "github.com/wago-org/wago"
)

//go:embed guest.wasm
var guest []byte

//go:embed compute.spv
var shader []byte

//go:embed layouts.json
var layoutData []byte

type layout struct {
	Size   uint32            `json:"size"`
	Fields map[string]uint32 `json:"fields"`
}
type smoke struct {
	inst                                       *wago.Instance
	layouts                                    map[string]layout
	next                                       uint64
	device, physical, instance, queue, surface uint64
	family                                     uint64
	validation                                 bool
	cleanup                                    []func()
}

func (s *smoke) alloc(n uint32) uint64 {
	p := (s.next + 7) &^ 7
	s.next = p + uint64(n)
	if s.next > 16<<20 {
		panic(errors.New("smoke arena exhausted"))
	}
	if !s.inst.Write(uint32(p), make([]byte, n)) {
		panic(errors.New("guest memory write failed"))
	}
	return p
}
func (s *smoke) bytes(b []byte) uint64 {
	p := s.alloc(uint32(len(b)))
	if !s.inst.Write(uint32(p), b) {
		panic(errors.New("guest write failed"))
	}
	return p
}
func (s *smoke) text(t string) uint64 { return s.bytes(append([]byte(t), 0)) }
func (s *smoke) u32(p, v uint64) {
	if !s.inst.WriteUint32Le(uint32(p), uint32(v)) {
		panic(errors.New("guest word write failed"))
	}
}
func (s *smoke) u64(p, v uint64) {
	if !s.inst.WriteUint64Le(uint32(p), v) {
		panic(errors.New("guest handle write failed"))
	}
}
func (s *smoke) r32(p uint64) uint64 {
	v, ok := s.inst.ReadUint32Le(uint32(p))
	if !ok {
		panic(errors.New("guest word read failed"))
	}
	return uint64(v)
}
func (s *smoke) r64(p uint64) uint64 {
	v, ok := s.inst.ReadUint64Le(uint32(p))
	if !ok {
		panic(errors.New("guest handle read failed"))
	}
	return v
}
func (s *smoke) field(t string, p uint64, name string) uint64 {
	l, ok := s.layouts[t]
	if !ok {
		panic(fmt.Errorf("unknown ABI type %s", t))
	}
	off, ok := l.Fields[name]
	if !ok {
		panic(fmt.Errorf("unknown ABI field %s.%s", t, name))
	}
	return p + uint64(off)
}
func (s *smoke) set(t string, p uint64, name string, v uint64)  { s.u32(s.field(t, p, name), v) }
func (s *smoke) wide(t string, p uint64, name string, v uint64) { s.u64(s.field(t, p, name), v) }
func (s *smoke) structure(t string, stype uint64) uint64 {
	l, ok := s.layouts[t]
	if !ok {
		panic(fmt.Errorf("unknown ABI type %s", t))
	}
	p := s.alloc(l.Size)
	if stype != math.MaxUint64 {
		s.set(t, p, "sType", stype)
	}
	return p
}
func (s *smoke) call(name string, args ...uint64) uint64 {
	result, err := s.inst.Invoke(name, args...)
	if err != nil {
		panic(fmt.Errorf("%s: %w", name, err))
	}
	if len(result) == 0 {
		return 0
	}
	return result[0]
}
func (s *smoke) ok(name string, args ...uint64) {
	if r := int32(s.call(name, args...)); r != 0 {
		panic(fmt.Errorf("%s: VkResult %d", name, r))
	}
}
func (s *smoke) addCleanup(fn func()) { s.cleanup = append(s.cleanup, fn) }
func (s *smoke) close() (err error) {
	// The script's process timeout also covers a stuck native driver during idle
	// or teardown; fences and acquisitions in the happy path use 5s timeouts.
	attempt := func(fn func()) {
		defer func() {
			if r := recover(); r != nil {
				err = errors.Join(err, fmt.Errorf("teardown: %v", r))
			}
		}()
		fn()
	}
	if s.device != 0 {
		attempt(func() { s.ok("vkDeviceWaitIdle", s.device) })
	}
	for i := len(s.cleanup) - 1; i >= 0; i-- {
		attempt(s.cleanup[i])
	}
	if s.validation && debugErrors() != 0 {
		err = errors.Join(err, fmt.Errorf("%d validation errors", debugErrors()))
	}
	return err
}
func (s *smoke) list(count, stride uint32, enumerate func(uint64, uint64)) (uint64, uint64) {
	n := s.alloc(4)
	enumerate(n, 0)
	c := s.r32(n)
	if c > uint64(count) {
		panic(fmt.Errorf("enumeration count %d exceeds smoke bound %d", c, count))
	}
	if c == 0 {
		return 0, 0
	}
	p := s.alloc(uint32(c) * stride)
	enumerate(n, p)
	return p, s.r32(n)
}
func (s *smoke) extensions(device uint64) map[string]bool {
	p, n := s.list(512, 260, func(c, p uint64) {
		if device == 0 {
			s.ok("vkEnumerateInstanceExtensionProperties", 0, c, p)
		} else {
			s.ok("vkEnumerateDeviceExtensionProperties", device, 0, c, p)
		}
	})
	result := map[string]bool{}
	for i := uint64(0); i < n; i++ {
		b, ok := s.inst.Read(uint32(p+i*260), 256)
		if !ok {
			panic(errors.New("extension read failed"))
		}
		result[strings.TrimRight(string(b), "\x00")] = true
	}
	return result
}
func (s *smoke) names(names []string) uint64 {
	if len(names) == 0 {
		return 0
	}
	p := s.alloc(uint32(len(names)) * 4)
	for i, name := range names {
		s.u32(p+uint64(i*4), s.text(name))
	}
	return p
}
func require(extensions map[string]bool, name string) {
	if !extensions[name] {
		panic(fmt.Errorf("required extension %s is unavailable", name))
	}
}
func (s *smoke) initialize(layer uint64, allowSoftware bool) {
	exts := s.extensions(0)
	names := []string{}
	ci := s.structure("VkInstanceCreateInfo", 1)
	if exts["VK_KHR_portability_enumeration"] {
		names = append(names, "VK_KHR_portability_enumeration")
		s.set("VkInstanceCreateInfo", ci, "flags", 1)
	}
	if exts["VK_KHR_get_physical_device_properties2"] {
		names = append(names, "VK_KHR_get_physical_device_properties2")
	}
	if layer != 0 {
		for _, name := range []string{"VK_KHR_surface", "VK_EXT_metal_surface"} {
			require(exts, name)
			names = append(names, name)
		}
	}
	layers, n := s.list(128, 520, func(c, p uint64) { s.ok("vkEnumerateInstanceLayerProperties", c, p) })
	for i := uint64(0); i < n; i++ {
		b, _ := s.inst.Read(uint32(layers+i*520), 256)
		if strings.TrimRight(string(b), "\x00") == "VK_LAYER_KHRONOS_validation" {
			s.validation = exts["VK_EXT_debug_utils"]
		}
	}
	if s.validation {
		names = append(names, "VK_EXT_debug_utils")
		s.set("VkInstanceCreateInfo", ci, "enabledLayerCount", 1)
		s.set("VkInstanceCreateInfo", ci, "ppEnabledLayerNames", s.names([]string{"VK_LAYER_KHRONOS_validation"}))
	} else {
		fmt.Println("SKIP: validation layer/debug utils unavailable (GPU checks still run; validation unverified)")
	}
	s.set("VkInstanceCreateInfo", ci, "enabledExtensionCount", uint64(len(names)))
	s.set("VkInstanceCreateInfo", ci, "ppEnabledExtensionNames", s.names(names))
	app := s.structure("VkApplicationInfo", 0)
	s.set("VkApplicationInfo", app, "apiVersion", 1<<22)
	s.set("VkInstanceCreateInfo", ci, "pApplicationInfo", app)
	out := s.alloc(8)
	s.ok("vkCreateInstance", ci, 0, out)
	s.instance = s.r64(out)
	s.addCleanup(func() { s.call("vkDestroyInstance", s.instance, 0) })
	if s.validation {
		if r := debugStart(s.instance); r != 0 {
			panic(fmt.Errorf("validation messenger: VkResult %d", r))
		}
		s.addCleanup(func() { debugStop(s.instance) })
		fmt.Println("INFO: VK_LAYER_KHRONOS_validation enabled")
	}
	if layer != 0 {
		ci := s.structure("VkMetalSurfaceCreateInfoEXT", 1000217000)
		// External host pointers are 64 bits even in the Wasm32 catalogue.
		s.wide("VkMetalSurfaceCreateInfoEXT", ci, "pLayer", layer)
		s.ok("vkCreateMetalSurfaceEXT", s.instance, ci, 0, out)
		s.surface = s.r64(out)
		s.addCleanup(func() { s.call("vkDestroySurfaceKHR", s.instance, s.surface, 0) })
		fmt.Println("PASS: guest vkCreateMetalSurfaceEXT with host-owned CAMetalLayer")
	}
	devices, n := s.list(16, 8, func(c, p uint64) { s.ok("vkEnumeratePhysicalDevices", s.instance, c, p) })
	if n == 0 {
		panic(errors.New("no Vulkan device; check MoltenVK ICD, Metal support, and matching loader architecture"))
	}
	for d := uint64(0); d < n && s.physical == 0; d++ {
		physical := s.r64(devices + d*8)
		properties := s.structure("VkPhysicalDeviceProperties", math.MaxUint64)
		s.call("vkGetPhysicalDeviceProperties", physical, properties)
		kind := s.r32(s.field("VkPhysicalDeviceProperties", properties, "deviceType"))
		if !allowSoftware && kind != 1 && kind != 2 {
			continue
		} // integrated/discrete hardware only
		families, count := s.list(64, 24, func(c, p uint64) { s.call("vkGetPhysicalDeviceQueueFamilyProperties", physical, c, p) })
		for f := uint64(0); f < count; f++ {
			if s.r32(families+f*24)&3 != 3 || s.r32(families+f*24+4) == 0 {
				continue
			}
			if s.surface != 0 {
				s.ok("vkGetPhysicalDeviceSurfaceSupportKHR", physical, f, s.surface, out)
				if s.r32(out) == 0 {
					continue
				}
			}
			s.physical = physical
			s.family = f
			b, _ := s.inst.Read(uint32(s.field("VkPhysicalDeviceProperties", properties, "deviceName")), 256)
			fmt.Printf("INFO: GPU=%q type=%d vendor=%#x device=%#x Vulkan=%#x driver=%#x queue-family=%d\n", strings.TrimRight(string(b), "\x00"), kind, s.r32(properties+8), s.r32(properties+12), s.r32(properties), s.r32(properties+4), f)
			break
		}
	}
	if s.physical == 0 {
		panic(errors.New("no hardware GPU with graphics+compute+present queue (software devices are not accepted on Mac)"))
	}
	dexts := s.extensions(s.physical)
	names = nil
	if dexts["VK_KHR_portability_subset"] {
		names = append(names, "VK_KHR_portability_subset")
	}
	if s.surface != 0 {
		require(dexts, "VK_KHR_swapchain")
		names = append(names, "VK_KHR_swapchain")
	}
	qi := s.structure("VkDeviceQueueCreateInfo", 2)
	s.set("VkDeviceQueueCreateInfo", qi, "queueFamilyIndex", s.family)
	s.set("VkDeviceQueueCreateInfo", qi, "queueCount", 1)
	priority := s.alloc(4)
	s.u32(priority, uint64(math.Float32bits(1)))
	s.set("VkDeviceQueueCreateInfo", qi, "pQueuePriorities", priority)
	di := s.structure("VkDeviceCreateInfo", 3)
	s.set("VkDeviceCreateInfo", di, "queueCreateInfoCount", 1)
	s.set("VkDeviceCreateInfo", di, "pQueueCreateInfos", qi)
	s.set("VkDeviceCreateInfo", di, "enabledExtensionCount", uint64(len(names)))
	s.set("VkDeviceCreateInfo", di, "ppEnabledExtensionNames", s.names(names))
	s.ok("vkCreateDevice", s.physical, di, 0, out)
	s.device = s.r64(out)
	s.addCleanup(func() { s.call("vkDestroyDevice", s.device, 0) })
	s.call("vkGetDeviceQueue", s.device, s.family, 0, out)
	s.queue = s.r64(out)
	if s.queue == 0 {
		panic(errors.New("null queue"))
	}
}
func (s *smoke) create(name, destroy string, ci uint64) uint64 {
	out := s.alloc(8)
	s.ok(name, s.device, ci, 0, out)
	h := s.r64(out)
	if h == 0 {
		panic(fmt.Errorf("%s returned null handle", name))
	}
	s.addCleanup(func() { s.call(destroy, s.device, h, 0) })
	return h
}
func (s *smoke) command() (uint64, uint64) {
	ci := s.structure("VkCommandPoolCreateInfo", 39)
	s.set("VkCommandPoolCreateInfo", ci, "flags", 2)
	s.set("VkCommandPoolCreateInfo", ci, "queueFamilyIndex", s.family)
	pool := s.create("vkCreateCommandPool", "vkDestroyCommandPool", ci)
	ai := s.structure("VkCommandBufferAllocateInfo", 40)
	s.wide("VkCommandBufferAllocateInfo", ai, "commandPool", pool)
	s.set("VkCommandBufferAllocateInfo", ai, "commandBufferCount", 1)
	out := s.alloc(8)
	s.ok("vkAllocateCommandBuffers", s.device, ai, out)
	cmd := s.r64(out)
	fence := s.create("vkCreateFence", "vkDestroyFence", s.structure("VkFenceCreateInfo", 8))
	return cmd, fence
}
func (s *smoke) begin(cmd uint64) {
	ci := s.structure("VkCommandBufferBeginInfo", 42)
	s.set("VkCommandBufferBeginInfo", ci, "flags", 1)
	s.ok("vkBeginCommandBuffer", cmd, ci)
}
func (s *smoke) submit(cmd, fence, wait, signal uint64) {
	s.ok("vkEndCommandBuffer", cmd)
	submit := s.structure("VkSubmitInfo", 4)
	commands := s.alloc(8)
	s.u64(commands, cmd)
	s.set("VkSubmitInfo", submit, "commandBufferCount", 1)
	s.set("VkSubmitInfo", submit, "pCommandBuffers", commands)
	if wait != 0 {
		p := s.alloc(8)
		s.u64(p, wait)
		stage := s.alloc(4)
		s.u32(stage, 0x1000)
		s.set("VkSubmitInfo", submit, "waitSemaphoreCount", 1)
		s.set("VkSubmitInfo", submit, "pWaitSemaphores", p)
		s.set("VkSubmitInfo", submit, "pWaitDstStageMask", stage)
	}
	if signal != 0 {
		p := s.alloc(8)
		s.u64(p, signal)
		s.set("VkSubmitInfo", submit, "signalSemaphoreCount", 1)
		s.set("VkSubmitInfo", submit, "pSignalSemaphores", p)
	}
	s.ok("vkQueueSubmit", s.queue, 1, submit, fence)
	fp := s.alloc(8)
	s.u64(fp, fence)
	s.ok("vkWaitForFences", s.device, 1, fp, 1, 5_000_000_000)
}
func (s *smoke) hostBuffer(byteCount, usage uint64) (buffer, address uint64, unmap func()) {
	ci := s.structure("VkBufferCreateInfo", 12)
	s.wide("VkBufferCreateInfo", ci, "size", byteCount)
	s.set("VkBufferCreateInfo", ci, "usage", usage)
	out := s.alloc(8)
	s.ok("vkCreateBuffer", s.device, ci, 0, out)
	buffer = s.r64(out)
	var allocation uint64
	var mapped bool
	s.addCleanup(func() {
		if mapped {
			s.call("vkUnmapMemory", s.device, allocation)
		}
		s.call("vkDestroyBuffer", s.device, buffer, 0)
		if allocation != 0 {
			s.call("vkFreeMemory", s.device, allocation, 0)
		}
	})
	req := s.structure("VkMemoryRequirements", math.MaxUint64)
	s.call("vkGetBufferMemoryRequirements", s.device, buffer, req)
	props := s.structure("VkPhysicalDeviceMemoryProperties", math.MaxUint64)
	s.call("vkGetPhysicalDeviceMemoryProperties", s.physical, props)
	count := s.r32(props)
	if count > 32 {
		panic(errors.New("invalid memory type count"))
	}
	kind := uint64(32)
	for i := uint64(0); i < count; i++ {
		if s.r32(req+16)&(1<<i) != 0 && s.r32(props+4+i*8)&6 == 6 {
			kind = i
			break
		}
	}
	if kind == 32 {
		panic(errors.New("no compatible HOST_VISIBLE|HOST_COHERENT storage-buffer memory"))
	}
	ai := s.structure("VkMemoryAllocateInfo", 5)
	s.wide("VkMemoryAllocateInfo", ai, "allocationSize", s.r64(req))
	s.set("VkMemoryAllocateInfo", ai, "memoryTypeIndex", kind)
	s.ok("vkAllocateMemory", s.device, ai, 0, out)
	allocation = s.r64(out)
	s.ok("vkBindBufferMemory", s.device, buffer, allocation, 0)
	s.ok("vkMapMemory", s.device, allocation, 0, byteCount, 0, out)
	mapped = true
	address = s.r64(out)
	unmap = func() {
		if mapped {
			s.call("vkUnmapMemory", s.device, allocation)
			mapped = false
		}
	}
	return
}
func (s *smoke) compute() {
	buffer, address, unmap := s.hostBuffer(256, 0x20)
	out := s.alloc(8)
	input := make([]byte, 256)
	for i := 0; i < 64; i++ {
		binary.LittleEndian.PutUint32(input[i*4:], uint32(i*i+11))
	}
	src := s.bytes(input)
	s.call("writeMapped", address, src, 256)
	binding := s.structure("VkDescriptorSetLayoutBinding", math.MaxUint64)
	s.set("VkDescriptorSetLayoutBinding", binding, "descriptorType", 7)
	s.set("VkDescriptorSetLayoutBinding", binding, "descriptorCount", 1)
	s.set("VkDescriptorSetLayoutBinding", binding, "stageFlags", 0x20)
	dl := s.structure("VkDescriptorSetLayoutCreateInfo", 32)
	s.set("VkDescriptorSetLayoutCreateInfo", dl, "bindingCount", 1)
	s.set("VkDescriptorSetLayoutCreateInfo", dl, "pBindings", binding)
	descriptorLayout := s.create("vkCreateDescriptorSetLayout", "vkDestroyDescriptorSetLayout", dl)
	layouts := s.alloc(8)
	s.u64(layouts, descriptorLayout)
	pl := s.structure("VkPipelineLayoutCreateInfo", 30)
	s.set("VkPipelineLayoutCreateInfo", pl, "setLayoutCount", 1)
	s.set("VkPipelineLayoutCreateInfo", pl, "pSetLayouts", layouts)
	pipelineLayout := s.create("vkCreatePipelineLayout", "vkDestroyPipelineLayout", pl)
	size := s.structure("VkDescriptorPoolSize", math.MaxUint64)
	s.set("VkDescriptorPoolSize", size, "type", 7)
	s.set("VkDescriptorPoolSize", size, "descriptorCount", 1)
	dp := s.structure("VkDescriptorPoolCreateInfo", 33)
	s.set("VkDescriptorPoolCreateInfo", dp, "maxSets", 1)
	s.set("VkDescriptorPoolCreateInfo", dp, "poolSizeCount", 1)
	s.set("VkDescriptorPoolCreateInfo", dp, "pPoolSizes", size)
	pool := s.create("vkCreateDescriptorPool", "vkDestroyDescriptorPool", dp)
	da := s.structure("VkDescriptorSetAllocateInfo", 34)
	s.wide("VkDescriptorSetAllocateInfo", da, "descriptorPool", pool)
	s.set("VkDescriptorSetAllocateInfo", da, "descriptorSetCount", 1)
	s.set("VkDescriptorSetAllocateInfo", da, "pSetLayouts", layouts)
	s.ok("vkAllocateDescriptorSets", s.device, da, out)
	set := s.r64(out)
	bi := s.structure("VkDescriptorBufferInfo", math.MaxUint64)
	s.wide("VkDescriptorBufferInfo", bi, "buffer", buffer)
	s.wide("VkDescriptorBufferInfo", bi, "range", 256)
	write := s.structure("VkWriteDescriptorSet", 35)
	s.wide("VkWriteDescriptorSet", write, "dstSet", set)
	s.set("VkWriteDescriptorSet", write, "descriptorCount", 1)
	s.set("VkWriteDescriptorSet", write, "descriptorType", 7)
	s.set("VkWriteDescriptorSet", write, "pBufferInfo", bi)
	s.call("vkUpdateDescriptorSets", s.device, 1, write, 0, 0)
	sh := s.structure("VkShaderModuleCreateInfo", 16)
	s.set("VkShaderModuleCreateInfo", sh, "codeSize", uint64(len(shader)))
	s.set("VkShaderModuleCreateInfo", sh, "pCode", s.bytes(shader))
	module := s.create("vkCreateShaderModule", "vkDestroyShaderModule", sh)
	cp := s.structure("VkComputePipelineCreateInfo", 29)
	stage := s.field("VkComputePipelineCreateInfo", cp, "stage")
	s.set("VkPipelineShaderStageCreateInfo", stage, "sType", 18)
	s.set("VkPipelineShaderStageCreateInfo", stage, "stage", 0x20)
	s.wide("VkPipelineShaderStageCreateInfo", stage, "module", module)
	s.set("VkPipelineShaderStageCreateInfo", stage, "pName", s.text("main"))
	s.wide("VkComputePipelineCreateInfo", cp, "layout", pipelineLayout)
	s.set("VkComputePipelineCreateInfo", cp, "basePipelineIndex", math.MaxUint32)
	s.ok("vkCreateComputePipelines", s.device, 0, 1, cp, 0, out)
	pipeline := s.r64(out)
	s.addCleanup(func() { s.call("vkDestroyPipeline", s.device, pipeline, 0) })
	cmd, fence := s.command()
	s.begin(cmd)
	s.call("vkCmdBindPipeline", cmd, 1, pipeline)
	sets := s.alloc(8)
	s.u64(sets, set)
	s.call("vkCmdBindDescriptorSets", cmd, 1, pipelineLayout, 0, 1, sets, 0, 0)
	s.call("vkCmdDispatch", cmd, 1, 1, 1)
	barrier := s.structure("VkMemoryBarrier", 46)
	s.set("VkMemoryBarrier", barrier, "srcAccessMask", 0x40)
	s.set("VkMemoryBarrier", barrier, "dstAccessMask", 0x2000)
	s.call("vkCmdPipelineBarrier", cmd, 0x800, 0x4000, 0, 1, barrier, 0, 0, 0, 0)
	s.submit(cmd, fence, 0, 0)
	dst := s.alloc(256)
	s.call("readMapped", address, dst, 256)
	for i := 0; i < 64; i++ {
		want := uint64((i*i+11)*3 + 7)
		if got := s.r32(dst + uint64(i*4)); got != want {
			panic(fmt.Errorf("GPU compute value[%d]=%d, want %d", i, got, want))
		}
	}
	unmap()
	fmt.Println("PASS: guest GPU compute, all 64 storage-buffer values verified after fence + shader-to-host barrier")
}
func (s *smoke) present(green bool) {
	caps := s.structure("VkSurfaceCapabilitiesKHR", math.MaxUint64)
	s.ok("vkGetPhysicalDeviceSurfaceCapabilitiesKHR", s.physical, s.surface, caps)
	if s.r32(caps+48)&2 == 0 {
		panic(errors.New("surface does not support TRANSFER_DST clear"))
	}
	formats, n := s.list(128, 8, func(c, p uint64) { s.ok("vkGetPhysicalDeviceSurfaceFormatsKHR", s.physical, s.surface, c, p) })
	if n == 0 {
		panic(errors.New("surface has no formats"))
	}
	format, colorSpace := uint64(0), uint64(0)
	for i := uint64(0); i < n; i++ {
		f := s.r32(formats + i*8)
		if (f == 44 || f == 50 || (n == 1 && f == 0)) && s.r32(formats+i*8+4) == 0 {
			format = f
			if format == 0 {
				format = 44
			}
			break
		}
	}
	if format == 0 {
		panic(errors.New("surface has no BGRA8 UNORM/SRGB nonlinear format"))
	}
	// FIFO is guaranteed, but query advertised modes to catch driver problems.
	modes, m := s.list(32, 4, func(c, p uint64) { s.ok("vkGetPhysicalDeviceSurfacePresentModesKHR", s.physical, s.surface, c, p) })
	fifo := false
	for i := uint64(0); i < m; i++ {
		fifo = fifo || s.r32(modes+i*4) == 2
	}
	if !fifo {
		panic(errors.New("surface has no FIFO present mode"))
	}
	width, height := windowSize()
	w, h := uint64(width), uint64(height)
	if s.r32(caps+8) != math.MaxUint32 {
		w, h = s.r32(caps+8), s.r32(caps+12)
	} else {
		w = max(s.r32(caps+16), min(w, s.r32(caps+24)))
		h = max(s.r32(caps+20), min(h, s.r32(caps+28)))
	}
	if w == 0 || h == 0 || w > 1600 || h > 1000 {
		panic(errors.New("surface extent outside modest smoke bound (1..1600 x 1..1000)"))
	}
	count := s.r32(caps) + 1
	if maximum := s.r32(caps + 4); maximum != 0 && count > maximum {
		count = maximum
	}
	alpha := s.r32(caps + 44)
	alpha &= -alpha
	if alpha == 0 {
		panic(errors.New("surface has no composite alpha mode"))
	}
	ci := s.structure("VkSwapchainCreateInfoKHR", 1000001000)
	s.wide("VkSwapchainCreateInfoKHR", ci, "surface", s.surface)
	s.set("VkSwapchainCreateInfoKHR", ci, "minImageCount", count)
	s.set("VkSwapchainCreateInfoKHR", ci, "imageFormat", format)
	s.set("VkSwapchainCreateInfoKHR", ci, "imageColorSpace", colorSpace)
	extent := s.field("VkSwapchainCreateInfoKHR", ci, "imageExtent")
	s.u32(extent, w)
	s.u32(extent+4, h)
	s.set("VkSwapchainCreateInfoKHR", ci, "imageArrayLayers", 1)
	s.set("VkSwapchainCreateInfoKHR", ci, "imageUsage", 2)
	s.set("VkSwapchainCreateInfoKHR", ci, "preTransform", s.r32(caps+40))
	s.set("VkSwapchainCreateInfoKHR", ci, "compositeAlpha", alpha)
	s.set("VkSwapchainCreateInfoKHR", ci, "presentMode", 2)
	s.set("VkSwapchainCreateInfoKHR", ci, "clipped", 1)
	out := s.alloc(8)
	s.ok("vkCreateSwapchainKHR", s.device, ci, 0, out)
	swapchain := s.r64(out)
	// Destroy each swapchain before resize/recreation; only one is live on the
	// surface at a time. The deferred destruction also covers any failing call.
	destroyed := false
	s.addCleanup(func() {
		if !destroyed {
			s.call("vkDestroySwapchainKHR", s.device, swapchain, 0)
		}
	})
	images, imageCount := s.list(16, 8, func(c, p uint64) { s.ok("vkGetSwapchainImagesKHR", s.device, swapchain, c, p) })
	if imageCount == 0 {
		panic(errors.New("empty swapchain"))
	}
	acquired := s.create("vkCreateSemaphore", "vkDestroySemaphore", s.structure("VkSemaphoreCreateInfo", 9))
	rendered := s.create("vkCreateSemaphore", "vkDestroySemaphore", s.structure("VkSemaphoreCreateInfo", 9))
	index := s.alloc(4)
	r := int32(s.call("vkAcquireNextImageKHR", s.device, swapchain, 5_000_000_000, acquired, 0, index))
	if r != 0 && r != 1000001003 {
		panic(fmt.Errorf("vkAcquireNextImageKHR: VkResult %d", r))
	}
	if s.r32(index) >= imageCount {
		panic(errors.New("acquired image index outside swapchain"))
	}
	image := s.r64(images + s.r32(index)*8)
	cmd, fence := s.command()
	s.begin(cmd)
	barrier := s.structure("VkImageMemoryBarrier", 45)
	s.set("VkImageMemoryBarrier", barrier, "dstAccessMask", 0x1000)
	s.set("VkImageMemoryBarrier", barrier, "newLayout", 7)
	s.set("VkImageMemoryBarrier", barrier, "srcQueueFamilyIndex", math.MaxUint32)
	s.set("VkImageMemoryBarrier", barrier, "dstQueueFamilyIndex", math.MaxUint32)
	s.wide("VkImageMemoryBarrier", barrier, "image", image)
	subrange := s.field("VkImageMemoryBarrier", barrier, "subresourceRange")
	s.set("VkImageSubresourceRange", subrange, "aspectMask", 1)
	s.set("VkImageSubresourceRange", subrange, "levelCount", 1)
	s.set("VkImageSubresourceRange", subrange, "layerCount", 1)
	s.call("vkCmdPipelineBarrier", cmd, 1, 0x1000, 0, 0, 0, 0, 0, 1, barrier)
	pixels := thankYouBitmap(uint32(w), uint32(h), green)
	upload, address, unmap := s.hostBuffer(uint64(len(pixels)), 1)
	s.call("writeMapped", address, s.bytes(pixels), uint64(len(pixels)))
	unmap()
	copyRegion := s.structure("VkBufferImageCopy", math.MaxUint64)
	sub := s.field("VkBufferImageCopy", copyRegion, "imageSubresource")
	s.set("VkImageSubresourceLayers", sub, "aspectMask", 1)
	s.set("VkImageSubresourceLayers", sub, "layerCount", 1)
	copyExtent := s.field("VkBufferImageCopy", copyRegion, "imageExtent")
	s.u32(copyExtent, w)
	s.u32(copyExtent+4, h)
	s.u32(copyExtent+8, 1)
	s.call("vkCmdCopyBufferToImage", cmd, upload, image, 7, 1, copyRegion)
	s.set("VkImageMemoryBarrier", barrier, "srcAccessMask", 0x1000)
	s.set("VkImageMemoryBarrier", barrier, "dstAccessMask", 0)
	s.set("VkImageMemoryBarrier", barrier, "oldLayout", 7)
	s.set("VkImageMemoryBarrier", barrier, "newLayout", 1000001002)
	s.call("vkCmdPipelineBarrier", cmd, 0x1000, 0x2000, 0, 0, 0, 0, 0, 1, barrier)
	s.submit(cmd, fence, acquired, rendered)
	pi := s.structure("VkPresentInfoKHR", 1000001001)
	wait := s.alloc(8)
	s.u64(wait, rendered)
	sc := s.alloc(8)
	s.u64(sc, swapchain)
	s.set("VkPresentInfoKHR", pi, "waitSemaphoreCount", 1)
	s.set("VkPresentInfoKHR", pi, "pWaitSemaphores", wait)
	s.set("VkPresentInfoKHR", pi, "swapchainCount", 1)
	s.set("VkPresentInfoKHR", pi, "pSwapchains", sc)
	s.set("VkPresentInfoKHR", pi, "pImageIndices", index)
	r = int32(s.call("vkQueuePresentKHR", s.queue, pi))
	if r != 0 && r != 1000001003 {
		panic(fmt.Errorf("vkQueuePresentKHR: VkResult %d", r))
	}
	s.ok("vkQueueWaitIdle", s.queue)
	windowPump(2)
	s.call("vkDestroySwapchainKHR", s.device, swapchain, 0)
	destroyed = true
	fmt.Printf("PASS: guest swapchain bitmap upload + present (%dx%d, green=%t); visible pixels require human confirmation\n", w, h, green)
}
func run(headless, allowSoftware, requireValidation bool) (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = errors.Join(err, fmt.Errorf("%v", r))
		}
	}()
	if allowSoftware && runtime.GOOS == "darwin" {
		return errors.New("-allow-software is a Linux verification option only")
	}
	var layer uint64
	if !headless {
		if runtime.GOOS != "darwin" {
			return errors.New("visible smoke requires macOS; Linux verification uses -headless -allow-software")
		}
		defer windowClose()
		layer = windowOpen()
		if layer == 0 {
			return errors.New("cannot create AppKit/Metal window; run in a logged-in native Mac GUI session with a Metal GPU")
		}
		windowPump(0.1)
	}
	features := wago.SupportedFeatures() & wago.CoreFeaturesV3
	rt := wago.NewRuntime(wago.WithRuntimeConfig(wago.NewRuntimeConfig().WithCoreFeatures(features)))
	defer rt.Close()
	if err := rt.LoadPlugins(context.Background(), vulkan.PluginSet()); err != nil {
		return err
	}
	mod, err := rt.Compile(guest)
	if err != nil {
		return err
	}
	defer mod.Close()
	inst, err := rt.Instantiate(context.Background(), mod)
	if err != nil {
		return err
	}
	defer inst.Close()
	s := &smoke{inst: inst, next: 8}
	if err := json.Unmarshal(layoutData, &s.layouts); err != nil {
		return err
	}
	defer func() { err = errors.Join(err, s.close()) }()
	s.initialize(layer, allowSoftware)
	fmt.Printf("INFO: loaded-loader=%s\n", loadedLoader())
	if runtime.GOOS == "darwin" {
		fmt.Printf("INFO: loaded-moltenvk=%s\n", loadedMoltenVK())
	}
	if allowSoftware {
		fmt.Println("SKIP: hardware Metal GPU validation (Linux software-device verification enabled)")
	}
	s.compute()
	if !headless {
		s.present(false)
		if !windowResize() {
			return errors.New("AppKit resize failed")
		}
		s.present(true)
		fmt.Println("PASS: automated resize/recreate/present sequence; HUMAN: confirm thank you for testing! on blue, then on larger green window, then clean close")
	} else {
		fmt.Println("SKIP: visible Metal surface/presentation (-headless)")
	}
	if !s.validation && requireValidation {
		return errors.New("INCOMPLETE: GPU checks passed but validation layer/debug utils unavailable")
	}
	return nil
}
func main() {
	runtime.LockOSThread() // Lock the initial/main thread before touching AppKit.
	defer runtime.UnlockOSThread()
	headless := flag.Bool("headless", false, "compute only; skips surface/presentation")
	software := flag.Bool("allow-software", false, "Linux verification only: allow lavapipe")
	validation := flag.Bool("require-validation", true, "fail incomplete if validation is unavailable")
	flag.Parse()
	if flag.NArg() != 0 {
		fmt.Fprintln(os.Stderr, "unexpected arguments")
		os.Exit(1)
	}
	fmt.Printf("INFO: harness %s/%s, ABI=wasm32; SKIP: GC/wasm64 are outside this smoke\n", runtime.GOOS, runtime.GOARCH)
	if err := run(*headless, *software, *validation); err != nil {
		fmt.Fprintln(os.Stderr, "FAIL:", err)
		os.Exit(1)
	}
	fmt.Println("PASS: requested automated phases and orderly Vulkan teardown; human visual confirmation is separate")
}
