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

HGLRC :: distinct HANDLE;
Hglrc :: HGLRC;

COLORREF  :: distinct u32;
Color_Ref :: COLORREF;

LAYERPLANEDESCRIPTOR :: struct {
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
Layer_Plane_Descriptor :: LAYERPLANEDESCRIPTOR;


POINTFLOAT  :: struct {x, y: f32};
Point_Float :: POINTFLOAT;

GLYPHMETRICSFLOAT :: struct {
	black_box_x:  f32,
	black_box_y:  f32,
	glyph_origin: Point_Float,
	cell_inc_x:   f32,
	cell_inc_y:   f32,
}
Glyph_Metrics_Float :: GLYPHMETRICSFLOAT;


Create_Context_Attribs_ARB_Type :: #type proc "c" (hdc: HDC, h_share_context: rawptr, attribList: ^i32) -> HGLRC;
Choose_Pixel_Format_ARB_Type    :: #type proc "c" (hdc: HDC, attrib_i_list: ^i32, attrib_f_list: ^f32, max_formats: u32, formats: ^i32, num_formats : ^u32) -> BOOL;
Swap_Interval_EXT_Type          :: #type proc "c" (interval: i32) -> bool;
Get_Extensions_String_ARB_Type  :: #type proc "c" (HDC) -> cstring;

// Procedures
	create_context_attribs_arb: Create_Context_Attribs_ARB_Type;
	choose_pixel_format_arb:    Choose_Pixel_Format_ARB_Type;
	swap_interval_ext:          Swap_Interval_EXT_Type;
	get_extensions_string_arb:  Get_Extensions_String_ARB_Type;


foreign opengl32 {
	wglCreateContext     :: proc(hdc: HDC) -> HGLRC ---;
	wglDeleteContext     :: proc(hglrc: HGLRC) -> BOOL ---;
	wglMakeCurrent       :: proc(hdc: HDC, hglrc: HGLRC) -> BOOL ---;
	wglCopyContext       :: proc(src, dst: HGLRC, mask: u32) -> BOOL ---;
	wglGetCurrentContext :: proc() -> HGLRC ---;
	wglGetProcAddress    :: proc(c_str: cstring) -> rawptr ---;

	wglCreateLayerContext :: proc(hdc: HDC, layer_plane: i32) -> HGLRC ---;

	wglSwapLayerBuffers :: proc(hdc: HDC, planes: u32) -> BOOL ---;
	wglGetCurrentDC     :: proc() -> HDC ---;

	wglDescribeLayerPlane     :: proc(hdc: HDC, pixel_format, layer_plane: i32, bytes: u32, pd: ^Layer_Plane_Descriptor) -> BOOL ---;
	wglGetLayerPaletteEntries :: proc(hdc: HDC, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32 ---;
	wglRealizeLayerPalette    :: proc(hdc: HDC, layer_plane: i32, realize: BOOL) -> BOOL ---;
	wglSetLayerPaletteEntries :: proc(hdc: HDC, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32 ---;
	wglShareLists             :: proc(hglrc1, hglrc2: HGLRC) -> BOOL ---;

	wglUseFontBitmaps  :: proc(hdc: HDC, first, count, list_base: u32) -> BOOL ---;
	wglUseFontOutlines :: proc(hdc: HDC, first, count, list_base: u32, deviation, extrusion: f32, format: i32, gmf: ^Glyph_Metrics_Float) -> BOOL ---;
}

create_context            :: wglCreateContext;
delete_context            :: wglDeleteContext;
make_current              :: wglMakeCurrent;
copy_context              :: wglCopyContext;
get_current_context       :: wglGetCurrentContext;
get_gl_proc_address       :: wglGetProcAddress;
create_layer_context      :: wglCreateLayerContext;
swap_layer_buffers        :: wglSwapLayerBuffers;
get_current_dc            :: wglGetCurrentDC;
describe_layer_plane      :: wglDescribeLayerPlane;
get_layer_palette_entries :: wglGetLayerPaletteEntries;
realize_layer_palette     :: wglRealizeLayerPalette;
set_layer_palette_entries :: wglSetLayerPaletteEntries;
share_lists               :: wglShareLists;
use_font_bitmaps          :: wglUseFontBitmaps;
use_Font_outlines         :: wglUseFontOutlines;