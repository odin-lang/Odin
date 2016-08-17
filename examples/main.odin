#load "basic.odin"
#load "win32.odin"
#load "opengl.odin"
#load "stb_image.odin"

win32_perf_count_freq := GetQueryPerformanceFrequency();
time_now :: proc() -> f64 {
	if win32_perf_count_freq == 0 {
		debug_trap();
	}

	counter: i64;
	_ = QueryPerformanceCounter(^counter);
	result := counter as f64 / win32_perf_count_freq as f64;
	return result;
}
win32_print_last_error :: proc() {
	err_code := GetLastError() as int;
	if err_code != 0 {
		print_string("GetLastError: ");
		print_int(err_code);
		print_string("\n");
	}
}

// Yuk!
to_c_string :: proc(s: string) -> ^u8 {
	c_str := heap_alloc(len(s)+1) as ^u8;
	mem_copy(c_str, ^s[0], len(s));
	c_str[len(s)] = 0;
	return c_str;
}


type Window: struct {
	width, height: int,
	wc: WNDCLASSEXA,
	dc: HDC,
	hwnd: HWND,
	opengl_context: HGLRC,
	rc: HGLRC,
	c_title: ^u8,
}

win32_proc :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #no_inline {
	if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
		ExitProcess(0);
		return 0;
	}
	return DefWindowProcA(hwnd, msg, wparam, lparam);
}

make_window :: proc(title: string, msg, height: int) -> (Window, bool) {
	w: Window;
	w.width, w.height = msg, height;

	class_name   := "Win32-Odin-Window\x00";
	c_class_name := ^class_name[0];
	w.c_title = to_c_string(title);

	instance := GetModuleHandleA(null);

	w.wc = WNDCLASSEXA{
		cbSize    = size_of(WNDCLASSEXA) as u32,
		style     = CS_VREDRAW | CS_HREDRAW,
		hInstance = instance as HINSTANCE,
		className = c_class_name,
		wndProc   = win32_proc,
	};

	if RegisterClassExA(^w.wc) == 0 {
		return w, false;
	}

	w.hwnd = CreateWindowExA(0,
	                         c_class_name, w.c_title,
	                         WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
	                         CW_USEDEFAULT, CW_USEDEFAULT,
	                         w.width as i32, w.height as i32,
	                         null, null, instance, null);

	if w.hwnd == null {
		win32_print_last_error();
		return w, false;
	}

	w.dc = GetDC(w.hwnd);

	{
		pfd := PIXELFORMATDESCRIPTOR{
			nSize        = size_of(PIXELFORMATDESCRIPTOR) as u32,
			nVersion     = 1,
			dwFlags      = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
			iPixelType   = PFD_TYPE_RGBA,
			cColorBits   = 32,
			cAlphaBits   = 8,
			cDepthBits   = 24,
			cStencilBits = 8,
			iLayerType   = PFD_MAIN_PLANE,
		};

		SetPixelFormat(w.dc, ChoosePixelFormat(w.dc, ^pfd), null);
		w.opengl_context = wglCreateContext(w.dc);
		wglMakeCurrent(w.dc, w.opengl_context);

		attribs := [8]i32{
			WGL_CONTEXT_MAJOR_VERSION_ARB, 2,
			WGL_CONTEXT_MINOR_VERSION_ARB, 1,
			WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
			0, // NOTE(bill): tells the proc that this is the end of attribs
		};

		wgl_string := "wglCreateContextAttribsARB\x00";
		c_wgl_string := ^wgl_string[0];
		wglCreateContextAttribsARB := wglGetProcAddress(c_wgl_string) as wglCreateContextAttribsARBType;
		w.rc = wglCreateContextAttribsARB(w.dc, 0, ^attribs[0]);
		wglMakeCurrent(w.dc, w.rc);
		SwapBuffers(w.dc);
	}

	return w, true;
}

destroy_window :: proc(w: ^Window) {
	heap_free(w.c_title);
}

update_window :: proc(w: ^Window) -> bool {
	msg: MSG;
	for {
		ok := PeekMessageA(^msg, null, 0, 0, PM_REMOVE) != 0;
		if !ok {
			break;
		}

		if msg.message == WM_QUIT {
			return true;
		}
		_ = TranslateMessage(^msg);
		_ = DispatchMessageA(^msg);
	}
	return false;
}

display_window :: proc(w: ^Window) {
	SwapBuffers(w.dc);
}



main :: proc() {
	WINDOW_WIDTH  :: 854;
	WINDOW_HEIGHT :: 480;

	window, window_success := make_window("Odin Language Demo", WINDOW_WIDTH, WINDOW_HEIGHT);
	if !window_success {
		return;
	}
	defer destroy_window(^window);

	start_time := time_now();
	running := true;
	for running {
		curr_time := time_now();
		dt := curr_time - start_time;

		if update_window(^window) {
			running = false;
		}


		glClearColor(0.5, 0.7, 1.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT);
		// glOrtho(0, WINDOW_WIDTH, 0, WINDOW_HEIGHT, -1, +1);

		{
			glBegin(GL_TRIANGLES);
			defer glEnd();

			glColor3f(1, 0, 0); glVertex3f(+0.5, -0.5, 0);
			glColor3f(0, 1, 0); glVertex3f(+0.5, +0.5, 0);
			glColor3f(0, 0, 1); glVertex3f(-0.5, +0.5, 0);

			glColor3f(0, 0, 1); glVertex3f(-0.5, +0.5, 0);
			glColor3f(1, 1, 0); glVertex3f(-0.5, -0.5, 0);
			glColor3f(1, 0, 0); glVertex3f(+0.5, -0.5, 0);
		}

		display_window(^window);
		{
			ms := (16 - dt*1000) as i32;
			if ms > 0 { sleep_ms(ms); }
		}
	}
}
