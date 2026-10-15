#+build darwin:default

package glfw

import NS "vendor:darwin/AppKit"

@(default_calling_convention="c", link_prefix="glfw")
foreign {
	GetCocoaWindow :: proc(window: WindowHandle) -> ^NS.Window ---
	GetCocoaView   :: proc(window: WindowHandle) -> ^NS.View   ---
}

// TODO:
// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
// id glfwGetNSGLContext(GLFWwindow* window);
