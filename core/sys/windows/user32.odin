// +build windows
package sys_windows

foreign import user32 "system:User32.lib"

@(default_calling_convention="stdcall")
foreign user32 {
	GetClassInfoA :: proc(hInstance: HINSTANCE, lpClassNAme: LPCSTR, lpWndClass: ^WNDCLASSA) -> BOOL ---
	GetClassInfoW :: proc(hInstance: HINSTANCE, lpClassNAme: LPCWSTR, lpWndClass: ^WNDCLASSW) -> BOOL ---
	GetClassInfoExA :: proc(hInsatnce: HINSTANCE, lpszClass: LPCSTR, lpwcx: ^WNDCLASSEXA) -> BOOL ---
	GetClassInfoExW :: proc(hInsatnce: HINSTANCE, lpszClass: LPCWSTR, lpwcx: ^WNDCLASSEXW) -> BOOL ---

	GetClassLongA :: proc(hWnd: HWND, nIndex: c_int) -> DWORD ---
	GetClassLongW :: proc(hWnd: HWND, nIndex: c_int) -> DWORD ---
	SetClassLongA :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> DWORD ---
	SetClassLongW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> DWORD ---

	GetWindowLongA :: proc(hWnd: HWND, nIndex: c_int) -> LONG ---
	GetWindowLongW :: proc(hWnd: HWND, nIndex: c_int) -> LONG ---
	SetWindowLongA :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> LONG ---
	SetWindowLongW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> LONG ---

	GetClassNameA :: proc(hWnd: HWND, lpClassName: LPSTR, nMaxCount: c_int) -> c_int ---
	GetClassNameW :: proc(hWnd: HWND, lpClassName: LPWSTR, nMaxCount: c_int) -> c_int ---

	RegisterClassA :: proc(lpWndClass: ^WNDCLASSA) -> ATOM ---
	RegisterClassW :: proc(lpWndClass: ^WNDCLASSW) -> ATOM ---
	RegisterClassExA :: proc(^WNDCLASSEXA) -> ATOM ---
	RegisterClassExW :: proc(^WNDCLASSEXW) -> ATOM ---

	CreateWindowExA :: proc(
		dwExStyle: DWORD,
		lpClassName: LPCSTR,
		lpWindowName: LPCSTR,
		dwStyle: DWORD,
		X: c_int,
		Y: c_int,
		nWidth: c_int,
		nHeight: c_int,
		hWndParent: HWND,
		hMenu: HMENU,
		hInstance: HINSTANCE,
		lpParam: LPVOID,
	) -> HWND ---
	CreateWindowExW :: proc(
		dwExStyle: DWORD,
		lpClassName: LPCWSTR,
		lpWindowName: LPCWSTR,
		dwStyle: DWORD,
		X: c_int,
		Y: c_int,
		nWidth: c_int,
		nHeight: c_int,
		hWndParent: HWND,
		hMenu: HMENU,
		hInstance: HINSTANCE,
		lpParam: LPVOID,
	) -> HWND ---

	DestroyWindow :: proc(hWnd: HWND) -> BOOL ---

	ShowWindow :: proc(hWnd: HWND, nCmdShow: c_int) -> BOOL ---
	BringWindowToTop :: proc(hWnd: HWND) -> BOOL ---
	GetTopWindow :: proc(hWnd: HWND) -> HWND ---
	SetForegroundWindow :: proc(hWnd: HWND) -> BOOL ---
	GetForegroundWindow :: proc() -> HWND ---
	SetActiveWindow :: proc(hWnd: HWND) -> HWND ---
	GetActiveWindow :: proc() -> HWND ---

	GetMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---
	GetMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---

	TranslateMessage :: proc(lpMsg: ^MSG) -> BOOL ---
	DispatchMessageA :: proc(lpMsg: ^MSG) -> LRESULT ---
	DispatchMessageW :: proc(lpMsg: ^MSG) -> LRESULT ---

	PeekMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---
	PeekMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---

	PostMessageA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	PostMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	SendMessageA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	SendMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	PostThreadMessageA :: proc(idThread: DWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	PostThreadMessageW :: proc(idThread: DWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---

	PostQuitMessage :: proc(nExitCode: c_int) ---

	GetQueueStatus :: proc(flags: UINT) -> DWORD ---

	DefWindowProcA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	DefWindowProcW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	FindWindowA :: proc(lpClassName: LPCSTR, lpWindowName: LPCSTR) -> HWND ---
	FindWindowW :: proc(lpClassName: LPCWSTR, lpWindowName: LPCWSTR) -> HWND ---
	FindWindowExA :: proc(hWndParent: HWND, hWndChildAfter: HWND, lpszClass: LPCSTR, lpszWindow: LPCSTR) -> HWND ---
	FindWindowExW :: proc(hWndParent: HWND, hWndChildAfter: HWND, lpszClass: LPCWSTR, lpszWindow: LPCWSTR) -> HWND ---

	LoadIconA :: proc(hInstance: HINSTANCE, lpIconName: LPCSTR) -> HICON ---
	LoadIconW :: proc(hInstance: HINSTANCE, lpIconName: LPCWSTR) -> HICON ---
	LoadCursorA :: proc(hInstance: HINSTANCE, lpCursorName: LPCSTR) -> HCURSOR ---
	LoadCursorW :: proc(hInstance: HINSTANCE, lpCursorName: LPCWSTR) -> HCURSOR ---

	GetWindowRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	GetClientRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	ClientToScreen :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	SetWindowPos :: proc(
		hWnd: HWND,
		hWndInsertAfter: HWND,
		X: c_int,
		Y: c_int,
		cx: c_int,
		cy: c_int,
		uFlags: UINT,
	) -> BOOL ---
	GetSystemMetrics :: proc(nIndex: c_int) -> c_int ---
	AdjustWindowRect :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL) -> BOOL ---
	AdjustWindowRectEx :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) -> BOOL ---

	GetWindowDC :: proc(hWnd: HWND) -> HDC ---
	GetDC :: proc(hWnd: HWND) -> HDC ---
	ReleaseDC :: proc(hWnd: HWND, hDC: HDC) -> c_int ---

	GetUpdateRect :: proc(hWnd: HWND, lpRect: LPRECT, bErase: BOOL) -> BOOL ---
	ValidateRect :: proc(hWnd: HWND, lpRect: ^RECT) -> BOOL ---
	InvalidateRect :: proc(hWnd: HWND, lpRect: ^RECT, bErase: BOOL) -> BOOL ---

	BeginPaint :: proc(hWnd: HWND, lpPaint: ^PAINTSTRUCT) -> HDC ---
	EndPaint :: proc(hWnd: HWND, lpPaint: ^PAINTSTRUCT) -> BOOL ---

	GetCapture :: proc() -> HWND ---
	SetCapture :: proc(hWnd: HWND) -> HWND ---
	ReleaseCapture :: proc() -> BOOL ---
	TrackMouseEvent :: proc(lpEventTrack: LPTRACKMOUSEEVENT) -> BOOL ---

	GetKeyState :: proc(nVirtKey: c_int) -> SHORT ---
	GetAsyncKeyState :: proc(vKey: c_int) -> SHORT ---

	MapVirtualKeyA :: proc(uCode: UINT, uMapType: UINT) -> UINT ---
	MapVirtualKeyW :: proc(uCode: UINT, uMapType: UINT) -> UINT ---

	SetWindowsHookExA :: proc(idHook: c_int, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD) -> HHOOK ---
	SetWindowsHookExW :: proc(idHook: c_int, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD) -> HHOOK ---
	UnhookWindowsHookEx :: proc(hhk: HHOOK) -> BOOL ---
	CallNextHookEx :: proc(hhk: HHOOK, nCode: c_int, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	SetTimer :: proc(hWnd: HWND, nIDEvent: UINT_PTR, uElapse: UINT, lpTimerFunc: TIMERPROC) -> UINT_PTR ---
	KillTimer :: proc(hWnd: HWND, uIDEvent: UINT_PTR) -> BOOL ---

	MessageBoxA :: proc(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) -> c_int ---
	MessageBoxW :: proc(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT) -> c_int ---
	MessageBoxExA :: proc(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT, wLanguageId: WORD) -> c_int ---
	MessageBoxExW :: proc(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT, wLanguageId: WORD) -> c_int ---
}

CreateWindowA :: #force_inline proc "stdcall" (
	lpClassName: LPCSTR,
	lpWindowName: LPCSTR,
	dwStyle: DWORD,
	X: c_int,
	Y: c_int,
	nWidth: c_int,
	nHeight: c_int,
	hWndParent: HWND,
	hMenu: HMENU,
	hInstance: HINSTANCE,
	lpParam: LPVOID,
) -> HWND {
	return CreateWindowExA(
		0,
		lpClassName,
		lpWindowName,
		dwStyle,
		X,
		Y,
		nWidth,
		nHeight,
		hWndParent,
		hMenu,
		hInstance,
		lpParam,
	)
}

CreateWindowW :: #force_inline proc "stdcall" (
	lpClassName: LPCTSTR,
	lpWindowName: LPCTSTR,
	dwStyle: DWORD,
	X: c_int,
	Y: c_int,
	nWidth: c_int,
	nHeight: c_int,
	hWndParent: HWND,
	hMenu: HMENU,
	hInstance: HINSTANCE,
	lpParam: LPVOID,
) -> HWND {
	return CreateWindowExW(
		0,
		lpClassName,
		lpWindowName,
		dwStyle,
		X,
		Y,
		nWidth,
		nHeight,
		hWndParent,
		hMenu,
		hInstance,
		lpParam,
	)
}

when ODIN_ARCH == .amd64 {
	@(default_calling_convention="stdcall")
	foreign user32 {
		GetClassLongPtrA :: proc(hWnd: HWND, nIndex: c_int) -> ULONG_PTR ---
		GetClassLongPtrW :: proc(hWnd: HWND, nIndex: c_int) -> ULONG_PTR ---
		SetClassLongPtrA :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> ULONG_PTR ---
		SetClassLongPtrW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> ULONG_PTR ---

		GetWindowLongPtrA :: proc(hWnd: HWND, nIndex: c_int) -> LONG_PTR ---
		GetWindowLongPtrW :: proc(hWnd: HWND, nIndex: c_int) -> LONG_PTR ---
		SetWindowLongPtrA :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> LONG_PTR ---
		SetWindowLongPtrW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> LONG_PTR ---
	}
} else when ODIN_ARCH == .i386 {
	GetClassLongPtrA :: GetClassLongA
	GetClassLongPtrW :: GetClassLongW
	SetClassLongPtrA :: SetClassLongA
	SetClassLongPtrW :: SetClassLongW

	GetWindowLongPtrA :: GetWindowLongA
	GetWindowLongPtrW :: GetWindowLongW
	SetWindowLongPtrA :: GetWindowLongA
	SetWindowLongPtrW :: GetWindowLongW
}

GET_SC_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> c_int {
	return c_int(wParam) & 0xFFF0
}

GET_WHEEL_DELTA_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> c_short {
	return cast(c_short)HIWORD(cast(DWORD)wParam)
}

GET_KEYSTATE_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> WORD {
	return LOWORD(cast(DWORD)wParam)
}

GET_NCHITTEST_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> c_short {
	return cast(c_short)LOWORD(cast(DWORD)wParam)
}

GET_XBUTTON_WPARAM ::  #force_inline proc "contextless" (wParam: WPARAM) -> WORD {
	return HIWORD(cast(DWORD)wParam)
}
