#+build windows

package glfw

import win32 "core:sys/windows"

@(default_calling_convention="c", link_prefix="glfw")
foreign {
    GetWin32Adapter :: proc(monitor: MonitorHandle) -> cstring ---
    GetWin32Monitor :: proc(monitor: MonitorHandle) -> cstring ---
    GetWin32Window  :: proc(window: WindowHandle) -> win32.HWND ---
    GetWGLContext   :: proc(window: WindowHandle) -> rawptr ---
}
