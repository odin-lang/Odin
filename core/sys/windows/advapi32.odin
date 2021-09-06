// +build windows
package sys_windows

foreign import advapi32 "system:Advapi32.lib"

@(default_calling_convention="stdcall")
foreign advapi32 {
	@(link_name = "SystemFunction036")
	RtlGenRandom :: proc(RandomBuffer: ^u8, RandomBufferLength: ULONG) -> BOOLEAN ---
	OpenProcessToken :: proc(ProcessHandle: HANDLE,
	                         DesiredAccess: DWORD,
	                         TokenHandle: ^HANDLE) -> BOOL ---
}

// Necessary to create a token to impersonate a user with for CreateProcessAsUser
@(default_calling_convention="stdcall")
foreign advapi32 {
	LogonUserW :: proc(
		lpszUsername: LPCWSTR,
		lpszDomain: LPCWSTR,
		lpszPassword: LPCWSTR,
		dwLogonType: Logon32_Type,
		dwLogonProvider: Logon32_Provider,
		phToken: ^HANDLE,
	) -> BOOL ---

	// https://docs.microsoft.com/en-us/windows/win32/api/winbase/nf-winbase-lookupaccountnamew
	// To look up the SID to use with DeleteProfileW.
	LookupAccountNameW :: proc(
		lpSystemName: wstring,
		lpAccountName: wstring,
		Sid: ^SID,
		cbSid: ^DWORD,
		ReferencedDomainName: wstring,
		cchReferencedDomainName: ^DWORD,
		peUse: ^SID_TYPE,
	) -> BOOL ---

	CreateProcessWithLogonW :: proc(
		lpUsername: wstring,
		lpDomain: wstring,
		lpPassword: wstring,
		dwLogonFlags: DWORD,
		lpApplicationName: wstring,
		lpCommandLine: wstring,
		dwCreationFlags: DWORD,
		lpEnvironment: LPVOID,
		lpCurrentDirectory: wstring,
		lpStartupInfo: LPSTARTUPINFO,
		lpProcessInformation: LPPROCESS_INFORMATION,
	) -> BOOL ---

	// https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessasuserw
	CreateProcessAsUserW :: proc(
		hToken: HANDLE,
		lpApplicationName: wstring,
		lpCommandLine: wstring,
		lpProcessAttributes: LPSECURITY_ATTRIBUTES,
		lpThreadAttributes: LPSECURITY_ATTRIBUTES,
		bInheritHandles: BOOL,
		dwCreationFlags: DWORD,
		lpEnvironment: LPVOID,
		lpCurrentDirectory: wstring,
		lpStartupInfo: LPSTARTUPINFO,
		lpProcessInformation: LPPROCESS_INFORMATION,
	) -> BOOL ---
}