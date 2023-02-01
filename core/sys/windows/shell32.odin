// +build windows
package sys_windows

foreign import shell32 "system:Shell32.lib"

@(default_calling_convention="stdcall")
foreign shell32 {
	CommandLineToArgvW :: proc(cmd_list: wstring, num_args: ^c_int) -> ^wstring ---
	ShellExecuteW :: proc(
		hwnd: HWND,
		lpOperation: LPCWSTR,
		lpFile: LPCWSTR,
		lpParameters: LPCWSTR,
		lpDirectory: LPCWSTR,
		nShowCmd: INT,
	) -> HINSTANCE ---
	ShellExecuteExW :: proc(pExecInfo: ^SHELLEXECUTEINFOW) -> BOOL ---
	SHCreateDirectoryExW :: proc(
		hwnd: HWND,
		pszPath: LPCWSTR,
		psa: ^SECURITY_ATTRIBUTES,
	) -> c_int ---
	SHFileOperationW :: proc(lpFileOp: LPSHFILEOPSTRUCTW) -> c_int ---
	SHGetFolderPathW :: proc(hwnd: HWND, csidl: c_int, hToken: HANDLE, dwFlags: DWORD, pszPath: LPWSTR) -> HRESULT ---
	SHAppBarMessage :: proc(dwMessage: DWORD, pData: PAPPBARDATA) -> UINT_PTR --- 
}

APPBARDATA :: struct {
	cbSize: DWORD,
	hWnd: HWND,
	uCallbackMessage: UINT,
	uEdge: UINT,
	rc: RECT,
	lParam: LPARAM,
}
PAPPBARDATA :: ^APPBARDATA
 
ABM_NEW              :: 0x00000000
ABM_REMOVE           :: 0x00000001
ABM_QUERYPOS         :: 0x00000002
ABM_SETPOS           :: 0x00000003
ABM_GETSTATE         :: 0x00000004
ABM_GETTASKBARPOS    :: 0x00000005
ABM_ACTIVATE         :: 0x00000006 
ABM_GETAUTOHIDEBAR   :: 0x00000007
ABM_SETAUTOHIDEBAR   :: 0x00000008 
ABM_WINDOWPOSCHANGED :: 0x0000009
ABM_SETSTATE         :: 0x0000000a
ABN_STATECHANGE      :: 0x0000000
ABN_POSCHANGED       :: 0x0000001
ABN_FULLSCREENAPP    :: 0x0000002
ABN_WINDOWARRANGE    :: 0x0000003
ABS_AUTOHIDE         :: 0x0000001
ABS_ALWAYSONTOP      :: 0x0000002
ABE_LEFT             :: 0
ABE_TOP              :: 1
ABE_RIGHT            :: 2
ABE_BOTTOM           :: 3
