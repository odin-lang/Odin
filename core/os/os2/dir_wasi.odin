#+private
package os2

import "base:runtime"
import "core:slice"
import "base:intrinsics"
import "core:sys/wasm/wasi"

Read_Directory_Iterator_Impl :: struct {
	fullpath: [dynamic]byte,
	buf:      []byte,
	off:      int,
}

@(require_results)
_read_directory_iterator :: proc(it: ^Read_Directory_Iterator) -> (fi: File_Info, index: int, ok: bool) {
	fimpl := (^File_Impl)(it.f.impl)

	buf := it.impl.buf[it.impl.off:]

	index = it.index
	it.index += 1

	for {
		if len(buf) < size_of(wasi.dirent_t) {
			return
		}

		entry := intrinsics.unaligned_load((^wasi.dirent_t)(raw_data(buf)))
		buf    = buf[size_of(wasi.dirent_t):]

		assert(len(buf) < int(entry.d_namlen))

		name := string(buf[:entry.d_namlen])
		buf = buf[entry.d_namlen:]
		it.impl.off += size_of(wasi.dirent_t) + int(entry.d_namlen)

		if name == "." || name == ".." {
			continue
		}

		n := len(fimpl.name)+1
		if alloc_err := non_zero_resize(&it.impl.fullpath, n+len(name)); alloc_err != nil {
			read_directory_iterator_set_error(it, name, alloc_err)
			ok = true
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
			read_directory_iterator_set_error(it, string(it.impl.fullpath[:]), _get_platform_error(err))
		}

		fi = internal_stat(stat, string(it.impl.fullpath[:]))
		ok = true
		return
	}
}

_read_directory_iterator_init :: proc(it: ^Read_Directory_Iterator, f: ^File) {
	// NOTE: Allow calling `init` to target a new directory with the same iterator.
	it.impl.off = 0

	if f == nil || f.impl == nil {
		read_directory_iterator_set_error(it, "", .Invalid_File)
		return
	}

	impl := (^File_Impl)(f.impl)

	buf: [dynamic]byte
	// NOTE: Allow calling `init` to target a new directory with the same iterator.
	if it.impl.buf != nil {
		buf = slice.into_dynamic(it.impl.buf)
	}
	buf.allocator = file_allocator()

	defer if it.err.err != nil { delete(buf) }

	for {
		if err := non_zero_resize(&buf, 512 if len(buf) == 0 else len(buf)*2); err != nil {
			read_directory_iterator_set_error(it, name(f), err)
			return
		}

		n, err := wasi.fd_readdir(__fd(f), buf[:], 0)
		if err != nil {
			read_directory_iterator_set_error(it, name(f), _get_platform_error(err))
			return
		}

		if n < len(buf) {
			non_zero_resize(&buf, n)
			break
		}

		assert(n == len(buf))
	}
	it.impl.buf = buf[:]

	// NOTE: Allow calling `init` to target a new directory with the same iterator.
	it.impl.fullpath.allocator = file_allocator()
	clear(&it.impl.fullpath)
	if err := reserve(&it.impl.fullpath, len(impl.name)+128); err != nil {
		read_directory_iterator_set_error(it, name(f), err)
		return
	}

	append(&it.impl.fullpath, impl.name)
	append(&it.impl.fullpath, "/")

	return
}

_read_directory_iterator_destroy :: proc(it: ^Read_Directory_Iterator) {
	delete(it.impl.buf, file_allocator())
	delete(it.impl.fullpath)
}
