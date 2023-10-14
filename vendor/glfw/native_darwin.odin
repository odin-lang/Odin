//+build darwin

package glfw

import NS "vendor:darwin/foundation"

when GLFW_SHARED {
    #panic("Dynamic linking for glfw is not supported for darwin yet")
    foreign import glfw {"_"}
} else {
    foreign import glfw {
        "lib/darwin/libglfw3.a",
    }
}

@(default_calling_convention="c", link_prefix="glfw")
foreign glfw {
    GetCocoaWindow :: proc(window: WindowHandle) -> ^NS.Window ---
}

// TODO:
// CGDirectDisplayID glfwGetCocoaMonitor(GLFWmonitor* monitor);
// id glfwGetNSGLContext(GLFWwindow* window);
