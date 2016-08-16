STD_INPUT_HANDLE  :: -10;
STD_OUTPUT_HANDLE :: -11;
STD_ERROR_HANDLE  :: -12;

CS_VREDRAW    :: 1;
CS_HREDRAW    :: 2;
CW_USEDEFAULT :: 0x80000000;

WS_OVERLAPPED       :: 0;
WS_MAXIMIZEBOX      :: 0x00010000;
WS_MINIMIZEBOX      :: 0x00020000;
WS_THICKFRAME       :: 0x00040000;
WS_SYSMENU          :: 0x00080000;
WS_CAPTION          :: 0x00C00000;
WS_VISIBLE          :: 0x10000000;
WS_OVERLAPPEDWINDOW :: WS_OVERLAPPED|WS_CAPTION|WS_SYSMENU|WS_THICKFRAME|WS_MINIMIZEBOX|WS_MAXIMIZEBOX;

WM_DESTROY :: 0x02;
WM_CLOSE   :: 0x10;
WM_QUIT    :: 0x12;

PM_REMOVE :: 1;

COLOR_BACKGROUND: rawptr : 1; // NOTE(bill): cast to HBRUSH when needed


type HANDLE: rawptr
type HWND: HANDLE
type HDC: HANDLE
type HINSTANCE: HANDLE
type HICON: HANDLE
type HCURSOR: HANDLE
type HMENU: HANDLE
type HBRUSH: HANDLE
type WPARAM: uint
type LPARAM: int
type LRESULT: int
type ATOM: i16
type POINT: struct { x, y: i32 }
type BOOL: i32

type WNDPROC: proc(hwnd: HWND, msg: u32, wparam: WPARAM, lparam: LPARAM) -> LRESULT

type WNDCLASSEXA: struct {
	cbSize, style: u32,
	wndProc: WNDPROC,
	cbClsExtra, cbWndExtra: i32,
	hInstance: HINSTANCE,
	hIcon: HICON,
	hCursor: HCURSOR,
	hbrBackground: HBRUSH,
	menuName, className: ^u8,
	hIconSm: HICON,
}

type MSG: struct {
	hwnd: HWND,
	message: u32,
	wparam: WPARAM,
	lparam: LPARAM,
	time: u32,
	pt: POINT,
}


GetStdHandle     :: proc(h: i32) -> HANDLE #foreign
CloseHandle      :: proc(h: HANDLE) -> i32 #foreign
WriteFileA       :: proc(h: HANDLE, buf: rawptr, len: i32, written_result: ^i32, overlapped: rawptr) -> i32 #foreign
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
	Sleep(ms);
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
	r: i64;
	_ = QueryPerformanceFrequency(^r);
	return r;
}





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

type HGLRC: HANDLE
type PROC: proc()
type wglCreateContextAttribsARBType: proc(hdc: HDC, hshareContext: rawptr, attribList: ^i32) -> HGLRC


type PIXELFORMATDESCRIPTOR: struct  {
	nSize,
	nVersion,
	dwFlags: u32,

	iPixelType,
	cColorBits,
	cRedBits,
	cRedShift,
	cGreenBits,
	cGreenShift,
	cBlueBits,
	cBlueShift,
	cAlphaBits,
	cAlphaShift,
	cAccumBits,
	cAccumRedBits,
	cAccumGreenBits,
	cAccumBlueBits,
	cAccumAlphaBits,
	cDepthBits,
	cStencilBits,
	cAuxBuffers,
	iLayerType,
	bReserved: byte,

	dwLayerMask,
	dwVisibleMask,
	dwDamageMask: u32,
}

GetDC :: proc(h: HANDLE) -> HDC #foreign
SetPixelFormat    :: proc(hdc: HDC, pixel_format: i32, pfd: ^PIXELFORMATDESCRIPTOR ) -> BOOL #foreign
ChoosePixelFormat :: proc(hdc: HDC, pfd: ^PIXELFORMATDESCRIPTOR) -> i32 #foreign
wglCreateContext  :: proc(hdc: HDC) -> HGLRC #foreign
wglMakeCurrent    :: proc(hdc: HDC, hglrc: HGLRC) -> BOOL #foreign
wglGetProcAddress :: proc(c_str: ^u8) -> PROC #foreign
wglDeleteContext  :: proc(hglrc: HGLRC) -> BOOL #foreign
SwapBuffers       :: proc(hdc: HDC) -> BOOL #foreign
