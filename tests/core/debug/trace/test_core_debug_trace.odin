#+build windows amd64, windows arm64
package test_core_debug_trace

import "base:intrinsics"
import "core:debug/trace"
import "core:testing"

// A trace must walk through every frame: on amd64 with the unwind tables, and on arm64 along the frame records that
// x29 points to.

@(private="file")
DEPTH :: 8

@(private="file")
capture_nested :: #force_no_inline proc(buf: trace.Capture, depth: int) -> (n: int) {
	if depth == 0 {
		n = trace.capture_fill(buf)
	} else {
		n = capture_nested(buf, depth - 1)
	}
	// Keeps the calls out of the tail position, so that each level keeps its frame.
	intrinsics.volatile_store(&n, n)
	return
}

@(test)
test_capture_walks_every_frame :: proc(t: ^testing.T) {
	buf: [64]trace.Capture_Entry
	frames := buf[:capture_nested(buf[:], DEPTH)]

	// The recursive calls all return to the same address, once for each level below the first.
	repeats := 0
	for a in frames {
		count := 0
		for b in frames {
			count += int(a == b)
		}
		repeats = max(repeats, count)
	}
	testing.expectf(t, repeats == DEPTH, "expected %d frames returning to the recursive call, got %d in a trace of %d frames", DEPTH, repeats, len(frames))
}
