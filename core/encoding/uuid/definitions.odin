package uuid

// A RFC 4122 Universally Unique Identifier
Identifier :: distinct [16]u8

EXPECTED_LENGTH :: 8 + 4 + 4 + 4 + 12 + 4

VERSION_BYTE_INDEX :: 6
VARIANT_BYTE_INDEX :: 8

// The number of 100-nanosecond intervals between 1582-10-15 and 1970-01-01.
HNS_INTERVALS_BETWEEN_GREG_AND_UNIX :: 141427 * 24 * 60 * 60 * 1000 * 1000 * 10

VERSION_7_TIME_MASK     :: 0xffffffff_ffff0000_00000000_00000000
VERSION_7_TIME_SHIFT    :: 80
VERSION_7_COUNTER_MASK  :: 0x00000000_00000fff_00000000_00000000
VERSION_7_COUNTER_SHIFT :: 64

@(private)
NO_CSPRNG_ERROR :: "The context random generator is not cryptographic. See the documentation for an example of how to set one up."
@(private)
BIG_CLOCK_ERROR :: "The clock sequence can only hold 14 bits of data, therefore no number greater than 16,383 (0x3FFF)."
@(private)
VERSION_7_BIG_COUNTER_ERROR :: "This implementation of the version 7 UUID counter can only hold 12 bits of data, therefore no number greater than 4,095 (0xFFF)."

Read_Error :: enum {
	None,
	Invalid_Length,
	Invalid_Hexadecimal,
	Invalid_Separator,
}

Variant_Type :: enum {
	Unknown,
	Reserved_Apollo_NCS,    // 0b0xx
	RFC_4122,               // 0b10x
	Reserved_Microsoft_COM, // 0b110
	Reserved_Future,        // 0b111
}

// Name string is a fully-qualified domain name.
@(rodata)
Namespace_DNS := Identifier {
	0x6b, 0xa7, 0xb8, 0x10, 0x9d, 0xad, 0x11, 0xd1,
	0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
}

// Name string is a URL.
@(rodata)
Namespace_URL := Identifier {
	0x6b, 0xa7, 0xb8, 0x11, 0x9d, 0xad, 0x11, 0xd1,
	0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
}

// Name string is an ISO OID.
@(rodata)
Namespace_OID := Identifier {
	0x6b, 0xa7, 0xb8, 0x12, 0x9d, 0xad, 0x11, 0xd1,
	0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
}

// Name string is an X.500 DN (in DER or a text output format).
@(rodata)
Namespace_X500 := Identifier {
	0x6b, 0xa7, 0xb8, 0x14, 0x9d, 0xad, 0x11, 0xd1,
	0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8,
}
