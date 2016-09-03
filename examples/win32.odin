#foreign_system_library "user32"
#foreign_system_library "gdi32"

CS_VREDRAW    :: 1
CS_HREDRAW    :: 2
CW_USEDEFAULT :: 0x80000000

WS_OVERLAPPED       :: 0
WS_MAXIMIZEBOX      :: 0x00010000
WS_MINIMIZEBOX      :: 0x00020000
WS_THICKFRAME       :: 0x00040000
WS_SYSMENU          :: 0x00080000
WS_CAPTION          :: 0x00C00000
WS_VISIBLE          :: 0x10000000
WS_OVERLAPPEDWINDOW :: WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX

WM_DESTROY :: 0x02
WM_CLOSE   :: 0x10
WM_QUIT    :: 0x12

PM_REMOVE :: 1

COLOR_BACKGROUND :: 1 as HBRUSH


HANDLE    :: type rawptr
HWND      :: type HANDLE
HDC       :: type HANDLE
HINSTANCE :: type HANDLE
HICON     :: type HANDLE
HCURSOR   :: type HANDLE
HMENU     :: type HANDLE
HBRUSH    :: type HANDLE
WPARAM    :: type uint
LPARAM    :: type int
LRESULT   :: type int
ATOM      :: type i16
BOOL      :: type i32
POINT     :: type struct { x, y: i32 }

INVALID_HANDLE_VALUE :: (-1 as int) as HANDLE

WNDPROC :: type proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT

WNDCLASSEXA :: type struct {
	size, style:           u32
	wnd_proc:              WNDPROC
	cls_extra, wnd_extra:  i32
	instance:              HINSTANCE
	icon:                  HICON
	cursor:                HCURSOR
	background:            HBRUSH
	menu_name, class_name: ^u8
	sm:                    HICON
}

MSG :: type struct {
	hwnd:    HWND
	message: u32
	wparam:  WPARAM
	lparam:  LPARAM
	time:    u32
	pt:      POINT
}



GetLastError     :: proc() -> i32 #foreign
ExitProcess      :: proc(exit_code: u32) #foreign
GetDesktopWindow :: proc() -> HWND #foreign
GetCursorPos     :: proc(p: ^POINT) -> i32 #foreign
ScreenToClient   :: proc(h: HWND, p: ^POINT) -> i32 #foreign

GetModuleHandleA :: proc(module_name: ^u8) -> HINSTANCE #foreign

QueryPerformanceFrequency :: proc(result: ^i64) -> i32 #foreign
QueryPerformanceCounter   :: proc(result: ^i64) -> i32 #foreign

sleep_ms :: proc(ms: i32) {
	Sleep :: proc(ms: i32) -> i32 #foreign
	Sleep(ms)
}

OutputDebugStringA :: proc(c_str: ^u8) #foreign


RegisterClassExA :: proc(wc: ^WNDCLASSEXA) -> ATOM #foreign
CreateWindowExA  :: proc(ex_style: u32,
                         class_name, title: ^u8,
                         style: u32,
                         x, y: u32,
                         w, h: i32,
                         parent: HWND, menu: HMENU, instance: HINSTANCE,
                         param: rawptr) -> HWND #foreign

ShowWindow       :: proc(hwnd: HWND, cmd_show: i32) -> BOOL #foreign
UpdateWindow     :: proc(hwnd: HWND) -> BOOL #foreign
PeekMessageA     :: proc(msg: ^MSG, hwnd: HWND,
                         msg_filter_min, msg_filter_max, remove_msg: u32) -> BOOL #foreign
TranslateMessage :: proc(msg: ^MSG) -> BOOL #foreign
DispatchMessageA :: proc(msg: ^MSG) -> LRESULT #foreign

DefWindowProcA   :: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT #foreign



GetQueryPerformanceFrequency :: proc() -> i64 {
	r: i64
	_ = QueryPerformanceFrequency(^r)
	return r
}

GetCommandLineA :: proc() -> ^u8 #foreign



// File Stuff

CloseHandle  :: proc(h: HANDLE) -> i32 #foreign
GetStdHandle :: proc(h: i32) -> HANDLE #foreign
CreateFileA  :: proc(filename: ^u8, desired_access, share_mode: u32,
                     security: rawptr,
                     creation, flags_and_attribs: u32, template_file: HANDLE) -> HANDLE #foreign
ReadFile     :: proc(h: HANDLE, buf: rawptr, to_read: u32, bytes_read: ^i32, overlapped: rawptr) -> BOOL #foreign
WriteFile    :: proc(h: HANDLE, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> i32 #foreign

GetFileSizeEx :: proc(file_handle: HANDLE, file_size: ^i64) -> BOOL #foreign

FILE_SHARE_READ      :: 0x00000001
FILE_SHARE_WRITE     :: 0x00000002
FILE_SHARE_DELETE    :: 0x00000004
FILE_GENERIC_ALL     :: 0x10000000
FILE_GENERIC_EXECUTE :: 0x20000000
FILE_GENERIC_WRITE   :: 0x40000000
FILE_GENERIC_READ    :: 0x80000000

STD_INPUT_HANDLE  :: -10
STD_OUTPUT_HANDLE :: -11
STD_ERROR_HANDLE  :: -12

CREATE_NEW        :: 1
CREATE_ALWAYS     :: 2
OPEN_EXISTING     :: 3
OPEN_ALWAYS       :: 4
TRUNCATE_EXISTING :: 5


HeapAlloc :: proc(h: HANDLE, flags: u32, bytes: int) -> rawptr #foreign
HeapFree  :: proc(h: HANDLE, flags: u32, memory: rawptr) -> BOOL #foreign
GetProcessHeap :: proc() -> HANDLE #foreign

HEAP_ZERO_MEMORY :: 0x00000008












// Windows OpenGL

PFD_TYPE_RGBA             :: 0
PFD_TYPE_COLORINDEX       :: 1
PFD_MAIN_PLANE            :: 0
PFD_OVERLAY_PLANE         :: 1
PFD_UNDERLAY_PLANE        :: -1
PFD_DOUBLEBUFFER          :: 1
PFD_STEREO                :: 2
PFD_DRAW_TO_WINDOW        :: 4
PFD_DRAW_TO_BITMAP        :: 8
PFD_SUPPORT_GDI           :: 16
PFD_SUPPORT_OPENGL        :: 32
PFD_GENERIC_FORMAT        :: 64
PFD_NEED_PALETTE          :: 128
PFD_NEED_SYSTEM_PALETTE   :: 0x00000100
PFD_SWAP_EXCHANGE         :: 0x00000200
PFD_SWAP_COPY             :: 0x00000400
PFD_SWAP_LAYER_BUFFERS    :: 0x00000800
PFD_GENERIC_ACCELERATED   :: 0x00001000
PFD_DEPTH_DONTCARE        :: 0x20000000
PFD_DOUBLEBUFFER_DONTCARE :: 0x40000000
PFD_STEREO_DONTCARE       :: 0x80000000

HGLRC :: type HANDLE
PROC  :: type proc()
wglCreateContextAttribsARBType :: type proc(hdc: HDC, hshareContext: rawptr, attribList: ^i32) -> HGLRC


PIXELFORMATDESCRIPTOR :: type struct  {
	size,
	version,
	flags: u32

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
	reserved: byte

	layer_mask,
	visible_mask,
	damage_mask: u32
}

GetDC             :: proc(h: HANDLE) -> HDC #foreign
SetPixelFormat    :: proc(hdc: HDC, pixel_format: i32, pfd: ^PIXELFORMATDESCRIPTOR ) -> BOOL #foreign
ChoosePixelFormat :: proc(hdc: HDC, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 #foreign
SwapBuffers       :: proc(hdc: HDC) -> BOOL #foreign


WGL_CONTEXT_MAJOR_VERSION_ARB             :: 0x2091
WGL_CONTEXT_MINOR_VERSION_ARB             :: 0x2092
WGL_CONTEXT_PROFILE_MASK_ARB              :: 0x9126
WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB :: 0x0002

wglCreateContext  :: proc(hdc: HDC) -> HGLRC #foreign
wglMakeCurrent    :: proc(hdc: HDC, hglrc: HGLRC) -> BOOL #foreign
wglGetProcAddress :: proc(c_str: ^u8) -> PROC #foreign
wglDeleteContext  :: proc(hglrc: HGLRC) -> BOOL #foreign



GetAsyncKeyState :: proc(v_key: i32) -> i16 #foreign

is_key_down :: proc(key: int) -> bool {
	return GetAsyncKeyState(key as i32) < 0
}


VK_LBUTTON    :: 0x01
VK_RBUTTON    :: 0x02
VK_CANCEL     :: 0x03
VK_MBUTTON    :: 0x04

VK_BACK       :: 0x08
VK_TAB        :: 0x09

VK_CLEAR      :: 0x0C
VK_RETURN     :: 0x0D

VK_SHIFT      :: 0x10
VK_CONTROL    :: 0x11
VK_MENU       :: 0x12
VK_PAUSE      :: 0x13
VK_CAPITAL    :: 0x14

VK_KANA       :: 0x15
VK_HANGEUL    :: 0x15
VK_HANGUL     :: 0x15
VK_JUNJA      :: 0x17
VK_FINAL      :: 0x18
VK_HANJA      :: 0x19
VK_KANJI      :: 0x19

VK_ESCAPE     :: 0x1B

VK_CONVERT    :: 0x1C
VK_NONCONVERT :: 0x1D
VK_ACCEPT     :: 0x1E
VK_MODECHANGE :: 0x1F

VK_SPACE      :: 0x20
VK_PRIOR      :: 0x21
VK_NEXT       :: 0x22
VK_END        :: 0x23
VK_HOME       :: 0x24
VK_LEFT       :: 0x25
VK_UP         :: 0x26
VK_RIGHT      :: 0x27
VK_DOWN       :: 0x28
VK_SELECT     :: 0x29
VK_PRINT      :: 0x2A
VK_EXECUTE    :: 0x2B
VK_SNAPSHOT   :: 0x2C
VK_INSERT     :: 0x2D
VK_DELETE     :: 0x2E
VK_HELP       :: 0x2F

VK_0 :: #rune "0"
VK_1 :: #rune "1"
VK_2 :: #rune "2"
VK_3 :: #rune "3"
VK_4 :: #rune "4"
VK_5 :: #rune "5"
VK_6 :: #rune "6"
VK_7 :: #rune "7"
VK_8 :: #rune "8"
VK_9 :: #rune "9"

VK_A :: #rune "A"
VK_B :: #rune "B"
VK_C :: #rune "C"
VK_D :: #rune "D"
VK_E :: #rune "E"
VK_F :: #rune "F"
VK_G :: #rune "G"
VK_H :: #rune "H"
VK_I :: #rune "I"
VK_J :: #rune "J"
VK_K :: #rune "K"
VK_L :: #rune "L"
VK_M :: #rune "M"
VK_N :: #rune "N"
VK_O :: #rune "O"
VK_P :: #rune "P"
VK_Q :: #rune "Q"
VK_R :: #rune "R"
VK_S :: #rune "S"
VK_T :: #rune "T"
VK_U :: #rune "U"
VK_V :: #rune "V"
VK_W :: #rune "W"
VK_X :: #rune "X"
VK_Y :: #rune "Y"
VK_Z :: #rune "Z"

VK_LWIN       :: 0x5B
VK_RWIN       :: 0x5C
VK_APPS       :: 0x5D

VK_NUMPAD0    :: 0x60
VK_NUMPAD1    :: 0x61
VK_NUMPAD2    :: 0x62
VK_NUMPAD3    :: 0x63
VK_NUMPAD4    :: 0x64
VK_NUMPAD5    :: 0x65
VK_NUMPAD6    :: 0x66
VK_NUMPAD7    :: 0x67
VK_NUMPAD8    :: 0x68
VK_NUMPAD9    :: 0x69
VK_MULTIPLY   :: 0x6A
VK_ADD        :: 0x6B
VK_SEPARATOR  :: 0x6C
VK_SUBTRACT   :: 0x6D
VK_DECIMAL    :: 0x6E
VK_DIVIDE     :: 0x6F
VK_F1         :: 0x70
VK_F2         :: 0x71
VK_F3         :: 0x72
VK_F4         :: 0x73
VK_F5         :: 0x74
VK_F6         :: 0x75
VK_F7         :: 0x76
VK_F8         :: 0x77
VK_F9         :: 0x78
VK_F10        :: 0x79
VK_F11        :: 0x7A
VK_F12        :: 0x7B
VK_F13        :: 0x7C
VK_F14        :: 0x7D
VK_F15        :: 0x7E
VK_F16        :: 0x7F
VK_F17        :: 0x80
VK_F18        :: 0x81
VK_F19        :: 0x82
VK_F20        :: 0x83
VK_F21        :: 0x84
VK_F22        :: 0x85
VK_F23        :: 0x86
VK_F24        :: 0x87

VK_NUMLOCK    :: 0x90
VK_SCROLL     :: 0x91

VK_LSHIFT     :: 0xA0
VK_RSHIFT     :: 0xA1
VK_LCONTROL   :: 0xA2
VK_RCONTROL   :: 0xA3
VK_LMENU      :: 0xA4
VK_RMENU      :: 0xA5
VK_PROCESSKEY :: 0xE5
VK_ATTN       :: 0xF6
VK_CRSEL      :: 0xF7
VK_EXSEL      :: 0xF8
VK_EREOF      :: 0xF9
VK_PLAY       :: 0xFA
VK_ZOOM       :: 0xFB
VK_NONAME     :: 0xFC
VK_PA1        :: 0xFD
VK_OEM_CLEAR  :: 0xFE

