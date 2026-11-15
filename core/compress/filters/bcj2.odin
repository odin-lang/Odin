package compress_filters

import "base:intrinsics"
import "base:runtime"

bcj2_decode :: proc{bcj2_decode_to_slice, bcj2_decode_to_dynamic}

bcj2_decode_to_slice :: proc(output: []u8, main, call, jump, rc: []u8) -> (err: Error) {
	rest := len(output) - len(main)
	if rest < 0 || len(call) > rest || len(jump) != rest - len(call) {
		return BCJ2_Error.Size_Mismatch
	}
	return bcj2_decode_streams(output, main, call, jump, rc)
}

bcj2_decode_to_dynamic :: proc(output: ^[dynamic]u8, main, call, jump, rc: []u8, allocator := context.allocator) -> (err: Error) {
	if output == nil {
		return General_Error.Incompatible_Options
	}
	if len(call) > max(int) - len(main) || len(jump) > max(int) - len(main) - len(call) {
		return BCJ2_Error.Size_Mismatch
	}
	context.allocator = allocator
	non_zero_resize(output, len(main) + len(call) + len(jump)) or_return
	if err = bcj2_decode_streams(output[:], main, call, jump, rc); err != nil {
		non_zero_resize(output, 0)
	}
	return
}

bcj2_encode :: proc(streams: ^Bcj2_Streams, input: []u8, relat_limit := BCJ2_RELAT_LIMIT_DEFAULT, file_size := i64(-1), allocator := context.allocator) -> (err: Error) {
	if streams == nil || relat_limit > BCJ2_RELAT_LIMIT_MAX {
		return General_Error.Incompatible_Options
	}
	context.allocator = allocator
	non_zero_resize(&streams.main, len(input)) or_return
	clear(&streams.call)
	clear(&streams.jump)
	clear(&streams.rc)
	reserve(&streams.rc, len(input) / 64 + 16) or_return
	if err = bcj2_encode_streams(streams, input, relat_limit, file_size); err != nil {
		non_zero_resize(&streams.main, 0)
		clear(&streams.call)
		clear(&streams.jump)
		clear(&streams.rc)
	}
	return
}

@(private)
bcj2_copy_scan :: #force_inline proc "contextless" (dst: []u8, o: int, src: []u8, start: int, prev: u32) -> int #no_bounds_check {
	LO :: 0x0101_0101_0101_0101
	HI :: 0x8080_8080_8080_8080
	k := start
	p := u64(prev)
	for k <= len(src) - 8 {
		v := u64(intrinsics.unaligned_load((^u64le)(&src[k])))
		intrinsics.unaligned_store((^u64le)(&dst[o + k - start]), u64le(v))
		a := (v & 0xFEFE_FEFE_FEFE_FEFE) ~ 0xE8E8_E8E8_E8E8_E8E8
		b := ((v & 0xF0F0_F0F0_F0F0_F0F0) ~ HI) | ((v << 8 | p) ~ 0x0F0F_0F0F_0F0F_0F0F)
		z := ((a - LO) & ~a | (b - LO) & ~b) & HI
		if z != 0 {
			return k + int(intrinsics.count_trailing_zeros(z) >> 3)
		}
		p  = v >> 56
		k += 8
	}
	for k < len(src) {
		c := u64(src[k])
		dst[o + k - start] = u8(c)
		if c & 0xFE == 0xE8 || (p == 0x0F && c & 0xF0 == 0x80) {
			return k
		}
		p  = c
		k += 1
	}
	return k
}

@(private)
bcj2_decode_streams :: proc(output: []u8, main, call, jump, rc: []u8) -> (err: Error) #no_bounds_check {
	if len(rc) < 5 {
		return General_Error.Stream_Too_Short
	}
	if rc[0] != 0 {
		return BCJ2_Error.Corrupt_Data
	}
	code := get_be32(rc, 1)
	if code == 0xFFFF_FFFF {
		return BCJ2_Error.Corrupt_Data
	}
	range_ := u32(0xFFFF_FFFF)
	r := 5

	probs: [2 + 256]u16 = ---
	for &p in probs {
		p = BCJ2_PROB_INIT
	}

	ip, prev := u32(0), u32(0)
	o, m, c, j := 0, 0, 0, 0
	for {
		if range_ < BCJ2_TOP {
			if r == len(rc) {
				return General_Error.Stream_Too_Short
			}
			range_ <<= 8
			code = code << 8 | u32(rc[r])
			r += 1
		}

		k := bcj2_copy_scan(output, o, main, m, prev)
		o  += k - m
		ip += u32(k - m)
		if k == len(main) {
			m = k
			break
		}
		marker := u32(main[k])
		before := prev if k == m else u32(main[k - 1])
		prev    = marker
		o  += 1
		ip += 1
		m   = k + 1

		index := 2 + int(before) if marker == 0xE8 else (1 if marker == 0xE9 else 0)
		ttt   := u32(probs[index])
		bound := (range_ >> BCJ2_PROB_BITS) * ttt
		if code < bound {
			range_ = bound
			probs[index] = u16(ttt + ((1 << BCJ2_PROB_BITS - ttt) >> BCJ2_MOVE_BITS))
			continue
		}
		range_ -= bound
		code   -= bound
		probs[index] = u16(ttt - (ttt >> BCJ2_MOVE_BITS))

		absolute: u32
		if marker == 0xE8 {
			if c > len(call) - 4 {
				return BCJ2_Error.Corrupt_Data
			}
			absolute = get_be32(call, c)
			c += 4
		} else {
			if j > len(jump) - 4 {
				return BCJ2_Error.Corrupt_Data
			}
			absolute = get_be32(jump, j)
			j += 4
		}
		ip += 4
		relative := absolute - ip
		put_le32(output, o, relative)
		o += 4
		prev = relative >> 24
	}

	if o != len(output) || c != len(call) || j != len(jump) || r != len(rc) || code != 0 {
		return BCJ2_Error.Corrupt_Data
	}
	return nil
}

@(private)
Bcj2_Range_Encoder :: struct {
	low:        u64,
	range_:     u32,
	cache:      u8,
	cache_size: u64,
	out:        ^[dynamic]u8,
}

@(private)
bcj2_shift_low :: proc(e: ^Bcj2_Range_Encoder) -> (err: runtime.Allocator_Error) {
	low  := u32(e.low)
	high := u8(e.low >> 32)
	if low < 0xFF00_0000 || high != 0 {
		temp := e.cache
		for {
			append(e.out, temp + high) or_return
			temp = 0xFF
			e.cache_size -= 1
			if e.cache_size == 0 {
				break
			}
		}
		e.cache = u8(low >> 24)
	}
	e.cache_size += 1
	e.low = u64(low << 8)
	return nil
}

@(private)
bcj2_encode_streams :: proc(streams: ^Bcj2_Streams, input: []u8, relat_limit: u32, file_size: i64) -> (err: Error) #no_bounds_check {
	probs: [2 + 256]u16 = ---
	for &p in probs {
		p = BCJ2_PROB_INIT
	}
	e := Bcj2_Range_Encoder{range_ = 0xFFFF_FFFF, cache_size = 1, out = &streams.rc}
	size_limit := max(u64) if file_size < 0 else u64(file_size) - 1

	main := streams.main[:]
	n    := len(input)
	ip   := u64(0)
	prev := u32(0)
	i, o := 0, 0
	for {
		if e.range_ < BCJ2_TOP {
			bcj2_shift_low(&e) or_return
			e.range_ <<= 8
		}

		k := bcj2_copy_scan(main, o, input, i, prev)
		o  += k - i
		ip += u64(k - i)
		if k == n {
			i = k
			break
		}
		marker := u32(input[k])
		before := prev if k == i else u32(input[k - 1])
		prev    = marker
		o  += 1
		ip += 1
		i   = k + 1

		convert  := false
		relative := u32(0)
		if n - i >= 4 {
			relative = get_le32(input, i)
			first    := u64(1) if marker & 0xF0 == 0x80 else 0
			if ip > first && u64(i64(ip) + 4 + i64(i32(relative))) <= size_limit && (relative + relat_limit) >> 1 < relat_limit {
				convert = true
			}
		}

		index := 2 + int(before) if marker == 0xE8 else (1 if marker == 0xE9 else 0)
		ttt   := u32(probs[index])
		bound := (e.range_ >> BCJ2_PROB_BITS) * ttt
		if !convert {
			e.range_ = bound
			probs[index] = u16(ttt + ((1 << BCJ2_PROB_BITS - ttt) >> BCJ2_MOVE_BITS))
			continue
		}
		e.low    += u64(bound)
		e.range_ -= bound
		probs[index] = u16(ttt - (ttt >> BCJ2_MOVE_BITS))

		ip += 4
		absolute := u32(ip) + relative
		target   := &streams.call if marker == 0xE8 else &streams.jump
		bytes    := [4]u8{u8(absolute >> 24), u8(absolute >> 16), u8(absolute >> 8), u8(absolute)}
		append(target, ..bytes[:]) or_return
		i += 4
		prev = relative >> 24
	}
	for _ in 0..<5 {
		bcj2_shift_low(&e) or_return
	}
	return non_zero_resize(&streams.main, o)
}
