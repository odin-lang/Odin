package image

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
		Ginger Bill:     Cosmetic changes.
*/

import "core:bytes"
import "core:mem"

Image :: struct {
	width:         int,
	height:        int,
	channels:      int,
	depth:         int,
	pixels:        bytes.Buffer,
	/*
		Some image loaders/writers can return/take an optional background color.
		For convenience, we return them as u16 so we don't need to switch on the type
		in our viewer, and can just test against nil.
	*/
	background:    Maybe([3]u16),

	metadata_ptr:  rawptr,
	metadata_type: typeid,
}

/*
	IMPORTANT: `.do_not_expand_*` options currently skip handling of the `alpha_*` options,
		therefore Gray+Alpha will be returned as such even if you add `.alpha_drop_if_present`,
		and `.alpha_add_if_missing` and keyed transparency will likewise be ignored.

		The same goes for indexed images. This will be remedied in a near future update.
*/

/*
Image_Option:
	`.info`
		This option behaves as `.return_ihdr` and `.do_not_decompress_image` and can be used
		to gather an image's dimensions and color information.

	`.return_header`
		Fill out img.sidecar.header with the image's format-specific header struct.
		If we only care about the image specs, we can set `.return_header` +
		`.do_not_decompress_image`, or `.info`, which works as if both of these were set.

	`.return_metadata`
		Returns all chunks not needed to decode the data.
		It also returns the header as if `.return_header` was set.

	`.do_not_decompress_image`
		Skip decompressing IDAT chunk, defiltering and the rest.

	`.do_not_expand_grayscale`
		Do not turn grayscale (+ Alpha) images into RGB(A).
		Returns just the 1 or 2 channels present, although 1, 2 and 4 bit are still scaled to 8-bit.

	`.do_not_expand_indexed`
		Do not turn indexed (+ Alpha) images into RGB(A).
		Returns just the 1 or 2 (with `tRNS`) channels present.
		Make sure to use `return_metadata` to also return the palette chunk so you can recolor it yourself.

	`.do_not_expand_channels`
		Applies both `.do_not_expand_grayscale` and `.do_not_expand_indexed`.

	`.alpha_add_if_missing`
		If the image has no alpha channel, it'll add one set to max(type).
		Turns RGB into RGBA and Gray into Gray+Alpha

	`.alpha_drop_if_present`
		If the image has an alpha channel, drop it.
		You may want to use `.alpha_premultiply` in this case.

		NOTE: For PNG, this also skips handling of the tRNS chunk, if present,
		unless you select `alpha_premultiply`.
		In this case it'll premultiply the specified pixels in question only,
		as the others are implicitly fully opaque.	

	`.alpha_premultiply`
		If the image has an alpha channel, returns image data as follows:
			RGB  *= A, Gray = Gray *= A

	`.blend_background`
		If a bKGD chunk is present in a PNG, we normally just set `img.background`
		with its value and leave it up to the application to decide how to display the image,
		as per the PNG specification.

		With `.blend_background` selected, we blend the image against the background
		color. As this negates the use for an alpha channel, we'll drop it _unless_
		you also specify `.alpha_add_if_missing`.

	Options that don't apply to an image format will be ignored by their loader.
*/

Option :: enum {
	info = 0,
	do_not_decompress_image,
	return_header,
	return_metadata,
	alpha_add_if_missing,
	alpha_drop_if_present,
	alpha_premultiply,
	blend_background,
	// Unimplemented
	do_not_expand_grayscale,
	do_not_expand_indexed,
	do_not_expand_channels,
}
Options :: distinct bit_set[Option];

Error :: enum {
	Invalid_PNG_Signature,
	IHDR_Not_First_Chunk,
	IHDR_Corrupt,
	IDAT_Missing,
	IDAT_Must_Be_Contiguous,
	IDAT_Corrupt,
	PNG_Does_Not_Adhere_to_Spec,
	PLTE_Encountered_Unexpectedly,
	PLTE_Invalid_Length,
	TRNS_Encountered_Unexpectedly,
	BKGD_Invalid_Length,
	Invalid_Image_Dimensions,
	Unknown_Color_Type,
	Invalid_Color_Bit_Depth_Combo,
	Unknown_Filter_Method,
	Unknown_Interlace_Method,
	Requested_Channel_Not_Present,
	Post_Processing_Error,
}

/*
	Functions to help with image buffer calculations
*/

compute_buffer_size :: proc(width, height, channels, depth: int, extra_row_bytes := int(0)) -> (size: int) {
	size = ((((channels * width * depth) + 7) >> 3) + extra_row_bytes) * height;
	return;
}

/*
	For when you have an RGB(A) image, but want a particular channel.
*/

Channel :: enum u8 {
	R = 1,
	G = 2,
	B = 3,
	A = 4,
}

return_single_channel :: proc(img: ^Image, channel: Channel) -> (res: ^Image, ok: bool) {
	ok = false;
	t: bytes.Buffer;

	idx := int(channel);

	if img.channels == 2 && idx == 4 {
		// Alpha requested, which in a two channel image is index 2: G.
		idx = 2;
	}

	if idx > img.channels {
		return {}, false;
	}

	switch img.depth {
	case 8:
		buffer_size := compute_buffer_size(img.width, img.height, 1, 8);
		t = bytes.Buffer{};
		resize(&t.buf, buffer_size);

		i := bytes.buffer_to_bytes(&img.pixels);
		o := bytes.buffer_to_bytes(&t);

		for len(i) > 0 {
			o[0] = i[idx];
			i = i[img.channels:];
			o = o[1:];
		}
	case 16:
		buffer_size := compute_buffer_size(img.width, img.height, 2, 8);
		t = bytes.Buffer{};
		resize(&t.buf, buffer_size);

		i := mem.slice_data_cast([]u16, img.pixels.buf[:]);
		o := mem.slice_data_cast([]u16, t.buf[:]);

		for len(i) > 0 {
			o[0] = i[idx];
			i = i[img.channels:];
			o = o[1:];
		}
	case 1, 2, 4:
		// We shouldn't see this case, as the loader already turns these into 8-bit.
		return {}, false;
	}

	res = new(Image);
	res.width         = img.width;
	res.height        = img.height;
	res.channels      = 1;
	res.depth         = img.depth;
	res.pixels        = t;
	res.background    = img.background;
	res.metadata_ptr  = img.metadata_ptr;
	res.metadata_type = img.metadata_type;

	return res, true;
}
