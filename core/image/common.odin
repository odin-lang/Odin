/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
		Ginger Bill:     Cosmetic changes.
*/

// package image implements a general 2D image library to be used with other image related packages
package image

import "core:bytes"
import "core:mem"
import "core:compress"
import "core:runtime"

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

	metadata:      Image_Metadata,
}

Image_Metadata :: union {
	^PNG_Info,
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
Options :: distinct bit_set[Option]

Error :: union {
	General_Image_Error,
	PNG_Error,

	compress.Error,
	compress.General_Error,
	compress.Deflate_Error,
	compress.ZLIB_Error,
	runtime.Allocator_Error,
}

General_Image_Error :: enum {
	None = 0,
	Invalid_Image_Dimensions,
	Image_Dimensions_Too_Large,
	Image_Does_Not_Adhere_to_Spec,
}

PNG_Error :: enum {
	Invalid_PNG_Signature,
	IHDR_Not_First_Chunk,
	IHDR_Corrupt,
	IDAT_Missing,
	IDAT_Must_Be_Contiguous,
	IDAT_Corrupt,
	IDAT_Size_Too_Large,
	PLTE_Encountered_Unexpectedly,
	PLTE_Invalid_Length,
	TRNS_Encountered_Unexpectedly,
	BKGD_Invalid_Length,
	Unknown_Color_Type,
	Invalid_Color_Bit_Depth_Combo,
	Unknown_Filter_Method,
	Unknown_Interlace_Method,
	Requested_Channel_Not_Present,
	Post_Processing_Error,
	Invalid_Chunk_Length,
}

/*
	PNG-specific structs
*/
PNG_Info :: struct {
	header: PNG_IHDR,
	chunks: [dynamic]PNG_Chunk,
}

PNG_Chunk_Header :: struct #packed {
	length: u32be,
	type:   PNG_Chunk_Type,
}

PNG_Chunk :: struct #packed {
	header: PNG_Chunk_Header,
	data:   []byte,
	crc:    u32be,
}

PNG_Chunk_Type :: enum u32be {
	// IHDR must come first in a file
	IHDR = 'I' << 24 | 'H' << 16 | 'D' << 8 | 'R',
	// PLTE must precede the first IDAT chunk
	PLTE = 'P' << 24 | 'L' << 16 | 'T' << 8 | 'E',
	bKGD = 'b' << 24 | 'K' << 16 | 'G' << 8 | 'D',
	tRNS = 't' << 24 | 'R' << 16 | 'N' << 8 | 'S',
	IDAT = 'I' << 24 | 'D' << 16 | 'A' << 8 | 'T',

	iTXt = 'i' << 24 | 'T' << 16 | 'X' << 8 | 't',
	tEXt = 't' << 24 | 'E' << 16 | 'X' << 8 | 't',
	zTXt = 'z' << 24 | 'T' << 16 | 'X' << 8 | 't',

	iCCP = 'i' << 24 | 'C' << 16 | 'C' << 8 | 'P',
	pHYs = 'p' << 24 | 'H' << 16 | 'Y' << 8 | 's',
	gAMA = 'g' << 24 | 'A' << 16 | 'M' << 8 | 'A',
	tIME = 't' << 24 | 'I' << 16 | 'M' << 8 | 'E',

	sPLT = 's' << 24 | 'P' << 16 | 'L' << 8 | 'T',
	sRGB = 's' << 24 | 'R' << 16 | 'G' << 8 | 'B',
	hIST = 'h' << 24 | 'I' << 16 | 'S' << 8 | 'T',
	cHRM = 'c' << 24 | 'H' << 16 | 'R' << 8 | 'M',
	sBIT = 's' << 24 | 'B' << 16 | 'I' << 8 | 'T',

	/*
		eXIf tags are not part of the core spec, but have been ratified
		in v1.5.0 of the PNG Ext register.

		We will provide unprocessed chunks to the caller if `.return_metadata` is set.
		Applications are free to implement an Exif decoder.
	*/
	eXIf = 'e' << 24 | 'X' << 16 | 'I' << 8 | 'f',

	// PNG files must end with IEND
	IEND = 'I' << 24 | 'E' << 16 | 'N' << 8 | 'D',

	/*
		XCode sometimes produces "PNG" files that don't adhere to the PNG spec.
		We recognize them only in order to avoid doing further work on them.

		Some tools like PNG Defry may be able to repair them, but we're not
		going to reward Apple for producing proprietary broken files purporting
		to be PNGs by supporting them.

	*/
	iDOT = 'i' << 24 | 'D' << 16 | 'O' << 8 | 'T',
	CbGI = 'C' << 24 | 'b' << 16 | 'H' << 8 | 'I',
}

PNG_IHDR :: struct #packed {
	width:              u32be,
	height:             u32be,
	bit_depth:          u8,
	color_type:         PNG_Color_Type,
	compression_method: u8,
	filter_method:      u8,
	interlace_method:   PNG_Interlace_Method,
}
PNG_IHDR_SIZE :: size_of(PNG_IHDR)
#assert (PNG_IHDR_SIZE == 13)

PNG_Color_Value :: enum u8 {
	Paletted = 0, // 1 << 0 = 1
	Color    = 1, // 1 << 1 = 2
	Alpha    = 2, // 1 << 2 = 4
}
PNG_Color_Type :: distinct bit_set[PNG_Color_Value; u8]

PNG_Interlace_Method :: enum u8 {
	None  = 0,
	Adam7 = 1,
}

/*
	Functions to help with image buffer calculations
*/
compute_buffer_size :: proc(width, height, channels, depth: int, extra_row_bytes := int(0)) -> (size: int) {
	size = ((((channels * width * depth) + 7) >> 3) + extra_row_bytes) * height
	return
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
	ok = false
	t: bytes.Buffer

	idx := int(channel)

	if img.channels == 2 && idx == 4 {
		// Alpha requested, which in a two channel image is index 2: G.
		idx = 2
	}

	if idx > img.channels {
		return {}, false
	}

	switch img.depth {
	case 8:
		buffer_size := compute_buffer_size(img.width, img.height, 1, 8)
		t = bytes.Buffer{}
		resize(&t.buf, buffer_size)

		i := bytes.buffer_to_bytes(&img.pixels)
		o := bytes.buffer_to_bytes(&t)

		for len(i) > 0 {
			o[0] = i[idx]
			i = i[img.channels:]
			o = o[1:]
		}
	case 16:
		buffer_size := compute_buffer_size(img.width, img.height, 2, 8)
		t = bytes.Buffer{}
		resize(&t.buf, buffer_size)

		i := mem.slice_data_cast([]u16, img.pixels.buf[:])
		o := mem.slice_data_cast([]u16, t.buf[:])

		for len(i) > 0 {
			o[0] = i[idx]
			i = i[img.channels:]
			o = o[1:]
		}
	case 1, 2, 4:
		// We shouldn't see this case, as the loader already turns these into 8-bit.
		return {}, false
	}

	res = new(Image)
	res.width         = img.width
	res.height        = img.height
	res.channels      = 1
	res.depth         = img.depth
	res.pixels        = t
	res.background    = img.background
	res.metadata      = img.metadata

	return res, true
}
