# macOS / MoltenVK smoke-test checklist

Use a checkout of the proposed change and run from the repository root. This
checklist is for an available Mac; successful Linux tests do not establish these
results. Nothing below needs credentials, a paid service, XQuartz, or a window.

## 1. Prerequisites and build

Use macOS with a Metal-capable device, native-architecture Go 1.25 or newer,
Xcode Command Line Tools (`xcode-select -p`), and Homebrew. On Apple Silicon use
arm64 Go and arm64 Homebrew libraries; avoid running this shell under Rosetta.

```sh
brew install pkgconf vulkan-headers vulkan-loader molten-vk
export PKG_CONFIG_PATH="$(brew --prefix vulkan-loader)/lib/pkgconfig:$(brew --prefix vulkan-headers)/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export VK_DRIVER_FILES="$(brew --prefix molten-vk)/etc/vulkan/icd.d/MoltenVK_icd.json"
test -f "$VK_DRIVER_FILES"
pkg-config --modversion vulkan
go vet ./...
go test -count=1 ./...
GOEXPERIMENT=cgocheck2 go test -count=1 ./...
bash scripts/test-native.sh
```

Expected: supported Go guest modes pass and the native script prints four
`PASS:` lines. Use `go test -v -count=1 ./...` to see explicit runtime-capability
skips. The pinned Wago runtime does not advertise GC/memory64 on Intel macOS;
the included GC fixture also lacks exact host-boundary root-map admission on
Apple Silicon. Skips are unsupported/unverified ABIs, not passes.
These are compile/link, Wago CPU/ABI tests, and mocked native Vulkan calls. They
do **not** establish that MoltenVK can enumerate a Metal device or render.
Generated files are checked in; Python and `wasm-tools` are not prerequisites.

If using the LunarG Vulkan SDK instead, source its `setup-env.sh` and use its
loader/headers/MoltenVK consistently rather than mixing SDK and Homebrew paths.
Check `pkg-config --cflags --libs vulkan` before building.

## 2. Real MoltenVK headless path

```sh
set -o pipefail
go test -count=1 -v -tags integration ./... 2>&1 | tee macos-integration.log
GOEXPERIMENT=cgocheck2 go test -count=1 -v -tags integration ./...
go run ./examples/headless -abi wasm32
# Apple Silicon only, where the pinned Wago runtime advertises memory64:
go run ./examples/headless -abi wasm64
```

Expected: `TestVulkanRoundTrip/wasm32` passes on either Mac, with `/wasm64`
also expected on Apple Silicon. Unsupported GC/Intel-memory64 fixtures are
explicitly skipped with the runtime's reason. Each supported example
prints `vulkan.<abi>: Vulkan <version>, queue <nonzero handle>, mapped memory round trip passed`.
This reaches the real loader and MoltenVK, negotiates portability extensions,
creates an instance/device/queue, queries properties, and allocates/maps/copies
memory. It does not submit a rendering workload or prove visible presentation.

If it fails, preserve the first failure and run one diagnostic attempt:

```sh
VK_LOADER_DEBUG=error,warn,driver go run ./examples/headless -abi wasm32 > macos-loader.log 2>&1
```

Do not suppress failures or treat a missing Metal device as a pass. A no-device
host can still be useful for step 1. Share only the relevant logs; inspect them
for local paths or other information you do not want to disclose.

## 3. Details to return

```sh
git rev-parse HEAD
sw_vers
uname -m
go version
go env GOOS GOARCH CGO_ENABLED
pkg-config --modversion vulkan
brew list --versions vulkan-loader vulkan-headers molten-vk
system_profiler SPDisplaysDataType
```

Return the commit, Mac model/chip, macOS version, Go/tool versions, which steps
passed, which ABI cases were skipped, and the first failing command plus `macos-integration.log` and, if
needed, `macos-loader.log`. Redact serial numbers or other personal identifiers
if present in hardware output. Do not dump your full environment.

## Presentation still requires a host harness

This change adds the guest `vkCreateMetalSurfaceEXT` import and tests its ABI
with mocks; it does not include an AppKit renderer. A further hardware test
needs a host-owned window and `CAMetalLayer`, surface extension enablement,
surface support/format queries, swapchain creation, actual draw/present, resize,
and orderly destruction before releasing the layer. A passing headless run
must not be reported as a passing rendering test.

References:
- [MoltenVK runtime integration](https://github.com/KhronosGroup/MoltenVK/blob/main/Docs/MoltenVK_Runtime_UserGuide.md)
- [Portability enumeration](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_portability_enumeration.html)
- [Portability subset](https://docs.vulkan.org/refpages/latest/refpages/source/VK_KHR_portability_subset.html)
- [Metal surface extension](https://docs.vulkan.org/refpages/latest/refpages/source/VK_EXT_metal_surface.html)
