/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: `index_byte` procedures.
*/

// package simd_util implements compositions of SIMD operations for optimizing
// the core library where available.
package simd_util

import "base:intrinsics"

@private SCAN_WIDTH :: 32

@(private, rodata)
simd_scanner_indices := #simd[SCAN_WIDTH]u8 {
	 0,  1,  2,  3,  4,  5,  6,  7,
	 8,  9, 10, 11, 12, 13, 14, 15,
	16, 17, 18, 19, 20, 21, 22, 23,
	24, 25, 26, 27, 28, 29, 30, 31,
}

/*
Scan a slice of bytes for a specific byte.

This procedure safely handles slices of any length, including empty slices.

Inputs:
- data: A slice of bytes.
- c: The byte to search for.

Returns:
- index: The index of the byte `c`, or -1 if it was not found.
*/
index_byte :: proc(data: []u8, c: byte) -> (index: int) #no_bounds_check {
	length := len(data)
	i := 0

	// Guard against small strings.
	if length < SCAN_WIDTH {
		for /**/; i < length; i += 1 {
			if data[i] == c {
				return i
			}
		}
		return -1
	}

	ptr := cast(int)cast(uintptr)raw_data(data)

	alignment_start := (SCAN_WIDTH - ptr % SCAN_WIDTH) % SCAN_WIDTH

	// Iterate as a scalar until the data is aligned on a `SCAN_WIDTH` boundary.
	//
	// This way, every load in the vector loop will be aligned, which should be
	// the fastest possible scenario.
	for /**/; i < alignment_start; i += 1 {
		if data[i] == c {
			return i
		}
	}

	// Iterate as a vector over every aligned chunk, evaluating each byte simultaneously at the CPU level.
	scanner: #simd[SCAN_WIDTH]u8 = c
	tail := length - (length - alignment_start) % SCAN_WIDTH

	for /**/; i < tail; i += SCAN_WIDTH {
		load := (cast(^#simd[SCAN_WIDTH]u8)(&data[i]))^
		comparison := intrinsics.simd_lanes_eq(load, scanner)
		match := intrinsics.simd_reduce_or(comparison)
		if match > 0 {
			sentinel: #simd[SCAN_WIDTH]u8 = u8(0xFF)
			index_select := intrinsics.simd_select(comparison, simd_scanner_indices, sentinel)
			index_reduce := intrinsics.simd_reduce_min(index_select)
			return i + cast(int)index_reduce
		}
	}
	
	// Iterate as a scalar over the remaining unaligned portion.
	for /**/; i < length; i += 1 {
		if data[i] == c {
			return i
		}
	}

	return -1
}

/*
Scan a slice of bytes for a specific byte, starting from the end and working
backwards to the start.

This procedure safely handles slices of any length, including empty slices.

Inputs:
- data: A slice of bytes.
- c: The byte to search for.

Returns:
- index: The index of the byte `c`, or -1 if it was not found.
*/
last_index_byte :: proc(data: []u8, c: byte) -> int #no_bounds_check {
	length := len(data)
	i := length - 1

	// Guard against small strings.
	if length < SCAN_WIDTH {
		for /**/; i >= 0; i -= 1 {
			if data[i] == c {
				return i
			}
		}
		return -1
	}

	ptr := cast(int)cast(uintptr)raw_data(data)

	tail := length - (ptr + length) % SCAN_WIDTH

	// Iterate as a scalar until the data is aligned on a `SCAN_WIDTH` boundary.
	//
	// This way, every load in the vector loop will be aligned, which should be
	// the fastest possible scenario.
	for /**/; i >= tail; i -= 1 {
		if data[i] == c {
			return i
		}
	}

	// Iterate as a vector over every aligned chunk, evaluating each byte simultaneously at the CPU level.
	scanner: #simd[SCAN_WIDTH]u8 = c
	alignment_start := (SCAN_WIDTH - ptr % SCAN_WIDTH) % SCAN_WIDTH

	i -= SCAN_WIDTH - 1

	for /**/; i >= alignment_start; i -= SCAN_WIDTH {
		load := (cast(^#simd[SCAN_WIDTH]u8)(&data[i]))^
		comparison := intrinsics.simd_lanes_eq(load, scanner)
		match := intrinsics.simd_reduce_or(comparison)
		if match > 0 {
			sentinel: #simd[SCAN_WIDTH]u8
			index_select := intrinsics.simd_select(comparison, simd_scanner_indices, sentinel)
			index_reduce := intrinsics.simd_reduce_max(index_select)
			return i + cast(int)index_reduce
		}
	}

	// Iterate as a scalar over the remaining unaligned portion.
	i += SCAN_WIDTH - 1
	
	for /**/; i >= 0; i -= 1 {
		if data[i] == c {
			return i
		}
	}

	return -1
}
