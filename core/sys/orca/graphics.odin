package orca

import "core:c"

// types
color :: distinct [4]f32
utf32 :: rune

// handles
surface :: distinct u64
font :: distinct u64
image :: distinct u64
canvas :: distinct u64

joint_type :: enum c.int {
	MITER,
	BEVEL,
	NONE,
}

cap_type :: enum c.int {
	NONE,
	SQUARE,
}

font_metrics :: struct {
	ascent: f32,    // the extent above the baseline (by convention a positive value extends above the baseline)
	descent: f32,   // the extent below the baseline (by convention, positive value extends below the baseline)
	lineGap: f32,   // spacing between one row's descent and the next row's ascent
	xHeight: f32,   // height of the lower case letter 'x'
	capHeight: f32, // height of the upper case letter 'M'
	width: f32,     // maximum width of the font
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

rect_atlas :: struct {
	arena: ^arena,
	size: vec2i,
	pos: vec2i,
	lineHeight: u32,
}

image_region :: struct {
	image: image,
	rect: rect,
}

//------------------------------------------------------------------------------------------
// graphics surface
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	surface_nil :: proc() -> surface ---
	surface_is_nil :: proc() -> c.bool ---
	surface_canvas :: proc() -> surface ---
	surface_gles :: proc() -> surface ---
	surface_destroy :: proc(surface: surface) ---
	
	surface_select :: proc(surface: surface) ---
	surface_deselect :: proc() ---
	surface_present :: proc(surface: surface) ---
	
	surface_get_size :: proc(surface: surface) -> vec2 ---
	surface_contents_scaling :: proc(surface: surface) -> vec2 ---
	surface_bring_to_front :: proc(surface: surface) ---
	surface_send_to_back :: proc(surface: surface) ---
}

//------------------------------------------------------------------------------------------
// 2D canvas command buffer
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	canvas_nil :: proc() -> canvas ---
	canvas_is_nil :: proc(canvas: canvas) -> c.bool ---
	canvas_create :: proc() -> canvas ---
	canvas_destroy :: proc(canvas: canvas) ---
	canvas_set_current :: proc(_canvas: canvas) -> canvas ---
	canvas_select :: proc(_canvas: canvas) -> canvas ---
	render :: proc(canvas: canvas) ---
}

//------------------------------------------------------------------------------------------
// transform and clipping
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	matrix_push :: proc(mat: mat2x3) ---
	matrix_multiply_push :: proc(mat: mat2x3) ---
	matrix_pop :: proc() ---
	matrix_top :: proc() -> mat2x3 ---

	clip_push :: proc(x, y, w, h: f32) ---
	clip_pop :: proc() ---
	clip_top :: proc() -> rect ---
}

//------------------------------------------------------------------------------------------
// graphics attributes setting/getting
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	set_color :: proc(color: color) ---
	set_color_rgba :: proc(r, g, b, a: f32) ---
	set_width :: proc(width: f32) ---
	set_tolerance :: proc(tolerance: f32) ---
	set_joint :: proc(joint: joint_type) ---
	set_max_joint_excursion :: proc(maxJointExcursion: f32) ---
	set_cap :: proc(cap: cap_type) ---
	set_font :: proc(font: font) ---
	set_font_size :: proc(size: f32) ---
	set_text_flip :: proc(flip: c.bool) ---
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
}

//------------------------------------------------------------------------------------------
// path construction
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	get_position :: proc() -> vec2 ---
	move_to :: proc(x, y: f32) ---
	line_to :: proc(x, y: f32) ---
	quadratic_to :: proc(x1, y1, x2, y2: f32) ---
	cubic_to :: proc(x1, y1, x2, y2, x3, y3: f32) ---
	close_path :: proc() ---

	glyph_outlines :: proc(glyphIndices: str32) -> rect ---
	codepoints_outlines :: proc(str: str32) ---
	text_outlines :: proc(str: str8) ---
}

//------------------------------------------------------------------------------------------
// clear/fill/stroke
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	clear :: proc() ---
	fill :: proc() ---
	stroke :: proc() ---
}

//------------------------------------------------------------------------------------------
// shapes helpers
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	rectangle_fill :: proc(x, y, w, h: f32) ---
	rectangle_stroke :: proc(x, y, w, h: f32) ---
	rounded_rectangle_fill :: proc(x, y, w, h, r: f32) ---
	rounded_rectangle_stroke :: proc(x, y, w, h, r: f32) ---
	ellipse_fill :: proc(x, y, rx, ry: f32) ---
	ellipse_stroke :: proc(x, y, rx, ry: f32) ---
	circle_fill :: proc(x, y, r: f32) ---
	circle_stroke :: proc(x, y, r: f32) ---
	arc :: proc(x, y, r, arcAngle, startAngle: f32) ---
	image_draw :: proc(image: image, rect: rect) ---
	image_draw_region :: proc(image: image, srcRegion, dstRegion: rect) ---

	text_fill :: proc(x, y: f32, text: str8) ---
}

//------------------------------------------------------------------------------------------
// fonts
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	font_nil :: proc() -> font ---
	font_is_nil :: proc(font: font) -> c.bool ---

	font_create_from_memory :: proc(mem: str8, rangeCount: u32, ranges: [^]unicode_range) -> font ---
	font_create_from_file :: proc(file: file, rangeCount: u32, ranges: [^]unicode_range) -> font ---
	font_create_from_path :: proc(path: str8, rangeCount: u32, ranges: [^]unicode_range) -> font ---

	font_destroy :: proc(font: font) ---

	font_get_glyph_indices :: proc(font: font, codePoints: str32, backing: str32) -> str32 ---
	font_push_glyph_indices :: proc(arena: ^arena, font: font, codePoints: str32) -> str32 ---
	font_get_glyph_index :: proc(font: font, codePoint: utf32) -> u32 ---

	font_get_metrics :: proc(font: font, emSize: f32) -> font_metrics ---
	font_get_metrics_unscaled :: proc(font: font) -> font_metrics ---
	font_get_scale_for_em_pixels :: proc(font: font, emSize: f32) -> f32 ---

	font_text_metrics_utf32 :: proc(font: font, fontSize: f32, codepoints: str32) -> text_metrics ---
	font_text_metrics :: proc(font: font, fontSize: f32, text: str8) -> text_metrics ---
}

//------------------------------------------------------------------------------------------
// images
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	image_nil :: proc() -> image ---
	image_is_nil :: proc(a: image) -> c.bool ---

	image_create :: proc(surface: surface, width, height: u32) -> image ---
	image_create_from_rgba8 :: proc(surface: surface, width, height: u32, pixels: [^]u8) -> image ---
	image_create_from_memory :: proc(surface: surface, mem: str8, flip: c.bool) -> image ---
	image_create_from_file :: proc(surface: surface, file: file, flip: c.bool) -> image ---
	image_create_from_path :: proc(surface: surface, path: str8, flip: c.bool) -> image ---

	image_destroy :: proc(image: image) ---

	image_upload_region_rgba8 :: proc(image: image, region: rect, pixels: [^]u8) ---
	image_size :: proc(image: image) -> vec2 ---
}

//------------------------------------------------------------------------------------------
// image atlas
//------------------------------------------------------------------------------------------
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	rect_atlas_create :: proc(arena: ^arena, width, height: i32) -> ^rect_atlas ---
	rect_atlas_alloc :: proc(atlas: ^rect_atlas, width, height: i32) -> rect ---
	rect_atlas_recycle :: proc(atlas: ^rect_atlas, rect: rect) ---

	image_atlas_allfrom_rgba8 :: proc(atlas: ^rect_atlas, backingImage: image, width, height: u32, pixels: [^]u8) -> image_region ---
	image_atlas_allfrom_memory :: proc(atlas: ^rect_atlas, backingImage: image, mem: str8, flip: c.bool) -> image_region ---
	image_atlas_allfrom_file :: proc(atlas: ^rect_atlas, backingImage: image, file: file, flip: c.bool) -> image_region ---
	image_atlas_allfrom_path :: proc(atlas: ^rect_atlas, backingImage: image, path: str8, flip: c.bool) -> image_region ---

	image_atlas_recycle :: proc(atlas: ^rect_atlas, imageRgn: image_region) ---
}
