package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

DisplayMode :: struct {
	format:       u32,    /**< pixel format */
	w:            c.int,  /**< width, in screen coordinates */
	h:            c.int,  /**< height, in screen coordinates */
	refresh_rate: c.int,  /**< refresh rate (or zero for unspecified) */
	driverdata:   rawptr, /**< driver-specific data, initialize to 0 */
}

Window :: struct {}

WindowFlag :: enum u32 {
	FULLSCREEN    = 0,       /**< fullscreen window */
	OPENGL        = 1,       /**< window usable with OpenGL context */
	SHOWN         = 2,       /**< window is visible */
	HIDDEN        = 3,       /**< window is not visible */
	BORDERLESS    = 4,       /**< no window decoration */
	RESIZABLE     = 5,       /**< window can be resized */
	MINIMIZED     = 6,       /**< window is minimized */
	MAXIMIZED     = 7,       /**< window is maximized */
	MOUSE_GRABBED = 8,       /**< window has grabbed mouse input */
	INPUT_FOCUS   = 9,       /**< window has input focus */
	MOUSE_FOCUS   = 10,      /**< window has mouse focus */
	_INTERNAL_FULLSCREEN_DESKTOP = 12,
	FOREIGN       = 11,      /**< window not created by SDL */
	ALLOW_HIGHDPI = 13,      /**< window should be created in high-DPI mode if supported.
	                                             On macOS NSHighResolutionCapable must be set true in the
	                                             application's Info.plist for this to have any effect. */
	MOUSE_CAPTURE    = 14,   /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
	ALWAYS_ON_TOP    = 15,   /**< window should always be above others */
	SKIP_TASKBAR     = 16,   /**< window should not be added to the taskbar */
	UTILITY          = 17,   /**< window should be treated as a utility window */
	TOOLTIP          = 18,   /**< window should be treated as a tooltip */
	POPUP_MENU       = 19,   /**< window should be treated as a popup menu */
	KEYBOARD_GRABBED = 20,   /**< window has grabbed keyboard input */
	VULKAN           = 28,   /**< window usable for Vulkan surface */
	METAL            = 29,   /**< window usable for Metal view */

	INPUT_GRABBED = MOUSE_GRABBED, /**< equivalent to SDL_WINDOW_MOUSE_GRABBED for compatibility */
}
WindowFlags :: distinct bit_set[WindowFlag; u32]


WINDOW_FULLSCREEN         :: WindowFlags{.FULLSCREEN}
WINDOW_OPENGL             :: WindowFlags{.OPENGL}
WINDOW_SHOWN              :: WindowFlags{.SHOWN}
WINDOW_HIDDEN             :: WindowFlags{.HIDDEN}
WINDOW_BORDERLESS         :: WindowFlags{.BORDERLESS}
WINDOW_RESIZABLE          :: WindowFlags{.RESIZABLE}
WINDOW_MINIMIZED          :: WindowFlags{.MINIMIZED}
WINDOW_MAXIMIZED          :: WindowFlags{.MAXIMIZED}
WINDOW_MOUSE_GRABBED      :: WindowFlags{.MOUSE_GRABBED}
WINDOW_INPUT_FOCUS        :: WindowFlags{.INPUT_FOCUS}
WINDOW_MOUSE_FOCUS        :: WindowFlags{.MOUSE_FOCUS}
WINDOW_FULLSCREEN_DESKTOP :: WindowFlags{.FULLSCREEN, ._INTERNAL_FULLSCREEN_DESKTOP}
WINDOW_FOREIGN            :: WindowFlags{.FOREIGN}
WINDOW_ALLOW_HIGHDPI      :: WindowFlags{.ALLOW_HIGHDPI}
WINDOW_MOUSE_CAPTURE      :: WindowFlags{.MOUSE_CAPTURE}
WINDOW_ALWAYS_ON_TOP      :: WindowFlags{.ALWAYS_ON_TOP}
WINDOW_SKIP_TASKBAR       :: WindowFlags{.SKIP_TASKBAR}
WINDOW_UTILITY            :: WindowFlags{.UTILITY}
WINDOW_TOOLTIP            :: WindowFlags{.TOOLTIP}
WINDOW_POPUP_MENU         :: WindowFlags{.POPUP_MENU}
WINDOW_KEYBOARD_GRABBED   :: WindowFlags{.KEYBOARD_GRABBED}
WINDOW_VULKAN             :: WindowFlags{.VULKAN}
WINDOW_METAL              :: WindowFlags{.METAL}
WINDOW_INPUT_GRABBED      :: WindowFlags{.INPUT_GRABBED}


WINDOWPOS_UNDEFINED_MASK :: 0x1FFF0000
WINDOWPOS_UNDEFINED_DISPLAY :: #force_inline proc "c" (X: c.int) -> c.int { return WINDOWPOS_UNDEFINED_MASK|X }
WINDOWPOS_UNDEFINED :: WINDOWPOS_UNDEFINED_MASK|0
WINDOWPOS_ISUNDEFINED :: #force_inline proc "c" (X: c.int) -> bool {
	return u32(X)&0xFFFF0000 == WINDOWPOS_UNDEFINED_MASK
}

WINDOWPOS_CENTERED_MASK :: 0x2FFF0000
WINDOWPOS_CENTERED_DISPLAY :: #force_inline proc "c" (X: c.int) -> c.int { return WINDOWPOS_CENTERED_MASK|X }
WINDOWPOS_CENTERED :: WINDOWPOS_CENTERED_MASK|0
WINDOWPOS_ISCENTERED :: #force_inline proc "c" (X: c.int) -> bool {
	return u32(X)&0xFFFF0000 == WINDOWPOS_CENTERED_MASK
}


WindowEventID :: enum u8 {
	NONE,           /**< Never used */
	SHOWN,          /**< Window has been shown */
	HIDDEN,         /**< Window has been hidden */
	EXPOSED,        /**< Window has been exposed and should be
	                                 redrawn */
	MOVED,          /**< Window has been moved to data1, data2
	                             */
	RESIZED,        /**< Window has been resized to data1xdata2 */
	SIZE_CHANGED,   /**< The window size has changed, either as
	                                 a result of an API call or through the
	                                 system or user changing the window size. */
	MINIMIZED,      /**< Window has been minimized */
	MAXIMIZED,      /**< Window has been maximized */
	RESTORED,       /**< Window has been restored to normal size
	                                 and position */
	ENTER,          /**< Window has gained mouse focus */
	LEAVE,          /**< Window has lost mouse focus */
	FOCUS_GAINED,   /**< Window has gained keyboard focus */
	FOCUS_LOST,     /**< Window has lost keyboard focus */
	CLOSE,          /**< The window manager requests that the window be closed */
	TAKE_FOCUS,     /**< Window is being offered a focus (should SetWindowInputFocus() on itself or a subwindow, or ignore) */
	HIT_TEST,       /**< Window had a hit test that wasn't SDL_HITTEST_NORMAL. */
}

DisplayEventID :: enum u8 {
	NONE,          /**< Never used */
	ORIENTATION,   /**< Display orientation has changed to data1 */
	CONNECTED,     /**< Display has been added to the system */
	DISCONNECTED,  /**< Display has been removed from the system */
}

DisplayOrientation :: enum c.int {
	UNKNOWN,            /**< The display orientation can't be determined */
	LANDSCAPE,          /**< The display is in landscape mode, with the right side up, relative to portrait mode */
	LANDSCAPE_FLIPPED,  /**< The display is in landscape mode, with the left side up, relative to portrait mode */
	PORTRAIT,           /**< The display is in portrait mode */
	PORTRAIT_FLIPPED,   /**< The display is in portrait mode, upside down */
}

FlashOperation :: enum c.int {
	CANCEL,                   /**< Cancel any window flash state */
	BRIEFLY,                  /**< Flash the window briefly to get attention */
	UNTIL_FOCUSED,            /**< Flash the window until it gets focus */
}

GLContext :: distinct rawptr

GLattr :: enum c.int {
	RED_SIZE,
	GREEN_SIZE,
	BLUE_SIZE,
	ALPHA_SIZE,
	BUFFER_SIZE,
	DOUBLEBUFFER,
	DEPTH_SIZE,
	STENCIL_SIZE,
	ACCUM_RED_SIZE,
	ACCUM_GREEN_SIZE,
	ACCUM_BLUE_SIZE,
	ACCUM_ALPHA_SIZE,
	STEREO,
	MULTISAMPLEBUFFERS,
	MULTISAMPLESAMPLES,
	ACCELERATED_VISUAL,
	RETAINED_BACKING,
	CONTEXT_MAJOR_VERSION,
	CONTEXT_MINOR_VERSION,
	CONTEXT_EGL,
	CONTEXT_FLAGS,
	CONTEXT_PROFILE_MASK,
	SHARE_WITH_CURRENT_CONTEXT,
	FRAMEBUFFER_SRGB_CAPABLE,
	CONTEXT_RELEASE_BEHAVIOR,
	CONTEXT_RESET_NOTIFICATION,
	CONTEXT_NO_ERROR,
}

GLprofile :: enum c.int {
	CORE           = 0x0001,
	COMPATIBILITY  = 0x0002,
	ES             = 0x0004, /**< GLX_CONTEXT_ES2_PROFILE_BIT_EXT */
}

GLcontextFlag :: enum c.int {
	DEBUG_FLAG              = 0x0001,
	FORWARD_COMPATIBLE_FLAG = 0x0002,
	ROBUST_ACCESS_FLAG      = 0x0004,
	RESET_ISOLATION_FLAG    = 0x0008,
}

GLcontextReleaseFlag :: enum c.int {
	NONE   = 0x0000,
	FLUSH  = 0x0001,
}

GLContextResetNotification :: enum c.int {
	NO_NOTIFICATION = 0x0000,
	LOSE_CONTEXT    = 0x0001,
}


HitTestResult :: enum c.int {
	NORMAL,  /**< Region is normal. No special properties. */
	DRAGGABLE,  /**< Region can drag entire window. */
	RESIZE_TOPLEFT,
	RESIZE_TOP,
	RESIZE_TOPRIGHT,
	RESIZE_RIGHT,
	RESIZE_BOTTOMRIGHT,
	RESIZE_BOTTOM,
	RESIZE_BOTTOMLEFT,
	RESIZE_LEFT,
}

HitTest :: proc "c" (win: ^Window, area: ^Point, data: rawptr) -> HitTestResult


@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumVideoDrivers       :: proc() -> c.int ---
	GetVideoDriver           :: proc(index: c.int) -> cstring ---
	VideoInit                :: proc(driver_name: cstring) -> c.int ---
	VideoQuit                :: proc() ---
	GetCurrentVideoDriver    :: proc() -> cstring ---
	GetNumVideoDisplays      :: proc() -> c.int ---
	GetDisplayName           :: proc(displayIndex: c.int) -> cstring ---
	GetDisplayBounds         :: proc(displayIndex: c.int, rect: ^Rect) -> c.int ---
	GetDisplayUsableBounds   :: proc(displayIndex: c.int, rect: ^Rect) -> c.int ---
	GetDisplayDPI            :: proc(displayIndex: c.int, ddpi, hdpi, vdpi: ^f32) -> c.int ---
	GetDisplayOrientation    :: proc(displayIndex: c.int) -> DisplayOrientation ---
	GetNumDisplayModes       :: proc(displayIndex: c.int) -> c.int ---
	GetDisplayMode           :: proc(displayIndex: c.int, modeIndex: c.int, mode: ^DisplayMode) -> c.int ---
	GetDesktopDisplayMode    :: proc(displayIndex: c.int, mode: ^DisplayMode) -> c.int ---
	GetCurrentDisplayMode    :: proc(displayIndex: c.int, mode: ^DisplayMode) -> c.int ---
	GetClosestDisplayMode    :: proc(displayIndex: c.int, mode, closest: ^DisplayMode) -> ^DisplayMode ---
	GetWindowDisplayIndex    :: proc(window: ^Window) -> c.int ---
	SetWindowDisplayMode     :: proc(window: ^Window, mode: ^DisplayMode) -> c.int ---
	GetWindowDisplayMode     :: proc(window: ^Window, mode: ^DisplayMode) -> c.int ---
	GetWindowPixelFormat     :: proc(window: ^Window) -> u32 ---
	CreateWindow             :: proc(title: cstring, x, y, w, h: c.int, flags: WindowFlags) -> ^Window ---
	CreateWindowFrom         :: proc(data: rawptr) -> ^Window ---
	GetWindowID              :: proc(window: ^Window) -> u32 ---
	GetWindowFromID          :: proc(id: u32) -> ^Window ---
	GetWindowFlags           :: proc(window: ^Window) -> u32 ---
	SetWindowTitle           :: proc(window: ^Window,  title: cstring) ---
	GetWindowTitle           :: proc(window: ^Window) -> cstring ---
	SetWindowIcon            :: proc(window: ^Window, icon: ^Surface) ---
	SetWindowData            :: proc(window: ^Window, name: cstring, userdata: rawptr) -> rawptr ---
	GetWindowData            :: proc(window: ^Window, name: cstring) -> rawptr ---
	SetWindowPosition        :: proc(window: ^Window, x, y: c.int) ---
	GetWindowPosition        :: proc(window: ^Window, x, y: ^c.int) ---
	SetWindowSize            :: proc(window: ^Window, w, h: c.int) ---
	GetWindowSize            :: proc(window: ^Window, w, h: ^c.int) ---
	GetWindowBordersSize     :: proc(window: ^Window, top, left, bottom, right: ^c.int) -> c.int ---
	SetWindowMinimumSize     :: proc(window: ^Window, min_w, min_h: c.int) ---
	GetWindowMinimumSize     :: proc(window: ^Window, w, h: ^c.int) ---
	SetWindowMaximumSize     :: proc(window: ^Window, max_w, max_h: c.int) ---
	GetWindowMaximumSize     :: proc(window: ^Window, w, h: ^c.int) ---
	SetWindowBordered        :: proc(window: ^Window, bordered:  bool) ---
	SetWindowResizable       :: proc(window: ^Window, resizable: bool) ---
	SetWindowAlwaysOnTop     :: proc(window: ^Window, on_top:    bool) ---
	ShowWindow               :: proc(window: ^Window) ---
	HideWindow               :: proc(window: ^Window) ---
	RaiseWindow              :: proc(window: ^Window) ---
	MaximizeWindow           :: proc(window: ^Window) ---
	MinimizeWindow           :: proc(window: ^Window) ---
	RestoreWindow            :: proc(window: ^Window) ---
	SetWindowFullscreen      :: proc(window: ^Window, flags: WindowFlags) -> c.int ---
	GetWindowSurface         :: proc(window: ^Window) -> ^Surface ---
	UpdateWindowSurface      :: proc(window: ^Window) -> c.int ---
	UpdateWindowSurfaceRects :: proc(window: ^Window, rects: [^]Rect, numrects: c.int) -> c.int ---
	SetWindowGrab            :: proc(window: ^Window, grabbed: bool) ---
	SetWindowKeyboardGrab    :: proc(window: ^Window, grabbed: bool) ---
	SetWindowMouseGrab       :: proc(window: ^Window, grabbed: bool) ---
	GetWindowGrab            :: proc(window: ^Window) -> bool ---
	GetWindowKeyboardGrab    :: proc(window: ^Window) -> bool ---
	GetWindowMouseGrab       :: proc(window: ^Window) -> bool ---
	GetGrabbedWindow         :: proc() -> ^Window ---
	SetWindowBrightness      :: proc(window: ^Window, brightness: f32) -> c.int ---
	GetWindowBrightness      :: proc(window: ^Window) -> f32 ---
	SetWindowOpacity         :: proc(window: ^Window, opacity: f32) -> c.int ---
	GetWindowOpacity         :: proc(window: ^Window, out_opacity: ^f32) -> c.int ---
	SetWindowModalFor        :: proc(modal_window, parent_window: ^Window) -> c.int ---
	SetWindowInputFocus      :: proc(window: ^Window) -> c.int ---
	SetWindowGammaRamp       :: proc(window: ^Window, red, green, blue: ^u16) -> c.int ---
	GetWindowGammaRamp       :: proc(window: ^Window, red, green, blue: ^u16) -> c.int ---
	SetWindowHitTest         :: proc(window: ^Window, callback: HitTest, callback_data: rawptr) -> c.int ---
	FlashWindow              :: proc(window: ^Window, operation: FlashOperation) -> c.int ---
	DestroyWindow            :: proc(window: ^Window) ---
	IsScreenSaverEnabled     :: proc() -> bool ---
	EnableScreenSaver        :: proc() ---
	DisableScreenSaver       :: proc() ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GL_LoadLibrary           :: proc(path: cstring) -> c.int ---
	GL_GetProcAddress        :: proc(procedure: cstring) -> rawptr ---
	GL_UnloadLibrary         :: proc() ---
	GL_ExtensionSupported    :: proc(extension: cstring) -> bool ---
	GL_ResetAttributes       :: proc() ---
	GL_SetAttribute          :: proc(attr: GLattr, value: c.int) -> c.int ---
	GL_GetAttribute          :: proc(attr: GLattr, value: ^c.int) -> c.int ---
	GL_CreateContext         :: proc(window: ^Window) -> GLContext ---
	GL_MakeCurrent           :: proc(window: ^Window, ctx: GLContext) -> c.int ---
	GL_GetCurrentWindow      :: proc() -> ^Window ---
	GL_GetCurrentContext     :: proc() -> GLContext ---
	GL_GetDrawableSize       :: proc(window: ^Window, w, h: ^c.int) ---
	GL_SetSwapInterval       :: proc(interval: c.int) -> c.int ---
	GL_GetSwapInterval       :: proc() -> c.int ---
	GL_SwapWindow            :: proc(window: ^Window) ---
	GL_DeleteContext         :: proc(ctx: GLContext) ---
}



// Used by vendor:OpenGL
gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = GL_GetProcAddress(name)
}
