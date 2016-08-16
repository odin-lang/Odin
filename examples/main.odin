#load "basic.odin"
#load "win32.odin"

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

main :: proc() {
	instance := GetModuleHandleA(null);

	class_name := "Odin-Language-Demo\x00";
	title := "Odin Language Demo\x00";
	c_class_name := ^class_name[0];
	c_title := ^title[0];

	wc := WNDCLASSEXA{
		cbSize    = size_of(WNDCLASSEXA) as u32,
		style     = CS_VREDRAW | CS_HREDRAW,
		hInstance = instance as HINSTANCE,
		className = c_class_name,
		wndProc   = proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #no_inline {
			if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
				ExitProcess(0);
				return 0;
			}
			return DefWindowProcA(hwnd, msg, wparam, lparam);
		},
	};

	if RegisterClassExA(^wc) == 0 {
		return;
	}

	hwnd := CreateWindowExA(0,
	                        c_class_name, c_title,
	                        WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
	                        CW_USEDEFAULT, CW_USEDEFAULT, 854, 480,
	                        null, null, instance, null);


	if hwnd == null {
		win32_print_last_error();
		return;
	}

	dc := GetDC(hwnd);
	opengl_context: HGLRC;

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

		SetPixelFormat(dc, ChoosePixelFormat(dc, ^pfd), null);
		opengl_context = wglCreateContext(dc);
		wglMakeCurrent(dc, opengl_context);

		attribs := [8]i32{
			0x2091, // WGL_CONTEXT_MAJOR_VERSION_ARB
			2, // Major
			0x2092, // WGL_CONTEXT_MINOR_VERSION_ARB
			1, // Minor
			0x9126, // WGL_CONTEXT_PROFILE_MASK_ARB
			0x0002, // WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB
			0, // NOTE(bill): tells the proc that this is the end of attribs
		};

		wgl_string := "wglCreateContextAttribsARB\x00";
		wglCreateContextAttribsARB := wglGetProcAddress(^wgl_string[0]) as wglCreateContextAttribsARBType;
		rc := wglCreateContextAttribsARB(dc, 0, ^attribs[0]);
		wglMakeCurrent(dc, rc);
		SwapBuffers(dc);
	}

	start_time := time_now();
	running := false;
	for running {
		curr_time := time_now();
		dt := curr_time - start_time;
		if dt > 2.0 {
			running = false;
		}

		msg: MSG;
		for {
			ok := PeekMessageA(^msg, null, 0, 0, PM_REMOVE) != 0;
			if !ok {
				break;
			}

			if msg.message == WM_QUIT {
				return;
			} else {
				_ = TranslateMessage(^msg);
				_ = DispatchMessageA(^msg);
			}
		}

		SwapBuffers(dc);
		sleep_ms(2);
	}
}
