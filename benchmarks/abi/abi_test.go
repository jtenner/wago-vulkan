//go:build abi_benchmark

package abi

import (
	"context"
	"fmt"
	wago "github.com/wago-org/wago"
	"math"
	"os"
	"path/filepath"
	"testing"
)

var kinds = []string{"packed32", "packed64", "structs_bulk", "structs_fields", "structs_batch"}
var phases = []string{"bridge", "update", "rebuild", "construct"}
var sizes = []int{100, 1000, 10000, 100000}

func fixture(tb testing.TB, kind string, n int) (*wago.Instance, *bridge) {
	tb.Helper()
	guest := kind
	if kind == "structs_bulk" || kind == "structs_fields" || kind == "structs_batch" {
		guest = "structs"
	}
	data, err := os.ReadFile(filepath.Join("generated", guest+".wasm"))
	if err != nil {
		tb.Fatal("run generate.py first:", err)
	}
	b := newBridge(kind, n)
	tb.Cleanup(b.close)
	rt := wago.NewRuntime(wago.WithRuntimeConfig(wago.NewRuntimeConfig().WithCoreFeatures(wago.CoreFeaturesV3)))
	tb.Cleanup(func() { rt.Close() })
	definition := wago.PluginDefinition{
		ID: "github.com/jtenner/wago-vulkan/benchmarks/abi", Name: "ABI benchmark", Version: "0.1.0", Description: "Benchmark-only GC ABI", Stability: wago.Experimental,
		Provenance:  wago.PluginProvenance{Repository: "https://github.com/jtenner/wago-vulkan", License: "UNLICENSED"},
		Authorities: []wago.AuthorityRequest{{Name: wago.AuthorityHostImportDefine, Mode: wago.AuthorityRequired, Reason: "Benchmark GC host calls", Scope: wago.AuthorityScope{Modules: []string{"abi"}}}},
	}
	digest, err := wago.DefinitionDigest(definition)
	if err != nil {
		tb.Fatal(err)
	}
	set := wago.PluginSet{
		Providers: []wago.PluginProvider{{Definition: definition, New: func() wago.Plugin { return b }}},
		Selections: []wago.PluginSelection{{ID: definition.ID, DefinitionDigest: digest, Direct: true, Dependencies: map[string]string{},
			Grants: []wago.AuthorityGrant{{Name: wago.AuthorityHostImportDefine, Scope: wago.AuthorityScope{Modules: []string{"abi"}}}}}},
	}
	if err := rt.LoadPlugins(context.Background(), set); err != nil {
		tb.Fatal(err)
	}
	mod, err := rt.Compile(data)
	if err != nil {
		tb.Fatal(err)
	}
	tb.Cleanup(func() { mod.Close() })
	inst, err := rt.Instantiate(context.Background(), mod)
	if err != nil {
		tb.Fatal(err)
	}
	tb.Cleanup(func() { inst.Close() })
	if _, err := inst.Invoke("init", wago.I32(int32(n))); err != nil {
		tb.Fatal(err)
	}
	return inst, b
}

func checksum(n int, seed uint32) uint64 {
	var sum uint64
	for i := 0; i < n; i++ {
		values := [...]float32{float32(i), 2, 640 + float32(seed), 480, 0, 1}
		for j, value := range values {
			sum += uint64(math.Float32bits(value)) * uint64(j+1)
		}
	}
	return sum
}

func TestEquivalentABIs(t *testing.T) {
	for _, n := range sizes {
		for _, kind := range kinds {
			t.Run(fmt.Sprintf("%s/%d", kind, n), func(t *testing.T) {
				inst, bridge := fixture(t, kind, n)
				// Verify every field, preservation of i64 word's other half,
				// repeated object construction and collection-safe roots.
				for _, phase := range phases {
					for i := 0; i < 3; i++ {
						out, err := inst.Invoke(phase)
						if err != nil {
							t.Fatal(err)
						}
						tick, err := inst.Invoke("tick")
						if err != nil {
							t.Fatal(err)
						}
						want := checksum(n, uint32(tick[0]))
						if len(out) != 0 || bridge.last != want {
							t.Fatalf("%s: got %d, want %d", phase, bridge.last, want)
						}
					}
					if err := inst.CollectGC(); err != nil {
						t.Fatal(err)
					}
					if _, err := inst.Invoke("bridge"); err != nil {
						t.Fatal(err)
					}
					tick, err := inst.Invoke("tick")
					if err != nil {
						t.Fatal(err)
					}
					if bridge.last != checksum(n, uint32(tick[0])) {
						t.Fatal("checksum after collection")
					}
				}
				if n == 100 {
					for i := 0; i < 1025; i++ {
						if _, err := inst.Invoke("update_only"); err != nil {
							t.Fatal(err)
						}
					}
					if _, err := inst.Invoke("bridge"); err != nil {
						t.Fatal(err)
					}
					tick, err := inst.Invoke("tick")
					if err != nil {
						t.Fatal(err)
					}
					if bridge.last != checksum(n, uint32(tick[0])) {
						t.Fatal("checksum after seed wrap")
					}
				}
			})
		}
	}
}

func BenchmarkABI(b *testing.B) {
	for _, phase := range phases {
		for _, n := range sizes {
			for _, kind := range kinds {
				b.Run(fmt.Sprintf("%s/%d/%s", phase, n, kind), func(b *testing.B) {
					inst, bridge := fixture(b, kind, n)
					fn, err := inst.WasmFunc(phase)
					if err != nil {
						b.Fatal(err)
					}
					// Warm the host boundary, guest code and native scratch.
					for i := 0; i < 8; i++ {
						if _, err := fn.Invoke(); err != nil {
							b.Fatal(err)
						}
					}
					b.ReportAllocs()
					b.SetBytes(int64(n * 24))
					b.ResetTimer()
					for i := 0; i < b.N; i++ {
						_, err := fn.Invoke()
						if err != nil {
							b.Fatal(err)
						}
					}
					b.StopTimer()
					tick, err := inst.Invoke("tick")
					if err != nil || bridge.last != checksum(n, uint32(tick[0])) {
						b.Fatal("benchmark checksum mismatch", err)
					}
					b.ReportMetric(float64(b.Elapsed().Nanoseconds())/float64(b.N*n), "ns/item")
				})
			}
		}
	}
}

// Isolate guest writes from native marshalling. The final untimed submission
// verifies that all writes are observable and produce the same native data.
func BenchmarkGuestWrites(b *testing.B) {
	for _, phase := range []string{"update_only", "rebuild_only"} {
		for _, n := range sizes {
			for _, kind := range []string{"packed32", "packed64", "structs_bulk"} {
				b.Run(fmt.Sprintf("%s/%d/%s", phase, n, kind), func(b *testing.B) {
					inst, bridge := fixture(b, kind, n)
					fn, err := inst.WasmFunc(phase)
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
					b.StopTimer()
					if _, err := inst.Invoke("bridge"); err != nil {
						b.Fatal(err)
					}
					tick, err := inst.Invoke("tick")
					if err != nil {
						b.Fatal(err)
					}
					if bridge.last != checksum(n, uint32(tick[0])) {
						b.Fatal("guest write checksum mismatch")
					}
					b.ReportMetric(float64(b.Elapsed().Nanoseconds())/float64(b.N*n), "ns/item")
				})
			}
		}
	}
}
