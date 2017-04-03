#import win32 "sys/windows.odin" when ODIN_OS == "windows";
#import wgl "sys/wgl.odin" when ODIN_OS == "windows";
#import "fmt.odin";
#import "math.odin";
#import "os.odin";
#import gl "opengl.odin";

TWO_HEARTS :: '💕';

win32_perf_count_freq := win32.GetQueryPerformanceFrequency();
time_now :: proc() -> f64 {
	assert(win32_perf_count_freq != 0);

	counter: i64;
	win32.QueryPerformanceCounter(^counter);
	result := cast(f64)counter / cast(f64)win32_perf_count_freq;
	return result;
}
win32_print_last_error :: proc() {
	err_code := cast(int)win32.GetLastError();
	if err_code != 0 {
		fmt.println("GetLastError: %", err_code);
	}
}

// Yuk!
to_c_string :: proc(s: string) -> []u8 {
	c_str := make([]u8, len(s)+1);
	copy(c_str, cast([]byte)s);
	c_str[len(s)] = 0;
	return c_str;
}


Window :: struct {
	width, height:      int,
	wc:                 win32.WndClassExA,
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
	c_class_name := ^class_name[0];
	if title[len(title)-1] != 0 {
		w.c_title = to_c_string(title);
	} else {
		w.c_title = cast([]u8)title;
	}

	instance := GetModuleHandleA(nil);

	w.wc = WndClassExA{
		size       = size_of(WndClassExA),
		style      = CS_VREDRAW | CS_HREDRAW,
		instance   = cast(Hinstance)instance,
		class_name = c_class_name,
		wnd_proc   = window_proc,
	};

	if RegisterClassExA(^w.wc) == 0 {
		win32_print_last_error();
		return w, false;
	}

	w.hwnd = CreateWindowExA(0,
	                         c_class_name, ^w.c_title[0],
	                         WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
	                         CW_USEDEFAULT, CW_USEDEFAULT,
	                         cast(i32)w.width, cast(i32)w.height,
	                         nil, nil, instance, nil);

	if w.hwnd == nil {
		win32_print_last_error();
		return w, false;
	}

	w.dc = GetDC(w.hwnd);

	{
		pfd := PIXELFORMATDESCRIPTOR{
			size         = size_of(PIXELFORMATDESCRIPTOR),
			version      = 1,
			flags        = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
			pixel_type   = PFD_TYPE_RGBA,
			color_bits   = 32,
			alpha_bits   = 8,
			depth_bits   = 24,
			stencil_bits = 8,
			layer_type   = PFD_MAIN_PLANE,
		};

		SetPixelFormat(w.dc, ChoosePixelFormat(w.dc, ^pfd), nil);
		w.opengl_context = wgl.CreateContext(w.dc);
		wgl.MakeCurrent(w.dc, w.opengl_context);

		attribs := [8]i32{
			wgl.CONTEXT_MAJOR_VERSION_ARB, 2,
			wgl.CONTEXT_MINOR_VERSION_ARB, 1,
			wgl.CONTEXT_PROFILE_MASK_ARB, wgl.CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
			0, // NOTE(bill): tells the proc that this is the end of attribs
		};

		wgl_str := "wglCreateContextAttribsARB\x00";
		wglCreateContextAttribsARB := cast(wgl.Create_Context_Attribs_ARB_Type)wgl.GetProcAddress(^wgl_str[0]);
		w.rc = wglCreateContextAttribsARB(w.dc, nil, ^attribs[0]);
		wgl.MakeCurrent(w.dc, w.rc);
		SwapBuffers(w.dc);
	}

	return w, true;
}

destroy_window :: proc(w: ^Window) {
	free(w.c_title);
}

display_window :: proc(w: ^Window) {
	win32.SwapBuffers(w.dc);
}


run :: proc() {
	using win32;
	using math;

	win32_proc :: proc(hwnd: win32.Hwnd, msg: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult #no_inline {
		if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
			os.exit(0);
			return 0;
		}
		return DefWindowProcA(hwnd, msg, wparam, lparam);
	}

	window, window_success := make_window("Odin Language Demo", 854, 480, cast(Wnd_Proc)win32_proc);
	if !window_success {
		return;
	}
	defer destroy_window(^window);

	gl.init();


	prev_time := time_now();
	running := true;

	pos := Vec2{100, 100};

	for running {
		curr_time := time_now();
		dt := cast(f32)(curr_time - prev_time);
		prev_time = curr_time;

		msg: Msg;
		for PeekMessageA(^msg, nil, 0, 0, PM_REMOVE) > 0 {
			if msg.message == WM_QUIT {
				running = false;
			}
			TranslateMessage(^msg);
			DispatchMessageA(^msg);
		}

		if is_key_down(Key_Code.ESCAPE) {
			running = false;
		}

		{
			SPEED :: 500;
			v: Vec2;

			if is_key_down(Key_Code.RIGHT) { v[0] += 1; }
			if is_key_down(Key_Code.LEFT)  { v[0] -= 1; }
			if is_key_down(Key_Code.UP)    { v[1] += 1; }
			if is_key_down(Key_Code.DOWN)  { v[1] -= 1; }

			v = norm(v);

			pos += v * Vec2{SPEED * dt};
		}


		gl.ClearColor(0.5, 0.7, 1.0, 1.0);
		gl.Clear(gl.COLOR_BUFFER_BIT);

		gl.LoadIdentity();
		gl.Ortho(0, cast(f64)window.width,
		         0, cast(f64)window.height, 0, 1);

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

		display_window(^window);
		ms_to_sleep := cast(i32)(16 - 1000*dt);
		if ms_to_sleep > 0 {
			win32.Sleep(ms_to_sleep);
		}
	}
}


main :: proc() {
	run();
}
