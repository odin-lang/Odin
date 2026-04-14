#+private
package noise

import "base:runtime"
import "core:crypto"
import "core:crypto/aead"
import "core:crypto/ecdh"
import "core:crypto/hash"
import "core:crypto/hkdf"
import "core:encoding/endian"
import "core:slice"
import "core:strings"

AEAD_KEY_SIZE :: 32

MIN_DH_SIZE :: 32
MAX_DH_SIZE :: 56
MAX_HASH_SIZE :: 64

Protocol :: struct {
	handshake_pattern: Handshake_Pattern,
	dh: ecdh.Curve,
	cipher: aead.Algorithm,
	hash: hash.Algorithm,
}

Symmetric_State :: struct {
	protocol: Protocol,
	cipher_state: Cipher_State,

	_ck: [MAX_HASH_SIZE]byte,
	_h: [MAX_HASH_SIZE]byte,
}

Cipher_State :: struct {
	ctx: aead.Context,
	n: u64,
	n_exhausted: bool,
	is_invalid: bool,
}

@(require_results)
dh_len :: proc(protocol: ^Protocol) -> int {
	return ecdh.PUBLIC_KEY_SIZES[protocol.dh]
}

@(require_results)
hash_len :: proc(protocol: ^Protocol) -> int {
	return hash.DIGEST_SIZES[protocol.hash]
}

// Generates a new Diffie-Hellman key pair. A DH key pair consists of
// public_key and private_key elements.  public_key represents an encoding
// of a DH public key into a byte sequence of length DHLEN.  The public_key
// encoding details are specific to each set of DH functions.
GENERATE_KEYPAIR :: proc(protocol: ^Protocol, private_key: ^ecdh.Private_Key) {
	#partial switch protocol.dh {
	case .X25519, .X448:
	case: panic("crypto/noise: unsupported DH curve in protocol")
	}

	ecdh.private_key_generate(private_key, protocol.dh)
}

// Performs a Diffie-Hellman calculation between the private key in key_pair
// and the public_key and returns an output sequence of bytes of length DHLEN.
// For security, the Gap-DH problem based on this function must be unsolvable
// by any practical cryptanalytic adversary [2].
//
// The public_key either encodes some value which is a generator in a
// large prime-order group (which value may have multiple equivalent
// encodings), or is an invalid value.  Implementations must handle invalid
// public keys either by returning some output which is purely a function
// of the public key and does not depend on the private key, or by signaling
// an error to the caller.
//
// The DH function may define more specific rules for handling invalid values.
@(require_results)
DH :: proc(our_private_key: ^ecdh.Private_Key, their_public_key: ^ecdh.Public_Key, dst: []byte) -> Status {
	if ok := ecdh.ecdh(our_private_key, their_public_key, dst); !ok {
		return .DH_Failure
	}
	return .Ok
}

// Encrypts plaintext using the cipher key k of 32 bytes and an 8-byte
// unsigned integer nonce n which must be unique for the key k.
// Returns the ciphertext. Encryption must be done with an "AEAD"
// encryption mode with the associated data(AD) (using the terminology
// from [1]) and returns a ciphertext that is the same size as the plaintext
// plus 16 bytes for authentication data.  The entire ciphertext must be
// indistinguishable from random if the key is secret (note that this is
// an additional requirement that isn't necessarily met by all AEAD schemes).
ENCRYPT :: proc(ctx: ^aead.Context, n: u64, ad, plaintext, dst: []byte) {
	pt_len := len(plaintext)
	ensure(len(dst) == pt_len + TAG_SIZE, "crypto/noise: invalid AEAD encrypt destination")

	iv: [12]byte
	#partial switch aead.algorithm(ctx) {
	case .AES_GCM_256: endian.unchecked_put_u64be(iv[4:], n)
	case .CHACHA20POLY1305: endian.unchecked_put_u64le(iv[4:], n)
	}

	ciphertext, tag := dst[:pt_len], dst[pt_len:]
	aead.seal_ctx(ctx, ciphertext, tag, iv[:], ad, plaintext)
}

// Decrypts ciphertext using a cipher key k of 32 bytes, an 8-byte unsigned
// integer nonce n, and associated data ad. Returns the plaintext, unless
// authentication fails, in which case an error is signaled to the caller.
@(require_results)
DECRYPT :: proc(ctx: ^aead.Context, n: u64, ad, ciphertext, dst: []byte) -> Status {
	if len(ciphertext) < TAG_SIZE {
		return .Decryption_Failure
	}

	iv: [12]byte
	#partial switch aead.algorithm(ctx) {
	case .AES_GCM_256: endian.unchecked_put_u64be(iv[4:], n)
	case .CHACHA20POLY1305: endian.unchecked_put_u64le(iv[4:], n)
	}

	ct_len := len(ciphertext) - TAG_SIZE
	ct, tag := ciphertext[:ct_len], ciphertext[ct_len:]
	if ok := aead.open_ctx(ctx, dst, iv[:], ad, ct, tag); !ok {
		return .Decryption_Failure
	}

	return .Ok
}

// Hashes some arbitrary-length data with a collision-resistant cryptographic
// hash function and returns an output of HASHLEN bytes.
HASH :: proc(dst: []byte, protocol: ^Protocol, data: ..[]byte) {
	ctx: hash.Context
	hash.init(&ctx, protocol.hash)

	for datum in data {
		hash.update(&ctx, datum)
	}

	hash.final(&ctx, dst)
}

// Takes a chaining_key byte sequence of length HASHLEN, and an
// input_key_material byte sequence with length either zero bytes,
// 32 bytes, or DHLEN bytes. Returns a pair or triple of byte sequences
// each of length HASHLEN, depending on whether num_outputs is two or three:
//  - Sets temp_key = HMAC-HASH(chaining_key, input_key_material).
//  - Sets output1 = HMAC-HASH(temp_key, byte(0x01)).
//  - Sets output2 = HMAC-HASH(temp_key, output1 || byte(0x02)).
//  - If num_outputs == 2 then returns the pair (output1, output2).
//  - Sets output3 = HMAC-HASH(temp_key, output2 || byte(0x03)).
//  - Returns the triple (output1, output2, output3).
//
// Note that temp_key, output1, output2, and output3 are all HASHLEN
// bytes in length. Also note that the HKDF() function is simply HKDF
// from [4] with the chaining_key as HKDF salt, and zero-length HKDF info.
@(require_results)
HKDF :: proc(dst, chaining_key, input_key_material: []byte, protocol: ^Protocol) -> ([]byte, []byte, []byte) {
	assert(len(input_key_material) == 0 || len(input_key_material) == 32 || len(input_key_material) == dh_len(protocol))

	hkdf.extract_and_expand(protocol.hash, chaining_key, input_key_material, nil, dst)

	h_len := hash_len(protocol)
	assert(len(dst) == h_len * 2 || len(dst) == h_len * 3)

	r1, r2 := dst[:h_len], dst[h_len:h_len*2]
	if len(dst) == h_len * 2 {
		return r1, r2, nil
	}
	return r1, r2, dst[h_len*2:]
}

// Sets k = key. Sets n = 0.
cipherstate_InitializeKey :: proc(self: ^Cipher_State, key: []byte, protocol: ^Protocol) {
	k_len := len(key)
	switch {
	case k_len == 0:
		// k = empty
		aead.reset(&self.ctx)
		self.n = 0
	case k_len < AEAD_KEY_SIZE:
		panic("crypto/noise: invalid AEAD key size")
	case:
		aead.init(&self.ctx, protocol.cipher, key[:AEAD_KEY_SIZE])
		self.n = 0
	}
}

// Returns true if k is non-empty, false otherwise.
@(require_results)
cipherstate_HasKey :: proc(self: ^Cipher_State) -> bool {
	return aead.algorithm(&self.ctx) != .Invalid
}

// If k is non-empty returns ENCRYPT(k, n++, ad, plaintext). Otherwise
// returns plaintext.
@(require_results)
cipherstate_EncryptWithAd :: proc(self: ^Cipher_State, ad, plaintext, dst: []byte) -> ([]byte, Status) {
	if self.is_invalid {
		return nil, .Invalid_Cipher_State
	}
	if self.n_exhausted {
		return nil, .IV_Exhausted
	}

	pt_len := len(plaintext)
	if pt_len > MAX_PACKET_SIZE - 16 {
		return nil, .Max_Packet_Size
	}

	if cipherstate_HasKey(self) {
		if len(dst) != pt_len + TAG_SIZE {
			return nil, .Invalid_Destination_Buffer
		}
		ENCRYPT(&self.ctx, self.n, ad, plaintext, dst)
		self.n += 1
		if self.n == 0 {
			self.n_exhausted = true
		}
	} else {
		if len(dst) != pt_len {
			return nil, .Invalid_Destination_Buffer
		}
		if raw_data(dst) != raw_data(plaintext) {
			copy(dst, plaintext)
		}
	}

	return dst, .Ok
}

// If k is non-empty returns DECRYPT(k, n++, ad, ciphertext). Otherwise
// returns ciphertext.  If an authentication failure occurs in DECRYPT()
// then n is not incremented and an error is signaled to the caller.
@(require_results)
cipherstate_DecryptWithAd :: proc(self: ^Cipher_State, ad, ciphertext, dst: []byte) -> ([]byte, Status) {
	if self.is_invalid {
		return nil, .Invalid_Cipher_State
	}
	if self.n_exhausted {
		return nil, .IV_Exhausted
	}

	if cipherstate_HasKey(self) {
		if status := DECRYPT(&self.ctx, self.n, ad, ciphertext, dst); status != .Ok {
			return nil, status
		}
		self.n += 1
		if self.n == 0 {
			self.n_exhausted = true
		}
	} else {
		if len(dst) != len(ciphertext) {
			return nil, .Invalid_Destination_Buffer
		}
		if raw_data(dst) != raw_data(ciphertext) {
			copy(dst, ciphertext)
		}
	}

	return dst, .Ok
}

// Sets k = REKEY(k).
cipherstate_Rekey :: proc(self: ^Cipher_State) {
	if cipherstate_HasKey(self) {
		algorithm := aead.algorithm(&self.ctx)

		// The "sensible" way to implement this is to inlike REKEY(k),
		// so we do.
		//
		// Returns a new 32-byte cipher key as a pseudorandom function
		// of k. If this function is not specifically defined for some
		// set of cipher functions, then it defaults to returning the
		// first 32 bytes from `ENCRYPT(k, maxnonce, zerolen, zeros)`,
		// where maxnonce equals (2^64)-1, zerolen is a zero-length
		// byte sequence, and zeros is a sequence of 32 bytes filled
		// with zeros.

		zeroes: [AEAD_KEY_SIZE + TAG_SIZE]byte
		defer crypto.zero_explicit(&zeroes, size_of(zeroes))

		//		 1  2  3  4  5  6  7  8
		n: u64 = 0xFF_FF_FF_FF_FF_FF_FF_FF
		ENCRYPT(&self.ctx, n, nil, zeroes[:AEAD_KEY_SIZE], zeroes[:])
		aead.init(&self.ctx, algorithm, zeroes[:AEAD_KEY_SIZE])
	}
}

cipherstate_reset :: proc(self: ^Cipher_State) {
	aead.reset(&self.ctx)
	crypto.zero_explicit(self, size_of(Cipher_State))
}

// Takes an arbitrary-length protocol_name byte sequence (see Section 8).
// Executes the following steps:
//  - If protocol_name is less than or equal to HASHLEN bytes in length,
//	sets h equal to protocol_name with zero bytes appended to make
//	HASHLEN bytes.
//  - Otherwise sets h = HASH(protocol_name).
//  - Sets ck = h.
//  - Calls InitializeKey(empty).
@(require_results)
symmetricstate_Initialize :: proc(ss: ^Symmetric_State, protocol_name: string) -> Status {
	if status := protocol_from_string(&ss.protocol, protocol_name); status != .Ok {
		return status
	}

	cipherstate_InitializeKey(&ss.cipher_state, nil, &ss.protocol)

	h_len := hash_len(&ss.protocol)
	h := ss._h[:h_len]
	if len(protocol_name) <= h_len {
		copy(h, protocol_name)
	} else {
		HASH(h, &ss.protocol, transmute([]byte)protocol_name)
	}

	copy(ss._ck[:h_len], h)

	return .Ok
}

// Sets h = HASH(h || data).
symmetricstate_MixHash :: proc(self: ^Symmetric_State, data: ..[]byte) {
	h := self._h[:hash_len(&self.protocol)]
	if len(data) == 1 {
		HASH(h, &self.protocol, h, data[0])
	} else if len(data) == 2 {
		HASH(h, &self.protocol, h, data[0], data[1])
	} else if len(data) == 3 {
		HASH(h, &self.protocol, h, data[0], data[1], data[2])
	} else {
		panic("crypto/noise: invalid MixHash inputs")
	}
}

// Executes the following steps:
// - Sets ck, temp_k = HKDF(ck, input_key_material, 2).
// - If HASHLEN is 64, then truncates temp_k to 32 bytes.
// - Calls InitializeKey(temp_k).
symmetricstate_MixKey :: proc(self: ^Symmetric_State, input_key_material: []byte) {
	h_len := hash_len(&self.protocol)

	dst_len := h_len * 2
	dst: [2*MAX_HASH_SIZE]byte = ---
	defer crypto.zero_explicit(&dst, dst_len)

	ck, temp_k, _ := HKDF(dst[:dst_len], self._ck[:h_len], input_key_material, &self.protocol)
	copy(self._ck[:], ck)
	cipherstate_InitializeKey(&self.cipher_state, temp_k, &self.protocol)
}

// This function is used for handling pre-shared symmetric keys, as described
// in Section 9. It executes the following steps:
// - Sets ck, temp_h, temp_k = HKDF(ck, input_key_material, 3).
// - Calls MixHash(temp_h).
// - If HASHLEN is 64, then truncates temp_k to 32 bytes.
// - Calls InitializeKey(temp_k).
symmetricstate_MixKeyAndHash :: proc(self: ^Symmetric_State, input_key_material: []byte) {
	h_len := hash_len(&self.protocol)

	dst_len := h_len * 3
	dst: [3*MAX_HASH_SIZE]byte = ---
	defer crypto.zero_explicit(&dst, dst_len)

	ck, temp_h, temp_k := HKDF(dst[:dst_len], self._ck[:h_len], input_key_material, &self.protocol)
	copy(self._ck[:], ck)
	symmetricstate_MixHash(self, temp_h)
	cipherstate_InitializeKey(&self.cipher_state, temp_k, &self.protocol)
}

// Returns h. This function should only be called at the end of a handshake,
// i.e. after the Split() function has been called.
//
// This function is used for channel binding, as described in Section 11.2
@(require_results)
symmetricstate_GetHandshakeHash :: proc(self: ^Symmetric_State) -> []byte {
	return self._h[:hash_len(&self.protocol)]
}

// Sets ciphertext = EncryptWithAd(h, plaintext), calls MixHash(ciphertext),
// and returns ciphertext.
//
// Note that if k is empty, the EncryptWithAd() call will set ciphertext
// equal to plaintext.
@(require_results)
symmetricstate_EncryptAndHash :: proc(self: ^Symmetric_State, plaintext, dst: []byte) -> ([]byte, Status) {
	ciphertext, status := cipherstate_EncryptWithAd(&self.cipher_state, self._h[:hash_len(&self.protocol)], plaintext, dst)
	if status != .Ok {
		return nil, status
	}
	symmetricstate_MixHash(self, ciphertext)
	return ciphertext, status
}

// Sets plaintext = DecryptWithAd(h, ciphertext), calls MixHash(ciphertext),
// and returns plaintext.
//
// Note that if k is empty, the DecryptWithAd() call will set plaintext
// equal to ciphertext.
@(require_results)
symmetricstate_DecryptAndHash :: proc(self: ^Symmetric_State, ciphertext, dst: []byte) -> ([]byte, Status) {
	h_len := hash_len(&self.protocol)

	h: [MAX_HASH_SIZE]byte = ---
	copy(h[:], self._h[:h_len])
	defer crypto.zero_explicit(&h, size_of(h))

	// We reverse the order to save having to copy the ciphertext, in
	// the case that ciphertext and dst alias.
	symmetricstate_MixHash(self, ciphertext)
	return cipherstate_DecryptWithAd(&self.cipher_state, h[:h_len], ciphertext, dst)
}

// Returns a pair of CipherState objects for encrypting transport messages.
// Executes the following steps, where zerolen is a zero-length byte sequence:
//  - Sets temp_k1, temp_k2 = HKDF(ck, zerolen, 2).
//  - If HASHLEN is 64, then truncates temp_k1 and temp_k2 to 32 bytes.
//  - Creates two new CipherState objects c1 and c2.
//  - Calls c1.InitializeKey(temp_k1) and c2.InitializeKey(temp_k2).
//  - Returns the pair (c1, c2).
symmetricstate_Split :: proc(self: ^Symmetric_State, cipher_states: ^Cipher_States) {
	h_len := hash_len(&self.protocol)

	dst_len := h_len * 2
	dst: [2*MAX_HASH_SIZE]byte = ---
	defer crypto.zero_explicit(&dst, dst_len)

	temp_k1, temp_k2, _ := HKDF(dst[:dst_len], self._ck[:h_len], nil, &self.protocol)
	cipherstate_InitializeKey(&cipher_states.c1_i_to_r, temp_k1, &self.protocol)
	cipherstate_InitializeKey(&cipher_states.c2_r_to_i, temp_k2, &self.protocol)
}

symmetricstate_reset :: proc(self: ^Symmetric_State) {
	cipherstate_reset(&self.cipher_state)

	crypto.zero_explicit(self, size_of(Symmetric_State))
}

// Takes a valid handshake_pattern (see Section 7) and an initiator boolean
// specifying this party's role as either initiator or responder.
// Takes a prologue byte sequence which may be zero-length, or which may
// contain context information that both parties want to confirm is identical
// (see Section 6).
//
// Takes a set of DH key pairs (s, e) and public keys (rs, re) for
// initializing local variables, any of which may be empty.  Public keys
// are only passed in if the handshake_pattern uses pre-messages
// (see Section 7). The ephemeral values (e, re) are typically left empty,
// since they are created and exchanged during the handshake; but there
// are exceptions (see Section 10).
//
// Performs the following steps:
//  - Derives a protocol_name byte sequence by combining the names for
//	the handshake pattern and crypto functions, as specified in Section 8.
//  - Calls InitializeSymmetric(protocol_name).
//  - Calls MixHash(prologue).
//  - Sets the initiator, s, e, rs, and re variables to the corresponding
//	arguments.
//  - Calls MixHash() once for each public key listed in the pre-messages
//	from handshake_pattern, with the specified public key as input
//	(see Section 7 for an explanation of pre-messages).
//  - If both initiator and responder have pre-messages, the initiator's
//	public keys are hashed first.
//  - If multiple public keys are listed in either party's pre-message,
//	the public keys are hashed in the order that they are listed.
//  -  Sets message_pattern to the message patterns from handshake_pattern.
@(require_results)
handshakestate_Initialize :: proc(
	handshake_state: ^Handshake_State,
	initiator: bool,
	prologue: []byte,
	s: ^ecdh.Private_Key,
	e: ^ecdh.Private_Key, // Only set for testing.
	rs: ^ecdh.Public_Key,
	re: ^ecdh.Public_Key, // Only set for testing.
	protocol_name: string,
	psk: []byte = nil,
) -> Status {
	crypto.zero_explicit(handshake_state, size_of(Handshake_State))

	symmetric_state := &handshake_state.symmetric_state
	status: Status
	do_init: {
		if status = symmetricstate_Initialize(symmetric_state, protocol_name); status != .Ok {
			break do_init
		}

		curve := symmetric_state.protocol.dh
		if s != nil && ecdh.curve(s) != curve {
			status = .Invalid_DH_Key
			break do_init
		}
		if e != nil && ecdh.curve(e) != curve {
			status = .Invalid_DH_Key
			break do_init
		}
		if rs != nil && ecdh.curve(rs) != curve {
			status = .Invalid_DH_Key
			break do_init
		}
		if re != nil && ecdh.curve(re) != curve {
			status = .Invalid_DH_Key
			break do_init
		}

		// Check if we will require s later down the line.
		s_pre, s_hs: bool
		if initiator {
			s_pre, s_hs = pattern_requires_initiator_s(symmetric_state.protocol.handshake_pattern)
		} else {
			s_pre, s_hs = pattern_requires_responder_s(symmetric_state.protocol.handshake_pattern)
		}
		if (s_pre || s_hs) && s == nil {
			status = .No_Self_Identity
			break do_init
		}

		message_pattern := HANDSHAKE_PATTERNS[symmetric_state.protocol.handshake_pattern]
		if message_pattern.pre_messages != nil {
			if initiator {
				if slice.contains(message_pattern.pre_messages, Pre_Token.res_s) {
					if rs == nil {
						status = .No_Peer_Identity
						break do_init
					}
				}
			} else {
				if slice.contains(message_pattern.pre_messages, Pre_Token.ini_s) {
					if rs == nil {
						status = .No_Peer_Identity
						break do_init
					}
				}
			}
		} else {
			if rs != nil {
				status = .Unexpected_Peer_Identity
				break do_init
			}
		}

		symmetricstate_MixHash(symmetric_state, prologue)

		// In all supported patterns, `ini_s` will always precede `res_s`.
		if message_pattern.pre_messages != nil {
			tmp: [MAX_DH_SIZE]byte = ---
			d_len := dh_len(&symmetric_state.protocol)
			dst := tmp[:d_len]

			if initiator {
				if slice.contains(message_pattern.pre_messages, Pre_Token.ini_s) {
					ecdh.public_key_bytes(&s._pub_key, dst)
					symmetricstate_MixHash(symmetric_state, dst)
				}
				if slice.contains(message_pattern.pre_messages, Pre_Token.res_s) {
					ecdh.public_key_bytes(rs, dst)
					symmetricstate_MixHash(symmetric_state, dst)
				}
			} else {
				if slice.contains(message_pattern.pre_messages, Pre_Token.ini_s) {
					ecdh.public_key_bytes(rs, dst)
					symmetricstate_MixHash(symmetric_state, dst)
				}
				if slice.contains(message_pattern.pre_messages, Pre_Token.res_s) {
					ecdh.public_key_bytes(&s._pub_key, dst)
					symmetricstate_MixHash(symmetric_state, dst)
				}
			}
		}
		if message_pattern.is_psk {
			if len(psk) != PSK_SIZE {
				status = .Invalid_Pre_Shared_Key
				break do_init
			}
		} else if len(psk) != 0 {
			status = .Unexpected_Pre_Shared_Key
			break do_init
		}
	}
	if status != .Ok {
		symmetricstate_reset(symmetric_state)
		return status
	}

	if s != nil {
		ecdh.private_key_set(&handshake_state.s, s)
	}
	if e != nil {
		ecdh.private_key_set(&handshake_state.e, e)
		handshake_state.pre_set_e = true
	}
	if rs != nil {
		ecdh.public_key_set(&handshake_state.rs, rs)
	}
	if re != nil {
		ecdh.public_key_set(&handshake_state.re, re)
	}
	copy(handshake_state.psk[:], psk)
	handshake_state.message_pattern = HANDSHAKE_PATTERNS[symmetric_state.protocol.handshake_pattern]
	handshake_state.current_message = 0
	handshake_state.status = .Handshake_Pending
	handshake_state.initiator = initiator

	return .Ok
}

handshakestate_reset :: proc(self: ^Handshake_State) {
	symmetricstate_reset(&self.symmetric_state)
	ecdh.private_key_clear(&self.s)
	ecdh.private_key_clear(&self.e)

	crypto.zero_explicit(self, size_of(Handshake_State))
}

// Takes a payload byte sequence which may be zero-length, and a
// message_buffer to write the output into.
// Performs the following steps, aborting if any EncryptAndHash() call
// returns an error:
//  - Fetches and deletes the next message pattern from message_pattern,
//	then sequentially processes each token from the message pattern:
//	  - For "e": Sets e (which must be empty) to GENERATE_KEYPAIR().
//		Appends e.public_key to the buffer. Calls MixHash(e.public_key).
//	  - For "s": Appends EncryptAndHash(s.public_key) to the buffer.
//	  - For "ee": Calls MixKey(DH(e, re)).
//	  - For "es": Calls MixKey(DH(e, rs)) if initiator, MixKey(DH(s, re))
//		if responder.
//	  - For "se": Calls MixKey(DH(s, re)) if initiator, MixKey(DH(e, rs))
//		if responder.
//	  - For "ss": Calls MixKey(DH(s, rs)).
//  - Appends EncryptAndHash(payload) to the buffer.
//  – (SKIPPED) If there are no more message patterns returns two new
//    CipherState objects by calling Split().
//
// Calling Split() is left to a separate function, although it is technically
// part of the specification.
@(require_results)
handshakestate_WriteMessage :: proc(self: ^Handshake_State, payload, dst: []byte, allocator := context.allocator) -> ([]byte, Status) {
	ensure(self.status == .Handshake_Pending, "crypto/noise: invalid state for WriteMessage")

	protocol := &self.symmetric_state.protocol
	d_len := dh_len(protocol)

	pattern_buf: [dynamic; MAX_STEP_MSG_SIZE]byte
	dh_buf: [MAX_DH_SIZE]byte = ---
	defer crypto.zero_explicit(&dh_buf, size_of(dh_buf))

	pattern := self.message_pattern.messages[self.current_message]
	for token in pattern {
		switch token {
		case .e:
			switch self.pre_set_e {
			case true:
				// Note: "which must be empty", but we allow pre-generated `e`
				// for testing/rng-less systems.
				self.pre_set_e = false
			case false:
				if ecdh.curve(&self.e) != .Invalid {
					panic("crypto/noise: e was not empty when processing token 'e' during WriteMessage")
				}
				GENERATE_KEYPAIR(protocol, &self.e)
			}
			e_public := dh_buf[:d_len]
			ecdh.public_key_bytes(&self.e._pub_key, e_public)
			n := append(&pattern_buf, ..e_public)
			ensure(n == d_len, "crypto/noise: truncated append `e`")

			symmetricstate_MixHash(&self.symmetric_state, e_public)
			if self.message_pattern.is_psk {
				symmetricstate_MixKey(&self.symmetric_state, e_public)
			}

		case .s:
			s_public := dh_buf[:d_len]
			ecdh.public_key_bytes(&self.s._pub_key, s_public)

			tmp: [MAX_DH_SIZE+TAG_SIZE]byte = ---
			dh_buf := tmp[:d_len+TAG_SIZE]
			if !cipherstate_HasKey(&self.symmetric_state.cipher_state) {
				dh_buf = tmp[:d_len]
			}
			ct, status := symmetricstate_EncryptAndHash(&self.symmetric_state, s_public, dh_buf)
			if status != .Ok {
				self.status = .Handshake_Failed
				return nil, status
			}
			n := append(&pattern_buf, ..ct)
			ensure(n == len(ct), "crypto/noise: truncated append `s`")

		case .ee:
			dh := dh_buf[:d_len]
			if status := DH(&self.e, &self.re, dh); status != .Ok {
				self.status = .Handshake_Failed
				return nil, status
			}
			symmetricstate_MixKey(&self.symmetric_state, dh)

		case .es:
			dh := dh_buf[:d_len]
			if self.initiator {
				if status := DH(&self.e, &self.rs, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			} else {
				if status := DH(&self.s, &self.re, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			}

		case .se:
			dh := dh_buf[:d_len]
			if self.initiator {
				if status := DH(&self.s, &self.re, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			} else {
				if status := DH(&self.e, &self.rs, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			}

		case .ss:
			dh := dh_buf[:d_len]
			if status := DH(&self.s, &self.rs, dh); status != .Ok {
				self.status = .Handshake_Failed
				return nil, status
			}
			symmetricstate_MixKey(&self.symmetric_state, dh)

		case .psk:
			symmetricstate_MixKeyAndHash(&self.symmetric_state, self.psk[:])
		}
	}
	self.current_message += 1 // Advance after the current message is successful.

	pattern_len := len(pattern_buf)
	payload_len := len(payload)
	msg_len := pattern_len + payload_len
	if payload_len != 0 && cipherstate_HasKey(&self.symmetric_state.cipher_state) {
		msg_len += TAG_SIZE
	}

	msg: []byte
	if msg_len != 0 {
		did_alloc: bool
		if dst != nil {
			if len(dst) < msg_len {
				self.status = .Handshake_Failed
				return nil, .Out_Of_Memory
			}
			msg = dst[:msg_len]
		} else {
			err: runtime.Allocator_Error
			msg, err = make([]byte, msg_len, allocator)
			if err != nil {
				self.status = .Handshake_Failed
				return nil, .Out_Of_Memory
			}
			did_alloc = true
		}

		copy(msg, pattern_buf[:])
		if payload_len != 0 {
			ciphertext := msg[pattern_len:]
			if _, status := symmetricstate_EncryptAndHash(&self.symmetric_state, payload, ciphertext); status != .Ok {
				if did_alloc {
					delete(msg)
				}
				self.status = .Handshake_Failed
				return nil, status
			}
		}
	}

	if self.current_message == len(self.message_pattern.messages) {
		self.current_message = -1
		self.status = .Handshake_Complete
	}

	return msg, self.status
}

// Takes a byte sequence containing a Noise handshake message, and a
// payload_buffer to write the message's plaintext payload into.
// Performs the following steps, aborting if any DecryptAndHash()
// call returns an error:
//  -  Fetches and deletes the next message pattern from message_pattern,
//     then sequentially processes each token from the message pattern:
//    - For "e": Sets re (which must be empty) to the next DHLEN bytes
//      from the message. Calls MixHash(re.public_key).
//    - For "s": Sets temp to the next DHLEN + 16 bytes of the message
//      if HasKey() == True, or to the next DHLEN bytes otherwise.
//      Sets rs (which must be empty) to DecryptAndHash(temp).
//    - For "ee": Calls MixKey(DH(e, re)).
//    - For "es": Calls MixKey(DH(e, rs)) if initiator, MixKey(DH(s, re))
//      if responder.
//    - For "se": Calls MixKey(DH(s, re)) if initiator, MixKey(DH(e, rs))
//      if responder.
//    -For "ss": Calls MixKey(DH(s, rs)).
//  - Calls DecryptAndHash() on the remaining bytes of the message and stores
//    the output into payload_buffer.
//  – (SKIPPED) If there are no more message patterns returns two new
//    CipherState objects by calling Split().
//
// Calling Split() is left to a separate function, although it is technically
// part of the specification.
@(require_results)
handshakestate_ReadMessage :: proc(self: ^Handshake_State, message, dst: []byte, allocator := context.allocator)  -> ([]byte, Status) {
	ensure(self.status == .Handshake_Pending, "crypto/noise: invalid state for ReadMessage")

	if len(message) < MIN_DH_SIZE {
		return nil, .Invalid_Handshake_Message
	}

	protocol := &self.symmetric_state.protocol
	d_len := dh_len(&self.symmetric_state.protocol)

	dh_buf: [MAX_DH_SIZE]byte = ---
	defer crypto.zero_explicit(&dh_buf, size_of(dh_buf))

	msg := message

	pattern := self.message_pattern.messages[self.current_message]
	for token in pattern {
		switch token {
		case .e:
			if len(msg) < d_len {
				return nil, .Invalid_Handshake_Message
			}
			re := msg[:d_len]

			if ecdh.curve(&self.re) != .Invalid {
				panic("crypto/noise: re was not empty when processing token 'e' during ReadMessage")
			}

			ecdh.public_key_set_bytes(&self.re, protocol.dh, re)
			symmetricstate_MixHash(&self.symmetric_state, re)
			if self.message_pattern.is_psk {
				symmetricstate_MixKey(&self.symmetric_state, re)
			}
			msg = msg[d_len:]

		case .s:
			rs_len := d_len
			if cipherstate_HasKey(&self.symmetric_state.cipher_state) {
				rs_len += TAG_SIZE
			}
			if len(msg) < rs_len {
				self.status = .Handshake_Failed
				return nil, .Invalid_Handshake_Message
			}

			rs := dh_buf[:d_len]
			if _, status := symmetricstate_DecryptAndHash(&self.symmetric_state, msg[:rs_len], rs); status != .Ok {
				self.status = .Handshake_Failed
				return nil, status
			}

			if ecdh.curve(&self.rs) != .Invalid {
				panic("crypto/noise: rs was not empty when processing token 's' during ReadMessage")
			}

			ecdh.public_key_set_bytes(&self.rs, protocol.dh, rs)
			msg = msg[rs_len:]

		case .ee:
			dh := dh_buf[:d_len]
			if status := DH(&self.e, &self.re, dh); status != .Ok {
				self.status = .Handshake_Failed
				return nil, status
			}
			symmetricstate_MixKey(&self.symmetric_state, dh)

		case .es:
			dh := dh_buf[:d_len]
			if self.initiator {
				if status := DH(&self.e, &self.rs, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			} else {
				if status := DH(&self.s, &self.re, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			}

		case .se:
			dh := dh_buf[:d_len]
			if self.initiator {
				if status := DH(&self.s, &self.re, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			} else {
				if status := DH(&self.e, &self.rs, dh); status != .Ok {
					self.status = .Handshake_Failed
					return nil, status
				}
				symmetricstate_MixKey(&self.symmetric_state, dh)
			}

		case .ss:
			dh := dh_buf[:d_len]
			if status := DH(&self.s, &self.rs, dh); status != .Ok {
				self.status = .Handshake_Failed
				return nil, status
			}
			symmetricstate_MixKey(&self.symmetric_state, dh)

		case .psk:
			symmetricstate_MixKeyAndHash(&self.symmetric_state, self.psk[:])
		}
	}
	self.current_message += 1 // Advance after the current message is successful.

	payload: []byte
	if len(msg) > 0 {
		payload_len := len(msg)
		if cipherstate_HasKey(&self.symmetric_state.cipher_state) {
			if payload_len < TAG_SIZE {
				self.status = .Handshake_Failed
				return nil, self.status
			}
			payload_len -= TAG_SIZE
		}

		did_alloc: bool
		if dst != nil {
			if len(dst) < payload_len {
				self.status = .Handshake_Failed
				return nil, .Out_Of_Memory
			}
			payload = dst[:payload_len]
		} else {
			err: runtime.Allocator_Error
			payload, err = make([]byte, payload_len, allocator)
			if err != nil {
				self.status = .Handshake_Failed
				return nil, .Out_Of_Memory
			}
			did_alloc = true
		}

		if _, status := symmetricstate_DecryptAndHash(&self.symmetric_state, msg, payload); status != .Ok {
			if did_alloc {
				delete(payload)
			}
			self.status = .Handshake_Failed
			return nil, self.status
		}
	}

	if self.current_message == len(self.message_pattern.messages) {
		self.current_message = -1
		self.status = .Handshake_Complete
	}

	return payload, self.status
}

@(require_results)
protocol_from_string :: proc(self: ^Protocol, protocol_name: string) -> Status {
	str := protocol_name
	self^ = Protocol{}

	if len(str) > 255 {
		return .Invalid_Protocol_String
	}

	s, ok := strings.split_by_byte_iterator(&str, '_')
	if !ok || s != "Noise" {
		return .Invalid_Protocol_String
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid_Protocol_String
	}
	pattern: Handshake_Pattern
	switch s {
	case "N" : pattern = .N
	case "K" : pattern = .K
	case "X" : pattern = .X
	case "XX": pattern = .XX
	case "NK": pattern = .NK
	case "NN": pattern = .NN
	case "KN": pattern = .KN
	case "KK": pattern = .KK
	case "NX": pattern = .NX
	case "KX": pattern = .KX
	case "XN": pattern = .XN
	case "IN": pattern = .IN
	case "XK": pattern = .XK
	case "IK": pattern = .IK
	case "IX": pattern = .IX
	case "Npsk0": pattern = .Npsk0
	case "Kpsk0": pattern = .Kpsk0
	case "Xpsk1": pattern = .Xpsk1
	case "NNpsk0": pattern = .NNpsk0
	case "NNpsk2": pattern = .NNpsk2
	case "NKpsk0": pattern = .NKpsk0
	case "NKpsk2": pattern = .NKpsk2
	case "NXpsk2": pattern = .NXpsk2
	case "XNpsk3": pattern = .XNpsk3
	case "XKpsk3": pattern = .XKpsk3
	case "XXpsk3": pattern = .XXpsk3
	case "KNpsk0": pattern = .KNpsk0
	case "KNpsk2": pattern = .KNpsk2
	case "KKpsk0": pattern = .KKpsk0
	case "KKpsk2": pattern = .KKpsk2
	case "KXpsk2": pattern = .KXpsk2
	case "INpsk1": pattern = .INpsk1
	case "INpsk2": pattern = .INpsk2
	case "IKpsk1": pattern = .IKpsk1
	case "IKpsk2": pattern = .IKpsk2
	case "IXpsk2": pattern = .IXpsk2
	case: return .Invalid_Protocol_String
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid_Protocol_String
	}
	dh: ecdh.Curve
	switch s {
	case "25519": dh = .X25519
	case "448": dh = .X448
	case: return .Invalid_Protocol_String
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid_Protocol_String
	}
	cipher: aead.Algorithm
	switch s {
	case "AESGCM": cipher = .AES_GCM_256
	case "ChaChaPoly": cipher = .CHACHA20POLY1305
	case: return .Invalid_Protocol_String
	}

	if s, ok = strings.split_by_byte_iterator(&str, '_'); !ok {
		return .Invalid_Protocol_String
	}
	hash: hash.Algorithm
	switch s {
	case "SHA512": hash = .SHA512
	case "SHA256": hash = .SHA256
	case "Blake2s": hash = .BLAKE2S
	case "Blake2b": hash = .BLAKE2B
	case: return .Invalid_Protocol_String
	}

	if len(str) != 0 {
		return .Invalid_Protocol_String
	}

	self.handshake_pattern = pattern
	self.dh = dh
	self.cipher = cipher
	self.hash = hash

	return .Ok
}
