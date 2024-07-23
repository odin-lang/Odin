package vendor_wgpu_example_triangle

import "base:runtime"

import "core:fmt"

import "vendor:sdl2"
import "vendor:wgpu"
import "vendor:wgpu/sdl2glue"

State :: struct {
	ctx: runtime.Context,
	window: ^sdl2.Window,

	instance:        wgpu.Instance,
	surface:         wgpu.Surface,
	adapter:         wgpu.Adapter,
	device:          wgpu.Device,
	config:          wgpu.SurfaceConfiguration,
	queue:           wgpu.Queue,
	module:          wgpu.ShaderModule,
	pipeline_layout: wgpu.PipelineLayout,
	pipeline:        wgpu.RenderPipeline,
}

@(private="file")
state: State

main :: proc() {
	state.ctx = context
	
	sdl_flags := sdl2.InitFlags{.VIDEO, .JOYSTICK, .GAMECONTROLLER, .EVENTS}
	if res := sdl2.Init(sdl_flags); res != 0 {
		fmt.eprintf("ERROR: Failed to initialize SDL: [%s]\n", sdl2.GetError())
		return
	}
	
	window_flags: sdl2.WindowFlags = {.SHOWN, .ALLOW_HIGHDPI, .RESIZABLE}
	state.window = sdl2.CreateWindow(
		"wgpu triangle",
		sdl2.WINDOWPOS_CENTERED,
		sdl2.WINDOWPOS_CENTERED,
		800,
		600,
		window_flags,
	)
	if state.window == nil {
		fmt.eprintf("ERROR: Failed to create the SDL Window: [%s]\n", sdl2.GetError())
		return
	}

	state.instance = wgpu.CreateInstance(nil)
	if state.instance == nil {
		panic("WebGPU is not supported")
	}
	
	state.surface = sdl2glue.GetSurface(state.instance, state.window)

	wgpu.InstanceRequestAdapter(state.instance, &{ compatibleSurface = state.surface }, on_adapter, nil)

	on_adapter :: proc "c" (status: wgpu.RequestAdapterStatus, adapter: wgpu.Adapter, message: cstring, userdata: rawptr) {
		context = state.ctx
		if status != .Success || adapter == nil {
			fmt.panicf("request adapter failure: [%v] %s", status, message)
		}
		state.adapter = adapter
		wgpu.AdapterRequestDevice(adapter, nil, on_device)
	}

	on_device :: proc "c" (status: wgpu.RequestDeviceStatus, device: wgpu.Device, message: cstring, userdata: rawptr) {
		context = state.ctx
		if status != .Success || device == nil {
			fmt.panicf("request device failure: [%v] %s", status, message)
		}
		state.device = device 

		width, height : u32 = 800, 600 // os_get_render_bounds(&state.os)

		state.config = wgpu.SurfaceConfiguration {
			device      = state.device,
			usage       = { .RenderAttachment },
			format      = .BGRA8Unorm,
			width       = width,
			height      = height,
			presentMode = .Fifo,
			alphaMode   = .Opaque,
		}
		wgpu.SurfaceConfigure(state.surface, &state.config)

		state.queue = wgpu.DeviceGetQueue(state.device)

		shader :: `
	@vertex
	fn vs_main(@builtin(vertex_index) in_vertex_index: u32) -> @builtin(position) vec4<f32> {
		let x = f32(i32(in_vertex_index) - 1);
		let y = f32(i32(in_vertex_index & 1u) * 2 - 1);
		return vec4<f32>(x, y, 0.0, 1.0);
	}

	@fragment
	fn fs_main() -> @location(0) vec4<f32> {
		return vec4<f32>(1.0, 0.0, 0.0, 1.0);
	}`

		state.module = wgpu.DeviceCreateShaderModule(state.device, &{
			nextInChain = &wgpu.ShaderModuleWGSLDescriptor{
				sType = .ShaderModuleWGSLDescriptor,
				code  = shader,
			},
		})

		state.pipeline_layout = wgpu.DeviceCreatePipelineLayout(state.device, &{})
		state.pipeline = wgpu.DeviceCreateRenderPipeline(state.device, &{
			layout = state.pipeline_layout,
			vertex = {
				module     = state.module,
				entryPoint = "vs_main",
			},
			fragment = &{
				module      = state.module,
				entryPoint  = "fs_main",
				targetCount = 1,
				targets     = &wgpu.ColorTargetState{
					format    = .BGRA8Unorm,
					writeMask = wgpu.ColorWriteMaskFlags_All,
				},
			},
			primitive = {
				topology = .TriangleList,

			},
			multisample = {
				count = 1,
				mask  = 0xFFFFFFFF,
			},
		})

		now := sdl2.GetPerformanceCounter()
		last : u64 = 0
		dt: f32 = 0
 		main_loop: for {
			last = now
			now := sdl2.GetPerformanceCounter()
			dt = auto_cast((now - last)*1000 / sdl2.GetPerformanceFrequency())

			e: sdl2.Event
	
			for sdl2.PollEvent(&e) {
				#partial switch (e.type) {
				case .QUIT:
					break main_loop
	
				case .WINDOWEVENT:
					#partial switch (e.window.event) {
					case .SIZE_CHANGED:
					case .RESIZED:
						state.config.width = cast(u32)e.window.data1
						state.config.height = cast(u32)e.window.data2
						wgpu.SurfaceConfigure(state.surface, &state.config)
					}
				}
			}

			frame(dt)
		}
	}
}

frame :: proc "c" (dt: f32) {
	context = state.ctx

	surface_texture := wgpu.SurfaceGetCurrentTexture(state.surface)
	switch surface_texture.status {
	case .Success:
		// All good, could check for `surface_texture.suboptimal` here.
	case .Timeout, .Outdated, .Lost:
		// Skip this frame, and re-configure surface.
		if surface_texture.texture != nil {
			wgpu.TextureRelease(surface_texture.texture)
		}
		// todo - resize()
		return
	case .OutOfMemory, .DeviceLost:
		// Fatal error
		fmt.panicf("[triangle] get_current_texture status=%v", surface_texture.status)
	}
	defer wgpu.TextureRelease(surface_texture.texture)

	frame := wgpu.TextureCreateView(surface_texture.texture, nil)
	defer wgpu.TextureViewRelease(frame)

	command_encoder := wgpu.DeviceCreateCommandEncoder(state.device, nil)
	defer wgpu.CommandEncoderRelease(command_encoder)

	render_pass_encoder := wgpu.CommandEncoderBeginRenderPass(
		command_encoder, &{
			colorAttachmentCount = 1,
			colorAttachments     = &wgpu.RenderPassColorAttachment{
				view       = frame,
				loadOp     = .Clear,
				storeOp    = .Store,
				clearValue = { r = 0, g = 1, b = 0, a = 1 },
			},
		},
	)
	defer wgpu.RenderPassEncoderRelease(render_pass_encoder)

	wgpu.RenderPassEncoderSetPipeline(render_pass_encoder, state.pipeline)
	wgpu.RenderPassEncoderDraw(render_pass_encoder, vertexCount=3, instanceCount=1, firstVertex=0, firstInstance=0)
	wgpu.RenderPassEncoderEnd(render_pass_encoder)

	command_buffer := wgpu.CommandEncoderFinish(command_encoder, nil)
	defer wgpu.CommandBufferRelease(command_buffer)

	wgpu.QueueSubmit(state.queue, { command_buffer })
	wgpu.SurfacePresent(state.surface)
}

finish :: proc() {
	wgpu.RenderPipelineRelease(state.pipeline)
	wgpu.PipelineLayoutRelease(state.pipeline_layout)
	wgpu.ShaderModuleRelease(state.module)
	wgpu.QueueRelease(state.queue)
	wgpu.DeviceRelease(state.device)
	wgpu.AdapterRelease(state.adapter)
	wgpu.SurfaceRelease(state.surface)
	wgpu.InstanceRelease(state.instance)
}
