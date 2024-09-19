#+build !js
package vendor_wgpu_example_triangle

import "core:c"
import "core:fmt"

import "vendor:sdl2"
import "vendor:wgpu"
import "vendor:wgpu/sdl2glue"

OS :: struct {
	window: ^sdl2.Window,
}

os_init :: proc(os: ^OS) {
	sdl_flags := sdl2.InitFlags{.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}
	if res := sdl2.Init(sdl_flags); res != 0 {
		fmt.eprintfln("ERROR: Failed to initialize SDL: [%s]", sdl2.GetError())
		return
	}
	
	window_flags: sdl2.WindowFlags = {.SHOWN, .ALLOW_HIGHDPI, .RESIZABLE}
	os.window = sdl2.CreateWindow(
		"WGPU Native Triangle",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		960,
		540,
		window_flags,
	)
	if os.window == nil {
		fmt.eprintfln("ERROR: Failed to create the SDL Window: [%s]", sdl2.GetError())
		return
	}

	sdl2.AddEventWatch(size_callback, nil)
}

os_run :: proc(os: ^OS) {
	now := sdl2.GetPerformanceCounter()
	last : u64
	dt: f32
	main_loop: for {
		last = now
		now = sdl2.GetPerformanceCounter()
		dt = f32((now - last) * 1000) / f32(sdl2.GetPerformanceFrequency())

		e: sdl2.Event

		for sdl2.PollEvent(&e) {
			#partial switch (e.type) {
			case .QUIT:
				break main_loop
			}
		}

		frame(dt)
	}

	sdl2.DestroyWindow(os.window)
	sdl2.Quit()

	finish()
}


os_get_render_bounds :: proc(os: ^OS) -> (width, height: u32) {
	iw, ih: c.int
	sdl2.GetWindowSize(os.window, &iw, &ih)
	return u32(iw), u32(ih)
}

os_get_surface :: proc(os: ^OS, instance: wgpu.Instance) -> wgpu.Surface {
	return sdl2glue.GetSurface(instance, os.window)
}

@(private="file")
size_callback :: proc "c" (userdata: rawptr, event: ^sdl2.Event) -> c.int {
	if event.type == .WINDOWEVENT {
		if event.window.event == .SIZE_CHANGED || event.window.event == .RESIZED {
			resize()
		}
	}
	return 0
}
