package os2

import "base:runtime"
import "core:strings"
import "core:time"

Fstat_Callback :: proc(f: ^File, allocator: runtime.Allocator) -> (File_Info, Error)

/*
	`File_Info` describes a file and is returned from `stat`, `fstat`, and `lstat`.
*/
File_Info :: struct {
	fullpath:          string,        // fullpath of the file
	name:              string,        // base name of the file

	inode:             u128,          // might be zero if cannot be determined
	size:              i64 `fmt:"M"`, // length in bytes for regular files; system-dependent for other file types
	mode:              Permissions,   // file permission flags
	type:              File_Type,

	creation_time:     time.Time,
	modification_time: time.Time,
	access_time:       time.Time,
}

@(require_results)
file_info_clone :: proc(fi: File_Info, allocator: runtime.Allocator) -> (cloned: File_Info, err: runtime.Allocator_Error) {
	cloned = fi
	cloned.fullpath = strings.clone(fi.fullpath, allocator) or_return
	_, cloned.name = split_path(cloned.fullpath)
	return
}

file_info_slice_delete :: proc(infos: []File_Info, allocator: runtime.Allocator) {
	#reverse for info in infos {
		file_info_delete(info, allocator)
	}
	delete(infos, allocator)
}

file_info_delete :: proc(fi: File_Info, allocator: runtime.Allocator) {
	delete(fi.fullpath, allocator)
}

@(require_results)
fstat :: proc(f: ^File, allocator: runtime.Allocator) -> (File_Info, Error) {
	if f == nil {
		return {}, nil
	} else if f.fstat != nil {
		return f->fstat(allocator)
	}
	return {}, .Invalid_Callback
}

/*
	`stat` returns a `File_Info` describing the named file from the file system.
	The resulting `File_Info` must be deleted with `file_info_delete`.
*/
@(require_results)
stat :: proc(name: string, allocator: runtime.Allocator) -> (File_Info, Error) {
	return _stat(name, allocator)
}

lstat :: stat_do_not_follow_links

/*
	Returns a `File_Info` describing the named file from the file system.
	If the file is a symbolic link, the `File_Info` returns describes the symbolic link,
	rather than following the link.
	The resulting `File_Info` must be deleted with `file_info_delete`.
*/
@(require_results)
stat_do_not_follow_links :: proc(name: string, allocator: runtime.Allocator) -> (File_Info, Error) {
	return _lstat(name, allocator)
}


/*
	Returns true if two `File_Info`s are equivalent.
*/
@(require_results)
same_file :: proc(fi1, fi2: File_Info) -> bool {
	return _same_file(fi1, fi2)
}


last_write_time         :: modification_time
last_write_time_by_name :: modification_time_by_path

/*
	Returns the modification time of the file `f`.
	The resolution of the timestamp is system-dependent.
*/
@(require_results)
modification_time :: proc(f: ^File) -> (time.Time, Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	fi, err := fstat(f, temp_allocator)
	return fi.modification_time, err
}

/*
	Returns the modification time of the named file `path`.
	The resolution of the timestamp is system-dependent.
*/
@(require_results)
modification_time_by_path :: proc(path: string) -> (time.Time, Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})
	fi, err := stat(path, temp_allocator)
	return fi.modification_time, err
}
