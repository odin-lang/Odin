import win32 "sys/windows.odin" when ODIN_OS == "windows";
import wgl "sys/wgl.odin" when ODIN_OS == "windows";
import "fmt.odin";
import "math.odin";
import "os.odin";
import gl "opengl.odin";

const TWO_HEARTS = '💕';

var win32_perf_count_freq = win32.get_query_performance_frequency();
proc time_now() -> f64 {
	assert(win32_perf_count_freq != 0);

	var counter: i64;
	win32.query_performance_counter(&counter);
	return f64(counter) / f64(win32_perf_count_freq);
}
proc win32_print_last_error() {
	var err_code = win32.get_last_error();
	if err_code != 0 {
		fmt.println("get_last_error: ", err_code);
	}
}

// Yuk!
proc to_c_string(s: string) -> []u8 {
	var c_str = make([]u8, len(s)+1);
	copy(c_str, []u8(s));
	c_str[len(s)] = 0;
	return c_str;
}


type Window struct {
	width, height:      int,
	wc:                 win32.WndClassExA,
	dc:                 win32.Hdc,
	hwnd:               win32.Hwnd,
	opengl_context, rc: wgl.Hglrc,
	c_title:            []u8,
}

proc make_window(title: string, msg, height: int, window_proc: win32.WndProc) -> (Window, bool) {
	using win32;

	var w: Window;
	w.width, w.height = msg, height;

	var class_name = "Win32-Odin-Window\x00";
	var c_class_name = &class_name[0];
	if title[len(title)-1] != 0 {
		w.c_title = to_c_string(title);
	} else {
		w.c_title = []u8(title);
	}

	var instance = get_module_handle_a(nil);

	w.wc = WndClassExA{
		size       = size_of(WndClassExA),
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
		var pfd = PixelFormatDescriptor{
			size         = size_of(PixelFormatDescriptor),
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

		var attribs = [8]i32{
			wgl.CONTEXT_MAJOR_VERSION_ARB, 2,
			wgl.CONTEXT_MINOR_VERSION_ARB, 1,
			wgl.CONTEXT_PROFILE_MASK_ARB, wgl.CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
			0, // NOTE(bill): tells the proc that this is the end of attribs
		};

		var wgl_str = "wglCreateContextAttribsARB\x00";
		var wglCreateContextAttribsARB = wgl.CreateContextAttribsARBType(wgl.get_proc_address(&wgl_str[0]));
		w.rc = wglCreateContextAttribsARB(w.dc, nil, &attribs[0]);
		wgl.make_current(w.dc, w.rc);
		swap_buffers(w.dc);
	}

	return w, true;
}

proc destroy_window(w: ^Window) {
	free(w.c_title);
}

proc display_window(w: ^Window) {
	win32.swap_buffers(w.dc);
}


proc run() {
	using math;

	proc win32_proc(hwnd: win32.Hwnd, msg: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult #no_inline {
		using win32;
		if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
			os.exit(0);
			return 0;
		}
		return def_window_proc_a(hwnd, msg, wparam, lparam);
	}

	var window, window_success = make_window("Odin Language Demo", 854, 480, win32.WndProc(win32_proc));
	if !window_success {
		return;
	}
	defer destroy_window(&window);

	gl.init();

	using win32;

	var prev_time = time_now();
	var running = true;

	var pos = Vec2{100, 100};

	for running {
		var curr_time = time_now();
		var dt = f32(curr_time - prev_time);
		prev_time = curr_time;

		var msg: Msg;
		for peek_message_a(&msg, nil, 0, 0, PM_REMOVE) > 0 {
			if msg.message == WM_QUIT {
				running = false;
			}
			translate_message(&msg);
			dispatch_message_a(&msg);
		}

		if is_key_down(KeyCode.Escape) {
			running = false;
		}

		{
			const SPEED = 500;
			var v: Vec2;

			if is_key_down(KeyCode.Right) { v[0] += 1; }
			if is_key_down(KeyCode.Left)  { v[0] -= 1; }
			if is_key_down(KeyCode.Up)    { v[1] += 1; }
			if is_key_down(KeyCode.Down)  { v[1] -= 1; }

			v = norm(v);

			pos += v * Vec2{SPEED * dt};
		}


		gl.ClearColor(0.5, 0.7, 1.0, 1.0);
		gl.Clear(gl.COLOR_BUFFER_BIT);

		gl.LoadIdentity();
		gl.Ortho(0, f64(window.width),
		         0, f64(window.height), 0, 1);

		proc draw_rect(x, y, w, h: f32) {
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
		var ms_to_sleep = i32(16 - 1000*dt);
		if ms_to_sleep > 0 {
			win32.sleep(ms_to_sleep);
		}
	}
}


proc main() {
	run();
}
