package runtime

import "base:intrinsics"

@(private)
chacha8rand_refill_ref :: proc(r: ^Default_Random_State) {
	// Initialize the base state.
	k: [^]u32 = (^u32)(raw_data(r._buf[RNG_OUTPUT_PER_ITER:]))
	when ODIN_ENDIAN == .Little {
		s4 := k[0]
		s5 := k[1]
		s6 := k[2]
		s7 := k[3]
		s8 := k[4]
		s9 := k[5]
		s10 := k[6]
		s11 := k[7]
	} else {
		s4 := intrinsics.byte_swap(k[0])
		s5 := intrinsics.byte_swap(k[1])
		s6 := intrinsics.byte_swap(k[2])
		s7 := intrinsics.byte_swap(k[3])
		s8 := intrinsics.byte_swap(k[4])
		s9 := intrinsics.byte_swap(k[5])
		s10 := intrinsics.byte_swap(k[6])
		s11 := intrinicss.byte_swap(k[7])
	}
	s12: u32           // Counter starts at 0.
	s13, s14, s15: u32 // IV of all 0s.

	dst: [^]u32 = (^u32)(raw_data(r._buf[:]))

	// At least with LLVM21 force_inline produces identical perf to
	// manual inlining, yay.
	quarter_round := #force_inline proc "contextless" (a, b, c, d: u32) -> (u32, u32, u32, u32) {
		a, b, c, d := a, b, c, d

		a += b
		d ~= a
		d = rotl(d, 16)

		c += d
		b ~= c
		b = rotl(b, 12)

		a += b
		d ~= a
		d = rotl(d, 8)

		c += d
		b ~= c
		b = rotl(b, 7)

		return a, b, c, d
	}

	// Filippo Valsorda made an observation that only one of the column
	// round depends on the counter (s12), so it is worth precomputing
	// and reusing across multiple blocks.  As far as I know, only Go's
	// chacha implementation does this.

	p1, p5, p9, p13 := quarter_round(CHACHA_SIGMA_1, s5, s9, s13)
	p2, p6, p10, p14 := quarter_round(CHACHA_SIGMA_2, s6, s10, s14)
	p3, p7, p11, p15 := quarter_round(CHACHA_SIGMA_3, s7, s11, s15)

	// 4 groups
	for g := 0; g < 4; g = g + 1 {
		// 4 blocks per group
		for n := 0; n < 4; n = n + 1 {
			// First column round that depends on the counter
			p0, p4, p8, p12 := quarter_round(CHACHA_SIGMA_0, s4, s8, s12)

			// First diagonal round
			x0, x5, x10, x15 := quarter_round(p0, p5, p10, p15)
			x1, x6, x11, x12 := quarter_round(p1, p6, p11, p12)
			x2, x7, x8, x13 := quarter_round(p2, p7, p8, p13)
			x3, x4, x9, x14 := quarter_round(p3, p4, p9, p14)

			for i := CHACHA_ROUNDS - 2; i > 0; i = i - 2 {
				x0, x4, x8, x12 = quarter_round(x0, x4, x8, x12)
				x1, x5, x9, x13 = quarter_round(x1, x5, x9, x13)
				x2, x6, x10, x14 = quarter_round(x2, x6, x10, x14)
				x3, x7, x11, x15 = quarter_round(x3, x7, x11, x15)

				x0, x5, x10, x15 = quarter_round(x0, x5, x10, x15)
				x1, x6, x11, x12 = quarter_round(x1, x6, x11, x12)
				x2, x7, x8, x13 = quarter_round(x2, x7, x8, x13)
				x3, x4, x9, x14 = quarter_round(x3, x4, x9, x14)
			}

			// Interleave 4 blocks
			// NB: The additions of sigma and the counter are omitted
			STRIDE :: 4
			d_ := dst[n:]
			when ODIN_ENDIAN == .Little {
				d_[STRIDE*0] = x0
				d_[STRIDE*1] = x1
				d_[STRIDE*2] = x2
				d_[STRIDE*3] = x3
				d_[STRIDE*4] = x4 + s4
				d_[STRIDE*5] = x5 + s5
				d_[STRIDE*6] = x6 + s6
				d_[STRIDE*7] = x7 + s7
				d_[STRIDE*8] = x8 + s8
				d_[STRIDE*9] = x9 + s9
				d_[STRIDE*10] = x10 + s10
				d_[STRIDE*11] = x11 + s11
				d_[STRIDE*12] = x12
				d_[STRIDE*13] = x13 + s13
				d_[STRIDE*14] = x14 + s14
				d_[STRIDE*15] = x15 + s15
			} else {
				d_[STRIDE*0] = intrinsics.byte_swap(x0)
				d_[STRIDE*1] = intrinsics.byte_swap(x1)
				d_[STRIDE*2] = intrinsics.byte_swap(x2)
				d_[STRIDE*3] = intrinsics.byte_swap(x3)
				d_[STRIDE*4] = intrinsics.byte_swap(x4 + s4)
				d_[STRIDE*5] = intrinsics.byte_swap(x5 + s5)
				d_[STRIDE*6] = intrinsics.byte_swap(x6 + s6)
				d_[STRIDE*7] = intrinsics.byte_swap(x7 + s7)
				d_[STRIDE*8] = intrinsics.byte_swap(x8 + s8)
				d_[STRIDE*9] = intrinsics.byte_swap(x9 + s9)
				d_[STRIDE*10] = intrinsics.byte_swap(x10 + s10)
				d_[STRIDE*11] = intrinsics.byte_swap(x11 + s11)
				d_[STRIDE*12] = intrinsics.byte_swap(x12)
				d_[STRIDE*13] = intrinsics.byte_swap(x13 + s13)
				d_[STRIDE*14] = intrinsics.byte_swap(x14 + s14)
				d_[STRIDE*15] = intrinsics.byte_swap(x15 + s15)
			}

			s12 = s12 + 1 // Increment the counter
		}

		dst = dst[16*4:]
	}
}

// This replicates `rotate_left32` from `core:math/bits`, under the
// assumption that this will live in `base:runtime`.
@(require_results, private = "file")
rotl :: #force_inline proc "contextless" (x: u32, k: int) -> u32 {
	n :: 32
	s := uint(k) & (n-1)
	return x << s | x >> (n-s)
}
