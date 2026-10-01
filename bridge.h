#ifndef WAGO_VULKAN_BRIDGE_H
#define WAGO_VULKAN_BRIDGE_H
#define VK_USE_PLATFORM_XLIB_KHR
#include <vulkan/vulkan.h>
#include <stdint.h>
#include <stddef.h>

#define WV_MAX_ARGS 16
enum { WV_OK, WV_RANGE, WV_NOMEM, WV_UNSUPPORTED, WV_CYCLE, WV_WIDTH };
enum { WV_POINTER=1, WV_DOUBLE=2, WV_STRING=4, WV_PNEXT=8, WV_EXTERNAL=16, WV_WRITE=32, WV_DESC_IMAGE=64, WV_DESC_BUFFER=128, WV_DESC_TEXEL=256 };
enum { WV_SCALAR, WV_STRUCT, WV_UNION, WV_SIZE, WV_PTR_ARRAY };
typedef struct {
    uint32_t off32, off64;
    uint16_t type, flags;
    uint32_t count;
    int32_t len32, len64;
    uint8_t len_width32, len_width64, divisor, roundup;
} wv_field;
typedef struct {
    uint32_t size32, size64, align64;
    uint16_t kind, fields_count;
    uint8_t convert32, convert64;
    const wv_field *fields;
} wv_type;
typedef struct {
    uint8_t *base;
    uint64_t bytes;
    uint8_t width, present;
} wv_buffer;
typedef struct wv_block wv_block;
typedef struct wv_memo wv_memo;
typedef struct wv_writeback wv_writeback;
typedef struct {
    uint64_t args[WV_MAX_ARGS], input[WV_MAX_ARGS], result;
    wv_buffer buffers[WV_MAX_ARGS];
    wv_block *blocks;
    wv_block *small_head, *small_tail, *small_cursor, *available_root;
    wv_memo *memo;
    wv_writeback *writes;
    uint32_t *memo_slots;
    size_t memo_slots_cap;
    size_t memo_hash_count;
    size_t memo_count, memo_cap, write_count, write_cap, retained, limit;
    int error;
} wv_context;

#ifdef WV_TEST_SCRATCH_SCAN
extern size_t wv_scratch_visits;
#endif

extern const wv_type wv_types[];
extern const size_t wv_type_count;
int wv_chain_type(uint32_t stype);
int wv_prepare(wv_context *ctx, int command);
uint64_t wv_dispatch(int command, const uint64_t *args);
wv_context *wv_new(size_t scratch_limit);
void wv_free(wv_context *ctx);
void wv_reset(wv_context *ctx);
int wv_invoke(wv_context *ctx, int command);
int wv_complete(wv_context *ctx);
void wv_abort(wv_context *ctx);
void *wv_root(wv_context *ctx, int index, int type, uint64_t count, int output);
void *wv_string_root(wv_context *ctx, int index);
uint64_t wv_argument_value(wv_context *ctx, int index, int width);
uint64_t wv_argument_member(wv_context *ctx, int index, size_t off32, size_t off64, int width32, int width64);
void wv_copy(uint64_t destination, uint64_t source, size_t bytes);
size_t wv_retained(const wv_context *ctx);
#endif
