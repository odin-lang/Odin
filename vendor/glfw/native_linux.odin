//+build linux

package glfw

import "vendor:x11/xlib"

foreign import glfw "system:glfw"
@(link_prefix="glfw")
foreign glfw {
	GetX11Display :: proc() -> ^xlib.Display ---
	GetX11Window :: proc(window: ^Window) -> xlib.Window ---
	SetX11SelectionString :: proc(string: cstring) ---
	GetX11SelectionString :: proc() -> cstring ---
}

// TODO: xrandr extension procedures
// RRCrtc glfwGetX11Adapter(GLFWmonitor* monitor);
// RROutput glfwGetX11Monitor(GLFWmonitor* monitor);

// TODO: implement native wayland procedures
// struct wl_display* glfwGetWaylandDisplay(void);
// struct wl_output* glfwGetWaylandMonitor(GLFWmonitor* monitor);
// struct wl_surface* glfwGetWaylandWindow(GLFWwindow* window);
