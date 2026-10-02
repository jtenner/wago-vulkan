package vulkan

import (
	"context"
	"embed"
	"runtime"
	"strings"
	"testing"

	wago "github.com/wago-org/wago"
)

// Fixtures are checked in so ordinary tests need no Wasm assembler.
//
//go:embed testdata/*.wasm
var guests embed.FS

func fixture(tb testing.TB, mode string, opts Options) (*wago.Instance, *Plugin) {
	tb.Helper()
	features := wago.SupportedFeatures() & wago.CoreFeaturesV3
	if runtime.GOOS == "darwin" && (mode == "gc" && !features.IsEnabled(wago.CoreFeatureGC) ||
		mode == "wasm64" && !features.IsEnabled(wago.CoreFeatureMemory64)) {
		tb.Skipf("pinned Wago does not support %s guests on %s/%s", mode, runtime.GOOS, runtime.GOARCH)
	}
	data, err := guests.ReadFile("testdata/" + mode + ".wasm")
	if err != nil {
		tb.Fatal(err)
	}
	p := New(opts)
	set := PluginSet(opts)
	set.Providers[0].New = func() wago.Plugin { return p }
	rt := wago.NewRuntime(wago.WithRuntimeConfig(wago.NewRuntimeConfig().WithCoreFeatures(features)))
	tb.Cleanup(func() {
		if err := rt.Close(); err != nil {
			tb.Error(err)
		}
	})
	if err := rt.LoadPlugins(context.Background(), set); err != nil {
		tb.Fatal(err)
	}
	mod, err := rt.Compile(data)
	if err != nil {
		tb.Fatal(err)
	}
	tb.Cleanup(func() { mod.Close() })
	if mode == "gc" && runtime.GOOS == "darwin" {
		if admission := mod.Compiled().GCNativeRootAdmission(); !admission.Exact {
			tb.Skipf("pinned Wago cannot admit this GC host-boundary fixture: %s", admission.Reason)
		}
	}
	inst, err := rt.Instantiate(context.Background(), mod)
	if err != nil {
		tb.Fatal(err)
	}
	tb.Cleanup(func() { inst.Close() })
	if _, err := inst.Invoke("prepare"); err != nil {
		tb.Fatal(err)
	}
	return inst, p
}

func invoke(tb testing.TB, inst *wago.Instance, name string) []uint64 {
	tb.Helper()
	result, err := inst.Invoke(name)
	if err != nil {
		tb.Fatalf("%s: %v", name, err)
	}
	return result
}

func initialize(tb testing.TB, inst *wago.Instance) {
	tb.Helper()
	// Runs against the installed Vulkan ICD, including software drivers.
	// Explicitly opt into these driver-dependent tests with the integration tag.
	tb.Cleanup(func() {
		if _, err := inst.Invoke("cleanup"); err != nil {
			tb.Error(err)
		}
	})
	if _, err := inst.Invoke("init"); err != nil {
		tb.Fatal(err)
	}
}

func TestSignaturesAndActivation(t *testing.T) {
	for _, mode := range []string{"gc", "wasm32", "wasm64"} {
		t.Run(mode, func(t *testing.T) {
			inst, p := fixture(t, mode, Options{})
			if got := invoke(t, inst, "version")[0]; got != ABIVersion {
				t.Fatalf("version %d", got)
			}
			if p.free != nil {
				t.Fatal("activation allocated a native call frame")
			}
		})
	}
}

func TestGuestExtensionMatching(t *testing.T) {
	// CPU-only checks of the guest's portability-extension discovery helper:
	// empty list, prefix mismatch, match after a nonmatch, and absent name.
	for _, mode := range []string{"gc", "wasm32", "wasm64"} {
		t.Run(mode, func(t *testing.T) {
			inst, _ := fixture(t, mode, Options{})
			if got := invoke(t, inst, "extensionMatching")[0]; got != 1 {
				t.Fatalf("extension matching: got %d, want 1", got)
			}
			invoke(t, inst, "extensionNegotiation")
		})
	}
}

func TestPluginClose(t *testing.T) {
	p := New(Options{})
	a, err := p.take()
	if err != nil {
		t.Fatal(err)
	}
	b, err := p.take()
	if err != nil {
		t.Fatal(err)
	}
	p.release(a)
	if err := p.Close(); err != nil {
		t.Fatal(err)
	}
	if a.native != nil {
		t.Fatal("idle frame retained")
	}
	p.release(b)
	if b.native != nil {
		t.Fatal("active frame retained after release")
	}
	if _, err := p.take(); err == nil {
		t.Fatal("closed plugin acquired frame")
	}
}

func TestInvalidScratchLimit(t *testing.T) {
	rt := wago.NewRuntime()
	defer rt.Close()
	if err := rt.LoadPlugins(context.Background(), PluginSet(Options{ScratchLimit: 1})); err == nil {
		t.Fatal("invalid scratch limit accepted")
	}
}

func TestGuestValidation(t *testing.T) {
	// All of these fail before native dispatch and require no installed ICD.
	for _, mode := range []string{"gc", "wasm32", "wasm64"} {
		t.Run(mode, func(t *testing.T) {
			inst, p := fixture(t, mode, Options{})
			expectTrap(t, inst, "badRange", "bridge error 1")
			expectTrap(t, inst, "badAllocator", "unsupported")
			if mode == "gc" {
				expectTrap(t, inst, "badArray", "packed i32")
				expectTrap(t, inst, "mixedBuffers", "packed i32")
				expectTrap(t, inst, "immutableArray", "immutable")
				expectTrap(t, inst, "nullOffset", "nonzero offset")
			} else {
				expectTrap(t, inst, "wrongWidth", "namespace requires")
			}
			for _, b := range p.free.native.buffers {
				if b.base != nil {
					t.Fatal("guest view retained after validation failure")
				}
			}
		})
	}
	t.Run("gcScratchLimit", func(t *testing.T) {
		inst, _ := fixture(t, "gc", Options{ScratchLimit: 4096})
		expectTrap(t, inst, "badExtension", "scratch limit")
	})
}

func expectTrap(tb testing.TB, inst *wago.Instance, name, contains string) {
	tb.Helper()
	if _, err := inst.Invoke(name); err == nil || !strings.Contains(err.Error(), contains) {
		tb.Fatalf("%s: expected %q trap, got %v", name, contains, err)
	}
}
