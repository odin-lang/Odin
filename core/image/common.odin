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
import "core:io"
import "core:compress"
import "base:runtime"

/*
	67_108_864 pixels max by default.

	For QOI, the Worst case scenario means all pixels will be encoded as RGBA literals, costing 5 bytes each.
	This caps memory usage at 320 MiB.

	The tunable is limited to 4_294_836_225 pixels maximum, or 4 GiB per 8-bit channel.
	It is not advised to tune it this large.

	The 64 Megapixel default is considered to be a decent upper bound you won't run into in practice,
	except in very specific circumstances.

*/
MAX_DIMENSIONS :: min(#config(MAX_DIMENSIONS, 8192 * 8192), 65535 * 65535)

// Color
RGB_Pixel     :: [3]u8
RGBA_Pixel    :: [4]u8
RGB_Pixel_16  :: [3]u16
RGBA_Pixel_16 :: [4]u16
// Grayscale
G_Pixel       :: [1]u8
GA_Pixel      :: [2]u8
G_Pixel_16    :: [1]u16
GA_Pixel_16   :: [2]u16

Image :: struct {
	width:         int,
	height:        int,
	channels:      int,
	depth:         int, // Channel depth in bits, typically 8 or 16
	pixels:        bytes.Buffer `fmt:"-"`,
	/*
		Some image loaders/writers can return/take an optional background color.
		For convenience, we return them as u16 so we don't need to switch on the type
		in our viewer, and can just test against nil.
	*/
	background:    Maybe(RGB_Pixel_16),
	metadata:      Image_Metadata,
	which:         Which_File_Type,
}

Image_Metadata :: union #shared_nil {
	^Netpbm_Info,
	^PNG_Info,
	^QOI_Info,
	^TGA_Info,
	^BMP_Info,
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
		This option behaves as `.return_metadata` and `.do_not_decompress_image` and can be used
		to gather an image's dimensions and color information.

	`.return_header`
		Fill out img.metadata.header with the image's format-specific header struct.
		If we only care about the image specs, we can set `.return_header` +
		`.do_not_decompress_image`, or `.info`.

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
		You may want to use `.alpha_
		tiply` in this case.

		NOTE: For PNG, this also skips handling of the tRNS chunk, if present,
		unless you select `alpha_premultiply`.
		In this case it'll premultiply the specified pixels in question only,
		as the others are implicitly fully opaque.	

	`.alpha_premultiply`
		If the image has an alpha channel, returns image data as follows:
			RGB *= A, Gray = Gray *= A

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
	// LOAD OPTIONS
	info = 0,
	do_not_decompress_image,
	return_header,
	return_metadata,
	alpha_add_if_missing,          // Ignored for QOI. Always returns RGBA8.
	alpha_drop_if_present,         // Unimplemented for QOI. Returns error.
	alpha_premultiply,             // Unimplemented for QOI. Returns error.
	blend_background,              // Ignored for non-PNG formats

	// Unimplemented
	do_not_expand_grayscale,
	do_not_expand_indexed,
	do_not_expand_channels,

	// SAVE OPTIONS
	qoi_all_channels_linear,       // QOI, informative only. If not set, defaults to sRGB with linear alpha.
}
Options :: distinct bit_set[Option]

Error :: union #shared_nil {
	General_Image_Error,
	Netpbm_Error,
	PNG_Error,
	QOI_Error,
	BMP_Error,

	compress.Error,
	compress.General_Error,
	compress.Deflate_Error,
	compress.ZLIB_Error,
	io.Error,
	runtime.Allocator_Error,
}

General_Image_Error :: enum {
	None = 0,
	Unsupported_Option,
	// File I/O
	Unable_To_Read_File,
	Unable_To_Write_File,

	// Invalid
	Unsupported_Format,
	Invalid_Signature,
	Invalid_Input_Image,
	Image_Dimensions_Too_Large,
	Invalid_Image_Dimensions,
	Invalid_Number_Of_Channels,
	Image_Does_Not_Adhere_to_Spec,
	Invalid_Image_Depth,
	Invalid_Bit_Depth,
	Invalid_Color_Space,

	// More data than pixels to decode into, for example.
	Corrupt,

	// Output buffer is the wrong size
	Invalid_Output,

	// Allocation
	Unable_To_Allocate_Or_Resize,
}

/*
	BMP-specific
*/
BMP_Error :: enum {
	None = 0,
	Invalid_File_Size,
	Unsupported_BMP_Version,
	Unsupported_OS2_File,
	Unsupported_Compression,
	Unsupported_BPP,
	Invalid_Stride,
	Invalid_Color_Count,
	Implausible_File_Size,
	Bitfield_Version_Unhandled, // We don't (yet) handle bit fields for this BMP version.
	Bitfield_Sum_Exceeds_BPP,   // Total mask bit count > bpp
	Bitfield_Overlapped,        // Channel masks overlap
}

// img.metadata is wrapped in a struct in case we need to add to it later
// without putting it in BMP_Header
BMP_Info :: struct {
	info: BMP_Header,
}

BMP_Magic :: enum u16le {
	Bitmap            = 0x4d42, // 'BM'
	OS2_Bitmap_Array  = 0x4142, // 'BA'
	OS2_Icon          = 0x4349, // 'IC',
	OS2_Color_Icon    = 0x4943, // 'CI'
	OS2_Pointer       = 0x5450, // 'PT'
	OS2_Color_Pointer = 0x5043, // 'CP'
}

// See: http://justsolve.archiveteam.org/wiki/BMP#Well-known_versions
BMP_Version :: enum u32le {
	OS2_v1    = 12,  // BITMAPCOREHEADER  (Windows V2 / OS/2 version 1.0)
	OS2_v2    = 64,  // BITMAPCOREHEADER2 (OS/2 version 2.x)
	V3        = 40,  // BITMAPINFOHEADER
	V4        = 108, // BITMAPV4HEADER
	V5        = 124, // BITMAPV5HEADER

	ABBR_16   = 16,  // Abbreviated
	ABBR_24   = 24,  // ..
	ABBR_48   = 48,  // ..
	ABBR_52   = 52,  // ..
	ABBR_56   = 56,  // ..
}

BMP_Header :: struct #packed {
	// File header
	magic:            BMP_Magic,
	size:             u32le,
	_res1:            u16le, // Reserved; must be zero
	_res2:            u16le, // Reserved; must be zero
	pixel_offset:     u32le, // Offset in bytes, from the beginning of BMP_Header to the pixel data
	// V3
	info_size:        BMP_Version,
	width:            i32le,
	height:           i32le,
	planes:           u16le,
	bpp:              u16le,
	compression:      BMP_Compression,
	image_size:       u32le,
	pels_per_meter:   [2]u32le,
	colors_used:      u32le,
	colors_important: u32le, // OS2_v2 is equal up to here
	// V4
	masks:            [4]u32le `fmt:"32b"`,
	colorspace:       BMP_Logical_Color_Space,
	endpoints:        BMP_CIEXYZTRIPLE,
	gamma:            [3]BMP_GAMMA16_16,
	// V5
	intent:           BMP_Gamut_Mapping_Intent,
	profile_data:     u32le,
	profile_size:     u32le,
	reserved:         u32le,
}
#assert(size_of(BMP_Header) == 138)

OS2_Header :: struct #packed {
	// BITMAPCOREHEADER minus info_size field
	width:            i16le,
	height:           i16le,
	planes:           u16le,
	bpp:              u16le,
}
#assert(size_of(OS2_Header) == 8)

BMP_Compression :: enum u32le {
	RGB              = 0x0000,
	RLE8             = 0x0001,
	RLE4             = 0x0002,
	Bit_Fields       = 0x0003, // If Windows
	Huffman1D        = 0x0003, // If OS2v2
	JPEG             = 0x0004, // If Windows
	RLE24            = 0x0004, // If OS2v2
	PNG              = 0x0005,
	Alpha_Bit_Fields = 0x0006,
	CMYK             = 0x000B,
	CMYK_RLE8        = 0x000C,
	CMYK_RLE4        = 0x000D,
}

BMP_Logical_Color_Space :: enum u32le {
	CALIBRATED_RGB      = 0x00000000,
	sRGB                = 0x73524742, // 'sRGB'
	WINDOWS_COLOR_SPACE = 0x57696E20, // 'Win '
}

BMP_FXPT2DOT30   :: u32le
BMP_CIEXYZ       :: [3]BMP_FXPT2DOT30
BMP_CIEXYZTRIPLE :: [3]BMP_CIEXYZ
BMP_GAMMA16_16   :: [2]u16le

BMP_Gamut_Mapping_Intent :: enum u32le {
	INVALID          = 0x00000000, // If not V5, this field will just be zero-initialized and not valid.
	ABS_COLORIMETRIC = 0x00000008,
	BUSINESS         = 0x00000001,
	GRAPHICS         = 0x00000002,
	IMAGES           = 0x00000004,
}

/*
	Netpbm-specific definitions
*/
Netpbm_Format :: enum {
	P1, P2, P3, P4, P5, P6, P7, Pf, PF,
}

Netpbm_Header :: struct {
	format:        Netpbm_Format,
	width:         int,
	height:        int,
	channels:      int,
	depth:         int,
	maxval:        int,
	tupltype:      string,
	scale:         f32,
	little_endian: bool,
}

Netpbm_Info :: struct {
	header: Netpbm_Header,
}

Netpbm_Error :: enum {
	None = 0,

	// reading
	Invalid_Header_Token_Character,
	Incomplete_Header,
	Invalid_Header_Value,
	Duplicate_Header_Field,
	Buffer_Too_Small,
	Invalid_Buffer_ASCII_Token,
	Invalid_Buffer_Value,

	// writing
	Invalid_Format,
}

/*
	PNG-specific definitions
*/
PNG_Error :: enum {
	None = 0,
	IHDR_Not_First_Chunk,
	IHDR_Corrupt,
	IDAT_Missing,
	IDAT_Must_Be_Contiguous,
	IDAT_Corrupt,
	IDAT_Size_Too_Large,
	PLTE_Encountered_Unexpectedly,
	PLTE_Invalid_Length,
	PLTE_Missing,
	TRNS_Encountered_Unexpectedly,
	TNRS_Invalid_Length,
	BKGD_Invalid_Length,
	Unknown_Color_Type,
	Invalid_Color_Bit_Depth_Combo,
	Unknown_Filter_Method,
	Unknown_Interlace_Method,
	Requested_Channel_Not_Present,
	Post_Processing_Error,
	Invalid_Chunk_Length,
}

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
	CgBI = 'C' << 24 | 'g' << 16 | 'B' << 8 | 'I',
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
	QOI-specific definitions
*/
QOI_Error :: enum {
	None = 0,
	Missing_Or_Corrupt_Trailer, // Image seemed to have decoded okay, but trailer is missing or corrupt.
}

QOI_Magic :: u32be(0x716f6966) // "qoif"

QOI_Color_Space :: enum u8 {
	sRGB   = 0,
	Linear = 1,
}

QOI_Header :: struct #packed {
	magic:       u32be,
	width:       u32be,
	height:      u32be,
	channels:    u8,
	color_space: QOI_Color_Space,
}
#assert(size_of(QOI_Header) == 14)

QOI_Info :: struct {
	header: QOI_Header,
}

TGA_Data_Type :: enum u8  {
	No_Image_Data             = 0,
	Uncompressed_Color_Mapped = 1,
	Uncompressed_RGB          = 2,
	Uncompressed_Black_White  = 3,
	Compressed_Color_Mapped   = 9,
	Compressed_RGB            = 10,
	Compressed_Black_White    = 11,
}

TGA_Header :: struct #packed {
	id_length:        u8,
	color_map_type:   u8,
	data_type_code:   TGA_Data_Type,
	color_map_origin: u16le,
	color_map_length: u16le,
	color_map_depth:  u8,
	origin:           [2]u16le,
	dimensions:       [2]u16le,
	bits_per_pixel:   u8,
	image_descriptor: u8,
}
#assert(size_of(TGA_Header) == 18)

New_TGA_Signature :: "TRUEVISION-XFILE.\x00"

TGA_Footer :: struct #packed {
	extension_area_offset:      u32le,
	developer_directory_offset: u32le,
	signature:                  [18]u8 `fmt:"s,0"`, // Should match signature if New TGA.
}
#assert(size_of(TGA_Footer) == 26)

TGA_Extension :: struct #packed {
	extension_size:          u16le,               // Size of this struct. If not 495 bytes it means it's an unsupported version.
	author_name:             [41]u8  `fmt:"s,0"`, // Author name, ASCII. Zero-terminated
	author_comments:         [324]u8 `fmt:"s,0"`, // Author comments, formatted as 4 lines of 80 character lines, each zero terminated.
	datetime:                struct {month, day, year, hour, minute, second: u16le},
	job_name:                [41]u8  `fmt:"s,0"`, // Author name, ASCII. Zero-terminated
	job_time:                struct {hour, minute, second: u16le},
	software_id:             [41]u8  `fmt:"s,0"`, // Software ID name, ASCII. Zero-terminated
	software_version: struct #packed {
		number: u16le, // Version number * 100
		letter: u8 `fmt:"r"`,   // " " if not used
	},
	key_color:               [4]u8,    // ARGB key color used at time of production
	aspect_ratio:            [2]u16le, // Numerator / Denominator
	gamma:                   [2]u16le, // Numerator / Denominator, range should be 0.0..10.0
	color_correction_offset: u32le,    // 0 if no color correction information
	postage_stamp_offset:    u32le,    // 0 if no thumbnail
	scanline_offset:         u32le,    // 0 if no scanline table
	attributes:              TGA_Alpha_Kind,
}
#assert(size_of(TGA_Extension) == 495)

TGA_Alpha_Kind :: enum u8 {
	None,
	Undefined_Ignore,
	Undefined_Retain,
	Useful,
	Premultiplied,
}

TGA_Info :: struct {
	header:    TGA_Header,
	image_id:  string,
	footer:    Maybe(TGA_Footer),
	extension: Maybe(TGA_Extension),
}

// Function to help with image buffer calculations
compute_buffer_size :: proc(width, height, channels, depth: int, extra_row_bytes := int(0)) -> (size: int) {
	size = ((((channels * width * depth) + 7) >> 3) + extra_row_bytes) * height
	return
}

Channel :: enum u8 {
	R = 1,
	G = 2,
	B = 3,
	A = 4,
}

// Take a slice of pixels (`[]RGBA_Pixel`, etc), and return an `Image`
// Don't call `destroy` on the resulting `Image`. Instead, delete the original `pixels` slice.
pixels_to_image :: proc(pixels: [][$N]$E, width: int, height: int) -> (img: Image, ok: bool) where E == u8 || E == u16, N >= 1, N <= 4 {
	if len(pixels) != width * height {
		return {}, false
	}

	img.height   = height
	img.width    = width
	img.depth    = 8 when E == u8 else 16
	img.channels = N

	s := transmute(runtime.Raw_Slice)pixels
	d := runtime.Raw_Dynamic_Array{
		data = s.data,
		len  = s.len * size_of(E) * N,
		cap  = s.len * size_of(E) * N,
		allocator = runtime.nil_allocator(),
	}
	img.pixels = bytes.Buffer{
		buf = transmute([dynamic]u8)d,
	}

	return img, true
}

// When you have an RGB(A) image, but want a particular channel.
return_single_channel :: proc(img: ^Image, channel: Channel) -> (res: ^Image, ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return nil, false
	}

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
		buffer_size := compute_buffer_size(img.width, img.height, 1, 16)
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

// Does the image have 1 or 2 channels, a valid bit depth (8 or 16),
// Is the pointer valid, are the dimensions valid?
is_valid_grayscale_image :: proc(img: ^Image) -> (ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return false
	}

	// Are we a Gray or Gray + Alpha image?
	if img.channels != 1 && img.channels != 2 {
		return false
	}

	// Do we have an acceptable bit depth?
	if img.depth != 8 && img.depth != 16 {
		return false
	}

	// This returns 0 if any of the inputs is zero.
	bytes_expected := compute_buffer_size(img.width, img.height, img.channels, img.depth)

	// If the dimensions are invalid or the buffer size doesn't match the image characteristics, bail.
	if bytes_expected == 0 || bytes_expected != len(img.pixels.buf) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	return true
}

// Does the image have 3 or 4 channels, a valid bit depth (8 or 16),
// Is the pointer valid, are the dimensions valid?
is_valid_color_image :: proc(img: ^Image) -> (ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return false
	}

	// Are we an RGB or RGBA image?
	if img.channels != 3 && img.channels != 4 {
		return false
	}

	// Do we have an acceptable bit depth?
	if img.depth != 8 && img.depth != 16 {
		return false
	}

	// This returns 0 if any of the inputs is zero.
	bytes_expected := compute_buffer_size(img.width, img.height, img.channels, img.depth)

	// If the dimensions are invalid or the buffer size doesn't match the image characteristics, bail.
	if bytes_expected == 0 || bytes_expected != len(img.pixels.buf) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	return true
}

// Does the image have 1..4 channels, a valid bit depth (8 or 16),
// Is the pointer valid, are the dimensions valid?
is_valid_image :: proc(img: ^Image) -> (ok: bool) {
	// Were we actually given a valid image?
	if img == nil {
		return false
	}

	return is_valid_color_image(img) || is_valid_grayscale_image(img)
}

Alpha_Key :: union {
	GA_Pixel,
	RGBA_Pixel,
	GA_Pixel_16,
	RGBA_Pixel_16,
}

/*
	Add alpha channel if missing, in-place.

	Expects 1..4 channels (Gray, Gray + Alpha, RGB, RGBA).
	Any other number of channels will be considered an error, returning `false` without modifying the image.
	If the input image already has an alpha channel, it'll return `true` early (without considering optional keyed alpha).

	If an image doesn't already have an alpha channel:
	If the optional `alpha_key` is provided, it will be resolved as follows:
		- For RGB,  if pix = key.rgb -> pix = {0, 0, 0, key.a}
		- For Gray, if pix = key.r  -> pix = {0, key.g}
	Otherwise, an opaque alpha channel will be added.
*/
alpha_add_if_missing :: proc(img: ^Image, alpha_key := Alpha_Key{}, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if !is_valid_image(img) {
		return false
	}

	// We should now have a valid Image with 1..4 channels. Do we already have alpha?
	if img.channels == 2 || img.channels == 4 {
		// We're done.
		return true
	}

	channels     := img.channels + 1
	bytes_wanted := compute_buffer_size(img.width, img.height, channels, img.depth)

	buf := bytes.Buffer{}

	// Can we allocate the return buffer?
	if resize(&buf.buf, bytes_wanted) != nil {
		delete(buf.buf)
		return false
	}

	switch img.depth {
	case 8:
		switch channels {
		case 2:
			// Turn Gray into Gray + Alpha
			inp := mem.slice_data_cast([]G_Pixel,  img.pixels.buf[:])
			out := mem.slice_data_cast([]GA_Pixel, buf.buf[:])

			if key, key_ok := alpha_key.(GA_Pixel); key_ok {
				// We have keyed alpha.
				o: GA_Pixel
				for p in inp {
					if p.r == key.r {
						o = GA_Pixel{0, key.g}
					} else {
						o = GA_Pixel{p.r, 255}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := GA_Pixel{0, 255}
				for p in inp {
					o.r    = p.r
					out[0] = o
					out = out[1:]
				}
			}

		case 4:
			// Turn RGB into RGBA
			inp := mem.slice_data_cast([]RGB_Pixel,  img.pixels.buf[:])
			out := mem.slice_data_cast([]RGBA_Pixel, buf.buf[:])

			if key, key_ok := alpha_key.(RGBA_Pixel); key_ok {
				// We have keyed alpha.
				o: RGBA_Pixel
				for p in inp {
					if p == key.rgb {
						o = RGBA_Pixel{0, 0, 0, key.a}
					} else {
						o = RGBA_Pixel{p.r, p.g, p.b, 255}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := RGBA_Pixel{0, 0, 0, 255}
				for p in inp {
					o.rgb  = p
					out[0] = o
					out = out[1:]
				}
			}
		case:
			// We shouldn't get here.
			unreachable()
		}
	case 16:
		switch channels {
		case 2:
			// Turn Gray into Gray + Alpha
			inp := mem.slice_data_cast([]G_Pixel_16,  img.pixels.buf[:])
			out := mem.slice_data_cast([]GA_Pixel_16, buf.buf[:])

			if key, key_ok := alpha_key.(GA_Pixel_16); key_ok {
				// We have keyed alpha.
				o: GA_Pixel_16
				for p in inp {
					if p.r == key.r {
						o = GA_Pixel_16{0, key.g}
					} else {
						o = GA_Pixel_16{p.r, 65535}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := GA_Pixel_16{0, 65535}
				for p in inp {
					o.r    = p.r
					out[0] = o
					out = out[1:]
				}
			}

		case 4:
			// Turn RGB into RGBA
			inp := mem.slice_data_cast([]RGB_Pixel_16,  img.pixels.buf[:])
			out := mem.slice_data_cast([]RGBA_Pixel_16, buf.buf[:])

			if key, key_ok := alpha_key.(RGBA_Pixel_16); key_ok {
				// We have keyed alpha.
				o: RGBA_Pixel_16
				for p in inp {
					if p == key.rgb {
						o = RGBA_Pixel_16{0, 0, 0, key.a}
					} else {
						o = RGBA_Pixel_16{p.r, p.g, p.b, 65535}
					}
					out[0] = o
					out = out[1:]
				}
			} else {
				// No keyed alpha, just make all pixels opaque.
				o := RGBA_Pixel_16{0, 0, 0, 65535}
				for p in inp {
					o.rgb  = p
					out[0] = o
					out = out[1:]
				}
			}
		case:
			// We shouldn't get here.
			unreachable()
		}
	}

	// If we got here, that means we've now got a buffer with the alpha channel added.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	bytes.buffer_destroy(&img.pixels)
	img.pixels   = buf
	img.channels = channels
	return true
}
alpha_apply_keyed_alpha :: alpha_add_if_missing

/*
	Drop alpha channel if present, in-place.

	Expects 1..4 channels (Gray, Gray + Alpha, RGB, RGBA).
	Any other number of channels will be considered an error, returning `false` without modifying the image.

	Of the `options`, the following are considered:
	`.alpha_premultiply`
		If the image has an alpha channel, returns image data as follows:
			RGB *= A, Gray = Gray *= A

	`.blend_background`
		If `img.background` is set, it'll be blended in like this:
			RGB = (1 - A) * Background + A * RGB

	If an image has 1 (Gray) or 3 (RGB) channels, it'll return early without modifying the image,
	with one exception: `alpha_key` and `img.background` are present, and `.blend_background` is set.

	In this case a keyed alpha pixel will be replaced with the background color.
*/
alpha_drop_if_present :: proc(img: ^Image, options := Options{}, alpha_key := Alpha_Key{}, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if !is_valid_image(img) {
		return false
	}

	// Do we have a background to blend?
	will_it_blend := false
	switch v in img.background {
	case RGB_Pixel_16: will_it_blend = true if .blend_background in options else false
	}

	// Do we have keyed alpha?
	keyed := false
	switch v in alpha_key {
	case GA_Pixel:      keyed = true if img.channels == 1 && img.depth ==  8 else false
	case RGBA_Pixel:    keyed = true if img.channels == 3 && img.depth ==  8 else false
	case GA_Pixel_16:   keyed = true if img.channels == 1 && img.depth == 16 else false
	case RGBA_Pixel_16: keyed = true if img.channels == 3 && img.depth == 16 else false
	}

	// We should now have a valid Image with 1..4 channels. Do we have alpha?
	if img.channels == 1 || img.channels == 3 {
		if !(will_it_blend && keyed) {
			// We're done
			return true
		}
	}

	// # of destination channels
	channels := 1 if img.channels < 3 else 3

	bytes_wanted := compute_buffer_size(img.width, img.height, channels, img.depth)
	buf := bytes.Buffer{}

	// Can we allocate the return buffer?
	if resize(&buf.buf, bytes_wanted) != nil {
		delete(buf.buf)
		return false
	}

	switch img.depth {
	case 8:
		switch img.channels {
		case 1: // Gray to Gray, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]G_Pixel, img.pixels.buf[:])
			out := mem.slice_data_cast([]G_Pixel, buf.buf[:])

			key := alpha_key.(GA_Pixel).r
			bg  := G_Pixel{}
			if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
				// Background is RGB 16-bit, take just the red channel's topmost byte.
				bg.r = u8(temp_bg.r >> 8)
			}

			for p in inp {
				out[0] = bg if p.r == key else p
				out    = out[1:]
			}

		case 2: // Gray + Alpha to Gray, no keyed alpha but we can have a background.
			inp := mem.slice_data_cast([]GA_Pixel, img.pixels.buf[:])
			out := mem.slice_data_cast([]G_Pixel,  buf.buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg  := f32(0.0)
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, take just the red channel's topmost byte.
					bg = f32(temp_bg.r >> 8)
				}

				for p in inp {
					a := f32(p.g) / 255.0
					c := ((1.0 - a) * bg + a * f32(p.r))
					out[0].r = u8(c)
					out      = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a := f32(p.g) / 255.0
					c := f32(p.r) * a
					out[0].r = u8(c)
					out      = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0].r = p.r
					out      = out[1:]
				}
			}

		case 3: // RGB to RGB, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]RGB_Pixel, img.pixels.buf[:])
			out := mem.slice_data_cast([]RGB_Pixel, buf.buf[:])

			key := alpha_key.(RGBA_Pixel)
			bg  := RGB_Pixel{}
			if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
				// Background is RGB 16-bit, squash down to 8 bits.
				bg = {u8(temp_bg.r >> 8), u8(temp_bg.g >> 8), u8(temp_bg.b >> 8)}
			}

			for p in inp {
				out[0] = bg if p == key.rgb else p
				out    = out[1:]
			}

		case 4: // RGBA to RGB, no keyed alpha but we can have a background or need to premultiply.
			inp := mem.slice_data_cast([]RGBA_Pixel, img.pixels.buf[:])
			out := mem.slice_data_cast([]RGB_Pixel,  buf.buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg := [3]f32{}
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, take just the red channel's topmost byte.
					bg = {f32(temp_bg.r >> 8), f32(temp_bg.g >> 8), f32(temp_bg.b >> 8)}
				}

				for p in inp {
					a   := f32(p.a) / 255.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := ((1.0 - a) * bg + a * rgb)

					out[0] = {u8(c.r), u8(c.g), u8(c.b)}
					out    = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a   := f32(p.a) / 255.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := rgb * a

					out[0] = {u8(c.r), u8(c.g), u8(c.b)}
					out    = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0] = p.rgb
					out    = out[1:]
				}
			}
		}

	case 16:
		switch img.channels {
		case 1: // Gray to Gray, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]G_Pixel_16, img.pixels.buf[:])
			out := mem.slice_data_cast([]G_Pixel_16, buf.buf[:])

			key := alpha_key.(GA_Pixel_16).r
			bg  := G_Pixel_16{}
			if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
				// Background is RGB 16-bit, take just the red channel.
				bg.r = temp_bg.r
			}

			for p in inp {
				out[0] = bg if p.r == key else p
				out    = out[1:]
			}

		case 2: // Gray + Alpha to Gray, no keyed alpha but we can have a background.
			inp := mem.slice_data_cast([]GA_Pixel_16, img.pixels.buf[:])
			out := mem.slice_data_cast([]G_Pixel_16,  buf.buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg  := f32(0.0)
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, take just the red channel.
					bg = f32(temp_bg.r)
				}

				for p in inp {
					a := f32(p.g) / 65535.0
					c := ((1.0 - a) * bg + a * f32(p.r))
					out[0].r = u16(c)
					out      = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a := f32(p.g) / 65535.0
					c := f32(p.r) * a
					out[0].r = u16(c)
					out      = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0].r = p.r
					out      = out[1:]
				}
			}

		case 3: // RGB to RGB, but we should have keyed alpha + background.
			inp := mem.slice_data_cast([]RGB_Pixel_16, img.pixels.buf[:])
			out := mem.slice_data_cast([]RGB_Pixel_16, buf.buf[:])

			key := alpha_key.(RGBA_Pixel_16)
			bg  := img.background.(RGB_Pixel_16)

			for p in inp {
				out[0] = bg if p == key.rgb else p
				out    = out[1:]
			}

		case 4: // RGBA to RGB, no keyed alpha but we can have a background or need to premultiply.
			inp := mem.slice_data_cast([]RGBA_Pixel_16, img.pixels.buf[:])
			out := mem.slice_data_cast([]RGB_Pixel_16,  buf.buf[:])

			if will_it_blend {
				// Blend with background "color", then drop alpha.
				bg := [3]f32{}
				if temp_bg, temp_bg_ok := img.background.(RGB_Pixel_16); temp_bg_ok {
					// Background is RGB 16-bit, convert to [3]f32 to blend.
					bg = {f32(temp_bg.r), f32(temp_bg.g), f32(temp_bg.b)}
				}

				for p in inp {
					a   := f32(p.a) / 65535.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := ((1.0 - a) * bg + a * rgb)

					out[0] = {u16(c.r), u16(c.g), u16(c.b)}
					out    = out[1:]
				}

			} else if .alpha_premultiply in options {
				// Premultiply component with alpha, then drop alpha.
				for p in inp {
					a   := f32(p.a) / 65535.0
					rgb := [3]f32{f32(p.r), f32(p.g), f32(p.b)}
					c   := rgb * a

					out[0] = {u16(c.r), u16(c.g), u16(c.b)}
					out    = out[1:]
				}
			} else {
				// Just drop alpha on the floor.
				for p in inp {
					out[0] = p.rgb
					out    = out[1:]
				}
			}
		}

	case:
		unreachable()
	}

	// If we got here, that means we've now got a buffer with the alpha channel dropped.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	bytes.buffer_destroy(&img.pixels)
	img.pixels   = buf
	img.channels = channels
	return true
}

// Apply palette to 8-bit single-channel image and return an 8-bit RGB image, in-place.
// If the image given is not a valid 8-bit single channel image, the procedure will return `false` early.
apply_palette_rgb :: proc(img: ^Image, palette: [256]RGB_Pixel, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if img == nil || img.channels != 1 || img.depth != 8 {
		return false
	}

	bytes_expected := compute_buffer_size(img.width, img.height, 1, 8)
	if bytes_expected == 0 || bytes_expected != len(img.pixels.buf) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	// Can we allocate the return buffer?
	buf := bytes.Buffer{}
	bytes_wanted := compute_buffer_size(img.width, img.height, 3, 8)
	if resize(&buf.buf, bytes_wanted) != nil {
		delete(buf.buf)
		return false
	}

	out := mem.slice_data_cast([]RGB_Pixel, buf.buf[:])

	// Apply the palette
	for p, i in img.pixels.buf {
		out[i] = palette[p]
	}

	// If we got here, that means we've now got a buffer with the alpha channel dropped.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	bytes.buffer_destroy(&img.pixels)
	img.pixels   = buf
	img.channels = 3
	return true
}

// Apply palette to 8-bit single-channel image and return an 8-bit RGBA image, in-place.
// If the image given is not a valid 8-bit single channel image, the procedure will return `false` early.
apply_palette_rgba :: proc(img: ^Image, palette: [256]RGBA_Pixel, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if img == nil || img.channels != 1 || img.depth != 8 {
		return false
	}

	bytes_expected := compute_buffer_size(img.width, img.height, 1, 8)
	if bytes_expected == 0 || bytes_expected != len(img.pixels.buf) || img.width * img.height > MAX_DIMENSIONS {
		return false
	}

	// Can we allocate the return buffer?
	buf := bytes.Buffer{}
	bytes_wanted := compute_buffer_size(img.width, img.height, 4, 8)
	if resize(&buf.buf, bytes_wanted) != nil {
		delete(buf.buf)
		return false
	}

	out := mem.slice_data_cast([]RGBA_Pixel, buf.buf[:])

	// Apply the palette
	for p, i in img.pixels.buf {
		out[i] = palette[p]
	}

	// If we got here, that means we've now got a buffer with the alpha channel dropped.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	bytes.buffer_destroy(&img.pixels)
	img.pixels   = buf
	img.channels = 4
	return true
}
apply_palette :: proc{apply_palette_rgb, apply_palette_rgba}

blend_single_channel :: #force_inline proc(fg, alpha, bg: $T) -> (res: T) where T == u8 || T == u16 {
	MAX :: 256 when T == u8 else 65536

	c := u32(fg) * (MAX - u32(alpha)) + u32(bg) * (1 + u32(alpha))
	return T(c & (MAX - 1))
}

blend_pixel :: #force_inline proc(fg: [$N]$T, alpha: T, bg: [N]T) -> (res: [N]T) where (T == u8 || T == u16), N >= 1, N <= 4 {
	MAX :: 256 when T == u8 else 65536

	when N == 1 {
		r := u32(fg.r) * (MAX - u32(alpha)) + u32(bg.r) * (1 + u32(alpha))
		return {T(r & (MAX - 1))}
	}
	when N == 2 {
		r := u32(fg.r) * (MAX - u32(alpha)) + u32(bg.r) * (1 + u32(alpha))
		g := u32(fg.g) * (MAX - u32(alpha)) + u32(bg.g) * (1 + u32(alpha))
		return {T(r & (MAX - 1)), T(g & (MAX - 1))}
	}
	when N == 3 || N == 4 {
		r := u32(fg.r) * (MAX - u32(alpha)) + u32(bg.r) * (1 + u32(alpha))
		g := u32(fg.g) * (MAX - u32(alpha)) + u32(bg.g) * (1 + u32(alpha))
		b := u32(fg.b) * (MAX - u32(alpha)) + u32(bg.b) * (1 + u32(alpha))

		when N == 3 {
			return {T(r & (MAX - 1)), T(g & (MAX - 1)), T(b & (MAX - 1))}
		} else {
			return {T(r & (MAX - 1)), T(g & (MAX - 1)), T(b & (MAX - 1)), MAX - 1}
		}
	}
	unreachable()
}
blend :: proc{blend_single_channel, blend_pixel}

// For all pixels of the image, multiplies R, G and B by Alpha. This is useful mainly for games rendering anti-aliased transparent sprites.
// Grayscale with alpha images are supported as well.
// Note that some image formats like QOI explicitly do NOT support premultiplied alpha, so you will end up with a non-standard file.
premultiply_alpha :: proc(img: ^Image) -> (ok: bool) {
	switch {
	case img.channels == 2 && img.depth == 8:
		pixels := mem.slice_data_cast([]GA_Pixel, img.pixels.buf[:])
		for &pixel in pixels {
			pixel.r = u8(u32(pixel.r) * u32(pixel.g) / 0xFF)
		}
		return true
	case img.channels == 2 && img.depth == 16:
		pixels := mem.slice_data_cast([]GA_Pixel_16, img.pixels.buf[:])
		for &pixel in pixels {
			pixel.r = u16(u32(pixel.r) * u32(pixel.g) / 0xFFFF)
		}
		return true
	case img.channels == 4 && img.depth == 8:
		pixels := mem.slice_data_cast([]RGBA_Pixel, img.pixels.buf[:])
		for &pixel in pixels {
			pixel.r = u8(u32(pixel.r) * u32(pixel.a) / 0xFF)
			pixel.g = u8(u32(pixel.g) * u32(pixel.a) / 0xFF)
			pixel.b = u8(u32(pixel.b) * u32(pixel.a) / 0xFF)
		}
		return true
	case img.channels == 4 && img.depth == 16:
		pixels := mem.slice_data_cast([]RGBA_Pixel_16, img.pixels.buf[:])
		for &pixel in pixels {
			pixel.r = u16(u32(pixel.r) * u32(pixel.a) / 0xFFFF)
			pixel.g = u16(u32(pixel.g) * u32(pixel.a) / 0xFFFF)
			pixel.b = u16(u32(pixel.b) * u32(pixel.a) / 0xFFFF)
		}
		return true
	case: return false
	}
}

// Replicates grayscale values into RGB(A) 8- or 16-bit images as appropriate.
// Returns early with `false` if already an RGB(A) image.
expand_grayscale :: proc(img: ^Image, allocator := context.allocator) -> (ok: bool) {
	context.allocator = allocator

	if !is_valid_grayscale_image(img) {
		return false
	}

	// We should have 1 or 2 channels of 8- or 16 bits now. We need to turn that into 3 or 4.
	// Can we allocate the return buffer?
	buf := bytes.Buffer{}
	bytes_wanted := compute_buffer_size(img.width, img.height, img.channels + 2, img.depth)
	if resize(&buf.buf, bytes_wanted) != nil {
		delete(buf.buf)
		return false
	}

	switch img.depth {
	case 8:
		switch img.channels {
		case 1: // Turn Gray into RGB
			out := mem.slice_data_cast([]RGB_Pixel, buf.buf[:])

			for p in img.pixels.buf {
				out[0] = p // Broadcast gray value into RGB components.
				out    = out[1:]
			}

		case 2: // Turn Gray + Alpha into RGBA
			inp := mem.slice_data_cast([]GA_Pixel,   img.pixels.buf[:])
			out := mem.slice_data_cast([]RGBA_Pixel, buf.buf[:])

			for p in inp {
				out[0].rgb = p.r // Gray component.
				out[0].a   = p.g // Alpha component.
				out    = out[1:]
			}

		case:
			unreachable()
		}

	case 16:
		switch img.channels {
		case 1: // Turn Gray into RGB
			inp := mem.slice_data_cast([]u16, img.pixels.buf[:])
			out := mem.slice_data_cast([]RGB_Pixel_16, buf.buf[:])

			for p in inp {
				out[0] = p // Broadcast gray value into RGB components.
				out    = out[1:]
			}

		case 2: // Turn Gray + Alpha into RGBA
			inp := mem.slice_data_cast([]GA_Pixel_16,   img.pixels.buf[:])
			out := mem.slice_data_cast([]RGBA_Pixel_16, buf.buf[:])

			for p in inp {
				out[0].rgb = p.r // Gray component.
				out[0].a   = p.g // Alpha component.
				out    = out[1:]
			}

		case:
			unreachable()
		}

	case:
		unreachable()
	}


	// If we got here, that means we've now got a buffer with the extra alpha channel.
	// Destroy the old pixel buffer and replace it with the new one, and update the channel count.
	bytes.buffer_destroy(&img.pixels)
	img.pixels   = buf
	img.channels += 2
	return true
}

/*
	Helper functions to read and write data from/to a Context, etc.
*/
@(optimization_mode="favor_size")
read_data :: proc(z: $C, $T: typeid) -> (res: T, err: compress.General_Error) {
	if r, e := compress.read_data(z, T); e != .None {
		return {}, .Stream_Too_Short
	} else {
		return r, nil
	}
}

@(optimization_mode="favor_size")
read_u8 :: proc(z: $C) -> (res: u8, err: compress.General_Error) {
	if r, e := compress.read_u8(z); e != .None {
		return {}, .Stream_Too_Short
	} else {
		return r, nil
	}
}

write_bytes :: proc(buf: ^bytes.Buffer, data: []u8) -> (err: compress.General_Error) {
	if len(data) == 0 {
		return nil
	} else if len(data) == 1 {
		if bytes.buffer_write_byte(buf, data[0]) != nil {
			return .Resize_Failed
		}
	} else if n, _ := bytes.buffer_write(buf, data); n != len(data) {
		return .Resize_Failed
	}
	return nil
}
