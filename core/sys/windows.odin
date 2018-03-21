when ODIN_OS == "windows" {
	foreign import "system:kernel32.lib"
	foreign import "system:user32.lib"
	foreign import "system:gdi32.lib"
	foreign import "system:winmm.lib"
	foreign import "system:shell32.lib"
}

Handle    :: distinct rawptr;
Hwnd      :: distinct Handle;
Hdc       :: distinct Handle;
Hinstance :: distinct Handle;
Hicon     :: distinct Handle;
Hcursor   :: distinct Handle;
Hmenu     :: distinct Handle;
Hbrush    :: distinct Handle;
Hgdiobj   :: distinct Handle;
Hmodule   :: distinct Handle;
Hmonitor  :: distinct Handle;
Hrawinput :: distinct Handle;
HKL       :: distinct Handle;
Wparam    :: distinct uint;
Lparam    :: distinct int;
Lresult   :: distinct int;
Wnd_Proc  :: distinct #type proc "c" (Hwnd, u32, Wparam, Lparam) -> Lresult;

Long_Ptr :: distinct int;

Bool :: distinct b32;

Wstring :: ^u16;

Point :: struct {
	x, y: i32,
}

Wnd_Class_Ex_A :: struct {
	size, style:           u32,
	wnd_proc:              Wnd_Proc,
	cls_extra, wnd_extra:  i32,
	instance:              Hinstance,
	icon:                  Hicon,
	cursor:                Hcursor,
	background:            Hbrush,
	menu_name, class_name: cstring,
	sm:                    Hicon,
}

Wnd_Class_Ex_W :: struct {
	size, style:           u32,
	wnd_proc:              Wnd_Proc,
	cls_extra, wnd_extra:  i32,
	instance:              Hinstance,
	icon:                  Hicon,
	cursor:                Hcursor,
	background:            Hbrush,
	menu_name, class_name: Wstring,
	sm:                    Hicon,
}


Msg :: struct {
	hwnd:    Hwnd,
	message: u32,
	wparam:  Wparam,
	lparam:  Lparam,
	time:    u32,
	pt:      Point,
}

Rect :: struct {
	left:   i32,
	top:    i32,
	right:  i32,
	bottom: i32,
}

Filetime :: struct {
	lo, hi: u32,
}

Systemtime :: struct {
	year, month: u16,
	day_of_week, day: u16,
	hour, minute, second, millisecond: u16,
}

By_Handle_File_Information :: struct {
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

File_Attribute_Data :: struct {
	file_attributes:  u32,
	creation_time,
	last_access_time,
	last_write_time:  Filetime,
	file_size_high,
	file_size_low:    u32,
}

Find_Data_W :: struct{
    file_attributes:     u32,
    creation_time:       Filetime,
    last_access_time:    Filetime,
    last_write_time:     Filetime,
    file_size_high:      u32,
    file_size_low:       u32,
    reserved0:           u32,
    reserved1:           u32,
    file_name:           [MAX_PATH]u16,
    alternate_file_name: [14]u16,
}

Find_Data_A :: struct{
    file_attributes:     u32,
    creation_time:       Filetime,
    last_access_time:    Filetime,
    last_write_time:     Filetime,
    file_size_high:      u32,
    file_size_low:       u32,
    reserved0:           u32,
    reserved1:           u32,
    file_name:           [MAX_PATH]byte,
    alternate_file_name: [14]byte,
}

Security_Attributes :: struct {
	length:              u32,
	security_descriptor: rawptr,
	inherit_handle:      Bool,
}

Process_Information :: struct {
	process:    Handle,
	thread:     Handle,
	process_id: u32,
	thread_id:  u32
}

Startup_Info :: struct {
    cb:             u32,
    reserved:       Wstring,
    desktop:        Wstring,
    title:          Wstring,
    x:              u32,
    y:              u32,
    x_size:         u32,
    y_size:         u32,
    x_count_chars:  u32,
    y_count_chars:  u32,
    fill_attribute: u32,
    flags:          u32,
    show_window:    u16,
    _:              u16,
    _:              cstring,
    stdin:          Handle,
    stdout:         Handle,
    stderr:         Handle,
}

Pixel_Format_Descriptor :: struct {
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

Critical_Section :: struct {
	debug_info:      ^Critical_Section_Debug,

	lock_count:      i32,
	recursion_count: i32,
	owning_thread:   Handle,
	lock_semaphore:  Handle,
	spin_count:      ^u32,
}

Critical_Section_Debug :: struct {
	typ:                           u16,
	creator_back_trace_index:      u16,
	critical_section:              ^Critical_Section,
	process_locks_list:            ^List_Entry,
	entry_count:                   u32,
	contention_count:              u32,
	flags:                         u32,
	creator_back_trace_index_high: u16,
	spare_word:                    u16,
}

List_Entry :: struct {flink, blink: ^List_Entry};


Raw_Input_Device :: struct {
	usage_page: u16,
	usage:      u16,
	flags:      u32,
	wnd_target: Hwnd,
}

Raw_Input_Header :: struct {
	kind:   u32,
	size:   u32,
	device: Handle,
	wparam: Wparam,
}

Raw_HID :: struct {
	size_hid: u32,
	count:    u32,
	raw_data: [1]byte,
}

Raw_Keyboard :: struct {
	make_code:         u16,
	flags:             u16,
	reserved:          u16,
	vkey:              u16,
	message:           u32,
	extra_information: u32,
}

Raw_Mouse :: struct {
	flags: u16,
	using data: struct #raw_union {
		buttons: u32,
		using _: struct {
			button_flags: u16,
			button_data:  u16,
		},
	},
	raw_buttons:       u32,
	last_x:            i32,
	last_y:            i32,
	extra_information: u32,
}

Raw_Input :: struct {
	using header: Raw_Input_Header,
	data: struct #raw_union {
		mouse:    Raw_Mouse,
		keyboard: Raw_Keyboard,
		hid:      Raw_HID,
	},
}


Overlapped :: struct {
    internal:      ^u64,
    internal_high: ^u64,
    using _: struct #raw_union {
        using _: struct {
            offset:      u32,
            offset_high: u32,
        },
        pointer: rawptr,
    },
    event: Handle,
}

File_Notify_Information :: struct {
  next_entry_offset: u32,
  action:            u32,
  file_name_length:  u32,
  file_name:         [1]u16,
}

MAPVK_VK_TO_VSC    :: 0;
MAPVK_VSC_TO_VK    :: 1;
MAPVK_VK_TO_CHAR   :: 2;
MAPVK_VSC_TO_VK_EX :: 3;




INVALID_HANDLE :: Handle(~uintptr(0));

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
WS_MAXIMIZE         :: 0x01000000;
WS_MINIMIZE         :: 0x20000000;
WS_OVERLAPPEDWINDOW :: WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;
WS_POPUPWINDOW      :: WS_POPUP | WS_BORDER | WS_SYSMENU;

WM_ACTIVATE          :: 0x0006;
WM_ACTIVATEAPP       :: 0x001C;
WM_CHAR              :: 0x0102;
WM_CLOSE             :: 0x0010;
WM_CREATE            :: 0x0001;
WM_DESTROY           :: 0x0002;
WM_INPUT             :: 0x00ff;
WM_KEYDOWN           :: 0x0100;
WM_KEYUP             :: 0x0101;
WM_KILLFOCUS         :: 0x0008;
WM_QUIT              :: 0x0012;
WM_SETCURSOR         :: 0x0020;
WM_SETFOCUS          :: 0x0007;
WM_SIZE	             :: 0x0005;
WM_SIZING            :: 0x0214;
WM_SYSKEYDOWN        :: 0x0104;
WM_SYSKEYUP          :: 0x0105;
WM_USER              :: 0x0400;
WM_WINDOWPOSCHANGED  :: 0x0047;

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

COLOR_BACKGROUND :: Hbrush(uintptr(1));

INVALID_SET_FILE_POINTER :: ~u32(0);
HEAP_ZERO_MEMORY         :: 0x00000008;
INFINITE                 :: 0xffffffff;
GWL_EXSTYLE              :: -20;
GWLP_HINSTANCE           :: -6;
GWLP_ID                  :: -12;
GWL_STYLE                :: -16;
GWLP_USERDATA            :: -21;
GWLP_WNDPROC             :: -4;
Hwnd_TOP                 :: Hwnd(uintptr(0));

BI_RGB         :: 0;
DIB_RGB_COLORS :: 0x00;
SRCCOPY: u32 : 0x00cc0020;


MONITOR_DEFAULTTONULL    :: 0x00000000;
MONITOR_DEFAULTTOPRIMARY :: 0x00000001;
MONITOR_DEFAULTTONEAREST :: 0x00000002;

SWP_FRAMECHANGED  :: 0x0020;
SWP_NOOWNERZORDER :: 0x0200;
SWP_NOZORDER      :: 0x0004;
SWP_NOSIZE        :: 0x0001;
SWP_NOMOVE        :: 0x0002;


// Raw Input


RID_HEADER :: 0x10000005;
RID_INPUT  :: 0x10000003;


RIDEV_APPKEYS      :: 0x00000400;
RIDEV_CAPTUREMOUSE :: 0x00000200;
RIDEV_DEVNOTIFY    :: 0x00002000;
RIDEV_EXCLUDE      :: 0x00000010;
RIDEV_EXINPUTSINK  :: 0x00001000;
RIDEV_INPUTSINK    :: 0x00000100;
RIDEV_NOHOTKEYS    :: 0x00000200;
RIDEV_NOLEGACY     :: 0x00000030;
RIDEV_PAGEONLY     :: 0x00000020;
RIDEV_REMOVE       :: 0x00000001;


RIM_TYPEMOUSE    :: 0;
RIM_TYPEKEYBOARD :: 1;
RIM_TYPEHID      :: 2;


MOUSE_ATTRIBUTES_CHANGED :: 0x04;
MOUSE_MOVE_RELATIVE      :: 0;
MOUSE_MOVE_ABSOLUTE      :: 1;
MOUSE_VIRTUAL_DESKTOP    :: 0x02;



RI_MOUSE_BUTTON_1_DOWN      :: 0x0001;
RI_MOUSE_BUTTON_1_UP        :: 0x0002;
RI_MOUSE_BUTTON_2_DOWN      :: 0x0004;
RI_MOUSE_BUTTON_2_UP        :: 0x0008;
RI_MOUSE_BUTTON_3_DOWN      :: 0x0010;
RI_MOUSE_BUTTON_3_UP        :: 0x0020;
RI_MOUSE_BUTTON_4_DOWN      :: 0x0040;
RI_MOUSE_BUTTON_4_UP        :: 0x0080;
RI_MOUSE_BUTTON_5_DOWN      :: 0x0100;
RI_MOUSE_BUTTON_5_UP        :: 0x0200;
RI_MOUSE_LEFT_BUTTON_DOWN   :: 0x0001;
RI_MOUSE_LEFT_BUTTON_UP     :: 0x0002;
RI_MOUSE_MIDDLE_BUTTON_DOWN :: 0x0010;
RI_MOUSE_MIDDLE_BUTTON_UP   :: 0x0020;
RI_MOUSE_RIGHT_BUTTON_DOWN  :: 0x0004;
RI_MOUSE_RIGHT_BUTTON_UP    :: 0x0008;
RI_MOUSE_WHEEL              :: 0x0400;


RI_KEY_MAKE            :: 0x00;
RI_KEY_BREAK           :: 0x01;
RI_KEY_E0              :: 0x02;
RI_KEY_E1              :: 0x04;
RI_KEY_TERMSRV_SET_LED :: 0x08;
RI_KEY_TERMSRV_SHADOW  :: 0x10;

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

GET_FILEEX_INFO_LEVELS :: distinct i32;
GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0;
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1;

STARTF_USESHOWWINDOW    :: 0x00000001;
STARTF_USESIZE          :: 0x00000002;
STARTF_USEPOSITION      :: 0x00000004;
STARTF_USECOUNTCHARS    :: 0x00000008;
STARTF_USEFILLATTRIBUTE :: 0x00000010;
STARTF_RUNFULLSCREEN    :: 0x00000020;  // ignored for non-x86 platforms
STARTF_FORCEONFEEDBACK  :: 0x00000040;
STARTF_FORCEOFFFEEDBACK :: 0x00000080;
STARTF_USESTDHANDLES    :: 0x00000100;
STARTF_USEHOTKEY        :: 0x00000200;
STARTF_TITLEISLINKNAME  :: 0x00000800;
STARTF_TITLEISAPPID     :: 0x00001000;
STARTF_PREVENTPINNING   :: 0x00002000;
STARTF_UNTRUSTEDSOURCE  :: 0x00008000;


MOVEFILE_REPLACE_EXISTING      :: 0x00000001;
MOVEFILE_COPY_ALLOWED          :: 0x00000002;
MOVEFILE_DELAY_UNTIL_REBOOT    :: 0x00000004;
MOVEFILE_WRITE_THROUGH         :: 0x00000008;
MOVEFILE_CREATE_HARDLINK       :: 0x00000010;
MOVEFILE_FAIL_IF_NOT_TRACKABLE :: 0x00000020;

FILE_NOTIFY_CHANGE_FILE_NAME   :: 0x00000001;
FILE_NOTIFY_CHANGE_DIR_NAME    :: 0x00000002;
FILE_NOTIFY_CHANGE_ATTRIBUTES  :: 0x00000004;
FILE_NOTIFY_CHANGE_SIZE        :: 0x00000008;
FILE_NOTIFY_CHANGE_LAST_WRITE  :: 0x00000010;
FILE_NOTIFY_CHANGE_LAST_ACCESS :: 0x00000020;
FILE_NOTIFY_CHANGE_CREATION    :: 0x00000040;
FILE_NOTIFY_CHANGE_SECURITY    :: 0x00000100;

FILE_FLAG_WRITE_THROUGH        :: 0x80000000;
FILE_FLAG_OVERLAPPED           :: 0x40000000;
FILE_FLAG_NO_BUFFERING         :: 0x20000000;
FILE_FLAG_RANDOM_ACCESS        :: 0x10000000;
FILE_FLAG_SEQUENTIAL_SCAN      :: 0x08000000;
FILE_FLAG_DELETE_ON_CLOSE      :: 0x04000000;
FILE_FLAG_BACKUP_SEMANTICS     :: 0x02000000;
FILE_FLAG_POSIX_SEMANTICS      :: 0x01000000;
FILE_FLAG_SESSION_AWARE        :: 0x00800000;
FILE_FLAG_OPEN_REPARSE_POINT   :: 0x00200000;
FILE_FLAG_OPEN_NO_RECALL       :: 0x00100000;
FILE_FLAG_FIRST_PIPE_INSTANCE  :: 0x00080000;

FILE_ACTION_ADDED            :: 0x00000001;
FILE_ACTION_REMOVED          :: 0x00000002;
FILE_ACTION_MODIFIED         :: 0x00000003;
FILE_ACTION_RENAMED_OLD_NAME :: 0x00000004;
FILE_ACTION_RENAMED_NEW_NAME :: 0x00000005;

CP_ACP        :: 0;     // default to ANSI code page
CP_OEMCP      :: 1;     // default to OEM  code page
CP_MACCP      :: 2;     // default to MAC  code page
CP_THREAD_ACP :: 3;     // current thread's ANSI code page
CP_SYMBOL     :: 42;    // SYMBOL translations
CP_UTF7       :: 65000; // UTF-7 translation
CP_UTF8       :: 65001; // UTF-8 translation

@(default_calling_convention = "std")
foreign kernel32 {
	@(link_name="GetLastError")              get_last_error              :: proc() -> i32 ---;
	@(link_name="CreateProcessA")		     create_process_a		     :: proc(application_name, command_line: cstring,
	                                                              				 process_attributes, thread_attributes: ^Security_Attributes,
	                                                              				 inherit_handle: Bool, creation_flags: u32, environment: rawptr,
	                                                              				 current_direcotry: cstring, startup_info: ^Startup_Info,
	                                                              				 process_information: ^Process_Information) -> Bool ---;
    @(link_name="CreateProcessW")            create_process_w            :: proc(application_name, command_line: Wstring,
                                                                                 process_attributes, thread_attributes: ^Security_Attributes,
                                                                                 inherit_handle: Bool, creation_flags: u32, environment: rawptr,
                                                                                 current_direcotry: cstring, startup_info: ^Startup_Info,
                                                                                 process_information: ^Process_Information) -> Bool ---;
	@(link_name="GetExitCodeProcess")		 get_exit_code_process       :: proc(process: Handle, exit: ^u32) -> Bool ---;
	@(link_name="ExitProcess")               exit_process                :: proc(exit_code: u32) ---;
	@(link_name="GetModuleHandleA")          get_module_handle_a         :: proc(module_name: cstring) -> Hinstance ---;
	@(link_name="GetModuleHandleW")          get_module_handle_w         :: proc(module_name: Wstring) -> Hinstance ---;
	@(link_name="Sleep")                     sleep                       :: proc(ms: i32) -> i32 ---;
	@(link_name="QueryPerformanceFrequency") query_performance_frequency :: proc(result: ^i64) -> i32 ---;
	@(link_name="QueryPerformanceCounter")   query_performance_counter   :: proc(result: ^i64) -> i32 ---;
	@(link_name="OutputDebugStringA")        output_debug_string_a       :: proc(c_str: cstring) ---;

	@(link_name="GetCommandLineA")    get_command_line_a    :: proc() -> cstring ---;
	@(link_name="GetCommandLineW")    get_command_line_w    :: proc() -> Wstring ---;
	@(link_name="GetSystemMetrics")   get_system_metrics    :: proc(index: i32) -> i32 ---;
	@(link_name="GetCurrentThreadId") get_current_thread_id :: proc() -> u32 ---;

	@(link_name="GetSystemTimeAsFileTime") get_system_time_as_file_time :: proc(system_time_as_file_time: ^Filetime) ---;
	@(link_name="FileTimeToLocalFileTime") file_time_to_local_file_time :: proc(file_time: ^Filetime, local_file_time: ^Filetime) -> Bool ---;
	@(link_name="FileTimeToSystemTime")    file_time_to_system_time     :: proc(file_time: ^Filetime, system_time: ^Systemtime) -> Bool ---;
	@(link_name="SystemTimeToFileTime")    system_time_to_file_time     :: proc(system_time: ^Systemtime, file_time: ^Filetime) -> Bool ---;

	@(link_name="CloseHandle")  close_handle   :: proc(h: Handle) -> i32 ---;
	@(link_name="GetStdHandle") get_std_handle :: proc(h: i32) -> Handle ---;

	@(link_name="CreateFileA")
	create_file_a :: proc(filename: cstring, desired_access, share_module: u32,
	                      security: rawptr,
	                      creation, flags_and_attribs: u32, template_file: Handle) -> Handle ---;

	@(link_name="CreateFileW")
	create_file_w :: proc(filename: Wstring, desired_access, share_module: u32,
	                      security: rawptr,
	                      creation, flags_and_attribs: u32, template_file: Handle) -> Handle ---;


	@(link_name="ReadFile")  read_file  :: proc(h: Handle, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> Bool ---;
	@(link_name="WriteFile") write_file :: proc(h: Handle, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> Bool ---;

	@(link_name="GetFileSizeEx")              get_file_size_ex               :: proc(file_handle: Handle, file_size: ^i64) -> Bool ---;
	@(link_name="GetFileAttributesA")         get_file_attributes_a          :: proc(filename: cstring) -> u32 ---;
	@(link_name="GetFileAttributesW")         get_file_attributes_w          :: proc(filename: Wstring) -> u32 ---;
	@(link_name="GetFileAttributesExA")       get_file_attributes_ex_a       :: proc(filename: cstring, info_level_id: GET_FILEEX_INFO_LEVELS, file_info: rawptr) -> Bool ---;
	@(link_name="GetFileInformationByHandle") get_file_information_by_handle :: proc(file_handle: Handle, file_info: ^By_Handle_File_Information) -> Bool ---;

	@(link_name="CreateDirectoryA") 		  create_directory_a			 :: proc(path: cstring, security_attributes: ^Security_Attributes) -> Bool ---;
	@(link_name="CreateDirectoryW") 		  create_directory_w			 :: proc(path: Wstring, security_attributes: ^Security_Attributes) -> Bool ---;

	@(link_name="GetFileType")    get_file_type    :: proc(file_handle: Handle) -> u32 ---;
	@(link_name="SetFilePointer") set_file_pointer :: proc(file_handle: Handle, distance_to_move: i32, distance_to_move_high: ^i32, move_method: u32) -> u32 ---;

	@(link_name="SetHandleInformation") set_handle_information :: proc(obj: Handle, mask, flags: u32) -> Bool ---;

	@(link_name="FindFirstFileA") find_first_file_a :: proc(file_name: cstring, data: ^Find_Data_A) -> Handle ---;
	@(link_name="FindNextFileA")  find_next_file_a  :: proc(file: Handle, data: ^Find_Data_A) -> Bool ---;

	@(link_name="FindFirstFileW") find_first_file_w :: proc(file_name: Wstring, data: ^Find_Data_W) -> Handle ---;
	@(link_name="FindNextFileW")  find_next_file_w  :: proc(file: Handle, data: ^Find_Data_W) -> Bool ---;

	@(link_name="FindClose")      find_close        :: proc(file: Handle) -> Bool ---;

	@(link_name="MoveFileExA")    move_file_ex_a    :: proc(existing, new: cstring, flags: u32) -> Bool ---;
	@(link_name="DeleteFileA")    delete_file_a     :: proc(file_name: cstring) -> Bool ---;
	@(link_name="CopyFileA")      copy_file_a       :: proc(existing, new: cstring, fail_if_exists: Bool) -> Bool ---;

	@(link_name="MoveFileExW")    move_file_ex_w    :: proc(existing, new: Wstring, flags: u32) -> Bool ---;
	@(link_name="DeleteFileW")    delete_file_w     :: proc(file_name: Wstring) -> Bool ---;
	@(link_name="CopyFileW")      copy_file_w       :: proc(existing, new: Wstring, fail_if_exists: Bool) -> Bool ---;

	@(link_name="HeapAlloc")      heap_alloc       :: proc(h: Handle, flags: u32, bytes: int) -> rawptr ---;
	@(link_name="HeapReAlloc")    heap_realloc     :: proc(h: Handle, flags: u32, memory: rawptr, bytes: int) -> rawptr ---;
	@(link_name="HeapFree")       heap_free        :: proc(h: Handle, flags: u32, memory: rawptr) -> Bool ---;
	@(link_name="GetProcessHeap") get_process_heap :: proc() -> Handle ---;

	@(link_name="LocalAlloc")     local_alloc      :: proc(flags: u32, bytes: int) -> rawptr ---;
	@(link_name="LocalReAlloc")   local_realloc    :: proc(mem: rawptr, bytes: int, flags: uint) -> rawptr ---;
	@(link_name="LocalFree")      local_free       :: proc(mem: rawptr) -> rawptr ---;

	@(link_name="FindFirstChangeNotificationA") find_first_change_notification_a :: proc(path: cstring, watch_subtree: Bool, filter: u32) -> Handle ---;
	@(link_name="FindNextChangeNotification")   find_next_change_notification    :: proc(h: Handle) -> Bool ---;
	@(link_name="FindCloseChangeNotification")  find_close_change_notification   :: proc(h: Handle) -> Bool ---;

	@(link_name="ReadDirectoryChangesW") read_directory_changes_w :: proc(dir: Handle, buf: rawptr, buf_length: u32,
	                                                                      watch_subtree: Bool, notify_filter: u32,
	                                                                      bytes_returned: ^u32, overlapped: ^Overlapped,
	                                                                      completion: rawptr) -> Bool ---;

	@(link_name="WideCharToMultiByte") wide_char_to_multi_byte :: proc(code_page: u32, flags: u32,
	                                                                   wchar_str: Wstring, wchar: i32,
	                                                                   multi_str: cstring, multi: i32,
	                                                                   default_char: cstring, used_default_char: ^Bool) -> i32 ---;

	@(link_name="MultiByteToWideChar") multi_byte_to_wide_char :: proc(code_page: u32, flags: u32,
	                                                                   mb_str: cstring, mb: i32,
	                                                                   wc_str: Wstring, wc: i32) -> i32 ---;

	@(link_name="CreateSemaphoreA")    create_semaphore_a     :: proc(attributes: ^Security_Attributes, initial_count, maximum_count: i32, name: cstring) -> Handle ---;
	@(link_name="ReleaseSemaphore")    release_semaphore      :: proc(semaphore: Handle, release_count: i32, previous_count: ^i32) -> Bool ---;
	@(link_name="WaitForSingleObject") wait_for_single_object :: proc(handle: Handle, milliseconds: u32) -> u32 ---;
}

@(default_calling_convention = "c")
foreign kernel32 {
	@(link_name="InterlockedCompareExchange") interlocked_compare_exchange :: proc(dst: ^i32, exchange, comparand: i32) -> i32 ---;
	@(link_name="InterlockedExchange")        interlocked_exchange         :: proc(dst: ^i32, desired: i32) -> i32 ---;
	@(link_name="InterlockedExchangeAdd")     interlocked_exchange_add     :: proc(dst: ^i32, desired: i32) -> i32 ---;
	@(link_name="InterlockedAnd")             interlocked_and              :: proc(dst: ^i32, desired: i32) -> i32 ---;
	@(link_name="InterlockedOr")              interlocked_or               :: proc(dst: ^i32, desired: i32) -> i32 ---;

	@(link_name="InterlockedCompareExchange64") interlocked_compare_exchange64 :: proc(dst: ^i64, exchange, comparand: i64) -> i64 ---;
	@(link_name="InterlockedExchange64")        interlocked_exchange64         :: proc(dst: ^i64, desired: i64) -> i64 ---;
	@(link_name="InterlockedExchangeAdd64")     interlocked_exchange_add64     :: proc(dst: ^i64, desired: i64) -> i64 ---;
	@(link_name="InterlockedAnd64")             interlocked_and64              :: proc(dst: ^i64, desired: i64) -> i64 ---;
	@(link_name="InterlockedOr64")              interlocked_or64               :: proc(dst: ^i64, desired: i64) -> i64 ---;
}

@(default_calling_convention = "std")
foreign kernel32 {
	@(link_name="_mm_pause")        mm_pause           :: proc() ---;
	@(link_name="ReadWriteBarrier") read_write_barrier :: proc() ---;
	@(link_name="WriteBarrier")     write_barrier      :: proc() ---;
	@(link_name="ReadBarrier")      read_barrier       :: proc() ---;

	@(link_name="CreateThread")
	create_thread :: proc(thread_attributes: ^Security_Attributes, stack_size: int, start_routine: rawptr,
	                      parameter: rawptr, creation_flags: u32, thread_id: ^u32) -> Handle ---;
	@(link_name="ResumeThread")      resume_thread        :: proc(thread: Handle) -> u32 ---;
	@(link_name="GetThreadPriority") get_thread_priority  :: proc(thread: Handle) -> i32 ---;
	@(link_name="SetThreadPriority") set_thread_priority  :: proc(thread: Handle, priority: i32) -> Bool ---;
    @(link_name="GetExitCodeThread") get_exit_code_thread :: proc(thread: Handle, exit_code: ^u32) -> Bool ---;
	@(link_name="TerminateThread")   terminate_thread     :: proc(thread: Handle, exit_code: u32) -> Bool ---;

	@(link_name="InitializeCriticalSection")             initialize_critical_section                :: proc(critical_section: ^Critical_Section) ---;
	@(link_name="InitializeCriticalSectionAndSpinCount") initialize_critical_section_and_spin_count :: proc(critical_section: ^Critical_Section, spin_count: u32) ---;
	@(link_name="DeleteCriticalSection")                 delete_critical_section                    :: proc(critical_section: ^Critical_Section) ---;
	@(link_name="SetCriticalSectionSpinCount")           set_critical_section_spin_count            :: proc(critical_section: ^Critical_Section, spin_count: u32) -> u32 ---;
	@(link_name="TryEnterCriticalSection")               try_enter_critical_section                 :: proc(critical_section: ^Critical_Section) -> Bool ---;
	@(link_name="EnterCriticalSection")                  enter_critical_section                     :: proc(critical_section: ^Critical_Section) ---;
	@(link_name="LeaveCriticalSection")                  leave_critical_section                     :: proc(critical_section: ^Critical_Section) ---;

	@(link_name="CreateEventA") create_event_a :: proc(event_attributes: ^Security_Attributes, manual_reset, initial_state: Bool, name: cstring) -> Handle ---;

	@(link_name="LoadLibraryA")   load_library_a   :: proc(c_str: cstring)  -> Hmodule ---;
	@(link_name="LoadLibraryW")   load_library_w   :: proc(c_str: Wstring) -> Hmodule ---;
	@(link_name="FreeLibrary")    free_library     :: proc(h: Hmodule) ---;
	@(link_name="GetProcAddress") get_proc_address :: proc(h: Hmodule, c_str: cstring) -> rawptr ---;

}

@(default_calling_convention = "std")
foreign user32 {
	@(link_name="GetDesktopWindow") get_desktop_window  :: proc() -> Hwnd ---;
	@(link_name="ShowCursor")       show_cursor         :: proc(show: Bool) ---;
	@(link_name="GetCursorPos")     get_cursor_pos      :: proc(p: ^Point) -> Bool ---;
	@(link_name="SetCursorPos")     set_cursor_pos      :: proc(x, y: i32) -> Bool ---;
	@(link_name="ScreenToClient")   screen_to_client    :: proc(h: Hwnd, p: ^Point) -> Bool ---;
	@(link_name="ClientToScreen")   client_to_screen    :: proc(h: Hwnd, p: ^Point) -> Bool ---;
	@(link_name="PostQuitMessage")  post_quit_message   :: proc(exit_code: i32) ---;
	@(link_name="SetWindowTextA")   set_window_text_a   :: proc(hwnd: Hwnd, c_string: cstring) -> Bool ---;
	@(link_name="RegisterClassExA") register_class_ex_a :: proc(wc: ^Wnd_Class_Ex_A) -> i16 ---;
	@(link_name="RegisterClassExW") register_class_ex_w :: proc(wc: ^Wnd_Class_Ex_W) -> i16 ---;

	@(link_name="CreateWindowExA")
	create_window_ex_a :: proc(ex_style: u32,
	                           class_name, title: cstring,
	                           style: u32,
	                           x, y, w, h: i32,
	                           parent: Hwnd, menu: Hmenu, instance: Hinstance,
	                           param: rawptr) -> Hwnd ---;

	@(link_name="CreateWindowExW")
	create_window_ex_w :: proc(ex_style: u32,
	                           class_name, title: Wstring,
	                           style: u32,
	                           x, y, w, h: i32,
	                           parent: Hwnd, menu: Hmenu, instance: Hinstance,
	                           param: rawptr) -> Hwnd ---;

	@(link_name="ShowWindow")       show_window        :: proc(hwnd: Hwnd, cmd_show: i32) -> Bool ---;
	@(link_name="TranslateMessage") translate_message  :: proc(msg: ^Msg) -> Bool ---;
	@(link_name="DispatchMessageA") dispatch_message_a :: proc(msg: ^Msg) -> Lresult ---;
	@(link_name="DispatchMessageW") dispatch_message_w :: proc(msg: ^Msg) -> Lresult ---;
	@(link_name="UpdateWindow")     update_window      :: proc(hwnd: Hwnd) -> Bool ---;
	@(link_name="GetMessageA")      get_message_a      :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max: u32) -> Bool ---;
	@(link_name="GetMessageW")      get_message_w      :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max: u32) -> Bool ---;

	@(link_name="PeekMessageA") peek_message_a :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool ---;
	@(link_name="PeekMessageW") peek_message_w :: proc(msg: ^Msg, hwnd: Hwnd, msg_filter_min, msg_filter_max, remove_msg: u32) -> Bool ---;


	@(link_name="PostMessageA") post_message :: proc(hwnd: Hwnd, msg, wparam, lparam: u32) -> Bool ---;

	@(link_name="DefWindowProcA") def_window_proc_a :: proc(hwnd: Hwnd, msg: u32, wparam: Wparam, lparam: Lparam) -> Lresult ---;

	@(link_name="AdjustWindowRect") adjust_window_rect :: proc(rect: ^Rect, style: u32, menu: Bool) -> Bool ---;
	@(link_name="GetActiveWindow")  get_active_window  :: proc() -> Hwnd ---;

	@(link_name="DestroyWindow")       destroy_window        :: proc(wnd: Hwnd) -> Bool ---;
	@(link_name="DescribePixelFormat") describe_pixel_format :: proc(dc: Hdc, pixel_format: i32, bytes: u32, pfd: ^Pixel_Format_Descriptor) -> i32 ---;

	@(link_name="GetMonitor_InfoA")  get_monitor_info_a  :: proc(monitor: Hmonitor, mi: ^Monitor_Info) -> Bool ---;
	@(link_name="MonitorFromWindow") monitor_from_window :: proc(wnd: Hwnd, flags: u32) -> Hmonitor ---;

	@(link_name="SetWindowPos") set_window_pos :: proc(wnd: Hwnd, wndInsertAfter: Hwnd, x, y, width, height: i32, flags: u32) ---;

	@(link_name="GetWindowPlacement") get_window_placement  :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool ---;
	@(link_name="SetWindowPlacement") set_window_placement  :: proc(wnd: Hwnd, wndpl: ^Window_Placement) -> Bool ---;
	@(link_name="GetWindowRect")      get_window_rect       :: proc(wnd: Hwnd, rect: ^Rect) -> Bool ---;

	@(link_name="GetWindowLongPtrA") get_window_long_ptr_a :: proc(wnd: Hwnd, index: i32) -> Long_Ptr ---;
	@(link_name="SetWindowLongPtrA") set_window_long_ptr_a :: proc(wnd: Hwnd, index: i32, new: Long_Ptr) -> Long_Ptr ---;
	@(link_name="GetWindowLongPtrW") get_window_long_ptr_w :: proc(wnd: Hwnd, index: i32) -> Long_Ptr ---;
	@(link_name="SetWindowLongPtrW") set_window_long_ptr_w :: proc(wnd: Hwnd, index: i32, new: Long_Ptr) -> Long_Ptr ---;

	@(link_name="GetWindowText") get_window_text :: proc(wnd: Hwnd, str: cstring, maxCount: i32) -> i32 ---;

	@(link_name="GetClientRect") get_client_rect :: proc(hwnd: Hwnd, rect: ^Rect) -> Bool ---;

	@(link_name="GetDC")     get_dc     :: proc(h: Hwnd) -> Hdc ---;
	@(link_name="ReleaseDC") release_dc :: proc(wnd: Hwnd, hdc: Hdc) -> i32 ---;

	@(link_name="MapVirtualKeyA") map_virtual_key_a :: proc(scancode: u32, map_type: u32) -> u32 ---;
	@(link_name="MapVirtualKeyW") map_virtual_key_w :: proc(scancode: u32, map_type: u32) -> u32 ---;

	@(link_name="GetKeyState")      get_key_state       :: proc(v_key: i32) -> i16 ---;
	@(link_name="GetAsyncKeyState") get_async_key_state :: proc(v_key: i32) -> i16 ---;

	@(link_name="SetForegroundWindow") set_foreground_window :: proc(h: Hwnd) -> Bool ---;
	@(link_name="SetFocus")            set_focus             :: proc(h: Hwnd) -> Hwnd ---;


    @(link_name="LoadImageA")       load_image_a        :: proc(instance: Hinstance, name: cstring, type_: u32, x_desired, y_desired : i32, load : u32) -> Handle ---;
    @(link_name="LoadIconA")        load_icon_a         :: proc(instance: Hinstance, icon_name: cstring) -> Hicon ---;
    @(link_name="DestroyIcon")      destroy_icon        :: proc(icon: Hicon) -> Bool ---;

    @(link_name="LoadCursorA")      load_cursor_a       :: proc(instance: Hinstance, cursor_name: cstring) -> Hcursor ---;
	@(link_name="GetCursor")        get_cursor          :: proc() -> Hcursor ---;
	@(link_name="SetCursor")        set_cursor          :: proc(cursor: Hcursor) -> Hcursor ---;

	@(link_name="RegisterRawInputDevices") register_raw_input_devices :: proc(raw_input_device: ^Raw_Input_Device, num_devices, size: u32) -> Bool ---;

	@(link_name="GetRawInputData") get_raw_input_data :: proc(raw_input: Hrawinput, command: u32, data: rawptr, size: ^u32, size_header: u32) -> u32 ---;

	@(link_name="MapVirtualKeyExW") map_virtual_key_ex_w :: proc(code, map_type: u32, hkl: HKL) ---;
	@(link_name="MapVirtualKeyExA") map_virtual_key_ex_a :: proc(code, map_type: u32, hkl: HKL) ---;
}

@(default_calling_convention = "std")
foreign gdi32 {
	@(link_name="GetStockObject") get_stock_object :: proc(fn_object: i32) -> Hgdiobj ---;

	@(link_name="StretchDIBits")
	stretch_dibits :: proc(hdc: Hdc,
	                       x_dst, y_dst, width_dst, height_dst: i32,
	                       x_src, y_src, width_src, header_src: i32,
	                       bits: rawptr, bits_info: ^Bitmap_Info,
	                       usage: u32,
	                       rop: u32) -> i32 ---;

	@(link_name="SetPixelFormat")    set_pixel_format    :: proc(hdc: Hdc, pixel_format: i32, pfd: ^Pixel_Format_Descriptor) -> Bool ---;
	@(link_name="ChoosePixelFormat") choose_pixel_format :: proc(hdc: Hdc, pfd: ^Pixel_Format_Descriptor) -> i32 ---;
	@(link_name="SwapBuffers")       swap_buffers        :: proc(hdc: Hdc) -> Bool ---;

}

@(default_calling_convention = "std")
foreign shell32 {
	@(link_name="CommandLineToArgvW") command_line_to_argv_w :: proc(cmd_list: Wstring, num_args: ^i32) -> ^Wstring ---;
}

@(default_calling_convention = "std")
foreign winmm {
	@(link_name="timeGetTime") time_get_time :: proc() -> u32 ---;
}



get_query_performance_frequency :: proc() -> i64 {
	r: i64;
	query_performance_frequency(&r);
	return r;
}

HIWORD_W :: proc(wParam: Wparam) -> u16 { return u16((u32(wParam) >> 16) & 0xffff); }
HIWORD_L :: proc(lParam: Lparam) -> u16 { return u16((u32(lParam) >> 16) & 0xffff); }
LOWORD_W :: proc(wParam: Wparam) -> u16 { return u16(wParam); }
LOWORD_L :: proc(lParam: Lparam) -> u16 { return u16(lParam); }

is_key_down :: inline proc(key: Key_Code) -> bool { return get_async_key_state(i32(key)) < 0; }




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


Monitor_Info :: struct {
	size:      u32,
	monitor:   Rect,
	work:      Rect,
	flags:     u32,
}

Window_Placement :: struct {
	length:     u32,
	flags:      u32,
	show_cmd:   u32,
	min_pos:    Point,
	max_pos:    Point,
	normal_pos: Rect,
}

Bitmap_Info_Header :: struct {
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
Bitmap_Info :: struct {
	using header: Bitmap_Info_Header,
	colors:       [1]Rgb_Quad,
}


Rgb_Quad :: struct {blue, green, red, reserved: byte}


Key_Code :: enum i32 {
	Unknown    = 0x00,

	Lbutton    = 0x01,
	Rbutton    = 0x02,
	Cancel     = 0x03,
	Mbutton    = 0x04,
	Xbutton1   = 0x05,
	Xbutton2   = 0x06,
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
