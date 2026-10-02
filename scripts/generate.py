#!/usr/bin/env python3
"""Generate named, typed Wago imports and packed Vulkan ABI metadata from vk.xml.

Generation probes native C headers, checks every 64-bit layout, and computes
32-bit wire layouts with 64-bit Vulkan handles. Runtime has no XML/reflection.
"""
import argparse, hashlib, json, os, pathlib, re, shlex, subprocess, tempfile
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
ap = argparse.ArgumentParser()
ap.add_argument("--registry", default="/usr/share/vulkan/registry/vk.xml")
opts = ap.parse_args()
registry = pathlib.Path(opts.registry)
x = ET.parse(registry).getroot()
types = {t.get("name", t.findtext("name")): t for t in x.findall("types/type")}
commands = {c.findtext("proto/name"): c for c in x.findall("commands/command") if c.find("proto") is not None}
extensions = ["VK_KHR_surface", "VK_KHR_swapchain", "VK_KHR_xlib_surface", "VK_EXT_metal_surface"]
external_types = {"Display", "CAMetalLayer"}
native_commands = {
    "vkCreateMetalSurfaceEXT": "wv_create_metal_surface",
    "vkCreateXlibSurfaceKHR": "wv_create_xlib_surface",
    "vkGetPhysicalDeviceXlibPresentationSupportKHR": "wv_xlib_presentation_support",
}
names = [c.get("name") for f in x.findall("feature") if f.get("name") == "VK_VERSION_1_0" for c in f.findall("require/command")]
for e in x.findall("extensions/extension"):
    if e.get("name") in extensions:
        names += [c.get("name") for c in e.findall("require/command")]
names = sorted(set(names) - {"vkGetInstanceProcAddr", "vkGetDeviceProcAddr"})
# Keep the original command/type IDs stable when adding the Metal surface ABI.
# The IDs are internal, but preserving them keeps generated changes reviewable.
names = [n for n in names if n != 'vkCreateMetalSurfaceEXT'] + ['vkCreateMetalSurfaceEXT']
for c in commands.values():
    for p in list(c.findall("param")):
        if p.get("api", "vulkan") != "vulkan": c.remove(p)

def members(t):
    return [m for m in types[t].findall("member") if m.get("api", "vulkan") == "vulkan"]

def declaration(m):
    # Exclude registry prose comments, which can contain brackets and stars.
    return "".join(m.itertext()).split(m.findtext("name"))[0].strip()

def pointers(m):
    return declaration(m).count("*")

def array_extent(m):
    name = m.find("name")
    tail = (name.tail or "")
    enums = [e.text for e in m.findall("enum")]
    dims = re.findall(r"\[(\d+)\]", tail)
    if enums: return enums[0]
    if dims: return str(int(dims[0]))
    return None

constants = {e.get("name"): e.get("value") for e in x.findall("enums/enum") if e.get("value")}
def number(n):
    if n.isdigit(): return int(n)
    return int(constants[n], 0)

seen = set()
def visit(t):
    if t in seen: return
    seen.add(t)
    node = types.get(t)
    if node is not None and node.get("category") in ["struct", "union"]:
        for m in members(t): visit(m.findtext("type"))
for n in names:
    for p in commands[n].findall("param"): visit(p.findtext("type"))
seen.update(["uint64_t", "uint32_t", "char", "void", "size_t"])
metal_types = {'CAMetalLayer', 'VkMetalSurfaceCreateFlagsEXT', 'VkMetalSurfaceCreateInfoEXT'}
ordered = sorted(seen - metal_types) + sorted(seen & metal_types)
ids = {t: i for i, t in enumerate(ordered)}

def scalar(t, width):
    if t == "void": return 1, 1
    if t in external_types: return 8, 8  # native external object, never dereferenced
    if t in ["Window", "VisualID"]: return 8, 8
    if t == "size_t": return width//8, width//8
    if t in ["char", "uint8_t", "int8_t"]: return 1, 1
    if t in ["uint16_t", "int16_t"]: return 2, 2
    if t in ["float", "int", "uint32_t", "int32_t"]: return 4, 4
    if t in ["double", "uint64_t", "int64_t"]: return 8, 8
    node = types[t]
    if node.get("alias"): return scalar(node.get("alias"), width)
    cat = node.get("category")
    if cat == "handle": return 8, 8
    if cat == "enum": return 4, 4
    if cat == "funcpointer": return width//8, width//8
    underlying = node.findtext("type")
    if underlying: return scalar(underlying, width)
    raise ValueError("unknown scalar " + t)

layouts = {}
def layout(t, width):
    key = (t, width)
    if key in layouts: return layouts[key]
    node = types.get(t)
    if node is None or node.get("category") not in ["struct", "union"]:
        size, align = scalar(t, width)
        layouts[key] = dict(size=size, align=align, fields={})
        return layouts[key]
    union = node.get("category") == "union"
    pos, align, fields = 0, 1, {}
    for m in members(t):
        if pointers(m): size = a = 8 if m.findtext('type') in external_types else width//8
        else:
            sub = layout(m.findtext("type"), width)
            size, a = sub["size"], sub["align"]
        extent = array_extent(m)
        if extent: size *= number(extent)
        off = 0 if union else (pos+a-1)//a*a
        fields[m.findtext("name")] = off
        pos = max(pos, size) if union else off+size
        align = max(align, a)
    layouts[key] = dict(size=(pos+align-1)//align*align, align=align, fields=fields)
    return layouts[key]
for t in ordered:
    for w in [32, 64]: layout(t, w)

# Validate the host ABI rather than silently publishing guessed native layouts.
probe = ['#include "platform.h"', '#include <stdio.h>', '#include <stddef.h>', 'int main(void) {']
for t in ordered:
    if t == "void" or t in external_types: continue
    probe += [f'printf("{t} __sizeof %zu\\n", sizeof({t}));']
    if types.get(t) is not None and types[t].get("category") in ["struct", "union"]:
        for m in members(t):
            field = m.findtext("name")
            probe += [f'printf("{t} {field} %zu\\n", offsetof({t}, {field}));']
probe += ['}']
with tempfile.TemporaryDirectory() as d:
    p = pathlib.Path(d)
    (p/"probe.c").write_text("\n".join(probe))
    packages = ['vulkan'] + ([] if os.uname().sysname == 'Darwin' else ['x11'])
    flags = shlex.split(subprocess.check_output(['pkg-config', '--cflags', *packages], text=True))
    subprocess.run([os.environ.get('CC', 'cc'), '-I'+str(ROOT), *flags, str(p/"probe.c"), "-o", str(p/"probe")], check=True)
    for line in subprocess.check_output([str(p/"probe")], text=True).splitlines():
        t, field, value = line.split()
        expected = layout(t, 64)["size"] if field == "__sizeof" else layout(t, 64)["fields"][field]
        if expected != int(value): raise ValueError(f"native ABI mismatch: {t}.{field}: {expected} != {value}")

converted = {}
def needs(t, width):
    if (t,width) in converted: return converted[t,width]
    converted[t,width] = False
    node = types.get(t)
    if node is None or node.get("category") not in ["struct", "union"]:
        result = layout(t,width)["size"] != layout(t,64)["size"]
    else:
        result = layout(t,width) != layout(t,64) or any(pointers(m) and m.findtext("type") not in external_types or not pointers(m) and needs(m.findtext("type"),width) for m in members(t))
    converted[t,width] = bool(result)
    return bool(result)

def count_rule(t, m):
    length = m.get("len")
    if not length or length == "null-terminated": return -1,-1,0,0,1,0
    field = length.split(",")[0]
    div, roundup = 1,0
    if t == "VkShaderModuleCreateInfo" and m.findtext("name") == "pCode": field,div="codeSize",4
    if t == "VkPipelineMultisampleStateCreateInfo" and m.findtext("name") == "pSampleMask": field,div,roundup="rasterizationSamples",32,1
    source = next(f for f in members(t) if f.findtext("name") == field)
    return layout(t,32)["fields"][field],layout(t,64)["fields"][field],layout(source.findtext("type"),32)["size"],layout(source.findtext("type"),64)["size"],div,roundup

c = ['// Generated by scripts/generate.py. SPDX-License-Identifier: Apache-2.0 OR MIT (registry-derived declarations).', '#include "bridge.h"', '#include <string.h>', '#include <stdint.h>', 'static float wv_f32(uint64_t bits) { uint32_t b=(uint32_t)bits; float f; memcpy(&f,&b,4); return f; }']
for t in ordered:
    node = types.get(t)
    if node is None or node.get('category') not in ['struct','union']: continue
    c += [f'_Static_assert(sizeof({t}) == {layout(t,64)["size"]}, "{t} native size");']
    for m in members(t):
        name = m.findtext('name')
        c += [f'_Static_assert(offsetof({t}, {name}) == {layout(t,64)["fields"][name]}, "{t}.{name} native offset");']
for t in ordered:
    node = types.get(t)
    if node is None or node.get("category") != "struct": continue
    c += [f'static const wv_field fields_{t}[] = {{']
    for m in members(t):
        name, mt = m.findtext("name"), m.findtext("type")
        flags=[]
        if pointers(m):
            flags.append("WV_POINTER")
            if pointers(m)>1: flags.append("WV_DOUBLE")
            if mt=="char": flags.append("WV_STRING")
            if name=="pNext": flags.append("WV_PNEXT")
            if mt in external_types or mt.startswith("PFN_"): flags.append("WV_EXTERNAL")
            if not declaration(m).startswith("const"): flags.append("WV_WRITE")
            if t=='VkWriteDescriptorSet' and name in ['pImageInfo','pBufferInfo','pTexelBufferView']:
                flags.append({'pImageInfo':'WV_DESC_IMAGE','pBufferInfo':'WV_DESC_BUFFER','pTexelBufferView':'WV_DESC_TEXEL'}[name])
        rule = count_rule(t,m) if pointers(m) else (-1,-1,0,0,1,0)
        fields=[layout(t,32)["fields"][name],layout(t,64)["fields"][name],ids[mt],"|".join(flags) or "0",number(array_extent(m)) if array_extent(m) else 1,*rule]
        c += ['    {'+', '.join(str(v) for v in fields)+'},']
    c += ['};']
c += ['const wv_type wv_types[] = {']
for t in ordered:
    node=types.get(t); cat=node.get("category") if node is not None else None
    kind="WV_STRUCT" if cat=="struct" else "WV_UNION" if cat=="union" else "WV_SIZE" if t=="size_t" else "WV_SCALAR"
    c += [f'    {{{layout(t,32)["size"]}, {layout(t,64)["size"]}, {layout(t,64)["align"]}, {kind}, {len(members(t)) if cat=="struct" else 0}, {int(needs(t,32))}, {int(needs(t,64))}, '+(f'fields_{t}' if cat=="struct" else 'NULL')+'}, // '+t]
c += ['};', 'const size_t wv_type_count = sizeof(wv_types)/sizeof(wv_types[0]);', 'int wv_chain_type(uint32_t stype) { switch(stype) {']
chain_values=set()
for t in ordered:
    if types.get(t) is None or types[t].get("category") != "struct": continue
    stype=next((m.get("values") for m in members(t) if m.findtext("name")=="sType"),None)
    if stype and stype not in chain_values:
        c += [f'case {stype}: return {ids[t]};'];chain_values.add(stype)
c += ['default: return -1; }}']

def is_pointer(p): return bool(pointers(p) or array_extent(p))
def guest_pointer(p): return is_pointer(p) and p.findtext("type") not in external_types | {"VkAllocationCallbacks"}
def result_type(t):
    if t=="void": return None
    return "i64" if scalar(t,64)[0]==8 else "i32"
def valtype(p,w):
    if is_pointer(p): return "i64" if p.findtext("type") in external_types else f"i{w}"
    if p.findtext("type")=="float": return "f32"
    return f'i{scalar(p.findtext("type"),w)[0]*8}'
def native_expression(p, j):
    typ=declaration(p)
    if array_extent(p): typ+=' *'
    return f'wv_f32(a[{j}])' if typ=='float' else f'({typ})(uintptr_t)a[{j}]'
def root_count(cmd,p):
    name=p.findtext("name");length=p.get("len")
    if array_extent(p): return array_extent(p)
    if not length or length=="null-terminated": return '1'
    params=cmd.findall("param")
    if '->' in length:
        arg,field=length.split('->');i=next(i for i,q in enumerate(params) if q.findtext('name')==arg); t=params[i].findtext('type')
        f=next(m for m in members(t) if m.findtext('name')==field)
        return f'wv_argument_member(ctx, {i}, {layout(t,32)["fields"][field]}, {layout(t,64)["fields"][field]}, {layout(f.findtext("type"),32)["size"]}, {layout(f.findtext("type"),64)["size"]})'
    i=next(i for i,q in enumerate(params) if q.findtext('name')==length)
    q=params[i]
    if is_pointer(q):
        width=0 if q.findtext('type')=='size_t' else layout(q.findtext('type'),64)['size']
        return f'wv_argument_value(ctx, {i}, {width})'
    return f'ctx->input[{i}]'

c += ['int wv_prepare(wv_context *ctx, int command) { switch(command) {']
metadata=[]
for i,n in enumerate(names):
    cmd=commands[n];params=cmd.findall("param")
    c += [f'case {i}:']
    for j,p in enumerate(params):
        if p.findtext('type')=='VkAllocationCallbacks':
            c += [f'    if(ctx->input[{j}]) return WV_UNSUPPORTED; ctx->args[{j}]=0;']
        elif guest_pointer(p):
            if p.findtext('type')=='char' and p.get('len')=='null-terminated': expr=f'wv_string_root(ctx,{j})'
            else:
                pt='uint64_t' if n=='vkMapMemory' and p.findtext('name')=='ppData' else p.findtext('type')
                expr=f'wv_root(ctx, {j}, {ids[pt]}, {root_count(cmd,p)}, {int(not declaration(p).startswith("const"))})'
            c += [f'    if(ctx->buffers[{j}].present) ctx->args[{j}] = (uint64_t)(uintptr_t){expr}; else ctx->args[{j}]=0;', '    if(ctx->error) return ctx->error;']
    c += ['    return WV_OK;']
    metadata.append(dict(name=n,params=[dict(name=p.findtext('name'),type=p.findtext('type'),pointer=is_pointer(p),guest_pointer=guest_pointer(p)) for p in params]))
c += ['default: return WV_UNSUPPORTED; }}','uint64_t wv_dispatch(int command, const uint64_t *a) { switch(command) {']
for i,n in enumerate(names):
    cmd=commands[n];params=cmd.findall('param');invoke=f'{native_commands.get(n,n)}('+', '.join(native_expression(p,j) for j,p in enumerate(params))+')'
    c += [f'case {i}: '+(invoke+'; return 0;' if cmd.findtext('proto/type')=='void' else 'return (uint64_t)'+invoke+';')]
c += ['default: return 0; }}']

go=['// Code generated by scripts/generate.py; DO NOT EDIT.', 'package vulkan', '/*', '#include "bridge.h"', '#include "scalar_generated.h"', '*/', 'import "C"', 'import "errors"', 'import wago "github.com/wago-org/wago"', 'var commands = []command{']
scalar_h=['// Generated direct scalar trampolines.', '#ifndef WV_SCALAR_GENERATED_H', '#define WV_SCALAR_GENERATED_H', '#include <stdint.h>']
direct_go=[]
signature_docs={m:[] for m in ['vulkan.gc','vulkan.wasm32','vulkan.wasm64']}
for i,n in enumerate(names):
    cmd=commands[n];params=cmd.findall('param');rt=result_type(cmd.findtext('proto/type'));pmask=sum(1<<j for j,p in enumerate(params) if guest_pointer(p));amask=sum(1<<j for j,p in enumerate(params) if p.findtext('type')=='VkAllocationCallbacks')
    signatures=[]
    for mode,width in [('gc',64),('wasm32',32),('wasm64',64)]:
        sig=[];display=[]
        for p in params:
            pname=p.findtext('name')
            if mode=='gc' and is_pointer(p) and p.findtext('type') not in external_types:
                sig += ['wago.ValAnyRef','wago.ValI32'];display += [pname+': anyref',pname+'Offset: i32']
            else:
                vt=valtype(p,width);sig += ['wago.Val'+vt.upper()];display += [pname+': '+vt]
        signatures.append('[]wago.ValType{'+','.join(sig)+'}')
        signature_docs['vulkan.'+mode].append(n+'('+', '.join(display)+')'+(' -> '+rt if rt else ' -> void'))
    direct='nil'
    if not pmask:
        direct='direct_'+n
        nativeparams=', '.join(f'uint64_t a{j}' for j in range(len(params))) or 'void'
        scalar_h += [f'uint64_t wv_direct_{n}({nativeparams});']
        nativeargs=[native_expression(p,j).replace(f'a[{j}]',f'a{j}') for j,p in enumerate(params)]
        invoke=native_commands.get(n,n)+'('+', '.join(nativeargs)+')'
        c += [f'uint64_t wv_direct_{n}({nativeparams}) '+'{ '+(invoke+'; return 0;' if rt is None else 'return (uint64_t)'+invoke+';')+' }']
        call=f'C.wv_direct_{n}('+', '.join(f'C.uint64_t(call.ParamSlots()[{j}])' for j in range(len(params)))+')'
        body=call if rt is None else 'call.Set'+rt.upper()+'(0, '+('int32' if rt=='i32' else 'int64')+'('+call+'))'
        guard=''
        if amask:
            # The selected commands with only an allocator pointer place it
            # last. GC adds exactly one null-offset slot after the allocator.
            assert amask == 1 << (len(params)-1)
            j=len(params)-1
            guard=f'if call.ParamSlots()[{j}] != 0 || len(call.ParamSlots()) > {len(params)} && uint32(call.ParamSlots()[{j+1}]) != 0 {{ trap(errors.New("guest Vulkan allocator callbacks are unsupported")) }}; '
        direct_go += [f'func direct_{n}(call wago.HostCall) {{ {guard}{body} }}']
    go += [f'    {{name: "{n}", arity: {len(params)}, pointers: {pmask}, allocators: {amask}, result: '+('voidResult' if rt is None else 'wago.Val'+rt.upper())+', signatures: [3][]wago.ValType{'+','.join(signatures)+'}, direct: '+direct+'},']
go += ['}',*direct_go]
scalar_h += ['#endif']
(ROOT/'commands_generated.c').write_text('\n'.join(c)+'\n')
(ROOT/'scalar_generated.h').write_text('\n'.join(scalar_h)+'\n')
(ROOT/'commands_generated.go').write_text('\n'.join(go)+'\n')
for module,signatures in signature_docs.items():
    (ROOT/'abi'/f'{module}.txt').write_text('\n'.join(signatures)+'\n')
layout_json={t:{str(w):layout(t,w) for w in [32,64]} for t in ordered if types.get(t) is not None and types[t].get('category') in ['struct','union']}
(ROOT/'abi/layouts.json').write_text(json.dumps(layout_json,indent=2,sort_keys=True)+'\n')
(ROOT/'abi/registry.json').write_text(json.dumps(dict(sha256=hashlib.sha256(registry.read_bytes()).hexdigest(),core='1.0',extensions=extensions,commands=len(names),structures=len(layout_json)),indent=2)+'\n')
# Portable guest declarations: pointer fields are integer offsets, every handle
# is uint64_t. No native Vulkan/X11 headers or host typedefs leak into the SDK.
wire=['// Generated packed wire declarations. Pointer fields contain byte offsets.', '#ifndef WV_WIRE_H', '#define WV_WIRE_H', '#include <stdint.h>', '#include <stddef.h>']
for w in [32,64]:
    emitted=set()
    def emit(t):
        if t in emitted:return
        emitted.add(t)
        node=types.get(t)
        if node is None or node.get('category') not in ['struct','union']:return
        for m in members(t):
            if not pointers(m):emit(m.findtext('type'))
        wire.append('typedef '+node.get('category')+' {')
        for m in members(t):
            mt=m.findtext('type')
            if pointers(m):ctype='uint64_t' if mt in external_types else f'uint{w}_t'
            elif types.get(mt) is not None and types[mt].get('category') in ['struct','union']:ctype=f'wv{w}_{mt}'
            elif mt in ['float','double','char']:ctype=mt
            else:ctype='uint'+str(scalar(mt,w)[0]*8)+'_t'
            suffix='['+str(number(array_extent(m)))+']' if array_extent(m) else ''
            wire.append(f'    {ctype} {m.findtext("name")}{suffix};')
        wire.append(f'}} wv{w}_{t};')
        wire.append(f'_Static_assert(sizeof(wv{w}_{t}) == {layout(t,w)["size"]}, "{t} wire size");')
        for m in members(t):
            f=m.findtext('name');wire.append(f'_Static_assert(offsetof(wv{w}_{t}, {f}) == {layout(t,w)["fields"][f]}, "{t}.{f} wire offset");')
    for t in ordered:emit(t)
wire += ['#endif']
(ROOT/'abi/wire.h').write_text('\n'.join(wire)+'\n')
(ROOT/'command_ids_generated.h').write_text('// Generated internal test/dispatch identifiers; not a public ABI.\n#ifndef WV_COMMAND_IDS_H\n#define WV_COMMAND_IDS_H\nenum {\n'+',\n'.join(f'    WV_{n} = {i}' for i,n in enumerate(names))+'\n};\n#endif\n')
subprocess.run(['gofmt','-w',str(ROOT/'commands_generated.go')],check=True)
print(f'Generated {len(names)} functions in each namespace and {len(layout_json)} verified structure layouts.')
