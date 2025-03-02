package wgpu_sdl3_glue

import win "core:sys/windows"

import "vendor:sdl3"
import "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl3.Window) -> wgpu.Surface {
	hwnd := sdl3.GetPointerProperty(
		sdl3.GetWindowProperties(window),
		sdl3.PROP_WINDOW_WIN32_HWND_POINTER,
		nil,
	)
	hinstance := sdl3.GetPointerProperty(
		sdl3.GetWindowProperties(window),
		sdl3.PROP_WINDOW_WIN32_INSTANCE_POINTER,
		nil,
	)
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor {
			nextInChain = &wgpu.SurfaceDescriptorFromWindowsHWND {
				chain = wgpu.ChainedStruct{sType = .SurfaceDescriptorFromWindowsHWND},
				hinstance = hinstance,
				hwnd = hwnd,
			},
		},
	)
}
