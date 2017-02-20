#foreign_system_library "opengl32.lib" when ODIN_OS == "windows";
#import . "windows.odin";

CONTEXT_MAJOR_VERSION_ARB          :: 0x2091;
CONTEXT_MINOR_VERSION_ARB          :: 0x2092;
CONTEXT_FLAGS_ARB                  :: 0x2094;
CONTEXT_PROFILE_MASK_ARB           :: 0x9126;
CONTEXT_FORWARD_COMPATIBLE_BIT_ARB :: 0x0002;
CONTEXT_CORE_PROFILE_BIT_ARB       :: 0x00000001;

HGLRC :: HANDLE;
COLORREF :: u32;

LAYERPLANEDESCRIPTOR :: struct #ordered {
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
	transparent:      COLORREF,
}

POINTFLOAT :: struct #ordered {
	x, y: f32,
}

GLYPHMETRICSFLOAT :: struct #ordered {
	black_box_x:  f32,
	black_box_y:  f32,
	glyph_origin: POINTFLOAT,
	cell_inc_x:   f32,
	cell_inc_y:   f32,
}

CreateContextAttribsARBType :: #type proc(hdc: HDC, hshareContext: rawptr, attribList: ^i32) -> HGLRC;
ChoosePixelFormatARBType    :: #type proc(hdc: HDC, attrib_i_list: ^i32, attrib_f_list: ^f32, max_formats: u32, formats: ^i32, num_formats : ^u32) -> BOOL #cc_c;


CreateContext           :: proc(hdc: HDC) -> HGLRC                                                                                               #foreign opengl32 "wglCreateContext";
MakeCurrent             :: proc(hdc: HDC, hglrc: HGLRC) -> BOOL                                                                                  #foreign opengl32 "wglMakeCurrent";
GetProcAddress          :: proc(c_str: ^u8) -> PROC                                                                                              #foreign opengl32 "wglGetProcAddress";
DeleteContext           :: proc(hglrc: HGLRC) -> BOOL                                                                                            #foreign opengl32 "wglDeleteContext";
CopyContext             :: proc(src, dst: HGLRC, mask: u32) -> BOOL                                                                              #foreign opengl32 "wglCopyContext";
CreateLayerContext      :: proc(hdc: HDC, layer_plane: i32) -> HGLRC                                                                             #foreign opengl32 "wglCreateLayerContext";
DescribeLayerPlane      :: proc(hdc: HDC, pixel_format, layer_plane: i32, bytes: u32, pd: ^LAYERPLANEDESCRIPTOR) -> BOOL                         #foreign opengl32 "wglDescribeLayerPlane";
GetCurrentContext       :: proc() -> HGLRC                                                                                                       #foreign opengl32 "wglGetCurrentContext";
GetCurrentDC            :: proc() -> HDC                                                                                                         #foreign opengl32 "wglGetCurrentDC";
GetLayerPaletteEntries  :: proc(hdc: HDC, layer_plane, start, entries: i32, cr: ^COLORREF) -> i32                                                #foreign opengl32 "wglGetLayerPaletteEntries";
RealizeLayerPalette     :: proc(hdc: HDC, layer_plane: i32, realize: BOOL) -> BOOL                                                               #foreign opengl32 "wglRealizeLayerPalette";
SetLayerPaletteEntries  :: proc(hdc: HDC, layer_plane, start, entries: i32, cr: ^COLORREF) -> i32                                                #foreign opengl32 "wglSetLayerPaletteEntries";
ShareLists              :: proc(hglrc1, hglrc2: HGLRC) -> BOOL                                                                                   #foreign opengl32 "wglShareLists";
SwapLayerBuffers        :: proc(hdc: HDC, planes: u32) -> BOOL                                                                                   #foreign opengl32 "wglSwapLayerBuffers";
UseFontBitmaps          :: proc(hdc: HDC, first, count, list_base: u32) -> BOOL                                                                  #foreign opengl32 "wglUseFontBitmaps";
UseFontOutlines         :: proc(hdc: HDC, first, count, list_base: u32, deviation, extrusion: f32, format: i32, gmf: ^GLYPHMETRICSFLOAT) -> BOOL #foreign opengl32 "wglUseFontOutlines";
