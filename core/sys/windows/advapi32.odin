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
