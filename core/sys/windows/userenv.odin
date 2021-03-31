package sys_windows

foreign import userenv "system:Userenv.lib"

@(default_calling_convention="stdcall")
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
		pszProfilePath: LPWSTR,
		cchProfilePath: DWORD,
	) -> HRESULT ---

	// https://docs.microsoft.com/en-us/windows/win32/api/userenv/nf-userenv-deleteprofilew
	// The caller must have administrative privileges to delete a user's profile.
	DeleteProfileW :: proc(
		lpSidString: LPCWSTR,
		lpProfilePath: LPCWSTR,
		lpComputerName: LPCWSTR,
	) -> BOOL ---

	// https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountnamew
	// To look up the SID to use with DeleteProfileW.
	LookupAccountNameW :: proc(
		lpSystemName: LPCWSTR,
		lpAccountName: LPCWSTR,
		Sid: ^SID,
		cbSid: LPDWORD,
		ReferencedDomainName: LPWSTR,
		cchReferencedDomainName: LPDWORD,
		peUse: ^SID_TYPE,
	) -> BOOL ---

	// https://docs.microsoft.com/en-us/windows/win32/api/sddl/nf-sddl-convertsidtostringsida
	// To turn a SID into a string SID to use with DeleteProfileW.
	ConvertSidToStringSidW :: proc(
		Sid: ^SID,
	  	StringSid: LPWSTR,
	) -> BOOL ---
}
