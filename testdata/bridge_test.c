// Native bridge tests use a fake driver to inspect translated pointers, exact
// scalar bits, output conversion, aliasing, and failure before native dispatch.
#include "../bridge.h"
#include "../command_ids_generated.h"
#include "../scalar_generated.h"
#include "../abi/wire.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int calls;
static int expected;
static uint64_t handle=UINT64_C(0x123456789abcdef0);
static void *expected_viewports;
static uint32_t viewport_count;
static int scalar_calls;
static uint32_t pipeline_count;
static const void *pipeline_data;
static uint32_t barrier_counts[3];
static const void *barrier_guest[3];
static const void *barrier_native[3];
static uint32_t barrier_events;
static const void *barrier_events_guest;
static const void *barrier_events_native;

void wv_test_vkCmdSetDepthBias(VkCommandBuffer cmd,float constant,float clamp,float slope) {
    scalar_calls++;
    uint32_t clamp_bits;memcpy(&clamp_bits,&clamp,4);
    assert((uintptr_t)cmd==17 && constant==-0.5f && slope==1.0f);
    assert(clamp_bits==UINT32_C(0x80000000)); // retain negative zero's exact bits
}

uint64_t wv_dispatch(int command,const uint64_t *args) {
    calls++;
    assert(command==expected);
    if(command==WV_vkCreateMetalSurfaceEXT) {
        const VkMetalSurfaceCreateInfoEXT *info=(const void*)(uintptr_t)args[1];
        assert(args[0]==17 && args[2]==0);
        assert(info->sType==VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT);
        assert(info->pNext==NULL && info->flags==0);
        assert((uintptr_t)info->pLayer==UINT64_C(0x123456789abcdef0));
        memcpy((void*)(uintptr_t)args[3],&handle,8);
        return (uint64_t)(int64_t)VK_ERROR_SURFACE_LOST_KHR;
    }
    if(command==WV_vkCreateDevice) {
        const VkDeviceCreateInfo *info=(const void*)(uintptr_t)args[1];
        assert(args[0]==17 && args[2]==0);
        assert(info->sType==VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO);
        assert(info->queueCreateInfoCount==1);
        assert(info->pQueueCreateInfos->sType==VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO);
        assert(info->pQueueCreateInfos->queueFamilyIndex==3);
        assert(info->pQueueCreateInfos->queueCount==1);
        assert(*info->pQueueCreateInfos->pQueuePriorities==0.75f);
        assert(info->enabledExtensionCount==1);
        assert(!strcmp(info->ppEnabledExtensionNames[0],"VK_KHR_swapchain"));
        memcpy((void*)(uintptr_t)args[3],&handle,8);
        return 0;
    }
    if(command==WV_vkGetPhysicalDeviceProperties) {
        VkPhysicalDeviceProperties *out=(void*)(uintptr_t)args[1];
        assert(out->apiVersion==7);
        out->apiVersion=4194304;
        out->limits.minMemoryMapAlignment=4096;
        out->limits.nonCoherentAtomSize=UINT64_C(0x123456789abcdef0);
        return 0;
    }
    if(command==WV_vkQueuePresentKHR) {
        const VkPresentInfoKHR *info=(const void*)(uintptr_t)args[1];
        assert(info->swapchainCount==1 && *info->pImageIndices==2);
        info->pResults[0]=VK_SUBOPTIMAL_KHR;
        return (uint64_t)(int64_t)VK_ERROR_OUT_OF_DATE_KHR;
    }
    if(command==WV_vkUpdateDescriptorSets) {
        const VkWriteDescriptorSet *info=(const void*)(uintptr_t)args[2];
        assert(info->descriptorType==VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER);
        assert(info->pImageInfo==NULL && info->pTexelBufferView==NULL);
        assert(info->pBufferInfo->range==4096);
        return 0;
    }
    if(command==WV_vkCmdSetBlendConstants) {
        const float *values=(const void*)(uintptr_t)args[1];
        assert(values[0]==1.0f && values[3]==4.0f);
        return 0;
    }
    if(command==WV_vkCmdSetViewport) {
        const VkViewport *values=(const void*)(uintptr_t)args[3];
        assert(args[2]==viewport_count && (uintptr_t)values%_Alignof(VkViewport)==0);
        if(expected_viewports) assert(values==expected_viewports);
        assert(values[0].height==480 && values[viewport_count-1].width==640);
        return 0;
    }
    if(command==WV_vkCreateGraphicsPipelines) {
        const VkGraphicsPipelineCreateInfo *infos=(const void*)(uintptr_t)args[3];
        uint64_t *outputs=(void*)(uintptr_t)args[5];
        assert(args[2]==pipeline_count && args[4]==0);
        for(uint32_t i=0;i<pipeline_count;i++) {
            assert(infos[i].stageCount==1);
            const VkSpecializationInfo *spec=infos[i].pStages[0].pSpecializationInfo;
            assert(spec->dataSize==8 && spec->pData==pipeline_data);
            if(i%2) assert(spec==infos[i-1].pStages[0].pSpecializationInfo);
            outputs[i]=handle+i;
        }
        return 0;
    }
    if(command==WV_vkCmdPipelineBarrier || command==WV_vkCmdWaitEvents) {
        const size_t sizes[]={sizeof(VkMemoryBarrier),sizeof(VkBufferMemoryBarrier),sizeof(VkImageMemoryBarrier)};
        unsigned stage=command==WV_vkCmdWaitEvents?3:1,count=command==WV_vkCmdWaitEvents?5:4;
        assert(args[0]==17 && args[stage]==VK_PIPELINE_STAGE_ALL_COMMANDS_BIT && args[stage+1]==VK_PIPELINE_STAGE_ALL_COMMANDS_BIT);
        if(command==WV_vkCmdWaitEvents) {
            assert(args[1]==barrier_events);
            const VkEvent *events=(const void*)(uintptr_t)args[2];
            barrier_events_native=events;
            assert(events!=barrier_events_guest && (uintptr_t)events%8==0);
            for(uint32_t i=0;i<barrier_events;i++) assert((uintptr_t)events[i]==handle);
        }
        for(unsigned j=0;j<3;j++) {
            assert(args[count+2*j]==barrier_counts[j]);
            barrier_native[j]=(const void*)(uintptr_t)args[count+1+2*j];
            if(!barrier_counts[j]) { assert(!barrier_native[j]); continue; }
            assert(barrier_native[j]!=barrier_guest[j]); // these pointer-bearing arrays require native scratch
            assert((uintptr_t)barrier_native[j]%8==0);
            if(command==WV_vkCmdWaitEvents) {
                uintptr_t begin=(uintptr_t)barrier_native[j],other=(uintptr_t)barrier_events_native;
                assert(begin>=other+barrier_events*8 || other>=begin+sizes[j]*barrier_counts[j]);
            }
            for(unsigned k=0;k<j;k++) if(barrier_counts[k]) {
                uintptr_t begin=(uintptr_t)barrier_native[j],other=(uintptr_t)barrier_native[k];
                assert(begin>=other+sizes[k]*barrier_counts[k] || other>=begin+sizes[j]*barrier_counts[j]);
            }
        }
        const VkMemoryBarrier *memory=barrier_native[0];
        const VkBufferMemoryBarrier *buffers=barrier_native[1];
        const VkImageMemoryBarrier *images=barrier_native[2];
        for(uint32_t i=0;i<barrier_counts[0];i++) {
            assert(memory[i].sType==VK_STRUCTURE_TYPE_MEMORY_BARRIER && !memory[i].pNext);
            assert(memory[i].srcAccessMask==VK_ACCESS_MEMORY_READ_BIT && memory[i].dstAccessMask==VK_ACCESS_MEMORY_WRITE_BIT);
        }
        for(uint32_t i=0;i<barrier_counts[1];i++) {
            assert(buffers[i].sType==VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER && !buffers[i].pNext);
            assert((uintptr_t)buffers[i].buffer==handle && buffers[i].offset==(uint64_t)i*64 && buffers[i].size==4096);
        }
        for(uint32_t i=0;i<barrier_counts[2];i++) {
            assert(images[i].sType==VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER && !images[i].pNext);
            assert((uintptr_t)images[i].image==handle && images[i].newLayout==VK_IMAGE_LAYOUT_GENERAL);
            assert(images[i].subresourceRange.levelCount==1 && images[i].subresourceRange.layerCount==1);
        }
        return 0;
    }
    assert(0); return 0;
}

static void buffer(wv_context *c,int arg,void *data,size_t bytes,int width,uint64_t offset) {
    c->buffers[arg]=(wv_buffer){data,bytes,(uint8_t)width,1};
    c->input[arg]=offset;c->args[arg]=offset;
}
static void metal_surface(wv_context *c,int width) {
    _Alignas(16) uint8_t arena[128]={0},before[128];
    if(width==32) {
        wv32_VkMetalSurfaceCreateInfoEXT *info=(void*)arena;
        info->sType=VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT;
        info->pLayer=handle;
    } else {
        wv64_VkMetalSurfaceCreateInfoEXT *info=(void*)arena;
        info->sType=VK_STRUCTURE_TYPE_METAL_SURFACE_CREATE_INFO_EXT;
        info->pLayer=handle;
    }
    memcpy(before,arena,sizeof(arena));
    wv_reset(c);c->args[0]=c->input[0]=17;
    buffer(c,1,arena,sizeof(arena),width,0);
    buffer(c,3,arena,sizeof(arena),width,64);
    expected=WV_vkCreateMetalSurfaceEXT;
    assert(wv_invoke(c,expected)==WV_OK);
    assert((int32_t)c->result==VK_ERROR_SURFACE_LOST_KHR);
    uint64_t out;memcpy(&out,arena+64,8);assert(out==handle);
    // A native CAMetalLayer address is 64-bit even in the Wasm32 wire layout.
    // It is never a guest offset or a target for bridge traversal.
    assert(!memcmp(arena,before,64));
    for(int i=0;i<WV_MAX_ARGS;i++) assert(c->buffers[i].base==NULL && c->args[i]==0);
}
static void device(wv_context *c,int width) {
    _Alignas(16) uint8_t arena[256]={0},before[256];
    if(width==32) {
        wv32_VkDeviceCreateInfo *info=(void*)arena;
        info->sType=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;info->queueCreateInfoCount=1;info->pQueueCreateInfos=80;
        info->enabledExtensionCount=1;info->ppEnabledExtensionNames=136;
        wv32_VkDeviceQueueCreateInfo *queue=(void*)(arena+80);
        queue->sType=VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;queue->queueFamilyIndex=3;queue->queueCount=1;queue->pQueuePriorities=128;
        uint32_t name=144;memcpy(arena+136,&name,4);
    } else {
        wv64_VkDeviceCreateInfo *info=(void*)arena;
        info->sType=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;info->queueCreateInfoCount=1;info->pQueueCreateInfos=80;
        info->enabledExtensionCount=1;info->ppEnabledExtensionNames=136;
        wv64_VkDeviceQueueCreateInfo *queue=(void*)(arena+80);
        queue->sType=VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;queue->queueFamilyIndex=3;queue->queueCount=1;queue->pQueuePriorities=128;
        uint64_t name=144;memcpy(arena+136,&name,8);
    }
    float priority=0.75f;memcpy(arena+128,&priority,4);memcpy(arena+144,"VK_KHR_swapchain",17);
    memcpy(before,arena,sizeof(arena));
    wv_reset(c);c->args[0]=c->input[0]=17;
    buffer(c,1,arena,sizeof(arena),width,0);buffer(c,3,arena,sizeof(arena),width,200);
    expected=WV_vkCreateDevice;
    assert(wv_invoke(c,expected)==WV_OK);
    uint64_t out;memcpy(&out,arena+200,8);assert(out==handle);
    assert(!memcmp(arena,before,200));
    for(int i=0;i<WV_MAX_ARGS;i++) assert(c->buffers[i].base==NULL && c->args[i]==0);
    // Conversion blocks/metadata are reused on the next same-shape call.
    size_t retained=wv_retained(c);
    buffer(c,1,arena,sizeof(arena),width,0);buffer(c,3,arena,sizeof(arena),width,200);
    c->args[0]=c->input[0]=17;
    assert(wv_invoke(c,expected)==WV_OK);assert(wv_retained(c)==retained);
}
static void properties(wv_context *c) {
    wv32_VkPhysicalDeviceProperties out={0};out.apiVersion=7;
    wv_reset(c);buffer(c,1,&out,sizeof(out),32,0);expected=WV_vkGetPhysicalDeviceProperties;
    assert(wv_invoke(c,expected)==WV_OK);
    assert(out.apiVersion==4194304 && out.limits.minMemoryMapAlignment==4096);
    assert(out.limits.nonCoherentAtomSize==handle);
}
static void present(wv_context *c) {
    _Alignas(16) uint8_t arena[128]={0};
    wv32_VkPresentInfoKHR *info=(void*)arena;
    info->sType=VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;info->swapchainCount=1;info->pSwapchains=64;info->pImageIndices=72;info->pResults=76;
    uint32_t index=2;memcpy(arena+72,&index,4);
    wv_reset(c);buffer(c,1,arena,sizeof(arena),32,0);expected=WV_vkQueuePresentKHR;
    assert(wv_invoke(c,expected)==WV_OK);
    assert((int32_t)c->result==VK_ERROR_OUT_OF_DATE_KHR);
    int32_t result;memcpy(&result,arena+76,4);assert(result==VK_SUBOPTIMAL_KHR);
    assert(info->pResults==76);
}
static void descriptors(wv_context *c) {
    _Alignas(16) uint8_t arena[128]={0};
    wv64_VkWriteDescriptorSet *info=(void*)arena;
    info->sType=VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;info->descriptorCount=1;info->descriptorType=VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    info->pImageInfo=UINT64_MAX;info->pTexelBufferView=UINT64_MAX;info->pBufferInfo=80;
    wv64_VkDescriptorBufferInfo *data=(void*)(arena+80);data->range=4096;
    wv_reset(c);c->input[1]=c->args[1]=1;buffer(c,2,arena,sizeof(arena),64,0);expected=WV_vkUpdateDescriptorSets;
    assert(wv_invoke(c,expected)==WV_OK);
}
static void errors(wv_context *c) {
    _Alignas(16) uint8_t arena[96]={0},before[96];
    wv64_VkDeviceCreateInfo *info=(void*)arena;info->sType=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    info->queueCreateInfoCount=1;info->pQueueCreateInfos=88;memcpy(before,arena,sizeof(arena));
    int previous=calls;
    wv_reset(c);buffer(c,1,arena,sizeof(arena),64,0);buffer(c,3,arena,sizeof(arena),64,80);
    assert(wv_invoke(c,WV_vkCreateDevice)==WV_RANGE);assert(calls==previous && !memcmp(arena,before,sizeof(arena)));
    info->pQueueCreateInfos=0;info->pNext=80;
    uint32_t stype=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;memcpy(arena+80,&stype,4);
    wv_reset(c);buffer(c,1,arena,sizeof(arena),64,0);
    assert(wv_invoke(c,WV_vkCreateDevice)==WV_RANGE);assert(calls==previous);
    // Self-referential pNext chain: fully in bounds, still rejected.
    wv64_VkDeviceCreateInfo cyc[2]={{0}};cyc[0].sType=cyc[1].sType=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    cyc[0].pNext=cyc[1].pNext=sizeof(cyc[0]);
    wv_reset(c);buffer(c,1,cyc,sizeof(cyc),64,0);
    assert(wv_invoke(c,WV_vkCreateDevice)==WV_CYCLE);assert(calls==previous);
    wv_reset(c);c->input[2]=1;
    assert(wv_invoke(c,WV_vkCreateDevice)==WV_UNSUPPORTED);assert(calls==previous);
    float values[3]={1,2,3};wv_reset(c);buffer(c,1,values,sizeof(values),64,0);
    assert(wv_invoke(c,WV_vkCmdSetBlendConstants)==WV_RANGE);assert(calls==previous);
    float four[4]={1,2,3,4};wv_reset(c);buffer(c,1,four,sizeof(four),64,0);expected=WV_vkCmdSetBlendConstants;
    assert(wv_invoke(c,expected)==WV_OK);
}
static void viewports(wv_context *c) {
    const uint32_t counts[]={100,1000,10000,100000};
    size_t retained=wv_retained(c);
    for(unsigned j=0;j<sizeof(counts)/sizeof(counts[0]);j++) {
        viewport_count=counts[j];
        size_t bytes=sizeof(VkViewport)*viewport_count;
        VkViewport *data=malloc(bytes);assert(data);
        for(uint32_t i=0;i<viewport_count;i++) data[i]=(VkViewport){0,0,640,480,0,1};
        for(int width=32;width<=64;width+=32) {
            wv_reset(c);c->input[2]=c->args[2]=viewport_count;
            buffer(c,3,data,bytes,width,0);expected_viewports=data;expected=WV_vkCmdSetViewport;
            assert(wv_invoke(c,expected)==WV_OK);
            assert(wv_retained(c)==retained); // large compatible batches allocate nothing
        }
        free(data);
    }
    uint8_t unaligned[sizeof(VkViewport)+1];
    VkViewport one={0,0,640,480,0,1};memcpy(unaligned+1,&one,sizeof(one));
    viewport_count=1;expected_viewports=NULL;
    wv_reset(c);c->input[2]=c->args[2]=1;
    buffer(c,3,unaligned,sizeof(unaligned),64,1);
    assert(wv_invoke(c,WV_vkCmdSetViewport)==WV_OK);
}
static void pipelines(wv_context *c) {
    const uint32_t counts[]={100,1000,10000,50000};
    for(unsigned j=0;j<sizeof(counts)/sizeof(counts[0]);j++) {
        pipeline_count=counts[j];
        size_t stages_off=pipeline_count*sizeof(wv64_VkGraphicsPipelineCreateInfo);
        size_t specs_off=stages_off+pipeline_count*sizeof(wv64_VkPipelineShaderStageCreateInfo);
        size_t data_off=specs_off+((pipeline_count+1)/2)*sizeof(wv64_VkSpecializationInfo);
        size_t outputs_off=data_off+8,bytes=outputs_off+pipeline_count*8;
        uint8_t *arena=calloc(1,bytes);assert(arena);
        wv64_VkGraphicsPipelineCreateInfo *infos=(void*)arena;
        wv64_VkPipelineShaderStageCreateInfo *stages=(void*)(arena+stages_off);
        wv64_VkSpecializationInfo *specs=(void*)(arena+specs_off);
        for(uint32_t i=0;i<pipeline_count;i++) {
            infos[i].sType=VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
            infos[i].stageCount=1;infos[i].pStages=stages_off+i*sizeof(*stages);
            stages[i].sType=VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
            stages[i].pSpecializationInfo=specs_off+(i/2)*sizeof(*specs);
            specs[i/2].dataSize=8;specs[i/2].pData=data_off;
        }
        pipeline_data=arena+data_off;expected=WV_vkCreateGraphicsPipelines;
        size_t retained=0;
        for(int repeat=0;repeat<2;repeat++) {
            wv_reset(c);c->args[2]=c->input[2]=pipeline_count;
            buffer(c,3,arena,bytes,64,0);buffer(c,5,arena,bytes,64,outputs_off);
#ifdef WV_TEST_SCRATCH_SCAN
            wv_scratch_visits=0;
#endif
            assert(wv_invoke(c,expected)==WV_OK);
#ifdef WV_TEST_SCRATCH_SCAN
            // This fixed mixture permits logarithmic AVL lookups when small
            // allocations reuse larger blocks and skipped tails. Its visit
            // envelope still rejects the former head-first quadratic scans.
            assert(wv_scratch_visits<=6*(size_t)pipeline_count+256);
#endif
            uint64_t last;memcpy(&last,arena+outputs_off+(pipeline_count-1)*8,8);
            assert(last==handle+pipeline_count-1);
            if(repeat) assert(wv_retained(c)==retained);
            retained=wv_retained(c);
            for(size_t i=0;i<c->memo_slots_cap;i++) assert(c->memo_slots[i]==0);
            assert(infos[pipeline_count-1].pStages==stages_off+(pipeline_count-1)*sizeof(*stages));
        }
        free(arena);
    }
}
static void barriers_with_events(wv_context *c,uint32_t event_count,uint32_t memory_count,uint32_t buffer_count,uint32_t image_count) {
    VkMemoryBarrier *memory=memory_count?calloc(memory_count,sizeof(*memory)):NULL;
    VkBufferMemoryBarrier *buffers=buffer_count?calloc(buffer_count,sizeof(*buffers)):NULL;
    VkImageMemoryBarrier *images=image_count?calloc(image_count,sizeof(*images)):NULL;
    uint8_t *events=event_count?malloc((size_t)event_count*8+1):NULL;
    assert((memory || !memory_count) && (buffers || !buffer_count) && (images || !image_count));
    assert(events || !event_count);
    for(uint32_t i=0;i<event_count;i++) memcpy(events+1+(size_t)i*8,&handle,8);
    for(uint32_t i=0;i<memory_count;i++) memory[i]=(VkMemoryBarrier){
        .sType=VK_STRUCTURE_TYPE_MEMORY_BARRIER,.srcAccessMask=VK_ACCESS_MEMORY_READ_BIT,.dstAccessMask=VK_ACCESS_MEMORY_WRITE_BIT};
    for(uint32_t i=0;i<buffer_count;i++) buffers[i]=(VkBufferMemoryBarrier){
        .sType=VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER,.buffer=(VkBuffer)(uintptr_t)handle,
        .srcQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED,.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED,.offset=(uint64_t)i*64,.size=4096};
    for(uint32_t i=0;i<image_count;i++) images[i]=(VkImageMemoryBarrier){
        .sType=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,.image=(VkImage)(uintptr_t)handle,
        .srcQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED,.dstQueueFamilyIndex=VK_QUEUE_FAMILY_IGNORED,.newLayout=VK_IMAGE_LAYOUT_GENERAL,
        .subresourceRange={VK_IMAGE_ASPECT_COLOR_BIT,0,1,0,1}};
    barrier_counts[0]=memory_count;barrier_counts[1]=buffer_count;barrier_counts[2]=image_count;
    barrier_guest[0]=memory;barrier_guest[1]=buffers;barrier_guest[2]=images;
    barrier_events=event_count;barrier_events_guest=events?events+1:NULL;
    wv_reset(c);c->args[0]=c->input[0]=17;
    unsigned stage=event_count?3:1,count=event_count?5:4;
    c->args[stage]=c->input[stage]=c->args[stage+1]=c->input[stage+1]=VK_PIPELINE_STAGE_ALL_COMMANDS_BIT;
    for(unsigned j=0;j<3;j++) c->args[count+2*j]=c->input[count+2*j]=barrier_counts[j];
    if(memory_count) buffer(c,count+1,memory,memory_count*sizeof(*memory),64,0);
    if(buffer_count) buffer(c,count+3,buffers,buffer_count*sizeof(*buffers),64,0);
    if(image_count) buffer(c,count+5,images,image_count*sizeof(*images),64,0);
    if(event_count) { c->args[1]=c->input[1]=event_count;buffer(c,2,events,(size_t)event_count*8+1,64,1); }
    expected=event_count?WV_vkCmdWaitEvents:WV_vkCmdPipelineBarrier;
    int previous=calls;
    assert(wv_invoke(c,expected)==WV_OK && calls==previous+1);
    for(int i=0;i<WV_MAX_ARGS;i++) assert(c->buffers[i].base==NULL && c->args[i]==0);
    free(memory);free(buffers);free(images);free(events);
}
static void barriers(wv_context *c,uint32_t memory_count,uint32_t buffer_count,uint32_t image_count) {
    barriers_with_events(c,0,memory_count,buffer_count,image_count);
}
static void scratch_shapes(void) {
    // Equal live allocation sizes in reversed order must reuse both existing
    // blocks even though a forward scan would skip the smaller block first.
    wv_context *c=wv_new(200000);assert(c);
    barriers(c,3003,2001,0); // 72,072 then 112,056 native bytes
    size_t retained=wv_retained(c);
    const void *small=barrier_native[0],*large=barrier_native[1];
    barriers(c,4669,1287,0); // exactly the same sizes in reverse order
    assert(wv_retained(c)==retained && barrier_native[0]==large && barrier_native[1]==small);
    barriers(c,3003,2001,0);
    assert(wv_retained(c)==retained && barrier_native[0]==small && barrier_native[1]==large);
    wv_free(c);

    // A shrinking workload may reuse a larger block across size classes.
    c=wv_new(200000);assert(c);
    barriers(c,8000,0,0); // one 192,000-byte block leaves no budget for another
    retained=wv_retained(c);large=barrier_native[0];
    barriers(c,4000,0,0); // 96,000 bytes
    assert(wv_retained(c)==retained && barrier_native[0]==large);

    // Several arrays may share that large block's remaining capacity. Every
    // request is below 64 KiB; creating a new small block would exceed the limit.
    barriers(c,2000,1000,800); // 48,000 + 56,000 + 57,600 = 161,600 bytes
    assert(wv_retained(c)==retained && barrier_native[0]==large);
    assert((uintptr_t)barrier_native[1]==(uintptr_t)large+48000);
    assert((uintptr_t)barrier_native[2]==(uintptr_t)large+104000);
    barriers(c,8000,0,0);
    assert(wv_retained(c)==retained && barrier_native[0]==large);
    wv_free(c);

    // A skipped small-block tail remains usable later in the same call.
    // The unaligned event array requires another scratch allocation before the
    // three pointer-bearing barrier arrays, giving four allocations to reorder.
    c=wv_new(150000);assert(c);
    barriers_with_events(c,6000,666,857,222); // 48,000 / 15,984 / 48,000 / 15,984 rounded bytes
    retained=wv_retained(c);
    barriers_with_events(c,6000,2000,285,222); // 48,000 / 48,000 / 15,968 / 15,984 rounded bytes
    assert(wv_retained(c)==retained);
    barriers_with_events(c,6000,666,857,222);
    assert(wv_retained(c)==retained);
    wv_free(c);
}
int main(void) {
    wv_direct_vkCmdSetDepthBias(17,UINT32_C(0xbf000000),UINT32_C(0x80000000),UINT32_C(0x3f800000));
    assert(scalar_calls==1);
    wv_context *c=wv_new(32*1024*1024);assert(c);
    metal_surface(c,32);metal_surface(c,64);
    device(c,64);device(c,32);properties(c);present(c);descriptors(c);errors(c);viewports(c);pipelines(c);errors(c);
    wv_free(c);
    scratch_shapes();
    // Allocation limits reject before dispatch, without touching guest bytes.
    c=wv_new(4096);assert(c);
    wv64_VkDeviceCreateInfo info={0};info.sType=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
    buffer(c,1,&info,sizeof(info),64,0);int previous=calls;
    assert(wv_invoke(c,WV_vkCreateDevice)==WV_NOMEM && calls==previous);
    wv_free(c);puts("PASS: native Vulkan ABI conversion, aliasing, writeback, errors and scratch reuse");
}
