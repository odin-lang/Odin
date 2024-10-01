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

	GetPrimaryMonitor      :: proc() -> MonitorHandle ---
	GetMonitors            :: proc(count: ^c.int) -> [^]MonitorHandle ---
	GetMonitorPos          :: proc(monitor: MonitorHandle, xpos, ypos: ^c.int) ---
	GetMonitorPhysicalSize :: proc(monitor: MonitorHandle, widthMM, heightMM: ^c.int) ---
	GetMonitorContentScale :: proc(monitor: MonitorHandle, xscale, yscale: ^f32) ---

	SetMonitorUserPointer :: proc(monitor: MonitorHandle, pointer: rawptr) ---
	GetMonitorUserPointer :: proc(monitor: MonitorHandle) -> rawptr ---

	GetVideoMode :: proc(monitor: MonitorHandle) -> ^VidMode ---
	SetGamma     :: proc(monitor: MonitorHandle, gamma: f32) ---
	GetGammaRamp :: proc(monitor: MonitorHandle) -> ^GammaRamp ---
	SetGammaRamp :: proc(monitor: MonitorHandle, ramp: ^GammaRamp) ---

	CreateWindow  :: proc(width, height: c.int, title: cstring, monitor: MonitorHandle, share: WindowHandle) -> WindowHandle ---
	DestroyWindow :: proc(window: WindowHandle) ---

	WindowHint         :: proc(hint, value: c.int) ---
	DefaultWindowHints :: proc() ---
	WindowHintString   :: proc(hint: c.int, value: cstring) ---
	WindowShouldClose  :: proc(window: WindowHandle) -> b32 ---

	SwapInterval :: proc(interval: c.int) ---
	SwapBuffers  :: proc(window: WindowHandle) ---

	SetWindowTitle       :: proc(window: WindowHandle, title: cstring) ---
	SetWindowIcon        :: proc(window: WindowHandle, count: c.int, images: [^]Image) ---
	SetWindowPos         :: proc(window: WindowHandle, xpos, ypos: c.int) ---
	SetWindowSizeLimits  :: proc(window: WindowHandle, minwidth, minheight, maxwidth, maxheight: c.int) ---
	SetWindowAspectRatio :: proc(window: WindowHandle, numer, denom: c.int) ---
	SetWindowSize        :: proc(window: WindowHandle, width, height: c.int) ---
	GetWindowPos         :: proc(window: WindowHandle, xpos, ypos: ^c.int) ---
	GetWindowSize        :: proc(window: WindowHandle, width, height: ^c.int) ---
	GetFramebufferSize   :: proc(window: WindowHandle, width, height: ^c.int) ---
	GetWindowFrameSize   :: proc(window: WindowHandle, left, top, right, bottom: ^c.int) ---

	GetWindowContentScale :: proc(window: WindowHandle, xscale, yscale: ^f32) ---
	GetWindowOpacity      :: proc(window: WindowHandle) -> f32 ---
	SetWindowOpacity      :: proc(window: WindowHandle, opacity: f32) ---

	GetVersionString     :: proc() -> cstring ---
	GetMonitorName       :: proc(monitor: MonitorHandle) -> cstring ---
	GetClipboardString   :: proc(window: WindowHandle) -> cstring ---
	GetVideoModes        :: proc(monitor: MonitorHandle, count: ^c.int) -> [^]VidMode ---
	GetKey               :: proc(window: WindowHandle, key: c.int) -> c.int ---
	GetKeyName           :: proc(key, scancode: c.int) -> cstring ---
	SetWindowShouldClose :: proc(window: WindowHandle, value: b32) ---
	GetWindowTitle       :: proc(window: WindowHandle) -> cstring ---
	JoystickPresent      :: proc(joy: c.int) -> b32 ---
	GetJoystickName      :: proc(joy: c.int) -> cstring ---
	GetKeyScancode       :: proc(key: c.int) -> c.int ---

	IconifyWindow  :: proc(window: WindowHandle) ---
	RestoreWindow  :: proc(window: WindowHandle) ---
	MaximizeWindow :: proc(window: WindowHandle) ---
	ShowWindow     :: proc(window: WindowHandle) ---
	HideWindow     :: proc(window: WindowHandle) ---
	FocusWindow    :: proc(window: WindowHandle) ---

	RequestWindowAttention :: proc(window: WindowHandle) ---

	GetWindowMonitor     :: proc(window: WindowHandle) -> MonitorHandle ---
	SetWindowMonitor     :: proc(window: WindowHandle, monitor: MonitorHandle, xpos, ypos, width, height, refresh_rate: c.int) ---
	GetWindowAttrib      :: proc(window: WindowHandle, attrib: c.int) -> c.int ---
	SetWindowUserPointer :: proc(window: WindowHandle, pointer: rawptr) ---
	GetWindowUserPointer :: proc(window: WindowHandle) -> rawptr ---

	SetWindowAttrib :: proc(window: WindowHandle, attrib, value: c.int) ---

	PollEvents        :: proc() ---
	WaitEvents        :: proc() ---
	WaitEventsTimeout :: proc(timeout: f64) ---
	PostEmptyEvent    :: proc() ---

	RawMouseMotionSupported :: proc() -> b32 ---
	GetInputMode :: proc(window: WindowHandle, mode: c.int) -> c.int ---
	SetInputMode :: proc(window: WindowHandle, mode, value: c.int) ---

	GetMouseButton :: proc(window: WindowHandle, button: c.int) -> c.int ---
	GetCursorPos   :: proc(window: WindowHandle, xpos, ypos: ^f64) ---
	SetCursorPos   :: proc(window: WindowHandle, xpos, ypos: f64) ---

	CreateCursor         :: proc(image: ^Image, xhot, yhot: c.int) -> CursorHandle ---
	DestroyCursor        :: proc(cursor: CursorHandle) ---
	SetCursor            :: proc(window: WindowHandle, cursor: CursorHandle) ---
	CreateStandardCursor :: proc(shape: c.int) -> CursorHandle ---

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

	SetClipboardString :: proc(window: WindowHandle, str: cstring) ---
	
	SetTime           :: proc(time: f64) ---
	GetTime           :: proc() -> f64 ---
	GetTimerValue     :: proc() -> u64 ---
	GetTimerFrequency :: proc() -> u64 ---

	MakeContextCurrent :: proc(window: WindowHandle) ---
	GetCurrentContext  :: proc() -> WindowHandle ---
	GetProcAddress     :: proc(name: cstring) -> rawptr ---
	ExtensionSupported :: proc(extension: cstring) -> c.int ---

	VulkanSupported                      :: proc() -> b32 ---
	GetRequiredInstanceExtensions        :: proc(count: ^u32) -> [^]cstring ---
	GetInstanceProcAddress               :: proc(instance: vk.Instance, procname: cstring) -> rawptr ---
	GetPhysicalDevicePresentationSupport :: proc(instance: vk.Instance, device: vk.PhysicalDevice, queuefamily: u32) -> c.int ---
	CreateWindowSurface                  :: proc(instance: vk.Instance, window: WindowHandle, allocator: ^vk.AllocationCallbacks, surface: ^vk.SurfaceKHR) -> vk.Result ---
	
	SetWindowIconifyCallback      :: proc(window: WindowHandle, cbfun: WindowIconifyProc)      -> WindowIconifyProc ---
	SetWindowRefreshCallback      :: proc(window: WindowHandle, cbfun: WindowRefreshProc)      -> WindowRefreshProc ---
	SetWindowFocusCallback        :: proc(window: WindowHandle, cbfun: WindowFocusProc)        -> WindowFocusProc ---
	SetWindowCloseCallback        :: proc(window: WindowHandle, cbfun: WindowCloseProc)        -> WindowCloseProc ---
	SetWindowSizeCallback         :: proc(window: WindowHandle, cbfun: WindowSizeProc)         -> WindowSizeProc ---
	SetWindowPosCallback          :: proc(window: WindowHandle, cbfun: WindowPosProc)          -> WindowPosProc ---
	SetFramebufferSizeCallback    :: proc(window: WindowHandle, cbfun: FramebufferSizeProc)    -> FramebufferSizeProc ---
	SetDropCallback               :: proc(window: WindowHandle, cbfun: DropProc)               -> DropProc ---
	SetMonitorCallback            :: proc(window: WindowHandle, cbfun: MonitorProc)            -> MonitorProc ---
	SetWindowMaximizeCallback     :: proc(window: WindowHandle, cbfun: WindowMaximizeProc)     -> WindowMaximizeProc ---
	SetWindowContentScaleCallback :: proc(window: WindowHandle, cbfun: WindowContentScaleProc) -> WindowContentScaleProc ---

	SetKeyCallback         :: proc(window: WindowHandle, cbfun: KeyProc)         -> KeyProc ---
	SetMouseButtonCallback :: proc(window: WindowHandle, cbfun: MouseButtonProc) -> MouseButtonProc ---
	SetCursorPosCallback   :: proc(window: WindowHandle, cbfun: CursorPosProc)   -> CursorPosProc ---
	SetScrollCallback      :: proc(window: WindowHandle, cbfun: ScrollProc)      -> ScrollProc ---
	SetCharCallback        :: proc(window: WindowHandle, cbfun: CharProc)        -> CharProc ---
	SetCharModsCallback    :: proc(window: WindowHandle, cbfun: CharModsProc)    -> CharModsProc ---
	SetCursorEnterCallback :: proc(window: WindowHandle, cbfun: CursorEnterProc) -> CursorEnterProc ---
	SetJoystickCallback    :: proc(cbfun: JoystickProc)    -> JoystickProc ---

	SetErrorCallback :: proc(cbfun: ErrorProc) -> ErrorProc ---

	// Functions added in 3.4, Linux links against system glfw so we define these as weak to be able
	// to check at runtime if they are available.

	@(linkage="weak")
	GetPlatform       :: proc() -> c.int ---
	@(linkage="weak")
	PlatformSupported :: proc(platform: c.int) -> b32 ---
}

