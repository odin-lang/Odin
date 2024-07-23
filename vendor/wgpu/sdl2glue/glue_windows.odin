package wgpu_sdl2_glue

import win "core:sys/windows"

import     "vendor:sdl2"
import     "vendor:wgpu"

GetSurface :: proc(instance: wgpu.Instance, window: ^sdl2.Window) -> wgpu.Surface {
    window_info: sdl2.SysWMinfo 
    sdl2.GetWindowWMInfo(window, &window_info)
    hwnd := cast(win.HWND)window_info.info.win.window
    hinstance := win.GetModuleHandleW(nil)
    return wgpu.InstanceCreateSurface(
        instance,
        &wgpu.SurfaceDescriptor{
			nextInChain = &wgpu.SurfaceDescriptorFromMetalLayer{
				chain = wgpu.ChainedStruct{
					sType = .SurfaceDescriptorFromMetalLayer,
				},
				hinstance = rawptr(hinstance),
				hwnd = rawptr(hwnd),
			},
		},
    )
}