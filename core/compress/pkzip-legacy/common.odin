package compress_pkzip_legacy

import "core:compress"

Error              :: compress.Error
General_Error      :: compress.General_Error
PKZIP_Legacy_Error :: compress.PKZIP_Legacy_Error

Implode_Option :: enum u8 {
	Large_Window = 1,
	Literal_Tree = 2,
}
Implode_Options :: bit_set[Implode_Option; u8]

SHRINK_MIN_CODE_SIZE      :: 9
SHRINK_MAX_CODE_SIZE      :: 13
SHRINK_TABLE_SIZE         :: 1 << SHRINK_MAX_CODE_SIZE
SHRINK_CONTROL_CODE       :: 256
SHRINK_FIRST_FREE_CODE    :: 257
SHRINK_INCREASE_CODE_SIZE :: 1
SHRINK_PARTIAL_CLEAR      :: 2
SHRINK_LEAF_END           :: 0xffff
#assert(compress.SHRINK_EXPANSION_MAX == SHRINK_TABLE_SIZE)

REDUCE_DLE                :: 144
REDUCE_MAX_FOLLOWERS      :: 32
REDUCE_MIN_MATCH          :: 3

IMPLODE_PRIMARY_BITS      :: 9
IMPLODE_MAX_CODE_LENGTH   :: 16
IMPLODE_LITERAL_SYMBOLS   :: 256
IMPLODE_LENGTH_SYMBOLS    :: 64
IMPLODE_DISTANCE_SYMBOLS  :: 64
IMPLODE_EXTRA_LENGTH      :: 63

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

@(private)
refill_bits :: proc(z: ^compress.Context) -> (err: Error) #no_bounds_check {
	for z.num_bits <= 56 {
		if len(z.window) == 0 {
			refill_err := compress.refill_window(z, 1)
			if refill_err == .EOF {
				return nil
			}
			if refill_err != nil {
				return refill_err
			}
		}
		z.code_buffer |= u64(z.window[0]) << z.num_bits
		z.window       = z.window[1:]
		z.num_bits    += 8
	}
	return nil
}

@(private)
read_bits :: #force_inline proc(z: ^compress.Context, count: uint) -> (value: int, available: bool, err: Error) #no_bounds_check {
	if z.num_bits < u64(count) {
		refill_bits(z) or_return
		if z.num_bits < u64(count) {
			return 0, false, nil
		}
	}
	value = int(z.code_buffer & (u64(1) << count - 1))
	z.code_buffer >>= count
	z.num_bits     -= u64(count)
	return value, true, nil
}

@(private)
read_bits_required :: #force_inline proc(z: ^compress.Context, count: uint) -> (value: int, err: Error) {
	available: bool
	value, available = read_bits(z, count) or_return
	if !available {
		return 0, General_Error.Stream_Too_Short
	}
	return
}
