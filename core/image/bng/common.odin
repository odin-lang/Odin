package bng

import "core:image"

Error   :: image.Error
Image   :: image.Image
Options :: image.Options

Default_Options :: Options{.alpha_premultiply}

MAX_CODE_LENGTH :: 12
TOKEN_COUNT     :: 144
TOKEN_EOL       :: 131
MAX_RUN         :: 8191
MAX_PAD_BYTES   :: 16
MAX_BODY_LENGTH :: 0x7FFF_FFFF

CODE_LENGTHS := [TOKEN_COUNT]u8{
	 3,  3,  3,  4,  4,  4,  4,  5,  5,  6,  6,  6,  6,  7,  7,  7,
	 7,  7,  7,  8,  8,  8,  8,  8,  8,  8,  8,  9,  9,  9,  9,  9,
	 9,  9,  9,  9,  9, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11, 11, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 11, 12,  7,
	 7, 12, 11,  9,  4,  6,  7,  8,  9, 10, 10, 11, 12, 12, 12, 12,
}

DECODE_MANTISSA_MASK :: 0x0F
DECODE_NEGATIVE      :: 0x10
DECODE_RUN           :: 0x20
DECODE_END_OF_ROW    :: 0x40

Decode_Entry :: struct {
	base:   u16,
	length: u8,
	flags:  u8,
}
#assert(size_of(Decode_Entry) == 4)

Encode_Entry :: struct {
	code:   u16,
	length: u8,
}

@(private)
decode_table: [1 << MAX_CODE_LENGTH]Decode_Entry

@(private)
encode_table: [TOKEN_COUNT]Encode_Entry

@(private)
residual_table: [256]u32

@(private)
Bit_Reader :: struct {
	data:  []u8,
	pos:   int,
	acc:   u64,
	count: uint,
	pad:   int,
}

@(private)
Bit_Writer :: struct {
	data:     []u8,
	pos:      int,
	acc:      u64,
	count:    uint,
	overflow: bool,
}
