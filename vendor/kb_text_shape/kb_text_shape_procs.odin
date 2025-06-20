package vendor_kb_text_shape

when ODIN_OS == .Windows {
	foreign import lib {
		"lib/kb_text_shape.lib",
	}
} else {
	foreign import lib {
		"kb_text_shape.a"
	}
}

import "core:c"

#assert(size_of(c.int) == size_of(b32))
#assert(size_of(u32)   == size_of(b32))

@(default_calling_convention="c", link_prefix="kbts_")
foreign lib {
	// when !TEXT_SHAPE_NO_CRT {
	FontFromFile     :: proc(FileName: cstring) -> font ---
	FreeFont         :: proc(Font: ^font) ---
	CreateShapeState :: proc(Font: ^font) -> ^shape_state ---
	FreeShapeState   :: proc(State: ^shape_state) ---
	// }

	FontIsValid            :: proc(Font: ^font) -> int ---
	ReadFontHeader         :: proc(Font: ^font, Data:    rawptr, Size:        un) -> un ---
	ReadFontData           :: proc(Font: ^font, Scratch: rawptr, ScratchSize: un) -> un ---
	PostReadFontInitialize :: proc(Font: ^font, Memory:  rawptr, MemorySize:  un) -> int ---
	SizeOfShapeState       :: proc(Font: ^font) -> un ---
	PlaceShapeState        :: proc(Address: rawptr, Size: un) -> ^shape_state ---
	ResetShapeState        :: proc(State: ^shape_state) ---
	ShapeConfig            :: proc(Font: ^font, Script: u32, Language: u32) -> shape_config ---
	ShaperIsComplex        :: proc(Shaper: shaper) -> b32 ---
	Shape                  :: proc(State: ^shape_state, Config: ^shape_config, MainDirection, RunDirection: direction, Glyphs: [^]glyph, GlyphCount: ^u32, GlyphCapacity: u32) -> c.int ---
	Cursor                 :: proc(Direction: direction) -> cursor  ---
	PositionGlyph          :: proc(Cursor: ^cursor, Glyph: ^glyph, X, Y: ^i32) ---
	BeginBreak             :: proc(State: ^break_state, MainDirection: direction, JapaneseLineBreakStyle: japanese_line_break_style) ---
	BreakStateIsValid      :: proc(State: ^break_state) -> c.int ---
	BreakAddCodepoint      :: proc(State: ^break_state, Codepoint: rune, PositionIncrement: u32, EndOfText: c.int) ---
	BreakFlush             :: proc(State: ^break_state) ---
	Break                  :: proc(State: ^break_state, Break: ^break_type) -> c.int ---
	DecodeUtf8             :: proc(Utf8: [^]byte, Length: uint) -> decode ---
	CodepointToGlyph       :: proc(Font: ^font, Codepoint: rune) -> glyph ---
	InferScript            :: proc(Direction: ^direction, Script: ^script, GlyphScript: script) ---
	ScriptIsComplex        :: proc(Script: script) -> b32 ---
}