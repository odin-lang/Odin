package orca

import "core:c"

char :: c.char

// currently missing in the api.json
window :: distinct u64
    
// currently missing in the api.json
pool :: struct {
	arena: arena,
	freeList: list,
	blockSize: u64,
}

@(link_prefix="OC_")
foreign {
	UI_DARK_THEME: ui_theme
	UI_LIGHT_THEME: ui_theme

	UI_DARK_PALETTE: ui_palette
	UI_LIGHT_PALETTE: ui_palette
}


SYS_MAX_ERROR :: 1024

sys_err_def :: struct {
	msg: [SYS_MAX_ERROR]u8 `fmt:"s,0"`,
	code: i32,
}

@(link_prefix="oc_")
foreign {
	sys_error: sys_err_def
}
UNICODE_BASIC_LATIN :: unicode_range { 0x0000, 127 }
UNICODE_C1_CONTROLS_AND_LATIN_1_SUPPLEMENT :: unicode_range { 0x0080, 127 }
UNICODE_LATIN_EXTENDED_A :: unicode_range { 0x0100, 127 }
UNICODE_LATIN_EXTENDED_B :: unicode_range { 0x0180, 207 }
UNICODE_IPA_EXTENSIONS :: unicode_range { 0x0250, 95 }
UNICODE_SPACING_MODIFIER_LETTERS :: unicode_range { 0x02b0, 79 }
UNICODE_COMBINING_DIACRITICAL_MARKS :: unicode_range { 0x0300, 111 }
UNICODE_GREEK_COPTIC :: unicode_range { 0x0370, 143 }
UNICODE_CYRILLIC :: unicode_range { 0x0400, 255 }
UNICODE_CYRILLIC_SUPPLEMENT :: unicode_range { 0x0500, 47 }
UNICODE_ARMENIAN :: unicode_range { 0x0530, 95 }
UNICODE_HEBREW :: unicode_range { 0x0590, 111 }
UNICODE_ARABIC :: unicode_range { 0x0600, 255 }
UNICODE_SYRIAC :: unicode_range { 0x0700, 79 }
UNICODE_THAANA :: unicode_range { 0x0780, 63 }
UNICODE_DEVANAGARI :: unicode_range { 0x0900, 127 }
UNICODE_BENGALI_ASSAMESE :: unicode_range { 0x0980, 127 }
UNICODE_GURMUKHI :: unicode_range { 0x0a00, 127 }
UNICODE_GUJARATI :: unicode_range { 0x0a80, 127 }
UNICODE_ORIYA :: unicode_range { 0x0b00, 127 }
UNICODE_TAMIL :: unicode_range { 0x0b80, 127 }
UNICODE_TELUGU :: unicode_range { 0x0c00, 127 }
UNICODE_KANNADA :: unicode_range { 0x0c80, 127 }
UNICODE_MALAYALAM :: unicode_range { 0x0d00, 255 }
UNICODE_SINHALA :: unicode_range { 0x0d80, 127 }
UNICODE_THAI :: unicode_range { 0x0e00, 127 }
UNICODE_LAO :: unicode_range { 0x0e80, 127 }
UNICODE_TIBETAN :: unicode_range { 0x0f00, 255 }
UNICODE_MYANMAR :: unicode_range { 0x1000, 159 }
UNICODE_GEORGIAN :: unicode_range { 0x10a0, 95 }
UNICODE_HANGUL_JAMO :: unicode_range { 0x1100, 255 }
UNICODE_ETHIOPIC :: unicode_range { 0x1200, 383 }
UNICODE_CHEROKEE :: unicode_range { 0x13a0, 95 }
UNICODE_UNIFIED_CANADIAN_ABORIGINAL_SYLLABICS :: unicode_range { 0x1400, 639 }
UNICODE_OGHAM :: unicode_range { 0x1680, 31 }
UNICODE_RUNIC :: unicode_range { 0x16a0, 95 }
UNICODE_TAGALOG :: unicode_range { 0x1700, 31 }
UNICODE_HANUNOO :: unicode_range { 0x1720, 31 }
UNICODE_BUHID :: unicode_range { 0x1740, 31 }
UNICODE_TAGBANWA :: unicode_range { 0x1760, 31 }
UNICODE_KHMER :: unicode_range { 0x1780, 127 }
UNICODE_MONGOLIAN :: unicode_range { 0x1800, 175 }
UNICODE_LIMBU :: unicode_range { 0x1900, 79 }
UNICODE_TAI_LE :: unicode_range { 0x1950, 47 }
UNICODE_KHMER_SYMBOLS :: unicode_range { 0x19e0, 31 }
UNICODE_PHONETIC_EXTENSIONS :: unicode_range { 0x1d00, 127 }
UNICODE_LATIN_EXTENDED_ADDITIONAL :: unicode_range { 0x1e00, 255 }
UNICODE_GREEK_EXTENDED :: unicode_range { 0x1f00, 255 }
UNICODE_GENERAL_PUNCTUATION :: unicode_range { 0x2000, 111 }
UNICODE_SUPERSCRIPTS_AND_SUBSCRIPTS :: unicode_range { 0x2070, 47 }
UNICODE_CURRENCY_SYMBOLS :: unicode_range { 0x20a0, 47 }
UNICODE_COMBINING_DIACRITICAL_MARKS_FOR_SYMBOLS :: unicode_range { 0x20d0, 47 }
UNICODE_LETTERLIKE_SYMBOLS :: unicode_range { 0x2100, 79 }
UNICODE_NUMBER_FORMS :: unicode_range { 0x2150, 63 }
UNICODE_ARROWS :: unicode_range { 0x2190, 111 }
UNICODE_MATHEMATICAL_OPERATORS :: unicode_range { 0x2200, 255 }
UNICODE_MISCELLANEOUS_TECHNICAL :: unicode_range { 0x2300, 255 }
UNICODE_CONTROL_PICTURES :: unicode_range { 0x2400, 63 }
UNICODE_OPTICAL_CHARACTER_RECOGNITION :: unicode_range { 0x2440, 31 }
UNICODE_ENCLOSED_ALPHANUMERICS :: unicode_range { 0x2460, 159 }
UNICODE_BOX_DRAWING :: unicode_range { 0x2500, 127 }
UNICODE_BLOCK_ELEMENTS :: unicode_range { 0x2580, 31 }
UNICODE_GEOMETRIC_SHAPES :: unicode_range { 0x25a0, 95 }
UNICODE_MISCELLANEOUS_SYMBOLS :: unicode_range { 0x2600, 255 }
UNICODE_DINGBATS :: unicode_range { 0x2700, 191 }
UNICODE_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_A :: unicode_range { 0x27c0, 47 }
UNICODE_SUPPLEMENTAL_ARROWS_A :: unicode_range { 0x27f0, 15 }
UNICODE_BRAILLE_PATTERNS :: unicode_range { 0x2800, 255 }
UNICODE_SUPPLEMENTAL_ARROWS_B :: unicode_range { 0x2900, 127 }
UNICODE_MISCELLANEOUS_MATHEMATICAL_SYMBOLS_B :: unicode_range { 0x2980, 127 }
UNICODE_SUPPLEMENTAL_MATHEMATICAL_OPERATORS :: unicode_range { 0x2a00, 255 }
UNICODE_MISCELLANEOUS_SYMBOLS_AND_ARROWS :: unicode_range { 0x2b00, 255 }
UNICODE_CJK_RADICALS_SUPPLEMENT :: unicode_range { 0x2e80, 127 }
UNICODE_KANGXI_RADICALS :: unicode_range { 0x2f00, 223 }
UNICODE_IDEOGRAPHIC_DESCRIPTION_CHARACTERS :: unicode_range { 0x2ff0, 15 }
UNICODE_CJK_SYMBOLS_AND_PUNCTUATION :: unicode_range { 0x3000, 63 }
UNICODE_HIRAGANA :: unicode_range { 0x3040, 95 }
UNICODE_KATAKANA :: unicode_range { 0x30a0, 95 }
UNICODE_BOPOMOFO :: unicode_range { 0x3100, 47 }
UNICODE_HANGUL_COMPATIBILITY_JAMO :: unicode_range { 0x3130, 95 }
UNICODE_KANBUN_KUNTEN :: unicode_range { 0x3190, 15 }
UNICODE_BOPOMOFO_EXTENDED :: unicode_range { 0x31a0, 31 }
UNICODE_KATAKANA_PHONETIC_EXTENSIONS :: unicode_range { 0x31f0, 15 }
UNICODE_ENCLOSED_CJK_LETTERS_AND_MONTHS :: unicode_range { 0x3200, 255 }
UNICODE_CJK_COMPATIBILITY :: unicode_range { 0x3300, 255 }
UNICODE_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A :: unicode_range { 0x3400, 6591 }
UNICODE_YIJING_HEXAGRAM_SYMBOLS :: unicode_range { 0x4dc0, 63 }
UNICODE_CJK_UNIFIED_IDEOGRAPHS :: unicode_range { 0x4e00, 20911 }
UNICODE_YI_SYLLABLES :: unicode_range { 0xa000, 1167 }
UNICODE_YI_RADICALS :: unicode_range { 0xa490, 63 }
UNICODE_HANGUL_SYLLABLES :: unicode_range { 0xac00, 11183 }
UNICODE_HIGH_SURROGATE_AREA :: unicode_range { 0xd800, 1023 }
UNICODE_LOW_SURROGATE_AREA :: unicode_range { 0xdc00, 1023 }
UNICODE_PRIVATE_USE_AREA :: unicode_range { 0xe000, 6399 }
UNICODE_CJK_COMPATIBILITY_IDEOGRAPHS :: unicode_range { 0xf900, 511 }
UNICODE_ALPHABETIC_PRESENTATION_FORMS :: unicode_range { 0xfb00, 79 }
UNICODE_ARABIC_PRESENTATION_FORMS_A :: unicode_range { 0xfb50, 687 }
UNICODE_VARIATION_SELECTORS :: unicode_range { 0xfe00, 15 }
UNICODE_COMBINING_HALF_MARKS :: unicode_range { 0xfe20, 15 }
UNICODE_CJK_COMPATIBILITY_FORMS :: unicode_range { 0xfe30, 31 }
UNICODE_SMALL_FORM_VARIANTS :: unicode_range { 0xfe50, 31 }
UNICODE_ARABIC_PRESENTATION_FORMS_B :: unicode_range { 0xfe70, 143 }
UNICODE_HALFWIDTH_AND_FULLWIDTH_FORMS :: unicode_range { 0xff00, 239 }
UNICODE_SPECIALS :: unicode_range { 0xfff0, 15 }
UNICODE_LINEAR_B_SYLLABARY :: unicode_range { 0x10000, 127 }
UNICODE_LINEAR_B_IDEOGRAMS :: unicode_range { 0x10080, 127 }
UNICODE_AEGEAN_NUMBERS :: unicode_range { 0x10100, 63 }
UNICODE_OLD_ITALIC :: unicode_range { 0x10300, 47 }
UNICODE_GOTHIC :: unicode_range { 0x10330, 31 }
UNICODE_UGARITIC :: unicode_range { 0x10380, 31 }
UNICODE_DESERET :: unicode_range { 0x10400, 79 }
UNICODE_SHAVIAN :: unicode_range { 0x10450, 47 }
UNICODE_OSMANYA :: unicode_range { 0x10480, 47 }
UNICODE_CYPRIOT_SYLLABARY :: unicode_range { 0x10800, 63 }
UNICODE_BYZANTINE_MUSICAL_SYMBOLS :: unicode_range { 0x1d000, 255 }
UNICODE_MUSICAL_SYMBOLS :: unicode_range { 0x1d100, 255 }
UNICODE_TAI_XUAN_JING_SYMBOLS :: unicode_range { 0x1d300, 95 }
UNICODE_MATHEMATICAL_ALPHANUMERIC_SYMBOLS :: unicode_range { 0x1d400, 1023 }
UNICODE_CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B :: unicode_range { 0x20000, 42719 }
UNICODE_CJK_COMPATIBILITY_IDEOGRAPHS_SUPPLEMENT :: unicode_range { 0x2f800, 543 }
UNICODE_TAGS :: unicode_range { 0xe0000, 127 }
UNICODE_VARIATION_SELECTORS_SUPPLEMENT :: unicode_range { 0xe0100, 239 }
UNICODE_SUPPLEMENTARY_PRIVATE_USE_AREA_A :: unicode_range { 0xf0000, 65533 }
UNICODE_SUPPLEMENTARY_PRIVATE_USE_AREA_B  :: unicode_range { 0x100000, 65533 }

clock_kind :: enum c.int {
	MONOTONIC,
	UPTIME,
	DATE,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	clock_time :: proc(clock: clock_kind) -> f64 ---
}

file_write_slice :: proc(file: file, slice: []char) -> u64 {
	return file_write(file, u64(len(slice)), raw_data(slice))
}

file_read_slice :: proc(file: file, slice: []char) -> u64 {
	return file_read(file, u64(len(slice)), raw_data(slice))
}

style_enum :: enum {
	SIZE_WIDTH = 1,
	SIZE_HEIGHT,
	
	LAYOUT_AXIS,
	LAYOUT_ALIGN_X,
	LAYOUT_ALIGN_Y,
	LAYOUT_SPACING,
	LAYOUT_MARGIN_X,
	LAYOUT_MARGIN_Y,
	
	FLOAT_X,
	FLOAT_Y,

	COLOR,
	BG_COLOR,
	BORDER_COLOR,
	BORDER_SIZE,
	ROUNDNESS,

	FONT,
	FONT_SIZE,

	ANIMATION_TIME,
	ANIMATION_MASK,
}

ui_style_mask :: bit_set[style_enum; u64]

// Masks like the C version that can be used as common combinations
SIZE :: ui_style_mask { .SIZE_WIDTH, .SIZE_HEIGHT }
LAYOUT_MARGINS :: ui_style_mask { .LAYOUT_MARGIN_X, .LAYOUT_MARGIN_Y }
LAYOUT :: ui_style_mask { .LAYOUT_AXIS, .LAYOUT_ALIGN_X, .LAYOUT_ALIGN_Y, .LAYOUT_SPACING, .LAYOUT_MARGIN_X, .LAYOUT_MARGIN_Y }
FLOAT :: ui_style_mask { .FLOAT_X, .FLOAT_Y }
MASK_INHERITED :: ui_style_mask { .COLOR, .FONT, .FONT_SIZE, .ANIMATION_TIME, .ANIMATION_MASK }

////////////////////////////////////////////////////////////////////////////////
// Utility data structures and helpers used throughout the Orca API.
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Types and helpers for vectors and matrices.
////////////////////////////////////////////////////////////////////////////////

// A 2D vector type.
vec2 :: [2]f32

// A 3D vector type.
vec3 :: [3]f32

// A 2D integer vector type.
vec2i :: [2]i32

// A 4D vector type.
vec4 :: [4]f32

// A 2-by-3 matrix.
mat2x3 :: [6]f32

// An axis-aligned rectangle.
rect :: struct { x, y, w, h: f32 }

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Check if two 2D vectors are equal.
	vec2_equal :: proc(v0: vec2, v1: vec2) -> bool ---
	// Multiply a 2D vector by a scalar.
	vec2_mul :: proc(f: f32, v: vec2) -> vec2 ---
	// Add two 2D vectors
	vec2_add :: proc(v0: vec2, v1: vec2) -> vec2 ---
	// Transforms a vector by an affine transformation represented as a 2x3 matrix.
	mat2x3_mul :: proc(m: mat2x3, p: vec2) -> vec2 ---
	// Multiply two affine transformations represented as 2x3 matrices. Both matrices are treated as 3x3 matrices with an implicit `(0, 0, 1)` bottom row
	mat2x3_mul_m :: proc(lhs: mat2x3, rhs: mat2x3) -> mat2x3 ---
	// Invert an affine transform represented as a 2x3 matrix.
	mat2x3_inv :: proc(x: mat2x3) -> mat2x3 ---
	// Return a 2x3 matrix representing a rotation.
	mat2x3_rotate :: proc(radians: f32) -> mat2x3 ---
	// Return a 2x3 matrix representing a translation.
	mat2x3_translate :: proc(x: f32, y: f32) -> mat2x3 ---
}

////////////////////////////////////////////////////////////////////////////////
// Helpers for logging, asserting and aborting.
////////////////////////////////////////////////////////////////////////////////

// Constants allowing to specify the level of logging verbosity.
log_level :: enum u32 {
	// Only errors are logged.
	ERROR = 0,
	// Only warnings and errors are logged.
	WARNING = 1,
	// All messages are logged.
	INFO = 2,
	COUNT = 3,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	/*
	Abort the application, showing an error message.
	
	This function should not be called directly by user code, which should use the `OC_ABORT` macro instead, as the macro takes care of filling in the source location parameters of the function.
	*/
	abort_ext :: proc(file: cstring, function: cstring, line: i32, fmt: cstring, #c_vararg args: ..any) -> ! ---
	/*
	Tigger a failed assertion. This aborts the application, showing the failed assertion and an error message.
	
	This function should not be called directly by user code, which should use the `OC_ASSERT` macro instead. The macro checks the assert condition and calls the function if it is false. It also takes care of filling in the source location parameters of the function.
	*/
	assert_fail :: proc(file: cstring, function: cstring, line: i32, src: cstring, fmt: cstring, #c_vararg args: ..any) -> ! ---
	// Set the logging verbosity.
	log_set_level :: proc(level: log_level) ---
	/*
	Log a message to the console.
	
	This function should not be called directly by user code, which should use the `oc_log_XXX` family of macros instead. The macros take care of filling in the message level and source location parameters of the function.
	*/
	log_ext :: proc(level: log_level, function: cstring, file: cstring, line: i32, fmt: cstring, #c_vararg args: ..any) ---
}

////////////////////////////////////////////////////////////////////////////////
// Types and helpers for doubly-linked lists.
////////////////////////////////////////////////////////////////////////////////

// An element of an intrusive doubly-linked list.
list_elt :: struct {
	// Points to the previous element in the list.
	prev: ^list_elt,
	// Points to the next element in the list.
	next: ^list_elt,
}

// A doubly-linked list.
list :: struct {
	// Points to the first element in the list.
	first: ^list_elt,
	// Points to the last element in the list.
	last: ^list_elt,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Check if a list is empty.
	list_empty :: proc(list: list) -> bool ---
	// Zero-initializes a linked list.
	list_init :: proc(list: ^list) ---
	// Insert an element in a list after a given element.
	list_insert :: proc(list: ^list, afterElt: ^list_elt, elt: ^list_elt) ---
	// Insert an element in a list before a given element.
	list_insert_before :: proc(list: ^list, beforeElt: ^list_elt, elt: ^list_elt) ---
	// Remove an element from a list.
	list_remove :: proc(list: ^list, elt: ^list_elt) ---
	// Add an element at the end of a list.
	list_push_back :: proc(list: ^list, elt: ^list_elt) ---
	// Remove the last element from a list.
	list_pop_back :: proc(list: ^list) -> ^list_elt ---
	// Add an element at the beginning of a list.
	list_push_front :: proc(list: ^list, elt: ^list_elt) ---
	// Remove the first element from a list.
	list_pop_front :: proc(list: ^list) -> ^list_elt ---
}

////////////////////////////////////////////////////////////////////////////////
// Base allocator and memory arenas.
////////////////////////////////////////////////////////////////////////////////

// The prototype of a procedure to reserve memory from the system.
mem_reserve_proc :: proc "c" (_context: ^base_allocator, size: u64) -> rawptr

// The prototype of a procedure to modify a memory reservation.
mem_modify_proc :: proc "c" (_context: ^base_allocator, ptr: rawptr, size: u64)

// A structure that defines how to allocate memory from the system.
base_allocator :: struct {
	// A procedure to reserve memory from the system.
	reserve: mem_reserve_proc,
	// A procedure to commit memory from the system.
	commit: mem_modify_proc,
	// A procedure to decommit memory from the system.
	decommit: mem_modify_proc,
	// A procedure to release memory previously reserved from the system.
	release: mem_modify_proc,
}

// A contiguous chunk of memory managed by a memory arena.
arena_chunk :: struct {
	listElt: list_elt,
	ptr: cstring,
	offset: u64,
	committed: u64,
	cap: u64,
}

// A memory arena, allowing to allocate memory in a linear or stack-like fashion.
arena :: struct {
	// An allocator providing memory pages from the system
	base: ^base_allocator,
	// A list of `oc_arena_chunk` chunks.
	chunks: list,
	// The chunk new memory allocations are pulled from.
	currentChunk: ^arena_chunk,
}

// This struct provides a way to store the current offset in a given arena, in order to reset the arena to that offset later. This allows using arenas in a stack-like fashion, e.g. to create temporary "scratch" allocations
arena_scope :: struct {
	// The arena which offset is stored.
	arena: ^arena,
	// The arena chunk to which the offset belongs.
	chunk: ^arena_chunk,
	// The offset to rewind the arena to.
	offset: u64,
}

// Options for arena creation.
arena_options :: struct {
	// The base allocator to use with this arena
	base: ^base_allocator,
	// The amount of memory to reserve up-front when creating the arena.
	reserve: u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Initialize a memory arena.
	arena_init :: proc(arena: ^arena) ---
	// Initialize a memory arena with additional options.
	arena_init_with_options :: proc(arena: ^arena, options: ^arena_options) ---
	// Release all resources allocated to a memory arena.
	arena_cleanup :: proc(arena: ^arena) ---
	// Allocate a block of memory from an arena.
	arena_push :: proc(arena: ^arena, size: u64) -> rawptr ---
	// Allocate an aligned block of memory from an arena.
	arena_push_aligned :: proc(arena: ^arena, size: u64, alignment: u32) -> rawptr ---
	// Reset an arena. All memory that was previously allocated from this arena is released to the arena, and can be reallocated by later calls to `oc_arena_push` and similar functions. No memory is actually released _to the system_.
	arena_clear :: proc(arena: ^arena) ---
	// Begin a memory scope. This creates an `oc_arena_scope` object that stores the current offset of the arena. The arena can later be reset to that offset by calling `oc_arena_scope_end`, releasing all memory that was allocated within the scope to the arena.
	arena_scope_begin :: proc(arena: ^arena) -> arena_scope ---
	// End a memory scope. This resets an arena to the offset it had when the scope was created. All memory allocated within the scope is released back to the arena.
	arena_scope_end :: proc(scope: arena_scope) ---
	/*
	Begin a scratch scope. This creates a memory scope on a per-thread, global "scratch" arena. This allows easily creating temporary memory for scratch computations or intermediate results, in a stack-like fashion.
	
	If you must return results in an arena passed by the caller, and you also use a scratch arena to do intermediate computations, beware that the results arena could itself be a scatch arena. In this case, you have to be careful not to intermingle your scratch computations with the final result, or clear your result entirely. You can either:
	
	- Allocate memory for the result upfront and call `oc_scratch_begin` afterwards, if possible.
	- Use `oc_scratch_begin_next()` and pass it the result arena, to get a scratch arena that does not conflict with it.
	*/
	scratch_begin :: proc() -> arena_scope ---
	// Begin a scratch scope that does not conflict with a given arena. See `oc_scratch_begin()` for more details about when to use this function.
	scratch_begin_next :: proc(used: ^arena) -> arena_scope ---
}

////////////////////////////////////////////////////////////////////////////////
// String slices and string lists.
////////////////////////////////////////////////////////////////////////////////

// A type representing a string of bytes.
str8 :: string

// A type representing an element of a string list.
str8_elt :: struct {
	// The string element is linked into its parent string list through this field.
	listElt: list_elt,
	// The string for this element.
	string: str8,
}

// A type representing a string list.
str8_list :: struct {
	// A linked-list of `oc_str8_elt`.
	list: list,
	// The number of elements in `list`.
	eltCount: u64,
	// The total length of the string list, which is the sum of the lengths over all elements.
	len: u64,
}

// A type describing a string of 16-bits characters (typically used for UTF-16).
str16 :: distinct []u16

// A type representing an element of an `oc_str16` list.
str16_elt :: struct {
	// The string element is linked into its parent string list through this field.
	listElt: list_elt,
	// The string for this element.
	string: str16,
}

str16_list :: struct {
	// A linked-list of `oc_str16_elt`.
	list: list,
	// The number of elements in `list`.
	eltCount: u64,
	// The total length of the string list, which is the sum of the lengths over all elements.
	len: u64,
}

// A type describing a string of 32-bits characters (typically used for UTF-32 codepoints).
str32 :: distinct []rune

// A type representing an element of an `oc_str32` list.
str32_elt :: struct {
	// The string element is linked into its parent string list through this field.
	listElt: list_elt,
	// The string for this element.
	string: str32,
}

str32_list :: struct {
	// A linked-list of `oc_str32_elt`.
	list: list,
	// The number of elements in `list`.
	eltCount: u64,
	// The total length of the string list, which is the sum of the lengths over all elements.
	len: u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Make a string from a bytes buffer and a length.
	str8_from_buffer :: proc(len: u64, buffer: [^]char) -> str8 ---
	// Make a string from a slice of another string. The resulting string designates some subsequence of the input string.
	str8_slice :: proc(s: str8, start: u64, end: u64) -> str8 ---
	// Pushes a copy of a buffer to an arena, and makes a string refering to that copy.
	str8_push_buffer :: proc(arena: ^arena, len: u64, buffer: [^]char) -> str8 ---
	// Pushes a copy of a C null-terminated string to an arena, and makes a string referring to that copy.
	str8_push_cstring :: proc(arena: ^arena, str: cstring) -> str8 ---
	// Copy the contents of a string on an arena and make a new string referring to the copied bytes.
	str8_push_copy :: proc(arena: ^arena, s: str8) -> str8 ---
	// Make a copy of a string slice. This function copies a subsequence of the input string onto an arena, and returns a new string referring to the copied content.
	str8_push_slice :: proc(arena: ^arena, s: str8, start: u64, end: u64) -> str8 ---
	// Lexicographically compare the contents of two strings.
	str8_cmp :: proc(s1: str8, s2: str8) -> i32 ---
	// Create a null-terminated C-string from an `oc_str8` string.
	str8_to_cstring :: proc(arena: ^arena, string: str8) -> cstring ---
	// Push a string element to the back of a string list. This creates a `oc_str8_elt` element referring to the contents of the input string, and links that element at the end of the string list.
	str8_list_push :: proc(arena: ^arena, list: ^str8_list, str: str8) ---
	// Build a string from a null-terminated format string an variadic arguments, and append it to a string list.
	str8_list_pushf :: proc(arena: ^arena, list: ^str8_list, format: cstring, #c_vararg args: ..any) ---
	// Build a string by combining the elements of a string list with a prefix, a suffix, and separators.
	str8_list_collate :: proc(arena: ^arena, list: str8_list, prefix: str8, separator: str8, suffix: str8) -> str8 ---
	// Build a string by joining the elements of a string list.
	str8_list_join :: proc(arena: ^arena, list: str8_list) -> str8 ---
	/*
	Split a list into a string list according to separators.
	
	No string copies are made. The elements of the resulting string list refer to subsequences of the input string.
	*/
	str8_split :: proc(arena: ^arena, str: str8, separators: str8_list) -> str8_list ---
	// Make an `oc_str16` string from a buffer of 16-bit characters.
	str16_from_buffer :: proc(len: u64, buffer: [^]u16) -> str16 ---
	// Make an `oc_str16` string from a slice of another `oc_str16` string.
	str16_slice :: proc(s: str16, start: u64, end: u64) -> str16 ---
	// Copy the content of a 16-bit character buffer on an arena and make a new `oc_str16` referencing the copied contents.
	str16_push_buffer :: proc(arena: ^arena, len: u64, buffer: [^]u16) -> str16 ---
	// Copy the contents of an `oc_str16` string and make a new string referencing the copied contents.
	str16_push_copy :: proc(arena: ^arena, s: str16) -> str16 ---
	// Copy a slice of an `oc_str16` string an make a new string referencing the copies contents.
	str16_push_slice :: proc(arena: ^arena, s: str16, start: u64, end: u64) -> str16 ---
	// Push a string element to the back of a string list. This creates a `oc_str16_elt` element referring to the contents of the input string, and links that element at the end of the string list.
	str16_list_push :: proc(arena: ^arena, list: ^str16_list, str: str16) ---
	// Build a string by joining the elements of a string list.
	str16_list_join :: proc(arena: ^arena, list: str16_list) -> str16 ---
	/*
	Split a list into a string list according to separators.
	
	No string copies are made. The elements of the resulting string list refer to subsequences of the input string.
	*/
	str16_split :: proc(arena: ^arena, str: str16, separators: str16_list) -> str16_list ---
	// Make an `oc_str32` string from a buffer of 32-bit characters.
	str32_from_buffer :: proc(len: u64, buffer: [^]u32) -> str32 ---
	// Make an `oc_str32` string from a slice of another `oc_str32` string.
	str32_slice :: proc(s: str32, start: u64, end: u64) -> str32 ---
	// Copy the content of a 32-bit character buffer on an arena and make a new `oc_str32` referencing the copied contents.
	str32_push_buffer :: proc(arena: ^arena, len: u64, buffer: [^]u32) -> str32 ---
	// Copy the contents of an `oc_str32` string and make a new string referencing the copied contents.
	str32_push_copy :: proc(arena: ^arena, s: str32) -> str32 ---
	// Copy a slice of an `oc_str32` string an make a new string referencing the copies contents.
	str32_push_slice :: proc(arena: ^arena, s: str32, start: u64, end: u64) -> str32 ---
	// Push a string element to the back of a string list. This creates a `oc_str32_elt` element referring to the contents of the input string, and links that element at the end of the string list.
	str32_list_push :: proc(arena: ^arena, list: ^str32_list, str: str32) ---
	// Build a string by joining the elements of a string list.
	str32_list_join :: proc(arena: ^arena, list: str32_list) -> str32 ---
	/*
	Split a list into a string list according to separators.
	
	No string copies are made. The elements of the resulting string list refer to subsequences of the input string.
	*/
	str32_split :: proc(arena: ^arena, str: str32, separators: str32_list) -> str32_list ---
}

////////////////////////////////////////////////////////////////////////////////
// UTF8 encoding/decoding.
////////////////////////////////////////////////////////////////////////////////

// A unicode codepoint.
utf32 :: rune

// A type representing the result of decoding of utf8-encoded codepoint.
utf8_dec :: struct {
	// The decoded codepoint.
	codepoint: utf32,
	// The size of the utf8 sequence encoding that codepoint.
	size: u32,
}

// A type representing a contiguous range of unicode codepoints.
unicode_range :: struct {
	// The first codepoint of the range.
	firstCodePoint: utf32,
	// The number of codepoints in the range.
	count: u32,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Get the size of a utf8-encoded codepoint for the first byte of the encoded sequence.
	utf8_size_from_leading_char :: proc(leadingChar: char) -> u32 ---
	// Get the size of the utf8 encoding of a codepoint.
	utf8_codepoint_size :: proc(codePoint: utf32) -> u32 ---
	utf8_codepoint_count_for_string :: proc(string: str8) -> u64 ---
	// Get the length of the utf8 encoding of a sequence of unicode codepoints.
	utf8_byte_count_for_codepoints :: proc(codePoints: str32) -> u64 ---
	// Get the offset of the next codepoint after a given offset, in a utf8 encoded string.
	utf8_next_offset :: proc(string: str8, byteOffset: u64) -> u64 ---
	// Get the offset of the previous codepoint before a given offset, in a utf8 encoded string.
	utf8_prev_offset :: proc(string: str8, byteOffset: u64) -> u64 ---
	// Decode a utf8 encoded codepoint.
	utf8_decode :: proc(string: str8) -> utf8_dec ---
	// Decode a codepoint at a given offset in a utf8 encoded string.
	utf8_decode_at :: proc(string: str8, offset: u64) -> utf8_dec ---
	// Encode a unicode codepoint into a utf8 sequence.
	utf8_encode :: proc(dst: cstring, codePoint: utf32) -> str8 ---
	// Decode a utf8 string to a string of unicode codepoints using memory passed by the caller.
	utf8_to_codepoints :: proc(maxCount: u64, backing: ^utf32, string: str8) -> str32 ---
	// Encode a string of unicode codepoints into a utf8 string using memory passed by the caller.
	utf8_from_codepoints :: proc(maxBytes: u64, backing: cstring, codePoints: str32) -> str8 ---
	// Decode a utf8 encoded string to a string of unicode codepoints using an arena.
	utf8_push_to_codepoints :: proc(arena: ^arena, string: str8) -> str32 ---
	// Encode a string of unicode codepoints into a utf8 string using an arena.
	utf8_push_from_codepoints :: proc(arena: ^arena, codePoints: str32) -> str8 ---
}

////////////////////////////////////////////////////////////////////////////////
// Input, windowing, dialogs.
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// Application events.
////////////////////////////////////////////////////////////////////////////////

// This enum defines the type events that can be sent to the application by the runtime. This determines which member of the `oc_event` union field is active.
event_type :: enum u32 {
	// No event. That could be used simply to wake up the application.
	NONE = 0,
	// A modifier key event. This event is sent when a key such as <kbd>Alt</kbd>, <kbd>Control</kbd>, <kbd>Command</kbd> or <kbd>Shift</kbd> are pressed, released, or repeated. The `key` field contains the event's details.
	KEYBOARD_MODS = 1,
	// A key event. This event is sent when a normal key is pressed, released, or repeated. The `key` field contains the event's details.
	KEYBOARD_KEY = 2,
	// A character input event. This event is sent when an input character is produced by the keyboard. The `character` field contains the event's details.
	KEYBOARD_CHAR = 3,
	// A mouse button event. This is event sent when one of the mouse buttons is pressed, released, or clicked. The `key` field contains the event's details.
	MOUSE_BUTTON = 4,
	// A mouse move event. This is event sent when the mouse is moved. The `mouse` field contains the event's details.
	MOUSE_MOVE = 5,
	// A mouse wheel event. This is event sent when the mouse wheel is moved (or when a trackpad is scrolled). The `mouse` field contains the event's details.
	MOUSE_WHEEL = 6,
	// A mouse enter event. This event is sent when the mouse enters the application's window. The `mouse` field contains the event's details.
	MOUSE_ENTER = 7,
	// A mouse leave event. This event is sent when the mouse leaves the application's window.
	MOUSE_LEAVE = 8,
	// A clipboard paste event. This event is sent when the user uses the paste shortcut while the application window has focus.
	CLIPBOARD_PASTE = 9,
	// A resize event. This event is sent when the application's window is resized. The `move` field contains the event's details.
	WINDOW_RESIZE = 10,
	// A move event. This event is sent when the window is moved. The `move` field contains the event's details.
	WINDOW_MOVE = 11,
	// A focus event. This event is sent when the application gains focus.
	WINDOW_FOCUS = 12,
	// An unfocus event. This event is sent when the application looses focus.
	WINDOW_UNFOCUS = 13,
	// A hide event. This event is sent when the application's window is hidden or minimized.
	WINDOW_HIDE = 14,
	// A show event. This event is sent when the application's window is shown or de-minimized.
	WINDOW_SHOW = 15,
	// A close event. This event is sent when the window is about to be closed.
	WINDOW_CLOSE = 16,
	// A path drop event. This event is sent when the user drops files onto the application's window. The `paths` field contains the event's details.
	PATHDROP = 17,
	// A frame event. This event is sent when the application should render a frame.
	FRAME = 18,
	// A quit event. This event is sent when the application has been requested to quit.
	QUIT = 19,
}

// This enum describes the actions that can happen to a key.
key_action :: enum u32 {
	// No action happened on that key.
	NO_ACTION = 0,
	// The key was pressed.
	PRESS = 1,
	// The key was released.
	RELEASE = 2,
	// The key was maintained pressed at least for the system's key repeat period.
	REPEAT = 3,
}

// A code representing a key's physical location. This is independent of the system's keyboard layout.
scan_code :: enum u32 {
	UNKNOWN = 0,
	SPACE = 32,
	APOSTROPHE = 39,
	COMMA = 44,
	MINUS = 45,
	PERIOD = 46,
	SLASH = 47,
	_0 = 48,
	_1 = 49,
	_2 = 50,
	_3 = 51,
	_4 = 52,
	_5 = 53,
	_6 = 54,
	_7 = 55,
	_8 = 56,
	_9 = 57,
	SEMICOLON = 59,
	EQUAL = 61,
	LEFT_BRACKET = 91,
	BACKSLASH = 92,
	RIGHT_BRACKET = 93,
	GRAVE_ACCENT = 96,
	A = 97,
	B = 98,
	C = 99,
	D = 100,
	E = 101,
	F = 102,
	G = 103,
	H = 104,
	I = 105,
	J = 106,
	K = 107,
	L = 108,
	M = 109,
	N = 110,
	O = 111,
	P = 112,
	Q = 113,
	R = 114,
	S = 115,
	T = 116,
	U = 117,
	V = 118,
	W = 119,
	X = 120,
	Y = 121,
	Z = 122,
	WORLD_1 = 161,
	WORLD_2 = 162,
	ESCAPE = 256,
	ENTER = 257,
	TAB = 258,
	BACKSPACE = 259,
	INSERT = 260,
	DELETE = 261,
	RIGHT = 262,
	LEFT = 263,
	DOWN = 264,
	UP = 265,
	PAGE_UP = 266,
	PAGE_DOWN = 267,
	HOME = 268,
	END = 269,
	CAPS_LOCK = 280,
	SCROLL_LOCK = 281,
	NUM_LOCK = 282,
	PRINT_SCREEN = 283,
	PAUSE = 284,
	F1 = 290,
	F2 = 291,
	F3 = 292,
	F4 = 293,
	F5 = 294,
	F6 = 295,
	F7 = 296,
	F8 = 297,
	F9 = 298,
	F10 = 299,
	F11 = 300,
	F12 = 301,
	F13 = 302,
	F14 = 303,
	F15 = 304,
	F16 = 305,
	F17 = 306,
	F18 = 307,
	F19 = 308,
	F20 = 309,
	F21 = 310,
	F22 = 311,
	F23 = 312,
	F24 = 313,
	F25 = 314,
	KP_0 = 320,
	KP_1 = 321,
	KP_2 = 322,
	KP_3 = 323,
	KP_4 = 324,
	KP_5 = 325,
	KP_6 = 326,
	KP_7 = 327,
	KP_8 = 328,
	KP_9 = 329,
	KP_DECIMAL = 330,
	KP_DIVIDE = 331,
	KP_MULTIPLY = 332,
	KP_SUBTRACT = 333,
	KP_ADD = 334,
	KP_ENTER = 335,
	KP_EQUAL = 336,
	LEFT_SHIFT = 340,
	LEFT_CONTROL = 341,
	LEFT_ALT = 342,
	LEFT_SUPER = 343,
	RIGHT_SHIFT = 344,
	RIGHT_CONTROL = 345,
	RIGHT_ALT = 346,
	RIGHT_SUPER = 347,
	MENU = 348,
	COUNT = 349,
}

// A code identifying a key. The physical location of the key corresponding to a given key code depends on the system's keyboard layout.
key_code :: enum u32 {
	UNKNOWN = 0,
	SPACE = 32,
	APOSTROPHE = 39,
	COMMA = 44,
	MINUS = 45,
	PERIOD = 46,
	SLASH = 47,
	_0 = 48,
	_1 = 49,
	_2 = 50,
	_3 = 51,
	_4 = 52,
	_5 = 53,
	_6 = 54,
	_7 = 55,
	_8 = 56,
	_9 = 57,
	SEMICOLON = 59,
	EQUAL = 61,
	LEFT_BRACKET = 91,
	BACKSLASH = 92,
	RIGHT_BRACKET = 93,
	GRAVE_ACCENT = 96,
	A = 97,
	B = 98,
	C = 99,
	D = 100,
	E = 101,
	F = 102,
	G = 103,
	H = 104,
	I = 105,
	J = 106,
	K = 107,
	L = 108,
	M = 109,
	N = 110,
	O = 111,
	P = 112,
	Q = 113,
	R = 114,
	S = 115,
	T = 116,
	U = 117,
	V = 118,
	W = 119,
	X = 120,
	Y = 121,
	Z = 122,
	WORLD_1 = 161,
	WORLD_2 = 162,
	ESCAPE = 256,
	ENTER = 257,
	TAB = 258,
	BACKSPACE = 259,
	INSERT = 260,
	DELETE = 261,
	RIGHT = 262,
	LEFT = 263,
	DOWN = 264,
	UP = 265,
	PAGE_UP = 266,
	PAGE_DOWN = 267,
	HOME = 268,
	END = 269,
	CAPS_LOCK = 280,
	SCROLL_LOCK = 281,
	NUM_LOCK = 282,
	PRINT_SCREEN = 283,
	PAUSE = 284,
	F1 = 290,
	F2 = 291,
	F3 = 292,
	F4 = 293,
	F5 = 294,
	F6 = 295,
	F7 = 296,
	F8 = 297,
	F9 = 298,
	F10 = 299,
	F11 = 300,
	F12 = 301,
	F13 = 302,
	F14 = 303,
	F15 = 304,
	F16 = 305,
	F17 = 306,
	F18 = 307,
	F19 = 308,
	F20 = 309,
	F21 = 310,
	F22 = 311,
	F23 = 312,
	F24 = 313,
	F25 = 314,
	KP_0 = 320,
	KP_1 = 321,
	KP_2 = 322,
	KP_3 = 323,
	KP_4 = 324,
	KP_5 = 325,
	KP_6 = 326,
	KP_7 = 327,
	KP_8 = 328,
	KP_9 = 329,
	KP_DECIMAL = 330,
	KP_DIVIDE = 331,
	KP_MULTIPLY = 332,
	KP_SUBTRACT = 333,
	KP_ADD = 334,
	KP_ENTER = 335,
	KP_EQUAL = 336,
	LEFT_SHIFT = 340,
	LEFT_CONTROL = 341,
	LEFT_ALT = 342,
	LEFT_SUPER = 343,
	RIGHT_SHIFT = 344,
	RIGHT_CONTROL = 345,
	RIGHT_ALT = 346,
	RIGHT_SUPER = 347,
	MENU = 348,
	COUNT = 349,
}

keymod_flag :: enum u32 {
	ALT = 0,
	SHIFT,
	CTRL,
	CMD,
	MAIN_MODIFIER,
}
keymod_flags :: bit_set[keymod_flag; u32]

// A code identifying a mouse button.
mouse_button :: enum u32 {
	LEFT = 0,
	RIGHT = 1,
	MIDDLE = 2,
	EXT1 = 3,
	EXT2 = 4,
	BUTTON_COUNT = 5,
}

// A structure describing a key event or a mouse button event.
key_event :: struct {
	// The action that was done on the key.
	action: key_action,
	// The scan code of the key. Only valid for key events.
	scanCode: scan_code,
	// The key code of the key. Only valid for key events.
	keyCode: key_code,
	// The button of the mouse. Only valid for mouse button events.
	button: mouse_button,
	// Modifier flags indicating which modifier keys where pressed at the time of the event.
	mods: keymod_flags,
	// The number of clicks that where detected for the button. Only valid for mouse button events.
	clickCount: u8,
}

// A structure describing a character input event.
char_event :: struct {
	// The unicode codepoint of the character.
	codepoint: utf32,
	// The utf8 sequence of the character.
	sequence: [8]char,
	// The utf8 sequence length.
	seqLen: u8,
}

// A structure describing a mouse move or a mouse wheel event. Mouse coordinates have their origin at the top-left corner of the window, with the y axis going down.
mouse_event :: struct {
	// The x coordinate of the mouse.
	x: f32,
	// The y coordinate of the mouse.
	y: f32,
	// The delta from the last x coordinate of the mouse, or the scroll value along the x coordinate.
	deltaX: f32,
	// The delta from the last y coordinate of the mouse, or the scoll value along the y  coordinate.
	deltaY: f32,
	// Modifier flags indicating which modifier keys where pressed at the time of the event.
	mods: keymod_flags,
}

// A structure describing a window move or resize event.
move_event :: struct {
	// The position and dimension of the frame rectangle, i.e. including the window title bar and border.
	frame: rect,
	// The position and dimension of the content rectangle, relative to the frame rectangle.
	content: rect,
}

// A structure describing an event sent to the application.
event :: struct {
	// The window in which this event happened.
	window: window,
	// The type of the event. This determines which member of the event union is active.
	type: event_type,
	using _: struct #raw_union {
		key: key_event,
		character: char_event,
		mouse: mouse_event,
		move: move_event,
		paths: str8_list,
	},
}

// This enum describes the kinds of possible file dialogs.
file_dialog_kind :: enum u32 {
	// The file dialog is a save dialog.
	SAVE = 0,
	// The file dialog is an open dialog.
	OPEN = 1,
}

// A type for flags describing various file dialog options.
// File dialog flags.
file_dialog_flag :: enum u32 {
	// This dialog allows selecting files.
	FILES = 1,
	// This dialog allows selecting directories.
	DIRECTORIES,
	// This dialog allows selecting multiple items.
	MULTIPLE,
	// This dialog allows creating directories.
	CREATE_DIRECTORIES,
}
file_dialog_flags :: bit_set[file_dialog_flag; u32]

// A structure describing a file dialog.
file_dialog_desc :: struct {
	// The kind of file dialog, see `oc_file_dialog_kind`.
	kind: file_dialog_kind,
	// A combination of file dialog flags used to enable file dialog options.
	flags: file_dialog_flags,
	// The title of the dialog, displayed in the dialog title bar.
	title: str8,
	// Optional. The label of the OK button, e.g. "Save" or "Open".
	okLabel: str8,
	// Optional. A file handle to the root directory for the dialog. If set to zero, the root directory is the application's default data directory.
	startAt: file,
	// Optional. The path of the starting directory of the dialog, relative to its root directory. If set to nil, the dialog starts at its root directory.
	startPath: str8,
	// A list of file extensions used to restrict which files can be selected in this dialog. An empty list allows all files to be selected. Extensions should be provided without a leading dot.
	filters: str8_list,
}

// An enum identifying the button clicked by the user when a file dialog returns.
file_dialog_button :: enum u32 {
	// The user clicked the "Cancel" button, or closed the dialog box.
	CANCEL = 0,
	// The user clicked the "OK" button.
	OK = 1,
}

// A structure describing the result of a file dialog.
file_dialog_result :: struct {
	// The button clicked by the user.
	button: file_dialog_button,
	// The path that was selected when the user clicked the OK button. If the dialog box had the `OC_FILE_DIALOG_MULTIPLE` flag set, this is the first file of the list of selected paths.
	path: str8,
	// If the dialog box had the `OC_FILE_DIALOG_MULTIPLE` flag set and the user clicked the OK button, this list contains the selected paths.
	selection: str8_list,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Set the title of the application's window.
	window_set_title :: proc(title: str8) ---
	// Set the size of the application's window.
	window_set_size :: proc(size: vec2) ---
	// Request the system to quit the application.
	request_quit :: proc() ---
	// Convert a scancode to a keycode, according to current keyboard layout.
	scancode_to_keycode :: proc(scanCode: scan_code) -> key_code ---
	// Put a string in the clipboard.
	clipboard_set_string :: proc(string: str8) ---
}

////////////////////////////////////////////////////////////////////////////////
// File input/output.
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// API for opening, reading and writing files.
////////////////////////////////////////////////////////////////////////////////

// An opaque handle identifying an opened file.
file :: distinct u64

// The type of file open flags describing file open options.
// Flags for the `oc_file_open()` function.
file_open_flag :: enum u16 {
	// Open the file in 'append' mode. All writes append data at the end of the file.
	APPEND = 1,
	// Truncate the file to 0 bytes when opening.
	TRUNCATE,
	// Create the file if it does not exist.
	CREATE,
	// If the file is a symlink, open the symlink itself instead of following it.
	SYMLINK,
	// If the file is a symlink, the call to open will fail.
	NO_FOLLOW,
	// Reserved.
	RESTRICT,
}
file_open_flags :: bit_set[file_open_flag; u16]

// This enum describes the access permissions of a file handle.
file_access_flag :: enum u16 {
	// The file handle can be used for reading from the file.
	READ = 1,
	// The file handle can be used for writing to the file.
	WRITE,
}
file_access :: bit_set[file_access_flag; u16]

// This enum is used in `oc_file_seek()` to specify the starting point of the seek operation.
file_whence :: enum u32 {
	// Set the file position relative to the beginning of the file.
	SET = 0,
	// Set the file position relative to the end of the file.
	END = 1,
	// Set the file position relative to the current position.
	CURRENT = 2,
}

// A type used to identify I/O requests.
io_req_id :: u64

// A type used to identify I/O operations.
// This enum declares all I/O operations.
io_op :: enum u32 {
	// ['Open a file at a path relative to a given root directory.', '', "    - `handle` is the handle to the root directory. If it is nil, the application's default directory is used.", '    - `size` is the size of the path, in bytes.', '    - `buffer` points to an array containing the path of the file to open, relative to the directory identified by `handle`.', '    - `open` contains the permissions and flags for the open operation.']
	OPEN_AT = 0,
	// ['Close a file handle.', '', '    - `handle` is the handle to close.']
	CLOSE = 1,
	// ['Get status information for a file handle.', '', '    - `handle` is the handle to stat.', '    - `size` is the size of the result buffer. It should be at least `sizeof(oc_file_status)`.', '    - `buffer` is the result buffer.']
	FSTAT = 2,
	// ['Move the file position in a file.', '', '    - `handle` is the handle of the file.', '    - `offset` specifies the offset of the new position, relative to the base position specified by `whence`.', '    - `whence` determines the base position for the seek operation.']
	SEEK = 3,
	// ['Read data from a file.', '', '    - `handle` is the handle of the file.', '    - `size` is the number of bytes to read.', '    - `buffer` is the result buffer. It should be big enough to hold `size` bytes.']
	READ = 4,
	// ['Write data to a file.', '', '    - `handle` is the handle of the file.', '    - `size` is the number of bytes to write.', '    - `buffer` contains the data to write to the file.']
	WRITE = 5,
	// ['Get the error attached to a file handle.', '', '    - `handle` is the handle of the file.']
	OC_OC_IO_ERROR = 6,
}

// A structure describing an I/O request.
io_req :: struct {
	// An identifier for the request. You can set this to any value you want. It is passed back in the `oc_io_cmp` completion and can be used to match requests and completions.
	id: io_req_id,
	// The requested operation.
	op: io_op,
	// A file handle used by some operations.
	handle: file,
	// An offset used by some operations.
	offset: i64,
	// A size indicating the capacity of the buffer pointed to by `buffer`, in bytes.
	size: u64,
	using _: struct #raw_union {
		buffer: [^]char,
		unused: u64,
	},
	using _: struct #raw_union {
		open: struct {
			// The access permissions requested on the file to open.
			rights: file_access,
			// The options to use when opening the file.
			flags: file_open_flags,
		},
		whence: file_whence,
	},
}

// A type identifying an I/O error.
// This enum declares all I/O error values.
io_error :: enum u32 {
	// No error.
	OK = 0,
	// An unexpected error happened.
	UNKNOWN = 1,
	// The request had an invalid operation.
	OP = 2,
	// The request had an invalid handle.
	HANDLE = 3,
	// The operation was not carried out because the file handle has previous errors.
	PREV = 4,
	// The request contained wrong arguments.
	ARG = 5,
	// The operation requires permissions that the file handle doesn't have.
	PERM = 6,
	// The operation couldn't complete due to a lack of space in the result buffer.
	SPACE = 7,
	// One of the directory in the path does not exist or couldn't be traversed.
	NO_ENTRY = 8,
	// The file already exists.
	EXISTS = 9,
	// The file is not a directory.
	NOT_DIR = 10,
	// The file is a directory.
	DIR = 11,
	// There are too many opened files.
	MAX_FILES = 12,
	// The path contains too many symbolic links (this may be indicative of a symlink loop).
	MAX_LINKS = 13,
	// The path is too long.
	PATH_LENGTH = 14,
	// The file is too large.
	FILE_SIZE = 15,
	// The file is too large to be opened.
	OVERFLOW = 16,
	// The file is locked or the device on which it is stored is not ready.
	NOT_READY = 17,
	// The system is out of memory.
	MEM = 18,
	// The operation was interrupted by a signal.
	INTERRUPT = 19,
	// A physical error happened.
	PHYSICAL = 20,
	// The device on which the file is stored was not found.
	NO_DEVICE = 21,
	// One element along the path is outside the root directory subtree.
	WALKOUT = 22,
}

// A structure describing the completion of an I/O operation.
io_cmp :: struct {
	// The request ID as passed in the `oc_io_req` request that generated this completion.
	id: io_req_id,
	// The error value for the operation.
	error: io_error,
	using _: struct #raw_union {
		result: i64,
		size: u64,
		offset: i64,
		handle: file,
	},
}

// An enum identifying the type of a file.
file_type :: enum u32 {
	// The file is of unknown type.
	UNKNOWN = 0,
	// The file is a regular file.
	REGULAR = 1,
	// The file is a directory.
	DIRECTORY = 2,
	// The file is a symbolic link.
	SYMLINK = 3,
	// The file is a block device.
	BLOCK = 4,
	// The file is a character device.
	CHARACTER = 5,
	// The file is a FIFO pipe.
	FIFO = 6,
	// The file is a socket.
	SOCKET = 7,
}

// A type describing file permissions.
file_perm_flag :: enum u16 {
	OTHER_EXEC = 1,
	OTHER_WRITE,
	OTHER_READ,
	GROUP_EXEC,
	GROUP_WRITE,
	GROUP_READ,
	OWNER_EXEC,
	OWNER_WRITE,
	OWNER_READ,
	STICKY_BIT,
	SET_GID,
	SET_UID,
}
file_perm :: bit_set[file_perm_flag; u16]

datestamp :: struct {
	seconds: i64,
	fraction: u64,
}

file_status :: struct {
	uid: u64,
	type: file_type,
	perm: file_perm,
	size: u64,
	creationDate: datestamp,
	accessDate: datestamp,
	modificationDate: datestamp,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Send a single I/O request and wait for its completion.
	io_wait_single_req :: proc(req: ^io_req) -> io_cmp ---
	// Returns a `nil` file handle
	file_nil :: proc() -> file ---
	// Test if a file handle is `nil`.
	file_is_nil :: proc(handle: file) -> bool ---
	// Open a file in the applications' default directory subtree.
	file_open :: proc(path: str8, rights: file_access, flags: file_open_flags) -> file ---
	// Open a file in a given directory's subtree.
	file_open_at :: proc(dir: file, path: str8, rights: file_access, flags: file_open_flags) -> file ---
	// Close a file.
	file_close :: proc(file: file) ---
	// Get the current position in a file.
	file_pos :: proc(file: file) -> i64 ---
	// Set the current position in a file.
	file_seek :: proc(file: file, offset: i64, whence: file_whence) -> i64 ---
	// Write data to a file.
	file_write :: proc(file: file, size: u64, buffer: [^]char) -> u64 ---
	// Read from a file.
	file_read :: proc(file: file, size: u64, buffer: [^]char) -> u64 ---
	// Get the last error on a file handle.
	file_last_error :: proc(handle: file) -> io_error ---
	file_get_status :: proc(file: file) -> file_status ---
	file_size :: proc(file: file) -> u64 ---
	file_open_with_request :: proc(path: str8, rights: file_access, flags: file_open_flags) -> file ---
}

////////////////////////////////////////////////////////////////////////////////
// API for obtaining file capabilities through open/save dialogs.
////////////////////////////////////////////////////////////////////////////////

// An element of a list of file handles acquired through a file dialog.
file_open_with_dialog_elt :: struct {
	listElt: list_elt,
	file: file,
}

// A structure describing the result of a call to `oc_file_open_with_dialog()`.
file_open_with_dialog_result :: struct {
	// The button of the file dialog clicked by the user.
	button: file_dialog_button,
	// The file that was opened through the dialog. If the dialog had the `OC_FILE_DIALOG_MULTIPLE` flag set, this is equal to the first handle in the `selection` list.
	file: file,
	// If the dialog had the `OC_FILE_DIALOG_MULTIPLE` flag set, this list of `oc_file_open_with_dialog_elt` contains the handles of the opened files.
	selection: list,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Open files through a file dialog. This allows the user to select files outside the root directories currently accessible to the applications, giving them a way to provide new file capabilities to the application.
	file_open_with_dialog :: proc(arena: ^arena, rights: file_access, flags: file_open_flags, desc: ^file_dialog_desc) -> file_open_with_dialog_result ---
}

////////////////////////////////////////////////////////////////////////////////
// API for handling filesystem paths.
////////////////////////////////////////////////////////////////////////////////

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	// Get a string slice of the directory part of a path.
	path_slice_directory :: proc(path: str8) -> str8 ---
	// Get a string slice of the file name part of a path.
	path_slice_filename :: proc(path: str8) -> str8 ---
	// Split a path into path elements.
	path_split :: proc(arena: ^arena, path: str8) -> str8_list ---
	// Join path elements to form a path.
	path_join :: proc(arena: ^arena, elements: str8_list) -> str8 ---
	// Append a path to another path.
	path_append :: proc(arena: ^arena, parent: str8, relPath: str8) -> str8 ---
	// Test wether a path is an absolute path.
	path_is_absolute :: proc(path: str8) -> bool ---
}

////////////////////////////////////////////////////////////////////////////////
// 2D/3D rendering APIs.
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// A 2D Vector Graphics API.
////////////////////////////////////////////////////////////////////////////////

surface :: distinct u64

canvas_renderer :: distinct u64

canvas_context :: distinct u64

font :: distinct u64

image :: distinct u64

gradient_blend_space :: enum u32 {
	LINEAR = 0,
	SRGB = 1,
}

color_space :: enum u32 {
	RGB = 0,
	SRGB = 1,
}

color :: struct { using c: [4]f32, colorSpace: color_space }

joint_type :: enum u32 {
	MITER = 0,
	BEVEL = 1,
	NONE = 2,
}

cap_type :: enum u32 {
	NONE = 0,
	SQUARE = 1,
}

font_metrics :: struct {
	ascent: f32,
	descent: f32,
	lineGap: f32,
	xHeight: f32,
	capHeight: f32,
	width: f32,
}

glyph_metrics :: struct {
	ink: rect,
	advance: vec2,
}

text_metrics :: struct {
	ink: rect,
	logical: rect,
	advance: vec2,
}

rect_atlas :: struct {}

image_region :: struct {
	image: image,
	rect: rect,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	surface_nil :: proc() -> surface ---
	surface_is_nil :: proc(surface: surface) -> bool ---
	surface_destroy :: proc(surface: surface) ---
	surface_get_size :: proc(surface: surface) -> vec2 ---
	surface_contents_scaling :: proc(surface: surface) -> vec2 ---
	surface_bring_to_front :: proc(surface: surface) ---
	surface_send_to_back :: proc(surface: surface) ---
	surface_get_hidden :: proc(surface: surface) -> bool ---
	surface_set_hidden :: proc(surface: surface, hidden: bool) ---
	color_rgba :: proc(r: f32, g: f32, b: f32, a: f32) -> color ---
	color_srgba :: proc(r: f32, g: f32, b: f32, a: f32) -> color ---
	color_convert :: proc(_color: color, colorSpace: color_space) -> color ---
	canvas_renderer_nil :: proc() -> canvas_renderer ---
	canvas_renderer_is_nil :: proc(renderer: canvas_renderer) -> bool ---
	canvas_renderer_create :: proc() -> canvas_renderer ---
	canvas_renderer_destroy :: proc(renderer: canvas_renderer) ---
	canvas_render :: proc(renderer: canvas_renderer, _context: canvas_context, surface: surface) ---
	canvas_present :: proc(renderer: canvas_renderer, surface: surface) ---
	canvas_surface_create :: proc(renderer: canvas_renderer) -> surface ---
	canvas_surface_swap_interval :: proc(surface: surface, swap: i32) ---
	canvas_context_nil :: proc() -> canvas_context ---
	canvas_context_is_nil :: proc(_context: canvas_context) -> bool ---
	canvas_context_create :: proc() -> canvas_context ---
	canvas_context_destroy :: proc(_context: canvas_context) ---
	canvas_context_select :: proc(_context: canvas_context) -> canvas_context ---
	canvas_context_set_msaa_sample_count :: proc(_context: canvas_context, sampleCount: u32) ---
	font_nil :: proc() -> font ---
	font_is_nil :: proc(font: font) -> bool ---
	font_create_from_memory :: proc(mem: str8, rangeCount: u32, ranges: ^unicode_range) -> font ---
	font_create_from_file :: proc(file: file, rangeCount: u32, ranges: ^unicode_range) -> font ---
	font_create_from_path :: proc(path: str8, rangeCount: u32, ranges: ^unicode_range) -> font ---
	font_destroy :: proc(font: font) ---
	font_get_glyph_indices :: proc(font: font, codePoints: str32, backing: str32) -> str32 ---
	font_push_glyph_indices :: proc(arena: ^arena, font: font, codePoints: str32) -> str32 ---
	font_get_glyph_index :: proc(font: font, codePoint: utf32) -> u32 ---
	font_get_metrics :: proc(font: font, emSize: f32) -> font_metrics ---
	font_get_metrics_unscaled :: proc(font: font) -> font_metrics ---
	font_get_scale_for_em_pixels :: proc(font: font, emSize: f32) -> f32 ---
	font_text_metrics_utf32 :: proc(font: font, fontSize: f32, codepoints: str32) -> text_metrics ---
	font_text_metrics :: proc(font: font, fontSize: f32, text: str8) -> text_metrics ---
	image_nil :: proc() -> image ---
	image_is_nil :: proc(a: image) -> bool ---
	image_create :: proc(renderer: canvas_renderer, width: u32, height: u32) -> image ---
	image_create_from_rgba8 :: proc(renderer: canvas_renderer, width: u32, height: u32, pixels: [^]u8) -> image ---
	image_create_from_memory :: proc(renderer: canvas_renderer, mem: str8, flip: bool) -> image ---
	image_create_from_file :: proc(renderer: canvas_renderer, file: file, flip: bool) -> image ---
	image_create_from_path :: proc(renderer: canvas_renderer, path: str8, flip: bool) -> image ---
	image_destroy :: proc(image: image) ---
	image_upload_region_rgba8 :: proc(image: image, region: rect, pixels: [^]u8) ---
	image_size :: proc(image: image) -> vec2 ---
	rect_atlas_create :: proc(arena: ^arena, width: i32, height: i32) -> ^rect_atlas ---
	rect_atlas_alloc :: proc(atlas: ^rect_atlas, width: i32, height: i32) -> rect ---
	rect_atlas_recycle :: proc(atlas: ^rect_atlas, rect: rect) ---
	image_atlas_alloc_from_rgba8 :: proc(atlas: ^rect_atlas, backingImage: image, width: u32, height: u32, pixels: [^]u8) -> image_region ---
	image_atlas_alloc_from_memory :: proc(atlas: ^rect_atlas, backingImage: image, mem: str8, flip: bool) -> image_region ---
	image_atlas_alloc_from_file :: proc(atlas: ^rect_atlas, backingImage: image, file: file, flip: bool) -> image_region ---
	image_atlas_alloc_from_path :: proc(atlas: ^rect_atlas, backingImage: image, path: str8, flip: bool) -> image_region ---
	image_atlas_recycle :: proc(atlas: ^rect_atlas, imageRgn: image_region) ---
	matrix_push :: proc(_matrix: mat2x3) ---
	matrix_multiply_push :: proc(_matrix: mat2x3) ---
	matrix_pop :: proc() ---
	matrix_top :: proc() -> mat2x3 ---
	clip_push :: proc(x: f32, y: f32, w: f32, h: f32) ---
	clip_pop :: proc() ---
	clip_top :: proc() -> rect ---
	set_color :: proc(_color: color) ---
	set_color_rgba :: proc(r: f32, g: f32, b: f32, a: f32) ---
	set_color_srgba :: proc(r: f32, g: f32, b: f32, a: f32) ---
	set_gradient :: proc(blendSpace: gradient_blend_space, bottomLeft: color, bottomRight: color, topRight: color, topLeft: color) ---
	set_width :: proc(width: f32) ---
	set_tolerance :: proc(tolerance: f32) ---
	set_joint :: proc(joint: joint_type) ---
	set_max_joint_excursion :: proc(maxJointExcursion: f32) ---
	set_cap :: proc(cap: cap_type) ---
	set_font :: proc(font: font) ---
	set_font_size :: proc(size: f32) ---
	set_text_flip :: proc(flip: bool) ---
	set_image :: proc(image: image) ---
	set_image_source_region :: proc(region: rect) ---
	get_color :: proc() -> color ---
	get_width :: proc() -> f32 ---
	get_tolerance :: proc() -> f32 ---
	get_joint :: proc() -> joint_type ---
	get_max_joint_excursion :: proc() -> f32 ---
	get_cap :: proc() -> cap_type ---
	get_font :: proc() -> font ---
	get_font_size :: proc() -> f32 ---
	get_text_flip :: proc() -> bool ---
	get_image :: proc() -> image ---
	get_image_source_region :: proc() -> rect ---
	get_position :: proc() -> vec2 ---
	move_to :: proc(x: f32, y: f32) ---
	line_to :: proc(x: f32, y: f32) ---
	quadratic_to :: proc(x1: f32, y1: f32, x2: f32, y2: f32) ---
	cubic_to :: proc(x1: f32, y1: f32, x2: f32, y2: f32, x3: f32, y3: f32) ---
	close_path :: proc() ---
	glyph_outlines :: proc(glyphIndices: str32) -> rect ---
	codepoints_outlines :: proc(string: str32) ---
	text_outlines :: proc(string: str8) ---
	clear :: proc() ---
	fill :: proc() ---
	stroke :: proc() ---
	rectangle_fill :: proc(x: f32, y: f32, w: f32, h: f32) ---
	rectangle_stroke :: proc(x: f32, y: f32, w: f32, h: f32) ---
	rounded_rectangle_fill :: proc(x: f32, y: f32, w: f32, h: f32, r: f32) ---
	rounded_rectangle_stroke :: proc(x: f32, y: f32, w: f32, h: f32, r: f32) ---
	ellipse_fill :: proc(x: f32, y: f32, rx: f32, ry: f32) ---
	ellipse_stroke :: proc(x: f32, y: f32, rx: f32, ry: f32) ---
	circle_fill :: proc(x: f32, y: f32, r: f32) ---
	circle_stroke :: proc(x: f32, y: f32, r: f32) ---
	arc :: proc(x: f32, y: f32, r: f32, arcAngle: f32, startAngle: f32) ---
	text_fill :: proc(x: f32, y: f32, text: str8) ---
	image_draw :: proc(image: image, rect: rect) ---
	image_draw_region :: proc(image: image, srcRegion: rect, dstRegion: rect) ---
}

////////////////////////////////////////////////////////////////////////////////
// A surface for rendering using the GLES API.
////////////////////////////////////////////////////////////////////////////////

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	gles_surface_create :: proc() -> surface ---
	gles_surface_make_current :: proc(surface: surface) ---
	gles_surface_swap_interval :: proc(surface: surface, interval: i32) ---
	gles_surface_swap_buffers :: proc(surface: surface) ---
}

////////////////////////////////////////////////////////////////////////////////
// Graphical User Interface API.
////////////////////////////////////////////////////////////////////////////////

key_state :: struct {
	lastUpdate: u64,
	transitionCount: u32,
	repeatCount: u32,
	down: bool,
	sysClicked: bool,
	sysDoubleClicked: bool,
	sysTripleClicked: bool,
}

keyboard_state :: struct {
	keys: [349]key_state,
	mods: keymod_flags,
}

mouse_state :: struct {
	lastUpdate: u64,
	posValid: bool,
	pos: vec2,
	delta: vec2,
	wheel: vec2,
	using _: struct #raw_union {
		buttons: [5]key_state,
		using _: struct {
			left: key_state,
			right: key_state,
			middle: key_state,
			ext1: key_state,
			ext2: key_state,
		},
	},
}

BACKING_SIZE :: 64

text_state :: struct {
	lastUpdate: u64,
	backing: [64]utf32,
	codePoints: str32,
}

clipboard_state :: struct {
	lastUpdate: u64,
	pastedText: str8,
}

input_state :: struct {
	frameCounter: u64,
	keyboard: keyboard_state,
	mouse: mouse_state,
	text: text_state,
	clipboard: clipboard_state,
}

ui_key :: struct {
	hash: u64,
}

ui_axis :: enum u32 {
	X = 0,
	Y = 1,
	COUNT = 2,
}

ui_align :: enum u32 {
	START = 0,
	END = 1,
	CENTER = 2,
}

ui_layout_align :: [2]ui_align

ui_layout :: struct {
	axis: ui_axis,
	spacing: f32,
	margin: [2]f32,
	align: ui_layout_align,
}

ui_size_kind :: enum u32 {
	TEXT = 0,
	PIXELS = 1,
	CHILDREN = 2,
	PARENT = 3,
	PARENT_MINUS_PIXELS = 4,
}

ui_size :: struct {
	kind: ui_size_kind,
	value: f32,
	relax: f32,
	minSize: f32,
}

ui_box_size :: [2]ui_size

ui_box_floating :: [2]bool

ui_style :: struct {
	size: ui_box_size,
	layout: ui_layout,
	floating: ui_box_floating,
	floatTarget: vec2,
	_color: color,
	bgColor: color,
	borderColor: color,
	font: font,
	fontSize: f32,
	borderSize: f32,
	roundness: f32,
	animationTime: f32,
	animationMask: ui_style_mask,
}

ui_palette :: struct {
	red0: color,
	red1: color,
	red2: color,
	red3: color,
	red4: color,
	red5: color,
	red6: color,
	red7: color,
	red8: color,
	red9: color,
	orange0: color,
	orange1: color,
	orange2: color,
	orange3: color,
	orange4: color,
	orange5: color,
	orange6: color,
	orange7: color,
	orange8: color,
	orange9: color,
	amber0: color,
	amber1: color,
	amber2: color,
	amber3: color,
	amber4: color,
	amber5: color,
	amber6: color,
	amber7: color,
	amber8: color,
	amber9: color,
	yellow0: color,
	yellow1: color,
	yellow2: color,
	yellow3: color,
	yellow4: color,
	yellow5: color,
	yellow6: color,
	yellow7: color,
	yellow8: color,
	yellow9: color,
	lime0: color,
	lime1: color,
	lime2: color,
	lime3: color,
	lime4: color,
	lime5: color,
	lime6: color,
	lime7: color,
	lime8: color,
	lime9: color,
	lightGreen0: color,
	lightGreen1: color,
	lightGreen2: color,
	lightGreen3: color,
	lightGreen4: color,
	lightGreen5: color,
	lightGreen6: color,
	lightGreen7: color,
	lightGreen8: color,
	lightGreen9: color,
	green0: color,
	green1: color,
	green2: color,
	green3: color,
	green4: color,
	green5: color,
	green6: color,
	green7: color,
	green8: color,
	green9: color,
	teal0: color,
	teal1: color,
	teal2: color,
	teal3: color,
	teal4: color,
	teal5: color,
	teal6: color,
	teal7: color,
	teal8: color,
	teal9: color,
	cyan0: color,
	cyan1: color,
	cyan2: color,
	cyan3: color,
	cyan4: color,
	cyan5: color,
	cyan6: color,
	cyan7: color,
	cyan8: color,
	cyan9: color,
	lightBlue0: color,
	lightBlue1: color,
	lightBlue2: color,
	lightBlue3: color,
	lightBlue4: color,
	lightBlue5: color,
	lightBlue6: color,
	lightBlue7: color,
	lightBlue8: color,
	lightBlue9: color,
	blue0: color,
	blue1: color,
	blue2: color,
	blue3: color,
	blue4: color,
	blue5: color,
	blue6: color,
	blue7: color,
	blue8: color,
	blue9: color,
	indigo0: color,
	indigo1: color,
	indigo2: color,
	indigo3: color,
	indigo4: color,
	indigo5: color,
	indigo6: color,
	indigo7: color,
	indigo8: color,
	indigo9: color,
	violet0: color,
	violet1: color,
	violet2: color,
	violet3: color,
	violet4: color,
	violet5: color,
	violet6: color,
	violet7: color,
	violet8: color,
	violet9: color,
	purple0: color,
	purple1: color,
	purple2: color,
	purple3: color,
	purple4: color,
	purple5: color,
	purple6: color,
	purple7: color,
	purple8: color,
	purple9: color,
	pink0: color,
	pink1: color,
	pink2: color,
	pink3: color,
	pink4: color,
	pink5: color,
	pink6: color,
	pink7: color,
	pink8: color,
	pink9: color,
	grey0: color,
	grey1: color,
	grey2: color,
	grey3: color,
	grey4: color,
	grey5: color,
	grey6: color,
	grey7: color,
	grey8: color,
	grey9: color,
	black: color,
	white: color,
}

ui_theme :: struct {
	white: color,
	primary: color,
	primaryHover: color,
	primaryActive: color,
	border: color,
	fill0: color,
	fill1: color,
	fill2: color,
	bg0: color,
	bg1: color,
	bg2: color,
	bg3: color,
	bg4: color,
	text0: color,
	text1: color,
	text2: color,
	text3: color,
	sliderThumbBorder: color,
	elevatedBorder: color,
	roundnessSmall: f32,
	roundnessMedium: f32,
	roundnessLarge: f32,
	palette: ^ui_palette,
}

ui_tag :: struct {
	hash: u64,
}

ui_selector_kind :: enum u32 {
	ANY = 0,
	OWNER = 1,
	TEXT = 2,
	TAG = 3,
	STATUS = 4,
	KEY = 5,
}

ui_status_flag :: enum u8 {
	HOVER = 1,
	HOT,
	ACTIVE,
	DRAGGING,
}
ui_status :: bit_set[ui_status_flag; u8]

ui_selector_op :: enum u32 {
	DESCENDANT = 0,
	AND = 1,
}

ui_selector :: struct {
	listElt: list_elt,
	kind: ui_selector_kind,
	op: ui_selector_op,
	using _: struct #raw_union {
		text: str8,
		key: ui_key,
		tag: ui_tag,
		status: ui_status,
	},
}

ui_pattern :: struct {
	l: list,
}

ui_box :: struct {
	listElt: list_elt,
	children: list,
	parent: ^ui_box,
	overlayElt: list_elt,
	bucketElt: list_elt,
	key: ui_key,
	frameCounter: u64,
	flags: ui_flags,
	string: str8,
	tags: list,
	drawProc: ui_box_draw_proc,
	drawData: rawptr,
	beforeRules: list,
	afterRules: list,
	targetStyle: ^ui_style,
	style: ui_style,
	z: u32,
	floatPos: vec2,
	childrenSum: [2]f32,
	spacing: [2]f32,
	minSize: [2]f32,
	rect: rect,
	sig: ^ui_sig,
	fresh: bool,
	closed: bool,
	parentClosed: bool,
	dragging: bool,
	hot: bool,
	active: bool,
	scroll: vec2,
	pressedMouse: vec2,
	hotTransition: f32,
	activeTransition: f32,
}

ui_style_rule :: struct {
	boxElt: list_elt,
	buildElt: list_elt,
	tmpElt: list_elt,
	owner: ^ui_box,
	pattern: ui_pattern,
	mask: ui_style_mask,
	style: ^ui_style,
}

ui_sig :: struct {
	box: ^ui_box,
	mouse: vec2,
	delta: vec2,
	wheel: vec2,
	pressed: bool,
	released: bool,
	clicked: bool,
	doubleClicked: bool,
	tripleClicked: bool,
	rightPressed: bool,
	dragging: bool,
	hovering: bool,
	pasted: bool,
}

ui_box_draw_proc :: proc "c" (arg0: ^ui_box, arg1: rawptr)

ui_flag :: enum u32 {
	CLICKABLE = 0,
	SCROLL_WHEEL_X,
	SCROLL_WHEEL_Y,
	BLOCK_MOUSE,
	HOT_ANIMATION,
	ACTIVE_ANIMATION,
	OVERFLOW_ALLOW_X,
	OVERFLOW_ALLOW_Y,
	CLIP,
	DRAW_BACKGROUND,
	DRAW_FOREGROUND,
	DRAW_BORDER,
	DRAW_TEXT,
	DRAW_PROC,
	OVERLAY,
}
ui_flags :: bit_set[ui_flag; u32]

MAX_INPUT_CHAR_PER_FRAME :: 64

ui_input_text :: struct {
	count: u8 `fmt:"-"`,
	codePoints: [64]utf32 `fmt:"s,count"`,
}

ui_stack_elt :: struct {
	parent: ^ui_stack_elt,
	using _: struct #raw_union {
		box: ^ui_box,
		size: ui_size,
		clip: rect,
	},
}

ui_tag_elt :: struct {
	listElt: list_elt,
	tag: ui_tag,
}

BOX_MAP_BUCKET_COUNT :: 1024

ui_edit_move :: enum u32 {
	NONE = 0,
	CHAR = 1,
	WORD = 2,
	LINE = 3,
}

ui_context :: struct {
	init: bool,
	input: input_state,
	frameCounter: u64,
	frameTime: f64,
	lastFrameDuration: f64,
	frameArena: arena,
	boxPool: pool,
	boxMap: [1024]list,
	root: ^ui_box,
	overlay: ^ui_box,
	overlayList: list,
	boxStack: ^ui_stack_elt,
	clipStack: ^ui_stack_elt,
	nextBoxBeforeRules: list,
	nextBoxAfterRules: list,
	nextBoxTags: list,
	z: u32,
	hovered: ^ui_box,
	focus: ^ui_box,
	editCursor: i32,
	editMark: i32,
	editFirstDisplayedChar: i32,
	editCursorBlinkStart: f64,
	editSelectionMode: ui_edit_move,
	editWordSelectionInitialCursor: i32,
	editWordSelectionInitialMark: i32,
	theme: ^ui_theme,
}

ui_text_box_result :: struct {
	changed: bool,
	accepted: bool,
	text: str8,
}

ui_select_popup_info :: struct {
	changed: bool,
	selectedIndex: i32,
	optionCount: i32 `fmt:"-"`,
	options: [^]str8 `fmt:"s,optionCount"`,
	placeholder: str8,
}

ui_radio_group_info :: struct {
	changed: bool,
	selectedIndex: i32,
	optionCount: i32 `fmt:"-"`,
	options: [^]str8 `fmt:"s,optionCount"`,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	input_process_event :: proc(arena: ^arena, state: ^input_state, event: ^event) ---
	input_next_frame :: proc(state: ^input_state) ---
	key_down :: proc(state: ^input_state, key: key_code) -> bool ---
	key_press_count :: proc(state: ^input_state, key: key_code) -> u8 ---
	key_release_count :: proc(state: ^input_state, key: key_code) -> u8 ---
	key_repeat_count :: proc(state: ^input_state, key: key_code) -> u8 ---
	key_down_scancode :: proc(state: ^input_state, key: scan_code) -> bool ---
	key_press_count_scancode :: proc(state: ^input_state, key: scan_code) -> u8 ---
	key_release_count_scancode :: proc(state: ^input_state, key: scan_code) -> u8 ---
	key_repeat_count_scancode :: proc(state: ^input_state, key: scan_code) -> u8 ---
	mouse_down :: proc(state: ^input_state, button: mouse_button) -> bool ---
	mouse_pressed :: proc(state: ^input_state, button: mouse_button) -> u8 ---
	mouse_released :: proc(state: ^input_state, button: mouse_button) -> u8 ---
	mouse_clicked :: proc(state: ^input_state, button: mouse_button) -> bool ---
	mouse_double_clicked :: proc(state: ^input_state, button: mouse_button) -> bool ---
	mouse_position :: proc(state: ^input_state) -> vec2 ---
	mouse_delta :: proc(state: ^input_state) -> vec2 ---
	mouse_wheel :: proc(state: ^input_state) -> vec2 ---
	input_text_utf32 :: proc(arena: ^arena, state: ^input_state) -> str32 ---
	input_text_utf8 :: proc(arena: ^arena, state: ^input_state) -> str8 ---
	clipboard_pasted :: proc(state: ^input_state) -> bool ---
	clipboard_pasted_text :: proc(state: ^input_state) -> str8 ---
	key_mods :: proc(state: ^input_state) -> keymod_flags ---
	ui_init :: proc(_context: ^ui_context) ---
	ui_get_context :: proc() -> ^ui_context ---
	ui_set_context :: proc(_context: ^ui_context) ---
	ui_process_event :: proc(event: ^event) ---
	ui_begin_frame :: proc(size: vec2, #by_ptr defaultStyle: ui_style, mask: ui_style_mask) ---
	ui_end_frame :: proc() ---
	ui_draw :: proc() ---
	ui_set_theme :: proc(theme: ^ui_theme) ---
	ui_key_make_str8 :: proc(string: str8) -> ui_key ---
	ui_key_make_path :: proc(path: str8_list) -> ui_key ---
	ui_box_make_str8 :: proc(string: str8, flags: ui_flags) -> ^ui_box ---
	ui_box_begin_str8 :: proc(string: str8, flags: ui_flags) -> ^ui_box ---
	ui_box_end :: proc() -> ^ui_box ---
	ui_box_push :: proc(box: ^ui_box) ---
	ui_box_pop :: proc() ---
	ui_box_top :: proc() -> ^ui_box ---
	ui_box_lookup_key :: proc(key: ui_key) -> ^ui_box ---
	ui_box_lookup_str8 :: proc(string: str8) -> ^ui_box ---
	ui_box_set_draw_proc :: proc(box: ^ui_box, _proc: ui_box_draw_proc, data: rawptr) ---
	ui_box_closed :: proc(box: ^ui_box) -> bool ---
	ui_box_set_closed :: proc(box: ^ui_box, closed: bool) ---
	ui_box_active :: proc(box: ^ui_box) -> bool ---
	ui_box_activate :: proc(box: ^ui_box) ---
	ui_box_deactivate :: proc(box: ^ui_box) ---
	ui_box_hot :: proc(box: ^ui_box) -> bool ---
	ui_box_set_hot :: proc(box: ^ui_box, hot: bool) ---
	ui_box_sig :: proc(box: ^ui_box) -> ui_sig ---
	ui_tag_make_str8 :: proc(string: str8) -> ui_tag ---
	ui_tag_box_str8 :: proc(box: ^ui_box, string: str8) ---
	ui_tag_next_str8 :: proc(string: str8) ---
	ui_apply_style_with_mask :: proc(dst: ^ui_style, src: ^ui_style, mask: ui_style_mask) ---
	ui_pattern_push :: proc(arena: ^arena, pattern: ^ui_pattern, selector: ui_selector) ---
	ui_pattern_all :: proc() -> ui_pattern ---
	ui_pattern_owner :: proc() -> ui_pattern ---
	ui_style_next :: proc(#by_ptr style: ui_style, mask: ui_style_mask) ---
	ui_style_match_before :: proc(pattern: ui_pattern, #by_ptr style: ui_style, mask: ui_style_mask) ---
	ui_style_match_after :: proc(pattern: ui_pattern, #by_ptr style: ui_style, mask: ui_style_mask) ---
	ui_label :: proc(label: cstring) -> ui_sig ---
	ui_label_str8 :: proc(label: str8) -> ui_sig ---
	ui_button :: proc(label: cstring) -> ui_sig ---
	ui_checkbox :: proc(name: cstring, checked: ^bool) -> ui_sig ---
	ui_slider :: proc(name: cstring, value: ^f32) -> ^ui_box ---
	ui_scrollbar :: proc(name: cstring, thumbRatio: f32, scrollValue: ^f32) -> ^ui_box ---
	ui_tooltip :: proc(label: cstring) ---
	ui_panel_begin :: proc(name: cstring, flags: ui_flags) ---
	ui_panel_end :: proc() ---
	ui_menu_bar_begin :: proc(name: cstring) ---
	ui_menu_bar_end :: proc() ---
	ui_menu_begin :: proc(label: cstring) ---
	ui_menu_end :: proc() ---
	ui_menu_button :: proc(label: cstring) -> ui_sig ---
	ui_text_box :: proc(name: cstring, arena: ^arena, text: str8) -> ui_text_box_result ---
	ui_select_popup :: proc(name: cstring, info: ^ui_select_popup_info) -> ui_select_popup_info ---
	ui_radio_group :: proc(name: cstring, info: ^ui_radio_group_info) -> ui_radio_group_info ---
}

