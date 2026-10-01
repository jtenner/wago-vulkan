//go:build abi_benchmark

// Package abi benchmarks proposed buffer and struct ABIs. It is not a Vulkan plugin.
package abi

/*
#cgo CFLAGS: -O3
#include "native.h"
#include <stdlib.h>
#include <string.h>
*/
import "C"

import (
	"encoding/binary"
	"fmt"
	wago "github.com/wago-org/wago"
	"unsafe"
)

type bridge struct {
	kind    string
	count   int
	scratch unsafe.Pointer
	last    uint64
	fields  [6]uint64
}

// Each benchmark instance owns its scratch; no pools, reflection, per-item
// allocations, retained guest addresses, or re-entry during the borrow.
func newBridge(kind string, count int) *bridge {
	b := &bridge{kind: kind, count: count}
	if kind == "structs_fields" || kind == "structs_bulk" || kind == "structs_batch" {
		b.scratch = C.malloc(C.size_t(count * 24))
		if b.scratch == nil {
			panic("native scratch allocation failed")
		}
	}
	return b
}

func (b *bridge) close() { C.free(b.scratch); b.scratch = nil }

func (b *bridge) Register(reg *wago.Registrar) error {
	imports, err := reg.HostImports()
	if err != nil {
		return err
	}
	imports.HostFunc("abi", "submit", b.submit).Params(wago.ValI32, wago.ValAnyRef)
	return nil
}

func (b *bridge) submit(caller wago.Caller, call wago.HostCall) {
	var checksum int64
	host, ok := any(caller).(wago.GuestStorageHostModule)
	if !ok {
		panic("guest storage unavailable")
	}
	err := host.WithGuestStorage(func(s wago.GuestStorage) error {
		n := int(call.I32(0))
		if n != b.count {
			return fmt.Errorf("unexpected item count")
		}
		ref, err := s.GCRef(call.ParamSlots()[1])
		if err != nil {
			return err
		}
		if b.kind == "packed32" || b.kind == "packed64" {
			data, info, err := s.GCArrayBytes(ref, wago.GuestStorageRead)
			if err != nil {
				return err
			}
			want := wago.GuestGCArrayI32
			if b.kind == "packed64" {
				want = wago.GuestGCArrayI64
			}
			if info.Storage != want || len(data) != n*24 {
				return fmt.Errorf("invalid packed buffer")
			}
			if uintptr(unsafe.Pointer(unsafe.SliceData(data)))%4 != 0 {
				return fmt.Errorf("unaligned buffer")
			}
			result := C.consume_viewports((*C.VkViewport)(unsafe.Pointer(unsafe.SliceData(data))), C.size_t(n))
			checksum = int64(result)
			return nil
		}
		dst := unsafe.Slice((*byte)(b.scratch), n*24)
		if b.kind == "structs_batch" {
			access := s.(interface {
				BenchmarkViewportArray(wago.GuestGCRef, []byte) error
			})
			if err := access.BenchmarkViewportArray(ref, dst); err != nil {
				return err
			}
			checksum = int64(C.consume_viewports((*C.VkViewport)(b.scratch), C.size_t(n)))
			return nil
		}
		info, err := s.GCArrayInfo(ref)
		if err != nil {
			return err
		}
		if info.Storage != wago.GuestGCArrayRef || int(info.Length) != n {
			return fmt.Errorf("invalid struct array")
		}
		if b.kind == "structs_fields" {
			access := s.(interface {
				BenchmarkStructFields(wago.GuestGCRef, []uint64) error
			})
			fields := b.fields[:]
			for i := 0; i < n; i++ {
				child, err := s.GCArrayRef(ref, uint32(i))
				if err != nil {
					return err
				}
				if err := access.BenchmarkStructFields(child, fields); err != nil {
					return err
				}
				for j, bits := range fields {
					binary.LittleEndian.PutUint32(dst[i*24+j*4:], uint32(bits))
				}
			}
		} else {
			access := s.(interface {
				BenchmarkStructBytes(wago.GuestGCRef) ([]byte, error)
			})
			for i := 0; i < n; i++ {
				child, err := s.GCArrayRef(ref, uint32(i))
				if err != nil {
					return err
				}
				data, err := access.BenchmarkStructBytes(child)
				if err != nil {
					return err
				}
				copy(dst[i*24:(i+1)*24], data)
			}
		}
		checksum = int64(C.consume_viewports((*C.VkViewport)(b.scratch), C.size_t(n)))
		return nil
	})
	if err != nil {
		panic(wago.HostTrap{Err: err})
	}
	b.last = uint64(checksum)
}
