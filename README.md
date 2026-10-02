# wago-vulkan

Thin, named Vulkan imports for Wago. The GC interface uses **mutable packed
`array<i32>` buffers**. Guests assemble Vulkan data themselves; wrappers borrow
compatible buffers and translate pointer fields where necessary.

Licensed under [MIT](LICENSE). [NOTICE](NOTICE) preserves the upstream Vulkan
registry attribution.

| Import module | Pointer parameter | Structure layout |
| --- | --- | --- |
| `vulkan.gc` | `(anyref buffer, i32 byteOffset)` | 64-bit wire layout inside packed i32 words |
| `vulkan.wasm32` | `i32` linear-memory byte offset | 32-bit wire layout |
| `vulkan.wasm64` | `i64` linear-memory byte offset | 64-bit wire layout |

All Vulkan handles are `i64` in every interface, including dispatchable handles
in Wasm32. Flags, enums, counts and `VkResult` are `i32`; native scalar `float`
arguments are `f32`. Native `void` functions return no Wasm values. Negative
Vulkan results are returned unchanged. Bridge validation failures trap.

Current coverage is 152 commands per module: Vulkan 1.0 plus `VK_KHR_surface`,
`VK_KHR_swapchain`, `VK_KHR_xlib_surface` and `VK_EXT_metal_surface`. This is an
experimental ABI, version 1, for 64-bit Linux and macOS hosts. macOS uses the
Vulkan loader and MoltenVK; native Metal rendering still needs hardware testing.
It uses the public pinned Wago API;
the benchmark runtime overlay is not needed by the library.

## Build and load

Requires Go 1.25 or later, CGO, a C compiler, `pkg-config`, Vulkan development
headers/loader and, on Linux, X11 development headers. A Vulkan ICD is needed to execute
Vulkan calls; Mesa lavapipe works for the headless example and integration tests.

```go
import (
    "context"
    wago "github.com/wago-org/wago"
    vulkan "github.com/jtenner/wago-vulkan"
)

rt := wago.NewRuntime(wago.WithRuntimeConfig(
    wago.NewRuntimeConfig().WithCoreFeatures(wago.SupportedFeatures() & wago.CoreFeaturesV3),
))
defer rt.Close()
err := rt.LoadPlugins(context.Background(), vulkan.PluginSet(vulkan.Options{
    MemoryIndex: 0,          // selected linear memory for both pointer modules
    ScratchLimit: 32 << 20,  // retained native conversion bytes per active call
}))
// Check err, then compile and instantiate your guest normally.
```

`Provider(options)` is available for hosts that compose their own plugin set and
authority grants. Runtime shutdown frees the wrapper's native scratch pool.
The caller manages Vulkan object lifetimes and Vulkan synchronization.

For Wago's plugin manager, the module exports its default provider through
`github.com/jtenner/wago-vulkan/register`. [wago.json](wago.json) describes the
experimental 0.1.0 release; [wago.providers.json](wago.providers.json) contains
the immutable definition and its digest. Native build dependencies above also
apply when Wago builds a runtime containing this plugin. Embedding hosts use
`Provider(options)` for a different memory index or scratch limit.

Run the included headless guest through any of the three interfaces:

```sh
go run ./examples/headless -abi gc
go run ./examples/headless -abi wasm32
go run ./examples/headless -abi wasm64
```

### macOS / MoltenVK

With native-architecture Go, Xcode Command Line Tools and Homebrew installed:

```sh
brew install pkgconf vulkan-headers vulkan-loader molten-vk
export PKG_CONFIG_PATH="$(brew --prefix vulkan-loader)/lib/pkgconfig:$(brew --prefix vulkan-headers)/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export VK_DRIVER_FILES="$(brew --prefix molten-vk)/etc/vulkan/icd.d/MoltenVK_icd.json"
go test ./...                       # no GPU required
go run ./examples/headless -abi wasm32 # requires a usable Metal device
```

Alternatively, use the [macOS Vulkan SDK](https://vulkan.lunarg.com/doc/sdk/latest/mac/getting_started.html)
and its environment setup (`setup-env.sh`). `pkg-config --cflags --libs vulkan`
must find matching headers and `libvulkan.dylib`. This package links the Vulkan
loader; installing only `libMoltenVK.dylib` is not enough. Do not mix Intel and
Apple Silicon Go/libraries. No XQuartz or X11 library is required on macOS.

The pinned Wago runtime has additional guest-ABI limits independent of Vulkan:
Intel macOS does not advertise GC or memory64, and the included GC fixture is
not admitted on Apple Silicon because exact host-boundary root maps are
unavailable for it. Start with `wasm32` on either Mac; `wasm64` is also a candidate
on Apple Silicon. The example reports unsupported modes before instantiation,
and Mac tests explicitly skip them using Wago's feature/root-admission APIs.
A skipped ABI is **not** validated support. The GC bridge layout still has native
mock coverage. No Wago compiler changes or dependency updates are included.

Guests retain control of instance/device creation. They must:

- Enumerate instance extensions and, when available, enable
  `VK_KHR_portability_enumeration` together with
  `VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR` (value `1`)
- For a Vulkan 1.0 instance, enable `VK_KHR_get_physical_device_properties2`
  when using `VK_KHR_portability_subset`
- Enumerate the selected physical device's extensions and enable
  `VK_KHR_portability_subset` if advertised

The checked-in headless guests do this negotiation on both platforms. The plugin
does not add extensions, change flags, or promise Vulkan features on a guest's
behalf. MoltenVK implements a portability subset, so check device capabilities
and its [runtime guidance](https://github.com/KhronosGroup/MoltenVK/blob/main/Docs/MoltenVK_Runtime_UserGuide.md).
The current catalogue does not expose the extended portability feature/property
query structures. Full portability-subset feature discovery is outside this change.

For presentation, the embedding host must create/retain an AppKit view and
`CAMetalLayer` on the appropriate thread, set the layer's delegate to the view,
and pass its native address to the guest. Enable `VK_KHR_surface` and
`VK_EXT_metal_surface`, then call `vkCreateMetalSurfaceEXT` with a packed
`VkMetalSurfaceCreateInfoEXT`. Its `pLayer` is an **external 64-bit native
address in all three ABIs**, not a guest offset. The wrapper never creates,
retains, or releases the layer. Keep it alive through surface/swapchain use.
The Metal command is resolved through `vkGetInstanceProcAddr` for its instance;
an unavailable command returns `VK_ERROR_EXTENSION_NOT_PRESENT`.

All import signatures remain present on both platforms. On macOS,
`vkCreateXlibSurfaceKHR` returns `VK_ERROR_EXTENSION_NOT_PRESENT` and
`vkGetPhysicalDeviceXlibPresentationSupportKHR` returns `VK_FALSE`; neither
touches an Xlib address. Existing Linux Xlib dispatch is preserved.

See the [Mac smoke-test checklist](docs/macos-testing.md) for commands, expected
results, and the distinction between CPU checks, headless device access and
actual surface/rendering validation.

## Function shapes

Each import has the Vulkan command's name, argument order and native return
type. A GC pointer becomes a buffer/offset pair; a linear pointer becomes one
integer offset. There is no generic command-ID import or separate relocation
array to build on each call.

```text
vulkan.gc.vkCmdSetViewport(
    commandBuffer: i64, firstViewport: i32, viewportCount: i32,
    pViewports: anyref, pViewportsOffset: i32
) -> void

vulkan.wasm32.vkCmdSetViewport(
    commandBuffer: i64, firstViewport: i32, viewportCount: i32,
    pViewports: i32
) -> void

vulkan.wasm64.vkCmdSetViewport(
    commandBuffer: i64, firstViewport: i32, viewportCount: i32,
    pViewports: i64
) -> void
```

The complete generated signatures are in
[vulkan.gc.txt](abi/vulkan.gc.txt),
[vulkan.wasm32.txt](abi/vulkan.wasm32.txt), and
[vulkan.wasm64.txt](abi/vulkan.wasm64.txt).

Every module also exports `abiVersion() -> i32`, `writeMapped` and `readMapped`.

## Packing GC buffers

"Packed i32" describes the storage elements. **Keep the padding and field
offsets in the wire layout**; do not concatenate fields without padding.
Data is little-endian. A 32-bit float occupies one i32 element containing its
bit pattern. A 64-bit handle, offset or scalar occupies two consecutive words,
low word first. A single float update takes one reinterpret and one array store.

For example, `VkViewport` contains six f32 fields and occupies six i32 elements:

```wat
(type $words (array (mut i32)))
(import "vulkan.gc" "vkCmdSetViewport"
  (func $setViewport (param i64 i32 i32 anyref i32)))

;; Given an existing packed array and a valid recording command buffer:
;; array word 2 is viewport.width (byte offset 8).
local.get $viewports
i32.const 2
f32.const 1920
i32.reinterpret_f32
array.set $words

local.get $commandBuffer
i32.const 0                 ;; firstViewport
i32.const 1                 ;; viewportCount
local.get $viewports
i32.const 0                 ;; byte offset, not element index
call $setViewport
```

With compatible alignment, the six words go directly to `vkCmdSetViewport` as
one native `VkViewport`. The wrapper does not traverse or rebuild each item.
Native tests check that borrowing property with synthetic batches up to 100,000
items. Actual Vulkan calls must respect the device's viewport count limits.

Root GC pointers may use separate arrays. Each root buffer owns its entire
nested graph: **embedded pointer fields are byte offsets from that buffer's
start**, not references to other GC arrays. Embedded zero means NULL. A root
`(non-null array, 0)` is valid; a null root is `(ref.null any, 0)`.
Use separate output buffers or offsets in the same arena as appropriate.
All arrays must be mutable i32 arrays, including input arrays.

## Device creation example

```text
vulkan.gc.vkCreateDevice(
    physicalDevice: i64,
    pCreateInfo: anyref, pCreateInfoOffset: i32,
    pAllocator: anyref, pAllocatorOffset: i32,
    pDevice: anyref, pDeviceOffset: i32
) -> i32
```

A zero-initialized 120-byte GC arena can contain the following data, using the
64-bit wire layout. Write 64-bit values as two i32 words; leave padding zero.

| Byte offset | Field | Value |
| --- | --- | --- |
| 0 | `VkDeviceCreateInfo.sType` | 3 (`DEVICE_CREATE_INFO`) |
| 20 | `queueCreateInfoCount` | 1 |
| 24 | `pQueueCreateInfos` | 72, stored as u64 |
| 72 | `VkDeviceQueueCreateInfo.sType` | 2 (`DEVICE_QUEUE_CREATE_INFO`) |
| 92 | `queueFamilyIndex` | a supported queue family index |
| 96 | `queueCount` | 1 |
| 104 | `pQueuePriorities` | 112, stored as u64 |
| 112 | `pQueuePriorities[0]` | bit pattern of f32 `1.0` |

The remaining fields are zero: no `pNext`, flags, layers, extensions or optional
features. On a portability device, also populate the required
`VK_KHR_portability_subset` extension as described above. Provide a separate two-word output buffer for the native device
handle and pass a null allocator:

```wat
local.get $physicalDevice
local.get $arena i32.const 0
ref.null any i32.const 0
local.get $deviceOut i32.const 0
call $vkCreateDevice         ;; returns VkResult, deviceOut receives two words
```

The wrapper copies the small pointer-bearing create structures into reusable
native scratch and patches their pointers. The float priority array and output
handle are borrowed directly when aligned. There are no GC struct objects to
walk and no allocation per queue.

For Wasm32/Wasm64, use `wv32_VkDeviceCreateInfo` or
`wv64_VkDeviceCreateInfo` from [wire.h](abi/wire.h), place the structures in
linear memory, and store absolute guest-memory byte offsets in pointer fields.
Root pointer zero is NULL in these modules. Wasm32 pointer fields and `size_t`
are 32-bit; handles remain 64-bit. Do not assume the native Vulkan headers'
Wasm32 handle typedefs match this wire ABI.

[layouts.json](abi/layouts.json) contains the sizes, alignments and member byte
offsets for all 112 supported structure/union layouts. GC uses its `64` layouts.

## Mapped memory

`vkMapMemory` writes an opaque native mapped address into an **eight-byte output
slot in all three modules**. Use `writeMapped` to upload guest bytes and
`readMapped` to copy them back:

```text
vulkan.gc.writeMapped(nativeAddress: i64, buffer: anyref,
                     byteOffset: i32, byteLength: i32) -> void
vulkan.wasm32.writeMapped(nativeAddress: i64, guestOffset: i32,
                         byteLength: i32) -> void
vulkan.wasm64.writeMapped(nativeAddress: i64, guestOffset: i64,
                         byteLength: i64) -> void
```

`readMapped` has the same signature with the transfer direction reversed. Both
perform one native `memmove` after checking the guest range. Callers manage the
mapped range's validity, lifetime, and flush/invalidate requirements.

## Performance and supported usage

Imports without guest-memory data use dedicated generated C trampolines,
including destruction functions whose allocator must be NULL. They acquire no
guest-storage lease, frame or scratch. Pointer imports borrow storage once,
check spans, translate necessary structures, call Vulkan and write outputs back
within that lease. Borrowed addresses are cleared before returning to Wago.
Go-backed buffers are pinned until native invocation and pointer cleanup finish,
including mapped transfers and validation failures.
Input guest offsets are never replaced with native pointers in guest memory.

Aligned, layout-compatible POD arrays are borrowed directly. Unaligned data,
Wasm32 structures with different native layouts, pointer arrays and structures
with pointers use retained native scratch. Scratch grows on demand and is reused
on subsequent calls. The default bound is 32 MiB per concurrent call frame, not
an eagerly allocated 32 MiB buffer or a total process-memory limit.
Small allocations use forward-only cursors. A balanced index of remaining block
capacity finds reusable larger blocks and skipped tails without rescanning full
blocks. Reordered and shrinking workloads can reuse retained capacity; large
blocks keep exact capacities.

Shared substructures are translated once per call. A reusable hash table tracks
aliases and cycles, avoiding repeated scans of all earlier converted structures
in large nested batches. Compatible 64-bit records are copied in bulk before
patching their pointer fields.

The pinned Wago storage/reference machinery still has fixed per-call Go
allocations: the measured queue-query round trip uses 624 B / 2 allocations for
GC and 48 B / 1 allocation for either linear-memory interface. Scalar-only
`vkDeviceWaitIdle` round trips use 0 B / 0 allocations. These totals include
Wago and the driver; they are not wrapper-only timings or allocation counts.
See [the production measurements](benchmarks/production.md) and
[the original ABI comparison](benchmarks/abi/results/report.md).

This is a trusted native FFI. The caller supplies valid Vulkan handles, native
external addresses such as Xlib `Display*` or `CAMetalLayer*`, correct counts and Vulkan valid
usage. Bounds checks on guest buffers do not validate arbitrary native addresses.
Guest allocator callbacks and proc-address getters are not supported; allocator
arguments must be NULL. `pNext` chains accept types present in the generated
layout catalogue; unknown types and cyclic/deep graphs trap. Zero unused pointer
fields unless explicitly handled by the wrapper, such as ignored descriptor
image/buffer/texel pointers.

## Verify and regenerate

```sh
go test ./...                       # all import signatures, validation, pool lifecycle
go vet ./...
GOEXPERIMENT=cgocheck2 go test -tags integration ./... # strict Go/C pointer checks
bash scripts/test-native.sh         # fake driver, ASan/UBSan, conversion/writeback/zero-copy
go test -tags integration ./...     # real Vulkan ICD through all three namespaces
go test -tags integration -run '^$' -bench BenchmarkVulkan -benchmem -cpu=1
python3 scripts/benchmark-scratch.py # native nested-batch allocation work
```

To force lavapipe on machines with multiple ICDs, set
`VK_DRIVER_FILES=/usr/share/vulkan/icd.d/lvp_icd.json` (adjust to your install).
Integration fixtures create/destroy an instance and device, test a real negative
`VkResult`, query properties/queues, and allocate/map/copy/read/free memory.
Native fixtures also check shader byte counts, sample-mask rounding, enumeration
capacity/writeback, and `size_t` outputs in both wire widths. Scratch regressions
cover allocation order changes and shrinking batches under tight limits.
Metal surface tests use a fake driver to verify the 64-bit external layer address,
both wire layouts, negative results and per-instance function lookup. The macOS CI jobs are configured to build/link and run Go CPU checks and
ASan/UBSan native mocks on Intel and Apple Silicon; they do not run the
`integration` tests or certify Metal GPU/rendering.

Generated wrappers are checked in. Regeneration additionally requires Python 3,
the Vulkan XML registry, and `wasm-tools` for integration guests:

```sh
python3 scripts/generate.py --registry /usr/share/vulkan/registry/vk.xml
python3 scripts/generate-test-guests.py
```

Generation probes every native layout and emits compile-time size/member-offset
assertions. [registry.json](abi/registry.json) records the source registry hash
and selected command profile. Benchmark-only GC struct accessors are isolated
under `benchmarks/abi` and enabled only with the `abi_benchmark` build tag.
