package test_core_container

import "core:container/bit_array"
import "core:log"
import "core:math/rand"
import "core:slice"
import "core:testing"

ELEM_BIT_SIZE :: 8 * size_of(u64)

@test
test_bit_array_bias :: proc(t: ^testing.T) {
	for bias in -ELEM_BIT_SIZE..=ELEM_BIT_SIZE {
		M :: 19
		list := []int{0,1,3,5,7,11,13,17,M}

		ba := bit_array.create(M + bias, bias)
		defer bit_array.destroy(ba)

		for v, i in list {
			list[i] = v + bias
		}

		for i in list {
			bit_array.set(ba, i)
			testing.expectf(t, bit_array.get(ba, i),
				"Expected bit_array<length: %i, bias: %i>[%i] to be true",
				ba.length, ba.bias, i)
		}

		seen: [dynamic]int
		defer delete(seen)

		iter := bit_array.make_iterator(ba)
		for i in bit_array.iterate_by_set(&iter) {
			append(&seen, i)
		}

		testing.expectf(t, slice.equal(list, seen[:]),
			"Expected bit_array<length: %i, bias: %i> to be: %v, got %v",
			ba.length, ba.bias, list, seen)
	}
}

@test
test_bit_array_empty_iteration :: proc(t: ^testing.T) {
	ba: ^bit_array.Bit_Array = &{}
	defer bit_array.destroy(ba)

	for x in 0..=1 {
		if x == 1 {
			// Run the same tests with a created bit_array.
			ba = bit_array.create(0,0)
		}

		iter := bit_array.make_iterator(ba)
		for v, i in bit_array.iterate_by_all(&iter) {
			log.errorf("Empty bit array had iterable: %v, %i", v, i)
		}

		iter = bit_array.make_iterator(ba)
		for i in bit_array.iterate_by_unset(&iter) {
			log.errorf("Empty bit array had iterable: %v", i)
		}
	}
}

@test
test_bit_array_biased_max_index :: proc(t: ^testing.T) {
	for bias in -ELEM_BIT_SIZE..=ELEM_BIT_SIZE {
		for max_index in 1+bias..<ELEM_BIT_SIZE {
			length := max_index - bias
			ba := bit_array.create(max_index, bias)
			defer bit_array.destroy(ba)

			bit_array.set(ba, max_index - 1)

			expected := max_index - bias
			testing.expectf(t, ba.length == expected,
				"Expected bit_array<max_index: %i, bias: %i> length to be: %i, got %i",
				max_index, bias, expected, ba.length)

			list := make([]int, length)
			defer delete(list)
			for i in 0..<len(list) {
				list[i] = i + bias
			}

			seen: [dynamic]int
			defer delete(seen)

			iter := bit_array.make_iterator(ba)
			for _, i in bit_array.iterate_by_all(&iter) {
				append(&seen, i)
			}
			testing.expectf(t, slice.equal(list[:], seen[:]),
				"Expected bit_array<max_index: %i, bias: %i> to contain: %v, got %v",
				max_index, bias, list, seen)
		}
	}
}

@test
test_bit_array_shrink :: proc(t: ^testing.T) {
	for bias in -ELEM_BIT_SIZE..=ELEM_BIT_SIZE {
		ba := bit_array.create(bias, bias)
		defer bit_array.destroy(ba)

		N :: 3*ELEM_BIT_SIZE

		for i in 0..=N {
			biased_i := bias + i
			bit_array.set(ba, biased_i)

			testing.expectf(t, bit_array.get(ba, biased_i),
				"Expected bit_array<bias: %i>[%i] to be true",
				ba.bias, biased_i)
			testing.expectf(t, ba.length == 1 + i,
				"Expected bit_array<bias: %i> length to be %i, got %i",
				ba.bias, 1 + i, ba.length)

			legs := 1 + i / ELEM_BIT_SIZE

			testing.expectf(t, len(ba.bits) == legs,
				"Expected bit_array<bias: %i> to have %i legs with index %i set, had %i legs",
				ba.bias, legs, biased_i, len(ba.bits))

			bit_array.unset(ba, biased_i)

			if i >= ELEM_BIT_SIZE {
				// Test shrinking arrays with bits set across two legs.
				bit_array.set(ba, bias)
				bit_array.shrink(ba)

				testing.expectf(t, ba.length == 1,
					"Expected bit_array<bias: %i> length to be 1 after >1 leg shrink, got %i",
					ba.bias, ba.length)
				testing.expectf(t, len(ba.bits) == 1,
					"Expected bit_array<bias: %i> to have one leg after >1 leg shrink, had %i",
					ba.bias, len(ba.bits))

				bit_array.unset(ba, bias)
			}

			bit_array.shrink(ba)

			testing.expectf(t, ba.length == 0,
				"Expected bit_array<bias: %i> length to be zero after final shrink, got %i",
				ba.bias, ba.length)
			testing.expectf(t, len(ba.bits) == 0,
				"Expected bit_array<bias: %i> to have zero legs with index %i set after final shrink, had %i",
				ba.bias, biased_i, len(ba.bits))
		}
	}
}

@test
test_bit_array :: proc(t: ^testing.T) {
	ba := bit_array.create(0, 0)
	defer bit_array.destroy(ba)

	list_set: [dynamic]int
	seen_set: [dynamic]int
	list_unset: [dynamic]int
	seen_unset: [dynamic]int
	defer {
		delete(list_set)
		delete(seen_set)
		delete(list_unset)
		delete(seen_unset)
	}

	// Setup bits.
	MAX_INDEX :: 1+16*ELEM_BIT_SIZE
	for i in 0..=MAX_INDEX {
		append(&list_unset, i)
	}
	for i in 1..=16 {
		for j in -1..=1 {
			n := ELEM_BIT_SIZE * i + j
			bit_array.set(ba, n)
			append(&list_set, n)
		}
	}
	#reverse for i in list_set {
		ordered_remove(&list_unset, i)
	}

	// Test iteration.
	iter := bit_array.make_iterator(ba)
	for i in bit_array.iterate_by_set(&iter) {
		append(&seen_set, i)
	}
	testing.expectf(t, slice.equal(list_set[:], seen_set[:]),
		"Expected set bit_array to be: %v, got %v",
		list_set, seen_set)

	iter = bit_array.make_iterator(ba)
	for i in bit_array.iterate_by_unset(&iter) {
		append(&seen_unset, i)
	}
	testing.expectf(t, slice.equal(list_unset[:], seen_unset[:]),
		"Expected unset bit_array to be: %v, got %v",
		list_unset, seen_unset)

	// Test getting.
	for i in list_set {
		testing.expectf(t, bit_array.get(ba, i),
			"Expected index %i to be true, got false",
			i)
	}
	for i in list_unset {
		testing.expectf(t, bit_array.get(ba, i) == false,
			"Expected index %i to be false, got true",
			i)
	}

	// Test flipping bits.
	rand.shuffle(list_set[:])
	rand.shuffle(list_unset[:])

	for i in list_set {
		bit_array.unset(ba, i)
		testing.expectf(t, bit_array.get(ba, i) == false,
			"Expected index %i to be false after unsetting, got true",
			i)
	}

	for i in list_unset {
		bit_array.set(ba, i)
		testing.expectf(t, bit_array.get(ba, i),
			"Expected index %i to be true after setting, got false",
			i)
	}

	// Test clearing.
	bit_array.clear(ba)
	iter = bit_array.make_iterator(ba)
	for i in 0..=MAX_INDEX {
		testing.expectf(t, bit_array.get(ba, i) == false,
			"Expected index %i to be false after clearing, got true",
			i)
	}
}
