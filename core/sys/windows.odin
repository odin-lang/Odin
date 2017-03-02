#foreign_system_library "kernel32.lib" when ODIN_OS == "windows";
#foreign_system_library "user32.lib"   when ODIN_OS == "windows";
#foreign_system_library "gdi32.lib"    when ODIN_OS == "windows";
#foreign_system_library "winmm.lib"    when ODIN_OS == "windows";

HANDLE    :: rawptr;
HWND      :: HANDLE;
HDC       :: HANDLE;
HINSTANCE :: HANDLE;
HICON     :: HANDLE;
HCURSOR   :: HANDLE;
HMENU     :: HANDLE;
HBRUSH    :: HANDLE;
HGDIOBJ   :: HANDLE;
HMODULE   :: HANDLE;
WPARAM    :: uint;
LPARAM    :: int;
LRESULT   :: int;
ATOM      :: i16;
BOOL      :: i32;
WNDPROC   :: #type proc(HWND, u32, WPARAM, LPARAM) -> LRESULT #cc_c;


INVALID_HANDLE_VALUE :: cast(HANDLE)~cast(int)0;

FALSE: BOOL : 0;
TRUE:  BOOL : 1;

CS_VREDRAW    :: 0x0001;
CS_HREDRAW    :: 0x0002;
CS_OWNDC      :: 0x0020;
CW_USEDEFAULT :: -0x80000000;

WS_OVERLAPPED       :: 0;
WS_MAXIMIZEBOX      :: 0x00010000;
WS_MINIMIZEBOX      :: 0x00020000;
WS_THICKFRAME       :: 0x00040000;
WS_SYSMENU          :: 0x00080000;
WS_CAPTION          :: 0x00C00000;
WS_VISIBLE          :: 0x10000000;
WS_OVERLAPPEDWINDOW :: WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;

WM_DESTROY           :: 0x0002;
WM_SIZE	             :: 0x0005;
WM_CLOSE             :: 0x0010;
WM_ACTIVATEAPP       :: 0x001C;
WM_QUIT              :: 0x0012;
WM_KEYDOWN           :: 0x0100;
WM_KEYUP             :: 0x0101;
WM_SIZING            :: 0x0214;
WM_MOUSEWHEEL        :: 0x020A;
WM_SYSKEYDOWN        :: 0x0104;
WM_WINDOWPOSCHANGED  :: 0x0047;
WM_SETCURSOR         :: 0x0020;
WM_CHAR              :: 0x0102;

PM_REMOVE :: 1;

COLOR_BACKGROUND :: cast(HBRUSH)(cast(int)1);
BLACK_BRUSH :: 4;

SM_CXSCREEN :: 0;
SM_CYSCREEN :: 1;

SW_SHOW :: 5;


POINT :: struct #ordered {
	x, y: i32,
}

WNDCLASSEXA :: struct #ordered {
	size, style:           u32,
	wnd_proc:              WNDPROC,
	cls_extra, wnd_extra:  i32,
	instance:              HINSTANCE,
	icon:                  HICON,
	cursor:                HCURSOR,
	background:            HBRUSH,
	menu_name, class_name: ^u8,
	sm:                    HICON,
}

MSG :: struct #ordered {
	hwnd:    HWND,
	message: u32,
	wparam:  WPARAM,
	lparam:  LPARAM,
	time:    u32,
	pt:      POINT,
}

RECT :: struct #ordered {
	left:   i32,
	top:    i32,
	right:  i32,
	bottom: i32,
}

FILETIME :: struct #ordered {
	lo, hi: u32,
}

SYSTEMTIME :: struct #ordered {
	year, month: u16,
	day_of_week, day: u16,
	hour, minute, second, millisecond: u16,
}

BY_HANDLE_FILE_INFORMATION :: struct #ordered {
	file_attributes:      u32,
	creation_time,
	last_access_time,
	last_write_time:      FILETIME,
	volume_serial_number,
	file_size_high,
	file_size_low,
	number_of_links,
	file_index_high,
	file_index_low:       u32,
}

FILE_ATTRIBUTE_DATA :: struct #ordered {
	file_attributes:  u32,
	creation_time,
	last_access_time,
	last_write_time:  FILETIME,
	file_size_high,
	file_size_low:    u32,
}

GET_FILEEX_INFO_LEVELS :: i32;

GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0;
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1;

GetLastError     :: proc() -> i32                            #foreign kernel32;
ExitProcess      :: proc(exit_code: u32)                     #foreign kernel32;
GetDesktopWindow :: proc() -> HWND                           #foreign user32;
GetCursorPos     :: proc(p: ^POINT) -> i32                   #foreign user32;
ScreenToClient   :: proc(h: HWND, p: ^POINT) -> i32          #foreign user32;
GetModuleHandleA :: proc(module_name: ^u8) -> HINSTANCE      #foreign kernel32;
GetStockObject   :: proc(fn_object: i32) -> HGDIOBJ          #foreign gdi32;
PostQuitMessage  :: proc(exit_code: i32)                     #foreign user32;
SetWindowTextA   :: proc(hwnd: HWND, c_string: ^u8) -> BOOL  #foreign user32;

QueryPerformanceFrequency :: proc(result: ^i64) -> i32 #foreign kernel32;
QueryPerformanceCounter   :: proc(result: ^i64) -> i32 #foreign kernel32;

Sleep :: proc(ms: i32) -> i32 #foreign kernel32;

OutputDebugStringA :: proc(c_str: ^u8) #foreign kernel32;


RegisterClassExA :: proc(wc: ^WNDCLASSEXA) -> ATOM #foreign user32;
CreateWindowExA  :: proc(ex_style: u32,
                         class_name, title: ^u8,
                         style: u32,
                         x, y, w, h: i32,
                         parent: HWND, menu: HMENU, instance: HINSTANCE,
                         param: rawptr) -> HWND #foreign user32;

ShowWindow       :: proc(hwnd: HWND, cmd_show: i32) -> BOOL #foreign user32;
TranslateMessage :: proc(msg: ^MSG) -> BOOL                 #foreign user32;
DispatchMessageA :: proc(msg: ^MSG) -> LRESULT              #foreign user32;
UpdateWindow     :: proc(hwnd: HWND) -> BOOL                #foreign user32;
PeekMessageA     :: proc(msg: ^MSG, hwnd: HWND,
                         msg_filter_min, msg_filter_max, remove_msg: u32) -> BOOL #foreign user32;

DefWindowProcA :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #foreign user32;

AdjustWindowRect :: proc(rect: ^RECT, style: u32, menu: BOOL) -> BOOL #foreign user32;
GetActiveWindow  :: proc() -> HWND #foreign user32;

DestroyWindow       :: proc(wnd: HWND) -> BOOL #foreign user32;
DescribePixelFormat :: proc(dc: HDC, pixel_format: i32, bytes : u32, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 #foreign user32;


GetQueryPerformanceFrequency :: proc() -> i64 {
	r: i64;
	QueryPerformanceFrequency(^r);
	return r;
}

GetCommandLineA    :: proc() -> ^u8 #foreign kernel32;
GetSystemMetrics   :: proc(index: i32) -> i32 #foreign kernel32;
GetCurrentThreadId :: proc() -> u32 #foreign kernel32;

timeGetTime             :: proc() -> u32 #foreign winmm;
GetSystemTimeAsFileTime :: proc(system_time_as_file_time: ^FILETIME) #foreign kernel32;
FileTimeToLocalFileTime :: proc(file_time: ^FILETIME, local_file_time: ^FILETIME) -> BOOL #foreign kernel32;
FileTimeToSystemTime    :: proc(file_time: ^FILETIME, system_time: ^SYSTEMTIME) -> BOOL #foreign kernel32;
SystemTimeToFileTime    :: proc(system_time: ^SYSTEMTIME, file_time: ^FILETIME) -> BOOL #foreign kernel32;

// File Stuff

CloseHandle  :: proc(h: HANDLE) -> i32 #foreign kernel32;
GetStdHandle :: proc(h: i32) -> HANDLE #foreign kernel32;
CreateFileA  :: proc(filename: ^u8, desired_access, share_mode: u32,
                     security: rawptr,
                     creation, flags_and_attribs: u32, template_file: HANDLE) -> HANDLE #foreign kernel32;
ReadFile  :: proc(h: HANDLE, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> BOOL #foreign kernel32;
WriteFile :: proc(h: HANDLE, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> BOOL #foreign kernel32;

GetFileSizeEx              :: proc(file_handle: HANDLE, file_size: ^i64) -> BOOL #foreign kernel32;
GetFileAttributesExA       :: proc(filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> BOOL #foreign kernel32;
GetFileInformationByHandle :: proc(file_handle: HANDLE, file_info: ^BY_HANDLE_FILE_INFORMATION) -> BOOL #foreign kernel32;

GetFileType    :: proc(file_handle: HANDLE) -> u32 #foreign kernel32;
SetFilePointer :: proc(file_handle: HANDLE, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #foreign kernel32;

SetHandleInformation :: proc(obj: HANDLE, mask, flags: u32) -> BOOL #foreign kernel32;

HANDLE_FLAG_INHERIT :: 1;
HANDLE_FLAG_PROTECT_FROM_CLOSE :: 2;


FILE_BEGIN   :: 0;
FILE_CURRENT :: 1;
FILE_END     :: 2;

FILE_SHARE_READ      :: 0x00000001;
FILE_SHARE_WRITE     :: 0x00000002;
FILE_SHARE_DELETE    :: 0x00000004;
FILE_GENERIC_ALL     :: 0x10000000;
FILE_GENERIC_EXECUTE :: 0x20000000;
FILE_GENERIC_WRITE   :: 0x40000000;
FILE_GENERIC_READ    :: 0x80000000;

FILE_APPEND_DATA :: 0x0004;

STD_INPUT_HANDLE  :: -10;
STD_OUTPUT_HANDLE :: -11;
STD_ERROR_HANDLE  :: -12;

CREATE_NEW        :: 1;
CREATE_ALWAYS     :: 2;
OPEN_EXISTING     :: 3;
OPEN_ALWAYS       :: 4;
TRUNCATE_EXISTING :: 5;

FILE_ATTRIBUTE_READONLY             :: 0x00000001;
FILE_ATTRIBUTE_HIDDEN               :: 0x00000002;
FILE_ATTRIBUTE_SYSTEM               :: 0x00000004;
FILE_ATTRIBUTE_DIRECTORY            :: 0x00000010;
FILE_ATTRIBUTE_ARCHIVE              :: 0x00000020;
FILE_ATTRIBUTE_DEVICE               :: 0x00000040;
FILE_ATTRIBUTE_NORMAL               :: 0x00000080;
FILE_ATTRIBUTE_TEMPORARY            :: 0x00000100;
FILE_ATTRIBUTE_SPARSE_FILE          :: 0x00000200;
FILE_ATTRIBUTE_REPARSE_POINT        :: 0x00000400;
FILE_ATTRIBUTE_COMPRESSED           :: 0x00000800;
FILE_ATTRIBUTE_OFFLINE              :: 0x00001000;
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  :: 0x00002000;
FILE_ATTRIBUTE_ENCRYPTED            :: 0x00004000;

FILE_TYPE_DISK :: 0x0001;
FILE_TYPE_CHAR :: 0x0002;
FILE_TYPE_PIPE :: 0x0003;

INVALID_SET_FILE_POINTER :: ~cast(u32)0;




HeapAlloc      :: proc (h: HANDLE, flags: u32, bytes: int) -> rawptr                 #foreign kernel32;
HeapReAlloc    :: proc (h: HANDLE, flags: u32, memory: rawptr, bytes: int) -> rawptr #foreign kernel32;
HeapFree       :: proc (h: HANDLE, flags: u32, memory: rawptr) -> BOOL               #foreign kernel32;
GetProcessHeap :: proc () -> HANDLE #foreign kernel32;


HEAP_ZERO_MEMORY :: 0x00000008;

// Synchronization

SECURITY_ATTRIBUTES :: struct #ordered {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      BOOL,
}

INFINITE :: 0xffffffff;

CreateSemaphoreA    :: proc(attributes: ^SECURITY_ATTRIBUTES, initial_count, maximum_count: i32, name: ^byte) -> HANDLE #foreign kernel32;
ReleaseSemaphore    :: proc(semaphore: HANDLE, release_count: i32, previous_count: ^i32) -> BOOL #foreign kernel32;
WaitForSingleObject :: proc(handle: HANDLE, milliseconds: u32) -> u32 #foreign kernel32;


InterlockedCompareExchange :: proc(dst: ^i32, exchange, comparand: i32) -> i32 #foreign kernel32;
InterlockedExchange        :: proc(dst: ^i32, desired: i32) -> i32 #foreign kernel32;
InterlockedExchangeAdd     :: proc(dst: ^i32, desired: i32) -> i32 #foreign kernel32;
InterlockedAnd             :: proc(dst: ^i32, desired: i32) -> i32 #foreign kernel32;
InterlockedOr              :: proc(dst: ^i32, desired: i32) -> i32 #foreign kernel32;

InterlockedCompareExchange64 :: proc(dst: ^i64, exchange, comparand: i64) -> i64 #foreign kernel32;
InterlockedExchange64        :: proc(dst: ^i64, desired: i64) -> i64 #foreign kernel32;
InterlockedExchangeAdd64     :: proc(dst: ^i64, desired: i64) -> i64 #foreign kernel32;
InterlockedAnd64             :: proc(dst: ^i64, desired: i64) -> i64 #foreign kernel32;
InterlockedOr64              :: proc(dst: ^i64, desired: i64) -> i64 #foreign kernel32;

mm_pause         :: proc() #foreign kernel32 "_mm_pause";
ReadWriteBarrier :: proc() #foreign kernel32;
WriteBarrier     :: proc() #foreign kernel32;
ReadBarrier      :: proc() #foreign kernel32;





HMONITOR :: HANDLE;

GWL_STYLE     :: -16;

HWND_TOP :: cast(HWND)cast(uint)0;

MONITOR_DEFAULTTONULL    :: 0x00000000;
MONITOR_DEFAULTTOPRIMARY :: 0x00000001;
MONITOR_DEFAULTTONEAREST :: 0x00000002;

SWP_FRAMECHANGED  :: 0x0020;
SWP_NOOWNERZORDER :: 0x0200;
SWP_NOZORDER      :: 0x0004;
SWP_NOSIZE        :: 0x0001;
SWP_NOMOVE        :: 0x0002;


MONITORINFO :: struct #ordered {
	size:      u32,
	monitor:   RECT,
	work:      RECT,
	flags:     u32,
}

WINDOWPLACEMENT :: struct #ordered {
	length:     u32,
	flags:      u32,
	show_cmd:   u32,
	min_pos:    POINT,
	max_pos:    POINT,
	normal_pos: RECT,
}

GetMonitorInfoA    :: proc(monitor: HMONITOR, mi: ^MONITORINFO) -> BOOL #foreign user32;
MonitorFromWindow  :: proc(wnd: HWND, flags : u32) -> HMONITOR #foreign user32;

SetWindowPos       :: proc(wnd: HWND, wndInsertAfter: HWND, x, y, width, height: i32, flags: u32) #foreign user32 "SetWindowPos";

GetWindowPlacement :: proc(wnd: HWND, wndpl: ^WINDOWPLACEMENT) -> BOOL #foreign user32;
SetWindowPlacement :: proc(wnd: HWND, wndpl: ^WINDOWPLACEMENT) -> BOOL #foreign user32;

GetWindowLongPtrA :: proc(wnd: HWND, index: i32) -> i64 #foreign user32;
SetWindowLongPtrA :: proc(wnd: HWND, index: i32, new: i64) -> i64 #foreign user32;

GetWindowText :: proc(wnd: HWND, str: ^byte, maxCount: i32) -> i32 #foreign user32;

HIWORD :: proc(wParam: WPARAM) -> u16 { return cast(u16)((cast(u32)wParam >> 16) & 0xffff); }
HIWORD :: proc(lParam: LPARAM) -> u16 { return cast(u16)((cast(u32)lParam >> 16) & 0xffff); }
LOWORD :: proc(wParam: WPARAM) -> u16 { return cast(u16)wParam; }
LOWORD :: proc(lParam: LPARAM) -> u16 { return cast(u16)lParam; }










BITMAPINFOHEADER :: struct #ordered {
	size:              u32,
	width, height:     i32,
	planes, bit_count: i16,
	compression:       u32,
	size_image:        u32,
	x_pels_per_meter:  i32,
	y_pels_per_meter:  i32,
	clr_used:          u32,
	clr_important:     u32,
}
BITMAPINFO :: struct #ordered {
	using header: BITMAPINFOHEADER,
	colors:       [1]RGBQUAD,
}


RGBQUAD :: struct #ordered { blue, green, red, reserved: byte }

BI_RGB         :: 0;
DIB_RGB_COLORS :: 0x00;
SRCCOPY: u32    : 0x00cc0020;


StretchDIBits :: proc (hdc: HDC,
                       x_dst, y_dst, width_dst, height_dst: i32,
                       x_src, y_src, width_src, header_src: i32,
                       bits: rawptr, bits_info: ^BITMAPINFO,
                       usage: u32,
                       rop: u32) -> i32 #foreign gdi32;



LoadLibraryA   :: proc (c_str: ^u8) -> HMODULE #foreign kernel32;
FreeLibrary    :: proc (h: HMODULE) #foreign kernel32;
GetProcAddress :: proc (h: HMODULE, c_str: ^u8) -> PROC #foreign kernel32;

GetClientRect :: proc(hwnd: HWND, rect: ^RECT) -> BOOL #foreign user32;

// Windows OpenGL
PFD_TYPE_RGBA             :: 0;
PFD_TYPE_COLORINDEX       :: 1;
PFD_MAIN_PLANE            :: 0;
PFD_OVERLAY_PLANE         :: 1;
PFD_UNDERLAY_PLANE        :: -1;
PFD_DOUBLEBUFFER          :: 1;
PFD_STEREO                :: 2;
PFD_DRAW_TO_WINDOW        :: 4;
PFD_DRAW_TO_BITMAP        :: 8;
PFD_SUPPORT_GDI           :: 16;
PFD_SUPPORT_OPENGL        :: 32;
PFD_GENERIC_FORMAT        :: 64;
PFD_NEED_PALETTE          :: 128;
PFD_NEED_SYSTEM_PALETTE   :: 0x00000100;
PFD_SWAP_EXCHANGE         :: 0x00000200;
PFD_SWAP_COPY             :: 0x00000400;
PFD_SWAP_LAYER_BUFFERS    :: 0x00000800;
PFD_GENERIC_ACCELERATED   :: 0x00001000;
PFD_DEPTH_DONTCARE        :: 0x20000000;
PFD_DOUBLEBUFFER_DONTCARE :: 0x40000000;
PFD_STEREO_DONTCARE       :: 0x80000000;


PIXELFORMATDESCRIPTOR :: struct #ordered {
	size,
	version,
	flags: u32,

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
	reserved: byte,

	layer_mask,
	visible_mask,
	damage_mask: u32,
}

GetDC             :: proc(h: HWND) -> HDC #foreign user32;
SetPixelFormat    :: proc(hdc: HDC, pixel_format: i32, pfd: ^PIXELFORMATDESCRIPTOR) -> BOOL #foreign gdi32;
ChoosePixelFormat :: proc(hdc: HDC, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 #foreign gdi32;
SwapBuffers       :: proc(hdc: HDC) -> BOOL #foreign gdi32;
ReleaseDC         :: proc(wnd: HWND, hdc: HDC) -> i32 #foreign user32;


PROC  :: #type proc() #cc_c;


GetKeyState      :: proc(v_key: i32) -> i16 #foreign user32;
GetAsyncKeyState :: proc(v_key: i32) -> i16 #foreign user32;

is_key_down :: proc(key: Key_Code) -> bool #inline { return GetAsyncKeyState(cast(i32)key) < 0; }

Key_Code :: enum i32 {
	LBUTTON    = 0x01,
	RBUTTON    = 0x02,
	CANCEL     = 0x03,
	MBUTTON    = 0x04,
	BACK       = 0x08,
	TAB        = 0x09,
	CLEAR      = 0x0C,
	RETURN     = 0x0D,

	SHIFT      = 0x10,
	CONTROL    = 0x11,
	MENU       = 0x12,
	PAUSE      = 0x13,
	CAPITAL    = 0x14,
	KANA       = 0x15,
	HANGEUL    = 0x15,
	HANGUL     = 0x15,
	JUNJA      = 0x17,
	FINAL      = 0x18,
	HANJA      = 0x19,
	KANJI      = 0x19,
	ESCAPE     = 0x1B,
	CONVERT    = 0x1C,
	NONCONVERT = 0x1D,
	ACCEPT     = 0x1E,
	MODECHANGE = 0x1F,
	SPACE      = 0x20,
	PRIOR      = 0x21,
	NEXT       = 0x22,
	END        = 0x23,
	HOME       = 0x24,
	LEFT       = 0x25,
	UP         = 0x26,
	RIGHT      = 0x27,
	DOWN       = 0x28,
	SELECT     = 0x29,
	PRINT      = 0x2A,
	EXECUTE    = 0x2B,
	SNAPSHOT   = 0x2C,
	INSERT     = 0x2D,
	DELETE     = 0x2E,
	HELP       = 0x2F,

	NUM0 = '0',
	NUM1 = '1',
	NUM2 = '2',
	NUM3 = '3',
	NUM4 = '4',
	NUM5 = '5',
	NUM6 = '6',
	NUM7 = '7',
	NUM8 = '8',
	NUM9 = '9',
	A = 'A',
	B = 'B',
	C = 'C',
	D = 'D',
	E = 'E',
	F = 'F',
	G = 'G',
	H = 'H',
	I = 'I',
	J = 'J',
	K = 'K',
	L = 'L',
	M = 'M',
	N = 'N',
	O = 'O',
	P = 'P',
	Q = 'Q',
	R = 'R',
	S = 'S',
	T = 'T',
	U = 'U',
	V = 'V',
	W = 'W',
	X = 'X',
	Y = 'Y',
	Z = 'Z',

	LWIN       = 0x5B,
	RWIN       = 0x5C,
	APPS       = 0x5D,

	NUMPAD0    = 0x60,
	NUMPAD1    = 0x61,
	NUMPAD2    = 0x62,
	NUMPAD3    = 0x63,
	NUMPAD4    = 0x64,
	NUMPAD5    = 0x65,
	NUMPAD6    = 0x66,
	NUMPAD7    = 0x67,
	NUMPAD8    = 0x68,
	NUMPAD9    = 0x69,
	MULTIPLY   = 0x6A,
	ADD        = 0x6B,
	SEPARATOR  = 0x6C,
	SUBTRACT   = 0x6D,
	DECIMAL    = 0x6E,
	DIVIDE     = 0x6F,

	F1         = 0x70,
	F2         = 0x71,
	F3         = 0x72,
	F4         = 0x73,
	F5         = 0x74,
	F6         = 0x75,
	F7         = 0x76,
	F8         = 0x77,
	F9         = 0x78,
	F10        = 0x79,
	F11        = 0x7A,
	F12        = 0x7B,
	F13        = 0x7C,
	F14        = 0x7D,
	F15        = 0x7E,
	F16        = 0x7F,
	F17        = 0x80,
	F18        = 0x81,
	F19        = 0x82,
	F20        = 0x83,
	F21        = 0x84,
	F22        = 0x85,
	F23        = 0x86,
	F24        = 0x87,

	NUMLOCK    = 0x90,
	SCROLL     = 0x91,
	LSHIFT     = 0xA0,
	RSHIFT     = 0xA1,
	LCONTROL   = 0xA2,
	RCONTROL   = 0xA3,
	LMENU      = 0xA4,
	RMENU      = 0xA5,
	PROCESSKEY = 0xE5,
	ATTN       = 0xF6,
	CRSEL      = 0xF7,
	EXSEL      = 0xF8,
	EREOF      = 0xF9,
	PLAY       = 0xFA,
	ZOOM       = 0xFB,
	NONAME     = 0xFC,
	PA1        = 0xFD,
	OEM_CLEAR  = 0xFE,
}

