package path

foreign import libc "system:c"

import "core:os"
import "core:strings"


MAX :: 4096; // @note(bp): apparently PATH_MAX is bullshit

SEPARATOR        :: '/';
SEPARATOR_STRING :: "/";


@(private)
null_term :: proc(str: string) -> string {
    for c, i in str {
        if c == '\x00' {
            return str[:i];
        }
    }
    return str;
}


full :: proc(path: string, allocator := context.allocator) -> string {
    cpath := strings.clone_to_cstring(path, context.temp_allocator);
    
    foreign libc {
        realpath :: proc(path: cstring, resolved_path: ^u8) -> cstring ---;
    }

    buf := make([dynamic]u8, MAX, MAX, allocator);

    cstr := realpath(cpath, &buf[0]);
    for cstr == nil && os.get_last_error() == int(os.ENAMETOOLONG) {
        resize(&buf, len(buf) + MAX);
        cstr = realpath(cpath, &buf[0]);
    }

    return null_term(string(buf[:]));
}

current :: proc(allocator := context.allocator) -> string {
    foreign libc{
        getcwd :: proc(buf: ^u8, size: int) -> cstring ---;
    }

    buf := make([dynamic]u8, MAX, MAX, allocator);

    cstr := getcwd(&buf[0], len(buf));
    for cstr == nil && os.get_last_error() == int(os.ENAMETOOLONG) {
        resize(&buf, len(buf) + MAX);
        cstr = getcwd(&buf[0], len(buf));
    }

    return null_term(string(buf[:]));
}


exists :: proc(path: string) -> bool {
    if _, err := os.stat(path); err != os.ERROR_NONE {
        return true;
    }
    return false;
}

is_dir :: proc(path: string) -> bool {
    if stat, err := os.stat(path); err == os.ERROR_NONE {
        return os.S_ISDIR(stat.mode);
    }
    return false;
}

is_file :: proc(path: string) -> bool {
    if stat, err := os.stat(path); err == os.ERROR_NONE {
        return os.S_ISREG(stat.mode);
    }
    return false;
}
