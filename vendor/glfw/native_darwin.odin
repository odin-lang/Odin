//+build darwin

package glfw

import NS "vendor:darwin/foundation"

foreign import glfw { "lib/darwin/libglfw3.a" }

@(default_calling_convention="c", link_prefix="glfw")
foreign glfw {
    GetCocoaWindow :: proc(window: WindowHandle) -> ^NS.Window ---
}

// TODO:
// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
// id glfwGetNSGLContext(GLFWwindow* window);
