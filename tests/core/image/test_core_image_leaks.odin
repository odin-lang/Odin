package test_core_image

import "base:runtime"
import "core:bytes"
import "core:compress"
import "core:image"
import "core:image/jpeg"
import pbm "core:image/netpbm"
import "core:mem"
import "core:testing"

@(private="file")
LEAK_KINDS :: bit_set[Stream_Kind]{.Memory, .One_Byte_No_Seek}

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
leak_failing_allocator :: proc(fa: ^Leak_Failing_Allocator) -> runtime.Allocator {
	return {procedure = leak_failing_allocator_proc, data = fa}
}

@(private="file")
leak_tracker_init :: proc(track: ^mem.Tracking_Allocator) {
	mem.tracking_allocator_init(track, context.allocator)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array
}

@(private="file")
LEAK_OOM :: runtime.Allocator_Error.Out_Of_Memory

@(private="file")
leak_load_once :: proc(t: ^testing.T, name: string, data: []byte, loader: Context_Loader, options: image.Options, kind: Stream_Kind, fail_at: int, loc: runtime.Source_Code_Location) -> (count: int, ok: bool) {
	track: mem.Tracking_Allocator
	leak_tracker_init(&track)
	defer mem.tracking_allocator_destroy(&track)

	input := data
	br: bytes.Reader
	tr: Trickle_Reader
	ctx := stream_test_context(kind, &input, &br, &tr)
	defer compress.destroy_context(&ctx)

	fa := Leak_Failing_Allocator{backing = mem.tracking_allocator(&track), fail_at = fail_at}
	img: ^image.Image
	err: image.Error
	{
		context.allocator = leak_failing_allocator(&fa)
		img, err = loader(&ctx, options, context.allocator)
		if err == nil {
			image.destroy(img)
		}
	}
	count = fa.count

	if fail_at < 0 {
		ok = testing.expectf(t, err == nil, "%v, %v, %v: load returned %v", name, kind, options, err, loc=loc)
	} else {
		ok = testing.expectf(t, err == LEAK_OOM, "%v, %v, %v, allocation %v of %v failing: load returned %v, expected %v", name, kind, options, fail_at, count, err, LEAK_OOM, loc=loc)
	}
	nil_on_error := testing.expectf(t, err == nil || img == nil, "%v, %v, %v, allocation %v failing: load returned %v and an image", name, kind, options, fail_at, err, loc=loc)
	no_leak      := testing.expectf(t, len(track.allocation_map) == 0, "%v, %v, %v, allocation %v failing: %v allocations leaked", name, kind, options, fail_at, len(track.allocation_map), loc=loc)
	no_bad_free  := testing.expectf(t, len(track.bad_free_array) == 0, "%v, %v, %v, allocation %v failing: %v bad frees", name, kind, options, fail_at, len(track.bad_free_array), loc=loc)
	ok = ok && nil_on_error && no_leak && no_bad_free
	return
}

@(private="file")
leak_sweep_load :: proc(t: ^testing.T, name: string, data: []byte, loader: Context_Loader, options: image.Options, kinds := LEAK_KINDS, loc := #caller_location) {
	for kind in kinds {
		total, ok := leak_load_once(t, name, data, loader, options, kind, -1, loc)
		if !ok {
			continue
		}
		testing.expectf(t, total > 0, "%v, %v, %v: load made no allocations", name, kind, options, loc=loc)
		for k in 0..<total {
			if _, k_ok := leak_load_once(t, name, data, loader, options, kind, k, loc); !k_ok {
				break
			}
		}
	}
}

@(private="file")
leak_jpeg_segment :: proc(buf: ^[dynamic]u8, marker: u8, payload: []u8) {
	length := len(payload) + 2
	append(buf, 0xff, marker, u8(length >> 8), u8(length))
	append(buf, ..payload)
}

@(test)
jpeg_app_segments_oom :: proc(t: ^testing.T) {
	src := png_save_test_image(16, 16, 3, 8)
	defer delete(src.pixels)
	saved: [dynamic]u8
	defer delete(saved)
	if !testing.expect_value(t, jpeg.save(&saved, &src), nil) {
		return
	}

	thumbnail: [12]u8
	for &v, i in thumbnail {
		v = u8(i * 19)
	}

	jfif: [dynamic]u8
	defer delete(jfif)
	append(&jfif, "JFIF\x00")
	append(&jfif, 1, 2, 0, 0, 1, 0, 1, 2, 2)
	append(&jfif, ..thumbnail[:])

	jfxx_rgb: [dynamic]u8
	defer delete(jfxx_rgb)
	append(&jfxx_rgb, "JFXX\x00")
	append(&jfxx_rgb, 0x13, 2, 1)
	append(&jfxx_rgb, ..thumbnail[:6])

	JFXX_JPEG :: "JFXX\x00\x10\xff\xd8\xff\xd9"
	EXIF_LE   :: "Exif\x00\x00II\x2a\x00\x08\x00\x00\x00"
	EXIF_BE   :: "Exif\x00\x00MM\x00\x2a\x00\x00\x00\x08"
	COMMENT   :: "Odin was here"

	insert_at := 2
	if len(saved) > 6 && saved[2] == 0xff && saved[3] == 0xe0 {
		insert_at = 4 + (int(saved[4]) << 8 | int(saved[5]))
	}

	data: [dynamic]u8
	defer delete(data)
	append(&data, ..saved[:2])
	leak_jpeg_segment(&data, 0xe0, jfif[:])
	append(&data, ..saved[2:insert_at])
	leak_jpeg_segment(&data, 0xe0, jfxx_rgb[:])
	leak_jpeg_segment(&data, 0xe0, transmute([]u8)string(JFXX_JPEG))
	leak_jpeg_segment(&data, 0xe1, transmute([]u8)string(EXIF_LE))
	leak_jpeg_segment(&data, 0xe1, transmute([]u8)string(EXIF_BE))
	leak_jpeg_segment(&data, 0xfe, transmute([]u8)string(COMMENT))
	leak_jpeg_segment(&data, 0xe0, jfif[:])
	append(&data, ..saved[insert_at:])

	img, err := jpeg.load_from_bytes(data[:], {.return_metadata})
	if testing.expectf(t, err == nil, "load returned %v", err) {
		info, info_ok := img.metadata.(^image.JPEG_Info)
		if testing.expect(t, info_ok) {
			jfif_app0, jfif_ok := info.jfif_app0.?
			testing.expect(t, jfif_ok && len(jfif_app0.thumbnail) == 12)
			jfxx_app0, jfxx_ok := info.jfxx_app0.?
			testing.expect(t, jfxx_ok && jfxx_app0.extension_code == .Thumbnail_JPEG && len(jfxx_app0.thumbnail) == 4)
			testing.expect_value(t, len(info.exif), 2)
			testing.expect_value(t, len(info.comments), 1)
		}
		jpeg.destroy(img)
	}

	leak_sweep_load(t, "jpeg app segments", data[:], jpeg_context_loader, {.return_metadata})
	leak_sweep_load(t, "jpeg app segments", data[:], jpeg_context_loader, {})
}

@(test)
netpbm_pam_tupltype_temp_oom :: proc(t: ^testing.T) {
	PAM :: "P7\nWIDTH 2\nHEIGHT 1\nDEPTH 2\nMAXVAL 255\nTUPLTYPE GRAYSCALE\nTUPLTYPE ALPHA\nENDHDR\n\x01\x02\x03\x04"

	total := -1
	for k := -1; total < 0 || k < total; k += 1 {
		track: mem.Tracking_Allocator
		leak_tracker_init(&track)
		defer mem.tracking_allocator_destroy(&track)
		temp_track: mem.Tracking_Allocator
		leak_tracker_init(&temp_track)
		defer mem.tracking_allocator_destroy(&temp_track)

		fa := Leak_Failing_Allocator{backing = mem.tracking_allocator(&temp_track), fail_at = k}
		img: ^image.Image
		err: image.Error
		tupltype_ok := false
		{
			context.allocator      = mem.tracking_allocator(&track)
			context.temp_allocator = leak_failing_allocator(&fa)
			img, err = pbm.load_from_bytes(transmute([]u8)string(PAM))
			if err == nil {
				if info, info_ok := img.metadata.(^image.Netpbm_Info); info_ok {
					tupltype_ok = info.header.tupltype == "GRAYSCALE ALPHA"
				}
				pbm.destroy(img)
			}
		}
		if k < 0 {
			total = fa.count
			testing.expectf(t, err == nil && tupltype_ok, "load returned %v, tupltype ok %v", err, tupltype_ok)
			testing.expectf(t, total > 0, "load made no temp allocations")
		} else {
			testing.expectf(t, err == LEAK_OOM, "temp allocation %v of %v failing: load returned %v, expected %v", k, total, err, LEAK_OOM)
			testing.expectf(t, img == nil, "temp allocation %v failing: load returned an image", k)
		}
		testing.expectf(t, len(track.allocation_map) == 0, "temp allocation %v failing: %v allocations leaked", k, len(track.allocation_map))
		testing.expectf(t, len(track.bad_free_array) == 0, "temp allocation %v failing: %v bad frees", k, len(track.bad_free_array))
		testing.expectf(t, len(temp_track.allocation_map) == 0, "temp allocation %v failing: %v temp allocations leaked", k, len(temp_track.allocation_map))
		testing.expectf(t, len(temp_track.bad_free_array) == 0, "temp allocation %v failing: %v temp bad frees", k, len(temp_track.bad_free_array))
	}
}

@(private="file")
leak_fake_gif_load :: proc(data: []byte, options: image.Options, allocator: runtime.Allocator) -> (img: ^image.Image, err: image.Error) {
	img = new(image.Image, allocator) or_return
	img.pixels.allocator = allocator
	if _, append_err := append(&img.pixels, ..data); append_err != nil {
		delete(img.pixels)
		free(img, allocator)
		return nil, append_err
	}
	img.width    = len(data)
	img.height   = 1
	img.channels = 1
	img.depth    = 8
	img.which    = .GIF
	return img, nil
}

@(private="file")
leak_fake_gif_destroy :: proc(img: ^image.Image) {
	delete(img.pixels)
	free(img)
}

@(init, private="file")
leak_register_fake_gif :: proc "contextless" () {
	image.register(.GIF, leak_fake_gif_load, leak_fake_gif_destroy)
}
