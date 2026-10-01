# GC ABI benchmark

Actual Wasm GC guests run in pinned Wago and pass arrays of `VkViewport` data to
one synchronous native C consumer. This isolates ABI cost: it does not call a
Vulkan driver, create a device, or measure GPU work. Every item has six `f32`
fields and the same 24-byte native representation.

Variants:

- `packed32`: mutable GC `array<i32>`, one element per float bit pattern.
- `packed64`: mutable GC `array<i64>`, two floats per element. A single-field
  update preserves the other half using a read–modify–write.
- `structs_fields`: GC array of references to actual six-field GC structs.
  Host reads six checked scalar fields and marshals into reusable native scratch.
- `structs_bulk`: the same GC structs, with a benchmark-only checked bulk payload
  accessor and one 24-byte copy per item. This is a favorable case: the GC struct
  payload happens to match `VkViewport`. It is not representative of arbitrary
  Vulkan structures, nested references, unions or pointer relocation.
- `structs_batch`: an optimized bulk traversal inside the collector. Checks the
  reference array once, resolves and checks every struct, then copies 24 bytes
  per item. Avoids repeated public array-access validation. This is the fastest
  structured marshaller tested, using the same favorable six-float schema.

Phases:

- `bridge`: submit already constructed data.
- `update`: update each item's width, then submit; reuse buffers and objects.
- `rebuild`: write all six fields of each existing item, then submit.
- `construct`: allocate new arrays/objects, populate and submit on every call;
  includes guest allocation and collection. Structs allocate N+1 objects;
  packed variants allocate one. Native scratch remains reused in all phases.
- `update_only` and `rebuild_only`: guest writes without host submission. A final
  untimed submission checks the result. Measures the caller-side packing cost.

Each operation is one Go → Wasm → host → C → return round trip for the entire
batch, with an observable checksum reading every native field. Compilation,
initialization, scratch allocation and warmup are outside timed regions.
The host import returns void, like `vkCmdSetViewport`; the native checksum is
retained by the host and checked outside the timed loop.
Go's `B/op` and `allocs/op` do **not** include native scratch or Wasm GC heap
allocation. Struct marshalling retains a separate `24*N`-byte native buffer;
packed inputs go directly to C. No guest pointer survives the storage borrow.

The pinned public Wago storage API has no GC struct field accessor. `overlay/`
contains two small benchmark-only extensions. `prepare.py` copies the pinned
runtime into ignored `.bench-cache/wago` and adds these files; neither the
installed module cache nor another Wago checkout is modified. Both packed and
structured variants run against the same overlaid runtime.

Prerequisites: Go 1.25, Python 3, `wasm-tools`, a C compiler and Vulkan headers.

From the project root:

```sh
python3 benchmarks/abi/run.py
```

The runner prepares the runtime overlay and guests, runs correctness checks,
then records five samples per case and writes JSON/CSV and a Markdown report.
Read the current [results](results/report.md).

To run all individual variants, including the intermediate `structs_bulk` path:

```sh
GOWORK="$PWD/.bench-cache/go.work" go test -tags abi_benchmark ./benchmarks/abi -run '^$' -bench 'BenchmarkABI|BenchmarkGuestWrites' -benchmem -benchtime=200ms -count=5 -cpu=1
```

Measured sizes: 100, 1,000, 10,000 and 100,000 items. Results apply to this
schema, Wago revision, GC profile and machine, not every Vulkan command.
