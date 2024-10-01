package os2

@(require_results)
pipe :: proc() -> (r, w: ^File, err: Error) {
	return _pipe()
}
