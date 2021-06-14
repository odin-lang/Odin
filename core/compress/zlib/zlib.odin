package zlib

import "core:compress"

import "core:mem"
import "core:io"
import "core:bytes"
import "core:hash"
/*
	zlib.inflate decompresses a ZLIB stream passed in as a []u8 or io.Stream.
	Returns: Error.
*/

Context :: compress.Context;

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

Error     :: compress.Error;
E_General :: compress.General_Error;
E_ZLIB    :: compress.ZLIB_Error;
E_Deflate :: compress.Deflate_Error;

DEFLATE_MAX_CHUNK_SIZE   :: 65535;
DEFLATE_MAX_LITERAL_SIZE :: 65535;
DEFLATE_MAX_DISTANCE     :: 32768;
DEFLATE_MAX_LENGTH       :: 258;

HUFFMAN_MAX_BITS  :: 16;
HUFFMAN_FAST_BITS :: 9;
HUFFMAN_FAST_MASK :: ((1 << HUFFMAN_FAST_BITS) - 1);

Z_LENGTH_BASE := [31]u16{
	3,4,5,6,7,8,9,10,11,13,15,17,19,23,27,31,35,43,51,59,
	67,83,99,115,131,163,195,227,258,0,0,
};

Z_LENGTH_EXTRA := [31]u8{
	0,0,0,0,0,0,0,0,1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,5,5,5,5,0,0,0,
};

Z_DIST_BASE := [32]u16{
	1,2,3,4,5,7,9,13,17,25,33,49,65,97,129,193,
	257,385,513,769,1025,1537,2049,3073,4097,6145,8193,12289,16385,24577,0,0,
};

Z_DIST_EXTRA := [32]u8{
	0,0,0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,0,0,
};

Z_LENGTH_DEZIGZAG := []u8{
	16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
};

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
};

Z_FIXED_DIST := [32]u8{
	5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,
};

/*
	Accelerate all cases in default tables.
*/
ZFAST_BITS :: 9;
ZFAST_MASK :: ((1 << ZFAST_BITS) - 1);

/*
	ZLIB-style Huffman encoding.
	JPEG packs from left, ZLIB from right. We can't share code.
*/
Huffman_Table :: struct {
	fast:        [1 << ZFAST_BITS]u16,
	firstcode:   [16]u16,
	maxcode:     [17]int,
	firstsymbol: [16]u16,
	size:        [288]u8,
	value:       [288]u16,
};

// Implementation starts here

z_bit_reverse :: #force_inline proc(n: u16, bits: u8) -> (r: u16) {
	assert(bits <= 16);
	// NOTE: Can optimize with llvm.bitreverse.i64 or some bit twiddling
	// by reversing all of the bits and masking out the unneeded ones.
	r = n;
	r = ((r & 0xAAAA) >>  1) | ((r & 0x5555) << 1);
	r = ((r & 0xCCCC) >>  2) | ((r & 0x3333) << 2);
	r = ((r & 0xF0F0) >>  4) | ((r & 0x0F0F) << 4);
	r = ((r & 0xFF00) >>  8) | ((r & 0x00FF) << 8);

	r >>= (16 - bits);
	return;
}

write_byte :: #force_inline proc(z: ^Context, c: u8) -> (err: io.Error) #no_bounds_check {
	c := c;
	buf := transmute([]u8)mem.Raw_Slice{data=&c, len=1};
	z.rolling_hash = hash.adler32(buf, z.rolling_hash);

	_, e := z.output->impl_write(buf);
	if e != .None {
		return e;
	}
	z.last[z.bytes_written % z.window_size] = c;

	z.bytes_written += 1;
	return .None;
}

allocate_huffman_table :: proc(allocator := context.allocator) -> (z: ^Huffman_Table, err: Error) {
	return new(Huffman_Table, allocator), nil;
}

build_huffman :: proc(z: ^Huffman_Table, code_lengths: []u8) -> (err: Error) {
	sizes:     [HUFFMAN_MAX_BITS+1]int;
	next_code: [HUFFMAN_MAX_BITS]int;

	k := int(0);

	mem.zero_slice(sizes[:]);
	mem.zero_slice(z.fast[:]);

	for v in code_lengths {
		sizes[v] += 1;
	}
	sizes[0] = 0;

	for i in 1..<(HUFFMAN_MAX_BITS+1) {
		if sizes[i] > (1 << uint(i)) {
			return E_Deflate.Huffman_Bad_Sizes;
		}
	}
	code := int(0);

	for i in 1..<HUFFMAN_MAX_BITS {
		next_code[i]     = code;
		z.firstcode[i]   = u16(code);
		z.firstsymbol[i] = u16(k);
		code = code + sizes[i];
		if sizes[i] != 0 {
			if code - 1 >= (1 << u16(i)) {
				return E_Deflate.Huffman_Bad_Code_Lengths;
			}
		}
		z.maxcode[i] = code << (HUFFMAN_MAX_BITS - uint(i));
		code <<= 1;
		k += int(sizes[i]);
	}

	z.maxcode[HUFFMAN_MAX_BITS] = 0x10000; // Sentinel
	c: int;

	for v, ci in code_lengths {
		if v != 0 {
			c = next_code[v] - int(z.firstcode[v]) + int(z.firstsymbol[v]);
			fastv := u16((u16(v) << 9) | u16(ci));
			z.size[c]  = u8(v);
			z.value[c] = u16(ci);
			if v <= ZFAST_BITS {
				j := z_bit_reverse(u16(next_code[v]), v);
				for j < (1 << ZFAST_BITS) {
					z.fast[j] = fastv;
					j += (1 << v);
				}
			}
			next_code[v] += 1;
		}
	}
	return nil;
}

decode_huffman_slowpath :: proc(z: ^Context, t: ^Huffman_Table) -> (r: u16, err: Error) #no_bounds_check {
	code := u16(compress.peek_bits_lsb(z, 16));

	k := int(z_bit_reverse(code, 16));
	s: u8;

	#no_bounds_check for s = HUFFMAN_FAST_BITS+1; ; {
		if k < t.maxcode[s] {
			break;
		}
		s += 1;
	}
	if s >= 16 {
		return 0, E_Deflate.Bad_Huffman_Code;
	}
	// code size is s, so:
	b := (k >> (16-s)) - int(t.firstcode[s]) + int(t.firstsymbol[s]);
	if b >= size_of(t.size) {
		return 0, E_Deflate.Bad_Huffman_Code;
	}
	if t.size[b] != s {
		return 0, E_Deflate.Bad_Huffman_Code;
	}

	compress.consume_bits_lsb(z, s);

	r = t.value[b];
	return r, nil;
}

decode_huffman :: proc(z: ^Context, t: ^Huffman_Table) -> (r: u16, err: Error) #no_bounds_check {
	if z.num_bits < 16 {
		if z.num_bits == -100 {
			return 0, E_ZLIB.Code_Buffer_Malformed;
		}
		compress.refill_lsb(z);
		if z.eof {
			return 0, E_General.Stream_Too_Short;
		}
	}
	#no_bounds_check b := t.fast[z.code_buffer & ZFAST_MASK];
	if b != 0 {
		s := u8(b >> ZFAST_BITS);
		compress.consume_bits_lsb(z, s);
		return b & 511, nil;
	}
	return decode_huffman_slowpath(z, t);
}

parse_huffman_block :: proc(z: ^Context, z_repeat, z_offset: ^Huffman_Table) -> (err: Error) #no_bounds_check {
	#no_bounds_check for {
		value, e := decode_huffman(z, z_repeat);
		if e != nil {
			return err;
		}
		if value < 256 {
			e := write_byte(z, u8(value));
			if e != .None {
				return E_General.Output_Too_Short;
			}
		} else {
			if value == 256 {
      				// End of block
      				return nil;
			}

			value -= 257;
			length := Z_LENGTH_BASE[value];
			if Z_LENGTH_EXTRA[value] > 0 {
				length += u16(compress.read_bits_lsb(z, Z_LENGTH_EXTRA[value]));
			}

			value, e = decode_huffman(z, z_offset);
			if e != nil {
				return E_Deflate.Bad_Huffman_Code;
			}

			distance := Z_DIST_BASE[value];
			if Z_DIST_EXTRA[value] > 0 {
				distance += u16(compress.read_bits_lsb(z, Z_DIST_EXTRA[value]));
			}

			if z.bytes_written < i64(distance) {
				// Distance is longer than we've decoded so far.
				return E_Deflate.Bad_Distance;
			}

			offset := i64(z.bytes_written - i64(distance));
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
					b, e := compress.peek_back_byte(z, offset);
					if e != .None {
						return E_General.Output_Too_Short;
					}
					#no_bounds_check for _ in 0..<length {
						write_byte(z, b);
					}
				}
			} else {
				if length > 0 {
					#no_bounds_check for _ in 0..<length {
						b, e := compress.peek_back_byte(z, offset);
						if e != .None {
							return E_General.Output_Too_Short;
						}
						write_byte(z, b);
						offset += 1;
					}
				}
			}
		}
	}
}

inflate_from_stream :: proc(using ctx: ^Context, raw := false, allocator := context.allocator) -> (err: Error) #no_bounds_check {
	/*
		ctx.input must be an io.Stream backed by an implementation that supports:
		- read
		- size

		ctx.output must be an io.Stream backed by an implementation that supports:
		- write

		raw determines whether the ZLIB header is processed, or we're inflating a raw
		DEFLATE stream.
	*/

	if !raw {
		data_size := io.size(ctx.input);
		if data_size < 6 {
			return E_General.Stream_Too_Short;
		}

		cmf, _ := compress.read_u8(ctx);

		method := Compression_Method(cmf & 0xf);
		if method != .DEFLATE {
			return E_General.Unknown_Compression_Method;
		}

		cinfo  := (cmf >> 4) & 0xf;
		if cinfo > 7 {
			return E_ZLIB.Unsupported_Window_Size;
		}
		ctx.window_size = 1 << (cinfo + 8);

		flg, _ := compress.read_u8(ctx);

		fcheck  := flg & 0x1f;
		fcheck_computed := (cmf << 8 | flg) & 0x1f;
		if fcheck != fcheck_computed {
			return E_General.Checksum_Failed;
		}

		fdict   := (flg >> 5) & 1;
		/*
			We don't handle built-in dictionaries for now.
			They're application specific and PNG doesn't use them.
		*/
		if fdict != 0 {
			return E_ZLIB.FDICT_Unsupported;
		}

		// flevel  := Compression_Level((flg >> 6) & 3);
		/*
			Inflate can consume bits belonging to the Adler checksum.
			We pass the entire stream to Inflate and will unget bytes if we need to
			at the end to compare checksums.
		*/

		// Seed the Adler32 rolling checksum.
		ctx.rolling_hash = 1;
	}

 	// Parse ZLIB stream without header.
	err = inflate_raw(ctx);
	if err != nil {
		return err;
	}

	if !raw {
		compress.discard_to_next_byte_lsb(ctx);

		adler32 := compress.read_bits_lsb(ctx, 8) << 24 | compress.read_bits_lsb(ctx, 8) << 16 | compress.read_bits_lsb(ctx, 8) << 8 | compress.read_bits_lsb(ctx, 8);
		if ctx.rolling_hash != u32(adler32) {
			return E_General.Checksum_Failed;
		}
	}
	return nil;
}

// @(optimization_mode="speed")
inflate_from_stream_raw :: proc(z: ^Context, allocator := context.allocator) -> (err: Error) #no_bounds_check {
	final := u32(0);
	type := u32(0);

	z.num_bits = 0;
	z.code_buffer = 0;

	z_repeat:      ^Huffman_Table;
	z_offset:      ^Huffman_Table;
	codelength_ht: ^Huffman_Table;

	z_repeat, err = allocate_huffman_table(allocator=context.allocator);
	if err != nil {
		return err;
	}
	z_offset, err = allocate_huffman_table(allocator=context.allocator);
	if err != nil {
		return err;
	}
	codelength_ht, err = allocate_huffman_table(allocator=context.allocator);
	if err != nil {
		return err;
	}
	defer free(z_repeat);
	defer free(z_offset);
	defer free(codelength_ht);

	if z.window_size == 0 {
		z.window_size = DEFLATE_MAX_DISTANCE;
	}

	// Allocate rolling window buffer.
	last_b := mem.make_dynamic_array_len_cap([dynamic]u8, z.window_size, z.window_size, allocator);
	z.last = &last_b;
	defer delete(last_b);

	for {
		final = compress.read_bits_lsb(z, 1);
		type  = compress.read_bits_lsb(z, 2);

		// fmt.printf("Final: %v | Type: %v\n", final, type);

		switch type {
		case 0:
			// Uncompressed block

			// Discard bits until next byte boundary
			compress.discard_to_next_byte_lsb(z);

			uncompressed_len  := i16(compress.read_bits_lsb(z, 16));
			length_check      := i16(compress.read_bits_lsb(z, 16));

			// fmt.printf("LEN: %v, ~LEN: %v, NLEN: %v, ~NLEN: %v\n", uncompressed_len, ~uncompressed_len, length_check, ~length_check);


			if ~uncompressed_len != length_check {
				return E_Deflate.Len_Nlen_Mismatch;
			}

			/*
				TODO: Maybe speed this up with a stream-to-stream copy (read_from)
				and a single Adler32 update after.
			*/
			#no_bounds_check for uncompressed_len > 0 {
				compress.refill_lsb(z);
				lit := compress.read_bits_lsb(z, 8);
				write_byte(z, u8(lit));
				uncompressed_len -= 1;
			}
		case 3:
			return E_Deflate.BType_3;
		case:
			// log.debugf("Err: %v | Final: %v | Type: %v\n", err, final, type);
			if type == 1 {
				// Use fixed code lengths.
				err = build_huffman(z_repeat, Z_FIXED_LENGTH[:]);
				if err != nil {
					return err;
				}
				err = build_huffman(z_offset, Z_FIXED_DIST[:]);
				if err != nil {
					return err;
				}
			} else {
				lencodes: [286+32+137]u8;
				codelength_sizes: [19]u8;

				//i: u32;
				n: u32;

				compress.refill_lsb(z, 14);
				hlit  := compress.read_bits_no_refill_lsb(z, 5) + 257;
				hdist := compress.read_bits_no_refill_lsb(z, 5) + 1;
				hclen := compress.read_bits_no_refill_lsb(z, 4) + 4;
				ntot  := hlit + hdist;

				#no_bounds_check for i in 0..<hclen {
					s := compress.read_bits_lsb(z, 3);
					codelength_sizes[Z_LENGTH_DEZIGZAG[i]] = u8(s);
				}
				err = build_huffman(codelength_ht, codelength_sizes[:]);
				if err != nil {
					return err;
				}

				n = 0;
				c: u16;

				for n < ntot {
					c, err = decode_huffman(z, codelength_ht);
					if err != nil {
						return err;
					}

					if c < 0 || c >= 19 {
						return E_Deflate.Huffman_Bad_Code_Lengths;
					}
					if c < 16 {
						lencodes[n] = u8(c);
						n += 1;
					} else {
						fill := u8(0);
						compress.refill_lsb(z, 7);
						switch c {
						case 16:
							c = u16(compress.read_bits_no_refill_lsb(z, 2) + 3);
							if n == 0 {
								return E_Deflate.Huffman_Bad_Code_Lengths;
							}
							fill = lencodes[n - 1];
						case 17:
							c = u16(compress.read_bits_no_refill_lsb(z, 3) + 3);
						case 18:
							c = u16(compress.read_bits_no_refill_lsb(z, 7) + 11);
						case:
					         	return E_Deflate.Huffman_Bad_Code_Lengths;
						}

						if ntot - n < u32(c) {
							return E_Deflate.Huffman_Bad_Code_Lengths;
						}

						nc := n + u32(c);
						#no_bounds_check for ; n < nc; n += 1 {
							lencodes[n] = fill;
						}
					}
				}

				if n != ntot {
					return E_Deflate.Huffman_Bad_Code_Lengths;
				}

				err = build_huffman(z_repeat, lencodes[:hlit]);
				if err != nil {
					return err;
				}

				err = build_huffman(z_offset, lencodes[hlit:ntot]);
				if err != nil {
					return err;
				}
			}
			err = parse_huffman_block(z, z_repeat, z_offset);
			// log.debugf("Err: %v | Final: %v | Type: %v\n", err, final, type);
			if err != nil {
				return err;
			}
		}
		if final == 1 {
			break;
		}
	}
	return nil;
}

inflate_from_byte_array :: proc(input: []u8, buf: ^bytes.Buffer, raw := false) -> (err: Error) {
	ctx := Context{};

	r := bytes.Reader{};
	bytes.reader_init(&r, input);
	rs := bytes.reader_to_stream(&r);
	ctx.input = rs;

	buf := buf;
	ws := bytes.buffer_to_stream(buf);
	ctx.output = ws;

	err = inflate_from_stream(&ctx, raw);

	return err;
}

inflate_from_byte_array_raw :: proc(input: []u8, buf: ^bytes.Buffer, raw := false) -> (err: Error) {
	return inflate_from_byte_array(input, buf, true);
}

inflate     :: proc{inflate_from_stream, inflate_from_byte_array};
inflate_raw :: proc{inflate_from_stream_raw, inflate_from_byte_array_raw};
