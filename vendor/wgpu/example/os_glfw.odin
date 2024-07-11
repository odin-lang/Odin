//+build !js
package vendor_wgpu_example_triangle

import "core:time"

import "vendor:glfw"
import "vendor:wgpu"
import "vendor:wgpu/glfwglue"

OS :: struct {
	window: glfw.WindowHandle,
}

os_init :: proc(os: ^OS) {
	if !glfw.Init() {
		panic("[glfw] init failure")
	}

	glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
	os.window = glfw.CreateWindow(960, 540, "WGPU Native Triangle", nil, nil)

	glfw.SetFramebufferSizeCallback(os.window, size_callback)
}

os_run :: proc(os: ^OS) {
    dt: f32

	for !glfw.WindowShouldClose(os.window) {
		start := time.tick_now()

		glfw.PollEvents()
		frame(dt)

		dt = f32(time.duration_seconds(time.tick_since(start)))
	}

	finish()

	glfw.DestroyWindow(os.window)
	glfw.Terminate()
}

os_get_render_bounds :: proc(os: ^OS) -> (width, height: u32) {
	iw, ih := glfw.GetWindowSize(os.window)
	return u32(iw), u32(ih)
}

os_get_surface :: proc(os: ^OS, instance: wgpu.Instance) -> wgpu.Surface {
	return glfwglue.GetSurface(instance, os.window)
}

@(private="file")
size_callback :: proc "c" (window: glfw.WindowHandle, width, height: i32) {
	resize()
}
