package wgpu_glfw_glue

import "vendor:glfw"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: glfw.WindowHandle) -> wgpu.Surface {
	if glfw.GetPlatform != nil {
		if glfw.GetPlatform() == glfw.PLATFORM_WAYLAND {
			display := glfw.GetWaylandDisplay()
			surface := glfw.GetWaylandWindow(window)
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
		}

		if glfw.GetPlatform() != glfw.PLATFORM_X11 {
			panic("wgpu glfw glue: unsupported platform, expected Wayland or X11")
		}
	}

	display := glfw.GetX11Display()
	window  := glfw.GetX11Window(window)
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
}
