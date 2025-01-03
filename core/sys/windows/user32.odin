#+build windows
package sys_windows

import "base:intrinsics"
foreign import user32 "system:User32.lib"

@(default_calling_convention="system")
foreign user32 {
	GetClassInfoW :: proc(hInstance: HINSTANCE, lpClassName: LPCWSTR, lpWndClass: ^WNDCLASSW) -> BOOL ---
	GetClassInfoExW :: proc(hInstance: HINSTANCE, lpszClass: LPCWSTR, lpwcx: ^WNDCLASSEXW) -> BOOL ---

	GetClassLongW :: proc(hWnd: HWND, nIndex: INT) -> DWORD ---
	SetClassLongW :: proc(hWnd: HWND, nIndex: INT, dwNewLong: LONG) -> DWORD ---

	GetWindowLongW :: proc(hWnd: HWND, nIndex: INT) -> LONG ---
	SetWindowLongW :: proc(hWnd: HWND, nIndex: INT, dwNewLong: LONG) -> LONG ---

	GetClassNameW :: proc(hWnd: HWND, lpClassName: LPWSTR, nMaxCount: INT) -> INT ---

	GetParent :: proc(hWnd: HWND) -> HWND ---
	SetWinEventHook :: proc(
		eventMin, eventMax: DWORD,
		hmodWinEventProc: HMODULE,
		pfnWinEvenProc: WINEVENTPROC,
		idProcess, idThread: DWORD,
		dwFlags: WinEventFlags,
	) -> HWINEVENTHOOK ---

	IsChild :: proc(hWndParent, hWnd: HWND) -> BOOL ---

	RegisterClassW :: proc(lpWndClass: ^WNDCLASSW) -> ATOM ---
	RegisterClassExW :: proc(^WNDCLASSEXW) -> ATOM ---
	UnregisterClassW :: proc(lpClassName: LPCWSTR, hInstance: HINSTANCE) -> BOOL ---

	CreateWindowExW :: proc(
		dwExStyle: DWORD,
		lpClassName: LPCWSTR,
		lpWindowName: LPCWSTR,
		dwStyle: DWORD,
		X, Y, nWidth, nHeight: INT,
		hWndParent: HWND,
		hMenu: HMENU,
		hInstance: HINSTANCE,
		lpParam: LPVOID,
	) -> HWND ---

	DestroyWindow :: proc(hWnd: HWND) -> BOOL ---

	ShowWindow :: proc(hWnd: HWND, nCmdShow: INT) -> BOOL ---
	IsWindow :: proc(hWnd: HWND) -> BOOL ---
	IsWindowVisible :: proc(hwnd: HWND) -> BOOL ---
	IsWindowEnabled :: proc(hwnd: HWND) -> BOOL ---
	IsIconic :: proc(hwnd: HWND) -> BOOL ---
	IsZoomed :: proc(hwnd: HWND) -> BOOL ---
	BringWindowToTop :: proc(hWnd: HWND) -> BOOL ---
	GetTopWindow :: proc(hWnd: HWND) -> HWND ---
	SetForegroundWindow :: proc(hWnd: HWND) -> BOOL ---
	GetForegroundWindow :: proc() -> HWND ---
	GetDesktopWindow :: proc() -> HWND ---
	UpdateWindow :: proc(hWnd: HWND) -> BOOL ---
	SetActiveWindow :: proc(hWnd: HWND) -> HWND ---
	GetActiveWindow :: proc() -> HWND ---
	RedrawWindow :: proc(hwnd: HWND, lprcUpdate: LPRECT, hrgnUpdate: HRGN, flags: RedrawWindowFlags) -> BOOL ---
	SetParent :: proc(hWndChild: HWND, hWndNewParent: HWND) -> HWND ---
	SetPropW :: proc(hWnd: HWND, lpString: LPCWSTR, hData: HANDLE) -> BOOL ---
	GetPropW :: proc(hWnd: HWND, lpString: LPCWSTR) -> HANDLE ---
	RemovePropW :: proc(hWnd: HWND, lpString: LPCWSTR) -> HANDLE ---
	EnumPropsW :: proc(hWnd: HWND, lpEnumFunc: PROPENUMPROCW) -> INT ---
	EnumPropsExW :: proc(hWnd: HWND, lpEnumFunc: PROPENUMPROCW, lParam: LPARAM) -> INT ---
	GetMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) -> INT ---

	TranslateMessage :: proc(lpMsg: ^MSG) -> BOOL ---
	DispatchMessageW :: proc(lpMsg: ^MSG) -> LRESULT ---

	WaitMessage :: proc() -> BOOL ---
	MsgWaitForMultipleObjects :: proc(nCount: DWORD, pHandles: ^HANDLE, fWaitAll: BOOL, dwMilliseconds: DWORD, dwWakeMask: DWORD) -> DWORD ---

	PeekMessageA :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---
	PeekMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT, wRemoveMsg: UINT) -> BOOL ---

	PostMessageA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	PostMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	SendMessageA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	SendMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	PostThreadMessageA :: proc(idThread: DWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	PostThreadMessageW :: proc(idThread: DWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---

	PostQuitMessage :: proc(nExitCode: INT) ---

	GetQueueStatus :: proc(flags: UINT) -> DWORD ---

	DefWindowProcA :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	DefWindowProcW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	FindWindowA :: proc(lpClassName: LPCSTR, lpWindowName: LPCSTR) -> HWND ---
	FindWindowW :: proc(lpClassName: LPCWSTR, lpWindowName: LPCWSTR) -> HWND ---
	FindWindowExA :: proc(hWndParent: HWND, hWndChildAfter: HWND, lpszClass: LPCSTR, lpszWindow: LPCSTR) -> HWND ---
	FindWindowExW :: proc(hWndParent: HWND, hWndChildAfter: HWND, lpszClass: LPCWSTR, lpszWindow: LPCWSTR) -> HWND ---

	LoadIconA :: proc(hInstance: HINSTANCE, lpIconName: LPCSTR) -> HICON ---
	LoadIconW :: proc(hInstance: HINSTANCE, lpIconName: LPCWSTR) -> HICON ---
	GetIconInfoExW :: proc(hIcon: HICON, piconinfo: PICONINFOEXW) -> BOOL ---
	LoadCursorA :: proc(hInstance: HINSTANCE, lpCursorName: LPCSTR) -> HCURSOR ---
	LoadCursorW :: proc(hInstance: HINSTANCE, lpCursorName: LPCWSTR) -> HCURSOR ---
	LoadImageW :: proc(hInst: HINSTANCE, name: LPCWSTR, type: UINT, cx, cy: INT, fuLoad: UINT) -> HANDLE ---

	CreateIcon :: proc(hInstance: HINSTANCE, nWidth, nHeight: INT, cPlanes: BYTE, cBitsPixel: BYTE, lpbANDbits: PBYTE, lpbXORbits: PBYTE) -> HICON ---
	CreateIconFromResource :: proc(presbits: PBYTE, dwResSize: DWORD, fIcon: BOOL, dwVer: DWORD) -> HICON ---
	DestroyIcon :: proc(hIcon: HICON) -> BOOL ---
	DrawIcon :: proc(hDC: HDC, X, Y: INT, hIcon: HICON) -> BOOL ---

	CreateCursor :: proc(hInst: HINSTANCE, xHotSpot, yHotSpot, nWidth, nHeight: INT, pvANDPlane: PVOID, pvXORPlane: PVOID) -> HCURSOR ---
	DestroyCursor :: proc(hCursor: HCURSOR) -> BOOL ---

	GetWindowRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	GetClientRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	ClientToScreen :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	ScreenToClient :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	SetWindowPos :: proc(hWnd: HWND, hWndInsertAfter: HWND, X, Y, cx, cy: INT, uFlags: UINT) -> BOOL ---
	MoveWindow :: proc(hWnd: HWND, X, Y, hWidth, hHeight: INT, bRepaint: BOOL) -> BOOL ---
	GetSystemMetrics :: proc(nIndex: INT) -> INT ---
	AdjustWindowRect :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL) -> BOOL ---
	AdjustWindowRectEx :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) -> BOOL ---
	AdjustWindowRectExForDpi :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD, dpi: UINT) -> BOOL ---

	SystemParametersInfoW :: proc(uiAction, uiParam: UINT, pvParam: PVOID, fWinIni: UINT) -> BOOL ---
	GetMonitorInfoW :: proc(hMonitor: HMONITOR, lpmi: LPMONITORINFO) -> BOOL ---

	GetWindowDC :: proc(hWnd: HWND) -> HDC ---
	GetDC :: proc(hWnd: HWND) -> HDC ---
	GetDCEx :: proc(hWnd: HWND, hrgnClip: HRGN, flags: DWORD) -> HDC ---
	ReleaseDC :: proc(hWnd: HWND, hDC: HDC) -> INT ---

	GetDlgCtrlID :: proc(hWnd: HWND) -> INT ---
	GetDlgItem :: proc(hDlg: HWND, nIDDlgItem: INT) -> HWND ---

	CreateMenu :: proc() -> HMENU ---
	CreatePopupMenu :: proc() -> HMENU ---
	DeleteMenu :: proc(hMenu: HMENU, uPosition: UINT, uFlags: UINT) -> BOOL ---
	DestroyMenu :: proc(hMenu: HMENU) -> BOOL ---
	InsertMenuW :: proc(hMenu: HMENU, uPosition: UINT, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: LPCWSTR) -> BOOL ---
	AppendMenuW :: proc(hMenu: HMENU, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: LPCWSTR) -> BOOL ---
	GetMenu :: proc(hWnd: HWND) -> HMENU ---
	SetMenu :: proc(hWnd: HWND, hMenu: HMENU) -> BOOL ---
	TrackPopupMenu :: proc(hMenu: HMENU, uFlags: UINT, x, y: INT, nReserved: INT, hWnd: HWND, prcRect: ^RECT) -> INT ---
	RegisterWindowMessageW :: proc(lpString: LPCWSTR) -> UINT ---

	CreateAcceleratorTableW :: proc(paccel: LPACCEL, cAccel: INT) -> HACCEL ---
	DestroyAcceleratorTable :: proc(hAccel: HACCEL) -> BOOL ---
	LoadAcceleratorsW :: proc(hInstance: HINSTANCE, lpTableName: LPCWSTR) -> HACCEL ---
	TranslateAcceleratorW :: proc(hWnd: HWND, hAccTable: HACCEL, lpMsg: LPMSG) -> INT ---
	CopyAcceleratorTableW :: proc(hAccelSrc: HACCEL, lpAccelDst: LPACCEL, cAccelEntries: INT) -> INT ---

	InsertMenuItemW :: proc(hmenu: HMENU, item: UINT, fByPosition: BOOL, lpmi: LPMENUITEMINFOW) -> BOOL ---
	GetMenuItemInfoW :: proc(hmenu: HMENU, item: UINT, fByPosition: BOOL, lpmii: LPMENUITEMINFOW) -> BOOL ---
	SetMenuItemInfoW :: proc(hmenu: HMENU, item: UINT, fByPositon: BOOL, lpmii: LPMENUITEMINFOW) -> BOOL ---
	GetMenuDefaultItem :: proc(hMenu: HMENU, fByPos: UINT, gmdiFlags: UINT) -> UINT ---
	SetMenuDefaultItem :: proc(hMenu: HMENU, uItem: UINT, fByPos: UINT) -> BOOL ---
	GetMenuItemRect :: proc(hWnd: HWND, hMenu: HMENU, uItem: UINT, lprcItem: LPRECT) -> c_int ---

	GetUpdateRect :: proc(hWnd: HWND, lpRect: LPRECT, bErase: BOOL) -> BOOL ---
	ValidateRect :: proc(hWnd: HWND, lpRect: ^RECT) -> BOOL ---
	InvalidateRect :: proc(hWnd: HWND, lpRect: ^RECT, bErase: BOOL) -> BOOL ---

	BeginPaint :: proc(hWnd: HWND, lpPaint: ^PAINTSTRUCT) -> HDC ---
	EndPaint :: proc(hWnd: HWND, lpPaint: ^PAINTSTRUCT) -> BOOL ---

	GetCapture :: proc() -> HWND ---
	SetCapture :: proc(hWnd: HWND) -> HWND ---
	ReleaseCapture :: proc() -> BOOL ---
	TrackMouseEvent :: proc(lpEventTrack: LPTRACKMOUSEEVENT) -> BOOL ---

	GetKeyState :: proc(nVirtKey: INT) -> SHORT ---
	GetAsyncKeyState :: proc(vKey: INT) -> SHORT ---

	GetKeyboardState :: proc(lpKeyState: PBYTE) -> BOOL ---

	MapVirtualKeyW :: proc(uCode: UINT, uMapType: UINT) -> UINT ---
	ToUnicode :: proc(nVirtKey: UINT, wScanCode: UINT, lpKeyState: ^BYTE, pwszBuff: LPWSTR, cchBuff: INT, wFlags: UINT) -> INT ---

	SetWindowsHookExW :: proc(idHook: INT, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD) -> HHOOK ---
	UnhookWindowsHookEx :: proc(hhk: HHOOK) -> BOOL ---
	CallNextHookEx :: proc(hhk: HHOOK, nCode: INT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---

	SetTimer :: proc(hWnd: HWND, nIDEvent: UINT_PTR, uElapse: UINT, lpTimerFunc: TIMERPROC) -> UINT_PTR ---
	KillTimer :: proc(hWnd: HWND, uIDEvent: UINT_PTR) -> BOOL ---

	// MessageBoxA :: proc(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT) -> INT ---
	MessageBoxW :: proc(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT) -> INT ---
	// MessageBoxExA :: proc(hWnd: HWND, lpText: LPCSTR, lpCaption: LPCSTR, uType: UINT, wLanguageId: WORD) -> INT ---
	MessageBoxExW :: proc(hWnd: HWND, lpText: LPCWSTR, lpCaption: LPCWSTR, uType: UINT, wLanguageId: WORD) -> INT ---

	ClipCursor :: proc(lpRect: LPRECT) -> BOOL ---
	GetCursorPos :: proc(lpPoint: LPPOINT) -> BOOL ---
	SetCursorPos :: proc(X, Y: INT) -> BOOL ---
	SetCursor :: proc(hCursor: HCURSOR) -> HCURSOR ---
	when !intrinsics.is_package_imported("raylib") {
		ShowCursor :: proc(bShow: BOOL) -> INT ---
	}

	EnumDisplayDevicesW :: proc (lpDevice: LPCWSTR, iDevNum: DWORD, lpDisplayDevice: PDISPLAY_DEVICEW, dwFlags: DWORD) -> BOOL ---
	EnumDisplaySettingsW :: proc(lpszDeviceName: LPCWSTR, iModeNum: DWORD, lpDevMode: ^DEVMODEW) -> BOOL ---

	MonitorFromPoint  :: proc(pt: POINT, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	MonitorFromRect   :: proc(lprc: LPRECT, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	MonitorFromWindow :: proc(hwnd: HWND, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	EnumDisplayMonitors :: proc(hdc: HDC, lprcClip: LPRECT, lpfnEnum: Monitor_Enum_Proc, dwData: LPARAM) -> BOOL ---

	EnumWindows :: proc(lpEnumFunc: Window_Enum_Proc, lParam: LPARAM) -> BOOL ---

	IsProcessDPIAware :: proc() -> BOOL ---
	SetProcessDPIAware :: proc() -> BOOL ---

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

	GetSysColor :: proc(nIndex: INT) -> DWORD ---
	GetSysColorBrush :: proc(nIndex: INT) -> HBRUSH ---
	SetSysColors :: proc(cElements: INT, lpaElements: ^INT, lpaRgbValues: ^COLORREF) -> BOOL ---
	MessageBeep :: proc(uType: UINT) -> BOOL ---

	IsDialogMessageW :: proc(hDlg: HWND, lpMsg: LPMSG) -> BOOL ---
	GetWindowTextLengthW :: proc(hWnd: HWND) -> INT ---
	GetWindowTextW :: proc(hWnd: HWND, lpString: LPWSTR, nMaxCount: INT) -> INT ---
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

	SendInput :: proc(cInputs: UINT, pInputs: [^]INPUT, cbSize: INT) -> UINT ---

	SetLayeredWindowAttributes  :: proc(hWnd: HWND, crKey: COLORREF, bAlpha: BYTE, dwFlags: DWORD) -> BOOL ---

	FillRect :: proc(hDC: HDC, lprc: ^RECT, hbr: HBRUSH) -> int ---
	EqualRect :: proc(lprc1, lprc2: ^RECT) -> BOOL ---
	OffsetRect :: proc(lprc1: ^RECT, dx, dy: INT) -> BOOL ---
	InflateRect :: proc(lprc1: ^RECT, dx, dy: INT) -> BOOL ---
	IntersectRect :: proc(lprcDst, lprcSrc1, lprcSrc2: ^RECT) -> BOOL ---
	SubtractRect :: proc(lprcDst, lprcSrc1, lprcSrc2: ^RECT) -> BOOL ---
	UnionRect :: proc(lprcDst, lprcSrc1, lprcSrc2: ^RECT) -> BOOL ---
	IsRectEmpty :: proc(lprc: ^RECT) -> BOOL ---
	SetRectEmpty :: proc(lprc: ^RECT) -> BOOL ---
	CopyRect :: proc(lprcDst, lprcSrc: ^RECT) -> BOOL ---

	GetWindowInfo :: proc(hwnd: HWND, pwi: PWINDOWINFO) -> BOOL ---
	GetWindowPlacement :: proc(hWnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	SetWindowPlacement :: proc(hwnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	SetWindowRgn :: proc(hWnd: HWND, hRgn: HRGN, bRedraw: BOOL) -> int ---
	CreateRectRgnIndirect :: proc(lprect: ^RECT) -> HRGN ---
	GetSystemMetricsForDpi :: proc(nIndex: int, dpi: UINT) -> int ---

	GetCursorInfo :: proc(pci: PCURSORINFO) -> BOOL ---

	GetSystemMenu :: proc(hWnd: HWND, bRevert: BOOL) -> HMENU ---
	EnableMenuItem :: proc(hMenu: HMENU, uIDEnableItem: UINT, uEnable: UINT) -> BOOL ---
	MenuItemFromPoint :: proc(hWnd: HWND, hMenu: HMENU, ptScreen: POINT) -> INT ---

	DrawTextW :: proc(hdc: HDC, lpchText: LPCWSTR, cchText: INT, lprc: LPRECT, format: DrawTextFormat) -> INT ---
	DrawTextExW :: proc(hdc: HDC, lpchText: LPCWSTR, cchText: INT, lprc: LPRECT, format: DrawTextFormat, lpdtp: PDRAWTEXTPARAMS) -> INT ---

	GetLocaleInfoEx :: proc(lpLocaleName: LPCWSTR, LCType: LCTYPE, lpLCData: LPWSTR, cchData: INT) -> INT ---
	IsValidLocaleName :: proc(lpLocaleName: LPCWSTR) -> BOOL ---
	ResolveLocaleName :: proc(lpNameToResolve: LPCWSTR, lpLocaleName: LPWSTR, cchLocaleName: INT) -> INT ---
	IsValidCodePage :: proc(CodePage: UINT) -> BOOL ---
	GetACP :: proc() -> CODEPAGE ---
	GetCPInfoExW :: proc(CodePage: CODEPAGE, dwFlags: DWORD, lpCPInfoEx: LPCPINFOEXW) -> BOOL ---

	GetProcessWindowStation :: proc() -> HWINSTA ---
	GetUserObjectInformationW :: proc(hObj: HANDLE, nIndex: GetUserObjectInformationFlags, pvInfo: PVOID, nLength: DWORD, lpnLengthNeeded: LPDWORD) -> BOOL ---
	
	OpenClipboard :: proc(hWndNewOwner: HWND) -> BOOL ---
	CloseClipboard :: proc() -> BOOL ---
	GetClipboardData :: proc(uFormat: UINT) -> HANDLE ---
	SetClipboardData :: proc(uFormat: UINT, hMem: HANDLE) -> HANDLE ---
	IsClipboardFormatAvailable :: proc(format: UINT) -> BOOL ---
	EmptyClipboard :: proc() -> BOOL ---
}

CreateWindowW :: #force_inline proc "system" (
	lpClassName: LPCTSTR,
	lpWindowName: LPCTSTR,
	dwStyle: DWORD,
	X: INT,
	Y: INT,
	nWidth: INT,
	nHeight: INT,
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
		GetClassLongPtrW :: proc(hWnd: HWND, nIndex: INT) -> ULONG_PTR ---
		SetClassLongPtrW :: proc(hWnd: HWND, nIndex: INT, dwNewLong: LONG_PTR) -> ULONG_PTR ---

		GetWindowLongPtrW :: proc(hWnd: HWND, nIndex: INT) -> LONG_PTR ---
		SetWindowLongPtrW :: proc(hWnd: HWND, nIndex: INT, dwNewLong: LONG_PTR) -> LONG_PTR ---
	}
} else when ODIN_ARCH == .i386 {
	GetClassLongPtrW :: GetClassLongW
	SetClassLongPtrW :: SetClassLongW

	GetWindowLongPtrW :: GetWindowLongW
	SetWindowLongPtrW :: SetWindowLongW
}

GET_SC_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> INT {
	return INT(wParam) & 0xFFF0
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

// Retrieves the input code from wParam in WM_INPUT message.
GET_RAWINPUT_CODE_WPARAM :: #force_inline proc "contextless" (wParam: WPARAM) -> RAWINPUT_CODE {
	return RAWINPUT_CODE(wParam & 0xFF)
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

RAWINPUT_CODE :: enum {
	// The input is in the regular message flow,
	// the app is required to call DefWindowProc
	// so that the system can perform clean ups.
	RIM_INPUT       = 0,
	// The input is sink only. The app is expected
	// to behave nicely.
	RIM_INPUTSINK   = 1,
}

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
MOUSE_ATTRIBUTES_CHANGED :: 0x04
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

CURSORINFO :: struct {
	cbSize: DWORD,
	flags: DWORD,
	hCursor: HCURSOR,
	ptScreenPos: POINT,
}
PCURSORINFO :: ^CURSORINFO


DRAWTEXTPARAMS :: struct {
	cbSize: UINT,
	iTabLength: INT,
	iLeftMargin: INT,
	iRightMargin: INT,
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

GetUserObjectInformationFlags :: enum INT {
	UOI_FLAGS      = 1,
	UOI_NAME       = 2,
	UOI_TYPE       = 3,
	UOI_USER_SID   = 4,
	UOI_HEAPSIZE   = 5,
	UOI_IO         = 6,
	UOI_TIMERPROC_EXCEPTION_SUPPRESSION = 7,
}

USEROBJECTFLAGS :: struct  {
	fInherit: BOOL,
	fReserved: BOOL,
	dwFlags: DWORD,
}

PROPENUMPROCW :: #type proc(unnamedParam1: HWND, unnamedParam2: LPCWSTR, unnamedParam3: HANDLE) -> BOOL
PROPENUMPROCEXW :: #type proc(unnamedParam1: HWND, unnamedParam2: LPCWSTR, unnamedParam3: HANDLE, unnamedParam4: ULONG_PTR) -> BOOL

RT_CURSOR       :: LPWSTR(uintptr(0x00000001))
RT_BITMAP       :: LPWSTR(uintptr(0x00000002))
RT_ICON         :: LPWSTR(uintptr(0x00000003))
RT_MENU         :: LPWSTR(uintptr(0x00000004))
RT_DIALOG       :: LPWSTR(uintptr(0x00000005))
RT_STRING       :: LPWSTR(uintptr(0x00000006))
RT_FONTDIR      :: LPWSTR(uintptr(0x00000007))
RT_FONT         :: LPWSTR(uintptr(0x00000008))
RT_ACCELERATOR  :: LPWSTR(uintptr(0x00000009))
RT_RCDATA       :: LPWSTR(uintptr(0x0000000A))
RT_MESSAGETABLE :: LPWSTR(uintptr(0x0000000B))
RT_GROUP_CURSOR :: LPWSTR(uintptr(0x0000000C))
RT_GROUP_ICON   :: LPWSTR(uintptr(0x0000000E))
RT_VERSION      :: LPWSTR(uintptr(0x00000010))
RT_DLGINCLUDE   :: LPWSTR(uintptr(0x00000011))
RT_PLUGPLAY     :: LPWSTR(uintptr(0x00000013))
RT_VXD          :: LPWSTR(uintptr(0x00000014))
RT_ANICURSOR    :: LPWSTR(uintptr(0x00000015))
RT_ANIICON      :: LPWSTR(uintptr(0x00000016))
RT_MANIFEST     :: LPWSTR(uintptr(0x00000018))

CREATEPROCESS_MANIFEST_RESOURCE_ID                 :: LPWSTR(uintptr(0x00000001))
ISOLATIONAWARE_MANIFEST_RESOURCE_ID                :: LPWSTR(uintptr(0x00000002))
ISOLATIONAWARE_NOSTATICIMPORT_MANIFEST_RESOURCE_ID :: LPWSTR(uintptr(0x00000003))
ISOLATIONPOLICY_MANIFEST_RESOURCE_ID               :: LPWSTR(uintptr(0x00000004))
ISOLATIONPOLICY_BROWSER_MANIFEST_RESOURCE_ID       :: LPWSTR(uintptr(0x00000005))
MINIMUM_RESERVED_MANIFEST_RESOURCE_ID              :: LPWSTR(uintptr(0x00000001))
MAXIMUM_RESERVED_MANIFEST_RESOURCE_ID              :: LPWSTR(uintptr(0x00000010))

ACCEL :: struct {
	/* Also called the flags field */
	fVirt: BYTE,
	key: WORD,
	cmd: WORD,
}
LPACCEL :: ^ACCEL

MIIM_STATE      :: 0x00000001
MIIM_ID         :: 0x00000002
MIIM_SUBMENU    :: 0x00000004
MIIM_CHECKMARKS :: 0x00000008
MIIM_TYPE       :: 0x00000010
MIIM_DATA       :: 0x00000020

MIIM_STRING :: 0x00000040
MIIM_BITMAP :: 0x00000080
MIIM_FTYPE  :: 0x00000100

MENUITEMINFOW :: struct {
	cbSize: UINT,
	fMask: UINT,
	fType: UINT,         // used if MIIM_TYPE (4.0) or MIIM_FTYPE (>4.0)
	fState: UINT,        // used if MIIM_STATE
	wID: UINT,           // used if MIIM_ID
	hSubMenu: HMENU,      // used if MIIM_SUBMENU
	hbmpChecked: HBITMAP,   // used if MIIM_CHECKMARKS
	hbmpUnchecked: HBITMAP, // used if MIIM_CHECKMARKS
	dwItemData: ULONG_PTR,   // used if MIIM_DATA
	dwTypeData: LPWSTR,    // used if MIIM_TYPE (4.0) or MIIM_STRING (>4.0)
	cch: UINT,           // used if MIIM_TYPE (4.0) or MIIM_STRING (>4.0)
	hbmpItem: HBITMAP,      // used if MIIM_BITMAP
}
LPMENUITEMINFOW :: ^MENUITEMINFOW
DISPLAY_DEVICEW :: struct {
	cb: DWORD,
	DeviceName: [32]WCHAR,
	DeviceString: [128]WCHAR,
	StateFlags: DWORD,
	DeviceID: [128]WCHAR,
	DeviceKey: [128]WCHAR,
}
PDISPLAY_DEVICEW :: ^DISPLAY_DEVICEW

// OUTOFCONTEXT is the zero value, use {}
WinEventFlags :: bit_set[WinEventFlag; DWORD]

WinEventFlag :: enum DWORD {
	SKIPOWNTHREAD  = 0,
	SKIPOWNPROCESS = 1,
	INCONTEXT      = 2,
}

// Standard Clipboard Formats
CF_TEXT            :: 1
CF_BITMAP          :: 2
CF_METAFILEPICT    :: 3
CF_SYLK            :: 4
CF_DIF             :: 5
CF_TIFF            :: 6
CF_OEMTEXT         :: 7
CF_DIB             :: 8
CF_PALETTE         :: 9
CF_PENDATA         :: 10
CF_RIFF            :: 11
CF_WAVE            :: 12
CF_UNICODETEXT     :: 13
CF_ENHMETAFILE     :: 14
CF_HDROP           :: 15
CF_LOCALE          :: 16
CF_DIBV5           :: 17
CF_DSPBITMAP       :: 0x0082
CF_DSPENHMETAFILE  :: 0x008E
CF_DSPMETAFILEPICT :: 0x0083
CF_DSPTEXT         :: 0x0081
CF_GDIOBJFIRST     :: 0x0300
CF_GDIOBJLAST      :: 0x03FF
CF_OWNERDISPLAY    :: 0x0080
CF_PRIVATEFIRST    :: 0x0200
CF_PRIVATELAST     :: 0x02FF

STICKYKEYS :: struct {
	cbSize: UINT,
	dwFlags: DWORD,
}
LPSTICKYKEYS :: ^STICKYKEYS

SKF_STICKYKEYSON    :: 0x1
SKF_AVAILABLE       :: 0x2
SKF_HOTKEYACTIVE    :: 0x4
SKF_CONFIRMHOTKEY   :: 0x8
SKF_HOTKEYSOUND     :: 0x10
SKF_INDICATOR       :: 0x20
SKF_AUDIBLEFEEDBACK :: 0x40
SKF_TRISTATE        :: 0x80
SKF_TWOKEYSOFF      :: 0x100
SKF_LSHIFTLOCKED    :: 0x10000
SKF_RSHIFTLOCKED    :: 0x20000
SKF_LCTLLOCKED      :: 0x40000
SKF_RCTLLOCKED      :: 0x80000
SKF_LALTLOCKED      :: 0x100000
SKF_RALTLOCKED      :: 0x200000
SKF_LWINLOCKED      :: 0x400000
SKF_RWINLOCKED      :: 0x800000
SKF_LSHIFTLATCHED   :: 0x1000000
SKF_RSHIFTLATCHED   :: 0x2000000
SKF_LCTLLATCHED     :: 0x4000000
SKF_RCTLLATCHED     :: 0x8000000
SKF_LALTLATCHED     :: 0x10000000
SKF_RALTLATCHED     :: 0x20000000

TOGGLEKEYS :: struct {
	cbSize: UINT,
	dwFlags: DWORD,
}
LPTOGGLEKEYS :: ^TOGGLEKEYS

TKF_TOGGLEKEYSON  :: 0x1
TKF_AVAILABLE     :: 0x2
TKF_HOTKEYACTIVE  :: 0x4
TKF_CONFIRMHOTKEY :: 0x8
TKF_HOTKEYSOUND   :: 0x10
TKF_INDICATOR     :: 0x20

FILTERKEYS :: struct {
	cbSize:  UINT,
	dwFlags: DWORD,
	iWaitMSec: DWORD,
	iDelayMSec: DWORD,
	iRepeatMSec: DWORD,
	iBounceMSec: DWORD,
}
LPFILTERKEYS :: ^FILTERKEYS

FKF_FILTERKEYSON  :: 0x1
FKF_AVAILABLE     :: 0x2
FKF_HOTKEYACTIVE  :: 0x4
FKF_CONFIRMHOTKEY :: 0x8
FKF_HOTKEYSOUND   :: 0x10
FKF_INDICATOR     :: 0x20
FKF_CLICKON       :: 0x40
