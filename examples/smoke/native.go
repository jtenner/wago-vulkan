package main

/*
#cgo pkg-config: vulkan
#cgo linux LDFLAGS: -ldl
#cgo darwin LDFLAGS: -framework AppKit -framework QuartzCore -framework Metal
#include "native.h"
*/
import "C"

func debugStart(instance uint64) int32 { return int32(C.smoke_debug_start(C.uint64_t(instance))) }
func debugStop(instance uint64)        { C.smoke_debug_stop(C.uint64_t(instance)) }
func debugErrors() uint32              { return uint32(C.smoke_debug_errors()) }
func windowOpen() uint64               { return uint64(C.smoke_window_open()) }
func windowResize() bool               { return C.smoke_window_resize() != 0 }
func windowPump(seconds float64)       { C.smoke_window_pump(C.double(seconds)) }
func windowClose()                     { C.smoke_window_close() }
func windowSize() (uint32, uint32) {
	var width, height C.uint32_t
	C.smoke_window_size(&width, &height)
	return uint32(width), uint32(height)
}

func loadedLoader() string   { return C.GoString(C.smoke_loader_path()) }
func loadedMoltenVK() string { return C.GoString(C.smoke_moltenvk_path()) }
