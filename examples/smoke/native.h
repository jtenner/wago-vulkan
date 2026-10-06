#ifndef SMOKE_NATIVE_H
#define SMOKE_NATIVE_H
#include <stdint.h>
const char *smoke_loader_path(void);
const char *smoke_moltenvk_path(void);
int smoke_debug_start(uint64_t instance);
void smoke_debug_stop(uint64_t instance);
unsigned smoke_debug_errors(void);
uint64_t smoke_window_open(void);
int smoke_window_resize(void);
void smoke_window_pump(double seconds);
void smoke_window_close(void);
void smoke_window_size(uint32_t *width, uint32_t *height);
#endif
