package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:compress/xz"
import "core:io"
import "core:testing"

Declared_Codec :: enum {
	Deflate,
	Zlib,
	Gzip,
	Deflate64,
	BZip2,
	LZ4_Frame,
	LZ4_Frame_Sized,
	LZ4_Block,
	PPMd_H,
	PPMd_I,
	LZMA,
	LZMA_Raw,
	LZMA2,
	XZ,
}

Declared_Path :: enum {
	Bytes,
	Context_Memory,
	Context_Stream,
	Writer_Memory,
	Writer_Stream,
	Reader_Memory,
	Reader_Stream,
}

Declared_Stream :: struct {
	packed:     [dynamic]byte,
	ppmd_props: ppmd.Properties,
	lzma_props: lzma.Properties,
	dict_size:  u32,
}

DECLARED_SIZE_INPUT :: 70_000

@(test)
declared_size_is_exact :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0xdec1}
	data := lz4_test_lcg_text(&g, DECLARED_SIZE_INPUT)
	defer delete(data)

	for codec in Declared_Codec {
		s := declared_encode(t, codec, data)
		defer delete(s.packed)

		for path in Declared_Path {
			if codec == .LZ4_Block && path > .Context_Stream {
				continue
			}
			for delta in ([]int{-1, 0, 1}) {
				expected := len(data) + delta
				out: [dynamic]byte
				err := declared_decode(codec, path, &s, expected, &out)
				want: compress.Error = nil if delta == 0 else compress.General_Error.Size_Mismatch
				testing.expectf(t, err == want, "%v %v declared %+d: got %v, want %v", codec, path, delta, err, want)
				if delta == 0 && err == nil {
					testing.expectf(t, bytes.equal(out[:], data), "%v %v: output differs (%v of %v bytes)", codec, path, len(out), len(data))
				}
				delete(out)
			}
			out: [dynamic]byte
			err := declared_decode(codec, path, &s, -1, &out)
			testing.expectf(t, err == nil && bytes.equal(out[:], data), "%v %v undeclared: %v, %v of %v bytes", codec, path, err, len(out), len(data))
			delete(out)
		}
	}
}

declared_encode :: proc(t: ^testing.T, codec: Declared_Codec, data: []byte) -> (s: Declared_Stream) {
	err: compress.Error
	switch codec {
	case .Deflate:
		err = deflate.compress_raw_to_dynamic(&s.packed, data)
	case .Zlib:
		err = deflate.compress_zlib_to_dynamic(&s.packed, data)
	case .Gzip:
		err = deflate.compress_gzip_to_dynamic(&s.packed, data)
	case .Deflate64:
		err = deflate.compress_raw64_to_dynamic(&s.packed, data)
	case .BZip2:
		err = bzip2.compress_to_dynamic(&s.packed, data)
	case .LZ4_Frame:
		err = lz4.compress_frame_to_dynamic(&s.packed, data, .Level_1, {flags = {.Content_Checksum}})
	case .LZ4_Frame_Sized:
		err = lz4.compress_frame_to_dynamic(&s.packed, data, .Level_1, {flags = lz4.DEFAULT_FRAME_FLAGS})
	case .LZ4_Block:
		err = lz4.compress_block_to_dynamic(&s.packed, data)
	case .PPMd_H, .PPMd_I:
		s.ppmd_props = ppmd.level_properties(.H if codec == .PPMd_H else .I, .Default, len(data))
		err = ppmd.compress_to_dynamic(&s.packed, data, s.ppmd_props, true)
	case .LZMA:
		err = lzma.compress_to_dynamic(&s.packed, data)
	case .LZMA_Raw:
		options := lzma.level_options()
		options.end_marker = true
		s.lzma_props, err = lzma.compress_raw_to_dynamic(&s.packed, data, options)
	case .LZMA2:
		props: lzma.Properties
		props, err = lzma.compress_lzma2_to_dynamic(&s.packed, data, lzma.level_options())
		s.dict_size = props.dict_size
	case .XZ:
		err = xz.compress_to_dynamic(&s.packed, data)
	}
	testing.expectf(t, err == nil, "%v: encode failed: %v", codec, err)
	return
}

declared_decode :: proc(codec: Declared_Codec, path: Declared_Path, s: ^Declared_Stream, expected: int, out: ^[dynamic]byte) -> (err: compress.Error) {
	input := s.packed[:]
	if path == .Bytes {
		switch codec {
		case .Deflate:          return deflate.decompress_raw_from_bytes(out, input, expected)
		case .Zlib:             return deflate.decompress_zlib_from_bytes(out, input, expected)
		case .Gzip:             return deflate.decompress_gzip_from_bytes(out, input, expected)
		case .Deflate64:        return deflate.decompress_raw64_from_bytes(out, input, expected)
		case .BZip2:            return bzip2.decompress_from_bytes(out, input, expected)
		case .LZ4_Frame, .LZ4_Frame_Sized:
			return lz4.decompress_frame_from_bytes(out, input, expected)
		case .LZ4_Block:        return lz4.decompress_block_from_bytes(out, input, expected)
		case .PPMd_H, .PPMd_I:  return ppmd.decompress_from_bytes(out, input, s.ppmd_props, expected)
		case .LZMA:             return lzma.decompress_from_bytes(out, input, expected)
		case .LZMA_Raw:         return lzma.decompress_raw_from_bytes(out, input, s.lzma_props, expected)
		case .LZMA2:            return lzma.decompress_lzma2_from_bytes(out, input, s.dict_size, expected)
		case .XZ:               return xz.decompress_from_bytes(out, input, {}, expected)
		}
	}

	br: bytes.Reader
	ctx: compress.Context
	streamed := path == .Context_Stream || path == .Writer_Stream || path == .Reader_Stream
	if streamed {
		ctx = compress.init_context(bytes.reader_init(&br, input))
	} else {
		ctx = compress.init_context(&input)
	}
	defer compress.destroy_context(&ctx)

	switch path {
	case .Bytes:
	case .Context_Memory, .Context_Stream:
		ctx.output = out
		switch codec {
		case .Deflate:          return deflate.decompress_raw_from_context(&ctx, expected)
		case .Zlib:             return deflate.decompress_zlib_from_context(&ctx, expected)
		case .Gzip:             return deflate.decompress_gzip_from_context(&ctx, expected)
		case .Deflate64:        return deflate.decompress_raw64_from_context(&ctx, expected)
		case .BZip2:            return bzip2.decompress_from_context(&ctx, expected)
		case .LZ4_Frame, .LZ4_Frame_Sized:
			return lz4.decompress_frame_from_context(&ctx, expected)
		case .LZ4_Block:        return lz4.decompress_block_from_context(&ctx, expected)
		case .PPMd_H, .PPMd_I:  return ppmd.decompress_from_context(&ctx, s.ppmd_props, expected)
		case .LZMA:             return lzma.decompress_from_context(&ctx, expected)
		case .LZMA_Raw:         return lzma.decompress_raw_from_context(&ctx, s.lzma_props, expected)
		case .LZMA2:            return lzma.decompress_lzma2_from_context(&ctx, s.dict_size, expected)
		case .XZ:               return xz.decompress_from_context(&ctx, {}, expected)
		}
	case .Writer_Memory, .Writer_Stream:
		buf: bytes.Buffer
		defer bytes.buffer_destroy(&buf)
		w := bytes.buffer_to_stream(&buf)
		switch codec {
		case .Deflate:          err = deflate.decompress_raw_to_writer(w, &ctx, expected)
		case .Zlib:             err = deflate.decompress_zlib_to_writer(w, &ctx, expected)
		case .Gzip:             err = deflate.decompress_gzip_to_writer(w, &ctx, expected)
		case .Deflate64:        err = deflate.decompress_raw64_to_writer(w, &ctx, expected)
		case .BZip2:            err = bzip2.decompress_to_writer(w, &ctx, expected)
		case .LZ4_Frame, .LZ4_Frame_Sized:
			err = lz4.decompress_frame_to_writer(w, &ctx, expected)
		case .LZ4_Block:        err = compress.General_Error.Unimplemented
		case .PPMd_H, .PPMd_I:  err = ppmd.decompress_to_writer(w, &ctx, s.ppmd_props, expected)
		case .LZMA:             err = lzma.decompress_to_writer(w, &ctx, expected)
		case .LZMA_Raw:         err = lzma.decompress_raw_to_writer(w, &ctx, s.lzma_props, expected)
		case .LZMA2:            err = lzma.decompress_lzma2_to_writer(w, &ctx, s.dict_size, expected)
		case .XZ:               err = xz.decompress_to_writer(w, &ctx, {}, expected)
		}
		append(out, ..bytes.buffer_to_bytes(&buf))
		return
	case .Reader_Memory, .Reader_Stream:
		switch codec {
		case .Deflate, .Zlib, .Gzip, .Deflate64:
			formats := #partial [Declared_Codec]deflate.Format{.Deflate = .Raw, .Zlib = .Zlib, .Gzip = .Gzip, .Deflate64 = .Raw64}
			r: deflate.Reader
			deflate.reader_init(&r, &ctx, formats[codec], expected) or_return
			defer deflate.reader_destroy(&r)
			return declared_read_all(&r, deflate.reader_read, out)
		case .BZip2:
			r: bzip2.Reader
			bzip2.reader_init(&r, &ctx, expected) or_return
			defer bzip2.reader_destroy(&r)
			return declared_read_all(&r, bzip2.reader_read, out)
		case .LZ4_Frame, .LZ4_Frame_Sized:
			r: lz4.Frame_Reader
			lz4.frame_reader_init(&r, &ctx, expected) or_return
			defer lz4.frame_reader_destroy(&r)
			return declared_read_all(&r, lz4.frame_reader_read, out)
		case .LZ4_Block:
			return compress.General_Error.Unimplemented
		case .PPMd_H, .PPMd_I:
			r: ppmd.Reader
			ppmd.reader_init(&r, &ctx, s.ppmd_props, expected) or_return
			defer ppmd.reader_destroy(&r)
			return declared_read_all(&r, ppmd.reader_read, out)
		case .LZMA, .LZMA_Raw, .LZMA2:
			r: lzma.Reader
			#partial switch codec {
			case .LZMA:     lzma.reader_init(&r, &ctx, expected) or_return
			case .LZMA_Raw: lzma.reader_init_raw(&r, &ctx, s.lzma_props, expected) or_return
			case .LZMA2:    lzma.reader_init_lzma2(&r, &ctx, s.dict_size, expected) or_return
			}
			defer lzma.reader_destroy(&r)
			return declared_read_all(&r, lzma.reader_read, out)
		case .XZ:
			r: xz.Reader
			xz.reader_init(&r, &ctx, {}, expected) or_return
			defer xz.reader_destroy(&r)
			return declared_read_all(&r, xz.reader_read, out)
		}
	}
	return
}

declared_read_all :: proc(r: ^$R, read: proc(r: ^R, p: []u8) -> (n: int, err: compress.Error), out: ^[dynamic]byte) -> (err: compress.Error) {
	buf: [4099]byte
	for {
		n, read_err := read(r, buf[:])
		append(out, ..buf[:n])
		if read_err == io.Error.EOF {
			return nil
		}
		if read_err != nil {
			return read_err
		}
	}
}
