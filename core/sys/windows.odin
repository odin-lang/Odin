foreign_system_library (
	"kernel32.lib" when ODIN_OS == "windows";
	"user32.lib"   when ODIN_OS == "windows";
	"gdi32.lib"    when ODIN_OS == "windows";
	"winmm.lib"    when ODIN_OS == "windows";
	"shell32.lib"  when ODIN_OS == "windows";
)

type (
	Handle    rawptr;
	Hwnd      Handle;
	Hdc       Handle;
	Hinstance Handle;
	Hicon     Handle;
	Hcursor   Handle;
	Hmenu     Handle;
	Hbrush    Handle;
	Hgdiobj   Handle;
	Hmodule   Handle;
	Hmonitor  Handle;
	Wparam    uint;
	Lparam    int;
	Lresult   int;
	Bool      i32;
	WndProc   proc(Hwnd, u32, Wparam, Lparam) -> Lresult #cc_c;

)

type Point struct #ordered {
	x, y: i32,
}

type WndClassExA struct #ordered {
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

type Msg struct #ordered {
	hwnd:    Hwnd,
	message: u32,
	wparam:  Wparam,
	lparam:  Lparam,
	time:    u32,
	pt:      Point,
}

type Rect struct #ordered {
	left:   i32,
	top:    i32,
	right:  i32,
	bottom: i32,
}

type Filetime struct #ordered {
	lo, hi: u32,
}

type Systemtime struct #ordered {
	year, month: u16,
	day_of_week, day: u16,
	hour, minute, second, millisecond: u16,
}

type ByHandleFileInformation struct #ordered {
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

type FileAttributeData struct #ordered {
	file_attributes:  u32,
	creation_time,
	last_access_time,
	last_write_time:  Filetime,
	file_size_high,
	file_size_low:    u32,
}

type FindData struct #ordered {
    file_attributes:     u32,
    creation_time:       Filetime,
    last_access_time:    Filetime,
    last_write_time:     Filetime,
    file_size_high:      u32,
    file_size_low:       u32,
    reserved0:           u32,
    reserved1:           u32,
    file_name:           [MAX_PATH]u8,
    alternate_file_name: [14]u8,
}

type Security_Attributes struct #ordered {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}



type PixelFormatDescriptor struct #ordered {
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




type Proc proc() #cc_c;

const (
	MAPVK_VK_TO_CHAR   = 2;
	MAPVK_VK_TO_VSC    = 0;
	MAPVK_VSC_TO_VK    = 1;
	MAPVK_VSC_TO_VK_EX = 3;
)



const INVALID_HANDLE = Handle(~int(0));
const (
	FALSE: Bool = 0;
	TRUE        = 1;
)

const (
	CS_VREDRAW    = 0x0001;
	CS_HREDRAW    = 0x0002;
	CS_OWNDC      = 0x0020;
	CW_USEDEFAULT = -0x80000000;

	WS_OVERLAPPED       = 0;
	WS_MAXIMIZEBOX      = 0x00010000;
	WS_MINIMIZEBOX      = 0x00020000;
	WS_THICKFRAME       = 0x00040000;
	WS_SYSMENU          = 0x00080000;
	WS_BORDER           = 0x00800000;
	WS_CAPTION          = 0x00C00000;
	WS_VISIBLE          = 0x10000000;
	WS_POPUP            = 0x80000000;
	WS_OVERLAPPEDWINDOW = WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;
	WS_POPUPWINDOW      = WS_POPUP | WS_BORDER | WS_SYSMENU;

	WM_DESTROY           = 0x0002;
	WM_SIZE	             = 0x0005;
	WM_CLOSE             = 0x0010;
	WM_ACTIVATEAPP       = 0x001C;
	WM_QUIT              = 0x0012;
	WM_KEYDOWN           = 0x0100;
	WM_KEYUP             = 0x0101;
	WM_SIZING            = 0x0214;
	WM_SYSKEYDOWN        = 0x0104;
	WM_SYSKEYUP          = 0x0105;
	WM_WINDOWPOSCHANGED  = 0x0047;
	WM_SETCURSOR         = 0x0020;
	WM_CHAR              = 0x0102;
	WM_ACTIVATE          = 0x0006;
	WM_SETFOCUS          = 0x0007;
	WM_KILLFOCUS         = 0x0008;
	WM_USER              = 0x0400;

	WM_MOUSEWHEEL    = 0x020A;
	WM_MOUSEMOVE     = 0x0200;
	WM_LBUTTONDOWN   = 0x0201;
	WM_LBUTTONUP     = 0x0202;
	WM_LBUTTONDBLCLK = 0x0203;
	WM_RBUTTONDOWN   = 0x0204;
	WM_RBUTTONUP     = 0x0205;
	WM_RBUTTONDBLCLK = 0x0206;
	WM_MBUTTONDOWN   = 0x0207;
	WM_MBUTTONUP     = 0x0208;
	WM_MBUTTONDBLCLK = 0x0209;

	PM_NOREMOVE = 0x0000;
	PM_REMOVE   = 0x0001;
	PM_NOYIELD  = 0x0002;

	BLACK_BRUSH = 4;

	SM_CXSCREEN = 0;
	SM_CYSCREEN = 1;

	SW_SHOW = 5;
)

const COLOR_BACKGROUND = Hbrush(int(1));

const INVALID_SET_FILE_POINTER = ~u32(0);
const HEAP_ZERO_MEMORY = 0x00000008;
const INFINITE = 0xffffffff;
const GWL_STYLE = -16;
const Hwnd_TOP = Hwnd(uint(0));

const BI_RGB         = 0;
const DIB_RGB_COLORS = 0x00;
const SRCCOPY: u32   = 0x00cc0020;

const (
	MONITOR_DEFAULTTONULL    = 0x00000000;
	MONITOR_DEFAULTTOPRIMARY = 0x00000001;
	MONITOR_DEFAULTTONEAREST = 0x00000002;
)
const (
	SWP_FRAMECHANGED  = 0x0020;
	SWP_NOOWNERZORDER = 0x0200;
	SWP_NOZORDER      = 0x0004;
	SWP_NOSIZE        = 0x0001;
	SWP_NOMOVE        = 0x0002;
)




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



type GET_FILEEX_INFO_LEVELS i32;
const (
	GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS = 0;
	GetFileExMaxInfoLevel                         = 1;
)

foreign kernel32 {
	proc get_last_error     () -> i32                                                                                       #link_name "GetLastError";
	proc exit_process       (exit_code: u32)                                                                                #link_name "ExitProcess";
	proc get_module_handle_a(module_name: ^u8) -> Hinstance                                                                 #link_name "GetModuleHandleA";
	proc sleep(ms: i32) -> i32                                                                                              #link_name "Sleep";
	proc query_performance_frequency(result: ^i64) -> i32                                                                   #link_name "QueryPerformanceFrequency";
	proc query_performance_counter  (result: ^i64) -> i32                                                                   #link_name "QueryPerformanceCounter";
	proc output_debug_string_a(c_str: ^u8)                                                                                  #link_name "OutputDebugStringA";

	proc get_command_line_a    () -> ^u8                                                                                    #link_name "GetCommandLineA";
	proc get_command_line_w    () -> ^u16                                                                                   #link_name "GetCommandLineW";
	proc get_system_metrics    (index: i32) -> i32                                                                          #link_name "GetSystemMetrics";
	proc get_current_thread_id () -> u32                                                                                    #link_name "GetCurrentThreadId";

	proc get_system_time_as_file_time(system_time_as_file_time: ^Filetime)                                                  #link_name "GetSystemTimeAsFileTime";
	proc file_time_to_local_file_time(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool                             #link_name "FileTimeToLocalFileTime";
	proc file_time_to_system_time    (file_time: ^Filetime, system_time: ^Systemtime) -> Bool                               #link_name "FileTimeToSystemTime";
	proc system_time_to_file_time    (system_time: ^Systemtime, file_time: ^Filetime) -> Bool                               #link_name "SystemTimeToFileTime";

	proc close_handle  (h: Handle) -> i32                                                                                   #link_name "CloseHandle";
	proc get_std_handle(h: i32) -> Handle                                                                                   #link_name "GetStdHandle";
	proc create_file_a (filename: ^u8, desired_access, share_mode: u32,
	                       security: rawptr,
	                       creation, flags_and_attribs: u32, template_file: Handle) -> Handle                               #link_name "CreateFileA";
	proc read_file (h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool                     #link_name "ReadFile";
	proc write_file(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool                     #link_name "WriteFile";

	proc get_file_size_ex              (file_handle: Handle, file_size: ^i64) -> Bool                                       #link_name "GetFileSizeEx";
	proc get_file_attributes_a         (filename: ^u8) -> u32                                                               #link_name "GetFileAttributesA";
	proc get_file_attributes_ex_a      (filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool    #link_name "GetFileAttributesExA";
	proc get_file_information_by_handle(file_handle: Handle, file_info: ^ByHandleFileInformation) -> Bool                   #link_name "GetFileInformationByHandle";

	proc get_file_type   (file_handle: Handle) -> u32                                                                       #link_name "GetFileType";
	proc set_file_pointer(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #link_name "SetFilePointer";

	proc set_handle_information(obj: Handle, mask, flags: u32) -> Bool                                                      #link_name "SetHandleInformation";

	proc find_first_file_a(file_name : ^u8, data : ^FindData) -> Handle                                                     #link_name "FindFirstFileA";
	proc find_next_file_a (file : Handle, data : ^FindData) -> Bool                                                         #link_name "FindNextFileA";
	proc find_close       (file : Handle) -> Bool                                                                           #link_name "FindClose";


	proc heap_alloc      (h: Handle, flags: u32, bytes: int) -> rawptr                                                      #link_name "HeapAlloc";
	proc heap_realloc    (h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr                                      #link_name "HeapReAlloc";
	proc heap_free       (h: Handle, flags: u32, memory: rawptr) -> Bool                                                    #link_name "HeapFree";
	proc get_process_heap() -> Handle                                                                                       #link_name "GetProcessHeap";


	proc create_semaphore_a    (attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: ^u8) -> Handle   #link_name "CreateSemaphoreA";
	proc release_semaphore     (semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool                        #link_name "ReleaseSemaphore";
	proc wait_for_single_object(handle: Handle, milliseconds: u32) -> u32                                                   #link_name "WaitForSingleObject";


	proc interlocked_compare_exchange  (dst: ^i32, exchange, comparand: i32) -> i32                                         #link_name "InterlockedCompareExchange";
	proc interlocked_exchange          (dst: ^i32, desired: i32) -> i32                                                     #link_name "InterlockedExchange";
	proc interlocked_exchange_add      (dst: ^i32, desired: i32) -> i32                                                     #link_name "InterlockedExchangeAdd";
	proc interlocked_and               (dst: ^i32, desired: i32) -> i32                                                     #link_name "InterlockedAnd";
	proc interlocked_or                (dst: ^i32, desired: i32) -> i32                                                     #link_name "InterlockedOr";

	proc interlocked_compare_exchange64(dst: ^i64, exchange, comparand: i64) -> i64                                         #link_name "InterlockedCompareExchange64";
	proc interlocked_exchange64        (dst: ^i64, desired: i64) -> i64                                                     #link_name "InterlockedExchange64";
	proc interlocked_exchange_add64    (dst: ^i64, desired: i64) -> i64                                                     #link_name "InterlockedExchangeAdd64";
	proc interlocked_and64             (dst: ^i64, desired: i64) -> i64                                                     #link_name "InterlockedAnd64";
	proc interlocked_or64              (dst: ^i64, desired: i64) -> i64                                                     #link_name "InterlockedOr64";

	proc mm_pause          ()                                                                                               #link_name "_mm_pause";
	proc read_write_barrier()                                                                                               #link_name "ReadWriteBarrier";
	proc write_barrier     ()                                                                                               #link_name "WriteBarrier";
	proc read_barrier      ()                                                                                               #link_name "ReadBarrier";


	proc load_library_a  (c_str: ^u8) -> Hmodule                                                                            #link_name "LoadLibraryA";
	proc free_library    (h: Hmodule)                                                                                       #link_name "FreeLibrary";
	proc get_proc_address(h: Hmodule, c_str: ^u8) -> Proc                                                                   #link_name "GetProcAddress";

}

foreign user32 {
	proc get_desktop_window   () -> Hwnd                                                                    #link_name "GetDesktopWindow";
	proc show_cursor          (show : Bool)                                                                 #link_name "ShowCursor";
	proc get_cursor_pos       (p: ^Point) -> i32                                                            #link_name "GetCursorPos";
	proc screen_to_client     (h: Hwnd, p: ^Point) -> i32                                                   #link_name "ScreenToClient";
	proc post_quit_message    (exit_code: i32)                                                              #link_name "PostQuitMessage";
	proc set_window_text_a    (hwnd: Hwnd, c_string: ^u8) -> Bool                                           #link_name "SetWindowTextA";
	proc register_class_ex_a  (wc: ^WndClassExA) -> i16                                                     #link_name "RegisterClassExA";

	proc create_window_ex_a   (ex_style: u32,
                               class_name, title: ^u8,
                               style: u32,
                               x, y, w, h: i32,
                               parent: Hwnd, menu: Hmenu, instance: Hinstance,
                               param: rawptr) -> Hwnd                                                       #link_name "CreateWindowExA";

	proc show_window          (hwnd: Hwnd, cmd_show: i32) -> Bool                                           #link_name "ShowWindow";
	proc translate_message    (msg: ^Msg) -> Bool                                                           #link_name "TranslateMessage";
	proc dispatch_message_a   (msg: ^Msg) -> Lresult                                                        #link_name "DispatchMessageA";
	proc update_window        (hwnd: Hwnd) -> Bool                                                          #link_name "UpdateWindow";
	proc get_message_a        (msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max : u32) -> Bool         #link_name "GetMessageA";
	proc peek_message_a       (msg: ^Msg, hwnd: Hwnd,
	                           msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool                     #link_name "PeekMessageA";


	proc post_message         (hwnd: Hwnd, msg, wparam, lparam : u32) -> Bool                               #link_name "PostMessageA";

	proc def_window_proc_a    (hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult             #link_name "DefWindowProcA";

	proc adjust_window_rect   (rect: ^Rect, style: u32, menu: Bool) -> Bool                                 #link_name "AdjustWindowRect";
	proc get_active_window    () -> Hwnd                                                                    #link_name "GetActiveWindow";

	proc destroy_window       (wnd: Hwnd) -> Bool                                                           #link_name "DestroyWindow";
	proc describe_pixel_format(dc: Hdc, pixel_format: i32, bytes : u32, pfd: ^PixelFormatDescriptor) -> i32 #link_name "DescribePixelFormat";

	proc get_monitor_info_a   (monitor: Hmonitor, mi: ^MonitorInfo) -> Bool                                 #link_name "GetMonitorInfoA";
	proc monitor_from_window  (wnd: Hwnd, flags : u32) -> Hmonitor                                          #link_name "MonitorFromWindow";

	proc set_window_pos       (wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32)       #link_name "SetWindowPos";

	proc get_window_placement (wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                                  #link_name "GetWindowPlacement";
	proc set_window_placement (wnd: Hwnd, wndpl: ^WindowPlacement) -> Bool                                  #link_name "SetWindowPlacement";
	proc get_window_rect      (wnd: Hwnd, rect: ^Rect) -> Bool                                              #link_name "GetWindowRect";

	proc get_window_long_ptr_a(wnd: Hwnd, index: i32) -> i64                                                #link_name "GetWindowLongPtrA";
	proc set_window_long_ptr_a(wnd: Hwnd, index: i32, new: i64) -> i64                                      #link_name "SetWindowLongPtrA";

	proc get_window_text      (wnd: Hwnd, str: ^u8, maxCount: i32) -> i32                                   #link_name "GetWindowText";

	proc get_client_rect (hwnd: Hwnd, rect: ^Rect) -> Bool                                                  #link_name "GetClientRect";

	proc get_dc             (h: Hwnd) -> Hdc                                                                #link_name "GetDC";
	proc release_dc         (wnd: Hwnd, hdc: Hdc) -> i32                                                    #link_name "ReleaseDC";

	proc map_virtual_key(scancode : u32, map_type : u32) -> u32                                             #link_name "MapVirtualKeyA";

	proc get_key_state      (v_key: i32) -> i16                                                             #link_name "GetKeyState";
	proc get_async_key_state(v_key: i32) -> i16                                                             #link_name "GetAsyncKeyState";
}

foreign gdi32 {
	proc get_stock_object(fn_object: i32) -> Hgdiobj                                           #link_name "GetStockObject";

	proc stretch_dibits( hdc: Hdc,
	                        x_dst, y_dst, width_dst, height_dst: i32,
	                        x_src, y_src, width_src, header_src: i32,
	                        bits: rawptr, bits_info: ^BitmapInfo,
	                        usage: u32,
	                        rop: u32) -> i32                                                   #link_name "StretchDIBits";

	proc set_pixel_format   (hdc: Hdc, pixel_format: i32, pfd: ^PixelFormatDescriptor) -> Bool #link_name "SetPixelFormat";
	proc choose_pixel_format(hdc: Hdc, pfd: ^PixelFormatDescriptor) -> i32                     #link_name "ChoosePixelFormat";
	proc swap_buffers       (hdc: Hdc) -> Bool                                                 #link_name "SwapBuffers";

}

foreign shell32 {
	proc command_line_to_argv_w(cmd_list: ^u16, num_args: ^i32) -> ^^u16 #link_name "CommandLineToArgvW";
}

foreign winmm {
	proc time_get_time() -> u32 #link_name "timeGetTime";
}



proc get_query_performance_frequency() -> i64 {
	var r: i64;
	query_performance_frequency(&r);
	return r;
}

proc HIWORD(wParam: Wparam) -> u16 { return u16((u32(wParam) >> 16) & 0xffff); }
proc HIWORD(lParam: Lparam) -> u16 { return u16((u32(lParam) >> 16) & 0xffff); }
proc LOWORD(wParam: Wparam) -> u16 { return u16(wParam); }
proc LOWORD(lParam: Lparam) -> u16 { return u16(lParam); }

proc is_key_down(key: KeyCode) -> bool #inline { return get_async_key_state(i32(key)) < 0; }




const (
	MAX_PATH = 0x00000104;

	HANDLE_FLAG_INHERIT = 1;
	HANDLE_FLAG_PROTECT_FROM_CLOSE = 2;

	FILE_BEGIN   = 0;
	FILE_CURRENT = 1;
	FILE_END     = 2;

	FILE_SHARE_READ      = 0x00000001;
	FILE_SHARE_WRITE     = 0x00000002;
	FILE_SHARE_DELETE    = 0x00000004;
	FILE_GENERIC_ALL     = 0x10000000;
	FILE_GENERIC_EXECUTE = 0x20000000;
	FILE_GENERIC_WRITE   = 0x40000000;
	FILE_GENERIC_READ    = 0x80000000;

	FILE_APPEND_DATA = 0x0004;

	STD_INPUT_HANDLE  = -10;
	STD_OUTPUT_HANDLE = -11;
	STD_ERROR_HANDLE  = -12;

	CREATE_NEW        = 1;
	CREATE_ALWAYS     = 2;
	OPEN_EXISTING     = 3;
	OPEN_ALWAYS       = 4;
	TRUNCATE_EXISTING = 5;

	INVALID_FILE_ATTRIBUTES  = -1;

	FILE_ATTRIBUTE_READONLY             = 0x00000001;
	FILE_ATTRIBUTE_HIDDEN               = 0x00000002;
	FILE_ATTRIBUTE_SYSTEM               = 0x00000004;
	FILE_ATTRIBUTE_DIRECTORY            = 0x00000010;
	FILE_ATTRIBUTE_ARCHIVE              = 0x00000020;
	FILE_ATTRIBUTE_DEVICE               = 0x00000040;
	FILE_ATTRIBUTE_NORMAL               = 0x00000080;
	FILE_ATTRIBUTE_TEMPORARY            = 0x00000100;
	FILE_ATTRIBUTE_SPARSE_FILE          = 0x00000200;
	FILE_ATTRIBUTE_REPARSE_Point        = 0x00000400;
	FILE_ATTRIBUTE_COMPRESSED           = 0x00000800;
	FILE_ATTRIBUTE_OFFLINE              = 0x00001000;
	FILE_ATTRIBUTE_NOT_CONTENT_INDEXED  = 0x00002000;
	FILE_ATTRIBUTE_ENCRYPTED            = 0x00004000;

	FILE_TYPE_DISK = 0x0001;
	FILE_TYPE_CHAR = 0x0002;
	FILE_TYPE_PIPE = 0x0003;
)


type MonitorInfo struct #ordered {
	size:      u32,
	monitor:   Rect,
	work:      Rect,
	flags:     u32,
}

type WindowPlacement struct #ordered {
	length:     u32,
	flags:      u32,
	show_cmd:   u32,
	min_pos:    Point,
	max_pos:    Point,
	normal_pos: Rect,
}

type BitmapInfoHeader struct #ordered {
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
type BitmapInfo struct #ordered {
	using header: BitmapInfoHeader,
	colors:       [1]RgbQuad,
}


type RgbQuad struct #ordered { blue, green, red, reserved: u8 }


type KeyCode enum i32 {
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
