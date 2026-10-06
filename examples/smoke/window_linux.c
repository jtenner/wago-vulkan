#include "native.h"
uint64_t smoke_window_open(void) { return 0; }
int smoke_window_resize(void) { return 0; }
void smoke_window_pump(double seconds) { (void)seconds; }
void smoke_window_close(void) {}
void smoke_window_size(uint32_t *width, uint32_t *height) { *width = 0; *height = 0; }
