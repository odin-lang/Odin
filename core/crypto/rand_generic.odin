package crypto

when ODIN_OS != .Linux && ODIN_OS != .OpenBSD && ODIN_OS != .Windows && ODIN_OS != .Darwin {
	_rand_bytes :: proc (dst: []byte) {
		unimplemented("crypto: rand_bytes not supported on this OS")
	}
}
