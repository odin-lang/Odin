package main

import "core:intrinsics"

SUS_exit :: uintptr(60)
SUS_write ::uintptr(1)
STDOUT_FILENO :: int(1)

sus_write :: proc "contextless" (fd: int, buf: cstring, size: uint) -> int {
    return int(intrinsics.syscall(
        SUS_write,
        cast(uintptr) fd,
        cast(uintptr) cast(rawptr) buf,
        cast(uintptr) size
    ))
}

@(link_name = "sussy_baka")
sus_exit :: proc "contextless" (code: $T)->! {
    intrinsics.syscall(SUS_exit, uintptr(code))
    unreachable()
}

sus :: proc {sus_write, sus_exit}

@(link_name="_start", export) _start :: proc "c" ()->! {
    str :: cstring("Hello, world!\n")
    sus_write(STDOUT_FILENO, str, uint(14));
    sus_exit(0)
}
