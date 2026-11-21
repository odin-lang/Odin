package test_core_image

import "core:image"
import "core:image/jpeg"
import "core:image/png"
import "core:os"
import "core:strings"
import "core:testing"

JPG_REFERENCE_MAX_DIFFERENCE :: 3
JPG_REFERENCE_MAX_MEAN       :: 0.25

JPG_Reference_Files := []string{
	"baseline-410",
	"baseline-411",
	"baseline-420",
	"baseline-422",
	"baseline-440",
	"baseline-444",
	"baseline-chroma-up",
	"baseline-mixed",
	"grad-420",
	"gray-2x2",
	"gray-odd",
	"gray-restart",
	"gray",
	"noise-q100",
	"odd-411",
	"odd-420",
	"odd-444",
	"one-420",
	"optimize-420",
	"prog-411",
	"prog-420",
	"prog-444",
	"prog-gray-odd",
	"prog-gray-sa",
	"prog-gray",
	"prog-mixed",
	"prog-noise-q100",
	"prog-odd",
	"prog-one",
	"prog-restart",
	"prog-sa",
	"prog-separate",
	"q100-444",
	"q5-420",
	"restart-1mcu",
	"restart-3mcu",
	"restart-411-7",
	"restart-row",
	"rgb",
	"seq-separate",
	"seq-y-cbcr",
}

@test
jpeg_test_reference :: proc(t: ^testing.T) {
	for name in JPG_Reference_Files {
		jpg_file := strings.concatenate({TEST_SUITE_PATH_JPG, "/", name, ".jpg"}, context.temp_allocator)

		img, err := jpeg.load(jpg_file)
		defer jpeg.destroy(img)
		expect_stream_loads_file(t, name, jpg_file, jpeg_context_loader, {}, img, err)
		testing.expectf(t, err == nil, "%v: load returned %v", name, err)
		if err == nil {
			expect_matches_reference(t, name, img, name)
		}
	}
}

@test
jpeg_test_rgb_component_ids :: proc(t: ^testing.T) {
	name     := "rgb-no-adobe"
	jpg_file := TEST_SUITE_PATH_JPG + "/rgb.jpg"

	data, read_err := os.read_entire_file(jpg_file, context.allocator)
	defer delete(data)
	testing.expectf(t, read_err == nil, "%v: couldn't read %v: %v", name, jpg_file, read_err)
	if read_err != nil {
		return
	}

	stripped := make([dynamic]byte, 0, len(data))
	defer delete(stripped)
	append(&stripped, ..data[:2])
	removed := 0
	i := 2
	for i + 4 <= len(data) && data[i] == 0xFF && data[i + 1] != 0xDA {
		length := int(data[i + 2]) << 8 | int(data[i + 3])
		if i + 2 + length > len(data) {
			break
		}
		if data[i + 1] == 0xEE {
			removed += 1
		} else {
			append(&stripped, ..data[i:][:2 + length])
		}
		i += 2 + length
	}
	append(&stripped, ..data[i:])
	testing.expectf(t, removed == 1, "%v: expected to remove 1 APP14 segment, removed %v", name, removed)

	img, err := jpeg.load_from_bytes(stripped[:])
	defer jpeg.destroy(img)
	testing.expectf(t, err == nil, "%v: load returned %v", name, err)
	if err == nil {
		expect_matches_reference(t, name, img, "rgb")
	}
}

expect_matches_reference :: proc(t: ^testing.T, name: string, img: ^image.Image, reference: string, loc := #caller_location) {
	ref_file := strings.concatenate({TEST_SUITE_PATH_JPG, "/", reference, ".ref.png"}, context.temp_allocator)
	ref, ref_err := png.load(ref_file, {.do_not_expand_channels})
	defer png.destroy(ref)
	testing.expectf(t, ref_err == nil, "%v: reference load returned %v", name, ref_err, loc=loc)
	if ref_err != nil {
		return
	}

	dims     := Dims{img.width, img.height, img.channels, img.depth}
	ref_dims := Dims{ref.width, ref.height, 3, 8}
	testing.expectf(t, dims == ref_dims, "%v has %v, expected %v", name, dims, ref_dims, loc=loc)
	if dims != ref_dims {
		return
	}

	max_difference := 0
	total          := 0
	pixels         := img.width * img.height
	for i in 0..<pixels {
		for c in 0..<3 {
			a := int(img.pixels[i * 3 + c])
			b := int(ref.pixels[i * ref.channels + min(c, ref.channels - 1)])
			max_difference = max(max_difference, abs(a - b))
			total += abs(a - b)
		}
	}
	mean := f64(total) / f64(pixels * 3)
	testing.expectf(t, max_difference <= JPG_REFERENCE_MAX_DIFFERENCE, "%v: maximum difference from the reference is %v", name, max_difference, loc=loc)
	testing.expectf(t, mean <= JPG_REFERENCE_MAX_MEAN, "%v: mean difference from the reference is %v", name, mean, loc=loc)
}
