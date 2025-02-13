package wgpu_sdl3_glue

import "vendor:sdl3"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	view := sdl3.Metal_CreateView(window)
	metal_layer := sdl3.Metal_GetLayer(view)
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor {
			nextInChain = &wgpu.SurfaceDescriptorFromMetalLayer {
				chain = wgpu.ChainedStruct{sType = .SurfaceDescriptorFromMetalLayer},
				layer = metal_layer,
			},
		},
	)
}
