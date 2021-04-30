package image

import "core:bytes"

Image :: struct {
	width:      int,
	height:     int,
	channels:   int,
	depth:      u8,
	pixels:     bytes.Buffer,
	/*
		Some image loaders/writers can return/take an optional background color.
		For convenience, we return them as u16 so we don't need to switch on the type
		in our viewer, and can just test against nil.
	*/
	background: Maybe([3]u16),
	sidecar:    any,
}

/*
Image_Option:
	`.info`
		This option behaves as `return_ihdr` and `do_not_decompress_image` and can be used
		to gather an image's dimensions and color information.

	`.return_header`
		Fill out img.sidecar.header with the image's format-specific header struct.
		If we only care about the image specs, we can set `return_header` +
		`do_not_decompress_image`, or `.info`, which works as if both of these were set.

	`.return_metadata`
		Returns all chunks not needed to decode the data.
		It also returns the header as if `.return_header` is set.

	`do_not_decompress_image`
		Skip decompressing IDAT chunk, defiltering and the rest.

	`alpha_add_if_missing`
		If the image has no alpha channel, it'll add one set to max(type).
		Turns RGB into RGBA and Gray into Gray+Alpha

	`alpha_drop_if_present`
		If the image has an alpha channel, drop it.
		You may want to use `alpha_premultiply` in this case.

        NOTE: For PNG, this also skips handling of the tRNS chunk, if present,
        unless you select `alpha_premultiply`.
        In this case it'll premultiply the specified pixels in question only,
        as the others are implicitly fully opaque.	

	`alpha_premultiply`
		If the image has an alpha channel, returns image data as follows:
			RGB  *= A, Gray = Gray *= A

	`blend_background`
		If a bKGD chunk is present in a PNG, we normally just set `img.background`
		with its value and leave it up to the application to decide how to display the image,
		as per the PNG specification.

		With `blend_background` selected, we blend the image against the background
		color. As this negates the use for an alpha channel, we'll drop it _unless_
		you also specify `alpha_add_if_missing`.

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
}
Options :: distinct bit_set[Option];

PNG_Error :: enum {
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
}


/*
	Functions to help with image buffer calculations
*/

compute_buffer_size :: proc(width, height, channels, depth: int, extra_row_bytes := int(0)) -> (size: int) {

	size = ((((channels * width * depth) + 7) >> 3) + extra_row_bytes) * height;
	return;
}