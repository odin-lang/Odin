package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

SWSURFACE       :: 0           /**< Just here for compatibility */
PREALLOC        :: 0x00000001  /**< Surface uses preallocated memory */
RLEACCEL        :: 0x00000002  /**< Surface is RLE encoded */
DONTFREE        :: 0x00000004  /**< Surface is referenced internally */
SIMD_ALIGNED    :: 0x00000008  /**< Surface uses aligned memory */

MUSTLOCK :: #force_inline proc "c" (surface: ^Surface) -> bool {
	return bool(surface.flags & RLEACCEL != 0)
}

BlitMap :: struct {}

Surface :: struct {
	flags:  u32,                 /**< Read-only */
	format: ^PixelFormat,        /**< Read-only */
	w, h:   c.int,               /**< Read-only */
	pitch:  c.int,               /**< Read-only */
	pixels: rawptr,              /**< Read-write */

	/** Application data associated with the surface */
	userdata: rawptr,            /**< Read-write */

	/** information needed for surfaces requiring locks */
	locked: c.int,               /**< Read-only */

	/** list of BlitMap that hold a reference to this surface */
	list_blitmap: rawptr,        /**< Private */

	/** clipping information */
	clip_rect: Rect,             /**< Read-only */

	/** info for fast blit mapping to other surfaces */
	blitmap: ^BlitMap,           /**< Private */

	/** Reference count -- used when freeing surface */
	refcount: c.int,             /**< Read-mostly */
}

blit :: proc "c" (src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int


YUV_CONVERSION_MODE :: enum c.int {
	JPEG,        /**< Full range JPEG */
	BT601,       /**< BT.601 (the default) */
	BT709,       /**< BT.709 */
	AUTOMATIC,   /**< BT.601 for SD content, BT.709 for HD content */
}


LoadBMP :: #force_inline proc "c" (file: cstring) -> ^Surface {
	return LoadBMP_RW(RWFromFile(file, "rb"), true)
}

SaveBMP :: #force_inline proc "c" (surface: ^Surface, file: cstring) -> c.int {
	return SaveBMP_RW(surface, RWFromFile(file, "wb"), true)
}

BlitSurface :: UpperBlit
BlitScaled  :: UpperBlitScaled


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	CreateRGBSurface                  :: proc(flags: u32, width, height, depth: c.int, Rmask, Gmask, Bmask, Amask: u32) -> ^Surface ---
	CreateRGBSurfaceWithFormat        :: proc(flags: u32, width, height, depth: c.int, format: u32) -> ^Surface ---
	CreateRGBSurfaceFrom              :: proc(pixels: rawptr, width, height, depth, pitch: c.int, Rmask, Gmask, Bmask, Amask: u32) -> ^Surface ---
	CreateRGBSurfaceWithFormatFrom    :: proc(pixels: rawptr, width, height, depth, pitch: c.int, format: u32) -> ^Surface ---
	FreeSurface                       :: proc(surface: ^Surface) ---
	SetSurfacePalette                 :: proc(surface: ^Surface, palette: ^Palette) -> c.int ---
	LockSurface                       :: proc(surface: ^Surface) -> c.int ---
	UnlockSurface                     :: proc(surface: ^Surface) ---
	LoadBMP_RW                        :: proc(src: ^RWops, freesrc: bool) -> ^Surface ---
	SaveBMP_RW                        :: proc(surface: ^Surface, dst: ^RWops, freedst: bool) -> c.int ---
	SetSurfaceRLE                     :: proc(surface: ^Surface, flag: c.int) -> c.int ---
	HasSurfaceRLE                     :: proc(surface: ^Surface) -> bool ---
	SetColorKey                       :: proc(surface: ^Surface, flag: c.int, key: u32) -> c.int ---
	HasColorKey                       :: proc(surface: ^Surface) -> bool ---
	GetColorKey                       :: proc(surface: ^Surface, key: ^u32) -> c.int ---
	SetSurfaceColorMod                :: proc(surface: ^Surface, r, g, b: u8) -> c.int ---
	GetSurfaceColorMod                :: proc(surface: ^Surface, r, g, b: ^u8) -> c.int ---
	SetSurfaceAlphaMod                :: proc(surface: ^Surface, alpha: u8) -> c.int ---
	GetSurfaceAlphaMod                :: proc(surface: ^Surface, alpha: ^u8) -> c.int ---
	SetSurfaceBlendMode               :: proc(surface: ^Surface, blendMode: BlendMode) -> c.int ---
	GetSurfaceBlendMode               :: proc(surface: ^Surface, blendMode: ^BlendMode) -> c.int ---
	SetClipRect                       :: proc(surface: ^Surface, rect: ^Rect) -> bool ---
	GetClipRect                       :: proc(surface: ^Surface, rect: ^Rect) ---
	DuplicateSurface                  :: proc(surface: ^Surface) -> ^Surface ---
	ConvertSurface                    :: proc(src: ^Surface, fmt: ^PixelFormat, flags: u32) -> ^Surface ---
	ConvertSurfaceFormat              :: proc(src: ^Surface, pixel_format: u32, flags: u32) -> ^Surface ---
	ConvertPixels                     :: proc(width, height: c.int, src_format: u32, src: rawptr, src_pitch: c.int, dst_format: u32, dst: rawptr, dst_pitch: c.int) -> c.int ---
	FillRect                          :: proc(dst: ^Surface, rect: ^Rect, color: u32) -> c.int ---
	FillRects                         :: proc(dst: ^Surface, rects: [^]Rect, count: c.int, color: u32) -> c.int ---
	UpperBlit                         :: proc(src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int ---
	LowerBlit                         :: proc(src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int ---
	SoftStretch                       :: proc(src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int ---
	SoftStretchLinear                 :: proc(src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int ---
	UpperBlitScaled                   :: proc(src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int ---
	LowerBlitScaled                   :: proc(src: ^Surface, srcrect: ^Rect, dst: ^Surface, dstrect: ^Rect) -> c.int ---
	SetYUVConversionMode              :: proc(mode: YUV_CONVERSION_MODE) ---
	GetYUVConversionMode              :: proc() -> YUV_CONVERSION_MODE ---
	GetYUVConversionModeForResolution :: proc(width, height: c.int) -> YUV_CONVERSION_MODE ---
}
