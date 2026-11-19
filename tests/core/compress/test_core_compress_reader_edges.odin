package test_core_compress

import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import "core:compress/ppmd"
import "core:fmt"
import "core:io"
import "core:testing"

Edge_Codec :: enum {
	BZip2,
	LZ4,
	Inflate,
	LZMA,
	PPMd,
}

Edge_Props :: struct {
	lzma: lzma.Properties,
	ppmd: ppmd.Properties,
}

@(test)
reader_progress_final_fill :: proc(t: ^testing.T) {
	log: Ppmd_Progress_Log
	defer delete(log.calls)
	g := Lz4_Test_Lcg{state = 0xf17a}

	for codec in Edge_Codec {
		for chunk in ([]int{1000, 4096}) {
			step := max(chunk, 1024) if codec == .LZMA else chunk
			base := 4096 if codec == .LZMA else 0
			sizes: [13]int
			for k in 1..=4 {
				for d in -1..=1 {
					sizes[3 * k + d - 1] = base + step * k + d
				}
			}
			for size in sizes {
				text := lz4_test_lcg_text(&g, size)
				defer delete(text)
				packed: [dynamic]byte
				defer delete(packed)
				props, pack_err := edge_pack(codec, text, &packed)
				testing.expect_value(t, pack_err, nil)
				for pull in ([]bool{false, true}) {
					label := fmt.tprintf("%v %v, chunk %v, %v bytes", codec, "pull" if pull else "push", chunk, len(text))
					output: [dynamic]byte
					defer delete(output)
					err := edge_unpack(codec, pull, packed[:], props, ppmd_progress_options(&log, {chunk_size = chunk}), step, &output)
					testing.expectf(t, err == nil && bytes.equal(output[:], text), "%v: %v, %v of %v bytes", label, err, len(output), len(text))
					codec_progress_expect_last(t, label, log.calls[:], i64(len(packed)), i64(len(text)))
				}
			}
		}
		free_all(context.temp_allocator)
	}
}

edge_pack :: proc(codec: Edge_Codec, text: []byte, packed: ^[dynamic]byte) -> (props: Edge_Props, err: compress.Error) {
	switch codec {
	case .BZip2:
		err = bzip2.compress(packed, text, .Level_1)
	case .LZ4:
		err = lz4.compress_frame(packed, text, .Level_1, {block_max_size = .Max_64KiB, flags = lz4.DEFAULT_FRAME_FLAGS})
	case .Inflate:
		err = deflate.compress_gzip(packed, text)
		if err == nil {
			empty: [dynamic]byte
			defer delete(empty)
			err = deflate.compress_gzip(&empty, nil)
			append(packed, ..empty[:])
		}
	case .LZMA:
		options := lzma.level_options(.Level_1)
		options.dict_size  = 4096
		options.end_marker = true
		props.lzma, err = lzma.compress_raw_to_dynamic(packed, text, options)
	case .PPMd:
		props.ppmd = {variant = .H, order = 6, mem_size = 1 << 20}
		err = ppmd.compress(packed, text, props.ppmd, true)
	}
	return
}

edge_unpack :: proc(codec: Edge_Codec, pull: bool, packed: []byte, props: Edge_Props, options: compress.Options, read_size: int, output: ^[dynamic]byte) -> (err: compress.Error) {
	input := packed
	ctx := compress.init_context(&input)
	if !pull {
		aw := Append_Writer{out = output, fail_at = -1}
		w  := append_writer(&aw)
		switch codec {
		case .BZip2:   return bzip2.decompress_to_writer(w, &ctx, -1, options)
		case .LZ4:     return lz4.decompress_frame_to_writer(w, &ctx, -1, options)
		case .Inflate: return deflate.decompress_gzip_to_writer(w, &ctx, -1, options)
		case .LZMA:    return lzma.decompress_raw_to_writer(w, &ctx, props.lzma, -1, options)
		case .PPMd:    return ppmd.decompress_to_writer(w, &ctx, props.ppmd, -1, options)
		}
		return
	}
	buffer := make([]byte, read_size)
	defer delete(buffer)
	switch codec {
	case .BZip2:
		r: bzip2.Reader
		defer bzip2.reader_destroy(&r)
		bzip2.reader_init(&r, &ctx, -1, options) or_return
		return edge_drain(&r, bzip2.reader_read, buffer, output)
	case .LZ4:
		r: lz4.Frame_Reader
		defer lz4.frame_reader_destroy(&r)
		lz4.frame_reader_init(&r, &ctx, -1, options) or_return
		return edge_drain(&r, lz4.frame_reader_read, buffer, output)
	case .Inflate:
		r: deflate.Reader
		defer deflate.reader_destroy(&r)
		deflate.reader_init(&r, &ctx, .Gzip, -1, options) or_return
		return edge_drain(&r, deflate.reader_read, buffer, output)
	case .LZMA:
		r: lzma.Reader
		defer lzma.reader_destroy(&r)
		lzma.reader_init_raw(&r, &ctx, props.lzma, -1, options) or_return
		return edge_drain(&r, lzma.reader_read, buffer, output)
	case .PPMd:
		r: ppmd.Reader
		defer ppmd.reader_destroy(&r)
		ppmd.reader_init(&r, &ctx, props.ppmd, -1, options) or_return
		return edge_drain(&r, ppmd.reader_read, buffer, output)
	}
	return
}

edge_drain :: proc(r: ^$R, read: proc(r: ^R, p: []u8) -> (n: int, err: compress.Error), buffer: []byte, output: ^[dynamic]byte) -> (err: compress.Error) {
	idle := 0
	for idle < 4 {
		n, read_err := read(r, buffer)
		append(output, ..buffer[:n])
		if read_err == compress.Error(io.Error.EOF) {
			return nil
		}
		if read_err != nil {
			return read_err
		}
		idle = idle + 1 if n == 0 else 0
	}
	return io.Error.No_Progress
}

@(test)
reader_empty_read_before_error :: proc(t: ^testing.T) {
	data := stream_match_data()
	defer delete(data)

	{
		packed: [dynamic]byte
		defer delete(packed)
		codec_pack(.BZip2, data, &packed)
		packed[len(packed) - 3] ~= 0x55
		input := packed[:]
		ctx := compress.init_context(&input)
		r: bzip2.Reader
		defer bzip2.reader_destroy(&r)
		testing.expect_value(t, bzip2.reader_init(&r, &ctx), nil)
		output, final := empty_read_drain(t, "bzip2", &r, bzip2.reader_read,
			proc(r: ^bzip2.Reader) -> bool { return r.flushed < r.written },
			proc(r: ^bzip2.Reader) -> compress.Error { return r.err })
		defer delete(output)
		testing.expect_value(t, final, compress.Error(compress.BZip2_Error.Stream_Checksum_Failed))
		testing.expect(t, bytes.equal(output[:], data), "bzip2: output differs")
	}
	{
		packed: [dynamic]byte
		defer delete(packed)
		codec_pack(.LZ4, data, &packed)
		packed[len(packed) - 2] ~= 0x55
		input := packed[:]
		ctx := compress.init_context(&input)
		r: lz4.Frame_Reader
		defer lz4.frame_reader_destroy(&r)
		testing.expect_value(t, lz4.frame_reader_init(&r, &ctx), nil)
		output, final := empty_read_drain(t, "lz4", &r, lz4.frame_reader_read,
			proc(r: ^lz4.Frame_Reader) -> bool { return r.flushed < r.written },
			proc(r: ^lz4.Frame_Reader) -> compress.Error { return r.err })
		defer delete(output)
		testing.expect_value(t, final, compress.Error(compress.LZ4_Error.Content_Checksum_Failed))
		testing.expect(t, bytes.equal(output[:], data), "lz4: output differs")
	}
	{
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, deflate.compress_gzip(&packed, data), nil)
		packed[len(packed) - 8] ~= 0x55
		input := packed[:]
		ctx := compress.init_context(&input)
		r: deflate.Reader
		defer deflate.reader_destroy(&r)
		testing.expect_value(t, deflate.reader_init(&r, &ctx, .Gzip), nil)
		output, final := empty_read_drain(t, "inflate", &r, deflate.reader_read,
			proc(r: ^deflate.Reader) -> bool { return r.flushed < r.written },
			proc(r: ^deflate.Reader) -> compress.Error { return r.err })
		defer delete(output)
		testing.expect_value(t, final, compress.Error(compress.GZIP_Error.Payload_CRC_Invalid))
		testing.expect(t, bytes.equal(output[:], data), "inflate: output differs")
	}
	{
		packed: [dynamic]byte
		defer delete(packed)
		testing.expect_value(t, lzma.compress_to_dynamic(&packed, data), nil)
		input := packed[:len(packed) - 4]
		ctx := compress.init_context(&input)
		r: lzma.Reader
		defer lzma.reader_destroy(&r)
		testing.expect_value(t, lzma.reader_init(&r, &ctx), nil)
		output, final := empty_read_drain(t, "lzma", &r, lzma.reader_read,
			proc(r: ^lzma.Reader) -> bool { return r.flushed < r.out.written },
			proc(r: ^lzma.Reader) -> compress.Error { return r.err })
		defer delete(output)
		testing.expect_value(t, final, compress.Error(compress.General_Error.Stream_Too_Short))
		testing.expectf(t, len(output) < len(data) && bytes.equal(output[:], data[:len(output)]), "lzma: output is not a prefix, %v of %v bytes", len(output), len(data))
	}
}

empty_read_drain :: proc(t: ^testing.T, label: string, r: ^$R, read: proc(r: ^R, p: []u8) -> (n: int, err: compress.Error), waiting: proc(r: ^R) -> bool, recorded: proc(r: ^R) -> compress.Error) -> (output: [dynamic]byte, final: compress.Error) {
	buffer: [100]byte
	held := 0
	for {
		pending := waiting(r)
		stored  := recorded(r)
		n, err := read(r, nil)
		if pending {
			testing.expectf(t, n == 0 && err == nil, "%v: empty read with data waiting gave %v, %v", label, n, err)
			held += 1 if stored != nil else 0
		} else {
			testing.expectf(t, n == 0 && err == stored, "%v: empty read gave %v, %v, want 0, %v", label, n, err, stored)
		}
		n, err = read(r, buffer[:])
		append(&output, ..buffer[:n])
		if err != nil {
			final = err
			break
		}
	}
	testing.expectf(t, held > 0, "%v: no empty read while an error waited behind data", label)
	return
}
