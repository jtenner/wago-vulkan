// Compiled with WV_NO_XLIB on every OS. No driver, window or GPU is used.
#include "../platform.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static VkInstance expected_instance;
static const VkMetalSurfaceCreateInfoEXT *expected_info;
static int available, lookups, calls;

static VKAPI_ATTR VkResult VKAPI_CALL create_metal(VkInstance instance,
    const VkMetalSurfaceCreateInfoEXT *info, const VkAllocationCallbacks *allocator,
    VkSurfaceKHR *surface) {
    assert(instance==expected_instance && info==expected_info && !allocator);
    calls++;
    *surface=(VkSurfaceKHR)(uintptr_t)123;
    return VK_ERROR_SURFACE_LOST_KHR;
}

VKAPI_ATTR PFN_vkVoidFunction VKAPI_CALL vkGetInstanceProcAddr(VkInstance instance, const char *name) {
    assert(instance==expected_instance && !strcmp(name,"vkCreateMetalSurfaceEXT"));
    lookups++;
    return available ? (PFN_vkVoidFunction)create_metal : NULL;
}

int main(void) {
    VkMetalSurfaceCreateInfoEXT info={0};
    expected_info=&info;
    VkSurfaceKHR surface=VK_NULL_HANDLE;
    expected_instance=(VkInstance)(uintptr_t)17;
    assert(wv_create_metal_surface(expected_instance,&info,NULL,&surface)==VK_ERROR_EXTENSION_NOT_PRESENT);
    assert(!surface && !calls && lookups==1);
    available=1;
    assert(wv_create_metal_surface(expected_instance,&info,NULL,&surface)==VK_ERROR_SURFACE_LOST_KHR);
    assert((uintptr_t)surface==123 && calls==1 && lookups==2);
    expected_instance=(VkInstance)(uintptr_t)29;
    assert(wv_create_metal_surface(expected_instance,&info,NULL,&surface)==VK_ERROR_SURFACE_LOST_KHR);
    assert(calls==2 && lookups==3); // no stale proc cached across instances
    assert(wv_create_xlib_surface(VK_NULL_HANDLE,NULL,NULL,NULL)==VK_ERROR_EXTENSION_NOT_PRESENT);
    assert(wv_xlib_presentation_support(VK_NULL_HANDLE,0,NULL,0)==VK_FALSE);
    puts("PASS: Metal proc lookup/forwarding and no-Xlib fallback (mocked, no GPU)");
}
