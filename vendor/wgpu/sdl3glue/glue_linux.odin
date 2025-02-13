package wgpu_sdl3_glue

import "vendor:sdl3"
import "vendor:wgpu"


GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	switch sdl3.GetCurrentVideoDriver() {
	case "x11":
		display := sdl3.GetPointerProperty(
			sdl3.GetWindowProperties(window),
			sdl3.PROP_WINDOW_X11_DISPLAY_POINTER,
			nil,
		)
		x_window := sdl3.GetNumberProperty(
			sdl3.GetWindowProperties(window),
			sdl3.PROP_WINDOW_X11_WINDOW_NUMBER,
			0,
		)
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor {
				nextInChain = &wgpu.SurfaceDescriptorFromXlibWindow {
					chain = {sType = .SurfaceDescriptorFromXlibWindow},
					display = display,
					window = u64(x_window),
				},
			},
		)
	case "wayland":
		display := sdl3.GetPointerProperty(
			sdl3.GetWindowProperties(window),
			sdl3.PROP_WINDOW_WAYLAND_DISPLAY_POINTER,
			nil,
		)
		w_surface := sdl3.GetPointerProperty(
			sdl3.GetWindowProperties(window),
			sdl3.PROP_WINDOW_WAYLAND_SURFACE_POINTER,
			nil,
		)
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor {
				nextInChain = &wgpu.SurfaceDescriptorFromWaylandSurface {
					chain = {sType = .SurfaceDescriptorFromWaylandSurface},
					display = display,
					surface = w_surface,
				},
			},
		)
	case:
		panic("wgpu sdl3 glue: unsupported platform, expected Wayland or X11")
	}
}
