#foreign_system_library "kernel32.lib" when ODIN_OS == "windows";
#foreign_system_library "user32.lib"   when ODIN_OS == "windows";
#foreign_system_library "gdi32.lib"    when ODIN_OS == "windows";
#foreign_system_library "winmm.lib"    when ODIN_OS == "windows";
#foreign_system_library "shell32.lib"  when ODIN_OS == "windows";

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
WndProc  :: #type proc(Hwnd, u32, Wparam, Lparam) -> Lresult #cc_c;


INVALID_HANDLE :: Handle(~int(0));

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

PM_NOREMOVE :: 0x0000;
PM_REMOVE   :: 0x0001;
PM_NOYIELD  :: 0x0002;

COLOR_BACKGROUND :: Hbrush(int(1));
BLACK_BRUSH :: 4;

SM_CXSCREEN :: 0;
SM_CYSCREEN :: 1;

SW_SHOW :: 5;


Point :: struct #ordered {
	x, y: i32,
}

WndClassExA :: struct #ordered {
	size, style:           u32,
	wndproc:               WndProc,
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

ByHandleFileInformation :: struct #ordered {
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

FileAttributeData :: struct #ordered {
	file_attributes:  u32,
	creation_time,
	last_access_time,
	last_write_time:  Filetime,
	file_size_high,
	file_size_low:    u32,
}

FindData :: struct #ordered {
    file_attributes     : u32,
    creation_time       : Filetime,
    last_access_time    : Filetime,
    last_write_time     : Filetime,
    file_size_high      : u32,
    file_size_low       : u32,
    reserved0           : u32,
    reserved1           : u32,
    file_name           : [MAX_PATH]byte,
    alternate_file_name : [14]byte,
}


GET_FILEEX_INFO_LEVELS :: i32;

GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0;
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1;

get_last_error      :: proc() -> i32                            #foreign kernel32 "GetLastError";
exit_process        :: proc(exit_code: u32)                     #foreign kernel32 "ExitProcess";
get_desktop_window  :: proc() -> Hwnd                           #foreign user32   "GetDesktopWindow";
show_cursor         :: proc(show : Bool)                        #foreign user32   "ShowCursor";
get_cursor_pos      :: proc(p: ^Point) -> i32                   #foreign user32   "GetCursorPos";
screen_to_client    :: proc(h: Hwnd, p: ^Point) -> i32          #foreign user32   "ScreenToClient";
get_module_handle_a :: proc(module_name: ^u8) -> Hinstance      #foreign kernel32 "GetModuleHandleA";
get_stock_object    :: proc(fn_object: i32) -> Hgdiobj          #foreign gdi32    "GetStockObject";
post_quit_message   :: proc(exit_code: i32)                     #foreign user32   "PostQuitMessage";
set_window_text_a   :: proc(hwnd: Hwnd, c_string: ^u8) -> Bool  #foreign user32   "SetWindowTextA";

query_performance_frequency :: proc(result: ^i64) -> i32 #foreign kernel32 "QueryPerformanceFrequency";
query_performance_counter   :: proc(result: ^i64) -> i32 #foreign kernel32 "QueryPerformanceCounter";

sleep :: proc(ms: i32) -> i32 #foreign kernel32 "Sleep";

output_debug_string_a :: proc(c_str: ^u8) #foreign kernel32 "OutputDebugStringA";


register_class_ex_a :: proc(wc: ^WndClassExA) -> i16 #foreign user32 "RegisterClassExA";
create_window_ex_a  :: proc(ex_style: u32,
                            class_name, title: ^u8,
                            style: u32,
                            x, y, w, h: i32,
                            parent: Hwnd, menu: Hmenu, instance: Hinstance,
                            param: rawptr) -> Hwnd #foreign user32 "CreateWindowExA";

show_window        :: proc(hwnd: Hwnd, cmd_show: i32) -> Bool #foreign user32 "ShowWindow";
translate_message  :: proc(msg: ^Msg) -> Bool                 #foreign user32 "TranslateMessage";
dispatch_message_a :: proc(msg: ^Msg) -> Lresult              #foreign user32 "DispatchMessageA";
update_window      :: proc(hwnd: Hwnd) -> Bool                #foreign user32 "UpdateWindow";
get_message_a      :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max : u32) -> Bool #foreign user32 "GetMessageA";
peek_message_a     :: proc(msg: ^Msg, hwnd: Hwnd,
                           msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool #foreign user32 "PeekMessageA";

post_message :: proc(hwnd: Hwnd, msg, wparam, lparam : u32) -> Bool #foreign user32 "PostMessageA";

def_window_proc_a :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult #foreign user32 "DefWindowProcA";

adjust_window_rect :: proc(rect: ^Rect, style: u32, menu: Bool) -> Bool #foreign user32 "AdjustWindowRect";
get_active_window  :: proc() -> Hwnd                                    #foreign user32 "GetActiveWindow";

destroy_window        :: proc(wnd: Hwnd) -> Bool                                                           #foreign user32 "DestroyWindow";
describe_pixel_format :: proc(dc: Hdc, pixel_format: i32, bytes : u32, pfd: ^PixelFormatDescriptor) -> i32 #foreign user32 "DescribePixelFormat";


get_query_performance_frequency :: proc() -> i64 {
	r: i64;
	query_performance_frequency(&r);
	return r;
}

get_command_line_a     :: proc() -> ^u8                                 #foreign kernel32 "GetCommandLineA";
get_command_line_w     :: proc() -> ^u16                                #foreign kernel32 "GetCommandLineW";
get_system_metrics     :: proc(index: i32) -> i32                       #foreign kernel32 "GetSystemMetrics";
get_current_thread_id  :: proc() -> u32                                 #foreign kernel32 "GetCurrentThreadId";
command_line_to_argv_w :: proc(cmd_list: ^u16, num_args: ^i32) -> ^^u16 #foreign shell32  "CommandLineToArgvW";

time_get_time                :: proc() -> u32                                                  #foreign winmm    "timeGetTime";
get_system_time_as_file_time :: proc(system_time_as_file_time: ^Filetime)                      #foreign kernel32 "GetSystemTimeAsFileTime";
file_time_to_local_file_time :: proc(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool #foreign kernel32 "FileTimeToLocalFileTime";
file_time_to_system_time     :: proc(file_time: ^Filetime, system_time: ^Systemtime) -> Bool   #foreign kernel32 "FileTimeToSystemTime";
system_time_to_file_time     :: proc(system_time: ^Systemtime, file_time: ^Filetime) -> Bool   #foreign kernel32 "SystemTimeToFileTime";

// File Stuff

close_handle   :: proc(h: Handle) -> i32 #foreign kernel32 "CloseHandle";
get_std_handle :: proc(h: i32) -> Handle #foreign kernel32 "GetStdHandle";
create_file_a  :: proc(filename: ^u8, desired_access, share_mode: u32,
                       security: rawptr,
                       creation, flags_and_attribs: u32, template_file: Handle) -> Handle #foreign kernel32 "CreateFileA";
read_file  :: proc(h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool #foreign kernel32 "ReadFile";
write_file :: proc(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool #foreign kernel32 "WriteFile";

get_file_size_ex               :: proc(file_handle: Handle, file_size: ^i64) -> Bool                                    #foreign kernel32 "GetFileSizeEx";
get_file_attributes_a          :: proc(filename: ^byte) -> u32                                                          #foreign kernel32 "GetFileAttributesA";
get_file_attributes_ex_a       :: proc(filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool #foreign kernel32 "GetFileAttributesExA";
get_file_information_by_handle :: proc(file_handle: Handle, file_info: ^ByHandleFileInformation) -> Bool                #foreign kernel32 "GetFileInformationByHandle";

get_file_type    :: proc(file_handle: Handle) -> u32                                                                       #foreign kernel32 "GetFileType";
set_file_pointer :: proc(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #foreign kernel32 "SetFilePointer";

set_handle_information :: proc(obj: Handle, mask, flags: u32) -> Bool #foreign kernel32 "SetHandleInformation";

find_first_file_a :: proc(file_name : ^byte, data : ^FindData) -> Handle #foreign kernel32 "FindFirstFileA";
find_next_file_a  :: proc(file : Handle, data : ^FindData) -> Bool       #foreign kernel32 "FindNextFileA";
find_close        :: proc(file : Handle) -> Bool                         #foreign kernel32 "FindClose";

MAX_PATH :: 0x00000104;

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

INVALID_FILE_ATTRIBUTES  :: -1;

FILE_ATTRIBUTE_READONLY             :: 0x00000001;
FILE_ATTRIBUTE_HIDDEN               :: 0x00000002;
FILE_ATTRIBUTE_SYSTEM               :: 0x00000004;
FILE_ATTRIBUTE_DIRECTORY            :: 0x00000010;
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

INVALID_SET_FILE_POINTER :: ~u32(0);




heap_alloc       :: proc (h: Handle, flags: u32, bytes: int) -> rawptr                 #foreign kernel32 "HeapAlloc";
heap_realloc     :: proc (h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr #foreign kernel32 "HeapReAlloc";
heap_free        :: proc (h: Handle, flags: u32, memory: rawptr) -> Bool               #foreign kernel32 "HeapFree";
get_process_heap :: proc () -> Handle                                                  #foreign kernel32 "GetProcessHeap";


HEAP_ZERO_MEMORY :: 0x00000008;

// Synchronization

Security_Attributes :: struct #ordered {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}

INFINITE :: 0xffffffff;

create_semaphore_a     :: proc(attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: ^byte) -> Handle #foreign kernel32 "CreateSemaphoreA";
release_semaphore      :: proc(semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool                        #foreign kernel32 "ReleaseSemaphore";
wait_for_single_object :: proc(handle: Handle, milliseconds: u32) -> u32                                                   #foreign kernel32 "WaitForSingleObject";


interlocked_compare_exchange   :: proc(dst: ^i32, exchange, comparand: i32) -> i32   #foreign kernel32 "InterlockedCompareExchange";
interlocked_exchange           :: proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedExchange";
interlocked_exchange_add       :: proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedExchangeAdd";
interlocked_and                :: proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedAnd";
interlocked_or                 :: proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedOr";

interlocked_compare_exchange64 :: proc(dst: ^i64, exchange, comparand: i64) -> i64   #foreign kernel32 "InterlockedCompareExchange64";
interlocked_exchange64         :: proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedExchange64";
interlocked_exchange_add64     :: proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedExchangeAdd64";
interlocked_and64              :: proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedAnd64";
interlocked_or64               :: proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedOr64";

mm_pause           :: proc() #foreign kernel32 "_mm_pause";
read_write_barrier :: proc() #foreign kernel32 "ReadWriteBarrier";
write_barrier      :: proc() #foreign kernel32 "WriteBarrier";
read_barrier       :: proc() #foreign kernel32 "ReadBarrier";





Hmonitor :: Handle;

GWL_STYLE :: -16;

Hwnd_TOP :: Hwnd(uint(0));

MONITOR_DEFAULTTONULL    :: 0x00000000;
MONITOR_DEFAULTTOPRIMARY :: 0x00000001;
MONITOR_DEFAULTTONEAREST :: 0x00000002;

SWP_FRAMECHANGED  :: 0x0020;
SWP_NOOWNERZORDER :: 0x0200;
SWP_NOZORDER      :: 0x0004;
SWP_NOSIZE        :: 0x0001;
SWP_NOMOVE        :: 0x0002;


MonitorInfo :: struct #ordered {
	size:      u32,
	monitor:   Rect,
	work:      Rect,
	flags:     u32,
}

WindowPlacement :: struct #ordered {
	length:     u32,
	flags:      u32,
	show_cmd:   u32,
	min_pos:    Point,
	max_pos:    Point,
	normal_pos: Rect,
}

get_monitor_info_a    :: proc(monitor: Hmonitor, mi: ^MonitorInfo) -> Bool                           #foreign user32 "GetMonitorInfoA";
monitor_from_window   :: proc(wnd: Hwnd, flags : u32) -> Hmonitor                                    #foreign user32 "MonitorFromWindow";

set_window_pos        :: proc(wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32) #foreign user32 "SetWindowPos";

get_window_placement  :: proc(wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                            #foreign user32 "GetWindowPlacement";
set_window_placement  :: proc(wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                            #foreign user32 "SetWindowPlacement";
get_window_rect       :: proc(wnd: Hwnd, rect: ^Rect) -> Bool                                        #foreign user32 "GetWindowRect";

get_window_long_ptr_a :: proc(wnd: Hwnd, index: i32) -> i64                                          #foreign user32 "GetWindowLongPtrA";
set_window_long_ptr_a :: proc(wnd: Hwnd, index: i32, new: i64) -> i64                                #foreign user32 "SetWindowLongPtrA";

get_window_text       :: proc(wnd: Hwnd, str: ^byte, maxCount: i32) -> i32                           #foreign user32 "GetWindowText";

HIWORD :: proc(wParam: Wparam) -> u16 { return u16((u32(wParam) >> 16) & 0xffff); }
HIWORD :: proc(lParam: Lparam) -> u16 { return u16((u32(lParam) >> 16) & 0xffff); }
LOWORD :: proc(wParam: Wparam) -> u16 { return u16(wParam); }
LOWORD :: proc(lParam: Lparam) -> u16 { return u16(lParam); }










BitmapInfoHeader :: struct #ordered {
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
BitmapInfo :: struct #ordered {
	using header: BitmapInfoHeader,
	colors:       [1]RgbQuad,
}


RgbQuad :: struct #ordered { blue, green, red, reserved: byte }

BI_RGB         :: 0;
DIB_RGB_COLORS :: 0x00;
SRCCOPY: u32    : 0x00cc0020;


stretch_dibits :: proc (hdc: Hdc,
                        x_dst, y_dst, width_dst, height_dst: i32,
                        x_src, y_src, width_src, header_src: i32,
                        bits: rawptr, bits_info: ^BitmapInfo,
                        usage: u32,
                        rop: u32) -> i32 #foreign gdi32 "StretchDIBits";



load_library_a   :: proc (c_str: ^u8) -> Hmodule          #foreign kernel32 "LoadLibraryA";
free_library     :: proc (h: Hmodule)                     #foreign kernel32 "FreeLibrary";
get_proc_address :: proc (h: Hmodule, c_str: ^u8) -> Proc #foreign kernel32 "GetProcAddress";

get_client_rect  :: proc(hwnd: Hwnd, rect: ^Rect) -> Bool #foreign user32 "GetClientRect";

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


PixelFormatDescriptor :: struct #ordered {
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

get_d_c             :: proc(h: Hwnd) -> Hdc                                                   #foreign user32 "GetDC";
set_pixel_format    :: proc(hdc: Hdc, pixel_format: i32, pfd: ^PixelFormatDescriptor) -> Bool #foreign gdi32  "SetPixelFormat";
choose_pixel_format :: proc(hdc: Hdc, pfd: ^PixelFormatDescriptor) -> i32                     #foreign gdi32  "ChoosePixelFormat";
swap_buffers        :: proc(hdc: Hdc) -> Bool                                                 #foreign gdi32  "SwapBuffers";
release_d_c         :: proc(wnd: Hwnd, hdc: Hdc) -> i32                                       #foreign user32 "ReleaseDC";


Proc  :: #type proc() #cc_c;


get_key_state       :: proc(v_key: i32) -> i16 #foreign user32 "GetKeyState";
get_async_key_state :: proc(v_key: i32) -> i16 #foreign user32 "GetAsyncKeyState";

is_key_down :: proc(key: KeyCode) -> bool #inline { return get_async_key_state(i32(key)) < 0; }

KeyCode :: enum i32 {
	Lbutton    = 0x01,
	Rbutton    = 0x02,
	Cancel     = 0x03,
	Mbutton    = 0x04,
	Back       = 0x08,
	Tab        = 0x09,
	Clear      = 0x0C,
	Return     = 0x0D,

	Shift      = 0x10,
	Control    = 0x11,
	Menu       = 0x12,
	Pause      = 0x13,
	Capital    = 0x14,
	Kana       = 0x15,
	Hangeul    = 0x15,
	Hangul     = 0x15,
	Junja      = 0x17,
	Final      = 0x18,
	Hanja      = 0x19,
	Kanji      = 0x19,
	Escape     = 0x1B,
	Convert    = 0x1C,
	NonConvert = 0x1D,
	Accept     = 0x1E,
	ModeChange = 0x1F,
	Space      = 0x20,
	Prior      = 0x21,
	Next       = 0x22,
	End        = 0x23,
	Home       = 0x24,
	Left       = 0x25,
	Up         = 0x26,
	Right      = 0x27,
	Down       = 0x28,
	Select     = 0x29,
	Print      = 0x2A,
	Execute    = 0x2B,
	Snapshot   = 0x2C,
	Insert     = 0x2D,
	Delete     = 0x2E,
	Help       = 0x2F,

	Num0 = '0',
	Num1 = '1',
	Num2 = '2',
	Num3 = '3',
	Num4 = '4',
	Num5 = '5',
	Num6 = '6',
	Num7 = '7',
	Num8 = '8',
	Num9 = '9',
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

	Lwin       = 0x5B,
	Rwin       = 0x5C,
	Apps       = 0x5D,

	Numpad0    = 0x60,
	Numpad1    = 0x61,
	Numpad2    = 0x62,
	Numpad3    = 0x63,
	Numpad4    = 0x64,
	Numpad5    = 0x65,
	Numpad6    = 0x66,
	Numpad7    = 0x67,
	Numpad8    = 0x68,
	Numpad9    = 0x69,
	Multiply   = 0x6A,
	Add        = 0x6B,
	Separator  = 0x6C,
	Subtract   = 0x6D,
	Decimal    = 0x6E,
	Divide     = 0x6F,

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

	Numlock    = 0x90,
	Scroll     = 0x91,
	Lshift     = 0xA0,
	Rshift     = 0xA1,
	Lcontrol   = 0xA2,
	Rcontrol   = 0xA3,
	Lmenu      = 0xA4,
	Rmenu      = 0xA5,
	ProcessKey = 0xE5,
	Attn       = 0xF6,
	Crsel      = 0xF7,
	Exsel      = 0xF8,
	Ereof      = 0xF9,
	Play       = 0xFA,
	Zoom       = 0xFB,
	Noname     = 0xFC,
	Pa1        = 0xFD,
	OemClear   = 0xFE,
}
