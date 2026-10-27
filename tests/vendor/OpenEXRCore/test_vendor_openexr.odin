#+build windows, darwin
package test_vendor_openexr

import "core:c"
import "core:fmt"
import "core:math"
import "core:os"
import "core:testing"
import exr "vendor:OpenEXRCore"

// Tests of the OpenEXRCore library built here (3.5.2), through `vendor:OpenEXRCore`. They write an image with every
// compression method, read it back, and compare it, which exercises the codecs added in OpenEXR 3.4 and 3.5 (the
// HTJ2K, LJ2K and ZSTD ones) as well as the older ones.

WIDTH  :: 67 // not a multiple of any lines per chunk
HEIGHT :: 53

CHANNEL_NAMES := [3]cstring{"B", "G", "R"} // the channel list is sorted by name

// `sizeof` and `offsetof` of the C structs of OpenEXR 3.5.2 on a 64-bit target.
@(test)
layout :: proc(t: ^testing.T) {
	when size_of(rawptr) == 8 {
		testing.expect_value(t, size_of(exr.context_initializer_t), 112)
		testing.expect_value(t, offset_of(exr.context_initializer_t, size), 0)
		testing.expect_value(t, offset_of(exr.context_initializer_t, zip_level), 88)
		testing.expect_value(t, offset_of(exr.context_initializer_t, dwa_quality), 92)
		testing.expect_value(t, offset_of(exr.context_initializer_t, flags), 96)
		testing.expect_value(t, offset_of(exr.context_initializer_t, lossy_htj2k_quality), 100)
		testing.expect_value(t, offset_of(exr.context_initializer_t, zstd_level), 104)

		testing.expect_value(t, size_of(exr.decode_pipeline_t), 528)
		testing.expect_value(t, offset_of(exr.decode_pipeline_t, _quick_chan_store), 264)
		testing.expect_value(t, offset_of(exr.decode_pipeline_t, sample_count_valid), 504)
		testing.expect_value(t, offset_of(exr.decode_pipeline_t, compression_context), 512)
		testing.expect_value(t, offset_of(exr.decode_pipeline_t, free_compression_context), 520)

		testing.expect_value(t, size_of(exr.encode_pipeline_t), 520)
		testing.expect_value(t, offset_of(exr.encode_pipeline_t, _quick_chan_store), 272)
		testing.expect_value(t, offset_of(exr.encode_pipeline_t, skip_sample_count_table_compression), 512)

		testing.expect_value(t, size_of(exr.attr_bytes_t), 32)
		testing.expect_value(t, offset_of(exr.attr_bytes_t, size), 0)
		testing.expect_value(t, offset_of(exr.attr_bytes_t, data), 8)
		testing.expect_value(t, offset_of(exr.attr_bytes_t, hint_length), 16)
		testing.expect_value(t, offset_of(exr.attr_bytes_t, type_hint), 24)

		testing.expect_value(t, size_of(exr.color_metadata_t), 48)
		testing.expect_value(t, offset_of(exr.color_metadata_t, chromaticities), 8)
		testing.expect_value(t, offset_of(exr.color_metadata_t, has_white_luminance), 16)
		testing.expect_value(t, offset_of(exr.color_metadata_t, aces_image_container_flag), 28)
		testing.expect_value(t, offset_of(exr.color_metadata_t, first_part_color_interop_id), 32)
		testing.expect_value(t, offset_of(exr.color_metadata_t, compare_to_first_part), 40)

		testing.expect_value(t, size_of(exr.attribute_t), 32)
		testing.expect_value(t, size_of(exr.chunk_info_t), 64)
	}
	testing.expect_value(t, int(exr.attribute_type_t.BYTES), 3)
	testing.expect_value(t, int(exr.attribute_type_t.OPAQUE), 31)
	testing.expect_value(t, int(exr.result_t.UNKNOWN), 35)
	testing.expect_value(t, int(exr.compression_t.HTJ2K256), 10)
	testing.expect_value(t, int(exr.compression_t.HTJ2K32), 11)
	testing.expect_value(t, int(exr.compression_t.LJ2K), 12)
	testing.expect_value(t, int(exr.compression_t.ZSTD), 13)
}

@(test)
library_version :: proc(t: ^testing.T) {
	major, minor, patch: c.int
	extra: cstring
	exr.get_library_version(&major, &minor, &patch, &extra)
	testing.expect_value(t, major, 3)
	testing.expect_value(t, minor, 5)
	testing.expect_value(t, patch, 2)
}

@(test)
default_context_initializer :: proc(t: ^testing.T) {
	init := exr.DEFAULT_CONTEXT_INITIALIZER
	testing.expect_value(t, init.size, size_of(exr.context_initializer_t))
	testing.expect_value(t, init.zip_level, -2)
	testing.expect_value(t, init.dwa_quality, -1)
	testing.expect_value(t, init.zstd_level, -1)
}

@(test)
compression_properties :: proc(t: ^testing.T) {
	Case :: struct {
		compression: exr.compression_t,
		name:        string,
		lines:       c.int,
		lossy:       bool,
	}
	cases := [?]Case{
		{.NONE,     "none",    1,   false},
		{.ZIPS,     "zips",    1,   false},
		{.ZIP,      "zip",     16,  false},
		{.DWAB,     "dwab",    256, true},
		{.HTJ2K256, "htj2k256", 256, false},
		{.HTJ2K32,  "htj2k32",  32,  false},
		{.LJ2K,     "lj2k",    256, true},
		{.ZSTD,     "zstd",    1,   false},
	}
	for tc in cases {
		testing.expect_value(t, string(exr.compression_name(tc.compression)), tc.name)
		testing.expect_value(t, exr.compression_lines_per_chunk(tc.compression), tc.lines)
		testing.expect_value(t, exr.compression_is_lossy(tc.compression) != 0, tc.lossy)
		testing.expect(t, len(string(exr.compression_description(tc.compression))) > 0, "a compression has a description")
		testing.expect_value(t, exr.compression_type_from_name(cstring(raw_data(tc.name))), tc.compression)
	}
	testing.expect_value(t, exr.compression_is_valid_for_deep(.ZIPS), c.int(1))
	testing.expect_value(t, exr.compression_is_valid_for_deep(.PIZ), c.int(0))
}

@(test)
default_levels :: proc(t: ^testing.T) {
	level: c.int
	exr.get_default_zstd_compression_level(&level)
	testing.expect_value(t, level, 5)
	exr.set_default_zstd_compression_level(9)
	exr.get_default_zstd_compression_level(&level)
	testing.expect_value(t, level, 9)
	exr.set_default_zstd_compression_level(5)

	quality: f32
	exr.get_default_lossy_htj2k_quality(&quality)
	exr.set_default_lossy_htj2k_quality(quality)
}

// ---- writing and reading an image ------------------------------------------------------------------------------

Image :: [3][]f32 // one plane per channel, in CHANNEL_NAMES order

make_image :: proc(allocator := context.temp_allocator) -> (image: Image) {
	for &plane, k in image {
		plane = make([]f32, WIDTH * HEIGHT, allocator)
		for y in 0..<HEIGHT {
			for x in 0..<WIDTH {
				// a smooth gradient with some texture, different per channel
				v := f32(x) * 0.07 + f32(y) * 0.11 * f32(k + 1)
				v += 0.4 * math.sin(f32(x * (k + 2)) * 0.31) * math.cos(f32(y) * 0.23)
				plane[y * WIDTH + x] = v
			}
		}
	}
	return
}

check :: proc(t: ^testing.T, result: exr.result_t, what: string, loc := #caller_location) -> bool {
	if result != .SUCCESS {
		testing.expectf(t, false, "%v failed: %v", what, result, loc = loc)
		return false
	}
	return true
}

temp_path :: proc(name: string) -> cstring {
	dir, err := os.temp_directory(context.temp_allocator)
	if err != nil { dir = "." }
	return fmt.ctprintf("%s/odin-openexr-test-%s.exr", dir, name)
}

write_image :: proc(t: ^testing.T, path: cstring, compression: exr.compression_t, image: Image, init := exr.DEFAULT_CONTEXT_INITIALIZER) -> bool {
	init := init
	ctxt: exr.context_t
	if !check(t, exr.start_write(&ctxt, path, .WRITE_FILE_DIRECTLY, &init), "start_write") { return false }
	defer exr.finish(&ctxt)

	part: c.int
	if !check(t, exr.add_part(ctxt, "image", .SCANLINE, &part), "add_part") { return false }
	if !check(t, exr.initialize_required_attr_simple(ctxt, part, WIDTH, HEIGHT, compression), "initialize_required_attr_simple") { return false }
	for name in CHANNEL_NAMES {
		if !check(t, exr.add_channel(ctxt, part, name, .FLOAT, .LINEAR, 1, 1), "add_channel") { return false }
	}
	if !check(t, exr.write_header(ctxt), "write_header") { return false }

	lines: i32
	if !check(t, exr.get_scanlines_per_chunk(ctxt, part, &lines), "get_scanlines_per_chunk") { return false }

	encoder: exr.encode_pipeline_t
	first := true
	for y: i32 = 0; y < HEIGHT; y += lines {
		chunk: exr.chunk_info_t
		if !check(t, exr.write_scanline_chunk_info(ctxt, part, y, &chunk), "write_scanline_chunk_info") { return false }
		if first {
			if !check(t, exr.encoding_initialize(ctxt, part, &chunk, &encoder), "encoding_initialize") { return false }
		} else {
			if !check(t, exr.encoding_update(ctxt, part, &chunk, &encoder), "encoding_update") { return false }
		}
		for i in 0..<int(encoder.channel_count) {
			channel := &encoder.channels[i]
			for name, k in CHANNEL_NAMES {
				if channel.channel_name == name {
					channel.encode_from_ptr         = (^u8)(&image[k][int(chunk.start_y) * WIDTH])
					channel.user_pixel_stride       = size_of(f32)
					channel.user_line_stride        = WIDTH * size_of(f32)
					channel.user_data_type          = u16(exr.pixel_type_t.FLOAT)
					channel.user_bytes_per_element  = size_of(f32)
				}
			}
		}
		if first {
			if !check(t, exr.encoding_choose_default_routines(ctxt, part, &encoder), "encoding_choose_default_routines") { return false }
			first = false
		}
		if !check(t, exr.encoding_run(ctxt, part, &encoder), "encoding_run") { return false }
	}
	exr.encoding_destroy(ctxt, &encoder)
	return true
}

read_image :: proc(t: ^testing.T, path: cstring, expected: exr.compression_t) -> (image: Image, ok: bool) {
	for &plane in image {
		plane = make([]f32, WIDTH * HEIGHT, context.temp_allocator)
	}

	init := exr.DEFAULT_CONTEXT_INITIALIZER
	ctxt: exr.context_t
	if !check(t, exr.start_read(&ctxt, path, &init), "start_read") { return }
	defer exr.finish(&ctxt)

	compression: exr.compression_t
	if !check(t, exr.get_compression(ctxt, 0, &compression), "get_compression") { return }
	testing.expect_value(t, compression, expected)

	lines: i32
	if !check(t, exr.get_scanlines_per_chunk(ctxt, 0, &lines), "get_scanlines_per_chunk") { return }

	decoder: exr.decode_pipeline_t
	first := true
	for y: i32 = 0; y < HEIGHT; y += lines {
		chunk: exr.chunk_info_t
		if !check(t, exr.read_scanline_chunk_info(ctxt, 0, y, &chunk), "read_scanline_chunk_info") { return }
		if first {
			if !check(t, exr.decoding_initialize(ctxt, 0, &chunk, &decoder), "decoding_initialize") { return }
		} else {
			if !check(t, exr.decoding_update(ctxt, 0, &chunk, &decoder), "decoding_update") { return }
		}
		for i in 0..<int(decoder.channel_count) {
			channel := &decoder.channels[i]
			for name, k in CHANNEL_NAMES {
				if channel.channel_name == name {
					channel.decode_to_ptr           = (^u8)(&image[k][int(chunk.start_y) * WIDTH])
					channel.user_pixel_stride       = size_of(f32)
					channel.user_line_stride        = WIDTH * size_of(f32)
					channel.user_data_type          = u16(exr.pixel_type_t.FLOAT)
					channel.user_bytes_per_element  = size_of(f32)
				}
			}
		}
		if first {
			if !check(t, exr.decoding_choose_default_routines(ctxt, 0, &decoder), "decoding_choose_default_routines") { return }
			first = false
		}
		if !check(t, exr.decoding_run(ctxt, 0, &decoder), "decoding_run") { return }
	}
	exr.decoding_destroy(ctxt, &decoder)
	return image, true
}

// Writes the image with `compression`, reads it back, and returns the largest difference seen (and the file size).
round_trip :: proc(t: ^testing.T, name: string, compression: exr.compression_t) -> (max_error: f32, file_size: i64, ok: bool) {
	image := make_image()
	path := temp_path(name)
	defer os.remove(string(path))

	if !write_image(t, path, compression, image) { return }
	if info, err := os.stat(string(path), context.temp_allocator); err == nil {
		file_size = info.size
	}
	decoded, read_ok := read_image(t, path, compression)
	if !read_ok { return }

	for k in 0..<3 {
		for i in 0..<WIDTH * HEIGHT {
			max_error = max(max_error, abs(decoded[k][i] - image[k][i]))
		}
	}
	return max_error, file_size, true
}

expect_lossless :: proc(t: ^testing.T, name: string, compression: exr.compression_t) {
	max_error, size, ok := round_trip(t, name, compression)
	if !ok { return }
	testing.expectf(t, max_error == 0, "%v must be lossless, the largest difference is %v", name, max_error)
	testing.expectf(t, size > 0, "%v wrote no file", name)
}

@(test) lossless_none     :: proc(t: ^testing.T) { expect_lossless(t, "none",     .NONE) }
@(test) lossless_rle      :: proc(t: ^testing.T) { expect_lossless(t, "rle",      .RLE) }
@(test) lossless_zips     :: proc(t: ^testing.T) { expect_lossless(t, "zips",     .ZIPS) }
@(test) lossless_zip      :: proc(t: ^testing.T) { expect_lossless(t, "zip",      .ZIP) }
@(test) lossless_piz      :: proc(t: ^testing.T) { expect_lossless(t, "piz",      .PIZ) }
@(test) lossless_htj2k256 :: proc(t: ^testing.T) { expect_lossless(t, "htj2k256", .HTJ2K256) }
@(test) lossless_htj2k32  :: proc(t: ^testing.T) { expect_lossless(t, "htj2k32",  .HTJ2K32) }
@(test) lossless_zstd     :: proc(t: ^testing.T) { expect_lossless(t, "zstd",     .ZSTD) }

// The lossy methods only have to come back close: LJ2K is the new lossy one, PXR24 and DWA the older ones.
expect_close :: proc(t: ^testing.T, name: string, compression: exr.compression_t, tolerance: f32) {
	max_error, size, ok := round_trip(t, name, compression)
	if !ok { return }
	testing.expectf(t, max_error <= tolerance, "%v: the largest difference %v is more than %v", name, max_error, tolerance)
	testing.expectf(t, size > 0, "%v wrote no file", name)
}

@(test) lossy_lj2k  :: proc(t: ^testing.T) { expect_close(t, "lj2k",  .LJ2K,  0.5) }
@(test) lossy_pxr24 :: proc(t: ^testing.T) { expect_close(t, "pxr24", .PXR24, 0.01) }
@(test) lossy_dwaa  :: proc(t: ^testing.T) { expect_close(t, "dwaa",  .DWAA,  0.5) }
@(test) lossy_dwab  :: proc(t: ^testing.T) { expect_close(t, "dwab",  .DWAB,  0.5) }

@(test)
zstd_levels :: proc(t: ^testing.T) {
	// a higher zstd level must still decode to the same pixels
	image := make_image()
	path := temp_path("zstd-level")
	defer os.remove(string(path))

	init := exr.DEFAULT_CONTEXT_INITIALIZER
	init.zstd_level = 19
	if !write_image(t, path, .ZSTD, image, init) { return }
	decoded, ok := read_image(t, path, .ZSTD)
	if !ok { return }
	for k in 0..<3 {
		for i in 0..<WIDTH * HEIGHT {
			if decoded[k][i] != image[k][i] {
				testing.expectf(t, false, "zstd level 19: pixel %v of channel %v differs", i, k)
				return
			}
		}
	}

	// the level of a part can be set and read back
	ctxt: exr.context_t
	init = exr.DEFAULT_CONTEXT_INITIALIZER
	if !check(t, exr.start_write(&ctxt, path, .WRITE_FILE_DIRECTLY, &init), "start_write") { return }
	defer exr.finish(&ctxt)
	part: c.int
	check(t, exr.add_part(ctxt, "image", .SCANLINE, &part), "add_part")
	check(t, exr.initialize_required_attr_simple(ctxt, part, WIDTH, HEIGHT, .ZSTD), "initialize_required_attr_simple")
	check(t, exr.set_zstd_compression_level(ctxt, part, 12), "set_zstd_compression_level")
	level: i32
	check(t, exr.get_zstd_compression_level(ctxt, part, &level), "get_zstd_compression_level")
	testing.expect_value(t, level, 12)
}

@(test)
htj2k_quality_per_part :: proc(t: ^testing.T) {
	path := temp_path("lj2k-quality")
	defer os.remove(string(path))

	// this test sets an invalid quality on purpose; the default error handler would print it to stderr
	quiet :: proc "c" (ctxt: exr.const_context_t, code: exr.result_t, msg: cstring) {}
	init := exr.DEFAULT_CONTEXT_INITIALIZER
	init.error_handler_fn = quiet
	ctxt: exr.context_t
	if !check(t, exr.start_write(&ctxt, path, .WRITE_FILE_DIRECTLY, &init), "start_write") { return }
	defer exr.finish(&ctxt)
	part: c.int
	check(t, exr.add_part(ctxt, "image", .SCANLINE, &part), "add_part")
	check(t, exr.initialize_required_attr_simple(ctxt, part, WIDTH, HEIGHT, .LJ2K), "initialize_required_attr_simple")
	// the quality is a number from 1 to 150 (the default is 110); anything else is rejected
	testing.expect_value(t, exr.set_lossy_htj2k_quality(ctxt, part, 0.75), exr.result_t.INVALID_ARGUMENT)
	check(t, exr.set_lossy_htj2k_quality(ctxt, part, 75), "set_lossy_htj2k_quality")
	quality: f32
	check(t, exr.get_lossy_htj2k_quality(ctxt, part, &quality), "get_lossy_htj2k_quality")
	testing.expect_value(t, quality, 75)
}

@(test)
bytes_attribute :: proc(t: ^testing.T) {
	path := temp_path("bytes")
	defer os.remove(string(path))

	init := exr.DEFAULT_CONTEXT_INITIALIZER
	ctxt: exr.context_t
	if !check(t, exr.start_write(&ctxt, path, .WRITE_FILE_DIRECTLY, &init), "start_write") { return }
	defer exr.finish(&ctxt)
	part: c.int
	check(t, exr.add_part(ctxt, "image", .SCANLINE, &part), "add_part")
	check(t, exr.initialize_required_attr_simple(ctxt, part, WIDTH, HEIGHT, .ZIP), "initialize_required_attr_simple")

	payload := [?]u8{1, 2, 3, 4, 5}
	hint := cstring("example")
	value := exr.attr_bytes_t{size = len(payload), data = raw_data(payload[:]), hint_length = u32(len(string(hint))), type_hint = hint}
	check(t, exr.attr_set_bytes(ctxt, part, "blob", &value), "attr_set_bytes")

	got: exr.attr_bytes_t
	check(t, exr.attr_get_bytes(ctxt, part, "blob", &got), "attr_get_bytes")
	testing.expect_value(t, int(got.size), len(payload))
	testing.expect_value(t, string(cstring(got.type_hint)), "example")
	if got.size == len(payload) {
		for i in 0..<len(payload) {
			testing.expect_value(t, got.data[i], payload[i])
		}
	}
}

@(test)
color_metadata :: proc(t: ^testing.T) {
	// the six interoperable IDs map to chromaticities and back
	chromaticities: exr.attr_chromaticities_t
	check(t, exr.color_interop_id_to_chromaticities("lin_rec709_scene", &chromaticities), "color_interop_id_to_chromaticities")
	testing.expect_value(t, chromaticities.red_x, 0.64)
	testing.expect_value(t, chromaticities.red_y, 0.33)

	id: cstring
	check(t, exr.chromaticities_to_color_interop_id(&chromaticities, exr.COLOR_INTEROP_ID_CHROMATICITIES_TOLERANCE, &id), "chromaticities_to_color_interop_id")
	testing.expect_value(t, string(id), "lin_rec709_scene")

	testing.expect_value(t, exr.color_interop_id_to_chromaticities("unknown", &chromaticities), exr.result_t.NO_ATTR_BY_NAME)

	// "data" parts must not carry chromaticities
	values := exr.color_metadata_t{color_interop_id = "data", chromaticities = &chromaticities}
	warnings: u32
	check(t, exr.check_color_metadata_values(&values, &warnings), "check_color_metadata_values")
	flags := transmute(exr.color_metadata_warning_flags_t)warnings
	testing.expect(t, .DATA_HAS_CHROMATICITIES in flags, "data with chromaticities must be reported")
	testing.expect(t, len(string(exr.get_color_metadata_warning_as_string(.DATA_HAS_CHROMATICITIES))) > 0)

	clean := exr.color_metadata_t{color_interop_id = "lin_rec709_scene"}
	check(t, exr.check_color_metadata_values(&clean, &warnings), "check_color_metadata_values")
	testing.expect_value(t, warnings, 0)
}
