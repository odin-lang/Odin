package vendor_wgpu_example_triangle

import "vendor:wgpu"
import "vendor:wasm/js"

OS :: struct {
	initialized: bool,
}

@(private="file")
g_os: ^OS

os_init :: proc(os: ^OS) {
	g_os = os
	assert(js.add_window_event_listener(.Resize, nil, size_callback))
}

// NOTE: frame loop is done by the runtime.js repeatedly calling `step`.
os_run :: proc(os: ^OS) {
	os.initialized = true
}

os_get_render_bounds :: proc(os: ^OS) -> (width, height: u32) {
	rect := js.get_bounding_client_rect("body")
	return u32(rect.width), u32(rect.height)
}

os_get_surface :: proc(os: ^OS, instance: wgpu.Instance) -> wgpu.Surface {
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceDescriptorFromCanvasHTMLSelector{
				sType = .SurfaceDescriptorFromCanvasHTMLSelector,
				selector = "#wgpu-canvas",
			},
		},
	)
}

@(private="file", export)
step :: proc(dt: f32) -> bool {
	if !g_os.initialized {
		return true
	}

	frame(dt)
	return true
}

@(private="file", fini)
os_fini :: proc() {
	js.remove_window_event_listener(.Resize, nil, size_callback)

	finish()
}

@(private="file")
size_callback :: proc(e: js.Event) {
	resize()
}
