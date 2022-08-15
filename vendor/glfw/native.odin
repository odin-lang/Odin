package glfw

when ODIN_OS == .Windows {
	import win32 "core:sys/windows"
	
	foreign import glfw { "lib/glfw3_mt.lib", "system:user32.lib", "system:gdi32.lib", "system:shell32.lib" }
	
	@(default_calling_convention="c", link_prefix="glfw")
	foreign glfw {
		GetWin32Adapter :: proc(monitor: MonitorHandle) -> cstring ---
		GetWin32Monitor :: proc(monitor: MonitorHandle) -> cstring ---
		GetWin32Window  :: proc(window: WindowHandle) -> win32.HWND ---
		GetWGLContext   :: proc(window: WindowHandle) -> rawptr ---
	}
} else when ODIN_OS == .Linux {
	// TODO: Native Linux
	// Display* glfwGetX11Display(void);
	// RRCrtc glfwGetX11Adapter(GLFWmonitor* monitor);
	// RROutput glfwGetX11Monitor(GLFWmonitor* monitor);
	// Window glfwGetX11Window(GLFWwindow* window);
	// void glfwSetX11SelectionString(const char* string);
	// const char* glfwGetX11SelectionString(void);
	
	// struct wl_display* glfwGetWaylandDisplay(void);
	// struct wl_output* glfwGetWaylandMonitor(GLFWmonitor* monitor);
	// struct wl_surface* glfwGetWaylandWindow(GLFWwindow* window);
} else when ODIN_OS == .Darwin {
	// TODO: Native Darwin
	// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
	// id glfwGetCocoaWindow(GLFWwindow* window);
	// id glfwGetNSGLContext(GLFWwindow* window);
}

