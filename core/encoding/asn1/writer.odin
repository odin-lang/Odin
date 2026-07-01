package asn1

/*
DER (Distinguished Encoding Rules) writer, the inverse of the cursor
reader, and the encoding substrate for signatures, keys, and certificates.

The model is declarative: build a tree of `Value` nodes with the
constructors below, then turn it into bytes with `encoded_len` + `encode`
(no allocation, into a caller buffer) or `marshal` (one allocation, owned
slice). A SEQUENCE/SET simply holds its children, so length is discovered
by a measure pass rather than back-patched, and `set` can sort its
children (DER SET OF ordering) without disturbing this surface, both are
additive.

Zero-copy, with a lifetime caveat: the constructors BORROW their byte and
child inputs (no copies), so a Value tree is only valid while those inputs
live. In practice build and encode the tree within one expression, or back
its children with a slice/array that outlives the encode call:

	// one expression (inputs r, s outlive the call):
	out := marshal(sequence({integer_unsigned(r), integer_unsigned(s)})) or_return

DER is canonical by construction: definite minimal-length headers, minimal
INTEGER magnitudes with the sign octet inserted only when required. The
writer emits low-tag-number identifiers only (tag number <= 30), which
covers all of PKIX; high-tag-number form is a future addition.

See:
- [[ https://www.itu.int/rec/T-REC-X.690 ]]
*/

import dt "core:time"

// Selects how a Value's content octets are produced when encoding.
@(private)
_Form :: enum u8 {
	Primitive,         // content holds the exact content octets, emitted verbatim.
	Constructed,       // children holds the sub-values, emitted in order.
	Integer_Magnitude, // content holds an unsigned big-endian magnitude; DER INTEGER rules are applied on emit.
	Bit_String_Octets, // content holds whole-octet payload; a leading 0x00 unused-bits count is added on emit.
	Bit_String_Wrapped, // children's DER becomes the payload, behind the 0x00 unused-bits count.
	Time,              // _when is formatted to UTCTime/GeneralizedTime per the tag on emit.
	Raw,               // content is a complete pre-encoded element, emitted verbatim (no added tag/length).
}

// Value is a node in a to-be-encoded DER tree. Construct it with the
// helpers below rather than by hand; the fields are an implementation
// detail. The byte/child inputs are borrowed (see the package lifetime note).
Value :: struct {
	tag:      Tag,
	form:     _Form,
	content:  []byte,
	children: []Value,
	_when:    dt.Time, // meaningful only when form == .Time: the instant to format on emit
}

@(rodata, private)
_BOOL_FALSE := []byte{0x00}
@(rodata, private)
_BOOL_TRUE := []byte{0xFF}

// Builds a primitive value with `tag` and the exact `content`
// octets (emitted verbatim). The caller owns canonical-form correctness.
primitive :: proc "contextless" (tag: Tag, content: []byte) -> Value {
	return Value{tag = tag, form = .Primitive, content = content}
}

// Builds a value whose encoding IS `encoded` verbatim, a complete
// already-DER-encoded element spliced in as-is (no tag/length added). The
// composition primitive for nesting an independently-marshalled structure
// (a signed CertificationRequestInfo, a pre-built TBSCertificate) inside a
// parent without re-encoding it.
raw :: proc "contextless" (encoded: []byte) -> Value {
	return Value{form = .Raw, content = encoded}
}

// Builds a BOOLEAN (DER: 0x00 / 0xFF).
boolean :: proc "contextless" (v: bool) -> Value {
	return Value{tag = universal(.Boolean), form = .Primitive, content = v ? _BOOL_TRUE : _BOOL_FALSE}
}

// Builds an INTEGER from an unsigned big-endian magnitude: leading zero 
// octets are dropped (minimal encoding) and a single 0x00 sign octet is 
// inserted when the top bit would otherwise read as negative. An empty 
// or all-zero magnitude encodes as 0. This is the shape RSA moduli / 
// exponents and certificate serials are written in, and the inverse of 
// read_unsigned_integer_bytes.
integer_unsigned :: proc "contextless" (magnitude: []byte) -> Value {
	return Value{tag = universal(.Integer), form = .Integer_Magnitude, content = magnitude}
}

// Builds an INTEGER from content octets that are ALREADY a minimal
// two's-complement encoding (e.g. a serial preserved verbatim from
// read_integer_bytes). No normalization is applied.
integer_raw :: proc "contextless" (content: []byte) -> Value {
	return Value{tag = universal(.Integer), form = .Primitive, content = content}
}

// Builds an OCTET STRING wrapping `content`.
octet_string :: proc "contextless" (content: []byte) -> Value {
	return Value{tag = universal(.Octet_String), form = .Primitive, content = content}
}

// Builds an OCTET STRING whose content is the DER encoding of `children`,
// the form X.509 Extension.extnValue uses to carry an extension's value. The
// OCTET STRING stays primitive (0x04); its content is just the children's
// concatenated DER, so this reuses the constructed-content machinery without
// a wrapper octet.
octet_string_wrap :: proc "contextless" (children: []Value) -> Value {
	return Value{tag = universal(.Octet_String), form = .Constructed, children = children}
}

// Builds a SEQUENCE from its sub-values (borrowed).
sequence :: proc "contextless" (children: []Value) -> Value {
	return Value{tag = universal(.Sequence, true), form = .Constructed, children = children}
}

// Builds a SET from its sub-values, emitted in the given order. DER SET OF
// requires components sorted by their encoding (X.690 section 11.6); this
// constructor does NOT sort, so a SET OF with more than one element must be
// given pre-sorted (a single-element RDN, the common PKIX case, is trivially
// ordered). 
set :: proc "contextless" (children: []Value) -> Value {
	return Value{tag = universal(.Set, true), form = .Constructed, children = children}
}

// Builds a SET OF from its sub-values, sorted into the DER canonical order
// (X.690 section 11.6: component encodings ascending, shorter padded with
// trailing 0-octets). Unlike the other constructors this one ALLOCATES, it
// must encode each child to compare them, and it sorts `children` in place;
// the returned Value then borrows that reordered slice as usual. Scratch is
// taken from and released to `allocator`. 0/1-element sets need no work.
@(require_results)
set_of :: proc(children: []Value, allocator := context.allocator) -> (value: Value, err: Error) {
	n := len(children)
	if n <= 1 {
		return set(children), .None
	}
	encs, merr := make([][]byte, n, allocator)
	if merr != nil {
		return {}, .Allocation_Failed
	}
	defer {
		for e in encs {
			delete(e, allocator)
		}
		delete(encs, allocator)
	}
	for i in 0 ..< n {
		encs[i] = marshal(children[i], allocator) or_return
	}
	// Insertion sort (n is small for a SET OF) keying children on their encodings.
	for i in 1 ..< n {
		for j := i; j > 0 && _der_less(encs[j], encs[j - 1]); j -= 1 {
			encs[j], encs[j - 1] = encs[j - 1], encs[j]
			children[j], children[j - 1] = children[j - 1], children[j]
		}
	}
	return set(children), .None
}

// Compares two encodings as octet strings with the shorter padded at its 
// trailing end with 0-octets (X.690 section 11.6 SET OF ordering).
@(private)
_der_less :: proc "contextless" (a, b: []byte) -> bool {
	n := min(len(a), len(b))
	for i in 0 ..< n {
		if a[i] != b[i] {
			return a[i] < b[i]
		}
	}
	if len(a) < len(b) {
		for i in n ..< len(b) {
			if b[i] != 0x00 {
				return true // a's zero padding is below b's non-zero tail
			}
		}
		return false
	}
	for i in n ..< len(a) {
		if a[i] != 0x00 {
			return false // a's non-zero tail is above b's zero padding
		}
	}
	return false
}

// Builds a NULL (empty content).
null :: proc "contextless" () -> Value {
	return Value{tag = universal(.Null), form = .Primitive, content = nil}
}

// Builds an OBJECT IDENTIFIER from already-encoded content octets (the form
// PKIX OIDs are held and compared in, e.g. the package's known-OID
// constants). The content is emitted verbatim; the caller owns its validity.
object_identifier :: proc "contextless" (content: []byte) -> Value {
	return Value{tag = universal(.Object_Identifier), form = .Primitive, content = content}
}

// Builds a BIT STRING from a whole-octet payload (unused-bits count 0), the
// only form PKIX uses for SubjectPublicKeyInfo keys and signature values.
bit_string_octets :: proc "contextless" (payload: []byte) -> Value {
	return Value{tag = universal(.Bit_String), form = .Bit_String_Octets, content = payload}
}

// Builds a BIT STRING (whole octets) whose payload is the DER encoding of
// `children`, the form SubjectPublicKeyInfo uses to carry an RSAPublicKey
// SEQUENCE inside the subjectPublicKey bit string.
bit_string_wrap :: proc "contextless" (children: []Value) -> Value {
	return Value{tag = universal(.Bit_String), form = .Bit_String_Wrapped, children = children}
}

// Builds a UTCTime ("YYMMDDHHMMSSZ", RFC 5280 DER profile). Appropriate for
// instants in 1950..=2049; the sliding-window century is what the reader
// (read_utc_time) decodes, so use generalized_time outside that range.
utc_time :: proc "contextless" (at: dt.Time) -> Value {
	return Value{tag = universal(.UTC_Time), form = .Time, _when = at}
}

// Builds a GeneralizedTime ("YYYYMMDDHHMMSSZ", RFC 5280 DER profile: Zulu,
// seconds present, no fractional part). The inverse of read_generalized_time.
generalized_time :: proc "contextless" (at: dt.Time) -> Value {
	return Value{tag = universal(.Generalized_Time), form = .Time, _when = at}
}

// 2050-01-01T00:00:00Z: the RFC 5280 boundary between the two time forms.
@(private)
_UNIX_2050 :: i64(2_524_608_000)

// Builds a UTCTime or GeneralizedTime, auto-selecting the form per the RFC
// 5280 profile: UTCTime for instants in 1950..=2049, GeneralizedTime from
// 2050 on. (X.509 validity dates are written this way.)
time :: proc "contextless" (at: dt.Time) -> Value {
	if dt.to_unix_seconds(at) < _UNIX_2050 {
		return utc_time(at)
	}
	return generalized_time(at)
}

// Builds a primitive [number] IMPLICIT value carrying raw content octets,
// e.g. AuthorityKeyIdentifier's keyIdentifier [0] IMPLICIT OCTET STRING.
context_primitive :: proc "contextless" (number: u32, content: []byte) -> Value {
	return Value{tag = context_specific(number, false), form = .Primitive, content = content}
}

// Builds a constructed [number] EXPLICIT wrapper around the given sub-values,
// e.g. TBSCertificate's version [0] EXPLICIT INTEGER.
context_explicit :: proc "contextless" (number: u32, children: []Value) -> Value {
	return Value{tag = context_specific(number, true), form = .Constructed, children = children}
}

// Returns the exact number of bytes encode/marshal will write
// for `v`, including its identifier and length octets.
encoded_len :: proc(v: Value) -> int {
	if v.form == .Raw {
		return len(v.content) // already a complete element
	}
	clen := _content_len(v)
	return _tag_len(v.tag) + _length_len(clen) + clen
}

// Writes the DER encoding of `v` into `dst` and returns the number
// of bytes written. `dst` must be at least encoded_len(v) bytes; if it is
// shorter, nothing is written and Buffer_Too_Small is returned.
encode :: proc(v: Value, dst: []byte) -> (n: int, err: Error) {
	need := encoded_len(v)
	if len(dst) < need {
		return 0, .Buffer_Too_Small
	}
	_emit(v, dst[:need])
	return need, .None
}

// Encodes `v` into a freshly allocated slice the caller owns.
marshal :: proc(v: Value, allocator := context.allocator) -> (out: []byte, err: Error) {
	n := encoded_len(v)
	buf, merr := make([]byte, n, allocator)
	if merr != nil {
		return nil, .Allocation_Failed
	}
	_emit(v, buf)
	return buf, .None
}

@(private)
_content_len :: proc(v: Value) -> int {
	switch v.form {
	case .Primitive:
		return len(v.content)
	case .Integer_Magnitude:
		start, pad := _int_shape(v.content)
		if start == len(v.content) {
			return 1 // zero encodes as a single 0x00 octet
		}
		return (len(v.content) - start) + (pad ? 1 : 0)
	case .Bit_String_Octets:
		return 1 + len(v.content) // leading unused-bits octet (0x00)
	case .Bit_String_Wrapped:
		total := 1 // leading unused-bits octet (0x00)
		for child in v.children {
			total += encoded_len(child)
		}
		return total
	case .Time:
		return _time_content_len(v.tag)
	case .Constructed:
		total := 0
		for child in v.children {
			total += encoded_len(child)
		}
		return total
	case .Raw:
		return len(v.content) // handled in encoded_len; here for exhaustiveness
	}
	return 0
}

// Writes v's complete encoding so that it ENDS at dst[len(dst)], i.e. into
// the tail of dst, and returns the bytes written. `dst` is the exactly-sized
// region this node may occupy (encoded_len(v) == len(dst) at the top call).
//
// Emitting back-to-front means a constructed node's content length falls out
// of where its children landed (no second measure pass): encoded_len does the
// single O(n) sizing pass, this does the single O(n) write pass. DER wants to
// be written this way — it is the tree generalization of the fixed-buffer
// trick in crypto/ecdsa's hand-rolled encoder.
@(private)
_emit :: proc(v: Value, dst: []byte) -> int {
	if v.form == .Raw {
		n := len(v.content)
		copy(dst[len(dst) - n:], v.content)
		return n
	}
	end := len(dst)
	switch v.form {
	case .Raw: // handled by the early return above
	case .Primitive:
		end -= len(v.content)
		copy(dst[end:], v.content)
	case .Integer_Magnitude:
		start, pad := _int_shape(v.content)
		if start == len(v.content) {
			end -= 1
			dst[end] = 0x00 // zero -> single 0x00 octet
		} else {
			body := v.content[start:]
			end -= len(body)
			copy(dst[end:], body)
			if pad {
				end -= 1
				dst[end] = 0x00 // sign octet so the value reads as non-negative
			}
		}
	case .Bit_String_Octets:
		end -= len(v.content)
		copy(dst[end:], v.content)
		end -= 1
		dst[end] = 0x00 // unused-bits count: whole octets
	case .Bit_String_Wrapped:
		for i := len(v.children) - 1; i >= 0; i -= 1 {
			end -= _emit(v.children[i], dst[:end])
		}
		end -= 1
		dst[end] = 0x00 // unused-bits count: whole octets
	case .Time:
		tmp: [15]byte // GeneralizedTime is the longest form
		n := _format_time(tmp[:], v._when, v.tag.number == u32(Tag_Number.Generalized_Time))
		end -= n
		copy(dst[end:], tmp[:n])
	case .Constructed:
		for i := len(v.children) - 1; i >= 0; i -= 1 {
			end -= _emit(v.children[i], dst[:end])
		}
	}
	clen := len(dst) - end // content length, read off the cursor — never recomputed

	tmp: [9]byte // identifier byte + up to 8 length octets covers any int length
	lw := _write_length(tmp[:], clen)
	end -= lw
	copy(dst[end:], tmp[:lw])

	end -= 1
	dst[end] = _tag_byte(v.tag)

	return len(dst) - end
}

// UTCTime content is "YYMMDDHHMMSSZ" (13 octets); GeneralizedTime is
// "YYYYMMDDHHMMSSZ" (15). The content length is fixed by the tag, so it is
// known for the measure pass without formatting.
@(private)
_time_content_len :: proc "contextless" (tag: Tag) -> int {
	return tag.number == u32(Tag_Number.Generalized_Time) ? 15 : 13
}

// Formats `at` into dst as the RFC 5280 DER time profile (Zulu, seconds
// present, no fractional part) and returns the bytes written: 15 for
// GeneralizedTime ("YYYYMMDDHHMMSSZ"), 13 for UTCTime ("YYMMDDHHMMSSZ", with
// the low two year digits). dst must hold the full width.
@(private)
_format_time :: proc "contextless" (dst: []byte, at: dt.Time, generalized: bool) -> int {
	// time_to_datetime decomposes the instant into UTC calendar fields; it only
	// fails outside time.Time's range, which an in-range time.Time can't reach.
	c, _ := dt.time_to_datetime(at)
	p := 0
	if generalized {
		p += _write_digits(dst[p:], int(c.year), 4)
	} else {
		p += _write_digits(dst[p:], int(c.year % 100), 2)
	}
	p += _write_digits(dst[p:], int(c.month), 2)
	p += _write_digits(dst[p:], int(c.day), 2)
	p += _write_digits(dst[p:], int(c.hour), 2)
	p += _write_digits(dst[p:], int(c.minute), 2)
	p += _write_digits(dst[p:], int(c.second), 2)
	dst[p] = 'Z'
	p += 1
	return p
}

// Writes `value` as exactly `width` zero-padded decimal digits.
@(private)
_write_digits :: proc "contextless" (dst: []byte, value, width: int) -> int {
	x := value
	for i := width - 1; i >= 0; i -= 1 {
		dst[i] = byte('0' + x % 10)
		x /= 10
	}
	return width
}

// Reports the index of the first significant magnitude octet
// (== len(mag) when the value is zero) and whether a 0x00 sign octet must
// be prepended so the result reads as non-negative.
@(private)
_int_shape :: proc "contextless" (mag: []byte) -> (start: int, pad: bool) {
	start = 0
	for start < len(mag) && mag[start] == 0x00 {
		start += 1
	}
	if start == len(mag) {
		return start, false
	}
	return start, mag[start] & 0x80 != 0
}

// _length_len / _write_length are the inverse of _read_length: definite
// form, minimal (short form below 128, otherwise the fewest octets).
@(private)
_length_len :: proc "contextless" (length: int) -> int {
	if length < 0x80 {
		return 1
	}
	n := 1
	v := length
	for v > 0 {
		v >>= 8
		n += 1
	}
	return n
}

@(private)
_write_length :: proc "contextless" (dst: []byte, length: int) -> int {
	if length < 0x80 {
		dst[0] = byte(length)
		return 1
	}
	nbytes := 0
	v := length
	for v > 0 {
		v >>= 8
		nbytes += 1
	}
	dst[0] = 0x80 | byte(nbytes)
	for i in 0 ..< nbytes {
		dst[1 + i] = byte(length >> uint(8 * (nbytes - 1 - i)))
	}
	return 1 + nbytes
}

// _tag_len / _tag_byte are the inverse of _read_tag, low-tag-number form
// only (number <= 30); PKIX never needs high-tag-number identifiers.
@(private)
_tag_len :: proc "contextless" (tag: Tag) -> int {
	return 1
}

@(private)
_tag_byte :: proc "contextless" (tag: Tag) -> byte {
	assert_contextless(tag.number <= 30, "asn1: high-tag-number form is not supported by the writer")
	b := byte(tag.class) << 6
	if tag.constructed {
		b |= 0x20
	}
	b |= byte(tag.number) & 0x1F
	return b
}
