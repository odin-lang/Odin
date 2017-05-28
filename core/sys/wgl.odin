#foreign_system_library "opengl32.lib" when ODIN_OS == "windows";
#import . "windows.odin";

CONTEXT_MAJOR_VERSION_ARB          :: 0x2091;
CONTEXT_MINOR_VERSION_ARB          :: 0x2092;
CONTEXT_FLAGS_ARB                  :: 0x2094;
CONTEXT_PROFILE_MASK_ARB           :: 0x9126;
CONTEXT_FORWARD_COMPATIBLE_BIT_ARB :: 0x0002;
CONTEXT_CORE_PROFILE_BIT_ARB       :: 0x00000001;
CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB :: 0x00000002;

Hglrc :: Handle;
Color_Ref :: u32;

LayerPlaneDescriptor :: struct {
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

PointFloat :: struct {
	x, y: f32,
}

Glyph_MetricsFloat :: struct {
	black_box_x:  f32,
	black_box_y:  f32,
	glyph_origin: PointFloat,
	cell_inc_x:   f32,
	cell_inc_y:   f32,
}

CreateContextAttribsARBType :: #type proc(hdc: Hdc, h_share_context: rawptr, attribList: ^i32) -> Hglrc;
ChoosePixelFormatARBType    :: #type proc(hdc: Hdc, attrib_i_list: ^i32, attrib_f_list: ^f32, max_formats: u32, formats: ^i32, num_formats : ^u32) -> Bool #cc_c;
SwapIntervalEXTType         :: #type proc(interval : i32) -> bool #cc_c;
GetExtensionsStringARBType  :: #type proc(Hdc) -> ^byte #cc_c;


CreateContextAttribsARB: CreateContextAttribsARBType;
ChoosePixelFormatARB:    ChoosePixelFormatARBType;
SwapIntervalEXT:         SwapIntervalEXTType;
GetExtensionsStringARB:  GetExtensionsStringARBType;



CreateContext           :: proc(hdc: Hdc) -> Hglrc                                                                                                 #foreign opengl32 "wglCreateContext";
MakeCurrent             :: proc(hdc: Hdc, hglrc: Hglrc) -> Bool                                                                                    #foreign opengl32 "wglMakeCurrent";
GetProcAddress          :: proc(c_str: ^u8) -> Proc                                                                                                #foreign opengl32 "wglGetProcAddress";
DeleteContext           :: proc(hglrc: Hglrc) -> Bool                                                                                              #foreign opengl32 "wglDeleteContext";
CopyContext             :: proc(src, dst: Hglrc, mask: u32) -> Bool                                                                                #foreign opengl32 "wglCopyContext";
CreateLayerContext      :: proc(hdc: Hdc, layer_plane: i32) -> Hglrc                                                                               #foreign opengl32 "wglCreateLayerContext";
DescribeLayerPlane      :: proc(hdc: Hdc, pixel_format, layer_plane: i32, bytes: u32, pd: ^LayerPlaneDescriptor) -> Bool                         #foreign opengl32 "wglDescribeLayerPlane";
GetCurrentContext       :: proc() -> Hglrc                                                                                                         #foreign opengl32 "wglGetCurrentContext";
GetCurrentDC            :: proc() -> Hdc                                                                                                           #foreign opengl32 "wglGetCurrentDC";
GetLayerPaletteEntries  :: proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32                                                 #foreign opengl32 "wglGetLayerPaletteEntries";
RealizeLayerPalette     :: proc(hdc: Hdc, layer_plane: i32, realize: Bool) -> Bool                                                                 #foreign opengl32 "wglRealizeLayerPalette";
SetLayerPaletteEntries  :: proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^Color_Ref) -> i32                                                 #foreign opengl32 "wglSetLayerPaletteEntries";
ShareLists              :: proc(hglrc1, hglrc2: Hglrc) -> Bool                                                                                     #foreign opengl32 "wglShareLists";
SwapLayerBuffers        :: proc(hdc: Hdc, planes: u32) -> Bool                                                                                     #foreign opengl32 "wglSwapLayerBuffers";
UseFontBitmaps          :: proc(hdc: Hdc, first, count, list_base: u32) -> Bool                                                                    #foreign opengl32 "wglUseFontBitmaps";
UseFontOutlines         :: proc(hdc: Hdc, first, count, list_base: u32, deviation, extrusion: f32, format: i32, gmf: ^Glyph_MetricsFloat) -> Bool #foreign opengl32 "wglUseFontOutlines";
