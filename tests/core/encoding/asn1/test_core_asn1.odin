package test_core_asn1

import "core:encoding/asn1"
import "core:testing"
import "core:time"

// ============================================================
// Tag and length forms
// ============================================================

@(test)
test_tag_forms :: proc(t: ^testing.T) {
	// Low tag, primitive universal.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x02, 0x01, 0x05})
		tag, content, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, tag, asn1.universal(.Integer))
		testing.expect_value(t, len(content), 1)
		testing.expect_value(t, asn1.done(&r), asn1.Error.None)
	}
	// Constructed context-specific [0].
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0xA0, 0x00})
		tag, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, tag, asn1.context_specific(0))
	}
	// High-tag-number form: [31] primitive → 9F 1F.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x9F, 0x1F, 0x00})
		tag, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, tag.number, u32(31))
	}
	// High-tag form used for a number < 31 is non-minimal → invalid.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x9F, 0x1E, 0x00})
		_, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Tag)
	}
	// High-tag form with 0x80 lead continuation octet is non-minimal.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x9F, 0x80, 0x1F, 0x00})
		_, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Tag)
	}
}

@(test)
test_length_forms :: proc(t: ^testing.T) {
	// Long-form length for 128 bytes: 81 80.
	{
		buf: [131]byte
		buf[0] = 0x04
		buf[1] = 0x81
		buf[2] = 0x80
		r: asn1.Cursor
		asn1.cursor_init(&r, buf[:])
		_, content, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, len(content), 128)
	}
	// Long form for a short length (81 05) is non-minimal.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x04, 0x81, 0x05, 1, 2, 3, 4, 5})
		_, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Length)
	}
	// Leading zero octet in long form (82 00 80) is non-minimal.
	{
		buf: [131]byte
		buf[0] = 0x04
		buf[1] = 0x82
		buf[2] = 0x00
		buf[3] = 0x80
		r: asn1.Cursor
		asn1.cursor_init(&r, buf[:])
		_, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Length)
	}
	// Indefinite length (80) is BER, never DER.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x30, 0x80, 0x00, 0x00})
		_, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Length)
	}
	// Length past end of input.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x04, 0x05, 1, 2})
		_, _, err := asn1.read_any(&r)
		testing.expect_value(t, err, asn1.Error.Truncated)
	}
}

// ============================================================
// Scalar types
// ============================================================

@(test)
test_boolean :: proc(t: ^testing.T) {
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x01, 0x01, 0xFF})
		v, err := asn1.read_boolean(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, v, true)
	}
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x01, 0x01, 0x00})
		v, err := asn1.read_boolean(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, v, false)
	}
	// DER: any value other than 0x00/0xFF is invalid.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x01, 0x01, 0x01})
		_, err := asn1.read_boolean(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Boolean)
	}
	// Wrong width.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x01, 0x02, 0xFF, 0xFF})
		_, err := asn1.read_boolean(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Boolean)
	}
}

@(test)
test_integer :: proc(t: ^testing.T) {
	Case :: struct {
		der:   []byte,
		value: i64,
		err:   asn1.Error,
	}
	cases := []Case{
		{der = {0x02, 0x01, 0x00}, value = 0},
		{der = {0x02, 0x01, 0x7F}, value = 127},
		{der = {0x02, 0x02, 0x00, 0x80}, value = 128},
		{der = {0x02, 0x01, 0x80}, value = -128},
		{der = {0x02, 0x02, 0xFF, 0x7F}, value = -129},
		{der = {0x02, 0x08, 0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF}, value = max(i64)},
		{der = {0x02, 0x08, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}, value = min(i64)},
		// Non-minimal: redundant leading 0x00 / 0xFF.
		{der = {0x02, 0x02, 0x00, 0x05}, err = .Invalid_Integer},
		{der = {0x02, 0x02, 0xFF, 0x85}, err = .Invalid_Integer},
		// Empty content.
		{der = {0x02, 0x00}, err = .Invalid_Integer},
		// Too wide for i64.
		{der = {0x02, 0x09, 0x01, 0, 0, 0, 0, 0, 0, 0, 0}, err = .Integer_Overflow},
	}
	for c in cases {
		r: asn1.Cursor
		asn1.cursor_init(&r, c.der)
		v, err := asn1.read_i64(&r)
		testing.expect_value(t, err, c.err)
		if c.err == .None {
			testing.expect_value(t, v, c.value)
		}
	}
}

@(test)
test_unsigned_integer :: proc(t: ^testing.T) {
	// 0x00 sign octet stripped: 255 encodes as 02 02 00 FF.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x02, 0x02, 0x00, 0xFF})
		mag, err := asn1.read_unsigned_integer_bytes(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, len(mag), 1)
		testing.expect_value(t, mag[0], u8(0xFF))
	}
	// Zero stays one octet.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x02, 0x01, 0x00})
		mag, err := asn1.read_unsigned_integer_bytes(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, len(mag), 1)
		testing.expect_value(t, mag[0], u8(0x00))
	}
	// Negative rejected.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x02, 0x01, 0x80})
		_, err := asn1.read_unsigned_integer_bytes(&r)
		testing.expect_value(t, err, asn1.Error.Negative_Integer)
	}
}

@(test)
test_bit_string :: proc(t: ^testing.T) {
	// Whole octets: 03 03 00 A0 0F.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x03, 0x00, 0xA0, 0x0F})
		octets, err := asn1.read_bit_string_octets(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, len(octets), 2)
	}
	// 4 unused bits, correctly zero-padded: A0 = 1010_0000.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x02, 0x04, 0xA0})
		bits, unused, err := asn1.read_bit_string(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, unused, 4)
		testing.expect_value(t, len(bits), 1)
	}
	// Non-zero padding bits violate DER.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x02, 0x04, 0xA1})
		_, _, err := asn1.read_bit_string(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Bit_String)
	}
	// Unused count > 7.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x02, 0x08, 0xA0})
		_, _, err := asn1.read_bit_string(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Bit_String)
	}
	// Empty payload must declare zero unused bits.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x01, 0x03})
		_, _, err := asn1.read_bit_string(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Bit_String)
	}
	// Empty content entirely.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x00})
		_, _, err := asn1.read_bit_string(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Bit_String)
	}
	// PKIX shape requires unused == 0.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x03, 0x02, 0x04, 0xA0})
		_, err := asn1.read_bit_string_octets(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Bit_String)
	}
}

@(test)
test_null :: proc(t: ^testing.T) {
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x05, 0x00})
		testing.expect_value(t, asn1.read_null(&r), asn1.Error.None)
	}
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x05, 0x01, 0x00})
		testing.expect_value(t, asn1.read_null(&r), asn1.Error.Invalid_Null)
	}
}

// ============================================================
// OBJECT IDENTIFIER
// ============================================================

@(test)
test_oid :: proc(t: ^testing.T) {
	// rsaEncryption: 1.2.840.113549.1.1.1
	rsa_encryption := []byte{0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01}
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, rsa_encryption)
		raw, err := asn1.read_oid(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, len(raw), 9)

		str, serr := asn1.oid_to_string(raw)
		defer delete(str)
		testing.expect_value(t, serr, asn1.Error.None)
		testing.expect_value(t, str, "1.2.840.113549.1.1.1")

		arcs, aerr := asn1.oid_components(raw)
		defer delete(arcs)
		testing.expect_value(t, aerr, asn1.Error.None)
		testing.expect_value(t, len(arcs), 7)
		testing.expect_value(t, arcs[3], u64(113549))
	}
	// ecPublicKey: 1.2.840.10045.2.1
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01})
		raw, err := asn1.read_oid(&r)
		testing.expect_value(t, err, asn1.Error.None)
		str, serr := asn1.oid_to_string(raw)
		defer delete(str)
		testing.expect_value(t, serr, asn1.Error.None)
		testing.expect_value(t, str, "1.2.840.10045.2.1")
	}
	// Arc-2 base offset: 2.5.4.3 (id-at-commonName) → 55 04 03.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x06, 0x03, 0x55, 0x04, 0x03})
		raw, err := asn1.read_oid(&r)
		testing.expect_value(t, err, asn1.Error.None)
		str, serr := asn1.oid_to_string(raw)
		defer delete(str)
		testing.expect_value(t, serr, asn1.Error.None)
		testing.expect_value(t, str, "2.5.4.3")
	}
	// Empty content is invalid.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x06, 0x00})
		_, err := asn1.read_oid(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Object_Identifier)
	}
	// Non-minimal subidentifier (leading 0x80 continuation octet).
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x06, 0x03, 0x2A, 0x80, 0x01})
		_, err := asn1.read_oid(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Object_Identifier)
	}
	// Truncated subidentifier (continuation bit set on last octet).
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x06, 0x02, 0x2A, 0x86})
		_, err := asn1.read_oid(&r)
		testing.expect_value(t, err, asn1.Error.Invalid_Object_Identifier)
	}
}

// ============================================================
// Time
// ============================================================

@(test)
test_time :: proc(t: ^testing.T) {
	// Times are returned as time.Time; compare via Unix seconds.
	// Reference epochs computed independently (e.g.
	// `date -u -d '1999-01-01T00:00:00Z' +%s`). UTCTime century window:
	// 990101000000Z → 1999, 490101000000Z → 2049.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x17, 0x0D, '9', '9', '0', '1', '0', '1', '0', '0', '0', '0', '0', '0', 'Z'})
		v, err := asn1.read_utc_time(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, time.to_unix_seconds(v), i64(915148800)) // 1999-01-01T00:00:00Z
	}
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x17, 0x0D, '4', '9', '0', '1', '0', '1', '0', '0', '0', '0', '0', '0', 'Z'})
		v, err := asn1.read_utc_time(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, time.to_unix_seconds(v), i64(2493072000)) // 2049-01-01T00:00:00Z
	}
	// GeneralizedTime: 20260612153000Z.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x18, 0x0F, '2', '0', '2', '6', '0', '6', '1', '2', '1', '5', '3', '0', '0', '0', 'Z'})
		v, err := asn1.read_generalized_time(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, time.to_unix_seconds(v), i64(1781278200)) // 2026-06-12T15:30:00Z
	}
	// read_time dispatches on tag.
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x18, 0x0F, '2', '0', '5', '0', '0', '1', '0', '1', '0', '0', '0', '0', '0', '0', 'Z'})
		v, err := asn1.read_time(&r)
		testing.expect_value(t, err, asn1.Error.None)
		testing.expect_value(t, time.to_unix_seconds(v), i64(2524608000)) // 2050-01-01T00:00:00Z
	}
	// Far-future dates (year 9999, the RFC 5280 no-expiration sentinel)
	// must still parse, but time.Time tops out near year 2262, so the
	// value SATURATES rather than carrying the literal 9999 epoch. This
	// is an intentional limitation (see asn1's _time_from_unix): the
	// 9999 sentinel just needs to read as "effectively never expires".
	{
		r: asn1.Cursor
		asn1.cursor_init(&r, []byte{0x18, 0x0F, '9', '9', '9', '9', '1', '2', '3', '1', '2', '3', '5', '9', '5', '9', 'Z'})
		v, err := asn1.read_generalized_time(&r)
		testing.expect_value(t, err, asn1.Error.None)
		// Saturated near year 2262, NOT the true 9999 epoch (253402300799).
		testing.expect(t, time.to_unix_seconds(v) >= i64(9_223_372_036), "9999 saturates to time.Time max")
		testing.expect(t, time.to_unix_seconds(v) < i64(253402300799), "saturated, not the literal 9999 epoch")
	}
	// RFC 5280 profile rejections: offset instead of Z, missing
	// seconds, fractional seconds, month/day out of range.
	bad := [][]byte{
		{0x17, 0x11, '9', '9', '0', '1', '0', '1', '0', '0', '0', '0', '0', '0', '+', '0', '1', '0', '0'},
		{0x17, 0x0B, '9', '9', '0', '1', '0', '1', '0', '0', '0', '0', 'Z'},
		{0x18, 0x12, '2', '0', '2', '6', '0', '6', '1', '2', '1', '5', '3', '0', '0', '0', '.', '5', '0', 'Z'},
		{0x17, 0x0D, '9', '9', '1', '3', '0', '1', '0', '0', '0', '0', '0', '0', 'Z'},
		{0x17, 0x0D, '9', '9', '0', '1', '0', '0', '0', '0', '0', '0', '0', '0', 'Z'},
		{0x17, 0x0D, '9', '9', '0', '1', '0', '1', '2', '4', '0', '0', '0', '0', 'Z'},
	}
	for der in bad {
		r: asn1.Cursor
		asn1.cursor_init(&r, der)
		_, err := asn1.read_time(&r)
		testing.expect(t, err != .None, "malformed time must be rejected")
	}
}

// ============================================================
// Compound structures
// ============================================================

// A real SubjectPublicKeyInfo for an EC P-256 key:
// SEQUENCE {
//   SEQUENCE { OID ecPublicKey, OID prime256v1 }
//   BIT STRING (65 octets of uncompressed point, 0 unused bits)
// }
@(private)
make_spki :: proc(allocator := context.allocator) -> [dynamic]byte {
	out: [dynamic]byte
	out.allocator = allocator
	append(&out, 0x30, 0x59)             // SEQUENCE, len 89
	append(&out, 0x30, 0x13)             // SEQUENCE, len 19
	append(&out, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01)       // ecPublicKey
	append(&out, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07) // prime256v1
	append(&out, 0x03, 0x42, 0x00)       // BIT STRING, len 66, 0 unused
	append(&out, 0x04)                   // uncompressed point marker
	for i in 0 ..< 64 {
		append(&out, u8(i))
	}
	return out
}

@(private)
parse_spki :: proc(data: []byte) -> (point: []byte, err: asn1.Error) {
	r: asn1.Cursor
	asn1.cursor_init(&r, data)

	spki, serr := asn1.read_sequence(&r)
	if serr != .None {
		return nil, serr
	}
	if derr := asn1.done(&r); derr != .None {
		return nil, derr
	}

	alg, aerr := asn1.read_sequence(&spki)
	if aerr != .None {
		return nil, aerr
	}
	alg_oid, oerr := asn1.read_oid(&alg)
	if oerr != .None {
		return nil, oerr
	}
	_ = alg_oid
	curve_oid, cerr := asn1.read_oid(&alg)
	if cerr != .None {
		return nil, cerr
	}
	_ = curve_oid
	if derr := asn1.done(&alg); derr != .None {
		return nil, derr
	}

	key, kerr := asn1.read_bit_string_octets(&spki)
	if kerr != .None {
		return nil, kerr
	}
	if derr := asn1.done(&spki); derr != .None {
		return nil, derr
	}
	return key, .None
}

@(test)
test_spki_walk :: proc(t: ^testing.T) {
	spki := make_spki()
	defer delete(spki)

	point, err := parse_spki(spki[:])
	testing.expect_value(t, err, asn1.Error.None)
	testing.expect_value(t, len(point), 65)
	testing.expect_value(t, point[0], u8(0x04))
}

// Every truncation of a valid structure must error cleanly — never
// panic, never succeed.
@(test)
test_truncation_sweep :: proc(t: ^testing.T) {
	spki := make_spki()
	defer delete(spki)

	for n in 0 ..< len(spki) {
		_, err := parse_spki(spki[:n])
		testing.expect(t, err != .None, "truncated input must be rejected")
	}
}

@(test)
test_explicit_optional :: proc(t: ^testing.T) {
	// [0] EXPLICIT INTEGER 2 (the X.509 version field shape), then an
	// INTEGER at the outer level.
	der := []byte{0xA0, 0x03, 0x02, 0x01, 0x02, 0x02, 0x01, 0x07}
	r: asn1.Cursor
	asn1.cursor_init(&r, der)

	inner, present, err := asn1.read_explicit(&r, 0)
	testing.expect_value(t, err, asn1.Error.None)
	testing.expect_value(t, present, true)
	version, verr := asn1.read_i64(&inner)
	testing.expect_value(t, verr, asn1.Error.None)
	testing.expect_value(t, version, i64(2))
	testing.expect_value(t, asn1.done(&inner), asn1.Error.None)

	// Absent optional: next element is [1]? No — it's the INTEGER, so
	// read_explicit(1) must not consume.
	_, present2, err2 := asn1.read_explicit(&r, 1)
	testing.expect_value(t, err2, asn1.Error.None)
	testing.expect_value(t, present2, false)

	serial, serr := asn1.read_i64(&r)
	testing.expect_value(t, serr, asn1.Error.None)
	testing.expect_value(t, serial, i64(7))
	testing.expect_value(t, asn1.done(&r), asn1.Error.None)
}
