package build

import "core:sys/windows"
import "core:runtime"
import "core:strings"

_exec :: proc(file: string, args: []string) -> int {
    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    si: windows.STARTUPINFOW
    pi: windows.PROCESS_INFORMATION
    args_joined := strings.join(args, " ", context.temp_allocator)
    file_and_args := strings.join({file, args_joined}, " ", context.temp_allocator)
    cmd_w := windows.utf8_to_wstring(file_and_args, context.temp_allocator)
    ok := windows.CreateProcessW(
        nil,
        cmd_w,
        nil,
        nil,
        false,
        0,
        nil,
        nil,
        &si,
        &pi,
    )
    defer if ok {
        windows.CloseHandle(pi.hProcess)
        windows.CloseHandle(pi.hThread)
    }
    assert(cast(bool)ok, "Process creation failed.")
    windows.WaitForSingleObject(pi.hProcess, windows.INFINITE)
    ret: windows.DWORD
    exit_ok := windows.GetExitCodeProcess(pi.hProcess, &ret)
    assert(cast(bool)exit_ok, "Process exit code retrieval failed.")
    return cast(int)ret
}