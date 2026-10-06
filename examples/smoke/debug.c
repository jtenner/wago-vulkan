#define _GNU_SOURCE
#include <dlfcn.h>
#include "native.h"
#include <vulkan/vulkan.h>
#include <stdatomic.h>
#include <stdio.h>
static VkDebugUtilsMessengerEXT messenger;
static _Atomic unsigned errors;
static VKAPI_ATTR VkBool32 VKAPI_CALL report(VkDebugUtilsMessageSeverityFlagBitsEXT severity,
    VkDebugUtilsMessageTypeFlagsEXT type, const VkDebugUtilsMessengerCallbackDataEXT *data, void *user) {
    (void)type; (void)user;
    if (severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) atomic_fetch_add(&errors, 1);
    fprintf(stderr, "VALIDATION %s: %.160s: %.1200s\n",
        severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT ? "ERROR" : "WARNING",
        data->pMessageIdName ? data->pMessageIdName : "unknown",
        data->pMessage ? data->pMessage : "");
    return VK_FALSE;
}
int smoke_debug_start(uint64_t handle) {
    VkInstance instance = (VkInstance)(uintptr_t)handle;
    PFN_vkCreateDebugUtilsMessengerEXT create = (PFN_vkCreateDebugUtilsMessengerEXT)
        vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
    if (!create) return VK_ERROR_EXTENSION_NOT_PRESENT;
    VkDebugUtilsMessengerCreateInfoEXT ci = {0};
    ci.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
    ci.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
    ci.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
        VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
    ci.pfnUserCallback = report;
    return create(instance, &ci, NULL, &messenger);
}
void smoke_debug_stop(uint64_t handle) {
    if (!messenger) return;
    VkInstance instance = (VkInstance)(uintptr_t)handle;
    PFN_vkDestroyDebugUtilsMessengerEXT destroy = (PFN_vkDestroyDebugUtilsMessengerEXT)
        vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    if (destroy) destroy(instance, messenger, NULL);
    messenger = VK_NULL_HANDLE;
}
unsigned smoke_debug_errors(void) { return atomic_load(&errors); }

const char *smoke_loader_path(void) {
    Dl_info info = {0};
    if (dladdr((void *)(uintptr_t)vkGetInstanceProcAddr, &info) && info.dli_fname)
        return info.dli_fname;
    return "";
}
#ifndef __APPLE__
const char *smoke_moltenvk_path(void) { return ""; }
#endif
