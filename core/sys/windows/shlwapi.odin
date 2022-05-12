// +build windows
package sys_windows

foreign import shlwapi "system:shlwapi.lib"

@(default_calling_convention="stdcall")
foreign shlwapi {
	PathFileExistsW    :: proc(pszPath: wstring) -> BOOL ---
	PathFindExtensionW :: proc(pszPath: wstring) -> wstring ---
	PathFindFileNameW  :: proc(pszPath: wstring) -> wstring ---
}
