package wgpu_sdl3_glue

import "vendor:sdl3"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	switch sdl3.GetCurrentVideoDriver() {
	case "wayland":
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor{
				nextInChain = &wgpu.SurfaceSourceWaylandSurface{
					chain = {
						sType = .SurfaceSourceWaylandSurface,
					},
					display = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WAYLAND_DISPLAY_POINTER, nil),
					surface = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WAYLAND_SURFACE_POINTER, nil),
				},
			},
		)
	case "x11":
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor{
				nextInChain = &wgpu.SurfaceSourceXlibWindow{
					chain = {
						sType = .SurfaceSourceXlibWindow,
					},
					display = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_X11_DISPLAY_POINTER, nil),
					window  = cast(u64)sdl3.GetNumberProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_X11_WINDOW_NUMBER, 0),
				},
			},
		)
	case:
		panic("wgpu sdl3 glue: unsupported video driver, expected Wayland or X11")
	}
}
