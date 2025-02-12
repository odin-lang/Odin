package wgpu_sdl3_glue

import "vendor:sdl3"
import "vendor:wgpu"

@(private="file")
DRIVER_X11: cstring = "x11"
@(private="file")
DRIVER_WAYLAND: cstring = "wayland"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	if sdl3.strcmp(sdl3.GetCurrentVideoDriver(), DRIVER_WAYLAND) == 0 {
		display := sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_X11_DISPLAY_POINTER, nil)
		surface := sdl3.GetNumberProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_X11_WINDOW_NUMBER, 0)
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor{
				nextInChain = &wgpu.SurfaceDescriptorFromWaylandSurface{
					chain = {
						sType = .SurfaceDescriptorFromWaylandSurface,
					},
					display = display,
					surface = surface,
				},
			},
		)
	} else if sdl3.strcmp(sdl3.GetCurrentVideoDriver(), DRIVER_X11) == 0 {
		display := sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WAYLAND_DISPLAY_POINTER, nil)
		surface := sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WAYLAND_SURFACE_POINTER, 0)
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor{
				nextInChain = &wgpu.SurfaceDescriptorFromXlibWindow{
					chain = {
						sType = .SurfaceDescriptorFromXlibWindow,
					},
					display = display,
					window  = u64(window),
				},
			},
		)
	} else {
		panic("wgpu sdl3 glue: unsupported platform, expected Wayland or X11")
	}
}
