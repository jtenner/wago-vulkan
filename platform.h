#ifndef WAGO_VULKAN_PLATFORM_H
#define WAGO_VULKAN_PLATFORM_H

// Keep the same wire catalogue/import signatures on both hosts. Darwin does
// not need XQuartz: these opaque Xlib types describe external 64-bit addresses
// only, and Xlib commands return unsupported there without dereferencing them.
// WV_NO_XLIB also lets the native tests exercise that build path on Linux.
#if defined(__APPLE__) || defined(WV_NO_XLIB)
#include <vulkan/vulkan.h>
typedef struct _XDisplay Display;
typedef unsigned long Window;
typedef unsigned long VisualID;
#include <vulkan/vulkan_xlib.h>
#else
#define VK_USE_PLATFORM_XLIB_KHR
#include <vulkan/vulkan.h>
#endif

// In C, CAMetalLayer is opaque. No Objective-C/AppKit dependency is necessary
// to forward a layer that the embedding host has created and retained.
#include <vulkan/vulkan_metal.h>

VkResult wv_create_metal_surface(VkInstance, const VkMetalSurfaceCreateInfoEXT *,
                               const VkAllocationCallbacks *, VkSurfaceKHR *);
VkResult wv_create_xlib_surface(VkInstance, const VkXlibSurfaceCreateInfoKHR *,
                              const VkAllocationCallbacks *, VkSurfaceKHR *);
VkBool32 wv_xlib_presentation_support(VkPhysicalDevice, uint32_t, Display *, VisualID);
#endif
