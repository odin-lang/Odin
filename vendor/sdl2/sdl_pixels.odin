package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

ALPHA_OPAQUE      :: 255
ALPHA_TRANSPARENT ::   0

PIXELTYPE_UNKNOWN  ::  0
PIXELTYPE_INDEX1   ::  1
PIXELTYPE_INDEX4   ::  2
PIXELTYPE_INDEX8   ::  3
PIXELTYPE_PACKED8  ::  4
PIXELTYPE_PACKED16 ::  5
PIXELTYPE_PACKED32 ::  6
PIXELTYPE_ARRAYU8  ::  7
PIXELTYPE_ARRAYU16 ::  8
PIXELTYPE_ARRAYU32 ::  9
PIXELTYPE_ARRAYF16 :: 10
PIXELTYPE_ARRAYF32 :: 11

BITMAPORDER_NONE :: 0
BITMAPORDER_4321 :: 1
BITMAPORDER_1234 :: 2

PACKEDORDER_NONE :: 0
PACKEDORDER_XRGB :: 1
PACKEDORDER_RGBX :: 2
PACKEDORDER_ARGB :: 3
PACKEDORDER_RGBA :: 4
PACKEDORDER_XBGR :: 5
PACKEDORDER_BGRX :: 6
PACKEDORDER_ABGR :: 7
PACKEDORDER_BGRA :: 8

/** Array component order, low byte -> high byte. */
/* !!! FIXME: in 2.1, make these not overlap differently with
   !!! FIXME:  SDL_PACKEDORDER_*, so we can simplify SDL_ISPIXELFORMAT_ALPHA */
ARRAYORDER_NONE :: 0
ARRAYORDER_RGB  :: 1
ARRAYORDER_RGBA :: 2
ARRAYORDER_ARGB :: 3
ARRAYORDER_BGR  :: 4
ARRAYORDER_BGRA :: 5
ARRAYORDER_ABGR :: 6

PACKEDLAYOUT_NONE    :: 0
PACKEDLAYOUT_332     :: 1
PACKEDLAYOUT_4444    :: 2
PACKEDLAYOUT_1555    :: 3
PACKEDLAYOUT_5551    :: 4
PACKEDLAYOUT_565     :: 5
PACKEDLAYOUT_8888    :: 6
PACKEDLAYOUT_2101010 :: 7
PACKEDLAYOUT_101010  :: 8



DEFINE_PIXELFOURCC :: FOURCC

DEFINE_PIXELFORMAT :: #force_inline proc "c" (type: u8, order: u8, layout, bits, bytes: u8) -> u32 {
	return (1 << 28) | (u32(type) << 24) | (u32(order) << 20) | (u32(layout) << 16) | (u32(bits) << 8) | (u32(bytes) << 0)
}


// #define SDL_PIXELFLAG(X)    (((X) >> 28) & 0x0F)
// #define SDL_PIXELTYPE(X)    (((X) >> 24) & 0x0F)
// #define SDL_PIXELORDER(X)   (((X) >> 20) & 0x0F)
// #define SDL_PIXELLAYOUT(X)  (((X) >> 16) & 0x0F)
// #define SDL_BITSPERPIXEL(X) (((X) >> 8) & 0xFF)
// #define SDL_BYTESPERPIXEL(X) \
//     (SDL_ISPIXELFORMAT_FOURCC(X) ? \
//         ((((X) == SDL_PIXELFORMAT_YUY2) || \
//           ((X) == SDL_PIXELFORMAT_UYVY) || \
//           ((X) == SDL_PIXELFORMAT_YVYU)) ? 2 : 1) : (((X) >> 0) & 0xFF))

// #define SDL_ISPIXELFORMAT_INDEXED(format)   \
//     (!SDL_ISPIXELFORMAT_FOURCC(format) && \
//      ((SDL_PIXELTYPE(format) == PIXELTYPE_INDEX1) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_INDEX4) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_INDEX8)))

// #define SDL_ISPIXELFORMAT_PACKED(format) \
//     (!SDL_ISPIXELFORMAT_FOURCC(format) && \
//      ((SDL_PIXELTYPE(format) == PIXELTYPE_PACKED8) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_PACKED16) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_PACKED32)))

// #define SDL_ISPIXELFORMAT_ARRAY(format) \
//     (!SDL_ISPIXELFORMAT_FOURCC(format) && \
//      ((SDL_PIXELTYPE(format) == PIXELTYPE_ARRAYU8) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_ARRAYU16) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_ARRAYU32) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_ARRAYF16) || \
//       (SDL_PIXELTYPE(format) == PIXELTYPE_ARRAYF32)))

// #define SDL_ISPIXELFORMAT_ALPHA(format)   \
//     ((SDL_ISPIXELFORMAT_PACKED(format) && \
//      ((SDL_PIXELORDER(format) == SDL_PACKEDORDER_ARGB) || \
//       (SDL_PIXELORDER(format) == SDL_PACKEDORDER_RGBA) || \
//       (SDL_PIXELORDER(format) == SDL_PACKEDORDER_ABGR) || \
//       (SDL_PIXELORDER(format) == SDL_PACKEDORDER_BGRA))) || \
//     (SDL_ISPIXELFORMAT_ARRAY(format) && \
//      ((SDL_PIXELORDER(format) == SDL_ARRAYORDER_ARGB) || \
//       (SDL_PIXELORDER(format) == SDL_ARRAYORDER_RGBA) || \
//       (SDL_PIXELORDER(format) == SDL_ARRAYORDER_ABGR) || \
//       (SDL_PIXELORDER(format) == SDL_ARRAYORDER_BGRA))))

// /* The flag is set to 1 because 0x1? is not in the printable ASCII range */
// #define SDL_ISPIXELFORMAT_FOURCC(format)    \
//     ((format) && (SDL_PIXELFLAG(format) != 1))


PixelFormatEnum :: enum u32 {
	UNKNOWN = 0,
	INDEX1LSB   = 1<<28 | PIXELTYPE_INDEX1<<24   | BITMAPORDER_4321<<20 | 0<<16 | 1<<8 | 0<<0,
	INDEX1MSB   = 1<<28 | PIXELTYPE_INDEX1<<24   | BITMAPORDER_1234<<20 | 0<<16 | 1<<8 | 0<<0,
	INDEX4LSB   = 1<<28 | PIXELTYPE_INDEX4<<24   | BITMAPORDER_4321<<20 | 0<<16 | 4<<8 | 0<<0,
	INDEX4MSB   = 1<<28 | PIXELTYPE_INDEX4<<24   | BITMAPORDER_1234<<20 | 0<<16 | 4<<8 | 0<<0,
	INDEX8      = 1<<28 | PIXELTYPE_INDEX8<<24   | 0<<20                | 0<<16 | 8<<8 | 1<<0,
	RGB332      = 1<<28 | PIXELTYPE_PACKED8<<24  | PACKEDORDER_XRGB<<20 | PACKEDLAYOUT_332<<16  | 8<<8  | 1<<0,
	XRGB4444    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_XRGB<<20 | PACKEDLAYOUT_4444<<16 | 12<<8 | 2<<0,
	RGB444      = XRGB4444,
	XBGR4444    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_XBGR<<20 | PACKEDLAYOUT_4444<<16 | 12<<8 | 2<<0,
	BGR444      = XBGR4444,
	XRGB1555    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_XRGB<<20 | PACKEDLAYOUT_1555<<16 | 15<<8 | 2<<0,
	RGB555      = XRGB1555,
	XBGR1555    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_XBGR<<20 | PACKEDLAYOUT_1555<<16 | 15<<8 | 2<<0,
	BGR555      = XBGR1555,
	ARGB4444    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_ARGB<<20 | PACKEDLAYOUT_4444<<16 | 16<<8 | 2<<0,
	RGBA4444    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_RGBA<<20 | PACKEDLAYOUT_4444<<16 | 16<<8 | 2<<0,
	ABGR4444    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_ABGR<<20 | PACKEDLAYOUT_4444<<16 | 16<<8 | 2<<0,
	BGRA4444    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_BGRA<<20 | PACKEDLAYOUT_4444<<16 | 16<<8 | 2<<0,
	ARGB1555    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_ARGB<<20 | PACKEDLAYOUT_1555<<16 | 16<<8 | 2<<0,
	RGBA5551    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_RGBA<<20 | PACKEDLAYOUT_5551<<16 | 16<<8 | 2<<0,
	ABGR1555    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_ABGR<<20 | PACKEDLAYOUT_1555<<16 | 16<<8 | 2<<0,
	BGRA5551    = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_BGRA<<20 | PACKEDLAYOUT_5551<<16 | 16<<8 | 2<<0,
	RGB565      = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_XRGB<<20 | PACKEDLAYOUT_565<<16  | 16<<8 | 2<<0,
	BGR565      = 1<<28 | PIXELTYPE_PACKED16<<24 | PACKEDORDER_XBGR<<20 | PACKEDLAYOUT_565<<16  | 16<<8 | 2<<0,
	RGB24       = 1<<28 | PIXELTYPE_ARRAYU8<<24  | ARRAYORDER_RGB<<20   | 0<<16 | 24<<8 | 3<<0,
	BGR24       = 1<<28 | PIXELTYPE_ARRAYU8<<24  | ARRAYORDER_BGR<<20   | 0<<16 | 24<<8 | 3<<0,
	XRGB8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_XRGB<<20 | PACKEDLAYOUT_8888<<16 | 24<<8 | 4<<0,
	RGB888      = XRGB8888,
	RGBX8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_RGBX<<20 | PACKEDLAYOUT_8888<<16 | 24<<8 | 4<<0,
	XBGR8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_XBGR<<20 | PACKEDLAYOUT_8888<<16 | 24<<8 | 4<<0,
	BGR888      = XBGR8888,
	BGRX8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_BGRX<<20 | PACKEDLAYOUT_8888<<16 | 24<<8 | 4<<0,
	ARGB8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_ARGB<<20 | PACKEDLAYOUT_8888<<16 | 32<<8 | 4<<0,
	RGBA8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_RGBA<<20 | PACKEDLAYOUT_8888<<16 | 32<<8 | 4<<0,
	ABGR8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_ABGR<<20 | PACKEDLAYOUT_8888<<16 | 32<<8 | 4<<0,
	BGRA8888    = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_BGRA<<20 | PACKEDLAYOUT_8888<<16 | 32<<8 | 4<<0,
	ARGB2101010 = 1<<28 | PIXELTYPE_PACKED32<<24 | PACKEDORDER_ARGB<<20 | PACKEDLAYOUT_2101010<<16 | 32<<8 | 4<<0,

	/* Aliases for RGBA byte arrays of color data, for the current platform */
	RGBA32 = RGBA8888 when ODIN_ENDIAN == .Big else ABGR8888,
	ARGB32 = ARGB8888 when ODIN_ENDIAN == .Big else BGRA8888,
	BGRA32 = BGRA8888 when ODIN_ENDIAN == .Big else ARGB8888,
	ABGR32 = ABGR8888 when ODIN_ENDIAN == .Big else RGBA8888,

	YV12 =      /**< Planar mode: Y + V + U  (3 planes) */
		'Y'<<0 | 'V'<<8 | '1'<<16 | '2'<<24,
	IYUV =      /**< Planar mode: Y + U + V  (3 planes) */
		'I'<<0 | 'Y'<<8 | 'U'<<16 | 'V'<<24,
	YUY2 =      /**< Packed mode: Y0+U0+Y1+V0 (1 plane) */
		'Y'<<0 | 'U'<<8 | 'Y'<<16 | '2'<<24,
	UYVY =      /**< Packed mode: U0+Y0+V0+Y1 (1 plane) */
		'U'<<0 | 'Y'<<8 | 'V'<<16 | 'Y'<<24,
	YVYU =      /**< Packed mode: Y0+V0+Y1+U0 (1 plane) */
		'Y'<<0 | 'V'<<8 | 'Y'<<16 | 'U'<<24,
	NV12 =      /**< Planar mode: Y + U/V interleaved  (2 planes) */
		'N'<<0 | 'V'<<8 | '1'<<16 | '2'<<24,
	NV21 =      /**< Planar mode: Y + V/U interleaved  (2 planes) */
		'N'<<0 | 'V'<<8 | '2'<<16 | '1'<<24,
	EXTERNAL_OES =      /**< Android video texture format */
		'O'<<0 | 'E'<<8 | 'S'<<16 | ' '<<24,
}


Colour :: Color
Color :: struct {
	r: u8,
	g: u8,
	b: u8,
	a: u8,
}

Palette :: struct {
	ncolors:  c.int,
	colors:   ^Color,
	version:  u32,
	refcount: c.int,
}


PixelFormat :: struct {
	format:        u32,
	palette:       ^Palette,
	BitsPerPixel:  u8,
	BytesPerPixel: u8,
	padding:       [2]u8,
	Rmask:         u32,
	Gmask:         u32,
	Bmask:         u32,
	Amask:         u32,
	Rloss:         u8,
	Gloss:         u8,
	Bloss:         u8,
	Aloss:         u8,
	Rshift:        u8,
	Gshift:        u8,
	Bshift:        u8,
	Ashift:        u8,
	refcount:      c.int,
	next:          ^PixelFormat,
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetPixelFormatName     :: proc(format: u32) -> cstring ---
	PixelFormatEnumToMasks :: proc(format: u32, bpp: ^c.int, Rmask, Gmask, Bmask, Amask: ^u32) -> bool ---
	MasksToPixelFormatEnum :: proc(bpp: c.int, Rmask, Gmask, Bmask, Amask: u32) -> u32 ---
	AllocFormat            :: proc(pixel_format: u32) -> ^PixelFormat ---
	FreeFormat             :: proc(format: ^PixelFormat) ---
	AllocPalette           :: proc(ncolors: c.int) -> ^Palette ---
	SetPixelFormatPalette  :: proc(format: ^PixelFormat, palette: ^Palette) -> c.int ---
	SetPaletteColors       :: proc(palette: ^Palette, colors: [^]Color, firstcolor, ncolors: c.int) -> c.int ---
	FreePalette            :: proc(palette: ^Palette) ---
	MapRGB                 :: proc(format: ^PixelFormat, r, g, b: u8) -> u32 ---
	MapRGBA                :: proc(format: ^PixelFormat, r, g, b, a: u8) -> u32 ---
	GetRGB                 :: proc(pixel: u32, format: ^PixelFormat, r, g, b: ^u8) ---
	GetRGBA                :: proc(pixel: u32, format: ^PixelFormat, r, g, b, a: ^u8) ---
	CalculateGammaRamp     :: proc(gamma: f32, ramp: ^[256]u16) ---
}
