// Exercise generated count metadata and output conversion through a fake driver.
// No Vulkan resources are created: dispatch checks the translated arguments.
#include "../bridge.h"
#include "../command_ids_generated.h"
#include "../abi/wire.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

static int calls;
static int expected_command;
static int expected_samples;
static int returned_devices;

static void buffer(wv_context *ctx, int arg, void *data, size_t bytes,
                   int width, uint64_t offset) {
    ctx->buffers[arg] = (wv_buffer){data, bytes, (uint8_t)width, 1};
    ctx->input[arg] = offset;
    ctx->args[arg] = offset;
}

uint64_t __wrap_wv_dispatch(int command, const uint64_t *args) {
    assert(command == expected_command);
    calls++;

    if (command == WV_vkCreateShaderModule) {
        const VkShaderModuleCreateInfo *info = (void *)(uintptr_t)args[1];
        assert(info->codeSize == 16);
        for (int i = 0; i < 4; i++) {
            assert(info->pCode[i] == 0x100u + (unsigned)i);
        }
        *(uint64_t *)(uintptr_t)args[3] = 123;
        return VK_SUCCESS;
    }

    if (command == WV_vkCreateGraphicsPipelines) {
        const VkGraphicsPipelineCreateInfo *info = (void *)(uintptr_t)args[3];
        const VkPipelineMultisampleStateCreateInfo *state = info->pMultisampleState;
        assert((int)state->rasterizationSamples == expected_samples);
        for (int i = 0; i < (expected_samples + 31) / 32; i++) {
            assert(state->pSampleMask[i] == 0x12345600u + (unsigned)i);
        }
        *(uint64_t *)(uintptr_t)args[5] = 123;
        return VK_SUCCESS;
    }

    if (command == WV_vkEnumeratePhysicalDevices) {
        uint32_t *count = (void *)(uintptr_t)args[1];
        VkPhysicalDevice *devices = (void *)(uintptr_t)args[2];
        if (!devices) {
            *count = 7;
            return VK_SUCCESS;
        }
        assert(*count == 3);
        for (int i = 0; i < returned_devices; i++) {
            devices[i] = (VkPhysicalDevice)(uintptr_t)(100 + i);
        }
        *count = (uint32_t)returned_devices;
        return returned_devices == 3 ? VK_INCOMPLETE : VK_SUCCESS;
    }

    if (command == WV_vkGetPipelineCacheData) {
        size_t *size = (void *)(uintptr_t)args[2];
        uint8_t *data = (void *)(uintptr_t)args[3];
        if (!data) {
            *size = 123;
            return VK_SUCCESS;
        }
        assert(*size == 16);
        memset(data, 0x55, 8);
        *size = 8;
        return VK_SUCCESS;
    }

    assert(0);
    return 0;
}

static void shader_counts(wv_context *ctx, int width) {
    _Alignas(16) uint8_t arena[96] = {0};
    if (width == 32) {
        wv32_VkShaderModuleCreateInfo *info = (void *)arena;
        info->sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
        info->codeSize = 16;
        info->pCode = 64;
    } else {
        wv64_VkShaderModuleCreateInfo *info = (void *)arena;
        info->sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
        info->codeSize = 16;
        info->pCode = 64;
    }
    for (int i = 0; i < 4; i++) {
        uint32_t word = 0x100u + (unsigned)i;
        memcpy(arena + 64 + 4 * i, &word, 4);
    }

    // codeSize counts bytes; translating pCode must consume exactly four words.
    wv_reset(ctx);
    buffer(ctx, 1, arena, 80, width, 0);
    buffer(ctx, 3, arena, sizeof(arena), width, 88);
    expected_command = WV_vkCreateShaderModule;
    assert(wv_invoke(ctx, expected_command) == WV_OK);
    uint64_t handle;
    memcpy(&handle, arena + 88, 8);
    assert(handle == 123);

    int previous_calls = calls;
    wv_reset(ctx);
    buffer(ctx, 1, arena, 79, width, 0);
    buffer(ctx, 3, arena, sizeof(arena), width, 88);
    assert(wv_invoke(ctx, expected_command) == WV_RANGE);
    assert(calls == previous_calls);
}

static void sample_masks(wv_context *ctx, int width) {
    const int sample_counts[] = {1, 2, 16, 32, 64};
    for (unsigned i = 0; i < sizeof(sample_counts) / sizeof(sample_counts[0]); i++) {
        _Alignas(16) uint8_t arena[256] = {0};
        expected_samples = sample_counts[i];
        if (width == 32) {
            wv32_VkGraphicsPipelineCreateInfo *info = (void *)arena;
            info->sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
            info->pMultisampleState = 160;
            wv32_VkPipelineMultisampleStateCreateInfo *state = (void *)(arena + 160);
            state->sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
            state->rasterizationSamples = (uint32_t)expected_samples;
            state->pSampleMask = 240;
        } else {
            wv64_VkGraphicsPipelineCreateInfo *info = (void *)arena;
            info->sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
            info->pMultisampleState = 160;
            wv64_VkPipelineMultisampleStateCreateInfo *state = (void *)(arena + 160);
            state->sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
            state->rasterizationSamples = (uint32_t)expected_samples;
            state->pSampleMask = 240;
        }
        int words = (expected_samples + 31) / 32;
        for (int j = 0; j < words; j++) {
            uint32_t word = 0x12345600u + (unsigned)j;
            memcpy(arena + 240 + 4 * j, &word, 4);
        }

        // A mask has ceil(rasterizationSamples / 32) words, including one
        // complete word for sample counts below 32.
        wv_reset(ctx);
        ctx->input[2] = ctx->args[2] = 1;
        buffer(ctx, 3, arena, 240 + 4 * (size_t)words, width, 0);
        buffer(ctx, 5, arena, sizeof(arena), width, 248);
        expected_command = WV_vkCreateGraphicsPipelines;
        assert(wv_invoke(ctx, expected_command) == WV_OK);

        int previous_calls = calls;
        wv_reset(ctx);
        ctx->input[2] = ctx->args[2] = 1;
        buffer(ctx, 3, arena, 240 + 4 * (size_t)words - 1, width, 0);
        buffer(ctx, 5, arena, sizeof(arena), width, 248);
        assert(wv_invoke(ctx, expected_command) == WV_RANGE);
        assert(calls == previous_calls);
    }
}

static void enumeration(wv_context *ctx, int width) {
    for (int unaligned = 0; unaligned < 2; unaligned++) {
        for (returned_devices = 2; returned_devices <= 3; returned_devices++) {
            _Alignas(16) uint8_t arena[64];
            memset(arena, 0xcc, sizeof(arena));
            uint32_t count = 3;
            memcpy(arena + unaligned, &count, 4);
            wv_reset(ctx);
            buffer(ctx, 1, arena, sizeof(arena), width, (uint64_t)unaligned);
            buffer(ctx, 2, arena, sizeof(arena), width, 8 + (uint64_t)unaligned);
            expected_command = WV_vkEnumeratePhysicalDevices;
            assert(wv_invoke(ctx, expected_command) == WV_OK);

            memcpy(&count, arena + unaligned, 4);
            assert(count == (uint32_t)returned_devices);
            for (int i = 0; i < returned_devices; i++) {
                uint64_t handle;
                memcpy(&handle, arena + 8 + unaligned + 8 * i, 8);
                assert(handle == 100u + (unsigned)i);
            }
            // A smaller returned count must preserve the unused array suffix,
            // including when conversion used aligned native scratch.
            if (returned_devices == 2) {
                for (int i = 0; i < 8; i++) {
                    assert(arena[8 + unaligned + 16 + i] == 0xcc);
                }
            }
            assert((int32_t)ctx->result ==
                   (returned_devices == 3 ? VK_INCOMPLETE : VK_SUCCESS));
        }
    }

    // With no output array, the previous count is ignored by enumeration.
    uint32_t count = UINT32_MAX;
    wv_reset(ctx);
    buffer(ctx, 1, &count, sizeof(count), width, 0);
    expected_command = WV_vkEnumeratePhysicalDevices;
    assert(wv_invoke(ctx, expected_command) == WV_OK);
    assert(count == 7);
}

static void cache_sizes(wv_context *ctx, int width) {
    _Alignas(16) uint8_t arena[40];
    memset(arena, 0xcc, sizeof(arena));
    uint64_t size = 16;
    memcpy(arena + 1, &size, (size_t)width / 8);
    wv_reset(ctx);
    // The deliberately unaligned size_t requires conversion/writeback in
    // both modes, and widening/narrowing additionally in the 32-bit mode.
    buffer(ctx, 2, arena, sizeof(arena), width, 1);
    buffer(ctx, 3, arena, sizeof(arena), width, 16);
    expected_command = WV_vkGetPipelineCacheData;
    assert(wv_invoke(ctx, expected_command) == WV_OK);
    size = 0;
    memcpy(&size, arena + 1, (size_t)width / 8);
    assert(size == 8);
    for (int i = 0; i < 8; i++) {
        assert(arena[16 + i] == 0x55);
    }
    for (int i = 8; i < 16; i++) {
        assert(arena[16 + i] == 0xcc);
    }

    size = 0;
    memcpy(arena + 1, &size, (size_t)width / 8);
    wv_reset(ctx);
    buffer(ctx, 2, arena, sizeof(arena), width, 1);
    assert(wv_invoke(ctx, expected_command) == WV_OK);
    memcpy(&size, arena + 1, (size_t)width / 8);
    assert(size == 123);
}

int main(void) {
    wv_context *ctx = wv_new(32 * 1024 * 1024);
    assert(ctx);
    for (int width = 32; width <= 64; width += 32) {
        shader_counts(ctx, width);
        sample_masks(ctx, width);
        enumeration(ctx, width);
        cache_sizes(ctx, width);
    }
    wv_free(ctx);
    printf("PASS: %d native dispatches for shader, sample-mask, enumeration and size_t counts\n", calls);
}
