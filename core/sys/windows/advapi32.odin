package sys_windows

foreign import advapi32 "system:Advapi32.lib"

HCRYPTPROV :: distinct HANDLE;

@(default_calling_convention="stdcall")
foreign advapi32 {
	@(link_name = "SystemFunction036")
	RtlGenRandom :: proc(RandomBuffer: ^u8, RandomBufferLength: ULONG) -> BOOLEAN ---
	OpenProcessToken :: proc(ProcessHandle: HANDLE,
	                         DesiredAccess: DWORD,
	                         TokenHandle: ^HANDLE) -> BOOL ---
}

@(default_calling_convention="cdecl")
foreign advapi32 {
	CryptAcquireContextW :: proc(phProv: ^HCRYPTPROV,
	                             szContainer, szProvider: wstring,
	                             dwProvType, dwFlags: DWORD) -> BOOL ---
	CryptReleaseContext :: proc(hProv: HCRYPTPROV, dwFlags: DWORD) -> BOOL ---
	CryptGenRandom :: proc(hProv: HCRYPTPROV, dwLen: DWORD, pbBuffer: ^BYTE) -> BOOL ---
}



PROV_RSA_FULL :: 1;
PROV_RSA_SIG  :: 2;
PROV_DSS      :: 3;
PROV_FORTEZZA :: 4;
PROV_MS_MAIL  :: 5;
PROV_SSL      :: 6;
PROV_STT_MER  :: 7;
PROV_STT_ACQ  :: 8;
PROV_STT_BRND :: 9;
PROV_STT_ROOT :: 10;
PROV_STT_ISS  :: 11;

CRYPT_VERIFYCONTEXT  :: 0xf0000000;
CRYPT_NEWKEYSET      :: 8;
CRYPT_DELETEKEYSET   :: 16;
CRYPT_MACHINE_KEYSET :: 32;
CRYPT_EXPORTABLE     :: 1;
CRYPT_USER_PROTECTED :: 2;
CRYPT_CREATE_SALT    :: 4;
CRYPT_UPDATE_KEY     :: 8;
