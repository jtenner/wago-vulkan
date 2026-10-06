#include "native.h"
#include <mach-o/dyld.h>
#include <string.h>
#import <AppKit/AppKit.h>
#import <QuartzCore/CAMetalLayer.h>
#import <Metal/Metal.h>
// All entry points run on Go's locked initial OS thread. Native ownership stays
// here until Vulkan swapchains/surface/instance have been destroyed by Go.
static NSWindow *window;
static CAMetalLayer *layer;
static NSAutoreleasePool *pool;
static void size_layer(void) {
    NSRect bounds = [[window contentView] bounds];
    CGFloat scale = [window backingScaleFactor];
    layer.contentsScale = scale;
    layer.drawableSize = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale);
}
uint64_t smoke_window_open(void) {
    if (![NSThread isMainThread]) return 0;
    pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return 0;
    window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 300)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    [window setReleasedWhenClosed:NO];
    [window setTitle:@"Wago Vulkan smoke: BLUE then GREEN after resize"];
    layer = [[CAMetalLayer alloc] init];
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = NO;
    [[window contentView] setWantsLayer:YES];
    [[window contentView] setLayer:layer];
    size_layer();
    [window center];
    [window makeKeyAndOrderFront:nil];
    [NSApp finishLaunching];
    [NSApp activateIgnoringOtherApps:YES];
    [device release];
    return (uint64_t)(uintptr_t)layer;
}
void smoke_window_pump(double seconds) {
    @autoreleasepool {
        NSDate *end = [NSDate dateWithTimeIntervalSinceNow:seconds];
        do {
            NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny
                untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]
                inMode:NSDefaultRunLoopMode dequeue:YES];
            if (event) [NSApp sendEvent:event];
            [NSApp updateWindows];
        } while ([end timeIntervalSinceNow] > 0);
    }
}
int smoke_window_resize(void) {
    if (![NSThread isMainThread] || !window || ![window isVisible]) return 0;
    [window setContentSize:NSMakeSize(640, 360)];
    size_layer();
    smoke_window_pump(0.1);
    return 1;
}
void smoke_window_size(uint32_t *width, uint32_t *height) {
    size_layer();
    *width = (uint32_t)layer.drawableSize.width;
    *height = (uint32_t)layer.drawableSize.height;
}
void smoke_window_close(void) {
    if (window) {
        [[window contentView] setLayer:nil];
        [window close];
        [window release]; window = nil;
    }
    [layer release]; layer = nil;
    [pool drain]; pool = nil;
}

const char *smoke_moltenvk_path(void) {
    for (uint32_t i = 0; i < _dyld_image_count(); ++i) {
        const char *name = _dyld_get_image_name(i);
        if (!name) continue;
        const char *base = strrchr(name, '/');
        base = base ? base + 1 : name;
        if (strstr(base, "MoltenVK")) return name;
    }
    return "";
}
