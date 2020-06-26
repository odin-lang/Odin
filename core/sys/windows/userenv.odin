package sys_windows

foreign import userenv "system:Userenv.lib"

@(default_calling_convention="stdcall")
foreign userenv {
	GetUserProfileDirectoryW :: proc(hToken: HANDLE,
	                                 lpProfileDir: LPWSTR,
	                                 lpcchSize: ^DWORD) -> BOOL ---
}
