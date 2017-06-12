#foreign_system_library "opengl32.lib" when ODIN_OS == "windows";
#import . "windows.odin";

const CONTEXT_MAJOR_VERSION_ARB          = 0x2091;
const CONTEXT_MINOR_VERSION_ARB          = 0x2092;
const CONTEXT_FLAGS_ARB                  = 0x2094;
const CONTEXT_PROFILE_MASK_ARB           = 0x9126;
const CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x0002;
const CONTEXT_CORE_PROFILE_BIT_ARB       = 0x00000001;
const CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002;

const Hglrc = Handle;
const ColorRef = u32;

const LayerPlaneDescriptor = struct {
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
	transparent:      ColorRef,
}

const PointFloat = struct {
	x, y: f32,
}

const Glyph_MetricsFloat = struct {
	black_box_x:  f32,
	black_box_y:  f32,
	glyph_origin: PointFloat,
	cell_inc_x:   f32,
	cell_inc_y:   f32,
}

const CreateContextAttribsARBType = type proc(hdc: Hdc, h_share_context: rawptr, attribList: ^i32) -> Hglrc;
const ChoosePixelFormatARBType    = type proc(hdc: Hdc, attrib_i_list: ^i32, attrib_f_list: ^f32, max_formats: u32, formats: ^i32, num_formats : ^u32) -> Bool #cc_c;
const SwapIntervalEXTType         = type proc(interval: i32) -> bool #cc_c;
const GetExtensionsStringARBType  = type proc(Hdc) -> ^u8 #cc_c;


var create_context_attribs_arb: CreateContextAttribsARBType;
var choose_pixel_format_arb:    ChoosePixelFormatARBType;
var swap_interval_ext:          SwapIntervalEXTType;
var get_extensions_string_arb:  GetExtensionsStringARBType;



const create_context            = proc(hdc: Hdc) -> Hglrc                                                                                                 #foreign opengl32 "wglCreateContext";
const make_current              = proc(hdc: Hdc, hglrc: Hglrc) -> Bool                                                                                    #foreign opengl32 "wglMakeCurrent";
const get_proc_address          = proc(c_str: ^u8) -> Proc                                                                                                #foreign opengl32 "wglGetProcAddress";
const delete_context            = proc(hglrc: Hglrc) -> Bool                                                                                              #foreign opengl32 "wglDeleteContext";
const copy_context              = proc(src, dst: Hglrc, mask: u32) -> Bool                                                                                #foreign opengl32 "wglCopyContext";
const create_layer_context      = proc(hdc: Hdc, layer_plane: i32) -> Hglrc                                                                               #foreign opengl32 "wglCreateLayerContext";
const describe_layer_plane      = proc(hdc: Hdc, pixel_format, layer_plane: i32, bytes: u32, pd: ^LayerPlaneDescriptor) -> Bool                           #foreign opengl32 "wglDescribeLayerPlane";
const get_current_context       = proc() -> Hglrc                                                                                                         #foreign opengl32 "wglGetCurrentContext";
const get_current_dc            = proc() -> Hdc                                                                                                           #foreign opengl32 "wglGetCurrentDC";
const get_layer_palette_entries = proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^ColorRef) -> i32                                                 #foreign opengl32 "wglGetLayerPaletteEntries";
const realize_layer_palette     = proc(hdc: Hdc, layer_plane: i32, realize: Bool) -> Bool                                                                 #foreign opengl32 "wglRealizeLayerPalette";
const set_layer_palette_entries = proc(hdc: Hdc, layer_plane, start, entries: i32, cr: ^ColorRef) -> i32                                                 #foreign opengl32 "wglSetLayerPaletteEntries";
const share_lists               = proc(hglrc1, hglrc2: Hglrc) -> Bool                                                                                     #foreign opengl32 "wglShareLists";
const swap_layer_buffers        = proc(hdc: Hdc, planes: u32) -> Bool                                                                                     #foreign opengl32 "wglSwapLayerBuffers";
const use_font_bitmaps          = proc(hdc: Hdc, first, count, list_base: u32) -> Bool                                                                    #foreign opengl32 "wglUseFontBitmaps";
const use_font_outlines         = proc(hdc: Hdc, first, count, list_base: u32, deviation, extrusion: f32, format: i32, gmf: ^Glyph_MetricsFloat) -> Bool  #foreign opengl32 "wglUseFontOutlines";
