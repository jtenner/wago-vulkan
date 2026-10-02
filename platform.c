#include "platform.h"

VkResult wv_create_metal_surface(VkInstance instance, const VkMetalSurfaceCreateInfoEXT *info,
                               const VkAllocationCallbacks *allocator, VkSurfaceKHR *surface) {
    // Extension commands are not guaranteed to be exported by the loader.
    // Resolve per instance, so multiple instances/layers remain independent.
    PFN_vkCreateMetalSurfaceEXT create = (PFN_vkCreateMetalSurfaceEXT)
        vkGetInstanceProcAddr(instance, "vkCreateMetalSurfaceEXT");
    if (!create) return VK_ERROR_EXTENSION_NOT_PRESENT;
    return create(instance, info, allocator, surface);
}

VkResult wv_create_xlib_surface(VkInstance instance, const VkXlibSurfaceCreateInfoKHR *info,
                              const VkAllocationCallbacks *allocator, VkSurfaceKHR *surface) {
#ifdef VK_USE_PLATFORM_XLIB_KHR
    return vkCreateXlibSurfaceKHR(instance, info, allocator, surface);
#else
    (void)instance; (void)info; (void)allocator; (void)surface;
    return VK_ERROR_EXTENSION_NOT_PRESENT;
#endif
}

VkBool32 wv_xlib_presentation_support(VkPhysicalDevice physical, uint32_t family,
                                    Display *display, VisualID visual) {
#ifdef VK_USE_PLATFORM_XLIB_KHR
    return vkGetPhysicalDeviceXlibPresentationSupportKHR(physical, family, display, visual);
#else
    (void)physical; (void)family; (void)display; (void)visual;
    return VK_FALSE;
#endif
}
