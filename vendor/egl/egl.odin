//+build linux
package egl

NativeDisplayType :: distinct rawptr
NativeWindowType  :: distinct rawptr
Display :: distinct rawptr
Surface :: distinct rawptr
Config  :: distinct rawptr
Context :: distinct rawptr

NO_DISPLAY :: Display(uintptr(0))
NO_CONTEXT :: Context(uintptr(0))
NO_SURFACE :: Surface(uintptr(0))

CONTEXT_OPENGL_CORE_PROFILE_BIT :: 0x00000001
WINDOW_BIT        :: 0x0004
OPENGL_BIT        :: 0x0008

BLUE_SIZE         :: 0x3022
GREEN_SIZE        :: 0x3023
RED_SIZE          :: 0x3024
DEPTH_SIZE        :: 0x3025
STENCIL_SIZE      :: 0x3026

SURFACE_TYPE      :: 0x3033
NONE              :: 0x3038
COLOR_BUFFER_TYPE :: 0x303F
RENDERABLE_TYPE   :: 0x3040
CONFORMANT        :: 0x3042

BACK_BUFFER          :: 0x3084
RENDER_BUFFER        :: 0x3086
GL_COLORSPACE_SRGB   :: 0x3089
GL_COLORSPACE_LINEAR :: 0x308A
RGB_BUFFER           :: 0x308E
GL_COLORSPACE        :: 0x309D

CONTEXT_MAJOR_VERSION       :: 0x3098
CONTEXT_MINOR_VERSION       :: 0x30FB
CONTEXT_OPENGL_PROFILE_MASK :: 0x30FD

OPENGL_API        :: 0x30A2

foreign import egl "system:EGL"
@(default_calling_convention="c", link_prefix="egl")
foreign egl {
	GetDisplay          :: proc(display: NativeDisplayType) -> Display ---
	Initialize          :: proc(display: Display, major: ^i32, minor: ^i32) -> i32 ---
	BindAPI             :: proc(api: u32) -> i32 ---
	ChooseConfig        :: proc(display: Display, attrib_list: ^i32, configs: ^Config, config_size: i32, num_config: ^i32) -> i32 ---
	CreateWindowSurface :: proc(display: Display, config: Config, native_window: NativeWindowType, attrib_list: ^i32) -> Surface ---
	CreateContext       :: proc(display: Display, config: Config, share_context: Context, attrib_list: ^i32) -> Context ---
	MakeCurrent         :: proc(display: Display, draw: Surface, read: Surface, ctx: Context) -> i32 ---
	SwapInterval        :: proc(display: Display, interval: i32) -> i32 ---
	SwapBuffers         :: proc(display: Display, surface: Surface) -> i32 ---
	GetProcAddress      :: proc(name: cstring) -> rawptr ---
}

gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = GetProcAddress(name)
}
