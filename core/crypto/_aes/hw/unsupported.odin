#+build !amd64
#+build !arm64
#+build !arm32
package aes_hw

HAS_GHASH :: false

@(private)
keysched :: proc(ctx: ^Context, key: []byte) {
	panic("crypto/aes: hardware implementation unsupported")
}
