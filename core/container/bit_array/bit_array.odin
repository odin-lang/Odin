package dynamic_bit_array

import "core:intrinsics"

/*
	Note that these constants are dependent on the backing being a u64.
*/
@(private="file")
INDEX_SHIFT :: 6

@(private="file")
INDEX_MASK  :: 63

@(private="file")
NUM_BITS :: 64

Bit_Array :: struct {
	bits: [dynamic]u64,
	bias: int,
}

Bit_Array_Iterator :: struct {
	array: ^Bit_Array,
	current_word: uint,
	current_bit: uint,
}

/*
	In:
		- it:    ^Bit_Array_Iterator - the iterator struct that holds the state.

	Out:
		- index: int - the next set bit of the Bit_Array referenced by `it`.
		- ok:	 bool - `true` if the iterator returned a valid index,
				`false` if there were no more bits set
*/
iterator :: proc (it: ^Bit_Array_Iterator) -> (int, bool) {
	words := it.array.bits
	// if the word is empty or we have already gone over all the bits in it,
	// b.current_bit is greater than the index of any set bit in the word,
	// meaning that word >> b.current_bit == 0.
	for it.current_word < len(words) && (words[it.current_word] >> it.current_bit == 0) {
		it.current_word += 1
		it.current_bit = 0
	}

	if it.current_word >= len(words) { return 0, false }

	// since we exited the loop and didn't return, this word has some bits higher than
	// or equal to `it.current_bit` set.
	offset := intrinsics.count_trailing_zeros(words[it.current_word] >> it.current_bit)
	// skip over the bit, if the resulting it.current_bit is over 63,
	// it is handled by the initial for loop in the next iteration.
	it.current_bit += uint(offset)
	defer it.current_bit += 1
	return int(it.current_word * NUM_BITS + it.current_bit) + it.array.bias, true
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
	return res, resize_if_needed(&res, legs)
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
