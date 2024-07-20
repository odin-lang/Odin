//+build linux

package glfw

import "vendor:x11/xlib"

foreign import glfw "system:glfw"
@(link_prefix="glfw")
foreign glfw {
	GetX11Display :: proc() -> ^xlib.Display ---
	GetX11Window :: proc(window: ^Window) -> xlib.Window ---
	GetX11Adapter :: proc(monitor: ^Monitor) -> xlib.RRCrtc ---
	GetX11Monitor :: proc(monitor: ^Monitor) -> xlib.RROutput ---
	SetX11SelectionString :: proc(string: cstring) ---
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

// TODO: xrandr extension procedures
// RRCrtc glfwGetX11Adapter(GLFWmonitor* monitor);
// RROutput glfwGetX11Monitor(GLFWmonitor* monitor);

// TODO: implement native wayland procedures
// struct wl_display* glfwGetWaylandDisplay(void);
// struct wl_output* glfwGetWaylandMonitor(GLFWmonitor* monitor);
// struct wl_surface* glfwGetWaylandWindow(GLFWwindow* window);

