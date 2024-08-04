/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: `index_byte` procedures.
*/

// package simd_util implements compositions of SIMD operations for optimizing
// the core library where available.

//+build i386, amd64
package simd_util

import "base:intrinsics"
import "core:simd/x86"

@private SCAN_REGISTER_SIZE :: 16
@private SCAN_REGISTERS     :: 4
@private SCAN_WIDTH         :: SCAN_REGISTERS * SCAN_REGISTER_SIZE

// How long should a string be before using any of the `index_*` procedures in
// this package.
RECOMMENDED_SCAN_SIZE :: SCAN_REGISTER_SIZE

/*
Scan a slice of bytes for a specific byte.

This procedure safely handles padding out slices of any length, including empty
slices.

Inputs:
- data: A slice of bytes.
- c: The byte to search for.

Returns:
- index: The index of the byte `c`, or -1 if it was not found.
*/
@(enable_target_feature="sse2")
index_byte :: proc(data: []u8, c: byte) -> (index: int) #no_bounds_check {
	scanner_data: [SCAN_REGISTER_SIZE]u8 = c
	scanner := intrinsics.unaligned_load(cast(^x86.__m128i)&scanner_data[0])

	i: int
	length := len(data)
	full_chunks_length := length - length % SCAN_WIDTH

	for /**/; i < full_chunks_length; i += SCAN_WIDTH {
		simd_load := intrinsics.unaligned_load(cast(^[SCAN_REGISTERS]x86.__m128i)&data[i])

		#unroll for j in 0..<SCAN_REGISTERS {
			cmp := x86._mm_cmpeq_epi8(simd_load[j], scanner)
			mask := x86._mm_movemask_epi8(cmp)

			// NOTE(Feoramund): I experimented with ORing all the masks onto a
			// 128-bit integer before performing the `mask != 0` check to see
			// if that might be faster. However, the cost to avoid 3
			// compares resulted in a marginally slower runtime on my machine.
			//
			// Simpler won out here.
			if mask != 0 {
				ctz := intrinsics.count_trailing_zeros(mask)
				return i + j * SCAN_REGISTER_SIZE + cast(int)ctz
			}
		}
	}

	if i < length {
		// The data is not exactly divisible by SCAN_WIDTH, and we haven't found
		// what we're looking for yet, so we must pad out the end, then run our
		// algorithm on it.
		padded_data_end: [SCAN_WIDTH]u8 = ---
		remnant_length := length % SCAN_WIDTH
		intrinsics.mem_copy_non_overlapping(
			&padded_data_end[0],
			&raw_data(data)[full_chunks_length],
			remnant_length,
		)

		simd_load := intrinsics.unaligned_load(cast(^[SCAN_REGISTERS]x86.__m128i)&padded_data_end[0])

		#unroll for j in 0..<SCAN_REGISTERS {
			cmp := x86._mm_cmpeq_epi8(simd_load[j], scanner)
			mask := x86._mm_movemask_epi8(cmp)

			// Because this data is padded out, it's possible that we could
			// match on uninitialized memory, so we must guard against that.

			// Create a relevancy mask: (Example)
			//
			//    max(u64)        = 0xFFFF_FFFF_FFFF_FFFF
			//
			//  Convert an integer into a stream of on-bits by using the
			//  shifted negation of the maximum. The subtraction selects which
			//  section of the overall mask we should apply.
			//
			//                   << 17 - (1 * SCAN_REGISTER_SIZE)
			//                    = 0xFFFF_FFFF_FFFF_FFFE
			//
			submask := max(u64) << u64(remnant_length - (j * SCAN_REGISTER_SIZE))
			//
			//    ~submask        = 0x0000_0000_0000_0001
			//    (submask >> 63) = 0x0000_0000_0000_0001
			//
			//  The multiplication is a guard against zero.
			//
			submask = ~submask * (submask >> 63)
			//
			//  Finally, mask out any irrelevant bits with the submask.
			mask &= i32(submask)

			if mask != 0 {
				ctz := int(intrinsics.count_trailing_zeros(mask))
				return i + j * SCAN_REGISTER_SIZE + ctz
			}
		}
	}

	return -1
}

/*
Scan a slice of bytes for a specific byte, starting from the end and working
backwards to the start.

This procedure safely handles padding out slices of any length, including empty
slices.

Inputs:
- data: A slice of bytes.
- c: The byte to search for.

Returns:
- index: The index of the byte `c`, or -1 if it was not found.
*/
@(enable_target_feature="sse2")
last_index_byte :: proc(data: []u8, c: byte) -> int #no_bounds_check {
	scanner_data: [SCAN_REGISTER_SIZE]u8 = c
	scanner := intrinsics.unaligned_load(cast(^x86.__m128i)&scanner_data[0])

	i := len(data) - SCAN_WIDTH

	for /**/; i >= 0; i -= SCAN_WIDTH {
		simd_load := intrinsics.unaligned_load(cast(^[SCAN_REGISTERS]x86.__m128i)&data[i])

		// There is no #reverse #unroll at the time of this writing, so we use
		// `j` to count down by subtraction.
		#unroll for j in 1..=SCAN_REGISTERS {
			cmp := x86._mm_cmpeq_epi8(simd_load[SCAN_REGISTERS-j], scanner)
			mask := x86._mm_movemask_epi8(cmp)

			if mask != 0 {
				// CLZ is used instead to get the on-bit from the other end.
				clz := (8 * size_of(mask) - 1) - int(intrinsics.count_leading_zeros(mask))
				return i + SCAN_WIDTH - j * SCAN_REGISTER_SIZE + clz
			}
		}
	}

	if i < 0 {
		padded_data_end: [SCAN_WIDTH]u8 = ---
		remnant_length := len(data) % SCAN_WIDTH
		intrinsics.mem_copy_non_overlapping(
			&padded_data_end[0],
			&raw_data(data)[0],
			remnant_length,
		)

		simd_load := intrinsics.unaligned_load(cast(^[SCAN_REGISTERS]x86.__m128i)&padded_data_end[0])

		#unroll for j in 1..=SCAN_REGISTERS {
			cmp := x86._mm_cmpeq_epi8(simd_load[SCAN_REGISTERS-j], scanner)
			mask := x86._mm_movemask_epi8(cmp)

			submask := max(u64) << u64(remnant_length - (SCAN_REGISTERS-j) * SCAN_REGISTER_SIZE)
			submask = ~submask * (submask >> 63)

			mask &= i32(submask)

			if mask != 0 {
				clz := (8 * size_of(mask) - 1) - int(intrinsics.count_leading_zeros(mask))
				return SCAN_WIDTH - j * SCAN_REGISTER_SIZE + clz
			}
		}
	}

	return -1
}
