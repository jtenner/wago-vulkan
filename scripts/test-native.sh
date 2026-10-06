#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .bench-cache
packages=(vulkan)
if [[ $(uname -s) != Darwin ]]; then packages+=(x11); fi
# pkg-config emits shell-separated compiler flags for these packages.
read -r -a native_flags <<< "$(pkg-config --cflags --libs "${packages[@]}")"
cc=${CC:-cc}
flags=(-std=c11 -O2 -Wall -Wextra -Werror -Wno-misleading-indentation
  -DWV_TEST_SCRATCH_SCAN -fsanitize=address,undefined -fno-omit-frame-pointer)
# Rename only the generated translation unit's dispatch implementation. This
# works with Apple ld as well as GNU ld (which previously needed --wrap).
"$cc" "${flags[@]}" $(pkg-config --cflags "${packages[@]}") \
  -Dwv_dispatch=wv_test_real_dispatch -DvkCmdSetDepthBias=wv_test_vkCmdSetDepthBias \
  -c commands_generated.c -o .bench-cache/commands-bridge.o
"$cc" "${flags[@]}" testdata/bridge_test.c bridge.c platform.c \
  .bench-cache/commands-bridge.o "${native_flags[@]}" -o .bench-cache/bridge-test
.bench-cache/bridge-test
"$cc" "${flags[@]}" testdata/scratch_test.c commands_generated.c platform.c \
  "${native_flags[@]}" -o .bench-cache/scratch-test
.bench-cache/scratch-test
"$cc" "${flags[@]}" $(pkg-config --cflags "${packages[@]}") \
  -Dwv_dispatch=wv_test_real_dispatch -c commands_generated.c -o .bench-cache/commands-counts.o
"$cc" "${flags[@]}" testdata/counts_test.c bridge.c platform.c \
  .bench-cache/commands-counts.o "${native_flags[@]}" -o .bench-cache/counts-test
.bench-cache/counts-test
# Deliberately do not link Vulkan or X11: vkGetInstanceProcAddr is a fake, and
# the no-Xlib path must have no platform-specific symbol dependency.
"$cc" "${flags[@]}" -DWV_NO_XLIB $(pkg-config --cflags vulkan) \
  testdata/platform_test.c platform.c -o .bench-cache/platform-test
.bench-cache/platform-test
