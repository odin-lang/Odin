package test_core_compress

import "base:runtime"
import "core:bytes"
import "core:compress"
import "core:compress/bzip2"
import "core:compress/deflate"
import "core:compress/lz4"
import "core:compress/lzma"
import pkzip_legacy "core:compress/pkzip-legacy"
import "core:compress/ppmd"
import "core:compress/shoco"
import "core:io"
import "core:mem"
import "core:testing"

@(test)
test_leak_shoco_string_errors :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	alloc := mem.tracking_allocator(&track)

	bad_inputs := [][]u8{
		{0xC0},
		{0x00},
		{0xE0, 0x00, 0x00},
		{0xF0},
		{0xED, 0xD8, 0x00, 0x00},
		{0xE1, 0x70, 0x00, 0x00},
		{0x41, 0x42, 0xC0},
	}
	for input, i in bad_inputs {
		res, err := shoco.decompress_slice_to_string(input, allocator = alloc)
		testing.expectf(t, err != nil, "input %v: expected an error", i)
		testing.expectf(t, res == "", "input %v: expected an empty string, got %q", i, res)
		testing.expectf(t, len(track.allocation_map) == 0, "input %v: %v block(s) leaked", i, len(track.allocation_map))
	}

	bad_model := shoco.DEFAULT_MODEL
	bad_model.max_successor_n = -1
	packed, pack_err := shoco.compress_string("the quick brown fox", bad_model, alloc)
	testing.expect_value(t, pack_err, compress.Error(compress.General_Error.Unknown_Compression_Method))
	testing.expect(t, packed == nil)

	unpacked, unpack_err := shoco.decompress_slice_to_string({0x41}, bad_model, alloc)
	testing.expect_value(t, unpack_err, compress.Error(compress.General_Error.Unknown_Compression_Method))
	testing.expect_value(t, unpacked, "")
	testing.expect_value(t, len(track.allocation_map), 0)
}

@(test)
test_leak_shoco_corrupt_buffer :: proc(t: ^testing.T) {
	out: [64]u8
	Case :: struct {
		input: []u8,
		err:   compress.Error,
	}
	GE :: compress.General_Error
	cases := []Case{
		{{0xF0},                   GE.Unknown_Compression_Method},
		{{0xF7, 0x00, 0x00, 0x00}, GE.Unknown_Compression_Method},
		{{0xED, 0xD8, 0x00, 0x00}, GE.Unknown_Compression_Method},
		{{0xE1, 0x70, 0x00, 0x00}, GE.Unknown_Compression_Method},
		{{0xC0},                   GE.Stream_Too_Short},
		{{0xE0, 0x00, 0x00},       GE.Stream_Too_Short},
	}
	for c, i in cases {
		_, err := shoco.decompress_slice_to_output_buffer(c.input, out[:])
		testing.expectf(t, err == c.err, "case %v: got %v, expected %v", i, err, c.err)
	}
}

@(test)
test_leak_shoco_custom_model :: proc(t: ^testing.T) {
	model := shoco.DEFAULT_MODEL
	model.packs = model.packs[:2]

	input := "wanderer, the wanderer went there"
	reference, reference_err := shoco.compress_string(input)
	defer delete(reference)
	testing.expect_value(t, reference_err, nil)
	testing.expect(t, leak_shoco_largest_pack(reference) == 2, "input doesn't exercise the 8-character pack")

	packed, pack_err := shoco.compress_string(input, model)
	defer delete(packed)
	testing.expect_value(t, pack_err, nil)
	testing.expect(t, leak_shoco_largest_pack(packed) < 2, "two-pack model emitted a third pack")

	unpacked, unpack_err := shoco.decompress_slice_to_string(packed, model)
	defer delete(unpacked)
	testing.expect_value(t, unpack_err, nil)
	testing.expect_value(t, unpacked, input)
}

@(test)
test_leak_shoco_oom :: proc(t: ^testing.T) {
	leak_oom_sweep(t, "shoco compress_string", proc(allocator: runtime.Allocator) -> compress.Error {
		packed, err := shoco.compress_string("shoco compresses short English strings.", allocator = allocator)
		delete(packed, allocator)
		return err
	})
	leak_oom_sweep(t, "shoco decompress_slice_to_string", proc(allocator: runtime.Allocator) -> compress.Error {
		unpacked, err := shoco.decompress_slice_to_string({0x80, 0xC5, 0x10, 0x41}, allocator = allocator)
		delete(unpacked, allocator)
		return err
	})
}

@(test)
test_leak_writer_init_oom :: proc(t: ^testing.T) {
	leak_oom_sweep(t, "deflate zlib writer", proc(allocator: runtime.Allocator) -> compress.Error {
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		dw: deflate.Writer
		err := deflate.writer_init(&dw, bytes.buffer_to_stream(&b), .Zlib, allocator = allocator)
		if err == nil {
			deflate.writer_destroy(&dw)
		}
		return err
	})
	leak_oom_sweep(t, "deflate64 writer", proc(allocator: runtime.Allocator) -> compress.Error {
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		dw: deflate.Writer
		err := deflate.writer_init(&dw, bytes.buffer_to_stream(&b), .Raw64, allocator = allocator)
		if err == nil {
			deflate.writer_destroy(&dw)
		}
		return err
	})
	leak_oom_sweep(t, "lz4 frame writer", proc(allocator: runtime.Allocator) -> compress.Error {
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		fw: lz4.Frame_Writer
		err := lz4.frame_writer_init(&fw, bytes.buffer_to_stream(&b), allocator = allocator)
		if err == nil {
			lz4.frame_writer_destroy(&fw)
		}
		return err
	})
	leak_oom_sweep(t, "bzip2 writer", proc(allocator: runtime.Allocator) -> compress.Error {
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		bw: bzip2.Writer
		err := bzip2.writer_init(&bw, bytes.buffer_to_stream(&b), allocator = allocator)
		if err == nil {
			bzip2.writer_destroy(&bw)
		}
		return err
	})
	leak_oom_sweep(t, "ppmd H writer", proc(allocator: runtime.Allocator) -> compress.Error {
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		pw: ppmd.Writer
		err := ppmd.writer_init(&pw, bytes.buffer_to_stream(&b), {variant = .H, order = 6, mem_size = 1 << 16}, allocator = allocator)
		if err == nil {
			ppmd.writer_destroy(&pw)
		}
		return err
	})
	leak_oom_sweep(t, "ppmd I writer", proc(allocator: runtime.Allocator) -> compress.Error {
		b: bytes.Buffer
		defer bytes.buffer_destroy(&b)
		pw: ppmd.Writer
		err := ppmd.writer_init(&pw, bytes.buffer_to_stream(&b), {variant = .I, order = 6, mem_size = 1 << 16}, allocator = allocator)
		if err == nil {
			ppmd.writer_destroy(&pw)
		}
		return err
	})
}

@(test)
test_leak_stream_context_oom :: proc(t: ^testing.T) {
	leak_oom_sweep(t, "stream context", proc(allocator: runtime.Allocator) -> compress.Error {
		data := [?]u8{1, 2, 3}
		r: bytes.Reader
		ctx, err := compress.init_context_from_stream(bytes.reader_init(&r, data[:]), nil, nil, allocator)
		compress.destroy_context(&ctx)
		return err
	})
	leak_oom_sweep(t, "legacy reader on a stream", proc(allocator: runtime.Allocator) -> compress.Error {
		data := [?]u8{'a', 0}
		r: bytes.Reader
		ctx := compress.init_context_from_stream(bytes.reader_init(&r, data[:]))
		defer compress.destroy_context(&ctx)
		lr: pkzip_legacy.Reader
		err := pkzip_legacy.reader_init_unshrink(&lr, &ctx, 1, {}, allocator)
		pkzip_legacy.reader_destroy(&lr)
		return err
	})

	data := [?]u8{1, 2, 3}
	r: bytes.Reader
	buffer: [64]u8
	_, buffer_err := compress.init_context_from_stream(bytes.reader_init(&r, data[:]), nil, buffer[:], runtime.nil_allocator())
	testing.expect_value(t, buffer_err, runtime.Allocator_Error.None)
	lone := compress.init_context(bytes.reader_init(&r, data[:]), nil, nil, runtime.nil_allocator())
	testing.expect_value(t, compress.refill_window(&lone, 1), io.Error.Buffer_Full)
}

@(test)
test_leak_reader_init_bad_input :: proc(t: ^testing.T) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
	alloc := mem.tracking_allocator(&track)

	{
		input := []u8{0x5D, 0x00, 0x00, 0x01, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01, 0x00, 0x00, 0x00, 0x00}
		ctx := compress.init_context_from_slice(&input)
		r: lzma.Reader
		err := lzma.reader_init(&r, &ctx, allocator = alloc)
		testing.expect_value(t, err, compress.Error(compress.LZMA_Error.Corrupt_Range_Coder))
		testing.expect_value(t, len(track.allocation_map), 0)
		lzma.reader_destroy(&r)
	}
	{
		input := []u8{0x01, 0x00, 0x00, 0x00, 0x00}
		ctx := compress.init_context_from_slice(&input)
		r: ppmd.Reader
		err := ppmd.reader_init(&r, &ctx, {variant = .H, order = 6, mem_size = 1 << 16}, allocator = alloc)
		testing.expect_value(t, err, compress.Error(compress.PPMd_Error.Corrupt_Data))
		testing.expect_value(t, len(track.allocation_map), 0)
		ppmd.reader_destroy(&r)
	}
	{
		input := []u8{0xFF, 0xFF, 0xFF, 0xFF}
		ctx := compress.init_context_from_slice(&input)
		r: ppmd.Reader
		err := ppmd.reader_init(&r, &ctx, {variant = .I, order = 6, mem_size = 1 << 16}, allocator = alloc)
		testing.expect_value(t, err, compress.Error(compress.PPMd_Error.Corrupt_Data))
		testing.expect_value(t, len(track.allocation_map), 0)
		ppmd.reader_destroy(&r)
	}
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(test)
test_leak_lz4_optimal_temp_oom :: proc(t: ^testing.T) {
	input := make([]u8, 20_000)
	defer delete(input)
	for &b, i in input {
		b = u8((i * 7) % 61 + (i / 97) % 5)
	}

	total := -1
	for k := -1; total < 0 || k < total; k += 1 {
		fa := Leak_Failing_Allocator{backing = context.temp_allocator, fail_at = k}
		packed: [dynamic]u8
		err: compress.Error
		{
			context.temp_allocator = {procedure = leak_failing_allocator_proc, data = &fa}
			err = lz4.compress_block(&packed, input, .Level_10)
		}
		if k < 0 {
			total = fa.count
			testing.expectf(t, total >= 2, "lz4 optimal made %v temp allocations", total)
		}
		testing.expectf(t, err == nil || (k >= 0 && err == compress.Error(runtime.Allocator_Error.Out_Of_Memory)), "temp allocation %v failing: %v", k, err)
		if err == nil {
			unpacked: [dynamic]u8
			unpack_err := lz4.decompress_block(&unpacked, packed[:], len(input))
			testing.expectf(t, unpack_err == nil && bytes.equal(unpacked[:], input), "temp allocation %v failing: round trip gave %v", k, unpack_err)
			delete(unpacked)
		}
		delete(packed)
	}
}

@(private="file")
Leak_Init_Proc :: #type proc(allocator: runtime.Allocator) -> compress.Error

@(private="file")
Leak_Failing_Allocator :: struct {
	backing: runtime.Allocator,
	count:   int,
	fail_at: int,
}

@(private="file")
leak_failing_allocator_proc :: proc(data: rawptr, mode: runtime.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, runtime.Allocator_Error) {
	fa := (^Leak_Failing_Allocator)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		if fa.count == fa.fail_at {
			fa.count += 1
			return nil, .Out_Of_Memory
		}
		fa.count += 1
	}
	return fa.backing.procedure(fa.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
leak_oom_sweep :: proc(t: ^testing.T, name: string, init: Leak_Init_Proc) {
	for k in 0..<64 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
		fa := Leak_Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = k}
		err := init({procedure = leak_failing_allocator_proc, data = &fa})
		leaked    := len(track.allocation_map)
		bad_frees := len(track.bad_free_array)
		mem.tracking_allocator_destroy(&track)
		testing.expectf(t, leaked == 0, "%v, fail at %v: %v block(s) leaked", name, k, leaked)
		testing.expectf(t, bad_frees == 0, "%v, fail at %v: %v bad free(s)", name, k, bad_frees)
		if fa.count <= k {
			testing.expectf(t, err == nil, "%v, no failure injected: %v", name, err)
			testing.expectf(t, k > 0, "%v: never allocated", name)
			return
		}
		testing.expectf(t, err == nil || err == compress.Error(runtime.Allocator_Error.Out_Of_Memory), "%v, fail at %v: %v", name, k, err)
	}
	testing.expectf(t, false, "%v: still allocating after 64 allocations", name)
}

@(private="file")
leak_shoco_largest_pack :: proc(packed: []u8) -> (largest: int) {
	largest = -1
	for i := 0; i < len(packed); {
		b := packed[i]
		switch {
		case b == 0x00:
			i += 2
		case b < 0x80:
			i += 1
		case b & 0xC0 == 0x80:
			largest = max(largest, 0)
			i += 1
		case b & 0xE0 == 0xC0:
			largest = max(largest, 1)
			i += 2
		case:
			largest = max(largest, 2)
			i += 4
		}
	}
	return
}
