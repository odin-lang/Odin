package ucd

import "core:os"

Age :: enum byte {
	Nil = 0,
	Age_1_1,
	Age_2_0,
	Age_2_1,
	Age_3_0,
	Age_3_1,
	Age_3_2,
	Age_4_0,
	Age_4_1,
	Age_5_0,
	Age_5_1,
	Age_5_2,
	Age_6_0,
	Age_6_1,
	Age_6_2,
	Age_6_3,
	Age_7_0,
	Age_8_0,
	Age_9_0,
	Age_10_0,
	Age_11_0,
	Age_12_0,
	Age_12_1,
	Age_13_0,
	Age_14_0,
	Age_15_0,
	Age_15_1,
	Age_16_0,
	Age_17_0,
	Age_Unassigned,
}

General_Category :: enum {
	Cc, // Control, a C0 or C1 control code
	Cf, // Format, a format control character
	Cn, // Unassigned, a reserved unassigned code point or a noncharacter
	Co, // Private_Use, a private-use character
	Cs, // Surrogate, a surrogate code point
	Ll, // Lowercase_Letter, a lowercase letter
	Lm, // Modifier_Letter, a modifier letter
	Lo, // Other_Letter, other letters, including syllables and ideographs
	Lt, // Titlecase_Letter, a digraph encoded as a single character, with first part uppercase
	Lu, // Uppercase_Letter, an uppercase letter
	Mc, // Spacing_Mark, a spacing combining mark (positive advance width)
	Me, // Enclosing_Mark, an enclosing combining mark
	Mn, // Nonspacing_Mark, a nonspacing combining mark (zero advance width)
	Nd, // Decimal_Number, a decimal digit
	Nl, // Letter_Number, a letterlike numeric character
	No, // Other_Number, a numeric character of other type
	Pc, // Connector_Punctuation, a connecting punctuation mark, like a tie
	Pd, // Dash_Punctuation, a dash or hyphen punctuation mark
	Pe, // Close_Punctuation, a closing punctuation mark (of a pair)
	Pf, // Final_Punctuation, a final quotation mark
	Pi, // Initial_Punctuation, an initial quotation mark
	Po, // Other_Punctuation, a punctuation mark of other type
	Ps, // Open_Punctuation, an opening punctuation mark (of a pair)
	Sc, // Currency_Symbol, a currency sign
	Sk, // Modifier_Symbol, a non-letterlike modifier symbol
	Sm, // Math_Symbol, a symbol of mathematical use
	So, // Other_Symbol, a symbol of other type
	Zl, // Line_Separator, U+2028 LINE SEPARATOR only
	Zp, // Paragraph_Separator, U+2029 PARAGRAPH SEPARATOR only
	Zs, // Space_Separator, a space character (of various non-zero widths)
}

Block :: enum {
	Nil = 0,
	Adlam,
	Aegean_Numbers,
	Ahom,
	Alchemical,
	Alphabetic_PF,
	Anatolian_Hieroglyphs,
	Ancient_Greek_Music,
	Ancient_Greek_Numbers,
	Ancient_Symbols,
	Arabic,
	Arabic_Ext_A,
	Arabic_Ext_B,
	Arabic_Ext_C,
	Arabic_Math,
	Arabic_PF_A,
	Arabic_PF_B,
	Arabic_Sup,
	Armenian,
	Arrows,
	ASCII,
	Avestan,
	Balinese,
	Bamum,
	Bamum_Sup,
	Bassa_Vah,
	Batak,
	Bengali,
	Beria_Erfe,
	Bhaiksuki,
	Block_Elements,
	Bopomofo,
	Bopomofo_Ext,
	Box_Drawing,
	Brahmi,
	Braille,
	Buginese,
	Buhid,
	Byzantine_Music,
	Carian,
	Caucasian_Albanian,
	Chakma,
	Cham,
	Cherokee,
	Cherokee_Sup,
	Chess_Symbols,
	Chorasmian,
	CJK,
	CJK_Compat,
	CJK_Compat_Forms,
	CJK_Compat_Ideographs,
	CJK_Compat_Ideographs_Sup,
	CJK_Ext_A,
	CJK_Ext_B,
	CJK_Ext_C,
	CJK_Ext_D,
	CJK_Ext_E,
	CJK_Ext_F,
	CJK_Ext_G,
	CJK_Ext_H,
	CJK_Ext_I,
	CJK_Ext_J,
	CJK_Radicals_Sup,
	CJK_Strokes,
	CJK_Symbols,
	Compat_Jamo,
	Control_Pictures,
	Coptic,
	Coptic_Epact_Numbers,
	Counting_Rod,
	Cuneiform,
	Cuneiform_Numbers,
	Currency_Symbols,
	Cypriot_Syllabary,
	Cypro_Minoan,
	Cyrillic,
	Cyrillic_Ext_A,
	Cyrillic_Ext_B,
	Cyrillic_Ext_C,
	Cyrillic_Ext_D,
	Cyrillic_Sup,
	Deseret,
	Devanagari,
	Devanagari_Ext,
	Devanagari_Ext_A,
	Diacriticals,
	Diacriticals_Ext,
	Diacriticals_For_Symbols,
	Diacriticals_Sup,
	Dingbats,
	Dives_Akuru,
	Dogra,
	Domino,
	Duployan,
	Early_Dynastic_Cuneiform,
	Egyptian_Hieroglyph_Format_Controls,
	Egyptian_Hieroglyphs,
	Egyptian_Hieroglyphs_Ext_A,
	Elbasan,
	Elymaic,
	Emoticons,
	Enclosed_Alphanum,
	Enclosed_Alphanum_Sup,
	Enclosed_CJK,
	Enclosed_Ideographic_Sup,
	Ethiopic,
	Ethiopic_Ext,
	Ethiopic_Ext_A,
	Ethiopic_Ext_B,
	Ethiopic_Sup,
	Garay,
	Geometric_Shapes,
	Geometric_Shapes_Ext,
	Georgian,
	Georgian_Ext,
	Georgian_Sup,
	Glagolitic,
	Glagolitic_Sup,
	Gothic,
	Grantha,
	Greek,
	Greek_Ext,
	Gujarati,
	Gunjala_Gondi,
	Gurmukhi,
	Gurung_Khema,
	Half_And_Full_Forms,
	Half_Marks,
	Hangul,
	Hanifi_Rohingya,
	Hanunoo,
	Hatran,
	Hebrew,
	High_PU_Surrogates,
	High_Surrogates,
	Hiragana,
	IDC,
	Ideographic_Symbols,
	Imperial_Aramaic,
	Indic_Number_Forms,
	Indic_Siyaq_Numbers,
	Inscriptional_Pahlavi,
	Inscriptional_Parthian,
	IPA_Ext,
	Jamo,
	Jamo_Ext_A,
	Jamo_Ext_B,
	Javanese,
	Kaithi,
	Kaktovik_Numerals,
	Kana_Ext_A,
	Kana_Ext_B,
	Kana_Sup,
	Kanbun,
	Kangxi,
	Kannada,
	Katakana,
	Katakana_Ext,
	Kawi,
	Kayah_Li,
	Kharoshthi,
	Khitan_Small_Script,
	Khmer,
	Khmer_Symbols,
	Khojki,
	Khudawadi,
	Kirat_Rai,
	Lao,
	Latin_1_Sup,
	Latin_Ext_A,
	Latin_Ext_Additional,
	Latin_Ext_B,
	Latin_Ext_C,
	Latin_Ext_D,
	Latin_Ext_E,
	Latin_Ext_F,
	Latin_Ext_G,
	Lepcha,
	Letterlike_Symbols,
	Limbu,
	Linear_A,
	Linear_B_Ideograms,
	Linear_B_Syllabary,
	Lisu,
	Lisu_Sup,
	Low_Surrogates,
	Lycian,
	Lydian,
	Mahajani,
	Mahjong,
	Makasar,
	Malayalam,
	Mandaic,
	Manichaean,
	Marchen,
	Masaram_Gondi,
	Math_Alphanum,
	Math_Operators,
	Mayan_Numerals,
	Medefaidrin,
	Meetei_Mayek,
	Meetei_Mayek_Ext,
	Mende_Kikakui,
	Meroitic_Cursive,
	Meroitic_Hieroglyphs,
	Miao,
	Misc_Arrows,
	Misc_Math_Symbols_A,
	Misc_Math_Symbols_B,
	Misc_Pictographs,
	Misc_Symbols,
	Misc_Symbols_Sup,
	Misc_Technical,
	Modi,
	Modifier_Letters,
	Modifier_Tone_Letters,
	Mongolian,
	Mongolian_Sup,
	Mro,
	Multani,
	Music,
	Myanmar,
	Myanmar_Ext_A,
	Myanmar_Ext_B,
	Myanmar_Ext_C,
	Nabataean,
	Nag_Mundari,
	Nandinagari,
	NB,
	New_Tai_Lue,
	Newa,
	NKo,
	Number_Forms,
	Nushu,
	Nyiakeng_Puachue_Hmong,
	OCR,
	Ogham,
	Ol_Chiki,
	Ol_Onal,
	Old_Hungarian,
	Old_Italic,
	Old_North_Arabian,
	Old_Permic,
	Old_Persian,
	Old_Sogdian,
	Old_South_Arabian,
	Old_Turkic,
	Old_Uyghur,
	Oriya,
	Ornamental_Dingbats,
	Osage,
	Osmanya,
	Ottoman_Siyaq_Numbers,
	Pahawh_Hmong,
	Palmyrene,
	Pau_Cin_Hau,
	Phags_Pa,
	Phaistos,
	Phoenician,
	Phonetic_Ext,
	Phonetic_Ext_Sup,
	Playing_Cards,
	Psalter_Pahlavi,
	PUA,
	Punctuation,
	Rejang,
	Rumi,
	Runic,
	Samaritan,
	Saurashtra,
	Sharada,
	Sharada_Sup,
	Shavian,
	Shorthand_Format_Controls,
	Siddham,
	Sidetic,
	Sinhala,
	Sinhala_Archaic_Numbers,
	Small_Forms,
	Small_Kana_Ext,
	Sogdian,
	Sora_Sompeng,
	Soyombo,
	Specials,
	Sundanese,
	Sundanese_Sup,
	Sunuwar,
	Sup_Arrows_A,
	Sup_Arrows_B,
	Sup_Arrows_C,
	Sup_Math_Operators,
	Sup_PUA_A,
	Sup_PUA_B,
	Sup_Punctuation,
	Sup_Symbols_And_Pictographs,
	Super_And_Sub,
	Sutton_SignWriting,
	Syloti_Nagri,
	Symbols_And_Pictographs_Ext_A,
	Symbols_For_Legacy_Computing,
	Symbols_For_Legacy_Computing_Sup,
	Syriac,
	Syriac_Sup,
	Tagalog,
	Tagbanwa,
	Tags,
	Tai_Le,
	Tai_Tham,
	Tai_Viet,
	Tai_Xuan_Jing,
	Tai_Yo,
	Takri,
	Tamil,
	Tamil_Sup,
	Tangsa,
	Tangut,
	Tangut_Components,
	Tangut_Components_Sup,
	Tangut_Sup,
	Telugu,
	Thaana,
	Thai,
	Tibetan,
	Tifinagh,
	Tirhuta,
	Todhri,
	Tolong_Siki,
	Toto,
	Transport_And_Map,
	Tulu_Tigalari,
	UCAS,
	UCAS_Ext,
	UCAS_Ext_A,
	Ugaritic,
	Vai,
	Vedic_Ext,
	Vertical_Forms,
	Vithkuqi,
	VS,
	VS_Sup,
	Wancho,
	Warang_Citi,
	Yezidi,
	Yi_Radicals,
	Yi_Syllables,
	Yijing,
	Zanabazar_Square,
	Znamenny_Music,
}

Combining_Class :: distinct byte

Paired_Brack_Type :: enum {
	Nil,
	Open,
	Close,
	None,
}

Bidi_Class :: enum {
	Nil, // 
	L,   // Left-to-Right  LRM
	R,   // Right-to-Left  RLM
	AL,  // Right-to-Left Arabic ALM 
	EN,  // European Number
	ES,  // European Number Separator
	ET,  // European Number Terminator
	AN,  // Arabic Number
	CS,  // Common Number Separator
	NSM, // Nonspacing Mark
	BN,  // Boundary Neutral
	B,   // Paragraph Separator
	S,   // Segment Separator
	WS,  // Whitespace
	ON,  // Other Neutrals
	LRE, // Left-to-Right Embedding  LRE    
	LRO, // Left-to-Right Override   LRO
	RLE, // Right-to-Left Embedding  RLE
	RLO, // Right-to-Left Override   RLO
	PDF, // Pop Directional Format   PDF
	LRI, // Left-to-Right Isolate    LRI
	RLI, // Right-to-Left Isolate    RLI
	FSI, // First Strong Isolate     FSI
	PDI, // Pop Directional Isolate  PDI
}


Bidi :: struct {
	bc: Bidi_Class,
	bmg: Maybe(rune), // mirrored glyph
	m: bool, // Bidi mirrored
	c: bool, // Bidi control property
	bpt : Paired_Brack_Type, // bidi paired bracket type 
	bpb : rune, // bidi paired bracket properties 
}


Decomposition_Type :: enum {
	Nil = 0,
	can,
	com,
	enc,
	fin,
	font,
	fra,
	init,
	iso,
	med,
	nar,
	nb,
	sml,
	sqr,
	sub,
	sup,
	vert,
	wid,
	none,
}

Trinary_Bool :: enum {
	Maybe = -1,
	False = 0,
	True = 1,
}

Decomposition_Mapping :: distinct [dynamic]rune 

Decomposition :: struct {
	dt: Decomposition_Type, // Decomposition type
	dm: Decomposition_Mapping, // Decomposition Mapping
	ce: bool, // Composition Exclusion
	comp_ex: bool, // Full Composition Exclusion
	nfc_quick_check: Trinary_Bool,
	nfd_quick_check: bool,
	nfkc_quick_check: Trinary_Bool,
	nfkd_quick_check: bool,
}

Numeric_Type :: enum {
	None = 0, // None
	Decimal, // De
	Digit, // Di
	Numeric, // Nu
}

/*
Note: Value is NAN when numberator and denominator ar 0
*/
Numberic_Value :: struct {
	numerator: int,
	denominator: int,
}

Char :: struct {
	cp: rune,
	name: string, 
	gc: General_Category,
	ccc: Combining_Class,
	bc: Bidi_Class,
	dt: Decomposition_Type,
	dm: Decomposition_Mapping,
	nt: Numeric_Type,
	nv: Numberic_Value,
	bm: bool,
	name1: string,
	sum: string, // Simple uppercase mapping
	slm: string, // Simple lowercase mapping
	stm: string, // Simple titlecase_mapping
}

Char_Range :: struct {
	first_cp: rune,
	last_cp: rune,
	name: string, 
	gc: General_Category,
	ccc: Combining_Class,
	bc: Bidi_Class,
	dt: Decomposition_Type,
	dm: Decomposition_Mapping,
	nt: Numeric_Type,
	nv: Numberic_Value,
	bm: bool,
	name1: string,
	sum: string, // Simple uppercase mapping
	slm: string, // Simple lowercase mapping
	stm: string, // Simple titlecase_mapping
}

Chars :: union {
	Char,
	Char_Range,
}

Unicode_Data :: distinct [dynamic]Chars


PropList_Property :: enum {
	White_Space,
	Bidi_Control,
	Join_Control,
	Dash,	
	Hyphen, 
	Quotation_Mark,
	Terminal_Punctuation,
	Other_Math,
	Hex_Digit,	
	ASCII_Hex_Digit,
	Other_Alphabetic,
	Ideographic,
	Diacritic,
	Extender,
	Other_Lowercase,
	Other_Uppercase,
	Noncharacter_Code_Point,
	Other_Grapheme_Extend,
	IDS_Binary_Operator,
	IDS_Trinary_Operator,
	IDS_Unary_Operator,
	Radical,
	Unified_Ideograph,
	Other_Default_Ignorable_Code_Point,
	Deprecated,
	Soft_Dotted,
	Logical_Order_Exception,
	Other_ID_Start,
	Other_ID_Continue,
	ID_Compat_Math_Continue,
	ID_Compat_Math_Start,
	Sentence_Terminal,
	Variation_Selector,
	Pattern_White_Space,
	Pattern_Syntax,
	Prepended_Concatenation_Mark,
	Regional_Indicator,
	Modifier_Combining_Mark,
}

UCD_Error :: enum {
	XML_LOAD_ERROR,
	XML_Not_UCD,
	Nil_XML_Document,
	Element_Not_Repertoire,
	Extra_Fields,
	Unknown_Property,

	NO_REPERTOIRE,
	UNEXPECTED_STRING,
	Invalid_Hex_Number,
	Invalid_General_Category,
	UnicodeData_6_Too_Long,
	UnicodeData_6_Invalid,
	UnicodeData_7_Too_Long,
	UnicodeData_7_Invalid,
}


Error :: union #shared_nil {
	UCD_Error,
	os.Error,
}

Range_u16 :: struct {
	first: u16,
	last: u16,
}

Range_i32 :: struct {
	first: i32,
	last: i32,
}

Range_Rune :: struct {
	first: rune,
	last: rune,
}

Dynamic_Range :: struct {
	single_16 : [dynamic]u16,
	ranges_16 : [dynamic]Range_u16,
	single_32 : [dynamic]i32,
	ranges_32 : [dynamic]Range_i32,
}

append_to_dynamic_range :: proc(
	dr: ^Dynamic_Range,
	range: Range_Rune,
	allocator := context.allocator,
) {
	if range.first == range.last && range.first <= 0xFFFF {
		if len(dr.single_16) == 0 {
			dr.single_16 = make([dynamic]u16, 0, 512, allocator) 
		}
		append(&dr.single_16, cast(u16) range.first)
	} else if range.first == range.last {
		if len(dr.single_32) == 0 {
			dr.single_32 = make([dynamic]i32, 0, 512, allocator) 
		}
		append(&dr.single_32, cast(i32) range.first)
	
	} else if range.first <= 0xFFFF && range.last <= 0xFFFF {
		if len(dr.ranges_16) == 0 {
			dr.ranges_16 = make([dynamic]Range_u16, 0, 128, allocator) 
		}
		r := Range_u16{ cast(u16)range.first, cast(u16) range.last}
		append(&dr.ranges_16, r)
	
	} else {
		if len(dr.ranges_32) == 0 {
			dr.ranges_32 = make([dynamic]Range_i32, 0, 128, allocator) 
		}
		r := Range_i32{ cast(i32)range.first, cast(i32) range.last}
		append(&dr.ranges_32, r)
	}
}

destroy_dynamic_range :: proc (
	dr: Dynamic_Range,
){
	delete(dr.ranges_16)
	delete(dr.ranges_32)
	delete(dr.single_16)
	delete(dr.single_32)
}

destroy_general_category_ranges :: proc(
	gcr: [General_Category]Dynamic_Range,
){
	for r in gcr {
		destroy_dynamic_range(r)
	}
}
