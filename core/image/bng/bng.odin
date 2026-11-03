// An implementation of the [BNG](https://bngformat.org)
package bng

import "base:intrinsics"
import "core:compress"
import "core:image"

load_from_bytes :: proc(data: []byte, options := Default_Options, allocator := context.allocator) -> (img: ^Image, err: Error) {
	data := data
	ctx  := compress.init_context_from_slice(&data)
	return load_from_context(&ctx, options, allocator)
}

load_from_context :: proc(ctx: ^compress.Context, options := Default_Options, allocator := context.allocator) -> (img: ^Image, err: Error) {
	context.allocator = allocator
	options := options

	if .info in options {
		options += {.return_metadata, .do_not_decompress_image}
		options -= {.info}
	}

	if .return_header in options && .return_metadata in options {
		options -= {.return_header}
	}

	header := compress.read_data(ctx, image.BNG_Header) or_return
	if header.magic != image.BNG_Magic {
		return img, .Invalid_Signature
	}

	img = new(Image)
	img.which = .BNG

	if .return_metadata in options {
		info := new(image.BNG_Info)
		info.header  = header
		img.metadata = info
	}

	if header.version != image.BNG_Version {
		return img, image.BNG_Error.Unsupported_Version
	}

	if header.width == 0 || header.height == 0 {
		return img, .Invalid_Image_Dimensions
	}

	if u64(header.width) * u64(header.height) > image.MAX_DIMENSIONS {
		return img, .Image_Dimensions_Too_Large
	}

	img.width    = int(header.width)
	img.height   = int(header.height)
	img.channels = 3 if .alpha_drop_if_present in options else 4
	img.depth    = 8

	if .do_not_decompress_image in options {
		return
	}

	raw         := header.stream_byte_count & image.BNG_Raw_Flag != 0
	body_length := int(header.stream_byte_count & ~image.BNG_Raw_Flag)

	body: []u8
	if compress.is_memory_context(ctx) {
		if body_length > len(ctx.window) {
			return img, .Body_Length_Exceeds_Input
		}
		body       = ctx.window[:body_length]
		ctx.window = ctx.window[body_length:]
	} else {
		buffer, buffer_err := make([]u8, body_length)
		if buffer_err != nil {
			return img, .Unable_To_Allocate_Or_Resize
		}
		defer delete(buffer)

		if read_err := compress.read_slice(ctx, buffer); read_err != nil {
			if read_err == .Short_Buffer {
				return img, .Body_Length_Exceeds_Input
			}
			return img, read_err
		}
		body = buffer
	}

	width  := img.width
	height := img.height
	pixels := width * height

	if raw && body_length != 4 * pixels {
		return img, .Invalid_Raw_Body_Length
	}

	if !raw && body_length * 8 < height {
		return img, .Body_Ends_Too_Early
	}

	if resize(&img.pixels, 4 * pixels) != nil {
		return img, .Unable_To_Allocate_Or_Resize
	}

	if raw {
		for i in 0..<pixels {
			img.pixels[4 * i + 0] = body[4 * i + 2]
			img.pixels[4 * i + 1] = body[4 * i + 1]
			img.pixels[4 * i + 2] = body[4 * i + 0]
			img.pixels[4 * i + 3] = body[4 * i + 3]
		}
	} else {
		decode_body(img, body) or_return
	}

	if .alpha_premultiply not_in options {
		unpremultiply(img.pixels[:])
	}

	if .alpha_drop_if_present in options {
		for i in 0..<pixels {
			img.pixels[3 * i + 0] = img.pixels[4 * i + 0]
			img.pixels[3 * i + 1] = img.pixels[4 * i + 1]
			img.pixels[3 * i + 2] = img.pixels[4 * i + 2]
		}
		resize(&img.pixels, 3 * pixels)
	}
	return
}

save_to_buffer :: proc(output: ^[dynamic]byte, img: ^Image, options := Options{}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	if img == nil {
		return .Invalid_Input_Image
	}

	if output == nil {
		return .Invalid_Output
	}

	if img.depth != 8 || img.channels < 3 || img.channels > 4 {
		return .Invalid_Input_Image
	}

	width  := img.width
	height := img.height
	if width <= 0 || height <= 0 {
		return .Invalid_Input_Image
	}

	pixels := width * height
	if pixels > image.MAX_DIMENSIONS || 4 * pixels > MAX_BODY_LENGTH {
		return .Image_Dimensions_Too_Large
	}

	if img.channels * pixels != len(img.pixels) {
		return .Invalid_Input_Image
	}

	raw_length := 4 * pixels
	if resize(output, size_of(image.BNG_Header) + raw_length) != nil {
		return .Unable_To_Allocate_Or_Resize
	}

	scratch, scratch_err := make([]u8, 12 * width)
	if scratch_err != nil {
		return .Unable_To_Allocate_Or_Resize
	}
	defer delete(scratch)

	cur, prv, res: [4][]u8
	for p in 0..<4 {
		cur[p] = scratch[(p + 0) * width:][:width]
		prv[p] = scratch[(p + 4) * width:][:width]
		res[p] = scratch[(p + 8) * width:][:width]
	}

	writer := Bit_Writer{data = output[size_of(image.BNG_Header):]}
	encode: for y in 0..<height {
		rgba_to_ycocg(cur, img.pixels[y * width * img.channels:][:width * img.channels], img.channels)

		for p in 0..<4 {
			compute_residuals(res[p], cur[p], prv[p], y == 0)
			encode_row(&writer, res[p])
		}
		if writer.overflow {
			break encode
		}
		cur, prv = prv, cur
	}
	flush(&writer)

	body_length := writer.pos
	stream_byte_count := u32le(body_length)
	if writer.overflow || body_length >= raw_length {
		body := output[size_of(image.BNG_Header):]
		for y in 0..<height {
			src := img.pixels[y * width * img.channels:][:width * img.channels]
			dst := body[y * width * 4:][:width * 4]
			for x in 0..<width {
				pixel := read_pixel(src, x, img.channels)
				dst[4 * x + 0] = pixel.b
				dst[4 * x + 1] = pixel.g
				dst[4 * x + 2] = pixel.r
				dst[4 * x + 3] = pixel.a
			}
		}
		body_length = raw_length
		stream_byte_count = u32le(raw_length) | image.BNG_Raw_Flag
	}

	header := image.BNG_Header{
		magic             = image.BNG_Magic,
		version           = image.BNG_Version,
		width             = u32le(width),
		height            = u32le(height),
		stream_byte_count = stream_byte_count,
	}
	header_bytes := transmute([size_of(image.BNG_Header)]u8)header
	copy(output[:], header_bytes[:])

	resize(output, size_of(image.BNG_Header) + body_length)
	return nil
}

destroy :: proc(img: ^Image) {
	if img == nil {
		return
	}

	delete(img.pixels)

	if v, ok := img.metadata.(^image.BNG_Info); ok {
		free(v)
	}
	free(img)
}

@(private)
decode_body :: proc(img: ^Image, body: []u8) -> (err: Error) {
	width  := img.width
	height := img.height

	scratch, scratch_err := make([]u8, 12 * width)
	if scratch_err != nil {
		return .Unable_To_Allocate_Or_Resize
	}
	defer delete(scratch)

	cur, prv, res: [4][]u8
	for p in 0..<4 {
		cur[p] = scratch[(p + 0) * width:][:width]
		prv[p] = scratch[(p + 4) * width:][:width]
		res[p] = scratch[(p + 8) * width:][:width]
	}

	reader := Bit_Reader{data = body}
	for y in 0..<height {
		for p in 0..<4 {
			decode_row(&reader, res[p]) or_return
		}
		if y == 0 {
			for p in 0..<4 {
				reconstruct_row(cur[p], prv[p], res[p], true)
			}
		} else {
			reconstruct_rows(cur, prv, res)
		}

		ycocg_to_rgba(img.pixels[y * width * 4:][:width * 4], cur)
		cur, prv = prv, cur
	}
	return nil
}

@(private)
ycocg_to_rgba :: proc(dst: []u8, src: [4][]u8) #no_bounds_check {
	U8x16 :: #simd[16]u8
	I8x16 :: #simd[16]i8
	U16x8 :: #simd[8]u16

	width := len(src[0])
	x := 0
	for ; x + 16 <= width; x += 16 {
		luma  := intrinsics.unaligned_load((^U8x16)(&src[0][x]))
		co    := intrinsics.unaligned_load((^U8x16)(&src[1][x]))
		cg    := intrinsics.unaligned_load((^U8x16)(&src[2][x]))
		alpha := intrinsics.unaligned_load((^U8x16)(&src[3][x]))

		t := luma - transmute(U8x16)intrinsics.simd_shr(transmute(I8x16)cg, U8x16(1))
		g := cg + t
		b := t - transmute(U8x16)intrinsics.simd_shr(transmute(I8x16)co, U8x16(1))
		r := b + co

		rg_lo := transmute(U16x8)intrinsics.simd_shuffle(r, g, 0, 16, 1, 17, 2, 18, 3, 19, 4, 20, 5, 21, 6, 22, 7, 23)
		rg_hi := transmute(U16x8)intrinsics.simd_shuffle(r, g, 8, 24, 9, 25, 10, 26, 11, 27, 12, 28, 13, 29, 14, 30, 15, 31)
		ba_lo := transmute(U16x8)intrinsics.simd_shuffle(b, alpha, 0, 16, 1, 17, 2, 18, 3, 19, 4, 20, 5, 21, 6, 22, 7, 23)
		ba_hi := transmute(U16x8)intrinsics.simd_shuffle(b, alpha, 8, 24, 9, 25, 10, 26, 11, 27, 12, 28, 13, 29, 14, 30, 15, 31)

		out := (^U16x8)(&dst[4 * x])
		intrinsics.unaligned_store(out,               intrinsics.simd_shuffle(rg_lo, ba_lo, 0, 8, 1, 9, 2, 10, 3, 11))
		intrinsics.unaligned_store(intrinsics.ptr_offset(out, 1), intrinsics.simd_shuffle(rg_lo, ba_lo, 4, 12, 5, 13, 6, 14, 7, 15))
		intrinsics.unaligned_store(intrinsics.ptr_offset(out, 2), intrinsics.simd_shuffle(rg_hi, ba_hi, 0, 8, 1, 9, 2, 10, 3, 11))
		intrinsics.unaligned_store(intrinsics.ptr_offset(out, 3), intrinsics.simd_shuffle(rg_hi, ba_hi, 4, 12, 5, 13, 6, 14, 7, 15))
	}

	for ; x < width; x += 1 {
		co := src[1][x]
		cg := src[2][x]
		t  := src[0][x] - u8(i8(cg) >> 1)
		b  := t - u8(i8(co) >> 1)
		dst[4 * x + 0] = b + co
		dst[4 * x + 1] = cg + t
		dst[4 * x + 2] = b
		dst[4 * x + 3] = src[3][x]
	}
}

@(private)
decode_row :: proc(reader: ^Bit_Reader, residuals: []u8) -> (err: Error) #no_bounds_check {
	width := len(residuals)
	intrinsics.mem_zero(raw_data(residuals), width)

	out   := raw_data(residuals)
	data  := raw_data(reader.data)
	limit := len(reader.data) - 8
	pos   := reader.pos
	acc   := reader.acc
	count := reader.count

	x := 0
	for x < width {
		if count < 32 {
			if pos <= limit {
				v := u64(intrinsics.unaligned_load((^u64be)(&data[pos])))
				acc |= v >> count
				take := (64 - count) >> 3
				pos   += int(take)
				count += take << 3
			} else {
				reader.pos, reader.acc, reader.count = pos, acc, count
				if !refill(reader) {
					return .Body_Ends_Too_Early
				}
				pos, acc, count = reader.pos, reader.acc, reader.count
			}
		}

		entry    := decode_table[acc >> (64 - MAX_CODE_LENGTH)]
		mantissa := uint(entry.flags & DECODE_MANTISSA_MASK)
		acc <<= entry.length
		value := int(entry.base) + int((acc >> 1) >> (63 - mantissa))
		acc <<= mantissa
		count -= uint(entry.length) + mantissa

		negative := int(entry.flags >> 4) & 1
		signed   := (value ~ -negative) + negative
		run      := entry.flags & DECODE_RUN != 0
		remain   := width - x

		out[x] = 0 if run else u8(signed)
		advance := value if run else 1
		advance  = remain if entry.flags & DECODE_END_OF_ROW != 0 else advance
		x += min(advance, remain)
	}

	reader.pos, reader.acc, reader.count = pos, acc, count
	return nil
}

@(private)
reconstruct_row :: proc(cur, prv, res: []u8, first_row: bool) #no_bounds_check {
	width := len(cur)
	if first_row {
		left := u8(0)
		for x in 0..<width {
			left  += res[x]
			cur[x] = left
		}
		return
	}

	cur[0] = prv[0] + res[0]
	for x in 1..<width {
		cur[x] = med(cur[x - 1], prv[x], prv[x - 1]) + res[x]
	}
}

@(private)
reconstruct_rows :: proc(cur, prv, res: [4][]u8) #no_bounds_check {
	width := len(cur[0])
	c0, c1, c2, c3 := raw_data(cur[0]), raw_data(cur[1]), raw_data(cur[2]), raw_data(cur[3])
	p0, p1, p2, p3 := raw_data(prv[0]), raw_data(prv[1]), raw_data(prv[2]), raw_data(prv[3])
	r0, r1, r2, r3 := raw_data(res[0]), raw_data(res[1]), raw_data(res[2]), raw_data(res[3])

	tl0, tl1, tl2, tl3 := p0[0], p1[0], p2[0], p3[0]
	l0 := tl0 + r0[0]
	l1 := tl1 + r1[0]
	l2 := tl2 + r2[0]
	l3 := tl3 + r3[0]
	c0[0], c1[0], c2[0], c3[0] = l0, l1, l2, l3

	for x in 1..<width {
		t0, t1, t2, t3 := p0[x], p1[x], p2[x], p3[x]
		l0 = med(l0, t0, tl0) + r0[x]
		l1 = med(l1, t1, tl1) + r1[x]
		l2 = med(l2, t2, tl2) + r2[x]
		l3 = med(l3, t3, tl3) + r3[x]
		c0[x], c1[x], c2[x], c3[x] = l0, l1, l2, l3
		tl0, tl1, tl2, tl3 = t0, t1, t2, t3
	}
}

@(private)
rgba_to_ycocg :: proc(dst: [4][]u8, src: []u8, channels: int) #no_bounds_check {
	U8x16  :: #simd[16]u8
	I8x16  :: #simd[16]i8
	U32x4  :: #simd[4]u32

	width := len(dst[0])
	x := 0
	if channels == 4 {
		for ; x + 16 <= width; x += 16 {
			in_ := (^U8x16)(&src[4 * x])
			v0 := intrinsics.unaligned_load(in_)
			v1 := intrinsics.unaligned_load(intrinsics.ptr_offset(in_, 1))
			v2 := intrinsics.unaligned_load(intrinsics.ptr_offset(in_, 2))
			v3 := intrinsics.unaligned_load(intrinsics.ptr_offset(in_, 3))

			g0 := transmute(U32x4)intrinsics.simd_shuffle(v0, v0, 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15)
			g1 := transmute(U32x4)intrinsics.simd_shuffle(v1, v1, 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15)
			g2 := transmute(U32x4)intrinsics.simd_shuffle(v2, v2, 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15)
			g3 := transmute(U32x4)intrinsics.simd_shuffle(v3, v3, 0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15)

			t0 := intrinsics.simd_shuffle(g0, g1, 0, 4, 1, 5)
			t1 := intrinsics.simd_shuffle(g2, g3, 0, 4, 1, 5)
			t2 := intrinsics.simd_shuffle(g0, g1, 2, 6, 3, 7)
			t3 := intrinsics.simd_shuffle(g2, g3, 2, 6, 3, 7)

			r := transmute(U8x16)intrinsics.simd_shuffle(t0, t1, 0, 1, 4, 5)
			g := transmute(U8x16)intrinsics.simd_shuffle(t0, t1, 2, 3, 6, 7)
			b := transmute(U8x16)intrinsics.simd_shuffle(t2, t3, 0, 1, 4, 5)
			a := transmute(U8x16)intrinsics.simd_shuffle(t2, t3, 2, 3, 6, 7)

			co := r - b
			t  := b + transmute(U8x16)intrinsics.simd_shr(transmute(I8x16)co, U8x16(1))
			cg := g - t
			intrinsics.unaligned_store((^U8x16)(&dst[0][x]), t + transmute(U8x16)intrinsics.simd_shr(transmute(I8x16)cg, U8x16(1)))
			intrinsics.unaligned_store((^U8x16)(&dst[1][x]), co)
			intrinsics.unaligned_store((^U8x16)(&dst[2][x]), cg)
			intrinsics.unaligned_store((^U8x16)(&dst[3][x]), a)
		}
	}

	for ; x < width; x += 1 {
		pixel := read_pixel(src, x, channels)
		co := pixel.r - pixel.b
		t  := pixel.b + u8(i8(co) >> 1)
		cg := pixel.g - t
		dst[0][x] = t + u8(i8(cg) >> 1)
		dst[1][x] = co
		dst[2][x] = cg
		dst[3][x] = pixel.a
	}
}

@(private)
compute_residuals :: proc(res, cur, prv: []u8, first_row: bool) #no_bounds_check {
	width := len(cur)
	if first_row {
		res[0] = cur[0]
		for x in 1..<width {
			res[x] = cur[x] - cur[x - 1]
		}
		return
	}

	U8x16 :: #simd[16]u8

	res[0] = cur[0] - prv[0]
	x := 1
	for ; x + 16 <= width; x += 16 {
		left     := intrinsics.unaligned_load((^U8x16)(&cur[x - 1]))
		top      := intrinsics.unaligned_load((^U8x16)(&prv[x]))
		top_left := intrinsics.unaligned_load((^U8x16)(&prv[x - 1]))
		current  := intrinsics.unaligned_load((^U8x16)(&cur[x]))

		lo   := intrinsics.simd_min(left, top)
		hi   := intrinsics.simd_max(left, top)
		pred := left + top - top_left
		pred  = intrinsics.simd_select(intrinsics.simd_lanes_ge(top_left, hi), lo, pred)
		pred  = intrinsics.simd_select(intrinsics.simd_lanes_le(top_left, lo), hi, pred)
		intrinsics.unaligned_store((^U8x16)(&res[x]), current - pred)
	}
	for ; x < width; x += 1 {
		res[x] = cur[x] - med(cur[x - 1], prv[x], prv[x - 1])
	}
}

@(private)
med :: #force_inline proc "contextless" (left, top, top_left: u8) -> u8 {
	lo := int(min(left, top))
	hi := int(max(left, top))
	g  := int(left) + int(top) - int(top_left)
	return u8(clamp(g, lo, hi))
}

@(private)
read_pixel :: #force_inline proc "contextless" (src: []u8, x: int, channels: int) -> (pixel: image.RGBA_Pixel) #no_bounds_check {
	if channels == 4 {
		pixel = image.RGBA_Pixel{src[4 * x + 0], src[4 * x + 1], src[4 * x + 2], src[4 * x + 3]}
	} else {
		pixel = image.RGBA_Pixel{src[3 * x + 0], src[3 * x + 1], src[3 * x + 2], 255}
	}
	return
}

@(private)
unpremultiply :: proc(pixels: []u8) #no_bounds_check {
	for i := 0; i < len(pixels); i += 4 {
		a := u32(pixels[i + 3])
		if a == 0 || a == 255 {
			continue
		}
		for c in 0..<3 {
			pixels[i + c] = u8(min((u32(pixels[i + c]) * 255 + a / 2) / a, 255))
		}
	}
}

@(private)
encode_row :: proc(writer: ^Bit_Writer, residuals: []u8) #no_bounds_check {
	w     := writer^
	width := len(residuals)
	res   := raw_data(residuals)
	defer writer^ = w

	x := 0
	for x < width {
		e := res[x]
		if e != 0 {
			entry := residual_table[e]
			put_bits(&w, entry & 0xFF_FFFF, uint(entry >> 24))
			x += 1
			continue
		}

		run := 1
		scan: for x + run + 8 <= width {
			v := u64(intrinsics.unaligned_load((^u64le)(&res[x + run])))
			if v != 0 {
				run += int(intrinsics.count_trailing_zeros(v)) >> 3
				break scan
			}
			run += 8
		}
		for x + run < width && res[x + run] == 0 {
			run += 1
		}

		if x + run == width {
			put_token(&w, TOKEN_EOL)
			return
		}

		if run == 1 {
			put_token(&w, 0)
			x += 1
			continue
		}

		run = min(run, MAX_RUN)
		exponent := 31 - int(intrinsics.count_leading_zeros(u32(run)))
		put_token(&w, TOKEN_EOL + exponent)
		put_bits(&w, u32(run - (int(1) << uint(exponent))), uint(exponent))
		x += run
	}
}

@(private)
refill :: #force_inline proc "contextless" (reader: ^Bit_Reader) -> (ok: bool) #no_bounds_check {
	if reader.count >= 32 {
		return true
	}

	if reader.pos + 8 <= len(reader.data) {
		v := u64(intrinsics.unaligned_load((^u64be)(&reader.data[reader.pos])))
		reader.acc |= v >> reader.count
		take := (64 - reader.count) >> 3
		reader.pos   += int(take)
		reader.count += take << 3
		return true
	}

	for reader.count <= 56 {
		b := u64(0)
		if reader.pos < len(reader.data) {
			b = u64(reader.data[reader.pos])
			reader.pos += 1
		} else {
			reader.pad += 1
			if reader.pad > MAX_PAD_BYTES {
				return false
			}
		}
		reader.acc |= b << (56 - reader.count)
		reader.count += 8
	}
	return true
}

@(private)
put_token :: #force_inline proc "contextless" (writer: ^Bit_Writer, token: int) #no_bounds_check {
	entry := encode_table[token]
	put_bits(writer, u32(entry.code), uint(entry.length))
}

@(private)
put_bits :: #force_inline proc "contextless" (writer: ^Bit_Writer, code: u32, length: uint) #no_bounds_check {
	writer.acc    = writer.acc << length | u64(code)
	writer.count += length
	if writer.count >= 32 {
		writer.count -= 32
		if writer.pos + 4 <= len(writer.data) {
			intrinsics.unaligned_store((^u32be)(&writer.data[writer.pos]), u32be(writer.acc >> writer.count))
		} else {
			writer.overflow = true
		}
		writer.pos += 4
	}
}

@(private)
flush :: proc "contextless" (writer: ^Bit_Writer) #no_bounds_check {
	for writer.count >= 8 {
		writer.count -= 8
		if writer.pos < len(writer.data) {
			writer.data[writer.pos] = u8(writer.acc >> writer.count)
		} else {
			writer.overflow = true
		}
		writer.pos += 1
	}
	if writer.count > 0 {
		if writer.pos < len(writer.data) {
			writer.data[writer.pos] = u8(writer.acc << (8 - writer.count))
		} else {
			writer.overflow = true
		}
		writer.pos  += 1
		writer.count = 0
	}
}

@(private)
token_entry :: proc "contextless" (token: int, length: u8) -> (entry: Decode_Entry) {
	entry.length = length
	switch {
	case token == 0:
	case token < 127:
		entry.base = u16((token + 1) / 2)
		if token & 1 == 0 {
			entry.flags = DECODE_NEGATIVE
		}
	case token < TOKEN_EOL:
		k        := token - 127
		exponent := 6 + k / 2
		entry.base  = u16(1) << uint(exponent)
		entry.flags = u8(exponent)
		if k & 1 == 1 {
			entry.flags |= DECODE_NEGATIVE
		}
	case token == TOKEN_EOL:
		entry.flags = DECODE_RUN | DECODE_END_OF_ROW
	case:
		j := token - TOKEN_EOL
		entry.base  = u16(1) << uint(j)
		entry.flags = u8(j) | DECODE_RUN
	}
	return
}

@(init, private)
_build_tables :: proc "contextless" () {
	code := u32(0)
	for length in u8(1)..=MAX_CODE_LENGTH {
		for token in 0..<TOKEN_COUNT {
			if CODE_LENGTHS[token] != length {
				continue
			}
			encode_table[token] = {code = u16(code), length = length}

			entry := token_entry(token, length)
			shift := uint(MAX_CODE_LENGTH - length)
			for i in u32(0)..<(u32(1) << shift) {
				decode_table[code << shift | i] = entry
			}
			code += 1
		}
		code <<= 1
	}

	for e in 1..<256 {
		magnitude := abs(int(i8(u8(e))))
		negative  := 1 if i8(u8(e)) < 0 else 0
		if magnitude <= 63 {
			entry := encode_table[2 * magnitude - 1 + negative]
			residual_table[e] = u32(entry.length) << 24 | u32(entry.code)
		} else {
			exponent := 31 - int(intrinsics.count_leading_zeros(u32(magnitude)))
			entry    := encode_table[127 + 2 * (exponent - 6) + negative]
			mantissa := u32(magnitude - (int(1) << uint(exponent)))
			residual_table[e] = (u32(entry.length) + u32(exponent)) << 24 | u32(entry.code) << uint(exponent) | mantissa
		}
	}
}

@(init, private)
_register :: proc "contextless" () {
	image.register(.BNG, load_from_bytes, destroy, load_from_context)
}
