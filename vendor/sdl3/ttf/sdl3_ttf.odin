// Bindings for [[ SDL3 TTF ; https://wiki.libsdl.org/SDL3/FrontPage ]].
package sdl3_ttf

import "core:c"
import SDL "vendor:sdl3"

when ODIN_OS == .Windows {
	foreign import lib "SDL3_ttf.lib"
} else {
	foreign import lib "system:SDL3_ttf"
}


PROP_FONT_CREATE_FILENAME_STRING            :: "SDL_ttf.font.create.filename"
PROP_FONT_CREATE_IOSTREAM_POINTER           :: "SDL_ttf.font.create.iostream"
PROP_FONT_CREATE_IOSTREAM_OFFSET_NUMBER     :: "SDL_ttf.font.create.iostream.offset"
PROP_FONT_CREATE_IOSTREAM_AUTOCLOSE_BOOLEAN :: "SDL_ttf.font.create.iostream.autoclose"
PROP_FONT_CREATE_SIZE_FLOAT                 :: "SDL_ttf.font.create.size"
PROP_FONT_CREATE_FACE_NUMBER                :: "SDL_ttf.font.create.face"
PROP_FONT_CREATE_HORIZONTAL_DPI_NUMBER      :: "SDL_ttf.font.create.hdpi"
PROP_FONT_CREATE_VERTICAL_DPI_NUMBER        :: "SDL_ttf.font.create.vdpi"
PROP_FONT_CREATE_EXISTING_FONT              :: "SDL_ttf.font.create.existing_font"

FONT_WEIGHT_THIN        :: 100 /**< Thin (100) named font weight value */
FONT_WEIGHT_EXTRA_LIGHT :: 200 /**< ExtraLight (200) named font weight value */
FONT_WEIGHT_LIGHT       :: 300 /**< Light (300) named font weight value */
FONT_WEIGHT_NORMAL      :: 400 /**< Normal (400) named font weight value */
FONT_WEIGHT_MEDIUM      :: 500 /**< Medium (500) named font weight value */
FONT_WEIGHT_SEMI_BOLD   :: 600 /**< SemiBold (600) named font weight value */
FONT_WEIGHT_BOLD        :: 700 /**< Bold (700) named font weight value */
FONT_WEIGHT_EXTRA_BOLD  :: 800 /**< ExtraBold (800) named font weight value */
FONT_WEIGHT_BLACK       :: 900 /**< Black (900) named font weight value */
FONT_WEIGHT_EXTRA_BLACK :: 950 /**< ExtraBlack (950) named font weight value */

PROP_RENDERER_TEXT_ENGINE_RENDERER           :: "SDL_ttf.renderer_text_engine.create.renderer"
PROP_RENDERER_TEXT_ENGINE_ATLAS_TEXTURE_SIZE :: "SDL_ttf.renderer_text_engine.create.atlas_texture_size"

PROP_GPU_TEXT_ENGINE_DEVICE             :: "SDL_ttf.gpu_text_engine.create.device"
PROP_GPU_TEXT_ENGINE_ATLAS_TEXTURE_SIZE :: "SDL_ttf.gpu_text_engine.create.atlas_texture_size"

MAJOR_VERSION :: 3
MINOR_VERSION :: 2
PATCHLEVEL    :: 2

Font :: struct {}

Text :: struct {
	text:      [^]u8,
	num_lines: c.int,
	refcount:  c.int,
	internal:  ^TextData,
}

FontStyle :: enum u32 {
	BOLD,
	ITALIC,
	UNDERLINE,
	STRIKETHROUGH,
}

FontStyleFlags :: distinct bit_set[FontStyle; u32]

// NOTE: This is called TTF_HintingFlags but its not a bit_set so 
// the "flags" doesn't really make sense, its just the hinting.
Hinting :: enum c.int {
	INVALID = -1,
	NORMAL,
	LIGHT,
	MONO,
	NONE,
	LIGHT_SUBPIXEL,
}

HorizontalAlignment :: enum c.int {
	INVALID = -1,
	LEFT,
	CENTER,
	RIGHT,
}

Direction :: enum c.int {
	INVALID,
	LTR = 4,
	RTL,
	TTB,
	BTT,
}

ImageType :: enum c.int {
	INVALID,
	ALPHA,
	COLOR,
	SDF,
}

GPUAtlasDrawSequence :: struct {
	atlas_texture: ^SDL.GPUTexture,
	xy, uv:        [^]SDL.FPoint `fmt:"v,num_vertices"`,
	num_vertices:  c.int,
	indices:       [^]c.int      `fmt:"v,num_indices"`,
	num_indices:   c.int,
	image_type:    ImageType,
	next:          ^GPUAtlasDrawSequence,
}

GPUTextEngineWinding :: enum c.int {
	INVALID           = -1,
	CLOCKWISE         =  0,
	COUNTER_CLOCKWISE = +1,
}

SubStringFlags :: bit_field u32 {
	direction:  u8   | 8,
	text_start: bool | 1,
	line_start: bool | 1,
	line_end:   bool | 1,
	text_end:   bool | 1,
}

SubString :: struct {
	flags:                     SubStringFlags,
	offset, length:            c.int,
	line_index, cluster_index: c.int,
	rect:                      SDL.Rect,
}

@(default_calling_convention="c", link_prefix="TTF_", require_results)
foreign lib {
	Version :: proc() -> c.int ---
	WasInit :: proc() -> c.int ---

	OpenFont               :: proc(file: cstring, ptsize: f32) -> ^Font ---
	OpenFontIO             :: proc(src: ^SDL.IOStream, closeio: bool, ptsize: f32) -> ^Font ---
	OpenFontWithProperties :: proc(props: SDL.PropertiesID) -> ^Font ---

	CopyFont :: proc(existing_font: ^Font) -> ^Font ---

	GetFontProperties :: proc(font: ^Font) -> SDL.PropertiesID ---
	GetFontGeneration :: proc(font: ^Font) -> u32 ---

	GetFontSize  :: proc(font: ^Font) -> f32 ---

	SetFontStyle :: proc(font: ^Font, style: FontStyleFlags) ---
	GetFontStyle :: proc(font: ^Font) -> FontStyleFlags ---

	SetFontOutline :: proc(font: ^Font, outline: c.int) -> bool ---
	GetFontOutline :: proc(font: ^Font) -> c.int ---

	SetFontHinting :: proc(font: ^Font, hinting: Hinting) ---
	GetFontHinting :: proc(font: ^Font) -> Hinting ---

	GetNumFontFaces :: proc(font: ^Font) -> c.int ---

	SetFontSDF :: proc(font: ^Font, enabled: bool) -> bool ---
	GetFontSDF :: proc(font: ^Font) -> bool ---

	GetFontWeight :: proc(font: ^Font) -> c.int ---

	SetFontWrapAlignment :: proc(font: ^Font, align: HorizontalAlignment) ---
	GetFontWrapAlignment :: proc(font: ^Font) -> HorizontalAlignment ---

	GetFontHeight :: proc(font: ^Font) -> c.int ---
	GetFontAscent :: proc(font: ^Font) -> c.int ---
	GetFontDescent :: proc(font: ^Font) -> c.int ---

	SetFontLineSkip :: proc(font: ^Font, lineskip: c.int) ---
	GetFontLineSkip :: proc(font: ^Font) -> c.int ---

	SetFontKerning :: proc(font: ^Font, enabled: bool) ---
	GetFontKerning :: proc(font: ^Font) -> bool ---

	FontIsFixedWidth :: proc(font: ^Font) -> bool ---
	FontIsScalable :: proc(font: ^Font) -> bool ---

	GetFontFamilyName :: proc(font: ^Font) -> cstring ---
	GetFontStyleName :: proc(font: ^Font) -> cstring ---

	GetFontDirection :: proc(font: ^Font) -> Direction ---

	StringToTag :: proc(string: cstring) -> u32 ---

	GetFontScript :: proc(font: ^Font) -> u32 ---

	GetGlyphScript        :: proc(ch: u32) -> u32 ---
	FontHasGlyph          :: proc(font: ^Font, ch: u32) -> bool ---
	GetGlyphImage         :: proc(font: ^Font, ch: u32, image_type: ^ImageType) -> ^SDL.Surface ---
	GetGlyphImageForIndex :: proc(font: ^Font, glyph_index: u32, image_type: ^ImageType) -> ^SDL.Surface ---

	RenderText_Solid           :: proc(font: ^Font, text: cstring, length: c.size_t, fg: SDL.Color) -> ^SDL.Surface ---
	RenderText_Solid_Wrapped   :: proc(font: ^Font, text: cstring, length: c.size_t, fg: SDL.Color, wrap_Length: c.int) -> ^SDL.Surface ---
	RenderGlyph_Solid          :: proc(font: ^Font, ch: u32, fg: SDL.Color) -> ^SDL.Surface ---
	RenderText_Shaded          :: proc(font: ^Font, text: cstring, length: c.size_t, fg, bg: SDL.Color) -> ^SDL.Surface ---
	RenderText_Shaded_Wrapped  :: proc(font: ^Font, text: cstring, length: c.size_t, fg, bg: SDL.Color, wrap_width: c.int) -> ^SDL.Surface ---
	RenderGlyph_Shaded         :: proc(font: ^Font, ch: u32, fg, bg: SDL.Color) -> ^SDL.Surface ---
	RenderText_Blended         :: proc(font: ^Font, text: cstring, length: c.size_t, fg: SDL.Color) -> ^SDL.Surface ---
	RenderText_Blended_Wrapped :: proc(font: ^Font, text: cstring, length: c.size_t, fg: SDL.Color, wrap_width: c.int) -> ^SDL.Surface ---
	RenderGlyph_Blended        :: proc(font: ^Font, ch: u32, fg: SDL.Color) -> ^SDL.Surface ---
	RenderText_LCD             :: proc(font: ^Font, text: cstring, length: c.size_t, fg, bg: SDL.Color) -> ^SDL.Surface ---
	RenderText_LCD_Wrapped     :: proc(font: ^Font, text: cstring, length: c.size_t, fg, bg: SDL.Color, wrap_width: c.int) -> ^SDL.Surface ---
	RenderGlyph_LCD            :: proc(font: ^Font, ch: u32, fg, bg: SDL.Color) -> ^SDL.Surface ---

	CreateSurfaceTextEngine :: proc() -> ^TextEngine ---

	CreateRendererTextEngine               :: proc(renderer: ^SDL.Renderer) -> ^TextEngine ---
	CreateRendererTextEngineWithProperties :: proc(props: SDL.PropertiesID) -> ^TextEngine ---

	CreateGPUTextEngine               :: proc(device: ^SDL.GPUDevice)  -> ^TextEngine ---
	CreateGPUTextEngineWithProperties :: proc(props: SDL.PropertiesID) -> ^TextEngine ---
	GetGPUTextDrawData                :: proc(text: ^Text) -> ^GPUAtlasDrawSequence ---
	SetGPUTextEngineWinding           :: proc(engine: ^TextEngine, winding: GPUTextEngineWinding) ---
	GetGPUTextEngineWinding           :: proc(#by_ptr engine: TextEngine) -> GPUTextEngineWinding ---

	CreateText                :: proc(engine: ^TextEngine, font: ^Font, text: cstring, length: c.size_t) -> ^Text ---
	GetTextProperties         :: proc(text: ^Text) -> SDL.PropertiesID ---
	GetTextEngine             :: proc(text: ^Text) -> ^TextEngine ---
	GetTextFont               :: proc(text: ^Text) -> ^Font ---
	GetTextDirection          :: proc(text: ^Text) -> Direction ---
	GetTextScript             :: proc(text: ^Text) -> u32 ---
	TextWrapWhitespaceVisible :: proc(text: ^Text) -> bool ---

	GetTextSubStringsForRange :: proc(text: ^Text, offset, length: c.int, count: ^c.int) -> [^]^SubString ---
}

@(default_calling_convention="c", link_prefix="TTF_")
foreign lib {
	GetFreeTypeVersion :: proc(major, minor, patch: ^c.int) ---
	GetHarfBuzzVersion :: proc(major, minor, patch: ^c.int) ---

	Init :: proc() -> bool ---

	AddFallbackFont    :: proc(font: ^Font, fallback: ^Font) -> bool ---
	RemoveFallbackFont :: proc(font: ^Font, fallback: ^Font) ---
	ClearFallbackFonts :: proc(font: ^Font) ---

	SetFontSize    :: proc(font: ^Font, ptsize: f32) -> bool ---
	SetFontSizeDPI :: proc(font: ^Font, ptsize: f32, hdpi: c.int, vdpi: c.int) -> bool ---
	GetFontDPI     :: proc(font: ^Font, hdpi: ^c.int, vdpi: ^c.int) -> bool ---

	SetFontDirection :: proc(font: ^Font, direction: Direction) -> bool ---

	TagToString :: proc(tag: u32, string: [^]c.char, size: c.size_t) ---

	SetFontScript :: proc(font: ^Font, script: u32) -> bool ---

	SetFontLanguage :: proc(font: ^Font, language_bcp47: cstring) -> bool ---

	GetGlyphMetrics :: proc(font: ^Font, ch: u32, minx, maxx, miny, maxy, advance: ^c.int) -> bool ---
	GetGlyphKerning :: proc(font: ^Font, previous_ch: u32, ch: u32, kerning: ^c.int) -> bool ---

	GetStringSize        :: proc(font: ^Font, text: cstring, length: c.size_t, w, h: ^c.int) -> bool ---
	GetStringSizeWrapped :: proc(font: ^Font, text: cstring, length: c.size_t, wrap_width: c.int, w, h: ^c.int) -> bool ---
	MeasureString        :: proc(font: ^Font, text: cstring, length: c.size_t, max_width: c.int, measured_width: ^c.int, measured_length: ^c.size_t) -> bool ---

	DrawSurfaceText           :: proc(text: ^Text, x, y: c.int, surface: ^SDL.Surface) -> bool ---
	DestroySurfaceTextEngine  :: proc(engine: ^TextEngine) ---

	DrawRendererText          :: proc(text: ^Text, x, y: f32) -> bool ---
	DestroyRendererTextEngine :: proc(engine: ^TextEngine) ---

	DestroyGPUTextEngine      :: proc(engine: ^TextEngine) ---

	SetTextEngine                :: proc(text: ^Text, engine: ^TextEngine) -> bool ---
	SetTextFont                  :: proc(text: ^Text, font: ^Font) -> bool ---
	SetTextDirection             :: proc(text: ^Text, direction: Direction) -> bool ---
	SetTextScript                :: proc(text: ^Text, script: u32) -> bool ---
	SetTextColor                 :: proc(text: ^Text, r, g, b, a: u8) -> bool ---
	SetTextColorFloat            :: proc(text: ^Text, r, g, b, a: f32) -> bool ---
	GetTextColor                 :: proc(text: ^Text, r, g, b, a: ^u8) -> bool ---
	GetTextColorFloat            :: proc(text: ^Text, r, g, b, a: ^f32) -> bool ---
	SetTextPosition              :: proc(text: ^Text, x, y: c.int) -> bool ---
	GetTextPosition              :: proc(text: ^Text, x, y: ^c.int) -> bool ---
	SetTextWrapWidth             :: proc(text: ^Text, wrap_width: c.int) -> bool ---
	GetTextWrapWidth             :: proc(text: ^Text, wrap_width: ^c.int) -> bool ---
	SetTextWrapWhitespaceVisible :: proc(text: ^Text, visible: bool) -> bool ---

	SetTextString    :: proc(text: ^Text, string: cstring, length: c.size_t) -> bool ---
	InsertTextString :: proc(text: ^Text, offset: c.int, string: cstring, length: c.size_t) -> bool ---
	AppendTextString :: proc(text: ^Text, string: cstring, length: c.size_t) -> bool ---
	DeleteTextString :: proc(text: ^Text, offset, length: c.int) -> bool ---

	GetTextSize :: proc(text: ^Text, w, h: ^c.int) -> bool ---

	GetTextSubString          :: proc(text: ^Text, offset: c.int, substring: ^SubString) -> bool ---
	GetTextSubStringForLine   :: proc(text: ^Text, line: c.int, substring: ^SubString) -> bool ---
	GetTextSubStringForPoint  :: proc(text: ^Text, x, y: c.int, substring: ^SubString) -> bool ---
	GetPreviousTextSubString  :: proc(text: ^Text, #by_ptr substring: SubString, previous: ^SubString) -> bool ---
	GetNextTextSubString      :: proc(text: ^Text, #by_ptr substring: SubString, next: ^SubString) -> bool ---

	UpdateText  :: proc(text: ^Text) -> bool ---
	DestroyText :: proc(text: ^Text) ---
	CloseFont   :: proc(font: ^Font) ---
	Quit        :: proc() ---
}
