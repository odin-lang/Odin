package wgpu_sdl3_glue

import "vendor:sdl3"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	view  := sdl3.Metal_CreateView(window)
	layer := sdl3.Metal_GetLayer(view)

	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceSourceMetalLayer{
				chain = wgpu.ChainedStruct{
					sType = .SurfaceSourceMetalLayer,
				},
				layer = layer,
			},
		},
	)
}
