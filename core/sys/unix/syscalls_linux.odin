package unix

import "core:slice"
import "core:strings"

open :: proc(name: string, flags: int, mode: u32) -> int {
    @static syscall_open :i32 =  2;

    result := asm(i32, ^u8, int, u32) -> int {
        "syscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_open, strings.ptr_from_string(name), flags, mode);

    return result;
}

close :: proc(fd: int) -> int {
    @static syscall_close :i32 =  3;

    result := asm(i32, int) -> int {
        "syscall",
        "={eax},{eax}{ebx}",
    }(syscall_close, fd);

    return result;
}

lseek :: proc(fd: int, offset: i64, whence: uint) -> i64 {
    @static syscall_lseek :i32 =  8;

    result := asm(i32, int, i64, uint) -> i64 {
        "syscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_lseek, fd, offset, whence);

    return result;
}

read :: proc(fd: int, p: []byte) -> int {
    @static syscall_read :i32=  8;

    result := asm(i32, int, ^u8, int) -> int {
        "syscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_read, fd, &p[0], len(p));

    return result;
}

write :: proc(fd: int, p: []byte) -> int {
    @static syscall_write :i32= 1;
    
    result := asm(i32, int, ^u8, int) -> int {
        "syscall",
        "={eax},{eax}{ebx}{ecx}{edx}",
    }(syscall_write, fd, &p[0], len(p));

    return result;
}

fsync :: proc(fd: int) -> int {
    @static syscall_fsync :i32= 74; 
    
    result := asm(i32, int) -> int {
        "syscall",
        "={eax},{eax}{ebx}",
    }(syscall_fsync, fd);

    return result;
}

fstat :: proc(fd: int, stat: uintptr) -> int {
    @static syscall_fstat :i32= 5;

    error := asm(i32, uintptr) -> int {
        "syscall",
        "={eax},{eax}{ebx}",
    }(syscall_fstat, stat);

    return error;
}
