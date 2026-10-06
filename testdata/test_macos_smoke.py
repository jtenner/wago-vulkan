"""CPU-only supervisor regressions; do not pretend to execute macOS/Vulkan."""
import importlib.util
import os
from pathlib import Path
import signal
import sys
import tempfile
import time
import unittest

SPEC = importlib.util.spec_from_file_location('macos_smoke', Path(__file__).resolve().parents[1]/'scripts/macos-smoke.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)

class SupervisorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='smoke-supervisor-test-')
        self.addCleanup(self.temp.cleanup)
        self.logs = Path(self.temp.name)
        self.supervisor = MODULE.Supervisor(self.logs)
        self.addCleanup(self.supervisor.stop)

    def test_paths_redacted_in_logs_but_not_command_output(self):
        path = str(Path.home()/'custom-brew')
        output = self.supervisor.run('path', [sys.executable, '-c', 'print('+repr(path)+')'], 5)
        self.assertEqual(output, path)
        self.assertNotIn(str(Path.home()), (self.logs/'path.log').read_text())
        self.assertIn('<home>', (self.logs/'path.log').read_text())

    def test_nonzero_and_validation_error_cannot_pass(self):
        with self.assertRaises(MODULE.Failure):
            self.supervisor.run('nonzero', [sys.executable, '-c', 'raise SystemExit(7)'], 5)
        self.assertEqual(self.supervisor.results[-1]['status'], 'FAIL')
        with self.assertRaises(MODULE.Failure):
            self.supervisor.run('validation', [sys.executable, '-c', 'print("VALIDATION ERROR: bad call")'], 5)
        self.assertEqual(self.supervisor.results[-1]['status'], 'FAIL')

    @unittest.skipUnless(sys.platform == 'linux', 'uses /proc to confirm orphan child is stopped')
    def test_timeout_stops_descendant_after_parent_exits(self):
        pidfile = self.logs/'child.pid'
        child = 'import signal,time;signal.signal(signal.SIGTERM,signal.SIG_IGN);time.sleep(60)'
        parent = 'import subprocess,sys;from pathlib import Path;p=subprocess.Popen([sys.executable,"-c",'+repr(child)+']);Path('+repr(str(pidfile))+').write_text(str(p.pid))'
        with self.assertRaisesRegex(MODULE.Failure, 'timed out'):
            self.supervisor.run('timeout', [sys.executable, '-c', parent], 1)
        pid = int(pidfile.read_text())
        def kill_if_alive():
            try: os.kill(pid, signal.SIGKILL)
            except ProcessLookupError: pass
        self.addCleanup(kill_if_alive)
        stat = Path('/proc')/str(pid)/'stat'
        # A terminated child can briefly remain a zombie waiting for PID 1.
        deadline = time.monotonic() + 2
        while stat.exists() and stat.read_text().split()[2] != 'Z' and time.monotonic() < deadline:
            time.sleep(0.02)
        if stat.exists():
            self.assertEqual(stat.read_text().split()[2], 'Z', 'descendant still running after timeout')
        self.assertEqual(self.supervisor.results[-1]['reason'], 'timeout')
        self.assertIsNone(self.supervisor.current)

    def test_validation_skip_is_recorded(self):
        self.supervisor.run('skip', [sys.executable, '-c', 'print("SKIP: validation layer/debug utils unavailable")'], 5)
        self.assertTrue(self.supervisor.validation_skipped)
        self.supervisor.save('INCOMPLETE')
        self.assertIn('SKIP: unavailable', (self.logs/'summary.json').read_text())

if __name__ == '__main__':
    unittest.main()
