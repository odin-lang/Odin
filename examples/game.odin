#load "basic.odin"
#load "opengl.odin"
#load "math.odin"

TWO_HEARTS :: #rune "💕"

win32_perf_count_freq := GetQueryPerformanceFrequency()
time_now :: proc() -> f64 {
	if win32_perf_count_freq == 0 {
		debug_trap()
	}

	counter: i64
	_ = QueryPerformanceCounter(^counter)
	result := counter as f64 / win32_perf_count_freq as f64
	return result
}
win32_print_last_error :: proc() {
	err_code := GetLastError() as int
	if err_code != 0 {
		print_string("GetLastError: ")
		print_int(err_code)
		print_string("\n")
	}
}

// Yuk!
to_c_string :: proc(s: string) -> ^u8 {
	c_str: ^u8 = alloc(len(s)+1)
	memory_copy(c_str, ^s[0], len(s))
	ptr_offset(c_str, len(s))^ = 0
	return c_str
}


Window :: type struct {
	width, height:      int
	wc:                 WNDCLASSEXA
	dc:                 HDC
	hwnd:               HWND
	opengl_context, rc: HGLRC
	c_title:            ^u8
}

make_window :: proc(title: string, msg, height: int, window_proc: WNDPROC) -> (Window, bool) {
	w: Window
	w.width, w.height = msg, height

	class_name   := "Win32-Odin-Window\x00"
	c_class_name := ^class_name[0]
	w.c_title = to_c_string(title)

	instance := GetModuleHandleA(null)

	w.wc = WNDCLASSEXA{
		size       = size_of(WNDCLASSEXA) as u32,
		style      = CS_VREDRAW | CS_HREDRAW,
		instance   = instance as HINSTANCE,
		class_name = c_class_name,
		wnd_proc   = window_proc,
	};

	if RegisterClassExA(^w.wc) == 0 {
		return w, false
	}

	w.hwnd = CreateWindowExA(0,
	                         c_class_name, w.c_title,
	                         WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
	                         CW_USEDEFAULT, CW_USEDEFAULT,
	                         w.width as i32, w.height as i32,
	                         null, null, instance, null)

	if w.hwnd == null {
		win32_print_last_error()
		return w, false
	}

	w.dc = GetDC(w.hwnd)

	{
		pfd := PIXELFORMATDESCRIPTOR{
			size         = size_of(PIXELFORMATDESCRIPTOR) as u32,
			version      = 1,
			flags        = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER,
			pixel_type   = PFD_TYPE_RGBA,
			color_bits   = 32,
			alpha_bits   = 8,
			depth_bits   = 24,
			stencil_bits = 8,
			layer_type   = PFD_MAIN_PLANE,
		}

		SetPixelFormat(w.dc, ChoosePixelFormat(w.dc, ^pfd), null)
		w.opengl_context = wglCreateContext(w.dc)
		wglMakeCurrent(w.dc, w.opengl_context)

		attribs := [8]i32{
			WGL_CONTEXT_MAJOR_VERSION_ARB, 2,
			WGL_CONTEXT_MINOR_VERSION_ARB, 1,
			WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
			0, // NOTE(bill): tells the proc that this is the end of attribs
		}

		wgl_string := "wglCreateContextAttribsARB\x00"
		c_wgl_string := ^wgl_string[0]
		wglCreateContextAttribsARB := wglGetProcAddress(c_wgl_string) as wglCreateContextAttribsARBType
		w.rc = wglCreateContextAttribsARB(w.dc, 0, ^attribs[0])
		wglMakeCurrent(w.dc, w.rc)
		SwapBuffers(w.dc)
	}

	return w, true
}

destroy_window :: proc(w: ^Window) {
	heap_free(w.c_title)
}

display_window :: proc(w: ^Window) {
	SwapBuffers(w.dc)
}


Entity :: type struct {
	pos: Vec2
	dim: Vec2
}


run_game :: proc() {
	win32_proc :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #no_inline {
		if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
			ExitProcess(0)
			return 0
		}
		return DefWindowProcA(hwnd, msg, wparam, lparam)
	}

	window, window_success := make_window("Odin Language Demo", 854, 480, win32_proc)
	if !window_success {
		return
	}
	defer destroy_window(^window)


	prev_time := time_now()
	running := true

	pos := Vec2{100, 100}

	for running {
		curr_time := time_now()
		dt := (curr_time - prev_time) as f32
		prev_time = curr_time

		msg: MSG
		for PeekMessageA(^msg, null, 0, 0, PM_REMOVE) > 0 {
			if msg.message == WM_QUIT {
				running = false
			}
			_ = TranslateMessage(^msg)
			_ = DispatchMessageA(^msg)
		}

		if is_key_down(VK_ESCAPE) {
			running = false
		}

		{
			SPEED :: 500
			v: Vec2

			if is_key_down(VK_RIGHT) { v[0] += 1 }
			if is_key_down(VK_LEFT)  { v[0] -= 1 }
			if is_key_down(VK_UP)    { v[1] += 1 }
			if is_key_down(VK_DOWN)  { v[1] -= 1 }

			v = vec2_norm0(v)

			pos += v * Vec2{SPEED * dt}
		}


		glClearColor(0.5, 0.7, 1.0, 1.0)
		glClear(GL_COLOR_BUFFER_BIT)

		glLoadIdentity()
		glOrtho(0, window.width as f64,
		        0, window.height as f64, 0, 1)

		draw_rect :: proc(x, y, w, h: f32) {
			glBegin(GL_TRIANGLES)

			glColor3f(1, 0, 0); glVertex3f(x,   y,   0)
			glColor3f(0, 1, 0); glVertex3f(x+w, y,   0)
			glColor3f(0, 0, 1); glVertex3f(x+w, y+h, 0)

			glColor3f(0, 0, 1); glVertex3f(x+w, y+h, 0)
			glColor3f(1, 1, 0); glVertex3f(x,   y+h, 0)
			glColor3f(1, 0, 0); glVertex3f(x,   y,   0)

			glEnd()
		}

		draw_rect(pos[0], pos[1], 50, 50)

		display_window(^window)
		ms_to_sleep := (16 - 1000*dt) as i32
		if ms_to_sleep > 0 {
			sleep_ms(ms_to_sleep)
		}
	}
}
