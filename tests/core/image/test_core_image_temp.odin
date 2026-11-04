package test_core_image

import "core:compress"
import "core:hash"
import "core:image"
import "core:image/png"
import "core:image/qoi"
import "core:image/tga"
import pbm "core:image/netpbm"
import "core:mem"
import "core:os"
import "core:testing"

expect_survives_temp_allocator :: proc(t: ^testing.T, name: string, data: []byte, loader: Context_Loader, loc := #caller_location) {
	input := data
	ctx := compress.init_context(&input)
	want, want_err := loader(&ctx, {}, context.allocator)
	defer image.destroy(want)
	testing.expectf(t, want_err == nil, "%v: load returned %v", name, want_err, loc=loc)
	if want_err != nil {
		return
	}
	want_hash := hash.crc32(want.pixels[:])

	input = data
	ctx = compress.init_context(&input)
	img, err := loader(&ctx, {}, context.temp_allocator)
	testing.expectf(t, err == nil, "%v: load with the temp allocator returned %v", name, err, loc=loc)
	if err != nil {
		return
	}

	for size in ([]int{64, 4096, len(img.pixels), len(img.pixels) + 64 * 1024}) {
		scribble := make([]byte, size, context.temp_allocator)
		mem.set(raw_data(scribble), 0xAA, len(scribble))
	}

	got_hash := hash.crc32(img.pixels[:])
	testing.expectf(t, got_hash == want_hash, "%v: pixels allocated with the temp allocator were overwritten (%08x, expected %08x)", name, got_hash, want_hash, loc=loc)
}

expect_survives_temp_allocator_file :: proc(t: ^testing.T, name, filename: string, loader: Context_Loader, loc := #caller_location) {
	data, read_err := os.read_entire_file(filename, context.allocator)
	defer delete(data)
	testing.expectf(t, read_err == nil, "%v: couldn't read %v: %v", name, filename, read_err, loc=loc)
	if read_err == nil {
		expect_survives_temp_allocator(t, name, data, loader, loc)
	}
}

@test
image_load_with_temp_allocator :: proc(t: ^testing.T) {
	expect_survives_temp_allocator_file(t, "png",  TEST_SUITE_PATH_PNG + "/basn2c08.png",     png_context_loader)
	expect_survives_temp_allocator_file(t, "bmp",  TEST_SUITE_PATH_BMP + "/rgb24.bmp",        bmp_context_loader)
	expect_survives_temp_allocator_file(t, "bmp8", TEST_SUITE_PATH_BMP + "/pal8.bmp",         bmp_context_loader)
	expect_survives_temp_allocator_file(t, "jpeg", TEST_SUITE_PATH_JPG + "/emblem-1024.jpg",  jpeg_context_loader)
	expect_survives_temp_allocator_file(t, "jpeg_progressive", TEST_SUITE_PATH_JPG + "/emblem-1024-progressive.jpg", jpeg_context_loader)
	expect_survives_temp_allocator_file(t, "jpeg_gray",        TEST_SUITE_PATH_JPG + "/emblem-1024-gray.jpg",        jpeg_context_loader)

	src, src_err := png.load(TEST_SUITE_PATH_PNG + "/basn2c08.png")
	defer png.destroy(src)
	testing.expectf(t, src_err == nil, "png: load returned %v", src_err)
	if src_err != nil {
		return
	}

	qoi_data: [dynamic]byte
	defer delete(qoi_data)
	testing.expect_value(t, qoi.save(&qoi_data, src), nil)
	expect_survives_temp_allocator(t, "qoi", qoi_data[:], qoi_context_loader)

	tga_data: [dynamic]byte
	defer delete(tga_data)
	testing.expect_value(t, tga.save(&tga_data, src), nil)
	expect_survives_temp_allocator(t, "tga", tga_data[:], tga_context_loader)

	pbm_data, pbm_err := pbm.save_to_buffer(src)
	defer delete(pbm_data)
	testing.expect_value(t, pbm_err, nil)
	expect_survives_temp_allocator(t, "netpbm", pbm_data, pbm_context_loader)
}
