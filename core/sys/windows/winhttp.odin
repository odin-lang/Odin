#+build windows
package sys_windows

foreign import winhttp "system:Winhttp.lib"

HINTERNET       :: LPVOID
INTERNET_PORT   :: WORD
INTERNET_SCHEME :: c_int

INTERNET_SCHEME_HTTP  :: 1
INTERNET_SCHEME_HTTPS :: 2
INTERNET_SCHEME_FTP   :: 3
INTERNET_SCHEME_SOCKS :: 4

URL_COMPONENTS :: struct {
	dwStructSize:      DWORD,
	lpszScheme:        LPWSTR,
	dwSchemeLength:    DWORD,
	nScheme:           INTERNET_SCHEME,
	lpszHostName:      LPWSTR,
	dwHostNameLength:  DWORD,
	nPort:             INTERNET_PORT,
	lpszUserName:      LPWSTR,
	dwUserNameLength:  DWORD,
	lpszPassword:      LPWSTR,
	dwPasswordLength:  DWORD,
	lpszUrlPath:       LPWSTR,
	dwUrlPathLength:   DWORD,
	lpszExtraInfo:     LPWSTR,
	dwExtraInfoLength: DWORD,
}
LPURL_COMPONENTS :: ^URL_COMPONENTS

WINHTTP_ACCESS_TYPE_DEFAULT_PROXY   :: 0
WINHTTP_ACCESS_TYPE_NO_PROXY        :: 1
WINHTTP_ACCESS_TYPE_NAMED_PROXY     :: 3
WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY :: 4

WINHTTP_FLAG_SECURE :: 0x00800000

WINHTTP_QUERY_CONTENT_LENGTH :: 5
WINHTTP_QUERY_STATUS_CODE    :: 19
WINHTTP_QUERY_CUSTOM         :: 65535
WINHTTP_QUERY_FLAG_NUMBER    :: 0x20000000

@(default_calling_convention="system")
foreign winhttp {
	WinHttpOpen :: proc(
		pszAgentW: LPCWSTR,
		dwAccessType: DWORD,
		pszProxyW: LPCWSTR,
		pszProxyBypassW: LPCWSTR,
		dwFlags: DWORD,
	) -> HINTERNET ---
	WinHttpCrackUrl :: proc(
		pwszUrl: LPCWSTR,
		dwUrlLength: DWORD,
		dwFlags: DWORD,
		lpUrlComponents: LPURL_COMPONENTS,
	) -> BOOL ---
	WinHttpConnect :: proc(
		hSession: HINTERNET,
		pswzServerName: LPCWSTR,
		nServerPort: INTERNET_PORT,
		dwReserved: DWORD,
	) -> HINTERNET ---
	WinHttpOpenRequest :: proc(
		hConnect: HINTERNET,
		pwszVerb: LPCWSTR,
		pwszObjectName: LPCWSTR,
		pwszVersion: LPCWSTR,
		pwszReferrer: LPCWSTR,
		ppwszAcceptTypes: ^LPCWSTR,
		dwFlags: DWORD,
	) -> HINTERNET ---
	WinHttpSendRequest :: proc(
		hRequest: HINTERNET,
		lpszHeaders: LPCWSTR,
		dwHeadersLength: DWORD,
		lpOptional: LPVOID,
		dwOptionalLength: DWORD,
		dwTotalLength: DWORD,
		dwContext: DWORD_PTR,
	) -> BOOL ---
	WinHttpReceiveResponse :: proc(hRequest: HINTERNET, lpReserved: LPVOID) -> BOOL ---
	WinHttpQueryHeaders :: proc(
		hRequest: HINTERNET,
		dwInfoLevel: DWORD,
		pwszName: LPCWSTR,
		lpBuffer: LPVOID,
		lpdwBufferLength: LPDWORD,
		lpdwIndex: LPDWORD,
	) -> BOOL ---
	WinHttpReadData :: proc(
		hRequest: HINTERNET,
		lpBuffer: LPVOID,
		dwNumberOfBytesToRead: DWORD,
		lpdwNumberOfBytesRead: LPDWORD,
	) -> BOOL ---
	WinHttpCloseHandle :: proc(hInternet: HINTERNET) -> BOOL ---
}
