# One-command Intel Mac smoke test

This branch adds a small test harness to PR1. It needs no Codex usage. Run it
from a logged-in **Intel Mac** desktop with a Metal GPU, native amd64 Go 1.25+
(`go version`), Xcode Command Line Tools, Python 3, Vulkan headers/loader, and
MoltenVK. No XQuartz is needed. It rejects Apple Silicon/Rosetta and mismatched
loader/driver architecture. Nothing installs itself, asks for passwords, changes
system settings, or uploads logs. Go may download the pinned module dependencies.

If dependencies are missing, these are optional **manual** installation steps:

```sh
# Only if the Command Line Tools are absent:
xcode-select --install
# Only if you use Homebrew and need these dependencies:
brew install go python pkgconf vulkan-headers vulkan-loader molten-vk
```

The script discovers standard Homebrew paths. For a LunarG SDK, source its
`setup-env.sh`, and explicitly export `VK_DRIVER_FILES` pointing to its single
MoltenVK ICD JSON. Use that SDK's loader, headers, and driver together. An explicit
`PKG_CONFIG_PATH`/`VK_DRIVER_FILES` is preserved. Avoid mixing SDK/Homebrew or
x86_64/arm64 libraries. The manifest's library path must resolve to an existing
MoltenVK dylib; failures report the missing path/architecture.

For validation, use a matching SDK that includes `VK_LAYER_KHRONOS_validation`,
or manually install/configure that layer. The basic Homebrew list above does
**not** promise a validation layer. The default run completes GPU phases and
fails if validation is missing. To collect those phases with an explicit
validation **SKIP**, use `--validation-optional`; that run exits **2 / INCOMPLETE**,
never a full pass. Unset validation-disabling environment overrides first.

From this checkout, run:

```sh
bash scripts/macos-smoke.sh
```

Keep the window visible for about five seconds. Vulkan should display the exact
message **thank you for testing!** on a blue background, resize to a larger green
window with the same message, then close. This is a single small window with two
presentations; there is no animation loop or stress test. The initial window is
480 × 300 points; the resized window is 640 × 360 points. Do not manually resize
or close it during the short run. Answer `y` only if you saw both stages, the
message, and a clean close. The question times out after 30 seconds.

Automated checks are reported separately:

- OS/architecture, Go/CGO/CLT, explicit ICD, x86_64 loader/MoltenVK slices.
- CPU/mock tests, vet, strict CGO checks, native ASan/UBSan mocks.
- Real Wasm32 instance/device/queue/mapped-memory round trip.
- One 64-invocation GPU compute dispatch through the Wasm32 guest imports;
  every result is checked against `input * 3 + 7` after a fence wait and a
  shader-write-to-host-read barrier.
- Host-owned AppKit window/CAMetalLayer on the locked initial OS thread; guest
  `vkCreateMetalSurfaceEXT`, queue surface support, formats/present modes,
  swapchain creation, bitmap upload, present, resize/recreation, and teardown.
- Available validation layer plus debug messenger; validation errors fail.

The embedded 5 × 7 bitmap font is uploaded with guest `vkCmdCopyBufferToImage`;
the message is part of the actual Vulkan image, not an AppKit label. Present
success alone does not prove that a person saw correct pixels. Human visual
confirmation is required for a full PASS. This tests transfers/presentation and
compute; it does not test a graphics draw pipeline or every Vulkan command.

The pinned Wago runtime's GC and memory64 modes on Intel Mac are explicitly
unsupported/unverified and skipped. A Wasm32 pass says nothing about those ABIs.
Missing GPU, driver, extensions, or an unusable GUI session fails, never passes.
A host with no compatible HOST_VISIBLE | HOST_COHERENT storage-buffer memory also
fails with an explicit reason. Headless mode (`--headless`) and noninteractive
mode (`--no-prompt`) intentionally report **INCOMPLETE**.

Exit codes: **0 PASS**, **1 FAIL**, **2 INCOMPLETE**. Default missing validation
returns 1 after recording GPU results. With `--validation-optional` it returns 2.
The script stops at the first failing stage. Commands have bounded timeouts;
GPU execution, presentation, and teardown share a 45-second process deadline,
with 5-second Vulkan fence/acquisition waits. Build stages allow up to 180 seconds
with Go parallelism limited to two. A stuck driver is terminated with its process
group; its window disappears when that process exits. Ctrl-C also stops the
current command. Temporary build/cache/native-test files are cleaned up.

Logs stay in `.smoke-logs/<UTC timestamp>/` with private permissions. Return
`summary.json`, `gpu.log` (if reached), and the first failing stage's log after
reviewing them. They include commit/dirty state, OS/Go/compiler/dependency versions,
loader/driver hashes and architecture (also checked against the actual loaded
images using `dladdr` and the dyld image list), Vulkan GPU name/vendor/device/API/driver
version, results and skips. Checkout/home paths are replaced with placeholders;
third-party diagnostics can still contain other local paths. No serial numbers,
account names, full environment, or system profiler dump are requested. No
upload occurs. You choose what to share.

## Getting this local branch to the tester

The branch is `smoke/intel-mac-moltenvk`, based on PR1 head
`ad7ff02d707940a645759eb3cb1dd7d9e38e1c87`. It must be published or its archive/patch
transferred before another machine can obtain it. Publishing is a separate action;
the original PR branch is not modified. A complete source archive can be extracted and used with the command above; its
`SMOKE-COMMIT.txt` and `SMOKE-SHA256.json` record the source commit and verify the
source files before running. Extract a fresh copy if this verification fails.
The Git bundle preserves commit history and can be cloned directly:

```sh
git clone -b smoke/intel-mac-moltenvk wago-intel-mac-smoke.bundle wago-intel-mac-smoke
cd wago-intel-mac-smoke
bash scripts/macos-smoke.sh
```

No remote publication is needed to use a locally transferred bundle/archive.

## Development and verification limits

`examples/smoke/generate.py` regenerates the checked-in guest and selected Wasm32
layouts using Python and `wasm-tools`. Regenerate `compute.spv` with:

```sh
glslangValidator -V --target-env vulkan1.0 -o examples/smoke/compute.spv examples/smoke/compute.comp
spirv-val --target-env vulkan1.0 examples/smoke/compute.spv
```

Linux can verify the guest compute path with lavapipe:

```sh
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/lvp_icd.json \
  go run ./examples/smoke -headless -allow-software -require-validation=false
```

This prints explicit software/validation/presentation skips. It is **not** native
Mac, Metal, AppKit, or visible presentation evidence. Native Mac compilation and
GPU/visual execution still require this hardware run. The smoke harness changes
no plugin or Wago algorithms.
