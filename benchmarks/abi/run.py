#!/usr/bin/env python3
"""Run correctness checks, repeated benchmarks, and the report from any cwd."""
import os, pathlib, subprocess, sys

here = pathlib.Path(__file__).resolve().parent
root = here.parents[1]
results = here / "results"
results.mkdir(exist_ok=True)
subprocess.run([sys.executable, str(here / "prepare.py")], cwd=root, check=True)
subprocess.run([sys.executable, str(here / "generate.py")], cwd=root, check=True)
env = dict(os.environ, GOWORK=str(root / ".bench-cache/go.work"))
subprocess.run(["go", "test", "-tags", "abi_benchmark", "./benchmarks/abi", "-run", "TestEquivalentABIs", "-count=1"], cwd=root, env=env, check=True)
for filename, pattern in [
    ("packed.txt", "BenchmarkABI/.*/.*/packed(32|64)$"),
    ("optimized-structs.txt", "BenchmarkABI/.*/.*/structs_(batch|fields)$"),
    ("guest-writes.txt", "BenchmarkGuestWrites"),
]:
    print("Measuring", filename, flush=True)
    with (results / filename).open("w") as f:
        subprocess.run(["go", "test", "-tags", "abi_benchmark", "./benchmarks/abi", "-run", "^$", "-bench", pattern,
                        "-benchmem", "-benchtime=200ms", "-count=5", "-cpu=1"],
                       cwd=root, env=env, stdout=f, stderr=subprocess.STDOUT, check=True)
subprocess.run([sys.executable, str(here / "summarize.py")], cwd=root, check=True)
