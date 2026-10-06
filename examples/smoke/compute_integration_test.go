//go:build integration

package main

import (
	"runtime"
	"testing"
)

// This is real driver evidence only when explicitly selected with integration.
// CI/Linux uses lavapipe; native Mac requires hardware. It intentionally does
// not claim validation or presentation: those belong to the one-command run.
func TestGuestCompute(t *testing.T) {
	if err := run(true, runtime.GOOS == "linux", false); err != nil {
		t.Fatal(err)
	}
}
