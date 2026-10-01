(module
    (import "vulkan.gc" "vkAcquireNextImage2KHR" (func $vkAcquireNextImage2KHR (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkAcquireNextImageKHR" (func $vkAcquireNextImageKHR (param i64) (param i64) (param i64) (param i64) (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkAllocateCommandBuffers" (func $vkAllocateCommandBuffers (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkAllocateDescriptorSets" (func $vkAllocateDescriptorSets (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkAllocateMemory" (func $vkAllocateMemory (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkBeginCommandBuffer" (func $vkBeginCommandBuffer (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkBindBufferMemory" (func $vkBindBufferMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkBindImageMemory" (func $vkBindImageMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkCmdBeginQuery" (func $vkCmdBeginQuery (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdBeginRenderPass" (func $vkCmdBeginRenderPass (param i64) (param anyref) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdBindDescriptorSets" (func $vkCmdBindDescriptorSets (param i64) (param i32) (param i64) (param i32) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdBindIndexBuffer" (func $vkCmdBindIndexBuffer (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdBindPipeline" (func $vkCmdBindPipeline (param i64) (param i32) (param i64)))
    (import "vulkan.gc" "vkCmdBindVertexBuffers" (func $vkCmdBindVertexBuffers (param i64) (param i32) (param i32) (param anyref) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdBlitImage" (func $vkCmdBlitImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param anyref) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdClearAttachments" (func $vkCmdClearAttachments (param i64) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdClearColorImage" (func $vkCmdClearColorImage (param i64) (param i64) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdClearDepthStencilImage" (func $vkCmdClearDepthStencilImage (param i64) (param i64) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdCopyBuffer" (func $vkCmdCopyBuffer (param i64) (param i64) (param i64) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdCopyBufferToImage" (func $vkCmdCopyBufferToImage (param i64) (param i64) (param i64) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdCopyImage" (func $vkCmdCopyImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdCopyImageToBuffer" (func $vkCmdCopyImageToBuffer (param i64) (param i64) (param i32) (param i64) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdCopyQueryPoolResults" (func $vkCmdCopyQueryPoolResults (param i64) (param i64) (param i32) (param i32) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdDispatch" (func $vkCmdDispatch (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdDispatchIndirect" (func $vkCmdDispatchIndirect (param i64) (param i64) (param i64)))
    (import "vulkan.gc" "vkCmdDraw" (func $vkCmdDraw (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdDrawIndexed" (func $vkCmdDrawIndexed (param i64) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdDrawIndexedIndirect" (func $vkCmdDrawIndexedIndirect (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdDrawIndirect" (func $vkCmdDrawIndirect (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdEndQuery" (func $vkCmdEndQuery (param i64) (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdEndRenderPass" (func $vkCmdEndRenderPass (param i64)))
    (import "vulkan.gc" "vkCmdExecuteCommands" (func $vkCmdExecuteCommands (param i64) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdFillBuffer" (func $vkCmdFillBuffer (param i64) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdNextSubpass" (func $vkCmdNextSubpass (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdPipelineBarrier" (func $vkCmdPipelineBarrier (param i64) (param i32) (param i32) (param i32) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdPushConstants" (func $vkCmdPushConstants (param i64) (param i64) (param i32) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdResetEvent" (func $vkCmdResetEvent (param i64) (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdResetQueryPool" (func $vkCmdResetQueryPool (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdResolveImage" (func $vkCmdResolveImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdSetBlendConstants" (func $vkCmdSetBlendConstants (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdSetDepthBias" (func $vkCmdSetDepthBias (param i64) (param f32) (param f32) (param f32)))
    (import "vulkan.gc" "vkCmdSetDepthBounds" (func $vkCmdSetDepthBounds (param i64) (param f32) (param f32)))
    (import "vulkan.gc" "vkCmdSetEvent" (func $vkCmdSetEvent (param i64) (param i64) (param i32)))
    (import "vulkan.gc" "vkCmdSetLineWidth" (func $vkCmdSetLineWidth (param i64) (param f32)))
    (import "vulkan.gc" "vkCmdSetScissor" (func $vkCmdSetScissor (param i64) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdSetStencilCompareMask" (func $vkCmdSetStencilCompareMask (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdSetStencilReference" (func $vkCmdSetStencilReference (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdSetStencilWriteMask" (func $vkCmdSetStencilWriteMask (param i64) (param i32) (param i32)))
    (import "vulkan.gc" "vkCmdSetViewport" (func $vkCmdSetViewport (param i64) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdUpdateBuffer" (func $vkCmdUpdateBuffer (param i64) (param i64) (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdWaitEvents" (func $vkCmdWaitEvents (param i64) (param i32) (param anyref) (param i32) (param i32) (param i32) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkCmdWriteTimestamp" (func $vkCmdWriteTimestamp (param i64) (param i32) (param i64) (param i32)))
    (import "vulkan.gc" "vkCreateBuffer" (func $vkCreateBuffer (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateBufferView" (func $vkCreateBufferView (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateCommandPool" (func $vkCreateCommandPool (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateComputePipelines" (func $vkCreateComputePipelines (param i64) (param i64) (param i32) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateDescriptorPool" (func $vkCreateDescriptorPool (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateDescriptorSetLayout" (func $vkCreateDescriptorSetLayout (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateDevice" (func $vkCreateDevice (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateEvent" (func $vkCreateEvent (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateFence" (func $vkCreateFence (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateFramebuffer" (func $vkCreateFramebuffer (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateGraphicsPipelines" (func $vkCreateGraphicsPipelines (param i64) (param i64) (param i32) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateImage" (func $vkCreateImage (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateImageView" (func $vkCreateImageView (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateInstance" (func $vkCreateInstance (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreatePipelineCache" (func $vkCreatePipelineCache (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreatePipelineLayout" (func $vkCreatePipelineLayout (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateQueryPool" (func $vkCreateQueryPool (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateRenderPass" (func $vkCreateRenderPass (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateSampler" (func $vkCreateSampler (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateSemaphore" (func $vkCreateSemaphore (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateShaderModule" (func $vkCreateShaderModule (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateSwapchainKHR" (func $vkCreateSwapchainKHR (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkCreateXlibSurfaceKHR" (func $vkCreateXlibSurfaceKHR (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkDestroyBuffer" (func $vkDestroyBuffer (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyBufferView" (func $vkDestroyBufferView (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyCommandPool" (func $vkDestroyCommandPool (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyDescriptorPool" (func $vkDestroyDescriptorPool (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyDescriptorSetLayout" (func $vkDestroyDescriptorSetLayout (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyDevice" (func $vkDestroyDevice (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyEvent" (func $vkDestroyEvent (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyFence" (func $vkDestroyFence (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyFramebuffer" (func $vkDestroyFramebuffer (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyImage" (func $vkDestroyImage (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyImageView" (func $vkDestroyImageView (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyInstance" (func $vkDestroyInstance (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyPipeline" (func $vkDestroyPipeline (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyPipelineCache" (func $vkDestroyPipelineCache (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyPipelineLayout" (func $vkDestroyPipelineLayout (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyQueryPool" (func $vkDestroyQueryPool (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyRenderPass" (func $vkDestroyRenderPass (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroySampler" (func $vkDestroySampler (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroySemaphore" (func $vkDestroySemaphore (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroyShaderModule" (func $vkDestroyShaderModule (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroySurfaceKHR" (func $vkDestroySurfaceKHR (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDestroySwapchainKHR" (func $vkDestroySwapchainKHR (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkDeviceWaitIdle" (func $vkDeviceWaitIdle (param i64) (result i32)))
    (import "vulkan.gc" "vkEndCommandBuffer" (func $vkEndCommandBuffer (param i64) (result i32)))
    (import "vulkan.gc" "vkEnumerateDeviceExtensionProperties" (func $vkEnumerateDeviceExtensionProperties (param i64) (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkEnumerateDeviceLayerProperties" (func $vkEnumerateDeviceLayerProperties (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkEnumerateInstanceExtensionProperties" (func $vkEnumerateInstanceExtensionProperties (param anyref) (param i32) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkEnumerateInstanceLayerProperties" (func $vkEnumerateInstanceLayerProperties (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkEnumeratePhysicalDevices" (func $vkEnumeratePhysicalDevices (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkFlushMappedMemoryRanges" (func $vkFlushMappedMemoryRanges (param i64) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkFreeCommandBuffers" (func $vkFreeCommandBuffers (param i64) (param i64) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkFreeDescriptorSets" (func $vkFreeDescriptorSets (param i64) (param i64) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkFreeMemory" (func $vkFreeMemory (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetBufferMemoryRequirements" (func $vkGetBufferMemoryRequirements (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetDeviceGroupPresentCapabilitiesKHR" (func $vkGetDeviceGroupPresentCapabilitiesKHR (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetDeviceGroupSurfacePresentModesKHR" (func $vkGetDeviceGroupSurfacePresentModesKHR (param i64) (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetDeviceMemoryCommitment" (func $vkGetDeviceMemoryCommitment (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetDeviceQueue" (func $vkGetDeviceQueue (param i64) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetEventStatus" (func $vkGetEventStatus (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkGetFenceStatus" (func $vkGetFenceStatus (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkGetImageMemoryRequirements" (func $vkGetImageMemoryRequirements (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetImageSparseMemoryRequirements" (func $vkGetImageSparseMemoryRequirements (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetImageSubresourceLayout" (func $vkGetImageSubresourceLayout (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceFeatures" (func $vkGetPhysicalDeviceFeatures (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceFormatProperties" (func $vkGetPhysicalDeviceFormatProperties (param i64) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceImageFormatProperties" (func $vkGetPhysicalDeviceImageFormatProperties (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceMemoryProperties" (func $vkGetPhysicalDeviceMemoryProperties (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDevicePresentRectanglesKHR" (func $vkGetPhysicalDevicePresentRectanglesKHR (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceProperties" (func $vkGetPhysicalDeviceProperties (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceQueueFamilyProperties" (func $vkGetPhysicalDeviceQueueFamilyProperties (param i64) (param anyref) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceSparseImageFormatProperties" (func $vkGetPhysicalDeviceSparseImageFormatProperties (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param anyref) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceSurfaceCapabilitiesKHR" (func $vkGetPhysicalDeviceSurfaceCapabilitiesKHR (param i64) (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceSurfaceFormatsKHR" (func $vkGetPhysicalDeviceSurfaceFormatsKHR (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceSurfacePresentModesKHR" (func $vkGetPhysicalDeviceSurfacePresentModesKHR (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceSurfaceSupportKHR" (func $vkGetPhysicalDeviceSurfaceSupportKHR (param i64) (param i32) (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetPhysicalDeviceXlibPresentationSupportKHR" (func $vkGetPhysicalDeviceXlibPresentationSupportKHR (param i64) (param i32) (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkGetPipelineCacheData" (func $vkGetPipelineCacheData (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetQueryPoolResults" (func $vkGetQueryPoolResults (param i64) (param i64) (param i32) (param i32) (param i64) (param anyref) (param i32) (param i64) (param i32) (result i32)))
    (import "vulkan.gc" "vkGetRenderAreaGranularity" (func $vkGetRenderAreaGranularity (param i64) (param i64) (param anyref) (param i32)))
    (import "vulkan.gc" "vkGetSwapchainImagesKHR" (func $vkGetSwapchainImagesKHR (param i64) (param i64) (param anyref) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkInvalidateMappedMemoryRanges" (func $vkInvalidateMappedMemoryRanges (param i64) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkMapMemory" (func $vkMapMemory (param i64) (param i64) (param i64) (param i64) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkMergePipelineCaches" (func $vkMergePipelineCaches (param i64) (param i64) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkQueueBindSparse" (func $vkQueueBindSparse (param i64) (param i32) (param anyref) (param i32) (param i64) (result i32)))
    (import "vulkan.gc" "vkQueuePresentKHR" (func $vkQueuePresentKHR (param i64) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkQueueSubmit" (func $vkQueueSubmit (param i64) (param i32) (param anyref) (param i32) (param i64) (result i32)))
    (import "vulkan.gc" "vkQueueWaitIdle" (func $vkQueueWaitIdle (param i64) (result i32)))
    (import "vulkan.gc" "vkResetCommandBuffer" (func $vkResetCommandBuffer (param i64) (param i32) (result i32)))
    (import "vulkan.gc" "vkResetCommandPool" (func $vkResetCommandPool (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.gc" "vkResetDescriptorPool" (func $vkResetDescriptorPool (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.gc" "vkResetEvent" (func $vkResetEvent (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkResetFences" (func $vkResetFences (param i64) (param i32) (param anyref) (param i32) (result i32)))
    (import "vulkan.gc" "vkSetEvent" (func $vkSetEvent (param i64) (param i64) (result i32)))
    (import "vulkan.gc" "vkUnmapMemory" (func $vkUnmapMemory (param i64) (param i64)))
    (import "vulkan.gc" "vkUpdateDescriptorSets" (func $vkUpdateDescriptorSets (param i64) (param i32) (param anyref) (param i32) (param i32) (param anyref) (param i32)))
    (import "vulkan.gc" "vkWaitForFences" (func $vkWaitForFences (param i64) (param i32) (param anyref) (param i32) (param i32) (param i64) (result i32)))
    (import "vulkan.gc" "writeMapped" (func $writeMapped (param i64 anyref i32 i32)))
    (import "vulkan.gc" "readMapped" (func $readMapped (param i64 anyref i32 i32)))
    (import "vulkan.gc" "abiVersion" (func $abiVersion (result i32)))
    (type $words (array (mut i32)))
        (type $wide (array (mut i64)))
        (type $immutable (array i32))
        (global $arena (mut (ref null $words)) (ref.null $words))
        (func $put32 (param $a i32) (param $v i32)
          global.get $arena local.get $a i32.const 2 i32.shr_u local.get $v array.set $words)
        (func $get32 (param $a i32) (result i32)
          global.get $arena local.get $a i32.const 2 i32.shr_u array.get $words)
        (func $put64 (param $a i32) (param $v i64)
          local.get $a local.get $v i32.wrap_i64 call $put32
          local.get $a i32.const 4 i32.add local.get $v i64.const 32 i64.shr_u i32.wrap_i64 call $put32)
        (func $get64 (param $a i32) (result i64)
          local.get $a call $get32 i64.extend_i32_u
          local.get $a i32.const 4 i32.add call $get32 i64.extend_i32_u i64.const 32 i64.shl i64.or)
    (global $instance (mut i64) (i64.const 0))
    (global $physical (mut i64) (i64.const 0))
    (global $device (mut i64) (i64.const 0))
    (global $family (mut i32) (i32.const 0))
    (global $allocation (mut i64) (i64.const 0))
    (global $mapped (mut i32) (i32.const 0))
    (func $check (param $r i32) local.get $r if unreachable end)
    (func (export "version") (result i32) call $abiVersion)
    (func (export "prepare")
      i32.const 8192 array.new_default $words global.set $arena
      i32.const 256 i32.const 0 call $put32 i32.const 300 i32.const 4194304 call $put32
      i32.const 512 i32.const 1 call $put32 i32.const 536 i64.const 256 call $put64
      i32.const 1552 i32.const 1465862998 call $put32
i32.const 1556 i32.const 1599031105 call $put32
i32.const 1560 i32.const 1701736302 call $put32
i32.const 1564 i32.const 1953720696 call $put32
i32.const 1568 i32.const 1601465957 call $put32
i32.const 1572 i32.const 1702131813 call $put32
i32.const 1576 i32.const 1869181806 call $put32
i32.const 1580 i32.const 110 call $put32 i32.const 1536 i64.const 1552 call $put64)
    (func (export "badExtension") (result i32) (local $r i32)
      i32.const 560 i32.const 1 call $put32 i32.const 568 i64.const 1536 call $put64
      global.get $arena i32.const 512 ref.null any i32.const 0 global.get $arena i32.const 1024 call $vkCreateInstance local.set $r
      i32.const 560 i32.const 0 call $put32 i32.const 568 i64.const 0 call $put64
      local.get $r)
    (func (export "init") (local $i i32)
      global.get $arena i32.const 512 ref.null any i32.const 0 global.get $arena i32.const 1024 call $vkCreateInstance call $check
      i32.const 1024 call $get64 global.set $instance
      i32.const 1056 i32.const 0 call $put32 global.get $instance global.get $arena i32.const 1056 ref.null any i32.const 0 call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.const 8 i32.gt_u if unreachable end
      global.get $instance global.get $arena i32.const 1056 global.get $arena i32.const 1080 call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.eqz if unreachable end
      i32.const 1080 call $get64 global.set $physical
      i32.const 1056 i32.const 8 call $put32 global.get $physical global.get $arena i32.const 1056 global.get $arena i32.const 1200 call $vkGetPhysicalDeviceQueueFamilyProperties
      block $found loop $next
        local.get $i i32.const 24 i32.mul i32.const 1200 i32.add call $get32 i32.const 1 i32.and
        if local.get $i global.set $family br $found end
        local.get $i i32.const 1 i32.add local.tee $i
        i32.const 1056 call $get32 i32.lt_u br_if $next unreachable
      end end
      i32.const 800 i32.const 2 call $put32
      i32.const 820 global.get $family call $put32
      i32.const 824 i32.const 1 call $put32 i32.const 832 i64.const 896 call $put64 i32.const 896 i32.const 1065353216 call $put32
      i32.const 600 i32.const 3 call $put32 i32.const 620 i32.const 1 call $put32 i32.const 624 i64.const 800 call $put64
      global.get $physical global.get $arena i32.const 600 ref.null any i32.const 0 global.get $arena i32.const 1032 call $vkCreateDevice call $check
      i32.const 1032 call $get64 global.set $device)
    (func (export "query") (result i64)
      global.get $device global.get $family i32.const 0 global.get $arena i32.const 1040 call $vkGetDeviceQueue
      i32.const 1040 call $get64)
    (func (export "idle") (result i32) global.get $device call $vkDeviceWaitIdle)
    (func (export "fenceStatus") (result i32) (local $fence i64) (local $result i32)
      i32.const 1800 i32.const 8 call $put32
      global.get $device global.get $arena i32.const 1800 ref.null any i32.const 0 global.get $arena i32.const 1840 call $vkCreateFence call $check
      i32.const 1840 call $get64 local.set $fence
      global.get $device local.get $fence call $vkGetFenceStatus local.set $result
      global.get $device local.get $fence ref.null any i32.const 0 call $vkDestroyFence
      local.get $result)
    (func (export "properties") (result i32)
      global.get $physical global.get $arena i32.const 4096 call $vkGetPhysicalDeviceProperties
      i32.const 4096 call $get32)
    (func (export "mapped") (result i32) (local $i i32) (local $address i64)
      global.get $physical global.get $arena i32.const 8192 call $vkGetPhysicalDeviceMemoryProperties
      block $found loop $next
        local.get $i i32.const 8 i32.mul i32.const 8196 i32.add call $get32
        i32.const 6 i32.and i32.const 6 i32.eq br_if $found
        local.get $i i32.const 1 i32.add local.tee $i i32.const 8192 call $get32 i32.lt_u br_if $next unreachable
      end end
      i32.const 1600 i32.const 5 call $put32 i32.const 1616 i64.const 4096 call $put64
      i32.const 1624 local.get $i call $put32
      global.get $device global.get $arena i32.const 1600 ref.null any i32.const 0 global.get $arena i32.const 1704 call $vkAllocateMemory call $check
      i32.const 1704 call $get64 global.set $allocation
      global.get $device global.get $allocation i64.const 0 i64.const 4096 i32.const 0 global.get $arena i32.const 1712 call $vkMapMemory call $check
      i32.const 1 global.set $mapped
      i32.const 1712 call $get64 local.set $address
      i32.const 1728 i32.const 305419896 call $put32 i32.const 1732 i32.const -1 call $put32
      local.get $address global.get $arena i32.const 1728 i32.const 8 call $writeMapped
      local.get $address global.get $arena i32.const 1744 i32.const 8 call $readMapped
      global.get $device global.get $allocation call $vkUnmapMemory
      i32.const 0 global.set $mapped
      global.get $device global.get $allocation ref.null any i32.const 0 call $vkFreeMemory
      i64.const 0 global.set $allocation
      i32.const 1744 call $get32 i32.const 305419896 i32.eq
      i32.const 1748 call $get32 i32.const -1 i32.eq i32.and)
    (func (export "badRange")
      global.get $physical global.get $arena i32.const 32764 call $vkGetPhysicalDeviceProperties)
    (func (export "badAllocator")
      global.get $device global.get $arena i32.const 0 call $vkDestroyDevice)
    (func (export "cleanup")
      global.get $allocation i64.eqz if else
        global.get $mapped if global.get $device global.get $allocation call $vkUnmapMemory end
        global.get $device global.get $allocation ref.null any i32.const 0 call $vkFreeMemory
      end
      global.get $device i64.eqz if else global.get $device ref.null any i32.const 0 call $vkDestroyDevice end
      global.get $instance i64.eqz if else global.get $instance ref.null any i32.const 0 call $vkDestroyInstance end
      i64.const 0 global.set $device i64.const 0 global.set $instance i64.const 0 global.set $allocation)

        (func (export "badArray")
          global.get $physical i32.const 2048 array.new_default $wide i32.const 0 call $vkGetPhysicalDeviceProperties)
        (func (export "mixedBuffers")
          global.get $instance global.get $arena i32.const 1056
          i32.const 2048 array.new_default $wide i32.const 0
          call $vkEnumeratePhysicalDevices drop)
        (func (export "immutableArray")
          global.get $physical i32.const 2048 array.new_default $immutable i32.const 0 call $vkGetPhysicalDeviceProperties)
        (func (export "nullOffset")
          global.get $physical ref.null any i32.const 4 call $vkGetPhysicalDeviceProperties)
        )
