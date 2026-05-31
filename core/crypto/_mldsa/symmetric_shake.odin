#+private
package _mldsa

import "core:crypto/_sha3"
import "core:crypto/shake"

STREAM128_BLOCKBYTES :: _sha3.RATE_128
STREAM256_BLOCKBYTES :: _sha3.RATE_256

stream128_init :: proc(ctx: ^shake.Context, seed: []byte, iv: u16) {
	t: [2]byte = ---
	t[0] = byte(iv)
	t[1] = byte(iv >> 8)

	shake.init_128(ctx)
	shake.write(ctx, seed)
	shake.write(ctx, t[:])
}

stream256_init :: proc(ctx: ^shake.Context, seed: []byte, iv: u16) {
	t: [2]byte = ---
	t[0] = byte(iv)
	t[1] = byte(iv >> 8)

	shake.init_256(ctx)
	shake.write(ctx, seed)
	shake.write(ctx, t[:])
}

shake256 :: proc(dst: []byte, srcs: ..[]byte) {
	ctx: shake.Context = ---
	defer shake.reset(&ctx)

	shake.init_256(&ctx)
	for src in srcs {
		shake.write(&ctx, src)
	}
	shake.read(&ctx, dst)
}
