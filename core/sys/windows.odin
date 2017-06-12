#foreign_system_library "kernel32.lib" when ODIN_OS == "windows";
#foreign_system_library "user32.lib"   when ODIN_OS == "windows";
#foreign_system_library "gdi32.lib"    when ODIN_OS == "windows";
#foreign_system_library "winmm.lib"    when ODIN_OS == "windows";
#foreign_system_library "shell32.lib"  when ODIN_OS == "windows";

const Handle    = rawptr;
const Hwnd      = Handle;
const Hdc       = Handle;
const Hinstance = Handle;
const Hicon     = Handle;
const Hcursor   = Handle;
const Hmenu     = Handle;
const Hbrush    = Handle;
const Hgdiobj   = Handle;
const Hmodule   = Handle;
const Wparam    = uint;
const Lparam    = int;
const Lresult   = int;
const Bool      = i32;
const WndProc  = type proc(Hwnd, u32, Wparam, Lparam) -> Lresult #cc_c;


const INVALID_HANDLE = Handle(~int(0));

const FALSE: Bool = 0;
const TRUE:  Bool = 1;

const CS_VREDRAW    = 0x0001;
const CS_HREDRAW    = 0x0002;
const CS_OWNDC      = 0x0020;
const CW_USEDEFAULT = -0x80000000;

const WS_OVERLAPPED       = 0;
const WS_MAXIMIZEBOX      = 0x00010000;
const WS_MINIMIZEBOX      = 0x00020000;
const WS_THICKFRAME       = 0x00040000;
const WS_SYSMENU          = 0x00080000;
const WS_BORDER           = 0x00800000;
const WS_CAPTION          = 0x00C00000;
const WS_VISIBLE          = 0x10000000;
const WS_POPUP            = 0x80000000;
const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;
const WS_POPUPWINDOW      = WS_POPUP | WS_BORDER | WS_SYSMENU;

const WM_DESTROY           = 0x0002;
const WM_SIZE	             = 0x0005;
const WM_CLOSE             = 0x0010;
const WM_ACTIVATEAPP       = 0x001C;
const WM_QUIT              = 0x0012;
const WM_KEYDOWN           = 0x0100;
const WM_KEYUP             = 0x0101;
const WM_SIZING            = 0x0214;
const WM_SYSKEYDOWN        = 0x0104;
const WM_SYSKEYUP          = 0x0105;
const WM_WINDOWPOSCHANGED  = 0x0047;
const WM_SETCURSOR         = 0x0020;
const WM_CHAR              = 0x0102;
const WM_ACTIVATE          = 0x0006;
const WM_SETFOCUS          = 0x0007;
const WM_KILLFOCUS         = 0x0008;
const WM_USER              = 0x0400;

const WM_MOUSEWHEEL    = 0x020A;
const WM_MOUSEMOVE     = 0x0200;
const WM_LBUTTONDOWN   = 0x0201;
const WM_LBUTTONUP     = 0x0202;
const WM_LBUTTONDBLCLK = 0x0203;
const WM_RBUTTONDOWN   = 0x0204;
const WM_RBUTTONUP     = 0x0205;
const WM_RBUTTONDBLCLK = 0x0206;
const WM_MBUTTONDOWN   = 0x0207;
const WM_MBUTTONUP     = 0x0208;
const WM_MBUTTONDBLCLK = 0x0209;

const PM_NOREMOVE = 0x0000;
const PM_REMOVE   = 0x0001;
const PM_NOYIELD  = 0x0002;

const COLOR_BACKGROUND = Hbrush(int(1));
const BLACK_BRUSH = 4;

const SM_CXSCREEN = 0;
const SM_CYSCREEN = 1;

const SW_SHOW = 5;


const Point = struct #ordered {
	x, y: i32,
}

const WndClassExA = struct #ordered {
	size, style:           u32,
	wnd_proc:              WndProc,
	cls_extra, wnd_extra:  i32,
	instance:              Hinstance,
	icon:                  Hicon,
	cursor:                Hcursor,
	background:            Hbrush,
	menu_name, class_name: ^u8,
	sm:                    Hicon,
}

const Msg = struct #ordered {
	hwnd:    Hwnd,
	message: u32,
	wparam:  Wparam,
	lparam:  Lparam,
	time:    u32,
	pt:      Point,
}

const Rect = struct #ordered {
	left:   i32,
	top:    i32,
	right:  i32,
	bottom: i32,
}

const Filetime = struct #ordered {
	lo, hi: u32,
}

const Systemtime = struct #ordered {
	year, month: u16,
	day_of_week, day: u16,
	hour, minute, second, millisecond: u16,
}

const ByHandleFileInformation = struct #ordered {
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

const FileAttributeData = struct #ordered {
	file_attributes:  u32,
	creation_time,
	last_access_time,
	last_write_time:  Filetime,
	file_size_high,
	file_size_low:    u32,
}

const FindData = struct #ordered {
    file_attributes     : u32,
    creation_time       : Filetime,
    last_access_time    : Filetime,
    last_write_time     : Filetime,
    file_size_high      : u32,
    file_size_low       : u32,
    reserved0           : u32,
    reserved1           : u32,
    file_name           : [MAX_PATH]u8,
    alternate_file_name : [14]u8,
}


const GET_FILEEX_INFO_LEVELS = i32;

const GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS = 0;
const GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS = 1;

const get_last_error      = proc() -> i32                            #foreign kernel32 "GetLastError";
const exit_process        = proc(exit_code: u32)                     #foreign kernel32 "ExitProcess";
const get_desktop_window  = proc() -> Hwnd                           #foreign user32   "GetDesktopWindow";
const show_cursor         = proc(show : Bool)                        #foreign user32   "ShowCursor";
const get_cursor_pos      = proc(p: ^Point) -> i32                   #foreign user32   "GetCursorPos";
const screen_to_client    = proc(h: Hwnd, p: ^Point) -> i32          #foreign user32   "ScreenToClient";
const get_module_handle_a = proc(module_name: ^u8) -> Hinstance      #foreign kernel32 "GetModuleHandleA";
const get_stock_object    = proc(fn_object: i32) -> Hgdiobj          #foreign gdi32    "GetStockObject";
const post_quit_message   = proc(exit_code: i32)                     #foreign user32   "PostQuitMessage";
const set_window_text_a   = proc(hwnd: Hwnd, c_string: ^u8) -> Bool  #foreign user32   "SetWindowTextA";

const query_performance_frequency = proc(result: ^i64) -> i32 #foreign kernel32 "QueryPerformanceFrequency";
const query_performance_counter   = proc(result: ^i64) -> i32 #foreign kernel32 "QueryPerformanceCounter";

const sleep = proc(ms: i32) -> i32 #foreign kernel32 "Sleep";

const output_debug_string_a = proc(c_str: ^u8) #foreign kernel32 "OutputDebugStringA";


const register_class_ex_a = proc(wc: ^WndClassExA) -> i16 #foreign user32 "RegisterClassExA";
const create_window_ex_a  = proc(ex_style: u32,
                            class_name, title: ^u8,
                            style: u32,
                            x, y, w, h: i32,
                            parent: Hwnd, menu: Hmenu, instance: Hinstance,
                            param: rawptr) -> Hwnd #foreign user32 "CreateWindowExA";

const show_window        = proc(hwnd: Hwnd, cmd_show: i32) -> Bool #foreign user32 "ShowWindow";
const translate_message  = proc(msg: ^Msg) -> Bool                 #foreign user32 "TranslateMessage";
const dispatch_message_a = proc(msg: ^Msg) -> Lresult              #foreign user32 "DispatchMessageA";
const update_window      = proc(hwnd: Hwnd) -> Bool                #foreign user32 "UpdateWindow";
const get_message_a      = proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max : u32) -> Bool #foreign user32 "GetMessageA";
const peek_message_a     = proc(msg: ^Msg, hwnd: Hwnd,
                           msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool #foreign user32 "PeekMessageA";

const post_message = proc(hwnd: Hwnd, msg, wparam, lparam : u32) -> Bool #foreign user32 "PostMessageA";

const def_window_proc_a = proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult #foreign user32 "DefWindowProcA";

const adjust_window_rect = proc(rect: ^Rect, style: u32, menu: Bool) -> Bool #foreign user32 "AdjustWindowRect";
const get_active_window  = proc() -> Hwnd                                    #foreign user32 "GetActiveWindow";

const destroy_window        = proc(wnd: Hwnd) -> Bool                                                           #foreign user32 "DestroyWindow";
const describe_pixel_format = proc(dc: Hdc, pixel_format: i32, bytes : u32, pfd: ^PixelFormatDescriptor) -> i32 #foreign user32 "DescribePixelFormat";


const get_query_performance_frequency = proc() -> i64 {
	var r: i64;
	query_performance_frequency(&r);
	return r;
}

const get_command_line_a     = proc() -> ^u8                                 #foreign kernel32 "GetCommandLineA";
const get_command_line_w     = proc() -> ^u16                                #foreign kernel32 "GetCommandLineW";
const get_system_metrics     = proc(index: i32) -> i32                       #foreign kernel32 "GetSystemMetrics";
const get_current_thread_id  = proc() -> u32                                 #foreign kernel32 "GetCurrentThreadId";
const command_line_to_argv_w = proc(cmd_list: ^u16, num_args: ^i32) -> ^^u16 #foreign shell32  "CommandLineToArgvW";

const time_get_time                = proc() -> u32                                                  #foreign winmm    "timeGetTime";
const get_system_time_as_file_time = proc(system_time_as_file_time: ^Filetime)                      #foreign kernel32 "GetSystemTimeAsFileTime";
const file_time_to_local_file_time = proc(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool #foreign kernel32 "FileTimeToLocalFileTime";
const file_time_to_system_time     = proc(file_time: ^Filetime, system_time: ^Systemtime) -> Bool   #foreign kernel32 "FileTimeToSystemTime";
const system_time_to_file_time     = proc(system_time: ^Systemtime, file_time: ^Filetime) -> Bool   #foreign kernel32 "SystemTimeToFileTime";

// File Stuff

const close_handle   = proc(h: Handle) -> i32 #foreign kernel32 "CloseHandle";
const get_std_handle = proc(h: i32) -> Handle #foreign kernel32 "GetStdHandle";
const create_file_a  = proc(filename: ^u8, desired_access, share_mode: u32,
                       security: rawptr,
                       creation, flags_and_attribs: u32, template_file: Handle) -> Handle #foreign kernel32 "CreateFileA";
const read_file  = proc(h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool #foreign kernel32 "ReadFile";
const write_file = proc(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool #foreign kernel32 "WriteFile";

const get_file_size_ex               = proc(file_handle: Handle, file_size: ^i64) -> Bool                                    #foreign kernel32 "GetFileSizeEx";
const get_file_attributes_a          = proc(filename: ^u8) -> u32                                                          #foreign kernel32 "GetFileAttributesA";
const get_file_attributes_ex_a       = proc(filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool #foreign kernel32 "GetFileAttributesExA";
const get_file_information_by_handle = proc(file_handle: Handle, file_info: ^ByHandleFileInformation) -> Bool                #foreign kernel32 "GetFileInformationByHandle";

const get_file_type    = proc(file_handle: Handle) -> u32                                                                       #foreign kernel32 "GetFileType";
const set_file_pointer = proc(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #foreign kernel32 "SetFilePointer";

const set_handle_information = proc(obj: Handle, mask, flags: u32) -> Bool #foreign kernel32 "SetHandleInformation";

const find_first_file_a = proc(file_name : ^u8, data : ^FindData) -> Handle #foreign kernel32 "FindFirstFileA";
const find_next_file_a  = proc(file : Handle, data : ^FindData) -> Bool       #foreign kernel32 "FindNextFileA";
const find_close        = proc(file : Handle) -> Bool                         #foreign kernel32 "FindClose";

const MAX_PATH = 0x00000104;

const HANDLE_FLAG_INHERIT = 1;
const HANDLE_FLAG_PROTECT_FROM_CLOSE = 2;


const FILE_BEGIN   = 0;
const FILE_CURRENT = 1;
const FILE_END     = 2;

const FILE_SHARE_READ      = 0x00000001;
const FILE_SHARE_WRITE     = 0x00000002;
const FILE_SHARE_DELETE    = 0x00000004;
const FILE_GENERIC_ALL     = 0x10000000;
const FILE_GENERIC_EXECUTE = 0x20000000;
const FILE_GENERIC_WRITE   = 0x40000000;
const FILE_GENERIC_READ    = 0x80000000;

const FILE_APPEND_DATA = 0x0004;

const STD_INPUT_HANDLE  = -10;
const STD_OUTPUT_HANDLE = -11;
const STD_ERROR_HANDLE  = -12;

const CREATE_NEW        = 1;
const CREATE_ALWAYS     = 2;
const OPEN_EXISTING     = 3;
const OPEN_ALWAYS       = 4;
const TRUNCATE_EXISTING = 5;

const INVALID_FILE_ATTRIBUTES  = -1;

const FILE_ATTRIBUTE_READONLY             = 0x00000001;
const FILE_ATTRIBUTE_HIDDEN               = 0x00000002;
const FILE_ATTRIBUTE_SYSTEM               = 0x00000004;
const FILE_ATTRIBUTE_DIRECTORY            = 0x00000010;
const FILE_ATTRIBUTE_ARCHIVE              = 0x00000020;
const FILE_ATTRIBUTE_DEVICE               = 0x00000040;
const FILE_ATTRIBUTE_NORMAL               = 0x00000080;
const FILE_ATTRIBUTE_TEMPORARY            = 0x00000100;
const FILE_ATTRIBUTE_SPARSE_FILE          = 0x00000200;
const FILE_ATTRIBUTE_REPARSE_Point        = 0x00000400;
const FILE_ATTRIBUTE_COMPRESSED           = 0x00000800;
const FILE_ATTRIBUTE_OFFLINE              = 0x00001000;
const FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  = 0x00002000;
const FILE_ATTRIBUTE_ENCRYPTED            = 0x00004000;

const FILE_TYPE_DISK = 0x0001;
const FILE_TYPE_CHAR = 0x0002;
const FILE_TYPE_PIPE = 0x0003;

const INVALID_SET_FILE_POINTER = ~u32(0);




const heap_alloc       = proc (h: Handle, flags: u32, bytes: int) -> rawptr                 #foreign kernel32 "HeapAlloc";
const heap_realloc     = proc (h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr #foreign kernel32 "HeapReAlloc";
const heap_free        = proc (h: Handle, flags: u32, memory: rawptr) -> Bool               #foreign kernel32 "HeapFree";
const get_process_heap = proc () -> Handle                                                  #foreign kernel32 "GetProcessHeap";


const HEAP_ZERO_MEMORY = 0x00000008;

// Synchronization

const Security_Attributes = struct #ordered {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}

const INFINITE = 0xffffffff;

const create_semaphore_a     = proc(attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: ^u8) -> Handle #foreign kernel32 "CreateSemaphoreA";
const release_semaphore      = proc(semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool                        #foreign kernel32 "ReleaseSemaphore";
const wait_for_single_object = proc(handle: Handle, milliseconds: u32) -> u32                                                   #foreign kernel32 "WaitForSingleObject";


const interlocked_compare_exchange   = proc(dst: ^i32, exchange, comparand: i32) -> i32   #foreign kernel32 "InterlockedCompareExchange";
const interlocked_exchange           = proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedExchange";
const interlocked_exchange_add       = proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedExchangeAdd";
const interlocked_and                = proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedAnd";
const interlocked_or                 = proc(dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedOr";

const interlocked_compare_exchange64 = proc(dst: ^i64, exchange, comparand: i64) -> i64   #foreign kernel32 "InterlockedCompareExchange64";
const interlocked_exchange64         = proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedExchange64";
const interlocked_exchange_add64     = proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedExchangeAdd64";
const interlocked_and64              = proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedAnd64";
const interlocked_or64               = proc(dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedOr64";

const mm_pause           = proc() #foreign kernel32 "_mm_pause";
const read_write_barrier = proc() #foreign kernel32 "ReadWriteBarrier";
const write_barrier      = proc() #foreign kernel32 "WriteBarrier";
const read_barrier       = proc() #foreign kernel32 "ReadBarrier";





const Hmonitor = Handle;

const GWL_STYLE = -16;

const Hwnd_TOP = Hwnd(uint(0));

const MONITOR_DEFAULTTONULL    = 0x00000000;
const MONITOR_DEFAULTTOPRIMARY = 0x00000001;
const MONITOR_DEFAULTTONEAREST = 0x00000002;

const SWP_FRAMECHANGED  = 0x0020;
const SWP_NOOWNERZORDER = 0x0200;
const SWP_NOZORDER      = 0x0004;
const SWP_NOSIZE        = 0x0001;
const SWP_NOMOVE        = 0x0002;


const MonitorInfo = struct #ordered {
	size:      u32,
	monitor:   Rect,
	work:      Rect,
	flags:     u32,
}

const WindowPlacement = struct #ordered {
	length:     u32,
	flags:      u32,
	show_cmd:   u32,
	min_pos:    Point,
	max_pos:    Point,
	normal_pos: Rect,
}

const get_monitor_info_a    = proc(monitor: Hmonitor, mi: ^MonitorInfo) -> Bool                           #foreign user32 "GetMonitorInfoA";
const monitor_from_window   = proc(wnd: Hwnd, flags : u32) -> Hmonitor                                    #foreign user32 "MonitorFromWindow";

const set_window_pos        = proc(wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32) #foreign user32 "SetWindowPos";

const get_window_placement  = proc(wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                            #foreign user32 "GetWindowPlacement";
const set_window_placement  = proc(wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                            #foreign user32 "SetWindowPlacement";
const get_window_rect       = proc(wnd: Hwnd, rect: ^Rect) -> Bool                                        #foreign user32 "GetWindowRect";

const get_window_long_ptr_a = proc(wnd: Hwnd, index: i32) -> i64                                          #foreign user32 "GetWindowLongPtrA";
const set_window_long_ptr_a = proc(wnd: Hwnd, index: i32, new: i64) -> i64                                #foreign user32 "SetWindowLongPtrA";

const get_window_text       = proc(wnd: Hwnd, str: ^u8, maxCount: i32) -> i32                           #foreign user32 "GetWindowText";

const HIWORD = proc(wParam: Wparam) -> u16 { return u16((u32(wParam) >> 16) & 0xffff); }
const HIWORD = proc(lParam: Lparam) -> u16 { return u16((u32(lParam) >> 16) & 0xffff); }
const LOWORD = proc(wParam: Wparam) -> u16 { return u16(wParam); }
const LOWORD = proc(lParam: Lparam) -> u16 { return u16(lParam); }










const BitmapInfoHeader = struct #ordered {
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
const BitmapInfo = struct #ordered {
	using header: BitmapInfoHeader,
	colors:       [1]RgbQuad,
}


const RgbQuad = struct #ordered { blue, green, red, reserved: u8 }

const BI_RGB         = 0;
const DIB_RGB_COLORS = 0x00;
const SRCCOPY: u32   = 0x00cc0020;


const stretch_dibits = proc (hdc: Hdc,
                        x_dst, y_dst, width_dst, height_dst: i32,
                        x_src, y_src, width_src, header_src: i32,
                        bits: rawptr, bits_info: ^BitmapInfo,
                        usage: u32,
                        rop: u32) -> i32 #foreign gdi32 "StretchDIBits";



const load_library_a   = proc (c_str: ^u8) -> Hmodule          #foreign kernel32 "LoadLibraryA";
const free_library     = proc (h: Hmodule)                     #foreign kernel32 "FreeLibrary";
const get_proc_address = proc (h: Hmodule, c_str: ^u8) -> Proc #foreign kernel32 "GetProcAddress";

const get_client_rect  = proc(hwnd: Hwnd, rect: ^Rect) -> Bool #foreign user32 "GetClientRect";

// Windows OpenGL
const PFD_TYPE_RGBA             = 0;
const PFD_TYPE_COLORINDEX       = 1;
const PFD_MAIN_PLANE            = 0;
const PFD_OVERLAY_PLANE         = 1;
const PFD_UNDERLAY_PLANE        = -1;
const PFD_DOUBLEBUFFER          = 1;
const PFD_STEREO                = 2;
const PFD_DRAW_TO_WINDOW        = 4;
const PFD_DRAW_TO_BITMAP        = 8;
const PFD_SUPPORT_GDI           = 16;
const PFD_SUPPORT_OPENGL        = 32;
const PFD_GENERIC_FORMAT        = 64;
const PFD_NEED_PALETTE          = 128;
const PFD_NEED_SYSTEM_PALETTE   = 0x00000100;
const PFD_SWAP_EXCHANGE         = 0x00000200;
const PFD_SWAP_COPY             = 0x00000400;
const PFD_SWAP_LAYER_BUFFERS    = 0x00000800;
const PFD_GENERIC_ACCELERATED   = 0x00001000;
const PFD_DEPTH_DONTCARE        = 0x20000000;
const PFD_DOUBLEBUFFER_DONTCARE = 0x40000000;
const PFD_STEREO_DONTCARE       = 0x80000000;


const PixelFormatDescriptor = struct #ordered {
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
	reserved: u8,

	layer_mask,
	visible_mask,
	damage_mask: u32,
}

const get_dc              = proc(h: Hwnd) -> Hdc                                                   #foreign user32 "GetDC";
const set_pixel_format    = proc(hdc: Hdc, pixel_format: i32, pfd: ^PixelFormatDescriptor) -> Bool #foreign gdi32  "SetPixelFormat";
const choose_pixel_format = proc(hdc: Hdc, pfd: ^PixelFormatDescriptor) -> i32                     #foreign gdi32  "ChoosePixelFormat";
const swap_buffers        = proc(hdc: Hdc) -> Bool                                                 #foreign gdi32  "SwapBuffers";
const release_dc          = proc(wnd: Hwnd, hdc: Hdc) -> i32                                       #foreign user32 "ReleaseDC";


const Proc  = type proc() #cc_c;

const MAPVK_VK_TO_CHAR   = 2;
const MAPVK_VK_TO_VSC    = 0;
const MAPVK_VSC_TO_VK    = 1;
const MAPVK_VSC_TO_VK_EX = 3;

const map_virtual_key = proc(scancode : u32, map_type : u32) -> u32 #foreign user32 "MapVirtualKeyA";

const get_key_state       = proc(v_key: i32) -> i16 #foreign user32 "GetKeyState";
const get_async_key_state = proc(v_key: i32) -> i16 #foreign user32 "GetAsyncKeyState";

const is_key_down = proc(key: KeyCode) -> bool #inline { return get_async_key_state(i32(key)) < 0; }

const KeyCode = enum i32 {
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
