package test_core_compress

import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:compress/xz"
import "core:io"
import "core:testing"

Input_Codec :: enum {
	BZip2,
	LZ4,
	Gzip,
	Zlib,
	LZMA,
	PPMd,
	XZ,
}

Input_Mode :: enum {
	One_Shot,
	Writer,
	Reader,
}

@(test)
decoder_input_errors :: proc(t: ^testing.T) {
	g := Lz4_Test_Lcg{state = 0x1e77}
	text := lz4_test_lcg_text(&g, 40_000)
	defer delete(text)

	for codec in Input_Codec {
		packed: [dynamic]byte
		defer delete(packed)
		props, pack_err := input_codec_pack(codec, text, &packed)
		testing.expect_value(t, pack_err, nil)
		first := len(packed)
		cuts  := make([dynamic]int)
		defer delete(cuts)
		append(&cuts, 0, 1, first / 3, 2 * first / 3)
		if codec != .Zlib && codec != .LZMA && codec != .PPMd {
			second: [dynamic]byte
			defer delete(second)
			_, second_err := input_codec_pack(codec, text, &second)
			testing.expect_value(t, second_err, nil)
			append(&packed, ..second[:])
			append(&cuts, first, first + 1, len(packed) - 1)
		}
		for cut in cuts {
			for fail in ([]io.Error{.Permission_Denied, .None, .EOF}) {
				want := compress.Error(fail)
				if fail == .None {
					want = io.Error.No_Progress
				} else if fail == .EOF {
					if cut == 0 || cut == first || cut == first + 1 {
						continue
					}
					want = compress.General_Error.File_Too_Short if codec == .Gzip && cut < 10 else compress.General_Error.Stream_Too_Short
				}
				for mode in Input_Mode {
					output: [dynamic]byte
					defer delete(output)
					r   := Stall_Reader{data = packed[:cut], fail = fail, chunk = 1000, hiccups = 3}
					ctx := compress.init_context(stall_stream(&r), &output)
					err := input_codec_unpack(codec, mode, &ctx, props, &output)
					compress.destroy_context(&ctx)
					testing.expectf(t, err == want, "%v %v, cut at %v of %v, fail %v: got %v after %v bytes", codec, mode, cut, len(packed), fail, err, len(output))
				}
			}
		}
	}
}

input_codec_pack :: proc(codec: Input_Codec, text: []byte, packed: ^[dynamic]byte) -> (props: Edge_Props, err: compress.Error) {
	switch codec {
	case .BZip2:
		err = bzip2.compress(packed, text, .Level_1)
	case .LZ4:
		err = lz4.compress_frame(packed, text, .Level_1, {block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS})
	case .Gzip:
		err = deflate.compress_gzip(packed, text)
	case .Zlib:
		err = deflate.compress_zlib(packed, text)
	case .LZMA:
		options := lzma.level_options(.Level_1)
		options.end_marker = true
		props.lzma, err = lzma.compress_raw_to_dynamic(packed, text, options)
	case .PPMd:
		props.ppmd = {variant = .H, order = 6, mem_size = 1 << 20}
		err = ppmd.compress(packed, text, props.ppmd, true)
	case .XZ:
		err = xz.compress(packed, text, .Level_1)
	}
	return
}

input_codec_unpack :: proc(codec: Input_Codec, mode: Input_Mode, ctx: ^compress.Context, props: Edge_Props, output: ^[dynamic]byte) -> (err: compress.Error) {
	switch mode {
	case .One_Shot:
		switch codec {
		case .BZip2: return bzip2.decompress(ctx)
		case .LZ4:   return lz4.decompress_frame(ctx)
		case .Gzip:  return deflate.decompress_gzip(ctx)
		case .Zlib:  return deflate.decompress_zlib(ctx)
		case .LZMA:  return lzma.decompress_raw_from_context(ctx, props.lzma)
		case .PPMd:  return ppmd.decompress(ctx, props.ppmd)
		case .XZ:    return xz.decompress(ctx)
		}
	case .Writer:
		aw := Append_Writer{out = output, fail_at = -1}
		w  := append_writer(&aw)
		switch codec {
		case .BZip2: return bzip2.decompress_to_writer(w, ctx)
		case .LZ4:   return lz4.decompress_frame_to_writer(w, ctx)
		case .Gzip:  return deflate.decompress_gzip_to_writer(w, ctx)
		case .Zlib:  return deflate.decompress_zlib_to_writer(w, ctx)
		case .LZMA:  return lzma.decompress_raw_to_writer(w, ctx, props.lzma)
		case .PPMd:  return ppmd.decompress_to_writer(w, ctx, props.ppmd)
		case .XZ:    return xz.decompress_to_writer(w, ctx)
		}
	case .Reader:
		switch codec {
		case .BZip2:
			r: bzip2.Reader
			defer bzip2.reader_destroy(&r)
			bzip2.reader_init(&r, ctx) or_return
			return input_drain(&r, bzip2.reader_read, output)
		case .LZ4:
			r: lz4.Frame_Reader
			defer lz4.frame_reader_destroy(&r)
			lz4.frame_reader_init(&r, ctx) or_return
			return input_drain(&r, lz4.frame_reader_read, output)
		case .Gzip, .Zlib:
			r: deflate.Reader
			defer deflate.reader_destroy(&r)
			deflate.reader_init(&r, ctx, .Gzip if codec == .Gzip else .Zlib) or_return
			return input_drain(&r, deflate.reader_read, output)
		case .LZMA:
			r: lzma.Reader
			defer lzma.reader_destroy(&r)
			lzma.reader_init_raw(&r, ctx, props.lzma) or_return
			return input_drain(&r, lzma.reader_read, output)
		case .PPMd:
			r: ppmd.Reader
			defer ppmd.reader_destroy(&r)
			ppmd.reader_init(&r, ctx, props.ppmd) or_return
			return input_drain(&r, ppmd.reader_read, output)
		case .XZ:
			r: xz.Reader
			defer xz.reader_destroy(&r)
			xz.reader_init(&r, ctx) or_return
			return input_drain(&r, xz.reader_read, output)
		}
	}
	return
}

input_drain :: proc(r: ^$R, read: proc(r: ^R, p: []u8) -> (n: int, err: compress.Error), output: ^[dynamic]byte) -> (err: compress.Error) {
	buffer: [4096]byte
	for _ in 0..<1000 {
		n, read_err := read(r, buffer[:])
		append(output, ..buffer[:n])
		if read_err == compress.Error(io.Error.EOF) {
			return nil
		}
		if read_err != nil {
			return read_err
		}
	}
	return compress.General_Error.Canceled
}
