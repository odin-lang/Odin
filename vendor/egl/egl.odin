// Bindings for [[ EGL ; https://registry.khronos.org/EGL/sdk/docs/man/html/eglIntro.xhtml ]].
#+build linux
package egl

NativeDisplayType :: distinct rawptr
NativeWindowType  :: distinct rawptr
Display :: distinct rawptr
Surface :: distinct rawptr
Config  :: distinct rawptr
Context :: distinct rawptr

Boolean :: b32

FALSE :: false
TRUE :: true

NO_DISPLAY :: Display(uintptr(0))
NO_CONTEXT :: Context(uintptr(0))
NO_SURFACE :: Surface(uintptr(0))

DEFAULT_DISPLAY :: NativeDisplayType(uintptr(0))

CONTEXT_OPENGL_CORE_PROFILE_BIT :: 0x00000001
WINDOW_BIT        :: 0x0004
OPENGL_BIT        :: 0x0008
OPENGL_ES2_BIT    :: 0x0004
OPENGL_ES3_BIT    :: 0x00000040

BUFFER_SIZE       :: 0x3020
ALPHA_SIZE        :: 0x3021
BLUE_SIZE         :: 0x3022
GREEN_SIZE        :: 0x3023
RED_SIZE          :: 0x3024
DEPTH_SIZE        :: 0x3025
STENCIL_SIZE      :: 0x3026
NATIVE_VISUAL_ID  :: 0x302E

SURFACE_TYPE      :: 0x3033
NONE              :: 0x3038
COLOR_BUFFER_TYPE :: 0x303F
RENDERABLE_TYPE   :: 0x3040
CONFORMANT        :: 0x3042
VENDOR            :: 0x3053
VERSION           :: 0x3054
HEIGHT            :: 0x3056
WIDTH             :: 0x3057

BACK_BUFFER          :: 0x3084
RENDER_BUFFER        :: 0x3086
GL_COLORSPACE_SRGB   :: 0x3089
GL_COLORSPACE_LINEAR :: 0x308A
RGB_BUFFER           :: 0x308E
GL_COLORSPACE        :: 0x309D

CONTEXT_CLIENT_VERSION      :: 0x3098
CONTEXT_MAJOR_VERSION       :: 0x3098
CONTEXT_MINOR_VERSION       :: 0x30FB
CONTEXT_OPENGL_PROFILE_MASK :: 0x30FD

OPENGL_API        :: 0x30A2

CONTEXT_OPENGL_DEBUG :: 0x31B0

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
	GetDisplay          :: proc(display: NativeDisplayType) -> Display ---
	GetPlatformDisplay  :: proc(platform: Platform, native_display: rawptr, attrib_list: ^int) -> Display ---
	Initialize          :: proc(display: Display, major: ^i32, minor: ^i32) -> Boolean ---
	BindAPI             :: proc(api: u32) -> Boolean ---
	ChooseConfig        :: proc(display: Display, attrib_list: ^i32, configs: [^]Config, config_size: i32, num_config: ^i32) -> Boolean ---
	CreateWindowSurface :: proc(display: Display, config: Config, native_window: NativeWindowType, attrib_list: ^i32) -> Surface ---
	CreatePlatformWindowSurface :: proc(display: Display, config: Config, native_window: rawptr, attrib_list: ^int) -> Surface ---
	CreateContext       :: proc(display: Display, config: Config, share_context: Context, attrib_list: ^i32) -> Context ---
	MakeCurrent         :: proc(display: Display, draw: Surface, read: Surface, ctx: Context) -> Boolean ---
	QuerySurface        :: proc(display: Display, surface: Surface, attribute: i32, value: ^i32) -> Boolean ---
	QueryString         :: proc(display: Display, name: i32) -> cstring ---
	SwapInterval        :: proc(display: Display, interval: i32) -> Boolean ---
	SwapBuffers         :: proc(display: Display, surface: Surface) -> Boolean ---
	GetProcAddress      :: proc(name: cstring) -> rawptr ---
	GetConfigAttrib     :: proc(display: Display, config: Config, attribute: i32, value: ^i32) -> Boolean ---
	DestroyContext      :: proc(display: Display, ctx: Context) -> Boolean ---
	DestroySurface      :: proc(display: Display, surface: Surface) -> Boolean ---
	Terminate           :: proc(display: Display) -> Boolean ---
}

gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = GetProcAddress(name)
}
