package rsa

// Copyright (c) 2016 Thomas Pornin <pornin@bolet.org>
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

import subtle "core:crypto/_subtle"

// unsafe_decrypt_tls_pms decrypts a TLS RSA-Encrypted Premaster Secret
// Message, unconditionally moves the decrypted plaintext to `data[:48]`,
// and returns 1 if and only if (⟺) the operation was successful.
//
// WARNING: This routine MUST only be used when implementing server-side
// support for TLS 1.2's Client Key Exchange message, and extreme care
// MUST be taken when handling failures.  This key exchange scheme was
// removed in TLS 1.3, and not implementing support in the first place
// is strongly RECOMMENDED even for TLS 1.2 servers.
@(require_results)
unsafe_decrypt_tls_pms :: proc(priv_key: ^Private_Key, data: []byte) -> u32 {
	// A first check on length. Since this test works only on the
	// buffer length, it needs not (and cannot) be constant-time.
	_len := len(data)
	if _len < 59 || _len != priv_key._pub_key._n.v_len {
		return 0
	}
	x := private_modpow(data, priv_key)

	x &= u32(subtle.eq(data[0], 0x00))
	x &= u32(subtle.eq(data[1], 0x02))
	for u in 2..<(_len-49) {
		x &= u32(subtle.neq(data[u], 0))
	}
	x &= u32(subtle.eq(data[_len - 49], 0x00))
	copy(data[:48], data[_len - 48:])

	return x
}
