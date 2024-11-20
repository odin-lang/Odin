#+private
package os2

import win32 "core:sys/windows"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	p: [2]win32.HANDLE
	sa := win32.SECURITY_ATTRIBUTES {
		nLength = size_of(win32.SECURITY_ATTRIBUTES),
		bInheritHandle = true,
	}
	if !win32.CreatePipe(&p[0], &p[1], &sa, 0) {
		return nil, nil, _get_platform_error()
	}
	return new_file(uintptr(p[0]), ""), new_file(uintptr(p[1]), ""), nil
}

@(require_results)
_pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	if r == nil || r.impl == nil {
		return false, nil
	}
	handle := win32.HANDLE((^File_Impl)(r.impl).fd)
	bytes_available: u32
	if !win32.PeekNamedPipe(handle, nil, 0, nil, &bytes_available, nil) {
		return false, _get_platform_error()
	}
	return bytes_available > 0, nil
}