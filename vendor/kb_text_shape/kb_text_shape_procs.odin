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

import "core:mem"

@(default_calling_convention="c", link_prefix="kbts_", require_results)
foreign lib {
	FeatureTagToId                    :: proc(Tag: feature_tag) -> feature_id ---
	FeatureOverride                   :: proc(Id: feature_id,  Alternate: b32, Value: u32) -> feature_override ---
	FeatureOverrideFromTag            :: proc(Tag: feature_tag, Alternate: b32, Value: u32) -> feature_override ---
	GlyphConfigOverrideFeature        :: proc(Config: ^glyph_config, Id:  feature_id,  Alternate: b32, Value: u32) -> b32 ---
	GlyphConfigOverrideFeatureFromTag :: proc(Config: ^glyph_config, Tag: feature_tag, Alternate: b32, Value: u32) -> b32 ---

	FontIsValid       :: proc(Font: ^font) -> b32 ---
	SizeOfShapeState  :: proc(Font: ^font) -> un ---

	ResetShapeState   :: proc(State: ^shape_state) ---

	ShapeConfig       :: proc(Font: ^font, Script: script, Language: language) -> shape_config ---
	ShaperIsComplex   :: proc(Shaper: shaper) -> b32 ---
	ScriptTagToScript :: proc(Tag: script_tag) -> script ---

	Shape             :: proc(State: ^shape_state, Config: ^shape_config,
	                          MainDirection, RunDirection: direction,
	                          Glyphs: [^]glyph, GlyphCount: ^u32, GlyphCapacity: u32) -> b32 ---

	Cursor            :: proc(Direction: direction) -> cursor  ---
	BeginBreak        :: proc(State: ^break_state, MainDirection: direction, JapaneseLineBreakStyle: japanese_line_break_style) ---
	BreakStateIsValid :: proc(State: ^break_state) -> b32 ---
	BreakAddCodepoint :: proc(State: ^break_state, Codepoint: rune, PositionIncrement: u32, EndOfText: b32) ---
	BreakFlush        :: proc(State: ^break_state) ---
	Break             :: proc(State: ^break_state, Break: ^break_type) -> b32 ---
	CodepointToGlyph  :: proc(Font: ^font, Codepoint: rune) -> glyph ---
	InferScript       :: proc(Direction: ^direction, Script: ^script, GlyphScript: script) ---
}


@(require_results)
GlyphConfig :: proc "c" (FeatureOverrides: []feature_override) -> glyph_config {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_GlyphConfig :: proc(FeatureOverrides: [^]feature_override, FeatureOverrideCount: u32) -> glyph_config ---
	}
	return kbts_GlyphConfig(raw_data(FeatureOverrides), u32(len(FeatureOverrides)))

}

@(require_results)
EmptyGlyphConfig :: proc(FeatureOverrides: []feature_override) -> glyph_config {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_EmptyGlyphConfig :: proc(FeatureOverrides: [^]feature_override, FeatureOverrideCapacity: u32) -> glyph_config ---
	}
	return kbts_EmptyGlyphConfig(raw_data(FeatureOverrides), u32(len(FeatureOverrides)))
}

@(require_results)
PlaceShapeState :: proc "c" (Memory: []byte) -> ^shape_state {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_PlaceShapeState :: proc(Address: rawptr, Size: un) -> ^shape_state ---
	}

	return kbts_PlaceShapeState(raw_data(Memory), un(len(Memory)))
}

@(require_results)
DecodeUtf8 :: proc "contextless" (String: string) -> (Codepoint: rune, SourceCharactersConsumed: u32, Valid: bool) {
	decode :: struct {
		Codepoint: rune,

		SourceCharactersConsumed: u32,
		Valid:                    b32,
	}

	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_DecodeUtf8 :: proc(Utf8: [^]byte, Length: un) -> decode ---
	}

	Decode := kbts_DecodeUtf8(raw_data(String), un(len(String)))
	return Decode.Codepoint, Decode.SourceCharactersConsumed, bool(Decode.Valid)
}


@(require_results)
ReadFontHeader :: proc "c" (Font: ^font, Data: []byte) -> un {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_ReadFontHeader :: proc(Font: ^font, Data: rawptr, Size: un) -> un ---
	}

	return kbts_ReadFontHeader(Font, raw_data(Data), un(len(Data)))
}
@(require_results)
ReadFontData :: proc "c" (Font: ^font, Scratch: []byte) -> un {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_ReadFontData :: proc(Font: ^font, Scratch: rawptr, ScratchSize: un) -> un ---
	}

	return kbts_ReadFontData(Font, raw_data(Scratch), un(len(Scratch)))
}
@(require_results)
PostReadFontInitialize :: proc "c" (Font: ^font, Memory: []byte) -> b32 {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_PostReadFontInitialize :: proc(Font: ^font, Memory: rawptr, MemorySize: un) -> b32 ---
	}

	return kbts_PostReadFontInitialize(Font, raw_data(Memory), un(len(Memory)))
}

@(require_results)
FontFromMemory :: proc(Data: []byte, allocator: mem.Allocator) -> (Result: font, Err: mem.Allocator_Error) {
	ClonedData := mem.make_aligned([]byte, len(Data), 16, allocator) or_return
	defer if Err != nil {
		delete(ClonedData, allocator)
	}
	copy(ClonedData, Data)

	ScratchSize := ReadFontHeader(&Result, ClonedData)
	Scratch := mem.make_aligned([]byte, ScratchSize, 16, allocator) or_return
	MemorySize := ReadFontData(&Result, Scratch)

	Memory := Scratch
	if MemorySize > ScratchSize {
		delete(Scratch, allocator)
		Memory = mem.make_aligned([]byte, MemorySize, 16, allocator) or_return
	}
	defer if Err != nil {
		delete(Memory, allocator)
	}

	_ = PostReadFontInitialize(&Result, Memory)
	return

}
FreeFont :: proc(Font: ^font, allocator: mem.Allocator) {
	free(Font.FileBase, allocator)
	free(Font.GlyphLookupMatrix, allocator)
	Font^ = {}
}

@(require_results)
CreateShapeState :: proc(Font: ^font, allocator: mem.Allocator) -> (Result: ^shape_state, Err: mem.Allocator_Error) {
	Size := SizeOfShapeState(Font)
	Memory := mem.make_aligned([]byte, Size, 16, allocator) or_return
	Result = PlaceShapeState(Memory)
	return
}
FreeShapeState :: proc(State: ^shape_state, allocator: mem.Allocator) {
	free(State, allocator)
}

@(require_results)
PositionGlyph :: proc(Cursor: ^cursor, Glyph: ^glyph) -> (X, Y: i32) {
	@(default_calling_convention="c", require_results)
	foreign lib {
		kbts_PositionGlyph :: proc(Cursor: ^cursor, Glyph: ^glyph, X, Y: ^i32) ---
	}
	kbts_PositionGlyph(Cursor, Glyph, &X, &Y)
	return
}

@(require_results)
ShapeDynamic :: proc(State: ^shape_state, Config: ^shape_config,
                     MainDirection, RunDirection: direction,
                     Glyphs: ^[dynamic]glyph) -> b32 {
	GlyphCount    := u32(len(Glyphs^))
	GlyphCapacity := u32(cap(Glyphs^))
	Res := Shape(State, Config, MainDirection, RunDirection, raw_data(Glyphs^), &GlyphCount, GlyphCapacity)
	resize(Glyphs, int(GlyphCount))
	return Res
}