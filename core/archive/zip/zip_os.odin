#+build !js
package archive_zip

import "core:archive"
import "core:compress"
import "core:os"

// Opens a zip archive from a path, a byte slice or a stream
open :: proc{open_from_path, open_from_bytes, open_from_stream}

// Starts a new zip archive at a path or on a stream
create :: proc{create_from_path, create_from_stream}

// Opens a zip archive at a path or on a stream for changes
update :: proc{update_from_path, update_from_stream}

/*
Opens a zip archive file

The file is share-locked until `close`, except on wasi. After a crashed update, the reader sees
the last committed state, as the update's journal records it.

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- path: The archive's path
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)

Returns:
- err: `General_Error.Busy` while a writer holds the file, an OS error, a `Zip_Error` for a
  malformed archive, or `nil`
*/
open_from_path :: proc(r: ^Reader, path: string, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	s, length, ranges := archive._open_view(path, allocator) or_return
	archive._ranges_delete(ranges, allocator)
	_init(r, options, allocator)
	r.file = s
	defer if err != nil {
		close(r)
	}
	r.store = {stream = s, size = length}
	return _load(r)
}

/*
Starts a new zip archive at a path

The archive is written to `path` plus `archive.TEMP_SUFFIX`, which `commit` renames over
`path`. An existing archive at `path` is locked meanwhile, except on wasi.

*Allocates Using Provided Allocator*

Inputs:
- zw: The writer; `close` it when done, it is left closed on an error
- path: Where the archive goes
- options: The default method, level and password, the archive comment, and more (default: {})
- allocator: (default: context.allocator)

Returns:
- err: Bad options as for `create_from_stream`, `General_Error.Busy` if another process holds
  the archive, an OS error, or `nil`
*/
create_from_path :: proc(zw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	zw^ = {}
	zw.allocator = allocator
	_check_options(options) or_return
	zw.mode = .Create_Path
	defer if err != nil {
		close_writer(zw)
	}
	s := archive._disk_create(&zw.disk, path, options.no_sync, allocator) or_return
	return _writer_init(zw, s, options)
}

/*
Opens a zip archive at a path to append, replace, remove or rename members

Appends happen in place, under a journal that rolls them back if the process dies before
`commit`. A replacement, remove or rename makes `commit` write a new archive and rename it over
the old one. The archive is locked until `close`, except on wasi.

*Allocates Using Provided Allocator*

Inputs:
- zw: The writer; `close` it when done, it is left closed on an error
- path: The archive's path
- options: The defaults for new members, and more; an empty comment keeps the archive's
  (default: {})
- allocator: (default: context.allocator)

Returns:
- err: Bad options as for `create_from_stream`, `General_Error.Busy` if another process holds
  the archive, an OS error, a `Zip_Error` for a malformed archive, or `nil`
*/
update_from_path :: proc(zw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	zw^ = {}
	zw.allocator = allocator
	_check_options(options) or_return
	zw.mode = .Update_Path
	defer if err != nil {
		close_writer(zw)
	}
	s := archive._disk_update(&zw.disk, path, allocator) or_return
	return _update_init(zw, s, options)
}

/*
Adds a directory tree: its directories, regular files and symlinks

Other file types are skipped. With `deterministic`, members go in sorted order.

Inputs:
- zw: An open writer
- dir: The directory to add
- prefix: Prepended to every member path; when set, `dir` itself is added, named `prefix`
  (default: "")
- options: Every member's method, level and password, in place of the writer's, and whether
  they replace the members an archive being updated has at their paths (default: {})

Returns:
- err: The first error, from the walk or from `write_entry_with_info`, or `nil`
*/
write_directory :: proc(zw: ^Writer, dir: string, prefix := "", options: Entry_Options = {}) -> (err: Error) {
	_writer_ready(zw) or_return
	password := archive._entry_password(options.password, zw.password, zw.options.deterministic) or_return
	_check_aes_password(password) or_return
	walk: archive.Walk
	defer archive._walk_destroy(&walk)
	archive._walk_create(&walk, dir, prefix, zw.options.deterministic, zw.allocator) or_return
	for entry in archive._walk_next(&walk) {
		_write_walked(zw, entry.name, entry.info, options) or_return
	}
	return walk.err
}

@(private)
_write_walked :: proc(zw: ^Writer, name: string, info: os.File_Info, options: Entry_Options) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
	fi.modification_time = info.modification_time
	fi.access_time       = info.access_time
	fi.creation_time     = info.creation_time
	#partial switch info.type {
	case .Directory:
		fi.type = .Directory
		return write_entry_with_info(zw, fi, nil, options)
	case .Symlink:
		target, link_err := os.read_link(info.fullpath, zw.allocator)
		if link_err != nil {
			return link_err
		}
		defer delete(target, zw.allocator)
		fi.type        = .Symlink
		fi.link_target = target
		return write_entry_with_info(zw, fi, nil, options)
	case .Regular:
		f, open_err := os.open(info.fullpath)
		if open_err != nil {
			return open_err
		}
		defer os.close(f)
		fi.type = .Regular
		fi.size = info.size
		return write_entry_with_info(zw, fi, os.to_reader(f), options)
	}
	return nil
}

@(private)
_archive_open_path :: proc(a: ^archive.Archive, path: string, options: compress.Options, _: archive.Read_Options) -> (err: Error) {
	r := new(Reader, a.allocator) or_return
	if err = open_from_path(r, path, options, a.allocator); err != nil {
		free(r, a.allocator)
		return
	}
	a.state = r
	return
}
