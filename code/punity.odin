import (
	win32 "sys/windows.odin";
	"fmt.odin";
	"os.odin";
	"mem.odin";
)

const (
	CANVAS_WIDTH  = 128;
	CANVAS_HEIGHT = 128;
	CANVAS_SCALE  = 3;
	FRAME_TIME    = 1.0/30.0;
	WINDOW_TITLE  = "Punity\x00";
)

const _ = compile_assert(CANVAS_WIDTH % 16 == 0);

const (
	WINDOW_WIDTH  = CANVAS_WIDTH  * CANVAS_SCALE;
	WINDOW_HEIGHT = CANVAS_HEIGHT * CANVAS_SCALE;
)

const (
	STACK_CAPACITY   = 1<<20;
	STORAGE_CAPACITY = 1<<20;

	DRAW_LIST_RESERVE = 128;

	MAX_KEYS = 256;
)

type Core struct {
	stack:   ^Bank,
	storage: ^Bank,

	running:       bool,
	key_modifiers: u32,
	key_states:    [MAX_KEYS]u8,
	key_deltas:    [MAX_KEYS]u8,

	perf_frame,
	perf_frame_inner,
	perf_step,
	perf_audio,
	perf_blit,
	perf_blit_cvt,
	perf_blit_gdi: Perf_Span,

	frame: i64,

	canvas:    Canvas,
	draw_list: ^Draw_List,
}

type Perf_Span struct {
	stamp: f64,
	delta: f32,
}

type Bank struct {
	memory: []u8,
	cursor: int,
}

type Bank_State struct {
	state: Bank,
	bank: ^Bank,
}


type Color raw_union {
	using channels: struct{a, b, g, r: u8},
	rgba: u32,
}

type Palette struct {
	colors: [256]Color,
	colors_count: u8,
}


type Rect raw_union {
	using minmax: struct {min_x, min_y, max_x, max_y: int},
	using pos: struct {left, top, right, bottom: int},
	e: [4]int,
}

type Bitmap struct {
	pixels: []u8,
	width:  int,
	height: int,
}

type Font struct {
	using bitmap: Bitmap,
	char_width:   int,
	char_height:  int,
}

type Canvas struct {
	using bitmap: ^Bitmap,
	palette:      Palette,
	translate_x:  int,
	translate_y:  int,
	clip:         Rect,
	font:         ^Font,
}

type DrawFlag enum {
	NONE   = 0,
	FLIP_H = 1<<0,
	FLIP_V = 1<<1,
	MASK   = 1<<2,
}

type Draw_Item struct {}
type Draw_List struct {
	items: []Draw_Item,
}

type Key enum {
	ModShift   = 0x0001,
	ModControl = 0x0002,
	ModAlt     = 0x0004,
	ModSuper   = 0x0008,


	Unknown            =-1,
	Invalid            =-2,


	Lbutton            = 1,
	Rbutton            = 2,
	Cancel             = 3,
	Mbutton            = 4,


	Back               = 8,
	Tab                = 9,
	Clear              = 12,
	Return             = 13,
	Shift              = 16,
	Control            = 17,
	Menu               = 18,
	Pause              = 19,
	Capital            = 20,
	Kana               = 0x15,
	Hangeul            = 0x15,
	Hangul             = 0x15,
	Junja              = 0x17,
	Final              = 0x18,
	Hanja              = 0x19,
	Kanji              = 0x19,
	Escape             = 0x1B,
	Convert            = 0x1C,
	NonConvert         = 0x1D,
	Accept             = 0x1E,
	ModeChange         = 0x1F,
	Space              = 32,
	Prior              = 33,
	Next               = 34,
	End                = 35,
	Home               = 36,
	Left               = 37,
	Up                 = 38,
	Right              = 39,
	Down               = 40,
	Select             = 41,
	Print              = 42,
	Exec               = 43,
	Snapshot           = 44,
	Insert             = 45,
	Delete             = 46,
	Help               = 47,
	Lwin               = 0x5B,
	Rwin               = 0x5C,
	Apps               = 0x5D,
	Sleep              = 0x5F,
	Numpad0            = 0x60,
	Numpad1            = 0x61,
	Numpad2            = 0x62,
	Numpad3            = 0x63,
	Numpad4            = 0x64,
	Numpad5            = 0x65,
	Numpad6            = 0x66,
	Numpad7            = 0x67,
	Numpad8            = 0x68,
	Numpad9            = 0x69,
	Multiply           = 0x6A,
	Add                = 0x6B,
	Separator          = 0x6C,
	Subtract           = 0x6D,
	Decimal            = 0x6E,
	Divide             = 0x6F,
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
	Numlock            = 0x90,
	Scroll             = 0x91,
	Lshift             = 0xA0,
	Rshift             = 0xA1,
	Lcontrol           = 0xA2,
	Rcontrol           = 0xA3,
	Lmenu              = 0xA4,
	Rmenu              = 0xA5,


	Apostrophe         = 39,  /* ' */
	Comma              = 44,  /* , */
	Minus              = 45,  /* - */
	Period             = 46,  /* . */
	Slash              = 47,  /* / */
	Num0               = 48,
	Num1               = 49,
	Num2               = 50,
	Num3               = 51,
	Num4               = 52,
	Num5               = 53,
	Num6               = 54,
	Num7               = 55,
	Num8               = 56,
	Num9               = 57,
	Semicolon          = 59,  /* ; */
	Equal              = 61,  /* = */
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
	LeftBracket        = 91,  /* [ */
	Backslash          = 92,  /* \ */
	RightBracket       = 93,  /* ] */
	GraveAccent        = 96,  /* ` */
};


proc key_down(k: Key) -> bool {
	return _core.key_states[k] != 0;
}

proc key_pressed(k: Key) -> bool {
	return (_core.key_deltas[k] != 0) && key_down(k);
}




let win32_perf_count_freq = win32.get_query_performance_frequency();
proc time_now() -> f64 {
	assert(win32_perf_count_freq != 0);

	var counter: i64;
	win32.query_performance_counter(&counter);
	return f64(counter) / f64(win32_perf_count_freq);
}

var _core: Core;

proc run(user_init, user_step: proc(c: ^Core)) {
	using win32;

	_core.running = true;

	proc win32_proc(hwnd: win32.Hwnd, msg: u32, wparam: win32.Wparam, lparam: win32.Lparam) -> win32.Lresult #no_inline #cc_c {
		proc win32_app_key_mods() -> u32 {
			var mods: u32 = 0;

			if is_key_down(KeyCode.Shift) {
				mods |= u32(Key.ModShift);
			}
			if is_key_down(KeyCode.Control) {
				mods |= u32(Key.ModControl);
			}
			if is_key_down(KeyCode.Menu) {
				mods |= u32(Key.ModAlt);
			}
			if is_key_down(KeyCode.Lwin) || is_key_down(KeyCode.Rwin) {
				mods |= u32(Key.ModSuper);
			}

			return mods;
		}

		match msg {
		case WM_KEYDOWN:
			_core.key_modifiers = win32_app_key_mods();
			if wparam < MAX_KEYS {
				_core.key_states[wparam] = 1;
				_core.key_deltas[wparam] = 1;
			}
			return 0;

		case WM_KEYUP:
			_core.key_modifiers = win32_app_key_mods();
			if wparam < MAX_KEYS {
				_core.key_states[wparam] = 0;
				_core.key_deltas[wparam] = 1;
			}
			return 0;

		case WM_CLOSE:
			post_quit_message(0);
			_core.running = false;
			return 0;
		}

		return def_window_proc_a(hwnd, msg, wparam, lparam);
	}


	var class_name = "Punity\x00";
	var window_class = WndClassExA{
		class_name = &class_name[0],
		size       = size_of(WndClassExA),
		style      = CS_HREDRAW | CS_VREDRAW | CS_OWNDC,
		instance   = Hinstance(get_module_handle_a(nil)),
		wnd_proc   = win32_proc,
		// wnd_proc   = DefWindowProcA,
		background = Hbrush(get_stock_object(BLACK_BRUSH)),
	};

	if register_class_ex_a(&window_class) == 0 {
		fmt.fprintln(os.stderr, "register_class_ex_a failed");
		return;
	}

	var screen_width  = get_system_metrics(SM_CXSCREEN);
	var screen_height = get_system_metrics(SM_CYSCREEN);

	var rc: Rect;
	rc.left   = (screen_width - WINDOW_WIDTH)   / 2;
	rc.top    = (screen_height - WINDOW_HEIGHT) / 2;
	rc.right  = rc.left + WINDOW_WIDTH;
	rc.bottom = rc.top + WINDOW_HEIGHT;

	var style: u32 = WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
	assert(adjust_window_rect(&rc, style, 0) != 0);

	var wt = WINDOW_TITLE;

	var win32_window = create_window_ex_a(0,
	                                      window_class.class_name,
	                                      &wt[0],
	                                      style,
	                                      rc.left, rc.top,
	                                      rc.right-rc.left, rc.bottom-rc.top,
	                                      nil, nil, window_class.instance,
	                                      nil);

	if win32_window == nil {
		fmt.fprintln(os.stderr, "create_window_ex_a failed");
		return;
	}


	var window_bmi: BitmapInfo;
	window_bmi.size        = size_of(BitmapInfoHeader);
	window_bmi.width       = CANVAS_WIDTH;
	window_bmi.height      = CANVAS_HEIGHT;
	window_bmi.planes      = 1;
	window_bmi.bit_count   = 32;
	window_bmi.compression = BI_RGB;


	user_init(&_core);

	show_window(win32_window, SW_SHOW);

	var window_buffer = make([]u32, CANVAS_WIDTH * CANVAS_HEIGHT);
	defer free(window_buffer);

	for _, i in window_buffer {
		window_buffer[i] = 0xff00ff;
	}

	var (
		dt: f64;
		prev_time = time_now();
		curr_time = time_now();
		total_time : f64 = 0;
		offset_x = 0;
		offset_y = 0;
	)

	var message: Msg;
	for _core.running {
		curr_time = time_now();
		dt = curr_time - prev_time;
		prev_time = curr_time;
		total_time += dt;

		offset_x += 1;
		offset_y += 2;

		{
			var buf: [128]u8;
			var s = fmt.bprintf(buf[..], "Punity: %.4f ms\x00", dt*1000);
			win32.set_window_text_a(win32_window, &s[0]);
		}


		for var y = 0; y < CANVAS_HEIGHT; y++ {
			for var x = 0; x < CANVAS_WIDTH; x++ {
				var g = (x % 32) * 8;
				var b = (y % 32) * 8;
				window_buffer[x + y*CANVAS_WIDTH] = u32(g << 8 | b);
			}
		}

		mem.zero(&_core.key_deltas[0], size_of(_core.key_deltas));

		for peek_message_a(&message, nil, 0, 0, PM_REMOVE) != 0 {
			if message.message == WM_QUIT {
				_core.running = false;
			}
			translate_message(&message);
			dispatch_message_a(&message);
		}

		user_step(&_core);

		var dc = get_dc(win32_window);
		stretch_dibits(dc,
		               0, 0, CANVAS_WIDTH * CANVAS_SCALE, CANVAS_HEIGHT * CANVAS_SCALE,
		               0, 0, CANVAS_WIDTH, CANVAS_HEIGHT,
		               &window_buffer[0],
		               &window_bmi,
		               DIB_RGB_COLORS,
		               SRCCOPY);
		release_dc(win32_window, dc);


		{
			var delta = time_now() - prev_time;
			var ms = i32((FRAME_TIME - delta) * 1000);
			if ms > 0 {
				win32.sleep(ms);
			}
		}

		_core.frame++;
	}
}


proc main() {
	proc user_init(c: ^Core) {

	}

	proc user_step(c: ^Core) {

	}

	run(user_init, user_step);
}
