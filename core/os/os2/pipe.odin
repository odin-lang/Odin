package os2

pipe :: proc() -> (r, w: Handle, err: Error) {
	return _pipe()
}
