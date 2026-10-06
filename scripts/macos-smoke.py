#!/usr/bin/env python3
"""Native Intel-Mac smoke supervisor. No installations, settings changes or upload.
Exit 0: requested automated checks + visual confirmation passed.
Exit 1: failure, including missing required validation.
Exit 2: explicit optional validation or missing visual/presentation confirmation.
"""
import argparse
import ctypes
import datetime
import json
import hashlib
import os
from pathlib import Path
import platform
import re
import selectors
import shutil
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
MAX_LOG = 2 * 1024 * 1024

class Failure(Exception):
    pass

class Supervisor:
    def __init__(self, logs):
        self.logs = logs
        self.env = dict(os.environ)
        self.env.update(GOMAXPROCS='2', GOTOOLCHAIN='local')
        self.current = None
        self.results = []
        self.provenance = {}
        self.validation_skipped = False
        self.visual = 'not confirmed'

    def scrub(self, text):
        # Keep version, GPU and failure evidence; avoid usernames/local paths.
        for path, replacement in ((str(ROOT), '<checkout>'), (str(Path.home()), '<home>')):
            text = text.replace(path, replacement)
        return text

    def stop(self):
        if self.current is None:
            return
        try:
            os.killpg(self.current.pid, signal.SIGTERM)
            self.current.wait(timeout=3)
        except ProcessLookupError:
            pass
        except subprocess.TimeoutExpired:
            os.killpg(self.current.pid, signal.SIGKILL)
            self.current.wait(timeout=3)
        # A shell/go parent may exit before a descendant that ignored TERM.
        # Kill any remaining members of the same isolated process group.
        try:
            os.killpg(self.current.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        self.current = None

    def run(self, name, args, timeout=120, env=None):
        print('RUN: ' + name, flush=True)
        log_path = self.logs / (name + '.log')
        output = bytearray()
        timed_out = False
        self.current = subprocess.Popen(args, cwd=ROOT, env=env or self.env,
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                        start_new_session=True)
        process = self.current
        selector = selectors.DefaultSelector()
        selector.register(self.current.stdout, selectors.EVENT_READ)
        deadline = time.monotonic() + timeout
        try:
            while selector.get_map():
                if time.monotonic() >= deadline:
                    timed_out = True
                    self.stop()
                    break
                for key, _ in selector.select(timeout=min(0.25, max(0, deadline - time.monotonic()))):
                    block = os.read(key.fileobj.fileno(), 65536)
                    if not block:
                        selector.unregister(key.fileobj)
                    else:
                        output.extend(block)
                        if len(output) > MAX_LOG:
                            raise Failure(name + ': log bound exceeded; driver/tool produced over 2 MiB')
            if self.current is not None:
                returncode = self.current.wait(timeout=max(0.1, deadline-time.monotonic()))
            else:
                returncode = -1
        except BaseException:
            self.stop()
            raise
        finally:
            selector.close()
            text = output.decode('utf-8', errors='replace')
            log_path.write_text(self.scrub(text))
            process.stdout.close()
        self.current = None
        if timed_out:
            self.results.append({'check': name, 'status': 'FAIL', 'reason': 'timeout', 'seconds': timeout})
            raise Failure(name + ': timed out after %ds; process group terminated' % timeout)
        self.validation_skipped |= 'SKIP: validation layer/debug utils unavailable' in text
        # Default layer callbacks can report instance-creation/destruction errors
        # outside the explicit messenger lifetime. Never ignore these errors.
        validation_error = bool(re.search(r'VALIDATION ERROR|Validation Error|VUID-.*(?:ERROR|Error)|Validation.*ERROR', text))
        status = 'PASS' if returncode == 0 and not validation_error else 'FAIL'
        self.results.append({'check': name, 'status': status, 'exit': returncode})
        # Print compact useful output, not all compiler/test details.
        for line in text.splitlines():
            if line.startswith(('PASS:', 'FAIL:', 'SKIP:', 'INFO:', 'VALIDATION ')):
                print(self.scrub(line), flush=True)
        if status != 'PASS':
            print(self.scrub('\n'.join(text.splitlines()[-25:])), file=sys.stderr)
            raise Failure(name + ': exit %d%s (see %s)' % (returncode, '; validation error' if validation_error else '', log_path.name))
        print('PASS: ' + name, flush=True)
        return text.strip()

    def save(self, status, reason=''):
        payload = {'status': status, 'reason': self.scrub(reason), 'provenance': self.provenance,
                   'checks': self.results, 'skips': ['GC and wasm64: pinned Intel Mac runtime unsupported/unverified'],
                   'validation': 'SKIP: unavailable' if self.validation_skipped else 'see gpu.log',
                   'human_visual_confirmation': self.visual}
        (self.logs / 'summary.json').write_text(self.scrub(json.dumps(payload, indent=2)) + '\n')


def native_intel_mac():
    if platform.system() != 'Darwin' or platform.machine() != 'x86_64':
        raise Failure('requires a native Intel Mac (Darwin x86_64); Linux/Apple Silicon/Rosetta are not this test')
    # An x86_64 shell on Apple Silicon is not an Intel Mac.
    lib = ctypes.CDLL('/usr/lib/libSystem.B.dylib')
    value = ctypes.c_int(0)
    size = ctypes.c_size_t(ctypes.sizeof(value))
    if lib.sysctlbyname(b'sysctl.proc_translated', ctypes.byref(value), ctypes.byref(size), None, 0) == 0 and value.value:
        raise Failure('Rosetta detected; use an Intel Mac with native amd64 Go and x86_64 libraries')


def preflight(s):
    native_intel_mac()
    for tool in ('go', 'git', 'pkg-config', 'xcode-select', 'xcrun', 'lipo', 'otool', 'sw_vers'):
        if not shutil.which(tool):
            raise Failure('missing %s; see docs/macos-smoke.md prerequisites (nothing is auto-installed)' % tool)
    if (ROOT / '.git').exists():
        s.provenance['commit'] = s.run('commit', ['git', 'rev-parse', 'HEAD'], 10)
        s.provenance['dirty'] = bool(s.run('checkout-state', ['git', 'status', '--porcelain'], 10))
    else:
        try:
            commit = (ROOT / 'SMOKE-COMMIT.txt').read_text().strip()
            expected = json.loads((ROOT / 'SMOKE-SHA256.json').read_text())
            if not re.fullmatch(r'[0-9a-f]{40}', commit) or not isinstance(expected, dict):
                raise ValueError('invalid archive metadata')
            for path, digest in expected.items():
                source = ROOT / path
                source.resolve().relative_to(ROOT)  # Python 3.8-compatible path containment check
                if source.is_symlink() or hashlib.sha256(source.read_bytes()).hexdigest() != digest:
                    raise ValueError('archive source hash mismatch: '+path)
            actual = {str(p.relative_to(ROOT)) for p in ROOT.rglob('*') if p.is_file() and
                      '.smoke-logs' not in p.parts and '__pycache__' not in p.parts and
                      p.name not in ('SMOKE-COMMIT.txt', 'SMOKE-SHA256.json')}
            if actual != set(expected):
                raise ValueError('archive source file set changed (extract a fresh copy)')
        except (OSError, ValueError, TypeError) as exc:
            raise Failure('archive needs intact SMOKE-COMMIT.txt + SMOKE-SHA256.json: '+str(exc)) from exc
        s.provenance['commit'] = commit
        s.provenance['source'] = 'source archive SHA-256 verified against supplied manifest'
        s.provenance['dirty'] = False
    s.provenance['macos'] = s.run('macos', ['sw_vers', '-productVersion'], 10)
    s.provenance['architecture'] = 'x86_64 / Go amd64'
    s.provenance['go'] = s.run('go-version', ['go', 'version'], 10)
    match = re.search(r'go(\d+)\.(\d+)', s.provenance['go'])
    if not match or tuple(map(int, match.groups())) < (1, 25):
        raise Failure('native Go 1.25+ required; toolchain auto-install is disabled')
    target = s.run('go-target', ['go', 'env', 'GOOS', 'GOARCH', 'CGO_ENABLED'], 10).splitlines()
    if target != ['darwin', 'amd64', '1']:
        raise Failure('Go target must be darwin/amd64 with CGO_ENABLED=1; got ' + repr(target))
    s.run('xcode-clt', ['xcode-select', '-p'], 10)
    s.provenance['clang'] = s.run('clang', ['xcrun', 'clang', '--version'], 10).splitlines()[0]
    # Use Homebrew only to discover paths when no explicit pkg-config/ICD
    # selection is given. Explicit SDK environments are preserved as a unit.
    brew = shutil.which('brew')
    sdk_selected = bool(s.env.get('VULKAN_SDK'))
    if brew and not sdk_selected:
        if not s.env.get('PKG_CONFIG_PATH'):
            loader = s.run('brew-loader-prefix', [brew, '--prefix', 'vulkan-loader'], 10)
            headers = s.run('brew-headers-prefix', [brew, '--prefix', 'vulkan-headers'], 10)
            s.env['PKG_CONFIG_PATH'] = loader+'/lib/pkgconfig:'+headers+'/share/pkgconfig'
        if not s.env.get('VK_DRIVER_FILES'):
            molten = s.run('brew-moltenvk-prefix', [brew, '--prefix', 'molten-vk'], 10)
            s.env['VK_DRIVER_FILES'] = molten+'/etc/vulkan/icd.d/MoltenVK_icd.json'
        s.provenance['brew_packages'] = s.run('brew-versions', [brew, 'list', '--versions', 'vulkan-loader', 'vulkan-headers', 'molten-vk'], 10)
    if not s.env.get('VK_DRIVER_FILES'):
        raise Failure('set VK_DRIVER_FILES to exactly one MoltenVK ICD JSON (SDK setup-env.sh may need this explicitly)')
    manifests = s.env['VK_DRIVER_FILES'].split(':')
    if len(manifests) != 1:
        raise Failure('VK_DRIVER_FILES must name one explicit MoltenVK manifest; multiple/software ICDs are not accepted')
    manifest = Path(manifests[0]).expanduser().resolve()
    try:
        icd = json.loads(manifest.read_text())['ICD']
        library = Path(icd['library_path'])
    except (OSError, ValueError, KeyError, TypeError) as exc:
        raise Failure('cannot read MoltenVK ICD JSON: ' + str(exc)) from exc
    if not library.is_absolute():
        library = (manifest.parent / library).resolve()
    if not library.is_file() or 'moltenvk' not in library.name.lower():
        raise Failure('ICD must resolve to an existing libMoltenVK dylib; bare names need an explicit path in the ICD')
    # Override deprecated/additive selectors locally, so only the chosen ICD
    # can be used by this process. Do not alter shell or machine settings.
    s.env.pop('VK_ICD_FILENAMES', None)
    s.env.pop('VK_ADD_DRIVER_FILES', None)
    s.env.pop('VK_LOADER_DRIVERS_SELECT', None)
    s.env.pop('VK_LOADER_DRIVERS_DISABLE', None)
    s.env['VK_DRIVER_FILES'] = str(manifest)
    s.provenance['icd_api_version'] = icd.get('api_version', 'unknown')
    s.provenance['vulkan_headers_loader'] = s.run('vulkan-version', ['pkg-config', '--modversion', 'vulkan'], 10)
    # Keep original output for commands: sanitized output is only for logs.
    libdir = subprocess.check_output(['pkg-config', '--variable=libdir', 'vulkan'], env=s.env, text=True, timeout=10).strip()
    loader = Path(libdir) / 'libvulkan.dylib'
    for name, path in (('loader', loader), ('moltenvk', library)):
        if not path.is_file():
            raise Failure('%s dylib not found: %s; do not mix SDK and Homebrew' % (name, path))
        archs = s.run(name+'-architectures', ['lipo', '-archs', str(path)], 10)
        if 'x86_64' not in archs.split():
            raise Failure('%s lacks x86_64: %s; loader and MoltenVK must match native Intel Go' % (name, archs))
        s.provenance[name+'_architectures'] = archs
        s.provenance[name+'_sha256'] = s.run(name+'-sha256', ['shasum', '-a', '256', str(path)], 10).split()[0]
    s.run('vulkan-flags', ['pkg-config', '--cflags', '--libs', 'vulkan'], 10)
    s.env['VK_LOADER_DEBUG'] = 'error,warn'
    # Reject overrides that can hide/remove validation diagnostics.
    for key in ('VK_LOADER_LAYERS_DISABLE', 'VK_LOADER_LAYERS_ALLOW', 'VK_LOADER_LAYERS_ENABLE', 'VK_INSTANCE_LAYERS',
                'VK_LAYER_ENABLES', 'VK_LAYER_DISABLES', 'VK_LAYER_SETTINGS_PATH', 'VK_LAYER_VALIDATE_CORE',
                'VK_LAYER_KHRONOS_VALIDATION_VALIDATE_CORE'):
        if key in s.env:
            raise Failure('unset %s for an unmodified validation smoke run' % key)
    print('SKIP: GC and wasm64 on pinned Intel Mac runtime; neither is claimed as passed', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--validation-optional', action='store_true', help='run GPU phases when validation is missing, but report INCOMPLETE and exit 2')
    parser.add_argument('--headless', action='store_true', help='explicitly skip window/presentation/visual checks; always incomplete')
    parser.add_argument('--no-prompt', action='store_true', help='skip human confirmation; always incomplete')
    args = parser.parse_args()
    os.umask(0o077)
    log_root = ROOT / '.smoke-logs'
    log_root.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    logs = Path(tempfile.mkdtemp(prefix=stamp+'-', dir=log_root))
    s = Supervisor(logs)
    def interrupted(signum, frame):
        s.stop()
        raise Failure('interrupted by signal %d; process group stopped' % signum)
    for signum in (signal.SIGTERM, signal.SIGINT):
        signal.signal(signum, interrupted)
    try:
        preflight(s)
        with tempfile.TemporaryDirectory(prefix='wago-mac-smoke-') as scratch:
            s.env['GOCACHE'] = str(Path(scratch)/'go-cache')
            s.env['GOTMPDIR'] = scratch
            s.env['WV_NATIVE_TEST_DIR'] = str(Path(scratch)/'native')
            binary = str(Path(scratch)/'gpu-smoke')
            s.run('module-download', ['go', 'mod', 'download'], 180)
            s.provenance['go_modules'] = s.run('dependency-versions', ['go', 'list', '-m', 'all'], 30)
            s.run('vet', ['go', 'vet', '-p=2', './...'], 180)
            s.run('cpu-mock', ['go', 'test', '-p=2', '-v', '-count=1', '-timeout=90s', './...'], 180)
            strict = dict(s.env, GOEXPERIMENT='cgocheck2')
            s.run('cpu-strict-cgo', ['go', 'test', '-p=2', '-v', '-count=1', '-timeout=90s', './...'], 180, strict)
            s.run('native-mock-sanitizers', ['bash', 'scripts/test-native.sh'], 180)
            s.run('real-wasm32-roundtrip', ['go', 'test', '-p=2', '-v', '-count=1', '-timeout=60s', '-tags=integration', '-run=^TestVulkanRoundTrip/wasm32$', '.'], 120)
            s.run('gpu-build', ['go', 'build', '-p=2', '-o', binary, './examples/smoke'], 180)
            s.run('linked-loader', ['otool', '-L', binary], 10)
            command = [binary]
            if args.headless:
                command.append('-headless')
            # Missing validation never hides hardware/compute/presentation
            # evidence: the harness completes those phases then reports failure.
            # Optional mode explicitly retains INCOMPLETE exit status below.
            if args.validation_optional:
                command.append('-require-validation=false')
            gpu_output = s.run('gpu', command, 45)
            for name in ('loader', 'moltenvk'):
                match = re.search(r'^INFO: loaded-'+name+r'=(.+)$', gpu_output, re.MULTILINE)
                if not match:
                    raise Failure('cannot establish actual loaded '+name+' path from native harness')
                path = Path(match.group(1)).resolve()
                digest = hashlib.sha256(path.read_bytes()).hexdigest()
                if digest != s.provenance[name+'_sha256']:
                    raise Failure('actual loaded '+name+' differs from preflight dylib; check DYLD paths and SDK/Homebrew mixing')
                s.provenance['actual_loaded_'+name+'_sha256'] = digest
            s.results.append({'check': 'actual-loaded-library-hashes', 'status': 'PASS'})
            print('PASS: actual loaded loader/MoltenVK match preflight hashes', flush=True)
        if not args.no_prompt and not args.headless and sys.stdin.isatty():
            print('Did the window show "thank you for testing!" on blue, resize to a larger green window with the same text, and close cleanly? [y/N] (30s timeout)', flush=True)
            ready, _, _ = __import__('select').select([sys.stdin], [], [], 30)
            if ready and sys.stdin.readline().strip().lower() in ('y', 'yes'):
                s.visual = 'PASS: tester confirmed exact message, blue -> larger green, clean close'
        incomplete = s.validation_skipped or args.headless or s.visual == 'not confirmed'
        status = 'INCOMPLETE' if incomplete else 'PASS'
        reason = 'missing validation, skipped presentation, or no human visual confirmation' if incomplete else ''
        s.save(status, reason)
        print(status + ': automated results and explicit skips saved in ' + str(logs))
        return 2 if incomplete else 0
    except (Failure, OSError, subprocess.SubprocessError) as exc:
        s.stop()
        s.save('FAIL', str(exc))
        print('FAIL: ' + s.scrub(str(exc)), file=sys.stderr)
        print('Local logs: ' + str(logs), file=sys.stderr)
        return 1

if __name__ == '__main__':
    sys.exit(main())
