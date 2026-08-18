package test_core_asn1

// Deterministic structure-aware fuzzing for the DER reader. The test
// runner seeds context.random_generator and logs the seed, so any
// failure reproduces with -define:ODIN_TEST_RANDOM_SEED=n.
//
// The load-bearing invariant: DER is canonical, so for any element the
// strict reader ACCEPTS, re-encoding the header from (tag, len) must
// reproduce the input bytes exactly. Any acceptance of a non-minimal
// encoding fails the oracle without needing a crash.

import "core:bytes"
import "core:encoding/asn1"
import "core:math/rand"
import "core:testing"

FUZZ_RANDOM_ITERS :: 4096
FUZZ_MUTATE_ITERS :: 2048
FUZZ_MAX_INPUT    :: 96
FUZZ_WALK_DEPTH   :: 8

// _encode_header re-encodes a DER identifier + length the canonical
// way; used as the acceptance oracle.
@(private="file")
_encode_header :: proc(tag: asn1.Tag, length: int, out: ^[dynamic]byte) {
	b := byte(u8(tag.class) << 6)
	if tag.constructed {
		b |= 0x20
	}
	if tag.number < 0x1F {
		append(out, b | byte(tag.number))
	} else {
		append(out, b | 0x1F)
		// Base-128, big-endian, minimal.
		tmp: [5]byte
		n := 0
		v := tag.number
		for {
			tmp[n] = byte(v & 0x7F)
			n += 1
			v >>= 7
			if v == 0 {
				break
			}
		}
		for i := n - 1; i >= 0; i -= 1 {
			c := tmp[i]
			if i > 0 {
				c |= 0x80
			}
			append(out, c)
		}
	}

	if length < 0x80 {
		append(out, byte(length))
	} else {
		tmp: [4]byte
		n := 0
		v := length
		for v > 0 {
			tmp[n] = byte(v & 0xFF)
			n += 1
			v >>= 8
		}
		append(out, 0x80 | byte(n))
		for i := n - 1; i >= 0; i -= 1 {
			append(out, tmp[i])
		}
	}
}

// _walk recursively consumes every element in the reader, applying the
// canonical re-encode oracle to each accepted element.
@(private="file")
_walk :: proc(t: ^testing.T, r: ^asn1.Cursor, depth: int, scratch: ^[dynamic]byte) {
	for !asn1.is_empty(r) {
		start := r.pos
		tag, content, err := asn1.read_any(r)
		if err != .None {
			return
		}
		element := r.data[start:r.pos]

		// Oracle: canonical re-encode must reproduce the element.
		clear(scratch)
		_encode_header(tag, len(content), scratch)
		append(scratch, ..content)
		if !bytes.equal(scratch[:], element) {
			testing.expectf(t, false, "accepted non-canonical element: % 02x", element)
			return
		}

		if tag.constructed && depth < FUZZ_WALK_DEPTH {
			sub := asn1.Cursor{data = content}
			_walk(t, &sub, depth + 1, scratch)
		}
	}
}

@(test)
test_fuzz_read_any_random :: proc(t: ^testing.T) {
	buf: [FUZZ_MAX_INPUT]byte
	scratch: [dynamic]byte
	defer delete(scratch)

	for _ in 0 ..< FUZZ_RANDOM_ITERS {
		n := rand.int_max(FUZZ_MAX_INPUT + 1)
		input := buf[:n]
		for i in 0 ..< n {
			input[i] = byte(rand.uint32())
		}
		// Bias half the inputs towards plausible structure: a known
		// universal tag and a length that fits.
		if n >= 2 && rand.int_max(2) == 0 {
			tags := [?]byte{0x02, 0x03, 0x04, 0x05, 0x06, 0x17, 0x18, 0x30, 0x31, 0xA0}
			input[0] = rand.choice(tags[:])
			input[1] = byte(rand.int_max(n))
		}

		r: asn1.Cursor
		asn1.cursor_init(&r, input)
		_walk(t, &r, 0, &scratch)
	}
}

@(test)
test_fuzz_typed_readers_random :: proc(t: ^testing.T) {
	buf: [FUZZ_MAX_INPUT]byte

	for _ in 0 ..< FUZZ_RANDOM_ITERS {
		n := rand.int_max(FUZZ_MAX_INPUT + 1)
		input := buf[:n]
		for i in 0 ..< n {
			input[i] = byte(rand.uint32())
		}

		// Every typed reader must fail cleanly or uphold its contract;
		// none may panic. Fresh reader per call: a failed read may
		// leave the cursor mid-element by design.
		{
			r: asn1.Cursor
			asn1.cursor_init(&r, input)
			if v, err := asn1.read_i64(&r); err == .None {
				_ = v
			}
		}
		{
			r: asn1.Cursor
			asn1.cursor_init(&r, input)
			if mag, err := asn1.read_unsigned_integer_bytes(&r); err == .None {
				// Magnitude is minimal: no leading zero unless the
				// value IS zero.
				if len(mag) > 1 {
					testing.expect(t, mag[0] != 0x00, "non-minimal magnitude")
				}
			}
		}
		{
			r: asn1.Cursor
			asn1.cursor_init(&r, input)
			if bits, unused, err := asn1.read_bit_string(&r); err == .None {
				testing.expect(t, unused <= 7)
				if unused > 0 {
					testing.expect(t, len(bits) > 0)
					mask := byte(1 << uint(unused)) - 1
					testing.expect(t, bits[len(bits) - 1] & mask == 0, "padding bits set")
				}
			}
		}
		{
			r: asn1.Cursor
			asn1.cursor_init(&r, input)
			if raw, err := asn1.read_oid(&r); err == .None {
				// Layer contract: structural acceptance by read_oid
				// means the decoders yield either arcs or Arc_Overflow
				// (X.660 arcs are unbounded) — never a structural error.
				// This invariant caught a real bug on this fuzzer's
				// first run.
				arcs, aerr := asn1.oid_components(raw)
				str, serr := asn1.oid_to_string(raw)
				testing.expect(t, aerr == .None || aerr == .Arc_Overflow, "components: structural error after acceptance")
				testing.expect_value(t, serr, aerr)
				if aerr == .None {
					testing.expect(t, len(arcs) >= 2)
					testing.expect(t, len(str) >= 3)
				}
				delete(arcs)
				delete(str)
			}
		}
		{
			r: asn1.Cursor
			asn1.cursor_init(&r, input)
			if _, err := asn1.read_time(&r); err == .None {
				// Acceptance implies the RFC 5280 profile already
				// validated ranges; nothing further to check here.
				continue
			}
		}
	}
}

@(test)
test_fuzz_mutated_spki :: proc(t: ^testing.T) {
	spki := make_spki()
	defer delete(spki)

	buf := make([]byte, len(spki))
	defer delete(buf)

	for _ in 0 ..< FUZZ_MUTATE_ITERS {
		copy(buf, spki[:])
		// 1-8 random byte mutations; structure mostly survives, so the
		// parser gets dragged deep before hitting the damage.
		for _ in 0 ..< 1 + rand.int_max(8) {
			buf[rand.int_max(len(buf))] = byte(rand.uint32())
		}
		// Must never panic; success or clean error are both fine.
		_, _ = parse_spki(buf)
	}
}
