// +build windows
package sys_windows

import "base:intrinsics"
foreign import user32 "system:User32.lib"

@(default_calling_convention="system")
foreign user32 {
	GetClassInfoW :: proc(hInstance: HINSTANCE, lpClassNAme: LPCWSTR, lpWndClass: ^WNDCLASSW) -> BOOL ---
	GetClassInfoExW :: proc(hInsatnce: HINSTANCE, lpszClass: LPCWSTR, lpwcx: ^WNDCLASSEXW) -> BOOL ---

	GetClassLongW :: proc(hWnd: HWND, nIndex: c_int) -> DWORD ---
	SetClassLongW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> DWORD ---

	GetWindowLongW :: proc(hWnd: HWND, nIndex: c_int) -> LONG ---
	SetWindowLongW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> LONG ---

	GetClassNameW :: proc(hWnd: HWND, lpClassName: LPWSTR, nMaxCount: c_int) -> c_int ---

	RegisterClassW :: proc(lpWndClass: ^WNDCLASSW) -> ATOM ---
	RegisterClassExW :: proc(^WNDCLASSEXW) -> ATOM ---
	UnregisterClassW :: proc(lpClassName: LPCWSTR, hInstance: HINSTANCE) -> BOOL ---

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
	IsWindow :: proc(hWnd: HWND) -> BOOL ---
	BringWindowToTop :: proc(hWnd: HWND) -> BOOL ---
	GetTopWindow :: proc(hWnd: HWND) -> HWND ---
	SetForegroundWindow :: proc(hWnd: HWND) -> BOOL ---
	GetForegroundWindow :: proc() -> HWND ---
	UpdateWindow :: proc(hWnd: HWND) -> BOOL ---
	SetActiveWindow :: proc(hWnd: HWND) -> HWND ---
	GetActiveWindow :: proc() -> HWND ---
	RedrawWindow :: proc(hwnd: HWND, lprcUpdate: LPRECT, hrgnUpdate: HRGN, flags: RedrawWindowFlags) -> BOOL ---

	GetMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> BOOL ---

	TranslateMessage :: proc(lpMsg: ^MSG) -> BOOL ---
	DispatchMessageW :: proc(lpMsg: ^MSG) -> LRESULT ---

	WaitMessage :: proc() -> BOOL ---
	MsgWaitForMultipleObjects :: proc(nCount: DWORD, pHandles: ^HANDLE, fWaitAll: bool, dwMilliseconds: DWORD, dwWakeMask: DWORD) -> DWORD ---

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
	LoadImageW :: proc(hInst: HINSTANCE, name: LPCWSTR, type: UINT, cx: c_int, cy: c_int, fuLoad: UINT) -> HANDLE ---

	CreateIcon :: proc(hInstance: HINSTANCE, nWidth: c_int, nHeight: c_int, cPlanes: BYTE, cBitsPixel: BYTE, lpbANDbits: PBYTE, lpbXORbits: PBYTE) -> HICON ---
	CreateIconFromResource :: proc(presbits: PBYTE, dwResSize: DWORD, fIcon: BOOL, dwVer: DWORD) -> HICON ---
	DestroyIcon :: proc(hIcon: HICON) -> BOOL ---
	DrawIcon :: proc(hDC: HDC, X: c_int, Y: c_int, hIcon: HICON) -> BOOL ---

	CreateCursor :: proc(hInst: HINSTANCE, xHotSpot: c_int, yHotSpot: c_int, nWidth: c_int, nHeight: c_int, pvANDPlane: PVOID, pvXORPlane: PVOID) -> HCURSOR ---
	DestroyCursor :: proc(hCursor: HCURSOR) -> BOOL ---

	GetWindowRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	GetClientRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	ClientToScreen :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	ScreenToClient :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	SetWindowPos :: proc(
		hWnd: HWND,
		hWndInsertAfter: HWND,
		X: c_int,
		Y: c_int,
		cx: c_int,
		cy: c_int,
		uFlags: UINT,
	) -> BOOL ---
	MoveWindow :: proc(hWnd: HWND, X, Y, hWidth, hHeight: c_int, bRepaint: BOOL) -> BOOL ---
	GetSystemMetrics :: proc(nIndex: c_int) -> c_int ---
	AdjustWindowRect :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL) -> BOOL ---
	AdjustWindowRectEx :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) -> BOOL ---
	AdjustWindowRectExForDpi :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD, dpi: UINT) -> BOOL ---

	SystemParametersInfoW :: proc(uiAction, uiParam: UINT, pvParam: PVOID, fWinIni: UINT) -> BOOL ---
	GetMonitorInfoW :: proc(hMonitor: HMONITOR, lpmi: LPMONITORINFO) -> BOOL ---

	GetWindowDC :: proc(hWnd: HWND) -> HDC ---
	GetDC :: proc(hWnd: HWND) -> HDC ---
	ReleaseDC :: proc(hWnd: HWND, hDC: HDC) -> c_int ---

	GetDlgCtrlID :: proc(hWnd: HWND) -> c_int ---
	GetDlgItem :: proc(hDlg: HWND, nIDDlgItem: c_int) -> HWND ---

	CreatePopupMenu :: proc() -> HMENU ---
	DestroyMenu :: proc(hMenu: HMENU) -> BOOL ---
	AppendMenuW :: proc(hMenu: HMENU, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: LPCWSTR) -> BOOL ---
	SetMenu :: proc(hWnd: HWND, hMenu: HMENU) -> BOOL ---
	TrackPopupMenu :: proc(hMenu: HMENU, uFlags: UINT, x: int, y: int, nReserved: int, hWnd: HWND, prcRect: ^RECT) -> i32 ---
	RegisterWindowMessageW :: proc(lpString: LPCWSTR) -> UINT ---

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

	GetKeyboardState :: proc(lpKeyState: PBYTE) -> BOOL ---

	MapVirtualKeyW :: proc(uCode: UINT, uMapType: UINT) -> UINT ---
	ToUnicode :: proc(nVirtKey: UINT, wScanCode: UINT, lpKeyState: ^BYTE, pwszBuff: LPWSTR, cchBuff: c_int, wFlags: UINT) -> c_int ---

	SetWindowsHookExW :: proc(idHook: c_int, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD) -> HHOOK ---
	UnhookWindowsHookEx :: proc(hhk: HHOOK) -> BOOL ---
	CallNextHookEx :: proc(hhk: HHOOK, nCode: c_int, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	SetTimer :: proc(hWnd: HWND, nIDEvent: UINT_PTR, uElapse: UINT, lpTimerFunc: TIMERPROC) -> UINT_PTR ---
	KillTimer :: proc(hWnd: HWND, uIDEvent: UINT_PTR) -> BOOL ---

	// MessageBoxA :: proc(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) -> c_int ---
	MessageBoxW :: proc(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT) -> c_int ---
	// MessageBoxExA :: proc(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT, wLanguageId: WORD) -> c_int ---
	MessageBoxExW :: proc(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT, wLanguageId: WORD) -> c_int ---

	ClipCursor :: proc(lpRect: LPRECT) -> BOOL ---
	GetCursorPos :: proc(lpPoint: LPPOINT) -> BOOL ---
	SetCursorPos :: proc(X: c_int, Y: c_int) -> BOOL ---
	SetCursor :: proc(hCursor: HCURSOR) -> HCURSOR ---
	when !intrinsics.is_package_imported("raylib") {
		ShowCursor :: proc(bShow: BOOL) -> INT ---
	}

	EnumDisplaySettingsW :: proc(lpszDeviceName: LPCWSTR, iModeNum: DWORD, lpDevMode: ^DEVMODEW) -> BOOL ---

	MonitorFromPoint  :: proc(pt: POINT, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	MonitorFromRect   :: proc(lprc: LPRECT, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	MonitorFromWindow :: proc(hwnd: HWND, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	EnumDisplayMonitors :: proc(hdc: HDC, lprcClip: LPRECT, lpfnEnum: Monitor_Enum_Proc, dwData: LPARAM) -> BOOL ---

	EnumWindows :: proc(lpEnumFunc: Window_Enum_Proc, lParam: LPARAM) -> BOOL ---

	SetThreadDpiAwarenessContext :: proc(dpiContext: DPI_AWARENESS_CONTEXT) -> DPI_AWARENESS_CONTEXT ---
	GetThreadDpiAwarenessContext :: proc() -> DPI_AWARENESS_CONTEXT ---
	GetWindowDpiAwarenessContext :: proc(hwnd: HWND) -> DPI_AWARENESS_CONTEXT ---
	GetDpiFromDpiAwarenessContext :: proc(value: DPI_AWARENESS_CONTEXT) -> UINT ---
	GetDpiForWindow :: proc(hwnd: HWND) -> UINT ---
	SetProcessDpiAwarenessContext :: proc(value: DPI_AWARENESS_CONTEXT) -> BOOL ---

	BroadcastSystemMessageW :: proc(
		flags: DWORD,
		lpInfo: LPDWORD,
		Msg: UINT,
		wParam: WPARAM,
		lParam: LPARAM,
	) -> c_long ---

	BroadcastSystemMessageExW :: proc(
		flags: DWORD,
		lpInfo: LPDWORD,
		Msg: UINT,
		wParam: WPARAM,
		lParam: LPARAM,
		pbsmInfo: PBSMINFO,
	) -> c_long ---

	SendMessageTimeoutW :: proc(
		hWnd: HWND,
		Msg: UINT,
		wParam: WPARAM,
		lParam: LPARAM,
		fuFlags: UINT,
		uTimeout: UINT,
		lpdwResult: PDWORD_PTR,
	) -> LRESULT ---

	GetSysColor :: proc(nIndex: c_int) -> DWORD ---
	GetSysColorBrush :: proc(nIndex: c_int) -> HBRUSH ---
	SetSysColors :: proc(cElements: c_int, lpaElements: ^INT, lpaRgbValues: ^COLORREF) -> BOOL ---
	MessageBeep :: proc(uType: UINT) -> BOOL ---

	IsDialogMessageW :: proc(hDlg: HWND, lpMsg: LPMSG) -> BOOL ---
	GetWindowTextLengthW :: proc(hWnd: HWND) -> c_int ---
	GetWindowTextW :: proc(hWnd: HWND, lpString: LPWSTR, nMaxCount: c_int) -> c_int ---
	SetWindowTextW :: proc(hWnd: HWND, lpString: LPCWSTR) -> BOOL ---
	CallWindowProcW :: proc(lpPrevWndFunc: WNDPROC, hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	EnableWindow :: proc(hWnd: HWND, bEnable: BOOL) -> BOOL ---

	DefRawInputProc :: proc(paRawInput: ^PRAWINPUT, nInput: INT, cbSizeHeader: UINT) -> LRESULT ---
	GetRawInputBuffer :: proc(pRawInput: PRAWINPUT, pcbSize: PUINT, cbSizeHeader: UINT) -> UINT ---
	GetRawInputData :: proc(hRawInput: HRAWINPUT, uiCommand: UINT, pData: LPVOID, pcbSize: PUINT, cbSizeHeader: UINT) -> UINT ---
	GetRawInputDeviceInfoW :: proc(hDevice: HANDLE, uiCommand: UINT, pData: LPVOID, pcbSize: PUINT) -> UINT ---
	GetRawInputDeviceList :: proc(pRawInputDeviceList: PRAWINPUTDEVICELIST, puiNumDevices: PUINT, cbSize: UINT) -> UINT ---
	GetRegisteredRawInputDevices :: proc(pRawInputDevices: PRAWINPUTDEVICE, puiNumDevices: PUINT, cbSize: UINT) -> UINT ---
	RegisterRawInputDevices :: proc(pRawInputDevices: PCRAWINPUTDEVICE, uiNumDevices: UINT, cbSize: UINT) -> BOOL ---

	SendInput :: proc(cInputs: UINT, pInputs: [^]INPUT, cbSize: c_int) -> UINT ---

	SetLayeredWindowAttributes  :: proc(hWnd: HWND, crKey: COLORREF, bAlpha: BYTE, dwFlags: DWORD) -> BOOL ---

	FillRect :: proc(hDC: HDC, lprc: ^RECT, hbr: HBRUSH) -> int ---
	EqualRect :: proc(lprc1: ^RECT, lprc2: ^RECT) -> BOOL ---

	GetWindowInfo :: proc(hwnd: HWND, pwi: PWINDOWINFO) -> BOOL ---
	GetWindowPlacement :: proc(hWnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	SetWindowPlacement :: proc(hwnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	SetWindowRgn :: proc(hWnd: HWND, hRgn: HRGN, bRedraw: BOOL) -> int ---
	CreateRectRgnIndirect :: proc(lprect: ^RECT) -> HRGN ---
	GetSystemMetricsForDpi :: proc(nIndex: int, dpi: UINT) -> int ---

	GetSystemMenu :: proc(hWnd: HWND, bRevert: BOOL) -> HMENU ---
	EnableMenuItem :: proc(hMenu: HMENU, uIDEnableItem: UINT, uEnable: UINT) -> BOOL ---

	DrawTextW :: proc(hdc: HDC, lpchText: LPCWSTR, cchText: INT, lprc: LPRECT, format: DrawTextFormat) -> INT ---
	DrawTextExW :: proc(hdc: HDC, lpchText: LPCWSTR, cchText: INT, lprc: LPRECT, format: DrawTextFormat, lpdtp: PDRAWTEXTPARAMS) -> INT ---
}

CreateWindowW :: #force_inline proc "system" (
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
	@(default_calling_convention="system")
	foreign user32 {
		GetClassLongPtrW :: proc(hWnd: HWND, nIndex: c_int) -> ULONG_PTR ---
		SetClassLongPtrW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> ULONG_PTR ---

		GetWindowLongPtrW :: proc(hWnd: HWND, nIndex: c_int) -> LONG_PTR ---
		SetWindowLongPtrW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG_PTR) -> LONG_PTR ---
	}
} else when ODIN_ARCH == .i386 {
	GetClassLongPtrW :: GetClassLongW
	SetClassLongPtrW :: SetClassLongW

	GetWindowLongPtrW :: GetWindowLongW
	SetWindowLongPtrW :: SetWindowLongW
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

GET_XBUTTON_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> WORD {
	return HIWORD(cast(DWORD)wParam)
}

MAKEINTRESOURCEW :: #force_inline proc "contextless" (#any_int i: int) -> LPWSTR {
	return cast(LPWSTR)uintptr(WORD(i))
}

Monitor_From_Flags :: enum DWORD {
	MONITOR_DEFAULTTONULL    = 0x00000000, // Returns NULL
	MONITOR_DEFAULTTOPRIMARY = 0x00000001, // Returns a handle to the primary display monitor
	MONITOR_DEFAULTTONEAREST = 0x00000002, // Returns a handle to the display monitor that is nearest to the window
}

Monitor_Enum_Proc :: #type proc "system" (HMONITOR, HDC, LPRECT, LPARAM) -> BOOL
Window_Enum_Proc :: #type proc "system" (HWND, LPARAM) -> BOOL

USER_DEFAULT_SCREEN_DPI                    :: 96
DPI_AWARENESS_CONTEXT                      :: distinct HANDLE
DPI_AWARENESS_CONTEXT_UNAWARE              :: DPI_AWARENESS_CONTEXT(~uintptr(0)) // -1
DPI_AWARENESS_CONTEXT_SYSTEM_AWARE         :: DPI_AWARENESS_CONTEXT(~uintptr(1)) // -2
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    :: DPI_AWARENESS_CONTEXT(~uintptr(2)) // -3
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 :: DPI_AWARENESS_CONTEXT(~uintptr(3)) // -4
DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED    :: DPI_AWARENESS_CONTEXT(~uintptr(4)) // -5

RAWINPUTHEADER :: struct {
	dwType: DWORD,
	dwSize: DWORD,
	hDevice: HANDLE,
	wParam: WPARAM,
}

RAWHID :: struct {
	dwSizeHid: DWORD,
	dwCount: DWORD,
	bRawData: [1]BYTE,
}

RAWMOUSE :: struct {
	usFlags: USHORT,
	using DUMMYUNIONNAME: struct #raw_union {
		ulButtons: ULONG,
		using DUMMYSTRUCTNAME: struct {
			usButtonFlags: USHORT,
			usButtonData: USHORT,
		},
	},
	ulRawButtons: ULONG,
	lLastX: LONG,
	lLastY: LONG,
	ulExtraInformation: ULONG,
}

RAWKEYBOARD :: struct {
	MakeCode: USHORT,
	Flags: USHORT,
	Rserved: USHORT,
	VKey: USHORT,
	Message: UINT,
	ExtraInformation: ULONG,
}

RAWINPUT :: struct {
	header: RAWINPUTHEADER,
	data: struct #raw_union {
		mouse: RAWMOUSE,
		keyboard: RAWKEYBOARD,
		hid: RAWHID,
	},
}

PRAWINPUT :: ^RAWINPUT
HRAWINPUT :: distinct LPARAM

RAWINPUTDEVICE :: struct {
	usUsagePage: USHORT,
	usUsage: USHORT,
	dwFlags: DWORD,
	hwndTarget: HWND,
}

PRAWINPUTDEVICE :: ^RAWINPUTDEVICE
PCRAWINPUTDEVICE :: PRAWINPUTDEVICE

RAWINPUTDEVICELIST :: struct {
	hDevice: HANDLE,
	dwType: DWORD,
}

PRAWINPUTDEVICELIST :: ^RAWINPUTDEVICELIST

RID_DEVICE_INFO_HID :: struct {
	dwVendorId: DWORD,
	dwProductId: DWORD,
	dwVersionNumber: DWORD,
	usUsagePage: USHORT,
	usUsage: USHORT,
}

RID_DEVICE_INFO_KEYBOARD :: struct {
	dwType: DWORD,
	dwSubType: DWORD,
	dwKeyboardMode: DWORD,
	dwNumberOfFunctionKeys: DWORD,
	dwNumberOfIndicators: DWORD,
	dwNumberOfKeysTotal: DWORD,
}

RID_DEVICE_INFO_MOUSE :: struct {
	dwId: DWORD,
	dwNumberOfButtons: DWORD,
	dwSampleRate: DWORD,
	fHasHorizontalWheel: BOOL,
}

RID_DEVICE_INFO :: struct {
	cbSize: DWORD,
	dwType: DWORD,
	using DUMMYUNIONNAME: struct #raw_union {
		mouse: RID_DEVICE_INFO_MOUSE,
		keyboard: RID_DEVICE_INFO_KEYBOARD,
		hid: RID_DEVICE_INFO_HID,
	},
}

RIDEV_REMOVE :: 0x00000001
RIDEV_EXCLUDE :: 0x00000010
RIDEV_PAGEONLY :: 0x00000020
RIDEV_NOLEGACY :: 0x00000030
RIDEV_INPUTSINK :: 0x00000100
RIDEV_CAPTUREMOUSE :: 0x00000200
RIDEV_NOHOTKEYS :: 0x00000200
RIDEV_APPKEYS :: 0x00000400
RIDEV_EXINPUTSINK :: 0x00001000
RIDEV_DEVNOTIFY :: 0x00002000

RID_HEADER :: 0x10000005
RID_INPUT :: 0x10000003

RIDI_PREPARSEDDATA :: 0x20000005
RIDI_DEVICENAME :: 0x20000007
RIDI_DEVICEINFO :: 0x2000000b

RIM_TYPEMOUSE :: 0
RIM_TYPEKEYBOARD :: 1
RIM_TYPEHID :: 2

RI_KEY_MAKE :: 0
RI_KEY_BREAK :: 1
RI_KEY_E0 :: 2
RI_KEY_E1 :: 4
RI_KEY_TERMSRV_SET_LED :: 8
RI_KEY_TERMSRV_SHADOW :: 0x10

MOUSE_MOVE_RELATIVE :: 0x00
MOUSE_MOVE_ABSOLUTE :: 0x01
MOUSE_VIRTUAL_DESKTOP :: 0x02
MOUSE_ATTRIUBTTES_CHANGED :: 0x04
MOUSE_MOVE_NOCOALESCE :: 0x08

RI_MOUSE_BUTTON_1_DOWN :: 0x0001
RI_MOUSE_LEFT_BUTTON_DOWNS :: RI_MOUSE_BUTTON_1_DOWN
RI_MOUSE_BUTTON_1_UP :: 0x0002
RI_MOUSE_LEFT_BUTTON_UP :: RI_MOUSE_BUTTON_1_UP
RI_MOUSE_BUTTON_2_DOWN :: 0x0004
RI_MOUSE_RIGHT_BUTTON_DOWN :: RI_MOUSE_BUTTON_2_DOWN
RI_MOUSE_BUTTON_2_UP :: 0x0008
RI_MOUSE_RIGHT_BUTTON_UP :: RI_MOUSE_BUTTON_2_UP
RI_MOUSE_BUTTON_3_DOWN :: 0x0010
RI_MOUSE_MIDDLE_BUTTON_DOWN :: RI_MOUSE_BUTTON_3_DOWN
RI_MOUSE_BUTTON_3_UP :: 0x0020
RI_MOUSE_MIDDLE_BUTTON_UP :: RI_MOUSE_BUTTON_3_UP
RI_MOUSE_BUTTON_4_DOWN :: 0x0040
RI_MOUSE_BUTTON_4_UP :: 0x0080
RI_MOUSE_BUTTON_5_DOWN :: 0x0100
RI_MOUSE_BUTTON_5_UP :: 0x0200
RI_MOUSE_WHEEL :: 0x0400
RI_MOUSE_HWHEEL :: 0x0800

WINDOWPLACEMENT :: struct {
	length: UINT,
	flags: UINT,
	showCmd: UINT,
	ptMinPosition: POINT,
  	ptMaxPosition: POINT,
  	rcNormalPosition: RECT,
}

WINDOWINFO :: struct {
	cbSize: DWORD,
	rcWindow: RECT,
	rcClient: RECT,
	dwStyle: DWORD,
	dwExStyle: DWORD,
	dwWindowStatus: DWORD,
	cxWindowBorders: UINT,
	cyWindowBorders: UINT,
	atomWindowType: ATOM,
	wCreatorVersion: WORD,
}
PWINDOWINFO :: ^WINDOWINFO

DRAWTEXTPARAMS :: struct {
	cbSize: UINT,
	iTabLength: int,
	iLeftMargin: int,
	iRightMargin: int,
	uiLengthDrawn: UINT,
}
PDRAWTEXTPARAMS :: ^DRAWTEXTPARAMS

DrawTextFormat :: enum UINT {
	DT_TOP                  = 0x00000000,
	DT_LEFT                 = 0x00000000,
	DT_CENTER               = 0x00000001,
	DT_RIGHT                = 0x00000002,
	DT_VCENTER              = 0x00000004,
	DT_BOTTOM               = 0x00000008,
	DT_WORDBREAK            = 0x00000010,
	DT_SINGLELINE           = 0x00000020,
	DT_EXPANDTABS           = 0x00000040,
	DT_TABSTOP              = 0x00000080,
	DT_NOCLIP               = 0x00000100,
	DT_EXTERNALLEADING      = 0x00000200,
	DT_CALCRECT             = 0x00000400,
	DT_NOPREFIX             = 0x00000800,
	DT_INTERNAL             = 0x00001000,
	DT_EDITCONTROL          = 0x00002000,
	DT_PATH_ELLIPSIS        = 0x00004000,
	DT_END_ELLIPSIS         = 0x00008000,
	DT_MODIFYSTRING         = 0x00010000,
	DT_RTLREADING           = 0x00020000,
	DT_WORD_ELLIPSIS        = 0x00040000,
	DT_NOFULLWIDTHCHARBREAK = 0x00080000,
	DT_HIDEPREFIX           = 0x00100000,
	DT_PREFIXONLY           = 0x00200000,
}

RedrawWindowFlags :: enum UINT {
	RDW_INVALIDATE      = 0x0001,
	RDW_INTERNALPAINT   = 0x0002,
	RDW_ERASE           = 0x0004,
	RDW_VALIDATE        = 0x0008,
	RDW_NOINTERNALPAINT = 0x0010,
	RDW_NOERASE         = 0x0020,
	RDW_NOCHILDREN      = 0x0040,
	RDW_ALLCHILDREN     = 0x0080,
	RDW_UPDATENOW       = 0x0100,
	RDW_ERASENOW        = 0x0200,
	RDW_FRAME           = 0x0400,
	RDW_NOFRAME         = 0x0800,
}
