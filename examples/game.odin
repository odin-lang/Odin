when ODIN_OS == "windows" do import win32 "core:sys/windows.odin";
when ODIN_OS == "windows" import wgl "core:sys/wgl.odin";
import "core:fmt.odin";
import "core:math.odin";
import "core:os.odin";
import gl "core:opengl.odin";

TWO_HEARTS :: '💕';

win32_perf_count_freq := win32.get_query_performance_frequency();
time_now :: proc() -> f64 {
	assert(win32_perf_count_freq != 0);

	counter: i64;
	win32.query_performance_counter(&counter);
	return f64(counter) / f64(win32_perf_count_freq);
}
win32_print_last_error :: proc() {
	err_code := win32.get_last_error();
	if err_code != 0 {
		fmt.println("get_last_error: ", err_code);
	}
}

// Yuk!
to_c_string :: proc(s: string) -> []u8 {
	c_str := make([]u8, len(s)+1);
	copy(c_str, cast([]u8)s);
	c_str[len(s)] = 0;
	return c_str;
}


Window :: struct {
	width, height:      int,
	wc:                 win32.Wnd_Class_Ex_A,
	dc:                 win32.Hdc,
	hwnd:               win32.Hwnd,
	opengl_context, rc: wgl.Hglrc,
	c_title:            []u8,
}

make_window :: proc(title: string, msg, height: int, window_proc: win32.Wnd_Proc) -> (Window, bool) {
	using win32;

	w: Window;
	w.width, w.height = msg, height;

	class_name := "Win32-Odin-Window\x00";
	c_class_name := &class_name[0];
	if title[len(title)-1] != 0 {
		w.c_title = to_c_string(title);
	} else {
		w.c_title = cast([]u8)title;
	}

	instance := get_module_handle_a(nil);

	w.wc = Wnd_Class_Ex_A{
		size       = size_of(Wnd_Class_Ex_A),
		style      = CS_VREDRAW | CS_HREDRAW,
		instance   = Hinstance(instance),
		class_name = c_class_name,
		wnd_proc   = window_proc,
	};

	if register_class_ex_a(&w.wc) == 0 {
		win32_print_last_error();
		return w, false;
	}

	w.hwnd = create_window_ex_a(0,
	                            c_class_name, &w.c_title[0],
	                            WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
	                            CW_USEDEFAULT, CW_USEDEFAULT,
	                            i32(w.width), i32(w.height),
	                            nil, nil, instance, nil);

	if w.hwnd == nil {
		win32_print_last_error();
		return w, false;
	}

	w.dc = get_dc(w.hwnd);

	{
		pfd := Pixel_Format_Descriptor{
			size         = size_of(Pixel_Format_Descriptor),
			version      = 1,
			flags        = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
			pixel_type   = PFD_TYPE_RGBA,
			color_bits   = 32,
			alpha_bits   = 8,
			depth_bits   = 24,
			stencil_bits = 8,
			layer_type   = PFD_MAIN_PLANE,
		};

		set_pixel_format(w.dc, choose_pixel_format(w.dc, &pfd), nil);
		w.opengl_context = wgl.create_context(w.dc);
		wgl.make_current(w.dc, w.opengl_context);

		attribs := [8]i32{
			wgl.CONTEXT_MAJOR_VERSION_ARB, 2,
			wgl.CONTEXT_MINOR_VERSION_ARB, 1,
			wgl.CONTEXT_PROFILE_MASK_ARB, wgl.CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
			0, // NOTE(bill): tells the that :: proc this is the end of attribs
		};

		wgl_str := "wglCreateContextAttribsARB\x00";
		wglCreateContextAttribsARB := cast(wgl.Create_Context_Attribs_ARB_Type)wgl.get_proc_address(&wgl_str[0]);
		w.rc = wglCreateContextAttribsARB(w.dc, nil, &attribs[0]);
		wgl.make_current(w.dc, w.rc);
		swap_buffers(w.dc);
	}

	return w, true;
}

destroy_window :: proc(w: ^Window) {
	free(w.c_title);
}

display_window :: proc(w: ^Window) {
	win32.swap_buffers(w.dc);
}


run :: proc() {
	using math;

	win32_proc :: proc(hwnd: win32.Hwnd, msg: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult #no_inline {
		using win32;
		if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
			os.exit(0);
			return 0;
		}
		return def_window_proc_a(hwnd, msg, wparam, lparam);
	}

	window, window_success := make_window("Odin Language Demo", 854, 480, cast(win32.Wnd_Proc)win32_proc);
	if !window_success {
		return;
	}
	defer destroy_window(&window);

	gl.init();

	using win32;

	prev_time := time_now();
	running := true;

	pos := Vec2{100, 100};

	for running {
		curr_time := time_now();
		dt := f32(curr_time - prev_time);
		prev_time = curr_time;

		msg: Msg;
		for peek_message_a(&msg, nil, 0, 0, PM_REMOVE) > 0 {
			if msg.message == WM_QUIT {
				running = false;
			}
			translate_message(&msg);
			dispatch_message_a(&msg);
		}

		if is_key_down(Key_Code.Escape) {
			running = false;
		}

		{
			SPEED :: 500;
			v: Vec2;

			if is_key_down(Key_Code.Right) do v[0] += 1;
			if is_key_down(Key_Code.Left)  do v[0] -= 1;
			if is_key_down(Key_Code.Up)    do v[1] += 1;
			if is_key_down(Key_Code.Down)  do v[1] -= 1;

			v = norm(v);

			pos += v * Vec2{SPEED * dt};
		}


		gl.ClearColor(0.5, 0.7, 1.0, 1.0);
		gl.Clear(gl.COLOR_BUFFER_BIT);

		gl.LoadIdentity();
		gl.Ortho(0, f64(window.width),
		         0, f64(window.height), 0, 1);

		draw_rect :: proc(x, y, w, h: f32) {
			gl.Begin(gl.TRIANGLES);
			defer gl.End();

			gl.Color3f(1, 0, 0); gl.Vertex3f(x,   y,   0);
			gl.Color3f(0, 1, 0); gl.Vertex3f(x+w, y,   0);
			gl.Color3f(0, 0, 1); gl.Vertex3f(x+w, y+h, 0);

			gl.Color3f(0, 0, 1); gl.Vertex3f(x+w, y+h, 0);
			gl.Color3f(1, 1, 0); gl.Vertex3f(x,   y+h, 0);
			gl.Color3f(1, 0, 0); gl.Vertex3f(x,   y,   0);
		}

		draw_rect(pos.x, pos.y, 50, 50);

		display_window(&window);
		if ms_to_sleep := i32(16 - 1000*dt); ms_to_sleep > 0 {
			win32.sleep(ms_to_sleep);
		}
	}
}


main :: proc() {
	run();
}
