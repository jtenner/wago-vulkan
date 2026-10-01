#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .bench-cache
cc -std=c11 -O2 -Wall -Wextra -Werror -Wno-misleading-indentation \
  -DWV_TEST_SCRATCH_SCAN \
  -fsanitize=address,undefined -fno-omit-frame-pointer \
  testdata/bridge_test.c bridge.c commands_generated.c \
  -Wl,--wrap=wv_dispatch -Wl,--wrap=vkCmdSetDepthBias $(pkg-config --cflags --libs vulkan x11) \
  -o .bench-cache/bridge-test
.bench-cache/bridge-test
cc -std=c11 -O2 -Wall -Wextra -Werror -Wno-misleading-indentation \
  -DWV_TEST_SCRATCH_SCAN \
  -fsanitize=address,undefined -fno-omit-frame-pointer \
  testdata/scratch_test.c commands_generated.c \
  $(pkg-config --cflags --libs vulkan x11) -o .bench-cache/scratch-test
.bench-cache/scratch-test
cc -std=c11 -O2 -Wall -Wextra -Werror -Wno-misleading-indentation \
  -fsanitize=address,undefined -fno-omit-frame-pointer \
  testdata/counts_test.c bridge.c commands_generated.c \
  -Wl,--wrap=wv_dispatch $(pkg-config --cflags --libs vulkan x11) \
  -o .bench-cache/counts-test
.bench-cache/counts-test
