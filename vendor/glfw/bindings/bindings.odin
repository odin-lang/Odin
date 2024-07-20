package glfw_bindings

import "core:c"
import vk "vendor:vulkan"

GLFW_SHARED :: #config(GLFW_SHARED, false)

when ODIN_OS == .Windows {
	when GLFW_SHARED {
		foreign import glfw {
			"../lib/glfw3dll.lib",
			"system:user32.lib", 
			"system:gdi32.lib", 
			"system:shell32.lib",
		}
	} else {
		foreign import glfw {
			"../lib/glfw3_mt.lib",
			"system:user32.lib",
			"system:gdi32.lib",
			"system:shell32.lib",
		}
	}
} else when ODIN_OS == .Darwin {
	when GLFW_SHARED {
		foreign import glfw {
			"system:glfw",
			"system:Cocoa.framework",
			"system:IOKit.framework",
			"system:OpenGL.framework",
		}
	} else {
		foreign import glfw { 
			"../lib/darwin/libglfw3.a",
			"system:Cocoa.framework",
			"system:IOKit.framework",
			"system:OpenGL.framework",
		}
	}
} else {
	foreign import glfw "system:glfw"
}

#assert(size_of(c.int) == size_of(b32))

/*** Functions ***/
@(default_calling_convention="c", link_prefix="glfw")
foreign glfw {
	Init      :: proc() -> b32 ---
	Terminate :: proc() ---
	
	InitHint  :: proc(hint, value: c.int) ---

	InitAllocator :: proc(#by_ptr allocator: Allocator) ---

	InitVulkanLoader :: proc(loader: vk.ProcGetInstanceProcAddr) ---

	GetVersion :: proc(major, minor, rev: ^c.int) ---
	GetError   :: proc(description: ^cstring) -> c.int ---

	GetPrimaryMonitor      :: proc() -> ^Monitor ---
	GetMonitors            :: proc(count: ^c.int) -> [^]^Monitor ---
	GetMonitorPos          :: proc(monitor: ^Monitor, xpos, ypos: ^c.int) ---
	GetMonitorPhysicalSize :: proc(monitor: ^Monitor, widthMM, heightMM: ^c.int) ---
	GetMonitorContentScale :: proc(monitor: ^Monitor, xscale, yscale: ^f32) ---

	SetMonitorUserPointer :: proc(monitor: ^Monitor, pointer: rawptr) ---
	GetMonitorUserPointer :: proc(monitor: ^Monitor) -> rawptr ---

	GetVideoMode :: proc(monitor: ^Monitor) -> ^VidMode ---
	SetGamma     :: proc(monitor: ^Monitor, gamma: f32) ---
	GetGammaRamp :: proc(monitor: ^Monitor) -> ^GammaRamp ---
	SetGammaRamp :: proc(monitor: ^Monitor, ramp: ^GammaRamp) ---

	CreateWindow  :: proc(width, height: c.int, title: cstring, monitor: ^Monitor, share: ^Window) -> ^Window ---
	DestroyWindow :: proc(window: ^Window) ---

	WindowHint         :: proc(hint, value: c.int) ---
	DefaultWindowHints :: proc() ---
	WindowHintString   :: proc(hint: c.int, value: cstring) ---
	WindowShouldClose  :: proc(window: ^Window) -> b32 ---

	SwapInterval :: proc(interval: c.int) ---
	SwapBuffers  :: proc(window: ^Window) ---

	SetWindowTitle       :: proc(window: ^Window, title: cstring) ---
	SetWindowIcon        :: proc(window: ^Window, count: c.int, images: [^]Image) ---
	SetWindowPos         :: proc(window: ^Window, xpos, ypos: c.int) ---
	SetWindowSizeLimits  :: proc(window: ^Window, minwidth, minheight, maxwidth, maxheight: c.int) ---
	SetWindowAspectRatio :: proc(window: ^Window, numer, denom: c.int) ---
	SetWindowSize        :: proc(window: ^Window, width, height: c.int) ---
	GetWindowPos         :: proc(window: ^Window, xpos, ypos: ^c.int) ---
	GetWindowSize        :: proc(window: ^Window, width, height: ^c.int) ---
	GetFramebufferSize   :: proc(window: ^Window, width, height: ^c.int) ---
	GetWindowFrameSize   :: proc(window: ^Window, left, top, right, bottom: ^c.int) ---

	GetWindowContentScale :: proc(window: ^Window, xscale, yscale: ^f32) ---
	GetWindowOpacity      :: proc(window: ^Window) -> f32 ---
	SetWindowOpacity      :: proc(window: ^Window, opacity: f32) ---

	GetVersionString     :: proc() -> cstring ---
	GetMonitorName       :: proc(monitor: ^Monitor) -> cstring ---
	GetClipboardString   :: proc(window: ^Window) -> cstring ---
	GetVideoModes        :: proc(monitor: ^Monitor, count: ^c.int) -> [^]VidMode ---
	GetKey               :: proc(window: ^Window, key: c.int) -> c.int ---
	GetKeyName           :: proc(key, scancode: c.int) -> cstring ---
	SetWindowShouldClose :: proc(window: ^Window, value: b32) ---
	GetWindowTitle       :: proc(window: ^Window) -> cstring ---
	JoystickPresent      :: proc(joy: c.int) -> b32 ---
	GetJoystickName      :: proc(joy: c.int) -> cstring ---
	GetKeyScancode       :: proc(key: c.int) -> c.int ---

	IconifyWindow  :: proc(window: ^Window) ---
	RestoreWindow  :: proc(window: ^Window) ---
	MaximizeWindow :: proc(window: ^Window) ---
	ShowWindow     :: proc(window: ^Window) ---
	HideWindow     :: proc(window: ^Window) ---
	FocusWindow    :: proc(window: ^Window) ---

	RequestWindowAttention :: proc(window: ^Window) ---

	GetWindowMonitor     :: proc(window: ^Window) -> ^Monitor ---
	SetWindowMonitor     :: proc(window: ^Window, monitor: ^Monitor, xpos, ypos, width, height, refresh_rate: c.int) ---
	GetWindowAttrib      :: proc(window: ^Window, attrib: c.int) -> c.int ---
	SetWindowUserPointer :: proc(window: ^Window, pointer: rawptr) ---
	GetWindowUserPointer :: proc(window: ^Window) -> rawptr ---

	SetWindowAttrib :: proc(window: ^Window, attrib, value: c.int) ---

	PollEvents        :: proc() ---
	WaitEvents        :: proc() ---
	WaitEventsTimeout :: proc(timeout: f64) ---
	PostEmptyEvent    :: proc() ---

	RawMouseMotionSupported :: proc() -> b32 ---
	GetInputMode :: proc(window: ^Window, mode: c.int) -> c.int ---
	SetInputMode :: proc(window: ^Window, mode, value: c.int) ---

	GetMouseButton :: proc(window: ^Window, button: c.int) -> c.int ---
	GetCursorPos   :: proc(window: ^Window, xpos, ypos: ^f64) ---
	SetCursorPos   :: proc(window: ^Window, xpos, ypos: f64) ---

	CreateCursor         :: proc(image: ^Image, xhot, yhot: c.int) -> ^Cursor ---
	DestroyCursor        :: proc(cursor: ^Cursor) ---
	SetCursor            :: proc(window: ^Window, cursor: ^Cursor) ---
	CreateStandardCursor :: proc(shape: c.int) -> ^Cursor ---

	GetJoystickAxes        :: proc(joy: c.int, count: ^c.int) -> [^]f32 ---
	GetJoystickButtons     :: proc(joy: c.int, count: ^c.int) -> [^]u8 ---
	GetJoystickHats        :: proc(jid: c.int, count: ^c.int) -> [^]u8 ---
	GetJoystickGUID        :: proc(jid: c.int) -> cstring ---
	SetJoystickUserPointer :: proc(jid: c.int, pointer: rawptr) ---
	GetJoystickUserPointer :: proc(jid: c.int) -> rawptr ---
	JoystickIsGamepad      :: proc(jid: c.int) -> b32 ---
	UpdateGamepadMappings  :: proc(str: cstring) -> c.int ---
	GetGamepadName         :: proc(jid: c.int) -> cstring ---
	GetGamepadState        :: proc(jid: c.int, state: ^GamepadState) -> c.int ---

	SetClipboardString :: proc(window: ^Window, str: cstring) ---
	
	SetTime           :: proc(time: f64) ---
	GetTime           :: proc() -> f64 ---
	GetTimerValue     :: proc() -> u64 ---
	GetTimerFrequency :: proc() -> u64 ---

	MakeContextCurrent :: proc(window: ^Window) ---
	GetCurrentContext  :: proc() -> ^Window ---
	GetProcAddress     :: proc(name: cstring) -> rawptr ---
	ExtensionSupported :: proc(extension: cstring) -> c.int ---

	VulkanSupported                      :: proc() -> b32 ---
	GetRequiredInstanceExtensions        :: proc(count: ^u32) -> [^]cstring ---
	GetInstanceProcAddress               :: proc(instance: vk.Instance, procname: cstring) -> rawptr ---
	GetPhysicalDevicePresentationSupport :: proc(instance: vk.Instance, device: vk.PhysicalDevice, queuefamily: u32) -> c.int ---
	CreateWindowSurface                  :: proc(instance: vk.Instance, window: ^Window, allocator: ^vk.AllocationCallbacks, surface: ^vk.SurfaceKHR) -> vk.Result ---
	
	SetWindowIconifyCallback      :: proc(window: ^Window, cbfun: WindowIconifyProc)      -> WindowIconifyProc ---
	SetWindowRefreshCallback      :: proc(window: ^Window, cbfun: WindowRefreshProc)      -> WindowRefreshProc ---
	SetWindowFocusCallback        :: proc(window: ^Window, cbfun: WindowFocusProc)        -> WindowFocusProc ---
	SetWindowCloseCallback        :: proc(window: ^Window, cbfun: WindowCloseProc)        -> WindowCloseProc ---
	SetWindowSizeCallback         :: proc(window: ^Window, cbfun: WindowSizeProc)         -> WindowSizeProc ---
	SetWindowPosCallback          :: proc(window: ^Window, cbfun: WindowPosProc)          -> WindowPosProc ---
	SetFramebufferSizeCallback    :: proc(window: ^Window, cbfun: FramebufferSizeProc)    -> FramebufferSizeProc ---
	SetDropCallback               :: proc(window: ^Window, cbfun: DropProc)               -> DropProc ---
	SetMonitorCallback            :: proc(window: ^Window, cbfun: MonitorProc)            -> MonitorProc ---
	SetWindowMaximizeCallback     :: proc(window: ^Window, cbfun: WindowMaximizeProc)     -> WindowMaximizeProc ---
	SetWindowContentScaleCallback :: proc(window: ^Window, cbfun: WindowContentScaleProc) -> WindowContentScaleProc ---

	SetKeyCallback         :: proc(window: ^Window, cbfun: KeyProc)         -> KeyProc ---
	SetMouseButtonCallback :: proc(window: ^Window, cbfun: MouseButtonProc) -> MouseButtonProc ---
	SetCursorPosCallback   :: proc(window: ^Window, cbfun: CursorPosProc)   -> CursorPosProc ---
	SetScrollCallback      :: proc(window: ^Window, cbfun: ScrollProc)      -> ScrollProc ---
	SetCharCallback        :: proc(window: ^Window, cbfun: CharProc)        -> CharProc ---
	SetCharModsCallback    :: proc(window: ^Window, cbfun: CharModsProc)    -> CharModsProc ---
	SetCursorEnterCallback :: proc(window: ^Window, cbfun: CursorEnterProc) -> CursorEnterProc ---
	SetJoystickCallback    :: proc(cbfun: JoystickProc)    -> JoystickProc ---

	SetErrorCallback :: proc(cbfun: ErrorProc) -> ErrorProc ---

	// Functions added in 3.4, Linux links against system glfw so we define these as weak to be able
	// to check at runtime if they are available.

	@(linkage="weak")
	GetPlatform       :: proc() -> c.int ---
	@(linkage="weak")
	PlatformSupported :: proc(platform: c.int) -> b32 ---
}

