#include "bridge.h"
#include <stdlib.h>
#include <string.h>
#include <limits.h>

_Static_assert(sizeof(void*) == 8, "wago-vulkan requires a 64-bit native host");
#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__
#error "wago-vulkan requires a little-endian native host"
#endif
struct wv_block {
    struct wv_block *next, *pool_next, *left, *right, *parent;
    size_t capacity, used, available, max_capacity;
    unsigned height;
    _Alignas(16) uint8_t data[];
};
#ifdef WV_TEST_SCRATCH_SCAN
size_t wv_scratch_visits;
#define WV_SCRATCH_VISIT() (++wv_scratch_visits)
#else
#define WV_SCRATCH_VISIT() ((void)0)
#endif
struct wv_memo { const wv_buffer *buffer; uint64_t offset, count; uint16_t type; uint8_t active, output; uint32_t bucket; uint8_t *native; };
struct wv_writeback { const wv_buffer *buffer; uint64_t offset, count; uint16_t type; uint8_t *native; };

wv_context *wv_new(size_t limit) {
    wv_context *c=calloc(1,sizeof(*c));
    if(c) { c->limit=limit; c->retained=sizeof(*c); }
    return c;
}
void wv_free(wv_context *c) {
    if(!c) return;
    wv_block *b=c->blocks;
    while(b) { wv_block *next=b->next; free(b); b=next; }
    free(c->memo); free(c->writes); free(c->memo_slots); free(c);
}
size_t wv_retained(const wv_context *c) { return c->retained; }
void wv_reset(wv_context *c) {
    memset(c->args,0,sizeof(c->args)); memset(c->input,0,sizeof(c->input));
    memset(c->buffers,0,sizeof(c->buffers));
    c->memo_count=c->write_count=c->memo_hash_count=0; c->error=WV_OK; c->result=0;
    for(wv_block *b=c->blocks;b;b=b->next) { b->used=0; b->available=b->max_capacity; }
    c->small_cursor=c->small_head;
}
static unsigned height(const wv_block *b) { return b?b->height:0; }
static void update_block(wv_block *b) {
    b->height=1+(height(b->left)>height(b->right)?height(b->left):height(b->right));
    b->available=b->capacity-b->used; b->max_capacity=b->capacity;
    if(b->left) {
        if(b->left->available>b->available) b->available=b->left->available;
        if(b->left->max_capacity>b->max_capacity) b->max_capacity=b->left->max_capacity;
    }
    if(b->right) {
        if(b->right->available>b->available) b->available=b->right->available;
        if(b->right->max_capacity>b->max_capacity) b->max_capacity=b->right->max_capacity;
    }
}
static void update_available(wv_block *b) {
    for(;b;b=b->parent) {
        size_t available=b->capacity-b->used;
        if(b->left && b->left->available>available) available=b->left->available;
        if(b->right && b->right->available>available) available=b->right->available;
        if(available==b->available) break;
        b->available=available;
    }
}
static void replace_block(wv_context *c,wv_block *old,wv_block *replacement) {
    replacement->parent=old->parent;
    if(!old->parent) c->available_root=replacement;
    else if(old->parent->left==old) old->parent->left=replacement;
    else old->parent->right=replacement;
}
static wv_block *rotate_left(wv_context *c,wv_block *b) {
    wv_block *r=b->right; replace_block(c,b,r);
    b->right=r->left; if(b->right) b->right->parent=b;
    r->left=b; b->parent=r; update_block(b); update_block(r); return r;
}
static wv_block *rotate_right(wv_context *c,wv_block *b) {
    wv_block *l=b->left; replace_block(c,b,l);
    b->left=l->right; if(b->left) b->left->parent=b;
    l->right=b; b->parent=l; update_block(b); update_block(l); return l;
}
static void insert_block(wv_context *c,wv_block *b) {
    wv_block **link=&c->available_root, *parent=NULL;
    while(*link) { parent=*link; link=b->capacity<parent->capacity?&parent->left:&parent->right; }
    *link=b; b->parent=parent;
    for(wv_block *p=b;p;p=p->parent) {
        update_block(p);
        int balance=(int)height(p->left)-(int)height(p->right);
        if(balance>1) {
            if(height(p->left->left)<height(p->left->right)) rotate_left(c,p->left);
            p=rotate_right(c,p);
        } else if(balance<-1) {
            if(height(p->right->right)<height(p->right->left)) rotate_right(c,p->right);
            p=rotate_left(c,p);
        }
    }
}
static void *reuse_block(wv_context *c,size_t n) {
    // Original capacities order the stable AVL tree. Subtree maxima track
    // remaining space, so full blocks and unsuitable subtrees are skipped.
    // Larger retained blocks and their tails remain usable by smaller requests.
    wv_block *b=c->available_root;
    if(!b || b->available<n) return NULL;
    while(b) {
        WV_SCRATCH_VISIT();
        if(b->left && b->left->available>=n) b=b->left;
        else if(b->capacity-b->used>=n) {
            void *p=b->data+b->used; b->used+=n;
            update_available(b);
            return p;
        } else b=b->right;
    }
    return NULL;
}
static void *allocate(wv_context *c, uint64_t bytes) {
    if(c->error) return NULL;
    if(bytes>SIZE_MAX-15) { c->error=WV_RANGE; return NULL; }
    size_t n=((size_t)bytes+15)&~(size_t)15;
    // The common small-record path advances through shared 64 KiB blocks.
    // An AVL index of all blocks provides logarithmic fallback lookup for
    // larger requests and reusable tails skipped by the common cursor path.
    wv_block *b;
    if(n<=65536) {
        for(b=c->small_cursor;b;b=b->pool_next) {
            WV_SCRATCH_VISIT();
            if(n<=b->capacity-b->used) {
                void *p=b->data+b->used; b->used+=n; c->small_cursor=b;
                update_available(b); return p;
            }
            c->small_cursor=b->pool_next;
        }
    }
    void *reused=reuse_block(c,n); if(reused) return reused;
    size_t cap=n>65536?n:65536;
    if(cap>SIZE_MAX-sizeof(wv_block) || c->retained>c->limit || cap+sizeof(wv_block)>c->limit-c->retained) { c->error=WV_NOMEM; return NULL; }
    b=malloc(sizeof(*b)+cap);
    if(!b) { c->error=WV_NOMEM; return NULL; }
    b->next=c->blocks; b->pool_next=b->left=b->right=b->parent=NULL;
    b->capacity=cap; b->used=n; b->available=cap-n; b->max_capacity=cap; b->height=1; c->blocks=b;
    insert_block(c,b);
    if(n<=65536) {
        if(c->small_tail) c->small_tail->pool_next=b; else c->small_head=b;
        c->small_tail=c->small_cursor=b;
    }
    c->retained+=sizeof(*b)+cap; return b->data;
}
static int grow(wv_context *c, void **p, size_t *capacity, size_t count, size_t size) {
    if(count<*capacity) return 1;
    size_t next=*capacity?*capacity*2:32;
    if(next<*capacity || next>SIZE_MAX/size) { c->error=WV_NOMEM; return 0; }
    size_t extra=(next-*capacity)*size;
    if(c->retained>c->limit || extra>c->limit-c->retained) { c->error=WV_NOMEM; return 0; }
    void *q=realloc(*p,next*size);
    if(!q) { c->error=WV_NOMEM; return 0; }
    *p=q; *capacity=next; c->retained+=extra; return 1;
}
static uint64_t mix(uint64_t n) {
    n^=n>>30;n*=UINT64_C(0xbf58476d1ce4e5b9);
    n^=n>>27;n*=UINT64_C(0x94d049bb133111eb);return n^(n>>31);
}
// Slots hold memo indices, never guest addresses. Keep load below one half;
// clearing only occupied buckets makes cleanup proportional to this call's
// graph even when a frame retains a larger table from an earlier call.
static size_t memo_slot(wv_context *c,const wv_buffer *b,uint64_t off,int type,uint64_t count) {
    uint64_t hash=mix((uintptr_t)b->base)^mix(off)^mix(count)^mix((uint64_t)type<<8|b->width);
    size_t slot=(size_t)hash&(c->memo_slots_cap-1);
    while(c->memo_slots[slot]) {
        const wv_memo *m=&c->memo[c->memo_slots[slot]-1];
        if(m->buffer->base==b->base && m->buffer->width==b->width && m->offset==off && m->type==type && m->count==count) break;
        slot=(slot+1)&(c->memo_slots_cap-1);
    }
    return slot;
}
static int ensure_memo_slots(wv_context *c) {
    if(c->memo_count>=UINT32_MAX-1) { c->error=WV_NOMEM; return 0; }
    if(c->memo_slots_cap && c->memo_hash_count+1<=c->memo_slots_cap/2) return 1;
    size_t cap=c->memo_slots_cap?c->memo_slots_cap*2:64;
    if(cap<c->memo_slots_cap || cap>UINT32_MAX) { c->error=WV_NOMEM; return 0; }
    size_t extra=(cap-c->memo_slots_cap)*sizeof(*c->memo_slots);
    if(c->retained>c->limit || extra>c->limit-c->retained) { c->error=WV_NOMEM; return 0; }
    uint32_t *slots=realloc(c->memo_slots,cap*sizeof(*slots));
    if(!slots) { c->error=WV_NOMEM; return 0; }
    c->memo_slots=slots;c->memo_slots_cap=cap;c->retained+=extra;
    memset(slots,0,cap*sizeof(*slots));
    for(size_t i=0;i<c->memo_count;i++) if(c->memo[i].type!=UINT16_MAX) {
        wv_memo *m=&c->memo[i];size_t slot=memo_slot(c,m->buffer,m->offset,m->type,m->count);
        slots[slot]=(uint32_t)i+1;m->bucket=(uint32_t)slot+1;
    }
    return 1;
}
static uint8_t *range(wv_context *c,const wv_buffer *b,uint64_t offset,uint64_t bytes) {
    if(offset>b->bytes || bytes>b->bytes-offset) { c->error=WV_RANGE; return NULL; }
    if(!b->base) { if(bytes) c->error=WV_RANGE; return NULL; }
    return b->base+(size_t)offset;
}
static uint64_t load(const void *p,int width) {
    uint64_t n=0; memcpy(&n,p,(size_t)width); return n;
}
uint64_t wv_argument_member(wv_context *c,int index,size_t off32,size_t off64,int w32,int w64) {
    const wv_buffer *b=&c->buffers[index];
    uint64_t off=b->width==32?off32:off64; int width=b->width==32?w32:w64;
    if(!b->present || off>UINT64_MAX-c->input[index]) { c->error=WV_RANGE; return 0; }
    uint8_t *p=range(c,b,c->input[index]+off,(uint64_t)width);
    return p?load(p,width):0;
}
uint64_t wv_argument_value(wv_context *c,int index,int width) {
    if(!width) width=c->buffers[index].width/8;
    return wv_argument_member(c,index,0,0,width,width);
}
static void *string_at(wv_context *c,const wv_buffer *b,uint64_t off) {
    uint8_t *p=range(c,b,off,1);
    if(!p) return NULL;
    if(!memchr(p,0,(size_t)(b->bytes-off))) { c->error=WV_RANGE; return NULL; }
    return p;
}
void *wv_string_root(wv_context *c,int i) { return string_at(c,&c->buffers[i],c->input[i]); }

static void *marshal(wv_context *,const wv_buffer *,int,uint64_t,uint64_t,int,unsigned);
static void clear_pointers(int type,uint8_t *native,uint64_t count) {
    const wv_type *t=&wv_types[type];
    if(t->kind!=WV_STRUCT) return;
    for(uint64_t i=0;i<count;i++) for(unsigned j=0;j<t->fields_count;j++) {
        const wv_field *f=&t->fields[j]; uint8_t *p=native+i*t->size64+f->off64;
        if(f->flags&WV_POINTER) { if(!(f->flags&WV_EXTERNAL)) memset(p,0,8); }
        else if(wv_types[f->type].convert64) clear_pointers(f->type,p,f->count);
    }
}
void wv_abort(wv_context *c) {
    // Clear every borrowed address, including copied structure pointer fields,
    // before the storage lease ends. Scratch bytes and capacity remain reusable.
    for(size_t i=0;i<c->memo_count;i++) {
        wv_memo *m=&c->memo[i];
        if(m->type==UINT16_MAX) memset(m->native,0,(size_t)m->count*8);
        else clear_pointers(m->type,m->native,m->count);
        if(m->bucket) c->memo_slots[m->bucket-1]=0;
    }
    if(c->memo_count) memset(c->memo,0,c->memo_count*sizeof(*c->memo));
    if(c->write_count) memset(c->writes,0,c->write_count*sizeof(*c->writes));
    memset(c->args,0,sizeof(c->args)); memset(c->input,0,sizeof(c->input));
    memset(c->buffers,0,sizeof(c->buffers)); c->memo_count=c->write_count=c->memo_hash_count=0;
}
static int record_write(wv_context *c,const wv_buffer *b,uint64_t off,int type,uint64_t count,uint8_t *p) {
    if(!grow(c,(void**)&c->writes,&c->write_cap,c->write_count,sizeof(*c->writes))) return 0;
    c->writes[c->write_count++]=(wv_writeback){b,off,count,(uint16_t)type,p}; return 1;
}
static uint64_t field_count(const wv_buffer *b,const wv_field *f,const uint8_t *src) {
    int off=b->width==32?f->len32:f->len64;
    if(off<0) return f->count;
    uint64_t n=load(src+off,b->width==32?f->len_width32:f->len_width64);
    return n/f->divisor+(f->roundup && n%f->divisor!=0);
}
static void *pointer_array(wv_context *c,const wv_buffer *b,uint64_t off,uint64_t count,int type,int strings,unsigned depth) {
    uint64_t width=b->width/8;
    if(count>UINT64_MAX/width || count>SIZE_MAX/8) { c->error=WV_RANGE; return NULL; }
    uint8_t *src=range(c,b,off,count*width);
    if(!src || !count) return src;
    uint8_t *dst=allocate(c,count*8);
    if(!dst) return NULL;
    memset(dst,0,(size_t)count*8);
    if(!grow(c,(void**)&c->memo,&c->memo_cap,c->memo_count,sizeof(*c->memo))) return NULL;
    c->memo[c->memo_count++]=(wv_memo){b,off,count,UINT16_MAX,0,0,0,dst};
    for(uint64_t i=0;i<count;i++) {
        uint64_t target=load(src+i*width,(int)width); void *p=NULL;
        if(target) p=strings?string_at(c,b,target):marshal(c,b,type,target,1,0,depth+1);
        memcpy(dst+i*8,&p,8); if(c->error) return NULL;
    }
    return dst;
}
static int copy_struct(wv_context *c,const wv_buffer *b,int type,const uint8_t *src,uint8_t *dst,int output,unsigned depth) {
    const wv_type *t=&wv_types[type]; int small=b->width==32;
    for(unsigned j=0;j<t->fields_count;j++) {
        const wv_field *f=&t->fields[j]; const uint8_t *s=src+(small?f->off32:f->off64); uint8_t *d=dst+f->off64;
        if(f->flags&WV_POINTER) {
            uint64_t off=load(s,(f->flags&WV_EXTERNAL)?8:(small?4:8)); void *p=NULL;
            if(f->flags&WV_EXTERNAL) { memcpy(d,&off,8); continue; }
            if(off) {
                uint64_t count=field_count(b,f,src);
                // Vulkan ignores these descriptor members for other descriptor
                // kinds. Do not follow or validate unused guest pointers.
                if(f->flags&(WV_DESC_IMAGE|WV_DESC_BUFFER|WV_DESC_TEXEL)) {
                    const wv_field *selector=&t->fields[6];
                    uint32_t descriptor=(uint32_t)load(src+(small?selector->off32:selector->off64),4);
                    if((f->flags&WV_DESC_IMAGE) && !(descriptor<=VK_DESCRIPTOR_TYPE_STORAGE_IMAGE || descriptor==VK_DESCRIPTOR_TYPE_INPUT_ATTACHMENT)) count=0;
                    if((f->flags&WV_DESC_BUFFER) && !(descriptor>=VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER && descriptor<=VK_DESCRIPTOR_TYPE_STORAGE_BUFFER_DYNAMIC)) count=0;
                    if((f->flags&WV_DESC_TEXEL) && !(descriptor==VK_DESCRIPTOR_TYPE_UNIFORM_TEXEL_BUFFER || descriptor==VK_DESCRIPTOR_TYPE_STORAGE_TEXEL_BUFFER)) count=0;
                }
                if(f->flags&WV_PNEXT) {
                    uint8_t *head=range(c,b,off,4);
                    if(!head) return 0;
                    int next=wv_chain_type((uint32_t)load(head,4));
                    if(next<0) { c->error=WV_UNSUPPORTED; return 0; }
                    p=marshal(c,b,next,off,1,output || (f->flags&WV_WRITE),depth+1);
                } else if(f->flags&WV_DOUBLE) p=pointer_array(c,b,off,count,f->type,f->flags&WV_STRING,depth+1);
                else if(f->flags&WV_STRING) p=string_at(c,b,off);
                else if(count) p=marshal(c,b,f->type,off,count,f->flags&WV_WRITE,depth+1);
            }
            memcpy(d,&p,8); if(c->error) return 0;
        } else {
            const wv_type *sub=&wv_types[f->type];
            if(sub->kind==WV_STRUCT && (small?sub->convert32:sub->convert64)) {
                for(uint32_t k=0;k<f->count;k++) if(!copy_struct(c,b,f->type,s+k*(small?sub->size32:sub->size64),d+k*sub->size64,output,depth+1)) return 0;
            } else if(!small) {
                // The entire 64-bit record was copied once. Only pointer
                // fields and embedded records needing relocation remain.
                continue;
            } else if(small && sub->size32!=sub->size64) {
                for(uint32_t k=0;k<f->count;k++) { uint64_t v=load(s+k*sub->size32,(int)sub->size32); memcpy(d+k*sub->size64,&v,sub->size64); }
            } else memcpy(d,s,(size_t)f->count*sub->size64);
        }
    }
    return 1;
}
static void *marshal(wv_context *c,const wv_buffer *b,int type,uint64_t off,uint64_t count,int output,unsigned depth) {
    if(c->error) return NULL;
    if(depth>64) { c->error=WV_CYCLE; return NULL; }
    if(type<0 || (size_t)type>=wv_type_count) { c->error=WV_UNSUPPORTED; return NULL; }
    const wv_type *t=&wv_types[type]; int small=b->width==32;
    uint32_t size=small?t->size32:t->size64;
    if(count>UINT64_MAX/size || count>SIZE_MAX/t->size64) { c->error=WV_RANGE; return NULL; }
    uint8_t *src=range(c,b,off,count*size);
    if(!src || !count) return src;
    // Borrow POD arrays directly when layouts and alignment are compatible.
    if(!(small?t->convert32:t->convert64) && (uintptr_t)src%t->align64==0) return src;
    if(!ensure_memo_slots(c)) return NULL;
    size_t slot=memo_slot(c,b,off,type,count);
    if(c->memo_slots[slot]) {
        wv_memo *m=&c->memo[c->memo_slots[slot]-1];
        if(m->active) { c->error=WV_CYCLE; return NULL; }
        if(output && !m->output) { if(!record_write(c,b,off,type,count,m->native)) return NULL; m->output=1; }
        return m->native;
    }
    uint8_t *dst=allocate(c,count*t->size64);
    if(!dst) return NULL;
    if(!small && t->kind==WV_STRUCT) memcpy(dst,src,(size_t)count*t->size64);
    else memset(dst,0,(size_t)count*t->size64);
    if(!grow(c,(void**)&c->memo,&c->memo_cap,c->memo_count,sizeof(*c->memo))) return NULL;
    size_t memo=c->memo_count++;
    c->memo[memo]=(wv_memo){b,off,count,(uint16_t)type,1,(uint8_t)output,(uint32_t)slot+1,dst};
    c->memo_slots[slot]=(uint32_t)memo+1;
    c->memo_hash_count++;
    if(output && !record_write(c,b,off,type,count,dst)) return NULL;
    if(t->kind==WV_STRUCT) {
        for(uint64_t i=0;i<count;i++) if(!copy_struct(c,b,type,src+i*size,dst+i*t->size64,output,depth+1)) return NULL;
    } else if(small && t->size32!=t->size64) {
        for(uint64_t i=0;i<count;i++) { uint64_t n=load(src+i*size,(int)size); memcpy(dst+i*t->size64,&n,t->size64); }
    } else memcpy(dst,src,(size_t)count*t->size64);
    c->memo[memo].active=0; return dst;
}
void *wv_root(wv_context *c,int index,int type,uint64_t count,int output) {
    return marshal(c,&c->buffers[index],type,c->input[index],count,output,0);
}
static int copy_back(wv_context *c,int type,uint8_t *src,const uint8_t *native,uint64_t count,int small) {
    const wv_type *t=&wv_types[type]; uint32_t size=small?t->size32:t->size64;
    if(t->kind==WV_STRUCT) {
        for(uint64_t i=0;i<count;i++) for(unsigned j=0;j<t->fields_count;j++) {
            const wv_field *f=&t->fields[j];
            if(f->flags&WV_POINTER) continue; // preserve original guest offsets
            if(!copy_back(c,f->type,src+i*size+(small?f->off32:f->off64),native+i*t->size64+f->off64,f->count,small)) return 0;
        }
    } else if(small && t->size32!=t->size64) {
        for(uint64_t i=0;i<count;i++) {
            uint64_t v=load(native+i*t->size64,(int)t->size64);
            if(t->size32==4 && v>UINT32_MAX) { c->error=WV_WIDTH; return 0; }
            memcpy(src+i*size,&v,size);
        }
    } else memcpy(src,native,(size_t)count*size);
    return 1;
}
int wv_complete(wv_context *c) {
    for(size_t i=0;i<c->write_count && !c->error;i++) {
        wv_writeback *w=&c->writes[i];
        uint8_t *p=w->buffer->base+w->offset;
        copy_back(c,w->type,p,w->native,w->count,w->buffer->width==32);
    }
    int err=c->error; wv_abort(c); return err;
}
int wv_invoke(wv_context *c,int command) {
    c->error=wv_prepare(c,command);
    if(c->error) { int err=c->error; wv_abort(c); return err; }
    c->result=wv_dispatch(command,c->args);
    return wv_complete(c);
}
void wv_copy(uint64_t destination,uint64_t source,size_t bytes) { memmove((void*)(uintptr_t)destination,(const void*)(uintptr_t)source,bytes); }
