// Bindings for [[ EGL ; https://registry.khronos.org/EGL/sdk/docs/man/html/eglIntro.xhtml ]].
#+build linux
package egl

NativeDisplayType :: distinct rawptr
NativePixmapType  :: distinct rawptr
NativeWindowType  :: distinct rawptr
Display :: distinct rawptr
Surface :: distinct rawptr
Config  :: distinct rawptr
Context :: distinct rawptr
ClientBuffer :: distinct rawptr

Sync :: distinct rawptr
Image :: distinct rawptr

Boolean :: b32

FALSE :: false
TRUE :: true

UNKNOWN :: i32(-1)

NO_DISPLAY :: Display(uintptr(0))
NO_CONTEXT :: Context(uintptr(0))
NO_SURFACE :: Surface(uintptr(0))
NO_IMAGE   :: Image(uintptr(0))
NO_SYNC    :: Sync(uintptr(0))

DEFAULT_DISPLAY :: NativeDisplayType(uintptr(0))

CONTEXT_OPENGL_CORE_PROFILE_BIT :: 0x00000001
CONTEXT_OPENGL_COMPATIBILITY_PROFILE_BIT :: 0x00000002
PBUFFER_BIT       :: 0x0001
PIXMAP_BIT        :: 0x0002
WINDOW_BIT        :: 0x0004
OPENVG_BIT        :: 0x0002
OPENGL_BIT        :: 0x0008
OPENGL_ES_BIT     :: 0x0001
OPENGL_ES2_BIT    :: 0x0004
OPENGL_ES3_BIT    :: 0x00000040

OPENGL_ES_API     :: 0x30A0
OPENVG_API        :: 0x30A1
OPENGL_API        :: 0x30A2

OPENVG_IMAGE      :: 0x3096

DISPLAY_SCALING   :: 10000

SUCCESS               :: 0x3000
NOT_INITIALIZED       :: 0x3001
BAD_ACCESS            :: 0x3002
BAD_ALLOC             :: 0x3003
BAD_ATTRIBUTE         :: 0x3004
BAD_CONFIG            :: 0x3005
BAD_CONTEXT           :: 0x3006
BAD_CURRENT_SURFACE   :: 0x3007
BAD_DISPLAY           :: 0x3008
BAD_MATCH             :: 0x3009
BAD_NATIVE_PIXMAP     :: 0x300A
BAD_NATIVE_WINDOW     :: 0x300B
BAD_PARAMETER         :: 0x300C
BAD_SURFACE           :: 0x300D
CONTEXT_LOST          :: 0x300E

BUFFER_SIZE        :: 0x3020
ALPHA_SIZE         :: 0x3021
BLUE_SIZE          :: 0x3022
GREEN_SIZE         :: 0x3023
RED_SIZE           :: 0x3024
DEPTH_SIZE         :: 0x3025
STENCIL_SIZE       :: 0x3026
CONFIG_CAVEAT      :: 0x3027
CONFIG_ID          :: 0x3028
LEVEL              :: 0x3029
MAX_PBUFFER_HEIGHT :: 0x302A
MAX_PBUFFER_PIXELS :: 0x302B
MAX_PBUFFER_WIDTH  :: 0x302C
NATIVE_RENDERABLE  :: 0x302D
NATIVE_VISUAL_ID   :: 0x302E
NATIVE_VISUAL_TYPE :: 0x302F

SAMPLES                 :: 0x3031
SAMPLE_BUFFERS          :: 0x3032
SURFACE_TYPE            :: 0x3033
TRANSPARENT_TYPE        :: 0x3034
TRANSPARENT_BLUE_VALUE  :: 0x3035
TRANSPARENT_GREEN_VALUE :: 0x3036
TRANSPARENT_RED_VALUE   :: 0x3037
NONE                    :: 0x3038
BIND_TO_TEXTURE_RGB     :: 0x3039
BIND_TO_TEXTURE_RGBA    :: 0x303A
MIN_SWAP_INTERVAL       :: 0x303B
MAX_SWAP_INTERVAL       :: 0x303C
LUMINANCE_SIZE          :: 0x303D
ALPHA_MASK_SIZE         :: 0x303E
COLOR_BUFFER_TYPE       :: 0x303F
RENDERABLE_TYPE         :: 0x3040
MATCH_NATIVE_PIXMAP     :: 0x3041
CONFORMANT              :: 0x3042
SLOW_CONFIG             :: 0x3050
NON_CONFORMANT_CONFIG   :: 0x3051
TRANSPARENT_RGB         :: 0x3052
VENDOR                  :: 0x3053
VERSION                 :: 0x3054
EXTENSIONS              :: 0x3055
HEIGHT                  :: 0x3056
WIDTH                   :: 0x3057
LARGEST_PBUFFER         :: 0x3058
DRAW                    :: 0x3059
READ                    :: 0x305A
CORE_NATIVE_ENGINE      :: 0x305B
NO_TEXTURE              :: 0x305C
TEXTURE_RGB             :: 0x305D
TEXTURE_RGBA            :: 0x305E
TEXTURE_2D              :: 0x305F


EGL_TEXTURE_FORMAT   :: 0x3080
EGL_TEXTURE_TARGET   :: 0x3081
MIPMAP_TEXTURE       :: 0x3082
MIPMAP_LEVEL         :: 0x3083
BACK_BUFFER          :: 0x3084
SINGLE_BUFFER        :: 0x3085
RENDER_BUFFER        :: 0x3086
COLORSPACE           :: 0x3087
ALPHA_FORMAT         :: 0x3088
GL_COLORSPACE_SRGB   :: 0x3089
GL_COLORSPACE_LINEAR :: 0x308A
ALPHA_FORMAT_NONPRE  :: 0x308B
ALPHA_FORMAT_PRE     :: 0x308C
CLIENT_APIS          :: 0x308D
RGB_BUFFER           :: 0x308E
LUMINANCE_BUFFER     :: 0x308F
GL_COLORSPACE        :: 0x309D

VG_COLORSPACE_LINEAR_BIT  :: 0x0020
VG_ALPHA_FORMAT_PRE_BIT   :: 0x0040

VG_COLORSPACE          :: 0x3087
VG_ALPHA_FORMAT        :: 0x3088
VG_COLORSPACE_SRGB     :: 0x3089
VG_COLORSPACE_LINEAR   :: 0x308A
VG_ALPHA_FORMAT_NONPRE :: 0x308B
VG_ALPHA_FORMAT_PRE    :: 0x308C

HORIZONTAL_RESOLUTION       :: 0x3090
VERTICAL_RESOLUTION         :: 0x3091
PIXEL_ASPECT_RATIO          :: 0x3092
SWAP_BEHAVIOR               :: 0x3093
BUFFER_PRESERVED            :: 0x3094
BUFFER_DESTROYED            :: 0x3095
CONTEXT_CLIENT_TYPE         :: 0x3097
CONTEXT_CLIENT_VERSION      :: 0x3098
CONTEXT_MAJOR_VERSION       :: 0x3098
MULTISAMPLE_RESOLVE         :: 0x3099
MULTISAMPLE_RESOLVE_DEFAULT :: 0x309A
MULTISAMPLE_RESOLVE_BOX     :: 0x309B
CL_EVENT_HANDLE             :: 0x309C
CONTEXT_MINOR_VERSION       :: 0x30FB
CONTEXT_OPENGL_PROFILE_MASK :: 0x30FD

CONTEXT_OPENGL_DEBUG              :: 0x31B0
CONTEXT_OPENGL_FORWARD_COMPATIBLE :: 0x31B1
CONTEXT_OPENGL_ROBUST_ACCESS      :: 0x31B2

MULTISAMPLE_RESOLVE_BOX_BIT :: 0x0200
SWAP_BEHAVIOR_PRESERVED_BIT :: 0x0400

CONTEXT_OPENGL_RESET_NOTIFICATION_STRATEGY ::0x31BD
NO_RESET_NOTIFICATION         :: 0x31BE
LOSE_CONTEXT_ON_RESET         :: 0x31BF


SYNC_PRIOR_COMMANDS_COMPLETE :: 0x30F0
SYNC_STATUS                  :: 0x30F1
SIGNALED                     :: 0x30F2
UNSIGNALED                   :: 0x30F3
TIMEOUT_EXPIRED              :: 0x30F5
CONDITION_SATISFIED          :: 0x30F6
SYNC_TYPE                    :: 0x30F7
SYNC_CONDITION               :: 0x30F8
SYNC_FENCE                   :: 0x30F9
SYNC_CL_EVENT                :: 0x30FE
SYNC_CL_EVENT_COMPLETE       :: 0x30FF

SYNC_FLUSH_COMMANDS_BIT      :: 0x0001

FOREVER                      :: 0xFFFFFFFFFFFFFFFF

GL_TEXTURE_2D                  :: 0x30B1
GL_TEXTURE_3D                  :: 0x30B2
GL_TEXTURE_CUBE_MAP_POSITIVE_X :: 0x30B3
GL_TEXTURE_CUBE_MAP_NEGATIVE_X :: 0x30B4
GL_TEXTURE_CUBE_MAP_POSITIVE_Y :: 0x30B5
GL_TEXTURE_CUBE_MAP_NEGATIVE_Y :: 0x30B6
GL_TEXTURE_CUBE_MAP_POSITIVE_Z :: 0x30B7
GL_TEXTURE_CUBE_MAP_NEGATIVE_Z :: 0x30B8
GL_RENDERBUFFER                :: 0x30B9
GL_TEXTURE_LEVEL               :: 0x30BC
GL_TEXTURE_ZOFFSET             :: 0x30BD

IMAGE_PRESERVED       ::       0x30D2

Platform :: enum u32 {
	ANDROID_KHR = 0x3141,
	GBM_KHR = 0x31D7,
	WAYLAND_KHR = 0x31D8,
	X11_KHR = 0x31D5,
	X11_SCREEN_KHR = 0x31D6,
	DEVICE_EXT = 0x313F,
	WAYLAND_EXT = 0x31D8,
	X11_EXT = 0x31D5,
	X11_SCREEN_EXT = 0x31D6,
	XCB_EXT = 0x31DC,
	XCB_SCREEN_EXT = 0x31DE,
	GBM_MESA = 0x31D7,
	SURFACELESS_MESA = 0x31DD,
}

foreign import egl "system:EGL"
@(default_calling_convention="c", link_prefix="egl")
foreign egl {
	CopyBuffers         :: proc(display: Display, surface: Surface, target: NativePixmapType) -> Boolean ---
	GetDisplay          :: proc(display: NativeDisplayType) -> Display ---
	GetCurrentDisplay   :: proc() -> Display ---
	GetPlatformDisplay  :: proc(platform: Platform, native_display: rawptr, attrib_list: ^int) -> Display ---
	GetCurrentSurface   :: proc(readdraw: i32) -> Surface ---
	Initialize          :: proc(display: Display, major: ^i32, minor: ^i32) -> Boolean ---
	BindAPI             :: proc(api: u32) -> Boolean ---
	QueryAPI            :: proc() -> u32 ---
	ReleaseThread       :: proc() -> Boolean ---
	WaitClient          :: proc() -> Boolean ---
	GetConfigs          :: proc(display: Display, configs: [^]Config, config_size: i32, num_config: ^i32) -> Boolean ---
	ChooseConfig        :: proc(display: Display, attrib_list: ^i32, configs: [^]Config, config_size: i32, num_config: ^i32) -> Boolean ---
	CreatePbufferFromClientBuffer :: proc(display: Display, buftype: u32, buffer: ClientBuffer, config: Config, attrib_list: ^i32) -> Surface ---
	CreatePbufferSurface:: proc(display: Display, config: Config, attrib_list: ^i32) -> Surface ---
	CreatePixmapSurface :: proc(display: Display, config: Config, pixmap: NativePixmapType, attrib_list: ^i32) -> Surface ---
	CreateWindowSurface :: proc(display: Display, config: Config, native_window: NativeWindowType, attrib_list: ^i32) -> Surface ---
	CreatePlatformWindowSurface :: proc(display: Display, config: Config, native_window: rawptr, attrib_list: ^int) -> Surface ---
	CreateContext       :: proc(display: Display, config: Config, share_context: Context, attrib_list: ^i32) -> Context ---
	MakeCurrent         :: proc(display: Display, draw: Surface, read: Surface, ctx: Context) -> Boolean ---
	QuerySurface        :: proc(display: Display, surface: Surface, attribute: i32, value: ^i32) -> Boolean ---
	QueryContext        :: proc(display: Display, ctx: Context, attribute: i32, value: ^i32) -> Boolean ---
	QueryString         :: proc(display: Display, name: i32) -> cstring ---
	SwapInterval        :: proc(display: Display, interval: i32) -> Boolean ---
	SwapBuffers         :: proc(display: Display, surface: Surface) -> Boolean ---
	GetProcAddress      :: proc(name: cstring) -> rawptr ---
	GetConfigAttrib     :: proc(display: Display, config: Config, attribute: i32, value: ^i32) -> Boolean ---
	DestroyContext      :: proc(display: Display, ctx: Context) -> Boolean ---
	DestroySurface      :: proc(display: Display, surface: Surface) -> Boolean ---
	Terminate           :: proc(display: Display) -> Boolean ---
	GetError            :: proc() -> i32 ---
	WaitGL              :: proc() -> Boolean ---
	WaitNative          :: proc(engine: i32) -> Boolean ---
	BindTexImage        :: proc(display: Display, surface: Surface, buffer: i32) -> Boolean ---
	ReleaseTexImage     :: proc(display: Display, surface: Surface, buffer: i32) -> Boolean ---
	SurfaceAttrib       :: proc(display: Display, surface: Surface, attribute: i32, value: i32) -> Boolean ---
	GetCurrentContext   :: proc() -> Context ---
	CreateSync          :: proc(display: Display, type: u32, attrib_list: ^int) -> Sync ---
	DestroySync         :: proc(display: Display, sync: Sync) -> Boolean ---
	ClientWaitSync      :: proc(display: Display, sync: Sync, flags: i32, timeout: u64) -> i32 ---
	GetSyncAttrib       :: proc(display: Display, sync: Sync, attribute: i32, value: ^int) -> Boolean ---
	CreateImage         :: proc(display: Display, ctx: Context, target: u32, buffer: ClientBuffer, attrib_list: ^int) -> Image ---
	DestroyImage        :: proc(display: Display, image: Image) -> Boolean ---
	CreatePlatformPixmapSurface :: proc(display: Display, config: Config, native_pixmap: rawptr, attrib_list: ^int) -> Surface ---
	WaitSync                    :: proc(display: Display, sync: Sync, flags: i32) -> Boolean ---
}

gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = GetProcAddress(name)
}
