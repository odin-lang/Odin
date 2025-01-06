#+build darwin

package glfw

import NS "core:sys/darwin/Foundation"

@(default_calling_convention="c", link_prefix="glfw")
foreign {
	GetCocoaWindow :: proc(window: WindowHandle) -> ^NS.Window ---
	GetCocoaView   :: proc(window: WindowHandle) -> ^NS.View   ---
}

// TODO:
// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
// id glfwGetNSGLContext(GLFWwindow* window);
