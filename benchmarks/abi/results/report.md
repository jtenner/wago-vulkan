# Wago GC ABI measurements

Median of five 200 ms Go benchmark samples per case; Linux/amd64, AMD Ryzen 7 8845HS, Go 1.27.1, GOMAXPROCS=1, Wago commit `9b0d97efdc76` with the documented benchmark-only accessor overlay.

One operation processes the whole batch. All times below are microseconds per batch. The native consumer reads every field of a `VkViewport` array; no Vulkan driver or GPU work is measured.

## Submit existing data

| Items | Packed i32 | Packed i64 | Optimized structs | Field-by-field structs |
|---:|---:|---:|---:|---:|
| 100 | 1.79 | 1.77 | 4.84 | 25.90 |
| 1,000 | 2.88 | 2.91 | 28.84 | 229.27 |
| 10,000 | 13.97 | 13.68 | 268.33 | 2,246.45 |
| 100,000 | 133.70 | 131.15 | 2,677.59 | 21,753.82 |

## Update one float per item and submit

| Items | Packed i32 | Packed i64 | Optimized structs | Field-by-field structs |
|---:|---:|---:|---:|---:|
| 100 | 2.29 | 2.58 | 6.03 | 26.20 |
| 1,000 | 7.44 | 10.86 | 43.20 | 258.07 |
| 10,000 | 59.08 | 91.83 | 383.62 | 2,564.11 |
| 100,000 | 576.89 | 882.16 | 3,722.06 | 23,238.52 |

## Rewrite all fields in reused storage and submit

| Items | Packed i32 | Packed i64 | Optimized structs | Field-by-field structs |
|---:|---:|---:|---:|---:|
| 100 | 4.01 | 2.99 | 8.06 | 28.05 |
| 1,000 | 25.45 | 14.96 | 59.80 | 263.98 |
| 10,000 | 241.44 | 140.67 | 608.87 | 2,603.63 |
| 100,000 | 2,377.50 | 1,311.63 | 4,411.43 | 21,370.18 |

## Construct fresh data and submit

| Items | Packed i32 | Packed i64 | Optimized structs | Field-by-field structs |
|---:|---:|---:|---:|---:|
| 100 | 4.23 | 3.29 | 7.73 | 24.62 |
| 1,000 | 26.99 | 15.78 | 124.00 | 289.04 |
| 10,000 | 264.13 | 157.41 | 1,369.88 | 3,044.26 |
| 100,000 | 2,549.05 | 1,394.20 | 12,238.77 | 27,308.43 |

## Guest writes only: update one float

| Items | Packed i32 | Packed i64 | GC structs |
|---:|---:|---:|---:|
| 100 | 0.76 | 1.18 | 1.45 |
| 1,000 | 4.98 | 8.81 | 10.13 |
| 10,000 | 63.26 | 115.38 | 98.52 |
| 100,000 | 592.15 | 991.05 | 1,008.32 |

## Guest writes only: rewrite all fields

| Items | Packed i32 | Packed i64 | GC structs |
|---:|---:|---:|---:|
| 100 | 3.21 | 1.96 | 3.12 |
| 1,000 | 29.95 | 16.22 | 29.63 |
| 10,000 | 306.39 | 162.30 | 291.76 |
| 100,000 | 2,987.09 | 1,642.76 | 2,884.75 |

## Interpretation and limits

Packed arrays bypass host structure copying. The optimized struct path still resolves N object references and copies N payloads, but avoids repeated array metadata checks. Field-by-field access adds six checked loads per item. All host paths reuse native scratch and field scratch.

For pointer-free, reused viewport data, packed buffers have the fastest bridge. Compare the guest-only rows before deciding whether i32 or i64 is preferable for caller writes; fewer stores can favor i64 when building a complete word, whereas updating half a word requires read–modify–write.

Reused full round trips report 624 Go bytes and two Go allocations per batch in this run, independent of item count. These include Wago boundary machinery and the borrow; they do not imply per-item allocation. Guest-only writes report zero Go allocations. Fresh-construction Go bytes vary because runtime metadata can grow during allocation/collection; see the CSV for per-case measurements. Go benchmark allocation metrics exclude native scratch and the Wasm GC heap.

Structured paths retain an additional 24*N bytes of reusable native scratch. Fresh construction creates N+1 guest GC objects for structs versus one for packed storage; GC headers, reference slots, allocator overhead and collection work are additional. Reused phases allocate no new guest objects.

`VkViewport` is deliberately favorable to bulk struct copying: its GC payload layout is already native-compatible. Mixed-width structures, pointers, pNext chains and output writeback are not covered. These numbers are not a general ratio for every Vulkan function.

Initial exploratory samples are retained in `raw.txt`. Final tables use `packed.txt`, `optimized-structs.txt` and `guest-writes.txt`; the field-by-field variant was improved to reuse its scalar scratch before the final samples.

Correctness checks compare all fields through the native checksum, test preservation of adjacent i64 halves, force collection between phases, and check seed wrap. Benchmark loops verify their final results outside the timed interval.
