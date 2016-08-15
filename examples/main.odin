#load "basic.odin"
#load "win32.odin"

main :: proc() {
	wc: WNDCLASSEXA;
	instance := GetModuleHandleA(null);

	// Yuck!
	to_c_string :: proc(s: string) -> ^u8 {
		c_str := heap_alloc(len(s)+1) as ^u8;
		mem_copy(c_str, ^s[0], len(s));
		c_str[len(s)] = 0;
		return c_str;
	}

	class_name := to_c_string("Odin-Language-Demo");
	title := to_c_string("Odin-Language-Demo");

	wc.cbSize = size_of(WNDCLASSEXA) as u32;
	wc.style = CS_VREDRAW | CS_HREDRAW;
	wc.hInstance = instance;
	wc.className = class_name;
	wc.wndProc = proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #no_inline {
		if (msg == WM_DESTROY ||
		    msg == WM_CLOSE ||
		    msg == WM_QUIT) {
			ExitProcess(0);
			return 0;
		}
		// HACK(bill): Compiler bug
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
		print_string("GetLastError: ");
		print_int(GetLastError() as int);
		print_string("\n");
		return;
	}

	msg: MSG;
	for {
		ok := PeekMessageA(^msg, null, 0, 0, PM_REMOVE);
		if ok == 0 { break; }

		if msg.message == WM_QUIT {
			return;
		} else {
			_ = TranslateMessage(^msg);
			_ = DispatchMessageA(^msg);
		}
	}
}
