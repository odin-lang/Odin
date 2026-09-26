package test_core_asn1

// Deterministic fuzzing for the DER WRITER. The runner seeds
// context.random_generator and logs the seed, so any failure reproduces
// with -define:ODIN_TEST_RANDOM_SEED=n. Run under -sanitize:address to turn
// the value-tree's borrow discipline into a checked property: a stray
// borrow of an out-of-scope composite-literal temporary is a stack
// use-after-scope ASan would catch here.
//
// Invariants:
//   - marshal of any constructed tree never crashes / writes out of bounds;
//   - the output is well-formed DER (a read_any walk consumes it exactly);
//   - leaf values survive a marshal -> read round-trip.

import "core:bytes"
import "core:encoding/asn1"
import "core:math/rand"
import "core:testing"
import "core:time"

WRITER_FUZZ_ITERS :: 2048
WRITER_FUZZ_DEPTH :: 6

// _gen_bytes allocates 0..max random bytes from the temp arena.
@(private = "file")
_gen_bytes :: proc(max: int) -> []byte {
	n := rand.int_max(max)
	b := make([]byte, n, context.temp_allocator)
	for i in 0 ..< n {
		b[i] = byte(rand.int_max(256))
	}
	return b
}

@(private = "file")
_gen_leaf :: proc() -> asn1.Value {
	switch rand.int_max(7) {
	case 0:
		return asn1.boolean(rand.int_max(2) == 1)
	case 1:
		return asn1.null()
	case 2:
		return asn1.integer_unsigned(_gen_bytes(20))
	case 3:
		return asn1.octet_string(_gen_bytes(20))
	case 4:
		return asn1.bit_string_octets(_gen_bytes(20))
	case 5:
		return asn1.object_identifier(_gen_bytes(12)) // raw OID octets: read_any tolerates any content
	case:
		return asn1.generalized_time(time.unix(i64(rand.int_max(2_000_000_000)), 0))
	}
}

// _gen_value builds a random tree; constructed nodes draw their children
// arrays from the temp arena (pre-sized, so the slices set() / sequence()
// borrow never move), freed wholesale after each iteration.
@(private = "file")
_gen_value :: proc(depth: int) -> asn1.Value {
	if depth <= 0 || rand.int_max(3) == 0 {
		return _gen_leaf()
	}
	n := rand.int_max(4) // 0..3 children
	kids := make([]asn1.Value, n, context.temp_allocator)
	for i in 0 ..< n {
		kids[i] = _gen_value(depth - 1)
	}
	switch rand.int_max(5) {
	case 0:
		return asn1.sequence(kids)
	case 1:
		return asn1.set(kids)
	case 2:
		return asn1.context_explicit(u32(rand.int_max(8)), kids)
	case 3:
		return asn1.bit_string_wrap(kids)
	case:
		sv, serr := asn1.set_of(kids, context.temp_allocator) // allocates scratch + sorts in place
		if serr != .None {
			return asn1.set(kids)
		}
		return sv
	}
}

// _walk recurses through a marshalled tree with read_any, asserting every
// element frames cleanly and the input is consumed exactly.
@(private = "file")
_walk :: proc(t: ^testing.T, data: []byte, depth: int) {
	cur: asn1.Cursor
	asn1.cursor_init(&cur, data)
	for !asn1.is_empty(&cur) {
		tag, content, err := asn1.read_any(&cur)
		testing.expect_value(t, err, asn1.Error.None)
		if err != .None {
			return
		}
		if tag.constructed && depth > 0 {
			_walk(t, content, depth - 1)
		}
	}
}

@(test)
test_fuzz_writer_wellformed :: proc(t: ^testing.T) {
	for _ in 0 ..< WRITER_FUZZ_ITERS {
		tree := _gen_value(WRITER_FUZZ_DEPTH)
		out, err := asn1.marshal(tree)
		testing.expect_value(t, err, asn1.Error.None)
		if err == .None {
			testing.expect_value(t, len(out), asn1.encoded_len(tree)) // sizing == emission
			_walk(t, out, 64)
			delete(out)
		}
		free_all(context.temp_allocator)
	}
}

@(test)
test_fuzz_writer_roundtrip :: proc(t: ^testing.T) {
	for _ in 0 ..< WRITER_FUZZ_ITERS {
		// OCTET STRING: content survives verbatim.
		payload := _gen_bytes(32)
		if o, e := asn1.marshal(asn1.octet_string(payload)); e == .None {
			cur: asn1.Cursor
			asn1.cursor_init(&cur, o)
			got, re := asn1.read_octet_string(&cur)
			testing.expect_value(t, re, asn1.Error.None)
			testing.expect_value(t, asn1.done(&cur), asn1.Error.None)
			testing.expect(t, bytes.equal(got, payload), "octet string round-trip")
			delete(o)
		}

		// BIT STRING (whole octets): payload survives verbatim.
		bits := _gen_bytes(32)
		if o, e := asn1.marshal(asn1.bit_string_octets(bits)); e == .None {
			cur: asn1.Cursor
			asn1.cursor_init(&cur, o)
			got, re := asn1.read_bit_string_octets(&cur)
			testing.expect_value(t, re, asn1.Error.None)
			testing.expect(t, bytes.equal(got, bits), "bit string round-trip")
			delete(o)
		}

		// BOOLEAN.
		bv := rand.int_max(2) == 1
		if o, e := asn1.marshal(asn1.boolean(bv)); e == .None {
			cur: asn1.Cursor
			asn1.cursor_init(&cur, o)
			got, re := asn1.read_boolean(&cur)
			testing.expect_value(t, re, asn1.Error.None)
			testing.expect_value(t, got, bv)
			delete(o)
		}

		free_all(context.temp_allocator)
	}
}
