//+build !linux
//+build !windows
//+build !openbsd
//+build !freebsd
//+build !darwin
//+build !js
package crypto

_rand_bytes :: proc(dst: []byte) {
	unimplemented("crypto: rand_bytes not supported on this OS")
}
