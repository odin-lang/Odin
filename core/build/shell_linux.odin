package build

import "core:sys/linux"
import "core:intrinsics"
import "core:runtime"

_exec :: proc(file: string, args: []string) -> int {
    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
    parent := linux.getpid()
    pid := linux.fork()
    assert(pid != -1, "Failed to fork.")
    if pid > 0 {
        status: u32
        linux.waitpid(pid, &status, 0)
        assert(linux.WIFEXITED(status), "Process didn't exit correctly.")
        return cast(int)linux.WEXITSTATUS(status)
    } else {
        c_args := make([dynamic]cstring, context.temp_allocator)
        env := []cstring{nil}
        for arg in args {
            append(&c_args, strings.clone_to_cstring(arg, context.temp_allocator))
        }
        append(&c_args, nil)
        c_file := strings.clone_to_cstring(file, context.temp_allocator)
        linux.syscall(linux.SYS_execve, rawptr(c_file), raw_data(c_args), raw_data(env))
        panic("All hell broke lose. We aren't here. We were never here.")
    }
    return -1
}