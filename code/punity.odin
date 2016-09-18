#import "win32.odin" as win32
#import "fmt.odin" as fmt

CANVAS_WIDTH  :: 128
CANVAS_HEIGHT :: 128
CANVAS_SCALE  :: 3
FRAME_TIME    :: 1.0/30.0
WINDOW_TITLE  : string : "Punity\x00"

_ := compile_assert(CANVAS_WIDTH % 16 == 0)

WINDOW_WIDTH  :: CANVAS_WIDTH  * CANVAS_SCALE
WINDOW_HEIGHT :: CANVAS_HEIGHT * CANVAS_SCALE


STACK_CAPACITY   :: 1<<20
STORAGE_CAPACITY :: 1<<20

DRAW_LIST_RESERVE :: 128

MAX_KEYS :: 256

Core :: struct {
	stack:   ^Bank
	storage: ^Bank

	running:       bool
	key_modifiers: u32
	key_states:    [MAX_KEYS]byte
	key_deltas:    [MAX_KEYS]byte

	perf_frame,
	perf_frame_inner,
	perf_step,
	perf_audio,
	perf_blit,
	perf_blit_cvt,
	perf_blit_gdi: Perf_Span

	frame: i64

	canvas: Canvas
	draw_list: ^Draw_List
}

Perf_Span :: struct {
	stamp: f64
	delta: f32
}

Bank :: struct {
	memory: []byte
	cursor: int
}

Bank_State :: struct {
	state: Bank
	bank: ^Bank
}


Color :: raw_union {
	using channels: struct{ a, b, g, r: byte }
	rgba: u32
}

Palette :: struct {
	colors: [256]Color
	colors_count: byte
}


Rect :: raw_union {
	using minmax: struct {
		min_x, min_y, max_x, max_y: int
	}
	using pos: struct {
		left, top, right, bottom: int
	}
	e: [4]int
}

Bitmap :: struct {
	pixels: []byte
	width:  int
	height: int
}

Font :: struct {
	using bitmap: Bitmap
	char_width:   int
	char_height:  int
}

Canvas :: struct {
	using bitmap: ^Bitmap
	palette:      Palette
	translate_x:  int
	translate_y:  int
	clip:         Rect
	font:         ^Font
}

DrawFlag :: enum {
	NONE   = 0,
	FLIP_H = 1<<0,
	FLIP_V = 1<<1,
	MASK   = 1<<2,
}


Draw_List :: struct {
	Item :: struct {

	}
	items: []Item
}

Key :: enum {
	MOD_SHIFT   = 0x0001,
	MOD_CONTROL = 0x0002,
	MOD_ALT     = 0x0004,
	MOD_SUPER   = 0x0008,

	UNKNOWN            =-1,
	INVALID            =-2,

	LBUTTON            = 1,
	RBUTTON            = 2,
	CANCEL             = 3,
	MBUTTON            = 4,

	BACK               = 8,
	TAB                = 9,
	CLEAR              = 12,
	RETURN             = 13,
	SHIFT              = 16,
	CONTROL            = 17,
	MENU               = 18,
	PAUSE              = 19,
	CAPITAL            = 20,
	KANA               = 0x15,
	HANGEUL            = 0x15,
	HANGUL             = 0x15,
	JUNJA              = 0x17,
	FINAL              = 0x18,
	HANJA              = 0x19,
	KANJI              = 0x19,
	ESCAPE             = 0x1B,
	CONVERT            = 0x1C,
	NONCONVERT         = 0x1D,
	ACCEPT             = 0x1E,
	MODECHANGE         = 0x1F,
	SPACE              = 32,
	PRIOR              = 33,
	NEXT               = 34,
	END                = 35,
	HOME               = 36,
	LEFT               = 37,
	UP                 = 38,
	RIGHT              = 39,
	DOWN               = 40,
	SELECT             = 41,
	PRINT              = 42,
	EXEC               = 43,
	SNAPSHOT           = 44,
	INSERT             = 45,
	DELETE             = 46,
	HELP               = 47,
	LWIN               = 0x5B,
	RWIN               = 0x5C,
	APPS               = 0x5D,
	SLEEP              = 0x5F,
	NUMPAD0            = 0x60,
	NUMPAD1            = 0x61,
	NUMPAD2            = 0x62,
	NUMPAD3            = 0x63,
	NUMPAD4            = 0x64,
	NUMPAD5            = 0x65,
	NUMPAD6            = 0x66,
	NUMPAD7            = 0x67,
	NUMPAD8            = 0x68,
	NUMPAD9            = 0x69,
	MULTIPLY           = 0x6A,
	ADD                = 0x6B,
	SEPARATOR          = 0x6C,
	SUBTRACT           = 0x6D,
	DECIMAL            = 0x6E,
	DIVIDE             = 0x6F,
	F1                 = 0x70,
	F2                 = 0x71,
	F3                 = 0x72,
	F4                 = 0x73,
	F5                 = 0x74,
	F6                 = 0x75,
	F7                 = 0x76,
	F8                 = 0x77,
	F9                 = 0x78,
	F10                = 0x79,
	F11                = 0x7A,
	F12                = 0x7B,
	F13                = 0x7C,
	F14                = 0x7D,
	F15                = 0x7E,
	F16                = 0x7F,
	F17                = 0x80,
	F18                = 0x81,
	F19                = 0x82,
	F20                = 0x83,
	F21                = 0x84,
	F22                = 0x85,
	F23                = 0x86,
	F24                = 0x87,
	NUMLOCK            = 0x90,
	SCROLL             = 0x91,
	LSHIFT             = 0xA0,
	RSHIFT             = 0xA1,
	LCONTROL           = 0xA2,
	RCONTROL           = 0xA3,
	LMENU              = 0xA4,
	RMENU              = 0xA5,

	APOSTROPHE         = 39,  /* ' */
	COMMA              = 44,  /* , */
	MINUS              = 45,  /* - */
	PERIOD             = 46,  /* . */
	SLASH              = 47,  /* / */
	NUM0               = 48,
	NUM1               = 49,
	NUM2               = 50,
	NUM3               = 51,
	NUM4               = 52,
	NUM5               = 53,
	NUM6               = 54,
	NUM7               = 55,
	NUM8               = 56,
	NUM9               = 57,
	SEMICOLON          = 59,  /* ; */
	EQUAL              = 61,  /* = */
	A                  = 65,
	B                  = 66,
	C                  = 67,
	D                  = 68,
	E                  = 69,
	F                  = 70,
	G                  = 71,
	H                  = 72,
	I                  = 73,
	J                  = 74,
	K                  = 75,
	L                  = 76,
	M                  = 77,
	N                  = 78,
	O                  = 79,
	P                  = 80,
	Q                  = 81,
	R                  = 82,
	S                  = 83,
	T                  = 84,
	U                  = 85,
	V                  = 86,
	W                  = 87,
	X                  = 88,
	Y                  = 89,
	Z                  = 90,
	LEFT_BRACKET       = 91,  /* [ */
	BACKSLASH          = 92,  /* \ */
	RIGHT_BRACKET      = 93,  /* ] */
	GRAVE_ACCENT       = 96,  /* ` */
}


key_down :: proc(k: Key) -> bool {
	return _core.key_states[k] != 0
}

key_pressed :: proc(k: Key) -> bool {
	return (_core.key_deltas[k] != 0) && key_down(k)
}




win32_perf_count_freq := win32.GetQueryPerformanceFrequency()
time_now :: proc() -> f64 {
	assert(win32_perf_count_freq != 0)

	counter: i64
	win32.QueryPerformanceCounter(^counter)
	result := counter as f64 / win32_perf_count_freq as f64
	return result
}

_core: Core

run :: proc(user_init, user_step: proc(c: ^Core)) {
	using win32


	_core.running = true

	win32_proc :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #no_inline #stdcall {
		win32_app_key_mods :: proc() -> u32 {
			mods: u32 = 0

			if is_key_down(Key_Code.SHIFT) {
				mods |= Key.MOD_SHIFT as u32;
			}
			if is_key_down(Key_Code.CONTROL) {
				mods |= Key.MOD_CONTROL as u32;
			}
			if is_key_down(Key_Code.MENU) {
				mods |= Key.MOD_ALT as u32;
			}
			if is_key_down(Key_Code.LWIN) || is_key_down(Key_Code.RWIN) {
				mods |= Key.MOD_SUPER as u32;
			}

			return mods
		}

		match msg {
		case WM_KEYDOWN:
			_core.key_modifiers = win32_app_key_mods()
			if wparam < MAX_KEYS {
				_core.key_states[wparam] = 1
				_core.key_deltas[wparam] = 1
			}
			return 0

		case WM_KEYUP:
			_core.key_modifiers = win32_app_key_mods()
			if wparam < MAX_KEYS {
				_core.key_states[wparam] = 0
				_core.key_deltas[wparam] = 1
			}
			return 0

		case WM_CLOSE:
			PostQuitMessage(0)
			_core.running = false
			return 0
		}

		return DefWindowProcA(hwnd, msg, wparam, lparam)
	}


	window_class := WNDCLASSEXA{
		class_name = ("Punity\x00" as string).data, // C-style string
		size       = size_of(WNDCLASSEXA) as u32,
		style      = CS_HREDRAW | CS_VREDRAW | CS_OWNDC,
		instance   = GetModuleHandleA(null) as HINSTANCE,
		wnd_proc   = win32_proc,
		// wnd_proc   = DefWindowProcA,
		background = GetStockObject(BLACK_BRUSH) as HBRUSH,
	}

	if RegisterClassExA(^window_class) == 0 {
		fmt.println_err("RegisterClassExA failed")
		return
	}

	screen_width  := GetSystemMetrics(SM_CXSCREEN)
	screen_height := GetSystemMetrics(SM_CYSCREEN)

	rc: RECT
	rc.left   = (screen_width - WINDOW_WIDTH)   / 2
	rc.top    = (screen_height - WINDOW_HEIGHT) / 2
	rc.right  = rc.left + WINDOW_WIDTH
	rc.bottom = rc.top + WINDOW_HEIGHT

	style: u32 = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX
	assert(AdjustWindowRect(^rc, style, 0) != 0)

	wt := WINDOW_TITLE

	win32_window := CreateWindowExA(0,
	                                window_class.class_name,
	                                WINDOW_TITLE.data,
	                                // wt.data,
	                                style,
	                                rc.left, rc.top,
	                                rc.right-rc.left, rc.bottom-rc.top,
	                                null, null, window_class.instance,
	                                null);

	if win32_window == null {
		fmt.println_err("CreateWindowExA failed")
		return
	}


	window_bmi: BITMAPINFO;
	window_bmi.size        = size_of(BITMAPINFO.HEADER) as u32
	window_bmi.width       = CANVAS_WIDTH
	window_bmi.height      = CANVAS_HEIGHT
	window_bmi.planes      = 1
	window_bmi.bit_count   = 32
	window_bmi.compression = BI_RGB


	user_init(^_core)


	ShowWindow(win32_window, SW_SHOW)

	window_buffer := new_slice(u32, CANVAS_WIDTH * CANVAS_HEIGHT);
	assert(window_buffer.data != null)
	defer free(window_buffer.data)

	for i := 0; i < window_buffer.count; i++ {
		window_buffer[i] = 0xff00ff
	}


	prev_time, curr_time,dt: f64
	prev_time = time_now()
	curr_time = time_now()
	total_time : f64 = 0
	offset_x := 0;
	offset_y := 0;

	message: MSG
	for _core.running {
		curr_time = time_now()
		dt = curr_time - prev_time
		prev_time = curr_time
		total_time += dt

		offset_x += 1
		offset_y += 2

		{
			data: [128]byte
			buf := data[:0]
			fmt.print_to_buffer(^buf, "Punity: % ms\x00", dt*1000)
			win32.SetWindowTextA(win32_window, buf.data)
		}


		for y := 0; y < CANVAS_HEIGHT; y++ {
			for x := 0; x < CANVAS_WIDTH; x++ {
				g := (x % 32) * 8
				b := (y % 32) * 8
				window_buffer[x + y*CANVAS_WIDTH] = (g << 8 | b) as u32
			}
		}

		memory_zero(^_core.key_deltas[0], size_of(_core.key_deltas[0]))


		for PeekMessageA(^message, null, 0, 0, PM_REMOVE) != 0 {
			if message.message == WM_QUIT {
				_core.running = false
			}
			TranslateMessage(^message)
			DispatchMessageA(^message)
		}

		user_step(^_core)

		dc := GetDC(win32_window);
		StretchDIBits(dc,
		              0, 0, CANVAS_WIDTH * CANVAS_SCALE, CANVAS_HEIGHT * CANVAS_SCALE,
		              0, 0, CANVAS_WIDTH, CANVAS_HEIGHT,
		              window_buffer.data,
		              ^window_bmi,
		              DIB_RGB_COLORS,
		              SRCCOPY)
		ReleaseDC(win32_window, dc)


		{
			delta := time_now() - prev_time
			ms := ((FRAME_TIME - delta) * 1000) as i32
			if ms > 0 {
				win32.Sleep(ms)
			}
		}

		_core.frame++
	}
}
