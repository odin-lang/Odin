package unix

import "core:strings"

/*
 * This would be nice, have to find some way to generate the ASM code with variable arguments though
 *
@private
_syscall :: proc(syscall: i32, $T: typeid, args: ..any) -> T {
    result := asm(i32, type_of(..args)) -> T {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall, args[:]);

    return result;
}
*/

@private
_syscall1 :: #force_inline proc(syscall: i32, $T: typeid, a: $A) -> T {
    result := asm(i32, A) -> T {
        "syscall",
        "={rax},{rax},{rdi}",
    }(syscall, a);

    return result;
}

@private
_syscall2 :: #force_inline proc(syscall: i32, $T: typeid, a: $A, b: $B) -> T {
    result := asm(i32, A, B) -> T {
        "syscall",
        "={rax},{rax},{rdi},{rsi}",
    }(syscall, a, b);

    return result;
}

@private 
_syscall3 :: proc(syscall: i32, $T: typeid, a: $A, b: $B, c: $C) -> T  {
    result := asm(i32, A, B, C) -> T {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx}",
    }(syscall, a, b, c);

    return result;
}

@private 
_syscall5 :: proc(syscall: i32, $T: typeid, a: $A, b: $B, c: $C, d: $D, e: $E) -> T  {
    result := asm(i32, A, B, C, D, E) -> T {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx},{r10},{r8}",
    }(syscall, a, b, c, d, e);
    
    return result;
}

@private 
_syscall6 :: proc(syscall: i32, $T: typeid, a: $A, b: $B, c: $C, d: $D, e: $E, f: $F) -> T  {
    result := asm(i32, A, B, C, D, E, F) -> T {
        "syscall",
        "={rax},{rax},{rdi},{rsi},{rdx},{r10}{r8}{r9}",
    }(syscall, a, b, c, d, e, f);
    
    return result;
}

open :: proc(name: string, flags: int, mode: u32) -> int  {
    SYSCALL_OPEN :: 2;
    name_ptr := strings.ptr_from_string(name);
    handle_or_error := _syscall3(SYSCALL_OPEN, int, name_ptr, flags, mode);
    return handle_or_error;
}

close :: proc(fd: int) -> int {
    SYSCALL_CLOSE  :: 3;
    result := _syscall1(SYSCALL_CLOSE, int, fd);
    return result;
}

lseek :: proc(fd: int, offset: i64, whence: uint) -> i64 {
    SYSCALL_LSEEK :: 8;
    result := _syscall3(SYSCALL_LSEEK, i64, fd, offset, whence);
    return result;
}

read :: proc(fd: int, p: []byte) -> int {
    SYSCALL_READ :: 0;
    result := _syscall3(SYSCALL_READ, int, fd, raw_data(p), len(p));
    return result;
};

write :: proc(fd: int, p: []byte) -> int {
    SYSCALL_WRITE :: 1;
    result := _syscall3(SYSCALL_WRITE, int, fd, raw_data(p), len(p));
    return result;
}

fsync :: proc(fd: int) -> int {
    SYSCALL_FSYNC :: 74; 
    result := _syscall1(SYSCALL_FSYNC, int, fd); 
    return result;
}

fstat :: proc(fd: int, stat: uintptr) -> int {
    SYSCALL_FSTAT :: 5;
    result := _syscall2(SYSCALL_FSTAT, int, fd, stat);
    return result;
}

lstat :: proc(name: string, stat: uintptr) -> int {
    SYSCALL_LSTAT :: 6;
    result := _syscall2(SYSCALL_LSTAT, int, strings.ptr_from_string(name), stat);
    return result;
}

readlink :: proc(name: string, p: []byte) -> int {
    SYSCALL_READLINK :: 89;
    result := _syscall3(SYSCALL_READLINK, int, strings.ptr_from_string(name), raw_data(p), len(p));
    return result;
}

mkdir :: proc(name: string, mode: u16) -> int {
    SYSCALL_MKDIR :: 83;
    result := _syscall2(SYSCALL_MKDIR, int, strings.ptr_from_string(name), mode);
    return result;
}

getcwd :: proc(p: []byte) -> ^u8 {
    SYSCALL_GETCWD :: 79;
    result := _syscall2(SYSCALL_GETCWD, ^u8, raw_data(p), len(p));
    return result;
}

rmdir :: proc(name: string) -> int {
    SYSCALL_RMDIR :: 84;
    result := _syscall1(SYSCALL_RMDIR, int, strings.ptr_from_string(name));
    return result;
}

chmod :: proc(name: string, perm: u16) -> int {
    SYSCALL_CHMOD :: 90;
    result := _syscall2(SYSCALL_CHMOD, int, strings.ptr_from_string(name), perm);
    return result;
}

umask :: proc(mask: int) -> int {
    SYSCALL_UMASK :: 95;
    result := _syscall1(SYSCALL_UMASK, int, mask);
    return result;
}

chdir :: proc(name: string) -> int {
    SYSCALL_CHDIR :: 80;
    result := _syscall1(SYSCALL_CHDIR, int, strings.ptr_from_string(name));
    return result;
}

truncate :: proc(name: string, len: i64) -> int {
    SYSCALL_TRUNCATE :: 76;
    result := _syscall2(SYSCALL_TRUNCATE, int, strings.ptr_from_string(name), len);
    return result;
}

rename :: proc(old_name: string, new_name: string) -> int {
    SYSCALL_RENAME :: 82;
    result := _syscall2(SYSCALL_RENAME, int, strings.ptr_from_string(old_name), strings.ptr_from_string(new_name));
    return result;
}

link :: proc(old_name: string, new_name: string) -> int {
    SYSCALL_LINK :: 86;
    result := _syscall2(SYSCALL_LINK, int, strings.ptr_from_string(old_name), strings.ptr_from_string(new_name));
    return result;
}

symlink :: proc(old_name: string, new_name: string) -> int {
    SYSCALL_SYMLINK :: 88;
    result := _syscall2(SYSCALL_SYMLINK, int, strings.ptr_from_string(old_name), strings.ptr_from_string(new_name));
    return result;
}

chown :: proc(name: string, uid, gid: int) -> int {
    SYSCALL_CHOWN :: 92;
    result := _syscall3(SYSCALL_CHOWN, int, strings.ptr_from_string(name), uid, gid);
    return result;
}

lchown :: proc(name: string, uid, gid: int) -> int {
    SYSCALL_LCHOWN :: 94;
    result := _syscall3(SYSCALL_LCHOWN, int, strings.ptr_from_string(name), uid, gid);
    return result;
}

setxattr :: proc(path, attr_name: string, value: uintptr, size: uint, flags: int) -> int {
    SYSCALL_SETXATTR :: 188;
    result := _syscall5(SYSCALL_SETXATTR, int, strings.ptr_from_string(path), strings.ptr_from_string(attr_name), value, size, flags);
    return result;
}

utime :: proc(name: string, atime, mtime: i64) -> int {
    SYSCALL_UTIME :: 132;

    utimbuf :: struct {
        atime: i64,
        mtime: i64,
    };
    values := utimbuf{atime, mtime};

    result := _syscall2(SYSCALL_UTIME, int, strings.ptr_from_string(name), uintptr(&values));
    return result;

}

// NOTE(rytc): Ehh, multiple return values are too nice
// to ignore just to do things the C-way in odin :\
// Not sure how much the original API should be followed in 
// this case
pipe :: proc() -> (fd: [2]int, err: int) {
    SYSCALL_PIPE :: 22;
    handles : [2]int;
    result := _syscall1(SYSCALL_PIPE, int, &handles[0]);
    return handles, result;
}

pipe2 :: proc(flags: int) -> (fd: [2]int, err: int) {
    SYSCALL_PIPE2 :: 293;
    handles : [2]int;
    result := _syscall2(SYSCALL_PIPE2, int, &handles[0], flags);
    return handles, result;
}

mmap :: proc(addr, len, prot, flags, fd, offset: uint) -> uintptr {
    SYSCALL_MMAP :: 9;

    handles : [2]int;

    result := _syscall6(SYSCALL_MMAP, u64, addr, len, prot, flags, fd, offset);

    // NOTE(rytc): these syscalls returns the error code in a negative number
    // to be able to easily translate it into a pointer on success, we just 
    // follow c's underflow rule for uints to figure out what would be an 
    // error code /invalid ptr
    // This magic number is based on the possible error codes that mmap could 
    // return
    if result >= max(u64) - 76 {
        return 0; 
    }

    return transmute(uintptr)result;
}

munmap :: proc(addr: rawptr, len: uint) -> int {
    SYSCALL_MUNMAP :: 11;
    handles : [2]int;
    result := _syscall2(SYSCALL_MUNMAP, int, addr, len);
    return result;
}

mremap :: proc(addr, old_len, new_len, flags, new_addr: uint) -> uintptr {
    SYSCALL_MREMAP :: 163;
    handles : [2]int;
    result := _syscall5(SYSCALL_MREMAP, u64, addr, old_len, new_len, flags, new_addr);

    // NOTE(rytc): See note in mmap
    if result >= max(u64) - 76 {
        return 0;
    }

    return transmute(uintptr)result;
}


