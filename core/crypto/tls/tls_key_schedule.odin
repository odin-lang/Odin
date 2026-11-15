#+private
package tls

import "base:runtime"
import "core:crypto"
import "core:crypto/aead"
import "core:crypto/ecdh"
import "core:crypto/hash"
import "core:crypto/hkdf"
import "core:crypto/hmac"
import "core:crypto/mlkem"
import "core:encoding/hex"
import "core:fmt"
import "core:io"
import "core:os"
import "core:slice"

AEAD_IV_SIZE  :: 12
AEAD_TAG_SIZE :: 16

@(private="file")
ZEROES: [hash.MAX_DIGEST_SIZE]byte

AEAD_REKEY_SEQ := #partial [aead.Algorithm]u64 {
	.AES_GCM_128      = 1 << 24, // < 2^24.5
	.AES_GCM_256      = 1 << 24, // < 2^24.5
	.CHACHA20POLY1305 = 1 << 63,
}

AEAD_ABORT_SEQ := #partial [aead.Algorithm]u64 {
	.AES_GCM_128      = 23726566, // ~= 2^24.5
	.AES_GCM_256      = 23726566, // ~= 2^24.5
	.CHACHA20POLY1305 = 0,
}

Ephemeral_Keys :: struct {
	supported_groups: []Named_Group,

	x25519_priv:    ecdh.Private_Key,
	x448_priv:      ecdh.Private_Key,
	secp256r1_priv: ecdh.Private_Key,
	secp384r1_priv: ecdh.Private_Key,

	pqt_x25519mlkem768_decaps: mlkem.Decapsulation_Key,
	pqt_x25519_priv:           ecdh.Private_Key,
}

@(require_results)
init_ephemeral_keys :: proc(keys: ^Ephemeral_Keys, supported_groups: []Named_Group) -> bool {
	did_generate: bool
	for group in supported_groups {
		switch group {
		case .Unallocated_RESERVED:
		case .Secp256r1:
			if ecdh.curve(&keys.secp256r1_priv) != .Invalid {
				return false
			}
			if !ecdh.private_key_generate(&keys.secp256r1_priv, .SECP256R1) {
				return false
			}
			did_generate = true
		case .Secp384r1:
			if ecdh.curve(&keys.secp384r1_priv) != .Invalid {
				return false
			}
			if !ecdh.private_key_generate(&keys.secp384r1_priv, .SECP384R1) {
				return false
			}
			did_generate = true
		case .X25519:
			if ecdh.curve(&keys.x25519_priv) != .Invalid {
				return false
			}
			if !ecdh.private_key_generate(&keys.x25519_priv, .X25519) {
				return false
			}
			did_generate = true
		case .X448:
			if ecdh.curve(&keys.x448_priv) != .Invalid {
				return false
			}
			if !ecdh.private_key_generate(&keys.x448_priv, .X448) {
				return false
			}
			did_generate = true
		case .X25519MLKEM768:
			if ecdh.curve(&keys.pqt_x25519_priv) != .Invalid {
				return false
			}
			if !ecdh.private_key_generate(&keys.pqt_x25519_priv, .X25519) {
				return false
			}
			if !mlkem.decapsulation_key_generate(&keys.pqt_x25519mlkem768_decaps, .ML_KEM_768) {
				return false
			}
			did_generate = true
		case:
			return false
		}
	}

	keys.supported_groups = supported_groups

	return did_generate
}

clear_ephemeral_keys :: proc(keys: ^Ephemeral_Keys) {
	crypto.zero_explicit(keys, size_of(Ephemeral_Keys))
}

Handshake_Keys :: struct {
	secret:    [hash.MAX_DIGEST_SIZE]byte,
	zero_hash: [hash.MAX_DIGEST_SIZE]byte,
	hash:      hash.Algorithm,
}

init_handshake_keys :: proc(
	keys:      ^Handshake_Keys,
	hash_algo: hash.Algorithm,
) {
	keys.hash = hash_algo
	zeroes := ZEROES[:hash.DIGEST_SIZES[hash_algo]]
	hash.hash_bytes_to_buffer(hash_algo, nil, keys.zero_hash[:])
	hkdf.extract(hash_algo, zeroes, zeroes, handshake_keys_secret(keys))
}

clear_handshake_keys :: proc(keys: ^Handshake_Keys) {
	crypto.zero_explicit(keys, size_of(Handshake_Keys))
}

update_handshake_keys :: proc(keys: ^Handshake_Keys, entropy: []byte) {
	LABEL_DERIVED :: []byte{'d', 'e', 'r', 'i', 'v', 'e', 'd'}

	secret := handshake_keys_secret(keys)
	empty_transcript_hash := keys.zero_hash[:len(secret)]

	// secret = Derive-Secret(secret, "derived", "")
	err := hkdf_expand_label(keys.hash, secret, LABEL_DERIVED, empty_transcript_hash, secret)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	// secret = HKDF-Extract(secret, entropy)
	hkdf.extract(keys.hash, secret, entropy, secret)
}

update_handshake_keys_ephemeral :: proc(
	keys:             ^Handshake_Keys,
	private_keys:     ^Ephemeral_Keys,
	named_group:      Named_Group,
	public_key_bytes: []byte,
) -> bool {
	if !slice.contains(private_keys.supported_groups, named_group) {
		return false
	}

	// This is large enough till we support SecP384r1MLKEM1024.
	shared_secret_buf: [64]byte = ---
	defer crypto.zero_explicit(&shared_secret_buf, size_of(shared_secret_buf))

	public_key: ecdh.Public_Key = ---
	shared_secret: []byte
	#partial switch named_group {
	case .X25519MLKEM768:
		kem_sz := mlkem.CIPHERTEXT_SIZES[.ML_KEM_768]
		ecdh_sz := ecdh.PUBLIC_KEY_SIZES[.X25519]
		if len(public_key_bytes) != kem_sz + ecdh_sz {
			return false
		}

		shared_secret = shared_secret_buf[:]

		kem_secret := shared_secret[:mlkem.SHARED_SECRET_SIZE]
		mlkem.decaps(&private_keys.pqt_x25519mlkem768_decaps, public_key_bytes[:kem_sz], kem_secret) or_return

		ecdh_secret := shared_secret[mlkem.SHARED_SECRET_SIZE:]
		ecdh.public_key_set_bytes(&public_key, .X25519, public_key_bytes[kem_sz:]) or_return
		ecdh.ecdh(&private_keys.pqt_x25519_priv, &public_key, ecdh_secret) or_return
	case .X25519:
		ecdh.public_key_set_bytes(&public_key, .X25519, public_key_bytes) or_return
		shared_secret = shared_secret_buf[:ecdh.SHARED_SECRET_SIZES[.X25519]]
		ecdh.ecdh(&private_keys.x25519_priv, &public_key, shared_secret) or_return
	case .X448:
		ecdh.public_key_set_bytes(&public_key, .X448, public_key_bytes) or_return
		shared_secret = shared_secret_buf[:ecdh.SHARED_SECRET_SIZES[.X448]]
		ecdh.ecdh(&private_keys.x448_priv, &public_key, shared_secret) or_return
	case .Secp256r1:
		ecdh.public_key_set_bytes(&public_key, .SECP256R1, public_key_bytes) or_return
		shared_secret = shared_secret_buf[:ecdh.SHARED_SECRET_SIZES[.SECP256R1]]
		ecdh.ecdh(&private_keys.secp256r1_priv, &public_key, shared_secret) or_return
	case .Secp384r1:
		ecdh.public_key_set_bytes(&public_key, .SECP384R1, public_key_bytes) or_return
		shared_secret = shared_secret_buf[:ecdh.SHARED_SECRET_SIZES[.SECP384R1]]
		ecdh.ecdh(&private_keys.secp384r1_priv, &public_key, shared_secret) or_return
	case:
		return false
	}

	update_handshake_keys(keys, shared_secret)

	return true
}

@(require_results, private="file")
handshake_keys_secret :: proc(keys: ^Handshake_Keys) -> []byte {
	return keys.secret[:hash.DIGEST_SIZES[keys.hash]]
}

@(require_results, private="file")
hkdf_expand_label :: proc(
	hash_algo: hash.Algorithm,
	secret:    []byte,
	label:     []byte,
	ctx:       []byte,
	dst:       []byte,
) -> Error {
	PREFIX_LABEL :: []byte{'t', 'l', 's', '1', '3', ' '}
	MAX_LABEL_SIZE :: 2 + 1 + 255 + 1 + 255

	hkdf_label_buf: [MAX_LABEL_SIZE]byte
	buf: Buffer
	buffer_init(&buf, hkdf_label_buf[:])
	defer buffer_sanitize(&buf)

	buffer_write_u16(&buf, u16(len(dst))) or_return

	l := len(PREFIX_LABEL) + len(label)
	if l > int(max(u8)) {
		return io.Error.Short_Buffer
	}
	buffer_write_u8(&buf, u8(l)) or_return
	buffer_write_bytes(&buf, PREFIX_LABEL) or_return
	buffer_write_bytes(&buf, label) or_return

	buffer_write_opaque_bytes(&buf, ctx, 1) or_return

	hkdf.expand(hash_algo, secret, buffer_bytes(&buf), dst)

	return nil
}

Aead_State :: struct {
	ctx: aead.Context,
	iv:  [AEAD_IV_SIZE]byte,
	seq: u64,
	gen: u64,
}

Connection_Secrets :: struct {
	client_secret: [hash.MAX_DIGEST_SIZE]byte,
	server_secret: [hash.MAX_DIGEST_SIZE]byte,
	client_aead:   Aead_State,
	server_aead:   Aead_State,

	hash: hash.Algorithm,
	aead: aead.Algorithm,

	// Debugging.
	client_random:        [RANDOM_SIZE]byte,
	unsafe_secret_logger: ^os.File,
	allocator:            runtime.Allocator,

	is_client: bool,
}

init_connection_secrets :: proc(
	secrets:              ^Connection_Secrets,
	handshake_keys:       ^Handshake_Keys,
	running_hash:         ^hash.Context,
	aead_algo:            aead.Algorithm,
	is_client:            bool,
	allocator:            runtime.Allocator,
	client_random:        []byte,
	unsafe_secret_logger: ^os.File = nil,
) {
	LABEL_CLIENT :: []byte{'c', ' ', 'h', 's', ' ', 't', 'r', 'a', 'f', 'f', 'i', 'c'}
	LABEL_SERVER :: []byte{'s', ' ', 'h', 's', ' ', 't', 'r', 'a', 'f', 'f', 'i', 'c'}

	secrets.hash = handshake_keys.hash
	secrets.aead = aead_algo
	secrets.is_client = is_client
	secrets.unsafe_secret_logger = unsafe_secret_logger
	secrets.allocator = allocator

	hash_len := hash.DIGEST_SIZES[secrets.hash]
	transcript_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
	transcript_hash := transcript_hash_buf[:hash_len]
	hash.final(running_hash, transcript_hash, true)

	secret_client := secrets.client_secret[:hash_len]
	secret_server := secrets.server_secret[:hash_len]

	err := hkdf_expand_label(
		secrets.hash,
		handshake_keys_secret(handshake_keys),
		LABEL_CLIENT,
		transcript_hash,
		secret_client,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	err = hkdf_expand_label(
		secrets.hash,
		handshake_keys_secret(handshake_keys),
		LABEL_SERVER,
		transcript_hash,
		secret_server,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	if client_random != nil || unsafe_secret_logger != nil {
		ensure(len(client_random) == RANDOM_SIZE, "tls: invalid client_random")
		ensure(unsafe_secret_logger != nil, "tls: missing unsafe_secret_logger")
		copy(secrets.client_random[:], client_random)

		random_hex := hex.encode(secrets.client_random[:], allocator)
		defer delete(random_hex, allocator)

		client_hex := hex.encode(secret_client, allocator)
		defer delete(client_hex, allocator)

		server_hex := hex.encode(secret_server, allocator)
		defer delete(server_hex, allocator)

		fmt.fprintf(
			secrets.unsafe_secret_logger,
			"CLIENT_HANDSHAKE_TRAFFIC_SECRET %s %s\n",
			random_hex,
			client_hex,
		)
		fmt.fprintf(
			secrets.unsafe_secret_logger,
			"SERVER_HANDSHAKE_TRAFFIC_SECRET %s %s\n",
			random_hex,
			hex.encode(secret_server, context.temp_allocator),
		)
		os.flush(secrets.unsafe_secret_logger)
	}

	update_connection_aead(secrets, true, false)
	update_connection_aead(secrets, false, false)
}

finished_connection_secrets :: proc(
	secrets:        ^Connection_Secrets,
	handshake_keys: ^Handshake_Keys,
	running_hash:   ^hash.Context,
) {
	LABEL_CLIENT :: []byte{'c', ' ', 'a', 'p', ' ', 't', 'r', 'a', 'f', 'f', 'i', 'c'}
	LABEL_SERVER :: []byte{'s', ' ', 'a', 'p', ' ', 't', 'r', 'a', 'f', 'f', 'i', 'c'}

	hash_len := hash.DIGEST_SIZES[secrets.hash]
	zeroes := ZEROES[:hash_len]

	transcript_hash_buf: [hash.MAX_DIGEST_SIZE]byte = ---
	transcript_hash := transcript_hash_buf[:hash_len]
	hash.final(running_hash, transcript_hash)

	// Derive the master secret.
	update_handshake_keys(handshake_keys, zeroes)

	secret_client := secrets.client_secret[:hash_len]
	secret_server := secrets.server_secret[:hash_len]

	err := hkdf_expand_label(
		secrets.hash,
		handshake_keys_secret(handshake_keys),
		LABEL_CLIENT,
		transcript_hash,
		secret_client,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	err = hkdf_expand_label(
		secrets.hash,
		handshake_keys_secret(handshake_keys),
		LABEL_SERVER,
		transcript_hash,
		secret_server,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	secrets.client_aead.gen = 0
	secrets.server_aead.gen = 0

	update_connection_aead(secrets, true)
	update_connection_aead(secrets, false)
}

can_update_connection_secret :: proc(
	secrets: ^Connection_Secrets,
	is_send: bool,
) -> bool {
	AEAD_MAX_EPOCH := #partial [aead.Algorithm]u64 {
		.AES_GCM_128 = (1 << 48), // 4.7.3
		.AES_GCM_256 = 0,
		.CHACHA20POLY1305 = 0,
	}

	aead_state := is_send == secrets.is_client ? &secrets.client_aead : &secrets.server_aead
	return aead_state.gen + 1 != AEAD_MAX_EPOCH[secrets.aead]
}

should_update_connection_secret :: proc(
	secrets: ^Connection_Secrets,
	is_send: bool,
) -> bool {
	if !can_update_connection_secret(secrets, is_send) {
		return false
	}

	aead_state := is_send == secrets.is_client ? &secrets.client_aead : &secrets.server_aead
	return aead_state.seq >= AEAD_REKEY_SEQ[secrets.aead]
}

update_connection_secret :: proc(
	secrets: ^Connection_Secrets,
	is_send: bool,
) {
	LABEL_UPDATE :: []byte{'t', 'r', 'a', 'f', 'f', 'i', 'c', ' ', 'u', 'p', 'd'}

	hash_len := hash.DIGEST_SIZES[secrets.hash]

	secret: []byte
	switch secrets.is_client {
	case true:
		secret = is_send ? secrets.client_secret[:hash_len] : secrets.server_secret[:hash_len]
	case false:
		secret = is_send ? secrets.server_secret[:hash_len] : secrets.client_secret[:hash_len]
	}

	err := hkdf_expand_label(
		secrets.hash,
		secret,
		LABEL_UPDATE,
		nil,
		secret,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	update_connection_aead(secrets, is_send == secrets.is_client)
}

update_connection_aead :: proc(
	secrets:   ^Connection_Secrets,
	is_client: bool,
	debug_log := true,
) {
	tmp: [32]byte
	defer crypto.zero_explicit(&tmp, size_of(tmp))
	key := tmp[:aead.KEY_SIZES[secrets.aead]]

	hash_len := hash.DIGEST_SIZES[secrets.hash]

	aead_state := is_client ? &secrets.client_aead : &secrets.server_aead
	secret := is_client ? secrets.client_secret[:hash_len] : secrets.server_secret[:hash_len]

	err := hkdf_expand_label(
		secrets.hash,
		secret,
		[]byte{'k', 'e', 'y'},
		nil,
		key,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")
	aead.init(&aead_state.ctx, secrets.aead, key)

	err = hkdf_expand_label(
		secrets.hash,
		secret,
		[]byte{'i', 'v',},
		nil,
		aead_state.iv[:],
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	if secrets.unsafe_secret_logger != nil && debug_log {
		random_hex := hex.encode(secrets.client_random[:], secrets.allocator)
		defer delete(random_hex, secrets.allocator)

		secret_hex := hex.encode(secret, secrets.allocator)
		defer delete(secret_hex, secrets.allocator)

		if is_client {
			fmt.fprintf(
				secrets.unsafe_secret_logger,
				"CLIENT_TRAFFIC_SECRET_%d %s %s\n",
				secrets.client_aead.gen,
				random_hex,
				secret_hex,
			)
		} else {
			fmt.fprintf(
				secrets.unsafe_secret_logger,
				"SERVER_TRAFFIC_SECRET_%d %s %s\n",
				secrets.server_aead.gen,
				random_hex,
				secret_hex,
			)
		}
		os.flush(secrets.unsafe_secret_logger)
	}

	aead_state.seq = 0
	aead_state.gen += 1
}

derive_connection_finished :: proc(secrets: ^Connection_Secrets, transcript_hash: ^hash.Context, dst: []byte, is_client: bool) {
	tmp: [hash.MAX_DIGEST_SIZE]byte
	defer crypto.zero_explicit(&tmp, size_of(tmp))

	hash_len := hash.DIGEST_SIZES[secrets.hash]

	key := tmp[:hash_len]
	secret := is_client ? secrets.client_secret[:hash_len] : secrets.server_secret[:hash_len]

	err := hkdf_expand_label(
		secrets.hash,
		secret,
		[]byte{'f', 'i', 'n', 'i', 's', 'h', 'e', 'd'},
		nil,
		key,
	)
	ensure(err == nil, "tls: HKDF-Expand-Label failed")

	hash.final(transcript_hash, dst, true)
	hmac.sum(secrets.hash, dst, dst, key)
}

@(require_results)
verify_connection_finished :: proc(secrets: ^Connection_Secrets, transcript_hash: ^hash.Context, verify_data: []byte, is_client: bool) -> bool {
	tmp: [hash.MAX_DIGEST_SIZE]byte

	hash_len := hash.DIGEST_SIZES[secrets.hash]
	derived := tmp[:hash_len]

	derive_connection_finished(secrets, transcript_hash, derived, !is_client)

	return crypto.compare_constant_time(derived, verify_data) == 1
}

clear_connection_secrets :: proc(secrets: ^Connection_Secrets) {
	crypto.zero_explicit(&secrets.client_secret, size_of(secrets.client_secret))
	crypto.zero_explicit(&secrets.server_secret, size_of(secrets.server_secret))
	aead.reset(&secrets.client_aead.ctx)
	aead.reset(&secrets.server_aead.ctx)

	if secrets.unsafe_secret_logger != nil {
		os.close(secrets.unsafe_secret_logger)
		secrets.unsafe_secret_logger = nil
	}
}
