// +build windows
package sys_windows

foreign import advapi32 "system:Advapi32.lib"

HCRYPTPROV :: distinct HANDLE

@(default_calling_convention="system")
foreign advapi32 {
	@(link_name = "SystemFunction036")
	RtlGenRandom :: proc(RandomBuffer: ^u8, RandomBufferLength: ULONG) -> BOOLEAN ---
	OpenProcessToken :: proc(ProcessHandle: HANDLE,
	                         DesiredAccess: DWORD,
	                         TokenHandle: ^HANDLE) -> BOOL ---

	OpenThreadToken :: proc(ThreadHandle:  HANDLE,
	                        DesiredAccess: DWORD,
	                        OpenAsSelf:    BOOL,
	                        TokenHandle:   ^HANDLE) -> BOOL ---

	CryptAcquireContextW :: proc(hProv: ^HCRYPTPROV, szContainer, szProvider: wstring, dwProvType, dwFlags: DWORD) -> DWORD ---
	CryptGenRandom       :: proc(hProv: HCRYPTPROV, dwLen: DWORD, buf: LPVOID) -> DWORD ---
	CryptReleaseContext  :: proc(hProv: HCRYPTPROV, dwFlags: DWORD) -> DWORD ---
}

// Necessary to create a token to impersonate a user with for CreateProcessAsUser
@(default_calling_convention="system")
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
		lpStartupInfo: LPSTARTUPINFOW,
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
		lpStartupInfo: LPSTARTUPINFOW,
		lpProcessInformation: LPPROCESS_INFORMATION,
	) -> BOOL ---

	RegCreateKeyExW :: proc(
		hKey: HKEY,
		lpSubKey: LPCWSTR,
		Reserved: DWORD,
		lpClass: LPWSTR,
		dwOptions: DWORD,
		samDesired: REGSAM,
		lpSecurityAttributes: LPSECURITY_ATTRIBUTES,
		phkResult: PHKEY,
		lpdwDisposition: LPDWORD,
	) -> LSTATUS ---

	RegOpenKeyW :: proc(
		hKey: HKEY,
		lpSubKey: LPCWSTR,
		phkResult: PHKEY,
	) -> LSTATUS ---

	RegOpenKeyExW :: proc(
		hKey: HKEY,
		lpSubKey: LPCWSTR,
		ulOptions: DWORD,
		samDesired: REGSAM,
		phkResult: PHKEY,
	) -> LSTATUS ---

	RegCloseKey :: proc(
		hKey: HKEY,
	) -> LSTATUS ---

	RegGetValueW :: proc(
		hkey: HKEY,
		lpSubKey: LPCWSTR,
		lpValue: LPCWSTR,
		dwFlags: DWORD,
		pdwType: LPDWORD,
		pvData: PVOID,
		pcbData: LPDWORD,
	) -> LSTATUS ---

	RegSetValueExW :: proc(
		hKey: HKEY,
		lpValueName: LPCWSTR,
		Reserved: DWORD,
		dwType: DWORD,
		lpData: ^BYTE,
		cbData: DWORD,
	) -> LSTATUS ---

	RegSetKeyValueW :: proc(
		hKey: HKEY,
		lpSubKey: LPCWSTR,
		lpValueName: LPCWSTR,
		dwType: DWORD,
		lpData: LPCVOID,
		cbData: DWORD,
	) -> LSTATUS ---

	GetFileSecurityW :: proc(
		lpFileName: LPCWSTR,
		RequestedInformation: SECURITY_INFORMATION,
		pSecurityDescriptor: PSECURITY_DESCRIPTOR,
		nLength: DWORD,
		lpnLengthNeeded: LPDWORD,
	) -> BOOL ---

	DuplicateToken :: proc(
		ExistingTokenHandle: HANDLE,
		ImpersonationLevel: SECURITY_IMPERSONATION_LEVEL,
		DuplicateTokenHandle: PHANDLE,
	) -> BOOL ---

	MapGenericMask :: proc(
		AccessMask: PDWORD,
		GenericMapping: PGENERIC_MAPPING,
	) ---

	AccessCheck :: proc(
		pSecurityDescriptor: PSECURITY_DESCRIPTOR,
		ClientToken: HANDLE,
		DesiredAccess: DWORD,
		GenericMapping: PGENERIC_MAPPING,
		PrivilegeSet: PPRIVILEGE_SET,
		PrivilegeSetLength: LPDWORD,
		GrantedAccess: LPDWORD,
		AccessStatus: LPBOOL,
	) -> BOOL ---
}
