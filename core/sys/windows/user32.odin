// +build windows
package sys_windows

foreign import user32 "system:User32.lib"

@(default_calling_convention="stdcall")
foreign user32 {
	//
	// Windows and Messages
	//

	AdjustWindowRect :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL) -> BOOL ---
	AdjustWindowRectEx :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD) -> BOOL ---

	AllowSetForegroundWindow :: proc(dwProcessId: DWORD) -> BOOL ---
	AnimateWindow :: proc(hWnd: HWND, dwTime, dwFlags: DWORD) -> BOOL ---
	AnyPopup :: proc() -> BOOL ---
	ArrangeIconicWindows :: proc(hWnd: HWND) -> UINT ---

	BeginDeferWindowPos :: proc(nNumWindows: c_int) -> HDWP ---
	BringWindowToTop :: proc(hWnd: HWND) -> BOOL ---
	BroadcastSystemMessage :: proc(flags: DWORD, lpInfo: ^DWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> c_long ---
	BroadcastSystemMessageExW :: proc(flags: DWORD, lpInfo: LPDWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM, pbsmInfo: PBSMINFO) -> c_long ---
	BroadcastSystemMessageW :: proc(flags: DWORD, lpInfo: LPDWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> c_long ---

	CalculatePopupWindowPosition :: proc(anchorPoint: ^POINT, windowSize: ^SIZE, flags: UINT, excludeRect: ^RECT, popupWindowPosition: ^RECT) -> BOOL ---
	CallMsgFilterW :: proc(lpMsg: LPMSG, nCode: i32) -> BOOL ---
	CallNextHookEx :: proc(hhk: HHOOK, nCode: c_int, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	CallWindowProcW :: proc(lpPrevWndFunc: WNDPROC, hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	CascadeWindows :: proc(hwndParent: HWND, wHow: UINT, lpRect: ^RECT, cKids: UINT, lpKids: ^HWND) -> WORD ---
	ChangeWindowMessageFilter :: proc(message: UINT, dwFlag: DWORD) -> BOOL ---
	ChangeWindowMessageFilterEx :: proc(hwnd: HWND, message: UINT, action: DWORD, pChangeFilterStruct: ^CHANGEFILTERSTRUCT) -> BOOL ---
	ChildWindowFromPoint :: proc(hWndParent: HWND, Point: POINT) -> HWND ---
	ChildWindowFromPointEx :: proc(hwnd: HWND, pt: POINT, flags: UINT) -> HWND ---
	CloseWindow :: proc(hWnd: HWND) -> BOOL ---

	CreateMDIWindowW :: proc(
		lpClassName: LPCWSTR,
		lpWindowName: LPCWSTR,
		dwStyle: DWORD,
		X: i32,
		Y: i32,
		nWidth: i32,
		nHeight: i32,
		hWndParent: HWND,
		hInstance: HINSTANCE,
		lParam: LPARAM
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

	DeferWindowPos :: proc(hWinPosInfo: HDWP, hWnd: HWND, hWndInsertAfter: HWND, x: i32, y: i32, cx: i32, cy: i32, uFlags: UINT) -> HDWP ---
	DefFrameProcW :: proc(hWnd: HWND, hWndMDIClient: HWND, uMsg: HWND, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	DefMDIChildProcW :: proc(hWnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	DefWindowProcW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	DeregisterShellHookWindow :: proc(hwnd: HWND) -> BOOL ---;
	DestroyWindow :: proc(hWnd: HWND) -> BOOL ---

	// DispatchMessage
	DispatchMessageW :: proc(lpMsg: ^MSG) -> LRESULT ---

	EndDeferWindowPos :: proc(hWinPosInfo: HDWP) -> BOOL ---
	EndTask :: proc(hWnd: HWND, fShutDown: BOOL, fForce: BOOL) -> BOOL ---
	EnumChildWindows :: proc(hWndParent: HWND, lpEnumFunc: WNDENUMPROC, lParam: LPARAM) -> BOOL ---
	EnumPropsExW :: proc(hWnd: HWND, lpEnumFunc: PROPENUMPROCEXW, lParam: LPARAM) -> i32 ---
	EnumPropsW :: proc(hWnd: HWND, lpEnumFunc: PROPENUMPROCW) -> i32 ---
	EnumThreadWindows :: proc(dwThreadId: DWORD, lpfn: WNDENUMPROC, lParam: LPARAM) -> BOOL ---
	EnumWindows :: proc(lpEnumFunc: Window_Enum_Proc, lParam: LPARAM) -> BOOL ---

	FindWindowW :: proc(lpClassName: LPCWSTR, lpWindowName: LPCWSTR) -> HWND ---
	FindWindowExW :: proc(hWndParent, hWndChildAfter: HWND, lpszClass: LPCWSTR, lpszWindow: LPCWSTR) -> HWND ---

	// GetAltTabInfoW
	// GetAncestor

	GetClassInfoExW :: proc(hInsatnce: HINSTANCE, lpszClass: LPCWSTR, lpwcx: ^WNDCLASSEXW) -> BOOL ---
	GetClassInfoW :: proc(hInstance: HINSTANCE, lpClassNAme: LPCWSTR, lpWndClass: ^WNDCLASSW) -> BOOL ---
    
	// GetClassLongPtrW
	GetClassLongW :: proc(hWnd: HWND, nIndex: c_int) -> DWORD ---

	// GetClassName
	GetClassNameW :: proc(hWnd: HWND, lpClassName: LPWSTR, nMaxCount: c_int) -> c_int ---

	// GetClassWord
	GetClientRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	GetDesktopWindow :: proc() -> HWND ---
	GetForegroundWindow :: proc() -> HWND ---
	// GetGUIThreadInfo
	// GetInputState
	// GetLastActivePopup
	// GetLayeredWindowAttributes

	// GetMessage
	// GetMessageExtraInfo
	// GetMessagePos
	// GetMessageTime
	GetMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin, wMsgFilterMax: UINT) -> BOOL ---

	// GetNextWindow (macro)
	// GetParent
	// GetProcessDefaultLayout

	// GetPropW
	GetQueueStatus :: proc(flags: UINT) -> DWORD ---
	// GetShellWindow
	GetSysColor :: proc(nIndex: c_int) -> DWORD ---
	GetSystemMetrics :: proc(nIndex: c_int) -> c_int ---
	// GetTitleBarInfo

	GetTopWindow :: proc(hWnd: HWND) -> HWND ---
	// GetWindow
	// GetWindowDisplayAffinity
	GetWindowInfo :: proc(hwnd: HWND, pwi: PWINDOWINFO) -> BOOL ---
	GetWindowLongW :: proc(hWnd: HWND, nIndex: c_int) -> LONG ---

	// GetWindowModuleFileNameW
	GetWindowPlacement :: proc(hWnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	GetWindowRect :: proc(hWnd: HWND, lpRect: LPRECT) -> BOOL ---
	GetWindowTextLengthW :: proc(hWnd: HWND) -> c_int ---
	GetWindowTextW :: proc(hWnd: HWND, lpString: LPWSTR, nMaxCount: c_int) -> c_int ---
	// GetWindowThreadProcessId
	// GetWindowWord

	// InSendMessage
	// InSendMessageEx
	// IsChild
	// IsGUIThread
	// IsHungAppWindow
	// IsIconic
	// IsProcessDPIAware
	IsWindow :: proc(hWnd: HWND) -> BOOL ---
	// IsWindowArranged
	// IsWindowUnicode
	// IsWindowVisible
	// IsZoomed

	KillTimer :: proc(hWnd: HWND, uIDEvent: UINT_PTR) -> BOOL ---

	LockSetForegroundWindow :: proc(uLockCode: UINT) -> BOOL ---
	LogicalToPhysicalPoint :: proc(hWnd: HWND, lpPoint: ^POINT) -> BOOL ---

	// MAKELPARAM macro, MAKELRESULT macro, MAKEWPARAM macro

	MoveWindow :: proc(hWnd: HWND, X, Y, hWidth, hHeight: c_int, bRepaint: BOOL) -> BOOL ---

	OpenIcon :: proc(hWnd: HWND) -> BOOL ---

	PeekMessageW :: proc(lpMsg: ^MSG, hWnd: HWND, wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT) -> BOOL ---
	PhysicalToLogicalPoint :: proc(hWnd: HWND, lpPoint: ^POINT) -> BOOL ---
	PostMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	PostQuitMessage :: proc(nExitCode: c_int) ---
	PostThreadMessageW :: proc(idThread: DWORD, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---

	RealChildWindowFromPoint :: proc(hwndParent: HWND, ptParentClientCoords: POINT) -> HWND ---
	RealGetWindowClassW :: proc(hwnd: HWND, ptszClassName: LPWSTR, cchClassNameMax: UINT) -> UINT ---

	RegisterClassExW :: proc(^WNDCLASSEXW) -> ATOM ---
	RegisterClassW :: proc(lpWndClass: ^WNDCLASSW) -> ATOM ---

	RegisterShellHookWindow :: proc(hwnd: HWND) -> BOOL ---
	RegisterWindowMessageW :: proc(lpString: LPCWSTR) -> UINT ---
	RemovePropW :: proc(hWnd: HWND, lpString: LPCWSTR) -> HANDLE ---
	ReplyMessage :: proc(lResult: LRESULT) -> BOOL ---

	SendMessageCallbackW :: proc(
		hWnd: HWND,
		Msg: UINT,
		wParam: WPARAM,
		lParam: LPARAM,
		lpResultCallBack: SENDASYNCPROC,
		dwData: ULONG_PTR,
	) -> BOOL ---

	SendMessageTimeoutW :: proc(
		hWnd: HWND,
		Msg: UINT,
		wParam: WPARAM,
		lParam: LPARAM,
		fuFlags: UINT,
		uTimeout: UINT,
		lpdwResult: PDWORD_PTR,
	) -> LRESULT ---

	SendMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> LRESULT ---
	SendNotifyMessageW :: proc(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) -> BOOL ---
	SetAdditionalForegroundBoostProcesses :: proc(topLevelWindow: HWND, processHandleCount: DWORD, processHandleArray: ^HANDLE) -> BOOL --- // @Todo(ema) Should this ptr be a multi-pointer? [^]HANDLE

	// SetClassLongPtrW
	SetClassLongW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> DWORD ---

	SetClassWord :: proc(hWnd: HWND, nIndex: c_int, wNewWord: WORD) -> WORD ---
	SetCoalescableTimer :: proc(
		hWnd: HWND,
		nIDEvent: UINT_PTR,
		uElapse: UINT,
		lpTimerFunc: TIMERPROC,
		uToleranceDelay: ULONG,
	) -> UINT_PTR ---

	SetForegroundWindow :: proc(hWnd: HWND) -> BOOL ---
	SetLayeredWindowAttributes  :: proc(hWnd: HWND, crKey: COLORREF, bAlpha: BYTE, dwFlags: DWORD) -> BOOL ---
	SetMessageExtraInfo :: proc(lParam: LPARAM) -> LPARAM ---
	SetParent :: proc(hWndChild, hWndNewParent: HWND) -> HWND ---
	SetProcessDefaultLayout :: proc(dwDefaultLayout: DWORD) -> BOOL ---
	SetProcessDPIAware :: proc() -> BOOL ---
	SetPropW :: proc(hWnd: HWND, lpString: LPCWSTR, hData: HANDLE) -> BOOL ---
	SetSysColors :: proc(cElements: c_int, lpaElements: ^INT, lpaRgbValues: ^COLORREF) -> BOOL --- // @Todo(ema): Same thing as above. Multi-pointers for these?
	SetTimer :: proc(hWnd: HWND, nIDEvent: UINT_PTR, uElapse: UINT, lpTimerFunc: TIMERPROC) -> UINT_PTR ---
	SetWindowDisplayAffinity :: proc(hWnd: HWND, dwAffinity: DWORD) -> BOOL ---

	// 
	SetWindowLongW :: proc(hWnd: HWND, nIndex: c_int, dwNewLong: LONG) -> LONG ---

	SetWindowPlacement :: proc(hwnd: HWND, lpwndpl: ^WINDOWPLACEMENT) -> BOOL ---
	SetWindowPos :: proc(
		hWnd: HWND,
		hWndInsertAfter: HWND,
		X: c_int,
		Y: c_int,
		cx: c_int,
		cy: c_int,
		uFlags: UINT,
	) -> BOOL ---

	SetWindowsHookExW :: proc(idHook: c_int, lpfn: HOOKPROC, hmod: HINSTANCE, dwThreadId: DWORD) -> HHOOK ---
	SetWindowTextW :: proc(hWnd: HWND, lpString: LPCWSTR) -> BOOL ---

	ShowOwnedPopups :: proc(hWnd: HWND, fShow: BOOL) -> BOOL ---
	ShowWindow :: proc(hWnd: HWND, nCmdShow: c_int) -> BOOL ---
	ShowWindowAsync :: proc(hWnd: HWND, nCmdShow: c_int) -> BOOL ---

	SoundSentry :: proc() -> BOOL ---
	SwitchToThisWindow :: proc(hwnd: HWND, fUnknown: BOOL) ---
	SystemParametersInfoW :: proc(uiAction, uiParam: UINT, pvParam: ^VOID, fWinIni: UINT) -> BOOL ---

	TileWindows :: proc(hwndParent: HWND, wHow: UINT, lpRect: ^RECT, cKids: UINT, lpKids: ^HWND) -> WORD --- // @Todo(ema): See todo on multi-pointers...
	TranslateMDISysAccel :: proc(hWndClient: HWND, lpMsg: LPMSG) -> BOOL ---
	TranslateMessage :: proc(lpMsg: ^MSG) -> BOOL ---

	UnhookWindowsHookEx :: proc(hhk: HHOOK) -> BOOL ---
	UnregisterClassW :: proc(lpClassName: LPCWSTR, hInstance: HINSTANCE) -> BOOL ---
	UpdateLayeredWindow :: proc(
		hWnd: HWND,
		hdcDst: HDC,
		pptDst: ^POINT,
		psize: ^SIZE,
		hdcSrc: HDC,
		pptSrc: ^POINT,
		crKey: COLORREF,
		pblend: ^BLENDFUNCTION,
		dwFlags: DWORD,
	) -> BOOL ---

	WaitMessage :: proc() -> BOOL ---
	WindowFromPhysicalPoint :: proc(Point: POINT) -> HWND ---
	WindowFromPoint :: proc(Point: POINT) -> HWND ---

	//
	// END OF: Windows and Messages
	//

	//
	// High DPI
	//

	AdjustWindowRectExForDpi :: proc(lpRect: LPRECT, dwStyle: DWORD, bMenu: BOOL, dwExStyle: DWORD, dpi: UINT) -> BOOL ---
	// AreDpiAwarenessContextsEqual

	//
	// END OF: High DPI
	//
	
	UpdateWindow :: proc(hWnd: HWND) -> BOOL ---
	SetActiveWindow :: proc(hWnd: HWND) -> HWND ---
	GetActiveWindow :: proc() -> HWND ---

	LoadIconW :: proc(hInstance: HINSTANCE, lpIconName: LPCWSTR) -> HICON ---
	LoadCursorW :: proc(hInstance: HINSTANCE, lpCursorName: LPCWSTR) -> HCURSOR ---
	LoadImageW :: proc(hInst: HINSTANCE, name: LPCWSTR, type: UINT, cx, cy: c_int, fuLoad: UINT) -> HANDLE ---

	ClientToScreen :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	ScreenToClient :: proc(hWnd: HWND, lpPoint: LPPOINT) -> BOOL ---
	
	GetMonitorInfoW :: proc(hMonitor: HMONITOR, lpmi: LPMONITORINFO) -> BOOL ---

	GetWindowDC :: proc(hWnd: HWND) -> HDC ---
	GetDC :: proc(hWnd: HWND) -> HDC ---
	ReleaseDC :: proc(hWnd: HWND, hDC: HDC) -> c_int ---

	GetDlgCtrlID :: proc(hWnd: HWND) -> c_int ---
	GetDlgItem :: proc(hDlg: HWND, nIDDlgItem: c_int) -> HWND ---

	CreatePopupMenu :: proc() -> HMENU ---
	DestroyMenu :: proc(hMenu: HMENU) -> BOOL ---
	AppendMenuW :: proc(hMenu: HMENU, uFlags: UINT, uIDNewItem: UINT_PTR, lpNewItem: LPCWSTR) -> BOOL ---
	TrackPopupMenu :: proc(hMenu: HMENU, uFlags: UINT, x, y: c_int, nReserved: c_int, hWnd: HWND, prcRect: ^RECT) -> BOOL ---
	
	GetUpdateRect :: proc(hWnd: HWND, lpRect: ^RECT, bErase: BOOL) -> BOOL ---
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

	MapVirtualKeyW :: proc(uCode, uMapType: UINT) -> UINT ---
	ToUnicode :: proc(nVirtKey, wScanCode: UINT, lpKeyState: ^BYTE, pwszBuff: LPWSTR, cchBuff: c_int, wFlags: UINT) -> c_int ---

	MessageBoxW :: proc(hWnd: HWND, lpText, lpCaption: LPCWSTR, uType: UINT) -> c_int ---
	MessageBoxExW :: proc(hWnd: HWND, lpText, lpCaption: LPCWSTR, uType: UINT, wLanguageId: WORD) -> c_int ---

	ClipCursor :: proc(lpRect: LPRECT) -> BOOL ---
	GetCursorPos :: proc(lpPoint: LPPOINT) -> BOOL ---
	SetCursorPos :: proc(X, Y: c_int) -> BOOL ---
	SetCursor :: proc(hCursor: HCURSOR) -> HCURSOR ---

	EnumDisplaySettingsW :: proc(lpszDeviceName: LPCWSTR, iModeNum: DWORD, lpDevMode: ^DEVMODEW) -> BOOL ---

	MonitorFromPoint  :: proc(pt: POINT, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	MonitorFromRect   :: proc(lprc: LPRECT, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	MonitorFromWindow :: proc(hwnd: HWND, dwFlags: Monitor_From_Flags) -> HMONITOR ---
	EnumDisplayMonitors :: proc(hdc: HDC, lprcClip: LPRECT, lpfnEnum: Monitor_Enum_Proc, dwData: LPARAM) -> BOOL ---
	
	SetThreadDpiAwarenessContext :: proc(dpiContext: DPI_AWARENESS_CONTEXT) -> DPI_AWARENESS_CONTEXT ---
	GetThreadDpiAwarenessContext :: proc() -> DPI_AWARENESS_CONTEXT ---
	GetWindowDpiAwarenessContext :: proc(hwnd: HWND) -> DPI_AWARENESS_CONTEXT ---
	GetDpiFromDpiAwarenessContext :: proc(value: DPI_AWARENESS_CONTEXT) -> UINT ---
	GetDpiForWindow :: proc(hwnd: HWND) -> UINT ---
	SetProcessDpiAwarenessContext :: proc(value: DPI_AWARENESS_CONTEXT) -> BOOL ---

	GetSysColorBrush :: proc(nIndex: c_int) -> HBRUSH ---
	
	MessageBeep :: proc(uType: UINT) -> BOOL ---

	IsDialogMessageW :: proc(hDlg: HWND, lpMsg: LPMSG) -> BOOL ---
	
	EnableWindow :: proc(hWnd: HWND, bEnable: BOOL) -> BOOL ---

	DefRawInputProc :: proc(paRawInput: ^PRAWINPUT, nInput: INT, cbSizeHeader: UINT) -> LRESULT ---
	GetRawInputBuffer :: proc(pRawInput: PRAWINPUT, pcbSize: PUINT, cbSizeHeader: UINT) -> UINT ---
	GetRawInputData :: proc(hRawInput: HRAWINPUT, uiCommand: UINT, pData: LPVOID, pcbSize: PUINT, cbSizeHeader: UINT) -> UINT ---
	GetRawInputDeviceInfoW :: proc(hDevice: HANDLE, uiCommand: UINT, pData: LPVOID, pcbSize: PUINT) -> UINT ---
	GetRawInputDeviceList :: proc(pRawInputDeviceList: PRAWINPUTDEVICELIST, puiNumDevices: PUINT, cbSize: UINT) -> UINT ---
	GetRegisteredRawInputDevices :: proc(pRawInputDevices: PRAWINPUTDEVICE, puiNumDevices: PUINT, cbSize: UINT) -> UINT ---
	RegisterRawInputDevices :: proc(pRawInputDevices: PCRAWINPUTDEVICE, uiNumDevices: UINT, cbSize: UINT) -> BOOL --- // @Todo(ema): Multi-pointers for these

	SendInput :: proc(cInputs: UINT, pInputs: [^]INPUT, cbSize: c_int) -> UINT ---

	FillRect :: proc(hDC: HDC, lprc: ^RECT, hbr: HBRUSH) -> c_int ---
	EqualRect :: proc(lprc1, lprc2: ^RECT) -> BOOL ---

	SetWindowRgn :: proc(hWnd: HWND, hRgn: HRGN, bRedraw: BOOL) -> c_int ---
	CreateRectRgnIndirect :: proc(lprect: ^RECT) -> HRGN ---
	GetSystemMetricsForDpi :: proc(nIndex: c_int, dpi: UINT) -> c_int ---

	GetSystemMenu :: proc(hWnd: HWND, bRevert: BOOL) -> HMENU ---
	EnableMenuItem :: proc(hMenu: HMENU, uIDEnableItem, uEnable: UINT) -> BOOL ---
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

Monitor_Enum_Proc :: #type proc "stdcall" (HMONITOR, HDC, LPRECT, LPARAM) -> BOOL
Window_Enum_Proc :: #type proc "stdcall" (HWND, LPARAM) -> BOOL

WNDENUMPROC :: #type proc "stdcall" (hwnd: HWND, lParam: LPARAM) -> BOOL
PROPENUMPROCW :: #type proc "stdcall" (unnamedParam1: HWND, unnamedParam2: LPCWSTR, unnamedParam3: HANDLE) -> BOOL
PROPENUMPROCEXW :: #type proc "stdcall" (unnamedParam1: HWND, unnamedParam2: LPWSTR, unnamedParam3: HANDLE, unnamedParam4: ULONG_PTR) -> BOOL

USER_DEFAULT_SCREEN_DPI                    :: 96
DPI_AWARENESS_CONTEXT                      :: distinct HANDLE
DPI_AWARENESS_CONTEXT_UNAWARE              :: DPI_AWARENESS_CONTEXT(~uintptr(0)) // -1
DPI_AWARENESS_CONTEXT_SYSTEM_AWARE         :: DPI_AWARENESS_CONTEXT(~uintptr(1)) // -2
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE    :: DPI_AWARENESS_CONTEXT(~uintptr(2)) // -3
DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 :: DPI_AWARENESS_CONTEXT(~uintptr(3)) // -4
DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED    :: DPI_AWARENESS_CONTEXT(~uintptr(4)) // -5

CHANGEFILTERSTRUCT :: struct {
	cbSize: DWORD,
	ExtStatus: DWORD,
}
PCHANGEFILTERSTRUCT :: ^CHANGEFILTERSTRUCT

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
	DUMMYUNIONNAME: struct #raw_union {
		ulButtons: ULONG,
		DUMMYSTRUCTNAME: struct {
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
	DUMMYUNIONNAME: struct #raw_union {
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

RIM_TYPEMOUSE :: 0
RIM_TYPEKEYBOARD :: 1
RIM_TYPEHID :: 2

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
