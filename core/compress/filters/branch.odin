package compress_filters

import "base:intrinsics"

branch_init :: proc "contextless" (state: ^Branch_State, arch: Branch_Arch, start_offset: u32 = 0) -> bool {
	if start_offset % u32(BRANCH_ALIGNMENT[arch]) != 0 {
		return false
	}
	state^ = {arch = arch, pc = start_offset}
	return true
}

branch_encode :: proc "contextless" (state: ^Branch_State, data: []u8) -> (processed: int) {
	return branch_convert(state, data, true)
}

branch_decode :: proc "contextless" (state: ^Branch_State, data: []u8) -> (processed: int) {
	return branch_convert(state, data, false)
}

@(private)
branch_convert :: proc "contextless" (state: ^Branch_State, data: []u8, $ENCODING: bool) -> (processed: int) {
	switch state.arch {
	case .X86:       processed = x86_convert(data, state.pc, &state.x86_mask, ENCODING)
	case .PowerPC:   processed = ppc_convert(data, state.pc, ENCODING)
	case .IA64:      processed = ia64_convert(data, state.pc, ENCODING)
	case .ARM:       processed = arm_convert(data, state.pc, ENCODING)
	case .ARM_Thumb: processed = armt_convert(data, state.pc, ENCODING)
	case .SPARC:     processed = sparc_convert(data, state.pc, ENCODING)
	case .ARM64:     processed = arm64_convert(data, state.pc, ENCODING)
	case .RISCV:
		when ENCODING {
			processed = riscv_encode(data, state.pc)
		} else {
			processed = riscv_decode(data, state.pc)
		}
	}
	state.pc += u32(processed)
	return
}

@(private)
x86_convert :: proc "contextless" (data: []u8, pc: u32, state: ^u32, $ENCODING: bool) -> int #no_bounds_check {
	size := len(data)
	if size < 5 {
		return 0
	}
	ip        := pc + 5
	prev_mask := state^ & 7
	prev_pos  := -1
	pos       := 0
	limit     := size - 4
	for {
		pos = x86_scan(data, pos, limit)
		if pos >= limit {
			break
		}
		distance := pos - prev_pos
		if distance > 3 {
			prev_mask = 0
		} else {
			prev_mask = (prev_mask << uint(distance - 1)) & 7
			if prev_mask != 0 {
				b := data[pos + 4 - int(X86_MASK_TO_BIT_NUMBER[prev_mask])]
				if !X86_MASK_TO_ALLOWED[prev_mask] || b == 0 || b == 0xFF {
					prev_pos  = pos
					prev_mask = ((prev_mask << 1) & 7) | 1
					pos += 1
					continue
				}
			}
		}
		prev_pos = pos

		b4 := data[pos + 4]
		if b4 != 0 && b4 != 0xFF {
			prev_mask = ((prev_mask << 1) & 7) | 1
			pos += 1
			continue
		}
		src  := u32(b4) << 24 | u32(data[pos + 3]) << 16 | u32(data[pos + 2]) << 8 | u32(data[pos + 1])
		dest := u32(0)
		for {
			when ENCODING {
				dest = ip + u32(pos) + src
			} else {
				dest = src - (ip + u32(pos))
			}
			if prev_mask == 0 {
				break
			}
			index := X86_MASK_TO_BIT_NUMBER[prev_mask] * 8
			b     := u8(dest >> (24 - index))
			if b != 0 && b != 0xFF {
				break
			}
			src = dest ~ ((u32(1) << (32 - index)) - 1)
		}
		data[pos + 4] = ~u8(((dest >> 24) & 1) - 1)
		data[pos + 3] = u8(dest >> 16)
		data[pos + 2] = u8(dest >> 8)
		data[pos + 1] = u8(dest)
		pos += 5
	}
	distance := pos - prev_pos
	state^ = 0 if distance > 3 else (prev_mask << uint(distance - 1)) & 7
	return pos
}

@(private)
x86_scan :: #force_inline proc "contextless" (data: []u8, pos, limit: int) -> int #no_bounds_check {
	if pos >= limit {
		return pos
	}
	i := pos
	for i <= len(data) - 8 {
		v := u64(intrinsics.unaligned_load((^u64le)(&data[i])))
		v  = (v & 0xFEFE_FEFE_FEFE_FEFE) ~ 0xE8E8_E8E8_E8E8_E8E8
		z := (v - 0x0101_0101_0101_0101) & ~v & 0x8080_8080_8080_8080
		if z != 0 {
			return min(i + int(intrinsics.count_trailing_zeros(z) >> 3), limit)
		}
		i += 8
	}
	for i < limit && data[i] & 0xFE != 0xE8 {
		i += 1
	}
	return min(i, limit)
}

@(private)
arm_convert :: proc "contextless" (data: []u8, pc: u32, $ENCODING: bool) -> int #no_bounds_check {
	size := len(data) &~ 3
	i := 0
	if size >= 8 {
		last := size - 8
		for i <= last {
			x := u64(intrinsics.unaligned_load((^u64le)(&data[i])))
			x  = ((x >> 24) & 0x0000_00FF_0000_00FF) ~ 0x0000_00EB_0000_00EB
			z := (x - 0x0000_0001_0000_0001) & 0x8000_0000_8000_0000
			if z == 0 {
				i += 8
				continue
			}
			if z & 0x8000_0000 == 0 {
				i += 4
			}
			arm_patch(data, i, pc, ENCODING)
			i += 4
		}
	}
	for i < size {
		if data[i + 3] == 0xEB {
			arm_patch(data, i, pc, ENCODING)
		}
		i += 4
	}
	return size
}

@(private)
arm_patch :: #force_inline proc "contextless" (data: []u8, i: int, pc: u32, $ENCODING: bool) #no_bounds_check {
	v := get_le32(data, i)
	c := (pc + u32(i) + 8) >> 2
	when ENCODING {
		v += c
	} else {
		v -= c
	}
	put_le32(data, i, (v & 0x00FF_FFFF) | 0xEB00_0000)
}

@(private)
armt_convert :: proc "contextless" (data: []u8, pc: u32, $ENCODING: bool) -> int #no_bounds_check {
	size := len(data) &~ 1
	if size <= 2 {
		return 0
	}
	limit := size - 2
	i := 0
	for {
		found := false
		for i <= size - 8 {
			x := u64(intrinsics.unaligned_load((^u64le)(&data[i])))
			w := ~((x ~ 0x0808_0808_0808_0808) & (x >> 16)) & 0xF800_F800_F800_F800
			z := (w - 0x0001_0001_0001_0001) & ~w & 0x8000_8000_8000_8000
			if z != 0 {
				i += int(intrinsics.count_trailing_zeros(z) >> 4) * 2
				found = true
				break
			}
			i += 6
		}
		if !found {
			for i < limit && (u32(data[i + 3]) & (u32(data[i + 1]) ~ 8)) < 0xF8 {
				i += 2
			}
			if i >= limit {
				break
			}
		}
		v := get_le16(data, i) << 11 | (get_le16(data, i + 2) & 0x7FF)
		c := (pc + u32(i) + 4) >> 1
		when ENCODING {
			v += c
		} else {
			v -= c
		}
		put_le16(data, i,     ((v >> 11) & 0x7FF) | 0xF000)
		put_le16(data, i + 2, v | 0xF800)
		i += 4
	}
	return i
}

@(private)
ppc_convert :: proc "contextless" (data: []u8, pc: u32, $ENCODING: bool) -> int #no_bounds_check {
	size := len(data) &~ 3
	i := 0
	if size >= 8 {
		last := size - 8
		for i <= last {
			x := u64(intrinsics.unaligned_load((^u64le)(&data[i])))
			x  = (x & 0x0300_00FC_0300_00FC) ~ 0x0100_0048_0100_0048
			z := (x - 0x0000_0001_0000_0001) & 0x8000_0000_8000_0000
			if z == 0 {
				i += 8
				continue
			}
			if z & 0x8000_0000 == 0 {
				i += 4
			}
			ppc_patch(data, i, pc, ENCODING)
			i += 4
		}
	}
	for i < size {
		if get_le32(data, i) & 0x0300_00FC == 0x0100_0048 {
			ppc_patch(data, i, pc, ENCODING)
		}
		i += 4
	}
	return size
}

@(private)
ppc_patch :: #force_inline proc "contextless" (data: []u8, i: int, pc: u32, $ENCODING: bool) #no_bounds_check {
	v := get_be32(data, i)
	c := pc + u32(i)
	when ENCODING {
		v += c
	} else {
		v -= c
	}
	put_be32(data, i, (v & 0x03FF_FFFF) | 0x4800_0000)
}

@(private)
sparc_convert :: proc "contextless" (data: []u8, pc: u32, $ENCODING: bool) -> int #no_bounds_check {
	FLAG :: u32(1) << 22
	size := len(data) &~ 3
	for i := 0; i < size; i += 4 {
		v := get_be32(data, i)
		v = v << 2 | v >> 30
		v += (FLAG << 2) - 1
		if v & 0xFE00_0003 != 0 {
			continue
		}
		c := pc + u32(i)
		when ENCODING {
			v += c
		} else {
			v -= c
		}
		v &= (FLAG << 3) - 1
		v -= (FLAG << 2) - 1
		v = v >> 2 | v << 30
		put_be32(data, i, v)
	}
	return size
}

@(private)
ia64_convert :: proc "contextless" (data: []u8, pc: u32, $ENCODING: bool) -> int #no_bounds_check {
	size := len(data) &~ 15
	ip   := (pc - 16) >> 3
	for i := 0; i < size; i += 16 {
		ip += 2
		m := (u32(0x334B_0000) >> (data[i] & 0x1E)) & 3
		if m == 0 {
			continue
		}
		p := i + int(m) * 5 - 4
		for {
			t := get_le16(data, p)
			z := get_le32(data, p + 1) >> m
			p += 5
			if (t >> m) & 0xE0 == 0 && (z - (0x500_0000 << 1)) & (0xF00_0000 << 1) == 0 {
				v := u32((0x8F_FFFF << 1) | 1) & z
				z ~= v
				when ENCODING {
					ip &= (0x1F_FFFF << 1) | 1
					v += ip
				} else {
					ip |= ~u32((0x1F_FFFF << 1) | 1)
					v -= ip
				}
				v &= ~u32(0x60_0000 << 1)
				v += 0x70_0000 << 1
				v &= (0x8F_FFFF << 1) | 1
				z |= v
				z <<= m
				put_le32(data, p - 4, z)
			}
			m = (m + 1) & 3
			if m == 0 {
				break
			}
		}
	}
	return size
}

@(private)
arm64_convert :: proc "contextless" (data: []u8, pc: u32, $ENCODING: bool) -> int #no_bounds_check {
	FLAG :: u32(1) << (24 - 4)
	MASK :: (u32(1) << 24) - (FLAG << 1)
	size := len(data) &~ 3
	for i := 0; i < size; i += 4 {
		v := get_le32(data, i)
		if (v - 0x9400_0000) & 0xFC00_0000 == 0 {
			c := (pc + u32(i)) >> 2
			when ENCODING {
				v += c
			} else {
				v -= c
			}
			put_le32(data, i, (v & 0x03FF_FFFF) | 0x9400_0000)
			continue
		}
		v -= 0x9000_0000
		if v & 0x9F00_0000 != 0 {
			continue
		}
		v += FLAG
		if v & MASK != 0 {
			continue
		}
		z := (v & 0xFFFF_FFE0) | (v >> 26)
		c := ((pc + u32(i)) >> (12 - 3)) &~ u32(7)
		when ENCODING {
			z += c
		} else {
			z -= c
		}
		v &= 0x1F
		v |= 0x9000_0000
		v |= z << 26
		v |= 0x00FF_FFE0 & ((z & ((FLAG << 1) - 1)) - FLAG)
		put_le32(data, i, v)
	}
	return size
}

@(private)
RISCV_REG_VAL :: u32(2 << 7)

@(private)
riscv_check_1 :: #force_inline proc "contextless" (v, b: u32) -> bool {
	return ((b - 3) ~ (v << 8)) & (0xF_8000 + 3) == 0
}

@(private)
riscv_check_2 :: #force_inline proc "contextless" (v, r: u32) -> bool {
	return (v - ((3 << 12) | RISCV_REG_VAL | 8)) << 18 < r & 0x1D
}

@(private)
riscv_scan :: #force_inline proc "contextless" (data: []u8, i: ^int, limit: int) -> (a: u32, ok: bool) #no_bounds_check {
	for i^ < limit - 8 {
		x := u64(intrinsics.unaligned_load((^u64le)(&data[i^])))
		w := (((x ~ 0x0010_0010_0010_0010) & 0x007F_007F_007F_007F) + 0x0001_0001_0001_0001) & 0x0077_0077_0077_0077
		z := (w - 0x0001_0001_0001_0001) & ~w & 0x8000_8000_8000_8000
		if z != 0 {
			i^ += int(intrinsics.count_trailing_zeros(z) >> 4) * 2
			return (get_le16(data, i^) ~ 0x10) + 1, true
		}
		i^ += 8
	}
	for {
		if i^ >= limit {
			return 0, false
		}
		a = (get_le16(data, i^) ~ 0x10) + 1
		if a & 0x77 == 0 {
			return a, true
		}
		a = (get_le16(data, i^ + 2) ~ 0x10) + 1
		i^ += 4
		if a & 0x77 == 0 {
			i^ -= 2
			if i^ >= limit {
				return 0, false
			}
			return a, true
		}
	}
}

@(private)
riscv_encode :: proc "contextless" (data: []u8, pc: u32) -> int #no_bounds_check {
	size := len(data) &~ 1
	if size <= 6 {
		return 0
	}
	limit := size - 6
	i := 0
	for {
		v := riscv_scan(data, &i, limit) or_break
		a := get_le32(data, i)
		if v & 8 == 0 {
			if (v - 0x100) & 0xD80 != 0 {
				i += 2
				continue
			}
			v = ((a & (u32(1) << 31)) >> 11) | ((a & (0x3FF << 21)) >> 20) | ((a & (1 << 20)) >> 9) | (a & (0xFF << 12))
			v += pc + u32(i)
			data[i + 1] = u8(((v >> 13) & 0xF0) | ((a >> 8) & 0xF))
			data[i + 2] = u8(v >> 9)
			data[i + 3] = u8(v >> 1)
			i += 4
			continue
		}
		if v & 0xE80 != 0 {
			b := get_le32(data, i + 4)
			if !riscv_check_1(v, b) {
				i += 6
				continue
			}
			put_le32(data, i, (b << 12) | (0x17 + RISCV_REG_VAL))
			a &= 0xFFFF_F000
			a += u32(i32(b) >> 20)
			a += pc + u32(i)
			put_be32(data, i + 4, a)
			i += 8
		} else {
			r := a >> 27
			if !riscv_check_2(v, r) {
				i += 4
				continue
			}
			v = get_le32(data, i + 4)
			r = (r << 7) + 0x17 + (v & 0xFFFF_F000)
			a = (a >> 12) | (v << 20)
			put_le32(data, i,     r)
			put_le32(data, i + 4, a)
			i += 8
		}
	}
	return i
}

@(private)
riscv_decode :: proc "contextless" (data: []u8, pc: u32) -> int #no_bounds_check {
	size := len(data) &~ 1
	if size <= 6 {
		return 0
	}
	limit := size - 6
	i := 0
	for {
		a := riscv_scan(data, &i, limit) or_break
		if a & 8 == 0 {
			a -= 0x100 - 0x7F
			if a & 0xD80 != 0 {
				i += 2
				continue
			}
			a_old := (a + (0xEF - 0x7F)) & 0xFFF
			v := u32(data[i + 3]) << 1 | u32(data[i + 2]) << 9 | (a & 0xF000) << 5
			v -= pc + u32(i)
			a = a_old | (v << 11 & (u32(1) << 31)) | (v << 20 & (0x3FF << 21)) | (v << 9 & (1 << 20)) | (v & (0xFF << 12))
			put_le32(data, i, a)
			i += 4
			continue
		}
		v := a
		a = get_le32(data, i)
		if v & 0xE80 == 0 {
			r := a >> 27
			if !riscv_check_2(v, r) {
				i += 4
				continue
			}
			b := get_be32(data, i + 4)
			v = a >> 12
			b -= pc + u32(i)
			a = (r << 7) + 0x17
			a += (b + 0x800) & 0xFFFF_F000
			v |= b << 20
			put_le32(data, i,     a)
			put_le32(data, i + 4, v)
			i += 8
		} else {
			b := get_le32(data, i + 4)
			if !riscv_check_1(v, b) {
				i += 6
				continue
			}
			v = (a & 0xFFFF_F000) | (b >> 20)
			a = (b << 12) | (0x17 + RISCV_REG_VAL)
			put_le32(data, i,     a)
			put_le32(data, i + 4, v)
			i += 8
		}
	}
	return i
}
