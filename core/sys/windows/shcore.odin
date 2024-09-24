#+build windows

package sys_windows

foreign import shcore "system:Shcore.lib"

@(default_calling_convention="system")
foreign shcore {
	GetProcessDpiAwareness :: proc(hprocess: HANDLE, value: ^PROCESS_DPI_AWARENESS) -> HRESULT ---
	SetProcessDpiAwareness :: proc(value: PROCESS_DPI_AWARENESS) -> HRESULT ---
	GetDpiForMonitor :: proc(hmonitor: HMONITOR, dpiType: MONITOR_DPI_TYPE, dpiX: ^UINT, dpiY: ^UINT) -> HRESULT ---
}

PROCESS_DPI_AWARENESS :: enum DWORD {
	PROCESS_DPI_UNAWARE = 0,
	PROCESS_SYSTEM_DPI_AWARE = 1,
	PROCESS_PER_MONITOR_DPI_AWARE = 2,
}

MONITOR_DPI_TYPE :: enum DWORD {
	MDT_EFFECTIVE_DPI = 0,
	MDT_ANGULAR_DPI = 1,
	MDT_RAW_DPI = 2,
	MDT_DEFAULT,
}
