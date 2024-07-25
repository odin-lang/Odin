// +build windows
package sys_windows

foreign import shell32 "system:Shell32.lib"

@(default_calling_convention="system")
foreign shell32 {
	CommandLineToArgvW :: proc(cmd_list: wstring, num_args: ^c_int) -> [^]wstring ---
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

	Shell_NotifyIconW :: proc(dwMessage: DWORD, lpData: ^NOTIFYICONDATAW) -> BOOL ---
	SHChangeNotify :: proc(wEventId: LONG, uFlags: UINT, dwItem1: LPCVOID, dwItem2: LPCVOID) ---

	SHGetKnownFolderIDList :: proc(rfid: REFKNOWNFOLDERID, dwFlags: /* KNOWN_FOLDER_FLAG */ DWORD, hToken: HANDLE, ppidl: rawptr) -> HRESULT ---
	SHSetKnownFolderPath :: proc(rfid: REFKNOWNFOLDERID, dwFlags: /* KNOWN_FOLDER_FLAG */ DWORD, hToken: HANDLE, pszPath: PCWSTR ) -> HRESULT ---
	SHGetKnownFolderPath :: proc(rfid: REFKNOWNFOLDERID, dwFlags: /* KNOWN_FOLDER_FLAG */ DWORD, hToken: HANDLE, ppszPath: ^LPWSTR) -> HRESULT ---

	ExtractIconExW :: proc(pszFile: LPCWSTR, nIconIndex: INT, phiconLarge: ^HICON, phiconSmall: ^HICON, nIcons: UINT) -> UINT ---
	DragAcceptFiles :: proc(hWnd: HWND, fAccept: BOOL) ---
	DragQueryPoint :: proc(hDrop: HDROP, ppt: ^POINT) -> BOOL ---
	DragQueryFileW :: proc(hDrop: HDROP, iFile: UINT, lpszFile: LPWSTR, cch: UINT) -> UINT ---
	DragFinish :: proc(hDrop: HDROP) --- // @New
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

KNOWNFOLDERID :: GUID
REFKNOWNFOLDERID :: ^KNOWNFOLDERID

HDROP :: HANDLE

KNOWN_FOLDER_FLAG :: enum u32 {
	DEFAULT                          = 0x00000000,

	// if NTDDI_VERSION >= NTDDI_WIN10_RS3
	FORCE_APP_DATA_REDIRECTION       = 0x00080000,

	// if NTDDI_VERSION >= NTDDI_WIN10_RS2
	RETURN_FILTER_REDIRECTION_TARGET = 0x00040000,
	FORCE_PACKAGE_REDIRECTION        = 0x00020000,
	NO_PACKAGE_REDIRECTION           = 0x00010000,
	FORCE_APPCONTAINER_REDIRECTION   = 0x00020000,

	// if NTDDI_VERSION >= NTDDI_WIN7
	NO_APPCONTAINER_REDIRECTION      = 0x00010000,

	CREATE                           = 0x00008000,
	DONT_VERIFY                      = 0x00004000,
	DONT_UNEXPAND                    = 0x00002000,
	NO_ALIAS                         = 0x00001000,
	INIT                             = 0x00000800,
	DEFAULT_PATH                     = 0x00000400,
	NOT_PARENT_RELATIVE              = 0x00000200,
	SIMPLE_IDLIST                    = 0x00000100,
	ALIAS_ONLY                       = 0x80000000,
}

SHCNRF_InterruptLevel     :: 0x0001
SHCNRF_ShellLevel         :: 0x0002
SHCNRF_RecursiveInterrupt :: 0x1000
SHCNRF_NewDelivery        :: 0x8000

SHCNE_RENAMEITEM          :: 0x00000001
SHCNE_CREATE              :: 0x00000002
SHCNE_DELETE              :: 0x00000004
SHCNE_MKDIR               :: 0x00000008
SHCNE_RMDIR               :: 0x00000010
SHCNE_MEDIAINSERTED       :: 0x00000020
SHCNE_MEDIAREMOVED        :: 0x00000040
SHCNE_DRIVEREMOVED        :: 0x00000080
SHCNE_DRIVEADD            :: 0x00000100
SHCNE_NETSHARE            :: 0x00000200
SHCNE_NETUNSHARE          :: 0x00000400
SHCNE_ATTRIBUTES          :: 0x00000800
SHCNE_UPDATEDIR           :: 0x00001000
SHCNE_UPDATEITEM          :: 0x00002000
SHCNE_SERVERDISCONNECT    :: 0x00004000
SHCNE_UPDATEIMAGE         :: 0x00008000
SHCNE_DRIVEADDGUI         :: 0x00010000
SHCNE_RENAMEFOLDER        :: 0x00020000
SHCNE_FREESPACE           :: 0x00040000

SHCNE_EXTENDED_EVENT      :: 0x04000000

SHCNE_ASSOCCHANGED        :: 0x08000000

SHCNE_DISKEVENTS          :: 0x0002381F
SHCNE_GLOBALEVENTS        :: 0x0C0581E0
SHCNE_ALLEVENTS           :: 0x7FFFFFFF
SHCNE_INTERRUPT           :: 0x80000000

SHCNEE_ORDERCHANGED       :: 2
SHCNEE_MSI_CHANGE         :: 4
SHCNEE_MSI_UNINSTALL      :: 5

SHCNF_IDLIST              :: 0x0000
SHCNF_PATHA               :: 0x0001
SHCNF_PRINTERA            :: 0x0002
SHCNF_DWORD               :: 0x0003
SHCNF_PATHW               :: 0x0005
SHCNF_PRINTERW            :: 0x0006
SHCNF_TYPE                :: 0x00FF
SHCNF_FLUSH               :: 0x1000
SHCNF_FLUSHNOWAIT         :: 0x3000

SHCNF_NOTIFYRECURSIVE     :: 0x10000
