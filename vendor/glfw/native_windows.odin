//+build windows

package glfw

import win32 "core:sys/windows"

foreign import glfw { "lib/glfw3_mt.lib", "system:user32.lib", "system:gdi32.lib", "system:shell32.lib" }

@(default_calling_convention="c", link_prefix="glfw")
foreign glfw {
    GetWin32Adapter :: proc(monitor: MonitorHandle) -> cstring ---
    GetWin32Monitor :: proc(monitor: MonitorHandle) -> cstring ---
    GetWin32Window  :: proc(window: WindowHandle) -> win32.HWND ---
    GetWGLContext   :: proc(window: WindowHandle) -> rawptr ---
}
