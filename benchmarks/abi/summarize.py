#!/usr/bin/env python3
"""Summarize final repeated measurements without third-party dependencies."""
import csv, json, pathlib, re, statistics

here = pathlib.Path(__file__).resolve().parent
results = here / "results"
inputs = ["packed.txt", "optimized-structs.txt", "guest-writes.txt"]
groups = {}
for filename in inputs:
    text = (results / filename).read_text()
    if "\nPASS\n" not in text:
        raise SystemExit(f"Incomplete benchmark run: {filename}")
    for line in text.splitlines():
        m = re.match(r"Benchmark(?:ABI|GuestWrites)/([^/]+)/(\d+)/([^\s]+)\s+\d+\s+([\d.]+) ns/op.*?([\d.]+) B/op\s+([\d.]+) allocs/op", line)
        if not m:
            continue
        phase, count, kind, ns, allocated, allocs = m.groups()
        key = (phase, int(count), kind)
        groups.setdefault(key, []).append((float(ns), float(allocated), float(allocs)))
rows = []
for (phase, count, kind), samples in sorted(groups.items()):
    if len(samples) != 5:
        raise SystemExit(f"Expected five samples: {phase}/{count}/{kind}: {len(samples)}")
    times = [s[0] for s in samples]
    rows.append(dict(phase=phase, items=count, representation=kind, samples=len(times),
                     median_ns=statistics.median(times), min_ns=min(times), max_ns=max(times),
                     median_ns_per_item=statistics.median(times)/count,
                     median_go_bytes=statistics.median(s[1] for s in samples),
                     median_go_allocations=statistics.median(s[2] for s in samples),
                     native_scratch_bytes=24*count if kind.startswith("structs_") else 0,
                     guest_objects_per_construct=count+1 if kind.startswith("structs_") else 1))
(results / "summary.json").write_text(json.dumps(rows, indent=2)+"\n")
with (results / "summary.csv").open("w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0]), lineterminator="\n")
    w.writeheader()
    w.writerows(rows)
lookup = {(r["phase"], r["items"], r["representation"]): r for r in rows}
labels = {"bridge": "Submit existing data", "update": "Update one float per item and submit", "rebuild": "Rewrite all fields in reused storage and submit", "construct": "Construct fresh data and submit", "update_only": "Guest writes only: update one float", "rebuild_only": "Guest writes only: rewrite all fields"}
report = ["# Wago GC ABI measurements", "", "Median of five 200 ms Go benchmark samples per case; Linux/amd64, AMD Ryzen 7 8845HS, Go 1.27.1, GOMAXPROCS=1, Wago commit `9b0d97efdc76` with the documented benchmark-only accessor overlay.", "", "One operation processes the whole batch. All times below are microseconds per batch. The native consumer reads every field of a `VkViewport` array; no Vulkan driver or GPU work is measured.", ""]
for phase, title in labels.items():
    variants = ["packed32", "packed64", "structs_batch", "structs_fields"] if not phase.endswith("_only") else ["packed32", "packed64", "structs_bulk"]
    names = ["Packed i32", "Packed i64", "Optimized structs", "Field-by-field structs"] if not phase.endswith("_only") else ["Packed i32", "Packed i64", "GC structs"]
    report += ["## "+title, "", "| Items | "+" | ".join(names)+" |", "|---:|"+"---:|"*len(names)]
    for count in [100, 1000, 10000, 100000]:
        report.append("| "+f"{count:,}"+" | "+" | ".join(f'{lookup[phase,count,v]["median_ns"]/1000:,.2f}' for v in variants)+" |")
    report += [""]
report += ["## Interpretation and limits", "", "Packed arrays bypass host structure copying. The optimized struct path still resolves N object references and copies N payloads, but avoids repeated array metadata checks. Field-by-field access adds six checked loads per item. All host paths reuse native scratch and field scratch.", "", "For pointer-free, reused viewport data, packed buffers have the fastest bridge. Compare the guest-only rows before deciding whether i32 or i64 is preferable for caller writes; fewer stores can favor i64 when building a complete word, whereas updating half a word requires read–modify–write.", "", "Reused full round trips report 624 Go bytes and two Go allocations per batch in this run, independent of item count. These include Wago boundary machinery and the borrow; they do not imply per-item allocation. Guest-only writes report zero Go allocations. Fresh-construction Go bytes vary because runtime metadata can grow during allocation/collection; see the CSV for per-case measurements. Go benchmark allocation metrics exclude native scratch and the Wasm GC heap.", "", "Structured paths retain an additional 24*N bytes of reusable native scratch. Fresh construction creates N+1 guest GC objects for structs versus one for packed storage; GC headers, reference slots, allocator overhead and collection work are additional. Reused phases allocate no new guest objects.", "", "`VkViewport` is deliberately favorable to bulk struct copying: its GC payload layout is already native-compatible. Mixed-width structures, pointers, pNext chains and output writeback are not covered. These numbers are not a general ratio for every Vulkan function.", "", "Initial exploratory samples are retained in `raw.txt`. Final tables use `packed.txt`, `optimized-structs.txt` and `guest-writes.txt`; the field-by-field variant was improved to reuse its scalar scratch before the final samples.", "", "Correctness checks compare all fields through the native checksum, test preservation of adjacent i64 halves, force collection between phases, and check seed wrap. Benchmark loops verify their final results outside the timed interval.", ""]
(results / "report.md").write_text("\n".join(report))
print("Wrote summary.csv, summary.json and report.md")
for phase in ["update", "update_only"]:
    print(labels[phase])
    for count in [100,1000,10000,100000]:
        ks = ["packed32", "packed64", "structs_batch", "structs_fields"] if phase == "update" else ["packed32", "packed64", "structs_bulk"]
        print(count, {k: round(lookup[phase,count,k]["median_ns"]/1000, 2) for k in ks})
