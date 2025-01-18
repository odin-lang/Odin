#+private
package os2

import "base:intrinsics"
import "core:sys/wasm/wasi"

Read_Directory_Iterator_Impl :: struct {
	fullpath: [dynamic]byte,
	buf:      []byte,
	off:      int,
	idx:      int,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	fimpl := (^File_Impl)(it.f.impl)

	buf := it.impl.buf[it.impl.off:]

	index = it.impl.idx
	it.impl.idx += 1

	for {
		if len(buf) < size_of(wasi.dirent_t) {
			return
		}

		entry := intrinsics.unaligned_load((^wasi.dirent_t)(raw_data(buf)))
		buf    = buf[size_of(wasi.dirent_t):]

		if len(buf) < int(entry.d_namlen) {
			// shouldn't be possible.
			return
		}

		name := string(buf[:entry.d_namlen])
		buf = buf[entry.d_namlen:]
		it.impl.off += size_of(wasi.dirent_t) + int(entry.d_namlen)

		if name == "." || name == ".." {
			continue
		}

		n := len(fimpl.name)+1
		if alloc_err := non_zero_resize(&it.impl.fullpath, n+len(name)); alloc_err != nil {
			// Can't really tell caller we had an error, sad.
			return
		}
		copy(it.impl.fullpath[n:], name)

		stat, err := wasi.path_filestat_get(__fd(it.f), {}, name)
		if err != nil {
			// Can't stat, fill what we have from dirent.
			stat = {
				ino      = entry.d_ino,
				filetype = entry.d_type,
			}
		}

		fi = internal_stat(stat, string(it.impl.fullpath[:]))
		ok = true
		return
	}
}

@(require_results)
_read_directory_iterator_create :: proc(f: ^File) -> (iter: Read_Directory_Iterator, err: Error) {
	if f == nil || f.impl == nil {
		err = .Invalid_File
		return
	}

	impl := (^File_Impl)(f.impl)
	iter.f = f

	buf: [dynamic]byte
	buf.allocator = file_allocator()
	defer if err != nil { delete(buf) }

	// NOTE: this is very grug.
	for {
		non_zero_resize(&buf, 512 if len(buf) == 0 else len(buf)*2) or_return

		n, _err := wasi.fd_readdir(__fd(f), buf[:], 0)
		if _err != nil {
			err = _get_platform_error(_err)
			return
		}

		if n < len(buf) {
			non_zero_resize(&buf, n)
			break
		}

		assert(n == len(buf))
	}
	iter.impl.buf = buf[:]

	iter.impl.fullpath = make([dynamic]byte, 0, len(impl.name)+128, file_allocator()) or_return
	append(&iter.impl.fullpath, impl.name)
	append(&iter.impl.fullpath, "/")

	return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	delete(it.impl.buf, file_allocator())
	delete(it.impl.fullpath)
	it^ = {}
}
