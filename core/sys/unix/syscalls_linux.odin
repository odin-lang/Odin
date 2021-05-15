package unix

import "core:strings"

open :: proc(name: string, flags: int, mode: u32) -> int {
    @static syscall_open :i32 = 2;

    result := asm(i32, ^u8, int, u32) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_open, strings.ptr_from_string(name), flags, mode);

    return result;
}

close :: proc(fd: int) -> int {
    @static syscall_close :i32 = 3;

    result := asm(i32, int) -> int {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall_close, fd);

    return result;
}

lseek :: proc(fd: int, offset: i64, whence: uint) -> i64 {
    @static syscall_lseek :i32 = 8;

    result := asm(i32, int, i64, uint) -> i64 {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_lseek, fd, offset, whence);

    return result;
}

read :: proc"contextless"(fd: int, p: []byte) -> int {
    @static syscall_read :i32= 0;

    result := asm(i32, int, ^u8, int) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_read, fd, raw_data(p), len(p));

    return int(result);
};

write :: proc(fd: int, p: []byte) -> int {
    @static syscall_write :i32= 1;
    
    result := asm(i32, int, ^u8, int) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_write, fd, raw_data(p), len(p));

    return result;
}

fsync :: proc(fd: int) -> int {
    @static syscall_fsync :i32= 74; 
    
    result := asm(i32, int) -> int {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall_fsync, fd);

    return result;
}

fstat :: proc(fd: int, stat: uintptr) -> int {
    @static syscall_fstat :i32= 5;

    result := asm(i32, int, uintptr) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_fstat, fd, stat);

    return result;
}

lstat :: proc(name: string, stat: uintptr) -> int {
    @static syscall_lstat :i32= 6;

    result := asm(i32, ^u8, uintptr) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_lstat, strings.ptr_from_string(name), stat);

    return result;
}

readlink :: proc(name: string, p: []byte) -> int {
    @static syscall_readlink :i32= 89;

    result := asm(i32, ^u8, ^u8, int) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_readlink, strings.ptr_from_string(name), raw_data(p), len(p));

    return result;
}

mkdir :: proc(name: string, mode: u16) -> int {
    @static syscall_mkdir :i32= 83;

    result := asm(i32, ^u8, u16) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_mkdir, strings.ptr_from_string(name), mode);

    return result;
}

getcwd :: proc(p: []byte) -> ^u8 {
    @static syscall_getcwd :i32= 79;

    result := asm(i32, ^u8, int) -> ^u8 {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_getcwd, &p[0], len(p));

    return result;
}

rmdir :: proc(name: string) -> int {
    @static syscall_rmdir :i32= 84;

    result := asm(i32, ^u8) -> int {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall_rmdir, strings.ptr_from_string(name));

    return result;
}

chmod :: proc(name: string, perm: u16) -> int {
    @static syscall_chmod :i32= 90;

    result := asm(i32, ^u8, u16) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_chmod, strings.ptr_from_string(name), perm);

    return result;
}

umask :: proc(mask: int) -> int {
    @static syscall_umask :i32= 95;

    result := asm(i32, int) -> int {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall_umask, mask);

    return result;
}

chdir :: proc(name: string) -> int {
    @static syscall_chdir :i32= 80;

    result := asm(i32, ^u8) -> int {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall_chdir, strings.ptr_from_string(name));

    return result;
}

truncate :: proc(name: string, len: i64) -> int {
    @static syscall_truncate :i32= 76;

    result := asm(i32, ^u8, i64) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_truncate, strings.ptr_from_string(name), len);

    return result;
}

rename :: proc(old_name: string, new_name: string) -> int {
    @static syscall_rename :i32= 82;

    result := asm(i32, ^u8, ^u8) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_rename, strings.ptr_from_string(old_name), strings.ptr_from_string(new_name));

    return result;
}

link :: proc(old_name: string, new_name: string) -> int {
    @static syscall_link :i32= 86;

    result := asm(i32, ^u8, ^u8) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_link, strings.ptr_from_string(old_name), strings.ptr_from_string(new_name));

    return result;
}

symlink :: proc(old_name: string, new_name: string) -> int {
    @static syscall_symlink :i32= 88;

    result := asm(i32, ^u8, ^u8) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_symlink, strings.ptr_from_string(old_name), strings.ptr_from_string(new_name));

    return result;
}

chown :: proc(name: string, uid, gid: int) -> int {
    @static syscall_chown :i32= 92;

    result := asm(i32, ^u8, int, int) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_chown, strings.ptr_from_string(name), uid, gid);

    return result;
}

lchown :: proc(name: string, uid, gid: int) -> int {
    @static syscall_lchown :i32= 94;

    result := asm(i32, ^u8, int, int) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall_lchown, strings.ptr_from_string(name), uid, gid);

    return result;
}

setxattr :: proc(path, attr_name: string, value: uintptr, size: uint, flags: int) -> int {
    @static syscall_setxattr :i32= 188;

    result := asm(i32, ^u8, ^u8, uintptr, uint, int) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8}",
    }(syscall_setxattr, strings.ptr_from_string(path), strings.ptr_from_string(attr_name), value, size, flags);

    return result;
}

utime :: proc(name: string, atime, mtime: i64) -> int {
    @static syscall_utime :i32= 132;

    utimbuf :: struct {
        atime: i64,
        mtime: i64,
    };

    values := utimbuf{atime, mtime};

    result := asm(i32, ^u8, uintptr) -> int {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall_utime, strings.ptr_from_string(name), uintptr(&values));

    return result;

}
