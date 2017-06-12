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

proc get_last_error     () -> i32                            #foreign kernel32 "GetLastError";
proc exit_process       (exit_code: u32)                     #foreign kernel32 "ExitProcess";
proc get_desktop_window () -> Hwnd                           #foreign user32   "GetDesktopWindow";
proc show_cursor        (show : Bool)                        #foreign user32   "ShowCursor";
proc get_cursor_pos     (p: ^Point) -> i32                   #foreign user32   "GetCursorPos";
proc screen_to_client   (h: Hwnd, p: ^Point) -> i32          #foreign user32   "ScreenToClient";
proc get_module_handle_a(module_name: ^u8) -> Hinstance      #foreign kernel32 "GetModuleHandleA";
proc get_stock_object   (fn_object: i32) -> Hgdiobj          #foreign gdi32    "GetStockObject";
proc post_quit_message  (exit_code: i32)                     #foreign user32   "PostQuitMessage";
proc set_window_text_a  (hwnd: Hwnd, c_string: ^u8) -> Bool  #foreign user32   "SetWindowTextA";

proc query_performance_frequency(result: ^i64) -> i32 #foreign kernel32 "QueryPerformanceFrequency";
proc query_performance_counter  (result: ^i64) -> i32 #foreign kernel32 "QueryPerformanceCounter";

proc sleep(ms: i32) -> i32 #foreign kernel32 "Sleep";

proc output_debug_string_a(c_str: ^u8) #foreign kernel32 "OutputDebugStringA";


proc register_class_ex_a(wc: ^WndClassExA) -> i16 #foreign user32 "RegisterClassExA";
proc create_window_ex_a (ex_style: u32,
                            class_name, title: ^u8,
                            style: u32,
                            x, y, w, h: i32,
                            parent: Hwnd, menu: Hmenu, instance: Hinstance,
                            param: rawptr) -> Hwnd #foreign user32 "CreateWindowExA";

proc show_window       (hwnd: Hwnd, cmd_show: i32) -> Bool #foreign user32 "ShowWindow";
proc translate_message (msg: ^Msg) -> Bool                 #foreign user32 "TranslateMessage";
proc dispatch_message_a(msg: ^Msg) -> Lresult              #foreign user32 "DispatchMessageA";
proc update_window     (hwnd: Hwnd) -> Bool                #foreign user32 "UpdateWindow";
proc get_message_a     (msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max : u32) -> Bool #foreign user32 "GetMessageA";
proc peek_message_a    (msg: ^Msg, hwnd: Hwnd,
                           msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool #foreign user32 "PeekMessageA";

proc post_message(hwnd: Hwnd, msg, wparam, lparam : u32) -> Bool #foreign user32 "PostMessageA";

proc def_window_proc_a(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult #foreign user32 "DefWindowProcA";

proc adjust_window_rect(rect: ^Rect, style: u32, menu: Bool) -> Bool #foreign user32 "AdjustWindowRect";
proc get_active_window () -> Hwnd                                    #foreign user32 "GetActiveWindow";

proc destroy_window       (wnd: Hwnd) -> Bool                                                           #foreign user32 "DestroyWindow";
proc describe_pixel_format(dc: Hdc, pixel_format: i32, bytes : u32, pfd: ^PixelFormatDescriptor) -> i32 #foreign user32 "DescribePixelFormat";


proc get_query_performance_frequency() -> i64 {
	var r: i64;
	query_performance_frequency(&r);
	return r;
}

proc get_command_line_a    () -> ^u8                                 #foreign kernel32 "GetCommandLineA";
proc get_command_line_w    () -> ^u16                                #foreign kernel32 "GetCommandLineW";
proc get_system_metrics    (index: i32) -> i32                       #foreign kernel32 "GetSystemMetrics";
proc get_current_thread_id () -> u32                                 #foreign kernel32 "GetCurrentThreadId";
proc command_line_to_argv_w(cmd_list: ^u16, num_args: ^i32) -> ^^u16 #foreign shell32  "CommandLineToArgvW";

proc time_get_time               () -> u32                                                  #foreign winmm    "timeGetTime";
proc get_system_time_as_file_time(system_time_as_file_time: ^Filetime)                      #foreign kernel32 "GetSystemTimeAsFileTime";
proc file_time_to_local_file_time(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool #foreign kernel32 "FileTimeToLocalFileTime";
proc file_time_to_system_time    (file_time: ^Filetime, system_time: ^Systemtime) -> Bool   #foreign kernel32 "FileTimeToSystemTime";
proc system_time_to_file_time    (system_time: ^Systemtime, file_time: ^Filetime) -> Bool   #foreign kernel32 "SystemTimeToFileTime";

// File Stuff

proc close_handle  (h: Handle) -> i32 #foreign kernel32 "CloseHandle";
proc get_std_handle(h: i32) -> Handle #foreign kernel32 "GetStdHandle";
proc create_file_a (filename: ^u8, desired_access, share_mode: u32,
                       security: rawptr,
                       creation, flags_and_attribs: u32, template_file: Handle) -> Handle #foreign kernel32 "CreateFileA";
proc read_file (h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool #foreign kernel32 "ReadFile";
proc write_file(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool #foreign kernel32 "WriteFile";

proc get_file_size_ex              (file_handle: Handle, file_size: ^i64) -> Bool                                    #foreign kernel32 "GetFileSizeEx";
proc get_file_attributes_a         (filename: ^u8) -> u32                                                          #foreign kernel32 "GetFileAttributesA";
proc get_file_attributes_ex_a      (filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool #foreign kernel32 "GetFileAttributesExA";
proc get_file_information_by_handle(file_handle: Handle, file_info: ^ByHandleFileInformation) -> Bool                #foreign kernel32 "GetFileInformationByHandle";

proc get_file_type   (file_handle: Handle) -> u32                                                                       #foreign kernel32 "GetFileType";
proc set_file_pointer(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #foreign kernel32 "SetFilePointer";

proc set_handle_information(obj: Handle, mask, flags: u32) -> Bool #foreign kernel32 "SetHandleInformation";

proc find_first_file_a(file_name : ^u8, data : ^FindData) -> Handle #foreign kernel32 "FindFirstFileA";
proc find_next_file_a (file : Handle, data : ^FindData) -> Bool       #foreign kernel32 "FindNextFileA";
proc find_close       (file : Handle) -> Bool                         #foreign kernel32 "FindClose";

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




proc heap_alloc      ( h: Handle, flags: u32, bytes: int) -> rawptr                 #foreign kernel32 "HeapAlloc";
proc heap_realloc    ( h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr #foreign kernel32 "HeapReAlloc";
proc heap_free       ( h: Handle, flags: u32, memory: rawptr) -> Bool               #foreign kernel32 "HeapFree";
proc get_process_heap( ) -> Handle                                                  #foreign kernel32 "GetProcessHeap";


const HEAP_ZERO_MEMORY = 0x00000008;

// Synchronization

const Security_Attributes = struct #ordered {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}

const INFINITE = 0xffffffff;

proc create_semaphore_a    (attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: ^u8) -> Handle #foreign kernel32 "CreateSemaphoreA";
proc release_semaphore     (semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool                        #foreign kernel32 "ReleaseSemaphore";
proc wait_for_single_object(handle: Handle, milliseconds: u32) -> u32                                                   #foreign kernel32 "WaitForSingleObject";


proc interlocked_compare_exchange  (dst: ^i32, exchange, comparand: i32) -> i32   #foreign kernel32 "InterlockedCompareExchange";
proc interlocked_exchange          (dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedExchange";
proc interlocked_exchange_add      (dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedExchangeAdd";
proc interlocked_and               (dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedAnd";
proc interlocked_or                (dst: ^i32, desired: i32) -> i32               #foreign kernel32 "InterlockedOr";

proc interlocked_compare_exchange64(dst: ^i64, exchange, comparand: i64) -> i64   #foreign kernel32 "InterlockedCompareExchange64";
proc interlocked_exchange64        (dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedExchange64";
proc interlocked_exchange_add64    (dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedExchangeAdd64";
proc interlocked_and64             (dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedAnd64";
proc interlocked_or64              (dst: ^i64, desired: i64) -> i64               #foreign kernel32 "InterlockedOr64";

proc mm_pause          () #foreign kernel32 "_mm_pause";
proc read_write_barrier() #foreign kernel32 "ReadWriteBarrier";
proc write_barrier     () #foreign kernel32 "WriteBarrier";
proc read_barrier      () #foreign kernel32 "ReadBarrier";





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

proc get_monitor_info_a   (monitor: Hmonitor, mi: ^MonitorInfo) -> Bool                           #foreign user32 "GetMonitorInfoA";
proc monitor_from_window  (wnd: Hwnd, flags : u32) -> Hmonitor                                    #foreign user32 "MonitorFromWindow";

proc set_window_pos       (wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32) #foreign user32 "SetWindowPos";

proc get_window_placement (wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                            #foreign user32 "GetWindowPlacement";
proc set_window_placement (wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                            #foreign user32 "SetWindowPlacement";
proc get_window_rect      (wnd: Hwnd, rect: ^Rect) -> Bool                                        #foreign user32 "GetWindowRect";

proc get_window_long_ptr_a(wnd: Hwnd, index: i32) -> i64                                          #foreign user32 "GetWindowLongPtrA";
proc set_window_long_ptr_a(wnd: Hwnd, index: i32, new: i64) -> i64                                #foreign user32 "SetWindowLongPtrA";

proc get_window_text      (wnd: Hwnd, str: ^u8, maxCount: i32) -> i32                           #foreign user32 "GetWindowText";

proc HIWORD(wParam: Wparam) -> u16 { return u16((u32(wParam) >> 16) & 0xffff); }
proc HIWORD(lParam: Lparam) -> u16 { return u16((u32(lParam) >> 16) & 0xffff); }
proc LOWORD(wParam: Wparam) -> u16 { return u16(wParam); }
proc LOWORD(lParam: Lparam) -> u16 { return u16(lParam); }










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


proc stretch_dibits( hdc: Hdc,
                        x_dst, y_dst, width_dst, height_dst: i32,
                        x_src, y_src, width_src, header_src: i32,
                        bits: rawptr, bits_info: ^BitmapInfo,
                        usage: u32,
                        rop: u32) -> i32 #foreign gdi32 "StretchDIBits";



proc load_library_a  ( c_str: ^u8) -> Hmodule          #foreign kernel32 "LoadLibraryA";
proc free_library    ( h: Hmodule)                     #foreign kernel32 "FreeLibrary";
proc get_proc_address( h: Hmodule, c_str: ^u8) -> Proc #foreign kernel32 "GetProcAddress";

proc get_client_rect (hwnd: Hwnd, rect: ^Rect) -> Bool #foreign user32 "GetClientRect";

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

proc get_dc             (h: Hwnd) -> Hdc                                                   #foreign user32 "GetDC";
proc set_pixel_format   (hdc: Hdc, pixel_format: i32, pfd: ^PixelFormatDescriptor) -> Bool #foreign gdi32  "SetPixelFormat";
proc choose_pixel_format(hdc: Hdc, pfd: ^PixelFormatDescriptor) -> i32                     #foreign gdi32  "ChoosePixelFormat";
proc swap_buffers       (hdc: Hdc) -> Bool                                                 #foreign gdi32  "SwapBuffers";
proc release_dc         (wnd: Hwnd, hdc: Hdc) -> i32                                       #foreign user32 "ReleaseDC";


const Proc  = type proc() #cc_c;

const MAPVK_VK_TO_CHAR   = 2;
const MAPVK_VK_TO_VSC    = 0;
const MAPVK_VSC_TO_VK    = 1;
const MAPVK_VSC_TO_VK_EX = 3;

proc map_virtual_key(scancode : u32, map_type : u32) -> u32 #foreign user32 "MapVirtualKeyA";

proc get_key_state      (v_key: i32) -> i16 #foreign user32 "GetKeyState";
proc get_async_key_state(v_key: i32) -> i16 #foreign user32 "GetAsyncKeyState";

proc is_key_down(key: KeyCode) -> bool #inline { return get_async_key_state(i32(key)) < 0; }

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
