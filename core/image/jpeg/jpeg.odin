// Reader for `JPEG` images. Supports baseline, extended sequential and progressive encoding.
package jpeg

import "base:intrinsics"
import "core:compress"
import "core:image"
import "core:slice"

load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	data := data
	ctx  := compress.init_context_from_slice(&data)
	return load_from_context(&ctx, options, allocator)
}

load_from_context :: proc(ctx: ^compress.Context, options := Options{}, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	if .info in options {
		options += {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	first     := compress.read_u8(ctx) or_return
	soi_byte  := compress.read_u8(ctx) or_return
	if first != 0xFF || image.JPEG_Marker(soi_byte) != .SOI {
		return img, .Invalid_Signature
	}

	img = new(Image) or_return
	img.which = .JPEG

	d := new(Decoder) or_return
	defer {
		for &c in d.components {
			delete(c.coefficients)
			delete(c.plane)
		}
		free(d)
	}
	d.ctx = ctx

	frame_seen := false
	loop: for {
		b, read_err := compress.read_u8(ctx)
		if read_err != nil {
			if d.scans > 0 {
				break loop
			}
			return img, read_err
		}
		if b != 0xFF {
			continue
		}

		marker_byte: u8 = 0xFF
		for marker_byte == 0xFF {
			marker_byte, read_err = compress.read_u8(ctx)
			if read_err != nil {
				if d.scans > 0 {
					break loop
				}
				return img, read_err
			}
		}
		marker := image.JPEG_Marker(marker_byte)

		#partial switch marker {
		case image.JPEG_Marker(0x00):
			continue
		case .SOI:
			return img, .Duplicate_SOI_Marker
		case .EOI:
			break loop
		case .RST0..=.RST7, .TEM:
			continue
		case .APP0:
			segment := read_segment(ctx) or_return
			defer delete(segment)
			parse_app0(d, img, segment, options) or_return
		case .APP1:
			if .return_metadata not_in options {
				skip_segment(ctx) or_return
				continue
			}
			segment := read_segment(ctx) or_return
			defer delete(segment)
			parse_app1(img, segment) or_return
		case .APP14:
			segment := read_segment(ctx) or_return
			defer delete(segment)
			parse_app14(d, segment)
		case .COM:
			if .return_metadata not_in options {
				skip_segment(ctx) or_return
				continue
			}
			segment := read_segment(ctx) or_return
			info, info_err := get_info(img)
			if info_err != nil {
				delete(segment)
				return img, info_err
			}
			if _, append_err := append(&info.comments, string(segment)); append_err != nil {
				delete(segment)
				return img, append_err
			}
		case .DQT:
			parse_quantization(d) or_return
		case .DHT:
			parse_huffman(d) or_return
		case .DRI:
			length := read_length(ctx) or_return
			if length < 2 {
				return img, .Corrupt
			}
			d.restart_interval = int(compress.read_data(ctx, u16be) or_return)
			compress.skip(ctx, i64(length - 2)) or_return
		case .SOF0, .SOF1, .SOF2:
			if frame_seen {
				return img, .Multiple_SOS_Markers
			}
			parse_frame(d, img, marker, options) or_return
			frame_seen = true
			if .do_not_decompress_image in options && .return_metadata not_in options {
				return img, nil
			}
		case .SOF3, .SOF5, .SOF6, .SOF7, .SOF9, .SOF10, .SOF11, .SOF13, .SOF14, .SOF15:
			if .return_metadata in options {
				info := get_info(img) or_return
				info.frame_type = marker
			}
			return img, .Unsupported_Frame_Type
		case .SOS:
			if !frame_seen {
				return img, .Encountered_SOS_Before_SOF
			}
			if .do_not_decompress_image in options {
				return img, nil
			}
			parse_scan(d) or_return
		case:
			skip_segment(ctx) or_return
		}
	}

	if d.scans == 0 {
		if frame_seen && .do_not_decompress_image in options {
			return img, nil
		}
		return img, .Missing_Image_Data
	}
	produce_image(d, img, options) or_return
	return img, nil
}

destroy :: proc(img: ^Image) {
	if img == nil {
		return
	}

	delete(img.pixels)

	if v, ok := img.metadata.(^image.JPEG_Info); ok {
		if jfxx, jfxx_ok := v.jfxx_app0.?; jfxx_ok {
			delete(jfxx.thumbnail)
		}
		if jfif, jfif_ok := v.jfif_app0.?; jfif_ok {
			delete(jfif.thumbnail)
		}

		for comment in v.comments {
			delete(comment)
		}
		delete(v.comments)

		for exif in v.exif {
			delete(exif.data)
		}
		delete(v.exif)

		free(v)
	}
	free(img)
}

@(private="file")
fill_bits :: proc(d: ^Decoder) #no_bounds_check {
	z := d.ctx
	if !d.stopped && len(z.window) >= 8 {
		w   := u64(intrinsics.unaligned_load((^u64be)(raw_data(z.window))))
		inv := ~w
		if (inv - 0x0101_0101_0101_0101) & w & 0x8080_8080_8080_8080 == 0 {
			n := (63 - d.count) >> 3
			d.bits  |= (w >> d.count) & ~(max(u64) >> (d.count + 8 * n))
			d.count += 8 * n
			z.window = z.window[n:]
			return
		}
	}
	for d.count <= 56 {
		b: u64
		if !d.stopped {
			if len(z.window) < 2 {
				compress.refill_window(z, 2)
			}
			if len(z.window) == 0 {
				d.stopped = true
			} else if z.window[0] != 0xFF {
				b = u64(z.window[0])
				z.window = z.window[1:]
			} else if len(z.window) == 1 {
				z.window = z.window[1:]
				d.stopped = true
			} else if z.window[1] == 0x00 {
				b = 0xFF
				z.window = z.window[2:]
			} else if z.window[1] == 0xFF {
				z.window = z.window[1:]
				continue
			} else {
				d.stopped = true
			}
		}
		d.bits  |= b << (56 - d.count)
		d.count += 8
	}
}

@(private="file")
get_bits :: #force_inline proc(d: ^Decoder, n: u32) -> i32 {
	if n == 0 {
		return 0
	}
	if d.count < n {
		fill_bits(d)
	}
	v := i32(d.bits >> (64 - n))
	d.bits <<= n
	d.count -= n
	return v
}

@(private="file")
receive_extend :: #force_inline proc(d: ^Decoder, s: u32) -> i32 {
	if s == 0 {
		return 0
	}
	v := get_bits(d, s)
	return v - (i32(1) << s) + 1 if v < (i32(1) << (s - 1)) else v
}

@(private="file")
decode_huffman :: #force_inline proc(d: ^Decoder, t: ^Huffman_Table) -> int #no_bounds_check {
	if d.count < 16 {
		fill_bits(d)
	}
	entry := t.lookup[d.bits >> (64 - HUFFMAN_LOOKAHEAD)]
	if entry != 0 {
		length := u32(entry >> 8)
		d.bits <<= length
		d.count -= length
		return int(entry & 0xFF)
	}
	for length in u32(HUFFMAN_LOOKAHEAD + 1)..=16 {
		code := i32(d.bits >> (64 - length))
		if code <= t.max_code[length] {
			d.bits <<= length
			d.count -= length
			return int(t.symbols[(code + t.value_offset[length]) & 0xFF])
		}
	}
	d.bits <<= 16
	d.count -= 16
	return -1
}

@(private="file")
build_huffman :: proc(t: ^Huffman_Table, counts: [17]i32, symbols: []u8) -> bool {
	t^ = {}
	copy(t.symbols[:], symbols)
	code  := i32(0)
	index := i32(0)
	for length in 1..=16 {
		n := counts[length]
		t.max_code[length] = -1
		if code + n > i32(1) << u32(length) {
			return false
		}
		if n > 0 {
			t.value_offset[length] = index - code
			if length <= HUFFMAN_LOOKAHEAD {
				shift := u32(HUFFMAN_LOOKAHEAD - length)
				for i in 0..<n {
					first := (code + i) << shift
					for j in 0..<(i32(1) << shift) {
						t.lookup[first + j] = u16(length << 8) | u16(symbols[index + i])
					}
				}
			}
			code  += n
			index += n
			t.max_code[length] = code - 1
		}
		code <<= 1
	}
	t.defined = true
	return true
}

@(private="file")
decode_block_sequential :: proc(d: ^Decoder, c: ^Component, block: []i16) -> bool #no_bounds_check {
	t := decode_huffman(d, &d.huffman[0][c.dc_table])
	if t < 0 || t > 11 {
		return false
	}
	c.dc_pred += receive_extend(d, u32(t))
	block[0] = i16(c.dc_pred)

	ac := &d.huffman[1][c.ac_table]
	for k := 1; k < COEFFICIENT_COUNT; {
		rs := decode_huffman(d, ac)
		if rs < 0 {
			return false
		}
		r := rs >> 4
		s := u32(rs & 15)
		if s == 0 {
			if r != 15 {
				break
			}
			k += 16
			continue
		}
		k += r
		if k >= COEFFICIENT_COUNT {
			return false
		}
		block[zigzag[k]] = i16(receive_extend(d, s))
		k += 1
	}
	return true
}

@(private="file")
decode_block_dc_first :: proc(d: ^Decoder, c: ^Component, block: []i16, al: u32) -> bool #no_bounds_check {
	t := decode_huffman(d, &d.huffman[0][c.dc_table])
	if t < 0 || t > 11 {
		return false
	}
	c.dc_pred += receive_extend(d, u32(t))
	block[0] = i16(c.dc_pred * (i32(1) << al))
	return true
}

@(private="file")
decode_block_dc_refine :: proc(d: ^Decoder, block: []i16, al: u32) -> bool #no_bounds_check {
	if get_bits(d, 1) != 0 {
		block[0] |= i16(1) << al
	}
	return true
}

@(private="file")
decode_block_ac_first :: proc(d: ^Decoder, c: ^Component, block: []i16, ss, se: int, al: u32) -> bool #no_bounds_check {
	if d.eobrun > 0 {
		d.eobrun -= 1
		return true
	}
	ac := &d.huffman[1][c.ac_table]
	for k := ss; k <= se; {
		rs := decode_huffman(d, ac)
		if rs < 0 {
			return false
		}
		r := rs >> 4
		s := u32(rs & 15)
		if s == 0 {
			if r < 15 {
				d.eobrun = (1 << u32(r)) - 1
				if r > 0 {
					d.eobrun += int(get_bits(d, u32(r)))
				}
				break
			}
			k += 16
			continue
		}
		k += r
		if k > se {
			return false
		}
		block[zigzag[k]] = i16(receive_extend(d, s) * (i32(1) << al))
		k += 1
	}
	return true
}

@(private="file")
zigzag_masks: [BLOCK_SIZE][256]u64

@(init, private="file")
init_zigzag_masks :: proc "contextless" () {
	natural_to_zigzag: [COEFFICIENT_COUNT]u8
	for k in 0..<COEFFICIENT_COUNT {
		natural_to_zigzag[zigzag[k]] = u8(k)
	}
	for row in 0..<BLOCK_SIZE {
		for bits in 0..<256 {
			mask: u64
			for col in 0..<BLOCK_SIZE {
				if bits & (1 << uint(col)) != 0 {
					mask |= 1 << natural_to_zigzag[row * BLOCK_SIZE + col]
				}
			}
			zigzag_masks[row][bits] = mask
		}
	}
}

@(private="file")
nonzero_mask :: #force_inline proc(block: []i16) -> (mask: u64) #no_bounds_check {
	for row in 0..<BLOCK_SIZE {
		v    := intrinsics.unaligned_load((^#simd[8]i16)(&block[row * BLOCK_SIZE]))
		bits := transmute(u8)intrinsics.simd_extract_msbs(intrinsics.simd_lanes_ne(v, 0))
		mask |= zigzag_masks[row][bits]
	}
	return
}

@(private="file")
span :: #force_inline proc(lo, hi: int) -> u64 {
	if lo > hi {
		return 0
	}
	return (max(u64) << uint(lo)) & (max(u64) >> uint(63 - hi))
}

@(private="file")
get_bit :: #force_inline proc(d: ^Decoder) -> u64 {
	if d.count == 0 {
		fill_bits(d)
	}
	v := d.bits >> 63
	d.bits <<= 1
	d.count -= 1
	return v
}

@(private="file")
refine_bits :: #force_inline proc(d: ^Decoder, block: []i16, mask: u64, p1: i16) #no_bounds_check {
	for m := mask; m != 0; m &= m - 1 {
		coefficient := &block[zigzag[intrinsics.count_trailing_zeros(m)]]
		v   := coefficient^
		add := i16(get_bit(d)) & i16(v & p1 == 0)
		coefficient^ = v + add * ((v >> 15) | 1) * p1
	}
}

@(private="file")
decode_block_ac_refine :: proc(d: ^Decoder, c: ^Component, block: []i16, ss, se: int, al: u32) -> bool #no_bounds_check {
	p1 := i16(1) << al
	m1 := -p1
	nonzero := nonzero_mask(block)
	k := ss
	if d.eobrun == 0 {
		ac := &d.huffman[1][c.ac_table]
		for ; k <= se; k += 1 {
			rs := decode_huffman(d, ac)
			if rs < 0 {
				return false
			}
			r := rs >> 4
			s := rs & 15
			value: i16
			if s != 0 {
				if s != 1 {
					return false
				}
				value = p1 if get_bit(d) != 0 else m1
			} else if r != 15 {
				d.eobrun = 1 << u32(r)
				if r > 0 {
					d.eobrun += int(get_bits(d, u32(r)))
				}
				break
			}
			zeros := ~nonzero & span(k, se)
			for _ in 0..<r {
				zeros &= zeros - 1
			}
			target := se + 1
			if zeros != 0 {
				target = int(intrinsics.count_trailing_zeros(zeros))
			}
			refine_bits(d, block, nonzero & span(k, target - 1), p1)
			k = target
			if value != 0 && k <= se {
				block[zigzag[k]] = value
			}
		}
	}
	if d.eobrun > 0 {
		refine_bits(d, block, nonzero & span(k, se), p1)
		d.eobrun -= 1
	}
	return true
}

@(private="file")
decode_block :: #force_inline proc(d: ^Decoder, c: ^Component, block: []i16, ss, se, ah, al: int) -> bool {
	if !d.progressive {
		return decode_block_sequential(d, c, block)
	}
	if ss == 0 {
		if ah == 0 {
			return decode_block_dc_first(d, c, block, u32(al))
		}
		return decode_block_dc_refine(d, block, u32(al))
	}
	if ah == 0 {
		return decode_block_ac_first(d, c, block, ss, se, u32(al))
	}
	return decode_block_ac_refine(d, c, block, ss, se, u32(al))
}

@(private="file")
handle_restart :: proc(d: ^Decoder, scan: []^Component) {
	z := d.ctx
	d.bits  = 0
	d.count = 0
	if !d.stopped {
		for {
			if len(z.window) < 2 {
				compress.refill_window(z, 2)
			}
			if len(z.window) < 2 {
				break
			}
			if z.window[0] == 0xFF && z.window[1] != 0x00 && z.window[1] != 0xFF {
				break
			}
			z.window = z.window[1:]
		}
	}
	if len(z.window) < 2 {
		compress.refill_window(z, 2)
	}
	if len(z.window) >= 2 && z.window[0] == 0xFF && z.window[1] >= u8(image.JPEG_Marker.RST0) && z.window[1] <= u8(image.JPEG_Marker.RST7) {
		z.window  = z.window[2:]
		d.stopped = false
	} else {
		d.stopped = true
	}
	for c in scan {
		c.dc_pred = 0
	}
	d.eobrun = 0
}

@(private="file")
decode_block_at :: #force_inline proc(d: ^Decoder, c: ^Component, bx, by: int, local: []i16, ss, se, ah, al: int) -> (err: Error) #no_bounds_check {
	if d.progressive {
		block := c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT:][:COEFFICIENT_COUNT]
		if !decode_block(d, c, block, ss, se, ah, al) {
			return .Corrupt
		}
		return nil
	}
	intrinsics.mem_zero(raw_data(local), COEFFICIENT_COUNT * size_of(i16))
	if !decode_block_sequential(d, c, local) {
		return .Corrupt
	}
	if bx < c.blocks_w && by < c.blocks_h {
		idct_block(local, &c.quant, c.plane[by * BLOCK_SIZE * c.plane_stride + bx * BLOCK_SIZE:], c.plane_stride)
	}
	return nil
}

@(private="file")
decode_scan :: proc(d: ^Decoder, scan: []^Component, ss, se, ah, al: int) -> (err: Error) {
	d.bits    = 0
	d.count   = 0
	d.stopped = false
	d.eobrun  = 0
	for c in scan {
		c.dc_pred = 0
	}

	local: [COEFFICIENT_COUNT]i16
	mcu := 0
	if len(scan) == 1 {
		c := scan[0]
		for by in 0..<c.blocks_h {
			for bx in 0..<c.blocks_w {
				if d.restart_interval > 0 && mcu > 0 && mcu % d.restart_interval == 0 {
					handle_restart(d, scan)
				}
				decode_block_at(d, c, bx, by, local[:], ss, se, ah, al) or_return
				mcu += 1
			}
		}
		return nil
	}

	for my in 0..<d.mcuy {
		for mx in 0..<d.mcux {
			if d.restart_interval > 0 && mcu > 0 && mcu % d.restart_interval == 0 {
				handle_restart(d, scan)
			}
			for c in scan {
				for v in 0..<c.v {
					for h in 0..<c.h {
						bx := mx * c.h + h
						by := my * c.v + v
						decode_block_at(d, c, bx, by, local[:], ss, se, ah, al) or_return
					}
				}
			}
			mcu += 1
		}
	}
	return nil
}

@(private="file")
Lanes :: #simd[8]i32

@(private="file")
idct_1d :: #force_inline proc(x: [8]Lanes, $SHIFT: u32, $BIAS: i32) -> (y: [8]Lanes) {
	C1 :: 8035
	C2 :: 7568
	C3 :: 6811
	C4 :: 5793
	C5 :: 4551
	C6 :: 3135
	C7 :: 1598

	e0 := (x[0] + x[4]) * C4
	e1 := (x[0] - x[4]) * C4
	e2 := x[2] * C6 - x[6] * C2
	e3 := x[2] * C2 + x[6] * C6
	a0 := e0 + e3 + BIAS
	a3 := e0 - e3 + BIAS
	a1 := e1 + e2 + BIAS
	a2 := e1 - e2 + BIAS
	b0 := x[1] * C1 + x[3] * C3 + x[5] * C5 + x[7] * C7
	b1 := x[1] * C3 - x[3] * C7 - x[5] * C1 - x[7] * C5
	b2 := x[1] * C5 - x[3] * C1 + x[5] * C7 + x[7] * C3
	b3 := x[1] * C7 - x[3] * C5 + x[5] * C3 - x[7] * C1
	shift: #simd[8]u32 = SHIFT

	y[0] = intrinsics.simd_shr(a0 + b0, shift)
	y[7] = intrinsics.simd_shr(a0 - b0, shift)
	y[1] = intrinsics.simd_shr(a1 + b1, shift)
	y[6] = intrinsics.simd_shr(a1 - b1, shift)
	y[2] = intrinsics.simd_shr(a2 + b2, shift)
	y[5] = intrinsics.simd_shr(a2 - b2, shift)
	y[3] = intrinsics.simd_shr(a3 + b3, shift)
	y[4] = intrinsics.simd_shr(a3 - b3, shift)
	return
}

@(private="file")
transpose :: #force_inline proc(r: [8]Lanes) -> (c: [8]Lanes) {
	t0 := intrinsics.simd_shuffle(r[0], r[1], 0, 8, 1, 9, 4, 12, 5, 13)
	t1 := intrinsics.simd_shuffle(r[0], r[1], 2, 10, 3, 11, 6, 14, 7, 15)
	t2 := intrinsics.simd_shuffle(r[2], r[3], 0, 8, 1, 9, 4, 12, 5, 13)
	t3 := intrinsics.simd_shuffle(r[2], r[3], 2, 10, 3, 11, 6, 14, 7, 15)
	t4 := intrinsics.simd_shuffle(r[4], r[5], 0, 8, 1, 9, 4, 12, 5, 13)
	t5 := intrinsics.simd_shuffle(r[4], r[5], 2, 10, 3, 11, 6, 14, 7, 15)
	t6 := intrinsics.simd_shuffle(r[6], r[7], 0, 8, 1, 9, 4, 12, 5, 13)
	t7 := intrinsics.simd_shuffle(r[6], r[7], 2, 10, 3, 11, 6, 14, 7, 15)

	u0 := intrinsics.simd_shuffle(t0, t2, 0, 1, 8, 9, 4, 5, 12, 13)
	u1 := intrinsics.simd_shuffle(t0, t2, 2, 3, 10, 11, 6, 7, 14, 15)
	u2 := intrinsics.simd_shuffle(t1, t3, 0, 1, 8, 9, 4, 5, 12, 13)
	u3 := intrinsics.simd_shuffle(t1, t3, 2, 3, 10, 11, 6, 7, 14, 15)
	u4 := intrinsics.simd_shuffle(t4, t6, 0, 1, 8, 9, 4, 5, 12, 13)
	u5 := intrinsics.simd_shuffle(t4, t6, 2, 3, 10, 11, 6, 7, 14, 15)
	u6 := intrinsics.simd_shuffle(t5, t7, 0, 1, 8, 9, 4, 5, 12, 13)
	u7 := intrinsics.simd_shuffle(t5, t7, 2, 3, 10, 11, 6, 7, 14, 15)

	c[0] = intrinsics.simd_shuffle(u0, u4, 0, 1, 2, 3, 8, 9, 10, 11)
	c[4] = intrinsics.simd_shuffle(u0, u4, 4, 5, 6, 7, 12, 13, 14, 15)
	c[1] = intrinsics.simd_shuffle(u1, u5, 0, 1, 2, 3, 8, 9, 10, 11)
	c[5] = intrinsics.simd_shuffle(u1, u5, 4, 5, 6, 7, 12, 13, 14, 15)
	c[2] = intrinsics.simd_shuffle(u2, u6, 0, 1, 2, 3, 8, 9, 10, 11)
	c[6] = intrinsics.simd_shuffle(u2, u6, 4, 5, 6, 7, 12, 13, 14, 15)
	c[3] = intrinsics.simd_shuffle(u3, u7, 0, 1, 2, 3, 8, 9, 10, 11)
	c[7] = intrinsics.simd_shuffle(u3, u7, 4, 5, 6, 7, 12, 13, 14, 15)
	return
}

@(private="file")
idct_block :: proc(coefficients: []i16, quant: ^[COEFFICIENT_COUNT]u16, output: []u8, stride: int) #no_bounds_check {
	C4 :: 5793
	BIAS :: (128 << 16) + (1 << 15)

	ac_mask := #simd[8]i16{0, -1, -1, -1, -1, -1, -1, -1}
	x: [8]Lanes
	ac: #simd[8]i16
	for i in 0..<BLOCK_SIZE {
		c := intrinsics.unaligned_load((^#simd[8]i16)(&coefficients[i * 8]))
		q := intrinsics.unaligned_load((^#simd[8]u16)(&quant[i * 8]))
		ac |= c & ac_mask
		ac_mask = -1
		x[i] = cast(Lanes)c * cast(Lanes)q
	}

	if intrinsics.simd_reduce_or(ac) == 0 {
		dc := (i32(coefficients[0]) * i32(quant[0]) * C4 + (1 << 11)) >> 12
		v  := u8(clamp((dc * C4 + BIAS) >> 16, 0, 255))
		for row in 0..<BLOCK_SIZE {
			intrinsics.unaligned_store((^u64)(&output[row * stride]), u64(v) * 0x0101_0101_0101_0101)
		}
		return
	}

	y := idct_1d(x, 12, 1 << 11)
	y  = transpose(y)
	y  = idct_1d(y, 16, BIAS)
	y  = transpose(y)
	for row in 0..<BLOCK_SIZE {
		pixels := cast(#simd[8]u8)intrinsics.simd_clamp(y[row], 0, 255)
		intrinsics.unaligned_store((^#simd[8]u8)(&output[row * stride]), pixels)
	}
}

@(private="file")
upsample_row :: proc(d: ^Decoder, c: ^Component, y: int, output: []u8, colsum: []i16, width: int) -> []u8 #no_bounds_check {
	plane := c.plane
	ps    := c.plane_stride
	if d.hmax % c.h != 0 || d.vmax % c.v != 0 {
		sy  := min(y * c.v / d.vmax, c.height - 1)
		row := plane[sy * ps:]
		for x in 0..<width {
			output[x] = row[min(x * c.h / d.hmax, c.width - 1)]
		}
		return output
	}

	hr := d.hmax / c.h
	vr := d.vmax / c.v
	switch {
	case hr == 1 && vr == 1:
		return plane[y * ps:][:width]

	case hr == 2 && vr == 1:
		row := plane[y * ps:]
		n   := c.width
		if n == 1 {
			output[0] = row[0]
			output[1] = row[0]
			return output
		}
		output[0] = row[0]
		output[1] = u8((3 * int(row[0]) + int(row[1]) + 2) >> 2)
		for i in 1..<n - 1 {
			s := 3 * u16(row[i])
			output[2 * i]     = u8((s + u16(row[i - 1]) + 1) >> 2)
			output[2 * i + 1] = u8((s + u16(row[i + 1]) + 2) >> 2)
		}
		output[2 * n - 2] = u8((3 * int(row[n - 1]) + int(row[n - 2]) + 1) >> 2)
		output[2 * n - 1] = row[n - 1]

	case hr == 1 && vr == 2:
		j    := y >> 1
		far  := clamp(j - 1 if y & 1 == 0 else j + 1, 0, c.height - 1)
		bias := u16(1 if y & 1 == 0 else 2)
		near_row := plane[j * ps:][:width]
		far_row  := plane[far * ps:][:width]
		for x in 0..<width {
			output[x] = u8((3 * u16(near_row[x]) + u16(far_row[x]) + bias) >> 2)
		}

	case hr == 2 && vr == 2:
		j   := y >> 1
		far := clamp(j - 1 if y & 1 == 0 else j + 1, 0, c.height - 1)
		n   := c.width
		near_row := plane[j * ps:][:n]
		far_row  := plane[far * ps:][:n]
		sums     := colsum[:n + 2]
		for i in 0..<n {
			sums[i + 1] = 3 * i16(near_row[i]) + i16(far_row[i])
		}
		sums[0]     = sums[1]
		sums[n + 1] = sums[n]
		for i in 0..<n {
			current := 3 * sums[i + 1]
			output[2 * i]     = u8((current + sums[i]     + 8) >> 4)
			output[2 * i + 1] = u8((current + sums[i + 2] + 7) >> 4)
		}

	case:
		row := plane[(y / vr) * ps:]
		for x in 0..<width {
			output[x] = row[x / hr]
		}
	}
	return output
}

@(private="file")
ycc_row :: proc(luma, cb, cr: []u8, out: []u8, width: int, $CHANNELS: int) #no_bounds_check {
	x := 0
	for ; x + 8 + (CHANNELS == 3 ? 3 : 0) <= width; x += 8 {
		yv := cast(Lanes)intrinsics.unaligned_load((^#simd[8]u8)(&luma[x]))
		bv := cast(Lanes)intrinsics.unaligned_load((^#simd[8]u8)(&cb[x])) - 128
		rv := cast(Lanes)intrinsics.unaligned_load((^#simd[8]u8)(&cr[x])) - 128
		r := cast(#simd[8]u8)intrinsics.simd_clamp(yv + intrinsics.simd_shr(91881 * rv + 32768, 16), 0, 255)
		g := cast(#simd[8]u8)intrinsics.simd_clamp(yv + intrinsics.simd_shr(-22554 * bv - 46802 * rv + 32768, 16), 0, 255)
		b := cast(#simd[8]u8)intrinsics.simd_clamp(yv + intrinsics.simd_shr(116130 * bv + 32768, 16), 0, 255)
		rg := intrinsics.simd_shuffle(r, g, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
		when CHANNELS == 3 {
			bb := intrinsics.simd_shuffle(b, b, 0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7)
			pixels := intrinsics.simd_shuffle(rg, bb,
				0, 8, 16, 1, 9, 17, 2, 10, 18, 3, 11, 19, 4, 12, 20, 5, 13, 21, 6, 14, 22, 7, 15, 23,
				0, 0, 0, 0, 0, 0, 0, 0)
		} else {
			a: #simd[8]u8 = 255
			ba := intrinsics.simd_shuffle(b, a, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
			pixels := intrinsics.simd_shuffle(rg, ba,
				0, 8, 16, 24, 1, 9, 17, 25, 2, 10, 18, 26, 3, 11, 19, 27,
				4, 12, 20, 28, 5, 13, 21, 29, 6, 14, 22, 30, 7, 15, 23, 31)
		}
		intrinsics.unaligned_store((^#simd[32]u8)(&out[x * CHANNELS]), pixels)
	}
	for ; x < width; x += 1 {
		yv := i32(luma[x])
		bv := i32(cb[x]) - 128
		rv := i32(cr[x]) - 128
		out[x * CHANNELS + 0] = u8(clamp(yv + ((91881 * rv + 32768) >> 16), 0, 255))
		out[x * CHANNELS + 1] = u8(clamp(yv + ((-22554 * bv - 46802 * rv + 32768) >> 16), 0, 255))
		out[x * CHANNELS + 2] = u8(clamp(yv + ((116130 * bv + 32768) >> 16), 0, 255))
		when CHANNELS == 4 {
			out[x * CHANNELS + 3] = 255
		}
	}
}

@(private="file")
color_space :: proc(d: ^Decoder) -> Color_Space {
	switch d.component_count {
	case 1:
		return .Gray
	case 3:
		if d.adobe {
			return .RGB if d.adobe_transform == 0 else .YCbCr
		}
		if d.jfif {
			return .YCbCr
		}
		c := d.components
		if c[0].id == 'R' && c[1].id == 'G' && c[2].id == 'B' {
			return .RGB
		}
		return .YCbCr
	case 4:
		if d.adobe && d.adobe_transform == 2 {
			return .YCCK
		}
		return .CMYK
	}
	unreachable()
}

@(private="file")
produce_image :: proc(d: ^Decoder, img: ^Image, options: Options) -> (err: Error) {
	for &c in d.components[:d.component_count] {
		if c.coefficients == nil {
			if c.plane == nil {
				return .Missing_Image_Data
			}
			continue
		}
		c.plane = make([]u8, c.plane_stride * c.blocks_h * BLOCK_SIZE) or_return
		for by in 0..<c.blocks_h {
			for bx in 0..<c.blocks_w {
				block := c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT:][:COEFFICIENT_COUNT]
				idct_block(block, &c.quant, c.plane[by * BLOCK_SIZE * c.plane_stride + bx * BLOCK_SIZE:], c.plane_stride)
			}
		}
		delete(c.coefficients)
		c.coefficients = nil
	}

	space     := color_space(d)
	gray_out  := space == .Gray && (.do_not_expand_grayscale in options || .do_not_expand_channels in options)
	has_alpha := .alpha_add_if_missing in options
	channels  := 1 if gray_out else 3
	if has_alpha {
		channels += 1
	}

	width, height := img.width, img.height
	resize(&img.pixels, width * height * channels) or_return
	img.channels = channels
	img.depth    = 8

	buffers: [MAX_COMPONENTS][]u8
	rows:    [MAX_COMPONENTS][]u8
	row_buffer := make([]u8, (width + 8) * d.component_count) or_return
	defer delete(row_buffer)
	for i in 0..<d.component_count {
		buffers[i] = row_buffer[i * (width + 8):][:width + 8]
	}
	colsum := make([]i16, width + 16) or_return
	defer delete(colsum)

	#no_bounds_check for y in 0..<height {
		for i in 0..<d.component_count {
			rows[i] = upsample_row(d, &d.components[i], y, buffers[i], colsum, width)
		}
		out := img.pixels[y * width * channels:][:width * channels]
		switch space {
		case .Gray:
			if gray_out {
				for x in 0..<width {
					out[x * channels] = rows[0][x]
				}
			} else {
				for x in 0..<width {
					g := rows[0][x]
					out[x * channels + 0] = g
					out[x * channels + 1] = g
					out[x * channels + 2] = g
				}
			}
		case .YCbCr:
			if channels == 4 {
				ycc_row(rows[0], rows[1], rows[2], out, width, 4)
				continue
			}
			ycc_row(rows[0], rows[1], rows[2], out, width, 3)
		case .RGB:
			for x in 0..<width {
				out[x * channels + 0] = rows[0][x]
				out[x * channels + 1] = rows[1][x]
				out[x * channels + 2] = rows[2][x]
			}
		case .CMYK:
			for x in 0..<width {
				k := i32(rows[3][x])
				out[x * channels + 0] = u8((i32(rows[0][x]) * k + 127) / 255)
				out[x * channels + 1] = u8((i32(rows[1][x]) * k + 127) / 255)
				out[x * channels + 2] = u8((i32(rows[2][x]) * k + 127) / 255)
			}
		case .YCCK:
			for x in 0..<width {
				luma := i32(rows[0][x])
				cb   := i32(rows[1][x]) - 128
				cr   := i32(rows[2][x]) - 128
				k    := i32(rows[3][x])
				r := clamp(luma + ((91881 * cr + 32768) >> 16), 0, 255)
				g := clamp(luma + ((-22554 * cb - 46802 * cr + 32768) >> 16), 0, 255)
				b := clamp(luma + ((116130 * cb + 32768) >> 16), 0, 255)
				out[x * channels + 0] = u8(((255 - r) * k + 127) / 255)
				out[x * channels + 1] = u8(((255 - g) * k + 127) / 255)
				out[x * channels + 2] = u8(((255 - b) * k + 127) / 255)
			}
		}
		if has_alpha {
			for x in 0..<width {
				out[x * channels + channels - 1] = 255
			}
		}
	}
	return nil
}

@(private="file")
get_info :: proc(img: ^Image) -> (info: ^image.JPEG_Info, err: Error) {
	if img.metadata == nil {
		info = new(image.JPEG_Info) or_return
		img.metadata = info
		return
	}
	return img.metadata.(^image.JPEG_Info), nil
}

@(private="file")
read_length :: proc(ctx: ^compress.Context) -> (length: int, err: Error) {
	length = int(compress.read_data(ctx, u16be) or_return) - 2
	if length < 0 {
		return 0, .Corrupt
	}
	return
}

@(private="file")
read_segment :: proc(ctx: ^compress.Context) -> (segment: []u8, err: Error) {
	length := read_length(ctx) or_return
	segment = make([]u8, length) or_return
	if read_err := compress.read_slice(ctx, segment); read_err != nil {
		delete(segment)
		return nil, read_err
	}
	return
}

@(private="file")
skip_segment :: proc(ctx: ^compress.Context) -> (err: Error) {
	length := read_length(ctx) or_return
	compress.skip(ctx, i64(length)) or_return
	return
}

@(private="file")
read_u16be :: #force_inline proc(b: []u8) -> u16be {
	return u16be(b[0]) << 8 | u16be(b[1])
}

@(private="file")
parse_app0 :: proc(d: ^Decoder, img: ^Image, segment: []u8, options: Options) -> (err: Error) {
	if len(segment) < 5 || segment[4] != 0 {
		return
	}
	ident := segment[:4]
	if slice.equal(ident, image.JFIF_Magic[:]) {
		d.jfif = true
		if .return_metadata not_in options || len(segment) < 14 {
			return
		}
		x_thumbnail := int(segment[12])
		y_thumbnail := int(segment[13])
		pixels      := x_thumbnail * y_thumbnail
		rest        := segment[14:]

		app0 := image.JFIF_APP0{
			version     = read_u16be(segment[5:]),
			units       = image.JFIF_Unit(segment[7]),
			x_density   = read_u16be(segment[8:]),
			y_density   = read_u16be(segment[10:]),
			x_thumbnail = u8(x_thumbnail),
			y_thumbnail = u8(y_thumbnail),
		}
		if pixels > 0 {
			if len(rest) >= pixels * 3 {
				app0.thumbnail = slice.clone(rest[:pixels * 3]) or_return
			} else if len(rest) >= pixels {
				app0.thumbnail = slice.clone(rest[:pixels]) or_return
				app0.greyscale_thumbnail = true
			}
		}
		info := get_info(img) or_return
		if previous, ok := info.jfif_app0.?; ok {
			delete(previous.thumbnail)
		}
		info.jfif_app0 = app0
	} else if slice.equal(ident, image.JFXX_Magic[:]) {
		if .return_metadata not_in options || len(segment) < 6 {
			return
		}
		app0 := image.JFXX_APP0{extension_code = image.JFXX_Extension_Code(segment[5])}
		#partial switch app0.extension_code {
		case .Thumbnail_JPEG:
			app0.thumbnail = slice.clone(segment[6:]) or_return
		case .Thumbnail_3_Byte_RGB:
			if len(segment) < 8 {
				return
			}
			app0.x_thumbnail = segment[6]
			app0.y_thumbnail = segment[7]
			size := int(app0.x_thumbnail) * int(app0.y_thumbnail) * 3
			if len(segment) - 8 < size {
				return
			}
			app0.thumbnail = slice.clone(segment[8:][:size]) or_return
		case:
			return
		}
		info := get_info(img) or_return
		if previous, ok := info.jfxx_app0.?; ok {
			delete(previous.thumbnail)
		}
		info.jfxx_app0 = app0
	}
	return
}

@(private="file")
parse_app1 :: proc(img: ^Image, segment: []u8) -> (err: Error) {
	if len(segment) < 6 || segment[4] != 0 || !slice.equal(segment[:4], image.Exif_Magic[:]) {
		return
	}
	info := get_info(img) or_return
	data := segment[6:]

	exif: image.Exif
	if len(data) >= 4 && data[0] == 'M' && data[1] == 'M' {
		if data[2] != 0 || data[3] != 42 {
			return
		}
		exif.byte_order = .big_endian
	} else if len(data) >= 4 && data[0] == 'I' && data[1] == 'I' {
		if data[2] != 42 || data[3] != 0 {
			return
		}
		exif.byte_order = .little_endian
	} else {
		return
	}
	exif.data = slice.clone(data) or_return
	append(&info.exif, exif) or_return
	return
}

@(private="file")
parse_app14 :: proc(d: ^Decoder, segment: []u8) {
	if len(segment) >= 12 && string(segment[:5]) == "Adobe" {
		d.adobe = true
		d.adobe_transform = segment[11]
	}
}

@(private="file")
parse_frame :: proc(d: ^Decoder, img: ^Image, marker: image.JPEG_Marker, options: Options) -> (err: Error) {
	ctx := d.ctx
	length     := read_length(ctx)               or_return
	precision  := compress.read_u8(ctx)          or_return
	height     := int(compress.read_data(ctx, u16be) or_return)
	width      := int(compress.read_data(ctx, u16be) or_return)
	components := int(compress.read_u8(ctx)      or_return)

	if .return_metadata in options {
		info := get_info(img) or_return
		info.frame_type = marker
	}

	if precision == 12 {
		return .Unsupported_12_Bit_Depth
	}
	if precision != 8 {
		return .Invalid_Frame_Bit_Depth_Combo
	}
	if width == 0 || height == 0 {
		return .Invalid_Image_Dimensions
	}
	if u128(width) * u128(height) > image.MAX_DIMENSIONS {
		return .Image_Dimensions_Too_Large
	}
	if components != 1 && components != 3 && components != 4 {
		return .Invalid_Number_Of_Channels
	}
	if length < 6 + 3 * components {
		return .Corrupt
	}

	d.hmax, d.vmax = 1, 1
	for i in 0..<components {
		c := &d.components[i]
		c.id = compress.read_u8(ctx) or_return
		sampling := compress.read_u8(ctx) or_return
		c.h = int(sampling >> 4)
		c.v = int(sampling & 15)
		c.quant_index = compress.read_u8(ctx) or_return
		if c.h < 1 || c.h > 4 || c.v < 1 || c.v > 4 {
			return .Invalid_Sampling_Factor
		}
		if c.quant_index > 3 {
			return .Invalid_Quantization_Table_Index
		}
		for j in 0..<i {
			if d.components[j].id == c.id {
				return .Invalid_Component
			}
		}
		d.hmax = max(d.hmax, c.h)
		d.vmax = max(d.vmax, c.v)
	}
	compress.skip(ctx, i64(length - 6 - 3 * components)) or_return

	d.component_count = components
	d.progressive     = marker == .SOF2
	d.mcux = (width  + 8 * d.hmax - 1) / (8 * d.hmax)
	d.mcuy = (height + 8 * d.vmax - 1) / (8 * d.vmax)
	for &c in d.components[:components] {
		c.width    = (width  * c.h + d.hmax - 1) / d.hmax
		c.height   = (height * c.v + d.vmax - 1) / d.vmax
		c.blocks_w = (c.width  + 7) / 8
		c.blocks_h = (c.height + 7) / 8
		c.stride   = d.mcux * c.h
		c.rows     = d.mcuy * c.v
		c.plane_stride = c.blocks_w * BLOCK_SIZE
	}

	img.width    = width
	img.height   = height
	img.depth    = 8
	img.channels = components
	return
}

@(private="file")
parse_scan :: proc(d: ^Decoder) -> (err: Error) {
	ctx := d.ctx
	length := read_length(ctx)              or_return
	count  := int(compress.read_u8(ctx)     or_return)
	if count < 1 || count > d.component_count {
		return .Invalid_Number_Of_Channels
	}
	if length < 4 + 2 * count {
		return .Corrupt
	}

	storage: [MAX_COMPONENTS]^Component
	scan := storage[:count]
	for i in 0..<count {
		id     := compress.read_u8(ctx) or_return
		tables := compress.read_u8(ctx) or_return
		for &c in d.components[:d.component_count] {
			if c.id == id {
				scan[i] = &c
			}
		}
		if scan[i] == nil {
			return .Invalid_Component
		}
		for j in 0..<i {
			if scan[j] == scan[i] {
				return .Invalid_Component
			}
		}
		scan[i].dc_table = tables >> 4
		scan[i].ac_table = tables & 15
		if scan[i].dc_table > 3 || scan[i].ac_table > 3 {
			return .Invalid_Huffman_Table_Index
		}
	}
	ss := int(compress.read_u8(ctx) or_return)
	se := int(compress.read_u8(ctx) or_return)
	a  := compress.read_u8(ctx) or_return
	ah := int(a >> 4)
	al := int(a & 15)
	compress.skip(ctx, i64(length - 4 - 2 * count)) or_return

	if d.progressive {
		if ss == 0 && se != 0 {
			return .Invalid_Scan_Parameters
		}
		if ss > 0 && (count != 1 || se < ss || se > 63) {
			return .Invalid_Scan_Parameters
		}
		if ah > 13 || al > 13 {
			return .Invalid_Scan_Parameters
		}
	} else {
		ss, se, ah, al = 0, 63, 0, 0
	}

	if count > 1 {
		blocks := 0
		for c in scan {
			blocks += c.h * c.v
		}
		if blocks > 10 {
			return .Invalid_Scan_Parameters
		}
	}

	needs_dc := !d.progressive || (ss == 0 && ah == 0)
	needs_ac := !d.progressive || ss > 0
	for c in scan {
		if needs_dc && !d.huffman[0][c.dc_table].defined {
			return .Missing_Huffman_Table
		}
		if needs_ac && !d.huffman[1][c.ac_table].defined {
			return .Missing_Huffman_Table
		}
		if !c.quant_latched {
			if !d.quant_defined[c.quant_index] {
				return .Missing_Quantization_Table
			}
			c.quant = d.quant[c.quant_index]
			c.quant_latched = true
		}
	}

	for &c in d.components[:d.component_count] {
		if d.progressive && c.coefficients == nil {
			c.coefficients = make([]i16, c.stride * c.rows * COEFFICIENT_COUNT) or_return
		}
		if !d.progressive && c.plane == nil {
			c.plane = make([]u8, c.plane_stride * c.blocks_h * BLOCK_SIZE) or_return
		}
	}

	decode_scan(d, scan, ss, se, ah, al) or_return
	d.scans += 1
	return
}

@(private="file")
parse_quantization :: proc(d: ^Decoder) -> (err: Error) {
	ctx := d.ctx
	length := read_length(ctx) or_return
	for length > 0 {
		pq_tq := compress.read_u8(ctx) or_return
		precision := int(pq_tq >> 4)
		index     := pq_tq & 15
		if precision > 1 {
			return .Invalid_Quantization_Table_Precision
		}
		if index > 3 {
			return .Invalid_Quantization_Table_Index
		}
		size := 1 + COEFFICIENT_COUNT * (precision + 1)
		if length < size {
			return .Corrupt
		}
		if precision == 1 {
			table: [COEFFICIENT_COUNT]u16be
			compress.read_slice(ctx, slice.to_bytes(table[:])) or_return
			for v, k in table {
				d.quant[index][zigzag[k]] = u16(v)
			}
		} else {
			table: [COEFFICIENT_COUNT]u8
			compress.read_slice(ctx, table[:]) or_return
			for v, k in table {
				d.quant[index][zigzag[k]] = u16(v)
			}
		}
		d.quant_defined[index] = true
		length -= size
	}
	return
}

@(private="file")
parse_huffman :: proc(d: ^Decoder) -> (err: Error) {
	ctx := d.ctx
	length := read_length(ctx) or_return
	for length > 0 {
		if length < 17 {
			return .Corrupt
		}
		tc_th := compress.read_u8(ctx) or_return
		class := tc_th >> 4
		index := tc_th & 15
		if class > 1 {
			return .Invalid_Huffman_Coefficient_Type
		}
		if index > 3 {
			return .Invalid_Huffman_Table_Index
		}

		lengths: [16]u8
		compress.read_slice(ctx, lengths[:]) or_return
		counts: [17]i32
		total := 0
		for n, i in lengths {
			counts[i + 1] = i32(n)
			total += int(n)
		}
		if total > 256 {
			return .Huffman_Symbols_Exceeds_Max
		}
		if length < 17 + total {
			return .Corrupt
		}
		symbols: [256]u8
		compress.read_slice(ctx, symbols[:total]) or_return
		if !build_huffman(&d.huffman[class][index], counts, symbols[:total]) {
			return .Invalid_Huffman_Table
		}
		length -= 17 + total
	}
	return
}

@(init, private)
_register :: proc "contextless" () {
	image.register(.JPEG, load_from_bytes, destroy, load_from_context)
}
