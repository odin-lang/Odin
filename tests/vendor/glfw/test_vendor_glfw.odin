//+build darwin, windows
package test_vendor_glfw

import "core:testing"
import "vendor:glfw"

GLFW_MAJOR :: 3
GLFW_MINOR :: 4
GLFW_PATCH :: 0

@(test)
test_glfw :: proc(t: ^testing.T) {
	major, minor, patch := glfw.GetVersion()
	testing.expectf(
		t,
		major == GLFW_MAJOR && \
		minor == GLFW_MINOR,
		"Expected GLFW.GetVersion: %v.%v.%v, got %v.%v.%v instead",
		GLFW_MAJOR, GLFW_MINOR, GLFW_PATCH,
		major, minor, patch,
	)
}
