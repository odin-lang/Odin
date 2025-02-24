package wgpu_sdl2_glue

import "vendor:sdl2"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl2.Window) -> wgpu.Surface {
	window_info: sdl2.SysWMinfo 
	sdl2.VERSION(&window_info.version)
	sdl2.GetWindowWMInfo(window, &window_info)

	if window_info.subsystem == .WAYLAND {
		display := window_info.info.wl.display
		surface := window_info.info.wl.surface
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor{
				nextInChain = &wgpu.SurfaceSourceWaylandSurface{
					chain = {
						sType = .SurfaceSourceWaylandSurface,
					},
					display = display,
					surface = surface,
				},
			},
		)
	} else if window_info.subsystem == .X11 {
		display := window_info.info.x11.display
		window  := window_info.info.x11.window
		return wgpu.InstanceCreateSurface(
			instance,
			&wgpu.SurfaceDescriptor{
				nextInChain = &wgpu.SurfaceSourceXlibWindow{
					chain = {
						sType = .SurfaceSourceXlibWindow,
					},
					display = display,
					window  = u64(window),
				},
			},
		)
	} else {
		panic("wgpu sdl2 glue: unsupported platform, expected Wayland or X11")
	}
}
