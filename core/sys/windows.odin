#foreign_system_library "user32" when ODIN_OS == "windows";
#foreign_system_library "gdi32"  when ODIN_OS == "windows";

type (
	HANDLE    rawptr;
	HWND      HANDLE;
	HDC       HANDLE;
	HINSTANCE HANDLE;
	HICON     HANDLE;
	HCURSOR   HANDLE;
	HMENU     HANDLE;
	HBRUSH    HANDLE;
	HGDIOBJ   HANDLE;
	HMODULE   HANDLE;
	WPARAM    uint;
	LPARAM    int;
	LRESULT   int;
	ATOM      i16;
	BOOL      i32;
	WNDPROC   proc(hwnd HWND, msg u32, wparam WPARAM, lparam LPARAM) -> LRESULT;
)

const (
	INVALID_HANDLE_VALUE = (-1 as int) as HANDLE;

	CS_VREDRAW    = 0x0001;
	CS_HREDRAW    = 0x0002;
	CS_OWNDC      = 0x0020;
	CW_USEDEFAULT = -0x80000000;

	WS_OVERLAPPED       = 0;
	WS_MAXIMIZEBOX      = 0x00010000;
	WS_MINIMIZEBOX      = 0x00020000;
	WS_THICKFRAME       = 0x00040000;
	WS_SYSMENU          = 0x00080000;
	WS_CAPTION          = 0x00C00000;
	WS_VISIBLE          = 0x10000000;
	WS_OVERLAPPEDWINDOW = WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;

	WM_DESTROY = 0x0002;
	WM_CLOSE   = 0x0010;
	WM_QUIT    = 0x0012;
	WM_KEYDOWN = 0x0100;
	WM_KEYUP   = 0x0101;

	PM_REMOVE = 1;

	COLOR_BACKGROUND = 1 as HBRUSH;
	BLACK_BRUSH = 4;

	SM_CXSCREEN = 0;
	SM_CYSCREEN = 1;

	SW_SHOW = 5;
)

type (
	POINT struct #ordered {
		x, y i32;
	}

	WNDCLASSEXA struct #ordered {
		size, style           u32;
		wnd_proc              WNDPROC;
		cls_extra, wnd_extra  i32;
		instance              HINSTANCE;
		icon                  HICON;
		cursor                HCURSOR;
		background            HBRUSH;
		menu_name, class_name ^u8;
		sm                    HICON;
	}

	MSG struct #ordered {
		hwnd    HWND;
		message u32;
		wparam  WPARAM;
		lparam  LPARAM;
		time    u32;
		pt      POINT;
	}

	RECT struct #ordered {
		left   i32;
		top    i32;
		right  i32;
		bottom i32;
	}

	FILETIME struct #ordered {
		low_date_time, high_date_time u32;
	}

	BY_HANDLE_FILE_INFORMATION struct #ordered {
		file_attributes      u32;
		creation_time,
		last_access_time,
		last_write_time      FILETIME;
		volume_serial_number,
		file_size_high,
		file_size_low,
		number_of_links,
		file_index_high,
		file_index_low       u32;
	}

	WIN32_FILE_ATTRIBUTE_DATA struct #ordered {
		file_attributes  u32;
		creation_time,
		last_access_time,
		last_write_time  FILETIME;
		file_size_high,
		file_size_low    u32;
	}

	GET_FILEEX_INFO_LEVELS i32;
)
const (
	GetFileExInfoStandard = 0 as GET_FILEEX_INFO_LEVELS;
	GetFileExMaxInfoLevel = 1 as GET_FILEEX_INFO_LEVELS;
)

proc GetLastError    () -> i32                           #foreign #dll_import
proc ExitProcess     (exit_code u32)                    #foreign #dll_import
proc GetDesktopWindow() -> HWND                          #foreign #dll_import
proc GetCursorPos    (p ^POINT) -> i32                  #foreign #dll_import
proc ScreenToClient  (h HWND, p ^POINT) -> i32         #foreign #dll_import
proc GetModuleHandleA(module_name ^u8) -> HINSTANCE     #foreign #dll_import
proc GetStockObject  (fn_object i32) -> HGDIOBJ         #foreign #dll_import
proc PostQuitMessage (exit_code i32)                    #foreign #dll_import
proc SetWindowTextA  (hwnd HWND, c_string ^u8) -> BOOL #foreign #dll_import

proc QueryPerformanceFrequency(result ^i64) -> i32 #foreign #dll_import
proc QueryPerformanceCounter  (result ^i64) -> i32 #foreign #dll_import

proc Sleep(ms i32) -> i32 #foreign #dll_import

proc OutputDebugStringA(c_str ^u8) #foreign #dll_import


proc RegisterClassExA(wc ^WNDCLASSEXA) -> ATOM #foreign #dll_import
proc CreateWindowExA (ex_style u32,
                      class_name, title ^u8,
                      style u32,
                      x, y, w, h i32,
                      parent HWND, menu HMENU, instance HINSTANCE,
                      param rawptr) -> HWND #foreign #dll_import

proc ShowWindow      (hwnd HWND, cmd_show i32) -> BOOL #foreign #dll_import
proc TranslateMessage(msg ^MSG) -> BOOL                 #foreign #dll_import
proc DispatchMessageA(msg ^MSG) -> LRESULT              #foreign #dll_import
proc UpdateWindow    (hwnd HWND) -> BOOL                #foreign #dll_import
proc PeekMessageA    (msg ^MSG, hwnd HWND,
                         msg_filter_min, msg_filter_max, remove_msg u32) -> BOOL #foreign #dll_import

proc DefWindowProcA  (hwnd HWND, msg u32, wparam WPARAM, lparam LPARAM) -> LRESULT #foreign #dll_import

proc AdjustWindowRect(rect ^RECT, style u32, menu BOOL) -> BOOL #foreign #dll_import
proc GetActiveWindow () -> HWND #foreign #dll_import


proc GetQueryPerformanceFrequency() -> i64 {
	var r i64;
	QueryPerformanceFrequency(^r);
	return r;
}

proc GetCommandLineA() -> ^u8 #foreign #dll_import
proc GetSystemMetrics(index i32) -> i32 #foreign #dll_import
proc GetCurrentThreadId() -> u32 #foreign #dll_import

// File Stuff

proc CloseHandle (h HANDLE) -> i32 #foreign #dll_import
proc GetStdHandle(h i32) -> HANDLE #foreign #dll_import
proc CreateFileA (filename ^u8, desired_access, share_mode u32,
                     security rawptr,
                     creation, flags_and_attribs u32, template_file HANDLE) -> HANDLE #foreign #dll_import
proc ReadFile    (h HANDLE, buf rawptr, to_read u32, bytes_read ^i32, overlapped rawptr) -> BOOL #foreign #dll_import
proc WriteFile   (h HANDLE, buf rawptr, len i32, written_result ^i32, overlapped rawptr) -> i32 #foreign #dll_import

proc GetFileSizeEx             (file_handle HANDLE, file_size ^i64) -> BOOL #foreign #dll_import
proc GetFileAttributesExA      (filename ^u8, info_level_id GET_FILEEX_INFO_LEVELS, file_info rawptr) -> BOOL #foreign #dll_import
proc GetFileInformationByHandle(file_handle HANDLE, file_info ^BY_HANDLE_FILE_INFORMATION) -> BOOL #foreign #dll_import

const (
	FILE_SHARE_READ      = 0x00000001;
	FILE_SHARE_WRITE     = 0x00000002;
	FILE_SHARE_DELETE    = 0x00000004;
	FILE_GENERIC_ALL     = 0x10000000;
	FILE_GENERIC_EXECUTE = 0x20000000;
	FILE_GENERIC_WRITE   = 0x40000000;
	FILE_GENERIC_READ    = 0x80000000;

	STD_INPUT_HANDLE  = -10;
	STD_OUTPUT_HANDLE = -11;
	STD_ERROR_HANDLE  = -12;

	CREATE_NEW        = 1;
	CREATE_ALWAYS     = 2;
	OPEN_EXISTING     = 3;
	OPEN_ALWAYS       = 4;
	TRUNCATE_EXISTING = 5;
)




proc HeapAlloc     (h HANDLE, flags u32, bytes int) -> rawptr                 #foreign #dll_import
proc HeapReAlloc   (h HANDLE, flags u32, memory rawptr, bytes int) -> rawptr #foreign #dll_import
proc HeapFree      (h HANDLE, flags u32, memory rawptr) -> BOOL               #foreign #dll_import
proc GetProcessHeap() -> HANDLE #foreign #dll_import


const HEAP_ZERO_MEMORY = 0x00000008;

// Synchronization

type SECURITY_ATTRIBUTES struct #ordered {
	length              u32;
	security_descriptor rawptr;
	inherit_handle      BOOL;
}

const INFINITE = 0xffffffff;

proc CreateSemaphoreA   (attributes ^SECURITY_ATTRIBUTES, initial_count, maximum_count i32, name ^byte) -> HANDLE #foreign #dll_import
proc ReleaseSemaphore   (semaphore HANDLE, release_count i32, previous_count ^i32) -> BOOL #foreign #dll_import
proc WaitForSingleObject(handle HANDLE, milliseconds u32) -> u32 #foreign #dll_import


proc InterlockedCompareExchange(dst ^i32, exchange, comparand i32) -> i32 #foreign
proc InterlockedExchange       (dst ^i32, desired i32) -> i32 #foreign
proc InterlockedExchangeAdd    (dst ^i32, desired i32) -> i32 #foreign
proc InterlockedAnd            (dst ^i32, desired i32) -> i32 #foreign
proc InterlockedOr             (dst ^i32, desired i32) -> i32 #foreign

proc InterlockedCompareExchange64(dst ^i64, exchange, comparand i64) -> i64 #foreign
proc InterlockedExchange64       (dst ^i64, desired i64) -> i64 #foreign
proc InterlockedExchangeAdd64    (dst ^i64, desired i64) -> i64 #foreign
proc InterlockedAnd64            (dst ^i64, desired i64) -> i64 #foreign
proc InterlockedOr64             (dst ^i64, desired i64) -> i64 #foreign

proc _mm_pause       () #foreign
proc ReadWriteBarrier() #foreign
proc WriteBarrier    () #foreign
proc ReadBarrier     () #foreign


// GDI
type (
	BITMAPINFOHEADER struct #ordered {
		size              u32;
		width, height     i32;
		planes, bit_count i16;
		compression       u32;
		size_image        u32;
		x_pels_per_meter  i32;
		y_pels_per_meter  i32;
		clr_used          u32;
		clr_important     u32;
	}
	BITMAPINFO struct #ordered {
		using header BITMAPINFOHEADER;
		colors       [1]RGBQUAD;
	}


	RGBQUAD struct #ordered {
		blue, green, red, reserved byte;
	}
)

const (
	BI_RGB         = 0;
	DIB_RGB_COLORS = 0x00;
	SRCCOPY        = 0x00cc0020 as u32;
)

proc StretchDIBits(hdc HDC,
                   x_dst, y_dst, width_dst, height_dst i32,
                   x_src, y_src, width_src, header_src i32,
                   bits rawptr, bits_info ^BITMAPINFO,
                   usage u32,
                   rop u32) -> i32 #foreign #dll_import



proc LoadLibraryA  (c_str ^u8) -> HMODULE #foreign
proc FreeLibrary   (h HMODULE) #foreign
proc GetProcAddress(h HMODULE, c_str ^u8) -> PROC #foreign

proc GetClientRect(hwnd HWND, rect ^RECT) -> BOOL #foreign



// Windows OpenGL
const (
	PFD_TYPE_RGBA             = 0;
	PFD_TYPE_COLORINDEX       = 1;
	PFD_MAIN_PLANE            = 0;
	PFD_OVERLAY_PLANE         = 1;
	PFD_UNDERLAY_PLANE        = -1;
	PFD_DOUBLEBUFFER          = 1;
	PFD_STEREO                = 2;
	PFD_DRAW_TO_WINDOW        = 4;
	PFD_DRAW_TO_BITMAP        = 8;
	PFD_SUPPORT_GDI           = 16;
	PFD_SUPPORT_OPENGL        = 32;
	PFD_GENERIC_FORMAT        = 64;
	PFD_NEED_PALETTE          = 128;
	PFD_NEED_SYSTEM_PALETTE   = 0x00000100;
	PFD_SWAP_EXCHANGE         = 0x00000200;
	PFD_SWAP_COPY             = 0x00000400;
	PFD_SWAP_LAYER_BUFFERS    = 0x00000800;
	PFD_GENERIC_ACCELERATED   = 0x00001000;
	PFD_DEPTH_DONTCARE        = 0x20000000;
	PFD_DOUBLEBUFFER_DONTCARE = 0x40000000;
	PFD_STEREO_DONTCARE       = 0x80000000;
)

type (
	HGLRC HANDLE;
	PROC  proc();
	wglCreateContextAttribsARBType proc(hdc HDC, hshareContext rawptr, attribList ^i32) -> HGLRC;


	PIXELFORMATDESCRIPTOR struct #ordered {
		size,
		version,
		flags u32;

		pixel_type,
		color_bits,
		red_bits,
		red_shift,
		green_bits,
		green_shift,
		blue_bits,
		blue_shift,
		alpha_bits,
		alpha_shift,
		accum_bits,
		accum_red_bits,
		accum_green_bits,
		accum_blue_bits,
		accum_alpha_bits,
		depth_bits,
		stencil_bits,
		aux_buffers,
		layer_type,
		reserved byte;

		layer_mask,
		visible_mask,
		damage_mask u32;
	}
)

proc GetDC            (h HANDLE) -> HDC #foreign
proc SetPixelFormat   (hdc HDC, pixel_format i32, pfd ^PIXELFORMATDESCRIPTOR ) -> BOOL #foreign #dll_import
proc ChoosePixelFormat(hdc HDC, pfd ^PIXELFORMATDESCRIPTOR) -> i32 #foreign #dll_import
proc SwapBuffers      (hdc HDC) -> BOOL #foreign #dll_import
proc ReleaseDC        (wnd HWND, hdc HDC) -> i32 #foreign #dll_import

const (
	WGL_CONTEXT_MAJOR_VERSION_ARB             = 0x2091;
	WGL_CONTEXT_MINOR_VERSION_ARB             = 0x2092;
	WGL_CONTEXT_PROFILE_MASK_ARB              = 0x9126;
	WGL_CONTEXT_CORE_PROFILE_BIT_ARB          = 0x0001;
	WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x0002;
)

proc wglCreateContext (hdc HDC) -> HGLRC #foreign #dll_import
proc wglMakeCurrent   (hdc HDC, hglrc HGLRC) -> BOOL #foreign #dll_import
proc wglGetProcAddress(c_str ^u8) -> PROC #foreign #dll_import
proc wglDeleteContext (hglrc HGLRC) -> BOOL #foreign #dll_import



proc GetKeyState     (v_key i32) -> i16 #foreign #dll_import
proc GetAsyncKeyState(v_key i32) -> i16 #foreign #dll_import

proc is_key_down(key i32) -> bool #inline { return GetAsyncKeyState(key) < 0; }

const (
	KEY_LBUTTON    = 0x01;
	KEY_RBUTTON    = 0x02;
	KEY_CANCEL     = 0x03;
	KEY_MBUTTON    = 0x04;

	KEY_BACK       = 0x08;
	KEY_TAB        = 0x09;

	KEY_CLEAR      = 0x0C;
	KEY_RETURN     = 0x0D;

	KEY_SHIFT      = 0x10;
	KEY_CONTROL    = 0x11;
	KEY_MENU       = 0x12;
	KEY_PAUSE      = 0x13;
	KEY_CAPITAL    = 0x14;

	KEY_KANA       = 0x15;
	KEY_HANGEUL    = 0x15;
	KEY_HANGUL     = 0x15;
	KEY_JUNJA      = 0x17;
	KEY_FINAL      = 0x18;
	KEY_HANJA      = 0x19;
	KEY_KANJI      = 0x19;

	KEY_ESCAPE     = 0x1B;

	KEY_CONVERT    = 0x1C;
	KEY_NONCONVERT = 0x1D;
	KEY_ACCEPT     = 0x1E;
	KEY_MODECHANGE = 0x1F;

	KEY_SPACE      = 0x20;
	KEY_PRIOR      = 0x21;
	KEY_NEXT       = 0x22;
	KEY_END        = 0x23;
	KEY_HOME       = 0x24;
	KEY_LEFT       = 0x25;
	KEY_UP         = 0x26;
	KEY_RIGHT      = 0x27;
	KEY_DOWN       = 0x28;
	KEY_SELECT     = 0x29;
	KEY_PRINT      = 0x2A;
	KEY_EXECUTE    = 0x2B;
	KEY_SNAPSHOT   = 0x2C;
	KEY_INSERT     = 0x2D;
	KEY_DELETE     = 0x2E;
	KEY_HELP       = 0x2F;

	KEY_NUM0 = '0';
	KEY_NUM1 = '1';
	KEY_NUM2 = '2';
	KEY_NUM3 = '3';
	KEY_NUM4 = '4';
	KEY_NUM5 = '5';
	KEY_NUM6 = '6';
	KEY_NUM7 = '7';
	KEY_NUM8 = '8';
	KEY_NUM9 = '9';

	KEY_A = 'A';
	KEY_B = 'B';
	KEY_C = 'C';
	KEY_D = 'D';
	KEY_E = 'E';
	KEY_F = 'F';
	KEY_G = 'G';
	KEY_H = 'H';
	KEY_I = 'I';
	KEY_J = 'J';
	KEY_K = 'K';
	KEY_L = 'L';
	KEY_M = 'M';
	KEY_N = 'N';
	KEY_O = 'O';
	KEY_P = 'P';
	KEY_Q = 'Q';
	KEY_R = 'R';
	KEY_S = 'S';
	KEY_T = 'T';
	KEY_U = 'U';
	KEY_V = 'V';
	KEY_W = 'W';
	KEY_X = 'X';
	KEY_Y = 'Y';
	KEY_Z = 'Z';

	KEY_LWIN       = 0x5B;
	KEY_RWIN       = 0x5C;
	KEY_APPS       = 0x5D;

	KEY_NUMPAD0    = 0x60;
	KEY_NUMPAD1    = 0x61;
	KEY_NUMPAD2    = 0x62;
	KEY_NUMPAD3    = 0x63;
	KEY_NUMPAD4    = 0x64;
	KEY_NUMPAD5    = 0x65;
	KEY_NUMPAD6    = 0x66;
	KEY_NUMPAD7    = 0x67;
	KEY_NUMPAD8    = 0x68;
	KEY_NUMPAD9    = 0x69;
	KEY_MULTIPLY   = 0x6A;
	KEY_ADD        = 0x6B;
	KEY_SEPARATOR  = 0x6C;
	KEY_SUBTRACT   = 0x6D;
	KEY_DECIMAL    = 0x6E;
	KEY_DIVIDE     = 0x6F;
	KEY_F1         = 0x70;
	KEY_F2         = 0x71;
	KEY_F3         = 0x72;
	KEY_F4         = 0x73;
	KEY_F5         = 0x74;
	KEY_F6         = 0x75;
	KEY_F7         = 0x76;
	KEY_F8         = 0x77;
	KEY_F9         = 0x78;
	KEY_F10        = 0x79;
	KEY_F11        = 0x7A;
	KEY_F12        = 0x7B;
	KEY_F13        = 0x7C;
	KEY_F14        = 0x7D;
	KEY_F15        = 0x7E;
	KEY_F16        = 0x7F;
	KEY_F17        = 0x80;
	KEY_F18        = 0x81;
	KEY_F19        = 0x82;
	KEY_F20        = 0x83;
	KEY_F21        = 0x84;
	KEY_F22        = 0x85;
	KEY_F23        = 0x86;
	KEY_F24        = 0x87;

	KEY_NUMLOCK    = 0x90;
	KEY_SCROLL     = 0x91;

	KEY_LSHIFT     = 0xA0;
	KEY_RSHIFT     = 0xA1;
	KEY_LCONTROL   = 0xA2;
	KEY_RCONTROL   = 0xA3;
	KEY_LMENU      = 0xA4;
	KEY_RMENU      = 0xA5;
	KEY_PROCESSKEY = 0xE5;
	KEY_ATTN       = 0xF6;
	KEY_CRSEL      = 0xF7;
	KEY_EXSEL      = 0xF8;
	KEY_EREOF      = 0xF9;
	KEY_PLAY       = 0xFA;
	KEY_ZOOM       = 0xFB;
	KEY_NONAME     = 0xFC;
	KEY_PA1        = 0xFD;
	KEY_OEM_CLEAR  = 0xFE;
)

