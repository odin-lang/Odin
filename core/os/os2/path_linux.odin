//+private
package os2

import "core:sys/unix"
import "core:strings"

_Path_Separator      :: '/';
_Path_List_Separator :: ';';

// TODO(rytc): Need to investigate this, not giving the expected permissions
@private _Default_Perm: u16: 00755;

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
	return nil;
}

_getwd :: proc(allocator := context.allocator) -> (dir: string, err: Error) {
    // TODO(rytc): don't hardcode max path length
    buff := make([]byte, 4094, allocator);
    result := unix.getcwd(buff);
    if result == nil {
        return "", Error.Permission_Denied;
    }
	return strings.string_from_ptr(raw_data(buff), len(buff)), nil;
}

_setwd :: proc(dir: string) -> (err: Error) {
	return nil;
}

