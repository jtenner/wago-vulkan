#!/usr/bin/env python3
"""Development only: regenerate the integer Wasm32 trampoline and ABI layouts.
Requires Python 3 and wasm-tools. No tool is needed by the smoke-test runner.
"""
import json
import pathlib
import re
import subprocess

here = pathlib.Path(__file__).resolve().parent
root = here.parents[1]
imports, exports = [], []
for line in (root / 'abi/vulkan.wasm32.txt').read_text().splitlines():
    match = re.fullmatch(r'(\w+)\((.*?)\) -> (\w+)', line)
    if not match:
        continue
    name, arguments, result = match.groups()
    types = [arg.split(': ')[1] for arg in arguments.split(', ') if arg]
    if any(t not in ('i32', 'i64') for t in types):
        continue
    signature = ''.join(f' (param {t})' for t in types)
    if result != 'void':
        signature += f' (result {result})'
    imports.append(f'(import "vulkan.wasm32" "{name}" (func ${name}{signature}))')
    exports.append(f'(func (export "{name}"){signature} ' +
                   ' '.join(f'local.get {i}' for i in range(len(types))) + f' call ${name})')
for name in ('readMapped', 'writeMapped'):
    signature = ' (param i64 i32 i32)'
    imports.append(f'(import "vulkan.wasm32" "{name}" (func ${name}{signature}))')
    exports.append(f'(func (export "{name}"){signature} local.get 0 local.get 1 local.get 2 call ${name})')
wat = '(module\n' + '\n'.join(imports) + '\n(memory (export "memory") 256)\n' + '\n'.join(exports) + '\n)\n'
(here / 'guest.wat').write_text(wat)
subprocess.run(['wasm-tools', 'parse', str(here / 'guest.wat'), '-o', str(here / 'guest.wasm')], check=True)
layouts = json.loads((root / 'abi/layouts.json').read_text())
names = set(re.findall(r'"(Vk\w+)"', (here / 'main.go').read_text()))
(here / 'layouts.json').write_text(json.dumps({name: layouts[name]['32'] for name in sorted(names)}, indent=2) + '\n')
