//+private
package os2

_pipe :: proc() -> (r, w: Handle, err: Error) {
	return INVALID_HANDLE, INVALID_HANDLE, nil
}

