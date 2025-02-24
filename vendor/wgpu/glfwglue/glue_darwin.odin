package wgpu_glfw_glue

import    "vendor:glfw"
import    "vendor:wgpu"
import CA "vendor:darwin/QuartzCore"

GetSurface :: proc(instance: wgpu.Instance, window: glfw.WindowHandle) -> wgpu.Surface {
	ns_window := glfw.GetCocoaWindow(window)
	ns_window->contentView()->setWantsLayer(true)
	metal_layer := CA.MetalLayer_layer()
	ns_window->contentView()->setLayer(metal_layer)
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceSourceMetalLayer{
				chain = wgpu.ChainedStruct{
					sType = .SurfaceSourceMetalLayer,
				},
				layer = rawptr(metal_layer),
			},
		},
	)
}
