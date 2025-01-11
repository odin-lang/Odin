package glfw

import "core:c"
import glfw "bindings"

Init      :: glfw.Init
Terminate :: glfw.Terminate

InitHint  :: glfw.InitHint

InitAllocator :: glfw.InitAllocator

InitVulkanLoader :: glfw.InitVulkanLoader

GetVersion :: proc "c" () -> (major, minor, rev: c.int) {
	glfw.GetVersion(&major, &minor, &rev)
	return
}
GetError :: proc "c" () -> (description: string, code: c.int) {
	desc: cstring
	code = glfw.GetError(&desc)
	description = string(desc)
	return
}

GetPrimaryMonitor :: glfw.GetPrimaryMonitor
GetMonitors :: proc "c" () -> []MonitorHandle {
	count: c.int
	monitors := glfw.GetMonitors(&count)
	return monitors[:count]
}
GetMonitorPos :: proc "c" (monitor: MonitorHandle) -> (xpos, ypos: c.int) {
	glfw.GetMonitorPos(monitor, &xpos, &ypos)
	return
}
GetMonitorWorkarea :: proc "c" (monitor: MonitorHandle) -> (xpos, ypos, width, height: c.int) {
	glfw.GetMonitorWorkarea(monitor, &xpos, &ypos, &width, &height)
	return
}
GetMonitorPhysicalSize :: proc "c" (monitor: MonitorHandle) -> (widthMM, heightMM: c.int) {
	glfw.GetMonitorPhysicalSize(monitor, &widthMM, &heightMM)
	return
}
GetMonitorContentScale :: proc "c" (monitor: MonitorHandle) -> (xscale, yscale: f32) {
	glfw.GetMonitorContentScale(monitor, &xscale, &yscale)
	return
}

SetMonitorUserPointer :: glfw.SetMonitorUserPointer
GetMonitorUserPointer :: glfw.GetMonitorUserPointer

GetVideoMode :: glfw.GetVideoMode
SetGamma     :: glfw.SetGamma
GetGammaRamp :: glfw.GetGammaRamp
SetGammaRamp :: glfw.SetGammaRamp

CreateWindow  :: glfw.CreateWindow
DestroyWindow :: glfw.DestroyWindow

WindowHint_int :: proc "contextless" (hint: c.int, value: c.int) {
	glfw.WindowHint(hint, value)
}

WindowHint_bool :: proc "contextless" (hint: c.int, value: b32) {
	glfw.WindowHint(hint, cast(c.int) value)
}

WindowHint :: proc {
	WindowHint_int,
	WindowHint_bool,
}

DefaultWindowHints :: glfw.DefaultWindowHints
WindowHintString   :: glfw.WindowHintString
WindowShouldClose  :: glfw.WindowShouldClose

SwapInterval :: glfw.SwapInterval
SwapBuffers  :: glfw.SwapBuffers

SetWindowTitle :: glfw.SetWindowTitle
SetWindowIcon :: proc "c" (window: WindowHandle, images: []Image) {
	glfw.SetWindowIcon(window, c.int(len(images)), raw_data(images))
}
SetWindowPos         :: glfw.SetWindowPos
SetWindowSizeLimits  :: glfw.SetWindowSizeLimits
SetWindowAspectRatio :: glfw.SetWindowAspectRatio
SetWindowSize        :: glfw.SetWindowSize
GetWindowPos :: proc "c" (window: WindowHandle) -> (xpos, ypos: c.int) {
	glfw.GetWindowPos(window, &xpos, &ypos)
	return
}
GetWindowSize :: proc "c" (window: WindowHandle) -> (width, height: c.int) {
	glfw.GetWindowSize(window, &width, &height)
	return
}
GetFramebufferSize :: proc "c" (window: WindowHandle) -> (width, height: c.int) {
	glfw.GetFramebufferSize(window, &width, &height)
	return
}
GetWindowFrameSize :: proc "c" (window: WindowHandle) -> (left, top, right, bottom: c.int) {
	glfw.GetWindowFrameSize(window, &left, &top, &right, &bottom)
	return
}

GetWindowContentScale :: proc "c" (window: WindowHandle) -> (xscale, yscale: f32) {
	glfw.GetWindowContentScale(window, &xscale, &yscale)
	return
}
GetWindowOpacity :: glfw.GetWindowOpacity
SetWindowOpacity :: glfw.SetWindowOpacity

GetVersionString :: proc "c" () -> string {
	return string(glfw.GetVersionString())
}
GetMonitorName :: proc "c" (monitor: MonitorHandle) -> string {
	return string(glfw.GetMonitorName(monitor))
}
GetClipboardString :: proc "c" (window: WindowHandle) -> string {
	return string(glfw.GetClipboardString(window))
}
GetVideoModes :: proc "c" (monitor: MonitorHandle) -> []VidMode {
	count: c.int
	modes := glfw.GetVideoModes(monitor, &count)
	return modes[:count]
}

GetKey :: glfw.GetKey
GetKeyName :: proc "c" (key, scancode: c.int) -> string {
	return string(glfw.GetKeyName(key, scancode))
}
SetWindowShouldClose :: glfw.SetWindowShouldClose
GetWindowTitle       :: glfw.GetWindowTitle
JoystickPresent      :: glfw.JoystickPresent
GetJoystickName :: proc "c" (joy: c.int) -> string {
	return string(glfw.GetJoystickName(joy))
}
GetKeyScancode :: glfw.GetKeyScancode

IconifyWindow  :: glfw.IconifyWindow
RestoreWindow  :: glfw.RestoreWindow
MaximizeWindow :: glfw.MaximizeWindow
ShowWindow     :: glfw.ShowWindow
HideWindow     :: glfw.HideWindow
FocusWindow    :: glfw.FocusWindow

RequestWindowAttention :: glfw.RequestWindowAttention

GetWindowMonitor     :: glfw.GetWindowMonitor
SetWindowMonitor     :: glfw.SetWindowMonitor
GetWindowAttrib      :: glfw.GetWindowAttrib
SetWindowUserPointer :: glfw.SetWindowUserPointer
GetWindowUserPointer :: glfw.GetWindowUserPointer

SetWindowAttrib :: glfw.SetWindowAttrib

PollEvents        :: glfw.PollEvents
WaitEvents        :: glfw.WaitEvents
WaitEventsTimeout :: glfw.WaitEventsTimeout
PostEmptyEvent    :: glfw.PostEmptyEvent

RawMouseMotionSupported :: glfw.RawMouseMotionSupported
GetInputMode            :: glfw.GetInputMode
SetInputMode            :: glfw.SetInputMode

GetMouseButton :: glfw.GetMouseButton
GetCursorPos :: proc "c" (window: WindowHandle) -> (xpos, ypos: f64) {
	glfw.GetCursorPos(window, &xpos, &ypos)
	return
}
SetCursorPos :: glfw.SetCursorPos

CreateCursor         :: glfw.CreateCursor
DestroyCursor        :: glfw.DestroyCursor
SetCursor            :: glfw.SetCursor
CreateStandardCursor :: glfw.CreateStandardCursor

GetJoystickAxes :: proc "c" (joy: c.int) -> []f32 {
	count: c.int
	axes := glfw.GetJoystickAxes(joy, &count)
	return axes[:count]
}
GetJoystickButtons :: proc "c" (joy: c.int) -> []u8 {
	count: c.int
	buttons := glfw.GetJoystickButtons(joy, &count)
	return buttons[:count]
}
GetJoystickHats :: proc "c" (jid: c.int) -> []u8 {
	count: c.int
	hats := glfw.GetJoystickHats(jid, &count)
	return hats[:count]
}
GetJoystickGUID :: proc "c" (jid: c.int) -> string {
	return string(glfw.GetJoystickGUID(jid))
}
SetJoystickUserPointer :: glfw.SetJoystickUserPointer
GetJoystickUserPointer :: glfw.GetJoystickUserPointer
JoystickIsGamepad      :: glfw.JoystickIsGamepad
UpdateGamepadMappings  :: glfw.UpdateGamepadMappings
GetGamepadName :: proc "c" (jid: c.int) -> string {
	return string(glfw.GetGamepadName(jid))
}
GetGamepadState    :: glfw.GetGamepadState

SetClipboardString :: glfw.SetClipboardString

SetTime            :: glfw.SetTime
GetTime            :: glfw.GetTime
GetTimerValue      :: glfw.GetTimerValue
GetTimerFrequency  :: glfw.GetTimerFrequency

MakeContextCurrent :: glfw.MakeContextCurrent
GetCurrentContext  :: glfw.GetCurrentContext
GetProcAddress     :: glfw.GetProcAddress
ExtensionSupported :: glfw.ExtensionSupported

VulkanSupported :: glfw.VulkanSupported
GetRequiredInstanceExtensions :: proc "c" () -> []cstring {
	count: u32
	exts := glfw.GetRequiredInstanceExtensions(&count)
	return exts[:count]
}
GetInstanceProcAddress               :: glfw.GetInstanceProcAddress
GetPhysicalDevicePresentationSupport :: glfw.GetPhysicalDevicePresentationSupport
CreateWindowSurface                  :: glfw.CreateWindowSurface

SetWindowIconifyCallback      :: glfw.SetWindowIconifyCallback
SetWindowRefreshCallback      :: glfw.SetWindowRefreshCallback
SetWindowFocusCallback        :: glfw.SetWindowFocusCallback
SetWindowCloseCallback        :: glfw.SetWindowCloseCallback
SetWindowSizeCallback         :: glfw.SetWindowSizeCallback
SetWindowPosCallback          :: glfw.SetWindowPosCallback
SetFramebufferSizeCallback    :: glfw.SetFramebufferSizeCallback
SetDropCallback               :: glfw.SetDropCallback
SetMonitorCallback            :: glfw.SetMonitorCallback
SetWindowMaximizeCallback     :: glfw.SetWindowMaximizeCallback
SetWindowContentScaleCallback :: glfw.SetWindowContentScaleCallback

SetKeyCallback         :: glfw.SetKeyCallback
SetMouseButtonCallback :: glfw.SetMouseButtonCallback
SetCursorPosCallback   :: glfw.SetCursorPosCallback
SetScrollCallback      :: glfw.SetScrollCallback
SetCharCallback        :: glfw.SetCharCallback
SetCharModsCallback    :: glfw.SetCharModsCallback
SetCursorEnterCallback :: glfw.SetCursorEnterCallback
SetJoystickCallback    :: glfw.SetJoystickCallback

SetErrorCallback :: glfw.SetErrorCallback

GetPlatform       :: glfw.GetPlatform
PlatformSupported :: glfw.PlatformSupported

// Used by vendor:OpenGL
gl_set_proc_address :: proc(p: rawptr, name: cstring) {
	(^rawptr)(p)^ = GetProcAddress(name)
}
