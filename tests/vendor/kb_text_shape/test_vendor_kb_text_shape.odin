package test_vendor_kb_text_shape

import "base:runtime"
import "core:log"
import "core:os"
import "core:testing"
import kb "vendor:kb_text_shape"

FONT_PATH :: ODIN_ROOT + "tests/core/assets/Fonts/"

NOTO_SANS          :: FONT_PATH + "NotoSans-Regular.ttf"
NOTO_SANS_VARIABLE :: FONT_PATH + "NotoSans-Variable.ttf"
NOTO_SANS_ARABIC   :: FONT_PATH + "NotoSansArabic-Regular.ttf"
NOTO_SANS_DEVANAGARI :: FONT_PATH + "NotoSansDevanagari-Regular.ttf"
NOTO_SANS_THAI     :: FONT_PATH + "NotoSansThai-Regular.ttf"
NOTO_SANS_MONO     :: FONT_PATH + "NotoSansMono-Regular.ttf"

WEIGHT :: u32('w') | u32('g')<<8 | u32('h')<<16 | u32('t')<<24

Shaped_Glyph :: struct {
	id:       u16,
	codepoint: rune,
	cluster:  int,
	offset_x: i32,
	offset_y: i32,
	advance:  i32,
}

@(test)
layout :: proc(t: ^testing.T) {
	when size_of(rawptr) == 8 {
		testing.expect_value(t, size_of(kb.font_info), 144)
		testing.expect_value(t, offset_of(kb.font_info, StringLengths), 104)
		testing.expect_value(t, offset_of(kb.font_info, StyleFlags), 132)
		testing.expect_value(t, offset_of(kb.font_info, Weight), 136)
		testing.expect_value(t, offset_of(kb.font_info, Width), 140)
		testing.expect_value(t, size_of(kb.font_info2), 152)
		testing.expect_value(t, size_of(kb.font_info2_1), 168)
		testing.expect_value(t, size_of(kb.font_info2_2), 176)
		testing.expect_value(t, offset_of(kb.font_info2_2, CapitalHeight), 168)

		testing.expect_value(t, size_of(kb.variation), 8)
		testing.expect_value(t, offset_of(kb.variation, Value), 4)

		testing.expect_value(t, size_of(kb.shape_codepoint), 48)
		testing.expect_value(t, size_of(kb.shape_codepoint2), 64)
		testing.expect_value(t, offset_of(kb.shape_codepoint2, Font), 8)
		testing.expect_value(t, offset_of(kb.shape_codepoint2, VariationVector), 16)
		testing.expect_value(t, offset_of(kb.shape_codepoint2, FeatureOverrides), 24)
		testing.expect_value(t, offset_of(kb.shape_codepoint2, Codepoint), 36)
		testing.expect_value(t, offset_of(kb.shape_codepoint2, BreakFlags), 44)
		testing.expect_value(t, offset_of(kb.shape_codepoint2, ParagraphDirection), 56)
		testing.expect_value(t, size_of(kb.shape_codepoint_iterator), 40)

		testing.expect_value(t, size_of(kb.run), 56)
		testing.expect_value(t, size_of(kb.run2), 64)
		testing.expect_value(t, offset_of(kb.run2, Glyphs), 24)
		testing.expect_value(t, offset_of(kb.run2, VariationVector), 56)
		testing.expect_value(t, size_of(kb.glyph_iterator), 32)
		testing.expect_value(t, size_of(kb.glyph), 120)

		testing.expect_value(t, size_of(kb.uid), 16)
		testing.expect_value(t, size_of(kb.variation_axis_info), 20)
		testing.expect_value(t, offset_of(kb.variation_axis_info, MinimumValue), 4)
		testing.expect_value(t, offset_of(kb.variation_axis_info, MaximumValue), 12)
		testing.expect_value(t, offset_of(kb.variation_axis_info, Flags), 16)
		testing.expect_value(t, offset_of(kb.variation_axis_info, NameStringId), 18)
		testing.expect_value(t, size_of(kb.variation_instance_info), 8)
		testing.expect_value(t, offset_of(kb.variation_instance_info, Flags), 4)
		testing.expect_value(t, size_of(kb.decode), 12)
		testing.expect_value(t, size_of(kb.break_type), 20)
	}
	testing.expect_value(t, int(kb.font_info_string_id.TYPOGRAPHIC_SUBFAMILY) + 1, kb.FONT_INFO_STRING_ID_COUNT0)
	testing.expect_value(t, len(kb.font_info{}.Strings), kb.FONT_INFO_STRING_ID_COUNT0)
	testing.expect_value(t, kb.version.CURRENT, kb.version._2_28)
	testing.expect_value(t, kb.VARIATION_VALUE_UNSET, f32(-100000))
}

@(test)
shape_error_values :: proc(t: ^testing.T) {
	testing.expect_value(t, u32(kb.shape_error.NONE), 0)
	testing.expect_value(t, u32(kb.shape_error.INVALID_FONT), 1)
	testing.expect_value(t, u32(kb.shape_error.GAVE_TEXT_BEFORE_CALLING_BEGIN), 2)
	testing.expect_value(t, u32(kb.shape_error.OUT_OF_MEMORY), 3)
	testing.expect_value(t, u32(kb.shape_error.GENERATED_TOO_MANY_GLYPHS), 4)
}

@(test)
decode_utf8 :: proc(t: ^testing.T) {
	d := kb.DecodeUtf8("éx")
	testing.expect_value(t, d.Codepoint, 'é')
	testing.expect_value(t, d.SourceCharactersConsumed, 2)
	testing.expect(t, bool(d.Valid))
}

@(test)
decode_utf16 :: proc(t: ^testing.T) {
	single := [?]u16{0x20AC}
	d := kb.DecodeUtf16(single[:])
	testing.expect_value(t, d.Codepoint, rune(0x20AC))
	testing.expect_value(t, d.SourceCharactersConsumed, 1)

	lone := [?]u16{0xD83D}
	d = kb.DecodeUtf16(lone[:])
	testing.expect(t, !bool(d.Valid), "a lone high surrogate is not valid UTF-16")
}

@(test)
windows_language_ids :: proc(t: ^testing.T) {
	ids: [64]kb.windows_language_id
	count := kb.WindowsIdsForLanguage(.ENGLISH, ids[:0])
	testing.expect(t, count > 0, "English must map to some Windows language ids")
	if count > 0 && int(count) <= len(ids) {
		testing.expect_value(t, kb.WindowsIdsForLanguage(.ENGLISH, ids[:count]), count)
		found := false
		for id in ids[:count] {
			if id == .ENGLISH_UNITED_STATES { found = true }
		}
		testing.expect(t, found, "en-US must be among the ids for English")
	}
	testing.expect_value(t, u16(kb.windows_language_id.ENGLISH_UNITED_STATES), 0x409)
	testing.expect_value(t, u16(kb.windows_language_id.GERMAN_GERMANY), 0x407)
}

@(test)
renamed_languages :: proc(t: ^testing.T) {
	testing.expect_value(t, u32(kb.language.AZERBAIJANI), u32('A') | u32('Z')<<8 | u32('E')<<16 | u32(' ')<<24)
	testing.expect_value(t, u32(kb.language.ESPERANTO),   u32('N') | u32('T')<<8 | u32('O')<<16 | u32(' ')<<24)
	testing.expect_value(t, u32(kb.language.KOREAN_OLD_HANGUL), u32('K') | u32('O')<<8 | u32('H')<<16 | u32(' ')<<24)
}

@(test)
text_properties :: proc(t: ^testing.T) {
	direction, script := kb.GuessTextPropertiesUtf8("Hello")
	testing.expect_value(t, direction, kb.direction.KBTS_DIRECTION_LTR)
	testing.expect_value(t, script, kb.script.LATIN)

	direction, script = kb.GuessTextPropertiesUtf8("مرحبا")
	testing.expect_value(t, direction, kb.direction.KBTS_DIRECTION_RTL)
	testing.expect_value(t, script, kb.script.ARABIC)

	direction, script = kb.GuessTextPropertiesUtf8("कि")
	testing.expect_value(t, direction, kb.direction.KBTS_DIRECTION_LTR)
	testing.expect_value(t, script, kb.script.DEVANAGARI)

	direction, script = kb.GuessTextPropertiesUtf8("สวัสดี")
	testing.expect_value(t, direction, kb.direction.KBTS_DIRECTION_LTR)
	testing.expect_value(t, script, kb.script.THAI)

	testing.expect_value(t, kb.ScriptDirection(.ARABIC), kb.direction.KBTS_DIRECTION_RTL)
	testing.expect(t, bool(kb.ScriptIsComplex(.ARABIC)))
	testing.expect(t, bool(kb.ScriptIsComplex(.DEVANAGARI)))
	testing.expect(t, !bool(kb.ScriptIsComplex(.LATIN)))
}

read_font :: proc(t: ^testing.T, path: string) -> (data: []byte, ok: bool) {
	bytes, err := os.read_entire_file(path, context.temp_allocator)
	if !testing.expectf(t, err == nil, "could not read %v, run tests/core/download_assets.py to fetch the test assets", path) {
		return
	}
	return bytes, true
}

shape :: proc(t: ^testing.T, font_data: []byte, text: string, variations: []kb.variation = nil, features: []kb.feature_tag = nil) -> (glyphs: []Shaped_Glyph, ok: bool) {
	allocator := context.allocator
	shape_context := kb.CreateShapeContext(kb.AllocatorFromOdinAllocator(&allocator))
	if !testing.expect(t, shape_context != nil, "CreateShapeContext failed") { return }
	defer kb.DestroyShapeContext(shape_context)

	if variations != nil {
		if !testing.expect(t, kb.ShapePushFontFromMemory2(shape_context, font_data, 0, variations) != nil, "the font did not load") { return }
	} else {
		if !testing.expect(t, kb.ShapePushFontFromMemory(shape_context, font_data, 0) != nil, "the font did not load") { return }
	}

	kb.ShapeBegin(shape_context, .DONT_KNOW, .DONT_KNOW)
	for feature in features {
		kb.ShapePushFeature(shape_context, feature, 0)
	}
	kb.ShapeUtf8(shape_context, text, .CODEPOINT_INDEX)
	kb.ShapeEnd(shape_context)
	if !testing.expect_value(t, kb.ShapeError(shape_context), kb.shape_error.NONE) { return }

	out := make([dynamic]Shaped_Glyph, context.temp_allocator)
	for run in kb.ShapeRun(shape_context) {
		run := run
		for glyph in kb.GlyphIteratorNext(&run.Glyphs) {
			append(&out, Shaped_Glyph{
				id        = glyph.Id,
				codepoint = glyph.Codepoint,
				cluster   = int(glyph.UserIdOrCodepointIndex),
				offset_x  = glyph.OffsetX,
				offset_y  = glyph.OffsetY,
				advance   = glyph.AdvanceX,
			})
		}
	}
	return out[:], true
}

total_advance :: proc(glyphs: []Shaped_Glyph) -> (sum: int) {
	for glyph in glyphs {
		sum += int(glyph.advance)
	}
	return
}

open_font :: proc(t: ^testing.T, data: []byte, font: ^kb.font, allocator: ^runtime.Allocator) -> bool {
	font^ = kb.FontFromMemory(data, 0, kb.AllocatorFromOdinAllocator(allocator))
	return testing.expect(t, bool(kb.FontIsValid(font)), "the font did not parse")
}

@(test)
latin_shaping :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS)
	if !found { return }

	glyphs, ok := shape(t, data, "Hello, world")
	if !ok { return }
	testing.expect_value(t, len(glyphs), 12)
	testing.expect(t, total_advance(glyphs) > 0, "the text has a width")
	for glyph, i in glyphs {
		testing.expect_value(t, glyph.cluster, i)
		testing.expect(t, glyph.id != 0, "every letter has a glyph")
	}

	single, _ := shape(t, data, "H")
	double, _ := shape(t, data, "HH")
	testing.expect_value(t, total_advance(double), 2 * total_advance(single))
}

@(test)
latin_ligature :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS)
	if !found { return }

	with, ok := shape(t, data, "fi")
	if !ok { return }
	without, _ := shape(t, data, "fi", features = {kb.feature_tag.liga})
	log.infof("fi: %v glyphs with liga, %v without", len(with), len(without))
	testing.expect_value(t, len(without), 2)
	testing.expect_value(t, len(with), 1)
}

@(test)
latin_kerning :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS)
	if !found { return }

	pair, ok := shape(t, data, "AV")
	if !ok { return }
	a, _ := shape(t, data, "A")
	v, _ := shape(t, data, "V")
	testing.expect_value(t, len(pair), 2)
	testing.expect(t, total_advance(pair) < total_advance(a) + total_advance(v), "AV is kerned")
}

@(test)
arabic_joining :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS_ARABIC)
	if !found { return }

	word, ok := shape(t, data, "مرحبا")
	if !ok { return }
	if !testing.expect_value(t, len(word), 6) { return }

	ids: [6]u16
	for glyph, i in word {
		ids[i] = glyph.id
	}
	testing.expect_value(t, ids, [6]u16{9, 316, 16, 27, 31, 79})
	testing.expect_value(t, word[5].cluster, 0)
	testing.expect_value(t, word[0].cluster, 4)

	isolated, _ := shape(t, data, "م")
	testing.expect_value(t, len(isolated), 1)
	testing.expect(t, isolated[0].id != word[5].id, "the initial form differs from the isolated one")
}

@(test)
devanagari_reordering :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS_DEVANAGARI)
	if !found { return }

	ki, ok := shape(t, data, "कि")
	if !ok { return }
	log.infof("devanagari: %v", ki)
	testing.expect(t, len(ki) >= 2, "consonant and vowel sign")
	if len(ki) >= 2 {
		testing.expect_value(t, ki[0].cluster, 1)
	}
}

@(test)
thai_marks :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS_THAI)
	if !found { return }

	word, ok := shape(t, data, "กิ")
	if !ok { return }
	log.infof("thai: %v", word)
	testing.expect_value(t, len(word), 2)
	if len(word) == 2 {
		testing.expect_value(t, word[1].advance, 0)
	}
}

@(test)
mono_advances :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS_MONO)
	if !found { return }

	glyphs, ok := shape(t, data, "iWm.")
	if !ok { return }
	testing.expect_value(t, len(glyphs), 4)
	for glyph in glyphs[1:] {
		testing.expect_value(t, glyph.advance, glyphs[0].advance)
	}
}

@(test)
variable_font :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS_VARIABLE)
	if !found { return }

	allocator := context.allocator
	font: kb.font
	if !open_font(t, data, &font, &allocator) { return }
	defer kb.FreeFont(&font)

	axes, instances: i32
	kb.GetVariationInfo(&font, &axes, &instances)
	testing.expect_value(t, axes, 2)
	testing.expect(t, instances > 0, "named instances")

	weight: kb.variation_axis_info
	has_weight := false
	for i in 0..<axes {
		info: kb.variation_axis_info
		if !testing.expect(t, bool(kb.GetVariationAxisInfo(&font, i, &info)), "axis in range") { return }
		testing.expect(t, info.MinimumValue <= info.DefaultValue && info.DefaultValue <= info.MaximumValue)
		if info.Tag == WEIGHT {
			weight = info
			has_weight = true
		}
	}
	if !testing.expect(t, has_weight, "Noto Sans has a weight axis") { return }
	testing.expect_value(t, weight.MinimumValue, 100)
	testing.expect_value(t, weight.DefaultValue, 400)
	testing.expect_value(t, weight.MaximumValue, 900)

	extra: kb.variation_axis_info
	testing.expect(t, !bool(kb.GetVariationAxisInfo(&font, axes, &extra)), "an axis past the end must not exist")

	info: kb.variation_instance_info
	vector := make([]f32, axes, context.temp_allocator)
	testing.expect(t, bool(kb.GetVariationInstance(&font, 0, &info, raw_data(vector))), "the first instance must exist")

	light := [?]kb.variation{{Tag = WEIGHT, Value = weight.MinimumValue}}
	heavy := [?]kb.variation{{Tag = WEIGHT, Value = weight.MaximumValue}}
	light_glyphs, light_ok := shape(t, data, "Hello, world", light[:])
	heavy_glyphs, heavy_ok := shape(t, data, "Hello, world", heavy[:])
	if light_ok && heavy_ok {
		log.infof("advance at weight 100: %v, at weight 900: %v", total_advance(light_glyphs), total_advance(heavy_glyphs))
		testing.expect(t, total_advance(heavy_glyphs) > total_advance(light_glyphs), "heavier text is wider")
	}

	for i in 0..<axes {
		axis: kb.variation_axis_info
		_ = kb.GetVariationAxisInfo(&font, i, &axis)
		vector[i] = axis.DefaultValue
	}
	normalized := make([]i16, axes, context.temp_allocator)
	kb.NormalizeVariationVector(&font, raw_data(vector), raw_data(normalized))
	for v in normalized {
		testing.expect_value(t, v, 0)
	}
}

@(test)
font_strings :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS)
	if !found { return }

	allocator := context.allocator
	font: kb.font
	if !open_font(t, data, &font, &allocator) { return }
	defer kb.FreeFont(&font)

	buffer: [256]byte
	length := kb.LookupFontString(&font, .FAMILY, .ENGLISH_UNITED_STATES, buffer[:])
	if testing.expect(t, length > 0 && int(length) <= len(buffer), "a font has a family name in English") {
		testing.expect_value(t, string(buffer[:length]), "Noto Sans")
	}

	length = kb.LookupFontString(&font, .SUBFAMILY, .ENGLISH_UNITED_STATES, buffer[:])
	if testing.expect(t, length > 0 && int(length) <= len(buffer), "a font has a subfamily name in English") {
		testing.expect_value(t, string(buffer[:length]), "Regular")
	}
}

@(test)
font_info :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS)
	if !found { return }

	allocator := context.allocator
	font: kb.font
	if !open_font(t, data, &font, &allocator) { return }
	defer kb.FreeFont(&font)

	info: kb.font_info
	kb.GetFontInfo(&font, &info)
	testing.expect_value(t, info.Weight, kb.font_weight.NORMAL)
}

@(test)
invalid_font :: proc(t: ^testing.T) {
	data, found := read_font(t, NOTO_SANS)
	if !found { return }

	allocator := context.allocator
	for cut in ([?]int{0, 4}) {
		font := kb.FontFromMemory(data[:cut], 0, kb.AllocatorFromOdinAllocator(&allocator))
		testing.expectf(t, !bool(kb.FontIsValid(&font)), "a font cut to %v bytes is not valid", cut)
		kb.FreeFont(&font)
	}

	for cut in ([?]int{12, 64, 1024, 4096, len(data) / 2, len(data) - 1}) {
		shape_context := kb.CreateShapeContext(kb.AllocatorFromOdinAllocator(&allocator))
		if !testing.expect(t, shape_context != nil, "CreateShapeContext failed") { return }
		if kb.ShapePushFontFromMemory(shape_context, data[:cut], 0) != nil {
			kb.ShapeBegin(shape_context, .DONT_KNOW, .DONT_KNOW)
			kb.ShapeUtf8(shape_context, "Hello", .CODEPOINT_INDEX)
			kb.ShapeEnd(shape_context)
			for run in kb.ShapeRun(shape_context) {
				run := run
				for _ in kb.GlyphIteratorNext(&run.Glyphs) {}
			}
		}
		kb.DestroyShapeContext(shape_context)
	}

	garbage := [?]byte{1, 2, 3, 4, 5, 6, 7, 8}
	font2 := kb.FontFromMemory(garbage[:], 0, kb.AllocatorFromOdinAllocator(&allocator))
	defer kb.FreeFont(&font2)
	testing.expect(t, !bool(kb.FontIsValid(&font2)), "garbage is not a font")
}
