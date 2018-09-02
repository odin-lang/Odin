// +build windows
package win32

foreign import "system:opengl32.lib"

CONTEXT_MAJOR_VERSION_ARB             :: 0x2091;
CONTEXT_MINOR_VERSION_ARB             :: 0x2092;
CONTEXT_FLAGS_ARB                     :: 0x2094;
CONTEXT_PROFILE_MASK_ARB              :: 0x9126;
CONTEXT_FORWARD_COMPATIBLE_BIT_ARB    :: 0x0002;
CONTEXT_CORE_PROFILE_BIT_ARB          :: 0x00000001;
CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB :: 0x00000002;

Hglrc     :: distinct Handle;
Color_Ref :: distinct u32;

Layer_Plane_Descriptor :: struct {
	size:             u16,
	version:          u16,
	flags:            u32,
	pixel_type:       u8,
	color_bits:       u8,
	red_bits:         u8,
	red_shift:        u8,
	green_bits:       u8,
	green_shift:      u8,
	blue_bits:        u8,
	blue_shift:       u8,
	alpha_bits:       u8,
	alpha_shift:      u8,
	accum_bits:       u8,
	accum_red_bits:   u8,
	accum_green_bits: u8,
	accum_blue_bits:  u8,
	accum_alpha_bits: u8,
	depth_bits:       u8,
	stencil_bits:     u8,
	aux_buffers:      u8,
	layer_type:       u8,
	reserved:         u8,
	transparent:      Color_Ref,
}

Point_Float :: struct {x, y: f32};

Glyph_Metrics_Float :: struct {
	black_box_x:  f32,
	black_box_y:  f32,
	glyph_origin: Point_Float,
	cell_inc_x:   f32,
	cell_inc_y:   f32,
}

Create_Context_Attribs_ARB_Type :: #type proc "c" (hdc: Hdc, h_share_context: rawptr, attribList: ^i32) -> Hglrc;
Choose_Pixel_Format_ARB_Type    :: #type proc "c" (hdc: Hdc, attrib_i_list: ^i32, attrib_f_list: ^f32, max_formats: u32, formats: ^i32, num_formats : ^u32) -> Bool;
Swap_Interval_EXT_Type          :: #type proc "c" (interval: i32) -> bool;
Get_Extensions_String_ARB_Type  :: #type proc "c" (Hdc) -> cstring;

// Procedures
	create_context_attribs_arb: Create_Context_Attribs_ARB_Type;
	choose_pixel_format_arb:    Choose_Pixel_Format_ARB_Type;
	swap_interval_ext:          Swap_Interval_EXT_Type;
	get_extensions_string_arb:  Get_Extensions_String_ARB_Type;


foreign opengl32 {
	@(link_name="wglCreateContext")
	create_context :: proc(hdc: Hdc) -> Hglrc ---;

	@(link_name="wglMakeCurrent")
	make_current :: proc(hdc: Hdc, hglrc: Hglrc) -> Bool ---;

	@(link_name="wglGetProcAddress")
	get_gl_proc_address :: proc(c_str: cstring) -> rawptr ---;

	@(link_name="wglDeleteContext")
	delete_context :: proc(hglrc: Hglrc) -> Bool ---;

	@(link_name="wglCopyContext")
	copy_context :: proc(src, dst: Hglrc, mask: u32) -> Bool ---;

	@(link_name="wglCreateLayerContext")
	create_layer_context :: proc(hdc: Hdc, layer_plane: i32) -> Hglrc ---;

	@(link_name="wglDescribeLayerPlane")
	describe_layer_plane :: proc(hdc: Hdc, pixel_format, layer_plane: i32, bytes: u32, pd: ^Layer_Plane_Descriptor) -> Bool ---;

	@(link_name="wglGetCurrentContext")
	get_current_context :: proc() -> Hglrc ---;

	@(link_name="wglGetCurrentDC")
	get_current_dc :: proc() -> Hdc ---;

	@(link_name="wglGetLayerPaletteEntries")
	get_layer_palette_entries :: proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32 ---;

	@(link_name="wglRealizeLayerPalette")
	realize_layer_palette :: proc(hdc: Hdc, layer_plane: i32, realize: Bool) -> Bool ---;

	@(link_name="wglSetLayerPaletteEntries")
	set_layer_palette_entries :: proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32 ---;

	@(link_name="wglShareLists")
	share_lists :: proc(hglrc1, hglrc2: Hglrc) -> Bool ---;

	@(link_name="wglSwapLayerBuffers")
	swap_layer_buffers :: proc(hdc: Hdc, planes: u32) -> Bool ---;

	@(link_name="wglUseFontBitmaps")
	use_font_bitmaps :: proc(hdc: Hdc, first, count, list_base: u32) -> Bool ---;

	@(link_name="wglUseFontOutlines")
	use_font_outlines :: proc(hdc: Hdc, first, count, list_base: u32, deviation, extrusion: f32, format: i32, gmf: ^Glyph_Metrics_Float) -> Bool ---;
}
