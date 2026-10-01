#!/usr/bin/env python3
"""Generate identical viewport workloads using actual Wasm GC instructions."""
import pathlib, subprocess

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "generated"
OUT.mkdir(exist_ok=True)

def values(seed):
    return ["(f32.convert_i32_u (local.get $i))", "(f32.const 2)",
            f"(f32.add (f32.const 640) (f32.convert_i32_u {seed}))",
            "(f32.const 480)", "(f32.const 0)", "(f32.const 1)"]

for kind in ["packed32", "packed64", "structs"]:
    structured = kind == "structs"
    width = 32 if kind == "packed32" else 64
    words = 6 if width == 32 else 3
    ty = "(type $item (struct " + " ".join("(field (mut f32))" for _ in range(6)) + "))\n" if structured else ""
    ty += "(type $items (array (mut " + ("(ref null $item)" if structured else f"i{width}") + ")))"
    def index(j):
        return f"(i32.add (i32.mul (local.get $i) (i32.const {words})) (i32.const {j}))"
    def item():
        return "(ref.as_non_null (array.get $items (global.get $items) (local.get $i)))"
    def store_all(seed):
        vs = values(seed)
        if structured:
            return "(local.set $obj (array.get $items (global.get $items) (local.get $i)))\n" + "\n".join(f"(struct.set $item {j} (ref.as_non_null (local.get $obj)) {v})" for j, v in enumerate(vs))
        if width == 32:
            return "\n".join(f"(array.set $items (global.get $items) {index(j)} (i32.reinterpret_f32 {v}))" for j, v in enumerate(vs))
        return "\n".join(f"(array.set $items (global.get $items) {index(j)} (i64.or (i64.extend_i32_u (i32.reinterpret_f32 {vs[j*2]})) (i64.shl (i64.extend_i32_u (i32.reinterpret_f32 {vs[j*2+1]})) (i64.const 32))))" for j in range(3))
    def loop(body):
        return f"""(local.set $i (i32.const 0))
        (block $done (loop $loop
          (br_if $done (i32.ge_u (local.get $i) (global.get $n)))
          {body}
          (local.set $i (i32.add (local.get $i) (i32.const 1)))
          (br $loop)))"""
    allocate = "(global.set $items (array.new_default $items " + ("(global.get $n)" if structured else f"(i32.mul (global.get $n) (i32.const {words}))") + "))"
    if structured:
        allocate += loop("(array.set $items (global.get $items) (local.get $i) (struct.new $item " + " ".join(values("(i32.const 0)")) + "))")
    construct = allocate.replace(" ".join(values("(i32.const 0)")), " ".join(values("(global.get $tick)"))) if structured else allocate + "(call $build (global.get $tick))"
    update_value = "(f32.add (f32.const 640) (f32.convert_i32_u (global.get $tick)))"
    if structured:
        update = f"(struct.set $item 2 {item()} {update_value})"
    elif width == 32:
        update = f"(array.set $items (global.get $items) {index(2)} (i32.reinterpret_f32 {update_value}))"
    else:
        update = f"(array.set $items (global.get $items) {index(1)} (i64.or (i64.and (array.get $items (global.get $items) {index(1)}) (i64.const -4294967296)) (i64.extend_i32_u (i32.reinterpret_f32 {update_value}))))"
    advance = "(global.set $tick (i32.and (i32.add (global.get $tick) (i32.const 1)) (i32.const 1023)))"
    wat = f"""(module
      {ty}
      (import "abi" "submit" (func $submit (param i32 (ref null $items))))
      (global $items (mut (ref null $items)) (ref.null $items))
      (global $n (mut i32) (i32.const 0))
      (global $tick (mut i32) (i32.const 0))
      (func $build (param $seed i32) (local $i i32) {"(local $obj (ref null $item))" if structured else ""}
        {loop(store_all('(local.get $seed)'))})
      (func (export "init") (param $count i32) (local $i i32)
        (global.set $n (local.get $count))
        (global.set $tick (i32.const 0))
        {allocate}
        {"" if structured else "(call $build (i32.const 0))"})
      (func $bridge (export "bridge")
        (call $submit (global.get $n) (global.get $items)))
      (func $update (export "update_only") (local $i i32)
        {advance}
        {loop(update)})
      (func (export "update") (call $update) (call $bridge))
      (func $rebuild (export "rebuild_only")
        {advance}
        (call $build (global.get $tick)))
      (func (export "rebuild") (call $rebuild) (call $bridge))
      (func (export "construct") (local $i i32)
        {advance}
        {construct}
        (call $bridge))
      (func (export "tick") (result i32) (global.get $tick))
    )"""
    path = OUT / (kind + ".wat")
    path.write_text('\n'.join(line.rstrip() for line in wat.splitlines()) + '\n')
    subprocess.run(["wasm-tools", "parse", str(path), "-o", str(path.with_suffix(".wasm"))], check=True)
    subprocess.run(["wasm-tools", "validate", str(path.with_suffix(".wasm"))], check=True)
print("Generated and validated three Wasm GC guests.")
