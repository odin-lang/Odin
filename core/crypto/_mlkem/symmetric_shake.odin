#+private
package _mlkem

import "core:crypto"
import "core:crypto/_sha3"
import "core:crypto/sha3"
import "core:crypto/shake"

XOF_BLOCKBYTES :: _sha3.RATE_128
#assert(XOF_BLOCKBYTES % 3 == 0)

prf :: proc(out, key: []byte, iv: byte) {
	ctx: shake.Context = ---
	defer shake.reset(&ctx)

	shake.init_256(&ctx)
	shake.write(&ctx, key)
	shake.write(&ctx, []byte{iv})
	shake.read(&ctx, out)
}

rkprf :: proc(out, key, input: []byte) {
	ctx: shake.Context = ---
	defer shake.reset(&ctx)

	shake.init_256(&ctx)
	shake.write(&ctx, key)
	shake.write(&ctx, input)
	shake.read(&ctx, out)
}

xof_absorb :: proc(ctx: ^shake.Context, seed: []byte, x, y: byte) {
	shake.init_128(ctx)

	extseed: [SYMBYTES+2]byte = ---
	defer crypto.zero_explicit(&extseed, size_of(extseed))

	copy(extseed[:], seed)
	extseed[SYMBYTES+0] = x
	extseed[SYMBYTES+1] = y

	shake.write(ctx, extseed[:])
}

hash_h :: proc(dst, src: []byte) {
	ctx: sha3.Context = ---

	sha3.init_256(&ctx)
	sha3.update(&ctx, src)
	sha3.final(&ctx, dst)
}

hash_g :: proc(dst: []byte, srcs: ..[]byte) {
	ctx: sha3.Context = ---

	sha3.init_512(&ctx)
	for src in srcs {
		sha3.update(&ctx, src)
	}
	sha3.final(&ctx, dst)
}
