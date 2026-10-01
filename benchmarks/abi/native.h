#ifndef WAGO_VULKAN_ABI_BENCH_NATIVE_H
#define WAGO_VULKAN_ABI_BENCH_NATIVE_H
#include <stdint.h>
#include <stddef.h>
#include <vulkan/vulkan.h>
uint64_t consume_viewports(const VkViewport *items, size_t count);
#endif
