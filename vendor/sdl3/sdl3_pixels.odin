package sdl3

import "core:c"

ALPHA_OPAQUE            :: 255
ALPHA_OPAQUE_FLOAT      :: 1.0
ALPHA_TRANSPARENT       :: 0
ALPHA_TRANSPARENT_FLOAT :: 0.0

PixelType :: enum c.int {
	UNKNOWN,
	INDEX1,
	INDEX4,
	INDEX8,
	PACKED8,
	PACKED16,
	PACKED32,
	ARRAYU8,
	ARRAYU16,
	ARRAYU32,
	ARRAYF16,
	ARRAYF32,
	/* appended at the end for compatibility with sdl2-compat:  */
	INDEX2,
}

BitmapOrder :: enum c.int {
	NONE,
	ORDER_4321,
	ORDER_1234,
}

PackedOrder :: enum c.int {
	NONE,
	XRGB,
	RGBX,
	ARGB,
	RGBA,
	XBGR,
	BGRX,
	ABGR,
	BGRA,
}

ArrayOrder :: enum c.int {
	NONE,
	RGB,
	RGBA,
	ARGB,
	BGR,
	BGRA,
	ABGR,
}

PackedLayout :: enum c.int {
	NONE,
	LAYOUT_332,
	LAYOUT_4444,
	LAYOUT_1555,
	LAYOUT_5551,
	LAYOUT_565,
	LAYOUT_8888,
	LAYOUT_2101010,
	LAYOUT_1010102,
}

@(require_results)
DEFINE_PIXELFOURCC :: #force_inline proc "c" (#any_int A, B, C, D: u8) -> Uint32 {
	return FOURCC(A, B, C, D)
}


@(require_results)
DEFINE_PIXELFORMAT :: #force_inline proc "c" (type: PixelType, order: PackedOrder, layout: PackedLayout, bits: Uint32, bytes: Uint32) -> PixelFormat {
	return PixelFormat(((1 << 28) | (Uint32(type) << 24) | (Uint32(order) << 20) | (Uint32(layout) << 16) | (Uint32(bits) << 8) | (Uint32(bytes) << 0)))
}

@(require_results) PIXELFLAG   :: proc "c" (format: PixelFormat) -> Uint32         { return ((Uint32(format) >> 28) & 0x0F) }
@(require_results) PIXELTYPE   :: proc "c" (format: PixelFormat) -> PixelType      { return PixelType((Uint32(format) >> 24) & 0x0F) }
@(require_results) PIXELORDER  :: proc "c" (format: PixelFormat) -> PackedOrder    { return PackedOrder((Uint32(format) >> 20) & 0x0F) }
@(require_results) PIXELLAYOUT :: proc "c" (format: PixelFormat) -> PackedLayout   { return PackedLayout((Uint32(format) >> 16) & 0x0F) }
@(require_results) PIXELARRAYORDER :: proc "c" (format: PixelFormat) -> ArrayOrder { return ArrayOrder((Uint32(format) >> 20) & 0x0F) }


@(require_results)
BITSPERPIXEL :: proc "c" (format: PixelFormat) -> Uint32 {
	return ISPIXELFORMAT_FOURCC(format) ? 0 : ((Uint32(format) >> 8) & 0xFF)
}

@(require_results)
ISPIXELFORMAT_INDEXED :: proc "c" (format: PixelFormat) -> bool {
	return (!ISPIXELFORMAT_FOURCC(format) &&
	        ((PIXELTYPE(format) == .INDEX1) ||
	         (PIXELTYPE(format) == .INDEX2) ||
	         (PIXELTYPE(format) == .INDEX4) ||
	         (PIXELTYPE(format) == .INDEX8)))
}


@(require_results)
ISPIXELFORMAT_PACKED :: proc "c" (format: PixelFormat) -> bool {
	return (!ISPIXELFORMAT_FOURCC(format) &&
	        ((PIXELTYPE(format) == .PACKED8) ||
	         (PIXELTYPE(format) == .PACKED16) ||
	         (PIXELTYPE(format) == .PACKED32)))
}

@(require_results)
ISPIXELFORMAT_ARRAY :: proc "c" (format: PixelFormat) -> bool {
	return (!ISPIXELFORMAT_FOURCC(format) &&
	        ((PIXELTYPE(format) == .ARRAYU8) ||
	         (PIXELTYPE(format) == .ARRAYU16) ||
	         (PIXELTYPE(format) == .ARRAYU32) ||
	         (PIXELTYPE(format) == .ARRAYF16) ||
	         (PIXELTYPE(format) == .ARRAYF32)))
}

@(require_results)
ISPIXELFORMAT_10BIT :: proc "c" (format: PixelFormat) -> bool {
	return (!ISPIXELFORMAT_FOURCC(format) &&
	        ((PIXELTYPE(format) == .PACKED32) &&
	         (PIXELLAYOUT(format) == .LAYOUT_2101010)))
}

@(require_results)
ISPIXELFORMAT_FLOAT :: proc "c" (format: PixelFormat) -> bool {
	return (!ISPIXELFORMAT_FOURCC(format) &&
	        ((PIXELTYPE(format) == .ARRAYF16) ||
	         (PIXELTYPE(format) == .ARRAYF32)))
}

@(require_results)
ISPIXELFORMAT_ALPHA :: proc "c" (format: PixelFormat) -> bool {
	return ((ISPIXELFORMAT_PACKED(format) &&
	         ((PIXELORDER(format) == .ARGB) ||
	          (PIXELORDER(format) == .RGBA) ||
	          (PIXELORDER(format) == .ABGR) ||
	          (PIXELORDER(format) == .BGRA))) ||
	(ISPIXELFORMAT_ARRAY(format) &&
	 ((PIXELARRAYORDER(format) == .ARGB) ||
	  (PIXELARRAYORDER(format) == .RGBA) ||
	  (PIXELARRAYORDER(format) == .ABGR) ||
	  (PIXELARRAYORDER(format) == .BGRA))))
}

@(require_results)
ISPIXELFORMAT_FOURCC :: proc "c" (format: PixelFormat) -> bool {
	return format != nil && PIXELFLAG(format) != 1
}

PixelFormat :: enum c.int {
	UNKNOWN = 0,
	INDEX1LSB = 0x11100100,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX1, SDL_BITMAPORDER_4321, 0, 1, 0), */
	INDEX1MSB = 0x11200100,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX1, SDL_BITMAPORDER_1234, 0, 1, 0), */
	INDEX2LSB = 0x1c100200,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX2, SDL_BITMAPORDER_4321, 0, 2, 0), */
	INDEX2MSB = 0x1c200200,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX2, SDL_BITMAPORDER_1234, 0, 2, 0), */
	INDEX4LSB = 0x12100400,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX4, SDL_BITMAPORDER_4321, 0, 4, 0), */
	INDEX4MSB = 0x12200400,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX4, SDL_BITMAPORDER_1234, 0, 4, 0), */
	INDEX8 = 0x13000801,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_INDEX8, 0, 0, 8, 1), */
	RGB332 = 0x14110801,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED8, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_332, 8, 1), */
	XRGB4444 = 0x15120c02,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_4444, 12, 2), */
	XBGR4444 = 0x15520c02,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_4444, 12, 2), */
	XRGB1555 = 0x15130f02,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_1555, 15, 2), */
	XBGR1555 = 0x15530f02,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_1555, 15, 2), */
	ARGB4444 = 0x15321002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_ARGB, SDL_PACKEDLAYOUT_4444, 16, 2), */
	RGBA4444 = 0x15421002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_RGBA, SDL_PACKEDLAYOUT_4444, 16, 2), */
	ABGR4444 = 0x15721002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_ABGR, SDL_PACKEDLAYOUT_4444, 16, 2), */
	BGRA4444 = 0x15821002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_BGRA, SDL_PACKEDLAYOUT_4444, 16, 2), */
	ARGB1555 = 0x15331002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_ARGB, SDL_PACKEDLAYOUT_1555, 16, 2), */
	RGBA5551 = 0x15441002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_RGBA, SDL_PACKEDLAYOUT_5551, 16, 2), */
	ABGR1555 = 0x15731002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_ABGR, SDL_PACKEDLAYOUT_1555, 16, 2), */
	BGRA5551 = 0x15841002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_BGRA, SDL_PACKEDLAYOUT_5551, 16, 2), */
	RGB565 = 0x15151002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_565, 16, 2), */
	BGR565 = 0x15551002,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED16, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_565, 16, 2), */
	RGB24 = 0x17101803,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU8, SDL_ARRAYORDER_RGB, 0, 24, 3), */
	BGR24 = 0x17401803,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU8, SDL_ARRAYORDER_BGR, 0, 24, 3), */
	XRGB8888 = 0x16161804,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_8888, 24, 4), */
	RGBX8888 = 0x16261804,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_RGBX, SDL_PACKEDLAYOUT_8888, 24, 4), */
	XBGR8888 = 0x16561804,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_8888, 24, 4), */
	BGRX8888 = 0x16661804,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_BGRX, SDL_PACKEDLAYOUT_8888, 24, 4), */
	ARGB8888 = 0x16362004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ARGB, SDL_PACKEDLAYOUT_8888, 32, 4), */
	RGBA8888 = 0x16462004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_RGBA, SDL_PACKEDLAYOUT_8888, 32, 4), */
	ABGR8888 = 0x16762004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ABGR, SDL_PACKEDLAYOUT_8888, 32, 4), */
	BGRA8888 = 0x16862004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_BGRA, SDL_PACKEDLAYOUT_8888, 32, 4), */
	XRGB2101010 = 0x16172004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XRGB, SDL_PACKEDLAYOUT_2101010, 32, 4), */
	XBGR2101010 = 0x16572004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_XBGR, SDL_PACKEDLAYOUT_2101010, 32, 4), */
	ARGB2101010 = 0x16372004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ARGB, SDL_PACKEDLAYOUT_2101010, 32, 4), */
	ABGR2101010 = 0x16772004,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_PACKED32, SDL_PACKEDORDER_ABGR, SDL_PACKEDLAYOUT_2101010, 32, 4), */
	RGB48 = 0x18103006,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU16, SDL_ARRAYORDER_RGB, 0, 48, 6), */
	BGR48 = 0x18403006,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU16, SDL_ARRAYORDER_BGR, 0, 48, 6), */
	RGBA64 = 0x18204008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU16, SDL_ARRAYORDER_RGBA, 0, 64, 8), */
	ARGB64 = 0x18304008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU16, SDL_ARRAYORDER_ARGB, 0, 64, 8), */
	BGRA64 = 0x18504008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU16, SDL_ARRAYORDER_BGRA, 0, 64, 8), */
	ABGR64 = 0x18604008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYU16, SDL_ARRAYORDER_ABGR, 0, 64, 8), */
	RGB48_FLOAT = 0x1a103006,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF16, SDL_ARRAYORDER_RGB, 0, 48, 6), */
	BGR48_FLOAT = 0x1a403006,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF16, SDL_ARRAYORDER_BGR, 0, 48, 6), */
	RGBA64_FLOAT = 0x1a204008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF16, SDL_ARRAYORDER_RGBA, 0, 64, 8), */
	ARGB64_FLOAT = 0x1a304008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF16, SDL_ARRAYORDER_ARGB, 0, 64, 8), */
	BGRA64_FLOAT = 0x1a504008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF16, SDL_ARRAYORDER_BGRA, 0, 64, 8), */
	ABGR64_FLOAT = 0x1a604008,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF16, SDL_ARRAYORDER_ABGR, 0, 64, 8), */
	RGB96_FLOAT = 0x1b10600c,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF32, SDL_ARRAYORDER_RGB, 0, 96, 12), */
	BGR96_FLOAT = 0x1b40600c,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF32, SDL_ARRAYORDER_BGR, 0, 96, 12), */
	RGBA128_FLOAT = 0x1b208010,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF32, SDL_ARRAYORDER_RGBA, 0, 128, 16), */
	ARGB128_FLOAT = 0x1b308010,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF32, SDL_ARRAYORDER_ARGB, 0, 128, 16), */
	BGRA128_FLOAT = 0x1b508010,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF32, SDL_ARRAYORDER_BGRA, 0, 128, 16), */
	ABGR128_FLOAT = 0x1b608010,
        /* SDL_DEFINE_PIXELFORMAT(SDL_PIXELTYPE_ARRAYF32, SDL_ARRAYORDER_ABGR, 0, 128, 16), */

	YV12 = 0x32315659,      /**< Planar mode: Y + V + U  (3 planes) */
        /* SDL_DEFINE_PIXELFOURCC('Y', 'V', '1', '2'), */
	IYUV = 0x56555949,      /**< Planar mode: Y + U + V  (3 planes) */
        /* SDL_DEFINE_PIXELFOURCC('I', 'Y', 'U', 'V'), */
	YUY2 = 0x32595559,      /**< Packed mode: Y0+U0+Y1+V0 (1 plane) */
        /* SDL_DEFINE_PIXELFOURCC('Y', 'U', 'Y', '2'), */
	UYVY = 0x59565955,      /**< Packed mode: U0+Y0+V0+Y1 (1 plane) */
        /* SDL_DEFINE_PIXELFOURCC('U', 'Y', 'V', 'Y'), */
	YVYU = 0x55595659,      /**< Packed mode: Y0+V0+Y1+U0 (1 plane) */
        /* SDL_DEFINE_PIXELFOURCC('Y', 'V', 'Y', 'U'), */
	NV12 = 0x3231564e,      /**< Planar mode: Y + U/V interleaved  (2 planes) */
        /* SDL_DEFINE_PIXELFOURCC('N', 'V', '1', '2'), */
	NV21 = 0x3132564e,      /**< Planar mode: Y + V/U interleaved  (2 planes) */
        /* SDL_DEFINE_PIXELFOURCC('N', 'V', '2', '1'), */
	P010 = 0x30313050,      /**< Planar mode: Y + U/V interleaved  (2 planes) */
        /* SDL_DEFINE_PIXELFOURCC('P', '0', '1', '0'), */
	EXTERNAL_OES = 0x2053454f,     /**< Android video texture format */
        /* SDL_DEFINE_PIXELFOURCC('O', 'E', 'S', ' ') */

	/* Aliases for RGBA byte arrays of color data, for the current platform */
	RGBA32 = RGBA8888 when BYTEORDER == BIG_ENDIAN else ABGR8888,
	ARGB32 = ARGB8888 when BYTEORDER == BIG_ENDIAN else BGRA8888,
	BGRA32 = BGRA8888 when BYTEORDER == BIG_ENDIAN else ARGB8888,
	ABGR32 = ABGR8888 when BYTEORDER == BIG_ENDIAN else RGBA8888,
	RGBX32 = RGBX8888 when BYTEORDER == BIG_ENDIAN else XBGR8888,
	XRGB32 = XRGB8888 when BYTEORDER == BIG_ENDIAN else BGRX8888,
	BGRX32 = BGRX8888 when BYTEORDER == BIG_ENDIAN else XRGB8888,
	XBGR32 = XBGR8888 when BYTEORDER == BIG_ENDIAN else RGBX8888,
}

ColorType :: enum c.int {
	UNKNOWN = 0,
	RGB     = 1,
	YCBCR   = 2,
}

ColorRange :: enum c.int {
	UNKNOWN = 0,
	LIMITED = 1, /**< Narrow range, e.g. 16-235 for 8-bit RGB and luma, and 16-240 for 8-bit chroma */
	FULL    = 2, /**< Full range, e.g. 0-255 for 8-bit RGB and luma, and 1-255 for 8-bit chroma */
}

ColorPrimaries :: enum c.int {
	UNKNOWN      = 0,
	BT709        = 1,  /**< ITU-R BT.709-6 */
	UNSPECIFIED  = 2,
	BT470M       = 4,  /**< ITU-R BT.470-6 System M */
	BT470BG      = 5,  /**< ITU-R BT.470-6 System B, G / ITU-R BT.601-7 625 */
	BT601        = 6,  /**< ITU-R BT.601-7 525, SMPTE 170M */
	SMPTE240     = 7,  /**< SMPTE 240M, functionally the same as SDL_COLOR_PRIMARIES_BT601 */
	GENERIC_FILM = 8,  /**< Generic film (color filters using Illuminant C) */
	BT2020       = 9,  /**< ITU-R BT.2020-2 / ITU-R BT.2100-0 */
	XYZ          = 10, /**< SMPTE ST 428-1 */
	SMPTE431     = 11, /**< SMPTE RP 431-2 */
	SMPTE432     = 12, /**< SMPTE EG 432-1 / DCI P3 */
	EBU3213      = 22, /**< EBU Tech. 3213-E */
	CUSTOM       = 31,
}

TransferCharacteristics :: enum c.int {
	UNKNOWN       = 0,
	BT709         = 1,  /**< Rec. ITU-R BT.709-6 / ITU-R BT1361 */
	UNSPECIFIED   = 2,
	GAMMA22       = 4,  /**< ITU-R BT.470-6 System M / ITU-R BT1700 625 PAL & SECAM */
	GAMMA28       = 5,  /**< ITU-R BT.470-6 System B, G */
	BT601         = 6,  /**< SMPTE ST 170M / ITU-R BT.601-7 525 or 625 */
	SMPTE240      = 7,  /**< SMPTE ST 240M */
	LINEAR        = 8,
	LOG100        = 9,
	LOG100_SQRT10 = 10,
	IEC61966      = 11, /**< IEC 61966-2-4 */
	BT1361        = 12, /**< ITU-R BT1361 Extended Colour Gamut */
	SRGB          = 13, /**< IEC 61966-2-1 (sRGB or sYCC) */
	BT2020_10BIT  = 14, /**< ITU-R BT2020 for 10-bit system */
	BT2020_12BIT  = 15, /**< ITU-R BT2020 for 12-bit system */
	PQ            = 16, /**< SMPTE ST 2084 for 10-, 12-, 14- and 16-bit systems */
	SMPTE428      = 17, /**< SMPTE ST 428-1 */
	HLG           = 18, /**< ARIB STD-B67, known as "hybrid log-gamma" (HLG) */
	CUSTOM        = 31,
}

MatrixCoefficients :: enum c.int {
	IDENTITY           = 0,
	BT709              = 1,  /**< ITU-R BT.709-6 */
	UNSPECIFIED        = 2,
	FCC                = 4,  /**< US FCC Title 47 */
	BT470BG            = 5,  /**< ITU-R BT.470-6 System B, G / ITU-R BT.601-7 625, functionally the same as SDL_MATRIX_COEFFICIENTS_BT601 */
	BT601              = 6,  /**< ITU-R BT.601-7 525 */
	SMPTE240           = 7,  /**< SMPTE 240M */
	YCGCO              = 8,
	BT2020_NCL         = 9,  /**< ITU-R BT.2020-2 non-constant luminance */
	BT2020_CL          = 10, /**< ITU-R BT.2020-2 constant luminance */
	SMPTE2085          = 11, /**< SMPTE ST 2085 */
	CHROMA_DERIVED_NCL = 12,
	CHROMA_DERIVED_CL  = 13,
	ICTCP              = 14, /**< ITU-R BT.2100-0 ICTCP */
	CUSTOM             = 31,
}

ChromaLocation :: enum c.int {
	NONE    = 0, /**< RGB, no chroma sampling */
	LEFT    = 1, /**< In MPEG-2, MPEG-4, and AVC, Cb and Cr are taken on midpoint of the left-edge of the 2x2 square. In other words, they have the same horizontal location as the top-left pixel, but is shifted one-half pixel down vertically. */
	CENTER  = 2, /**< In JPEG/JFIF, H.261, and MPEG-1, Cb and Cr are taken at the center of the 2x2 square. In other words, they are offset one-half pixel to the right and one-half pixel down compared to the top-left pixel. */
	TOPLEFT = 3, /**< In HEVC for BT.2020 and BT.2100 content (in particular on Blu-rays), Cb and Cr are sampled at the same location as the group's top-left Y pixel ("co-sited", "co-located"). */
}


@(require_results)
DEFINE_COLORSPACE :: proc "c" (type: ColorType, range: ColorRange, primaries: ColorPrimaries, transfer: TransferCharacteristics, matrix_: MatrixCoefficients, chroma: ChromaLocation) -> Colorspace {
	return Colorspace((Uint32(type) << 28) | (Uint32(range) << 24) | (Uint32(chroma) << 20) |
	                  (Uint32(primaries) << 10) | (Uint32(transfer) << 5) | (Uint32(matrix_) << 0))
}

@(require_results)
COLORSPACETYPE :: proc "c" (cspace: Colorspace) -> ColorType {
	return ColorType((Uint32(cspace) >> 28) & 0x0F)
}

@(require_results)
COLORSPACERANGE :: proc "c" (cspace: Colorspace) -> ColorRange {
	return ColorRange((Uint32(cspace) >> 24) & 0x0F)
}

@(require_results)
COLORSPACECHROMA :: proc "c" (cspace: Colorspace) -> ChromaLocation {
	return ChromaLocation((Uint32(cspace) >> 20) & 0x0F)
}

@(require_results)
COLORSPACEPRIMARIES :: proc "c" (cspace: Colorspace) -> ColorPrimaries {
	return ColorPrimaries((Uint32(cspace) >> 10) & 0x1F)
}

@(require_results)
COLORSPACETRANSFER :: proc "c" (cspace: Colorspace) -> TransferCharacteristics {
	return TransferCharacteristics((Uint32(cspace) >> 5) & 0x1F)
}

@(require_results)
COLORSPACEMATRIX :: proc "c" (cspace: Colorspace) -> MatrixCoefficients {
	return MatrixCoefficients(Uint32(cspace) & 0x1F)
}

@(require_results)
ISCOLORSPACE_MATRIX_BT601 :: proc "c" (cspace: Colorspace) -> bool {
	return COLORSPACEMATRIX(cspace) == .BT601 || COLORSPACEMATRIX(cspace) == .BT470BG
}

@(require_results)
ISCOLORSPACE_MATRIX_BT709 :: proc "c" (cspace: Colorspace) -> bool {
	return COLORSPACEMATRIX(cspace) == .BT709
}

@(require_results)
ISCOLORSPACE_MATRIX_BT2020_NCL :: proc "c" (cspace: Colorspace) -> bool {
	return COLORSPACEMATRIX(cspace) == .BT2020_NCL
}

@(require_results)
ISCOLORSPACE_LIMITED_RANGE :: proc "c" (cspace: Colorspace) -> bool {
	return COLORSPACERANGE(cspace) != .FULL
}

@(require_results)
ISCOLORSPACE_FULL_RANGE :: proc "c" (cspace: Colorspace) -> bool {
	return COLORSPACERANGE(cspace) == .FULL
}



Colorspace :: enum c.int {
	UNKNOWN = 0,

	/* sRGB is a gamma corrected colorspace, and the default colorspace for SDL rendering and 8-bit RGB surfaces */
	SRGB = 0x120005a0, /**< Equivalent to DXGI_COLOR_SPACE_RGB_FULL_G22_NONE_P709 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_RGB,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT709,
	                         SDL_TRANSFER_CHARACTERISTICS_SRGB,
	                         SDL_MATRIX_COEFFICIENTS_IDENTITY,
	                         SDL_CHROMA_LOCATION_NONE), */

	/* This is a linear colorspace and the default colorspace for floating point surfaces. On Windows this is the scRGB colorspace, and on Apple platforms this is kCGColorSpaceExtendedLinearSRGB for EDR content */
	SRGB_LINEAR = 0x12000500, /**< Equivalent to DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709  */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_RGB,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT709,
	                         SDL_TRANSFER_CHARACTERISTICS_LINEAR,
	                         SDL_MATRIX_COEFFICIENTS_IDENTITY,
	                         SDL_CHROMA_LOCATION_NONE), */

	/* HDR10 is a non-linear HDR colorspace and the default colorspace for 10-bit surfaces */
	HDR10 = 0x12002600, /**< Equivalent to DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020  */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_RGB,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT2020,
	                         SDL_TRANSFER_CHARACTERISTICS_PQ,
	                         SDL_MATRIX_COEFFICIENTS_IDENTITY,
	                         SDL_CHROMA_LOCATION_NONE), */

	JPEG = 0x220004c6, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_FULL_G22_NONE_P709_X601 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT709,
	                         SDL_TRANSFER_CHARACTERISTICS_BT601,
	                         SDL_MATRIX_COEFFICIENTS_BT601,
	                         SDL_CHROMA_LOCATION_NONE), */

	BT601_LIMITED = 0x211018c6, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P601 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_LIMITED,
	                         SDL_COLOR_PRIMARIES_BT601,
	                         SDL_TRANSFER_CHARACTERISTICS_BT601,
	                         SDL_MATRIX_COEFFICIENTS_BT601,
	                         SDL_CHROMA_LOCATION_LEFT), */

	BT601_FULL = 0x221018c6, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P601 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT601,
	                         SDL_TRANSFER_CHARACTERISTICS_BT601,
	                         SDL_MATRIX_COEFFICIENTS_BT601,
	                         SDL_CHROMA_LOCATION_LEFT), */

	BT709_LIMITED = 0x21100421, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P709 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_LIMITED,
	                         SDL_COLOR_PRIMARIES_BT709,
	                         SDL_TRANSFER_CHARACTERISTICS_BT709,
	                         SDL_MATRIX_COEFFICIENTS_BT709,
	                         SDL_CHROMA_LOCATION_LEFT), */

	BT709_FULL = 0x22100421, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P709 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT709,
	                         SDL_TRANSFER_CHARACTERISTICS_BT709,
	                         SDL_MATRIX_COEFFICIENTS_BT709,
	                         SDL_CHROMA_LOCATION_LEFT), */

	BT2020_LIMITED = 0x21102609, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_STUDIO_G22_LEFT_P2020 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_LIMITED,
	                         SDL_COLOR_PRIMARIES_BT2020,
	                         SDL_TRANSFER_CHARACTERISTICS_PQ,
	                         SDL_MATRIX_COEFFICIENTS_BT2020_NCL,
	                         SDL_CHROMA_LOCATION_LEFT), */

	BT2020_FULL = 0x22102609, /**< Equivalent to DXGI_COLOR_SPACE_YCBCR_FULL_G22_LEFT_P2020 */
	/* SDL_DEFINE_COLORSPACE(SDL_COLOR_TYPE_YCBCR,
	                         SDL_COLOR_RANGE_FULL,
	                         SDL_COLOR_PRIMARIES_BT2020,
	                         SDL_TRANSFER_CHARACTERISTICS_PQ,
	                         SDL_MATRIX_COEFFICIENTS_BT2020_NCL,
	                         SDL_CHROMA_LOCATION_LEFT), */

	RGB_DEFAULT = SRGB, /**< The default colorspace for RGB surfaces if no colorspace is specified */
	YUV_DEFAULT = JPEG, /**< The default colorspace for YUV surfaces if no colorspace is specified */
}

Color  :: distinct [4]Uint8
FColor :: distinct [4]f32

Palette :: struct {
	ncolors:  c.int,                      /**< number of elements in `colors`. */
	colors:   [^]Color `fmt:"v,ncolors"`, /**< an array of colors, `ncolors` long. */
	version:  Uint32,                     /**< internal use only, do not touch. */
	refcount: c.int,                      /**< internal use only, do not touch. */
}

PixelFormatDetails :: struct {
	format:          PixelFormat,
	bits_per_pixel:  Uint8,
	bytes_per_pixel: Uint8,
	_:               [2]Uint8,
	Rmask:           Uint32,
	Gmask:           Uint32,
	Bmask:           Uint32,
	Amask:           Uint32,
	Rbits:           Uint8,
	Gbits:           Uint8,
	Bbits:           Uint8,
	Abits:           Uint8,
	Rshift:          Uint8,
	Gshift:          Uint8,
	Bshift:          Uint8,
	Ashift:          Uint8,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetPixelFormatName     :: proc(format: PixelFormat) -> rawptr ---
	GetMasksForPixelFormat :: proc(format: PixelFormat, bpp: ^c.int, Rmask, Gmask, Bmask, Amask: ^Uint32) -> bool ---
	GetPixelFormatForMasks :: proc(bpp: c.int, Rmask, Gmask, Bmask, Amask: Uint32) -> PixelFormat ---
	GetPixelFormatDetails  :: proc(format: PixelFormat) -> ^PixelFormatDetails ---
	CreatePalette          :: proc(ncolors: c.int) -> ^Palette ---
	SetPaletteColors       :: proc(palette: ^Palette, colors: [^]Color, firstcolor: c.int, ncolors: c.int) -> bool ---
	DestroyPalette         :: proc(palette: ^Palette) ---
	MapRGB                 :: proc(format: ^PixelFormatDetails, palette: ^Palette, r, g, b: Uint8) -> Uint32 ---
	MapRGBA                :: proc(format: ^PixelFormatDetails, palette: ^Palette, r, g, b, a: Uint8) -> Uint32 ---
	GetRGB                 :: proc(pixel: Uint32, format: ^PixelFormatDetails, palette: ^Palette, r, g, b: ^Uint8) ---
	GetRGBA                :: proc(pixel: Uint32, format: ^PixelFormatDetails, palette: ^Palette, r, g, b, a: ^Uint8) ---
}