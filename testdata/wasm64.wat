(module
    (import "vulkan.wasm64" "vkAcquireNextImage2KHR" (func $vkAcquireNextImage2KHR (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkAcquireNextImageKHR" (func $vkAcquireNextImageKHR (param i64) (param i64) (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkAllocateCommandBuffers" (func $vkAllocateCommandBuffers (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkAllocateDescriptorSets" (func $vkAllocateDescriptorSets (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkAllocateMemory" (func $vkAllocateMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkBeginCommandBuffer" (func $vkBeginCommandBuffer (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkBindBufferMemory" (func $vkBindBufferMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkBindImageMemory" (func $vkBindImageMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCmdBeginQuery" (func $vkCmdBeginQuery (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdBeginRenderPass" (func $vkCmdBeginRenderPass (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdBindDescriptorSets" (func $vkCmdBindDescriptorSets (param i64) (param i32) (param i64) (param i32) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdBindIndexBuffer" (func $vkCmdBindIndexBuffer (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdBindPipeline" (func $vkCmdBindPipeline (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdBindVertexBuffers" (func $vkCmdBindVertexBuffers (param i64) (param i32) (param i32) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkCmdBlitImage" (func $vkCmdBlitImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdClearAttachments" (func $vkCmdClearAttachments (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdClearColorImage" (func $vkCmdClearColorImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdClearDepthStencilImage" (func $vkCmdClearDepthStencilImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdCopyBuffer" (func $vkCmdCopyBuffer (param i64) (param i64) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdCopyBufferToImage" (func $vkCmdCopyBufferToImage (param i64) (param i64) (param i64) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdCopyImage" (func $vkCmdCopyImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdCopyImageToBuffer" (func $vkCmdCopyImageToBuffer (param i64) (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdCopyQueryPoolResults" (func $vkCmdCopyQueryPoolResults (param i64) (param i64) (param i32) (param i32) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdDispatch" (func $vkCmdDispatch (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdDispatchIndirect" (func $vkCmdDispatchIndirect (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkCmdDraw" (func $vkCmdDraw (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdDrawIndexed" (func $vkCmdDrawIndexed (param i64) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdDrawIndexedIndirect" (func $vkCmdDrawIndexedIndirect (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdDrawIndirect" (func $vkCmdDrawIndirect (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdEndQuery" (func $vkCmdEndQuery (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdEndRenderPass" (func $vkCmdEndRenderPass (param i64)))
    (import "vulkan.wasm64" "vkCmdExecuteCommands" (func $vkCmdExecuteCommands (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdFillBuffer" (func $vkCmdFillBuffer (param i64) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdNextSubpass" (func $vkCmdNextSubpass (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdPipelineBarrier" (func $vkCmdPipelineBarrier (param i64) (param i32) (param i32) (param i32) (param i32) (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdPushConstants" (func $vkCmdPushConstants (param i64) (param i64) (param i32) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdResetEvent" (func $vkCmdResetEvent (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdResetQueryPool" (func $vkCmdResetQueryPool (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdResolveImage" (func $vkCmdResolveImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdSetBlendConstants" (func $vkCmdSetBlendConstants (param i64) (param i64)))
    (import "vulkan.wasm64" "vkCmdSetDepthBias" (func $vkCmdSetDepthBias (param i64) (param f32) (param f32) (param f32)))
    (import "vulkan.wasm64" "vkCmdSetDepthBounds" (func $vkCmdSetDepthBounds (param i64) (param f32) (param f32)))
    (import "vulkan.wasm64" "vkCmdSetEvent" (func $vkCmdSetEvent (param i64) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCmdSetLineWidth" (func $vkCmdSetLineWidth (param i64) (param f32)))
    (import "vulkan.wasm64" "vkCmdSetScissor" (func $vkCmdSetScissor (param i64) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdSetStencilCompareMask" (func $vkCmdSetStencilCompareMask (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdSetStencilReference" (func $vkCmdSetStencilReference (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdSetStencilWriteMask" (func $vkCmdSetStencilWriteMask (param i64) (param i32) (param i32)))
    (import "vulkan.wasm64" "vkCmdSetViewport" (func $vkCmdSetViewport (param i64) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdUpdateBuffer" (func $vkCmdUpdateBuffer (param i64) (param i64) (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkCmdWaitEvents" (func $vkCmdWaitEvents (param i64) (param i32) (param i64) (param i32) (param i32) (param i32) (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkCmdWriteTimestamp" (func $vkCmdWriteTimestamp (param i64) (param i32) (param i64) (param i32)))
    (import "vulkan.wasm64" "vkCreateBuffer" (func $vkCreateBuffer (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateBufferView" (func $vkCreateBufferView (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateCommandPool" (func $vkCreateCommandPool (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateComputePipelines" (func $vkCreateComputePipelines (param i64) (param i64) (param i32) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateDescriptorPool" (func $vkCreateDescriptorPool (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateDescriptorSetLayout" (func $vkCreateDescriptorSetLayout (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateDevice" (func $vkCreateDevice (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateEvent" (func $vkCreateEvent (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateFence" (func $vkCreateFence (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateFramebuffer" (func $vkCreateFramebuffer (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateGraphicsPipelines" (func $vkCreateGraphicsPipelines (param i64) (param i64) (param i32) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateImage" (func $vkCreateImage (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateImageView" (func $vkCreateImageView (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateInstance" (func $vkCreateInstance (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreatePipelineCache" (func $vkCreatePipelineCache (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreatePipelineLayout" (func $vkCreatePipelineLayout (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateQueryPool" (func $vkCreateQueryPool (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateRenderPass" (func $vkCreateRenderPass (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateSampler" (func $vkCreateSampler (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateSemaphore" (func $vkCreateSemaphore (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateShaderModule" (func $vkCreateShaderModule (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateSwapchainKHR" (func $vkCreateSwapchainKHR (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateXlibSurfaceKHR" (func $vkCreateXlibSurfaceKHR (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkDestroyBuffer" (func $vkDestroyBuffer (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyBufferView" (func $vkDestroyBufferView (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyCommandPool" (func $vkDestroyCommandPool (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyDescriptorPool" (func $vkDestroyDescriptorPool (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyDescriptorSetLayout" (func $vkDestroyDescriptorSetLayout (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyDevice" (func $vkDestroyDevice (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyEvent" (func $vkDestroyEvent (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyFence" (func $vkDestroyFence (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyFramebuffer" (func $vkDestroyFramebuffer (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyImage" (func $vkDestroyImage (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyImageView" (func $vkDestroyImageView (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyInstance" (func $vkDestroyInstance (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyPipeline" (func $vkDestroyPipeline (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyPipelineCache" (func $vkDestroyPipelineCache (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyPipelineLayout" (func $vkDestroyPipelineLayout (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyQueryPool" (func $vkDestroyQueryPool (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyRenderPass" (func $vkDestroyRenderPass (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroySampler" (func $vkDestroySampler (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroySemaphore" (func $vkDestroySemaphore (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroyShaderModule" (func $vkDestroyShaderModule (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroySurfaceKHR" (func $vkDestroySurfaceKHR (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDestroySwapchainKHR" (func $vkDestroySwapchainKHR (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkDeviceWaitIdle" (func $vkDeviceWaitIdle (param i64) (result i32)))
    (import "vulkan.wasm64" "vkEndCommandBuffer" (func $vkEndCommandBuffer (param i64) (result i32)))
    (import "vulkan.wasm64" "vkEnumerateDeviceExtensionProperties" (func $vkEnumerateDeviceExtensionProperties (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkEnumerateDeviceLayerProperties" (func $vkEnumerateDeviceLayerProperties (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkEnumerateInstanceExtensionProperties" (func $vkEnumerateInstanceExtensionProperties (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkEnumerateInstanceLayerProperties" (func $vkEnumerateInstanceLayerProperties (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkEnumeratePhysicalDevices" (func $vkEnumeratePhysicalDevices (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkFlushMappedMemoryRanges" (func $vkFlushMappedMemoryRanges (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkFreeCommandBuffers" (func $vkFreeCommandBuffers (param i64) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkFreeDescriptorSets" (func $vkFreeDescriptorSets (param i64) (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkFreeMemory" (func $vkFreeMemory (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetBufferMemoryRequirements" (func $vkGetBufferMemoryRequirements (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetDeviceGroupPresentCapabilitiesKHR" (func $vkGetDeviceGroupPresentCapabilitiesKHR (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetDeviceGroupSurfacePresentModesKHR" (func $vkGetDeviceGroupSurfacePresentModesKHR (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetDeviceMemoryCommitment" (func $vkGetDeviceMemoryCommitment (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetDeviceQueue" (func $vkGetDeviceQueue (param i64) (param i32) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkGetEventStatus" (func $vkGetEventStatus (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetFenceStatus" (func $vkGetFenceStatus (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetImageMemoryRequirements" (func $vkGetImageMemoryRequirements (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetImageSparseMemoryRequirements" (func $vkGetImageSparseMemoryRequirements (param i64) (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetImageSubresourceLayout" (func $vkGetImageSubresourceLayout (param i64) (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceFeatures" (func $vkGetPhysicalDeviceFeatures (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceFormatProperties" (func $vkGetPhysicalDeviceFormatProperties (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceImageFormatProperties" (func $vkGetPhysicalDeviceImageFormatProperties (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceMemoryProperties" (func $vkGetPhysicalDeviceMemoryProperties (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDevicePresentRectanglesKHR" (func $vkGetPhysicalDevicePresentRectanglesKHR (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceProperties" (func $vkGetPhysicalDeviceProperties (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceQueueFamilyProperties" (func $vkGetPhysicalDeviceQueueFamilyProperties (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceSparseImageFormatProperties" (func $vkGetPhysicalDeviceSparseImageFormatProperties (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceSurfaceCapabilitiesKHR" (func $vkGetPhysicalDeviceSurfaceCapabilitiesKHR (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceSurfaceFormatsKHR" (func $vkGetPhysicalDeviceSurfaceFormatsKHR (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceSurfacePresentModesKHR" (func $vkGetPhysicalDeviceSurfacePresentModesKHR (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceSurfaceSupportKHR" (func $vkGetPhysicalDeviceSurfaceSupportKHR (param i64) (param i32) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceXlibPresentationSupportKHR" (func $vkGetPhysicalDeviceXlibPresentationSupportKHR (param i64) (param i32) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetPipelineCacheData" (func $vkGetPipelineCacheData (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkGetQueryPoolResults" (func $vkGetQueryPoolResults (param i64) (param i64) (param i32) (param i32) (param i64) (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm64" "vkGetRenderAreaGranularity" (func $vkGetRenderAreaGranularity (param i64) (param i64) (param i64)))
    (import "vulkan.wasm64" "vkGetSwapchainImagesKHR" (func $vkGetSwapchainImagesKHR (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkInvalidateMappedMemoryRanges" (func $vkInvalidateMappedMemoryRanges (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkMapMemory" (func $vkMapMemory (param i64) (param i64) (param i64) (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkMergePipelineCaches" (func $vkMergePipelineCaches (param i64) (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkQueueBindSparse" (func $vkQueueBindSparse (param i64) (param i32) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkQueuePresentKHR" (func $vkQueuePresentKHR (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkQueueSubmit" (func $vkQueueSubmit (param i64) (param i32) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkQueueWaitIdle" (func $vkQueueWaitIdle (param i64) (result i32)))
    (import "vulkan.wasm64" "vkResetCommandBuffer" (func $vkResetCommandBuffer (param i64) (param i32) (result i32)))
    (import "vulkan.wasm64" "vkResetCommandPool" (func $vkResetCommandPool (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm64" "vkResetDescriptorPool" (func $vkResetDescriptorPool (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm64" "vkResetEvent" (func $vkResetEvent (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkResetFences" (func $vkResetFences (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkSetEvent" (func $vkSetEvent (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkUnmapMemory" (func $vkUnmapMemory (param i64) (param i64)))
    (import "vulkan.wasm64" "vkUpdateDescriptorSets" (func $vkUpdateDescriptorSets (param i64) (param i32) (param i64) (param i32) (param i64)))
    (import "vulkan.wasm64" "vkWaitForFences" (func $vkWaitForFences (param i64) (param i32) (param i64) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm64" "vkCreateMetalSurfaceEXT" (func $vkCreateMetalSurfaceEXT (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm64" "writeMapped" (func $writeMapped (param i64 i64 i64)))
    (import "vulkan.wasm64" "readMapped" (func $readMapped (param i64 i64 i64)))
    (import "vulkan.wasm64" "abiVersion" (func $abiVersion (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceProperties" (func $wrongWidth (param i64 i32)))
    (memory i64 4)
        (func $put32 (param $a i32) (param $v i32) local.get $a i64.extend_i32_u local.get $v i32.store)
        (func $get32 (param $a i32) (result i32) local.get $a i64.extend_i32_u i32.load)
        (func $put64 (param $a i32) (param $v i64) local.get $a i64.extend_i32_u local.get $v i64.store)
        (func $get64 (param $a i32) (result i64) local.get $a i64.extend_i32_u i64.load)
    (global $instance (mut i64) (i64.const 0))
    (global $physical (mut i64) (i64.const 0))
    (global $device (mut i64) (i64.const 0))
    (global $family (mut i32) (i32.const 0))
    (global $allocation (mut i64) (i64.const 0))
    (global $mapped (mut i32) (i32.const 0))
    (func $check (param $r i32) local.get $r if unreachable end)
    (func $get8 (param $a i32) (result i32)
      local.get $a i32.const -4 i32.and call $get32
      local.get $a i32.const 3 i32.and i32.const 8 i32.mul i32.shr_u i32.const 255 i32.and)
    (func $sameName (param $a i32) (param $b i32) (result i32) (local $i i32) (local $v i32)
      loop $next
        local.get $a local.get $i i32.add call $get8 local.tee $v
        local.get $b local.get $i i32.add call $get8 i32.ne if i32.const 0 return end
        local.get $v i32.eqz if i32.const 1 return end
        local.get $i i32.const 1 i32.add local.tee $i i32.const 256 i32.lt_u br_if $next
      end i32.const 0)
    (func $hasExtension (param $name i32) (result i32) (local $i i32)
      block $done loop $next
        local.get $i i32.const 1064 call $get32 i32.ge_u br_if $done
        local.get $i i32.const 260 i32.mul i32.const 16384 i32.add local.get $name call $sameName
        if i32.const 1 return end
        local.get $i i32.const 1 i32.add local.set $i br $next
      end end i32.const 0)
    (func $enableInstanceExtensions (local $n i32)
      i32.const 528 i32.const 0 call $put32
      i32.const 2048 call $hasExtension if
        i32.const 528 i32.const 1 call $put32 ;; VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR
        i32.const 3072 i64.const 2048 call $put64 i32.const 1 local.set $n
      end
      i32.const 2112 call $hasExtension if
        i32.const 3072 local.get $n i32.const 8 i32.mul i32.add
        i64.const 2112 call $put64
        local.get $n i32.const 1 i32.add local.set $n
      end
      i32.const 560 local.get $n call $put32
      i32.const 568 i64.const 3072 call $put64)
    (func $instanceExtensions
      ;; Bounded fixture storage: 512 VkExtensionProperties records, 260 bytes each.
      i32.const 1064 i32.const 512 call $put32 i64.const 0 i64.const 1064 i64.const 16384 call $vkEnumerateInstanceExtensionProperties call $check
      call $enableInstanceExtensions)
    (func $enableDeviceExtensions
      i32.const 648 i32.const 0 call $put32 i32.const 656 i64.const 0 call $put64
      i32.const 2176 call $hasExtension if
        i32.const 3136 i64.const 2176 call $put64 i32.const 648 i32.const 1 call $put32
        i32.const 656 i64.const 3136 call $put64
      end)
    (func $deviceExtensions
      i32.const 1064 i32.const 512 call $put32 global.get $physical i64.const 0 i64.const 1064 i64.const 16384 call $vkEnumerateDeviceExtensionProperties call $check
      call $enableDeviceExtensions)
    (func (export "extensionMatching") (result i32)
      i32.const 1064 i32.const 0 call $put32 i32.const 2176 call $hasExtension i32.eqz
      i32.const 1064 i32.const 1 call $put32 i32.const 2176 call $hasExtension i32.eqz i32.and
      i32.const 1064 i32.const 2 call $put32 i32.const 2176 call $hasExtension i32.and
      i32.const 2048 call $hasExtension i32.eqz i32.and)
    (func $expect32 (param $address i32) (param $value i32)
      local.get $address call $get32 local.get $value i32.ne if unreachable end)
    (func (export "extensionNegotiation")
      i32.const 1064 i32.const 0 call $put32 call $enableInstanceExtensions call $enableDeviceExtensions
      i32.const 528 i32.const 0 call $expect32
      i32.const 560 i32.const 0 call $expect32
      i32.const 648 i32.const 0 call $expect32
      i32.const 16384 i32.const 1264536406 call $put32
i32.const 16388 i32.const 1734300232 call $put32
i32.const 16392 i32.const 1885303909 call $put32
i32.const 16396 i32.const 1769175400 call $put32
i32.const 16400 i32.const 1600938339 call $put32
i32.const 16404 i32.const 1769366884 call $put32
i32.const 16408 i32.const 1885300067 call $put32
i32.const 16412 i32.const 1701867378 call $put32
i32.const 16416 i32.const 1701409906 call $put32
i32.const 16420 i32.const 12915 call $put32
      i32.const 1064 i32.const 1 call $put32 call $enableInstanceExtensions
      i32.const 528 i32.const 0 call $expect32
      i32.const 560 i32.const 1 call $expect32
      i32.const 3072 i32.const 2112 call $expect32
      i32.const 16384 i32.const 1264536406 call $put32
i32.const 16388 i32.const 1885295176 call $put32
i32.const 16392 i32.const 1635021423 call $put32
i32.const 16396 i32.const 1768712546 call $put32
i32.const 16400 i32.const 1700755828 call $put32
i32.const 16404 i32.const 1701672302 call $put32
i32.const 16408 i32.const 1769234802 call $put32
i32.const 16412 i32.const 28271 call $put32 call $enableInstanceExtensions
      i32.const 528 i32.const 1 call $expect32
      i32.const 560 i32.const 1 call $expect32
      i32.const 3072 i32.const 2048 call $expect32
      i32.const 16644 i32.const 1264536406 call $put32
i32.const 16648 i32.const 1734300232 call $put32
i32.const 16652 i32.const 1885303909 call $put32
i32.const 16656 i32.const 1769175400 call $put32
i32.const 16660 i32.const 1600938339 call $put32
i32.const 16664 i32.const 1769366884 call $put32
i32.const 16668 i32.const 1885300067 call $put32
i32.const 16672 i32.const 1701867378 call $put32
i32.const 16676 i32.const 1701409906 call $put32
i32.const 16680 i32.const 12915 call $put32
      i32.const 1064 i32.const 2 call $put32 call $enableInstanceExtensions
      i32.const 528 i32.const 1 call $expect32
      i32.const 560 i32.const 2 call $expect32
      i32.const 568 i32.const 3072 call $expect32
      i32.const 3072 i32.const 2048 call $expect32
      i32.const 3080 i32.const 2112 call $expect32
      i32.const 16384 i32.const 1264536406 call $put32
i32.const 16388 i32.const 1885295176 call $put32
i32.const 16392 i32.const 1635021423 call $put32
i32.const 16396 i32.const 1768712546 call $put32
i32.const 16400 i32.const 1935636852 call $put32
i32.const 16404 i32.const 1702060661 call $put32
i32.const 16408 i32.const 116 call $put32
      i32.const 1064 i32.const 1 call $put32 call $enableDeviceExtensions
      i32.const 648 i32.const 1 call $expect32
      i32.const 656 i32.const 3136 call $expect32
      i32.const 3136 i32.const 2176 call $expect32
      ;; Reusing the helper must remove stale flags/extensions as well.
      i32.const 1064 i32.const 0 call $put32 call $enableInstanceExtensions call $enableDeviceExtensions
      i32.const 528 i32.const 0 call $expect32
      i32.const 560 i32.const 0 call $expect32
      i32.const 648 i32.const 0 call $expect32
      i32.const 656 i32.const 0 call $expect32)
    (func (export "version") (result i32) call $abiVersion)
    (func (export "prepare")

      i32.const 256 i32.const 0 call $put32 i32.const 300 i32.const 4194304 call $put32
      i32.const 512 i32.const 1 call $put32 i32.const 536 i64.const 256 call $put64
      i32.const 1552 i32.const 1465862998 call $put32
i32.const 1556 i32.const 1599031105 call $put32
i32.const 1560 i32.const 1701736302 call $put32
i32.const 1564 i32.const 1953720696 call $put32
i32.const 1568 i32.const 1601465957 call $put32
i32.const 1572 i32.const 1702131813 call $put32
i32.const 1576 i32.const 1869181806 call $put32
i32.const 1580 i32.const 110 call $put32
i32.const 2048 i32.const 1264536406 call $put32
i32.const 2052 i32.const 1885295176 call $put32
i32.const 2056 i32.const 1635021423 call $put32
i32.const 2060 i32.const 1768712546 call $put32
i32.const 2064 i32.const 1700755828 call $put32
i32.const 2068 i32.const 1701672302 call $put32
i32.const 2072 i32.const 1769234802 call $put32
i32.const 2076 i32.const 28271 call $put32
i32.const 2112 i32.const 1264536406 call $put32
i32.const 2116 i32.const 1734300232 call $put32
i32.const 2120 i32.const 1885303909 call $put32
i32.const 2124 i32.const 1769175400 call $put32
i32.const 2128 i32.const 1600938339 call $put32
i32.const 2132 i32.const 1769366884 call $put32
i32.const 2136 i32.const 1885300067 call $put32
i32.const 2140 i32.const 1701867378 call $put32
i32.const 2144 i32.const 1701409906 call $put32
i32.const 2148 i32.const 12915 call $put32
i32.const 2176 i32.const 1264536406 call $put32
i32.const 2180 i32.const 1885295176 call $put32
i32.const 2184 i32.const 1635021423 call $put32
i32.const 2188 i32.const 1768712546 call $put32
i32.const 2192 i32.const 1935636852 call $put32
i32.const 2196 i32.const 1702060661 call $put32
i32.const 2200 i32.const 116 call $put32
i32.const 16384 i32.const 1264536406 call $put32
i32.const 16388 i32.const 1885295176 call $put32
i32.const 16392 i32.const 1635021423 call $put32
i32.const 16396 i32.const 1768712546 call $put32
i32.const 16400 i32.const 1935636852 call $put32
i32.const 16404 i32.const 1702060661 call $put32
i32.const 16408 i32.const 2019909492 call $put32
i32.const 16412 i32.const 6386292 call $put32
i32.const 16644 i32.const 1264536406 call $put32
i32.const 16648 i32.const 1885295176 call $put32
i32.const 16652 i32.const 1635021423 call $put32
i32.const 16656 i32.const 1768712546 call $put32
i32.const 16660 i32.const 1935636852 call $put32
i32.const 16664 i32.const 1702060661 call $put32
i32.const 16668 i32.const 116 call $put32 i32.const 1536 i64.const 1552 call $put64)
    (func (export "badExtension") (result i32) (local $r i32)
      i32.const 560 i32.const 1 call $put32 i32.const 568 i64.const 1536 call $put64
      i64.const 512 i64.const 0 i64.const 1024 call $vkCreateInstance local.set $r
      i32.const 560 i32.const 0 call $put32 i32.const 568 i64.const 0 call $put64
      local.get $r)
    (func (export "badPortableExtension") (result i32) (local $n i32) (local $r i32)
      call $instanceExtensions
      i32.const 560 call $get32 local.set $n
      i32.const 3072 local.get $n i32.const 8 i32.mul i32.add
      i64.const 1552 call $put64
      i32.const 560 local.get $n i32.const 1 i32.add call $put32
      i64.const 512 i64.const 0 i64.const 1024 call $vkCreateInstance local.set $r
      i32.const 560 local.get $n call $put32
      local.get $r)
    (func (export "init") (local $i i32)
      call $instanceExtensions
      i64.const 512 i64.const 0 i64.const 1024 call $vkCreateInstance call $check
      i32.const 1024 call $get64 global.set $instance
      i32.const 1056 i32.const 0 call $put32 global.get $instance i64.const 1056 i64.const 0 call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.const 8 i32.gt_u if unreachable end
      global.get $instance i64.const 1056 i64.const 1080 call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.eqz if unreachable end
      i32.const 1080 call $get64 global.set $physical
      i32.const 1056 i32.const 8 call $put32 global.get $physical i64.const 1056 i64.const 1200 call $vkGetPhysicalDeviceQueueFamilyProperties
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
      call $deviceExtensions
      global.get $physical i64.const 600 i64.const 0 i64.const 1032 call $vkCreateDevice call $check
      i32.const 1032 call $get64 global.set $device)
    (func (export "query") (result i64)
      global.get $device global.get $family i32.const 0 i64.const 1040 call $vkGetDeviceQueue
      i32.const 1040 call $get64)
    (func (export "idle") (result i32) global.get $device call $vkDeviceWaitIdle)
    (func (export "fenceStatus") (result i32) (local $fence i64) (local $result i32)
      i32.const 1800 i32.const 8 call $put32
      global.get $device i64.const 1800 i64.const 0 i64.const 1840 call $vkCreateFence call $check
      i32.const 1840 call $get64 local.set $fence
      global.get $device local.get $fence call $vkGetFenceStatus local.set $result
      global.get $device local.get $fence i64.const 0 call $vkDestroyFence
      local.get $result)
    (func (export "properties") (result i32)
      global.get $physical i64.const 4096 call $vkGetPhysicalDeviceProperties
      i32.const 4096 call $get32)
    (func (export "mapped") (result i32) (local $i i32) (local $address i64)
      global.get $physical i64.const 8192 call $vkGetPhysicalDeviceMemoryProperties
      block $found loop $next
        local.get $i i32.const 8 i32.mul i32.const 8196 i32.add call $get32
        i32.const 6 i32.and i32.const 6 i32.eq br_if $found
        local.get $i i32.const 1 i32.add local.tee $i i32.const 8192 call $get32 i32.lt_u br_if $next unreachable
      end end
      i32.const 1600 i32.const 5 call $put32 i32.const 1616 i64.const 4096 call $put64
      i32.const 1624 local.get $i call $put32
      global.get $device i64.const 1600 i64.const 0 i64.const 1704 call $vkAllocateMemory call $check
      i32.const 1704 call $get64 global.set $allocation
      global.get $device global.get $allocation i64.const 0 i64.const 4096 i32.const 0 i64.const 1712 call $vkMapMemory call $check
      i32.const 1 global.set $mapped
      i32.const 1712 call $get64 local.set $address
      i32.const 1728 i32.const 305419896 call $put32 i32.const 1732 i32.const -1 call $put32
      local.get $address i64.const 1728 i64.const 8 call $writeMapped
      local.get $address i64.const 1744 i64.const 8 call $readMapped
      global.get $device global.get $allocation call $vkUnmapMemory
      i32.const 0 global.set $mapped
      global.get $device global.get $allocation i64.const 0 call $vkFreeMemory
      i64.const 0 global.set $allocation
      i32.const 1744 call $get32 i32.const 305419896 i32.eq
      i32.const 1748 call $get32 i32.const -1 i32.eq i32.and)
    (func (export "badRange")
      global.get $physical i64.const 262140 call $vkGetPhysicalDeviceProperties)
    (func (export "badAllocator")
      global.get $device i64.const 123 call $vkDestroyDevice)
    (func (export "cleanup")
      global.get $allocation i64.eqz if else
        global.get $mapped if global.get $device global.get $allocation call $vkUnmapMemory end
        global.get $device global.get $allocation i64.const 0 call $vkFreeMemory
      end
      global.get $device i64.eqz if else global.get $device i64.const 0 call $vkDestroyDevice end
      global.get $instance i64.eqz if else global.get $instance i64.const 0 call $vkDestroyInstance end
      i64.const 0 global.set $device i64.const 0 global.set $instance i64.const 0 global.set $allocation)

        (func (export "wrongWidth")
          global.get $physical i32.const 4096 call $wrongWidth)
        )
