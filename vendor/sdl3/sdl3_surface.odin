package sdl3

import "core:c"

SurfaceFlags :: distinct bit_set[SurfaceFlag; Uint32]

SurfaceFlag :: enum Uint32 {
	PREALLOCATED = 0, /**< Surface uses preallocated pixel memory */
	LOCK_NEEDED  = 1, /**< Surface needs to be locked to access pixels */
	LOCKED       = 2, /**< Surface is currently locked */
	SIMD_ALIGNED = 3, /**< Surface uses pixel memory allocated with SDL_aligned_alloc() */
}

SURFACE_PREALLOCATED :: SurfaceFlags{.PREALLOCATED}
SURFACE_LOCK_NEEDED  :: SurfaceFlags{.LOCK_NEEDED}
SURFACE_LOCKED       :: SurfaceFlags{.LOCKED}
SURFACE_SIMD_ALIGNED :: SurfaceFlags{.SIMD_ALIGNED}

@(require_results)
MUSTLOCK :: proc "c" (S: ^Surface) -> bool {
	return .LOCK_NEEDED in S.flags
}

ScaleMode :: enum c.int {
	NEAREST, /**< nearest pixel sampling */
	LINEAR,  /**< linear filtering */
}

FlipMode :: enum c.int {
	NONE,          /**< Do not flip */
	HORIZONTAL,    /**< flip horizontally */
	VERTICAL,      /**< flip vertically */
}

Surface :: struct {
	flags:    SurfaceFlags, /**< The flags of the surface, read-only */
	format:   PixelFormat,  /**< The format of the surface, read-only */
	w:        c.int,        /**< The width of the surface, read-only. */
	h:        c.int,        /**< The height of the surface, read-only. */
	pitch:    c.int,        /**< The distance in bytes between rows of pixels, read-only */
	pixels:   rawptr,       /**< A pointer to the pixels of the surface, the pixels are writeable if non-NULL */

	refcount: c.int,        /**< Application reference count, used when freeing surface */

	reserved: rawptr,       /**< Reserved for internal use */
}


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	CreateSurface                :: proc(width, height: c.int, format: PixelFormat) -> ^Surface ---
	CreateSurfaceFrom            :: proc(width, height: c.int, format: PixelFormat, pixels: rawptr, pitch: c.int) -> ^Surface ---
	DestroySurface               :: proc(surface: ^Surface) ---
	GetSurfaceProperties         :: proc(surface: ^Surface) -> PropertiesID ---
	SetSurfaceColorspace         :: proc(surface: ^Surface, colorspace: Colorspace) -> bool ---
	GetSurfaceColorspace         :: proc(surface: ^Surface) -> Colorspace ---
	CreateSurfacePalette         :: proc(surface: ^Surface) -> ^Palette ---
	SetSurfacePalette            :: proc(surface: ^Surface, palette: ^Palette) -> bool ---
	GetSurfacePalette            :: proc(surface: ^Surface) -> ^Palette ---
	AddSurfaceAlternateImage     :: proc(surface: ^Surface, image: ^Surface) -> bool ---
	SurfaceHasAlternateImages    :: proc(surface: ^Surface) -> bool ---
	GetSurfaceImages             :: proc(surface: ^Surface, count: ^c.int) -> [^]^Surface ---
	RemoveSurfaceAlternateImages :: proc(surface: ^Surface) ---
	LockSurface                  :: proc(surface: ^Surface) -> bool ---
	UnlockSurface                :: proc(surface: ^Surface) ---
	LoadBMP_IO                   :: proc(src: ^IOStream, closeio: bool) -> ^Surface ---
	LoadBMP                      :: proc(file: cstring) -> ^Surface ---
	SaveBMP_IO                   :: proc(surface: ^Surface, dst: ^IOStream, closeio: bool) -> bool ---
	SaveBMP                      :: proc(surface: ^Surface, file: cstring) -> bool ---
	SetSurfaceRLE                :: proc(surface: ^Surface, enabled: bool) -> bool ---
	SurfaceHasRLE                :: proc(surface: ^Surface) -> bool ---
	SetSurfaceColorKey           :: proc(surface: ^Surface, enabled: bool, key: Uint32) -> bool ---
	SurfaceHasColorKey           :: proc(surface: ^Surface) -> bool ---
	GetSurfaceColorKey           :: proc(surface: ^Surface, key: ^Uint32) -> bool ---
	SetSurfaceColorMod           :: proc(surface: ^Surface, r, g, b: Uint8) -> bool ---
	GetSurfaceColorMod           :: proc(surface: ^Surface, r, g, b: ^Uint8) -> bool ---
	SetSurfaceAlphaMod           :: proc(surface: ^Surface, alpha: Uint8) -> bool ---
	GetSurfaceAlphaMod           :: proc(surface: ^Surface, alpha: ^Uint8) -> bool ---
	SetSurfaceBlendMode          :: proc(surface: ^Surface, blendMode: BlendMode) -> bool ---
	GetSurfaceBlendMode          :: proc(surface: ^Surface, blendMode: ^BlendMode) -> bool ---
	SetSurfaceClipRect           :: proc(surface: ^Surface, #by_ptr rect: Rect) -> bool ---
	GetSurfaceClipRect           :: proc(surface: ^Surface, rect: ^Rect) -> bool ---
	FlipSurface                  :: proc(surface: ^Surface, flip: FlipMode) -> bool ---
	DuplicateSurface             :: proc(surface: ^Surface) -> ^Surface ---
	ScaleSurface                 :: proc(surface: ^Surface, width, height: c.int, scaleMode: ScaleMode) -> ^Surface ---
	ConvertSurface               :: proc(surface: ^Surface, format: PixelFormat) -> ^Surface ---
	ConvertSurfaceAndColorspace  :: proc(surface: ^Surface, format: PixelFormat, palette: ^Palette, colorspace: Colorspace, props: PropertiesID) -> ^Surface ---
	ConvertPixels                :: proc(width, height: c.int, src_format: PixelFormat, src: rawptr, src_pitch: c.int, dst_format: PixelFormat, dst: rawptr, dst_pitch: c.int) -> bool ---
	ConvertPixelsAndColorspace   :: proc(width, height: c.int, src_format: PixelFormat, src_colorspace: Colorspace, src_properties: PropertiesID, src: rawptr, src_pitch: c.int, dst_format: PixelFormat, dst_colorspace: Colorspace, dst_properties: PropertiesID, dst: rawptr, dst_pitch: c.int) -> bool ---
	PremultiplyAlpha             :: proc(width, height: c.int, src_format: PixelFormat, src: rawptr, src_pitch: c.int, dst_format: PixelFormat, dst: rawptr, dst_pitch: c.int, linear: bool) -> bool ---
	PremultiplySurfaceAlpha      :: proc(surface: ^Surface, linear: bool) -> bool ---
	ClearSurface                 :: proc(surface: ^Surface, r, g, b, a: f32) -> bool ---
	FillSurfaceRect              :: proc(dst: ^Surface, #by_ptr rect: Rect, color: Uint32) -> bool ---
	FillSurfaceRects             :: proc(dst: ^Surface, rects: [^]Rect, count: c.int, color: Uint32) -> bool ---
	BlitSurface                  :: proc(src: ^Surface, #by_ptr srcrect: Rect, dst: ^Surface, #by_ptr dstrect: Rect) -> bool ---
	BlitSurfaceUnchecked         :: proc(src: ^Surface, #by_ptr srcrect: Rect, dst: ^Surface, #by_ptr dstrect: Rect) -> bool ---
	BlitSurfaceScaled            :: proc(src: ^Surface, #by_ptr srcrect: Rect, dst: ^Surface, #by_ptr dstrect: Rect, scaleMode: ScaleMode) -> bool ---
	BlitSurfaceUncheckedScaled   :: proc(src: ^Surface, #by_ptr srcrect: Rect, dst: ^Surface, #by_ptr dstrect: Rect, scaleMode: ScaleMode) -> bool ---
	BlitSurfaceTiled             :: proc(src: ^Surface, #by_ptr srcrect: Rect, dst: ^Surface, #by_ptr dstrect: Rect) -> bool ---
	BlitSurfaceTiledWithScale    :: proc(src: ^Surface, #by_ptr srcrect: Rect, scale: f32, scaleMode: ScaleMode, dst: ^Surface, #by_ptr dstrect: Rect) -> bool ---
	BlitSurface9Grid             :: proc(src: ^Surface, #by_ptr srcrect: Rect, left_width, right_width, top_height, bottom_height: c.int, scale: f32, scaleMode: ScaleMode, dst: ^Surface, #by_ptr dstrect: Rect) -> bool ---
	MapSurfaceRGB                :: proc(surface: ^Surface, r, g, b: Uint8) -> Uint32 ---
	MapSurfaceRGBA               :: proc(surface: ^Surface, r, g, b, a: Uint8) -> Uint32 ---
	ReadSurfacePixel             :: proc(surface: ^Surface, x, y: c.int, r, g, b, a: ^Uint8) -> bool ---
	ReadSurfacePixelFloat        :: proc(surface: ^Surface, x, y: c.int, r, g, b, a: ^f32) -> bool ---
	WriteSurfacePixel            :: proc(surface: ^Surface, x, y: c.int, r, g, b, a: Uint8) -> bool ---
	WriteSurfacePixelFloat       :: proc(surface: ^Surface, x, y: c.int, r, g, b, a: f32) -> bool ---
}