#!/usr/bin/env python3
"""Measure native conversion work using the pipeline fake-driver fixture."""
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "testdata/bridge_test.c").read_text()


def replace_once(old, new):
    global source
    if source.count(old) != 1:
        raise ValueError("native fixture changed: missing or ambiguous benchmark anchor")
    source = source.replace(old, new)


for name in ["bridge.h", "command_ids_generated.h", "scalar_generated.h", "abi/wire.h"]:
    replace_once(f'"../{name}"', f'"{ROOT / name}"')
replace_once("static int calls;", "#include <time.h>\nstatic int calls;")
replace_once("const uint32_t counts[]={100,1000,10000,50000};",
             "const uint32_t counts[]={1000,10000,20000,50000};")
replace_once("pipeline_count=counts[j];",
             "c=wv_new(32*1024*1024);assert(c);\n        pipeline_count=counts[j];")
replace_once("for(int repeat=0;repeat<2;repeat++) {",
             "for(int repeat=0;repeat<11;repeat++) {")
replace_once("            assert(wv_invoke(c,expected)==WV_OK);\n#ifdef WV_TEST_SCRATCH_SCAN",
             '''            struct timespec start,end;timespec_get(&start,TIME_UTC);
            assert(wv_invoke(c,expected)==WV_OK);
            timespec_get(&end,TIME_UTC);
            double ms=(end.tv_sec-start.tv_sec)*1000.0+(end.tv_nsec-start.tv_nsec)/1000000.0;
            printf("SAMPLE %u %d %zu %.6f\\n",pipeline_count,repeat,wv_scratch_visits,ms);
#ifdef WV_TEST_SCRATCH_SCAN''')
replace_once("        free(arena);", "        free(arena);wv_free(c);")

packages = ['vulkan'] + ([] if sys.platform == 'darwin' else ['x11'])
flags = subprocess.check_output(["pkg-config", "--cflags", "--libs", *packages], text=True).split()
with tempfile.TemporaryDirectory(prefix="wago-vulkan-scratch-") as directory:
    temporary = Path(directory)
    fixture = temporary / "fixture.c"
    executable = temporary / "benchmark"
    fixture.write_text(source)
    generated = temporary / "commands.o"
    cflags = subprocess.check_output(["pkg-config", "--cflags", *packages], text=True).split()
    subprocess.run(["cc", "-std=c11", "-O2", "-Dwv_dispatch=wv_test_real_dispatch",
                    "-DvkCmdSetDepthBias=wv_test_vkCmdSetDepthBias", *cflags,
                    "-c", str(ROOT / "commands_generated.c"), "-o", str(generated)], check=True)
    subprocess.run(["cc", "-std=c11", "-O2", "-DWV_TEST_SCRATCH_SCAN", str(fixture),
                    str(ROOT / "bridge.c"), str(ROOT / "platform.c"), str(generated), *flags,
                    "-o", str(executable)], check=True)
    output = subprocess.check_output([str(executable)], text=True)

rows = {}
for line in output.splitlines():
    if line.startswith("SAMPLE "):
        _, count, repeat, visits, milliseconds = line.split()
        rows.setdefault(int(count), []).append((int(repeat), int(visits), float(milliseconds)))
    else:
        print(line)
print("pipelines fresh_block_visits warm_block_visits fresh_ms warm_median_ms")
for count, samples in rows.items():
    assert len(samples) == 11
    print(count, samples[0][1], samples[1][1], samples[0][2],
          round(statistics.median(sample[2] for sample in samples[1:]), 6))
