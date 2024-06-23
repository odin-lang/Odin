package wgpu_glfw_glue

import "vendor:glfw"
import "vendor:wgpu"

// GLFW needs to be compiled with wayland support for this to work.
SUPPORT_WAYLAND :: #config(WGPU_GFLW_GLUE_SUPPORT_WAYLAND, false)

GetSurface :: proc(instance: wgpu.Instance, window: glfw.WindowHandle) -> wgpu.Surface {
	when SUPPORT_WAYLAND {
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
