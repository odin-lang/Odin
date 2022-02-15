package crypto

when ODIN_OS != .Linux {
	_rand_bytes :: proc (dst: []byte) {
		unimplemented("crypto: rand_bytes not supported on this OS")
	}
}
