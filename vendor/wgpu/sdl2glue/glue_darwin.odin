package wgpu_sdl2_glue

import    "vendor:sdl2"
import    "vendor:wgpu"
import CA "vendor:darwin/QuartzCore"
import NS "core:sys/darwin/Foundation"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl2.Window) -> wgpu.Surface {
	window_info: sdl2.SysWMinfo 
	sdl2.GetWindowWMInfo(window, &window_info)
	ns_window := cast(^NS.Window)window_info.info.cocoa.window
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
