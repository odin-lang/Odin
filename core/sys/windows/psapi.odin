#+build windows
package sys_windows

foreign import psapi "system:Psapi.lib"

@(default_calling_convention="system")
foreign psapi {
    EnumProcessModules :: proc(hProcess: HANDLE, lphModule: ^HMODULE, cb: DWORD, lpcbNeeded: LPDWORD) -> BOOL ---
}