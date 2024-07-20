//+build darwin

package glfw

import NS "core:sys/darwin/Foundation"

@(default_calling_convention="c", link_prefix="glfw"
foreign glfw {
	GetCocoaWindow :: proc(window: ^Window) -> ^NS.Window ---
	GetCocoaView   :: proc(window: ^Window) -> ^NS.View   ---
}

// TODO:
// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
// id glfwGetNSGLContext(GLFWwindow* window);
