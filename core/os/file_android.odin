#+private
#+build linux:android
package os

import "base:runtime"
import "core:io"
import "core:strings"
import "core:sys/android"

// Paths under this are the APK's assets, read through `core:sys/android`'s `asset_*`.
ASSET_ROOT :: "/android_asset"

// An asset file or directory. Its `fd` is -1, so the Linux procedures given its `File_Impl` see no descriptor.
Asset_Impl :: struct {
	using impl: File_Impl,
	stream:     io.Stream, // A file's `AAsset`. A directory has none.
	names:      []string,  // A directory's entries.
}

// Whether `name` is `/android_asset` or under it. A relative path never is.
_is_asset_name :: proc(name: string) -> bool {
	return strings.has_prefix(name, ASSET_ROOT) &&
	       (len(name) == len(ASSET_ROOT) || name[len(ASSET_ROOT)] == '/')
}

_is_asset_file :: proc(f: ^File) -> bool {
	return f != nil && f.stream.procedure == _asset_stream_proc
}

_open_asset :: proc(name: string, flags: File_Flags) -> (f: ^File, err: Error) {
	if flags & {.Write, .Append, .Create, .Trunc} != nil {
		return nil, _get_platform_error(.EROFS)
	}
	if android.asset_manager() == nil {
		return nil, .Unsupported
	}

	allocator := file_allocator()
	fullpath := clean_path(name, allocator) or_return
	defer if err != nil {
		delete(fullpath, allocator)
	}

	// `..` can leave the asset directory.
	if !_is_asset_name(fullpath) {
		return nil, .Not_Exist
	}
	path := strings.trim_prefix(fullpath[len(ASSET_ROOT):], "/")

	impl := new(Asset_Impl, allocator) or_return
	impl.file.impl = impl
	impl.file.stream = {data = impl, procedure = _asset_stream_proc}
	impl.name = fullpath
	impl.fd = -1
	impl.allocator = allocator

	if asset := android.asset_open(path); asset != nil {
		impl.stream = android.asset_to_stream(asset)
		return &impl.file, nil
	}

	// An APK holds no empty directories, so only the top can be one.
	names, ok := android.asset_list(path, allocator)
	if !ok || (path != "" && len(names) == 0) {
		android.asset_list_delete(names, allocator)
		free(impl, allocator)
		return nil, .Not_Exist
	}
	impl.names = names
	return &impl.file, nil
}

_stat_asset :: proc(name: string, allocator: runtime.Allocator) -> (fi: File_Info, err: Error) {
	f := _open_asset(name, {.Read}) or_return
	defer close(f)
	return fstat(f, allocator)
}

_asset_stream_proc :: proc(stream_data: rawptr, mode: File_Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From, allocator: runtime.Allocator) -> (n: i64, err: Error) {
	f := (^Asset_Impl)(stream_data)
	switch mode {
	case .Read, .Read_At, .Seek, .Size:
		if f.stream.procedure == nil {
			return 0, _get_platform_error(.EISDIR)
		}
		io_err: io.Error
		n, io_err = f.stream.procedure(f.stream.data, transmute(io.Stream_Mode)mode, p, offset, whence)
		return n, io_err
	case .Write, .Write_At:
		return 0, _get_platform_error(.EBADF)
	case .Flush:
		return 0, nil
	case .Close, .Destroy:
		if f.stream.procedure != nil {
			io.close(f.stream)
		}
		a := f.allocator
		android.asset_list_delete(f.names, a)
		delete(f.name, a)
		free(f, a)
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Read_At, .Seek, .Size, .Flush, .Close, .Destroy, .Query})
	case .Fstat:
		if len(p) < size_of(File_Info) {
			return 0, .Short_Buffer
		}
		fi: File_Info
		fi.fullpath = strings.clone(f.name, allocator) or_return
		_, fi.name = split_path(fi.fullpath)
		if f.stream.procedure != nil {
			fi.type = .Regular
			fi.mode = Permissions_Read_All
			fi.size, _ = io.size(f.stream)
		} else {
			fi.type = .Directory
			fi.mode = Permissions_Read_All + Permissions_Execute_All
		}
		runtime.mem_copy_non_overlapping(raw_data(p), &fi, size_of(fi))
		return 0, nil
	}
	return 0, .Unsupported
}

_init_asset_directory_iterator :: proc(it: ^Read_Directory_Iterator, f: ^File) {
	if (^Asset_Impl)(f.impl).stream.procedure != nil {
		read_directory_iterator_set_error(it, name(f), .Invalid_Dir)
	}
}

_read_asset_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	dir := (^Asset_Impl)(it.f.impl)
	for it.index < len(dir.names) {
		index = it.index
		it.index += 1

		file_info_delete(it.impl.prev_fi, file_allocator())
		it.impl.prev_fi = {}

		temp_allocator := TEMP_ALLOCATOR_GUARD({})
		path, _ := concatenate({dir.name, "/", dir.names[index]}, temp_allocator)
		err: Error
		if fi, err = _stat_asset(path, file_allocator()); err != nil {
			read_directory_iterator_set_error(it, path, err)
			continue
		}
		it.impl.prev_fi = fi
		return fi, index, true
	}
	return
}
