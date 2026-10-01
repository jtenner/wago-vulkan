// Include the implementation in this standalone test translation unit so tree
// invariants can be checked without adding an inspection API to the library.
#include "../bridge.c"
#include <assert.h>
#include <stdio.h>

static uint64_t seed=UINT64_C(0x1ecf97b5bd27a689);
static uint64_t next_value(void) {
    seed^=seed<<13;seed^=seed>>7;seed^=seed<<17;return seed;
}
static void check_tree(wv_block *b,wv_block *parent,size_t minimum,size_t maximum) {
    if(!b) return;
    assert(b->parent==parent && b->used<=b->capacity);
    assert(b->capacity>=minimum && b->capacity<=maximum);
    check_tree(b->left,b,minimum,b->capacity);check_tree(b->right,b,b->capacity,maximum);
    unsigned left=height(b->left),right=height(b->right);
    assert(b->height==1+(left>right?left:right));
    assert(left<=right+1 && right<=left+1);
    size_t available=b->capacity-b->used,capacity=b->capacity;
    if(b->left) {
        assert(b->left->capacity<=b->capacity);
        if(b->left->available>available) available=b->left->available;
        if(b->left->max_capacity>capacity) capacity=b->left->max_capacity;
    }
    if(b->right) {
        assert(b->right->capacity>=b->capacity);
        if(b->right->available>available) available=b->right->available;
        if(b->right->max_capacity>capacity) capacity=b->right->max_capacity;
    }
    assert(b->available==available && b->max_capacity==capacity);
}
static void request(wv_context *c,size_t bytes) {
    size_t aligned=(bytes+15)&~(size_t)15,retained=c->retained;
    int reusable=0;
    for(wv_block *b=c->blocks;b;b=b->next) if(aligned<=b->capacity-b->used) reusable=1;
    uint8_t *p=allocate(c,bytes);
    assert(p && !c->error && (uintptr_t)p%16==0);
    // The linear oracle ensures subtree summaries never hide reusable space.
    if(reusable) assert(c->retained==retained);
    if(bytes) { p[0]=1;p[bytes-1]=2; }
    check_tree(c->available_root,NULL,0,SIZE_MAX);
}
int main(void) {
    for(int order=0;order<3;order++) {
        wv_context *c=wv_new(128*1024*1024);assert(c);
        // Force ascending, descending and duplicate-capacity insertions before
        // exercising changing remaining capacities and both allocation paths.
        for(size_t i=0;i<200;i++) request(c,65552+(order==0?i:order==1?200-i:0)*16);
        for(int round=0;round<100;round++) {
            wv_reset(c);check_tree(c->available_root,NULL,0,SIZE_MAX);
            for(int i=0;i<200;i++) {
                uint64_t value=next_value();
                size_t bytes=value%5?16+(value>>8)%65000:65536+(value>>8)%262144;
                request(c,bytes);
            }
        }
        assert(c->retained<=c->limit);wv_free(c);
    }
    puts("PASS: 60,600 scratch allocations, AVL invariants, varying shapes and reset");
}
