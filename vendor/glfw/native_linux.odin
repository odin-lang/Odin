//+build linux

package glfw

import "vendor:x11/xlib"

// TODO: Native Linux RandR
// RRCrtc glfwGetX11Adapter(GLFWmonitor* monitor);
// RROutput glfwGetX11Monitor(GLFWmonitor* monitor);


@(default_calling_convention = "c", link_prefix = "glfw")
foreign _ {
	GetX11Display :: proc() -> ^xlib.Display ---
	GetX11Window :: proc(window: WindowHandle) -> xlib.Window ---
	SetX11SelectionString :: proc(str: cstring) ---
	GetX11SelectionString :: proc() -> cstring ---

	GetWaylandDisplay :: proc() -> rawptr --- // ^wl_display
	GetWaylandMonitor :: proc(monitor: MonitorHandle) -> rawptr --- // ^wl_output
	GetWaylandWindow :: proc(window: WindowHandle) -> rawptr --- // ^wl_surface
}

