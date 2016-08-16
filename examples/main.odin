#load "basic.odin"

main :: proc() {
	print_string("Hellope\n");
	defer print_string("World\n");

	for i := 0; i < 4; i++ {
		defer {
			print_int(i);
			print_rune('\n');
		}

		if i > 2 {
			defer print_string("break\n");
			break;
		}
		if i == 2 {
			// return;
		}
	}

	print_string("Never called\n");
}



/*
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
/*
	wc: WNDCLASSEXA;
	instance := GetModuleHandleA(null);

	// Init time info
	_ = QueryPerformanceFrequency(^win32_perf_count_freq);

	// Yuck!
	to_c_string :: proc(s: string) -> ^u8 {
		c_str := heap_alloc(len(s)+1) as ^u8;
		mem_copy(c_str, ^s[0], len(s));
		c_str[len(s)] = 0;
		return c_str;
	}

	class_name := to_c_string("Odin-Language-Demo");
	title := to_c_string("Odin Language Demo");

	wc.cbSize = size_of(WNDCLASSEXA) as u32;
	wc.style = CS_VREDRAW | CS_HREDRAW;
	wc.hInstance = instance;
	wc.className = class_name;
	wc.hbrBackground = COLOR_BACKGROUND as HBRUSH;

	wc.wndProc = proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #no_inline {
		if msg == WM_DESTROY || msg == WM_CLOSE || msg == WM_QUIT {
			ExitProcess(0);
			return 0;
		}
		return DefWindowProcA(hwnd, msg, wparam, lparam);
	};

	if RegisterClassExA(^wc) == 0 {
		return;
	}


	hwnd := CreateWindowExA(0,
	                        class_name, title,
	                        WS_VISIBLE | WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
	                        0, 0, 854, 480,
	                        null, null, instance, null);


	if hwnd == null {
		win32_print_last_error();
		return;
	}

	start_time := time_now();
	running := true;
	tick_count := 0;
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

		print_string("Tick: ");
		print_int(tick_count);
		tick_count++;
		print_rune('\n');

		sleep_ms(16);
	}
*/
}
*/
