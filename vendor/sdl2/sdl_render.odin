package sdl2

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "SDL2.lib"
} else {
	foreign import lib "system:SDL2"
}

RendererFlag :: enum u32 {
	SOFTWARE      = 0, /**< The renderer is a software fallback */
	ACCELERATED   = 1, /**< The renderer uses hardware acceleration */
	PRESENTVSYNC  = 2, /**< Present is synchronized with the refresh rate */
	TARGETTEXTURE = 3, /**< The renderer supports rendering to texture */
}

RendererFlags :: distinct bit_set[RendererFlag; u32]

RENDERER_SOFTWARE      :: RendererFlags{.SOFTWARE}
RENDERER_ACCELERATED   :: RendererFlags{.ACCELERATED}
RENDERER_PRESENTVSYNC  :: RendererFlags{.PRESENTVSYNC}
RENDERER_TARGETTEXTURE :: RendererFlags{.TARGETTEXTURE}

RendererInfo :: struct {
	name:                cstring,       /**< The name of the renderer */
	flags:               RendererFlags, /**< Supported ::SDL_RendererFlags */
	num_texture_formats: u32,           /**< The number of available texture formats */
	texture_formats:     [16]u32,       /**< The available texture formats */
	max_texture_width:   c.int,         /**< The maximum texture width */
	max_texture_height:  c.int,         /**< The maximum texture height */
}

/**
 * The scaling mode for a texture.
 */
ScaleMode :: enum c.int {
	Nearest, /**< nearest pixel sampling */
	Linear,  /**< linear filtering */
	Best,    /**< anisotropic filtering */
}

/**
 * The access pattern allowed for a texture.
 */
TextureAccess :: enum c.int {
	STATIC,    /**< Changes rarely, not lockable */
	STREAMING, /**< Changes frequently, lockable */
	TARGET,    /**< Texture can be used as a render target */
}

TEXTUREMODULATE_NONE  :: 0x00000000 /**< No modulation */
TEXTUREMODULATE_COLOR :: 0x00000001 /**< srcC = srcC * color */
TEXTUREMODULATE_ALPHA :: 0x00000002 /**< srcA = srcA * alpha */

/**
 * Flip constants for SDL_RenderCopyEx
 */
RendererFlip :: enum c.int {
	NONE       = 0x00000000,    /**< Do not flip */
	HORIZONTAL = 0x00000001,    /**< flip horizontally */
	VERTICAL   = 0x00000002,    /**< flip vertically */
}

Renderer :: struct {}

Texture :: struct {}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumRenderDrivers          :: proc() -> c.int ---
	GetRenderDriverInfo          :: proc(index: c.int, info: ^RendererInfo) -> c.int ---
	CreateWindowAndRenderer      :: proc(width, height: c.int, window_flags: WindowFlags, window: ^^Window, renderer: ^^Renderer) -> c.int ---
	CreateRenderer               :: proc(window:  ^Window, index: c.int, flags: RendererFlags) -> ^Renderer ---
	CreateSoftwareRenderer       :: proc(surface:  ^Surface) -> ^Renderer ---
	GetRenderer                  :: proc(window:   ^Window) -> ^Renderer ---
	GetRendererInfo              :: proc(renderer: ^Renderer, info: ^RendererInfo) -> c.int ---
	GetRendererOutputSize        :: proc(renderer: ^Renderer, w, h: ^c.int) -> c.int ---
	CreateTexture                :: proc(renderer: ^Renderer, format: PixelFormatEnum, access: TextureAccess, w, h: c.int) -> ^Texture ---
	CreateTextureFromSurface     :: proc(renderer: ^Renderer, surface: ^Surface) -> ^Texture ---
	QueryTexture                 :: proc(texture:  ^Texture, format: ^u32, access, w, h: ^c.int) -> c.int ---
	SetTextureColorMod           :: proc(texture:  ^Texture, r, g, b: u8) -> c.int ---
	GetTextureColorMod           :: proc(texture:  ^Texture, r, g, b: ^u8) -> c.int ---
	SetTextureAlphaMod           :: proc(texture:  ^Texture, alpha: u8) -> c.int ---
	GetTextureAlphaMod           :: proc(texture:  ^Texture, alpha: ^u8) -> c.int ---
	SetTextureBlendMode          :: proc(texture:  ^Texture, blendMode: BlendMode) -> c.int ---
	GetTextureBlendMode          :: proc(texture:  ^Texture, blendMode: ^BlendMode) -> c.int ---
	SetTextureScaleMode          :: proc(texture:  ^Texture, scaleMode: ScaleMode) -> c.int ---
	GetTextureScaleMode          :: proc(texture:  ^Texture, scaleMode: ^ScaleMode) -> c.int ---
	UpdateTexture                :: proc(texture:  ^Texture, rect: ^Rect, pixels: rawptr, pitch: c.int) -> c.int ---
	UpdateYUVTexture             :: proc(texture:  ^Texture, rect: ^Rect, Yplane: ^u8, Ypitch: c.int, Uplane: ^u8, Upitch: c.int, Vplane: ^u8, Vpitch: c.int) -> c.int ---
	UpdateNVTexture              :: proc(texture:  ^Texture, rect: ^Rect, Yplane: ^u8, Ypitch: c.int, UVplane: ^u8, UVpitch: c.int) -> c.int ---
	LockTexture                  :: proc(texture:  ^Texture, rect: ^Rect, pixels: ^rawptr, pitch: ^c.int) -> c.int ---
	LockTextureToSurface         :: proc(texture:  ^Texture, rect: ^Rect, surface: ^^Surface) -> c.int ---
	UnlockTexture                :: proc(texture:  ^Texture) ---
	RenderTargetSupported        :: proc(renderer: ^PixelFormatEnum) -> bool ---
	SetRenderTarget              :: proc(renderer: ^Renderer, texture: ^Texture) -> c.int ---
	GetRenderTarget              :: proc(renderer: ^Renderer) -> ^Texture ---
	RenderSetLogicalSize         :: proc(renderer: ^Renderer, w, h: c.int) -> c.int ---
	RenderGetLogicalSize         :: proc(renderer: ^Renderer, w, h: ^c.int) ---
	RenderSetIntegerScale        :: proc(renderer: ^Renderer, enable: bool) -> c.int ---
	RenderGetIntegerScale        :: proc(renderer: ^Renderer) -> bool ---
	RenderSetViewport            :: proc(renderer: ^Renderer, rect: ^Rect) -> c.int ---
	RenderGetViewport            :: proc(renderer: ^Renderer, rect: ^Rect) ---
	RenderSetClipRect            :: proc(renderer: ^Renderer, rect: ^Rect) -> c.int ---
	RenderGetClipRect            :: proc(renderer: ^Renderer, rect: ^Rect) ---
	RenderIsClipEnabled          :: proc(renderer: ^Renderer) -> bool ---
	RenderSetScale               :: proc(renderer: ^Renderer, scaleX, scaleY: f32) -> c.int ---
	RenderGetScale               :: proc(renderer: ^Renderer, scaleX, scaleY: ^f32) ---
	SetRenderDrawColor           :: proc(renderer: ^Renderer, r, g, b, a: u8) -> c.int ---
	GetRenderDrawColor           :: proc(renderer: ^Renderer, r, g, b, a: ^u8) -> c.int ---
	SetRenderDrawBlendMode       :: proc(renderer: ^Renderer, blendMode: BlendMode) -> c.int ---
	GetRenderDrawBlendMode       :: proc(renderer: ^Renderer, blendMode: ^BlendMode) -> c.int ---
	RenderClear                  :: proc(renderer: ^Renderer) -> c.int ---
	RenderDrawPoint              :: proc(renderer: ^Renderer, x, y: c.int) -> c.int ---
	RenderDrawPoints             :: proc(renderer: ^Renderer, points: [^]Point, count: c.int) -> c.int ---
	RenderDrawLine               :: proc(renderer: ^Renderer, x1, y1, x2, y2: c.int) -> c.int ---
	RenderDrawLines              :: proc(renderer: ^Renderer, points: [^]Point, count: c.int) -> c.int ---
	RenderDrawRect               :: proc(renderer: ^Renderer, rect: ^Rect) -> c.int ---
	RenderDrawRects              :: proc(renderer: ^Renderer, rect: ^Rect, count: c.int) -> c.int ---
	RenderFillRect               :: proc(renderer: ^Renderer, rect: ^Rect) -> c.int ---
	RenderFillRects              :: proc(renderer: ^Renderer, rects: [^]Rect, count: c.int) -> c.int ---
	RenderCopy                   :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: ^Rect, dstrect: ^Rect) -> c.int ---
	RenderCopyEx                 :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: ^Rect, dstrect: ^Rect, angle: f64, center: ^Point, flip: RendererFlip) -> c.int ---
	RenderDrawPointF             :: proc(renderer: ^Renderer, x, y: f32) -> c.int ---
	RenderDrawPointsF            :: proc(renderer: ^Renderer, points: [^]FPoint, count: c.int) -> c.int ---
	RenderDrawLineF              :: proc(renderer: ^Renderer, x1, y1, x2, y2: f32) -> c.int ---
	RenderDrawLinesF             :: proc(renderer: ^Renderer, points: [^]FPoint, count: c.int) -> c.int ---
	RenderDrawRectF              :: proc(renderer: ^Renderer, rect: ^FRect) -> c.int ---
	RenderDrawRectsF             :: proc(renderer: ^Renderer, rects: [^]FRect, count: c.int) -> c.int ---
	RenderFillRectF              :: proc(renderer: ^Renderer, rect: ^FRect) -> c.int ---
	RenderFillRectsF             :: proc(renderer: ^Renderer, rects: [^]FRect, count: c.int) -> c.int ---
	RenderCopyF                  :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: ^Rect, dstrect: ^FRect) -> c.int ---
	RenderCopyExF                :: proc(renderer: ^Renderer, texture: ^Texture, srcrect: ^Rect, dstrect: ^FRect, angle: f64, center: ^FPoint, flip: RendererFlip) -> c.int ---
	RenderReadPixels             :: proc(renderer: ^Renderer, rect: ^Rect, format: u32, pixels: rawptr, pitch: c.int) -> c.int ---
	RenderPresent                :: proc(renderer: ^Renderer) ---
	DestroyTexture               :: proc(texture:  ^Texture) ---
	DestroyRenderer              :: proc(renderer: ^Renderer) ---
	RenderFlush                  :: proc(renderer: ^Renderer) -> c.int ---
	GL_BindTexture               :: proc(texture:  ^Texture, texw, texh: ^f32) -> c.int ---
	GL_UnbindTexture             :: proc(texture:  ^Texture) -> c.int ---
	RenderGetMetalLayer          :: proc(renderer: ^Renderer) -> rawptr ---
	RenderGetMetalCommandEncoder :: proc(renderer: ^Renderer) -> rawptr ---
}
