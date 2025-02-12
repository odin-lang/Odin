package sdl3

import "core:c"

DisplayID :: distinct Uint32
WindowID  :: distinct Uint32

PROP_GLOBAL_VIDEO_WAYLAND_WL_DISPLAY_POINTER :: "SDL.video.wayland.wl_display"

SystemTheme :: enum c.int {
	UNKNOWN,   /**< Unknown system theme */
	LIGHT,     /**< Light colored system theme */
	DARK,      /**< Dark colored system theme */
}

DisplayModeData :: struct {}

DisplayMode :: struct {
	displayID:                DisplayID,   /**< the display this mode is associated with */
	format:                   PixelFormat, /**< pixel format */
	w:                        c.int,       /**< width */
	h:                        c.int,       /**< height */
	pixel_density:            f32,         /**< scale converting size to pixels (e.g. a 1920x1080 mode with 2.0 scale would have 3840x2160 pixels) */
	refresh_rate:             f32,         /**< refresh rate (or 0.0f for unspecified) */
	refresh_rate_numerator:   c.int,       /**< precise refresh rate numerator (or 0 for unspecified) */
	refresh_rate_denominator: c.int,       /**< precise refresh rate denominator */

	internal: ^DisplayModeData,           /**< Private */
}

DisplayOrientation :: enum c.int {
	UNKNOWN,            /**< The display orientation can't be determined */
	LANDSCAPE,          /**< The display is in landscape mode, with the right side up, relative to portrait mode */
	LANDSCAPE_FLIPPED,  /**< The display is in landscape mode, with the left side up, relative to portrait mode */
	PORTRAIT,           /**< The display is in portrait mode */
	PORTRAIT_FLIPPED,   /**< The display is in portrait mode, upside down */
}

Window :: struct {}

WindowFlags :: distinct bit_set[WindowFlag; Uint64]
WindowFlag :: enum Uint64 {
	FULLSCREEN          = 0,
	OPENGL              = 1,
	OCCLUDED            = 2,
	HIDDEN              = 3,
	BORDERLESS          = 4,
	RESIZABLE           = 5,
	MINIMIZED           = 6,
	MAXIMIZED           = 7,
	MOUSE_GRABBED       = 8,
	INPUT_FOCUS         = 9,
	MOUSE_FOCUS         = 10,
	EXTERNAL            = 11,
	MODAL               = 12,
	HIGH_PIXEL_DENSITY  = 13,
	MOUSE_CAPTURE       = 14,
	MOUSE_RELATIVE_MODE = 15,
	ALWAYS_ON_TOP       = 16,
	UTILITY             = 17,
	TOOLTIP             = 18,
	POPUP_MENU          = 19,
	KEYBOARD_GRABBED    = 20,

	VULKAN              = 28,
	METAL               = 29,
	TRANSPARENT         = 30,
	NOT_FOCUSABLE       = 31,
}

WINDOW_FULLSCREEN          :: WindowFlags{.FULLSCREEN}          /**< window is in fullscreen mode */
WINDOW_OPENGL              :: WindowFlags{.OPENGL}              /**< window usable with OpenGL context */
WINDOW_OCCLUDED            :: WindowFlags{.OCCLUDED}            /**< window is occluded */
WINDOW_HIDDEN              :: WindowFlags{.HIDDEN}              /**< window is neither mapped onto the desktop nor shown in the taskbar/dock/window list; SDL_ShowWindow() is required for it to become visible */
WINDOW_BORDERLESS          :: WindowFlags{.BORDERLESS}          /**< no window decoration */
WINDOW_RESIZABLE           :: WindowFlags{.RESIZABLE}           /**< window can be resized */
WINDOW_MINIMIZED           :: WindowFlags{.MINIMIZED}           /**< window is minimized */
WINDOW_MAXIMIZED           :: WindowFlags{.MAXIMIZED}           /**< window is maximized */
WINDOW_MOUSE_GRABBED       :: WindowFlags{.MOUSE_GRABBED}       /**< window has grabbed mouse input */
WINDOW_INPUT_FOCUS         :: WindowFlags{.INPUT_FOCUS}         /**< window has input focus */
WINDOW_MOUSE_FOCUS         :: WindowFlags{.MOUSE_FOCUS}         /**< window has mouse focus */
WINDOW_EXTERNAL            :: WindowFlags{.EXTERNAL}            /**< window not created by SDL */
WINDOW_MODAL               :: WindowFlags{.MODAL}               /**< window is modal */
WINDOW_HIGH_PIXEL_DENSITY  :: WindowFlags{.HIGH_PIXEL_DENSITY}  /**< window uses high pixel density back buffer if possible */
WINDOW_MOUSE_CAPTURE       :: WindowFlags{.MOUSE_CAPTURE}       /**< window has mouse captured (unrelated to MOUSE_GRABBED) */
WINDOW_MOUSE_RELATIVE_MODE :: WindowFlags{.MOUSE_RELATIVE_MODE} /**< window has relative mode enabled */
WINDOW_ALWAYS_ON_TOP       :: WindowFlags{.ALWAYS_ON_TOP}       /**< window should always be above others */
WINDOW_UTILITY             :: WindowFlags{.UTILITY}             /**< window should be treated as a utility window, not showing in the task bar and window list */
WINDOW_TOOLTIP             :: WindowFlags{.TOOLTIP}             /**< window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window */
WINDOW_POPUP_MENU          :: WindowFlags{.POPUP_MENU}          /**< window should be treated as a popup menu, requires a parent window */
WINDOW_KEYBOARD_GRABBED    :: WindowFlags{.KEYBOARD_GRABBED}    /**< window has grabbed keyboard input */
WINDOW_VULKAN              :: WindowFlags{.VULKAN}              /**< window usable for Vulkan surface */
WINDOW_METAL               :: WindowFlags{.METAL}               /**< window usable for Metal view */
WINDOW_TRANSPARENT         :: WindowFlags{.TRANSPARENT}         /**< window with transparent buffer */
WINDOW_NOT_FOCUSABLE       :: WindowFlags{.NOT_FOCUSABLE}       /**< window should not be focusable */


WINDOWPOS_UNDEFINED_MASK :: 0x1FFF0000


@(require_results)
WINDOWPOS_UNDEFINED_DISPLAY :: proc "c" (X: c.int) -> c.int {
	return WINDOWPOS_UNDEFINED_MASK|(X)
}


WINDOWPOS_UNDEFINED :: WINDOWPOS_UNDEFINED_MASK|0

@(require_results)
WINDOWPOS_ISUNDEFINED :: proc "c" (X: c.int) -> bool {
	return (Uint32(X)&0xFFFF0000) == WINDOWPOS_UNDEFINED_MASK
}

WINDOWPOS_CENTERED_MASK :: 0x2FFF0000


@(require_results)
WINDOWPOS_CENTERED_DISPLAY :: proc "c" (X: c.int) -> c.int {
	return WINDOWPOS_CENTERED_MASK|(X)
}

WINDOWPOS_CENTERED :: WINDOWPOS_CENTERED_MASK|0

@(require_results)
WINDOWPOS_ISCENTERED :: proc "c" (X: c.int) -> bool {
	return (Uint32(X)&0xFFFF0000) == WINDOWPOS_CENTERED_MASK
}


FlashOperation :: enum c.int {
	CANCEL,                   /**< Cancel any window flash state */
	BRIEFLY,                  /**< Flash the window briefly to get attention */
	UNTIL_FOCUSED,            /**< Flash the window until it gets focus */
}

GLContextState :: struct {}
GLContext      :: ^GLContextState
EGLDisplay     :: distinct rawptr
EGLConfig      :: distinct rawptr
EGLSurface     :: distinct rawptr
EGLAttrib      :: distinct uintptr
EGLint         :: distinct c.int

EGLAttribArrayCallback :: #type proc "c" (userdata: rawptr) -> ^EGLint
EGLIntArrayCallback    :: #type proc "c" (userdata: rawptr, display: EGLDisplay, config: EGLConfig) -> [^]EGLint

GLAttr :: enum c.int {
	RED_SIZE,                    /**< the minimum number of bits for the red channel of the color buffer; defaults to 3. */
	GREEN_SIZE,                  /**< the minimum number of bits for the green channel of the color buffer; defaults to 3. */
	BLUE_SIZE,                   /**< the minimum number of bits for the blue channel of the color buffer; defaults to 2. */
	ALPHA_SIZE,                  /**< the minimum number of bits for the alpha channel of the color buffer; defaults to 0. */
	BUFFER_SIZE,                 /**< the minimum number of bits for frame buffer size; defaults to 0. */
	DOUBLEBUFFER,                /**< whether the output is single or double buffered; defaults to double buffering on. */
	DEPTH_SIZE,                  /**< the minimum number of bits in the depth buffer; defaults to 16. */
	STENCIL_SIZE,                /**< the minimum number of bits in the stencil buffer; defaults to 0. */
	ACCUM_RED_SIZE,              /**< the minimum number of bits for the red channel of the accumulation buffer; defaults to 0. */
	ACCUM_GREEN_SIZE,            /**< the minimum number of bits for the green channel of the accumulation buffer; defaults to 0. */
	ACCUM_BLUE_SIZE,             /**< the minimum number of bits for the blue channel of the accumulation buffer; defaults to 0. */
	ACCUM_ALPHA_SIZE,            /**< the minimum number of bits for the alpha channel of the accumulation buffer; defaults to 0. */
	STEREO,                      /**< whether the output is stereo 3D; defaults to off. */
	MULTISAMPLEBUFFERS,          /**< the number of buffers used for multisample anti-aliasing; defaults to 0. */
	MULTISAMPLESAMPLES,          /**< the number of samples used around the current pixel used for multisample anti-aliasing. */
	ACCELERATED_VISUAL,          /**< set to 1 to require hardware acceleration, set to 0 to force software rendering; defaults to allow either. */
	RETAINED_BACKING,            /**< not used (deprecated). */
	CONTEXT_MAJOR_VERSION,       /**< OpenGL context major version. */
	CONTEXT_MINOR_VERSION,       /**< OpenGL context minor version. */
	CONTEXT_FLAGS,               /**< some combination of 0 or more of elements of the SDL_GLContextFlag enumeration; defaults to 0. */
	CONTEXT_PROFILE_MASK,        /**< type of GL context (Core, Compatibility, ES). See SDL_GLProfile; default value depends on platform. */
	SHARE_WITH_CURRENT_CONTEXT,  /**< OpenGL context sharing; defaults to 0. */
	FRAMEBUFFER_SRGB_CAPABLE,    /**< requests sRGB capable visual; defaults to 0. */
	CONTEXT_RELEASE_BEHAVIOR,    /**< sets context the release behavior. See SDL_GLContextReleaseFlag; defaults to FLUSH. */
	CONTEXT_RESET_NOTIFICATION,  /**< set context reset notification. See SDL_GLContextResetNotification; defaults to NO_NOTIFICATION. */
	CONTEXT_NO_ERROR,
	FLOATBUFFERS,
	EGL_PLATFORM,
}
GL_RED_SIZE                   :: GLAttr.RED_SIZE
GL_GREEN_SIZE                 :: GLAttr.GREEN_SIZE
GL_BLUE_SIZE                  :: GLAttr.BLUE_SIZE
GL_ALPHA_SIZE                 :: GLAttr.ALPHA_SIZE
GL_BUFFER_SIZE                :: GLAttr.BUFFER_SIZE
GL_DOUBLEBUFFER               :: GLAttr.DOUBLEBUFFER
GL_DEPTH_SIZE                 :: GLAttr.DEPTH_SIZE
GL_STENCIL_SIZE               :: GLAttr.STENCIL_SIZE
GL_ACCUM_RED_SIZE             :: GLAttr.ACCUM_RED_SIZE
GL_ACCUM_GREEN_SIZE           :: GLAttr.ACCUM_GREEN_SIZE
GL_ACCUM_BLUE_SIZE            :: GLAttr.ACCUM_BLUE_SIZE
GL_ACCUM_ALPHA_SIZE           :: GLAttr.ACCUM_ALPHA_SIZE
GL_STEREO                     :: GLAttr.STEREO
GL_MULTISAMPLEBUFFERS         :: GLAttr.MULTISAMPLEBUFFERS
GL_MULTISAMPLESAMPLES         :: GLAttr.MULTISAMPLESAMPLES
GL_ACCELERATED_VISUAL         :: GLAttr.ACCELERATED_VISUAL
GL_RETAINED_BACKING           :: GLAttr.RETAINED_BACKING
GL_CONTEXT_MAJOR_VERSION      :: GLAttr.CONTEXT_MAJOR_VERSION
GL_CONTEXT_MINOR_VERSION      :: GLAttr.CONTEXT_MINOR_VERSION
GL_CONTEXT_FLAGS              :: GLAttr.CONTEXT_FLAGS
GL_CONTEXT_PROFILE_MASK       :: GLAttr.CONTEXT_PROFILE_MASK
GL_SHARE_WITH_CURRENT_CONTEXT :: GLAttr.SHARE_WITH_CURRENT_CONTEXT
GL_FRAMEBUFFER_SRGB_CAPABLE   :: GLAttr.FRAMEBUFFER_SRGB_CAPABLE
GL_CONTEXT_RELEASE_BEHAVIOR   :: GLAttr.CONTEXT_RELEASE_BEHAVIOR
GL_CONTEXT_RESET_NOTIFICATION :: GLAttr.CONTEXT_RESET_NOTIFICATION
GL_CONTEXT_NO_ERROR           :: GLAttr.CONTEXT_NO_ERROR
GL_FLOATBUFFERS               :: GLAttr.FLOATBUFFERS
GL_EGL_PLATFORM               :: GLAttr.EGL_PLATFORM


GLProfile :: distinct bit_set[GLProfileFlag; Uint32]
GLProfileFlag :: enum Uint32 {
	CORE          = 0, /**< OpenGL Core Profile context */
	COMPATIBILITY = 1, /**< OpenGL Compatibility Profile context */
	ES            = 2, /**< GLX_CONTEXT_ES2_PROFILE_BIT_EXT */
}
GL_CONTEXT_PROFILE_CORE          :: GLProfile{.CORE}          /**< OpenGL Core Profile context */
GL_CONTEXT_PROFILE_COMPATIBILITY :: GLProfile{.COMPATIBILITY} /**< OpenGL Compatibility Profile context */
GL_CONTEXT_PROFILE_ES            :: GLProfile{.ES}            /**< GLX_CONTEXT_ES2_PROFILE_BIT_EXT */


GLContextFlag :: distinct bit_set[GLContextFlagBit; Uint32]
GLContextFlagBit :: enum Uint32 {
	DEBUG              = 0,
	FORWARD_COMPATIBLE = 1,
	ROBUST_ACCESS      = 2,
	RESET_ISOLATION    = 3,
}
GL_CONTEXT_DEBUG_FLAG              :: GLContextFlag{.DEBUG}
GL_CONTEXT_FORWARD_COMPATIBLE_FLAG :: GLContextFlag{.FORWARD_COMPATIBLE}
GL_CONTEXT_ROBUST_ACCESS_FLAG      :: GLContextFlag{.ROBUST_ACCESS}
GL_CONTEXT_RESET_ISOLATION_FLAG    :: GLContextFlag{.RESET_ISOLATION}


GLContextReleaseFlag :: distinct bit_set[GLContextReleaseFlagBit; Uint32]
GLContextReleaseFlagBit :: enum Uint32 {
	BEHAVIOR_FLUSH = 0,
}
GL_CONTEXT_RELEASE_BEHAVIOR_NONE  :: GLContextReleaseFlag{}
GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH :: GLContextReleaseFlag{.BEHAVIOR_FLUSH}


GLContextResetNotification :: distinct bit_set[GLContextResetNotificationFlag; Uint32]
GLContextResetNotificationFlag :: enum Uint32 {
	LOSE_CONTEXT = 0,
}
GL_CONTEXT_RESET_NO_NOTIFICATION :: GLContextResetNotification{}
GL_CONTEXT_RESET_LOSE_CONTEXT    :: GLContextResetNotification{.LOSE_CONTEXT}


PROP_DISPLAY_HDR_ENABLED_BOOLEAN             :: "SDL.display.HDR_enabled"
PROP_DISPLAY_KMSDRM_PANEL_ORIENTATION_NUMBER :: "SDL.display.KMSDRM.panel_orientation"

PROP_WINDOW_CREATE_ALWAYS_ON_TOP_BOOLEAN               :: "SDL.window.create.always_on_top"
PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN                  :: "SDL.window.create.borderless"
PROP_WINDOW_CREATE_FOCUSABLE_BOOLEAN                   :: "SDL.window.create.focusable"
PROP_WINDOW_CREATE_EXTERNAL_GRAPHICS_CONTEXT_BOOLEAN   :: "SDL.window.create.external_graphics_context"
PROP_WINDOW_CREATE_FLAGS_NUMBER                        :: "SDL.window.create.flags"
PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN                  :: "SDL.window.create.fullscreen"
PROP_WINDOW_CREATE_HEIGHT_NUMBER                       :: "SDL.window.create.height"
PROP_WINDOW_CREATE_HIDDEN_BOOLEAN                      :: "SDL.window.create.hidden"
PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN          :: "SDL.window.create.high_pixel_density"
PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN                   :: "SDL.window.create.maximized"
PROP_WINDOW_CREATE_MENU_BOOLEAN                        :: "SDL.window.create.menu"
PROP_WINDOW_CREATE_METAL_BOOLEAN                       :: "SDL.window.create.metal"
PROP_WINDOW_CREATE_MINIMIZED_BOOLEAN                   :: "SDL.window.create.minimized"
PROP_WINDOW_CREATE_MODAL_BOOLEAN                       :: "SDL.window.create.modal"
PROP_WINDOW_CREATE_MOUSE_GRABBED_BOOLEAN               :: "SDL.window.create.mouse_grabbed"
PROP_WINDOW_CREATE_OPENGL_BOOLEAN                      :: "SDL.window.create.opengl"
PROP_WINDOW_CREATE_PARENT_POINTER                      :: "SDL.window.create.parent"
PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN                   :: "SDL.window.create.resizable"
PROP_WINDOW_CREATE_TITLE_STRING                        :: "SDL.window.create.title"
PROP_WINDOW_CREATE_TRANSPARENT_BOOLEAN                 :: "SDL.window.create.transparent"
PROP_WINDOW_CREATE_TOOLTIP_BOOLEAN                     :: "SDL.window.create.tooltip"
PROP_WINDOW_CREATE_UTILITY_BOOLEAN                     :: "SDL.window.create.utility"
PROP_WINDOW_CREATE_VULKAN_BOOLEAN                      :: "SDL.window.create.vulkan"
PROP_WINDOW_CREATE_WIDTH_NUMBER                        :: "SDL.window.create.width"
PROP_WINDOW_CREATE_X_NUMBER                            :: "SDL.window.create.x"
PROP_WINDOW_CREATE_Y_NUMBER                            :: "SDL.window.create.y"
PROP_WINDOW_CREATE_COCOA_WINDOW_POINTER                :: "SDL.window.create.cocoa.window"
PROP_WINDOW_CREATE_COCOA_VIEW_POINTER                  :: "SDL.window.create.cocoa.view"
PROP_WINDOW_CREATE_WAYLAND_SURFACE_ROLE_CUSTOM_BOOLEAN :: "SDL.window.create.wayland.surface_role_custom"
PROP_WINDOW_CREATE_WAYLAND_CREATE_EGL_WINDOW_BOOLEAN   :: "SDL.window.create.wayland.create_egl_window"
PROP_WINDOW_CREATE_WAYLAND_WL_SURFACE_POINTER          :: "SDL.window.create.wayland.wl_surface"
PROP_WINDOW_CREATE_WIN32_HWND_POINTER                  :: "SDL.window.create.win32.hwnd"
PROP_WINDOW_CREATE_WIN32_PIXEL_FORMAT_HWND_POINTER     :: "SDL.window.create.win32.pixel_format_hwnd"
PROP_WINDOW_CREATE_X11_WINDOW_NUMBER                   :: "SDL.window.create.x11.window"

PROP_WINDOW_SHAPE_POINTER                             :: "SDL.window.shape"
PROP_WINDOW_HDR_ENABLED_BOOLEAN                       :: "SDL.window.HDR_enabled"
PROP_WINDOW_SDR_WHITE_LEVEL_FLOAT                     :: "SDL.window.SDR_white_level"
PROP_WINDOW_HDR_HEADROOM_FLOAT                        :: "SDL.window.HDR_headroom"
PROP_WINDOW_ANDROID_WINDOW_POINTER                    :: "SDL.window.android.window"
PROP_WINDOW_ANDROID_SURFACE_POINTER                   :: "SDL.window.android.surface"
PROP_WINDOW_UIKIT_WINDOW_POINTER                      :: "SDL.window.uikit.window"
PROP_WINDOW_UIKIT_METAL_VIEW_TAG_NUMBER               :: "SDL.window.uikit.metal_view_tag"
PROP_WINDOW_UIKIT_OPENGL_FRAMEBUFFER_NUMBER           :: "SDL.window.uikit.opengl.framebuffer"
PROP_WINDOW_UIKIT_OPENGL_RENDERBUFFER_NUMBER          :: "SDL.window.uikit.opengl.renderbuffer"
PROP_WINDOW_UIKIT_OPENGL_RESOLVE_FRAMEBUFFER_NUMBER   :: "SDL.window.uikit.opengl.resolve_framebuffer"
PROP_WINDOW_KMSDRM_DEVICE_INDEX_NUMBER                :: "SDL.window.kmsdrm.dev_index"
PROP_WINDOW_KMSDRM_DRM_FD_NUMBER                      :: "SDL.window.kmsdrm.drm_fd"
PROP_WINDOW_KMSDRM_GBM_DEVICE_POINTER                 :: "SDL.window.kmsdrm.gbm_dev"
PROP_WINDOW_COCOA_WINDOW_POINTER                      :: "SDL.window.cocoa.window"
PROP_WINDOW_COCOA_METAL_VIEW_TAG_NUMBER               :: "SDL.window.cocoa.metal_view_tag"
PROP_WINDOW_OPENVR_OVERLAY_ID                         :: "SDL.window.openvr.overlay_id"
PROP_WINDOW_VIVANTE_DISPLAY_POINTER                   :: "SDL.window.vivante.display"
PROP_WINDOW_VIVANTE_WINDOW_POINTER                    :: "SDL.window.vivante.window"
PROP_WINDOW_VIVANTE_SURFACE_POINTER                   :: "SDL.window.vivante.surface"
PROP_WINDOW_WIN32_HWND_POINTER                        :: "SDL.window.win32.hwnd"
PROP_WINDOW_WIN32_HDC_POINTER                         :: "SDL.window.win32.hdc"
PROP_WINDOW_WIN32_INSTANCE_POINTER                    :: "SDL.window.win32.instance"
PROP_WINDOW_WAYLAND_DISPLAY_POINTER                   :: "SDL.window.wayland.display"
PROP_WINDOW_WAYLAND_SURFACE_POINTER                   :: "SDL.window.wayland.surface"
PROP_WINDOW_WAYLAND_VIEWPORT_POINTER                  :: "SDL.window.wayland.viewport"
PROP_WINDOW_WAYLAND_EGL_WINDOW_POINTER                :: "SDL.window.wayland.egl_window"
PROP_WINDOW_WAYLAND_XDG_SURFACE_POINTER               :: "SDL.window.wayland.xdg_surface"
PROP_WINDOW_WAYLAND_XDG_TOPLEVEL_POINTER              :: "SDL.window.wayland.xdg_toplevel"
PROP_WINDOW_WAYLAND_XDG_TOPLEVEL_EXPORT_HANDLE_STRING :: "SDL.window.wayland.xdg_toplevel_export_handle"
PROP_WINDOW_WAYLAND_XDG_POPUP_POINTER                 :: "SDL.window.wayland.xdg_popup"
PROP_WINDOW_WAYLAND_XDG_POSITIONER_POINTER            :: "SDL.window.wayland.xdg_positioner"
PROP_WINDOW_X11_DISPLAY_POINTER                       :: "SDL.window.x11.display"
PROP_WINDOW_X11_SCREEN_NUMBER                         :: "SDL.window.x11.screen"
PROP_WINDOW_X11_WINDOW_NUMBER                         :: "SDL.window.x11.window"

WINDOW_SURFACE_VSYNC_DISABLED :: 0
WINDOW_SURFACE_VSYNC_ADAPTIVE :: -1

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumVideoDrivers              :: proc() -> c.int ---
	GetVideoDriver                  :: proc(index: c.int) -> cstring ---
	GetCurrentVideoDriver           :: proc() -> cstring ---
	GetSystemTheme                  :: proc() -> SystemTheme ---
	GetDisplays                     :: proc(count: ^c.int) -> [^]DisplayID ---
	GetPrimaryDisplay               :: proc() -> DisplayID ---
	GetDisplayProperties            :: proc(displayID: DisplayID) -> PropertiesID ---
	GetDisplayName                  :: proc(displayID: DisplayID) -> cstring ---
	GetDisplayBounds                :: proc(displayID: DisplayID, rect: ^Rect) -> bool ---
	GetDisplayUsableBounds          :: proc(displayID: DisplayID, rect: ^Rect) -> bool ---
	GetNaturalDisplayOrientation    :: proc(displayID: DisplayID) -> DisplayOrientation ---
	GetCurrentDisplayOrientation    :: proc(displayID: DisplayID) -> DisplayOrientation ---
	GetDisplayContentScale          :: proc(displayID: DisplayID) -> f32 ---
	GetFullscreenDisplayModes       :: proc(displayID: DisplayID, count: c.int) -> [^]^DisplayMode ---
	GetClosestFullscreenDisplayMode :: proc(displayID: DisplayID, w, h: c.int, refresh_rate: f32, include_high_density_modes: bool, closest: ^DisplayMode) -> bool ---
	GetDesktopDisplayMode           :: proc(displayID: DisplayID) -> ^DisplayMode ---
	GetCurrentDisplayMode           :: proc(displayID: DisplayID) -> ^DisplayMode ---
	GetDisplayForPoint              :: proc(#by_ptr point: Point) -> DisplayID ---
	GetDisplayForRect               :: proc(#by_ptr rect: Rect) -> DisplayID ---
	GetDisplayForWindow             :: proc(window: ^Window) -> DisplayID ---
	GetWindowPixelDensity           :: proc(window: ^Window) -> f32 ---
	GetWindowDisplayScale           :: proc(window: ^Window) -> f32 ---
	SetWindowFullscreenMode         :: proc(window: ^Window, #by_ptr mode: DisplayMode) -> bool ---
	GetWindowFullscreenMode         :: proc(window: ^Window) -> ^DisplayMode ---
	GetWindowICCProfile             :: proc(window: ^Window, size: ^uint) -> rawptr ---
	GetWindowPixelFormat            :: proc(window: ^Window) -> PixelFormat ---
	GetWindows                      :: proc(count: ^c.int) -> [^]^Window ---
	CreateWindow                    :: proc(title: cstring, w, h: c.int, flags: WindowFlags) -> ^Window ---
	CreatePopupWindow               :: proc(parent: ^Window, offset_x, offset_y: c.int, w, h: c.int, flags: WindowFlags) -> ^Window ---
	CreateWindowWithProperties      :: proc(props: PropertiesID) -> ^Window ---
	GetWindowID                     :: proc(window: ^Window) -> WindowID ---
	GetWindowFromID                 :: proc(id: WindowID) -> ^Window ---
	GetWindowParent                 :: proc(window: ^Window) -> ^Window ---
	GetWindowProperties             :: proc(window: ^Window) -> PropertiesID ---
	GetWindowFlags                  :: proc(window: ^Window) -> WindowFlags ---
	SetWindowTitle                  :: proc(window: ^Window, title: cstring) -> bool ---
	GetWindowTitle                  :: proc(window: ^Window) -> cstring ---
	SetWindowIcon                   :: proc(window: ^Window, icon: ^Surface) -> bool ---
	SetWindowPosition               :: proc(window: ^Window, x, y: c.int) -> bool ---
	GetWindowPosition               :: proc(window: ^Window, x, y: ^c.int) -> bool ---
	SetWindowSize                   :: proc(window: ^Window, w, h: c.int) -> bool ---
	GetWindowSize                   :: proc(window: ^Window, w, h: ^c.int) -> bool ---
	GetWindowSafeArea               :: proc(window: ^Window, rect: ^Rect) -> bool ---
	SetWindowAspectRatio            :: proc(window: ^Window, min_aspect, max_aspect: f32) -> bool ---
	GetWindowAspectRatio            :: proc(window: ^Window, min_aspect, max_aspect: ^f32) -> bool ---
	GetWindowBordersSize            :: proc(window: ^Window, top, left, bottom, right: ^c.int) -> bool ---
	GetWindowSizeInPixels           :: proc(window: ^Window, w, h: ^c.int) -> bool ---
	SetWindowMinimumSize            :: proc(window: ^Window, min_w, min_h: c.int) -> bool ---
	GetWindowMinimumSize            :: proc(window: ^Window, w, h: ^c.int) -> bool ---
	SetWindowMaximumSize            :: proc(window: ^Window, max_w, max_h: c.int) -> bool ---
	GetWindowMaximumSize            :: proc(window: ^Window, w, h: ^c.int) -> bool ---
	SetWindowBordered               :: proc(window: ^Window, bordered: bool) -> bool ---
	SetWindowResizable              :: proc(window: ^Window, resizable: bool) -> bool ---
	SetWindowAlwaysOnTop            :: proc(window: ^Window, on_top: bool) -> bool ---
	ShowWindow                      :: proc(window: ^Window) -> bool ---
	HideWindow                      :: proc(window: ^Window) -> bool ---
	RaiseWindow                     :: proc(window: ^Window) -> bool ---
	MaximizeWindow                  :: proc(window: ^Window) -> bool ---
	MinimizeWindow                  :: proc(window: ^Window) -> bool ---
	RestoreWindow                   :: proc(window: ^Window) -> bool ---
	SetWindowFullscreen             :: proc(window: ^Window, fullscreen: bool) -> bool ---
	SyncWindow                      :: proc(window: ^Window) -> bool ---
	WindowHasSurface                :: proc(window: ^Window) -> bool ---
	GetWindowSurface                :: proc(window: ^Window) -> ^Surface ---
	SetWindowSurfaceVSync           :: proc(window: ^Window, vsync: c.int) -> bool ---
	GetWindowSurfaceVSync           :: proc(window: ^Window, vsync: ^c.int) -> bool ---
	UpdateWindowSurface             :: proc(window: ^Window) -> bool ---
	UpdateWindowSurfaceRects        :: proc(window: ^Window, rects: [^]Rect, numrects: c.int) -> bool ---
	DestroyWindowSurface            :: proc(window: ^Window) -> bool ---
	SetWindowKeyboardGrab           :: proc(window: ^Window, grabbed: bool) -> bool ---
	SetWindowMouseGrab              :: proc(window: ^Window, grabbed: bool) -> bool ---
	GetWindowKeyboardGrab           :: proc(window: ^Window) -> bool ---
	GetWindowMouseGrab              :: proc(window: ^Window) -> bool ---
	GetGrabbedWindow                :: proc() -> ^Window ---
	SetWindowMouseRect              :: proc(window: ^Window, #by_ptr rect: Rect) -> bool ---
	GetWindowMouseRect              :: proc(window: ^Window) -> ^Rect ---
	SetWindowOpacity                :: proc(window: ^Window, opacity: f32) -> bool ---
	GetWindowOpacity                :: proc(window: ^Window) -> f32 ---
	SetWindowParent                 :: proc(window: ^Window, parent: ^Window) -> bool ---
	SetWindowModal                  :: proc(window: ^Window, modal: bool) -> bool ---
	SetWindowFocusable              :: proc(window: ^Window, focusable: bool) -> bool ---
	ShowWindowSystemMenu            :: proc(window: ^Window, x, y: c.int) -> bool ---
}

HitTestResult :: enum c.int {
	NORMAL,             /**< Region is normal. No special properties. */
	DRAGGABLE,          /**< Region can drag entire window. */
	RESIZE_TOPLEFT,     /**< Region is the resizable top-left corner border. */
	RESIZE_TOP,         /**< Region is the resizable top border. */
	RESIZE_TOPRIGHT,    /**< Region is the resizable top-right corner border. */
	RESIZE_RIGHT,       /**< Region is the resizable right border. */
	RESIZE_BOTTOMRIGHT, /**< Region is the resizable bottom-right corner border. */
	RESIZE_BOTTOM,      /**< Region is the resizable bottom border. */
	RESIZE_BOTTOMLEFT,  /**< Region is the resizable bottom-left corner border. */
	RESIZE_LEFT,        /**< Region is the resizable left border. */
}

HitTest :: #type proc "c" (win: ^Window, area: ^Point, data: rawptr) -> HitTestResult

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetWindowHitTest                :: proc(window: ^Window, callback: HitTest, callback_data: rawptr) -> bool ---
	SetWindowShape                  :: proc(window: ^Window, shape: ^Surface) -> bool ---
	FlashWindow                     :: proc(window: ^Window, operation: FlashOperation) -> bool ---
	DestroyWindow                   :: proc(window: ^Window) ---
	ScreenSaverEnabled              :: proc() -> bool ---
	EnableScreenSaver               :: proc() -> bool ---
	DisableScreenSaver              :: proc() -> bool ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GL_LoadLibrary                  :: proc(path: cstring) -> bool ---
	GL_GetProcAddress               :: proc(procName: cstring) -> FunctionPointer ---
	EGL_GetProcAddress              :: proc(procName: cstring) -> FunctionPointer ---
	GL_UnloadLibrary                :: proc() ---
	GL_ExtensionSupported           :: proc(extension: cstring) -> bool ---
	GL_ResetAttributes              :: proc() ---
	GL_SetAttribute                 :: proc(attr: GLAttr, value: c.int) -> bool ---
	GL_GetAttribute                 :: proc(attr: GLAttr, value: ^c.int) -> bool ---
	GL_CreateContext                :: proc(window: ^Window) -> GLContext ---
	GL_MakeCurrent                  :: proc(window: ^Window, ctx: GLContext) -> bool ---
	GL_GetCurrentWindow             :: proc() -> ^Window ---
	GL_GetCurrentContext            :: proc() -> GLContext ---
	EGL_GetCurrentDisplay           :: proc() -> EGLDisplay ---
	EGL_GetCurrentConfig            :: proc() -> EGLConfig ---
	EGL_GetWindowSurface            :: proc(window: ^Window) -> EGLSurface ---
	EGL_SetAttributeCallbacks       :: proc(platformAttribCallback: EGLAttribArrayCallback, surfaceAttribCallback: EGLIntArrayCallback, contextAttribCallback: EGLIntArrayCallback, userdata: rawptr) ---
	GL_SetSwapInterval              :: proc(interval: c.int) -> bool ---
	GL_GetSwapInterval              :: proc(interval: ^c.int) -> bool ---
	GL_SwapWindow                   :: proc(window: ^Window) -> bool ---
	GL_DestroyContext               :: proc(ctx: GLContext) -> bool ---
}


// Used by vendor:OpenGL
gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^FunctionPointer)(p)^ = GL_GetProcAddress(name)
}