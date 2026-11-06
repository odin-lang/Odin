package image

/*
	Copyright 2021-2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
		Ginger Bill:     Cosmetic changes.
*/

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
	pixels:        [dynamic]byte `fmt:"-"`,
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
	^BNG_Info,
	^Netpbm_Info,
	^PNG_Info,
	^QOI_Info,
	^TGA_Info,
	^BMP_Info,
	^JPEG_Info,
}

Exif :: struct {
	byte_order: enum {
		little_endian,
		big_endian,
	},
	data: []u8 `fmt:"-"`,
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
		This also applies to JPEG 12-bit images, in which case it returns
		samples in the range of 0..=4095, instead of expanding them to 0..=65535.

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
	do_not_expand_grayscale,       // Used in `jpeg`, `tga`, and `png`
	do_not_expand_indexed,         // Used in `png`
	do_not_expand_channels,        // Used in `jpeg` and `png`

	// SAVE OPTIONS
	qoi_all_channels_linear,       // QOI, informative only. If not set, defaults to sRGB with linear alpha.
}
Options :: distinct bit_set[Option]

Error :: union #shared_nil {
	General_Image_Error,
	BNG_Error,
	Netpbm_Error,
	PNG_Error,
	QOI_Error,
	BMP_Error,
	JPEG_Error,

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

BNG_Error :: enum {
	None = 0,
	Unsupported_Version,
	Body_Length_Exceeds_Input,
	Invalid_Raw_Body_Length,
	Invalid_Zero_Run,
	Body_Ends_Too_Early,
}

BNG_Magic :: [7]u8{0xFF, 0x0E, 0x38, 0x30, 0x2A, 0x1A, 0x18}

BNG_Version :: 0x01

BNG_Raw_Flag :: u32le(0x8000_0000)

BNG_Header :: struct #packed {
	magic:             [7]u8,
	version:           u8,
	width:             u32le,
	height:            u32le,
	stream_byte_count: u32le,
}
#assert(size_of(BNG_Header) == 20)

BNG_Info :: struct {
	header: BNG_Header,
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


/*
	JPEG-specific
*/
JFIF_Magic := [?]byte{0x4A, 0x46, 0x49, 0x46} // "JFIF"
JFXX_Magic := [?]byte{0x4A, 0x46, 0x58, 0x58} // "JFXX"
Exif_Magic := [?]byte{0x45, 0x78, 0x69, 0x66} // "Exif"

JPEG_Error :: enum {
	None = 0,
	Duplicate_SOI_Marker,
	Invalid_JFXX_Extension_Code,
	Encountered_SOS_Before_SOF,
	Invalid_Quantization_Table_Precision,
	Invalid_Quantization_Table_Index,
	Invalid_Huffman_Coefficient_Type,
	Invalid_Huffman_Table_Index,
	Unsupported_Frame_Type,
	Invalid_Frame_Bit_Depth_Combo,
	Invalid_Sampling_Factor,
	Unsupported_12_Bit_Depth,
	Multiple_SOS_Markers,
	Encountered_RST_Marker_Outside_ECS,
	Extra_Data_After_SOS, // Image seemed to have decoded okay, but there's more data after SOS
	Invalid_Thumbnail_Size,
	Huffman_Symbols_Exceeds_Max,
	Invalid_Huffman_Table,
	Missing_Huffman_Table,
	Missing_Quantization_Table,
	Invalid_Scan_Parameters,
	Invalid_Component,
	Missing_Image_Data,
	Missing_DNL_Marker,
	DNL_Requires_Seekable_Stream,
}

JFIF_Unit :: enum byte {
	None = 0,
	Dots_Per_Inch = 1,
	Dots_Per_Centimeter = 2,
}

JFIF_APP0 :: struct {
	version: u16be,
	x_density: u16be,
	y_density: u16be,
	units: JFIF_Unit,
	x_thumbnail: u8,
	y_thumbnail: u8,
	greyscale_thumbnail: bool,
	thumbnail: []byte `fmt:"-"`,
}

JFXX_APP0 :: struct {
	extension_code: JFXX_Extension_Code,
	x_thumbnail: u8,
	y_thumbnail: u8,
	thumbnail: []byte `fmt:"-"`,
}

JFXX_Extension_Code :: enum u8 {
	Thumbnail_JPEG = 0x10,
	Thumbnail_1_Byte_Palette = 0x11,
	Thumbnail_3_Byte_RGB = 0x13,
}

JPEG_Marker :: enum u8 {
	SOF0  = 0xC0, // Baseline sequential DCT
	SOF1  = 0xC1, // Extended sequential DCT
	SOF2  = 0xC2, // Progressive DCT
	SOF3  = 0xC3, // Lossless (sequential)
	SOF5  = 0xC5, // Differential sequential DCT
	SOF6  = 0xC6, // Differential progressive DCT
	SOF7  = 0xC7, // Differential lossless (sequential)
	SOF9  = 0xC9, // Extended sequential DCT, Arithmetic coding
	SOF10 = 0xCA, // Progressive DCT, Arithmetic coding
	SOF11 = 0xCB, // Lossless (sequential), Arithmetic coding
	SOF13 = 0xCD, // Differential sequential DCT, Arithmetic coding
	SOF14 = 0xCE, // Differential progressive DCT, Arithmetic coding
	SOF15 = 0xCF, // Differential lossless (sequential), Arithmetic coding

	DHT   = 0xC4,
	JPG   = 0xC8,
	DAC   = 0xCC,
	RST0  = 0xD0,
	RST1  = 0xD1,
	RST2  = 0xD2,
	RST3  = 0xD3,
	RST4  = 0xD4,
	RST5  = 0xD5,
	RST6  = 0xD6,
	RST7  = 0xD7,
	SOI   = 0xD8,
	EOI   = 0xD9,
	SOS   = 0xDA,
	DQT   = 0xDB,
	DNL   = 0xDC,
	DRI   = 0xDD,
	DHP   = 0xDE,
	EXP   = 0xDF,
	APP0  = 0xE0,
	APP1  = 0xE1,
	APP2  = 0xE2,
	APP3  = 0xE3,
	APP4  = 0xE4,
	APP5  = 0xE5,
	APP6  = 0xE6,
	APP7  = 0xE7,
	APP8  = 0xE8,
	APP9  = 0xE9,
	APP10 = 0xEA,
	APP11 = 0xEB,
	APP12 = 0xEC,
	APP13 = 0xED,
	APP14 = 0xEE,
	APP15 = 0xEF,
	JPG0  = 0xF0,
	JPG1  = 0xF1,
	JPG2  = 0xF2,
	JPG3  = 0xF3,
	JPG4  = 0xF4,
	JPG5  = 0xF5,
	JPG6  = 0xF6,
	JPG7  = 0xF7,
	JPG8  = 0xF8,
	JPG9  = 0xF9,
	JPG10 = 0xFA,
	JPG11 = 0xFB,
	JPG12 = 0xFC,
	JPG13 = 0xFD,
	COM   = 0xFE,
	TEM   = 0x01,
}

JPEG_Info :: struct {
	jfif_app0: Maybe(JFIF_APP0),
	jfxx_app0: Maybe(JFXX_APP0),
	comments: [dynamic]string,
	exif: [dynamic]Exif,
	frame_type: JPEG_Marker,
	color_space: JPEG_Color_Space,
}

JPEG_Color_Space :: enum u8 {
	Gray,
	Gray_Alpha,
	YCbCr,
	RGB,
	CMYK,
	YCCK,
}

JPEG_Subsampling :: enum u8 {
	S444,
	S422,
	S420,
}

// NOTE(Jeroen): Support for saving images using the hierarchical profile was left out on purpose.
//               Our JPEG loader decodes it, but the profile is only of historical interest as
//               far as creating them is.
JPEG_Profile :: enum u8 {
	Baseline,
	Extended,
	Progressive,
	Lossless,
}

JPEG_Entropy_Coding :: enum u8 {
	Huffman,
	Huffman_Optimized,
	Arithmetic,
}

JPEG_Lossless_Predictor :: enum u8 {
	Left,
	Above,
	Above_Left,
	Planar,
	Left_Planar,
	Above_Planar,
	Average,
	Best,
}

JPEG_Save_Options :: struct {
	entropy_coding:        JPEG_Entropy_Coding,
	lossless_predictor:    JPEG_Lossless_Predictor,
	restart_interval_rows: u16,
	color_space:           Maybe(JPEG_Color_Space),
}

Channel :: enum u8 {
	R = 1,
	G = 2,
	B = 3,
	A = 4,
}

Alpha_Key :: union {
	GA_Pixel,
	RGBA_Pixel,
	GA_Pixel_16,
	RGBA_Pixel_16,
}
