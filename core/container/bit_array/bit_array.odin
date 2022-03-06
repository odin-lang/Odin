package dynamic_bit_array

import "core:intrinsics"
import "core:mem"

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
	max_index: int,
}

Bit_Array_Iterator :: struct {
	array: ^Bit_Array,
	word_idx: int,
	bit_idx: uint,
}

/*
	In:
		- ba:   ^Bit_Array - the array to iterate over

	Out:
		- it:   ^Bit_Array_Iterator - the iterator that holds iteration state
*/
make_iterator :: proc (ba: ^Bit_Array) -> (it: Bit_Array_Iterator) {
	return Bit_Array_Iterator { array = ba }
}

/*
	In:
		- it:    ^Bit_Array_Iterator - the iterator struct that holds the state.

	Out:
		- set:    bool - the state of the bit at `index`
		- index:  int - the next bit of the Bit_Array referenced by `it`.
		- ok:	  bool - `true` if the iterator returned a valid index,
			  `false` if there were no more bits
*/
iterate_by_all :: proc (it: ^Bit_Array_Iterator) -> (set: bool, index: int, ok: bool) {
	index = it.word_idx * NUM_BITS + int(it.bit_idx) + it.array.bias
	if index > it.array.max_index { return false, 0, false }

	word := it.array.bits[it.word_idx] if len(it.array.bits) > it.word_idx else 0
	set = (word >> it.bit_idx & 1) == 1

	it.bit_idx += 1
	if it.bit_idx >= NUM_BITS {
		it.bit_idx = 0
		it.word_idx += 1
	}

	return set, index, true
}

/*
	In:
		- it:     ^Bit_Array_Iterator - the iterator struct that holds the state.

	Out:
		- index:  int - the next set bit of the Bit_Array referenced by `it`.
		- ok:	  bool - `true` if the iterator returned a valid index,
			  `false` if there were no more bits set
*/
iterate_by_set :: proc (it: ^Bit_Array_Iterator) -> (index: int, ok: bool) {
	return iterate_internal_(it, true)
}

/*
	In:
		- it:	  ^Bit_Array_Iterator - the iterator struct that holds the state.

	Out:
		- index:  int - the next unset bit of the Bit_Array referenced by `it`.
		- ok:	  bool - `true` if the iterator returned a valid index,
			  `false` if there were no more unset bits
*/
iterate_by_unset:: proc (it: ^Bit_Array_Iterator) -> (index: int, ok: bool) {
	return iterate_internal_(it, false)
}

@(private="file")
iterate_internal_ :: proc (it: ^Bit_Array_Iterator, $ITERATE_SET_BITS: bool) -> (index: int, ok: bool) {
	word := it.array.bits[it.word_idx] if len(it.array.bits) > it.word_idx else 0
	when ! ITERATE_SET_BITS { word = ~word }

	// if the word is empty or we have already gone over all the bits in it,
	// b.bit_idx is greater than the index of any set bit in the word,
	// meaning that word >> b.bit_idx == 0.
	for it.word_idx < len(it.array.bits) && word >> it.bit_idx == 0 {
		it.word_idx += 1
		it.bit_idx = 0
		word = it.array.bits[it.word_idx] if len(it.array.bits) > it.word_idx else 0
		when ! ITERATE_SET_BITS { word = ~word }
	}

	// if we are iterating the set bits, reaching the end of the array means we have no more bits to check
	when ITERATE_SET_BITS {
		if it.word_idx >= len(it.array.bits) {
			return 0, false
		}
	}

	// reaching here means that the word has some set bits
	it.bit_idx += uint(intrinsics.count_trailing_zeros(word >> it.bit_idx))
	index = it.word_idx * NUM_BITS + int(it.bit_idx) + it.array.bias

	it.bit_idx += 1
	if it.bit_idx >= NUM_BITS {
		it.bit_idx = 0
		it.word_idx += 1
	}
	return index, index <= it.array.max_index
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

	ba.max_index = max(idx, ba.max_index)
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
		max_index = max_index,
	}
	return res, resize_if_needed(&res, legs)
}

/*
	Sets all bits to `false`.
*/
clear :: proc(ba: ^Bit_Array) {
	if ba == nil { return }
	mem.zero_slice(ba.bits[:])
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
