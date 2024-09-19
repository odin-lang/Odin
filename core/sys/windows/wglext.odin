#+build windows
package sys_windows

// WGL_ARB_buffer_region
WGL_FRONT_COLOR_BUFFER_BIT_ARB :: 0x00000001
WGL_BACK_COLOR_BUFFER_BIT_ARB  :: 0x00000002
WGL_DEPTH_BUFFER_BIT_ARB       :: 0x00000004
WGL_STENCIL_BUFFER_BIT_ARB     :: 0x00000008

wglCreateBufferRegionARBType  :: #type proc "c" (hDC: HDC, iLayerPlane: c_int, uType: UINT) -> HANDLE
wglDeleteBufferRegionARBType  :: #type proc "c" (hRegion: HANDLE)
wglSaveBufferRegionARBType    :: #type proc "c" (hRegion: HANDLE, x: c_int, y: c_int, width: c_int, height: c_int) -> BOOL
wglRestoreBufferRegionARBType :: #type proc "c" (hRegion: HANDLE, x: c_int, y: c_int, width: c_int, height: c_int, xSrc: c_int, ySrc: c_int) -> BOOL

// wglCreateBufferRegionARB:  wglCreateBufferRegionARBType
// wglDeleteBufferRegionARB:  wglDeleteBufferRegionARBType
// wglSaveBufferRegionARB:    wglSaveBufferRegionARBType
// wglRestoreBufferRegionARB: wglRestoreBufferRegionARBType

// WGL_ARB_context_flush_control
WGL_CONTEXT_RELEASE_BEHAVIOR_ARB       :: 0x2097
WGL_CONTEXT_RELEASE_BEHAVIOR_NONE_ARB  :: 0
WGL_CONTEXT_RELEASE_BEHAVIOR_FLUSH_ARB :: 0x2098

// WGL_ARB_create_context
WGL_CONTEXT_DEBUG_BIT_ARB              :: 0x0001
WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB :: 0x0002
WGL_CONTEXT_MAJOR_VERSION_ARB          :: 0x2091
WGL_CONTEXT_MINOR_VERSION_ARB          :: 0x2092
WGL_CONTEXT_LAYER_PLANE_ARB            :: 0x2093
WGL_CONTEXT_FLAGS_ARB                  :: 0x2094
ERROR_INVALID_VERSION_ARB              :: 0x2095

// WGL_ARB_create_context_no_error
WGL_CONTEXT_OPENGL_NO_ERROR_ARB             :: 0x31B3

// WGL_ARB_create_context_profile
WGL_CONTEXT_PROFILE_MASK_ARB                :: 0x9126
WGL_CONTEXT_CORE_PROFILE_BIT_ARB            :: 0x0001
WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB   :: 0x0002
ERROR_INVALID_PROFILE_ARB                   :: 0x2096

// WGL_ARB_create_context_robustness
WGL_CONTEXT_ROBUST_ACCESS_BIT_ARB           :: 0x00000004
WGL_LOSE_CONTEXT_ON_RESET_ARB               :: 0x8252
WGL_CONTEXT_RESET_NOTIFICATION_STRATEGY_ARB :: 0x8256
WGL_NO_RESET_NOTIFICATION_ARB               :: 0x8261

// WGL_ARB_framebuffer_sRGB
WGL_FRAMEBUFFER_SRGB_CAPABLE_ARB :: 0x20A9

// WGL_ARB_make_current_read
ERROR_INVALID_PIXEL_TYPE_ARB           :: 0x2043
ERROR_INCOMPATIBLE_DEVICE_CONTEXTS_ARB :: 0x2054

wglMakeContextCurrentARBType :: #type proc "c" (hDrawDC: HDC, hReadDC:HDC, hglrc: HGLRC) -> BOOL
wglGetCurrentReadDCARBType   :: #type proc "c" () -> HDC

// wglMakeContextCurrentARB: wglMakeContextCurrentARBType
// wglGetCurrentReadDCARB:   wglGetCurrentReadDCARBType

// WGL_ARB_multisample
WGL_SAMPLE_BUFFERS_ARB          :: 0x2041
WGL_SAMPLES_ARB                 :: 0x2042

// WGL_ARB_pbuffer
HPBUFFERARB :: distinct rawptr
WGL_DRAW_TO_PBUFFER_ARB         :: 0x202D
WGL_MAX_PBUFFER_PIXELS_ARB      :: 0x202E
WGL_MAX_PBUFFER_WIDTH_ARB       :: 0x202F
WGL_MAX_PBUFFER_HEIGHT_ARB      :: 0x2030
WGL_PBUFFER_LARGEST_ARB         :: 0x2033
WGL_PBUFFER_WIDTH_ARB           :: 0x2034
WGL_PBUFFER_HEIGHT_ARB          :: 0x2035
WGL_PBUFFER_LOST_ARB            :: 0x2036

wglCreatePbufferARBType    :: #type proc "c" (hDC: HDC, iPixelFormat, iWidth, iHeight: c_int, piAttribList: [^]c_int) -> HPBUFFERARB
wglGetPbufferDCARBType     :: #type proc "c" (hPbuffer: HPBUFFERARB) -> HDC
wglReleasePbufferDCARBType :: #type proc "c" (hPbuffer: HPBUFFERARB, hDC: HDC) -> c_int
wglDestroyPbufferARBType   :: #type proc "c" (hPbuffer: HPBUFFERARB) -> BOOL
wglQueryPbufferARBType     :: #type proc "c" (hPbuffer: HPBUFFERARB, iAttribute: c_int, piValue: ^c_int) -> BOOL

// wglCreatePbufferARB:    wglCreatePbufferARBType
// wglGetPbufferDCARB:     wglGetPbufferDCARBType
// wglReleasePbufferDCARB: wglReleasePbufferDCARBType
// wglDestroyPbufferARB:   wglDestroyPbufferARBType
// wglQueryPbufferARB:     wglQueryPbufferARBType

// WGL_ARB_pixel_format
WGL_NUMBER_PIXEL_FORMATS_ARB    :: 0x2000
WGL_DRAW_TO_WINDOW_ARB          :: 0x2001
WGL_DRAW_TO_BITMAP_ARB          :: 0x2002
WGL_ACCELERATION_ARB            :: 0x2003
WGL_NEED_PALETTE_ARB            :: 0x2004
WGL_NEED_SYSTEM_PALETTE_ARB     :: 0x2005
WGL_SWAP_LAYER_BUFFERS_ARB      :: 0x2006
WGL_SWAP_METHOD_ARB             :: 0x2007
WGL_NUMBER_OVERLAYS_ARB         :: 0x2008
WGL_NUMBER_UNDERLAYS_ARB        :: 0x2009
WGL_TRANSPARENT_ARB             :: 0x200A
WGL_TRANSPARENT_RED_VALUE_ARB   :: 0x2037
WGL_TRANSPARENT_GREEN_VALUE_ARB :: 0x2038
WGL_TRANSPARENT_BLUE_VALUE_ARB  :: 0x2039
WGL_TRANSPARENT_ALPHA_VALUE_ARB :: 0x203A
WGL_TRANSPARENT_INDEX_VALUE_ARB :: 0x203B
WGL_SHARE_DEPTH_ARB             :: 0x200C
WGL_SHARE_STENCIL_ARB           :: 0x200D
WGL_SHARE_ACCUM_ARB             :: 0x200E
WGL_SUPPORT_GDI_ARB             :: 0x200F
WGL_SUPPORT_OPENGL_ARB          :: 0x2010
WGL_DOUBLE_BUFFER_ARB           :: 0x2011
WGL_STEREO_ARB                  :: 0x2012
WGL_PIXEL_TYPE_ARB              :: 0x2013
WGL_COLOR_BITS_ARB              :: 0x2014
WGL_RED_BITS_ARB                :: 0x2015
WGL_RED_SHIFT_ARB               :: 0x2016
WGL_GREEN_BITS_ARB              :: 0x2017
WGL_GREEN_SHIFT_ARB             :: 0x2018
WGL_BLUE_BITS_ARB               :: 0x2019
WGL_BLUE_SHIFT_ARB              :: 0x201A
WGL_ALPHA_BITS_ARB              :: 0x201B
WGL_ALPHA_SHIFT_ARB             :: 0x201C
WGL_ACCUM_BITS_ARB              :: 0x201D
WGL_ACCUM_RED_BITS_ARB          :: 0x201E
WGL_ACCUM_GREEN_BITS_ARB        :: 0x201F
WGL_ACCUM_BLUE_BITS_ARB         :: 0x2020
WGL_ACCUM_ALPHA_BITS_ARB        :: 0x2021
WGL_DEPTH_BITS_ARB              :: 0x2022
WGL_STENCIL_BITS_ARB            :: 0x2023
WGL_AUX_BUFFERS_ARB             :: 0x2024
WGL_NO_ACCELERATION_ARB         :: 0x2025
WGL_GENERIC_ACCELERATION_ARB    :: 0x2026
WGL_FULL_ACCELERATION_ARB       :: 0x2027
WGL_SWAP_EXCHANGE_ARB           :: 0x2028
WGL_SWAP_COPY_ARB               :: 0x2029
WGL_SWAP_UNDEFINED_ARB          :: 0x202A
WGL_TYPE_RGBA_ARB               :: 0x202B
WGL_TYPE_COLORINDEX_ARB         :: 0x202C

wglGetPixelFormatAttribivARBType :: #type proc "c" (hdc: HDC, iPixelFormat, iLayerPlane: c_int, nAttributes: UINT, piAttributes: [^]c_int, piValues: [^]c_int) -> BOOL
wglGetPixelFormatAttribfvARBType :: #type proc "c" (hdc: HDC, iPixelFormat, iLayerPlane: c_int, nAttributes: UINT, piAttributes: [^]c_int, pfValues: [^]f32) -> BOOL

// wglGetPixelFormatAttribivARB: wglGetPixelFormatAttribivARBType
// wglGetPixelFormatAttribfvARB: wglGetPixelFormatAttribfvARBType

// WGL_ARB_pixel_format_float
WGL_TYPE_RGBA_FLOAT_ARB         :: 0x21A0
