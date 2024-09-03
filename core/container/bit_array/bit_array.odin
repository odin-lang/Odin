package container_dynamic_bit_array

import "base:builtin"
import "base:intrinsics"
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
	bits:         [dynamic]u64,
	bias:         int,
	length:       int,
	free_pointer: bool,
}

Bit_Array_Iterator :: struct {
	array:    ^Bit_Array,
	word_idx: int,
	bit_idx:  uint,
}
/*
Wraps a `Bit_Array` into an Iterator

Inputs:
- ba: Pointer to the Bit_Array

Returns:
- it: Iterator struct
*/
make_iterator :: proc (ba: ^Bit_Array) -> (it: Bit_Array_Iterator) {
	return Bit_Array_Iterator { array = ba }
}
/*
Returns the next bit, including its set-state. ok=false once exhausted

Inputs:
- it: The iterator that holds the state.

Returns:
- set: `true` if the bit at `index` is set.
- index: The next bit of the Bit_Array referenced by `it`.
- ok: `true` if the iterator can continue, `false` if the iterator is done
*/
iterate_by_all :: proc (it: ^Bit_Array_Iterator) -> (set: bool, index: int, ok: bool) {
	index = it.word_idx * NUM_BITS + int(it.bit_idx) + it.array.bias
	if index >= it.array.length + it.array.bias { return false, 0, false }

	word := it.array.bits[it.word_idx] if builtin.len(it.array.bits) > it.word_idx else 0
	set = (word >> it.bit_idx & 1) == 1

	it.bit_idx += 1
	if it.bit_idx >= NUM_BITS {
		it.bit_idx = 0
		it.word_idx += 1
	}

	return set, index, true
}
/*
Returns the next Set Bit, for example if `0b1010`, then the iterator will return index={1, 3} over two calls.

Inputs:
- it: The iterator that holds the state.

Returns:
- index: The next *set* bit of the Bit_Array referenced by `it`.
- ok: `true` if the iterator can continue, `false` if the iterator is done
*/
iterate_by_set :: proc (it: ^Bit_Array_Iterator) -> (index: int, ok: bool) {
	return iterate_internal_(it, true)
}
/*
Returns the next Unset Bit, for example if `0b1010`, then the iterator will return index={0, 2} over two calls.

Inputs:
- it: The iterator that holds the state.

Returns:
- index: The next *unset* bit of the Bit_Array referenced by `it`.
- ok: `true` if the iterator can continue, `false` if the iterator is done
*/
iterate_by_unset:: proc (it: ^Bit_Array_Iterator) -> (index: int, ok: bool) {
	return iterate_internal_(it, false)
}
/*
Iterates through set/unset bits

*Private*

Inputs:
- it: The iterator that holds the state.
- ITERATE_SET_BITS: `true` for returning only set bits, false for returning only unset bits

Returns:
- index: The next *unset* bit of the Bit_Array referenced by `it`.
- ok: `true` if the iterator can continue, `false` if the iterator is done
*/
@(private="file")
iterate_internal_ :: proc (it: ^Bit_Array_Iterator, $ITERATE_SET_BITS: bool) -> (index: int, ok: bool) {
	word := it.array.bits[it.word_idx] if builtin.len(it.array.bits) > it.word_idx else 0
	when ! ITERATE_SET_BITS { word = ~word }

	// If the word is empty or we have already gone over all the bits in it,
	// b.bit_idx is greater than the index of any set bit in the word,
	// meaning that word >> b.bit_idx == 0.
	for it.word_idx < builtin.len(it.array.bits) && word >> it.bit_idx == 0 {
		it.word_idx += 1
		it.bit_idx = 0
		word = it.array.bits[it.word_idx] if builtin.len(it.array.bits) > it.word_idx else 0
		when ! ITERATE_SET_BITS { word = ~word }
	}

	// If we are iterating the set bits, reaching the end of the array means we have no more bits to check
	when ITERATE_SET_BITS {
		if it.word_idx >= builtin.len(it.array.bits) {
			return 0, false
		}
	}

	// Reaching here means that the word has some set bits
	it.bit_idx += uint(intrinsics.count_trailing_zeros(word >> it.bit_idx))
	index = it.word_idx * NUM_BITS + int(it.bit_idx) + it.array.bias

	it.bit_idx += 1
	if it.bit_idx >= NUM_BITS {
		it.bit_idx = 0
		it.word_idx += 1
	}
	return index, index < it.array.length + it.array.bias
}
/*
Gets the state of a bit in the bit-array

Inputs:
- ba: Pointer to the Bit_Array
- index: Which bit in the array

Returns:
- res: `true` if the bit at `index` is set.
- ok: Whether the index was valid. Returns `false` if the index is smaller than the bias.
*/
get :: proc(ba: ^Bit_Array, #any_int index: uint) -> (res: bool, ok: bool) #optional_ok {
	idx := int(index) - ba.bias

	if ba == nil || int(index) < ba.bias { return false, false }

	leg_index := idx >> INDEX_SHIFT
	bit_index := idx &  INDEX_MASK

	/*
		If we `get` a bit that doesn't fit in the Bit Array, it's naturally `false`.
		This early-out prevents unnecessary resizing.
	*/
	if leg_index + 1 > builtin.len(ba.bits) { return false, true }

	val := u64(1 << uint(bit_index))
	res = ba.bits[leg_index] & val == val

	return res, true
}
/*
Gets the state of a bit in the bit-array

*Bypasses all Checks*

Inputs:
- ba: Pointer to the Bit_Array
- index: Which bit in the array

Returns:
- `true` if bit is set
*/
unsafe_get :: #force_inline proc(ba: ^Bit_Array, #any_int index: uint) -> bool #no_bounds_check {
	return bool((ba.bits[index >> INDEX_SHIFT] >> uint(index & INDEX_MASK)) & 1)
}
/*
Sets the state of a bit in the bit-array

*Conditionally Allocates (Resizes backing data when `index > len(ba.bits)`)*

Inputs:
- ba: Pointer to the Bit_Array
- index: Which bit in the array
- set_to: `true` sets the bit on, `false` to turn it off
- allocator: (default is context.allocator)

Returns:
- ok: Whether the set was successful, `false` on allocation failure or bad index
*/
set :: proc(ba: ^Bit_Array, #any_int index: uint, set_to: bool = true, allocator := context.allocator) -> (ok: bool) {

	idx := int(index) - ba.bias

	if ba == nil || int(index) < ba.bias { return false }
	context.allocator = allocator

	leg_index := idx >> INDEX_SHIFT
	bit_index := idx &  INDEX_MASK

	resize_if_needed(ba, leg_index) or_return

	ba.length = max(1 + idx, ba.length)

	if set_to {
		ba.bits[leg_index] |=  1 << uint(bit_index)
	} else {
		ba.bits[leg_index] &~= 1 << uint(bit_index)
	}

	return true
}
/*
Sets the state of a bit in the bit-array

*Bypasses all checks*

Inputs:
- ba: Pointer to the Bit_Array
- index: Which bit in the array
*/
unsafe_set :: proc(ba: ^Bit_Array, bit: int) #no_bounds_check {
	ba.bits[bit >> INDEX_SHIFT] |= 1 << uint(bit & INDEX_MASK)
}
/*
Unsets the state of a bit in the bit-array. (Convienence wrapper for `set`)

*Conditionally Allocates (Resizes backing data when `index > len(ba.bits)`)*

Inputs:
- ba: Pointer to the Bit_Array
- index: Which bit in the array
- allocator: (default is context.allocator)

Returns:
- ok: Whether the unset was successful, `false` on allocation failure or bad index
*/
unset :: #force_inline proc(ba: ^Bit_Array, #any_int index: uint, allocator := context.allocator) -> (ok: bool) {
	return set(ba, index, false, allocator)
}
/*
Unsets the state of a bit in the bit-array

*Bypasses all Checks*

Inputs:
- ba: Pointer to the Bit_Array
- index: Which bit in the array
*/
unsafe_unset :: proc(b: ^Bit_Array, bit: int) #no_bounds_check {
	b.bits[bit >> INDEX_SHIFT] &~= 1 << uint(bit & INDEX_MASK)
}
/*
A helper function to create a Bit Array with optional bias, in case your smallest index is non-zero (including negative).

The range of bits created by this procedure is `min_index..<max_index`, and the
array will be able to expand beyond `max_index` if needed.

*Allocates (`new(Bit_Array) & make(ba.bits)`)*

Inputs:
- max_index: maximum starting index
- min_index: minimum starting index (used as a bias)
- allocator: (default is context.allocator)

Returns:
- ba: Allocates a bit_Array, backing data is set to `max-min / 64` indices, rounded up (eg 65 - 0 allocates for [2]u64).
*/
create :: proc(max_index: int, min_index: int = 0, allocator := context.allocator) -> (res: ^Bit_Array, ok: bool) #optional_ok {
	context.allocator = allocator
	size_in_bits := max_index - min_index

	if size_in_bits < 0 { return {}, false }

	legs := size_in_bits >> INDEX_SHIFT
	if size_in_bits & INDEX_MASK > 0 {legs+=1}
	bits, err := make([dynamic]u64, legs)
	ok = err == mem.Allocator_Error.None
	res = new(Bit_Array)
	res.bits         = bits
	res.bias         = min_index
	res.length       = max_index - min_index
	res.free_pointer = true
	return
}
/*
Sets all values in the Bit_Array to zero.

Inputs:
- ba: The target Bit_Array
*/
clear :: proc(ba: ^Bit_Array) {
	if ba == nil { return }
	mem.zero_slice(ba.bits[:])
}
/*
Gets the length of set and unset valid bits in the Bit_Array.

Inputs:
- ba: The target Bit_Array

Returns:
- length: The length of valid bits.
*/
len :: proc(ba: ^Bit_Array) -> (length: int) {
	if ba == nil { return }
	return ba.length
}
/*
Shrinks the Bit_Array's backing storage to the smallest possible size.

Inputs:
- ba: The target Bit_Array
*/
shrink :: proc(ba: ^Bit_Array) #no_bounds_check {
	if ba == nil { return }
	legs_needed := builtin.len(ba.bits)
	for i := legs_needed - 1; i >= 0; i -= 1 {
		if ba.bits[i] == 0 {
			legs_needed -= 1
		} else {
			break
		}
	}
	if legs_needed == builtin.len(ba.bits) {
		return
	}
	ba.length = 0
	if legs_needed > 0 {
		if legs_needed > 1 {
			ba.length = (legs_needed - 1) * NUM_BITS
		}
		ba.length += NUM_BITS - int(intrinsics.count_leading_zeros(ba.bits[legs_needed - 1]))
	}
	resize(&ba.bits, legs_needed)
	builtin.shrink(&ba.bits)
}
/*
Deallocates the Bit_Array and its backing storage

Inputs:
- ba: The target Bit_Array
*/
destroy :: proc(ba: ^Bit_Array) {
	if ba == nil { return }
	delete(ba.bits)
	if ba.free_pointer { // Only free if this Bit_Array was created using `create`, not when on the stack.
		free(ba)
	}
}
/*
	Resizes the Bit Array. For internal use. Provisions needed capacity+1
	If you want to reserve the memory for a given-sized Bit Array up front, you can use `create`.
*/
@(private="file")
resize_if_needed :: proc(ba: ^Bit_Array, legs: int, allocator := context.allocator) -> (ok: bool) {
	if ba == nil { return false }

	context.allocator = allocator

	if legs + 1 > builtin.len(ba.bits) {
		resize(&ba.bits, legs + 1)
	}
	return builtin.len(ba.bits) > legs
}
