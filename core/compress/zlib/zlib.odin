//+vet !using-param
package compress_zlib

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
		Ginger Bill:     Cosmetic changes.
*/

import "core:compress"

import "base:intrinsics"
import "core:mem"
import "core:io"
import "core:hash"
import "core:bytes"

/*
	zlib.inflate decompresses a ZLIB stream passed in as a []u8 or io.Stream.
	Returns: Error.
*/

/*
	Do we do Adler32 as we write bytes to output?
	It used to be faster to do it inline, now it's faster to do it at the end of `inflate`.

	We'll see what's faster after more optimization, and might end up removing
	`Context.rolling_hash` if not inlining it is still faster.

*/

Compression_Method :: enum u8 {
	DEFLATE  = 8,
	Reserved = 15,
}

Compression_Level :: enum u8 {
	Fastest = 0,
	Fast    = 1,
	Default = 2,
	Maximum = 3,
}

Options :: struct {
	window_size: u16,
	level: u8,
}

Error         :: compress.Error
General_Error :: compress.General_Error
ZLIB_Error    :: compress.ZLIB_Error
Deflate_Error :: compress.Deflate_Error

DEFLATE_MAX_CHUNK_SIZE   :: 65535
DEFLATE_MAX_LITERAL_SIZE :: 65535
DEFLATE_MAX_DISTANCE     :: 32768
DEFLATE_MAX_LENGTH       :: 258

HUFFMAN_MAX_BITS  :: 16
HUFFMAN_FAST_BITS :: 9
HUFFMAN_FAST_MASK :: ((1 << HUFFMAN_FAST_BITS) - 1)

Z_LENGTH_BASE := [31]u16{
	3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,
	67,83,99,115,131,163,195,227,258,0,0,
}

Z_LENGTH_EXTRA := [31]u8{
	0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0,
}

Z_DIST_BASE := [32]u16{
	1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
	257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577,0,0,
}

Z_DIST_EXTRA := [32]u8{
	0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,0,0,
}

Z_LENGTH_DEZIGZAG := []u8{
	16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
}

Z_FIXED_LENGTH := [288]u8{
	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
	9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
	9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
	9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,
	7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, 7,7,7,7,7,7,7,7,8,8,8,8,8,8,8,8,
}

Z_FIXED_DIST := [32]u8{
	5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
}

/*
	Accelerate all cases in default tables.
*/
ZFAST_BITS :: 9
ZFAST_MASK :: ((1 << ZFAST_BITS) - 1)

/*
	ZLIB-style Huffman encoding.
	JPEG packs from left, ZLIB from right. We can't share code.
*/
Huffman_Table :: struct {
	fast:        [1 << ZFAST_BITS]u16,
	firstcode:   [17]u16,
	maxcode:     [17]int,
	firstsymbol: [17]u16,
	size:        [288]u8,
	value:       [288]u16,
}

// Implementation starts here
@(optimization_mode="favor_size")
z_bit_reverse :: #force_inline proc(n: u16, bits: u8) -> (r: u16) {
	assert(bits <= 16)
	r = intrinsics.reverse_bits(n)

	r >>= (16 - bits)
	return
}


@(optimization_mode="favor_size")
grow_buffer :: proc(buf: ^[dynamic]u8) -> (err: compress.Error) {
	/*
		That we get here at all means that we didn't pass an expected output size,
		or that it was too little.
	*/

	/*
		Double until we reach the maximum allowed.
	*/
	new_size := min(len(buf) << 1, compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
	return resize(buf, new_size)
}

/*
	TODO: Make these return compress.Error.
*/

@(optimization_mode="favor_size")
write_byte :: #force_inline proc(z: ^$C, c: u8) -> (err: io.Error) #no_bounds_check {
	/*
		Resize if needed.
	*/
	if int(z.bytes_written) + 1 >= len(z.output.buf) {
		e := grow_buffer(&z.output.buf)
		if e != nil {
			return .Short_Write
		}
	}

	#no_bounds_check {
		z.output.buf[z.bytes_written] = c
	}
	z.bytes_written += 1
	return .None
}

@(optimization_mode="favor_size")
repl_byte :: proc(z: ^$C, count: u16, c: u8) -> (err: io.Error) #no_bounds_check {
	/*
		TODO(Jeroen): Once we have a magic ring buffer, we can just peek/write into it
		without having to worry about wrapping, so no need for a temp allocation to give to
		the output stream, just give it _that_ slice.
	*/

	/*
	Resize if needed.
	*/
	if int(z.bytes_written) + int(count) >= len(z.output.buf) {
		e := grow_buffer(&z.output.buf)
		if e != nil {
			return .Short_Write
		}
	}

	#no_bounds_check {
		for _ in 0..<count {
			z.output.buf[z.bytes_written] = c
			z.bytes_written += 1
		}
	}

	return .None
}

@(optimization_mode="favor_size")
repl_bytes :: proc(z: ^$C, count: u16, distance: u16) -> (err: io.Error) {
	/*
		TODO(Jeroen): Once we have a magic ring buffer, we can just peek/write into it
		without having to worry about wrapping, so no need for a temp allocation to give to
		the output stream, just give it _that_ slice.
	*/

	offset := i64(distance)

	if int(z.bytes_written) + int(count) >= len(z.output.buf) {
		e := grow_buffer(&z.output.buf)
		if e != nil {
			return .Short_Write
		}
	}

	#no_bounds_check {
		for _ in 0..<count {
			c := z.output.buf[z.bytes_written - offset]
			z.output.buf[z.bytes_written] = c
			z.bytes_written += 1
		}
	}

	return .None
}


allocate_huffman_table :: proc(allocator := context.allocator) -> (z: ^Huffman_Table, err: Error) {
	return new(Huffman_Table, allocator), nil
}

@(optimization_mode="favor_size")
build_huffman :: #force_no_inline proc(z: ^Huffman_Table, code_lengths: []u8) -> (err: Error) {
	sizes:     [HUFFMAN_MAX_BITS+1]int
	next_code: [HUFFMAN_MAX_BITS+1]int

	k := int(0)

	mem.zero_slice(sizes[:])
	mem.zero_slice(z.fast[:])

	for v in code_lengths {
		sizes[v] += 1
	}
	sizes[0] = 0

	for i in 1 ..< HUFFMAN_MAX_BITS {
		if sizes[i] > (1 << uint(i)) {
			return .Huffman_Bad_Sizes
		}
	}
	code := int(0)

	for i in 1 ..= HUFFMAN_MAX_BITS {
		next_code[i]     = code
		z.firstcode[i]   = u16(code)
		z.firstsymbol[i] = u16(k)
		code = code + sizes[i]
		if sizes[i] != 0 {
			if code - 1 >= (1 << u16(i)) {
				return .Huffman_Bad_Code_Lengths
			}
		}
		z.maxcode[i] = code << (HUFFMAN_MAX_BITS - uint(i))
		code <<= 1
		k += int(sizes[i])
	}

	z.maxcode[HUFFMAN_MAX_BITS] = 0x10000 // Sentinel
	c: int

	for v, ci in code_lengths {
		if v != 0 {
			c = next_code[v] - int(z.firstcode[v]) + int(z.firstsymbol[v])
			fastv := u16((u16(v) << 9) | u16(ci))
			z.size[c]  = u8(v)
			z.value[c] = u16(ci)
			if v <= ZFAST_BITS {
				j := z_bit_reverse(u16(next_code[v]), v)
				for j < (1 << ZFAST_BITS) {
					z.fast[j] = fastv
					j += (1 << v)
				}
			}
			next_code[v] += 1
		}
	}
	return nil
}

@(optimization_mode="favor_size")
decode_huffman_slowpath :: proc(z: ^$C, t: ^Huffman_Table) -> (r: u16, err: Error) #no_bounds_check {
	code := u16(compress.peek_bits_lsb(z,16))

	k := int(z_bit_reverse(code, 16))

	s: u8 = HUFFMAN_FAST_BITS+1
	for {
		#no_bounds_check if k < t.maxcode[s] {
			break
		}
		s += 1
	}
	if s >= 16 {
		return 0, .Bad_Huffman_Code
	}
	// code size is s, so:
	b := (k >> (16-s)) - int(t.firstcode[s]) + int(t.firstsymbol[s])
	if b >= size_of(t.size) {
		return 0, .Bad_Huffman_Code
	}
	if t.size[b] != s {
		return 0, .Bad_Huffman_Code
	}

	compress.consume_bits_lsb(z, s)

	r = t.value[b]
	return r, nil
}

@(optimization_mode="favor_size")
decode_huffman :: proc(z: ^$C, t: ^Huffman_Table) -> (r: u16, err: Error) #no_bounds_check {
	if z.num_bits < 16 {
		if z.num_bits > 63 {
			return 0, .Code_Buffer_Malformed
		}
		compress.refill_lsb(z)
		if z.num_bits > 63 {
			return 0, .Stream_Too_Short
		}
	}
	#no_bounds_check b := t.fast[z.code_buffer & ZFAST_MASK]
	if b != 0 {
		s := u8(b >> ZFAST_BITS)
		compress.consume_bits_lsb(z, s)
		return b & 511, nil
	}
	return decode_huffman_slowpath(z, t)
}

@(optimization_mode="favor_size")
parse_huffman_block :: proc(z: ^$C, z_repeat, z_offset: ^Huffman_Table) -> (err: Error) #no_bounds_check {
	#no_bounds_check for {
		value, e := decode_huffman(z, z_repeat)
		if e != nil {
			return err
		}
		if value < 256 {
			e := write_byte(z, u8(value))
			if e != .None {
				return .Output_Too_Short
			}
		} else {
			if value == 256 {
					// End of block
					return nil
			}

			value -= 257
			length := Z_LENGTH_BASE[value]
			if Z_LENGTH_EXTRA[value] > 0 {
				length += u16(compress.read_bits_lsb(z, Z_LENGTH_EXTRA[value]))
			}

			value, e = decode_huffman(z, z_offset)
			if e != nil {
				return .Bad_Huffman_Code
			}

			distance := Z_DIST_BASE[value]
			if Z_DIST_EXTRA[value] > 0 {
				distance += u16(compress.read_bits_lsb(z, Z_DIST_EXTRA[value]))
			}

			if z.bytes_written < i64(distance) {
				// Distance is longer than we've decoded so far.
				return .Bad_Distance
			}

			/*
				These might be sped up with a repl_byte call that copies
				from the already written output more directly, and that
				update the Adler checksum once after.

				That way we'd suffer less Stream vtable overhead.
			*/
			if distance == 1 {
				/*
					Replicate the last outputted byte, length times.
				*/
				if length > 0 {
					c := z.output.buf[z.bytes_written - i64(distance)]
					e := repl_byte(z, length, c)
					if e != .None {
						return .Output_Too_Short
					}
				}
			} else {
				if length > 0 {
					e := repl_bytes(z, length, distance)
					if e != .None {
						return .Output_Too_Short
					}
				}
			}
		}
	}
}

@(optimization_mode="favor_size")
inflate_from_context :: proc(using ctx: ^compress.Context_Memory_Input, raw := false, expected_output_size := -1, allocator := context.allocator) -> (err: Error) #no_bounds_check {
	/*
		ctx.output must be a bytes.Buffer for now. We'll add a separate implementation that writes to a stream.

		raw determines whether the ZLIB header is processed, or we're inflating a raw
		DEFLATE stream.
	*/

	if !raw {
		size, size_err := compress.input_size(ctx)
		if size < 6 || size_err != nil {
			return .Stream_Too_Short
		}

		cmf, _ := compress.read_u8(ctx)

		method := Compression_Method(cmf & 0xf)
		if method != .DEFLATE {
			return .Unknown_Compression_Method
		}

		if cinfo := (cmf >> 4) & 0xf; cinfo > 7 {
			return .Unsupported_Window_Size
		}
		flg, _ := compress.read_u8(ctx)

		fcheck := flg & 0x1f
		fcheck_computed := (cmf << 8 | flg) & 0x1f
		if fcheck != fcheck_computed {
			return .Checksum_Failed
		}

		/*
			We don't handle built-in dictionaries for now.
			They're application specific and PNG doesn't use them.
		*/
		if fdict := (flg >> 5) & 1; fdict != 0 {
			return .FDICT_Unsupported
		}

		// flevel  := Compression_Level((flg >> 6) & 3);
		/*
			Inflate can consume bits belonging to the Adler checksum.
			We pass the entire stream to Inflate and will unget bytes if we need to
			at the end to compare checksums.
		*/

	}

	// Parse ZLIB stream without header.
	inflate_raw(ctx, expected_output_size=expected_output_size) or_return

	if !raw {
		compress.discard_to_next_byte_lsb(ctx)

		adler_b: [4]u8
		for _, i in adler_b {
			adler_b[i], _ = compress.read_u8_prefer_code_buffer_lsb(ctx)
		}
		adler := transmute(u32be)adler_b

		output_hash := hash.adler32(ctx.output.buf[:])

		if output_hash != u32(adler) {
			return .Checksum_Failed
		}
	}
	return nil
}

// TODO: Check alignment of reserve/resize.

@(optimization_mode="favor_size")
inflate_raw :: proc(z: ^$C, expected_output_size := -1, allocator := context.allocator) -> (err: Error) #no_bounds_check {
	context.allocator = allocator
	expected_output_size := expected_output_size

	/*
		Always set up a minimum allocation size.
	*/
	expected_output_size = max(max(expected_output_size, compress.COMPRESS_OUTPUT_ALLOCATE_MIN), 512)

	// fmt.printf("\nZLIB: Expected Payload Size: %v\n\n", expected_output_size);

	if expected_output_size > 0 && expected_output_size <= compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		/*
			Try to pre-allocate the output buffer.
		*/
		reserve(&z.output.buf, expected_output_size) or_return
		resize (&z.output.buf, expected_output_size) or_return
	}

	if len(z.output.buf) != expected_output_size {
		return .Resize_Failed
	}

	z.num_bits    = 0
	z.code_buffer = 0

	z_repeat:      ^Huffman_Table
	z_offset:      ^Huffman_Table
	codelength_ht: ^Huffman_Table
	defer free(z_repeat)
	defer free(z_offset)
	defer free(codelength_ht)

	z_repeat      = allocate_huffman_table() or_return
	z_offset      = allocate_huffman_table() or_return
	codelength_ht = allocate_huffman_table() or_return

	final := u32(0)
	type  := u32(0)

	for {
		final = compress.read_bits_lsb(z, 1)
		type  = compress.read_bits_lsb(z, 2)

		// fmt.printf("Final: %v | Type: %v\n", final, type)

		switch type {
		case 0:
			// fmt.printf("Method 0: STORED\n")
			// Uncompressed block

			// Discard bits until next byte boundary
			compress.discard_to_next_byte_lsb(z)

			uncompressed_len := u16(compress.read_bits_lsb(z, 16))
			length_check     := u16(compress.read_bits_lsb(z, 16))

			// fmt.printf("LEN: %v, ~LEN: %v, NLEN: %v, ~NLEN: %v\n", uncompressed_len, ~uncompressed_len, length_check, ~length_check)


			if ~uncompressed_len != length_check {
				return .Len_Nlen_Mismatch
			}

			/*
				TODO: Maybe speed this up with a stream-to-stream copy (read_from)
				and a single Adler32 update after.
			*/
			#no_bounds_check for uncompressed_len > 0 {
				compress.refill_lsb(z)
				lit := compress.read_bits_lsb(z, 8)
				write_byte(z, u8(lit))
				uncompressed_len -= 1
			}
			assert(uncompressed_len == 0)

		case 3:
			return .BType_3
		case:
			// fmt.printf("Err: %v | Final: %v | Type: %v\n", err, final, type)
			if type == 1 {
				// Use fixed code lengths.
				build_huffman(z_repeat, Z_FIXED_LENGTH[:]) or_return
				build_huffman(z_offset, Z_FIXED_DIST[:])  or_return
			} else {
				lencodes: [286+32+137]u8
				codelength_sizes: [19]u8

				//i: u32;
				n: u32

				compress.refill_lsb(z, 14)
				hlit  := compress.read_bits_no_refill_lsb(z, 5) + 257
				hdist := compress.read_bits_no_refill_lsb(z, 5) + 1
				hclen := compress.read_bits_no_refill_lsb(z, 4) + 4
				ntot  := hlit + hdist

				#no_bounds_check for i in 0..<hclen {
					s := compress.read_bits_lsb(z, 3)
					codelength_sizes[Z_LENGTH_DEZIGZAG[i]] = u8(s)
				}
				build_huffman(codelength_ht, codelength_sizes[:]) or_return

				n = 0
				c: u16

				for n < ntot {
					c = decode_huffman(z, codelength_ht) or_return

					if c < 0 || c >= 19 {
						return .Huffman_Bad_Code_Lengths
					}
					if c < 16 {
						lencodes[n] = u8(c)
						n += 1
					} else {
						fill := u8(0)
						compress.refill_lsb(z, 7)
						switch c {
						case 16:
							c = u16(compress.read_bits_no_refill_lsb(z, 2) + 3)
							if n == 0 {
								return .Huffman_Bad_Code_Lengths
							}
							fill = lencodes[n - 1]
						case 17:
							c = u16(compress.read_bits_no_refill_lsb(z, 3) + 3)
						case 18:
							c = u16(compress.read_bits_no_refill_lsb(z, 7) + 11)
						case:
								return .Huffman_Bad_Code_Lengths
						}

						if ntot - n < u32(c) {
							return .Huffman_Bad_Code_Lengths
						}

						nc := n + u32(c)
						#no_bounds_check for ; n < nc; n += 1 {
							lencodes[n] = fill
						}
					}
				}

				if n != ntot {
					return .Huffman_Bad_Code_Lengths
				}

				build_huffman(z_repeat, lencodes[:hlit])     or_return
				build_huffman(z_offset, lencodes[hlit:ntot]) or_return
			}
			parse_huffman_block(z, z_repeat, z_offset) or_return
		}
		if final == 1 {
			break
		}
	}

	if int(z.bytes_written) != len(z.output.buf) {
		resize(&z.output.buf, int(z.bytes_written)) or_return
	}

	return nil
}

inflate_from_byte_array :: proc(input: []u8, buf: ^bytes.Buffer, raw := false, expected_output_size := -1) -> (err: Error) {
	ctx := compress.Context_Memory_Input{}

	ctx.input_data = input
	ctx.output = buf

	return inflate_from_context(&ctx, raw=raw, expected_output_size=expected_output_size)
}

inflate_from_byte_array_raw :: proc(input: []u8, buf: ^bytes.Buffer, raw := false, expected_output_size := -1) -> (err: Error) {
	ctx := compress.Context_Memory_Input{}

	ctx.input_data = input
	ctx.output = buf

	return inflate_raw(&ctx, expected_output_size=expected_output_size)
}

inflate :: proc{inflate_from_context, inflate_from_byte_array}