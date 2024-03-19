package orca

import "core:c"


surface_data :: struct {}
canvas_backend :: struct {}


surface_destroy_proc       :: proc "c" (surface: ^surface_data)
surface_select_proc        :: proc "c" (surface: ^surface_data)
surface_deselect_proc      :: proc "c" (surface: ^surface_data)
surface_present_proc       :: proc "c" (surface: ^surface_data)
surface_swap_interval_proc :: proc "c" (surface: ^surface_data, swap: c.int)

surface_get_size_proc         :: proc "c" (surface: ^surface_data) -> vec2
surface_contents_scaling_proc :: proc "c" (surface: ^surface_data) -> vec2
surface_get_hidden_proc       :: proc "c" (surface: ^surface_data) -> bool
surface_set_hidden_proc       :: proc "c" (surface: ^surface_data, hidden: bool);
surface_native_layer_proc     :: proc "c" (surface: ^surface_data) -> rawptr

surface_bring_to_front_proc :: proc "c" (surface: ^surface_data)
surface_send_to_back_proc   :: proc "c" (surface: ^surface_data)


//------------------------------------------------------------------------
// canvas structs
//------------------------------------------------------------------------
path_elt_type :: enum c.int {
	MOVE,
	LINE,
	QUADRATIC,
	CUBIC,
}

path_elt :: struct {
	type: path_elt_type,
	p:    [3]vec2,
}

path_descriptor :: struct {
	startIndex: u32,
	count:      u32,
	startPoint: vec2,
}

attributes :: struct {
	width:             f32,
	tolerance:         f32,
	color:             color,
	joint:             joint_type,
	maxJointExcursion: f32,
	cap:               cap_type,

	font:      font,
	fontSize:  f32,

	image:     image,
	srcRegion: rect,

	transform: mat2x3,
	clip:      rect,
}

primitive_cmd :: enum {
	FILL,
	STROKE,
	JUMP,
}

primitive :: struct {
	cmd:        primitive_cmd,
	attributes: attributes,

	using _: struct #raw_union {
		path: path_descriptor,
		rect: rect,
		jump: u32,
	},
}



surface_api :: enum c.int {
	NONE,
	METAL,
	GL,
	GLES,
	CANVAS,
	HOST,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	is_surface_api_available :: proc(api: surface_api) -> bool ---
}

//------------------------------------------------------------------------------------------
//SECTION: graphics surface
//------------------------------------------------------------------------------------------
surface :: struct {
	h: u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	oc_surface_nil             :: proc() -> surface ---            //DOC: returns a nil surface
	oc_surface_is_nil          :: proc(surface: surface) -> bool --- //DOC: true if surface is nil

	oc_surface_canvas          :: proc() -> surface --- //DOC: creates a surface for use with the canvas API
	oc_surface_gles            :: proc() -> surface ---   //DOC: create a surface for use with GLES API


	oc_surface_destroy         :: proc(surface: surface) --- //DOC: destroys the surface

	oc_surface_select          :: proc(surface: surface) --- //DOC: selects the surface in the current thread before drawing
	oc_surface_deselect        :: proc() ---             //DOC: deselects the current thread's previously selected surface
	oc_surface_get_selected    :: proc() -> surface ---

	oc_surface_present         :: proc(surface: surface) --- //DOC: presents the surface to its window

	oc_surface_get_size        :: proc(surface: surface) -> vec2 ---
	oc_surface_contents_scaling:: proc(surface: surface) -> vec2 --- //DOC: returns the scaling of the surface (pixels = points * scale)

	oc_surface_bring_to_front  :: proc(surface: surface) --- //DOC: puts surface on top of the surface stack
	oc_surface_send_to_back    :: proc(surface: surface) ---   //DOC: puts surface at the bottom of the surface stack
}

//------------------------------------------------------------------------------------------
//SECTION: graphics canvas structs
//------------------------------------------------------------------------------------------
canvas :: struct {h: u64}
font   :: struct {h: u64}
image  :: struct {h: u64}

joint_type :: enum c.int {
	MITER = 0,
	BEVEL,
	NONE,
}

cap_type :: enum c.int {
	NONE = 0,
	SQUARE,
}

font_metrics :: struct {
	ascent:    f32, // the extent above the baseline (by convention a positive value extends above the baseline)
	descent:   f32, // the extent below the baseline (by convention, positive value extends below the baseline)
	lineGap:   f32, // spacing between one row's descent and the next row's ascent
	xHeight:   f32, // height of the lower case letter 'x'
	capHeight: f32, // height of the upper case letter 'M'
	width:     f32, // maximum width of the font
}

glyph_metrics :: struct {
	ink:     rect,
	advance: vec2,
}

text_metrics :: struct {
	ink:     rect,
	logical: rect,
	advance: vec2,
}

//NOTE: image atlas helpers
image_region :: struct {
	image: image,
	rect:  rect,
}

/*
@(default_calling_convention="c", link_prefix="oc_")
foreign {
	//------------------------------------------------------------------------------------------
	//SECTION: graphics canvas
	//------------------------------------------------------------------------------------------
	ORCA_API oc_canvas oc_canvas_nil();           //DOC: returns a nil canvas
	ORCA_API bool oc_canvas_is_nil(oc_canvas canvas); //DOC: true if canvas is nil

	ORCA_API oc_canvas oc_canvas_create();             //DOC: create a new canvas
	ORCA_API void oc_canvas_destroy(oc_canvas canvas);     //DOC: destroys canvas
	ORCA_API oc_canvas oc_canvas_select(oc_canvas canvas); //DOC: selects canvas in the current thread
	ORCA_API void oc_render(oc_canvas canvas);             //DOC: renders all canvas commands onto surface

	//------------------------------------------------------------------------------------------
	//SECTION: fonts
	//------------------------------------------------------------------------------------------
	ORCA_API oc_font oc_font_nil();
	ORCA_API bool oc_font_is_nil(oc_font font);

	ORCA_API oc_font oc_font_create_from_memory(oc_str8 mem, u32 rangeCount, oc_unicode_range* ranges);
	ORCA_API oc_font oc_font_create_from_file(oc_file file, u32 rangeCount, oc_unicode_range* ranges);
	ORCA_API oc_font oc_font_create_from_path(oc_str8 path, u32 rangeCount, oc_unicode_range* ranges);

	ORCA_API void oc_font_destroy(oc_font font);

	ORCA_API oc_str32 oc_font_get_glyph_indices(oc_font font, oc_str32 codePoints, oc_str32 backing);
	ORCA_API oc_str32 oc_font_push_glyph_indices(oc_arena* arena, oc_font font, oc_str32 codePoints);
	ORCA_API u32 oc_font_get_glyph_index(oc_font font, oc_utf32 codePoint);

	// metrics
	ORCA_API oc_font_metrics oc_font_get_metrics(oc_font font, f32 emSize);
	ORCA_API oc_font_metrics oc_font_get_metrics_unscaled(oc_font font);
	ORCA_API f32 oc_font_get_scale_for_em_pixels(oc_font font, f32 emSize);

	ORCA_API oc_text_metrics oc_font_text_metrics_utf32(oc_font font, f32 fontSize, oc_str32 codepoints);
	ORCA_API oc_text_metrics oc_font_text_metrics(oc_font font, f32 fontSize, oc_str8 text);

	//------------------------------------------------------------------------------------------
	//SECTION: images
	//------------------------------------------------------------------------------------------
	ORCA_API oc_image oc_image_nil();
	ORCA_API bool oc_image_is_nil(oc_image a);

	ORCA_API oc_image oc_image_create(oc_surface surface, u32 width, u32 height);
	ORCA_API oc_image oc_image_create_from_rgba8(oc_surface surface, u32 width, u32 height, u8* pixels);
	ORCA_API oc_image oc_image_create_from_memory(oc_surface surface, oc_str8 mem, bool flip);
	ORCA_API oc_image oc_image_create_from_file(oc_surface surface, oc_file file, bool flip);
	ORCA_API oc_image oc_image_create_from_path(oc_surface surface, oc_str8 path, bool flip);

	ORCA_API void oc_image_destroy(oc_image image);

	ORCA_API void oc_image_upload_region_rgba8(oc_image image, oc_rect region, u8* pixels);
	ORCA_API oc_vec2 oc_image_size(oc_image image);

	//------------------------------------------------------------------------------------------
	//SECTION: atlasing
	//------------------------------------------------------------------------------------------

	//NOTE: rectangle allocator
	typedef struct oc_rect_atlas oc_rect_atlas;

	ORCA_API oc_rect_atlas* oc_rect_atlas_create(oc_arena* arena, i32 width, i32 height);
	ORCA_API oc_rect oc_rect_atlas_alloc(oc_rect_atlas* atlas, i32 width, i32 height);
	ORCA_API void oc_rect_atlas_recycle(oc_rect_atlas* atlas, oc_rect rect);

	ORCA_API oc_image_region oc_image_atlas_alloc_from_rgba8(oc_rect_atlas* atlas, oc_image backingImage, u32 width, u32 height, u8* pixels);
	ORCA_API oc_image_region oc_image_atlas_alloc_from_memory(oc_rect_atlas* atlas, oc_image backingImage, oc_str8 mem, bool flip);
	ORCA_API oc_image_region oc_image_atlas_alloc_from_file(oc_rect_atlas* atlas, oc_image backingImage, oc_file file, bool flip);
	ORCA_API oc_image_region oc_image_atlas_alloc_from_path(oc_rect_atlas* atlas, oc_image backingImage, oc_str8 path, bool flip);
	ORCA_API void oc_image_atlas_recycle(oc_rect_atlas* atlas, oc_image_region imageRgn);

	//------------------------------------------------------------------------------------------
	//SECTION: transform, viewport and clipping
	//------------------------------------------------------------------------------------------
	ORCA_API void oc_matrix_push(oc_mat2x3 matrix);
	ORCA_API void oc_matrix_multiply_push(oc_mat2x3 matrix);
	ORCA_API void oc_matrix_pop();
	ORCA_API oc_mat2x3 oc_matrix_top();

	ORCA_API void oc_clip_push(f32 x, f32 y, f32 w, f32 h);
	ORCA_API void oc_clip_pop();
	ORCA_API oc_rect oc_clip_top();

	//------------------------------------------------------------------------------------------
	//SECTION: graphics attributes setting/getting
	//------------------------------------------------------------------------------------------
	ORCA_API void oc_set_color(oc_color color);
	ORCA_API void oc_set_color_rgba(f32 r, f32 g, f32 b, f32 a);
	ORCA_API void oc_set_width(f32 width);
	ORCA_API void oc_set_tolerance(f32 tolerance);
	ORCA_API void oc_set_joint(oc_joint_type joint);
	ORCA_API void oc_set_max_joint_excursion(f32 maxJointExcursion);
	ORCA_API void oc_set_cap(oc_cap_type cap);
	ORCA_API void oc_set_font(oc_font font);
	ORCA_API void oc_set_font_size(f32 size);
	ORCA_API void oc_set_text_flip(bool flip);
	ORCA_API void oc_set_image(oc_image image);
	ORCA_API void oc_set_image_source_region(oc_rect region);

	ORCA_API oc_color oc_get_color();
	ORCA_API f32 oc_get_width();
	ORCA_API f32 oc_get_tolerance();
	ORCA_API oc_joint_type oc_get_joint();
	ORCA_API f32 oc_get_max_joint_excursion();
	ORCA_API oc_cap_type oc_get_cap();
	ORCA_API oc_font oc_get_font();
	ORCA_API f32 oc_get_font_size();
	ORCA_API bool oc_get_text_flip();
	ORCA_API oc_image oc_get_image();
	ORCA_API oc_rect oc_get_image_source_region();

	//------------------------------------------------------------------------------------------
	//SECTION: path construction
	//------------------------------------------------------------------------------------------
	ORCA_API oc_vec2 oc_get_position();
	ORCA_API void oc_move_to(f32 x, f32 y);
	ORCA_API void oc_line_to(f32 x, f32 y);
	ORCA_API void oc_quadratic_to(f32 x1, f32 y1, f32 x2, f32 y2);
	ORCA_API void oc_cubic_to(f32 x1, f32 y1, f32 x2, f32 y2, f32 x3, f32 y3);
	ORCA_API void oc_close_path();

	ORCA_API oc_rect oc_glyph_outlines(oc_str32 glyphIndices);
	ORCA_API void oc_codepoints_outlines(oc_str32 string);
	ORCA_API void oc_text_outlines(oc_str8 string);

	//------------------------------------------------------------------------------------------
	//SECTION: clear/fill/stroke
	//------------------------------------------------------------------------------------------
	ORCA_API void oc_clear();
	ORCA_API void oc_fill();
	ORCA_API void oc_stroke();

	//------------------------------------------------------------------------------------------
	//SECTION: shapes helpers
	//------------------------------------------------------------------------------------------
	ORCA_API void oc_rectangle_fill(f32 x, f32 y, f32 w, f32 h);
	ORCA_API void oc_rectangle_stroke(f32 x, f32 y, f32 w, f32 h);
	ORCA_API void oc_rounded_rectangle_fill(f32 x, f32 y, f32 w, f32 h, f32 r);
	ORCA_API void oc_rounded_rectangle_stroke(f32 x, f32 y, f32 w, f32 h, f32 r);
	ORCA_API void oc_ellipse_fill(f32 x, f32 y, f32 rx, f32 ry);
	ORCA_API void oc_ellipse_stroke(f32 x, f32 y, f32 rx, f32 ry);
	ORCA_API void oc_circle_fill(f32 x, f32 y, f32 r);
	ORCA_API void oc_circle_stroke(f32 x, f32 y, f32 r);
	ORCA_API void oc_arc(f32 x, f32 y, f32 r, f32 arcAngle, f32 startAngle);

	ORCA_API void oc_text_fill(f32 x, f32 y, oc_str8 text);

	//NOTE: image helpers
	ORCA_API void oc_image_draw(oc_image image, oc_rect rect);
	ORCA_API void oc_image_draw_region(oc_image image, oc_rect srcRegion, oc_rect dstRegion);
}


@(default_calling_convention="c", link_prefix="oc_")
foreign {
	egl_surface_create_for_window :: proc(window: window) -> ^surface_data ---
	egl_surface_create_remote     :: proc(width, height: u32) -> ^surface_data ---
}
*/