package jpeg

import "base:intrinsics"
import "base:runtime"
import "core:image"
import "core:math"
import "core:simd"
import "core:slice"

save_to_buffer :: proc(output: ^[dynamic]byte, img: ^Image, options := Options{}, quality := DEFAULT_QUALITY, subsampling := DEFAULT_SUBSAMPLING, profile := DEFAULT_PROFILE, save_options := Save_Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if img == nil {
		return .Invalid_Input_Image
	}
	if output == nil {
		return .Invalid_Output
	}
	if img.width <= 0 || img.height <= 0 || img.width > SAVE_MAX_DIMENSION || img.height > SAVE_MAX_DIMENSION || img.width * img.height > image.MAX_DIMENSIONS {
		return .Invalid_Image_Dimensions
	}
	if img.channels < 1 || img.channels > 4 {
		return .Invalid_Number_Of_Channels
	}
	if quality < 1 || quality > 100 || subsampling > .S420 {
		return .Unsupported_Option
	}
	if profile > .Lossless || save_options.entropy_coding > .Arithmetic || save_options.lossless_predictor > .Best {
		return .Unsupported_Option
	}
	if save_options.entropy_coding == .Arithmetic && profile == .Baseline {
		return .Unsupported_Option
	}
	lossless := profile == .Lossless
	if img.depth != 8 && !(img.depth == 16 && profile != .Baseline) {
		return .Invalid_Image_Depth
	}
	if img.width * img.height * img.channels * (img.depth / 8) != len(img.pixels) {
		return .Invalid_Input_Image
	}

	space: Color_Space
	if requested, requested_ok := save_options.color_space.?; requested_ok {
		space = requested
	} else if lossless {
		space = .Gray if img.channels <= 2 else .RGB
	} else {
		space = .Gray if img.channels <= 2 else .YCbCr
	}
	switch space {
	case .Gray:
	case .Gray_Alpha:
		if img.channels != 2 && img.channels != 4 {
			return .Invalid_Color_Space
		}
	case .YCbCr, .RGB:
		if img.channels < 3 {
			return .Invalid_Color_Space
		}
	case .CMYK, .YCCK:
		if img.channels != 4 {
			return .Invalid_Color_Space
		}
	case:
		return .Invalid_Color_Space
	}
	if lossless {
		#partial switch space {
		case .YCbCr, .YCCK:
			return .Unsupported_Option
		case .Gray:
			if img.channels > 2 {
				return .Unsupported_Option
			}
		case .Gray_Alpha:
			if img.channels != 2 {
				return .Unsupported_Option
			}
		}
	}

	e, e_err := new(Encoder)
	if e_err != nil {
		return .Unable_To_Allocate_Or_Resize
	}
	defer {
		for &c in e.components {
			delete(c.coefficients)
		}
		delete(e.corrections)
		delete(e.strip)
		free(e)
	}
	e.output       = output
	e.lossless     = lossless
	e.precision    = img.depth if lossless else (12 if img.depth == 16 else 8)
	e.progressive  = profile == .Progressive
	e.arithmetic   = save_options.entropy_coding == .Arithmetic
	e.store        = e.progressive || save_options.entropy_coding == .Huffman_Optimized || e.precision == 12 || e.arithmetic
	e.color_space  = space
	e.width        = img.width
	e.height       = img.height
	e.restart_rows = int(save_options.restart_interval_rows)

	save_setup_components(e, img, subsampling)
	save_setup_quantization(e, quality)

	clear(output)
	save_ensure(e, min(img.width * img.height / 4, SAVE_GROWTH_STEP) + SAVE_HEADER_BYTES)

	save_marker(e, .SOI)
	save_metadata(e)
	if lossless {
		save_frame(e, profile)
		save_lossless(e, img, save_options.lossless_predictor)
		save_marker(e, .EOI)
		if e.failed {
			clear(output)
			return .Unable_To_Allocate_Or_Resize
		}
		resize(output, e.pos)
		return nil
	}
	save_quantization_tables(e)
	save_frame(e, profile)

	full_scan := Scan{count = e.component_count, components = {0, 1, 2, 3}, ss = 0, se = COEFFICIENT_COUNT - 1}
	if !e.store {
		save_restart_interval(e, full_scan)
		save_standard_tables(e)
		save_scan_header(e, full_scan)
		save_transform(e, img)
		save_flush_bits(e)
	} else {
		save_transform(e, img)
		if e.progressive && !e.failed {
			scans: [SAVE_MAX_SCANS]Scan
			scan_count := save_scan_script(e, &scans)
			for scan in scans[:scan_count] {
				save_restart_interval(e, scan)
				if !e.arithmetic && !(scan.ss == 0 && scan.ah > 0) {
					save_optimal_tables(e, scan)
				}
				save_scan_header(e, scan)
				save_scan(e, scan, false)
			}
		} else if !e.failed {
			save_restart_interval(e, full_scan)
			if !e.arithmetic {
				save_optimal_tables(e, full_scan)
			}
			save_scan_header(e, full_scan)
			save_scan(e, full_scan, false)
		}
	}

	save_marker(e, .EOI)

	if e.failed {
		clear(output)
		return .Unable_To_Allocate_Or_Resize
	}
	resize(output, e.pos)
	return nil
}

@(private)
save_setup_components :: proc(e: ^Encoder, img: ^Image, subsampling: Subsampling) {
	e.hmax, e.vmax = 1, 1
	switch e.color_space {
	case .Gray:              e.component_count = 1
	case .Gray_Alpha:        e.component_count = 2
	case .YCbCr, .RGB:       e.component_count = 3
	case .CMYK, .YCCK:       e.component_count = 4
	}
	if e.color_space == .YCbCr || e.color_space == .YCCK {
		switch subsampling {
		case .S444: e.hmax, e.vmax = 1, 1
		case .S422: e.hmax, e.vmax = 2, 1
		case .S420: e.hmax, e.vmax = 2, 2
		}
	}

	e.mcux = (img.width  + 8 * e.hmax - 1) / (8 * e.hmax)
	e.mcuy = (img.height + 8 * e.vmax - 1) / (8 * e.vmax)

	e.table_count = 1
	rgb_ids := [3]u8{'R', 'G', 'B'}
	for i in 0..<e.component_count {
		chroma := (e.color_space == .YCbCr || e.color_space == .YCCK) && (i == 1 || i == 2)

		c := &e.components[i]
		c.id    = u8(i + 1)
		if e.color_space == .RGB {
			c.id = rgb_ids[i]
		}
		c.h     = 1 if chroma else e.hmax
		c.v     = 1 if chroma else e.vmax
		c.table = 1 if chroma else 0
		if chroma {
			e.table_count = 2
		}

		width  := (img.width  * c.h + e.hmax - 1) / e.hmax
		height := (img.height * c.v + e.vmax - 1) / e.vmax
		c.blocks_w = (width  + BLOCK_SIZE - 1) / BLOCK_SIZE
		c.blocks_h = (height + BLOCK_SIZE - 1) / BLOCK_SIZE
		c.stride   = e.mcux * c.h
		c.rows     = e.mcuy * c.v
	}

	if e.lossless {
		e.mcux, e.mcuy = img.width, img.height
		for &c, i in e.components[:e.component_count] {
			c.table    = i
			c.blocks_w = img.width
			c.blocks_h = img.height
		}
	}
}

@(private)
save_scan_script :: proc(e: ^Encoder, scans: ^[SAVE_MAX_SCANS]Scan) -> (n: int) {
	all := Scan{count = e.component_count, components = {0, 1, 2, 3}}
	add_each :: proc(e: ^Encoder, scans: ^[SAVE_MAX_SCANS]Scan, n: ^int, table: int, ss, se, ah, al: int) {
		for i in 0..<e.component_count {
			if e.components[i].table != table {
				continue
			}
			scans[n^] = Scan{count = 1, components = {i, 0, 0, 0}, ss = ss, se = se, ah = ah, al = al}
			n^ += 1
		}
	}

	scans[n] = all
	scans[n].al = 1
	n += 1
	add_each(e, scans, &n, 0, 1, 5,  0, 2)
	add_each(e, scans, &n, 1, 1, 63, 0, 1)
	add_each(e, scans, &n, 0, 6, 63, 0, 2)
	add_each(e, scans, &n, 0, 1, 63, 2, 1)
	scans[n] = all
	scans[n].ah = 1
	n += 1
	add_each(e, scans, &n, 1, 1, 63, 1, 0)
	add_each(e, scans, &n, 0, 1, 63, 1, 0)
	return
}

@(private)
save_restart_interval :: proc(e: ^Encoder, scan: Scan) {
	interval := 0
	if e.restart_rows > 0 {
		per_row := e.mcux
		if scan.count == 1 {
			c := &e.components[scan.components[0]]
			per_row = c.v * c.blocks_w
		}
		interval = e.restart_rows * per_row
		if interval > 65535 {
			interval = 65535 / per_row * per_row
		}
	}
	if interval != e.restart {
		e.restart = interval
		save_marker(e, .DRI)
		save_u16(e, 4)
		save_u16(e, interval)
	}
}

@(private)
save_restart :: proc(e: ^Encoder, index: int, $G: bool) {
	if e.arithmetic {
		when !G {
			save_arith_restart(e, index)
		}
		for &c in e.components[:e.component_count] {
			c.dc_pred = 0
		}
		return
	}
	if e.progressive {
		emit_eobrun(e, G)
	}
	when !G {
		save_flush_bits(e)
		save_marker(e, image.JPEG_Marker(u8(image.JPEG_Marker.RST0) + u8(index & 7)))
	}
	for &c in e.components[:e.component_count] {
		c.dc_pred = 0
	}
}

@(private)
save_metadata :: proc(e: ^Encoder) {
	if e.color_space == .Gray || e.color_space == .YCbCr {
		save_marker(e, .APP0)
		save_u16(e, 16)
		save_write(e, 'J', 'F', 'I', 'F', 0, 1, 1, 0, 0, 1, 0, 1, 0, 0)
	}

	if e.color_space == .RGB || e.color_space == .CMYK || e.color_space == .YCCK {
		save_marker(e, .APP14)
		save_u16(e, 14)
		save_write(e, 'A', 'd', 'o', 'b', 'e', 0, 100, 0, 0, 0, 0, 2 if e.color_space == .YCCK else 0)
	}
}

@(private)
save_setup_quantization :: proc(e: ^Encoder, quality: int) {
	aan: [BLOCK_SIZE]f64
	for k in 0..<BLOCK_SIZE {
		aan[k] = 1 if k == 0 else math.SQRT_TWO * math.cos(f64(k) * math.PI / 16)
	}

	scale   := 5000 / quality if quality < 50 else 200 - 2 * quality
	largest := 255 if e.precision == 8 else 32767
	for k in 0..<COEFFICIENT_COUNT {
		e.quant[0][k] = u16(clamp((int(QUANT_LUMA[k])   * scale + 50) / 100, 1, largest))
		e.quant[1][k] = u16(clamp((int(QUANT_CHROMA[k]) * scale + 50) / 100, 1, largest))
		factor := aan[k / BLOCK_SIZE] * aan[k % BLOCK_SIZE] * 8
		e.divisors[0][k] = f32(1 / (f64(e.quant[0][k]) * factor))
		e.divisors[1][k] = f32(1 / (f64(e.quant[1][k]) * factor))
	}
}

@(private)
save_transform :: proc(e: ^Encoder, img: ^Image) {
	strip_w    := e.mcux * BLOCK_SIZE * e.hmax
	strip_h    := BLOCK_SIZE * e.vmax
	plane_size := strip_w * strip_h

	strip_err: runtime.Allocator_Error
	e.strip, strip_err = make([]f32, plane_size * e.component_count)
	if strip_err != nil {
		e.failed = true
		return
	}
	if e.store {
		for i in 0..<e.component_count {
			c := &e.components[i]
			coefficients_err: runtime.Allocator_Error
			c.coefficients, coefficients_err = make([]i16, c.stride * c.rows * COEFFICIENT_COUNT)
			if coefficients_err != nil {
				e.failed = true
				return
			}
		}
	}

	if save_avx2_performant() {
		save_transform_avx2(e, img)
		return
	}
	save_transform_blocks(e, img, false)
}

@(private)
save_transform_blocks :: #force_inline proc(e: ^Encoder, img: ^Image, $AVX2: bool) {
	strip_w    := e.mcux * BLOCK_SIZE * e.hmax
	strip_h    := BLOCK_SIZE * e.vmax
	plane_size := strip_w * strip_h

	scratch: [COEFFICIENT_COUNT]i16
	limit := i32(1023 if e.precision == 8 else 16383)
	restart_left  := e.restart
	restart_index := 0
	for my in 0..<e.mcuy {
		save_convert_strip(e, img, my * strip_h, strip_w, strip_h)
		for mx in 0..<e.mcux {
			if !e.store && e.restart > 0 {
				if restart_left == 0 {
					save_restart(e, restart_index, false)
					restart_index += 1
					restart_left   = e.restart
				}
				restart_left -= 1
			}
			for i in 0..<e.component_count {
				c        := &e.components[i]
				plane    := e.strip[i * plane_size:]
				stride   := strip_w * c.h / e.hmax
				divisors := &e.divisors[c.table]
				for v in 0..<c.v {
					for h in 0..<c.h {
						bx := mx * c.h + h
						by := my * c.v + v
						block := &scratch
						if e.store {
							block = (^[COEFFICIENT_COUNT]i16)(&c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT])
						}
						when AVX2 {
							save_fdct_quantize_avx2(plane[v * BLOCK_SIZE * stride + bx * BLOCK_SIZE:], stride, block, divisors, limit)
						} else {
							save_fdct_quantize(plane[v * BLOCK_SIZE * stride + bx * BLOCK_SIZE:], stride, block, divisors, limit)
						}
						if !e.store {
							if e.failed {
								return
							}
							encode_block_baseline(e, c, block)
						}
					}
				}
			}
		}
	}
}

@(private)
save_convert_strip :: #force_inline proc(e: ^Encoder, img: ^Image, y0, strip_w, strip_h: int) {
	width, height, channels := img.width, img.height, img.channels
	plane_size := strip_w * strip_h

	for py in 0..<strip_h {
		offset := min(y0 + py, height - 1) * width * channels
		rows: [MAX_COMPONENTS][^]f32
		for i in 0..<e.component_count {
			rows[i] = raw_data(e.strip[i * plane_size + py * strip_w:][:strip_w])
		}

		if e.precision == 12 {
			save_convert_row(e, ([^]u16)(raw_data(img.pixels[2 * offset:][:2 * width * channels])), width, channels, &rows)
		} else {
			save_convert_row(e, raw_data(img.pixels[offset:][:width * channels]), width, channels, &rows)
		}

		for i in 0..<e.component_count {
			row  := rows[i]
			edge := row[width - 1]
			#no_bounds_check for px in width..<strip_w {
				row[px] = edge
			}
		}
	}

	for i in 0..<e.component_count {
		c := &e.components[i]
		if c.h < e.hmax || c.v < e.vmax {
			save_downsample(e.strip[i * plane_size:][:plane_size], strip_w, strip_h, e.hmax / c.h, e.vmax / c.v)
		}
	}
}

@(private)
save_convert_row :: #force_inline proc(e: ^Encoder, src: [^]$T, width, channels: int, rows: ^[MAX_COMPONENTS][^]f32) {
	switch e.color_space {
	case .Gray, .Gray_Alpha:
		switch channels {
		case 1: save_convert_row_channel(src, width, rows[0], 1, 0)
		case 2: save_convert_row_channel(src, width, rows[0], 2, 0)
		case 3: save_convert_row_color(src, width, rows[0], nil, nil, 3, true)
		case 4: save_convert_row_color(src, width, rows[0], nil, nil, 4, true)
		}
		if e.color_space == .Gray_Alpha {
			if channels == 2 {
				save_convert_row_channel(src, width, rows[1], 2, 1)
			} else {
				save_convert_row_channel(src, width, rows[1], 4, 3)
			}
		}
	case .YCbCr:
		if channels == 3 {
			save_convert_row_color(src, width, rows[0], rows[1], rows[2], 3, false)
		} else {
			save_convert_row_color(src, width, rows[0], rows[1], rows[2], 4, false)
		}
	case .RGB:
		if channels == 3 {
			save_convert_row_channel(src, width, rows[0], 3, 0)
			save_convert_row_channel(src, width, rows[1], 3, 1)
			save_convert_row_channel(src, width, rows[2], 3, 2)
		} else {
			save_convert_row_channel(src, width, rows[0], 4, 0)
			save_convert_row_channel(src, width, rows[1], 4, 1)
			save_convert_row_channel(src, width, rows[2], 4, 2)
		}
	case .CMYK:
		save_convert_row_channel(src, width, rows[0], 4, 0)
		save_convert_row_channel(src, width, rows[1], 4, 1)
		save_convert_row_channel(src, width, rows[2], 4, 2)
		save_convert_row_channel(src, width, rows[3], 4, 3)
	case .YCCK:
		save_convert_row_color(src, width, rows[0], rows[1], rows[2], 4, false)
		#no_bounds_check for px in 0..<width {
			rows[0][px] = -rows[0][px] - 1
			rows[1][px] = -rows[1][px]
			rows[2][px] = -rows[2][px]
		}
		save_convert_row_channel(src, width, rows[3], 4, 3)
	}
}

@(private)
save_convert_row_channel :: #force_inline proc "contextless" (src: [^]$T, width: int, row: [^]f32, $C: int, $O: int) {
	SHIFT  :: 4 * (size_of(T) - 1)
	CENTER :: f32(1 << (8 * size_of(T) - SHIFT - 1))
	px := 0
	L :: 16 * C + 16 * (C / 3) * (4 - C)
	#no_bounds_check {
		when SAVE_SIMD {
			for ; px * C + L <= width * C; px += 16 {
				v := intrinsics.unaligned_load((^#simd[L]T)(&src[px * C]))
				when C == 1 {
					g := v
				} else {
					g := simd.shuffle(v, v,
						O,          O +      C, O +  2 * C, O +  3 * C, O +  4 * C, O +  5 * C, O +  6 * C, O +  7 * C,
						O +  8 * C, O +  9 * C, O + 10 * C, O + 11 * C, O + 12 * C, O + 13 * C, O + 14 * C, O + 15 * C,
					)
				}
				when SHIFT > 0 {
					g = simd.shr(g, (#simd[16]T)(SHIFT))
				}
				intrinsics.unaligned_store((^#simd[16]f32)(&row[px]), cast(#simd[16]f32)g - CENTER)
			}
		}
		for ; px < width; px += 1 {
			row[px] = f32(src[px * C + O] >> SHIFT) - CENTER
		}
	}
}

@(private)
save_convert_row_color :: #force_inline proc "contextless" (src: [^]$T, width: int, row_y, row_cb, row_cr: [^]f32, $C: int, $LUMA_ONLY: bool) {
	SHIFT  :: 4 * (size_of(T) - 1)
	CENTER :: f32(1 << (8 * size_of(T) - SHIFT - 1))
	px := 0
	#no_bounds_check {
		when SAVE_SIMD {
			for ; px * C + 64 <= width * C; px += 16 {
				v := intrinsics.unaligned_load((^#simd[64]T)(&src[px * C]))
				when C == 3 {
					r8 := simd.shuffle(v, v, 0, 3, 6,  9, 12, 15, 18, 21, 24, 27, 30, 33, 36, 39, 42, 45)
					g8 := simd.shuffle(v, v, 1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31, 34, 37, 40, 43, 46)
					b8 := simd.shuffle(v, v, 2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32, 35, 38, 41, 44, 47)
				} else {
					r8, g8, b8, _ := intrinsics.simd_deinterleave(v, 4)
				}
				when SHIFT > 0 {
					r8 = simd.shr(r8, (#simd[16]T)(SHIFT))
					g8 = simd.shr(g8, (#simd[16]T)(SHIFT))
					b8 = simd.shr(b8, (#simd[16]T)(SHIFT))
				}
				r := cast(#simd[16]f32)r8
				g := cast(#simd[16]f32)g8
				b := cast(#simd[16]f32)b8
				intrinsics.unaligned_store((^#simd[16]f32)(&row_y[px]),   r *  0.299    + g * 0.587    + b * 0.114    - CENTER)
				when !LUMA_ONLY {
					intrinsics.unaligned_store((^#simd[16]f32)(&row_cb[px]),  r * -0.168736 - g * 0.331264 + b * 0.5)
					intrinsics.unaligned_store((^#simd[16]f32)(&row_cr[px]),  r *  0.5      - g * 0.418688 - b * 0.081312)
				}
			}
		}
		for ; px < width; px += 1 {
			p := src[px * C:]
			r, g, b := f32(p[0] >> SHIFT), f32(p[1] >> SHIFT), f32(p[2] >> SHIFT)
			row_y[px]  =  0.299    * r + 0.587    * g + 0.114    * b - CENTER
			when !LUMA_ONLY {
				row_cb[px] = -0.168736 * r - 0.331264 * g + 0.5      * b
				row_cr[px] =  0.5      * r - 0.418688 * g - 0.081312 * b
			}
		}
	}
}

@(private)
save_downsample :: #force_inline proc(plane: []f32, width, height, h, v: int) {
	out_w := width  / h
	out_h := height / v
	scale := 1 / f32(h * v)
	p := raw_data(plane)
	#no_bounds_check for y in 0..<out_h {
		x := 0
		when SAVE_SIMD {
			if h == 2 {
				row0 := p[y * v * width:]
				row1 := p[(y * v + v - 1) * width:]
				for ; x + 4 <= out_w; x += 4 {
					a0 := intrinsics.unaligned_load((^F4)(&row0[2 * x]))
					a1 := intrinsics.unaligned_load((^F4)(&row0[2 * x + 4]))
					sum := simd.shuffle(a0, a1, 0, 2, 4, 6) + simd.shuffle(a0, a1, 1, 3, 5, 7)
					if v == 2 {
						b0 := intrinsics.unaligned_load((^F4)(&row1[2 * x]))
						b1 := intrinsics.unaligned_load((^F4)(&row1[2 * x + 4]))
						sum = sum + simd.shuffle(b0, b1, 0, 2, 4, 6)
						sum = sum + simd.shuffle(b0, b1, 1, 3, 5, 7)
					}
					intrinsics.unaligned_store((^F4)(&p[y * out_w + x]), sum * scale)
				}
			}
		}
		for ; x < out_w; x += 1 {
			sum: f32
			for dy in 0..<v {
				row := p[(y * v + dy) * width + x * h:]
				for dx in 0..<h {
					sum += row[dx]
				}
			}
			p[y * out_w + x] = sum * scale
		}
	}
}

@(private)
fdct_8 :: #force_inline proc "contextless" (p: ^[BLOCK_SIZE]$T) {
	t0 := p[0] + p[7]
	t7 := p[0] - p[7]
	t1 := p[1] + p[6]
	t6 := p[1] - p[6]
	t2 := p[2] + p[5]
	t5 := p[2] - p[5]
	t3 := p[3] + p[4]
	t4 := p[3] - p[4]

	t10 := t0 + t3
	t13 := t0 - t3
	t11 := t1 + t2
	t12 := t1 - t2
	p[0] = t10 + t11
	p[4] = t10 - t11
	z1 := (t12 + t13) * 0.707106781
	p[2] = t13 + z1
	p[6] = t13 - z1

	t10 = t4 + t5
	t11 = t5 + t6
	t12 = t6 + t7
	z5  := (t10 - t12) * 0.382683433
	z2  := t10 * 0.541196100 + z5
	z4  := t12 * 1.306562965 + z5
	z3  := t11 * 0.707106781
	z11 := t7 + z3
	z13 := t7 - z3
	p[5] = z13 + z2
	p[3] = z13 - z2
	p[1] = z11 + z4
	p[7] = z11 - z4
}

@(private)
transpose_4 :: #force_inline proc "contextless" (a, b, c, d: F4) -> (F4, F4, F4, F4) {
	t0 := simd.shuffle(a, b, 0, 4, 1, 5)
	t1 := simd.shuffle(a, b, 2, 6, 3, 7)
	t2 := simd.shuffle(c, d, 0, 4, 1, 5)
	t3 := simd.shuffle(c, d, 2, 6, 3, 7)
	return simd.shuffle(t0, t2, 0, 1, 4, 5), simd.shuffle(t0, t2, 2, 3, 6, 7), simd.shuffle(t1, t3, 0, 1, 4, 5), simd.shuffle(t1, t3, 2, 3, 6, 7)
}

@(private)
save_fdct_quantize :: #force_inline proc(src: []f32, stride: int, block: ^[COEFFICIENT_COUNT]i16, divisors: ^[COEFFICIENT_COUNT]f32, limit: i32) {
	when SAVE_SIMD {
		save_fdct_quantize_simd(src, stride, block, divisors, limit)
	} else {
		save_fdct_quantize_scalar(src, stride, block, divisors, limit)
	}
}

@(private)
fdct_8_scalar :: #force_inline proc "contextless" (p: [^]f32, s: int) {
	t0 := p[0 * s] + p[7 * s]
	t7 := p[0 * s] - p[7 * s]
	t1 := p[1 * s] + p[6 * s]
	t6 := p[1 * s] - p[6 * s]
	t2 := p[2 * s] + p[5 * s]
	t5 := p[2 * s] - p[5 * s]
	t3 := p[3 * s] + p[4 * s]
	t4 := p[3 * s] - p[4 * s]

	t10 := t0 + t3
	t13 := t0 - t3
	t11 := t1 + t2
	t12 := t1 - t2
	p[0 * s] = t10 + t11
	p[4 * s] = t10 - t11
	z1 := (t12 + t13) * 0.707106781
	p[2 * s] = t13 + z1
	p[6 * s] = t13 - z1

	t10 = t4 + t5
	t11 = t5 + t6
	t12 = t6 + t7
	z5  := (t10 - t12) * 0.382683433
	z2  := 0.541196100 * t10 + z5
	z4  := 1.306562965 * t12 + z5
	z3  := t11 * 0.707106781
	z11 := t7 + z3
	z13 := t7 - z3
	p[5 * s] = z13 + z2
	p[3 * s] = z13 - z2
	p[1 * s] = z11 + z4
	p[7 * s] = z11 - z4
}

@(private)
save_fdct_quantize_scalar :: proc(src: []f32, stride: int, block: ^[COEFFICIENT_COUNT]i16, divisors: ^[COEFFICIENT_COUNT]f32, limit: i32) {
	t: [COEFFICIENT_COUNT]f32
	#no_bounds_check {
		for y in 0..<BLOCK_SIZE {
			copy(t[y * BLOCK_SIZE:][:BLOCK_SIZE], src[y * stride:][:BLOCK_SIZE])
			fdct_8_scalar(raw_data(t[y * BLOCK_SIZE:]), 1)
		}
		for x in 0..<BLOCK_SIZE {
			fdct_8_scalar(raw_data(t[x:]), BLOCK_SIZE)
		}
		for k in 0..<COEFFICIENT_COUNT {
			n := zigzag[k]
			q := t[n] * divisors[n]
			r := i32(q + 0.5) if q >= 0 else -i32(0.5 - q)
			block[k] = i16(clamp(r, -limit, limit))
		}
	}
}

@(private)
save_fdct_quantize_simd :: proc(src: []f32, stride: int, block: ^[COEFFICIENT_COUNT]i16, divisors: ^[COEFFICIENT_COUNT]f32, limit: i32) {
	lo, hi: [BLOCK_SIZE]F4
	ca, cb: [BLOCK_SIZE]F4
	natural: [COEFFICIENT_COUNT]i16
	p := raw_data(src)
	#no_bounds_check {
		for y in 0..<BLOCK_SIZE {
			lo[y] = intrinsics.unaligned_load((^F4)(&p[y * stride]))
			hi[y] = intrinsics.unaligned_load((^F4)(&p[y * stride + 4]))
		}
		ca[0], ca[1], ca[2], ca[3] = transpose_4(lo[0], lo[1], lo[2], lo[3])
		ca[4], ca[5], ca[6], ca[7] = transpose_4(hi[0], hi[1], hi[2], hi[3])
		cb[0], cb[1], cb[2], cb[3] = transpose_4(lo[4], lo[5], lo[6], lo[7])
		cb[4], cb[5], cb[6], cb[7] = transpose_4(hi[4], hi[5], hi[6], hi[7])
		fdct_8(&ca)
		fdct_8(&cb)
		lo[0], lo[1], lo[2], lo[3] = transpose_4(ca[0], ca[1], ca[2], ca[3])
		lo[4], lo[5], lo[6], lo[7] = transpose_4(cb[0], cb[1], cb[2], cb[3])
		hi[0], hi[1], hi[2], hi[3] = transpose_4(ca[4], ca[5], ca[6], ca[7])
		hi[4], hi[5], hi[6], hi[7] = transpose_4(cb[4], cb[5], cb[6], cb[7])
		fdct_8(&lo)
		fdct_8(&hi)

		d := raw_data(divisors)
		for y in 0..<BLOCK_SIZE {
			save_quantize_4(lo[y], intrinsics.unaligned_load((^F4)(&d[y * BLOCK_SIZE])),     (^#simd[4]i16)(&natural[y * BLOCK_SIZE]),     limit)
			save_quantize_4(hi[y], intrinsics.unaligned_load((^F4)(&d[y * BLOCK_SIZE + 4])), (^#simd[4]i16)(&natural[y * BLOCK_SIZE + 4]), limit)
		}
		v := intrinsics.unaligned_load((^#simd[COEFFICIENT_COUNT]i16)(&natural))
		intrinsics.unaligned_store((^#simd[COEFFICIENT_COUNT]i16)(block), simd.shuffle(v, v,
			 0,  1,  8, 16,  9,  2,  3, 10, 17, 24, 32, 25, 18, 11,  4,  5,
			12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13,  6,  7, 14, 21, 28,
			35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51,
			58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63,
		))
	}
}

@(private)
save_quantize_4 :: #force_inline proc "contextless" (t, divisor: F4, out: ^#simd[4]i16, limit: i32) {
	q := t * divisor
	half := transmute(F4)((transmute(#simd[4]u32)q & 0x80000000) | 0x3F000000)
	r := q + half
	i := simd.clamp(cast(#simd[4]i32)r, (#simd[4]i32)(-limit), (#simd[4]i32)(limit))
	intrinsics.unaligned_store(out, cast(#simd[4]i16)i)
}

@(private)
save_ensure :: #force_inline proc(e: ^Encoder, n: int) -> bool {
	if e.pos + n <= len(e.output) {
		return true
	}
	return save_grow(e, n)
}

@(private)
save_grow :: proc(e: ^Encoder, n: int) -> bool {
	if e.failed {
		return false
	}
	capacity := len(e.output)
	step     := capacity if capacity < SAVE_GROWTH_STEP else max(SAVE_GROWTH_STEP, capacity / 4)
	size     := max(capacity + step, e.pos + n, SAVE_HEADER_BYTES)
	if non_zero_resize(e.output, size) != nil {
		e.failed = true
		return false
	}
	return true
}

@(private)
save_write :: proc(e: ^Encoder, data: ..u8) {
	if !save_ensure(e, len(data)) {
		return
	}
	copy(e.output[e.pos:], data)
	e.pos += len(data)
}

@(private)
save_marker :: proc(e: ^Encoder, marker: image.JPEG_Marker) {
	save_write(e, 0xFF, u8(marker))
}

@(private)
save_u16 :: proc(e: ^Encoder, value: int) {
	save_write(e, u8(value >> 8), u8(value))
}

@(private)
save_quantization_tables :: proc(e: ^Encoder) {
	tables := e.table_count
	wide: [2]bool
	length := 2
	for t in 0..<tables {
		for q in e.quant[t] {
			if q > 255 {
				wide[t] = true
			}
		}
		length += 1 + COEFFICIENT_COUNT * (2 if wide[t] else 1)
	}
	save_marker(e, .DQT)
	save_u16(e, length)
	for t in 0..<tables {
		save_write(e, u8(int(wide[t]) << 4 | t))
		for k in 0..<COEFFICIENT_COUNT {
			if wide[t] {
				save_u16(e, int(e.quant[t][zigzag[k]]))
			} else {
				save_write(e, u8(e.quant[t][zigzag[k]]))
			}
		}
	}
}

@(private)
save_frame :: proc(e: ^Encoder, profile: Profile) {
	marker: image.JPEG_Marker
	#partial switch profile {
	case .Extended:    marker = .SOF9  if e.arithmetic else .SOF1
	case .Progressive: marker = .SOF10 if e.arithmetic else .SOF2
	case .Lossless:    marker = .SOF11 if e.arithmetic else .SOF3
	case:              marker = .SOF0
	}
	save_marker(e, marker)
	save_u16(e, 8 + 3 * e.component_count)
	save_write(e, u8(e.precision))
	save_u16(e, e.height)
	save_u16(e, e.width)
	save_write(e, u8(e.component_count))
	for c in e.components[:e.component_count] {
		save_write(e, c.id, u8(c.h << 4 | c.v), u8(0 if e.lossless else c.table))
	}
}

@(private)
save_scan_header :: proc(e: ^Encoder, scan: Scan) {
	save_marker(e, .SOS)
	save_u16(e, 6 + 2 * scan.count)
	save_write(e, u8(scan.count))
	for i in 0..<scan.count {
		c := &e.components[scan.components[i]]
		save_write(e, c.id, u8(c.table << 4 | c.table))
	}
	save_write(e, u8(scan.ss), u8(scan.se), u8(scan.ah << 4 | scan.al))
}

@(private)
save_spec_from_table :: proc(bits: [16]u8, values: []u8) -> (spec: Huffman_Spec) {
	spec.bits = bits
	copy(spec.values[:], values)
	spec.count = len(values)
	return
}

@(private)
save_build_codes :: proc(spec: ^Huffman_Spec, codes: ^Huffman_Code) {
	codes^ = {}
	code := u32(0)
	k    := 0
	for length in 1..=16 {
		for _ in 0..<spec.bits[length - 1] {
			symbol := spec.values[k]
			codes.code[symbol] = u16(code)
			codes.size[symbol] = u8(length)
			code += 1
			k    += 1
		}
		code <<= 1
	}
}

@(private)
save_huffman_tables :: proc(e: ^Encoder, classes: []int, indices: []int, specs: []Huffman_Spec) {
	length := 2
	for spec in specs {
		length += 1 + 16 + spec.count
	}
	save_marker(e, .DHT)
	save_u16(e, length)
	for &spec, i in specs {
		save_write(e, u8(classes[i] << 4 | indices[i]))
		save_write(e, ..spec.bits[:])
		save_write(e, ..spec.values[:spec.count])
		save_build_codes(&spec, &e.codes[classes[i]][indices[i]])
	}
}

@(private)
save_standard_tables :: proc(e: ^Encoder) {
	classes := [4]int{0, 1, 0, 1}
	indices := [4]int{0, 0, 1, 1}
	specs   := [4]Huffman_Spec{
		save_spec_from_table(DC_LUMA_BITS,   DC_VALUES[:]),
		save_spec_from_table(AC_LUMA_BITS,   AC_LUMA_VALUES[:]),
		save_spec_from_table(DC_CHROMA_BITS, DC_VALUES[:]),
		save_spec_from_table(AC_CHROMA_BITS, AC_CHROMA_VALUES[:]),
	}
	n := 2 * e.table_count
	save_huffman_tables(e, classes[:n], indices[:n], specs[:n])
}

@(private)
save_optimal_spec :: proc(frequencies: ^[257]u32) -> (spec: Huffman_Spec) {
	frequency: [257]i64
	others:    [257]int
	size:      [257]int
	for i in 0..<256 {
		frequency[i] = i64(frequencies[i])
		others[i]    = -1
	}
	frequency[256] = 1
	others[256]    = -1

	used := false
	for i in 0..<256 {
		if frequency[i] > 0 {
			used = true
		}
	}
	if !used {
		frequency[0] = 1
	}

	for {
		v1 := -1
		for i in 0..=256 {
			if frequency[i] > 0 && (v1 < 0 || frequency[i] <= frequency[v1]) {
				v1 = i
			}
		}
		v2 := -1
		for i in 0..=256 {
			if i != v1 && frequency[i] > 0 && (v2 < 0 || frequency[i] <= frequency[v2]) {
				v2 = i
			}
		}
		if v2 < 0 {
			break
		}

		frequency[v1] += frequency[v2]
		frequency[v2]  = 0

		size[v1] += 1
		for others[v1] >= 0 {
			v1 = others[v1]
			size[v1] += 1
		}
		others[v1] = v2

		size[v2] += 1
		for others[v2] >= 0 {
			v2 = others[v2]
			size[v2] += 1
		}
	}

	bits: [258]int
	for s in size {
		if s > 0 {
			bits[s] += 1
		}
	}

	for i := 257; i > 16; i -= 1 {
		for bits[i] > 0 {
			j := i - 2
			for bits[j] == 0 {
				j -= 1
			}
			bits[i]     -= 2
			bits[i - 1] += 1
			bits[j + 1] += 2
			bits[j]     -= 1
		}
	}

	longest := 16
	for bits[longest] == 0 {
		longest -= 1
	}
	bits[longest] -= 1

	for length in 1..=16 {
		spec.bits[length - 1] = u8(bits[length])
	}
	for length in 1..=257 {
		for symbol in 0..<256 {
			if size[symbol] == length {
				spec.values[spec.count] = u8(symbol)
				spec.count += 1
			}
		}
	}
	return
}

@(private)
save_optimal_tables :: proc(e: ^Encoder, scan: Scan) {
	e.frequencies = {}
	save_scan(e, scan, true)

	classes: [4]int
	indices: [4]int
	specs:   [4]Huffman_Spec
	n := 0
	for class in 0..<2 {
		if e.progressive && class == 0 && scan.ss > 0 {
			continue
		}
		if e.progressive && class == 1 && scan.ss == 0 {
			continue
		}
		for index in 0..<2 {
			referenced := false
			for i in 0..<scan.count {
				if e.components[scan.components[i]].table == index {
					referenced = true
				}
			}
			if !referenced {
				continue
			}
			classes[n] = class
			indices[n] = index
			specs[n]   = save_optimal_spec(&e.frequencies[class][index])
			n += 1
		}
	}
	save_huffman_tables(e, classes[:n], indices[:n], specs[:n])
}

@(private)
save_emit_word :: #force_inline proc(e: ^Encoder, w: u32) {
	pos := e.pos
	if pos + 8 > len(e.output) {
		save_emit_word_slow(e, w)
		return
	}
	if (~w - 0x01010101) & w & 0x80808080 != 0 {
		save_emit_word_stuffed(e, w)
		return
	}
	intrinsics.unaligned_store((^u32be)(&raw_data(e.output^)[pos]), u32be(w))
	e.pos = pos + 4
}

@(private, cold)
save_emit_word_slow :: proc(e: ^Encoder, w: u32) {
	if !save_grow(e, 8) {
		return
	}
	save_emit_word_stuffed(e, w)
}

@(private)
save_emit_word_stuffed :: proc(e: ^Encoder, w: u32) {
	p   := raw_data(e.output^)
	pos := e.pos
	#no_bounds_check for shift := u32(24); ; shift -= 8 {
		b := u8(w >> shift)
		p[pos] = b
		pos += 1
		if b == 0xFF {
			p[pos] = 0
			pos += 1
		}
		if shift == 0 {
			break
		}
	}
	e.pos = pos
}

@(private)
put_bits :: #force_inline proc(e: ^Encoder, value: u32, size: u32) {
	e.bits   = e.bits << (size & 63) | u64(value)
	e.count += size
	if e.count >= 32 {
		e.count -= 32
		save_emit_word(e, u32(e.bits >> (e.count & 63)))
	}
}

@(private)
put_value :: #force_inline proc(e: ^Encoder, value: u32, size: u32, $G: bool) {
	when !G {
		put_bits(e, value & ((u32(1) << size) - 1), size)
	}
}

@(private)
save_flush_bits :: proc(e: ^Encoder) {
	if !save_ensure(e, 16) {
		return
	}
	if e.count % 8 != 0 {
		pad := 8 - e.count % 8
		e.bits   = e.bits << pad | u64((u32(1) << pad) - 1)
		e.count += pad
	}
	p := raw_data(e.output^)
	for e.count >= 8 {
		e.count -= 8
		b := u8(e.bits >> e.count)
		p[e.pos] = b
		e.pos += 1
		if b == 0xFF {
			p[e.pos] = 0
			e.pos += 1
		}
	}
	e.bits  = 0
	e.count = 0
}

@(private)
emit_symbol :: #force_inline proc(e: ^Encoder, class, index, symbol: int, $G: bool) {
	when G {
		e.frequencies[class][index][symbol] += 1
	} else {
		codes := &e.codes[class][index]
		put_bits(e, u32(codes.code[symbol]), u32(codes.size[symbol]))
	}
}

@(private)
magnitude_masks :: #force_inline proc "contextless" (block: ^[COEFFICIENT_COUNT]i16, ss, se: int, al: u32) -> (nonzero, newly: u64) {
	when SAVE_SIMD {
		t1 := (#simd[16]i16)(i16(1) << al)
		t2 := (#simd[16]i16)(i16(2) << al)
		#no_bounds_check for i in 0..<4 {
			a  := simd.abs(intrinsics.unaligned_load((^#simd[16]i16)(&block[i * 16])))
			nz := transmute(u16)intrinsics.simd_extract_msbs(simd.lanes_ge(a, t1))
			hi := transmute(u16)intrinsics.simd_extract_msbs(simd.lanes_ge(a, t2))
			nonzero |= u64(nz) << u64(i * 16)
			newly   |= u64(nz &~ hi) << u64(i * 16)
		}
	} else {
		#no_bounds_check for k in ss..=se {
			m := abs(i32(block[k])) >> al
			nonzero |= u64(m != 0) << u64(k)
			newly   |= u64(m == 1) << u64(k)
		}
	}
	window := ((u64(1) << u64(se - ss + 1)) - 1) << u64(ss)
	return nonzero & window, newly & window
}

@(private)
bit_length :: #force_inline proc "contextless" (v: u32) -> u32 {
	return 32 - intrinsics.count_leading_zeros(v)
}

@(private)
nonzero_mask :: #force_inline proc "contextless" (block: ^[COEFFICIENT_COUNT]i16) -> (mask: u64) {
	when SAVE_SIMD {
		#no_bounds_check for i in 0..<4 {
			v := intrinsics.unaligned_load((^#simd[16]i16)(&block[i * 16]))
			bits := intrinsics.simd_extract_msbs(simd.lanes_ne(v, 0))
			mask |= u64(transmute(u16)bits) << u64(i * 16)
		}
		return mask &~ 1
	} else {
		#no_bounds_check for k in 1..<COEFFICIENT_COUNT {
			mask |= u64(block[k] != 0) << u64(k)
		}
		return
	}
}

@(private)
put_bits_local :: #force_inline proc "contextless" (out: [^]u8, pos: ^int, bits: ^u64, count: ^u32, value: u32, size: u32) {
	bits^   = bits^ << (size & 63) | u64(value)
	count^ += size
	if count^ >= 32 {
		count^ -= 32
		w := u32(bits^ >> (count^ & 63))
		if (~w - 0x01010101) & w & 0x80808080 == 0 {
			intrinsics.unaligned_store((^u32be)(&out[pos^]), u32be(w))
			pos^ += 4
		} else {
			#no_bounds_check for shift := u32(24); ; shift -= 8 {
				b := u8(w >> shift)
				out[pos^] = b
				pos^ += 1
				if b == 0xFF {
					out[pos^] = 0
					pos^ += 1
				}
				if shift == 0 {
					break
				}
			}
		}
	}
}

@(private)
encode_block_baseline :: proc(e: ^Encoder, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16) {
	if !save_ensure(e, SAVE_BLOCK_BYTES) {
		return
	}
	dc := &e.codes[0][c.table]
	ac := &e.codes[1][c.table]
	bits, count := e.bits, e.count
	out := raw_data(e.output^)
	pos := e.pos

	#no_bounds_check {
		value := i32(block[0])
		diff  := value - c.dc_pred
		c.dc_pred = value
		size := bit_length(u32(abs(diff)))
		v_bits := u32(diff if diff >= 0 else diff - 1) & ((u32(1) << size) - 1)
		put_bits_local(out, &pos, &bits, &count, u32(dc.code[size]) << size | v_bits, u32(dc.size[size]) + size)

		mask := nonzero_mask(block)
		last := 0
		for mask != 0 {
			k := int(intrinsics.count_trailing_zeros(mask))
			mask &= mask - 1
			run := k - last - 1
			last = k
			for run > 15 {
				put_bits_local(out, &pos, &bits, &count, u32(ac.code[0xF0]), u32(ac.size[0xF0]))
				run -= 16
			}
			v := i32(block[k])
			size = bit_length(u32(abs(v)))
			v_bits = u32(v if v >= 0 else v - 1) & ((u32(1) << size) - 1)
			symbol := run << 4 | int(size)
			put_bits_local(out, &pos, &bits, &count, u32(ac.code[symbol]) << size | v_bits, u32(ac.size[symbol]) + size)
		}
		if last < COEFFICIENT_COUNT - 1 {
			put_bits_local(out, &pos, &bits, &count, u32(ac.code[0x00]), u32(ac.size[0x00]))
		}
	}
	e.bits, e.count, e.pos = bits, count, pos
}

@(private)
gather_block_baseline :: proc(e: ^Encoder, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16) {
	dc := &e.frequencies[0][c.table]
	ac := &e.frequencies[1][c.table]

	#no_bounds_check {
		value := i32(block[0])
		diff  := value - c.dc_pred
		c.dc_pred = value
		dc[bit_length(u32(abs(diff)))] += 1

		mask := nonzero_mask(block)
		last := 0
		for mask != 0 {
			k := int(intrinsics.count_trailing_zeros(mask))
			mask &= mask - 1
			run := k - last - 1
			last = k
			for run > 15 {
				ac[0xF0] += 1
				run -= 16
			}
			ac[run << 4 | int(bit_length(u32(abs(i32(block[k])))))] += 1
		}
		if last < COEFFICIENT_COUNT - 1 {
			ac[0x00] += 1
		}
	}
}

@(private)
encode_dc :: proc(e: ^Encoder, c: ^Save_Component, value: i32, $G: bool) {
	diff := value - c.dc_pred
	c.dc_pred = value
	size := bit_length(u32(abs(diff)))
	emit_symbol(e, 0, c.table, int(size), G)
	put_value(e, u32(diff if diff >= 0 else diff - 1), size, G)
}

@(private)
emit_eobrun :: proc(e: ^Encoder, $G: bool) {
	if e.eobrun == 0 {
		return
	}
	size := bit_length(u32(e.eobrun)) - 1
	emit_symbol(e, 1, e.ac_table, int(size) << 4, G)
	put_value(e, u32(e.eobrun), size, G)
	e.eobrun = 0
	when !G {
		for bit in e.corrections {
			put_bits(e, u32(bit), 1)
		}
		clear(&e.corrections)
	}
}

@(private)
encode_ac_first :: proc(e: ^Encoder, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16, ss, se: int, al: u32, $G: bool) {
	nonzero, _ := magnitude_masks(block, ss, se, al)
	last := ss - 1
	#no_bounds_check for nonzero != 0 {
		k := int(intrinsics.count_trailing_zeros(nonzero))
		nonzero &= nonzero - 1
		run := k - last - 1
		last = k
		emit_eobrun(e, G)
		for run > 15 {
			emit_symbol(e, 1, c.table, 0xF0, G)
			run -= 16
		}
		v := i32(block[k])
		m := abs(v) >> al
		size := bit_length(u32(m))
		emit_symbol(e, 1, c.table, run << 4 | int(size), G)
		put_value(e, u32(m if v >= 0 else ~m), size, G)
	}
	if last < se {
		e.eobrun += 1
		if e.eobrun == EOBRUN_MAX {
			emit_eobrun(e, G)
		}
	}
}

@(private)
encode_ac_refine :: proc(e: ^Encoder, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16, ss, se: int, al: u32, $G: bool) {
	nonzero, newly := magnitude_masks(block, ss, se, al)
	eob := 63 - int(intrinsics.count_leading_zeros(newly)) if newly != 0 else 0

	pending: [COEFFICIENT_COUNT]u8
	pending_count := 0
	run  := 0
	prev := ss - 1
	#no_bounds_check for nonzero != 0 {
		k := int(intrinsics.count_trailing_zeros(nonzero))
		nonzero &= nonzero - 1
		run += k - prev - 1
		prev = k
		for run > 15 && k <= eob {
			emit_eobrun(e, G)
			emit_symbol(e, 1, c.table, 0xF0, G)
			run -= 16
			when !G {
				for bit in pending[:pending_count] {
					put_bits(e, u32(bit), 1)
				}
			}
			pending_count = 0
		}
		if newly & (u64(1) << u64(k)) == 0 {
			pending[pending_count] = u8((abs(i32(block[k])) >> al) & 1)
			pending_count += 1
			continue
		}
		emit_eobrun(e, G)
		emit_symbol(e, 1, c.table, run << 4 | 1, G)
		when !G {
			put_bits(e, 1 if block[k] > 0 else 0, 1)
			for bit in pending[:pending_count] {
				put_bits(e, u32(bit), 1)
			}
		}
		pending_count = 0
		run = 0
	}
	run += se - prev

	if run > 0 || pending_count > 0 {
		e.eobrun += 1
		when !G {
			if _, err := append(&e.corrections, ..pending[:pending_count]); err != nil {
				e.failed = true
			}
		}
		if e.eobrun == EOBRUN_MAX {
			emit_eobrun(e, G)
		}
	}
}

@(private)
encode_block :: #force_inline proc(e: ^Encoder, scan: Scan, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16, $G: bool) {
	when !G {
		if e.arithmetic {
			save_arith_block(e, scan, c, block)
			return
		}
	}
	if !e.progressive {
		when G {
			gather_block_baseline(e, c, block)
		} else {
			encode_block_baseline(e, c, block)
		}
		return
	}
	al := u32(scan.al)
	if scan.ss == 0 {
		if scan.ah == 0 {
			encode_dc(e, c, i32(block[0]) >> al, G)
		} else {
			put_value(e, u32(block[0] >> al) & 1, 1, G)
		}
		return
	}
	if scan.ah == 0 {
		encode_ac_first(e, c, block, scan.ss, scan.se, al, G)
	} else {
		encode_ac_refine(e, c, block, scan.ss, scan.se, al, G)
	}
}

@(private)
save_scan_block :: #force_inline proc(e: ^Encoder, scan: Scan, c: ^Save_Component, bx, by: int, $G: bool) -> bool {
	if e.failed {
		return false
	}
	encode_block(e, scan, c, (^[COEFFICIENT_COUNT]i16)(&c.coefficients[(by * c.stride + bx) * COEFFICIENT_COUNT]), G)
	return true
}

@(private)
save_scan_unit :: #force_inline proc(e: ^Encoder, left, index: ^int, $G: bool) {
	if e.restart == 0 {
		return
	}
	if left^ == 0 {
		save_restart(e, index^, G)
		index^ += 1
		left^   = e.restart
	}
	left^ -= 1
}

@(private)
save_scan :: proc(e: ^Encoder, scan: Scan, $G: bool) {
	e.bits   = 0
	e.count  = 0
	e.eobrun = 0
	clear(&e.corrections)
	for &c in e.components[:e.component_count] {
		c.dc_pred = 0
	}
	if e.arithmetic {
		save_arith_reset(e)
	}
	restart_left  := e.restart
	restart_index := 0

	if scan.count == 1 {
		c := &e.components[scan.components[0]]
		e.ac_table = c.table
		for by in 0..<c.blocks_h {
			for bx in 0..<c.blocks_w {
				save_scan_unit(e, &restart_left, &restart_index, G)
				if !save_scan_block(e, scan, c, bx, by, G) {
					return
				}
			}
		}
	} else {
		for my in 0..<e.mcuy {
			for mx in 0..<e.mcux {
				save_scan_unit(e, &restart_left, &restart_index, G)
				for i in 0..<scan.count {
					c := &e.components[scan.components[i]]
					for v in 0..<c.v {
						for h in 0..<c.h {
							if !save_scan_block(e, scan, c, mx * c.h + h, my * c.v + v, G) {
								return
							}
						}
					}
				}
			}
		}
	}

	if e.progressive && scan.ss > 0 {
		emit_eobrun(e, G)
	}
	when !G {
		if e.arithmetic {
			save_arith_flush(e)
		} else {
			save_flush_bits(e)
		}
	}
}

@(private)
save_lossless :: proc(e: ^Encoder, img: ^Image, predictor: Lossless_Predictor) {
	buffer, buffer_err := make([]u16, 3 * e.component_count * e.width)
	if buffer_err != nil {
		e.failed = true
		return
	}
	defer delete(buffer)

	save_restart_interval(e, Scan{count = e.component_count, components = {0, 1, 2, 3}})

	n        := e.component_count
	selected := int(predictor) + 1
	hist: [7][MAX_COMPONENTS][17]u32
	if predictor == .Best {
		save_lossless_gather(e, img, buffer, 1, 7, &hist)
		best_bits := max(u64)
		for p in 1..=7 {
			bits := u64(0)
			for i in 0..<n {
				frequencies: [257]u32
				copy(frequencies[:17], hist[p - 1][i][:])
				spec := save_optimal_spec(&frequencies)
				codes: Huffman_Code
				save_build_codes(&spec, &codes)
				for s in 0..<16 {
					bits += u64(frequencies[s]) * u64(int(codes.size[s]) + s)
				}
				bits += u64(frequencies[16]) * u64(codes.size[16])
			}
			if bits < best_bits {
				best_bits = bits
				selected  = p
			}
		}
	} else if !e.arithmetic {
		save_lossless_gather(e, img, buffer, selected, selected, &hist)
	}

	if !e.arithmetic {
		classes: [MAX_COMPONENTS]int
		indices: [MAX_COMPONENTS]int
		specs:   [MAX_COMPONENTS]Huffman_Spec
		for i in 0..<n {
			frequencies: [257]u32
			copy(frequencies[:17], hist[selected - 1][i][:])
			indices[i] = i
			specs[i]   = save_optimal_spec(&frequencies)
		}
		save_huffman_tables(e, classes[:n], indices[:n], specs[:n])
	}

	save_marker(e, .SOS)
	save_u16(e, 6 + 2 * n)
	save_write(e, u8(n))
	for c in e.components[:n] {
		save_write(e, c.id, u8(c.table << 4))
	}
	save_write(e, u8(selected), 0, 0)

	if e.arithmetic {
		save_lossless_scan_arith(e, img, buffer, selected)
		return
	}
	save_lossless_scan(e, img, buffer, selected)
	save_flush_bits(e)
}

@(private)
save_lossless_gather :: proc(e: ^Encoder, img: ^Image, buffer: []u16, first, last: int, hist: ^[7][MAX_COMPONENTS][17]u32) #no_bounds_check {
	width         := e.width
	count         := e.component_count
	interval_rows := e.restart / width
	initial       := u16(1) << u32(e.precision - 1)
	diffs         := buffer[2 * count * width:][:width]

	for y in 0..<e.height {
		reset := y == 0 || (interval_rows > 0 && y % interval_rows == 0)
		save_lossless_load_row(e, img, buffer, y)
		for i in 0..<count {
			row   := buffer[((y & 1) * count + i) * width:][:width]
			above := buffer[((1 - (y & 1)) * count + i) * width:][:width]
			if reset {
				counts: [17]u32
				save_lossless_differences(row, above, diffs, true, first, initial)
				save_lossless_histogram(diffs, &counts)
				for p in first..=last {
					for s in 0..<17 {
						hist[p - 1][i][s] += counts[s]
					}
				}
				continue
			}
			for p in first..=last {
				save_lossless_differences(row, above, diffs, false, p, initial)
				save_lossless_histogram(diffs, &hist[p - 1][i])
			}
		}
	}
}

@(private)
save_lossless_histogram :: #force_inline proc "contextless" (diffs: []u16, counts: ^[17]u32) #no_bounds_check {
	lanes: [4][17]u32
	n := len(diffs)
	x := 0
	for ; x + 4 <= n; x += 4 {
		lanes[0][bit_length(u32(abs(i32(i16(diffs[x])))))]     += 1
		lanes[1][bit_length(u32(abs(i32(i16(diffs[x + 1])))))] += 1
		lanes[2][bit_length(u32(abs(i32(i16(diffs[x + 2])))))] += 1
		lanes[3][bit_length(u32(abs(i32(i16(diffs[x + 3])))))] += 1
	}
	for ; x < n; x += 1 {
		lanes[0][bit_length(u32(abs(i32(i16(diffs[x])))))] += 1
	}
	for s in 0..<17 {
		counts[s] += lanes[0][s] + lanes[1][s] + lanes[2][s] + lanes[3][s]
	}
}

@(private)
save_lossless_scan :: proc(e: ^Encoder, img: ^Image, buffer: []u16, predictor: int) #no_bounds_check {
	width         := e.width
	count         := e.component_count
	interval_rows := e.restart / width
	restart_index := 0
	diffs         := buffer[2 * count * width:][:count * width]
	row_bytes     := 8 * count * width + 16
	bits          := u64(0)
	nbits         := u32(0)

	for y in 0..<e.height {
		reset := y == 0
		if interval_rows > 0 && y > 0 && y % interval_rows == 0 {
			reset = true
			e.bits, e.count = bits, nbits
			save_flush_bits(e)
			save_marker(e, image.JPEG_Marker(u8(image.JPEG_Marker.RST0) + u8(restart_index & 7)))
			bits, nbits = e.bits, e.count
			restart_index += 1
		}
		save_lossless_row(e, img, buffer, y, predictor, reset)
		if !save_ensure(e, row_bytes) {
			return
		}
		out := raw_data(e.output^)
		pos := e.pos
		for x in 0..<width {
			for i in 0..<count {
				codes := &e.codes[0][i]
				value := i32(i16(diffs[i * width + x]))
				size  := bit_length(u32(abs(value)))
				code  := u32(codes.code[size])
				csize := u32(codes.size[size])
				if size < 16 {
					v := u32(value if value >= 0 else value - 1) & ((u32(1) << size) - 1)
					put_bits_local(out, &pos, &bits, &nbits, code << size | v, csize + size)
				} else {
					put_bits_local(out, &pos, &bits, &nbits, code, csize)
				}
			}
		}
		e.pos = pos
	}
	e.bits, e.count = bits, nbits
}

@(private)
save_lossless_load_row :: #force_inline proc(e: ^Encoder, img: ^Image, buffer: []u16, y: int) #no_bounds_check {
	width    := e.width
	count    := e.component_count
	channels := img.channels
	pixels16 := slice.reinterpret([]u16, img.pixels[:])
	for i in 0..<count {
		row   := buffer[((y & 1) * count + i) * width:][:width]
		start := y * width * channels + i
		if e.precision == 8 {
			for x in 0..<width {
				row[x] = u16(img.pixels[start + x * channels])
			}
		} else {
			for x in 0..<width {
				row[x] = pixels16[start + x * channels]
			}
		}
	}
}

@(private)
save_lossless_row :: #force_inline proc(e: ^Encoder, img: ^Image, buffer: []u16, y, predictor: int, reset: bool) #no_bounds_check {
	width   := e.width
	count   := e.component_count
	initial := u16(1) << u32(e.precision - 1)
	diffs   := buffer[2 * count * width:][:count * width]
	save_lossless_load_row(e, img, buffer, y)
	for i in 0..<count {
		row   := buffer[((y & 1) * count + i) * width:][:width]
		above := buffer[((1 - (y & 1)) * count + i) * width:][:width]
		save_lossless_differences(row, above, diffs[i * width:][:width], reset, predictor, initial)
	}
}

@(private)
Save_Arith :: struct {
	c:  u32,
	a:  u32,
	ct: u32,
}

@(private)
save_lossless_scan_arith :: proc(e: ^Encoder, img: ^Image, buffer: []u16, predictor: int) #no_bounds_check {
	width         := e.width
	count         := e.component_count
	interval_rows := e.restart / width
	restart_index := 0
	diffs         := buffer[2 * count * width:][:count * width]

	categories, categories_err := make([]u8, 2 * count * width)
	if categories_err != nil {
		e.failed = true
		return
	}
	defer delete(categories)

	save_arith_reset(e)
	ar := Save_Arith{e.arith_c, e.arith_a, e.arith_ct}
	for y in 0..<e.height {
		reset := y == 0
		if interval_rows > 0 && y > 0 && y % interval_rows == 0 {
			reset = true
			e.arith_c, e.arith_a, e.arith_ct = ar.c, ar.a, ar.ct
			save_arith_restart(e, restart_index)
			ar = {e.arith_c, e.arith_a, e.arith_ct}
			restart_index += 1
		}
		save_lossless_row(e, img, buffer, y, predictor, reset)
		lefts: [MAX_COMPONENTS]int
		for x in 0..<width {
			for i in 0..<count {
				current := categories[((y & 1) * count + i) * width:]
				above   := categories[((1 - (y & 1)) * count + i) * width:]
				up      := 0 if reset else int(above[x])
				value   := i32(i16(diffs[i * width + x]))
				save_arith_difference(e, &ar, e.dc_stats[i][:], 20 * lefts[i] + 4 * up, 100 if up <= 2 else 129, value)
				lefts[i]   = save_arith_category(value)
				current[x] = u8(lefts[i])
			}
		}
	}
	e.arith_c, e.arith_a, e.arith_ct = ar.c, ar.a, ar.ct
	save_arith_flush(e)
}

@(private)
save_arith_reset :: proc(e: ^Encoder) {
	e.dc_stats = {}
	e.ac_stats = {}
	for &c in e.components[:e.component_count] {
		c.dc_context = 0
	}
	e.arith_a     = 0x10000
	e.arith_c     = 0
	e.arith_ct    = 11
	e.arith_start = e.pos
}

@(private)
save_arith_restart :: proc(e: ^Encoder, index: int) {
	save_arith_flush(e)
	save_marker(e, image.JPEG_Marker(u8(image.JPEG_Marker.RST0) + u8(index & 7)))
	save_arith_reset(e)
}

@(private)
save_arith_byte_out :: proc(e: ^Encoder, t: u32) #no_bounds_check {
	if !save_ensure(e, 1) {
		return
	}
	p := raw_data(e.output^)
	if t > 0xFF {
		i := e.pos - 1
		for i >= e.arith_start && p[i] == 0xFF {
			p[i] = 0
			i -= 1
		}
		if i >= e.arith_start {
			p[i] += 1
		}
	}
	p[e.pos] = u8(t)
	e.pos += 1
}

@(private)
save_arith_encode :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, st: ^u8, bit: int) {
	s     := st^
	entry := ARITH_STATES[s]
	a     := ar.a - entry.qe
	if bit == int(s >> 7) {
		if a >= 0x8000 {
			ar.a = a
			return
		}
		if a < entry.qe {
			ar.c += a
			a     = entry.qe
		}
		st^ = entry.mps
	} else {
		if a >= entry.qe {
			ar.c += a
			a     = entry.qe
		}
		st^ = entry.lps
	}
	shift := u32(intrinsics.count_leading_zeros(a)) - 16
	ar.a = a << shift
	for shift >= ar.ct {
		shift -= ar.ct
		ar.c <<= ar.ct
		save_arith_byte_out(e, ar.c >> 19)
		ar.c &= 0x7FFFF
		ar.ct = 8
	}
	ar.c  <<= shift
	ar.ct  -= shift
}

@(private)
save_arith_encode_fixed :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, bit: int) {
	st: u8
	save_arith_encode(e, ar, &st, bit)
}

@(private)
save_arith_flush :: proc(e: ^Encoder) #no_bounds_check {
	t := (e.arith_c + e.arith_a - 1) & 0xFFFF0000
	if t < e.arith_c {
		t += 0x8000
	}
	e.arith_c = t << e.arith_ct
	save_arith_byte_out(e, e.arith_c >> 19)
	e.arith_c = (e.arith_c & 0x7FFFF) << 8
	save_arith_byte_out(e, e.arith_c >> 19)
	e.arith_c &= 0x7FFFF
	if e.failed {
		return
	}

	p := raw_data(e.output^)
	for e.pos > e.arith_start && p[e.pos - 1] == 0 {
		e.pos -= 1
	}
	stuffed := 0
	for i in e.arith_start..<e.pos {
		if p[i] == 0xFF {
			stuffed += 1
		}
	}
	if stuffed == 0 || !save_ensure(e, stuffed) {
		return
	}
	p = raw_data(e.output^)
	dst := e.pos + stuffed - 1
	for src := e.pos - 1; src >= e.arith_start && dst > src; src -= 1 {
		if p[src] == 0xFF {
			p[dst] = 0
			dst -= 1
		}
		p[dst] = p[src]
		dst -= 1
	}
	e.pos += stuffed
}

@(private)
save_arith_category :: #force_inline proc "contextless" (v: i32) -> int {
	m := abs(v)
	if m == 0 {
		return 0
	}
	return (1 if m <= 2 else 3) + int(v < 0)
}

@(private)
save_arith_magnitude :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, stats: []u8, x2: int, sz: i32) #no_bounds_check {
	m  := i32(2)
	st := x2
	for sz >= 2 * m {
		save_arith_encode(e, ar, &stats[st], 1)
		m  <<= 1
		st  += 1
	}
	save_arith_encode(e, ar, &stats[st], 0)
	s := stats[st + 14]
	for bit := m >> 1; bit != 0; bit >>= 1 {
		save_arith_encode(e, ar, &s, int(sz & bit != 0))
	}
	stats[st + 14] = s
}

@(private)
save_arith_difference :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, stats: []u8, s0, x1: int, v: i32) #no_bounds_check {
	if v == 0 {
		save_arith_encode(e, ar, &stats[s0], 0)
		return
	}
	save_arith_encode(e, ar, &stats[s0], 1)
	sign := int(v < 0)
	save_arith_encode(e, ar, &stats[s0 + 1], sign)
	sz := abs(v) - 1
	save_arith_encode(e, ar, &stats[s0 + 2 + sign], int(sz != 0))
	if sz == 0 {
		return
	}
	save_arith_encode(e, ar, &stats[x1], int(sz != 1))
	if sz > 1 {
		save_arith_magnitude(e, ar, stats, x1 + 1, sz)
	}
}

@(private)
save_arith_dc :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, c: ^Save_Component, value: i32) {
	diff := value - c.dc_pred
	c.dc_pred = value
	save_arith_difference(e, ar, e.dc_stats[c.table][:], c.dc_context, 20, diff)
	c.dc_context = 4 * save_arith_category(diff)
}

@(private)
save_arith_ac_first :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16, ss, se: int, al: u32) #no_bounds_check {
	stats := e.ac_stats[c.table][:]
	nonzero, _ := magnitude_masks(block, ss, se, al)
	last := 63 - int(intrinsics.count_leading_zeros(nonzero)) if nonzero != 0 else ss - 1
	for k := ss; k <= se; k += 1 {
		st := 3 * (k - 1)
		if k > last {
			save_arith_encode(e, ar, &stats[st], 1)
			break
		}
		save_arith_encode(e, ar, &stats[st], 0)
		for nonzero & (u64(1) << u64(k)) == 0 {
			save_arith_encode(e, ar, &stats[st + 1], 0)
			k  += 1
			st += 3
		}
		save_arith_encode(e, ar, &stats[st + 1], 1)
		v := i32(block[k])
		save_arith_encode_fixed(e, ar, int(v < 0))
		sz := (abs(v) >> al) - 1
		save_arith_encode(e, ar, &stats[st + 2], int(sz != 0))
		if sz != 0 {
			save_arith_encode(e, ar, &stats[st + 2], int(sz != 1))
			if sz > 1 {
				save_arith_magnitude(e, ar, stats, 189 if k <= SAVE_ARITH_KX else 217, sz)
			}
		}
	}
}

@(private)
save_arith_ac_refine :: #force_inline proc(e: ^Encoder, ar: ^Save_Arith, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16, ss, se: int, al: u32) #no_bounds_check {
	stats := e.ac_stats[c.table][:]
	nonzero, newly := magnitude_masks(block, ss, se, al)
	previous := nonzero &~ newly
	eob  := 64 - int(intrinsics.count_leading_zeros(previous)) if previous != 0 else ss
	last := 63 - int(intrinsics.count_leading_zeros(nonzero))  if nonzero  != 0 else ss - 1
	for k := ss; k <= se; k += 1 {
		st := 3 * (k - 1)
		if k >= eob {
			if k > last {
				save_arith_encode(e, ar, &stats[st], 1)
				break
			}
			save_arith_encode(e, ar, &stats[st], 0)
		}
		for {
			bit := u64(1) << u64(k)
			if previous & bit != 0 {
				save_arith_encode(e, ar, &stats[st + 2], int((abs(i32(block[k])) >> al) & 1))
				break
			}
			if nonzero & bit != 0 {
				save_arith_encode(e, ar, &stats[st + 1], 1)
				save_arith_encode_fixed(e, ar, int(block[k] < 0))
				break
			}
			save_arith_encode(e, ar, &stats[st + 1], 0)
			k  += 1
			st += 3
		}
	}
}

@(private)
save_arith_block :: proc(e: ^Encoder, scan: Scan, c: ^Save_Component, block: ^[COEFFICIENT_COUNT]i16) {
	ar := Save_Arith{e.arith_c, e.arith_a, e.arith_ct}
	defer e.arith_c, e.arith_a, e.arith_ct = ar.c, ar.a, ar.ct
	if !e.progressive {
		save_arith_dc(e, &ar, c, i32(block[0]))
		save_arith_ac_first(e, &ar, c, block, 1, COEFFICIENT_COUNT - 1, 0)
		return
	}
	al := u32(scan.al)
	if scan.ss == 0 {
		if scan.ah == 0 {
			save_arith_dc(e, &ar, c, i32(block[0]) >> al)
		} else {
			save_arith_encode_fixed(e, &ar, int((block[0] >> al) & 1))
		}
		return
	}
	if scan.ah == 0 {
		save_arith_ac_first(e, &ar, c, block, scan.ss, scan.se, al)
	} else {
		save_arith_ac_refine(e, &ar, c, block, scan.ss, scan.se, al)
	}
}

@(private)
save_lossless_differences :: #force_inline proc(row, above, diff: []u16, reset: bool, predictor: int, initial: u16) #no_bounds_check {
	width := len(row)
	if reset {
		diff[0] = row[0] - initial
		for x in 1..<width {
			diff[x] = row[x] - row[x - 1]
		}
		return
	}
	diff[0] = row[0] - above[0]
	switch predictor {
	case 1:
		for x in 1..<width {
			diff[x] = row[x] - row[x - 1]
		}
	case 2:
		for x in 1..<width {
			diff[x] = row[x] - above[x]
		}
	case 3:
		for x in 1..<width {
			diff[x] = row[x] - above[x - 1]
		}
	case 4:
		for x in 1..<width {
			diff[x] = row[x] - (row[x - 1] + above[x] - above[x - 1])
		}
	case 5:
		for x in 1..<width {
			diff[x] = row[x] - u16(i32(row[x - 1]) + ((i32(above[x]) - i32(above[x - 1])) >> 1))
		}
	case 6:
		for x in 1..<width {
			diff[x] = row[x] - u16(i32(above[x]) + ((i32(row[x - 1]) - i32(above[x - 1])) >> 1))
		}
	case 7:
		for x in 1..<width {
			diff[x] = row[x] - u16((u32(row[x - 1]) + u32(above[x])) >> 1)
		}
	}
}

