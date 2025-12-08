// Bindings for [[ Jimmy Lefevre's Text Shape ; https://github.com/JimmyLefevre/kb ]] Unicode text segmentation and OpenType shaping.
package vendor_kb_text_shape

when ODIN_OS == .Windows {
	foreign import lib {
		"lib/kb_text_shape.lib",
	}
} else {
	foreign import lib {
		"lib/kb_text_shape.a",
	}
}

import "core:c"

//
// Context API
// The context can do everything for you. It is pretty convenient!
//
@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	SizeOfShapeContext             :: proc() -> c.int ---
	PlaceShapeContext              :: proc(Allocator: allocator_function, AllocatorData: rawptr, Memory: rawptr) -> ^shape_context ---
	PlaceShapeContextFixedMemory   :: proc(Memory: rawptr, Size: c.int) -> ^shape_context ---
	CreateShapeContext             :: proc(Allocator: allocator_function, AllocatorData: rawptr) -> ^shape_context ---
	DestroyShapeContext            :: proc(Context: ^shape_context) ---
	ShapePushFontFromMemory        :: proc(Context: ^shape_context, Memory: rawptr, Size: c.int, FontIndex: c.int) -> ^font ---
	ShapePushFont                  :: proc(Context: ^shape_context, Font: ^font) -> ^font ---
	ShapePopFont                   :: proc(Context: ^shape_context) -> ^font ---
	ShapeBegin                     :: proc(Context: ^shape_context, ParagraphDirection: direction, Language: language) ---
	ShapeEnd                       :: proc(Context: ^shape_context) ---
	ShapePushFeature               :: proc(Context: ^shape_context, FeatureTag: u32, Value: c.int) ---
	ShapePopFeature                :: proc(Context: ^shape_context, FeatureTag: u32) -> b32 ---
	ShapeCodepoint                 :: proc(Context: ^shape_context, Codepoint: rune) ---
	ShapeCodepointWithUserId       :: proc(Context: ^shape_context, Codepoint: rune, UserId: c.int) ---
	ShapeError                     :: proc(Context: ^shape_context) -> shape_error ---
	ShapeBeginManualRuns           :: proc(Context: ^shape_context) ---
	ShapeNextManualRun             :: proc(Context: ^shape_context, Direction: direction, Script: script) ---
	ShapeEndManualRuns             :: proc(Context: ^shape_context) ---
	ShapeManualBreak               :: proc(Context: ^shape_context) ---
}

@(require_results)
ShapeRun :: proc "contextless" (Context: ^shape_context) -> (Run: run, ok: b32) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeRun :: proc(Context: ^shape_context, Run: ^run) -> b32 ---
	}
	ok = ShapeRun(Context, &Run)
	return
}

ShapeUtf32 :: proc "c" (Context: ^shape_context, Utf32: []rune) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeUtf32 :: proc(Context: ^shape_context, Utf32: [^]rune, Length: c.int) ---
	}
	ShapeUtf32(Context, raw_data(Utf32), c.int(len(Utf32)))
}
ShapeUtf32WithUserId :: proc "c" (Context: ^shape_context, Utf32: []rune, UserId: c.int, UserIdIncrement: c.int) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeUtf32WithUserId :: proc(Context: ^shape_context, Utf32: [^]rune, Length: c.int, UserId: c.int, UserIdIncrement: c.int) ---
	}
	ShapeUtf32WithUserId(Context, raw_data(Utf32), c.int(len(Utf32)), UserId, UserIdIncrement)
}

ShapeUtf8 :: proc(Context: ^shape_context, Utf8: string, UserIdGenerationMode: user_id_generation_mode) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeUtf8 :: proc(Context: ^shape_context, Utf8: [^]byte, Length: c.int, UserIdGenerationMode: user_id_generation_mode) ---
	}
	ShapeUtf8(Context, raw_data(Utf8), c.int(len(Utf8)), UserIdGenerationMode)
}
ShapeUtf8WithUserId :: proc(Context: ^shape_context, Utf8: string, UserId: c.int, UserIdGenerationMode: user_id_generation_mode) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeUtf8WithUserId :: proc(Context: ^shape_context, Utf8: [^]byte, Length: c.int, UserId: c.int, UserIdGenerationMode: user_id_generation_mode) ---
	}
	ShapeUtf8WithUserId(Context, raw_data(Utf8), c.int(len(Utf8)), UserId, UserIdGenerationMode)
}


@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	ShapeCurrentCodepointsIterator :: proc(Context: ^shape_context) -> shape_codepoint_iterator ---
	ShapeCodepointIteratorIsValid  :: proc(It: ^shape_codepoint_iterator) -> b32 ---
	ShapeGetShapeCodepoint         :: proc(Context: ^shape_context, CodepointIndex: c.int, Codepoint: ^shape_codepoint) -> b32 ---
}

@(require_results)
ShapeCodepointIteratorNext :: proc "contextless" (It: ^shape_codepoint_iterator) -> (Codepoint: shape_codepoint, CodepointIndex: c.int, ok: b32) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeCodepointIteratorNext :: proc(It: ^shape_codepoint_iterator, Codepoint: ^shape_codepoint, CodepointIndex: ^c.int) -> b32 ---
	}
	ok = ShapeCodepointIteratorNext(It, &Codepoint, &CodepointIndex)
	return
}



//
// Direct API
//
@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	FontCount                         :: proc(FileData: rawptr, FileSize: c.int) -> b32 ---
	FontFromMemory                    :: proc(FileData: rawptr, FileSize: c.int, FontIndex: c.int, Allocator: allocator_function, AllocatorData: rawptr) -> font ---
	FreeFont                          :: proc(Font: ^font) ---
	FontIsValid                       :: proc(Font: ^font) -> b32 ---
	LoadFont                          :: proc(Font: ^font, State: ^load_font_state, FontData: rawptr, FontDataSize: c.int, FontIndex: c.int, ScratchSize_: ^c.int, OutputSize_: ^c.int) -> load_font_error ---
	PlaceBlob                         :: proc(Font: ^font, State: ^load_font_state, ScratchMemory: rawptr, OutputMemory: rawptr) -> load_font_error ---
	GetFontInfo                       :: proc(Font: ^font, Info: ^font_info) ---

	// A shape_config is a bag of pre-computed data for a specific shaping setup.
	SizeOfShapeConfig                 :: proc(Font: ^font, Script: script, Language: language) -> b32 ---
	PlaceShapeConfig                  :: proc(Font: ^font, Script: script, Language: language, Memory: rawptr) -> ^shape_config ---
	CreateShapeConfig                 :: proc(Font: ^font, Script: script, Language: language, Allocator: allocator_function, AllocatorData: rawptr) -> ^shape_config ---
	DestroyShapeConfig                :: proc(Config: ^shape_config) ---

	// A glyph_storage holds and recycles glyph data.
	InitializeGlyphStorage            :: proc(Storage: ^glyph_storage, Allocator: allocator_function, AllocatorData: rawptr) -> b32 ---
	InitializeGlyphStorageFixedMemory :: proc(Storage: ^glyph_storage, Memory: rawptr, MemorySize: c.int) -> b32 ---
	PushGlyph                         :: proc(Storage: ^glyph_storage, Font: ^font, Codepoint: rune, Config: ^glyph_config, UserId: c.int) -> ^glyph ---
	ClearActiveGlyphs                 :: proc(Storage: ^glyph_storage) ---
	FreeAllGlyphs                     :: proc(Storage: ^glyph_storage) ---
	CodepointToGlyph                  :: proc(Font: ^font, Codepoint: rune, Config: ^glyph_config, UserId: c.int) -> glyph ---
	CodepointToGlyphId                :: proc(Font: ^font, Codepoint: rune) -> c.int ---
	ActiveGlyphIterator               :: proc(Storage: ^glyph_storage) -> glyph_iterator ---

	// A glyph_config specifies glyph-specific shaping parameters.
	// A single glyph_config can be shared by multiple glyphs.

	DestroyGlyphConfig                :: proc(Config: ^glyph_config) ---
}


@(require_results)
ShapeDirect :: proc "contextless" (Config: ^shape_config, Storage: ^glyph_storage, RunDirection: direction, Allocator: allocator_function, AllocatorData: rawptr) -> (Output: glyph_iterator, err: shape_error) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeDirect :: proc(Config: ^shape_config, Storage: ^glyph_storage, RunDirection: direction, Allocator: allocator_function, AllocatorData: rawptr, Output: ^glyph_iterator) -> shape_error ---
	}
	err = ShapeDirect(Config, Storage, RunDirection, Allocator, AllocatorData, &Output)
	return
}

@(require_results)
ShapeDirectFixedMemory :: proc "contextless" (Config: ^shape_config, Storage: ^glyph_storage, RunDirection: direction, Memory: rawptr, MemorySize: c.int) -> (Output: glyph_iterator, err: shape_error) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		ShapeDirectFixedMemory :: proc(Config: ^shape_config, Storage: ^glyph_storage, RunDirection: direction, Memory: rawptr, MemorySize: c.int, Output: ^glyph_iterator) -> shape_error ---
	}
	err = ShapeDirectFixedMemory(Config, Storage, RunDirection, Memory, MemorySize, &Output)
	return
}


@(require_results)
SizeOfGlyphConfig :: proc "c" (Overrides: []feature_override) -> c.int {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		SizeOfGlyphConfig :: proc(Overrides: [^]feature_override, OverrideCount: c.int) -> c.int ---
	}
	return SizeOfGlyphConfig(raw_data(Overrides), c.int(len(Overrides)))
}

@(require_results)
PlaceGlyphConfig :: proc "c" (Overrides: []feature_override, Memory: rawptr) -> ^glyph_config {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		PlaceGlyphConfig :: proc(Overrides: [^]feature_override, OverrideCount: c.int, Memory: rawptr) -> ^glyph_config ---
	}
	return PlaceGlyphConfig(raw_data(Overrides), c.int(len(Overrides)), Memory)
}

@(require_results)
CreateGlyphConfig :: proc(Overrides: []feature_override, Allocator: allocator_function, AllocatorData: rawptr) -> ^glyph_config {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		CreateGlyphConfig :: proc(Overrides: [^]feature_override, OverrideCount: c.int, Allocator: allocator_function, AllocatorData: rawptr) -> ^glyph_config ---
	}
	return CreateGlyphConfig(raw_data(Overrides), c.int(len(Overrides)), Allocator, AllocatorData)
}

@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	GlyphIteratorIsValid :: proc(It: ^glyph_iterator) -> b32 ---
}

@(require_results)
GlyphIteratorNext :: proc "contextless" (It: ^glyph_iterator) -> (Glyph: ^glyph, ok: b32) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		GlyphIteratorNext :: proc(It: ^glyph_iterator, Glyph: ^^glyph) -> b32 ---
	}
	ok = GlyphIteratorNext(It, &Glyph)
	return
}


//
// Segmentation
//
@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	BreakBegin        :: proc(State: ^break_state, ParagraphDirection: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags) ---
	BreakAddCodepoint :: proc(State: ^break_state, Codepoint: rune, PositionIncrement: c.int, EndOfText: c.int) ---
	BreakEnd          :: proc(State: ^break_state) ---
}

@(require_results)
Break :: proc "contextless" (State: ^break_state) -> (Break: break_type, ok: b32) {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_Break :: proc(State: ^break_state, Break: ^break_type) -> b32 ---
	}
	ok = kbts_Break(State, &Break)
	return
}


BreakEntireString :: proc "c" (Direction: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags,
                               Input: []byte, InputFormat: text_format,
                               Breaks: []break_type, BreakCount: ^c.int,
                               BreakFlags: []break_flags, BreakFlagCount: ^c.int) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		BreakEntireString :: proc(Direction: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags,
		                          Input: rawptr, InputSizeInBytes: c.int, InputFormat: text_format,
		                          Breaks: [^]break_type, BreakCapacity: c.int, BreakCount: ^c.int,
		                          BreakFlags: [^]break_flags, BreakFlagCapacity: c.int, BreakFlagCount: ^c.int) ---
	}
	BreakEntireString(Direction, JapaneseLineBreakStyle, ConfigFlags, raw_data(Input), c.int(len(Input)), InputFormat, raw_data(Breaks), c.int(len(Breaks)), BreakCount, raw_data(BreakFlags), c.int(len(BreakFlags)), BreakFlagCount)
}

BreakEntireStringUtf32 :: proc "c" (Direction: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags,
                                    Utf32: []rune,
                                    Breaks: []break_type, BreakCount: ^c.int,
                                    BreakFlags: []break_flags, BreakFlagCount: ^c.int) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		BreakEntireStringUtf32 :: proc(Direction: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags,
		                               Utf32: [^]rune, Utf32Count: c.int,
		                               Breaks: [^]break_type, BreakCapacity: c.int, BreakCount: ^c.int,
		                               BreakFlags: [^]break_flags, BreakFlagCapacity: c.int, BreakFlagCount: ^c.int) ---
	}
	BreakEntireStringUtf32(Direction, JapaneseLineBreakStyle, ConfigFlags, raw_data(Utf32), c.int(len(Utf32)), raw_data(Breaks), c.int(len(Breaks)), BreakCount, raw_data(BreakFlags), c.int(len(BreakFlags)), BreakFlagCount)
}

BreakEntireStringUtf8 :: proc "c" (Direction: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags,
                                   Utf8: string,
                                   Breaks: []break_type, BreakCount: ^c.int,
                                   BreakFlags: []break_flags, BreakFlagCount: ^c.int) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		BreakEntireStringUtf8 :: proc(Direction: direction, JapaneseLineBreakStyle: japanese_line_break_style, ConfigFlags: break_config_flags,
		                              Utf8: [^]byte, Utf8Length: c.int,
		                              Breaks: [^]break_type, BreakCapacity: c.int, BreakCount: ^c.int,
		                              BreakFlags: [^]break_flags, BreakFlagCapacity: c.int, BreakFlagCount: ^c.int) ---
	}
	BreakEntireStringUtf8(Direction, JapaneseLineBreakStyle, ConfigFlags, raw_data(Utf8), c.int(len(Utf8)), raw_data(Breaks), c.int(len(Breaks)), BreakCount, raw_data(BreakFlags), c.int(len(BreakFlags)), BreakFlagCount)
}



@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	// Quick test for font support of a sequence of codepoints.
	FontCoverageTestBegin     :: proc(Test: ^font_coverage_test, Font: ^font) ---
	FontCoverageTestCodepoint :: proc(Test: ^font_coverage_test, Codepoint: rune) ---
	FontCoverageTestEnd       :: proc(Test: ^font_coverage_test) -> b32  ---

	EncodeUtf8                :: proc(Codepoint: rune) -> encode_utf8 ---
	ScriptDirection           :: proc(Script: script) -> direction ---
	ScriptIsComplex           :: proc(Script: script) -> b32 ---
	ScriptTagToScript         :: proc(Tag: script_tag) -> script ---
}

@(require_results)
DecodeUtf8 :: proc "c" (Utf8: string) -> decode {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		DecodeUtf8 :: proc(Utf8: [^]byte, Length: un) -> decode ---
	}
	return DecodeUtf8(raw_data(Utf8), un(len(Utf8)))
}

// This is a quick guess that stops at the first glyph that has a strong script/direction associated to it.
// It is convenient, but only works if you are sure your input text is mono-script and mono-direction.
@(require_results)
GuessTextProperties :: proc "contextless" (Text: []byte, Format: text_format) -> (Direction: direction, Script: script) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		GuessTextProperties :: proc(Text: rawptr, TextSizeInBytes: c.int, Format: text_format, Direction: ^direction, Script: ^script) ---
	}
	GuessTextProperties(raw_data(Text), c.int(len(Text)), Format, &Direction, &Script)
	return
}

// This is a quick guess that stops at the first glyph that has a strong script/direction associated to it.
// It is convenient, but only works if you are sure your input text is mono-script and mono-direction.
@(require_results)
GuessTextPropertiesUtf32 :: proc "contextless" (Utf32: []rune) -> (Direction: direction, Script: script) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		GuessTextPropertiesUtf32 :: proc(Utf32: [^]rune, Utf32Count: c.int, Direction: ^direction, Script: ^script) ---
	}
	GuessTextPropertiesUtf32(raw_data(Utf32), c.int(len(Utf32)), &Direction, &Script)
	return
}

// This is a quick guess that stops at the first glyph that has a strong script/direction associated to it.
// It is convenient, but only works if you are sure your input text is mono-script and mono-direction._results)
@(require_results)
GuessTextPropertiesUtf8 :: proc "contextless" (Utf8: string) -> (Direction: direction, Script: script) {
	@(default_calling_convention="c", link_prefix="kbts_", require_results)
	foreign lib {
		GuessTextPropertiesUtf8 :: proc(Utf8: cstring, Utf8Length: c.int, Direction: ^direction, Script: ^script) ---
	}
	GuessTextPropertiesUtf8(cstring(raw_data(Utf8)), c.int(len(Utf8)), &Direction, &Script)
	return
}