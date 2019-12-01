// +build windows
package win32

Uint_Ptr :: distinct uint;
Long_Ptr :: distinct int;

Handle    :: distinct rawptr;
Hwnd      :: distinct Handle;
Hdc       :: distinct Handle;
Hinstance :: distinct Handle;
Hicon     :: distinct Handle;
Hcursor   :: distinct Handle;
Hmenu     :: distinct Handle;
Hbitmap   :: distinct Handle;
Hbrush    :: distinct Handle;
Hgdiobj   :: distinct Handle;
Hmodule   :: distinct Handle;
Hmonitor  :: distinct Handle;
Hrawinput :: distinct Handle;
Hresult   :: distinct i32;
HKL       :: distinct Handle;
Wparam    :: distinct Uint_Ptr;
Lparam    :: distinct Long_Ptr;
Lresult   :: distinct Long_Ptr;
Wnd_Proc  :: distinct #type proc "c" (Hwnd, u32, Wparam, Lparam) -> Lresult;
Monitor_Enum_Proc :: distinct #type proc "std" (Hmonitor, Hdc, ^Rect, Lparam) -> bool;



Bool :: distinct b32;

Wstring :: distinct ^u16;

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

// NOTE(Jeroen): The widechar version might want at least the 32k MAX_PATH_WIDE
// https://docs.microsoft.com/en-us/windows/desktop/api/fileapi/nf-fileapi-findfirstfilew#parameters
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

// https://docs.microsoft.com/en-gb/windows/win32/api/sysinfoapi/ns-sysinfoapi-system_info
System_Info :: struct {
	using _: struct #raw_union {
		oem_id: u32,
		using _: struct #raw_union {
			processor_architecture: u16,
			_: u16, // reserved
		},
	},
	page_size: u32,
	minimum_application_address: rawptr,
	maximum_application_address: rawptr,
	active_processor_mask: u32,
	number_of_processors: u32,
	processor_type: u32,
	allocation_granularity: u32,
	processor_level: u16,
	processor_revision: u16,
}

// https://docs.microsoft.com/en-us/windows/desktop/api/winnt/ns-winnt-_osversioninfoexa
OS_Version_Info_Ex_A :: struct {
  os_version_info_size: u32,
  major_version:        u32,
  minor_version:        u32,
  build_number:         u32,
  platform_id :         u32,
  service_pack_string:  [128]u8,
  service_pack_major:   u16,
  service_pack_minor:   u16,
  suite_mask:           u16,
  product_type:         u8,
  reserved:             u8
}

MAPVK_VK_TO_VSC    :: 0;
MAPVK_VSC_TO_VK    :: 1;
MAPVK_VK_TO_CHAR   :: 2;
MAPVK_VSC_TO_VK_EX :: 3;

//WinUser.h
VK_LBUTTON        :: 0x01;
VK_RBUTTON        :: 0x02;
VK_CANCEL         :: 0x03;
VK_MBUTTON        :: 0x04;    /* NOT contiguous with L & RBUTTON */
VK_XBUTTON1       :: 0x05;    /* NOT contiguous with L & RBUTTON */
VK_XBUTTON2       :: 0x06;    /* NOT contiguous with L & RBUTTON */

/*
 * :: 0x07 : reserved
 */

VK_BACK           :: 0x08;
VK_TAB            :: 0x09;

/*
 * :: 0x0A - :: 0x0B : reserved
 */

VK_CLEAR          :: 0x0C;
VK_RETURN         :: 0x0D;

/*
 * :: 0x0E - :: 0x0F : unassigned
 */

VK_SHIFT          :: 0x10;
VK_CONTROL        :: 0x11;
VK_MENU           :: 0x12;
VK_PAUSE          :: 0x13;
VK_CAPITAL        :: 0x14;

VK_KANA           :: 0x15;
VK_HANGEUL        :: 0x15; /* old name - should be here for compatibility */
VK_HANGUL         :: 0x15;

/*
 * :: 0x16 : unassigned
 */

VK_JUNJA          :: 0x17;
VK_FINAL          :: 0x18;
VK_HANJA          :: 0x19;
VK_KANJI          :: 0x19;

/*
 * :: 0x1A : unassigned
 */

VK_ESCAPE         :: 0x1B;

VK_CONVERT        :: 0x1C;
VK_NONCONVERT     :: 0x1D;
VK_ACCEPT         :: 0x1E;
VK_MODECHANGE     :: 0x1F;

VK_SPACE          :: 0x20;
VK_PRIOR          :: 0x21;
VK_NEXT           :: 0x22;
VK_END            :: 0x23;
VK_HOME           :: 0x24;
VK_LEFT           :: 0x25;
VK_UP             :: 0x26;
VK_RIGHT          :: 0x27;
VK_DOWN           :: 0x28;
VK_SELECT         :: 0x29;
VK_PRINT          :: 0x2A;
VK_EXECUTE        :: 0x2B;
VK_SNAPSHOT       :: 0x2C;
VK_INSERT         :: 0x2D;
VK_DELETE         :: 0x2E;
VK_HELP           :: 0x2F;

/*
 * VK_0 - VK_9 are the same as ASCII '0' - '9' (:: 0x30 - :: 0x39)
 * :: 0x3A - :: 0x40 : unassigned
 * VK_A - VK_Z are the same as ASCII 'A' - 'Z' (:: 0x41 - :: 0x5A)
 */

VK_LWIN           :: 0x5B;
VK_RWIN           :: 0x5C;
VK_APPS           :: 0x5D;

/*
 * :: 0x5E : reserved
 */

VK_SLEEP          :: 0x5F;

VK_NUMPAD0        :: 0x60;
VK_NUMPAD1        :: 0x61;
VK_NUMPAD2        :: 0x62;
VK_NUMPAD3        :: 0x63;
VK_NUMPAD4        :: 0x64;
VK_NUMPAD5        :: 0x65;
VK_NUMPAD6        :: 0x66;
VK_NUMPAD7        :: 0x67;
VK_NUMPAD8        :: 0x68;
VK_NUMPAD9        :: 0x69;
VK_MULTIPLY       :: 0x6A;
VK_ADD            :: 0x6B;
VK_SEPARATOR      :: 0x6C;
VK_SUBTRACT       :: 0x6D;
VK_DECIMAL        :: 0x6E;
VK_DIVIDE         :: 0x6F;
VK_F1             :: 0x70;
VK_F2             :: 0x71;
VK_F3             :: 0x72;
VK_F4             :: 0x73;
VK_F5             :: 0x74;
VK_F6             :: 0x75;
VK_F7             :: 0x76;
VK_F8             :: 0x77;
VK_F9             :: 0x78;
VK_F10            :: 0x79;
VK_F11            :: 0x7A;
VK_F12            :: 0x7B;
VK_F13            :: 0x7C;
VK_F14            :: 0x7D;
VK_F15            :: 0x7E;
VK_F16            :: 0x7F;
VK_F17            :: 0x80;
VK_F18            :: 0x81;
VK_F19            :: 0x82;
VK_F20            :: 0x83;
VK_F21            :: 0x84;
VK_F22            :: 0x85;
VK_F23            :: 0x86;
VK_F24            :: 0x87;

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

WS_EX_DLGMODALFRAME     	:: 0x00000001;
WS_EX_NOPARENTNOTIFY    	:: 0x00000004;
WS_EX_TOPMOST           	:: 0x00000008;
WS_EX_ACCEPTFILES       	:: 0x00000010;
WS_EX_TRANSPARENT       	:: 0x00000020;
WS_EX_MDICHILD          	:: 0x00000040;
WS_EX_TOOLWINDOW        	:: 0x00000080;
WS_EX_WINDOWEDGE        	:: 0x00000100;
WS_EX_CLIENTEDGE        	:: 0x00000200;
WS_EX_CONTEXTHELP       	:: 0x00000400;
WS_EX_RIGHT             	:: 0x00001000;
WS_EX_LEFT              	:: 0x00000000;
WS_EX_RTLREADING        	:: 0x00002000;
WS_EX_LTRREADING        	:: 0x00000000;
WS_EX_LEFTSCROLLBAR     	:: 0x00004000;
WS_EX_RIGHTSCROLLBAR    	:: 0x00000000;
WS_EX_CONTROLPARENT     	:: 0x00010000;
WS_EX_STATICEDGE        	:: 0x00020000;
WS_EX_APPWINDOW         	:: 0x00040000;
WS_EX_OVERLAPPEDWINDOW  	:: WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;
WS_EX_PALETTEWINDOW     	:: WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST;
WS_EX_LAYERED           	:: 0x00080000;
WS_EX_NOINHERITLAYOUT   	:: 0x00100000; // Disable inheritence of mirroring by children
WS_EX_NOREDIRECTIONBITMAP 	:: 0x00200000;
WS_EX_LAYOUTRTL         	:: 0x00400000; // Right to left mirroring
WS_EX_COMPOSITED        	:: 0x02000000;
WS_EX_NOACTIVATE        	:: 0x08000000;

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
WM_COMMAND           :: 0x0111;

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


MB_ERR_INVALID_CHARS :: 8;
WC_ERR_INVALID_CHARS :: 128;

utf8_to_utf16 :: proc(s: string, allocator := context.temp_allocator) -> []u16 {
	if len(s) < 1 {
		return nil;
	}

	b := transmute([]byte)s;
	cstr := cstring(&b[0]);
	n := multi_byte_to_wide_char(CP_UTF8, MB_ERR_INVALID_CHARS, cstr, i32(len(s)), nil, 0);
	if n == 0 {
		return nil;
	}

	text := make([]u16, n+1, allocator);

	n1 := multi_byte_to_wide_char(CP_UTF8, MB_ERR_INVALID_CHARS, cstr, i32(len(s)), Wstring(&text[0]), i32(n));
	if n1 == 0 {
		delete(text, allocator);
		return nil;
	}

	text[n] = 0;

	return text[:len(text)-1];
}
utf8_to_wstring :: proc(s: string, allocator := context.temp_allocator) -> Wstring {
	if res := utf8_to_utf16(s, allocator); res != nil {
		return Wstring(&res[0]);
	}
	return nil;
}

utf16_to_utf8 :: proc(s: []u16, allocator := context.temp_allocator) -> string {
	if len(s) < 1 {
		return "";
	}

	n := wide_char_to_multi_byte(CP_UTF8, WC_ERR_INVALID_CHARS, Wstring(&s[0]), i32(len(s)), nil, 0, nil, nil);
	if n == 0 {
		return "";
	}

	text := make([]byte, n+1, allocator);

	n1 := wide_char_to_multi_byte(CP_UTF8, WC_ERR_INVALID_CHARS, Wstring(&s[0]), i32(len(s)), cstring(&text[0]), n, nil, nil);
	if n1 == 0 {
		delete(text, allocator);
		return "";
	}

	text[n] = 0;

	return string(text[:len(text)-1]);
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
MAX_PATH_WIDE :: 0x8000;

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

