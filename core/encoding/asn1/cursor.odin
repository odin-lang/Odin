package asn1

import "core:strings"
import dt "core:time"

// Cursor is a position into DER input, advanced by the read_* procs.
Cursor :: struct {
	data: []byte,
	pos:  int,
}

// Points a Cursor at `data` and rewinds it to the start.
cursor_init :: proc "contextless" (r: ^Cursor, data: []byte) {
	r.data = data
	r.pos = 0
}

// Returns the number of unconsumed bytes.
remaining :: proc "contextless" (r: ^Cursor) -> int {
	return len(r.data) - r.pos
}

// Reports whether the Cursor has been fully consumed.
is_empty :: proc "contextless" (r: ^Cursor) -> bool {
	return r.pos >= len(r.data)
}

// Returns Leftover_Bytes if input remains. DER structures are exact: every SEQUENCE walk should end with done() on its sub-cursor.
done :: proc "contextless" (r: ^Cursor) -> Error {
	if r.pos < len(r.data) {
		return .Leftover_Bytes
	}
	return .None
}

// Reads one complete TLV element of any tag, returning the tag and a view of the content octets.
read_any :: proc "contextless" (r: ^Cursor) -> (tag: Tag, content: []byte, err: Error) {
	tag, err = _read_tag(r)
	if err != .None {
		return
	}
	length: int
	length, err = _read_length(r)
	if err != .None {
		return
	}
	if length > remaining(r) {
		err = .Truncated
		return
	}
	content = r.data[r.pos:r.pos + length]
	r.pos += length
	return
}

// Decodes the next element's tag without consuming anything.
peek_tag :: proc "contextless" (r: ^Cursor) -> (tag: Tag, err: Error) {
	tmp := r^
	return _read_tag(&tmp)
}

// Consumes one complete element of any tag.
skip :: proc "contextless" (r: ^Cursor) -> Error {
	_, _, err := read_any(r)
	return err
}

// Reads one element and requires its tag to match exactly.
expect :: proc "contextless" (r: ^Cursor, tag: Tag) -> (content: []byte, err: Error) {
	got: Tag
	got, content, err = read_any(r)
	if err != .None {
		return
	}
	if got != tag {
		err = .Unexpected_Tag
	}
	return
}

// Enters a SEQUENCE, returning a sub-cursor over its content.
read_sequence :: proc "contextless" (r: ^Cursor) -> (seq: Cursor, err: Error) {
	content, eerr := expect(r, universal(.Sequence, true))
	if eerr != .None {
		return {}, eerr
	}
	return Cursor{data = content}, .None
}

// Enters a SET, returning a sub-cursor over its content. 
// NOTE: DER requires SET OF contents to be sorted; this cursor does
// not verify ordering, consumers that care (none in PKIX cert parsing) must check.
read_set :: proc "contextless" (r: ^Cursor) -> (set: Cursor, err: Error) {
	content, eerr := expect(r, universal(.Set, true))
	if eerr != .None {
		return {}, eerr
	}
	return Cursor{data = content}, .None
}

// Handles `[number] EXPLICIT ... OPTIONAL`: if the next element is the given 
// constructed context-specific tag, it is consumed and a sub-cursor over its 
// content returned with present=true. Otherwise nothing is consumed.
read_explicit :: proc "contextless" (r: ^Cursor, number: u32) -> (inner: Cursor, present: bool, err: Error) {
	if is_empty(r) {
		return {}, false, .None
	}
	tag, perr := peek_tag(r)
	if perr != .None {
		return {}, false, perr
	}
	if tag != context_specific(number, true) {
		return {}, false, .None
	}
	content, eerr := expect(r, tag)
	if eerr != .None {
		return {}, false, eerr
	}
	return Cursor{data = content}, true, .None
}

// Reads a BOOLEAN. DER: exactly one octet, 0x00 or 0xFF.
read_boolean :: proc "contextless" (r: ^Cursor) -> (value: bool, err: Error) {
	content, eerr := expect(r, universal(.Boolean))
	if eerr != .None {
		return false, eerr
	}
	if len(content) != 1 {
		return false, .Invalid_Boolean
	}
	switch content[0] {
	case 0x00:
		return false, .None
	case 0xFF:
		return true, .None
	}
	return false, .Invalid_Boolean
}

// Reads an INTEGER and returns the validated, minimally-encoded two's-complement content octets.
read_integer_bytes :: proc "contextless" (r: ^Cursor) -> (content: []byte, err: Error) {
	content, err = expect(r, universal(.Integer))
	if err != .None {
		return
	}
	err = _check_integer(content)
	return
}

// Reads an INTEGER that must fit in an i64.
read_i64 :: proc "contextless" (r: ^Cursor) -> (value: i64, err: Error) {
	content, ierr := read_integer_bytes(r)
	if ierr != .None {
		return 0, ierr
	}
	if len(content) > 8 {
		return 0, .Integer_Overflow
	}
	if content[0] & 0x80 != 0 {
		value = -1 // sign-extend
	}
	for b in content {
		value = value << 8 | i64(b)
	}
	return value, .None
}

// Reads a non-negative INTEGER and returns its magnitude octets with any leading 0x00 
// sign octet stripped, the shape RSA moduli, public exponents, and certificate serials 
// are consumed in.
read_unsigned_integer_bytes :: proc "contextless" (r: ^Cursor) -> (magnitude: []byte, err: Error) {
	content, ierr := read_integer_bytes(r)
	if ierr != .None {
		return nil, ierr
	}
	if content[0] & 0x80 != 0 {
		return nil, .Negative_Integer
	}
	if len(content) > 1 && content[0] == 0x00 {
		content = content[1:]
	}
	return content, .None
}

// Reads a BIT STRING, returning the payload octets and the count of unused trailing bits 
// in the final octet. DER: primitive form only, unused count 0..7 (0 if the payload is 
// empty), and the unused bits themselves must be zero.
read_bit_string :: proc "contextless" (r: ^Cursor) -> (bits: []byte, unused: int, err: Error) {
	content, eerr := expect(r, universal(.Bit_String))
	if eerr != .None {
		return nil, 0, eerr
	}
	if len(content) < 1 {
		return nil, 0, .Invalid_Bit_String
	}
	unused = int(content[0])
	bits = content[1:]
	if unused > 7 {
		return nil, 0, .Invalid_Bit_String
	}
	if len(bits) == 0 && unused != 0 {
		return nil, 0, .Invalid_Bit_String
	}
	if unused > 0 {
		mask := byte(1 << uint(unused)) - 1
		if bits[len(bits) - 1] & mask != 0 {
			return nil, 0, .Invalid_Bit_String
		}
	}
	return bits, unused, .None
}

// Reads a BIT STRING that must be a whole number of octets (unused == 0),
// the only form PKIX uses for SubjectPublicKeyInfo keys and signature values.
read_bit_string_octets :: proc "contextless" (r: ^Cursor) -> (octets: []byte, err: Error) {
	bits, unused, berr := read_bit_string(r)
	if berr != .None {
		return nil, berr
	}
	if unused != 0 {
		return nil, .Invalid_Bit_String
	}
	return bits, .None
}

// Reads an OCTET STRING (primitive form only).
read_octet_string :: proc "contextless" (r: ^Cursor) -> (octets: []byte, err: Error) {
	return expect(r, universal(.Octet_String))
}

// Reads a NULL (content must be empty).
read_null :: proc "contextless" (r: ^Cursor) -> Error {
	content, err := expect(r, universal(.Null))
	if err != .None {
		return err
	}
	if len(content) != 0 {
		return .Invalid_Null
	}
	return .None
}

// Reads an OBJECT IDENTIFIER and returns a view of its content octets, 
// validated for minimal base-128 encoding. The validation is structural 
// only: arc magnitude is unbounded per X.660, so PKIX consumers should 
// compare these bytes directly against known-OID constants. 
// oid_components/oid_to_string decode arcs when needed, reporting 
// Arc_Overflow for arcs beyond u64.
read_oid :: proc "contextless" (r: ^Cursor) -> (raw: []byte, err: Error) {
	raw, err = expect(r, universal(.Object_Identifier))
	if err != .None {
		return
	}
	if len(raw) == 0 {
		return nil, .Invalid_Object_Identifier
	}
	// Validate: each subidentifier is base-128 with minimal encoding
	// (no 0x80 lead octet) and terminates (last octet has bit 8 clear).
	expect_start := true
	for b in raw {
		if expect_start && b == 0x80 {
			return nil, .Invalid_Object_Identifier
		}
		expect_start = b & 0x80 == 0
	}
	if !expect_start {
		return nil, .Invalid_Object_Identifier
	}
	return raw, .None
}

// Times are returned as core:time.Time. time.Time is i64 nanoseconds
// and so tops out near year 2262, while UTCTime/GeneralizedTime reach
// year 9999; dates beyond what time.Time can hold (notably RFC 5280's
// "99991231235959Z" no-well-defined-expiration sentinel) saturate to
// time.Time's bound rather than erroring, so a far-future cert still
// parses and reads as "effectively never expires". See _time_from_unix.

// read_utc_time reads a UTCTime in the RFC 5280 DER profile:
// "YYMMDDHHMMSSZ", with the sliding century window (00-49 → 20xx,
// 50-99 → 19xx).
read_utc_time :: proc "contextless" (r: ^Cursor) -> (value: dt.Time, err: Error) {
	content, eerr := expect(r, universal(.UTC_Time))
	if eerr != .None {
		return {}, eerr
	}
	if len(content) != 13 || content[12] != 'Z' {
		return {}, .Invalid_Time
	}
	yy, ok := _two_digits(content[0:2])
	if !ok {
		return {}, .Invalid_Time
	}
	year := 2000 + yy
	if yy >= 50 {
		year = 1900 + yy
	}
	secs := _unix_from_fields(year, content[2:12]) or_return
	return _time_from_unix(secs), .None
}

// Reads a GeneralizedTime in the RFC 5280 DER profile: "YYYYMMDDHHMMSSZ", Zulu only, no fractional seconds.
read_generalized_time :: proc "contextless" (r: ^Cursor) -> (value: dt.Time, err: Error) {
	content, eerr := expect(r, universal(.Generalized_Time))
	if eerr != .None {
		return {}, eerr
	}
	if len(content) != 15 || content[14] != 'Z' {
		return {}, .Invalid_Time
	}
	hi, ok1 := _two_digits(content[0:2])
	lo, ok2 := _two_digits(content[2:4])
	if !ok1 || !ok2 {
		return {}, .Invalid_Time
	}
	secs := _unix_from_fields(hi * 100 + lo, content[4:14]) or_return
	return _time_from_unix(secs), .None
}

// Reads either time form, PKIX Validity uses UTCTime for dates through 2049 and GeneralizedTime from 2050 on.
read_time :: proc "contextless" (r: ^Cursor) -> (value: dt.Time, err: Error) {
	tag, perr := peek_tag(r)
	if perr != .None {
		return {}, perr
	}
	if tag == universal(.Generalized_Time) {
		return read_generalized_time(r)
	}
	return read_utc_time(r)
}

// OBJECT IDENTIFIER helpers (allocating).

// Decodes validated OID content octets (from read_oid) into their integer arcs, 
// e.g. {1, 2, 840, 113549, 1, 1, 1}.  Arcs beyond u64 (legal per X.660, see 
// Arc_Overflow) are not representable; compare such OIDs by their raw bytes instead.
oid_components :: proc(raw: []byte, allocator := context.allocator) -> (arcs: []u64, err: Error) {
	if len(raw) == 0 {
		return nil, .Invalid_Object_Identifier
	}
	count := 1 // the first octet encodes two arcs
	for b in raw {
		if b & 0x80 == 0 {
			count += 1
		}
	}

	out, merr := make([]u64, count, allocator)
	if merr != nil {
		return nil, .Allocation_Failed
	}
	idx := 0
	acc: u64 = 0
	first := true
	for b in raw {
		if acc > max(u64) >> 7 {
			delete(out, allocator)
			return nil, .Arc_Overflow
		}
		acc = acc << 7 | u64(b & 0x7F)
		if b & 0x80 != 0 {
			continue
		}
		if first {
			// X.690 section 8.19.4: the first subidentifier encodes the first
			// two arcs as arc1*40 + arc2 (arc1 limited to 0..2; arc2
			// unbounded only when arc1 == 2).
			switch {
			case acc < 40:
				out[idx] = 0
				out[idx + 1] = acc
			case acc < 80:
				out[idx] = 1
				out[idx + 1] = acc - 40
			case:
				out[idx] = 2
				out[idx + 1] = acc - 80
			}
			idx += 2
			first = false
		} else {
			out[idx] = acc
			idx += 1
		}
		acc = 0
	}
	return out, .None
}

// Renders OID content octets in dotted-decimal form ("1.2.840.113549.1.1.1") for diagnostics.
// The arcs are streamed directly into the result; the only allocation is the returned string.
oid_to_string :: proc(raw: []byte, allocator := context.allocator) -> (str: string, err: Error) {
	if len(raw) == 0 {
		return "", .Invalid_Object_Identifier
	}

	sb: strings.Builder
	if _, berr := strings.builder_init(&sb, allocator); berr != nil {
		return "", .Allocation_Failed
	}
	defer if err != .None {
		strings.builder_destroy(&sb)
	}

	// Builder writes swallow allocator failures, so tally the written
	// vs expected lengths and treat any shortfall as an allocation
	// failure (the same defense pem.encode uses).
	written, expected := 0, 0
	acc: u64 = 0
	first := true
	for b in raw {
		if acc > max(u64) >> 7 {
			err = .Arc_Overflow
			return "", err
		}
		acc = acc << 7 | u64(b & 0x7F)
		if b & 0x80 != 0 {
			continue
		}
		if first {
			// See oid_components for the X.690 section 8.19.4 split of the first subidentifier.
			arc1, arc2: u64
			switch {
			case acc < 40:
				arc1, arc2 = 0, acc
			case acc < 80:
				arc1, arc2 = 1, acc - 40
			case:
				arc1, arc2 = 2, acc - 80
			}
			written += strings.write_u64(&sb, arc1)
			written += strings.write_byte(&sb, '.')
			written += strings.write_u64(&sb, arc2)
			expected += _decimal_len(arc1) + 1 + _decimal_len(arc2)
			first = false
		} else {
			written += strings.write_byte(&sb, '.')
			written += strings.write_u64(&sb, acc)
			expected += 1 + _decimal_len(acc)
		}
		acc = 0
	}
	if written != expected {
		err = .Allocation_Failed
		return "", err
	}
	return strings.to_string(sb), .None
}

@(private)
_decimal_len :: proc "contextless" (v: u64) -> (n: int) {
	n = 1
	x := v
	for x >= 10 {
		x /= 10
		n += 1
	}
	return n
}

@(private)
_read_tag :: proc "contextless" (r: ^Cursor) -> (tag: Tag, err: Error) {
	if is_empty(r) {
		return {}, .Truncated
	}
	b := r.data[r.pos]
	r.pos += 1

	tag.class = Class(b >> 6)
	tag.constructed = b & 0x20 != 0
	number := u32(b & 0x1F)

	if number != 0x1F {
		tag.number = number
		return tag, .None
	}

	// High-tag-number form (X.690 section 8.1.2.4): base-128, minimal (first
	// octet may not be 0x80), and the resulting number must be >= 31.
	number = 0
	for i := 0; ; i += 1 {
		if is_empty(r) {
			return {}, .Truncated
		}
		nb := r.data[r.pos]
		r.pos += 1
		if i == 0 && nb == 0x80 {
			return {}, .Invalid_Tag
		}
		if number > (max(u32) >> 7) {
			return {}, .Invalid_Tag
		}
		number = number << 7 | u32(nb & 0x7F)
		if nb & 0x80 == 0 {
			break
		}
	}
	if number < 0x1F {
		return {}, .Invalid_Tag
	}
	tag.number = number
	return tag, .None
}

@(private)
_read_length :: proc "contextless" (r: ^Cursor) -> (length: int, err: Error) {
	if is_empty(r) {
		return 0, .Truncated
	}
	b := r.data[r.pos]
	r.pos += 1

	if b & 0x80 == 0 {
		return int(b), .None
	}

	n := int(b & 0x7F)
	if n == 0 {
		// 0x80: indefinite length, BER only.
		return 0, .Invalid_Length
	}
	if n > 4 {
		// Lengths beyond 2^31 are not plausible inputs here.
		return 0, .Invalid_Length
	}
	if remaining(r) < n {
		return 0, .Truncated
	}

	value := 0
	for i in 0 ..< n {
		value = value << 8 | int(r.data[r.pos + i])
	}
	r.pos += n

	// DER minimality: no leading zero octet, and the long form may only be used for lengths >= 128.
	if r.data[r.pos - n] == 0 || value < 0x80 {
		return 0, .Invalid_Length
	}
	if value < 0 {
		return 0, .Invalid_Length
	}
	return value, .None
}

// Enforces X.690 section 8.3: at least one octet, and minimal (the first nine bits may not be all-zero or all-one).
@(private)
_check_integer :: proc "contextless" (content: []byte) -> Error {
	switch len(content) {
	case 0:
		return .Invalid_Integer
	case 1:
		return .None
	}
	if content[0] == 0x00 && content[1] & 0x80 == 0 {
		return .Invalid_Integer
	}
	if content[0] == 0xFF && content[1] & 0x80 != 0 {
		return .Invalid_Integer
	}
	return .None
}

@(private)
_two_digits :: proc "contextless" (b: []byte) -> (value: int, ok: bool) {
	if b[0] < '0' || b[0] > '9' || b[1] < '0' || b[1] > '9' {
		return 0, false
	}
	return int(b[0] - '0') * 10 + int(b[1] - '0'), true
}

// Converts Unix seconds to a time.Time, saturating at time.Time's 
// representable bounds. time.Time counts i64 nanoseconds, so it tops 
// out near year 2262; a far-future X.509 date (notably RFC 5280's 
// "99991231235959Z" no-expiration sentinel) saturates to that bound
// rather than overflowing, and so reads as "effectively never".
@(private)
_time_from_unix :: proc "contextless" (secs: i64) -> dt.Time {
	NS_PER_SEC :: i64(1_000_000_000)
	if secs > max(i64) / NS_PER_SEC {
		return dt.Time{_nsec = max(i64)}
	}
	if secs < min(i64) / NS_PER_SEC {
		return dt.Time{_nsec = min(i64)}
	}
	return dt.Time{_nsec = secs * NS_PER_SEC}
}

// Converts a year plus "MMDDHHMMSS" into seconds since the Unix epoch, 
// validating field ranges. Computed directly (via the civil-date algorithm 
// below) rather than through time.Time so the whole year 1..9999 range is 
// computable before _time_from_unix decides how to represent it.
@(private)
_unix_from_fields :: proc "contextless" (year: int, fields: []byte) -> (unix_seconds: i64, err: Error) {
	month, mo_ok := _two_digits(fields[0:2])
	day, d_ok := _two_digits(fields[2:4])
	hour, h_ok := _two_digits(fields[4:6])
	minute, min_ok := _two_digits(fields[6:8])
	second, s_ok := _two_digits(fields[8:10])
	if !mo_ok || !d_ok || !h_ok || !min_ok || !s_ok {
		return 0, .Invalid_Time
	}
	if month < 1 || month > 12 || day < 1 || day > 31 {
		return 0, .Invalid_Time
	}
	if hour > 23 || minute > 59 || second > 59 {
		return 0, .Invalid_Time
	}
	days := _days_from_civil(i64(year), month, day)
	return days * 86400 + i64(hour) * 3600 + i64(minute) * 60 + i64(second), .None
}

// Returns the number of days since 1970-01-01 for a proleptic-Gregorian date 
// (Ref: http://howardhinnant.github.io/date_algorithms.html#days_from_civil).
// Exact for any representable year; no epoch-range limit.
@(private)
_days_from_civil :: proc "contextless" (y: i64, m, d: int) -> i64 {
	yy := y - (m <= 2 ? 1 : 0)
	era := (yy >= 0 ? yy : yy - 399) / 400
	yoe := yy - era * 400                                  // [0, 399]
	doy := i64((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1) // [0, 365]
	doe := yoe * 365 + yoe / 4 - yoe / 100 + doy           // [0, 146096]
	return era * 146097 + doe - 719468
}
