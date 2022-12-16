//+private
package os2

import win32 "core:sys/windows"

_pipe :: proc() -> (r, w: ^File, err: Error) {
	p: [2]win32.HANDLE
	if !win32.CreatePipe(&p[0], &p[1], nil, 0) {
		return nil, nil, _get_platform_error()
	}
	return new_file(uintptr(p[0]), ""), new_file(uintptr(p[1]), ""), nil
}

