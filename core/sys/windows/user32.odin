// +build windows
package sys_windows
foreign import user32 "system:User32.lib"

WNDPROC :: proc "stdcall" (HWND, UINT, WPARAM, LPARAM) -> LRESULT

CS_VREDRAW         : UINT : 0x0001
CS_HREDRAW         : UINT : 0x0002
CS_DBLCLKS         : UINT : 0x0008
CS_OWNDC           : UINT : 0x0020
CS_CLASSDC         : UINT : 0x0040
CS_PARENTDC        : UINT : 0x0080
CS_NOCLOSE         : UINT : 0x0200
CS_SAVEBITS        : UINT : 0x0800
CS_BYTEALIGNCLIENT : UINT : 0x1000
CS_BYTEALIGNWINDOW : UINT : 0x2000
CS_GLOBALCLASS     : UINT : 0x4000
CS_DROPSHADOW      : UINT : 0x0002_0000

GWL_EXSTYLE    : c_int : -20
GWLP_HINSTANCE : c_int : -6
GWLP_ID        : c_int : -12
GWL_STYLE      : c_int : -16
GWLP_USERDATA  : c_int : -21
GWLP_WNDPROC   : c_int : -4

WS_BORDER           : UINT : 0x0080_0000
WS_CAPTION          : UINT : 0x00C0_0000
WS_CHILD            : UINT : 0x4000_0000
WS_CHILDWINDOW      : UINT : WS_CHILD
WS_CLIPCHILDREN     : UINT : 0x0200_0000
WS_CLIPSIBLINGS     : UINT : 0x0400_0000
WS_DISABLED         : UINT : 0x0800_0000
WS_DLGFRAME         : UINT : 0x0040_0000
WS_GROUP            : UINT : 0x0002_0000
WS_HSCROLL          : UINT : 0x0010_0000
WS_ICONIC           : UINT : 0x2000_0000
WS_MAXIMIZE         : UINT : 0x0100_0000
WS_MAXIMIZEBOX      : UINT : 0x0001_0000
WS_MINIMIZE         : UINT : 0x2000_0000
WS_MINIMIZEBOX      : UINT : 0x0002_0000
WS_OVERLAPPED       : UINT : 0x0000_0000
WS_OVERLAPPEDWINDOW : UINT : WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
WS_POPUP			: UINT : 0x8000_0000
WS_POPUPWINDOW      : UINT : WS_POPUP | WS_BORDER | WS_SYSMENU
WS_SIZEBOX          : UINT : 0x0004_0000
WS_SYSMENU          : UINT : 0x0008_0000
WS_TABSTOP          : UINT : 0x0001_0000
WS_THICKFRAME       : UINT : 0x0004_0000
WS_TILED            : UINT : 0x0000_0000
WS_TILEDWINDOW      : UINT : WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_THICKFRAME | WS_MINIMIZE | WS_MAXIMIZE
WS_VISIBLE          : UINT : 0x1000_0000
WS_VSCROLL          : UINT : 0x0020_0000

QS_ALLEVENTS      : UINT : QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY
QS_ALLINPUT       : UINT : QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY | QS_SENDMESSAGE
QS_ALLPOSTMESSAGE : UINT : 0x0100
QS_HOTKEY         : UINT : 0x0080
QS_INPUT          : UINT : QS_MOUSE | QS_KEY | QS_RAWINPUT
QS_KEY            : UINT : 0x0001
QS_MOUSE          : UINT : QS_MOUSEMOVE | QS_MOUSEBUTTON
QS_MOUSEBUTTON    : UINT : 0x0004
QS_MOUSEMOVE      : UINT : 0x0002
QS_PAINT          : UINT : 0x0020
QS_POSTMESSAGE    : UINT : 0x0008
QS_RAWINPUT       : UINT : 0x0400
QS_SENDMESSAGE    : UINT : 0x0040
QS_TIMER          : UINT : 0x0010

PM_NOREMOVE : UINT : 0x0000
PM_REMOVE   : UINT : 0x0001
PM_NOYIELD  : UINT : 0x0002

PM_QS_INPUT       : UINT : QS_INPUT << 16
PM_QS_PAINT       : UINT : QS_PAINT << 16
PM_QS_POSTMESSAGE : UINT : (QS_POSTMESSAGE | QS_HOTKEY | QS_TIMER) << 16
PM_QS_SENDMESSAGE : UINT : QS_SENDMESSAGE << 16

SW_HIDE            : c_int : 0
SW_SHOWNORMAL      : c_int : SW_NORMAL
SW_NORMAL          : c_int : 1
SW_SHOWMINIMIZED   : c_int : 2
SW_SHOWMAXIMIZED   : c_int : SW_MAXIMIZE
SW_MAXIMIZE        : c_int : 3
SW_SHOWNOACTIVATE  : c_int : 4
SW_SHOW            : c_int : 5
SW_MINIMIZE        : c_int : 6
SW_SHOWMINNOACTIVE : c_int : 7
SW_SHOWNA          : c_int : 8
SW_RESTORE         : c_int : 9
SW_SHOWDEFAULT     : c_int : 10
SW_FORCEMINIMIZE   : c_int : 11

CW_USEDEFAULT      : c_int : -2147483648

WNDCLASSA :: struct {
	style:         UINT,
	lpfnWndProc:   WNDPROC,
	cbClsExtra:    c_int,
	cbWndExtra:    c_int,
	hInstance:     HINSTANCE,
	hIcon:         HICON,
	hCursor:       HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName:  LPCSTR,
	lpszClassName: LPCSTR,
}

WNDCLASSW :: struct {
	style:         UINT,
	lpfnWndProc:   WNDPROC,
	cbClsExtra:    c_int,
	cbWndExtra:    c_int,
	hInstance:     HINSTANCE,
	hIcon:         HICON,
	hCursor:       HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName:  LPCWSTR,
	lpszClassName: LPCWSTR,
}

WNDCLASSEXA :: struct {
	cbSize:        UINT,
	style:         UINT,
	lpfnWndProc:   WNDPROC,
	cbClsExtra:    c_int,
	cbWndExtra:    c_int,
	hInstance:     HINSTANCE,
	hIcon:         HICON,
	hCursor:       HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName:  LPCSTR,
	lpszClassName: LPCSTR,
	hIconSm:       HICON,
}

WNDCLASSEXW :: struct {
	cbSize:        UINT,
	style:         UINT,
	lpfnWndProc:   ^WNDPROC,
	cbClsExtra:    c_int,
	cbWndExtra:    c_int,
	hInstance:     HINSTANCE,
	hIcon:         HICON,
	hCursor:       HCURSOR,
	hbrBackground: HBRUSH,
	lpszMenuName:  LPCWSTR,
	lpszClassName: LPCWSTR,
	hIconSm:       HICON,
}

MSG :: struct {
	hwnd:     HWND,
	message:  UINT,
	wParam:   WPARAM,
	lParam:   LPARAM,
	time:     DWORD,
	pt:       POINT,
	lPrivate: DWORD,
}

CREATESTRUCTA :: struct {
	lpCreateParams: LPVOID,
	hInstance:      HINSTANCE,
	hMenu:          HMENU,
	hwndParent:     HWND,
	cy:             c_int,
	cx:             c_int,
	y:              c_int,
	x:              c_int,
	style:          LONG,
	lpszName:       LPCSTR,
	lpszClass:      LPCSTR,
	dwExStyle:      DWORD,
}

CREATESTRUCTW:: struct {
	lpCreateParams: LPVOID,
	hInstance:      HINSTANCE,
	hMenu:          HMENU,
	hwndParent:     HWND,
	cy:             c_int,
	cx:             c_int,
	y:              c_int,
	x:              c_int,
	style:          LONG,
	lpszName:       LPCWSTR,
	lpszClass:      LPCWSTR,
	dwExStyle:      DWORD,
}

_IDC_APPSTARTING := rawptr(uintptr(32650))
_IDC_ARROW       := rawptr(uintptr(32512))
_IDC_CROSS       := rawptr(uintptr(32515))
_IDC_HAND        := rawptr(uintptr(32649))
_IDC_HELP        := rawptr(uintptr(32651))
_IDC_IBEAM       := rawptr(uintptr(32513))
_IDC_ICON        := rawptr(uintptr(32641))
_IDC_NO          := rawptr(uintptr(32648))
_IDC_SIZE        := rawptr(uintptr(32640))
_IDC_SIZEALL     := rawptr(uintptr(32646))
_IDC_SIZENESW    := rawptr(uintptr(32643))
_IDC_SIZENS      := rawptr(uintptr(32645))
_IDC_SIZENWSE    := rawptr(uintptr(32642))
_IDC_SIZEWE      := rawptr(uintptr(32644))
_IDC_UPARROW     := rawptr(uintptr(32516))
_IDC_WAIT        := rawptr(uintptr(32514))
IDC_APPSTARTING := cstring(_IDC_APPSTARTING)
IDC_ARROW       := cstring(_IDC_ARROW)
IDC_CROSS       := cstring(_IDC_CROSS)
IDC_HAND        := cstring(_IDC_HAND)
IDC_HELP        := cstring(_IDC_HELP)
IDC_IBEAM       := cstring(_IDC_IBEAM)
IDC_ICON        := cstring(_IDC_ICON)
IDC_NO          := cstring(_IDC_NO)
IDC_SIZE        := cstring(_IDC_SIZE)
IDC_SIZEALL     := cstring(_IDC_SIZEALL)
IDC_SIZENESW    := cstring(_IDC_SIZENESW)
IDC_SIZENS      := cstring(_IDC_SIZENS)
IDC_SIZENWSE    := cstring(_IDC_SIZENWSE)
IDC_SIZEWE      := cstring(_IDC_SIZEWE)
IDC_UPARROW     := cstring(_IDC_UPARROW)
IDC_WAIT        := cstring(_IDC_WAIT)


@(default_calling_convention="stdcall")
foreign user32 {

	GetClassInfoA :: proc(hInstance: HINSTANCE, lpClassNAme: LPCSTR, lpWndClass: ^WNDCLASSA) -> BOOL ---
	GetClassInfoW :: proc(hInstance: HINSTANCE, lpClassNAme: LPCWSTR, lpWndClass: ^WNDCLASSW) -> BOOL ---
	GetClassInfoExA :: proc(hInsatnce: HINSTANCE, lpszClass: LPCSTR, lpwcx: ^WNDCLASSEXA) -> BOOL ---
	GetClassInfoExW :: proc(hInsatnce: HINSTANCE, lpszClass: LPCWSTR, lpwcx: ^WNDCLASSEXW) -> BOOL ---
	GetClassLongPtrA :: proc(hWnd: HWND, nIndex: c_int) -> DWORD ---
	GetClassLongPtrW :: proc(hWnd: HWND, nIndex: c_int) -> DWORD ---
	GetClassNameA :: proc(hWnd: HWND, lpClassName: LPSTR, nMaxCount: c_int) -> c_int ---
	GetClassNameW :: proc(hWnd: HWND, lpClassName: LPWSTR, nMaxCount: c_int) -> c_int ---
	GetWindowLongPtrA :: proc(hWnd: HWND, nIndex: c_int) -> LONG_PTR ---
	GetWindowLongPtrW :: proc(hWnd: HWND, nIndex: c_int) -> LONG_PTR ---
	RegisterClassA :: proc(^WNDCLASSA) -> ATOM ---
	RegisterClassW :: proc(^WNDCLASSW) -> ATOM ---
	RegisterClassExA :: proc(^WNDCLASSEXA) -> ATOM ---
	RegisterClassExW :: proc(^WNDCLASSEXW) -> ATOM ---
	SetClassLongPtrA :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> ULONG_PTR ---
	SetClassLongPtrW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> ULONG_PTR ---
	SetWindowLongPtrA :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> LONG_PTR ---
	SetWindowLongPtrW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> LONG_PTR ---
	UnregisterClassA :: proc(lpClassName: LPCSTR, hInstance: HINSTANCE) -> BOOL ---
	UnregisterClassW :: proc(lpClassName: LPCWSTR, hInstance: HINSTANCE) -> BOOL ---

	CreateWindowA :: proc(lpClassName: LPCSTR, lpWindowName: LPCSTR, dwStyle: DWORD, x: c_int, y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPARAM) -> HWND ---
	CreateWindowW :: proc(lpClassName: LPCWSTR, lpWindowName: LPCWSTR, dwStyle: DWORD, x: c_int, y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPARAM) -> HWND ---
	CreateWindowExA :: proc(dwExStyle: DWORD, lpClassName: LPCSTR, lpWindowName: LPCSTR, dwStyle: DWORD, x: c_int, y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPARAM) -> HWND ---
	CreateWindowExW :: proc(dwExStyle: DWORD, lpClassName: LPCWSTR, lpWindowName: LPCWSTR, dwStyle: DWORD, x: c_int, y: c_int, nWidth: c_int, nHeight: c_int, hWndParent: HWND, hMenu: HMENU, hInstance: HINSTANCE, lpParam: LPARAM) -> HWND ---

	DestroyWindow :: proc(hWnd: HWND) -> BOOL ---

	ShowWindow :: proc(hWnd: HWND, nCmdShow: c_int) -> BOOL ---

	GetMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---
	GetMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---
	PeekMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---
	PeekMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---

	TranslateMessage :: proc(lpMsg: ^MSG) -> BOOL ---
	DispatchMessageA :: proc(lpMsg: ^MSG) -> LRESULT ---
	DispatchMessageW :: proc(lpMsg: ^MSG) -> LRESULT ---

	PostQuitMessage :: proc(nExitCode: c_int) ---

	PostMessageA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	PostMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---

	GetQueueStatus :: proc(flags: UINT) -> DWORD ---

	DefWindowProcA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParma: LPARAM) -> LRESULT ---
	DefWindowProcW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParma: LPARAM) -> LRESULT ---

	LoadCursorA :: proc(hInstance: HINSTANCE, lpCursorName: LPCSTR) -> HCURSOR ---
	LoadCursorW :: proc(hInstance: HINSTANCE, lpCursorName: LPCWSTR) -> HCURSOR ---
}
