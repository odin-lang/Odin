//+private
package os2

import "core:fmt"
import "core:sys/unix"
import "core:time"
import "core:strings"

// TOOD(rytc): Make sure this is accurate
@private
Unix_Stat :: struct {
    dev:      u64,
    ino:      u64,
    nlink:    u64,
    mode:     u32,
    uid:      u32,
    gid:      u32,
    _pad0:    u32,
    rdev:     u64,
    size:     i64,
    blksize:  i64,
    blocks:   i64,
    atime:    u64,
    atime_ns: u64,
    mtime:    u64,
    mtime_ns: u64,
    ctime:    u64,
    ctime_ns: u64,
    _unused:  [3]i64,
};

S_IFMT:   u32: 00170000;
S_IFSOCK: u32: 0140000;
S_IFLNK:  u32: 0120000;
S_IFREG:  u32: 0100000;
S_IFBLK:  u32: 0060000;
S_IFDIR:  u32: 0040000;
S_IFCHR:  u32: 0020000;
S_IFIFO:  u32: 0010000;

_fstat :: proc(fd: Handle, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
    stat : Unix_Stat;
    err := unix.fstat(transmute(int)fd, uintptr(&stat));
   
    result : File_Info;
    if err < 0 do return result, nil;

    // TODO(rytc): don't hard code "max path"
    // TODO(rytc): Should we force the temp allocator or let the user choose?
    path := make([]byte, 4096, context.temp_allocator);
    //unix.readlink(fmt.tprint("/proc/self/fd/%", transmute(uint)fd), path[:]);
    unix.readlink("/proc/self/fd/3", path[:]);
    
    // TODO(rytc): this is bad. We don't want to return something
    // that was allocated on the temp allocator, because it could
    // potentially be stored.
    fullpath := strings.string_from_ptr(raw_data(path), len(path)); 
    
    // TODO(rytc): don't hardcode the path separator?
    // TODO(rytc): SLOW
    filename_break := strings.last_index_byte(fullpath, '/');
    name := strings.string_from_ptr(&path[filename_break+1], len(fullpath) - filename_break);
    //name := "";

    result.fullpath = fullpath;
    result.name = name;
    result.size = stat.size;
    result.mode = _get_mode(stat.mode);
    result.creation_time = time.unix(i64(stat.mtime), i64(stat.mtime_ns));
    result.modification_time = time.unix(i64(stat.mtime), i64(stat.mtime_ns));
    result.access_time = time.unix(i64(stat.atime), i64(stat.atime_ns));

    if result.mode == File_Mode_Dir {
        result.is_dir = true; 
    } else {
        result.is_dir = false;
    }

    return result, nil;
}

_stat :: proc(name: string, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
    stat : Unix_Stat;
    err := unix.lstat(name, uintptr(&stat));

    result : File_Info;
    if err < 0 do return result,nil;

    //result.fullpath = ""
    result.name = name; 
    result.size = stat.size;
    result.mode = _get_mode(stat.mode);
    result.creation_time = time.unix(i64(stat.mtime), i64(stat.mtime_ns));
    result.modification_time = time.unix(i64(stat.mtime), i64(stat.mtime_ns));
    result.access_time = time.unix(i64(stat.atime), i64(stat.atime_ns));

    if result.mode == File_Mode_Dir {
        result.is_dir = true; 
    } else {
        result.is_dir = false;
    }

    return result, nil;
}

_lstat :: proc(name: string, allocator := context.allocator) -> (File_Info, Maybe(Path_Error)) {
    return _stat(name, allocator);	
}

_same_file :: proc(fi1, fi2: File_Info) -> bool {
    return fi1.fullpath == fi2.fullpath;
}

@private
_get_mode :: proc(mode: u32) -> File_Mode {
    m := mode & S_IFMT;

    switch m {
        case S_IFLNK: return File_Mode_Sym_Link;
        case S_IFDIR: return File_Mode_Dir;
        case S_IFBLK: return File_Mode_Device;
        case S_IFIFO: return File_Mode_Named_Pipe;
        case S_IFCHR: return File_Mode_Char_Device;
    }

    return File_Mode(0);
}
