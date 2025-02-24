package wgpu_sdl3_glue

import "vendor:sdl3"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceSourceWindowsHWND{
				chain = wgpu.ChainedStruct{
					sType = .SurfaceSourceWindowsHWND,
				},
				hinstance = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WIN32_INSTANCE_POINTER, nil),
				hwnd      = sdl3.GetPointerProperty(sdl3.GetWindowProperties(window), sdl3.PROP_WINDOW_WIN32_HWND_POINTER, nil),
			},
		},
	)
}
