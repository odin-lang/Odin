//+private
package os2

import "core:sys/unix"

// TOOD(rytc): Make sure this is accurate
@private
Unix_Stat :: struct {
    dev: u64,
    ino: u64,
    nlink: u64,
    mode: u32,
    uid: u32,
    gid: u32,
    pad_: u32,
    rdev: u64,
    size: i64,
    blksize: i64,
    blocks: i64,
    atime: u64,
    atime_ns: u64,
    mtime: u64,
    mtime_ns: u64,
    ctime: u64,
    ctime_ns: u64,
    pad: [3]i64,
};


// TODO(rytc): Fill out whole File_Info struct, error handling
_fstat :: proc(fd: Handle, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
    stat : Unix_Stat;
    err := unix.fstat(transmute(int)fd, uintptr(&stat));

    result : File_Info;
    result.size = stat.size;

    return result, nil;
}

// TODO(rytc): stat syscall
_stat :: proc(name: string, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
    result : File_Info;
    return result, nil;
}

// TODO(rytc): temporary stub
_lstat :: proc(name: string, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
	result : File_Info;
    return result, nil;
}

// TODO(rytc): temporary stub
_same_file :: proc(fi1, fi2: File_Info) -> bool {
    return false;
}

