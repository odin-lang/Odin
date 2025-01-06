#+build windows
package sys_windows

foreign import userenv "system:Userenv.lib"

@(default_calling_convention="system")
foreign userenv {
	GetUserProfileDirectoryW :: proc(hToken: HANDLE,
	                                 lpProfileDir: LPWSTR,
	                                 lpcchSize: ^DWORD) -> BOOL ---
	LoadUserProfileW :: proc(
		hToken: HANDLE,
		lpProfileInfo: ^PROFILEINFOW,
	) -> BOOL ---

	// https://docs.microsoft.com/en-us/windows/win32/api/userenv/nf-userenv-createprofile
	// The caller must have administrator privileges to call this function.
	CreateProfile :: proc(
		pszUserSid: LPCWSTR,
		pszUserName: LPCWSTR,
		pszProfilePath: wstring,
		cchProfilePath: DWORD,
	) -> u32 ---

	// https://docs.microsoft.com/en-us/windows/win32/api/userenv/nf-userenv-deleteprofilew
	// The caller must have administrative privileges to delete a user's profile.
	DeleteProfileW :: proc(
		lpSidString: LPCWSTR,
		lpProfilePath: LPCWSTR,
		lpComputerName: LPCWSTR,
	) -> BOOL ---

	// https://docs.microsoft.com/en-us/windows/win32/api/sddl/nf-sddl-convertsidtostringsida
	// To turn a SID into a string SID to use with CreateProfile & DeleteProfileW.
	ConvertSidToStringSidW :: proc(
		Sid: ^SID,
	  	StringSid: ^LPCWSTR,
	) -> BOOL ---
}
