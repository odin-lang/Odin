#foreign_system_library "opengl32.lib" when ODIN_OS == "windows";
#import . "windows.odin";

CONTEXT_MAJOR_VERSION_ARB          :: 0x2091;
CONTEXT_MINOR_VERSION_ARB          :: 0x2092;
CONTEXT_FLAGS_ARB                  :: 0x2094;
CONTEXT_PROFILE_MASK_ARB           :: 0x9126;
CONTEXT_FORWARD_COMPATIBLE_BIT_ARB :: 0x0002;
CONTEXT_CORE_PROFILE_BIT_ARB       :: 0x00000001;

Hglrc :: Handle;
Color_Ref :: u32;

Layer_Plane_Descriptor :: struct #ordered {
	size:             u16,
	version:          u16,
	flags:            u32,
	pixel_type:       byte,
	color_bits:       byte,
	red_bits:         byte,
	red_shift:        byte,
	green_bits:       byte,
	green_shift:      byte,
	blue_bits:        byte,
	blue_shift:       byte,
	alpha_bits:       byte,
	alpha_shift:      byte,
	accum_bits:       byte,
	accum_red_bits:   byte,
	accum_green_bits: byte,
	accum_blue_bits:  byte,
	accum_alpha_bits: byte,
	depth_bits:       byte,
	stencil_bits:     byte,
	aux_buffers:      byte,
	layer_type:       byte,
	reserved:         byte,
	transparent:      Color_Ref,
}

Point_Float :: struct #ordered {
	x, y: f32,
}

Glyph_Metrics_Float :: struct #ordered {
	black_box_x:  f32,
	black_box_y:  f32,
	glyph_origin: Point_Float,
	cell_inc_x:   f32,
	cell_inc_y:   f32,
}

Create_Context_Attribs_ARB_Type :: #type proc(hdc: Hdc, hshareContext: rawptr, attribList: ^i32) -> Hglrc;
Choose_Pixel_Format_ARB_Type    :: #type proc(hdc: Hdc, attrib_i_list: ^i32, attrib_f_list: ^f32, max_formats: u32, formats: ^i32, num_formats : ^u32) -> Bool #cc_c;


CreateContext           :: proc(hdc: Hdc) -> Hglrc                                                                                                 #foreign opengl32 "wglCreateContext";
MakeCurrent             :: proc(hdc: Hdc, hglrc: Hglrc) -> Bool                                                                                    #foreign opengl32 "wglMakeCurrent";
GetProcAddress          :: proc(c_str: ^u8) -> Proc                                                                                                #foreign opengl32 "wglGetProcAddress";
DeleteContext           :: proc(hglrc: Hglrc) -> Bool                                                                                              #foreign opengl32 "wglDeleteContext";
CopyContext             :: proc(src, dst: Hglrc, mask: u32) -> Bool                                                                                #foreign opengl32 "wglCopyContext";
CreateLayerContext      :: proc(hdc: Hdc, layer_plane: i32) -> Hglrc                                                                               #foreign opengl32 "wglCreateLayerContext";
DescribeLayerPlane      :: proc(hdc: Hdc, pixel_format, layer_plane: i32, bytes: u32, pd: ^Layer_Plane_Descriptor) -> Bool                         #foreign opengl32 "wglDescribeLayerPlane";
GetCurrentContext       :: proc() -> Hglrc                                                                                                         #foreign opengl32 "wglGetCurrentContext";
GetCurrentDC            :: proc() -> Hdc                                                                                                           #foreign opengl32 "wglGetCurrentDC";
GetLayerPaletteEntries  :: proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32                                                 #foreign opengl32 "wglGetLayerPaletteEntries";
RealizeLayerPalette     :: proc(hdc: Hdc, layer_plane: i32, realize: Bool) -> Bool                                                                 #foreign opengl32 "wglRealizeLayerPalette";
SetLayerPaletteEntries  :: proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32                                                 #foreign opengl32 "wglSetLayerPaletteEntries";
ShareLists              :: proc(hglrc1, hglrc2: Hglrc) -> Bool                                                                                     #foreign opengl32 "wglShareLists";
SwapLayerBuffers        :: proc(hdc: Hdc, planes: u32) -> Bool                                                                                     #foreign opengl32 "wglSwapLayerBuffers";
UseFontBitmaps          :: proc(hdc: Hdc, first, count, list_base: u32) -> Bool                                                                    #foreign opengl32 "wglUseFontBitmaps";
UseFontOutlines         :: proc(hdc: Hdc, first, count, list_base: u32, deviation, extrusion: f32, format: i32, gmf: ^Glyph_Metrics_Float) -> Bool #foreign opengl32 "wglUseFontOutlines";
