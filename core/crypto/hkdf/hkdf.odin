/*
package hkdf implements the HKDF HMAC-based Extract-and-Expand Key
Derivation Function.

See: [[ https://www.rfc-editor.org/rfc/rfc5869 ]]
*/
package hkdf

import "core:crypto/hash"
import "core:crypto/hmac"
import "core:mem"

// extract_and_expand derives output keying material (OKM) via the
// HKDF-Extract and HKDF-Expand algorithms, with the specified has
// function, salt, input keying material (IKM), and optional info.
// The dst buffer must be less-than-or-equal to 255 HMAC tags.
extract_and_expand :: proc(algorithm: hash.Algorithm, salt, ikm, info, dst: []byte) {
	h_len := hash.DIGEST_SIZES[algorithm]

	tmp: [hash.MAX_DIGEST_SIZE]byte
	prk := tmp[:h_len]
	defer mem.zero_explicit(raw_data(prk), h_len)

	extract(algorithm, salt, ikm, prk)
	expand(algorithm, prk, info, dst)
}

// extract derives a pseudorandom key (PRK) via the HKDF-Extract algorithm,
// with the specified hash function, salt, and input keying material (IKM).
// It requires that the dst buffer be the HMAC tag size for the specified
// hash function.
extract :: proc(algorithm: hash.Algorithm, salt, ikm, dst: []byte) {
	// PRK = HMAC-Hash(salt, IKM)
	hmac.sum(algorithm, dst, ikm, salt)
}

// expand derives output keying material (OKM) via the HKDF-Expand algorithm,
// with the specified hash function, pseudorandom key (PRK), and optional
// info.  The dst buffer must be less-than-or-equal to 255 HMAC tags.
expand :: proc(algorithm: hash.Algorithm, prk, info, dst: []byte) {
	h_len := hash.DIGEST_SIZES[algorithm]

	// (<= 255*HashLen)
	dk_len := len(dst)
	switch {
	case dk_len == 0:
		return
	case dk_len > h_len * 255:
		panic("crypto/hkdf: derived key too long")
	case:
	}

	// The output OKM is calculated as follows:
	//
	// N = ceil(L/HashLen)
	// T = T(1) | T(2) | T(3) | ... | T(N)
	// OKM = first L octets of T
	//
	// where:
	// T(0) = empty string (zero length)
	// T(1) = HMAC-Hash(PRK, T(0) | info | 0x01)
	// T(2) = HMAC-Hash(PRK, T(1) | info | 0x02)
	// T(3) = HMAC-Hash(PRK, T(2) | info | 0x03)
	// ...

	n := dk_len / h_len
	r := dk_len % h_len

	base: hmac.Context
	defer hmac.reset(&base)

	hmac.init(&base, algorithm, prk)

	dst_blk := dst
	prev: []byte

	for i in 1 ..= n {
		_F(&base, prev, info, i, dst_blk[:h_len])

		prev = dst_blk[:h_len]
		dst_blk = dst_blk[h_len:]
	}

	if r > 0 {
		tmp: [hash.MAX_DIGEST_SIZE]byte
		blk := tmp[:h_len]
		defer mem.zero_explicit(raw_data(blk), h_len)

		_F(&base, prev, info, n + 1, blk)
		copy(dst_blk, blk)
	}
}

@(private)
_F :: proc(base: ^hmac.Context, prev, info: []byte, i: int, dst_blk: []byte) {
	prf: hmac.Context

	hmac.clone(&prf, base)
	hmac.update(&prf, prev)
	hmac.update(&prf, info)
	hmac.update(&prf, []byte{u8(i)})
	hmac.final(&prf, dst_blk)
}
