package crypto

when ODIN_OS != "linux" {
	_rand_bytes :: proc (dst: []byte) {
		unimplemented("crypto: rand_bytes not supported on this OS")
	}
}
