// Bindings for [[ SDL2 TTF ; https://wiki.libsdl.org/SDL2/FrontPage ]].
package sdl2_ttf

import "core:c"
import SDL ".."

when ODIN_OS == .Windows {
	foreign import lib "SDL2_ttf.lib"
} else {
	foreign import lib "system:SDL2_ttf"
}

bool :: SDL.bool

#assert(size_of(rune) == size_of(u32))

MAJOR_VERSION :: 2
MINOR_VERSION :: 0
PATCHLEVEL    :: 18

UNICODE_BOM_NATIVE  :: 0xFEFF
UNICODE_BOM_SWAPPED :: 0xFFFE

Font :: struct {}

StyleFlag :: enum c.int {
	BOLD          = 0,
	ITALIC        = 1,
	UNDERLINE     = 2,
	STRIKETHROUGH = 3,
}

Style :: distinct bit_set[StyleFlag; c.int]

STYLE_NORMAL        :: Style{}
STYLE_BOLD          :: Style{.BOLD}
STYLE_ITALIC        :: Style{.ITALIC}
STYLE_UNDERLINE     :: Style{.UNDERLINE}
STYLE_STRIKETHROUGH :: Style{.STRIKETHROUGH}

Hinting :: enum c.int {
	NORMAL         = 0,
	LIGHT          = 1,
	MONO           = 2,
	NONE           = 3,
	LIGHT_SUBPIXEL = 4,
}

HINTING_NORMAL         :: Hinting.NORMAL
HINTING_LIGHT          :: Hinting.LIGHT
HINTING_MONO           :: Hinting.MONO
HINTING_NONE           :: Hinting.NONE
HINTING_LIGHT_SUBPIXEL :: Hinting.LIGHT_SUBPIXEL

/* We'll use SDL for reporting errors */
SetError :: SDL.SetError
GetError :: SDL.GetError

/* For compatibility with previous versions, here are the old functions */
RenderText :: #force_inline proc "c" (font: ^Font, text: cstring, fg, bg: SDL.Color) -> ^SDL.Surface {
	return RenderText_Shaded(font, text, fg, bg)
}
RenderUTF8 :: #force_inline proc "c" (font: ^Font, text: cstring, fg, bg: SDL.Color) -> ^SDL.Surface {
	return RenderUTF8_Shaded(font, text, fg, bg)
}
RenderUNICODE :: #force_inline proc "c" (font: ^Font, text: [^]u16, fg, bg: SDL.Color)  -> ^SDL.Surface {
	return RenderUNICODE_Shaded(font, text, fg, bg)
}

@(default_calling_convention="c", link_prefix="TTF_")
foreign lib {
	Linked_Version :: proc() -> ^SDL.version ---

	Init :: proc() -> c.int ---
	Quit :: proc() ---
	WasInit :: proc() -> c.int ---

	OpenFont           :: proc(file: cstring, ptsize: c.int) -> ^Font ---
	OpenFontIndex      :: proc(file: cstring, ptsize: c.int, index: c.long) -> ^Font ---
	OpenFontRW         :: proc(src: ^SDL.RWops, freesrc: bool, ptsize: c.int) -> ^Font ---
	OpenFontIndexRW    :: proc(src: ^SDL.RWops, freesrc: bool, ptsize: c.int, index: c.long) -> ^Font ---

	OpenFontDPI        :: proc(file: cstring, ptsize: c.int, hdpi, vdpi: c.uint) -> ^Font ---
	OpenFontIndexDPI   :: proc(file: cstring, ptsize: c.int, index: c.long, hdpi, vdpi: c.uint) -> ^Font ---
	OpenFontDPIRW      :: proc(src: ^SDL.RWops, freesrc: bool, ptsize: c.int, hdpi, vdpi: c.uint) -> ^Font ---
	OpenFontIndexDPIRW :: proc(src: ^SDL.RWops, freesrc: bool, ptsize: c.int, index: c.long, hdpi, vdpi: c.uint) -> ^Font ---

	SetFontSize    :: proc(font: ^Font, ptsize: c.int) -> c.int ---
	SetFontSizeDPI :: proc(font: ^Font, ptsize: c.int, hdpi, vdpi: c.uint) -> c.int ---

	GetFontStyle   :: proc(font: ^Font) -> Style ---
	SetFontStyle   :: proc(font: ^Font, style: Style) ---
	GetFontOutline :: proc(font: ^Font) -> c.int ---
	SetFontOutline :: proc(font: ^Font, outline: c.int) ---

	GetFontHinting :: proc(font: ^Font) -> Hinting ---
	SetFontHinting :: proc(font: ^Font, hinting: Hinting) ---

	FontHeight           :: proc(font: ^Font) -> c.int ---
	FontAscent           :: proc(font: ^Font) -> c.int ---
	FontDescent          :: proc(font: ^Font) -> c.int ---
	FontLineSkip         :: proc(font: ^Font) -> c.int ---
	GetFontKerning       :: proc(font: ^Font) -> c.int ---
	SetFontKerning       :: proc(font: ^Font, allowed: bool) ---
	FontFaces            :: proc(font: ^Font) -> c.long ---
	FontFaceIsFixedWidth :: proc(font: ^Font) -> c.int ---
	FontFaceFamilyName   :: proc(font: ^Font) -> cstring ---
	FontFaceStyleName    :: proc(font: ^Font) -> cstring ---

	GlyphIsProvided   :: proc(font: ^Font, ch: u16) -> c.int ---
	GlyphIsProvided32 :: proc(font: ^Font, ch: rune) -> c.int ---
	GlyphMetrics      :: proc(font: ^Font, ch: u16, minx, maxx, miny, maxy: ^c.int, advance: ^c.int) -> c.int ---
	GlyphMetrics32    :: proc(font: ^Font, ch: rune, minx, maxx, miny, maxy: ^c.int, advance: ^c.int) -> c.int ---

	SizeText    :: proc(font: ^Font, text: cstring, w, h: ^c.int) -> c.int ---
	SizeUTF8    :: proc(font: ^Font, text: cstring, w, h: ^c.int) -> c.int ---
	SizeUNICODE :: proc(font: ^Font, text: [^]u16, w, h: ^c.int) -> c.int ---

	MeasureText    :: proc(font: ^Font, text: cstring, measure_width: c.int, extent: ^c.int, count: ^c.int) -> c.int ---
	MeasureUTF8    :: proc(font: ^Font, text: cstring, measure_width: c.int, extent: ^c.int, count: ^c.int) -> c.int ---
	MeasureUNICODE :: proc(font: ^Font, text: [^]u16,  measure_width: c.int, extent: ^c.int, count: ^c.int) -> c.int ---

	RenderText_Solid    :: proc(font: ^Font, text: cstring, fg: SDL.Color) -> ^SDL.Surface ---
	RenderUTF8_Solid    :: proc(font: ^Font, text: cstring, fg: SDL.Color) -> ^SDL.Surface ---
	RenderUNICODE_Solid :: proc(font: ^Font, text: [^]u16,  fg: SDL.Color) -> ^SDL.Surface ---

	RenderText_Solid_Wrapped    :: proc(font: ^Font, text: cstring, fg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---
	RenderUTF8_Solid_Wrapped    :: proc(font: ^Font, text: cstring, fg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---
	RenderUNICODE_Solid_Wrapped :: proc(font: ^Font, text: [^]u16,  fg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---

	RenderGlyph_Solid   :: proc(font: ^Font, ch: u16, fg: SDL.Color) -> ^SDL.Surface ---
	RenderGlyph32_Solid :: proc(font: ^Font, ch: rune, fg: SDL.Color) -> ^SDL.Surface ---

	RenderText_Shaded    :: proc(font: ^Font, text: cstring, fg, bg: SDL.Color) -> ^SDL.Surface ---
	RenderUTF8_Shaded    :: proc(font: ^Font, text: cstring, fg, bg: SDL.Color) -> ^SDL.Surface ---
	RenderUNICODE_Shaded :: proc(font: ^Font, text: [^]u16,  fg, bg: SDL.Color) -> ^SDL.Surface ---

	RenderText_Shaded_Wrapped    :: proc(font: ^Font, text: cstring, fg, bg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---
	RenderUTF8_Shaded_Wrapped    :: proc(font: ^Font, text: cstring, fg, bg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---
	RenderUNICODE_Shaded_Wrapped :: proc(font: ^Font, text: [^]u16,  fg, bg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---

	RenderGlyph_Shaded   :: proc(font: ^Font, ch: u16,  fg, bg: SDL.Color) -> ^SDL.Surface ---
	RenderGlyph32_Shaded :: proc(font: ^Font, ch: rune, fg, bg: SDL.Color) -> ^SDL.Surface ---

	RenderText_Blended    :: proc(font: ^Font, text: cstring, fg: SDL.Color) -> ^SDL.Surface ---
	RenderUTF8_Blended    :: proc(font: ^Font, text: cstring, fg: SDL.Color) -> ^SDL.Surface ---
	RenderUNICODE_Blended :: proc(font: ^Font, text: [^]u16,  fg: SDL.Color) -> ^SDL.Surface ---


	RenderText_Blended_Wrapped    :: proc(font: ^Font, text: cstring, fg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---
	RenderUTF8_Blended_Wrapped    :: proc(font: ^Font, text: cstring, fg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---
	RenderUNICODE_Blended_Wrapped :: proc(font: ^Font, text: [^]u16,  fg: SDL.Color, wrapLength: u32) -> ^SDL.Surface ---

	RenderGlyph_Blended   :: proc(font: ^Font, ch: u16, fg: SDL.Color) -> ^SDL.Surface ---
	RenderGlyph32_Blended :: proc(font: ^Font, ch: rune, fg: SDL.Color) -> ^SDL.Surface ---


	SetDirection :: proc(direction: c.int /* hb_direction_t */) -> c.int ---
	SetScript    :: proc(script:    c.int /* hb_script_t    */) -> c.int ---

	CloseFont :: proc(font: ^Font) ---

	GetFontKerningSizeGlyphs   :: proc(font: ^Font, previous_ch, ch: u16) -> c.int ---
	GetFontKerningSizeGlyphs32 :: proc(font: ^Font, previous_ch, ch: rune) -> c.int ---

	SetFontSDF :: proc(font: ^Font, on_off: bool) -> c.int ---
	GetFontSDF :: proc(font: ^Font) -> bool ---
}
