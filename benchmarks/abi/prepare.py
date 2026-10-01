#!/usr/bin/env python3
"""Prepare an isolated pinned Wago overlay; never edit the user's Wago tree."""
import pathlib, shutil, subprocess

root = pathlib.Path(__file__).resolve().parents[2]
version = "v0.1.0-beta.11.0.20260930161037-9b0d97efdc76"
cache = pathlib.Path(subprocess.check_output(["go", "env", "GOMODCACHE"], text=True).strip())
source = cache / "github.com/wago-org" / ("wago@" + version)
if not source.exists():
    subprocess.run(["go", "mod", "download", "github.com/wago-org/wago@" + version], cwd=root, check=True)
target = root / ".bench-cache/wago"
target.mkdir(parents=True, exist_ok=True)
for p in target.rglob("*"):
    p.chmod(0o755 if p.is_dir() else 0o644)
for name in ["src", "plugin", "profile", "internal", "codegen"]:
    shutil.copytree(source / name, target / name, dirs_exist_ok=True,
                    ignore=shutil.ignore_patterns("*_test.go", "testdata"))
for p in source.iterdir():
    if p.is_file() and (p.suffix == ".go" and not p.name.endswith("_test.go") or p.name in ["go.mod", "go.sum", "LICENSE"]):
        shutil.copyfile(p, target / p.name)
for p in target.rglob("*"):
    p.chmod(0o755 if p.is_dir() else 0o644)
overlay = pathlib.Path(__file__).parent / "overlay"
shutil.copyfile(overlay / "benchmark_struct.go.txt", target / "src/wago/benchmark_struct.go")
shutil.copyfile(overlay / "benchmark_payload.go.txt", target / "src/core/runtime/gc/native/benchmark_payload.go")
(root / ".bench-cache/go.work").write_text("go 1.25\n\nuse ..\n\nreplace github.com/wago-org/wago => ./wago\n")
print("Prepared benchmark-only Wago overlay:", target)
