// Reader and writer for `JPEG` images.
//
// Loading supports baseline, extended sequential and progressive encoding,
// as well as 12-bit DCT, lossless (SOF3), DNL and 2-component (gray + alpha) images,
// arithmetic coding (SOF9-11, DAC), and hierarchical mode (DHP, EXP, SOF5-7, SOF13-15),
// decoded at full resolution.
//
// Saving writes 8-bit baseline, extended sequential and progressive JPEG
// (standard or optimized Huffman tables, optional restart intervals),
// as greyscale, greyscale + alpha, YCbCr (4:4:4, 4:2:2 or 4:2:0), RGB, CMYK or YCCK,
// with a JFIF or Adobe header.
//
// 16-bit input saves as 12-bit extended sequential or progressive JPEG.
// Lossless (SOF3) saving writes 8- or 16-bit greyscale, greyscale + alpha, RGB or CMYK,
// using any of the seven predictors or the best one per image.
// Arithmetic coding (SOF9-11, default conditioning) is available for all but baseline.
package jpeg

import "base:intrinsics"
import "core:compress"
import "core:image"
import "core:io"
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
			delete(c.plane16)
		}
		for &r in d.references {
			delete(r.plane)
		}
		free(d)
	}
	d.ctx      = ctx
	d.arith_u  = 1
	d.arith_kx = 5

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
		case .SOF0, .SOF1, .SOF2, .SOF3, .SOF5, .SOF6, .SOF7, .SOF9, .SOF10, .SOF11, .SOF13, .SOF14, .SOF15:
			if frame_seen && !d.hierarchical {
				return img, .Multiple_SOS_Markers
			}
			finish_frame(d) or_return
			parse_frame(d, img, marker, options) or_return
			set_color_space(d, img, options) or_return
			frame_seen = true
			if .do_not_decompress_image in options {
				if d.hierarchical {
					img.width    = d.final_width
					img.height   = d.final_height
					img.channels = d.reference_count
				}
				if .return_metadata not_in options {
					return img, nil
				}
			}
		case .DHP:
			if frame_seen || d.hierarchical {
				return img, .Corrupt
			}
			parse_hierarchy(d) or_return
		case .EXP:
			if !d.hierarchical {
				return img, .Corrupt
			}
			parse_expand(d) or_return
		case .DAC:
			parse_arithmetic_conditioning(d) or_return
		case .SOS:
			if !frame_seen {
				return img, .Encountered_SOS_Before_SOF
			}
			if .do_not_decompress_image in options {
				set_color_space(d, img, options) or_return
				return img, nil
			}
			parse_scan(d, img) or_return
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
	if d.hierarchical {
		finish_frame(d) or_return
		finish_hierarchy(d, img) or_return
	}
	set_color_space(d, img, options) or_return
	produce_image(d, img, options) or_return
	return img, nil
}

@(private="file")
set_color_space :: proc(d: ^Decoder, img: ^Image, options: Options) -> (err: Error) {
	space := color_space(d)
	if .return_metadata in options || space == .CMYK || space == .YCCK {
		info := get_info(img) or_return
		info.color_space = space
	}
	return nil
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
		d.bits  |= next_byte(d) << (56 - d.count)
		d.count += 8
	}
}

@(private="file")
next_byte :: #force_inline proc(d: ^Decoder) -> u64 #no_bounds_check {
	z := d.ctx
	for !d.stopped {
		if len(z.window) < 2 {
			compress.refill_window(z, 2)
		}
		if len(z.window) == 0 {
			d.stopped = true
			break
		}
		b := z.window[0]
		if b != 0xFF {
			z.window = z.window[1:]
			return u64(b)
		}
		if len(z.window) == 1 {
			z.window = z.window[1:]
			d.stopped = true
			break
		}
		switch z.window[1] {
		case 0x00:
			z.window = z.window[2:]
			return 0xFF
		case 0xFF:
			z.window = z.window[1:]
		case:
			d.stopped = true
		}
	}
	return 0
}

@(private="file")
arith_fill :: proc(d: ^Decoder) #no_bounds_check {
	z := d.ctx
	for d.arith_ct <= 24 {
		b: u64
		if !d.stopped && len(z.window) > 0 && z.window[0] != 0xFF {
			b = u64(z.window[0])
			z.window = z.window[1:]
		} else {
			b = next_byte(d)
		}
		d.arith_c  |= b << (24 - d.arith_ct)
		d.arith_ct += 8
	}
}

@(private="file")
arith_reset :: proc(d: ^Decoder, scan: []^Component) {
	for c in scan {
		d.dc_stats[c.dc_table] = {}
		d.ac_stats[c.ac_table] = {}
		c.dc_context = 0
	}
	d.arith_c  = 0
	d.arith_ct = 0
	arith_fill(d)
	d.arith_c  <<= 16
	d.arith_ct  -= 16
	d.arith_a    = 0x10000
}

@(private="file")
arith_decode :: #force_inline proc(d: ^Decoder, st: ^u8) -> int #no_bounds_check {
	s   := st^
	e   := ARITH_STATES[s]
	a   := d.arith_a - e.qe
	bit := int(s >> 7)
	if u32(d.arith_c >> 32) < a {
		if a >= 0x8000 {
			d.arith_a = a
			return bit
		}
		if a < e.qe {
			bit ~= 1
			st^ = e.lps
		} else {
			st^ = e.mps
		}
	} else {
		d.arith_c -= u64(a) << 32
		if a < e.qe {
			st^ = e.mps
		} else {
			bit ~= 1
			st^ = e.lps
		}
		a = e.qe
	}
	shift := intrinsics.count_leading_zeros(a) - 16
	if d.arith_ct < shift {
		arith_fill(d)
	}
	d.arith_c  <<= shift
	d.arith_ct  -= shift
	d.arith_a    = a << shift
	return bit
}

@(private="file")
arith_decode_fixed :: #force_inline proc(d: ^Decoder) -> int {
	st: u8
	return arith_decode(d, &st)
}

@(private="file")
arith_bounds :: #force_inline proc(d: ^Decoder, table: u8) -> (lower, upper: i32) {
	l := d.arith_l[table]
	if l > 0 {
		lower = i32(1) << (l - 1)
	}
	upper = i32(1) << d.arith_u[table]
	return
}

@(private="file")
arith_category :: #force_inline proc(v, lower, upper: i32) -> int {
	m := abs(v)
	if m <= lower {
		return 0
	}
	return (1 if m <= upper else 3) + int(v < 0)
}

@(private="file")
arith_magnitude :: #force_inline proc(d: ^Decoder, stats: []u8, x2: int) -> (sz: i32, ok: bool) #no_bounds_check {
	m  := i32(2)
	st := x2
	for arith_decode(d, &stats[st]) != 0 {
		m <<= 1
		st += 1
		if st == x2 + 14 {
			return 0, false
		}
	}
	st += 14
	sz = m
	for bit := m >> 1; bit != 0; bit >>= 1 {
		if arith_decode(d, &stats[st]) != 0 {
			sz |= bit
		}
	}
	return sz, true
}

@(private="file")
arith_decode_difference :: #force_inline proc(d: ^Decoder, stats: []u8, s0, x1: int) -> (v: i32, ok: bool) #no_bounds_check {
	if arith_decode(d, &stats[s0]) == 0 {
		return 0, true
	}
	sign := arith_decode(d, &stats[s0 + 1])
	sz: i32
	if arith_decode(d, &stats[s0 + 2 + sign]) != 0 {
		sz = 1
		if arith_decode(d, &stats[x1]) != 0 {
			sz = arith_magnitude(d, stats, x1 + 1) or_return
		}
	}
	v = sz + 1
	return -v if sign != 0 else v, true
}

@(private="file")
arith_decode_dc :: #force_inline proc(d: ^Decoder, c: ^Component) -> (diff: i32, ok: bool) {
	diff = arith_decode_difference(d, d.dc_stats[c.dc_table][:], c.dc_context, 20) or_return
	lower, upper := arith_bounds(d, c.dc_table)
	c.dc_context = 4 * arith_category(diff, lower, upper)
	return diff, true
}

@(private="file")
arith_decode_ac_first :: proc(d: ^Decoder, c: ^Component, block: []i16, ss, se: int, al: u32) -> bool #no_bounds_check {
	stats := d.ac_stats[c.ac_table][:]
	kx    := int(d.arith_kx[c.ac_table])
	for k := ss; k <= se; k += 1 {
		st := 3 * (k - 1)
		if arith_decode(d, &stats[st]) != 0 {
			break
		}
		for arith_decode(d, &stats[st + 1]) == 0 {
			k  += 1
			st += 3
			if k > se {
				return false
			}
		}
		sign := arith_decode_fixed(d)
		sz: i32
		if arith_decode(d, &stats[st + 2]) != 0 {
			sz = 1
			if arith_decode(d, &stats[st + 2]) != 0 {
				ok: bool
				sz, ok = arith_magnitude(d, stats, 189 if k <= kx else 217)
				if !ok {
					return false
				}
			}
		}
		v := sz + 1
		if sign != 0 {
			v = -v
		}
		block[zigzag[k]] = i16(v * (i32(1) << al))
	}
	return true
}

@(private="file")
arith_decode_ac_refine :: proc(d: ^Decoder, c: ^Component, block: []i16, ss, se: int, al: u32) -> bool #no_bounds_check {
	stats := d.ac_stats[c.ac_table][:]
	p1 := i16(1) << al
	m1 := -p1
	eob := ss
	if mask := nonzero_mask(block) & span(ss, se); mask != 0 {
		eob = 64 - int(intrinsics.count_leading_zeros(mask))
	}
	for k := ss; k <= se; k += 1 {
		st := 3 * (k - 1)
		if k >= eob && arith_decode(d, &stats[st]) != 0 {
			break
		}
		for {
			coefficient := &block[zigzag[k]]
			if coefficient^ != 0 {
				if arith_decode(d, &stats[st + 2]) != 0 {
					coefficient^ += m1 if coefficient^ < 0 else p1
				}
				break
			}
			if arith_decode(d, &stats[st + 1]) != 0 {
				coefficient^ = m1 if arith_decode_fixed(d) != 0 else p1
				break
			}
			k  += 1
			st += 3
			if k > se {
				return false
			}
		}
	}
	return true
}

@(private="file")
decode_block_arith :: proc(d: ^Decoder, c: ^Component, block: []i16, ss, se, ah, al: int) -> bool #no_bounds_check {
	if ss == 0 {
		if ah == 0 {
			diff, ok := arith_decode_dc(d, c)
			if !ok {
				return false
			}
			c.dc_pred += diff
			block[0] = i16(c.dc_pred * (i32(1) << u32(al)))
		} else if arith_decode_fixed(d) != 0 {
			block[0] |= i16(1) << u32(al)
		}
		if d.progressive {
			return true
		}
		return arith_decode_ac_first(d, c, block, 1, 63, 0)
	}
	if ah == 0 {
		return arith_decode_ac_first(d, c, block, ss, se, u32(al))
	}
	return arith_decode_ac_refine(d, c, block, ss, se, u32(al))
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
	if t < 0 || t > d.dc_limit {
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
	if t < 0 || t > d.dc_limit {
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
	if d.arithmetic {
		arith_reset(d, scan)
	}
}

@(private="file")
decode_block_at :: #force_inline proc(d: ^Decoder, c: ^Component, bx, by: int, local: []i16, ss, se, ah, al: int) -> (err: Error) #no_bounds_check {
	if d.differential {
		c.dc_pred = 0
	}
	if d.progressive {
		block := c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT:][:COEFFICIENT_COUNT]
		ok := decode_block_arith(d, c, block, ss, se, ah, al) if d.arithmetic else decode_block(d, c, block, ss, se, ah, al)
		if !ok {
			return .Corrupt
		}
		return nil
	}
	intrinsics.mem_zero(raw_data(local), COEFFICIENT_COUNT * size_of(i16))
	ok := decode_block_arith(d, c, local, 0, 63, 0, 0) if d.arithmetic else decode_block_sequential(d, c, local)
	if !ok {
		return .Corrupt
	}
	if bx < c.blocks_w && by < c.blocks_h {
		if d.wide {
			center, maxval, flip := idct_wide_parameters(d)
			idct_block_wide(local, &c.quant, c.plane16[by * BLOCK_SIZE * c.plane_stride + bx * BLOCK_SIZE:], c.plane_stride, center, maxval, flip)
		} else {
			idct_block(local, &c.quant, c.plane[by * BLOCK_SIZE * c.plane_stride + bx * BLOCK_SIZE:], c.plane_stride)
		}
	}
	return nil
}

@(private="file")
decode_difference :: #force_inline proc(d: ^Decoder, t: ^Huffman_Table) -> (difference: u16, ok: bool) #no_bounds_check {
	if d.count < 32 {
		fill_bits(d)
	}
	s: u32
	entry := t.lookup[d.bits >> (64 - HUFFMAN_LOOKAHEAD)]
	if entry != 0 {
		length := u32(entry >> 8)
		d.bits <<= length
		d.count -= length
		s = u32(entry & 0xFF)
	} else {
		symbol := decode_huffman(d, t)
		if symbol < 0 {
			return 0, false
		}
		s = u32(symbol)
	}
	if s == 0 {
		return 0, true
	}
	if s >= LOSSLESS_DIFFERENCE_32768 {
		return 32768, s == LOSSLESS_DIFFERENCE_32768
	}
	v := i32(d.bits >> (64 - s))
	d.bits <<= s
	d.count -= s
	if v < i32(1) << (s - 1) {
		v += 1 - (i32(1) << s)
	}
	return u16(v), true
}

@(private="file")
undifference_row :: #force_inline proc(c: ^Component, y, width: int, reset: bool, predictor: int, initial: u16) #no_bounds_check {
	stride := c.plane_stride
	row    := c.plane16[y * stride:][:width]
	if reset {
		row[0] += initial
		for x in 1..<width {
			row[x] += row[x - 1]
		}
		return
	}
	above := c.plane16[(y - 1) * stride:][:width]
	row[0] += above[0]
	switch predictor {
	case 1:
		for x in 1..<width {
			row[x] += row[x - 1]
		}
	case 2:
		for x in 1..<width {
			row[x] += above[x]
		}
	case 3:
		for x in 1..<width {
			row[x] += above[x - 1]
		}
	case 4:
		for x in 1..<width {
			row[x] += row[x - 1] + above[x] - above[x - 1]
		}
	case 5:
		for x in 1..<width {
			row[x] += u16(i32(row[x - 1]) + ((i32(above[x]) - i32(above[x - 1])) >> 1))
		}
	case 6:
		for x in 1..<width {
			row[x] += u16(i32(above[x]) + ((i32(row[x - 1]) - i32(above[x - 1])) >> 1))
		}
	case 7:
		for x in 1..<width {
			row[x] += u16((u32(row[x - 1]) + u32(above[x])) >> 1)
		}
	}
}

@(private="file")
scale_lossless_row :: #force_inline proc(c: ^Component, y, width, pt: int, maxval: u16) #no_bounds_check {
	row := c.plane16[y * c.plane_stride:][:width]
	x := 0
	if pt == 0 {
		top: #simd[8]u16 = maxval
		for ; x + 8 <= width; x += 8 {
			v := intrinsics.unaligned_load((^#simd[8]u16)(&row[x]))
			intrinsics.unaligned_store((^#simd[8]u16)(&row[x]), intrinsics.simd_min(v, top))
		}
	}
	for ; x < width; x += 1 {
		row[x] = u16(min(u32(row[x]) << u32(pt), u32(maxval)))
	}
}

@(private="file")
finish_lossless_row :: #force_inline proc(c: ^Component, y, interval_rows: int, l: Lossless_Rows) {
	if y >= c.height {
		return
	}
	if l.differential {
		if l.pt > 0 {
			for &v in c.plane16[y * c.plane_stride:][:c.width] {
				v <<= u32(l.pt)
			}
		}
		return
	}
	reset := y == 0 || (interval_rows > 0 && y % interval_rows == 0)
	undifference_row(c, y, c.width, reset, l.predictor, l.initial)
	if l.needs_scale && y > 0 {
		scale_lossless_row(c, y - 1, c.width, l.pt, l.maxval)
	}
	if l.needs_scale && y == c.height - 1 {
		scale_lossless_row(c, y, c.width, l.pt, l.maxval)
	}
}

@(private="file")
decode_scan_lossless :: proc(d: ^Decoder, scan: []^Component, predictor, pt: int) -> (err: Error) #no_bounds_check {
	d.bits    = 0
	d.count   = 0
	d.stopped = false

	l := Lossless_Rows{
		predictor    = predictor,
		pt           = pt,
		initial      = u16(1) << u32(d.precision - pt - 1),
		maxval       = u16(u32(1) << u32(d.precision) - 1),
		needs_scale  = pt > 0 || d.precision < 16,
		differential = d.differential,
	}
	ri := d.restart_interval

	if d.arithmetic {
		return decode_scan_lossless_arith(d, scan, l)
	}

	if len(scan) == 1 {
		c := scan[0]
		t := &d.huffman[0][c.dc_table]
		interval_rows := ri / c.width
		for y in 0..<c.height {
			if ri > 0 && y > 0 && y % interval_rows == 0 {
				handle_restart(d, scan)
			}
			row := c.plane16[y * c.plane_stride:][:c.width]
			for x in 0..<c.width {
				ok: bool
				row[x], ok = decode_difference(d, t)
				if !ok {
					return .Corrupt
				}
			}
			finish_lossless_row(c, y, interval_rows, l)
		}
		return nil
	}

	tables: [MAX_COMPONENTS]^Huffman_Table
	unit := true
	for c, i in scan {
		tables[i] = &d.huffman[0][c.dc_table]
		unit &&= c.h == 1 && c.v == 1
	}
	mcu_rows := ri / d.mcux
	for my in 0..<d.mcuy {
		if ri > 0 && my > 0 && my % mcu_rows == 0 {
			handle_restart(d, scan)
		}
		if unit {
			rows: [MAX_COMPONENTS][]u16
			for c, i in scan {
				rows[i] = c.plane16[my * c.plane_stride:][:d.mcux]
			}
			for mx in 0..<d.mcux {
				for i in 0..<len(scan) {
					ok: bool
					rows[i][mx], ok = decode_difference(d, tables[i])
					if !ok {
						return .Corrupt
					}
				}
			}
		} else {
			for mx in 0..<d.mcux {
				for c, i in scan {
					for v in 0..<c.v {
						row := c.plane16[(my * c.v + v) * c.plane_stride + mx * c.h:][:c.h]
						for h in 0..<c.h {
							ok: bool
							row[h], ok = decode_difference(d, tables[i])
							if !ok {
								return .Corrupt
							}
						}
					}
				}
			}
		}
		for c in scan {
			for v in 0..<c.v {
				finish_lossless_row(c, my * c.v + v, mcu_rows * c.v, l)
			}
		}
	}
	return nil
}

@(private="file")
decode_scan_lossless_arith :: proc(d: ^Decoder, scan: []^Component, l: Lossless_Rows) -> (err: Error) #no_bounds_check {
	ri := d.restart_interval

	widths: [MAX_COMPONENTS]int
	lines:  [MAX_COMPONENTS]int
	total := 0
	for c, i in scan {
		widths[i] = c.width if len(scan) == 1 else d.mcux * c.h
		lines[i]  = 2 if len(scan) == 1 else c.v + 1
		total += widths[i] * lines[i]
	}
	buffer := non_zero_make([]u8, total) or_return
	defer delete(buffer)
	categories: [MAX_COMPONENTS][]u8
	offset := 0
	for i in 0..<len(scan) {
		categories[i] = buffer[offset:][:widths[i] * lines[i]]
		offset += widths[i] * lines[i]
	}

	arith_reset(d, scan)

	if len(scan) == 1 {
		c := scan[0]
		stats := d.dc_stats[c.dc_table][:]
		lower, upper := arith_bounds(d, c.dc_table)
		width := c.width
		interval_rows := ri / width
		first := 0
		for y in 0..<c.height {
			if ri > 0 && y > 0 && y % interval_rows == 0 {
				handle_restart(d, scan)
				first = y
			}
			row     := c.plane16[y * c.plane_stride:][:width]
			current := categories[0][(y & 1) * width:][:width]
			above   := categories[0][((y + 1) & 1) * width:][:width]
			left    := 0
			for x in 0..<width {
				up := 0 if y == first else int(above[x])
				v, ok := arith_decode_difference(d, stats, 20 * left + 4 * up, 100 if up <= 2 else 129)
				if !ok {
					return .Corrupt
				}
				row[x] = u16(v)
				left = arith_category(v, lower, upper)
				current[x] = u8(left)
			}
			finish_lossless_row(c, y, interval_rows, l)
		}
		return nil
	}

	lefts: [MAX_COMPONENTS][4]int
	mcu_rows := ri / d.mcux
	first_row := 0
	for my in 0..<d.mcuy {
		if ri > 0 && my > 0 && my % mcu_rows == 0 {
			handle_restart(d, scan)
			first_row = my
		}
		lefts = {}
		for mx in 0..<d.mcux {
			for c, i in scan {
				stats := d.dc_stats[c.dc_table][:]
				lower, upper := arith_bounds(d, c.dc_table)
				width := widths[i]
				for v in 0..<c.v {
					y       := my * c.v + v
					row     := c.plane16[y * c.plane_stride + mx * c.h:][:c.h]
					current := categories[i][(y % lines[i]) * width + mx * c.h:][:c.h]
					above   := categories[i][((y + lines[i] - 1) % lines[i]) * width + mx * c.h:][:c.h]
					top     := my == first_row && v == 0
					for h in 0..<c.h {
						up := 0 if top else int(above[h])
						left := lefts[i][v]
						value, ok := arith_decode_difference(d, stats, 20 * left + 4 * up, 100 if up <= 2 else 129)
						if !ok {
							return .Corrupt
						}
						row[h] = u16(value)
						category := arith_category(value, lower, upper)
						lefts[i][v] = category
						current[h] = u8(category)
					}
				}
			}
		}
		for c in scan {
			for v in 0..<c.v {
				finish_lossless_row(c, my * c.v + v, mcu_rows * c.v, l)
			}
		}
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
	if d.arithmetic {
		arith_reset(d, scan)
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
transpose :: #force_inline proc(r: [8]$T) -> (c: [8]T) {
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
idct_pass_wide :: #force_inline proc(x: [8]F8) -> (y: [8]F8) #no_bounds_check {
	A  :: 0.353553391
	C1 :: 0.490392640
	C2 :: 0.461939766
	C3 :: 0.415734806
	C5 :: 0.277785117
	C6 :: 0.191341716
	C7 :: 0.097545161

	t0 := (x[0] + x[4]) * A
	t1 := (x[0] - x[4]) * A
	t2 := x[2] * C2 + x[6] * C6
	t3 := x[2] * C6 - x[6] * C2
	e0 := t0 + t2
	e1 := t1 + t3
	e2 := t1 - t3
	e3 := t0 - t2
	o0 := x[1] * C1 + x[3] * C3 + x[5] * C5 + x[7] * C7
	o1 := x[1] * C3 - x[3] * C7 - x[5] * C1 - x[7] * C5
	o2 := x[1] * C5 - x[3] * C1 + x[5] * C7 + x[7] * C3
	o3 := x[1] * C7 - x[3] * C5 + x[5] * C3 - x[7] * C1
	y[0] = e0 + o0
	y[7] = e0 - o0
	y[1] = e1 + o1
	y[6] = e1 - o1
	y[2] = e2 + o2
	y[5] = e2 - o2
	y[3] = e3 + o3
	y[4] = e3 - o3
	return
}

@(private="file")
idct_wide_parameters :: #force_inline proc(d: ^Decoder) -> (center, maxval: f32, flip: u16) {
	if d.differential {
		return 32768.5, 65535, 0x8000
	}
	return f32(int(1) << u32(d.precision - 1)) + 0.5, f32(int(1) << u32(d.precision) - 1), 0
}

@(private="file")
idct_block_wide :: proc(coefficients: []i16, quant: ^[COEFFICIENT_COUNT]u16, output: []u16, stride: int, center_value, maxval_value: f32, flip_value: u16) #no_bounds_check {
	center: F8 = center_value
	maxval: F8 = maxval_value
	flip: #simd[8]u16 = flip_value

	ac_mask := #simd[8]i16{0, -1, -1, -1, -1, -1, -1, -1}
	ac: #simd[8]i16
	x: [8]F8
	for i in 0..<BLOCK_SIZE {
		c := intrinsics.unaligned_load((^#simd[8]i16)(&coefficients[i * 8]))
		q := intrinsics.unaligned_load((^#simd[8]u16)(&quant[i * 8]))
		ac |= c & ac_mask
		ac_mask = -1
		x[i] = cast(F8)c * cast(F8)q
	}

	if intrinsics.simd_reduce_or(ac) == 0 {
		dc := intrinsics.simd_clamp(F8(f32(coefficients[0]) * f32(quant[0]) * 0.125) + center, 0, maxval)
		v  := cast(#simd[8]u16)cast(#simd[8]i32)dc ~ flip
		for row in 0..<BLOCK_SIZE {
			intrinsics.unaligned_store((^#simd[8]u16)(&output[row * stride]), v)
		}
		return
	}

	y := idct_pass_wide(x)
	y  = transpose(y)
	y  = idct_pass_wide(y)
	y  = transpose(y)

	for row in 0..<BLOCK_SIZE {
		v := intrinsics.simd_clamp(y[row] + center, 0, maxval)
		intrinsics.unaligned_store((^#simd[8]u16)(&output[row * stride]), cast(#simd[8]u16)cast(#simd[8]i32)v ~ flip)
	}
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
upsample_row16 :: proc(d: ^Decoder, c: ^Component, y: int, output: []u16, colsum: []u32, width: int) -> []u16 #no_bounds_check {
	plane := c.plane16
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

	case d.lossless:
		row := plane[(y / vr) * ps:]
		for x in 0..<width {
			output[x] = row[x / hr]
		}

	case hr == 2 && vr == 1:
		row := plane[y * ps:]
		n   := c.width
		if n == 1 {
			output[0] = row[0]
			output[1] = row[0]
			return output
		}
		output[0] = row[0]
		output[1] = u16((3 * u32(row[0]) + u32(row[1]) + 2) >> 2)
		for i in 1..<n - 1 {
			s := 3 * u32(row[i])
			output[2 * i]     = u16((s + u32(row[i - 1]) + 1) >> 2)
			output[2 * i + 1] = u16((s + u32(row[i + 1]) + 2) >> 2)
		}
		output[2 * n - 2] = u16((3 * u32(row[n - 1]) + u32(row[n - 2]) + 1) >> 2)
		output[2 * n - 1] = row[n - 1]

	case hr == 1 && vr == 2:
		j    := y >> 1
		far  := clamp(j - 1 if y & 1 == 0 else j + 1, 0, c.height - 1)
		bias := u32(1 if y & 1 == 0 else 2)
		near_row := plane[j * ps:][:width]
		far_row  := plane[far * ps:][:width]
		for x in 0..<width {
			output[x] = u16((3 * u32(near_row[x]) + u32(far_row[x]) + bias) >> 2)
		}

	case hr == 2 && vr == 2:
		j   := y >> 1
		far := clamp(j - 1 if y & 1 == 0 else j + 1, 0, c.height - 1)
		n   := c.width
		near_row := plane[j * ps:][:n]
		far_row  := plane[far * ps:][:n]
		sums     := colsum[:n + 2]
		for i in 0..<n {
			sums[i + 1] = 3 * u32(near_row[i]) + u32(far_row[i])
		}
		sums[0]     = sums[1]
		sums[n + 1] = sums[n]
		for i in 0..<n {
			current := 3 * sums[i + 1]
			output[2 * i]     = u16((current + sums[i]     + 8) >> 4)
			output[2 * i + 1] = u16((current + sums[i + 2] + 7) >> 4)
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
	count := d.component_count
	ids   := [3]u8{d.components[0].id, d.components[1].id, d.components[2].id}
	if d.hierarchical {
		count = d.reference_count
		ids   = {d.references[0].id, d.references[1].id, d.references[2].id}
	}
	switch count {
	case 1:
		return .Gray
	case 2:
		return .Gray_Alpha
	case 3:
		if d.adobe {
			return .RGB if d.adobe_transform == 0 else .YCbCr
		}
		if d.jfif {
			return .YCbCr
		}
		if ids == {'R', 'G', 'B'} {
			return .RGB
		}
		if d.lossless {
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
output_layout :: proc(d: ^Decoder, options: Options) -> (space: Color_Space, gray_out, has_alpha, premultiply: bool, channels: int) {
	space     = color_space(d)
	if space == .CMYK || space == .YCCK {
		return space, false, false, false, 4
	}
	gray      := space == .Gray || space == .Gray_Alpha
	gray_out   = gray && (.do_not_expand_grayscale in options || .do_not_expand_channels in options)
	has_alpha  = .alpha_add_if_missing in options
	if space == .Gray_Alpha {
		has_alpha   = gray_out || .alpha_drop_if_present not_in options
		premultiply = !gray_out && .alpha_premultiply in options
	}
	channels = 1 if gray_out else 3
	if has_alpha {
		channels += 1
	}
	return
}

@(private="file")
produce_image :: proc(d: ^Decoder, img: ^Image, options: Options) -> (err: Error) {
	if d.wide {
		return produce_image_wide(d, img, options)
	}
	for &c in d.components[:d.component_count] {
		if c.coefficients == nil {
			if c.plane == nil {
				return .Missing_Image_Data
			}
			continue
		}
		c.plane = non_zero_make([]u8, c.plane_stride * c.blocks_h * BLOCK_SIZE) or_return
		for by in 0..<c.blocks_h {
			for bx in 0..<c.blocks_w {
				block := c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT:][:COEFFICIENT_COUNT]
				idct_block(block, &c.quant, c.plane[by * BLOCK_SIZE * c.plane_stride + bx * BLOCK_SIZE:], c.plane_stride)
			}
		}
		delete(c.coefficients)
		c.coefficients = nil
	}

	space, gray_out, has_alpha, premultiply, channels := output_layout(d, options)

	width, height := img.width, img.height
	non_zero_resize(&img.pixels, width * height * channels) or_return
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
		case .Gray_Alpha:
			for x in 0..<width {
				g := rows[0][x]
				a := rows[1][x]
				if gray_out {
					out[x * 2 + 0] = g
					out[x * 2 + 1] = a
					continue
				}
				if premultiply {
					g = u8((u32(g) * u32(a) + 127) / 255)
				}
				out[x * channels + 0] = g
				out[x * channels + 1] = g
				out[x * channels + 2] = g
				if has_alpha {
					out[x * channels + 3] = a
				}
			}
			continue
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
				out[x * 4 + 0] = rows[0][x]
				out[x * 4 + 1] = rows[1][x]
				out[x * 4 + 2] = rows[2][x]
				out[x * 4 + 3] = rows[3][x]
			}
		case .YCCK:
			for x in 0..<width {
				luma := i32(rows[0][x])
				cb   := i32(rows[1][x]) - 128
				cr   := i32(rows[2][x]) - 128
				out[x * 4 + 0] = u8(255 - clamp(luma + ((91881 * cr + 32768) >> 16), 0, 255))
				out[x * 4 + 1] = u8(255 - clamp(luma + ((-22554 * cb - 46802 * cr + 32768) >> 16), 0, 255))
				out[x * 4 + 2] = u8(255 - clamp(luma + ((116130 * cb + 32768) >> 16), 0, 255))
				out[x * 4 + 3] = rows[3][x]
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
replicate_bits :: proc(v: u32, from, to: int) -> (out: u32) {
	bits := to
	for bits > 0 {
		if bits >= from {
			out  |= v << u32(bits - from)
			bits -= from
		} else {
			out  |= v >> u32(from - bits)
			bits  = 0
		}
	}
	return
}

@(private="file")
ycc_to_rgb_wide :: proc(luma, cb, cr: []u16, rgb: [3][]u16, center, maxval: i32) #no_bounds_check {
	I8 :: #simd[8]i32
	U8 :: #simd[8]u16
	width := len(luma)
	c:    I8 = center
	top:  I8 = maxval
	half: I8 = 32768
	sh:   #simd[8]u32 = 16
	x := 0
	for ; x + 8 <= width; x += 8 {
		l  := cast(I8)intrinsics.unaligned_load((^U8)(&luma[x]))
		vb := cast(I8)intrinsics.unaligned_load((^U8)(&cb[x])) - c
		vr := cast(I8)intrinsics.unaligned_load((^U8)(&cr[x])) - c
		r  := intrinsics.simd_clamp(l + intrinsics.simd_shr(91881 * vr + half, sh), 0, top)
		g  := intrinsics.simd_clamp(l + intrinsics.simd_shr(-22554 * vb - 46802 * vr + half, sh), 0, top)
		b  := intrinsics.simd_clamp(l + intrinsics.simd_shr(116130 * vb + half, sh), 0, top)
		intrinsics.unaligned_store((^U8)(&rgb[0][x]), cast(U8)r)
		intrinsics.unaligned_store((^U8)(&rgb[1][x]), cast(U8)g)
		intrinsics.unaligned_store((^U8)(&rgb[2][x]), cast(U8)b)
	}
	for ; x < width; x += 1 {
		l  := i32(luma[x])
		vb := i32(cb[x]) - center
		vr := i32(cr[x]) - center
		rgb[0][x] = u16(clamp(l + ((91881 * vr + 32768) >> 16), 0, maxval))
		rgb[1][x] = u16(clamp(l + ((-22554 * vb - 46802 * vr + 32768) >> 16), 0, maxval))
		rgb[2][x] = u16(clamp(l + ((116130 * vb + 32768) >> 16), 0, maxval))
	}
}

@(private="file")
store_rgb_wide :: proc(img: ^Image, y, channels: int, rgb: [3][]u16, scale: []u16, alpha: u16) #no_bounds_check {
	width := img.width
	r, g, b := rgb[0], rgb[1], rgb[2]
	if img.depth == 16 {
		out := slice.reinterpret([]u16, img.pixels[:])[y * width * channels:][:width * channels]
		if scale != nil {
			if channels == 4 {
				for x in 0..<width {
					out[x * 4 + 0] = scale[r[x]]
					out[x * 4 + 1] = scale[g[x]]
					out[x * 4 + 2] = scale[b[x]]
					out[x * 4 + 3] = scale[alpha]
				}
			} else {
				for x in 0..<width {
					out[x * 3 + 0] = scale[r[x]]
					out[x * 3 + 1] = scale[g[x]]
					out[x * 3 + 2] = scale[b[x]]
				}
			}
		} else {
			if channels == 4 {
				for x in 0..<width {
					out[x * 4 + 0] = r[x]
					out[x * 4 + 1] = g[x]
					out[x * 4 + 2] = b[x]
					out[x * 4 + 3] = alpha
				}
			} else {
				for x in 0..<width {
					out[x * 3 + 0] = r[x]
					out[x * 3 + 1] = g[x]
					out[x * 3 + 2] = b[x]
				}
			}
		}
		return
	}
	out := img.pixels[y * width * channels:][:width * channels]
	if scale != nil {
		for x in 0..<width {
			out[x * channels + 0] = u8(scale[r[x]])
			out[x * channels + 1] = u8(scale[g[x]])
			out[x * channels + 2] = u8(scale[b[x]])
			if channels == 4 {
				out[x * 4 + 3] = u8(scale[alpha])
			}
		}
	} else {
		for x in 0..<width {
			out[x * channels + 0] = u8(r[x])
			out[x * channels + 1] = u8(g[x])
			out[x * channels + 2] = u8(b[x])
			if channels == 4 {
				out[x * 4 + 3] = u8(alpha)
			}
		}
	}
}

@(private="file")
store_gray_wide :: proc(img: ^Image, y: int, gray: []u16, scale: []u16) #no_bounds_check {
	width := img.width
	if img.depth == 16 {
		out := slice.reinterpret([]u16, img.pixels[:])[y * width:][:width]
		if scale != nil {
			for x in 0..<width {
				out[x] = scale[gray[x]]
			}
		} else {
			copy(out, gray[:width])
		}
		return
	}
	out := img.pixels[y * width:][:width]
	if scale != nil {
		for x in 0..<width {
			out[x] = u8(scale[gray[x]])
		}
	} else {
		for x in 0..<width {
			out[x] = u8(gray[x])
		}
	}
}

@(private="file")
idct_coefficients_wide :: proc(d: ^Decoder) -> (err: Error) {
	center, maxval, flip := idct_wide_parameters(d)
	for &c in d.components[:d.component_count] {
		if c.coefficients == nil {
			if c.plane16 == nil {
				return .Missing_Image_Data
			}
			continue
		}
		c.plane16 = non_zero_make([]u16, c.plane_stride * c.blocks_h * BLOCK_SIZE) or_return
		for by in 0..<c.blocks_h {
			for bx in 0..<c.blocks_w {
				block := c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT:][:COEFFICIENT_COUNT]
				idct_block_wide(block, &c.quant, c.plane16[by * BLOCK_SIZE * c.plane_stride + bx * BLOCK_SIZE:], c.plane_stride, center, maxval, flip)
			}
		}
		delete(c.coefficients)
		c.coefficients = nil
	}
	return nil
}

@(private="file")
produce_image_wide :: proc(d: ^Decoder, img: ^Image, options: Options) -> (err: Error) {
	idct_coefficients_wide(d) or_return
	space, gray_out, has_alpha, premultiply, channels := output_layout(d, options)

	precision := d.precision
	depth     := 8 if precision <= 8 else 16
	maxval    := u32(1) << u32(precision) - 1
	center    := i64(1) << u32(precision - 1)

	scale: []u16
	if precision != depth && .do_not_expand_channels not_in options {
		scale = make([]u16, maxval + 1) or_return
		for &v, i in scale {
			v = u16(replicate_bits(u32(i), precision, depth))
		}
	}
	defer delete(scale)

	width, height := img.width, img.height
	non_zero_resize(&img.pixels, width * height * channels * depth / 8) or_return
	img.channels = channels
	img.depth    = depth

	row_buffer := make([]u16, (width + 8) * (d.component_count + 3) + width * channels) or_return
	defer delete(row_buffer)
	buffers: [MAX_COMPONENTS][]u16
	rows:    [MAX_COMPONENTS][]u16
	for i in 0..<d.component_count {
		buffers[i] = row_buffer[i * (width + 8):][:width + 8]
	}
	rgb: [3][]u16
	for i in 0..<3 {
		rgb[i] = row_buffer[(d.component_count + i) * (width + 8):][:width]
	}
	line := row_buffer[(d.component_count + 3) * (width + 8):][:width * channels]
	colsum := make([]u32, width + 16) or_return
	defer delete(colsum)

	pixels16 := slice.reinterpret([]u16, img.pixels[:])
	alpha    := u16(maxval)

	#no_bounds_check for y in 0..<height {
		for i in 0..<d.component_count {
			rows[i] = upsample_row16(d, &d.components[i], y, buffers[i], colsum, width)
		}
		#partial switch space {
		case .YCbCr:
			if precision <= 12 {
				ycc_to_rgb_wide(rows[0][:width], rows[1][:width], rows[2][:width], rgb, i32(center), i32(maxval))
				store_rgb_wide(img, y, channels, rgb, scale, alpha)
				continue
			}
		case .RGB:
			store_rgb_wide(img, y, channels, {rows[0][:width], rows[1][:width], rows[2][:width]}, scale, alpha)
			continue
		case .Gray:
			if gray_out && !has_alpha {
				store_gray_wide(img, y, rows[0][:width], scale)
				continue
			}
		}
		switch space {
		case .Gray:
			for x in 0..<width {
				g := rows[0][x]
				if gray_out {
					line[x * channels] = g
				} else {
					line[x * channels + 0] = g
					line[x * channels + 1] = g
					line[x * channels + 2] = g
				}
				if has_alpha {
					line[x * channels + channels - 1] = alpha
				}
			}
		case .Gray_Alpha:
			for x in 0..<width {
				g := rows[0][x]
				a := rows[1][x]
				if gray_out {
					line[x * 2 + 0] = g
					line[x * 2 + 1] = a
					continue
				}
				if premultiply {
					g = u16((u32(g) * u32(a) + maxval / 2) / maxval)
				}
				line[x * channels + 0] = g
				line[x * channels + 1] = g
				line[x * channels + 2] = g
				if has_alpha {
					line[x * channels + 3] = a
				}
			}
		case .YCbCr:
			top := i64(maxval)
			for x in 0..<width {
				luma := i64(rows[0][x])
				cb   := i64(rows[1][x]) - center
				cr   := i64(rows[2][x]) - center
				line[x * channels + 0] = u16(clamp(luma + ((91881 * cr + 32768) >> 16), 0, top))
				line[x * channels + 1] = u16(clamp(luma + ((-22554 * cb - 46802 * cr + 32768) >> 16), 0, top))
				line[x * channels + 2] = u16(clamp(luma + ((116130 * cb + 32768) >> 16), 0, top))
				if has_alpha {
					line[x * channels + 3] = alpha
				}
			}
		case .RGB:
			for x in 0..<width {
				line[x * channels + 0] = rows[0][x]
				line[x * channels + 1] = rows[1][x]
				line[x * channels + 2] = rows[2][x]
				if has_alpha {
					line[x * channels + 3] = alpha
				}
			}
		case .CMYK:
			for x in 0..<width {
				line[x * 4 + 0] = rows[0][x]
				line[x * 4 + 1] = rows[1][x]
				line[x * 4 + 2] = rows[2][x]
				line[x * 4 + 3] = rows[3][x]
			}
		case .YCCK:
			top := i64(maxval)
			for x in 0..<width {
				luma := i64(rows[0][x])
				cb   := i64(rows[1][x]) - center
				cr   := i64(rows[2][x]) - center
				line[x * 4 + 0] = u16(top - clamp(luma + ((91881 * cr + 32768) >> 16), 0, top))
				line[x * 4 + 1] = u16(top - clamp(luma + ((-22554 * cb - 46802 * cr + 32768) >> 16), 0, top))
				line[x * 4 + 2] = u16(top - clamp(luma + ((116130 * cb + 32768) >> 16), 0, top))
				line[x * 4 + 3] = rows[3][x]
			}
		}

		if depth == 16 {
			out := pixels16[y * width * channels:][:width * channels]
			if scale != nil {
				for v, i in line {
					out[i] = scale[v]
				}
			} else {
				copy(out, line)
			}
		} else {
			out := img.pixels[y * width * channels:][:width * channels]
			if scale != nil {
				for v, i in line {
					out[i] = u8(scale[v])
				}
			} else {
				for v, i in line {
					out[i] = u8(v)
				}
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

	if .return_metadata in options && (!d.hierarchical || d.scans == 0) {
		info := get_info(img) or_return
		info.frame_type = marker
	}

	#partial switch marker {
	case .SOF5, .SOF6, .SOF7, .SOF13, .SOF14, .SOF15:
		if !d.hierarchical {
			return .Unsupported_Frame_Type
		}
		if d.scans == 0 {
			return .Corrupt
		}
	}
	differential := marker >= .SOF5 && marker <= .SOF7 || marker >= .SOF13
	lossless     := marker == .SOF3 || marker == .SOF7 || marker == .SOF11 || marker == .SOF15
	switch {
	case lossless:
		if precision < 2 || precision > 16 {
			return .Invalid_Frame_Bit_Depth_Combo
		}
	case marker == .SOF0:
		if precision != 8 {
			return .Invalid_Frame_Bit_Depth_Combo
		}
	case:
		if precision != 8 && precision != 12 {
			return .Invalid_Frame_Bit_Depth_Combo
		}
	}
	if width == 0 {
		return .Invalid_Image_Dimensions
	}
	if components < 1 || components > MAX_COMPONENTS {
		return .Invalid_Number_Of_Channels
	}
	if length < 6 + 3 * components {
		return .Corrupt
	}
	if d.hierarchical {
		if int(precision) != d.precision {
			return .Invalid_Frame_Bit_Depth_Combo
		}
		if width > d.final_width || (d.final_height > 0 && height > d.final_height) {
			return .Invalid_Image_Dimensions
		}
		if differential {
			if d.hier_lossless && !lossless {
				return .Corrupt
			}
		} else {
			if d.scans > 0 && d.hier_lossless != lossless {
				return .Corrupt
			}
			d.hier_lossless = lossless
			if d.expand_h || d.expand_v {
				return .Corrupt
			}
		}
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
		if d.hierarchical {
			r := find_reference(d, c.id)
			if r == nil || r.closed || (differential && r.plane == nil) || (!differential && r.plane != nil) {
				return .Invalid_Component
			}
			r.closed = differential && lossless && !d.hier_lossless
		}
		d.hmax = max(d.hmax, c.h)
		d.vmax = max(d.vmax, c.v)
	}
	compress.skip(ctx, i64(length - 6 - 3 * components)) or_return

	d.component_count = components
	d.progressive     = marker == .SOF2 || marker == .SOF6 || marker == .SOF10 || marker == .SOF14
	d.lossless        = lossless
	d.arithmetic      = marker >= .SOF9
	d.differential    = differential
	d.precision       = int(precision)
	d.wide            = lossless || precision != 8 || d.hierarchical
	d.dc_limit        = 11 if precision == 8 && !differential else 15
	d.frame_open      = true

	img.width    = width
	img.height   = 0
	img.depth    = 8 if precision <= 8 else 16
	img.channels = components
	if differential {
		d.frame_expand_h, d.frame_expand_v = d.expand_h, d.expand_v
		d.expand_h, d.expand_v = false, false
	}
	if height == 0 {
		d.height_from_dnl = true
		return
	}
	return setup_geometry(d, img, height)
}

@(private="file")
find_reference :: proc(d: ^Decoder, id: u8) -> ^Reference {
	for &r in d.references[:d.reference_count] {
		if r.id == id {
			return &r
		}
	}
	return nil
}

@(private="file")
add_reference_row :: proc "contextless" (dst, a, b: []u16, w: int, expand_h, blend: bool) #no_bounds_check {
	n := len(dst)
	if !expand_h {
		if blend {
			for x in 0..<n {
				dst[x] += u16((u32(a[x]) + u32(b[x])) >> 1)
			}
		} else {
			for x in 0..<n {
				dst[x] += a[x]
			}
		}
		return
	}
	half := min(n / 2, w - 1)
	if blend {
		for sx in 0..<half {
			a0, a1 := u32(a[sx]), u32(a[sx + 1])
			b0, b1 := u32(b[sx]), u32(b[sx + 1])
			dst[2 * sx]     += u16((a0 + b0) >> 1)
			dst[2 * sx + 1] += u16((((a0 + a1) >> 1) + ((b0 + b1) >> 1)) >> 1)
		}
	} else {
		for sx in 0..<half {
			a0, a1 := u32(a[sx]), u32(a[sx + 1])
			dst[2 * sx]     += u16(a0)
			dst[2 * sx + 1] += u16((a0 + a1) >> 1)
		}
	}
	for x in 2 * half..<n {
		sx := x >> 1
		s1 := min(sx + 1, w - 1)
		va, vb := u32(a[sx]), u32(b[sx])
		if x & 1 != 0 {
			va = (va + u32(a[s1])) >> 1
			vb = (vb + u32(b[s1])) >> 1
		}
		dst[x] += u16((va + vb) >> 1) if blend else u16(va)
	}
}

@(private="file")
finish_frame :: proc(d: ^Decoder) -> (err: Error) #no_bounds_check {
	if !d.frame_open {
		return nil
	}
	d.frame_open = false
	idct_coefficients_wide(d) or_return
	for &c in d.components[:d.component_count] {
		r := find_reference(d, c.id)
		if d.differential {
			expand_h, expand_v := d.frame_expand_h, d.frame_expand_v
			width  := 2 * r.width  if expand_h else r.width
			height := 2 * r.height if expand_v else r.height
			if width < c.width || height < c.height {
				return .Corrupt
			}
			for y in 0..<c.height {
				sy    := y >> 1 if expand_v else y
				blend := expand_v && y & 1 != 0
				a := r.plane[sy * r.stride:][:r.width]
				b := r.plane[min(sy + 1, r.height - 1) * r.stride:][:r.width] if blend else a
				add_reference_row(c.plane16[y * c.plane_stride:][:c.width], a, b, r.width, expand_h, blend)
			}
		}
		delete(r.plane)
		r.plane  = c.plane16
		r.stride = c.plane_stride
		r.width, r.height = c.width, c.height
		c = {}
	}
	d.component_count = 0
	return nil
}

@(private="file")
finish_hierarchy :: proc(d: ^Decoder, img: ^Image) -> (err: Error) #no_bounds_check {
	width  := d.final_width
	height := d.final_height
	if height == 0 {
		height = img.height
	}
	if u128(width) * u128(height) > image.MAX_DIMENSIONS {
		return .Image_Dimensions_Too_Large
	}
	img.width    = width
	img.height   = height
	img.channels = d.reference_count
	img.depth    = 8 if d.precision <= 8 else 16

	d.component_count = d.reference_count
	d.hmax, d.vmax    = d.final_hmax, d.final_vmax
	d.lossless        = d.hier_lossless
	d.differential    = false
	d.progressive     = false
	d.wide            = true

	maxval := i32(1) << u32(d.precision) - 1
	for i in 0..<d.reference_count {
		r := &d.references[i]
		c := &d.components[i]
		c^ = {}
		c.id, c.h, c.v = r.id, r.h, r.v
		c.width  = (width  * c.h + d.hmax - 1) / d.hmax
		c.height = (height * c.v + d.vmax - 1) / d.vmax
		if r.plane == nil || r.width < c.width || r.height < c.height {
			return .Missing_Image_Data
		}
		if d.precision < 16 {
			for y in 0..<c.height {
				for &v in r.plane[y * r.stride:][:c.width] {
					v = u16(clamp(i32(i16(v)), 0, maxval))
				}
			}
		}
		c.plane16      = r.plane
		c.plane_stride = r.stride
		r.plane        = nil
	}
	return nil
}

@(private="file")
parse_hierarchy :: proc(d: ^Decoder) -> (err: Error) {
	ctx := d.ctx
	length     := read_length(ctx)                   or_return
	precision  := compress.read_u8(ctx)              or_return
	height     := int(compress.read_data(ctx, u16be) or_return)
	width      := int(compress.read_data(ctx, u16be) or_return)
	components := int(compress.read_u8(ctx)          or_return)
	if precision < 2 || precision > 16 {
		return .Invalid_Frame_Bit_Depth_Combo
	}
	if width == 0 {
		return .Invalid_Image_Dimensions
	}
	if u128(width) * u128(max(height, 1)) > image.MAX_DIMENSIONS {
		return .Image_Dimensions_Too_Large
	}
	if components < 1 || components > MAX_COMPONENTS {
		return .Invalid_Number_Of_Channels
	}
	if length < 6 + 3 * components {
		return .Corrupt
	}
	d.final_hmax, d.final_vmax = 1, 1
	for i in 0..<components {
		r := &d.references[i]
		r.id = compress.read_u8(ctx) or_return
		sampling := compress.read_u8(ctx) or_return
		compress.read_u8(ctx) or_return
		r.h = int(sampling >> 4)
		r.v = int(sampling & 15)
		if r.h < 1 || r.h > 4 || r.v < 1 || r.v > 4 {
			return .Invalid_Sampling_Factor
		}
		for j in 0..<i {
			if d.references[j].id == r.id {
				return .Invalid_Component
			}
		}
		d.final_hmax = max(d.final_hmax, r.h)
		d.final_vmax = max(d.final_vmax, r.v)
	}
	compress.skip(ctx, i64(length - 6 - 3 * components)) or_return
	d.hierarchical    = true
	d.precision       = int(precision)
	d.final_width     = width
	d.final_height    = height
	d.reference_count = components
	return nil
}

@(private="file")
parse_expand :: proc(d: ^Decoder) -> (err: Error) {
	ctx := d.ctx
	length := read_length(ctx) or_return
	if length < 1 {
		return .Corrupt
	}
	e := compress.read_u8(ctx) or_return
	if e & 0xEE != 0 {
		return .Corrupt
	}
	d.expand_h = e >> 4 != 0
	d.expand_v = e & 1 != 0
	return compress.skip(ctx, i64(length - 1))
}

@(private="file")
parse_arithmetic_conditioning :: proc(d: ^Decoder) -> (err: Error) {
	ctx := d.ctx
	length := read_length(ctx) or_return
	if length % 2 != 0 {
		return .Corrupt
	}
	for _ in 0..<length / 2 {
		tb := compress.read_u8(ctx) or_return
		cs := compress.read_u8(ctx) or_return
		class, table := tb >> 4, tb & 15
		if class > 1 || table > 3 {
			return .Corrupt
		}
		if class == 0 {
			l, u := cs & 15, cs >> 4
			if l > u {
				return .Corrupt
			}
			d.arith_l[table] = l
			d.arith_u[table] = u
		} else {
			if cs < 1 || cs > 63 {
				return .Corrupt
			}
			d.arith_kx[table] = cs
		}
	}
	return nil
}

@(private="file")
setup_geometry :: proc(d: ^Decoder, img: ^Image, height: int) -> (err: Error) {
	width := img.width
	if u128(width) * u128(height) > image.MAX_DIMENSIONS {
		return .Image_Dimensions_Too_Large
	}
	unit := 1 if d.lossless else BLOCK_SIZE
	d.mcux = (width  + unit * d.hmax - 1) / (unit * d.hmax)
	d.mcuy = (height + unit * d.vmax - 1) / (unit * d.vmax)
	for &c in d.components[:d.component_count] {
		c.width  = (width  * c.h + d.hmax - 1) / d.hmax
		c.height = (height * c.v + d.vmax - 1) / d.vmax
		c.stride = d.mcux * c.h
		c.rows   = d.mcuy * c.v
		if d.lossless {
			c.blocks_w     = c.width
			c.blocks_h     = c.height
			c.plane_stride = c.stride
		} else {
			c.blocks_w     = (c.width  + 7) / 8
			c.blocks_h     = (c.height + 7) / 8
			c.plane_stride = c.blocks_w * BLOCK_SIZE
		}
	}
	img.height = height
	return nil
}

@(private="file")
scan_for_dnl :: proc(data: []u8, state: ^int, nl: ^[4]u8) -> (done: bool, err: Error) {
	for b in data {
		switch state^ {
		case 0:
			if b == 0xFF {
				state^ = 1
			}
		case 1:
			switch {
			case b == 0xFF:
			case b == 0x00, b >= u8(image.JPEG_Marker.RST0) && b <= u8(image.JPEG_Marker.RST7):
				state^ = 0
			case b == u8(image.JPEG_Marker.DNL):
				state^ = 2
			case:
				return false, .Missing_DNL_Marker
			}
		case:
			nl[state^ - 2] = b
			state^ += 1
			if state^ == 6 {
				return true, nil
			}
		}
	}
	return false, nil
}

@(private="file")
find_dnl_height :: proc(d: ^Decoder) -> (height: int, err: Error) {
	z := d.ctx
	state := 0
	nl: [4]u8
	done := scan_for_dnl(z.window, &state, &nl) or_return
	if !done {
		if compress.is_memory_context(z) {
			return 0, .Missing_DNL_Marker
		}
		position, seek_err := io.seek(z.input, 0, .Current)
		if seek_err != nil {
			return 0, .DNL_Requires_Seekable_Stream
		}
		chunk: [DNL_SCAN_CHUNK]u8
		stalled := 0
		for !done {
			n, read_err := io.read(z.input, chunk[:])
			if n > 0 {
				stalled = 0
				done, err = scan_for_dnl(chunk[:n], &state, &nl)
				if err != nil {
					break
				}
				continue
			}
			if read_err != nil {
				err = .Missing_DNL_Marker
				break
			}
			stalled += 1
			if stalled > 100 {
				err = .Missing_DNL_Marker
				break
			}
		}
		if _, back_err := io.seek(z.input, position, .Start); back_err != nil && err == nil {
			err = .DNL_Requires_Seekable_Stream
		}
		if err != nil {
			return 0, err
		}
	}
	if u16(nl[0]) << 8 | u16(nl[1]) != 4 {
		return 0, .Corrupt
	}
	height = int(u16(nl[2]) << 8 | u16(nl[3]))
	if height == 0 {
		return 0, .Invalid_Image_Dimensions
	}
	return
}

@(private="file")
remaining_input :: proc(z: ^compress.Context) -> (n: i64, known: bool) {
	if compress.is_memory_context(z) {
		return i64(len(z.window)), true
	}
	size, size_err := io.size(z.input)
	if size_err != nil || size <= 0 {
		return 0, false
	}
	position, position_err := io.seek(z.input, 0, .Current)
	if position_err != nil {
		return 0, false
	}
	return size - position + i64(len(z.window)), true
}

@(private="file")
parse_scan :: proc(d: ^Decoder, img: ^Image) -> (err: Error) {
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

	switch {
	case d.lossless:
		lowest := 0 if d.differential else 1
		highest := 0 if d.differential else 7
		if ss < lowest || ss > highest || se != 0 || ah != 0 || al >= d.precision {
			return .Invalid_Scan_Parameters
		}
	case d.progressive:
		if ss == 0 && se != 0 {
			return .Invalid_Scan_Parameters
		}
		if ss > 0 && (count != 1 || se < ss || se > 63) {
			return .Invalid_Scan_Parameters
		}
		if ah > 13 || al > 13 {
			return .Invalid_Scan_Parameters
		}
	case:
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

	if d.height_from_dnl && img.height == 0 {
		height := find_dnl_height(d) or_return
		setup_geometry(d, img, height) or_return
	}

	if d.lossless && d.restart_interval > 0 {
		per_row := d.mcux if count > 1 else scan[0].width
		if d.restart_interval % per_row != 0 {
			return .Invalid_Scan_Parameters
		}
	}

	needs_dc := !d.arithmetic && (!d.progressive || (ss == 0 && ah == 0))
	needs_ac := !d.arithmetic && !d.lossless && (!d.progressive || ss > 0)
	for c in scan {
		if needs_dc && !d.huffman[0][c.dc_table].defined {
			return .Missing_Huffman_Table
		}
		if needs_ac && !d.huffman[1][c.ac_table].defined {
			return .Missing_Huffman_Table
		}
		if !d.lossless && !c.quant_latched {
			if !d.quant_defined[c.quant_index] {
				return .Missing_Quantization_Table
			}
			c.quant = d.quant[c.quant_index]
			c.quant_latched = true
		}
	}

	if d.lossless && !d.arithmetic && d.components[0].plane16 == nil {
		samples: i64
		for c in d.components[:d.component_count] {
			samples += i64(c.width) * i64(c.height)
		}
		if remaining, known := remaining_input(d.ctx); known && remaining < (samples + 7) / 8 {
			return .Missing_Image_Data
		}
	}

	for &c in d.components[:d.component_count] {
		switch {
		case d.lossless:
			if c.plane16 == nil {
				c.plane16 = make([]u16, c.stride * c.rows) or_return
			}
		case d.progressive:
			if c.coefficients == nil {
				c.coefficients = make([]i16, c.stride * c.rows * COEFFICIENT_COUNT) or_return
			}
		case d.wide:
			if c.plane16 == nil {
				c.plane16 = make([]u16, c.plane_stride * c.blocks_h * BLOCK_SIZE) or_return
			}
		case:
			if c.plane == nil {
				c.plane = make([]u8, c.plane_stride * c.blocks_h * BLOCK_SIZE) or_return
			}
		}
	}

	if d.lossless {
		decode_scan_lossless(d, scan, ss, al) or_return
	} else {
		decode_scan(d, scan, ss, se, ah, al) or_return
	}
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
