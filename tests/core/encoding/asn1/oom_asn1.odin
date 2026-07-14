package test_core_asn1

// Out-of-memory robustness for the allocating OID helpers. A failing
// allocator wraps a tracking allocator; sweeping the fail point across
// every allocation (including the Builder's internal growth in
// oid_to_string) must yield Allocation_Failed with nothing leaked.

import "base:runtime"
import "core:mem"
import "core:encoding/asn1"
import "core:testing"

@(private="file")
Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
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

// rsaEncryption (1.2.840.113549.1.1.1) — seven arcs rendering to a
// 20-char string, enough to drive the Builder in oid_to_string past
// its initial capacity so the resize path is on the sweep.
@(private="file")
LONG_OID := []byte{0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01}

@(test)
test_oom_oid_components :: proc(t: ^testing.T) {
	raw: asn1.Cursor
	asn1.cursor_init(&raw, LONG_OID)
	oid, oerr := asn1.read_oid(&raw)
	testing.expect_value(t, oerr, asn1.Error.None)

	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		arcs, err := asn1.oid_components(oid, failing_allocator(&fa))
		testing.expect_value(t, err, asn1.Error.None)
		delete(arcs, failing_allocator(&fa))
		total = fa.count
		testing.expect(t, total >= 1)
		testing.expect_value(t, len(track.allocation_map), 0)
	}

	for k in 0 ..< total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		arcs, err := asn1.oid_components(oid, failing_allocator(&fa))
		if err == .None {
			delete(arcs, failing_allocator(&fa))
		} else {
			testing.expectf(t, err == .Allocation_Failed, "k=%d: got %v", k, err)
		}
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d: %d leaked", k, len(track.allocation_map))
	}
}

@(test)
test_oom_oid_to_string :: proc(t: ^testing.T) {
	raw: asn1.Cursor
	asn1.cursor_init(&raw, LONG_OID)
	oid, oerr := asn1.read_oid(&raw)
	testing.expect_value(t, oerr, asn1.Error.None)

	total: int
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = -1}
		str, err := asn1.oid_to_string(oid, failing_allocator(&fa))
		testing.expect_value(t, err, asn1.Error.None)
		delete(str, failing_allocator(&fa))
		total = fa.count
		testing.expect(t, total >= 1)
		testing.expect_value(t, len(track.allocation_map), 0)
	}

	for k in 0 ..< total {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		fa := Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		str, err := asn1.oid_to_string(oid, failing_allocator(&fa))
		if err == .None {
			delete(str, failing_allocator(&fa))
		} else {
			testing.expectf(t, err == .Allocation_Failed, "k=%d: got %v", k, err)
		}
		testing.expectf(t, len(track.allocation_map) == 0, "k=%d: %d leaked", k, len(track.allocation_map))
	}
}
