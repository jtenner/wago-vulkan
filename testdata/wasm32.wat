(module
    (import "vulkan.wasm32" "vkAcquireNextImage2KHR" (func $vkAcquireNextImage2KHR (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkAcquireNextImageKHR" (func $vkAcquireNextImageKHR (param i64) (param i64) (param i64) (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkAllocateCommandBuffers" (func $vkAllocateCommandBuffers (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkAllocateDescriptorSets" (func $vkAllocateDescriptorSets (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkAllocateMemory" (func $vkAllocateMemory (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkBeginCommandBuffer" (func $vkBeginCommandBuffer (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkBindBufferMemory" (func $vkBindBufferMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkBindImageMemory" (func $vkBindImageMemory (param i64) (param i64) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkCmdBeginQuery" (func $vkCmdBeginQuery (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdBeginRenderPass" (func $vkCmdBeginRenderPass (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdBindDescriptorSets" (func $vkCmdBindDescriptorSets (param i64) (param i32) (param i64) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdBindIndexBuffer" (func $vkCmdBindIndexBuffer (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdBindPipeline" (func $vkCmdBindPipeline (param i64) (param i32) (param i64)))
    (import "vulkan.wasm32" "vkCmdBindVertexBuffers" (func $vkCmdBindVertexBuffers (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdBlitImage" (func $vkCmdBlitImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdClearAttachments" (func $vkCmdClearAttachments (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdClearColorImage" (func $vkCmdClearColorImage (param i64) (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdClearDepthStencilImage" (func $vkCmdClearDepthStencilImage (param i64) (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdCopyBuffer" (func $vkCmdCopyBuffer (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdCopyBufferToImage" (func $vkCmdCopyBufferToImage (param i64) (param i64) (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdCopyImage" (func $vkCmdCopyImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdCopyImageToBuffer" (func $vkCmdCopyImageToBuffer (param i64) (param i64) (param i32) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdCopyQueryPoolResults" (func $vkCmdCopyQueryPoolResults (param i64) (param i64) (param i32) (param i32) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdDispatch" (func $vkCmdDispatch (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdDispatchIndirect" (func $vkCmdDispatchIndirect (param i64) (param i64) (param i64)))
    (import "vulkan.wasm32" "vkCmdDraw" (func $vkCmdDraw (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdDrawIndexed" (func $vkCmdDrawIndexed (param i64) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdDrawIndexedIndirect" (func $vkCmdDrawIndexedIndirect (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdDrawIndirect" (func $vkCmdDrawIndirect (param i64) (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdEndQuery" (func $vkCmdEndQuery (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdEndRenderPass" (func $vkCmdEndRenderPass (param i64)))
    (import "vulkan.wasm32" "vkCmdExecuteCommands" (func $vkCmdExecuteCommands (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdFillBuffer" (func $vkCmdFillBuffer (param i64) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdNextSubpass" (func $vkCmdNextSubpass (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdPipelineBarrier" (func $vkCmdPipelineBarrier (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdPushConstants" (func $vkCmdPushConstants (param i64) (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdResetEvent" (func $vkCmdResetEvent (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdResetQueryPool" (func $vkCmdResetQueryPool (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdResolveImage" (func $vkCmdResolveImage (param i64) (param i64) (param i32) (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetBlendConstants" (func $vkCmdSetBlendConstants (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetDepthBias" (func $vkCmdSetDepthBias (param i64) (param f32) (param f32) (param f32)))
    (import "vulkan.wasm32" "vkCmdSetDepthBounds" (func $vkCmdSetDepthBounds (param i64) (param f32) (param f32)))
    (import "vulkan.wasm32" "vkCmdSetEvent" (func $vkCmdSetEvent (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetLineWidth" (func $vkCmdSetLineWidth (param i64) (param f32)))
    (import "vulkan.wasm32" "vkCmdSetScissor" (func $vkCmdSetScissor (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetStencilCompareMask" (func $vkCmdSetStencilCompareMask (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetStencilReference" (func $vkCmdSetStencilReference (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetStencilWriteMask" (func $vkCmdSetStencilWriteMask (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdSetViewport" (func $vkCmdSetViewport (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdUpdateBuffer" (func $vkCmdUpdateBuffer (param i64) (param i64) (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCmdWaitEvents" (func $vkCmdWaitEvents (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkCmdWriteTimestamp" (func $vkCmdWriteTimestamp (param i64) (param i32) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkCreateBuffer" (func $vkCreateBuffer (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateBufferView" (func $vkCreateBufferView (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateCommandPool" (func $vkCreateCommandPool (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateComputePipelines" (func $vkCreateComputePipelines (param i64) (param i64) (param i32) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateDescriptorPool" (func $vkCreateDescriptorPool (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateDescriptorSetLayout" (func $vkCreateDescriptorSetLayout (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateDevice" (func $vkCreateDevice (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateEvent" (func $vkCreateEvent (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateFence" (func $vkCreateFence (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateFramebuffer" (func $vkCreateFramebuffer (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateGraphicsPipelines" (func $vkCreateGraphicsPipelines (param i64) (param i64) (param i32) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateImage" (func $vkCreateImage (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateImageView" (func $vkCreateImageView (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateInstance" (func $vkCreateInstance (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreatePipelineCache" (func $vkCreatePipelineCache (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreatePipelineLayout" (func $vkCreatePipelineLayout (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateQueryPool" (func $vkCreateQueryPool (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateRenderPass" (func $vkCreateRenderPass (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateSampler" (func $vkCreateSampler (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateSemaphore" (func $vkCreateSemaphore (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateShaderModule" (func $vkCreateShaderModule (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateSwapchainKHR" (func $vkCreateSwapchainKHR (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkCreateXlibSurfaceKHR" (func $vkCreateXlibSurfaceKHR (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkDestroyBuffer" (func $vkDestroyBuffer (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyBufferView" (func $vkDestroyBufferView (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyCommandPool" (func $vkDestroyCommandPool (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyDescriptorPool" (func $vkDestroyDescriptorPool (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyDescriptorSetLayout" (func $vkDestroyDescriptorSetLayout (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyDevice" (func $vkDestroyDevice (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyEvent" (func $vkDestroyEvent (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyFence" (func $vkDestroyFence (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyFramebuffer" (func $vkDestroyFramebuffer (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyImage" (func $vkDestroyImage (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyImageView" (func $vkDestroyImageView (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyInstance" (func $vkDestroyInstance (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyPipeline" (func $vkDestroyPipeline (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyPipelineCache" (func $vkDestroyPipelineCache (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyPipelineLayout" (func $vkDestroyPipelineLayout (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyQueryPool" (func $vkDestroyQueryPool (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyRenderPass" (func $vkDestroyRenderPass (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroySampler" (func $vkDestroySampler (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroySemaphore" (func $vkDestroySemaphore (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroyShaderModule" (func $vkDestroyShaderModule (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroySurfaceKHR" (func $vkDestroySurfaceKHR (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDestroySwapchainKHR" (func $vkDestroySwapchainKHR (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkDeviceWaitIdle" (func $vkDeviceWaitIdle (param i64) (result i32)))
    (import "vulkan.wasm32" "vkEndCommandBuffer" (func $vkEndCommandBuffer (param i64) (result i32)))
    (import "vulkan.wasm32" "vkEnumerateDeviceExtensionProperties" (func $vkEnumerateDeviceExtensionProperties (param i64) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkEnumerateDeviceLayerProperties" (func $vkEnumerateDeviceLayerProperties (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkEnumerateInstanceExtensionProperties" (func $vkEnumerateInstanceExtensionProperties (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkEnumerateInstanceLayerProperties" (func $vkEnumerateInstanceLayerProperties (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkEnumeratePhysicalDevices" (func $vkEnumeratePhysicalDevices (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkFlushMappedMemoryRanges" (func $vkFlushMappedMemoryRanges (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkFreeCommandBuffers" (func $vkFreeCommandBuffers (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkFreeDescriptorSets" (func $vkFreeDescriptorSets (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkFreeMemory" (func $vkFreeMemory (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetBufferMemoryRequirements" (func $vkGetBufferMemoryRequirements (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetDeviceGroupPresentCapabilitiesKHR" (func $vkGetDeviceGroupPresentCapabilitiesKHR (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetDeviceGroupSurfacePresentModesKHR" (func $vkGetDeviceGroupSurfacePresentModesKHR (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetDeviceMemoryCommitment" (func $vkGetDeviceMemoryCommitment (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetDeviceQueue" (func $vkGetDeviceQueue (param i64) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkGetEventStatus" (func $vkGetEventStatus (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkGetFenceStatus" (func $vkGetFenceStatus (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkGetImageMemoryRequirements" (func $vkGetImageMemoryRequirements (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetImageSparseMemoryRequirements" (func $vkGetImageSparseMemoryRequirements (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkGetImageSubresourceLayout" (func $vkGetImageSubresourceLayout (param i64) (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceFeatures" (func $vkGetPhysicalDeviceFeatures (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceFormatProperties" (func $vkGetPhysicalDeviceFormatProperties (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceImageFormatProperties" (func $vkGetPhysicalDeviceImageFormatProperties (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceMemoryProperties" (func $vkGetPhysicalDeviceMemoryProperties (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDevicePresentRectanglesKHR" (func $vkGetPhysicalDevicePresentRectanglesKHR (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceProperties" (func $vkGetPhysicalDeviceProperties (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceQueueFamilyProperties" (func $vkGetPhysicalDeviceQueueFamilyProperties (param i64) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceSparseImageFormatProperties" (func $vkGetPhysicalDeviceSparseImageFormatProperties (param i64) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceSurfaceCapabilitiesKHR" (func $vkGetPhysicalDeviceSurfaceCapabilitiesKHR (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceSurfaceFormatsKHR" (func $vkGetPhysicalDeviceSurfaceFormatsKHR (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceSurfacePresentModesKHR" (func $vkGetPhysicalDeviceSurfacePresentModesKHR (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceSurfaceSupportKHR" (func $vkGetPhysicalDeviceSurfaceSupportKHR (param i64) (param i32) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetPhysicalDeviceXlibPresentationSupportKHR" (func $vkGetPhysicalDeviceXlibPresentationSupportKHR (param i64) (param i32) (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkGetPipelineCacheData" (func $vkGetPipelineCacheData (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetQueryPoolResults" (func $vkGetQueryPoolResults (param i64) (param i64) (param i32) (param i32) (param i32) (param i32) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkGetRenderAreaGranularity" (func $vkGetRenderAreaGranularity (param i64) (param i64) (param i32)))
    (import "vulkan.wasm32" "vkGetSwapchainImagesKHR" (func $vkGetSwapchainImagesKHR (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkInvalidateMappedMemoryRanges" (func $vkInvalidateMappedMemoryRanges (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkMapMemory" (func $vkMapMemory (param i64) (param i64) (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkMergePipelineCaches" (func $vkMergePipelineCaches (param i64) (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkQueueBindSparse" (func $vkQueueBindSparse (param i64) (param i32) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkQueuePresentKHR" (func $vkQueuePresentKHR (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkQueueSubmit" (func $vkQueueSubmit (param i64) (param i32) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkQueueWaitIdle" (func $vkQueueWaitIdle (param i64) (result i32)))
    (import "vulkan.wasm32" "vkResetCommandBuffer" (func $vkResetCommandBuffer (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkResetCommandPool" (func $vkResetCommandPool (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkResetDescriptorPool" (func $vkResetDescriptorPool (param i64) (param i64) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkResetEvent" (func $vkResetEvent (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkResetFences" (func $vkResetFences (param i64) (param i32) (param i32) (result i32)))
    (import "vulkan.wasm32" "vkSetEvent" (func $vkSetEvent (param i64) (param i64) (result i32)))
    (import "vulkan.wasm32" "vkUnmapMemory" (func $vkUnmapMemory (param i64) (param i64)))
    (import "vulkan.wasm32" "vkUpdateDescriptorSets" (func $vkUpdateDescriptorSets (param i64) (param i32) (param i32) (param i32) (param i32)))
    (import "vulkan.wasm32" "vkWaitForFences" (func $vkWaitForFences (param i64) (param i32) (param i32) (param i32) (param i64) (result i32)))
    (import "vulkan.wasm32" "writeMapped" (func $writeMapped (param i64 i32 i32)))
    (import "vulkan.wasm32" "readMapped" (func $readMapped (param i64 i32 i32)))
    (import "vulkan.wasm32" "abiVersion" (func $abiVersion (result i32)))
    (import "vulkan.wasm64" "vkGetPhysicalDeviceProperties" (func $wrongWidth (param i64 i64)))
    (memory 1)
        (func $put32 (param $a i32) (param $v i32) local.get $a  local.get $v i32.store)
        (func $get32 (param $a i32) (result i32) local.get $a  i32.load)
        (func $put64 (param $a i32) (param $v i64) local.get $a  local.get $v i64.store)
        (func $get64 (param $a i32) (result i64) local.get $a  i64.load)
    (global $instance (mut i64) (i64.const 0))
    (global $physical (mut i64) (i64.const 0))
    (global $device (mut i64) (i64.const 0))
    (global $family (mut i32) (i32.const 0))
    (global $allocation (mut i64) (i64.const 0))
    (global $mapped (mut i32) (i32.const 0))
    (func $check (param $r i32) local.get $r if unreachable end)
    (func (export "version") (result i32) call $abiVersion)
    (func (export "prepare")

      i32.const 256 i32.const 0 call $put32 i32.const 280 i32.const 4194304 call $put32
      i32.const 512 i32.const 1 call $put32 i32.const 524 i32.const 256 call $put32
      i32.const 1552 i32.const 1465862998 call $put32
i32.const 1556 i32.const 1599031105 call $put32
i32.const 1560 i32.const 1701736302 call $put32
i32.const 1564 i32.const 1953720696 call $put32
i32.const 1568 i32.const 1601465957 call $put32
i32.const 1572 i32.const 1702131813 call $put32
i32.const 1576 i32.const 1869181806 call $put32
i32.const 1580 i32.const 110 call $put32 i32.const 1536 i32.const 1552 call $put32)
    (func (export "badExtension") (result i32) (local $r i32)
      i32.const 536 i32.const 1 call $put32 i32.const 540 i32.const 1536 call $put32
      i32.const 512 i32.const 0 i32.const 1024 call $vkCreateInstance local.set $r
      i32.const 536 i32.const 0 call $put32 i32.const 540 i32.const 0 call $put32
      local.get $r)
    (func (export "init") (local $i i32)
      i32.const 512 i32.const 0 i32.const 1024 call $vkCreateInstance call $check
      i32.const 1024 call $get64 global.set $instance
      i32.const 1056 i32.const 0 call $put32 global.get $instance i32.const 1056 i32.const 0 call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.const 8 i32.gt_u if unreachable end
      global.get $instance i32.const 1056 i32.const 1080 call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.eqz if unreachable end
      i32.const 1080 call $get64 global.set $physical
      i32.const 1056 i32.const 8 call $put32 global.get $physical i32.const 1056 i32.const 1200 call $vkGetPhysicalDeviceQueueFamilyProperties
      block $found loop $next
        local.get $i i32.const 24 i32.mul i32.const 1200 i32.add call $get32 i32.const 1 i32.and
        if local.get $i global.set $family br $found end
        local.get $i i32.const 1 i32.add local.tee $i
        i32.const 1056 call $get32 i32.lt_u br_if $next unreachable
      end end
      i32.const 800 i32.const 2 call $put32
      i32.const 812 global.get $family call $put32
      i32.const 816 i32.const 1 call $put32 i32.const 820 i32.const 896 call $put32 i32.const 896 i32.const 1065353216 call $put32
      i32.const 600 i32.const 3 call $put32 i32.const 612 i32.const 1 call $put32 i32.const 616 i32.const 800 call $put32
      global.get $physical i32.const 600 i32.const 0 i32.const 1032 call $vkCreateDevice call $check
      i32.const 1032 call $get64 global.set $device)
    (func (export "query") (result i64)
      global.get $device global.get $family i32.const 0 i32.const 1040 call $vkGetDeviceQueue
      i32.const 1040 call $get64)
    (func (export "idle") (result i32) global.get $device call $vkDeviceWaitIdle)
    (func (export "fenceStatus") (result i32) (local $fence i64) (local $result i32)
      i32.const 1800 i32.const 8 call $put32
      global.get $device i32.const 1800 i32.const 0 i32.const 1840 call $vkCreateFence call $check
      i32.const 1840 call $get64 local.set $fence
      global.get $device local.get $fence call $vkGetFenceStatus local.set $result
      global.get $device local.get $fence i32.const 0 call $vkDestroyFence
      local.get $result)
    (func (export "properties") (result i32)
      global.get $physical i32.const 4096 call $vkGetPhysicalDeviceProperties
      i32.const 4096 call $get32)
    (func (export "mapped") (result i32) (local $i i32) (local $address i64)
      global.get $physical i32.const 8192 call $vkGetPhysicalDeviceMemoryProperties
      block $found loop $next
        local.get $i i32.const 8 i32.mul i32.const 8196 i32.add call $get32
        i32.const 6 i32.and i32.const 6 i32.eq br_if $found
        local.get $i i32.const 1 i32.add local.tee $i i32.const 8192 call $get32 i32.lt_u br_if $next unreachable
      end end
      i32.const 1600 i32.const 5 call $put32 i32.const 1608 i64.const 4096 call $put64
      i32.const 1616 local.get $i call $put32
      global.get $device i32.const 1600 i32.const 0 i32.const 1704 call $vkAllocateMemory call $check
      i32.const 1704 call $get64 global.set $allocation
      global.get $device global.get $allocation i64.const 0 i64.const 4096 i32.const 0 i32.const 1712 call $vkMapMemory call $check
      i32.const 1 global.set $mapped
      i32.const 1712 call $get64 local.set $address
      i32.const 1728 i32.const 305419896 call $put32 i32.const 1732 i32.const -1 call $put32
      local.get $address i32.const 1728 i32.const 8 call $writeMapped
      local.get $address i32.const 1744 i32.const 8 call $readMapped
      global.get $device global.get $allocation call $vkUnmapMemory
      i32.const 0 global.set $mapped
      global.get $device global.get $allocation i32.const 0 call $vkFreeMemory
      i64.const 0 global.set $allocation
      i32.const 1744 call $get32 i32.const 305419896 i32.eq
      i32.const 1748 call $get32 i32.const -1 i32.eq i32.and)
    (func (export "badRange")
      global.get $physical i32.const 65532 call $vkGetPhysicalDeviceProperties)
    (func (export "badAllocator")
      global.get $device i32.const 123 call $vkDestroyDevice)
    (func (export "cleanup")
      global.get $allocation i64.eqz if else
        global.get $mapped if global.get $device global.get $allocation call $vkUnmapMemory end
        global.get $device global.get $allocation i32.const 0 call $vkFreeMemory
      end
      global.get $device i64.eqz if else global.get $device i32.const 0 call $vkDestroyDevice end
      global.get $instance i64.eqz if else global.get $instance i32.const 0 call $vkDestroyInstance end
      i64.const 0 global.set $device i64.const 0 global.set $instance i64.const 0 global.set $allocation)

        (func (export "wrongWidth")
          global.get $physical i64.const 4096 call $wrongWidth)
        )
