/*
package pbkdf2 implements the PBKDF2 password-based key derivation function.

See: [[ https://www.rfc-editor.org/rfc/rfc2898 ]]
*/
package pbkdf2

import "core:crypto/hash"
import "core:crypto/hmac"
import "core:encoding/endian"
import "core:mem"

// derive invokes PBKDF2-HMAC with the specified hash algorithm, password,
// salt, iteration count, and outputs the derived key to dst.
derive :: proc(
	hmac_hash: hash.Algorithm,
	password: []byte,
	salt: []byte,
	iterations: u32,
	dst: []byte,
) {
	h_len := hash.DIGEST_SIZES[hmac_hash]

	// 1. If dkLen > (2^32 - 1) * hLen, output "derived key too long"
	// and stop.

	dk_len := len(dst)
	switch {
	case dk_len == 0:
		return
	case u64(dk_len) > u64(max(u32)) * u64(h_len):
		// This is so beyond anything that is practical or reasonable,
		// so just panic instead of returning an error.
		panic("crypto/pbkdf2: derived key too long")
	case:
	}

	// 2. Let l be the number of hLen-octet blocks in the derived key,
	// rounding up, and let r be the number of octets in the last block.

	l := dk_len / h_len // Don't need to round up.
	r := dk_len % h_len

	// 3. For each block of the derived key apply the function F defined
	// below to the password P, the salt S, the iteration count c, and
	// the block index to compute the block.
	//
	// 4. Concatenate the blocks and extract the first dkLen octets to
	// produce a derived key DK.
	//
	// 5. Output the derived key DK.

	// Each iteration of F is always `PRF (P, ...)`, so instantiate the
	// PRF, and clone since memcpy is faster than having to re-initialize
	// HMAC repeatedly.

	base: hmac.Context
	defer hmac.reset(&base)

	hmac.init(&base, hmac_hash, password)

	// Process all of the blocks that will be written directly to dst.
	dst_blk := dst
	for i in 1 ..= l { 	// F expects i starting at 1.
		_F(&base, salt, iterations, u32(i), dst_blk[:h_len])
		dst_blk = dst_blk[h_len:]
	}

	// Instead of rounding l up, just proceass the one extra block iff
	// r != 0.
	if r > 0 {
		tmp: [hash.MAX_DIGEST_SIZE]byte
		blk := tmp[:h_len]
		defer mem.zero_explicit(raw_data(blk), h_len)

		_F(&base, salt, iterations, u32(l + 1), blk)
		copy(dst_blk, blk)
	}
}

@(private)
_F :: proc(base: ^hmac.Context, salt: []byte, c: u32, i: u32, dst_blk: []byte) {
	h_len := len(dst_blk)

	tmp: [hash.MAX_DIGEST_SIZE]byte
	u := tmp[:h_len]
	defer mem.zero_explicit(raw_data(u), h_len)

	// F (P, S, c, i) = U_1 \xor U_2 \xor ... \xor U_c
	//
	// where
	//
	// U_1 = PRF (P, S || INT (i)) ,
	// U_2 = PRF (P, U_1) ,
	// ...
	// U_c = PRF (P, U_{c-1}) .
	//
	// Here, INT (i) is a four-octet encoding of the integer i, most
	// significant octet first.

	prf: hmac.Context

	// U_1: PRF (P, S || INT (i))
	hmac.clone(&prf, base)
	hmac.update(&prf, salt)
	endian.unchecked_put_u32be(u, i) // Use u as scratch space.
	hmac.update(&prf, u[:4])
	hmac.final(&prf, u)
	copy(dst_blk, u)

	// U_2 ... U_c: U_n = PRF (P, U_(n-1))
	for _ in 1 ..< c {
		hmac.clone(&prf, base)
		hmac.update(&prf, u)
		hmac.final(&prf, u)

		// XOR dst_blk and u.
		for v, i in u {
			dst_blk[i] ~= v
		}
	}
}
