package test_core_x509

// Out-of-memory robustness: parse must surface Allocation_Failed
// cleanly and leak nothing when any one of its table allocations
// fails. A failing allocator wraps a tracking allocator; sweeping the
// fail point across every allocation site (and verifying zero leaked
// blocks after each) exercises every OOM path and its unwind.

import "base:runtime"
import "core:mem"
import "core:crypto/x509"
import "core:testing"
import "core:time"

// Failing_Allocator passes through to a backing allocator but returns
// Out_Of_Memory on the (fail_at)-th allocation request, counting only
// the allocating modes.
@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int, // -1 = never fail
}

@(private="file")
failing_allocator_proc :: proc(
	data: rawptr, mode: runtime.Allocator_Mode,
	size, alignment: int, old_memory: rawptr, old_size: int,
	loc := #caller_location,
) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
failing_allocator :: proc(fa: ^Failing_Allocator) -> runtime.Allocator {
	return {procedure = failing_allocator_proc, data = fa}
}

@(test)
test_oom_parse_sweep :: proc(t: ^testing.T) {
	// A cert that drives all three table allocations (extensions, DNS
	// SANs, IP SANs): the EC fixture has SANs + KU + EKU + BC.
	der := EC_DER

	// First, learn how many allocations a clean parse makes.
	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		cert, err := x509.parse(der, failing_allocator(&fa))
		testing.expect_value(t, err, x509.Error.None)
		x509.destroy(&cert, failing_allocator(&fa))
		total = fa.count
		testing.expect(t, total >= 3, "expected at least 3 allocation sites")
		testing.expect_value(t, len(track.allocation_map), 0)
	}

	// Now fail at each allocation in turn; every one must yield a clean
	// Allocation_Failed and leak nothing.
	for k in 0 ..< total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)

		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		cert, err := x509.parse(der, failing_allocator(&fa))

		if err == .None {
			// This allocation site wasn't on the parse path for this
			// input; clean up and move on.
			x509.destroy(&cert, failing_allocator(&fa))
		} else {
			testing.expectf(t, err == .Allocation_Failed,
				"fail_at=%d: expected Allocation_Failed, got %v", k, err)
		}

		// Either way, parse must own no memory afterwards (its failure
		// path calls destroy internally; the success path we cleaned).
		testing.expectf(t, len(track.allocation_map) == 0,
			"fail_at=%d: %d block(s) leaked", k, len(track.allocation_map))
	}
}

// verify_chain allocates exactly one block (the chain buffer). Failing
// it must yield Allocation_Failed and leak nothing. Certificates are
// parsed with the real allocator; only verify_chain gets the failing one.
@(test)
test_oom_verify_chain :: proc(t: ^testing.T) {
	leaf, _  := x509.parse(EC_CHAIN_LEAF);  defer x509.destroy(&leaf)
	inter, _ := x509.parse(EC_CHAIN_INTER); defer x509.destroy(&inter)
	root, _  := x509.parse(EC_CHAIN_ROOT);  defer x509.destroy(&root)
	opts := x509.Verify_Options{
		roots         = {&root},
		intermediates = {&inter},
		current_time  = time.unix(CHAIN_NOW, 0),
	}

	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		chain, err := x509.verify_chain(&leaf, opts, failing_allocator(&fa))
		testing.expect_value(t, err, x509.Error.None)
		delete(chain, failing_allocator(&fa))
		total = fa.count
		testing.expect(t, total >= 1, "verify_chain should allocate at least once")
		testing.expect_value(t, len(track.allocation_map), 0)
	}

	for k in 0 ..< total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		chain, err := x509.verify_chain(&leaf, opts, failing_allocator(&fa))
		if err == .None {
			delete(chain, failing_allocator(&fa))
		} else {
			testing.expectf(t, err == .Allocation_Failed,
				"fail_at=%d: expected Allocation_Failed, got %v", k, err)
		}
		testing.expectf(t, len(track.allocation_map) == 0,
			"fail_at=%d: %d block(s) leaked", k, len(track.allocation_map))
	}
}
