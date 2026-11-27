package test_core_image

import "core:compress"
import "core:image"
import "core:image/bmp"
import "core:image/bng"
import "core:image/jpeg"
import pbm "core:image/netpbm"
import "core:image/png"
import "core:image/qoi"
import "core:image/tga"
import "core:mem"
import "core:os"
import "core:testing"

Destroyer :: #type proc(img: ^image.Image)

pbm_destroyer :: proc(img: ^image.Image) {
	pbm.destroy(img)
}

bng_context_loader :: proc(ctx: ^compress.Context, options: image.Options, allocator: mem.Allocator) -> (img: ^image.Image, err: image.Error) {
	return bng.load_from_context(ctx, options, allocator)
}

expect_destroy_on_load_allocator :: proc(t: ^testing.T, name: string, data: []byte, loader: Context_Loader, destroyer: Destroyer, options := image.Options{.return_metadata}, loc := #caller_location) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	input := data
	ctx := compress.init_context(&input)
	img, err := loader(&ctx, options, mem.tracking_allocator(&arg_track))
	testing.expectf(t, err == nil, "%v: load returned %v", name, err, loc=loc)
	if err != nil {
		destroyer(img)
		return
	}
	testing.expectf(t, img.metadata != nil, "%v: load returned no metadata", name, loc=loc)

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		destroyer(img)
	}
	testing.expectf(t, len(arg_track.allocation_map) == 0, "%v: %v allocations left on the load allocator after destroy", name, len(arg_track.allocation_map), loc=loc)
	testing.expectf(t, len(ctx_track.bad_free_array) == 0, "%v: destroy freed %v allocations through the context allocator", name, len(ctx_track.bad_free_array), loc=loc)
}

expect_destroy_on_load_allocator_file :: proc(t: ^testing.T, name, filename: string, loader: Context_Loader, destroyer: Destroyer, options := image.Options{.return_metadata}, loc := #caller_location) {
	data, read_err := os.read_entire_file(filename, context.allocator)
	defer delete(data)
	testing.expectf(t, read_err == nil, "%v: couldn't read %v: %v", name, filename, read_err, loc=loc)
	if read_err == nil {
		expect_destroy_on_load_allocator(t, name, data, loader, destroyer, options, loc)
	}
}

@test
image_destroy_uses_load_allocator :: proc(t: ^testing.T) {
	expect_destroy_on_load_allocator_file(t, "png",  TEST_SUITE_PATH_PNG + "/basn2c08.png",               png_context_loader,  png.destroy)
	expect_destroy_on_load_allocator_file(t, "png_header", TEST_SUITE_PATH_PNG + "/basn2c08.png",         png_context_loader,  png.destroy, {.return_header})
	expect_destroy_on_load_allocator_file(t, "bmp",  TEST_SUITE_PATH_BMP + "/rgb24.bmp",                  bmp_context_loader,  bmp.destroy)
	expect_destroy_on_load_allocator_file(t, "jpeg", TEST_SUITE_PATH_JPG + "/emblem-1024.jpg",            jpeg_context_loader, jpeg.destroy)
	expect_destroy_on_load_allocator_file(t, "bng",  TEST_SUITE_PATH_BNG + "/pngimg-crab_PNG40.bng",      bng_context_loader,  bng.destroy)
	expect_destroy_on_load_allocator_file(t, "any",  TEST_SUITE_PATH_PNG + "/basn2c08.png",               png_context_loader,  proc(img: ^image.Image) { image.destroy(img) })

	src, src_err := png.load(TEST_SUITE_PATH_PNG + "/basn2c08.png")
	defer png.destroy(src)
	testing.expectf(t, src_err == nil, "png: load returned %v", src_err)
	if src_err != nil {
		return
	}

	qoi_data: [dynamic]byte
	defer delete(qoi_data)
	testing.expect_value(t, qoi.save(&qoi_data, src), nil)
	expect_destroy_on_load_allocator(t, "qoi", qoi_data[:], qoi_context_loader, qoi.destroy)

	tga_data: [dynamic]byte
	defer delete(tga_data)
	testing.expect_value(t, tga.save(&tga_data, src), nil)
	expect_destroy_on_load_allocator(t, "tga", tga_data[:], tga_context_loader, tga.destroy)

	P7 :: "P7\nWIDTH 1\nHEIGHT 1\nDEPTH 3\nMAXVAL 255\nTUPLTYPE RGB\nENDHDR\n\x01\x02\x03"
	expect_destroy_on_load_allocator(t, "netpbm", transmute([]byte)string(P7), pbm_context_loader, pbm_destroyer)
}

@test
image_helpers_keep_load_allocator :: proc(t: ^testing.T) {
	arg_track, ctx_track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&arg_track, context.allocator)
	defer mem.tracking_allocator_destroy(&arg_track)
	mem.tracking_allocator_init(&ctx_track, context.allocator)
	defer mem.tracking_allocator_destroy(&ctx_track)
	ctx_track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	img, err := png.load(TEST_SUITE_PATH_PNG + "/basn0g08.png", {.do_not_expand_grayscale}, mem.tracking_allocator(&arg_track))
	testing.expectf(t, err == nil, "load returned %v", err)
	if err != nil {
		return
	}

	palette: [256]image.RGB_Pixel
	palette_rgba: [256]image.RGBA_Pixel
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		testing.expect(t, image.expand_grayscale(img))
		testing.expect(t, image.alpha_add_if_missing(img))
		testing.expect(t, image.alpha_drop_if_present(img, {.alpha_premultiply}))
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)

	gray, gray_err := png.load(TEST_SUITE_PATH_PNG + "/basn0g08.png", {.do_not_expand_grayscale}, mem.tracking_allocator(&arg_track))
	testing.expectf(t, gray_err == nil, "load returned %v", gray_err)
	if gray_err == nil {
		context.allocator = mem.tracking_allocator(&ctx_track)
		testing.expect(t, image.apply_palette(gray, palette))
		png.destroy(gray)
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)

	gray_rgba, gray_rgba_err := png.load(TEST_SUITE_PATH_PNG + "/basn0g08.png", {.do_not_expand_grayscale}, mem.tracking_allocator(&arg_track))
	testing.expectf(t, gray_rgba_err == nil, "load returned %v", gray_rgba_err)
	if gray_rgba_err == nil {
		context.allocator = mem.tracking_allocator(&ctx_track)
		testing.expect(t, image.apply_palette(gray_rgba, palette_rgba))
		png.destroy(gray_rgba)
	}
	testing.expect_value(t, ctx_track.total_allocation_count, 0)

	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		png.destroy(img)
	}
	testing.expect_value(t, len(arg_track.allocation_map), 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)

	plain := new(image.Image, mem.tracking_allocator(&arg_track))
	plain.pixels = make([dynamic]u8, 16, mem.tracking_allocator(&arg_track))
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		image.destroy(plain)
	}
	testing.expect_value(t, len(arg_track.allocation_map), 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)

	header, _, header_err := pbm.parse_header(transmute([]byte)string("P7\nWIDTH 1\nHEIGHT 1\nDEPTH 3\nMAXVAL 255\nTUPLTYPE RGB\nENDHDR\n"), mem.tracking_allocator(&arg_track))
	testing.expectf(t, header_err == nil || header_err == pbm.Format_Error.None, "parse_header returned %v", header_err)
	{
		context.allocator = mem.tracking_allocator(&ctx_track)
		pbm.header_destroy(&header, mem.tracking_allocator(&arg_track))
	}
	testing.expect_value(t, len(arg_track.allocation_map), 0)
	testing.expect_value(t, len(ctx_track.bad_free_array), 0)
}
