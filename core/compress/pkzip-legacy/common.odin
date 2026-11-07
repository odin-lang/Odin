package compress_pkzip_legacy

import "core:compress"

Error              :: compress.Error
General_Error      :: compress.General_Error
PKZIP_Legacy_Error :: compress.PKZIP_Legacy_Error

Implode_Option :: enum u16 {
	Large_Window = 1,
	Literal_Tree = 2,
}
Implode_Options :: bit_set[Implode_Option; u16]

SHRINK_MIN_CODE_SIZE      :: 9
SHRINK_MAX_CODE_SIZE      :: 13
SHRINK_TABLE_SIZE         :: 1 << SHRINK_MAX_CODE_SIZE
SHRINK_CONTROL_CODE       :: 256
SHRINK_FIRST_FREE_CODE    :: 257
SHRINK_INCREASE_CODE_SIZE :: 1
SHRINK_PARTIAL_CLEAR      :: 2
SHRINK_EXPANSION_MAX      :: SHRINK_TABLE_SIZE
SHRINK_LEAF_END           :: 0xffff

REDUCE_DLE                :: 144
REDUCE_MAX_FOLLOWERS      :: 32
REDUCE_MIN_MATCH          :: 3
REDUCE_EXPANSION_MAX      :: 512

IMPLODE_PRIMARY_BITS      :: 9
IMPLODE_MAX_CODE_LENGTH   :: 16
IMPLODE_LITERAL_SYMBOLS   :: 256
IMPLODE_LENGTH_SYMBOLS    :: 64
IMPLODE_DISTANCE_SYMBOLS  :: 64
IMPLODE_EXTRA_LENGTH      :: 63
IMPLODE_EXPANSION_MAX     :: 256

RESERVE_STREAM            :: 64 * 1024
GROWTH_MIN                :: 4 * 1024
GROWTH_STEP               :: 16 * 1024 * 1024

@(private)
Unshrink :: struct {
	parent:    [SHRINK_TABLE_SIZE]u16,
	value:     [SHRINK_TABLE_SIZE]u8,
	used:      [SHRINK_TABLE_SIZE]bool,
	children:  [SHRINK_TABLE_SIZE]u16,
	leaf_next: [SHRINK_TABLE_SIZE]u16,
	free:      [SHRINK_TABLE_SIZE / 64]u64,
	leaf_head: u16,
	stack:     [SHRINK_TABLE_SIZE + 1]u8,
}

@(private)
Expand :: struct {
	followers:  [256][REDUCE_MAX_FOLLOWERS]u8,
	counts:     [256]u8,
	index_bits: [256]u8,
}

@(private)
Expand_State :: enum {
	Literal,
	DLE,
	Length,
	Distance,
}

@(private)
Implode_Tree :: struct {
	table:   [1 << IMPLODE_PRIMARY_BITS]u16,
	first:   [IMPLODE_MAX_CODE_LENGTH + 1]int,
	count:   [IMPLODE_MAX_CODE_LENGTH + 1]int,
	offset:  [IMPLODE_MAX_CODE_LENGTH + 1]int,
	symbols: [IMPLODE_LITERAL_SYMBOLS]u8,
}
