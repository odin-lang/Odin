#+build !wasi
package filepath

import "core:os"
import "core:slice"

// Walk_Proc is the type of the procedure called for each file or directory visited by 'walk'
// The 'path' parameter contains the parameter to walk as a prefix (this is the same as info.fullpath except on 'root')
// The 'info' parameter is the os.File_Info for the named path
//
// If there was a problem walking to the file or directory named by path, the incoming error will describe the problem
// and the procedure can decide how to handle that error (and walk will not descend into that directory)
// In the case of an error, the info argument will be 0
// If an error is returned, processing stops
// The sole exception is if 'skip_dir' is returned as true:
// 	when 'skip_dir' is invoked on a directory. 'walk' skips directory contents
// 	when 'skip_dir' is invoked on a non-directory. 'walk' skips the remaining files in the containing directory
Walk_Proc :: #type proc(info: os.File_Info, in_err: os.Error, user_data: rawptr) -> (err: os.Error, skip_dir: bool)

// walk walks the file tree rooted at 'root', calling 'walk_proc' for each file or directory in the tree, including 'root'
// All errors that happen visiting files and directories are filtered by walk_proc
// The files are walked in lexical order to make the output deterministic
// NOTE: Walking large directories can be inefficient due to the lexical sort
// NOTE: walk does not follow symbolic links
// NOTE: os.File_Info uses the 'context.temp_allocator' to allocate, and will delete when it is done
walk :: proc(root: string, walk_proc: Walk_Proc, user_data: rawptr) -> os.Error {
	info, err := os.lstat(root, context.temp_allocator)
	defer os.file_info_delete(info, context.temp_allocator)

	skip_dir: bool
	if err != nil {
		err, skip_dir = walk_proc(info, err, user_data)
	} else {
		err, skip_dir = _walk(info, walk_proc, user_data)
	}
	return nil if skip_dir else err
}


@(private)
_walk :: proc(info: os.File_Info, walk_proc: Walk_Proc, user_data: rawptr) -> (err: os.Error, skip_dir: bool) {
	if !info.is_dir {
		if info.fullpath == "" && info.name == "" {
			// ignore empty things
			return
		}
		return walk_proc(info, nil, user_data)
	}

	fis: []os.File_Info
	err1: os.Error
	fis, err = read_dir(info.fullpath, context.temp_allocator)
	defer os.file_info_slice_delete(fis, context.temp_allocator)

	err1, skip_dir = walk_proc(info, err, user_data)
	if err != nil || err1 != nil || skip_dir {
		err = err1
		return
	}

	for fi in fis {
		err, skip_dir = _walk(fi, walk_proc, user_data)
		if err != nil || skip_dir {
			if !fi.is_dir || !skip_dir {
				return
			}
		}
	}

	return
}

@(private)
read_dir :: proc(dir_name: string, allocator := context.temp_allocator) -> (fis: []os.File_Info, err: os.Error) {
	f := os.open(dir_name, os.O_RDONLY) or_return
	defer os.close(f)
	fis = os.read_dir(f, -1, allocator) or_return
	slice.sort_by(fis, proc(a, b: os.File_Info) -> bool {
		return a.name < b.name
	})
	return
}
