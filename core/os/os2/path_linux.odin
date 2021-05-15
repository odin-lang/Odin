//+private
package os2

import "core:sys/unix"
import "core:strings"

_Path_Separator      :: '/';
_Path_List_Separator :: ';';

// NOTE(rytc): the mkdir (and open()) permissions are masked with the processes
// permissions, so the resulting access permissions may end up different.
@private _Default_Perm :: 00755;

_is_path_separator :: proc(c: byte) -> bool {
    return c == _Path_Separator;
}

_mkdir :: proc(name: string, perm: File_Mode) -> Maybe(Path_Error) {
    unix.mkdir(name, _Default_Perm);
	return nil; 
}

// NOTE(rytc): is this procedure expect to make all sub directories
// or a list of directories separated by _Path_List_Separator?
_mkdir_all :: proc(path: string, perm: File_Mode) -> Maybe(Path_Error) {
    dirs := strings.split(path, ";");
    for d in dirs {
        unix.mkdir(d, _Default_Perm);
    }
    return nil;
}

_remove_all :: proc(path: string) -> Maybe(Path_Error) {
    dirs := strings.split(path, ";");
    for d in dirs {
        unix.rmdir(d);
    }
	return nil;
}

_getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
    buff := make([]byte, MAX_PATH_LENGTH, allocator);
    result := unix.getcwd(buff);
    if result == nil {
        return "", Error.Permission_Denied;
    }
	return strings.string_from_ptr(raw_data(buff), len(buff)), nil;
}

_setwd :: proc(dir: string) -> (err: Error) {
    error := unix.chdir(dir);
	return _unix_errno(error);
}

_is_relative_path :: proc(name: string) -> bool {
    if name[0] == '/' do return false;
    return true;
}

_get_handle_path :: proc(fd: Handle, allocator := context.allocator) -> string {
    path := make([]byte, MAX_PATH_LENGTH, allocator);
    fd_path := fmt.tprintf("/proc/self/fd/%v", transmute(uint)fd);
    unix.readlink(fd_path, path[:]);
    fullpath := strings.string_from_ptr(raw_data(path), len(path)); 
    
    return fullpath;
}

_get_handle_name :: proc(fd: Handle) -> string {
    path := make([]byte, MAX_PATH_LENGTH, context.temp_allocator);
    fd_path := fmt.tprintf("/proc/self/fd/%v", transmute(uint)fd);
    unix.readlink(fd_path, path[:]);
    fullpath := strings.string_from_ptr(raw_data(path), len(path)); 
    
    filename_break := strings.last_index_byte(fullpath, '/') + 1;
    name := fmt.aprintf(fullpath[filename_break:]);

    return name;
}
