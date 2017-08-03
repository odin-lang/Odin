foreign_system_library (
	"kernel32.lib" when ODIN_OS == "windows";
	"user32.lib"   when ODIN_OS == "windows";
	"gdi32.lib"    when ODIN_OS == "windows";
	"winmm.lib"    when ODIN_OS == "windows";
	"shell32.lib"  when ODIN_OS == "windows";
)

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
Hmonitor  :: Handle;
Wparam    :: uint;
Lparam    :: int;
Lresult   :: int;
Wnd_Proc  :: proc(Hwnd, u32, Wparam, Lparam) -> Lresult #cc_c;

Bool :: i32;
FALSE: Bool : 0;
TRUE:  Bool : 1;

Point :: struct #ordered {
	x, y: i32;
}

Wnd_Class_Ex_A :: struct #ordered {
	size, style:           u32;
	wnd_proc:              Wnd_Proc;
	cls_extra, wnd_extra:  i32;
	instance:              Hinstance;
	icon:                  Hicon;
	cursor:                Hcursor;
	background:            Hbrush;
	menu_name, class_name: ^u8;
	sm:                    Hicon;
}

Msg :: struct #ordered {
	hwnd:    Hwnd;
	message: u32;
	wparam:  Wparam;
	lparam:  Lparam;
	time:    u32;
	pt:      Point;
}

Rect :: struct #ordered {
	left:   i32;
	top:    i32;
	right:  i32;
	bottom: i32;
}

Filetime :: struct #ordered {
	lo, hi: u32;
}

Systemtime :: struct #ordered {
	year, month: u16;
	day_of_week, day: u16;
	hour, minute, second, millisecond: u16;
}

By_Handle_File_Information :: struct #ordered {
	file_attributes:      u32;
	creation_time,
	last_access_time,
	last_write_time:      Filetime;
	volume_serial_number,
	file_size_high,
	file_size_low,
	number_of_links,
	file_index_high,
	file_index_low:       u32;
}

File_Attribute_Data :: struct #ordered {
	file_attributes:  u32;
	creation_time,
	last_access_time,
	last_write_time:  Filetime;
	file_size_high,
	file_size_low:    u32;
}

Find_Data :: struct #ordered{
    file_attributes:     u32;
    creation_time:       Filetime;
    last_access_time:    Filetime;
    last_write_time:     Filetime;
    file_size_high:      u32;
    file_size_low:       u32;
    reserved0:           u32;
    reserved1:           u32;
    file_name:           [MAX_PATH]u8;
    alternate_file_name: [14]u8;
}

Security_Attributes :: struct #ordered {
	length:              u32;
	security_descriptor: rawptr;
	inherit_handle:      Bool;
}



Pixel_Format_Descriptor :: struct #ordered {
	size,
	version,
	flags: u32;

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
	reserved: u8;

	layer_mask,
	visible_mask,
	damage_mask: u32;
}

Critical_Section :: struct #ordered {
	debug_info:      ^Critical_Section_Debug;

	lock_count:      i32;
	recursion_count: i32;
	owning_thread:   Handle;
	lock_semaphore:  Handle;
	spin_count:      ^u32;
}

Critical_Section_Debug :: struct #ordered {
	typ:                           u16;
	creator_back_trace_index:      u16;
	critical_section:              ^Critical_Section;
	process_locks_list:            ^List_Entry;
	entry_count:                   u32;
	contention_count:              u32;
	flags:                         u32;
	creator_back_trace_index_high: u16;
	spare_word:                    u16;
}

List_Entry :: struct #ordered {flink, blink: ^List_Entry};



MAPVK_VK_TO_VSC    :: 0;
MAPVK_VSC_TO_VK    :: 1;
MAPVK_VK_TO_CHAR   :: 2;
MAPVK_VSC_TO_VK_EX :: 3;




INVALID_HANDLE :: Handle(~int(0));

CREATE_SUSPENDED                  :: 0x00000004;
STACK_SIZE_PARAM_IS_A_RESERVATION :: 0x00010000;
WAIT_ABANDONED :: 0x00000080;
WAIT_OBJECT_0  :: 0;
WAIT_TIMEOUT   :: 0x00000102;
WAIT_FAILED    :: 0xffffffff;

CS_VREDRAW    :: 0x0001;
CS_HREDRAW    :: 0x0002;
CS_OWNDC      :: 0x0020;
CW_USEDEFAULT :: -0x80000000;

WS_OVERLAPPED       :: 0;
WS_MAXIMIZEBOX      :: 0x00010000;
WS_MINIMIZEBOX      :: 0x00020000;
WS_THICKFRAME       :: 0x00040000;
WS_SYSMENU          :: 0x00080000;
WS_BORDER           :: 0x00800000;
WS_CAPTION          :: 0x00C00000;
WS_VISIBLE          :: 0x10000000;
WS_POPUP            :: 0x80000000;
WS_OVERLAPPEDWINDOW :: WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;
WS_POPUPWINDOW      :: WS_POPUP | WS_BORDER | WS_SYSMENU;

WM_DESTROY           :: 0x0002;
WM_SIZE	             :: 0x0005;
WM_CLOSE             :: 0x0010;
WM_ACTIVATEAPP       :: 0x001C;
WM_QUIT              :: 0x0012;
WM_KEYDOWN           :: 0x0100;
WM_KEYUP             :: 0x0101;
WM_SIZING            :: 0x0214;
WM_SYSKEYDOWN        :: 0x0104;
WM_SYSKEYUP          :: 0x0105;
WM_WINDOWPOSCHANGED  :: 0x0047;
WM_SETCURSOR         :: 0x0020;
WM_CHAR              :: 0x0102;
WM_ACTIVATE          :: 0x0006;
WM_SETFOCUS          :: 0x0007;
WM_KILLFOCUS         :: 0x0008;
WM_USER              :: 0x0400;

WM_MOUSEWHEEL    :: 0x020A;
WM_MOUSEMOVE     :: 0x0200;
WM_LBUTTONDOWN   :: 0x0201;
WM_LBUTTONUP     :: 0x0202;
WM_LBUTTONDBLCLK :: 0x0203;
WM_RBUTTONDOWN   :: 0x0204;
WM_RBUTTONUP     :: 0x0205;
WM_RBUTTONDBLCLK :: 0x0206;
WM_MBUTTONDOWN   :: 0x0207;
WM_MBUTTONUP     :: 0x0208;
WM_MBUTTONDBLCLK :: 0x0209;

PM_NOREMOVE :: 0x0000;
PM_REMOVE   :: 0x0001;
PM_NOYIELD  :: 0x0002;

BLACK_BRUSH :: 4;

SM_CXSCREEN :: 0;
SM_CYSCREEN :: 1;

SW_SHOW :: 5;

COLOR_BACKGROUND :: Hbrush(int(1));

INVALID_SET_FILE_POINTER :: ~u32(0);
HEAP_ZERO_MEMORY         :: 0x00000008;
INFINITE                 :: 0xffffffff;
GWL_STYLE                :: -16;
Hwnd_TOP                 :: Hwnd(uint(0));

BI_RGB         :: 0;
DIB_RGB_COLORS :: 0x00;
SRCCOPY: u32    : 0x00cc0020;


MONITOR_DEFAULTTONULL    :: 0x00000000;
MONITOR_DEFAULTTOPRIMARY :: 0x00000001;
MONITOR_DEFAULTTONEAREST :: 0x00000002;

SWP_FRAMECHANGED  :: 0x0020;
SWP_NOOWNERZORDER :: 0x0200;
SWP_NOZORDER      :: 0x0004;
SWP_NOSIZE        :: 0x0001;
SWP_NOMOVE        :: 0x0002;




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

GET_FILEEX_INFO_LEVELS :: i32;
GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0;
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1;


foreign kernel32 {
	get_last_error              :: proc() -> i32                                                                               #cc_std #link_name "GetLastError"                 ---;
	exit_process                :: proc(exit_code: u32)                                                                        #cc_std #link_name "ExitProcess"                  ---;
	get_module_handle_a         :: proc(module_name: ^u8) -> Hinstance                                                         #cc_std #link_name "GetModuleHandleA"             ---;
	sleep                       :: proc(ms: i32) -> i32                                                                        #cc_std #link_name "Sleep"                        ---;
	query_performance_frequency :: proc(result: ^i64) -> i32                                                                   #cc_std #link_name "QueryPerformanceFrequency"    ---;
	query_performance_counter   :: proc(result: ^i64) -> i32                                                                   #cc_std #link_name "QueryPerformanceCounter"      ---;
	output_debug_string_a       :: proc(c_str: ^u8)                                                                            #cc_std #link_name "OutputDebugStringA"           ---;

	get_command_line_a    :: proc() -> ^u8                                                                                     #cc_std #link_name "GetCommandLineA"              ---;
	get_command_line_w    :: proc() -> ^u16                                                                                    #cc_std #link_name "GetCommandLineW"              ---;
	get_system_metrics    :: proc(index: i32) -> i32                                                                           #cc_std #link_name "GetSystemMetrics"             ---;
	get_current_thread_id :: proc() -> u32                                                                                     #cc_std #link_name "GetCurrentThreadId"           ---;

	get_system_time_as_file_time :: proc(system_time_as_file_time: ^Filetime)                                                  #cc_std #link_name "GetSystemTimeAsFileTime"      ---;
	file_time_to_local_file_time :: proc(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool                             #cc_std #link_name "FileTimeToLocalFileTime"      ---;
	file_time_to_system_time     :: proc(file_time: ^Filetime, system_time: ^Systemtime) -> Bool                               #cc_std #link_name "FileTimeToSystemTime"         ---;
	system_time_to_file_time     :: proc(system_time: ^Systemtime, file_time: ^Filetime) -> Bool                               #cc_std #link_name "SystemTimeToFileTime"         ---;

	close_handle   :: proc(h: Handle) -> i32                                                                                   #cc_std #link_name "CloseHandle"                  ---;
	get_std_handle :: proc(h: i32) -> Handle                                                                                   #cc_std #link_name "GetStdHandle"                 ---;
	create_file_a  :: proc(filename: ^u8, desired_access, share_mode: u32,
		                   security: rawptr,
		                   creation, flags_and_attribs: u32, template_file: Handle) -> Handle                                  #cc_std #link_name "CreateFileA"                  ---;
	read_file  :: proc(h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool                     #cc_std #link_name "ReadFile"                     ---;
	write_file :: proc(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool                     #cc_std #link_name "WriteFile"                    ---;

	get_file_size_ex               :: proc(file_handle: Handle, file_size: ^i64) -> Bool                                       #cc_std #link_name "GetFileSizeEx"                ---;
	get_file_attributes_a          :: proc(filename: ^u8) -> u32                                                               #cc_std #link_name "GetFileAttributesA"           ---;
	get_file_attributes_ex_a       :: proc(filename: ^u8, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool    #cc_std #link_name "GetFileAttributesExA"         ---;
	get_file_information_by_handle :: proc(file_handle: Handle, file_info: ^By_Handle_File_Information) -> Bool                #cc_std #link_name "GetFileInformationByHandle"   ---;

	get_file_type    :: proc(file_handle: Handle) -> u32                                                                       #cc_std #link_name "GetFileType"                  ---;
	set_file_pointer :: proc(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 #cc_std #link_name "SetFilePointer"               ---;

	set_handle_information :: proc(obj: Handle, mask, flags: u32) -> Bool                                                      #cc_std #link_name "SetHandleInformation"         ---;

	find_first_file_a :: proc(file_name : ^u8, data : ^Find_Data) -> Handle                                                    #cc_std #link_name "FindFirstFileA"               ---;
	find_next_file_a  :: proc(file : Handle, data : ^Find_Data) -> Bool                                                        #cc_std #link_name "FindNextFileA"                ---;
	find_close        :: proc(file : Handle) -> Bool                                                                           #cc_std #link_name "FindClose"                    ---;


	heap_alloc       :: proc(h: Handle, flags: u32, bytes: int) -> rawptr                                                      #cc_std #link_name "HeapAlloc"                    ---;
	heap_realloc     :: proc(h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr                                      #cc_std #link_name "HeapReAlloc"                  ---;
	heap_free        :: proc(h: Handle, flags: u32, memory: rawptr) -> Bool                                                    #cc_std #link_name "HeapFree"                     ---;
	get_process_heap :: proc() -> Handle                                                                                       #cc_std #link_name "GetProcessHeap"               ---;


	create_semaphore_a     :: proc(attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: ^u8) -> Handle   #cc_std #link_name "CreateSemaphoreA"             ---;
	release_semaphore      :: proc(semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool                        #cc_std #link_name "ReleaseSemaphore"             ---;
	wait_for_single_object :: proc(handle: Handle, milliseconds: u32) -> u32                                                   #cc_std #link_name "WaitForSingleObject"          ---;


	interlocked_compare_exchange :: proc(dst: ^i32, exchange, comparand: i32) -> i32                                           #cc_c   #link_name "InterlockedCompareExchange"   ---;
	interlocked_exchange         :: proc(dst: ^i32, desired: i32) -> i32                                                       #cc_c   #link_name "InterlockedExchange"          ---;
	interlocked_exchange_add     :: proc(dst: ^i32, desired: i32) -> i32                                                       #cc_c   #link_name "InterlockedExchangeAdd"       ---;
	interlocked_and              :: proc(dst: ^i32, desired: i32) -> i32                                                       #cc_c   #link_name "InterlockedAnd"               ---;
	interlocked_or               :: proc(dst: ^i32, desired: i32) -> i32                                                       #cc_c   #link_name "InterlockedOr"                ---;

	interlocked_compare_exchange64 :: proc(dst: ^i64, exchange, comparand: i64) -> i64                                         #cc_c   #link_name "InterlockedCompareExchange64" ---;
	interlocked_exchange64         :: proc(dst: ^i64, desired: i64) -> i64                                                     #cc_c   #link_name "InterlockedExchange64"        ---;
	interlocked_exchange_add64     :: proc(dst: ^i64, desired: i64) -> i64                                                     #cc_c   #link_name "InterlockedExchangeAdd64"     ---;
	interlocked_and64              :: proc(dst: ^i64, desired: i64) -> i64                                                     #cc_c   #link_name "InterlockedAnd64"             ---;
	interlocked_or64               :: proc(dst: ^i64, desired: i64) -> i64                                                     #cc_c   #link_name "InterlockedOr64"              ---;

	mm_pause           :: proc()                                                                                               #cc_std #link_name "_mm_pause"                    ---;
	read_write_barrier :: proc()                                                                                               #cc_std #link_name "ReadWriteBarrier"             ---;
	write_barrier      :: proc()                                                                                               #cc_std #link_name "WriteBarrier"                 ---;
	read_barrier       :: proc()                                                                                               #cc_std #link_name "ReadBarrier"                  ---;

	create_thread        :: proc(thread_attributes: ^Security_Attributes, stack_size: int, start_routine: rawptr,
	                             parameter: rawptr, creation_flags: u32, thread_id: ^u32) -> Handle                            #cc_std #link_name "CreateThread"                 ---;
	resume_thread        :: proc(thread: Handle) -> u32                                                                        #cc_std #link_name "ResumeThread"                 ---;
	get_thread_priority  :: proc(thread: Handle) -> i32                                                                        #cc_std #link_name "GetThreadPriority"            ---;
	set_thread_priority  :: proc(thread: Handle, priority: i32) -> Bool                                                        #cc_std #link_name "SetThreadPriority"            ---;
	get_exit_code_thread :: proc(thread: Handle, exit_code: ^u32) -> Bool                                                      #cc_std #link_name "GetExitCodeThread"            ---;

	initialize_critical_section                :: proc(critical_section: ^Critical_Section)                                    #cc_std #link_name "InitializeCriticalSection"             ---;
	initialize_critical_section_and_spin_count :: proc(critical_section: ^Critical_Section, spin_count: u32)                   #cc_std #link_name "InitializeCriticalSectionAndSpinCount" ---;
	delete_critical_section                    :: proc(critical_section: ^Critical_Section)                                    #cc_std #link_name "DeleteCriticalSection"                 ---;
	set_critical_section_spin_count            :: proc(critical_section: ^Critical_Section, spin_count: u32) -> u32            #cc_std #link_name "SetCriticalSectionSpinCount"           ---;
	try_enter_critical_section                 :: proc(critical_section: ^Critical_Section) -> Bool                            #cc_std #link_name "TryEnterCriticalSection"               ---;
	enter_critical_section                     :: proc(critical_section: ^Critical_Section)                                    #cc_std #link_name "EnterCriticalSection"                  ---;
	leave_critical_section                     :: proc(critical_section: ^Critical_Section)                                    #cc_std #link_name "LeaveCriticalSection"                  ---;

	create_event_a :: proc(event_attributes: ^Security_Attributes, manual_reset, initial_state: Bool, name: ^u8) -> Handle     #cc_std #link_name "CreateEventA"                 ---;

	load_library_a   :: proc(c_str: ^u8) -> Hmodule                                                                            #cc_std #link_name "LoadLibraryA"                 ---;
	free_library     :: proc(h: Hmodule)                                                                                       #cc_std #link_name "FreeLibrary"                  ---;
	get_proc_address :: proc(h: Hmodule, c_str: ^u8) -> rawptr                                                                 #cc_std #link_name "GetProcAddress"               ---;

}

foreign user32 {
	get_desktop_window  :: proc() -> Hwnd                                                                       #cc_std #link_name "GetDesktopWindow"    ---;
	show_cursor         :: proc(show : Bool)                                                                    #cc_std #link_name "ShowCursor"          ---;
	get_cursor_pos      :: proc(p: ^Point) -> i32                                                               #cc_std #link_name "GetCursorPos"        ---;
	screen_to_client    :: proc(h: Hwnd, p: ^Point) -> i32                                                      #cc_std #link_name "ScreenToClient"      ---;
	post_quit_message   :: proc(exit_code: i32)                                                                 #cc_std #link_name "PostQuitMessage"     ---;
	set_window_text_a   :: proc(hwnd: Hwnd, c_string: ^u8) -> Bool                                              #cc_std #link_name "SetWindowTextA"      ---;
	register_class_ex_a :: proc(wc: ^Wnd_Class_Ex_A) -> i16                                                     #cc_std #link_name "RegisterClassExA"    ---;

	create_window_ex_a  :: proc(ex_style: u32,
	                            class_name, title: ^u8,
	                            style: u32,
	                            x, y, w, h: i32,
	                            parent: Hwnd, menu: Hmenu, instance: Hinstance,
	                            param: rawptr) -> Hwnd                                                          #cc_std #link_name "CreateWindowExA"     ---;

	show_window        :: proc(hwnd: Hwnd, cmd_show: i32) -> Bool                                               #cc_std #link_name "ShowWindow"          ---;
	translate_message  :: proc(msg: ^Msg) -> Bool                                                               #cc_std #link_name "TranslateMessage"    ---;
	dispatch_message_a :: proc(msg: ^Msg) -> Lresult                                                            #cc_std #link_name "DispatchMessageA"    ---;
	update_window      :: proc(hwnd: Hwnd) -> Bool                                                              #cc_std #link_name "UpdateWindow"        ---;
	get_message_a      :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max : u32) -> Bool             #cc_std #link_name "GetMessageA"         ---;
	peek_message_a     :: proc(msg: ^Msg, hwnd: Hwnd,
		                       msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool                         #cc_std #link_name "PeekMessageA"        ---;


	post_message          :: proc(hwnd: Hwnd, msg, wparam, lparam : u32) -> Bool                                #cc_std #link_name "PostMessageA"        ---;

	def_window_proc_a     :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult              #cc_std #link_name "DefWindowProcA"      ---;

	adjust_window_rect    :: proc(rect: ^Rect, style: u32, menu: Bool) -> Bool                                  #cc_std #link_name "AdjustWindowRect"    ---;
	get_active_window     :: proc() -> Hwnd                                                                     #cc_std #link_name "GetActiveWindow"     ---;

	destroy_window        :: proc(wnd: Hwnd) -> Bool                                                            #cc_std #link_name "DestroyWindow"       ---;
	describe_pixel_format :: proc(dc: Hdc, pixel_format: i32, bytes: u32, pfd: ^Pixel_Format_Descriptor) -> i32 #cc_std #link_name "DescribePixelFormat" ---;

	get_monitor_info_a    :: proc(monitor: Hmonitor, mi: ^Monitor_Info) -> Bool                                 #cc_std #link_name "GetMonitor_InfoA"     ---;
	monitor_from_window   :: proc(wnd: Hwnd, flags : u32) -> Hmonitor                                           #cc_std #link_name "MonitorFromWindow"   ---;

	set_window_pos        :: proc(wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32)        #cc_std #link_name "SetWindowPos"        ---;

	get_window_placement  :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool                                  #cc_std #link_name "GetWindowPlacement"  ---;
	set_window_placement  :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool                                  #cc_std #link_name "SetWindowPlacement"  ---;
	get_window_rect       :: proc(wnd: Hwnd, rect: ^Rect) -> Bool                                               #cc_std #link_name "GetWindowRect"       ---;

	get_window_long_ptr_a :: proc(wnd: Hwnd, index: i32) -> i64                                                 #cc_std #link_name "GetWindowLongPtrA"   ---;
	set_window_long_ptr_a :: proc(wnd: Hwnd, index: i32, new: i64) -> i64                                       #cc_std #link_name "SetWindowLongPtrA"   ---;

	get_window_text       :: proc(wnd: Hwnd, str: ^u8, maxCount: i32) -> i32                                    #cc_std #link_name "GetWindowText"       ---;

	get_client_rect       :: proc(hwnd: Hwnd, rect: ^Rect) -> Bool                                              #cc_std #link_name "GetClientRect"       ---;

	get_dc                :: proc(h: Hwnd) -> Hdc                                                               #cc_std #link_name "GetDC"               ---;
	release_dc            :: proc(wnd: Hwnd, hdc: Hdc) -> i32                                                   #cc_std #link_name "ReleaseDC"           ---;

	map_virtual_key       :: proc(scancode : u32, map_type : u32) -> u32                                        #cc_std #link_name "MapVirtualKeyA"      ---;

	get_key_state         :: proc(v_key: i32) -> i16                                                            #cc_std #link_name "GetKeyState"         ---;
	get_async_key_state   :: proc(v_key: i32) -> i16                                                            #cc_std #link_name "GetAsyncKeyState"    ---;
}

foreign gdi32 {
	get_stock_object :: proc(fn_object: i32) -> Hgdiobj                                                         #cc_std #link_name "GetStockObject"    ---;

	stretch_dibits   :: proc(hdc: Hdc,
	                        x_dst, y_dst, width_dst, height_dst: i32,
	                        x_src, y_src, width_src, header_src: i32,
	                        bits: rawptr, bits_info: ^BitmapInfo,
	                        usage: u32,
	                        rop: u32) -> i32                                                                    #cc_std #link_name "StretchDIBits"     ---;

	set_pixel_format    :: proc(hdc: Hdc, pixel_format: i32, pfd: ^Pixel_Format_Descriptor) -> Bool             #cc_std #link_name "SetPixelFormat"    ---;
	choose_pixel_format :: proc(hdc: Hdc, pfd: ^Pixel_Format_Descriptor) -> i32                                 #cc_std #link_name "ChoosePixelFormat" ---;
	swap_buffers        :: proc(hdc: Hdc) -> Bool                                                               #cc_std #link_name "SwapBuffers"       ---;

}

foreign shell32 {
	command_line_to_argv_w :: proc(cmd_list: ^u16, num_args: ^i32) -> ^^u16 #cc_std #link_name "CommandLineToArgvW" ---;
}

foreign winmm {
	time_get_time :: proc() -> u32 #cc_std #link_name "timeGetTime" ---;
}



get_query_performance_frequency :: proc() -> i64 {
	r: i64;
	query_performance_frequency(&r);
	return r;
}

HIWORD :: proc(wParam: Wparam) -> u16 { return u16((u32(wParam) >> 16) & 0xffff); }
HIWORD :: proc(lParam: Lparam) -> u16 { return u16((u32(lParam) >> 16) & 0xffff); }
LOWORD :: proc(wParam: Wparam) -> u16 { return u16(wParam); }
LOWORD :: proc(lParam: Lparam) -> u16 { return u16(lParam); }

is_key_down :: proc(key: Key_Code) -> bool #inline { return get_async_key_state(i32(key)) < 0; }





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


Monitor_Info :: struct #ordered {
	size:      u32;
	monitor:   Rect;
	work:      Rect;
	flags:     u32;
}

Window_Placement :: struct #ordered {
	length:     u32;
	flags:      u32;
	show_cmd:   u32;
	min_pos:    Point;
	max_pos:    Point;
	normal_pos: Rect;
}

Bitmap_Info_Header :: struct #ordered {
	size:              u32;
	width, height:     i32;
	planes, bit_count: i16;
	compression:       u32;
	size_image:        u32;
	x_pels_per_meter:  i32;
	y_pels_per_meter:  i32;
	clr_used:          u32;
	clr_important:     u32;
}
BitmapInfo :: struct #ordered {
	using header: Bitmap_Info_Header;
	colors:       [1]Rgb_Quad;
}


Rgb_Quad :: struct #ordered {blue, green, red, reserved: u8}


Key_Code :: enum i32 {
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
