package sys_windows

import "core:c"

c_char :: c.char;
c_int :: c.int;
c_uint :: c.uint;
c_long :: c.long;
c_longlong :: c.longlong;
c_ulong :: c.ulong;
c_ushort :: c.ushort;
size_t :: c.size_t;
wchar_t :: c.wchar_t;

DWORD :: c_ulong;
HANDLE :: distinct LPVOID;
HINSTANCE :: HANDLE;
HMODULE :: distinct HINSTANCE;
HRESULT :: distinct LONG;
BOOL :: distinct b32;
BYTE :: distinct u8;
BOOLEAN :: distinct b8;
GROUP :: distinct c_uint;
LARGE_INTEGER :: distinct c_longlong;
LONG :: c_long;
UINT :: c_uint;
WCHAR :: wchar_t;
USHORT :: c_ushort;
SIZE_T :: uint;
WORD :: u16;
CHAR :: c_char;
ULONG_PTR :: uint;
DWORD_PTR :: ULONG_PTR;
ULONG :: c_ulong;
UCHAR :: BYTE;

wstring :: ^WCHAR;

LPBOOL :: ^BOOL;
LPBYTE :: ^BYTE;
LPCSTR :: cstring;
LPCWSTR :: wstring;
LPDWORD :: ^DWORD;
LPHANDLE :: ^HANDLE;
LPOVERLAPPED :: ^OVERLAPPED;
LPPROCESS_INFORMATION :: ^PROCESS_INFORMATION;
LPSECURITY_ATTRIBUTES :: ^SECURITY_ATTRIBUTES;
LPSTARTUPINFO :: ^STARTUPINFO;
PVOID  :: rawptr;
LPVOID :: rawptr;
LPWCH :: ^WCHAR;
LPWIN32_FIND_DATAW :: ^WIN32_FIND_DATAW;
LPWSADATA :: ^WSADATA;
LPWSAPROTOCOL_INFO :: ^WSAPROTOCOL_INFO;
LPSTR :: ^CHAR;
LPWSTR :: ^WCHAR;
LPFILETIME :: ^FILETIME;
LPWSABUF :: ^WSABUF;
LPWSAOVERLAPPED :: distinct rawptr;
LPWSAOVERLAPPED_COMPLETION_ROUTINE :: distinct rawptr;
LPCVOID :: rawptr;

PCONDITION_VARIABLE :: ^CONDITION_VARIABLE;
PLARGE_INTEGER :: ^LARGE_INTEGER;
PSRWLOCK :: ^SRWLOCK;

SOCKET :: distinct uintptr; // TODO
socklen_t :: c_int;
ADDRESS_FAMILY :: USHORT;

TRUE  :: BOOL(true);
FALSE :: BOOL(false);

FILE_ATTRIBUTE_READONLY: DWORD : 0x00000001;
FILE_ATTRIBUTE_HIDDEN: DWORD : 0x00000002;
FILE_ATTRIBUTE_SYSTEM: DWORD : 0x00000004;
FILE_ATTRIBUTE_DIRECTORY: DWORD : 0x00000010;
FILE_ATTRIBUTE_ARCHIVE: DWORD : 0x00000020;
FILE_ATTRIBUTE_DEVICE: DWORD : 0x00000040;
FILE_ATTRIBUTE_NORMAL: DWORD : 0x00000080;
FILE_ATTRIBUTE_TEMPORARY: DWORD : 0x00000100;
FILE_ATTRIBUTE_SPARSE_FILE: DWORD : 0x00000200;
FILE_ATTRIBUTE_REPARSE_Point: DWORD : 0x00000400;
FILE_ATTRIBUTE_COMPRESSED: DWORD : 0x00000800;
FILE_ATTRIBUTE_OFFLINE: DWORD : 0x00001000;
FILE_ATTRIBUTE_NOT_CONTENT_INDEXED: DWORD : 0x00002000;
FILE_ATTRIBUTE_ENCRYPTED: DWORD : 0x00004000;

FILE_SHARE_READ: DWORD : 0x00000001;
FILE_SHARE_WRITE: DWORD : 0x00000002;
FILE_SHARE_DELETE: DWORD : 0x00000004;
FILE_GENERIC_ALL: DWORD : 0x10000000;
FILE_GENERIC_EXECUTE: DWORD : 0x20000000;
FILE_GENERIC_READ: DWORD : 0x80000000;

CREATE_NEW: DWORD : 1;
CREATE_ALWAYS: DWORD : 2;
OPEN_ALWAYS: DWORD : 4;
OPEN_EXISTING: DWORD : 3;
TRUNCATE_EXISTING: DWORD : 5;



FILE_WRITE_DATA: DWORD : 0x00000002;
FILE_APPEND_DATA: DWORD : 0x00000004;
FILE_WRITE_EA: DWORD : 0x00000010;
FILE_WRITE_ATTRIBUTES: DWORD : 0x00000100;
READ_CONTROL: DWORD : 0x00020000;
SYNCHRONIZE: DWORD : 0x00100000;
GENERIC_READ: DWORD : 0x80000000;
GENERIC_WRITE: DWORD : 0x40000000;
STANDARD_RIGHTS_WRITE: DWORD : READ_CONTROL;
FILE_GENERIC_WRITE: DWORD : STANDARD_RIGHTS_WRITE
	| FILE_WRITE_DATA
	| FILE_WRITE_ATTRIBUTES
	| FILE_WRITE_EA
	| FILE_APPEND_DATA
	| SYNCHRONIZE;

FILE_FLAG_OPEN_REPARSE_POINT: DWORD : 0x00200000;
FILE_FLAG_BACKUP_SEMANTICS: DWORD : 0x02000000;
SECURITY_SQOS_PRESENT: DWORD : 0x00100000;

FIONBIO: c_ulong : 0x8004667e;


GET_FILEEX_INFO_LEVELS :: distinct i32;
GetFileExInfoStandard: GET_FILEEX_INFO_LEVELS : 0;
GetFileExMaxInfoLevel: GET_FILEEX_INFO_LEVELS : 1;


WIN32_FIND_DATAW :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
	dwReserved0: DWORD,
	dwReserved1: DWORD,
	cFileName: [260]wchar_t, // #define MAX_PATH 260
	cAlternateFileName: [14]wchar_t,
}

WSA_FLAG_OVERLAPPED: DWORD : 0x01;
WSA_FLAG_NO_HANDLE_INHERIT: DWORD : 0x80;

WSADESCRIPTION_LEN :: 256;
WSASYS_STATUS_LEN :: 128;
WSAPROTOCOL_LEN: DWORD : 255;
INVALID_SOCKET :: ~SOCKET(0);

WSAEACCES: c_int : 10013;
WSAEINVAL: c_int : 10022;
WSAEWOULDBLOCK: c_int : 10035;
WSAEPROTOTYPE: c_int : 10041;
WSAEADDRINUSE: c_int : 10048;
WSAEADDRNOTAVAIL: c_int : 10049;
WSAECONNABORTED: c_int : 10053;
WSAECONNRESET: c_int : 10054;
WSAENOTCONN: c_int : 10057;
WSAESHUTDOWN: c_int : 10058;
WSAETIMEDOUT: c_int : 10060;
WSAECONNREFUSED: c_int : 10061;

MAX_PROTOCOL_CHAIN: DWORD : 7;

MAXIMUM_REPARSE_DATA_BUFFER_SIZE :: 16 * 1024;
FSCTL_GET_REPARSE_POINT: DWORD : 0x900a8;
IO_REPARSE_TAG_SYMLINK: DWORD : 0xa000000c;
IO_REPARSE_TAG_MOUNT_POINT: DWORD : 0xa0000003;
SYMLINK_FLAG_RELATIVE: DWORD : 0x00000001;
FSCTL_SET_REPARSE_POINT: DWORD : 0x900a4;

SYMBOLIC_LINK_FLAG_DIRECTORY: DWORD : 0x1;
SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE: DWORD : 0x2;

STD_INPUT_HANDLE:  DWORD : ~DWORD(0) -10 + 1;
STD_OUTPUT_HANDLE: DWORD : ~DWORD(0) -11 + 1;
STD_ERROR_HANDLE:  DWORD : ~DWORD(0) -12 + 1;

PROGRESS_CONTINUE: DWORD : 0;

ERROR_FILE_NOT_FOUND: DWORD : 2;
ERROR_PATH_NOT_FOUND: DWORD : 3;
ERROR_ACCESS_DENIED: DWORD : 5;
ERROR_INVALID_HANDLE: DWORD : 6;
ERROR_NO_MORE_FILES: DWORD : 18;
ERROR_HANDLE_EOF: DWORD : 38;
ERROR_FILE_EXISTS: DWORD : 80;
ERROR_INVALID_PARAMETER: DWORD : 87;
ERROR_BROKEN_PIPE: DWORD : 109;
ERROR_CALL_NOT_IMPLEMENTED: DWORD : 120;
ERROR_INSUFFICIENT_BUFFER: DWORD : 122;
ERROR_ALREADY_EXISTS: DWORD : 183;
ERROR_NO_DATA: DWORD : 232;
ERROR_ENVVAR_NOT_FOUND: DWORD : 203;
ERROR_OPERATION_ABORTED: DWORD : 995;
ERROR_IO_PENDING: DWORD : 997;
ERROR_TIMEOUT: DWORD : 0x5B4;

E_NOTIMPL :: HRESULT(-0x7fff_bfff); // 0x8000_4001

INVALID_HANDLE :: HANDLE(~uintptr(0));

FACILITY_NT_BIT: DWORD : 0x1000_0000;

FORMAT_MESSAGE_FROM_SYSTEM: DWORD : 0x00001000;
FORMAT_MESSAGE_FROM_HMODULE: DWORD : 0x00000800;
FORMAT_MESSAGE_IGNORE_INSERTS: DWORD : 0x00000200;

TLS_OUT_OF_INDEXES: DWORD : 0xFFFFFFFF;

DLL_THREAD_DETACH: DWORD : 3;
DLL_PROCESS_DETACH: DWORD : 0;
CREATE_SUSPENDED :: DWORD(0x00000004);

INFINITE :: ~DWORD(0);

DUPLICATE_SAME_ACCESS: DWORD : 0x00000002;

CONDITION_VARIABLE_INIT :: CONDITION_VARIABLE{};
SRWLOCK_INIT :: SRWLOCK{};

DETACHED_PROCESS: DWORD : 0x00000008;
CREATE_NEW_PROCESS_GROUP: DWORD : 0x00000200;
CREATE_UNICODE_ENVIRONMENT: DWORD : 0x00000400;
STARTF_USESTDHANDLES: DWORD : 0x00000100;

AF_INET: c_int : 2;
AF_INET6: c_int : 23;
SD_BOTH: c_int : 2;
SD_RECEIVE: c_int : 0;
SD_SEND: c_int : 1;
SOCK_DGRAM: c_int : 2;
SOCK_STREAM: c_int : 1;
SOL_SOCKET: c_int : 0xffff;
SO_RCVTIMEO: c_int : 0x1006;
SO_SNDTIMEO: c_int : 0x1005;
SO_REUSEADDR: c_int : 0x0004;
IPPROTO_IP: c_int : 0;
IPPROTO_TCP: c_int : 6;
IPPROTO_IPV6: c_int : 41;
TCP_NODELAY: c_int : 0x0001;
IP_TTL: c_int : 4;
IPV6_V6ONLY: c_int : 27;
SO_ERROR: c_int : 0x1007;
SO_BROADCAST: c_int : 0x0020;
IP_MULTICAST_LOOP: c_int : 11;
IPV6_MULTICAST_LOOP: c_int : 11;
IP_MULTICAST_TTL: c_int : 10;
IP_ADD_MEMBERSHIP: c_int : 12;
IP_DROP_MEMBERSHIP: c_int : 13;
IPV6_ADD_MEMBERSHIP: c_int : 12;
IPV6_DROP_MEMBERSHIP: c_int : 13;
MSG_PEEK: c_int : 0x2;

ip_mreq :: struct {
	imr_multiaddr: in_addr,
	imr_interface: in_addr,
}

ipv6_mreq :: struct {
	ipv6mr_multiaddr: in6_addr,
	ipv6mr_interface: c_uint,
}

VOLUME_NAME_DOS: DWORD : 0x0;
MOVEFILE_REPLACE_EXISTING: DWORD : 1;

FILE_BEGIN: DWORD : 0;
FILE_CURRENT: DWORD : 1;
FILE_END: DWORD : 2;

WAIT_OBJECT_0: DWORD : 0x00000000;
WAIT_TIMEOUT: DWORD : 258;
WAIT_FAILED: DWORD : 0xFFFFFFFF;

PIPE_ACCESS_INBOUND: DWORD : 0x00000001;
PIPE_ACCESS_OUTBOUND: DWORD : 0x00000002;
FILE_FLAG_FIRST_PIPE_INSTANCE: DWORD : 0x00080000;
FILE_FLAG_OVERLAPPED: DWORD : 0x40000000;
PIPE_WAIT: DWORD : 0x00000000;
PIPE_TYPE_BYTE: DWORD : 0x00000000;
PIPE_REJECT_REMOTE_CLIENTS: DWORD : 0x00000008;
PIPE_READMODE_BYTE: DWORD : 0x00000000;

FD_SETSIZE :: 64;

STACK_SIZE_PARAM_IS_A_RESERVATION: DWORD : 0x00010000;

INVALID_SET_FILE_POINTER :: ~DWORD(0);

HEAP_ZERO_MEMORY: DWORD : 0x00000008;

HANDLE_FLAG_INHERIT: DWORD : 0x00000001;
HANDLE_FLAG_PROTECT_FROM_CLOSE :: 0x00000002;

TOKEN_READ: DWORD : 0x20008;

CP_ACP        :: 0;     // default to ANSI code page
CP_OEMCP      :: 1;     // default to OEM  code page
CP_MACCP      :: 2;     // default to MAC  code page
CP_THREAD_ACP :: 3;     // current thread's ANSI code page
CP_SYMBOL     :: 42;    // SYMBOL translations
CP_UTF7       :: 65000; // UTF-7 translation
CP_UTF8       :: 65001; // UTF-8 translation

MB_ERR_INVALID_CHARS :: 8;
WC_ERR_INVALID_CHARS :: 128;


MAX_PATH :: 0x00000104;
MAX_PATH_WIDE :: 0x8000;

INVALID_FILE_ATTRIBUTES  :: -1;

FILE_TYPE_DISK :: 0x0001;
FILE_TYPE_CHAR :: 0x0002;
FILE_TYPE_PIPE :: 0x0003;


when size_of(uintptr) == 4 {
	WSADATA :: struct {
		wVersion: WORD,
		wHighVersion: WORD,
		szDescription: [WSADESCRIPTION_LEN + 1]u8,
		szSystemStatus: [WSASYS_STATUS_LEN + 1]u8,
		iMaxSockets: u16,
		iMaxUdpDg: u16,
		lpVendorInfo: ^u8,
	}
} else when size_of(uintptr) == 8 {
	WSADATA :: struct {
		wVersion: WORD,
		wHighVersion: WORD,
		iMaxSockets: u16,
		iMaxUdpDg: u16,
		lpVendorInfo: ^u8,
		szDescription: [WSADESCRIPTION_LEN + 1]u8,
		szSystemStatus: [WSASYS_STATUS_LEN + 1]u8,
	}
}

WSABUF :: struct {
	len: ULONG,
	buf: ^CHAR,
}

WSAPROTOCOL_INFO :: struct {
	dwServiceFlags1: DWORD,
	dwServiceFlags2: DWORD,
	dwServiceFlags3: DWORD,
	dwServiceFlags4: DWORD,
	dwProviderFlags: DWORD,
	ProviderId: GUID,
	dwCatalogEntryId: DWORD,
	ProtocolChain: WSAPROTOCOLCHAIN,
	iVersion: c_int,
	iAddressFamily: c_int,
	iMaxSockAddr: c_int,
	iMinSockAddr: c_int,
	iSocketType: c_int,
	iProtocol: c_int,
	iProtocolMaxOffset: c_int,
	iNetworkByteOrder: c_int,
	iSecurityScheme: c_int,
	dwMessageSize: DWORD,
	dwProviderReserved: DWORD,
	szProtocol: [WSAPROTOCOL_LEN + 1]u16,
}

WIN32_FILE_ATTRIBUTE_DATA :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
}

FILE_INFO_BY_HANDLE_CLASS :: enum c_int {
	FileBasicInfo = 0,
	FileStandardInfo = 1,
	FileNameInfo = 2,
	FileRenameInfo = 3,
	FileDispositionInfo = 4,
	FileAllocationInfo = 5,
	FileEndOfFileInfo = 6,
	FileStreamInfo = 7,
	FileCompressionInfo = 8,
	FileAttributeTagInfo = 9,
	FileIdBothDirectoryInfo = 10,        // 0xA
	FileIdBothDirectoryRestartInfo = 11, // 0xB
	FileIoPriorityHintInfo = 12,         // 0xC
	FileRemoteProtocolInfo = 13,         // 0xD
	FileFullDirectoryInfo = 14,          // 0xE
	FileFullDirectoryRestartInfo = 15,   // 0xF
	FileStorageInfo = 16,                // 0x10
	FileAlignmentInfo = 17,              // 0x11
	FileIdInfo = 18,                     // 0x12
	FileIdExtdDirectoryInfo = 19,        // 0x13
	FileIdExtdDirectoryRestartInfo = 20, // 0x14
	MaximumFileInfoByHandlesClass,
}

FILE_BASIC_INFO :: struct {
	CreationTime: LARGE_INTEGER,
	LastAccessTime: LARGE_INTEGER,
	LastWriteTime: LARGE_INTEGER,
	ChangeTime: LARGE_INTEGER,
	FileAttributes: DWORD,
}

FILE_END_OF_FILE_INFO :: struct {
	EndOfFile: LARGE_INTEGER,
}

REPARSE_DATA_BUFFER :: struct {
	ReparseTag: c_uint,
	ReparseDataLength: c_ushort,
	Reserved: c_ushort,
	rest: [0]byte,
}

SYMBOLIC_LINK_REPARSE_BUFFER :: struct {
	SubstituteNameOffset: c_ushort,
	SubstituteNameLength: c_ushort,
	PrintNameOffset: c_ushort,
	PrintNameLength: c_ushort,
	Flags: c_ulong,
	PathBuffer: WCHAR,
}

MOUNT_POINT_REPARSE_BUFFER :: struct {
	SubstituteNameOffset: c_ushort,
	SubstituteNameLength: c_ushort,
	PrintNameOffset: c_ushort,
	PrintNameLength: c_ushort,
	PathBuffer: WCHAR,
}

LPPROGRESS_ROUTINE :: #type proc "stdcall" (
	TotalFileSize: LARGE_INTEGER,
	TotalBytesTransferred: LARGE_INTEGER,
	StreamSize: LARGE_INTEGER,
	StreamBytesTransferred: LARGE_INTEGER,
	dwStreamNumber: DWORD,
	dwCallbackReason: DWORD,
	hSourceFile: HANDLE,
	hDestinationFile: HANDLE,
	lpData: LPVOID,
) -> DWORD;

CONDITION_VARIABLE :: struct {
	ptr: LPVOID,
}
SRWLOCK :: struct {
	ptr: LPVOID,
}
CRITICAL_SECTION :: struct {
	CriticalSectionDebug: LPVOID,
	LockCount: LONG,
	RecursionCount: LONG,
	OwningThread: HANDLE,
	LockSemaphore: HANDLE,
	SpinCount: ULONG_PTR,
}

REPARSE_MOUNTPOINT_DATA_BUFFER :: struct {
	ReparseTag: DWORD,
	ReparseDataLength: DWORD,
	Reserved: WORD,
	ReparseTargetLength: WORD,
	ReparseTargetMaximumLength: WORD,
	Reserved1: WORD,
	ReparseTarget: WCHAR,
}

GUID :: struct {
	Data1: DWORD,
	Data2: WORD,
	Data3: WORD,
	Data4: [8]BYTE,
}

WSAPROTOCOLCHAIN :: struct {
	ChainLen: c_int,
	ChainEntries: [MAX_PROTOCOL_CHAIN]DWORD,
}

SECURITY_ATTRIBUTES :: struct {
	nLength: DWORD,
	lpSecurityDescriptor: LPVOID,
	bInheritHandle: BOOL,
}

PROCESS_INFORMATION :: struct {
	hProcess: HANDLE,
	hThread: HANDLE,
	dwProcessId: DWORD,
	dwThreadId: DWORD,
}

STARTUPINFO :: struct {
	cb: DWORD,
	lpReserved: LPWSTR,
	lpDesktop: LPWSTR,
	lpTitle: LPWSTR,
	dwX: DWORD,
	dwY: DWORD,
	dwXSize: DWORD,
	dwYSize: DWORD,
	dwXCountChars: DWORD,
	dwYCountCharts: DWORD,
	dwFillAttribute: DWORD,
	dwFlags: DWORD,
	wShowWindow: WORD,
	cbReserved2: WORD,
	lpReserved2: LPBYTE,
	hStdInput: HANDLE,
	hStdOutput: HANDLE,
	hStdError: HANDLE,
}

SOCKADDR :: struct {
	sa_family: ADDRESS_FAMILY,
	sa_data: [14]CHAR,
}

FILETIME :: struct {
	dwLowDateTime: DWORD,
	dwHighDateTime: DWORD,
}

OVERLAPPED :: struct {
	Internal: ^c_ulong,
	InternalHigh: ^c_ulong,
	Offset: DWORD,
	OffsetHigh: DWORD,
	hEvent: HANDLE,
}

ADDRESS_MODE :: enum c_int {
	AddrMode1616,
	AddrMode1632,
	AddrModeReal,
	AddrModeFlat,
}

SOCKADDR_STORAGE_LH :: struct {
	ss_family: ADDRESS_FAMILY,
	__ss_pad1: [6]CHAR,
	__ss_align: i64,
	__ss_pad2: [112]CHAR,
}

ADDRINFOA :: struct {
	ai_flags: c_int,
	ai_family: c_int,
	ai_socktype: c_int,
	ai_protocol: c_int,
	ai_addrlen: size_t,
	ai_canonname: ^c_char,
	ai_addr: ^SOCKADDR,
	ai_next: ^ADDRINFOA,
}

sockaddr_in :: struct {
	sin_family: ADDRESS_FAMILY,
	sin_port: USHORT,
	sin_addr: in_addr,
	sin_zero: [8]CHAR,
}

sockaddr_in6 :: struct {
	sin6_family: ADDRESS_FAMILY,
	sin6_port: USHORT,
	sin6_flowinfo: c_ulong,
	sin6_addr: in6_addr,
	sin6_scope_id: c_ulong,
}

in_addr :: struct {
	s_addr: u32,
}

in6_addr :: struct {
	s6_addr: [16]u8,
}

EXCEPTION_DISPOSITION :: enum c_int {
	ExceptionContinueExecution,
	ExceptionContinueSearch,
	ExceptionNestedException,
	ExceptionCollidedUnwind,
}

fd_set :: struct {
	fd_count: c_uint,
	fd_array: [FD_SETSIZE]SOCKET,
}

timeval :: struct {
	tv_sec: c_long,
	tv_usec: c_long,
}


EXCEPTION_CONTINUE_SEARCH: LONG : 0;
EXCEPTION_CONTINUE_EXECUTION: LONG : -1;
EXCEPTION_EXECUTE_HANDLER: LONG : 1;

EXCEPTION_MAXIMUM_PARAMETERS :: 15;

EXCEPTION_DATATYPE_MISALIGNMENT     :: 0x80000002;
EXCEPTION_ACCESS_VIOLATION          :: 0xC0000005;
EXCEPTION_ILLEGAL_INSTRUCTION       :: 0xC000001D;
EXCEPTION_ARRAY_BOUNDS_EXCEEDED     :: 0xC000008C;
EXCEPTION_INT_DIVIDE_BY_ZERO        :: 0xC0000094;
EXCEPTION_INT_OVERFLOW              :: 0xC0000095;
EXCEPTION_STACK_OVERFLOW            :: 0xC00000FD;
STATUS_PRIVILEGED_INSTRUCTION       :: 0xC0000096;


EXCEPTION_RECORD :: struct {
	ExceptionCode: DWORD,
	ExceptionFlags: DWORD,
	ExceptionRecord: ^EXCEPTION_RECORD,
	ExceptionAddress: LPVOID,
	NumberParameters: DWORD,
	ExceptionInformation: [EXCEPTION_MAXIMUM_PARAMETERS]LPVOID,
}

CONTEXT :: struct{}; // TODO(bill)

EXCEPTION_POINTERS :: struct {
	ExceptionRecord: ^EXCEPTION_RECORD,
	ContextRecord: ^CONTEXT,
}

PVECTORED_EXCEPTION_HANDLER :: #type proc "stdcall" (ExceptionInfo: ^EXCEPTION_POINTERS) -> LONG;

CONSOLE_READCONSOLE_CONTROL :: struct {
	nLength: ULONG,
	nInitialChars: ULONG,
	dwCtrlWakeupMask: ULONG,
	dwControlKeyState: ULONG,
}

PCONSOLE_READCONSOLE_CONTROL :: ^CONSOLE_READCONSOLE_CONTROL;

BY_HANDLE_FILE_INFORMATION :: struct {
	dwFileAttributes: DWORD,
	ftCreationTime: FILETIME,
	ftLastAccessTime: FILETIME,
	ftLastWriteTime: FILETIME,
	dwVolumeSerialNumber: DWORD,
	nFileSizeHigh: DWORD,
	nFileSizeLow: DWORD,
	nNumberOfLinks: DWORD,
	nFileIndexHigh: DWORD,
	nFileIndexLow: DWORD,
}

LPBY_HANDLE_FILE_INFORMATION :: ^BY_HANDLE_FILE_INFORMATION;

FILE_STANDARD_INFO :: struct {
	AllocationSize: LARGE_INTEGER,
	EndOfFile: LARGE_INTEGER,
	NumberOfLinks: DWORD,
	DeletePending: BOOLEAN,
	Directory: BOOLEAN,
}



// https://docs.microsoft.com/en-gb/windows/win32/api/sysinfoapi/ns-sysinfoapi-system_info
SYSTEM_INFO :: struct {
	using _: struct #raw_union {
		dwOemID: DWORD,
		using _: struct #raw_union {
			wProcessorArchitecture: WORD,
			wReserved: WORD, // reserved
		},
	},
	dwPageSize: DWORD,
	lpMinimumApplicationAddress: LPVOID,
	lpMaximumApplicationAddress: LPVOID,
	dwActiveProcessorMask: DWORD_PTR,
	dwNumberOfProcessors: DWORD,
	dwProcessorType: DWORD,
	dwAllocationGranularity: DWORD,
	wProcessorLevel: WORD,
	wProcessorRevision: WORD,
}

// https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/ns-wdm-_osversioninfoexw
OSVERSIONINFOEXW :: struct {
  os_version_info_size: ULONG,
  major_version:        ULONG,
  minor_version:        ULONG,
  build_number:         ULONG,
  platform_id :         ULONG,
  service_pack_string:  [128]WCHAR,
  service_pack_major:   USHORT,
  service_pack_minor:   USHORT,
  suite_mask:           USHORT,
  product_type:         UCHAR,
  reserved:             UCHAR,
}
