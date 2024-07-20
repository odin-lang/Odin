//+build windows

package glfw

import win32 "core:sys/windows"

@(default_calling_convention="c", link_prefix="glfw")
foreign glfw {
    GetWin32Adapter :: proc(monitor: ^Monitor) -> cstring ---
    GetWin32Monitor :: proc(monitor: ^Monitor) -> cstring ---
    GetWin32Window  :: proc(window: ^Window) -> win32.HWND ---
    GetWGLContext   :: proc(window: ^Window) -> rawptr ---
}
