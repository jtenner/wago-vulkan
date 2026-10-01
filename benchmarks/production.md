# Implemented wrapper measurements

These measurements use the production plugin, the pinned public Wago runtime,
and Mesa lavapipe. There is no runtime overlay. Source:
[integration_test.go](../integration_test.go); raw results:
[production.txt](production.txt).

Linux amd64, AMD Ryzen 7 8845HS, Go 1.27.1; `-cpu=1`, three 200 ms samples per
case. Median times for one Go → Wasm → host → Vulkan → return round trip:

| Interface | `vkGetDeviceQueue` | Go B/op | Go allocs/op | `vkDeviceWaitIdle` | Go B/op | Go allocs/op |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Packed i32 GC | 2.152 µs | 624 | 2 | 8.362 µs | 0 | 0 |
| Wasm32 memory | 1.013 µs | 48 | 1 | 7.852 µs | 0 | 0 |
| Wasm64 memory | 0.927 µs | 48 | 1 | 8.044 µs | 0 | 0 |

Queue lookup exercises a pointer-bearing import with an eight-byte output in
reusable guest storage. Device idle exercises a scalar-only direct trampoline.
Both include driver execution; device-idle times largely reflect the software
driver and must not be interpreted as scalar marshalling overhead.

Compilation, device creation and warmup are excluded. Guest buffers and the
native call-frame pool are reused. Go heap allocation profiling attributes the
steady-state GC/reference allocation to Wago's `dispatchSyncHostReference` and
the storage-view allocation to `WithGuestStorage`; reusable wrapper callbacks
add no per-call Go closure allocation. Native scratch and guest allocations are
not counted by Go's B/op metric.
These samples include explicit Go buffer pinning; the measured steady-state
Go allocation counts remain unchanged.

The sanitizer-backed native tests independently check pointer identity for
aligned `VkViewport` batches of 100, 1,000, 10,000 and 100,000 items, in both
wire widths. Every compatible batch reaches the fake Vulkan driver at the
original buffer address, and retained native memory does not grow with the
batch. These are correctness/zero-copy checks, not GPU performance measurements.
Unaligned input takes the conversion path; pointer-bearing structures use
reusable native scratch and remain proportional to the structures translated.
Additional fake-driver tests translate batches of 100, 1,000, 10,000 and 50,000 graphics
pipeline descriptions with nested shader stages and shared specialization data.
They verify shared native pointer identity, output handles, cleared lookup
entries, and unchanged retained memory on the repeated call. These exercise the
hash table's growth and reuse without invoking costly pipeline compilation.
They also bound scratch block visits by graph size on fresh and warmed calls,
catching the former quadratic scan of full retained blocks. Production builds
omit the test-only visit counter.

The focused scratch benchmark uses a fresh frame per batch size followed by ten
warmed calls. After replacing the head-first scan with a small-block cursor and
a balanced index of all remaining block capacity:

| Pipeline descriptions | Previous warmed block visits | Current warmed block visits |
| --- | ---: | ---: |
| 10,000 | 80,891 | 15,013 |
| 50,000 | 1,868,714 | 75,053 |

These count allocator work rather than GPU execution. The 50,000-item native
translation measured 9.04 ms median in the current run; the earlier review run
measured 9.08 ms. Timing varies between runs, while the visit counts directly
verify that the repeated full-block scans are gone. The regression also fails
when run against the previous allocator with the same visit instrumentation.
Current native samples are in [scratch.txt](scratch.txt). Separate tight-budget
tests verify reordered and shrinking arrays, large-block sharing, and skipped
small-block tails without retained-memory growth. A deterministic stress test
checks 60,600 allocations against tree invariants and a linear reuse oracle.

Reproduce from the repository root:

```sh
VK_DRIVER_FILES=/usr/share/vulkan/icd.d/lvp_icd.json \
  go test -tags integration -run '^$' -bench BenchmarkVulkan \
  -benchmem -benchtime=200ms -count=3 -cpu=1
bash scripts/test-native.sh
python3 scripts/benchmark-scratch.py
```

The [original packed-array versus GC-struct experiment](abi/results/report.md)
measures different work: a six-float checksum consumer with a benchmark-only
struct accessor. Its timings should not be compared directly with these Vulkan
driver calls.
