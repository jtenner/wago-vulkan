// Package vulkan exposes thin, generated Vulkan imports to Wago guests.
//
// The three modules are vulkan.gc (mutable packed i32 arrays), vulkan.wasm32
// (32-bit guest pointers), and vulkan.wasm64 (64-bit guest pointers). This is a
// trusted native FFI: callers own Vulkan valid usage, handles and lifetimes.
package vulkan

/*
#cgo pkg-config: vulkan
#cgo linux pkg-config: x11
#cgo CFLAGS: -std=c11 -O3
#include "bridge.h"
*/
import "C"

import (
	"context"
	"fmt"
	"runtime"
	"sync"
	"unsafe"

	wago "github.com/wago-org/wago"
)

const (
	ModuleGC            = "vulkan.gc"
	ModuleWasm32        = "vulkan.wasm32"
	ModuleWasm64        = "vulkan.wasm64"
	PluginID            = "github.com/jtenner/wago-vulkan"
	ABIVersion          = 1
	DefaultScratchLimit = 32 << 20
	voidResult          = wago.ValType(255)
)

// Options selects the linear memory and bounds retained native conversion
// scratch per simultaneous pointer-bearing call. Zero ScratchLimit selects
// DefaultScratchLimit. Scalar-only imports do not acquire this scratch.
type Options struct {
	MemoryIndex  uint32
	ScratchLimit uint64
}

type command struct {
	name                 string
	arity                int
	pointers, allocators uint16
	result               wago.ValType
	signatures           [3][]wago.ValType
	direct               func(wago.HostCall)
}

type callState struct {
	native   *C.wv_context
	next     *callState
	options  Options
	callback func(wago.GuestStorage) error
	slots    []uint64
	id, mode int
	transfer bool
	read     bool
	pinner   runtime.Pinner
}

// Plugin owns a reusable pool of call frames. Concurrent calls use distinct
// frames; Runtime shutdown frees their native memory through the Stop hook.
type Plugin struct {
	options Options
	mu      sync.Mutex
	free    *callState
	closed  bool
}

func New(options Options) *Plugin {
	if options.ScratchLimit == 0 {
		options.ScratchLimit = DefaultScratchLimit
	}
	return &Plugin{options: options}
}

// Provider returns an explicitly linked Wago plugin provider. Options are
// immutable per activated plugin; no benchmark runtime overlay is required.
func Provider(options ...Options) wago.PluginProvider {
	var opts Options
	if len(options) > 1 {
		panic("vulkan.Provider accepts at most one Options")
	}
	if len(options) == 1 {
		opts = options[0]
	}
	definition := wago.PluginDefinition{
		ID: PluginID, Name: "Vulkan", Version: "0.1.1", Description: "Packed GC, Wasm32 and Wasm64 Vulkan FFI", Stability: wago.Experimental,
		Compatibility: wago.Compatibility{Platforms: []string{"linux/amd64", "linux/arm64", "darwin/amd64", "darwin/arm64"}},
		Provenance:    wago.PluginProvenance{Repository: "https://github.com/jtenner/wago-vulkan", License: "MIT", Authors: []string{"jtenner"}},
		Authorities: []wago.AuthorityRequest{{Name: wago.AuthorityHostImportDefine, Mode: wago.AuthorityRequired,
			Reason: "Define native Vulkan imports", Scope: wago.AuthorityScope{Modules: []string{ModuleGC, ModuleWasm32, ModuleWasm64}}}},
	}
	return wago.PluginProvider{Definition: definition, New: func() wago.Plugin { return New(opts) }}
}

// PluginSet selects this provider and grants precisely its declared authority.
// Hosts can instead compose Provider into their own reviewed plugin set.
func PluginSet(options ...Options) wago.PluginSet {
	p := Provider(options...)
	digest, err := wago.DefinitionDigest(p.Definition)
	if err != nil {
		panic(err)
	}
	r := p.Definition.Authorities[0]
	return wago.PluginSet{Providers: []wago.PluginProvider{p}, Selections: []wago.PluginSelection{{
		ID: p.Definition.ID, DefinitionDigest: digest, Direct: true, Dependencies: map[string]string{},
		Grants: []wago.AuthorityGrant{{Name: r.Name, Scope: r.Scope}},
	}}}
}

func (p *Plugin) Register(reg *wago.Registrar) error {
	if p.options.ScratchLimit < 4096 || p.options.ScratchLimit > uint64(^uint(0)>>1) {
		return fmt.Errorf("invalid Vulkan scratch limit")
	}
	imports, err := reg.HostImports()
	if err != nil {
		return err
	}
	for mode, module := range []string{ModuleGC, ModuleWasm32, ModuleWasm64} {
		for id := range commands {
			cmd := &commands[id]
			var fn any = cmd.direct
			if cmd.direct == nil {
				commandID, transport := id, mode
				fn = func(caller wago.Caller, call wago.HostCall) { p.invoke(commandID, transport, caller, call) }
			}
			binding := imports.HostFunc(module, cmd.name, fn).Params(cmd.signatures[mode]...)
			if cmd.result != voidResult {
				binding.Results(cmd.result)
			}
		}
		imports.HostFunc(module, "abiVersion", func(call wago.HostCall) { call.SetI32(0, ABIVersion) }).Results(wago.ValI32)
		transport := mode
		params := []wago.ValType{wago.ValI64, wago.ValAnyRef, wago.ValI32, wago.ValI32}
		if mode == 1 {
			params = []wago.ValType{wago.ValI64, wago.ValI32, wago.ValI32}
		}
		if mode == 2 {
			params = []wago.ValType{wago.ValI64, wago.ValI64, wago.ValI64}
		}
		imports.HostFunc(module, "writeMapped", func(caller wago.Caller, call wago.HostCall) { p.transfer(transport, false, caller, call) }).Params(params...)
		imports.HostFunc(module, "readMapped", func(caller wago.Caller, call wago.HostCall) { p.transfer(transport, true, caller, call) }).Params(params...)
	}
	return reg.Lifecycle(wago.PluginLifecycle{Stop: func(context.Context) error { return p.Close() }})
}

func (p *Plugin) take() (*callState, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.closed {
		return nil, fmt.Errorf("Vulkan plugin is closed")
	}
	if p.free != nil {
		s := p.free
		p.free = s.next
		s.next = nil
		return s, nil
	}
	native := C.wv_new(C.size_t(p.options.ScratchLimit))
	if native == nil {
		return nil, fmt.Errorf("cannot allocate Vulkan call frame")
	}
	s := &callState{native: native, options: p.options}
	// Allocate the storage callback once per pooled frame, not once per call.
	s.callback = s.withStorage
	return s, nil
}
func (p *Plugin) release(s *callState) {
	s.slots = nil
	s.id, s.mode = 0, 0
	s.transfer, s.read = false, false
	p.mu.Lock()
	defer p.mu.Unlock()
	if p.closed {
		C.wv_free(s.native)
		s.native = nil
		return
	}
	s.next = p.free
	p.free = s
}

// Close releases idle native frames and arranges release of any active frame
// after its callback returns. Guests remain responsible for Vulkan resources.
func (p *Plugin) Close() error {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.closed = true
	for p.free != nil {
		s := p.free
		p.free = s.next
		C.wv_free(s.native)
		s.native = nil
	}
	return nil
}

func trap(err error) { panic(wago.HostTrap{Err: err}) }

func bridgeError(command string, code C.int) error {
	detail := "unknown error"
	switch code {
	case C.WV_RANGE:
		detail = "guest buffer range or unterminated string"
	case C.WV_NOMEM:
		detail = "native scratch limit or allocation failure"
	case C.WV_UNSUPPORTED:
		detail = "unsupported pNext type or allocator callbacks"
	case C.WV_CYCLE:
		detail = "cyclic pointer graph or nesting limit"
	case C.WV_WIDTH:
		detail = "native output exceeds guest field width"
	}
	return fmt.Errorf("%s: bridge error %d (%s)", command, code, detail)
}

func borrow(caller wago.Caller, fn func(wago.GuestStorage) error) error {
	return caller.WithGuestStorage(fn)
}

// packed always requests a mutable i32 view. This prevents hidden copies of
// immutable arrays, and provides direct output writeback when required.
func packed(s wago.GuestStorage, token uint64) ([]byte, error) {
	ref, err := s.GCRef(token)
	if err != nil {
		return nil, err
	}
	b, info, err := s.GCArrayBytes(ref, wago.GuestStorageWrite)
	if err != nil {
		return nil, err
	}
	if info.Storage != wago.GuestGCArrayI32 {
		return nil, fmt.Errorf("Vulkan GC buffers must be mutable packed i32 arrays")
	}
	return b, nil
}

func (state *callState) memory(s wago.GuestStorage) ([]byte, error) {
	info, err := s.MemoryInfo(state.options.MemoryIndex)
	if err != nil {
		return nil, err
	}
	want := wago.GuestMemory32
	if state.mode == 2 {
		want = wago.GuestMemory64
	}
	if info.AddressType != want {
		return nil, fmt.Errorf("Vulkan namespace requires %d-bit linear memory", want)
	}
	return s.MemoryRange(state.options.MemoryIndex, 0, info.ByteLength, wago.GuestStorageWrite)
}

func (p *Plugin) invoke(id, mode int, caller wago.Caller, call wago.HostCall) {
	cmd := &commands[id]
	state, err := p.take()
	if err != nil {
		trap(err)
	}
	defer p.release(state)
	c := state.native
	C.wv_reset(c)
	slots := call.ParamSlots()
	// Lower direct values and null allocators without a storage borrow.
	for i, slot := 0, 0; i < cmd.arity; i++ {
		pointer := (cmd.pointers|cmd.allocators)&(1<<i) != 0
		value := slots[slot]
		if cmd.signatures[mode][slot] == wago.ValI32 {
			value = uint64(uint32(value))
		}
		if mode == 0 && pointer {
			if cmd.allocators&(1<<i) != 0 && value != 0 {
				trap(fmt.Errorf("guest Vulkan allocator callbacks are unsupported"))
			}
			if value == 0 && uint32(slots[slot+1]) != 0 {
				trap(fmt.Errorf("null Vulkan buffer has a nonzero offset"))
			}
			value = uint64(uint32(slots[slot+1]))
			slot += 2
		} else {
			if mode == 1 && pointer {
				value = uint64(uint32(value))
			}
			slot++
		}
		c.input[i] = C.uint64_t(value)
		c.args[i] = C.uint64_t(value)
	}
	if cmd.pointers == 0 {
		if code := C.wv_invoke(c, C.int(id)); code != C.WV_OK {
			trap(bridgeError(cmd.name, code))
		}
	} else {
		state.id, state.mode, state.slots = id, mode, slots
		err = borrow(caller, state.callback)
		if err != nil {
			trap(err)
		}
	}
	if cmd.result == wago.ValI32 {
		call.SetI32(0, int32(c.result))
	}
	if cmd.result == wago.ValI64 {
		call.SetI64(0, int64(c.result))
	}
}

func (state *callState) withStorage(s wago.GuestStorage) (err error) {
	if state.transfer {
		return state.transferStorage(s)
	}
	c := state.native
	// The storage lease prevents Wago relocation; explicit pinning also keeps
	// Go-backed buffers legal to store in C memory. Clear C pointers before
	// unpinning on validation failure or panic as well as ordinary completion.
	nativeFinished := false
	defer func() {
		if !nativeFinished {
			C.wv_abort(c)
		}
		state.pinner.Unpin()
	}()
	cmd := &commands[state.id]
	var memory []byte
	if state.mode != 0 {
		var err error
		memory, err = state.memory(s)
		if err != nil {
			return err
		}
	}
	for i, slot := 0, 0; i < cmd.arity; i++ {
		pointer := (cmd.pointers|cmd.allocators)&(1<<i) != 0
		if cmd.pointers&(1<<i) != 0 {
			var b []byte
			present, width := false, 64
			if state.mode == 0 {
				if state.slots[slot] != 0 {
					var err error
					b, err = packed(s, state.slots[slot])
					if err != nil {
						return err
					}
					present = true
				}
			} else {
				b, present = memory, c.input[i] != 0
				if state.mode == 1 {
					width = 32
				}
			}
			var base *C.uint8_t
			if len(b) != 0 {
				data := unsafe.SliceData(b)
				state.pinner.Pin(data)
				base = (*C.uint8_t)(unsafe.Pointer(data))
			}
			c.buffers[i].base = base
			c.buffers[i].bytes = C.uint64_t(len(b))
			c.buffers[i].width = C.uint8_t(width)
			if present {
				c.buffers[i].present = 1
			}
		}
		if state.mode == 0 && pointer {
			slot += 2
		} else {
			slot++
		}
	}
	code := C.wv_invoke(c, C.int(state.id))
	nativeFinished = true // wv_invoke clears C guest addresses on every exit.
	if code != C.WV_OK {
		return bridgeError(cmd.name, code)
	}
	return nil
}

func (p *Plugin) transfer(mode int, read bool, caller wago.Caller, call wago.HostCall) {
	state, err := p.take()
	if err != nil {
		trap(err)
	}
	defer p.release(state)
	state.mode, state.slots, state.transfer, state.read = mode, call.ParamSlots(), true, read
	if err := borrow(caller, state.callback); err != nil {
		trap(err)
	}
}

func (state *callState) transferStorage(s wago.GuestStorage) error {
	mode, slots := state.mode, state.slots
	var b []byte
	var off, length uint64
	if mode == 0 {
		var e error
		b, e = packed(s, slots[1])
		if e != nil {
			return e
		}
		off = uint64(uint32(slots[2]))
		length = uint64(uint32(slots[3]))
	} else {
		var e error
		b, e = state.memory(s)
		if e != nil {
			return e
		}
		if mode == 1 {
			off = uint64(uint32(slots[1]))
			length = uint64(uint32(slots[2]))
		} else {
			off = slots[1]
			length = slots[2]
		}
	}
	if off > uint64(len(b)) || length > uint64(len(b))-off {
		return fmt.Errorf("mapped Vulkan transfer exceeds guest buffer")
	}
	if length == 0 {
		return nil
	}
	address := slots[0]
	if address == 0 || length > ^uint64(0)-address {
		return fmt.Errorf("invalid mapped Vulkan address")
	}
	state.pinner.Pin(unsafe.SliceData(b))
	defer state.pinner.Unpin()
	guest := uint64(uintptr(unsafe.Pointer(unsafe.SliceData(b[off:]))))
	if state.read {
		C.wv_copy(C.uint64_t(guest), C.uint64_t(address), C.size_t(length))
	} else {
		C.wv_copy(C.uint64_t(address), C.uint64_t(guest), C.size_t(length))
	}
	return nil
}
