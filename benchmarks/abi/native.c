#include "native.h"
#include <string.h>
_Static_assert(sizeof(VkViewport) == 24, "unexpected viewport layout");
_Static_assert(offsetof(VkViewport, maxDepth) == 20, "unexpected viewport layout");
// Stand-in for vkCmdSetViewport's synchronous argument consumption. Same native
// function for every representation. Reads every field, never retains a pointer.
// No GPU, driver, validation layer or command-buffer timing is included.
uint64_t consume_viewports(const VkViewport *items, size_t count) {
    uint64_t sum = 0;
    for (size_t i = 0; i < count; ++i) {
        uint32_t words[6];
        memcpy(words, &items[i], sizeof(words));
        for (size_t j = 0; j < 6; ++j)
            sum += (uint64_t)words[j] * (j + 1);
    }
    return sum;
}
