package asn1

// Tag class from the identifier octet (X.690 section 8.1.2.2).
Class :: enum u8 {
	Universal        = 0,
	Application      = 1,
	Context_Specific = 2,
	Private          = 3,
}

// Tag_Number enumerates the UNIVERSAL tag numbers relevant to DER as
// used by PKIX. Context-specific tags carry their number directly in
// Tag.number.
Tag_Number :: enum u32 {
	Boolean           = 1,
	Integer           = 2,
	Bit_String        = 3,
	Octet_String      = 4,
	Null              = 5,
	Object_Identifier = 6,
	Enumerated        = 10,
	UTF8_String       = 12,
	Sequence          = 16,
	Set               = 17,
	Numeric_String    = 18,
	Printable_String  = 19,
	Teletex_String    = 20,
	IA5_String        = 22,
	UTC_Time          = 23,
	Generalized_Time  = 24,
	Visible_String    = 26,
	BMP_String        = 30,
}

// Tag is a decoded identifier octet (plus high-tag-number form).
Tag :: struct {
	class:       Class,
	constructed: bool,
	number:      u32,
}

Error :: enum {
	None, 
	Truncated, // The element (or its header) extends past the end of the input.
	Invalid_Tag, // Malformed identifier octets (non-minimal high-tag-number form, or a tag number that overflows u32).
	Invalid_Length, // Indefinite length, non-minimal length encoding, or a length beyond what this implementation supports.
	Unexpected_Tag, // An expect_*/read_* procedure found a different tag than required.
	Invalid_Boolean, // BOOLEAN content was not exactly one octet of 0x00 or 0xFF.
	Invalid_Integer, // INTEGER content was empty or not minimally encoded.
	Integer_Overflow, // INTEGER does not fit the requested machine type.
	Negative_Integer, // INTEGER was negative where an unsigned value is required.
	Invalid_Bit_String, // BIT STRING content violated X.690 sections 8.6/11.2 (bad unused-bit count, non-zero padding bits, or unused bits where none are permitted).
	Invalid_Null, // NULL with non-empty content.
	Invalid_Object_Identifier, // OBJECT IDENTIFIER content was empty or not minimally encoded.
	Invalid_Time, // UTCTime/GeneralizedTime outside the RFC 5280 DER profile (YYMMDDHHMMSSZ / YYYYMMDDHHMMSSZ, Zulu only, seconds present, no fractional seconds), or an impossible date.
	Leftover_Bytes, // done() was called with input remaining.
	// An OBJECT IDENTIFIER arc exceeds u64. Arc magnitude is unbounded per X.660 (e.g. 2.25 UUID-derived OIDs carry a 128-bit arc), so
	// this is a representation limit of oid_components/oid_to_string, not a malformed input; compare such OIDs by their raw bytes.
	Arc_Overflow,
	Allocation_Failed, // OOM
	Buffer_Too_Small, // encode: the destination slice is shorter than encoded_len.
}

// universal builds a UNIVERSAL-class tag.
universal :: proc "contextless" (number: Tag_Number, constructed := false) -> Tag {
	return Tag{class = .Universal, constructed = constructed, number = u32(number)}
}

// context_specific builds a CONTEXT-SPECIFIC-class tag ("[n]").
context_specific :: proc "contextless" (number: u32, constructed := true) -> Tag {
	return Tag{class = .Context_Specific, constructed = constructed, number = number}
}
