#+build windows
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

	GetTokenInformation :: proc (
		TokenHandle: HANDLE,
		TokenInformationClass: TOKEN_INFORMATION_CLASS,
		TokenInformation: LPVOID,
		TokenInformationLength: DWORD,
		ReturnLength: PDWORD,
	) -> BOOL ---

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
		peUse: PSID_NAME_USE,
	) -> BOOL ---

	LookupAccountSidW :: proc (
		lpSystemName: LPCWSTR,
		Sid: PSID,
		Name: LPWSTR,
		cchName: LPDWORD,
		ReferencedDomainName: LPWSTR,
		cchReferencedDomainName: LPDWORD,
		peUse: PSID_NAME_USE,
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

	RegQueryInfoKeyW :: proc(
		hKey: HKEY,
		lpClass: LPWSTR,
		lpcchClass: LPDWORD,
		lpReserved: LPDWORD,
		lpcSubKeys: LPDWORD,
		lpcbMaxSubKeyLen: LPDWORD,
		lpcbMaxClassLen: LPDWORD,
		lpcValues: LPDWORD,
		lpcbMaxValueNameLen: LPDWORD,
		lpcbMaxValueLen: LPDWORD,
		lpcbSecurityDescriptor: LPDWORD,
		lpftLastWriteTime: ^FILETIME,
	) -> LSTATUS ---

	RegEnumKeyExW :: proc(
		hKey: HKEY,
		dwIndex: DWORD,
		lpName: LPWSTR,
		lpcchName: LPDWORD,
		lpReserved: LPDWORD,
		lpClass: LPWSTR,
		lpcchClass: LPDWORD,
		lpftLastWriteTime: ^FILETIME,
	  ) -> LSTATUS ---

	RegEnumValueW :: proc(
		hKey: HKEY,
		dwIndex: DWORD,
		lpValueName: LPWSTR,
		lpcchValueName: LPDWORD,
		lpReserved: LPDWORD,
		lpType: LPDWORD,
		lpData: LPBYTE,
		lpcbData: LPDWORD,
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

PTOKEN_INFORMATION_CLASS :: ^TOKEN_INFORMATION_CLASS
TOKEN_INFORMATION_CLASS :: enum i32 {
	TokenUser = 1,
	TokenGroups,
	TokenPrivileges,
	TokenOwner,
	TokenPrimaryGroup,
	TokenDefaultDacl,
	TokenSource,
	TokenType,
	TokenImpersonationLevel,
	TokenStatistics,
	TokenRestrictedSids,
	TokenSessionId,
	TokenGroupsAndPrivileges,
	TokenSessionReference,
	TokenSandBoxInert,
	TokenAuditPolicy,
	TokenOrigin,
	TokenElevationType,
	TokenLinkedToken,
	TokenElevation,
	TokenHasRestrictions,
	TokenAccessInformation,
	TokenVirtualizationAllowed,
	TokenVirtualizationEnabled,
	TokenIntegrityLevel,
	TokenUIAccess,
	TokenMandatoryPolicy,
	TokenLogonSid,
	TokenIsAppContainer,
	TokenCapabilities,
	TokenAppContainerSid,
	TokenAppContainerNumber,
	TokenUserClaimAttributes,
	TokenDeviceClaimAttributes,
	TokenRestrictedUserClaimAttributes,
	TokenRestrictedDeviceClaimAttributes,
	TokenDeviceGroups,
	TokenRestrictedDeviceGroups,
	TokenSecurityAttributes,
	TokenIsRestricted,
	TokenProcessTrustLevel,
	TokenPrivateNameSpace,
	TokenSingletonAttributes,
	TokenBnoIsolation,
	TokenChildProcessFlags,
	TokenIsLessPrivilegedAppContainer,
	TokenIsSandboxed,
	TokenIsAppSilo,
	TokenLoggingInformation,
	MaxTokenInfoClass,
}

PSID_NAME_USE :: ^SID_NAME_USE
SID_NAME_USE :: enum i32 {
	SidTypeUser = 1,
	SidTypeGroup,
	SidTypeDomain,
	SidTypeAlias,
	SidTypeWellKnownGroup,
	SidTypeDeletedAccount,
	SidTypeInvalid,
	SidTypeUnknown,
	SidTypeComputer,
	SidTypeLabel,
	SidTypeLogonSession,
}

PTOKEN_USER :: ^TOKEN_USER
TOKEN_USER :: struct {
	User: SID_AND_ATTRIBUTES,
}

PSID_AND_ATTRIBUTES :: ^SID_AND_ATTRIBUTES
SID_AND_ATTRIBUTES :: struct {
	Sid: rawptr,
	Attributes: ULONG,
}

PTOKEN_TYPE :: ^TOKEN_TYPE
TOKEN_TYPE :: enum {
	TokenPrimary = 1,
	TokenImpersonation = 2,
}

PTOKEN_STATISTICS :: ^TOKEN_STATISTICS
TOKEN_STATISTICS :: struct {
	TokenId: LUID,
	AuthenticationId: LUID,
	ExpirationTime: LARGE_INTEGER,
	TokenType: TOKEN_TYPE,
	ImpersonationLevel: SECURITY_IMPERSONATION_LEVEL,
	DynamicCharged: DWORD,
	DynamicAvailable: DWORD,
	GroupCount: DWORD,
	PrivilegeCount: DWORD,
	ModifiedId: LUID,
}


TOKEN_SOURCE_LENGTH :: 8
PTOKEN_SOURCE :: ^TOKEN_SOURCE
TOKEN_SOURCE :: struct {
	SourceName: [TOKEN_SOURCE_LENGTH]CHAR,
	SourceIdentifier: LUID,
}


PTOKEN_PRIVILEGES :: ^TOKEN_PRIVILEGES
TOKEN_PRIVILEGES :: struct {
	PrivilegeCount: DWORD,
	Privileges: [0]LUID_AND_ATTRIBUTES,
}

PTOKEN_PRIMARY_GROUP :: ^TOKEN_PRIMARY_GROUP
TOKEN_PRIMARY_GROUP :: struct {
	PrimaryGroup: PSID,
}

PTOKEN_OWNER :: ^TOKEN_OWNER
TOKEN_OWNER :: struct {
	Owner: PSID,
}

PTOKEN_GROUPS_AND_PRIVILEGES :: ^TOKEN_GROUPS_AND_PRIVILEGES
TOKEN_GROUPS_AND_PRIVILEGES :: struct {
	SidCount: DWORD,
	SidLength: DWORD,
	Sids: PSID_AND_ATTRIBUTES,
	RestrictedSidCount: DWORD,
	RestrictedSidLength: DWORD,
	RestrictedSids: PSID_AND_ATTRIBUTES,
	PrivilegeCount: DWORD,
	PrivilegeLength: DWORD,
	Privileges: PLUID_AND_ATTRIBUTES,
	AuthenticationId: LUID,
}

PTOKEN_DEFAULT_DACL :: ^TOKEN_DEFAULT_DACL
TOKEN_DEFAULT_DACL :: struct {
	DefaultDacl: PACL,
}

PACL :: ^ACL
ACL :: struct {
	AclRevision: BYTE,
	Sbz1: BYTE,
	AclSize: WORD,
	AceCount: WORD,
	Sbz2: WORD,
}
