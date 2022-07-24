package os2

pipe :: proc() -> (r, w: ^File, err: Error) {
	return _pipe()
}
