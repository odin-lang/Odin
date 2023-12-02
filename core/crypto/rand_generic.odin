//+build !linux !windows !openbsd !freebsd !darwin !js
package crypto

_rand_bytes :: proc(dst: []byte) {
	unimplemented("crypto: rand_bytes not supported on this OS")
}
