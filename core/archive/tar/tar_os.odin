#+build !js
package archive_tar

import "core:archive"
import "core:compress"
import "core:os"

// Opens a tar archive from a path, a byte slice or a stream
open :: proc{open_from_path, open_from_bytes, open_from_stream}

// Starts a new tar archive at a path or on a stream
create :: proc{create_from_path, create_from_stream}

/*
Opens a tar archive file, plain or compressed with gzip, bzip2, LZ4, LZMA or XZ

Unlike zip's and 7z's, the file isn't locked.

*Allocates Using Provided Allocator*

Inputs:
- r: The reader; `close` it when done, it is left closed on an error
- path: The archive's path
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)

Returns:
- err: An OS error, an error as from `open_from_stream`, or `nil`
*/
open_from_path :: proc(r: ^Reader, path: string, options := compress.Options{}, allocator := context.allocator) -> (err: Error) {
	f := os.open(path) or_return
	s := os.to_stream(f)
	if err = open_from_stream(r, s, options, allocator); err != nil {
		os.close(f)
		return
	}
	r.file = s
	return
}

/*
Starts a new tar archive at a path

The archive is written to `path` plus `archive.TEMP_SUFFIX`, which `commit` renames over
`path`. An existing archive at `path` is locked meanwhile, except on wasi.

*Allocates Using Provided Allocator*

Inputs:
- tw: The writer; `close` it when done, it is left closed on an error
- path: Where the archive goes
- options: The compression and its level, the header format, and more (default: {})
- allocator: (default: context.allocator)

Returns:
- err: Bad options as for `create_from_stream`, `General_Error.Busy` if another process holds
  the archive, an OS error, or `nil`
*/
create_from_path :: proc(tw: ^Writer, path: string, options: Writer_Options = {}, allocator := context.allocator) -> (err: Error) {
	tw^ = {}
	tw.allocator = allocator
	_check_options(options) or_return
	defer if err != nil {
		close_writer(tw)
	}
	s := archive._disk_create(&tw.disk, path, options.no_sync, allocator) or_return
	return _writer_init(tw, s, options)
}

/*
Adds a directory tree: its directories, regular files and symlinks

Other file types are skipped. With `deterministic`, members go in sorted order.

Inputs:
- tw: An open writer
- dir: The directory to add
- prefix: Prepended to every member path; when set, `dir` itself is added, named `prefix`
  (default: "")

Returns:
- err: The first error, from the walk or from `write_entry_with_info`, or `nil`
*/
write_directory :: proc(tw: ^Writer, dir: string, prefix := "") -> (err: Error) {
	_writer_ready(tw) or_return
	walk: archive.Walk
	defer archive._walk_destroy(&walk)
	archive._walk_create(&walk, dir, prefix, tw.options.deterministic, tw.allocator) or_return
	for entry in archive._walk_next(&walk) {
		_write_walked(tw, entry.name, entry.info) or_return
	}
	return walk.err
}

@(private)
_write_walked :: proc(tw: ^Writer, name: string, info: os.File_Info) -> (err: Error) {
	fi: archive.File_Info
	fi.path              = name
	fi.unix_mode         = transmute(u32)info.mode & archive.UNIX_PERMISSION_MASK
	fi.modification_time = info.modification_time
	#partial switch info.type {
	case .Directory:
		fi.type = .Directory
		return write_entry_with_info(tw, fi, nil)
	case .Symlink:
		target, link_err := os.read_link(info.fullpath, tw.allocator)
		if link_err != nil {
			return link_err
		}
		defer delete(target, tw.allocator)
		fi.type        = .Symlink
		fi.link_target = target
		return write_entry_with_info(tw, fi, nil)
	case .Regular:
		f, open_err := os.open(info.fullpath)
		if open_err != nil {
			return open_err
		}
		defer os.close(f)
		fi.type = .Regular
		fi.size = info.size
		return write_entry_with_info(tw, fi, os.to_reader(f))
	}
	return nil
}
