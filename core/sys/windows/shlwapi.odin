#+build windows
package sys_windows

foreign import shlwapi "system:shlwapi.lib"

@(default_calling_convention="system")
foreign shlwapi {
	PathFileExistsW    :: proc(pszPath: wstring) -> BOOL ---
	PathFindExtensionW :: proc(pszPath: wstring) -> wstring ---
	PathFindFileNameW  :: proc(pszPath: wstring) -> wstring ---
	SHAutoComplete     :: proc(hwndEdit: HWND, dwFlags: DWORD) -> LWSTDAPI ---
}
