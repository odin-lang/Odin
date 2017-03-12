#foreign_system_library "kernel32.lib" when ODIN_OS == "windows";
#foreign_system_library "user32.lib"   when ODIN_OS == "windows";
#foreign_system_library "gdi32.lib"    when ODIN_OS == "windows";
#foreign_system_library "winmm.lib"    when ODIN_OS == "windows";

Handle    :: rawptr;
Hwnd      :: Handle;
Hdc       :: Handle;
Hinstance :: Handle;
Hicon     :: Handle;
Hcursor   :: Handle;
Hmenu     :: Handle;
Hbrush    :: Handle;
Hgdiobj   :: Handle;
Hmodule   :: Handle;
Wparam    :: uint;
Lparam    :: int;
Lresult   :: int;
Bool      :: i32;
Wnd_Proc  :: #type proc(Hwnd, u32, Wparam, Lparam) -> Lresult #cc_c;


INVALID_HANDLE :: cast(Handle)~cast(int)0;

FALSE: Bool : 0;
TRUE:  Bool : 1;

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

COLOR_BACKGROUND :: cast(Hbrush)(cast(int)1);
BLACK_BRUSH :: 4;

SM_CXSCREEN :: 0;
SM_CYSCREEN :: 1;

SW_SHOW :: 5;


Point :: struct #ordered {
	x, y: i32,
}

WndClassExA :: struct #ordered {
	size, style:           u32,
	wnd_proc:              Wnd_Proc,
	cls_extra, wnd_extra:  i32,
	instance:              Hinstance,
	icon:                  Hicon,
	cursor:                Hcursor,
	background:            Hbrush,
	menu_name, class_name: ^u8,
	sm:                    Hicon,
}

Msg :: struct #ordered {
	hwnd:    Hwnd,
	message: u32,
	wparam:  Wparam,
	lparam:  Lparam,
	time:    u32,
	pt:      Point,
}

Rect :: struct #ordered {
	left:   i32,
	top:    i32,
	right:  i32,
	bottom: i32,
}

Filetime :: struct #ordered {
	lo, hi: u32,
}

Systemtime :: struct #ordered {
	year, month: u16,
	day_of_week, day: u16,
	hour, minute, second, millisecond: u16,
}

By_Handle_File_Information :: struct #ordered {
	file_attributes:      u32,
	creation_time,
	last_access_time,
	last_write_time:      Filetime,
	volume_serial_number,
	file_size_high,
	file_size_low,
	number_of_links,
	file_index_high,
	file_index_low:       u32,
}

File_Attribute_Data :: struct #ordered {
	file_attributes:  u32,
	creation_time,
	last_access_time,
	last_write_time:  Filetime,
	file_size_high,
	file_size_low:    u32,
}

GET_FILEEX_INFO_LEVELS :: i32;

GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0;
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1;

GetLastError     :: proc() -> i32                            #foreign kernel32;
ExitProcess      :: proc(exit_code: u32)                     #foreign kernel32;
GetDesktopWindow :: proc() -> Hwnd                           #foreign user32;
GetCursorPos     :: proc(p: ^Point) -> i32                   #foreign user32;
ScreenToClient   :: proc(h: Hwnd, p: ^Point) -> i32          #foreign user32;
GetModuleHandleA :: proc(module_name: ^u8) -> Hinstance      #foreign kernel32;
GetStockObject   :: proc(fn_object: i32) -> Hgdiobj          #foreign gdi32;
PostQuitMessage  :: proc(exit_code: i32)                     #foreign user32;
SetWindowTextA   :: proc(hwnd: Hwnd, c_string: ^u8) -> Bool  #foreign user32;

QueryPerformanceFrequency :: proc(result: ^i64) -> i32 #foreign kernel32;
QueryPerformanceCounter   :: proc(result: ^i64) -> i32 #foreign kernel32;

Sleep :: proc(ms: i32) -> i32 #foreign kernel32;

OutputDebugStringA :: proc(c_str: ^u8) #foreign kernel32;


RegisterClassExA :: proc(wc: ^WndClassExA) -> i16 #foreign user32;
CreateWindowExA  :: proc(ex_style: u32,
                         class_name, title: ^u8,
                         style: u32,
                         x, y, w, h: i32,
                         parent: Hwnd, menu: Hmenu, instance: Hinstance,
                         param: rawptr) -> Hwnd #foreign user32;

ShowWindow       :: proc(hwnd: Hwnd, cmd_show: i32) -> Bool #foreign user32;
TranslateMessage :: proc(msg: ^Msg) -> Bool                 #foreign user32;
DispatchMessageA :: proc(msg: ^Msg) -> Lresult              #foreign user32;
UpdateWindow     :: proc(hwnd: Hwnd) -> Bool                #foreign user32;
PeekMessageA     :: proc(msg: ^Msg, hwnd: Hwnd,
                         msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool #foreign user32;

DefWindowProcA :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult #foreign user32;

AdjustWindowRect :: proc(rect: ^Rect, style: u32, menu: Bool) -> Bool #foreign user32;
GetActiveWindow  :: proc() -> Hwnd #foreign user32;

DestroyWindow       :: proc(wnd: Hwnd) -> Bool #foreign user32;
DescribePixelFormat :: proc(dc: Hdc, pixel_format: i32, bytes : u32, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 #foreign user32;


GetQueryPerformanceFrequency :: proc() -> i64 {
	r: i64;
	QueryPerformanceFrequency(^r);
	return r;
}

GetCommandLineA    :: proc() -> ^u8 #foreign kernel32;
GetSystemMetrics   :: proc(index: i32) -> i32 #foreign kernel32;
GetCurrentThreadId :: proc() -> u32 #foreign kernel32;

timeGetTime             :: proc() -> u32 #foreign winmm;
GetSystemTimeAsFileTime :: proc(system_time_as_file_time: ^Filetime) #foreign kernel32;
FileTimeToLocalFileTime :: proc(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool #foreign kernel32;
FileTimeToSystemTime    :: proc(file_time: ^Filetime, system_time: ^Systemtime) -> Bool #foreign kernel32;
SystemTimeToFileTime    :: proc(system_time: ^Systemtime, file_time: ^Filetime) -> Bool #foreign kernel32;

// File Stuff

CloseHandle  :: proc(h: Handle) -> i32 #foreign kernel32;
GetStdHandle :: proc(h: i32) -> Handle #foreign kernel32;
CreateFileA  :: proc(filename: ^u8, desired_access, share_mode: u32,
                     security: rawptr,
                     creation, flags_and_attribs: u32, template_file: Handle) -> Handle #foreign kernel32;
ReadFile  :: proc(h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool #foreign kernel32;
WriteFile :: proc(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool #foreign kernel32;

GetFileSizeEx              :: proc(file_handle: Handle, file_size: ^i64) -> Bool #foreign kernel32;
GetFileAttributesExA       :: proc(filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool #foreign kernel32;
GetFileInformationByHandle :: proc(file_handle: Handle, file_info: ^By_Handle_File_Information) -> Bool #foreign kernel32;

GetFileType    :: proc(file_handle: Handle) -> u32 #foreign kernel32;
SetFilePointer :: proc(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #foreign kernel32;

SetHandleInformation :: proc(obj: Handle, mask, flags: u32) -> Bool #foreign kernel32;

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
FILE_ATTRIBUTE_DIRectORY            :: 0x00000010;
FILE_ATTRIBUTE_ARCHIVE              :: 0x00000020;
FILE_ATTRIBUTE_DEVICE               :: 0x00000040;
FILE_ATTRIBUTE_NORMAL               :: 0x00000080;
FILE_ATTRIBUTE_TEMPORARY            :: 0x00000100;
FILE_ATTRIBUTE_SPARSE_FILE          :: 0x00000200;
FILE_ATTRIBUTE_REPARSE_Point        :: 0x00000400;
FILE_ATTRIBUTE_COMPRESSED           :: 0x00000800;
FILE_ATTRIBUTE_OFFLINE              :: 0x00001000;
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  :: 0x00002000;
FILE_ATTRIBUTE_ENCRYPTED            :: 0x00004000;

FILE_TYPE_DISK :: 0x0001;
FILE_TYPE_CHAR :: 0x0002;
FILE_TYPE_PIPE :: 0x0003;

INVALID_SET_FILE_POINTER :: ~cast(u32)0;




HeapAlloc      :: proc (h: Handle, flags: u32, bytes: int) -> rawptr                 #foreign kernel32;
HeapReAlloc    :: proc (h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr #foreign kernel32;
HeapFree       :: proc (h: Handle, flags: u32, memory: rawptr) -> Bool               #foreign kernel32;
GetProcessHeap :: proc () -> Handle #foreign kernel32;


HEAP_ZERO_MEMORY :: 0x00000008;

// Synchronization

Security_Attributes :: struct #ordered {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}

INFINITE :: 0xffffffff;

CreateSemaphoreA    :: proc(attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: ^byte) -> Handle #foreign kernel32;
ReleaseSemaphore    :: proc(semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool #foreign kernel32;
WaitForSingleObject :: proc(handle: Handle, milliseconds: u32) -> u32 #foreign kernel32;


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





Hmonitor :: Handle;

GWL_STYLE     :: -16;

Hwnd_TOP :: cast(Hwnd)cast(uint)0;

MONITOR_DEFAULTTONULL    :: 0x00000000;
MONITOR_DEFAULTTOPRIMARY :: 0x00000001;
MONITOR_DEFAULTTONEAREST :: 0x00000002;

SWP_FRAMECHANGED  :: 0x0020;
SWP_NOOWNERZORDER :: 0x0200;
SWP_NOZORDER      :: 0x0004;
SWP_NOSIZE        :: 0x0001;
SWP_NOMOVE        :: 0x0002;


Monitor_Info :: struct #ordered {
	size:      u32,
	monitor:   Rect,
	work:      Rect,
	flags:     u32,
}

Window_Placement :: struct #ordered {
	length:     u32,
	flags:      u32,
	show_cmd:   u32,
	min_pos:    Point,
	max_pos:    Point,
	normal_pos: Rect,
}

GetMonitorInfoA    :: proc(monitor: Hmonitor, mi: ^Monitor_Info) -> Bool #foreign user32;
MonitorFromWindow  :: proc(wnd: Hwnd, flags : u32) -> Hmonitor #foreign user32;

SetWindowPos       :: proc(wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32) #foreign user32 "SetWindowPos";

GetWindowPlacement :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool #foreign user32;
SetWindowPlacement :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool #foreign user32;

GetWindowLongPtrA :: proc(wnd: Hwnd, index: i32) -> i64 #foreign user32;
SetWindowLongPtrA :: proc(wnd: Hwnd, index: i32, new: i64) -> i64 #foreign user32;

GetWindowText :: proc(wnd: Hwnd, str: ^byte, maxCount: i32) -> i32 #foreign user32;

HIWORD :: proc(wParam: Wparam) -> u16 { return cast(u16)((cast(u32)wParam >> 16) & 0xffff); }
HIWORD :: proc(lParam: Lparam) -> u16 { return cast(u16)((cast(u32)lParam >> 16) & 0xffff); }
LOWORD :: proc(wParam: Wparam) -> u16 { return cast(u16)wParam; }
LOWORD :: proc(lParam: Lparam) -> u16 { return cast(u16)lParam; }










Bitmap_Info_Header :: struct #ordered {
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
Bitmap_Info :: struct #ordered {
	using header: Bitmap_Info_Header,
	colors:       [1]Rgb_Quad,
}


Rgb_Quad :: struct #ordered { blue, green, red, reserved: byte }

BI_RGB         :: 0;
DIB_RGB_COLORS :: 0x00;
SRCCOPY: u32    : 0x00cc0020;


StretchDIBits :: proc (hdc: Hdc,
                       x_dst, y_dst, width_dst, height_dst: i32,
                       x_src, y_src, width_src, header_src: i32,
                       bits: rawptr, bits_info: ^Bitmap_Info,
                       usage: u32,
                       rop: u32) -> i32 #foreign gdi32;



LoadLibraryA   :: proc (c_str: ^u8) -> Hmodule #foreign kernel32;
FreeLibrary    :: proc (h: Hmodule) #foreign kernel32;
GetProcAddress :: proc (h: Hmodule, c_str: ^u8) -> Proc #foreign kernel32;

GetClientRect :: proc(hwnd: Hwnd, rect: ^Rect) -> Bool #foreign user32;

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

GetDC             :: proc(h: Hwnd) -> Hdc #foreign user32;
SetPixelFormat    :: proc(hdc: Hdc, pixel_format: i32, pfd: ^PIXELFORMATDESCRIPTOR) -> Bool #foreign gdi32;
ChoosePixelFormat :: proc(hdc: Hdc, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 #foreign gdi32;
SwapBuffers       :: proc(hdc: Hdc) -> Bool #foreign gdi32;
ReleaseDC         :: proc(wnd: Hwnd, hdc: Hdc) -> i32 #foreign user32;


Proc  :: #type proc() #cc_c;


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
	ProcESSKEY = 0xE5,
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

