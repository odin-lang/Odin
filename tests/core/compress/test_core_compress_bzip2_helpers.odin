package test_core_compress

BZ_HELLO_PACKED :: "\x42\x5a\x68\x39\x31\x41\x59\x26\x53\x59\xbd\x5c\x87\x6d\x00\x00\x95\x99\x80\x40\x00\x10\x00\x12\x64\xc0\x10\x20\x00\x40\x52\xa8\xd1\x93\xd4\x20\x06\x1c\x45\xda\x2f\x91\x69\x16\xd1\x74\x8b\x11\x71\x16\x11\x62\x2c\x45\xf8\xbb\x92\x29\xc2\x84\x85\xea\xe4\x3b\x68"

bz_lcg :: proc(n, alpha: int) -> []u8 {
	data := make([]u8, n)
	x := u32(1)
	for &b in data {
		x = x * 1103515245 + 12345
		b = u8(97 + int(x >> 16) % alpha)
	}
	return data
}

BZ_Block :: struct {
	magic:        u64,
	crc:          u32,
	bad_combined: bool,
	orig_ptr:     int,
	in_use:       []u8,
	n_groups:     int,
	n_selectors:  int,
	selector_mtf: []u8,
	lengths:      []u8,
	symbols:      []u16,
}

BZ_Writer :: struct {
	buf:  [dynamic]u8,
	bits: u64,
	live: uint,
}

bz_put :: proc(w: ^BZ_Writer, n: uint, v: u64) {
	for i := int(n) - 1; i >= 0; i -= 1 {
		w.bits = w.bits << 1 | (v >> uint(i)) & 1
		w.live += 1
		if w.live == 8 {
			append(&w.buf, u8(w.bits))
			w.bits, w.live = 0, 0
		}
	}
}

bz_stream :: proc(level: u8, blocks: []BZ_Block) -> [dynamic]u8 {
	w: BZ_Writer
	append(&w.buf, 'B', 'Z', 'h', level)
	combined := u32(0)
	bad := false
	for b in blocks {
		bz_put(&w, 48, b.magic if b.magic != 0 else 0x314159265359)
		crc := b.crc if b.crc != 0 else bz_crc([]u8{b.in_use[0]} if len(b.in_use) > 0 else nil)
		combined = (combined << 1 | combined >> 31) ~ crc
		bad |= b.bad_combined
		bz_put(&w, 32, u64(crc))
		bz_put(&w, 1, 0)
		bz_put(&w, 24, u64(b.orig_ptr))

		used: [16]u16
		for c in b.in_use {
			used[c >> 4] |= 0x8000 >> (c & 15)
		}
		groups := u64(0)
		for u, i in used {
			if u != 0 {
				groups |= 0x8000 >> uint(i)
			}
		}
		bz_put(&w, 16, groups)
		for u in used {
			if u != 0 {
				bz_put(&w, 16, u64(u))
			}
		}

		bz_put(&w, 3, u64(b.n_groups))
		n_selectors := b.n_selectors
		switch {
		case n_selectors < 0:  n_selectors = 0
		case n_selectors == 0: n_selectors = max(1, (len(b.symbols) + 49) / 50)
		}
		bz_put(&w, 15, u64(n_selectors))
		for i in 0..<n_selectors {
			j := b.selector_mtf[i] if i < len(b.selector_mtf) else 0
			for _ in 0..<j {
				bz_put(&w, 1, 1)
			}
			bz_put(&w, 1, 0)
		}

		for _ in 0..<b.n_groups {
			curr := int(b.lengths[0])
			bz_put(&w, 5, u64(curr))
			for l in b.lengths {
				for curr < int(l) {
					bz_put(&w, 2, 2)
					curr += 1
				}
				for curr > int(l) {
					bz_put(&w, 2, 3)
					curr -= 1
				}
				bz_put(&w, 1, 0)
			}
		}

		codes: [258]u64
		next := u64(0)
		for l in 1..=20 {
			for length, s in b.lengths {
				if int(length) == l {
					codes[s] = next
					next += 1
				}
			}
			next <<= 1
		}
		for s in b.symbols {
			if int(s) >= len(b.lengths) {
				bz_put(&w, 20, 0xf_ffff)
			} else {
				bz_put(&w, uint(b.lengths[s]), codes[s])
			}
		}
	}
	bz_put(&w, 48, 0x177245385090)
	bz_put(&w, 32, u64(combined ~ (1 if bad else 0)))
	if w.live > 0 {
		bz_put(&w, 8 - w.live, 0)
	}
	return w.buf
}

bz_bomb :: proc(k: int) -> [dynamic]u8 {
	symbols: [dynamic]u16
	defer delete(symbols)
	run :: proc(symbols: ^[dynamic]u16, n: int) {
		z := n - 1
		for {
			append(symbols, u16(z & 1))
			if z < 2 {
				break
			}
			z = (z - 2) / 2
		}
	}
	append(&symbols, 2)
	run(&symbols, k - 1)
	append(&symbols, 2)
	run(&symbols, 4 * k - 1)
	append(&symbols, 3)

	table := bz_crc_table()
	crc := ~u32(0)
	for _ in 0..<k * 259 {
		crc = crc << 8 ~ table[crc >> 24]
	}

	return bz_stream('9', []BZ_Block{{
		crc      = ~crc,
		in_use   = {0x00, 0xff},
		n_groups = 2,
		lengths  = {1, 2, 3, 3},
		symbols  = symbols[:],
	}})
}

bz_crc_table :: proc() -> (table: [256]u32) {
	for i in 0..<256 {
		c := u32(i) << 24
		for _ in 0..<8 {
			c = c << 1 ~ (0x04c11db7 if c & 0x8000_0000 != 0 else 0)
		}
		table[i] = c
	}
	return
}

bz_crc :: proc(data: []u8) -> u32 {
	table := bz_crc_table()
	crc := ~u32(0)
	for b in data {
		crc = crc << 8 ~ table[crc >> 24 ~ u32(b)]
	}
	return ~crc
}

bz_set_bits :: proc(data: []u8, pos: int, n: int, v: u32) {
	for i in 0..<n {
		bit := pos + i
		mask := u8(0x80) >> uint(bit & 7)
		if (v >> uint(n - 1 - i)) & 1 != 0 {
			data[bit >> 3] |= mask
		} else {
			data[bit >> 3] &~= mask
		}
	}
}

bz_get_bits :: proc(data: []u8, pos: int, n: int) -> u64 {
	v := u64(0)
	for i in 0..<n {
		bit := pos + i
		v = v << 1 | u64(data[bit >> 3] >> (7 - uint(bit & 7))) & 1
	}
	return v
}

bz_find_end :: proc(data: []u8) -> int {
	for pad in 0..<8 {
		pos := len(data) * 8 - pad - 80
		if pos > 0 && bz_get_bits(data, pos, 48) == 0x177245385090 {
			return pos
		}
	}
	return -1
}

@(rodata)
BZ_RAND_TABLE := [512]u16{
	619, 720, 127, 481, 931, 816, 813, 233, 566, 247, 985, 724, 205, 454, 863, 491,
	741, 242, 949, 214, 733, 859, 335, 708, 621, 574, 73, 654, 730, 472, 419, 436,
	278, 496, 867, 210, 399, 680, 480, 51, 878, 465, 811, 169, 869, 675, 611, 697,
	867, 561, 862, 687, 507, 283, 482, 129, 807, 591, 733, 623, 150, 238, 59, 379,
	684, 877, 625, 169, 643, 105, 170, 607, 520, 932, 727, 476, 693, 425, 174, 647,
	73, 122, 335, 530, 442, 853, 695, 249, 445, 515, 909, 545, 703, 919, 874, 474,
	882, 500, 594, 612, 641, 801, 220, 162, 819, 984, 589, 513, 495, 799, 161, 604,
	958, 533, 221, 400, 386, 867, 600, 782, 382, 596, 414, 171, 516, 375, 682, 485,
	911, 276, 98, 553, 163, 354, 666, 933, 424, 341, 533, 870, 227, 730, 475, 186,
	263, 647, 537, 686, 600, 224, 469, 68, 770, 919, 190, 373, 294, 822, 808, 206,
	184, 943, 795, 384, 383, 461, 404, 758, 839, 887, 715, 67, 618, 276, 204, 918,
	873, 777, 604, 560, 951, 160, 578, 722, 79, 804, 96, 409, 713, 940, 652, 934,
	970, 447, 318, 353, 859, 672, 112, 785, 645, 863, 803, 350, 139, 93, 354, 99,
	820, 908, 609, 772, 154, 274, 580, 184, 79, 626, 630, 742, 653, 282, 762, 623,
	680, 81, 927, 626, 789, 125, 411, 521, 938, 300, 821, 78, 343, 175, 128, 250,
	170, 774, 972, 275, 999, 639, 495, 78, 352, 126, 857, 956, 358, 619, 580, 124,
	737, 594, 701, 612, 669, 112, 134, 694, 363, 992, 809, 743, 168, 974, 944, 375,
	748, 52, 600, 747, 642, 182, 862, 81, 344, 805, 988, 739, 511, 655, 814, 334,
	249, 515, 897, 955, 664, 981, 649, 113, 974, 459, 893, 228, 433, 837, 553, 268,
	926, 240, 102, 654, 459, 51, 686, 754, 806, 760, 493, 403, 415, 394, 687, 700,
	946, 670, 656, 610, 738, 392, 760, 799, 887, 653, 978, 321, 576, 617, 626, 502,
	894, 679, 243, 440, 680, 879, 194, 572, 640, 724, 926, 56, 204, 700, 707, 151,
	457, 449, 797, 195, 791, 558, 945, 679, 297, 59, 87, 824, 713, 663, 412, 693,
	342, 606, 134, 108, 571, 364, 631, 212, 174, 643, 304, 329, 343, 97, 430, 751,
	497, 314, 983, 374, 822, 928, 140, 206, 73, 263, 980, 736, 876, 478, 430, 305,
	170, 514, 364, 692, 829, 82, 855, 953, 676, 246, 369, 970, 294, 750, 807, 827,
	150, 790, 288, 923, 804, 378, 215, 828, 592, 281, 565, 555, 710, 82, 896, 831,
	547, 261, 524, 462, 293, 465, 502, 56, 661, 821, 976, 991, 658, 869, 905, 758,
	745, 193, 768, 550, 608, 933, 378, 286, 215, 979, 792, 961, 61, 688, 793, 644,
	986, 403, 106, 366, 905, 644, 372, 567, 466, 434, 645, 210, 389, 550, 919, 135,
	780, 773, 635, 389, 707, 100, 626, 958, 165, 504, 920, 176, 193, 713, 857, 265,
	203, 50, 668, 108, 645, 990, 626, 197, 510, 357, 358, 850, 858, 364, 936, 638,
}
