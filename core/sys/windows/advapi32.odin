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
		phToken: PHANDLE,
	) -> BOOL ---

	/*
	LogonUserExW :: proc(
		lpszUsername: LPCWSTR,
		lpszDomain:   LPCWSTR,
		lpszPassword: LPCWSTR,
		dwLogonType:  DWORD,
		dwLogonProvider: DWORD,
		phToken: PHANDLE,
		ppLogonSid: PSID,
		ppProfileBuffer: PVOID,
		pdwProfileLength: LPDWORD,
		pQuotaLimits: PQUOTA_LIMITS,
	) -> BOOL ---
	*/
}