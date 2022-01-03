package dynamic_bit_array

import "core:intrinsics"

/*
	Note that these constants are dependent on the backing being a u64.
*/
@(private="file")
INDEX_SHIFT :: 6

@(private="file")
INDEX_MASK  :: 63

Bit_Array :: struct {
	bits: [dynamic]u64,
	bias: int,
}

/*
	In:
		- ba:    ^Bit_Array - a pointer to the Bit Array
		- index: The bit index. Can be an enum member.

	Out:
		- res:   The bit you're interested in.
		- ok:    Whether the index was valid. Returns `false` if the index is smaller than the bias.

	The `ok` return value may be ignored.
*/
get :: proc(ba: ^Bit_Array, #any_int index: uint, allocator := context.allocator) -> (res: bool, ok: bool) {
	idx := int(index) - ba.bias

	if ba == nil || int(index) < ba.bias { return false, false }
	context.allocator = allocator

	leg_index := idx >> INDEX_SHIFT
	bit_index := idx &  INDEX_MASK

	/*
		If we `get` a bit that doesn't fit in the Bit Array, it's naturally `false`.
		This early-out prevents unnecessary resizing.
	*/
	if leg_index + 1 > len(ba.bits) { return false, true }

	val := u64(1 << uint(bit_index))
	res = ba.bits[leg_index] & val == val

	return res, true
}

/*
	In:
		- ba:    ^Bit_Array - a pointer to the Bit Array
		- index: The bit index. Can be an enum member.

	Out:
		- ok:    Whether or not we managed to set requested bit.

	`set` automatically resizes the Bit Array to accommodate the requested index if needed.
*/
set :: proc(ba: ^Bit_Array, #any_int index: uint, allocator := context.allocator) -> (ok: bool) {

	idx := int(index) - ba.bias

	if ba == nil || int(index) < ba.bias { return false }
	context.allocator = allocator

	leg_index := idx >> INDEX_SHIFT
	bit_index := idx &  INDEX_MASK

	resize_if_needed(ba, leg_index) or_return

	ba.bits[leg_index] |= 1 << uint(bit_index)
	return true
}

/*
	A helper function to create a Bit Array with optional bias, in case your smallest index is non-zero (including negative).
*/
create :: proc(max_index: int, min_index := 0, allocator := context.allocator) -> (res: Bit_Array, ok: bool) #optional_ok {
	context.allocator = allocator
	size_in_bits := max_index - min_index

	if size_in_bits < 1 { return {}, false }

	legs := size_in_bits >> INDEX_SHIFT

	res = Bit_Array{
		bias = min_index,
	}
	return res, resize_if_needed(&res, size_in_bits)
}

/*
	Sets all bits to `false`.
*/
clear :: proc(ba: ^Bit_Array) {
	if ba == nil { return }
	ba.bits = {}
}

/*
	Releases the memory used by the Bit Array.
*/
destroy :: proc(ba: ^Bit_Array) {
	if ba == nil { return }
	delete(ba.bits)
}

/*
	Resizes the Bit Array. For internal use.
	If you want to reserve the memory for a given-sized Bit Array up front, you can use `create`.
*/
@(private="file")
resize_if_needed :: proc(ba: ^Bit_Array, legs: int, allocator := context.allocator) -> (ok: bool) {
	if ba == nil { return false }

	context.allocator = allocator

	if legs + 1 > len(ba.bits) {
		resize(&ba.bits, legs + 1)
	}
	return len(ba.bits) > legs
}