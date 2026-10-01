//go:build integration

package vulkan

import (
	"testing"
)

func TestVulkanRoundTrip(t *testing.T) {
	for _, mode := range []string{"gc", "wasm32", "wasm64"} {
		t.Run(mode, func(t *testing.T) {
			inst, p := fixture(t, mode, Options{})
			// A real negative VkResult must cross the GC and pointer import ABIs.
			if got := int32(invoke(t, inst, "badExtension")[0]); got != -7 {
				t.Fatalf("VkResult: got %d, want VK_ERROR_EXTENSION_NOT_PRESENT (-7)", got)
			}
			initialize(t, inst)
			queue := invoke(t, inst, "query")[0]
			if queue == 0 {
				t.Fatal("null queue handle")
			}
			if got := invoke(t, inst, "properties")[0]; got < 1<<22 {
				t.Fatalf("invalid Vulkan API version %#x", got)
			}
			if got := invoke(t, inst, "idle")[0]; got != 0 {
				t.Fatalf("vkDeviceWaitIdle: %d", got)
			}
			if got := invoke(t, inst, "fenceStatus")[0]; got != 1 {
				t.Fatalf("scalar VkResult: got %d, want VK_NOT_READY (1)", got)
			}
			if got := invoke(t, inst, "mapped")[0]; got != 1 {
				t.Fatal("mapped memory transfer corrupted data")
			}
			expectTrap(t, inst, "badRange", "bridge error 1")
			expectTrap(t, inst, "badAllocator", "unsupported")
			if mode == "gc" {
				expectTrap(t, inst, "badArray", "packed i32")
				expectTrap(t, inst, "immutableArray", "immutable")
				expectTrap(t, inst, "nullOffset", "nonzero offset")
				if err := inst.CollectGC(); err != nil {
					t.Fatal(err)
				}
			}
			retained := uint64(p.free.native.retained)
			for i := 0; i < 100; i++ {
				if got := invoke(t, inst, "query")[0]; got != queue {
					t.Fatal("queue changed after trap/collection")
				}
				if uint64(p.free.native.retained) != retained {
					t.Fatal("native scratch grew after warmup")
				}
				for _, b := range p.free.native.buffers {
					if b.base != nil {
						t.Fatal("guest pointer retained after borrow")
					}
				}
			}
		})
	}
}

func TestSelectedMemory(t *testing.T) {
	inst, _ := fixture(t, "wasm32", Options{MemoryIndex: 1})
	expectTrap(t, inst, "badExtension", "memory")
}

// Measures the implemented imports with the actual Vulkan driver. Warm native
// scratch and reusable guest storage; no benchmark runtime overlay involved.
func BenchmarkVulkan(b *testing.B) {
	for _, mode := range []string{"gc", "wasm32", "wasm64"} {
		for _, operation := range []string{"query", "idle"} {
			b.Run(mode+"/"+operation, func(b *testing.B) {
				inst, _ := fixture(b, mode, Options{})
				initialize(b, inst)
				fn, err := inst.WasmFunc(operation)
				if err != nil {
					b.Fatal(err)
				}
				for i := 0; i < 8; i++ {
					if _, err := fn.Invoke(); err != nil {
						b.Fatal(err)
					}
				}
				b.ReportAllocs()
				b.ResetTimer()
				for i := 0; i < b.N; i++ {
					if _, err := fn.Invoke(); err != nil {
						b.Fatal(err)
					}
				}
			})
		}
	}
}
