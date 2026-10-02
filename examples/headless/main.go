// Run from the repository root: go run ./examples/headless -abi gc
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"runtime"

	vulkan "github.com/jtenner/wago-vulkan"
	wago "github.com/wago-org/wago"
)

func run() error {
	defaultABI := "gc"
	if runtime.GOOS == "darwin" {
		defaultABI = "wasm32"
	}
	abi := flag.String("abi", defaultABI, "guest interface: gc, wasm32, wasm64")
	flag.Parse()
	if *abi != "gc" && *abi != "wasm32" && *abi != "wasm64" {
		return fmt.Errorf("unsupported ABI %q", *abi)
	}
	features := wago.SupportedFeatures() & wago.CoreFeaturesV3
	if *abi == "gc" && !features.IsEnabled(wago.CoreFeatureGC) ||
		*abi == "wasm64" && !features.IsEnabled(wago.CoreFeatureMemory64) {
		return fmt.Errorf("pinned Wago does not support %s guests on %s/%s; try -abi wasm32", *abi, runtime.GOOS, runtime.GOARCH)
	}
	data, err := os.ReadFile("testdata/" + *abi + ".wasm")
	if err != nil {
		return err
	}
	rt := wago.NewRuntime(wago.WithRuntimeConfig(wago.NewRuntimeConfig().WithCoreFeatures(features)))
	defer rt.Close()
	if err := rt.LoadPlugins(context.Background(), vulkan.PluginSet()); err != nil {
		return err
	}
	mod, err := rt.Compile(data)
	if err != nil {
		return err
	}
	defer mod.Close()
	if *abi == "gc" {
		if admission := mod.Compiled().GCNativeRootAdmission(); !admission.Exact {
			return fmt.Errorf("pinned Wago cannot admit this GC host-boundary fixture: %s; try -abi wasm32", admission.Reason)
		}
	}
	inst, err := rt.Instantiate(context.Background(), mod)
	if err != nil {
		return err
	}
	defer inst.Close()
	if _, err := inst.Invoke("prepare"); err != nil {
		return err
	}
	// Cleanup is also safe if initialization only got as far as an instance.
	defer inst.Invoke("cleanup")
	if _, err := inst.Invoke("init"); err != nil {
		return err
	}
	queue, err := inst.Invoke("query")
	if err != nil {
		return err
	}
	queueHandle := queue[0] // Wago may reuse Invoke's result slots on the next call.
	properties, err := inst.Invoke("properties")
	if err != nil {
		return err
	}
	version := uint32(properties[0])
	mapped, err := inst.Invoke("mapped")
	if err != nil {
		return err
	}
	if mapped[0] != 1 {
		return fmt.Errorf("mapped memory round trip failed")
	}
	fmt.Printf("vulkan.%s: Vulkan %d.%d.%d, queue %#x, mapped memory round trip passed\n",
		*abi, version>>22, (version>>12)&1023, version&4095, queueHandle)
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
