package sys_windows

foreign import ntdll_lib "system:ntdll.lib"

@(default_calling_convention="std")
foreign ntdll_lib {
    RtlGetVersion :: proc(lpVersionInformation: ^OSVERSIONINFOEXW) -> NTSTATUS ---;
}