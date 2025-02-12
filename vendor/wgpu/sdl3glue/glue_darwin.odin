package wgpu_sdl3_glue

import    "vendor:sdl3"
import    "vendor:wgpu"
import CA "vendor:darwin/QuartzCore"
import NS "core:sys/darwin/Foundation"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	ns_window := cast(^NS.Window)sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_COCOA_WINDOW_POINTER, nil)
	metal_layer := CA.MetalLayer_layer()
	ns_window->contentView()->setLayer(metal_layer)
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceDescriptorFromMetalLayer{
				chain = wgpu.ChainedStruct{
					sType = .SurfaceDescriptorFromMetalLayer,
				},
				layer = rawptr(metal_layer),
			},
		},
	)
}
