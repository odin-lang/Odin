package rsa

// Copyright (c) 2018 Thomas Pornin <pornin@bolet.org>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
//
//   1. Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHORS “AS IS” AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import "core:crypto/hash"
import "core:encoding/endian"

@(private)
mgf1_xor :: proc(data: []byte, hash_algo: hash.Algorithm, seed: []byte) {
	tmp: [hash.MAX_DIGEST_SIZE]byte = ---
	ctx: hash.Context = ---

	buf, blen := data, len(data)
	hlen := hash.DIGEST_SIZES[hash_algo]
	digest := tmp[:hlen]
	for u, c := int(0), u32(0); u < blen; u, c = u + hlen, c + 1 {
		hash.init(&ctx, hash_algo)
		hash.update(&ctx, seed)
		endian.unchecked_put_u32be(tmp[:], c)
		hash.update(&ctx, tmp[:4])
		hash.final(&ctx, digest)
		for v in 0..<hlen {
			if u + v >= blen {
				break
			}
			buf[u + v] ~= digest[v]
		}
	}
}
