package test_core_asn1

import "core:bytes"
import "core:encoding/asn1"
import "core:testing"
import "core:time"

@(private = "file")
_marshal :: proc(t: ^testing.T, v: asn1.Value) -> []byte {
	out, err := asn1.marshal(v)
	testing.expect_value(t, err, asn1.Error.None)
	return out
}

@(private = "file")
_expect_der :: proc(t: ^testing.T, v: asn1.Value, want: []byte) {
	got := _marshal(t, v)
	defer delete(got)
	testing.expect_value(t, len(got), asn1.encoded_len(v)) // encoded_len must match what was written
	testing.expectf(t, bytes.equal(got, want), "got %x, want %x", got, want)
}

// INTEGER from an unsigned magnitude: minimal stripping + sign-octet
// insertion, the inverse of read_unsigned_integer_bytes.
@(test)
test_writer_integer_unsigned :: proc(t: ^testing.T) {
	_expect_der(t, asn1.integer_unsigned({}), {0x02, 0x01, 0x00}) // empty -> 0
	_expect_der(t, asn1.integer_unsigned({0x00}), {0x02, 0x01, 0x00}) // 0
	_expect_der(t, asn1.integer_unsigned({0x00, 0x00}), {0x02, 0x01, 0x00}) // all-zero -> 0
	_expect_der(t, asn1.integer_unsigned({0x2A}), {0x02, 0x01, 0x2A}) // 42
	_expect_der(t, asn1.integer_unsigned({0x00, 0x2A}), {0x02, 0x01, 0x2A}) // strip leading zero
	_expect_der(t, asn1.integer_unsigned({0x80}), {0x02, 0x02, 0x00, 0x80}) // 128: insert sign octet
	_expect_der(t, asn1.integer_unsigned({0xFF, 0xFF}), {0x02, 0x03, 0x00, 0xFF, 0xFF}) // 65535
	_expect_der(t, asn1.integer_unsigned({0x01, 0x00, 0x01}), {0x02, 0x03, 0x01, 0x00, 0x01}) // 65537 (RSA e)
}

// Length octets: short form below 128, otherwise minimal long form. Drive
// the boundary with OCTET STRINGs of crafted sizes and check the header.
@(test)
test_writer_length_forms :: proc(t: ^testing.T) {
	cases := []struct {
		n:    int,
		head: []byte,
	} {
		{0, {0x04, 0x00}},
		{1, {0x04, 0x01}},
		{127, {0x04, 0x7F}}, // last short-form length
		{128, {0x04, 0x81, 0x80}}, // first long form
		{255, {0x04, 0x81, 0xFF}},
		{256, {0x04, 0x82, 0x01, 0x00}},
		{300, {0x04, 0x82, 0x01, 0x2C}},
	}
	for c in cases {
		content := make([]byte, c.n)
		defer delete(content)
		got := _marshal(t, asn1.octet_string(content))
		defer delete(got)
		testing.expectf(t, len(got) >= len(c.head), "n=%d: short output", c.n)
		testing.expectf(t, bytes.equal(got[:len(c.head)], c.head), "n=%d: header %x, want %x", c.n, got[:len(c.head)], c.head)
		testing.expect_value(t, len(got), len(c.head) + c.n)
	}
}

// encode into a buffer one byte too small must write nothing and report it.
@(test)
test_writer_buffer_too_small :: proc(t: ^testing.T) {
	v := asn1.integer_unsigned({0x80}) // encodes to 4 bytes
	need := asn1.encoded_len(v)
	testing.expect_value(t, need, 4)

	short := make([]byte, need - 1)
	defer delete(short)
	n, err := asn1.encode(v, short)
	testing.expect_value(t, err, asn1.Error.Buffer_Too_Small)
	testing.expect_value(t, n, 0)

	exact := make([]byte, need)
	defer delete(exact)
	n2, err2 := asn1.encode(v, exact)
	testing.expect_value(t, err2, asn1.Error.None)
	testing.expect_value(t, n2, need)
}

// Round-trip every write back through the cursor reader: SEQUENCE { INTEGER
// r, INTEGER s }, the ECDSA signature shape, with s's top bit set so a sign
// octet is inserted on write and stripped on read.
@(test)
test_writer_roundtrip_ecdsa_sig :: proc(t: ^testing.T) {
	r := []byte{0x01, 0x23, 0x45, 0x67}
	s := []byte{0x80, 0x00, 0x00, 0x01} // top bit set

	sig := _marshal(t, asn1.sequence({asn1.integer_unsigned(r), asn1.integer_unsigned(s)}))
	defer delete(sig)

	// s gained a 0x00 sign octet: 2 + (2+4) + (2+5) = 15 bytes.
	testing.expect_value(t, len(sig), 15)

	cur: asn1.Cursor
	asn1.cursor_init(&cur, sig)
	seq, serr := asn1.read_sequence(&cur)
	testing.expect_value(t, serr, asn1.Error.None)

	gr, rerr := asn1.read_unsigned_integer_bytes(&seq)
	gs, srerr := asn1.read_unsigned_integer_bytes(&seq)
	testing.expect_value(t, rerr, asn1.Error.None)
	testing.expect_value(t, srerr, asn1.Error.None)
	testing.expect_value(t, asn1.done(&seq), asn1.Error.None)
	testing.expect_value(t, asn1.done(&cur), asn1.Error.None)

	testing.expect(t, bytes.equal(gr, r), "r round-trips")
	testing.expect(t, bytes.equal(gs, s), "s round-trips")
}

// Structural Tier 1 encoders: NULL, OID passthrough, BIT STRING (whole
// octets), SET, and the context-specific [n] wrappers, by exact bytes.
@(test)
test_writer_structural :: proc(t: ^testing.T) {
	_expect_der(t, asn1.null(), {0x05, 0x00})

	// BIT STRING, whole octets: 03 <len+1> 00 <payload>.
	_expect_der(t, asn1.bit_string_octets({0xCA, 0xFE}), {0x03, 0x03, 0x00, 0xCA, 0xFE})
	_expect_der(t, asn1.bit_string_octets({}), {0x03, 0x01, 0x00})

	// OID passthrough: rsaEncryption (1.2.840.113549.1.1.1) content octets.
	rsa_oid := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01}
	_expect_der(t, asn1.object_identifier(rsa_oid), {0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01})

	// [0] IMPLICIT primitive, and [0] EXPLICIT wrapping INTEGER 2.
	_expect_der(t, asn1.context_primitive(0, {0xAB, 0xCD}), {0x80, 0x02, 0xAB, 0xCD})
	_expect_der(t, asn1.context_explicit(0, {asn1.integer_unsigned({0x02})}), {0xA0, 0x03, 0x02, 0x01, 0x02})

	// SET emits in the given order (single/pre-sorted element is the contract).
	_expect_der(t, asn1.set({asn1.boolean(false)}), {0x31, 0x03, 0x01, 0x01, 0x00})
}

// A SubjectPublicKeyInfo-shaped tree round-trips through the reader:
// SEQUENCE { SEQUENCE { OID, NULL }, BIT STRING }.
@(test)
test_writer_spki_shape :: proc(t: ^testing.T) {
	oid := []byte{0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01} // rsaEncryption
	key := []byte{0x30, 0x06, 0x02, 0x01, 0x2A, 0x02, 0x01, 0x03} // opaque inner key octets

	der := _marshal(t, asn1.sequence({asn1.sequence({asn1.object_identifier(oid), asn1.null()}), asn1.bit_string_octets(key)}))
	defer delete(der)

	cur: asn1.Cursor
	asn1.cursor_init(&cur, der)
	spki, e0 := asn1.read_sequence(&cur)
	testing.expect_value(t, e0, asn1.Error.None)

	alg, e1 := asn1.read_sequence(&spki)
	testing.expect_value(t, e1, asn1.Error.None)
	got_oid, e2 := asn1.read_oid(&alg)
	testing.expect_value(t, e2, asn1.Error.None)
	testing.expect(t, bytes.equal(got_oid, oid), "oid round-trips")
	testing.expect_value(t, asn1.read_null(&alg), asn1.Error.None)
	testing.expect_value(t, asn1.done(&alg), asn1.Error.None)

	got_key, e3 := asn1.read_bit_string_octets(&spki)
	testing.expect_value(t, e3, asn1.Error.None)
	testing.expect(t, bytes.equal(got_key, key), "key bits round-trip")
	testing.expect_value(t, asn1.done(&spki), asn1.Error.None)
	testing.expect_value(t, asn1.done(&cur), asn1.Error.None)
}

// time() auto-selects UTCTime (<2050) vs GeneralizedTime (>=2050) per RFC 5280.
@(test)
test_writer_time_auto :: proc(t: ^testing.T) {
	// 2049-12-31T23:59:59Z -> UTCTime (tag 0x17).
	before := _marshal(t, asn1.time(time.unix(2524607999, 0)))
	defer delete(before)
	testing.expect_value(t, before[0], u8(0x17))
	// 2050-01-01T00:00:00Z -> GeneralizedTime (tag 0x18).
	after := _marshal(t, asn1.time(time.unix(2524608000, 0)))
	defer delete(after)
	testing.expect_value(t, after[0], u8(0x18))
}

// set_of sorts components into DER canonical order (X.690 11.6, by encoding).
@(test)
test_writer_set_of :: proc(t: ^testing.T) {
	// Integers given 3,1,2 must emit sorted 1,2,3.
	kids := [3]asn1.Value{asn1.integer_unsigned({0x03}), asn1.integer_unsigned({0x01}), asn1.integer_unsigned({0x02})}
	v, err := asn1.set_of(kids[:])
	testing.expect_value(t, err, asn1.Error.None)
	out := _marshal(t, v)
	defer delete(out)

	cur: asn1.Cursor
	asn1.cursor_init(&cur, out)
	s, e := asn1.read_set(&cur)
	testing.expect_value(t, e, asn1.Error.None)
	for want in ([]byte{0x01, 0x02, 0x03}) {
		got, ge := asn1.read_unsigned_integer_bytes(&s)
		testing.expect_value(t, ge, asn1.Error.None)
		testing.expect(t, len(got) == 1 && got[0] == want, "sorted ascending")
	}
	testing.expect_value(t, asn1.done(&s), asn1.Error.None)

	// Ordering is by ENCODING, not value: 2 (02 01 02) sorts before 256
	// (02 02 01 00) because the length octet 0x01 < 0x02.
	kids2 := [2]asn1.Value{asn1.integer_unsigned({0x01, 0x00}), asn1.integer_unsigned({0x02})}
	v2, err2 := asn1.set_of(kids2[:])
	testing.expect_value(t, err2, asn1.Error.None)
	_expect_der(t, v2, {0x31, 0x07, 0x02, 0x01, 0x02, 0x02, 0x02, 0x01, 0x00})
}

// raw() splices a complete pre-encoded element in verbatim, the composition
// primitive for nesting independently-marshalled structures.
@(test)
test_writer_raw :: proc(t: ^testing.T) {
	pre := []byte{0x02, 0x01, 0x2A} // a pre-encoded INTEGER 42
	_expect_der(t, asn1.raw(pre), {0x02, 0x01, 0x2A})
	// embedded beside another value inside a SEQUENCE.
	_expect_der(t, asn1.sequence({asn1.raw(pre), asn1.boolean(true)}), {0x30, 0x06, 0x02, 0x01, 0x2A, 0x01, 0x01, 0xFF})
}

@(private = "file")
_expect_time :: proc(t: ^testing.T, v: asn1.Value, tag: byte, ascii: string) {
	got := _marshal(t, v)
	defer delete(got)
	want := make([]byte, 2 + len(ascii))
	defer delete(want)
	want[0] = tag
	want[1] = byte(len(ascii))
	copy(want[2:], transmute([]byte)ascii)
	testing.expectf(t, bytes.equal(got, want), "got %x, want %x", got, want)
}

// UTCTime / GeneralizedTime formatting (option B: time.Time formatted into
// the output at emit) by exact bytes, plus a round-trip through the reader.
// Tags: UTCTime 0x17, GeneralizedTime 0x18.
@(test)
test_writer_time :: proc(t: ^testing.T) {
	epoch := time.unix(0, 0) // 1970-01-01 00:00:00Z
	_expect_time(t, asn1.generalized_time(epoch), 0x18, "19700101000000Z")
	_expect_time(t, asn1.utc_time(epoch), 0x17, "700101000000Z")

	y2027 := time.unix(1798761600, 0) // 2027-01-01 00:00:00Z
	_expect_time(t, asn1.generalized_time(y2027), 0x18, "20270101000000Z")
	_expect_time(t, asn1.utc_time(y2027), 0x17, "270101000000Z")

	// Nonzero month/day/time-of-day: 2023-11-14 22:13:20Z.
	tod := time.unix(1700000000, 0)
	_expect_time(t, asn1.generalized_time(tod), 0x18, "20231114221320Z")

	// Round-trip both forms through the reader.
	{
		der := _marshal(t, asn1.generalized_time(tod))
		defer delete(der)
		cur: asn1.Cursor
		asn1.cursor_init(&cur, der)
		got, err := asn1.read_generalized_time(&cur)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, time.to_unix_seconds(got), i64(1700000000))
	}
	{
		der := _marshal(t, asn1.utc_time(y2027))
		defer delete(der)
		cur: asn1.Cursor
		asn1.cursor_init(&cur, der)
		got, err := asn1.read_utc_time(&cur)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, time.to_unix_seconds(got), i64(1798761600))
	}
}

// Nesting + a second leaf type: SEQUENCE { BOOLEAN, SEQUENCE { INTEGER } }.
// Re-encoding the parsed structure must reproduce the bytes exactly
// (DER is canonical), which is the core correctness property for a writer.
@(test)
test_writer_nested_and_idempotent :: proc(t: ^testing.T) {
	inner := asn1.sequence({asn1.integer_unsigned({0x2A})})
	outer := asn1.sequence({asn1.boolean(true), inner})

	der := _marshal(t, outer)
	defer delete(der)

	// 30 08  01 01 FF  30 03 02 01 2A
	want := []byte{0x30, 0x08, 0x01, 0x01, 0xFF, 0x30, 0x03, 0x02, 0x01, 0x2A}
	testing.expectf(t, bytes.equal(der, want), "got %x, want %x", der, want)

	// Walk it back through the reader to confirm it parses as DER.
	cur: asn1.Cursor
	asn1.cursor_init(&cur, der)
	o, oerr := asn1.read_sequence(&cur)
	testing.expect_value(t, oerr, asn1.Error.None)
	b, berr := asn1.read_boolean(&o)
	testing.expect_value(t, berr, asn1.Error.None)
	testing.expect_value(t, b, true)
	i, ierr := asn1.read_sequence(&o)
	testing.expect_value(t, ierr, asn1.Error.None)
	mag, merr := asn1.read_unsigned_integer_bytes(&i)
	testing.expect_value(t, merr, asn1.Error.None)
	testing.expect(t, bytes.equal(mag, {0x2A}), "inner integer round-trips")
	testing.expect_value(t, asn1.done(&o), asn1.Error.None)
	testing.expect_value(t, asn1.done(&cur), asn1.Error.None)
}
