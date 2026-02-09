#+private
package os2

import "core:sys/darwin"

_copy_directory_all_native :: proc(dst, src: string, dst_perm := 0o755) -> (err: Error) {
	temp_allocator := TEMP_ALLOCATOR_GUARD({})

	csrc := clone_to_cstring(src, temp_allocator) or_return
	cdst := clone_to_cstring(dst, temp_allocator) or_return

	if darwin.copyfile(csrc, cdst, nil, darwin.COPYFILE_ALL + {.RECURSIVE}) < 0 {
		err = _get_platform_error()
	}

	return
}
