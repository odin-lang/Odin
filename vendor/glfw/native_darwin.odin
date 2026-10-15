#+build darwin:default

package glfw

import AK "vendor:darwin/AppKit"

@(default_calling_convention="c", link_prefix="glfw")
foreign {
	GetCocoaWindow :: proc(window: WindowHandle) -> ^AK.Window ---
	GetCocoaView   :: proc(window: WindowHandle) -> ^AK.View   ---
}

// TODO:
// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
// id glfwGetNSGLContext(GLFWwindow* window);
