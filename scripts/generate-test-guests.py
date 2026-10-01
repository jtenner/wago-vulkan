#!/usr/bin/env python3
"""Generate checked-in Wago integration guests from the public ABI catalogue."""
import json, pathlib, re, subprocess

root = pathlib.Path(__file__).resolve().parents[1]
layouts = json.loads((root / 'abi/layouts.json').read_text())
for mode in ['gc', 'wasm32', 'wasm64']:
    gc = mode == 'gc'
    width = 32 if mode == 'wasm32' else 64
    addr = 'i64' if mode == 'wasm64' else 'i32'
    ptr = lambda off: f'global.get $arena i32.const {off}' if gc else f'{addr}.const {off}'
    null = 'ref.null any i32.const 0' if gc else f'{addr}.const 0'
    off = lambda t, field: layouts[t][str(width)]['fields'][field]
    put = lambda location, value: f'i32.const {location} i32.const {value} call $put32'
    put64 = lambda location, value: f'i32.const {location} i64.const {value} call $put64'
    putptr = lambda location, value: (put if width == 32 else put64)(location, value)
    field = lambda t, base, name, value: put(base + off(t, name), value)
    pfield = lambda t, base, name, value: putptr(base + off(t, name), value)
    imports = []
    for line in (root / f'abi/vulkan.{mode}.txt').read_text().splitlines():
        m = re.match(r'(\w+)\((.*?)\) -> (\w+)', line)
        if m:
            params = [p.split(': ')[1] for p in m[2].split(', ') if p]
            sig = ''.join(f' (param {p})' for p in params)
            if m[3] != 'void': sig += f' (result {m[3]})'
            imports.append(f'(import "vulkan.{mode}" "{m[1]}" (func ${m[1]}{sig}))')
    transfer = '(param i64 anyref i32 i32)' if gc else f'(param i64 {addr} {addr})'
    for name in ['writeMapped', 'readMapped']:
        imports.append(f'(import "vulkan.{mode}" "{name}" (func ${name} {transfer}))')
    imports.append(f'(import "vulkan.{mode}" "abiVersion" (func $abiVersion (result i32)))')
    if not gc:
        wrong = 'wasm64' if mode == 'wasm32' else 'wasm32'
        wrong_addr = 'i64' if mode == 'wasm32' else 'i32'
        imports.append(f'(import "vulkan.{wrong}" "vkGetPhysicalDeviceProperties" (func $wrongWidth (param i64 {wrong_addr})))')
    if gc:
        storage = '''(type $words (array (mut i32)))
        (type $wide (array (mut i64)))
        (type $immutable (array i32))
        (global $arena (mut (ref null $words)) (ref.null $words))
        (func $put32 (param $a i32) (param $v i32)
          global.get $arena local.get $a i32.const 2 i32.shr_u local.get $v array.set $words)
        (func $get32 (param $a i32) (result i32)
          global.get $arena local.get $a i32.const 2 i32.shr_u array.get $words)
        (func $put64 (param $a i32) (param $v i64)
          local.get $a local.get $v i32.wrap_i64 call $put32
          local.get $a i32.const 4 i32.add local.get $v i64.const 32 i64.shr_u i32.wrap_i64 call $put32)
        (func $get64 (param $a i32) (result i64)
          local.get $a call $get32 i64.extend_i32_u
          local.get $a i32.const 4 i32.add call $get32 i64.extend_i32_u i64.const 32 i64.shl i64.or)'''
        make_storage = 'i32.const 8192 array.new_default $words global.set $arena'
    else:
        extend = 'i64.extend_i32_u' if width == 64 else ''
        storage = f'''(memory {"i64 " if width == 64 else ""}1)
        (func $put32 (param $a i32) (param $v i32) local.get $a {extend} local.get $v i32.store)
        (func $get32 (param $a i32) (result i32) local.get $a {extend} i32.load)
        (func $put64 (param $a i32) (param $v i64) local.get $a {extend} local.get $v i64.store)
        (func $get64 (param $a i32) (result i64) local.get $a {extend} i64.load)'''
        make_storage = ''
    app = 'VkApplicationInfo'
    ci = 'VkInstanceCreateInfo'
    di = 'VkDeviceCreateInfo'
    qi = 'VkDeviceQueueCreateInfo'
    mi = 'VkMemoryAllocateInfo'
    mp = 'VkPhysicalDeviceMemoryProperties'
    memtype = off(mp, 'memoryTypes')
    # Use word stores even for strings so the GC fixture needs no byte accessor.
    bad_extension = b'VK_WAGO_nonexistent_extension\0'
    bad_extension += b'\0' * (-len(bad_extension) % 4)
    string = '\n'.join(put(1552+i, int.from_bytes(bad_extension[i:i+4], 'little')) for i in range(0, len(bad_extension), 4))
    import_block = '\n    '.join(imports)
    code = f'''(module
    {import_block}
    {storage}
    (global $instance (mut i64) (i64.const 0))
    (global $physical (mut i64) (i64.const 0))
    (global $device (mut i64) (i64.const 0))
    (global $family (mut i32) (i32.const 0))
    (global $allocation (mut i64) (i64.const 0))
    (global $mapped (mut i32) (i32.const 0))
    (func $check (param $r i32) local.get $r if unreachable end)
    (func (export "version") (result i32) call $abiVersion)
    (func (export "prepare")
      {make_storage}
      {field(app,256,'sType',0)} {field(app,256,'apiVersion',4194304)}
      {field(ci,512,'sType',1)} {pfield(ci,512,'pApplicationInfo',256)}
      {string} {putptr(1536,1552)})
    (func (export "badExtension") (result i32) (local $r i32)
      {field(ci,512,'enabledExtensionCount',1)} {pfield(ci,512,'ppEnabledExtensionNames',1536)}
      {ptr(512)} {null} {ptr(1024)} call $vkCreateInstance local.set $r
      {field(ci,512,'enabledExtensionCount',0)} {pfield(ci,512,'ppEnabledExtensionNames',0)}
      local.get $r)
    (func (export "init") (local $i i32)
      {ptr(512)} {null} {ptr(1024)} call $vkCreateInstance call $check
      i32.const 1024 call $get64 global.set $instance
      {put(1056,0)} global.get $instance {ptr(1056)} {null} call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.const 8 i32.gt_u if unreachable end
      global.get $instance {ptr(1056)} {ptr(1080)} call $vkEnumeratePhysicalDevices call $check
      i32.const 1056 call $get32 i32.eqz if unreachable end
      i32.const 1080 call $get64 global.set $physical
      {put(1056,8)} global.get $physical {ptr(1056)} {ptr(1200)} call $vkGetPhysicalDeviceQueueFamilyProperties
      block $found loop $next
        local.get $i i32.const 24 i32.mul i32.const 1200 i32.add call $get32 i32.const 1 i32.and
        if local.get $i global.set $family br $found end
        local.get $i i32.const 1 i32.add local.tee $i
        i32.const 1056 call $get32 i32.lt_u br_if $next unreachable
      end end
      {field(qi,800,'sType',2)}
      i32.const {800+off(qi,'queueFamilyIndex')} global.get $family call $put32
      {field(qi,800,'queueCount',1)} {pfield(qi,800,'pQueuePriorities',896)} {put(896,1065353216)}
      {field(di,600,'sType',3)} {field(di,600,'queueCreateInfoCount',1)} {pfield(di,600,'pQueueCreateInfos',800)}
      global.get $physical {ptr(600)} {null} {ptr(1032)} call $vkCreateDevice call $check
      i32.const 1032 call $get64 global.set $device)
    (func (export "query") (result i64)
      global.get $device global.get $family i32.const 0 {ptr(1040)} call $vkGetDeviceQueue
      i32.const 1040 call $get64)
    (func (export "idle") (result i32) global.get $device call $vkDeviceWaitIdle)
    (func (export "fenceStatus") (result i32) (local $fence i64) (local $result i32)
      {field('VkFenceCreateInfo',1800,'sType',8)}
      global.get $device {ptr(1800)} {null} {ptr(1840)} call $vkCreateFence call $check
      i32.const 1840 call $get64 local.set $fence
      global.get $device local.get $fence call $vkGetFenceStatus local.set $result
      global.get $device local.get $fence {null} call $vkDestroyFence
      local.get $result)
    (func (export "properties") (result i32)
      global.get $physical {ptr(4096)} call $vkGetPhysicalDeviceProperties
      i32.const 4096 call $get32)
    (func (export "mapped") (result i32) (local $i i32) (local $address i64)
      global.get $physical {ptr(8192)} call $vkGetPhysicalDeviceMemoryProperties
      block $found loop $next
        local.get $i i32.const 8 i32.mul i32.const {8192+memtype} i32.add call $get32
        i32.const 6 i32.and i32.const 6 i32.eq br_if $found
        local.get $i i32.const 1 i32.add local.tee $i i32.const 8192 call $get32 i32.lt_u br_if $next unreachable
      end end
      {field(mi,1600,'sType',5)} {put64(1600+off(mi,'allocationSize'),4096)}
      i32.const {1600+off(mi,'memoryTypeIndex')} local.get $i call $put32
      global.get $device {ptr(1600)} {null} {ptr(1704)} call $vkAllocateMemory call $check
      i32.const 1704 call $get64 global.set $allocation
      global.get $device global.get $allocation i64.const 0 i64.const 4096 i32.const 0 {ptr(1712)} call $vkMapMemory call $check
      i32.const 1 global.set $mapped
      i32.const 1712 call $get64 local.set $address
      {put(1728,305419896)} {put(1732,-1)}
      local.get $address {ptr(1728)} {"i32" if gc else addr}.const 8 call $writeMapped
      local.get $address {ptr(1744)} {"i32" if gc else addr}.const 8 call $readMapped
      global.get $device global.get $allocation call $vkUnmapMemory
      i32.const 0 global.set $mapped
      global.get $device global.get $allocation {null} call $vkFreeMemory
      i64.const 0 global.set $allocation
      i32.const 1744 call $get32 i32.const 305419896 i32.eq
      i32.const 1748 call $get32 i32.const -1 i32.eq i32.and)
    (func (export "badRange")
      global.get $physical {ptr(32764 if gc else 65532)} call $vkGetPhysicalDeviceProperties)
    (func (export "badAllocator")
      global.get $device {ptr(0) if gc else ptr(123)} call $vkDestroyDevice)
    (func (export "cleanup")
      global.get $allocation i64.eqz if else
        global.get $mapped if global.get $device global.get $allocation call $vkUnmapMemory end
        global.get $device global.get $allocation {null} call $vkFreeMemory
      end
      global.get $device i64.eqz if else global.get $device {null} call $vkDestroyDevice end
      global.get $instance i64.eqz if else global.get $instance {null} call $vkDestroyInstance end
      i64.const 0 global.set $device i64.const 0 global.set $instance i64.const 0 global.set $allocation)
    )'''
    if gc:
        code = code[:-1] + f'''
        (func (export "badArray")
          global.get $physical i32.const 2048 array.new_default $wide i32.const 0 call $vkGetPhysicalDeviceProperties)
        (func (export "mixedBuffers")
          global.get $instance global.get $arena i32.const 1056
          i32.const 2048 array.new_default $wide i32.const 0
          call $vkEnumeratePhysicalDevices drop)
        (func (export "immutableArray")
          global.get $physical i32.const 2048 array.new_default $immutable i32.const 0 call $vkGetPhysicalDeviceProperties)
        (func (export "nullOffset")
          global.get $physical ref.null any i32.const 4 call $vkGetPhysicalDeviceProperties)
        )'''
    else:
        code = code[:-1] + f'''
        (func (export "wrongWidth")
          global.get $physical {wrong_addr}.const 4096 call $wrongWidth)
        )'''
    path = root / f'testdata/{mode}.wat'
    path.write_text('\n'.join(line.rstrip() for line in code.splitlines()) + '\n')
    subprocess.run(['wasm-tools','parse',str(path),'-o',str(path.with_suffix('.wasm'))],check=True)
    subprocess.run(['wasm-tools','validate',str(path.with_suffix('.wasm'))],check=True)
print('Generated gc/wasm32/wasm64 integration guests')
