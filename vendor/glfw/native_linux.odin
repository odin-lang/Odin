//+build linux

package glfw

import "vendor:x11/xlib"

@(default_calling_convention="c", link_prefix="glfw")
foreign {
	GetX11Display :: proc() -> ^xlib.Display ---
	GetX11Window :: proc(window:  WindowHandle) -> xlib.Window ---
	GetX11Adapter :: proc(monitor: MonitorHandle) -> xlib.RRCrtc ---
	GetX11Monitor :: proc(monitor: MonitorHandle) -> xlib.RROutput ---
	SetX11SelectionString :: proc(string:  cstring) ---
	GetX11SelectionString :: proc() -> cstring ---

	// Functions added in 3.4, Linux links against system glfw so we define these as weak to be able
	// to check at runtime if they are available.

	@(linkage="weak")
	GetWaylandDisplay :: proc()                       -> rawptr /* struct wl_display* */ ---
	@(linkage="weak")
	GetWaylandWindow  :: proc(window:  WindowHandle)  -> rawptr /* struct wl_surface* */ ---
	@(linkage="weak")
	GetWaylandMonitor :: proc(monitor: MonitorHandle) -> rawptr /* struct wl_output*  */ ---
}
