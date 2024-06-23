package wgpu_glfw_glue

import win "core:sys/windows"

import     "vendor:glfw"
import     "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: glfw.WindowHandle) -> wgpu.Surface {
	hwnd      := glfw.GetWin32Window(window)
	hinstance := win.GetModuleHandleW(nil)
	return wgpu.InstanceCreateSurface(
		instance,
		&wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceDescriptorFromWindowsHWND{
				chain = wgpu.ChainedStruct{
					sType = .SurfaceDescriptorFromWindowsHWND,
				},
				hinstance = rawptr(hinstance),
				hwnd = rawptr(hwnd),
			},
		},
	)
}
