package noise

import "core:bytes"
import "core:crypto"
import "core:crypto/aead"
import "core:crypto/ecdh"
import "core:crypto/hash"
import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:testing"

@(private = "file")
DH_CURVES :: []ecdh.Curve {
	.X25519,
	.X448,
}
@(private = "file")
CIPHERS :: []aead.Algorithm{
	.AES_GCM_256,
	.CHACHA20POLY1305,
}
@(private = "file")
HASHES :: []hash.Algorithm{
	.SHA256,
	.SHA512,
	.BLAKE2S,
	.BLAKE2B,
}

@(test)
test_supported_protocols :: proc(t: ^testing.T) {
	if !crypto.HAS_RAND_BYTES {
		log.info("rand_bytes not supported - skipping")
		return
	}

	protocol: Test_Protocol
	for pattern in Handshake_Pattern {
		if pattern == .Invalid {
			continue
		}
		protocol.handshake_pattern = pattern
		for dh in DH_CURVES {
			protocol.dh = dh
			for cipher in CIPHERS {
				protocol.cipher = cipher
				for hash in HASHES {
					protocol.hash = hash
					if !testing.expectf(
						t,
						test_noise_one_protocol(t, &protocol, context.temp_allocator),
						"Failed protocol: %v", protocol,
					) {
						testing.fail(t)
						break
					}
				}
			}
		}
	}
}

@(private = "file")
test_noise_one_protocol :: proc(t: ^testing.T, protocol: ^Test_Protocol, allocator := context.allocator) -> bool {
	protocol_name := test_protocol_string(protocol, allocator)
	defer delete(protocol_name, allocator)

	log.debugf("crypto/noise: %s", protocol_name)

	is_one_way := pattern_is_one_way(protocol.handshake_pattern)

	initiator_s, responder_s: ecdh.Private_Key
	ini_s, res_s: ^ecdh.Private_Key
	ini_s_pub, res_s_pub: ^ecdh.Public_Key

	pre, hs := pattern_requires_initiator_s(protocol.handshake_pattern)
	if pre || hs {
		if !testing.expect(t, ecdh.private_key_generate(&initiator_s, protocol.dh), "failed to generate initiator s") {
			return false
		}
		ini_s = &initiator_s
		if pre {
			ini_s_pub = &initiator_s._pub_key
		}
	}
	pre, hs = pattern_requires_responder_s(protocol.handshake_pattern)
	if pre || hs {
		if !testing.expect(t, ecdh.private_key_generate(&responder_s, protocol.dh), "failed to generate responder s") {
			return false
		}
		res_s = &responder_s
		if pre {
			res_s_pub = &responder_s._pub_key
		}
	}

	psk_buf: [32]byte = ---
	psk: []byte
	if pattern_is_psk(protocol.handshake_pattern) {
		crypto.rand_bytes(psk_buf[:])
		psk = psk_buf[:]
	}

	ini_hs, res_hs: Handshake_State
	status := handshake_init(&ini_hs, true, nil, ini_s, res_s_pub, protocol_name, psk)
	if !testing.expectf(t, status == .Ok, "failed to initialize initiator Handshake_State: %v", status) {
		return false
	}
	status = handshake_init(&res_hs, false, nil, res_s, ini_s_pub, protocol_name, psk)
	if !testing.expectf(t, status == .Ok, "failed to initialize responder Handshake_State: %v", status) {
		return false
	}

	ini_status, res_status: Status
	ini_msg, res_msg: []byte
	ini_payload, res_payload: []byte
	hs_msg_buf: [MAX_STEP_MSG_SIZE]byte
	for i := 0; ; i += 1{
		if ini_status == .Handshake_Complete && res_status == .Handshake_Complete {
			break
		}

		// Test the allocation path
		res_msg, res_payload, ini_status = handshake_initiator_step(&ini_hs, ini_msg, allocator = allocator)
		ini_msg = nil

		if ini_status == .Handshake_Complete && res_status == .Handshake_Complete {
			break
		}

		if !testing.expectf(t, len(res_payload) == 0, "step %d: unexpected responder payload: %x", i, res_payload) {
			return false
		}
		if !testing.expectf(t, ini_status == .Handshake_Pending || ini_status == .Handshake_Complete, "step %d: initiator step failed: %v", i, ini_status) {
			return false
		}

		// Test the non-allocation path
		ini_msg, ini_payload, res_status = handshake_responder_step(&res_hs, res_msg, nil, hs_msg_buf[:])
		delete(res_msg, allocator)
		res_msg = nil

		if !testing.expectf(t, len(ini_payload) == 0, "step %d: unexpected initiator payload: %x", i, ini_payload) {
			return false
		}
		if !testing.expectf(t, res_status == .Handshake_Pending || res_status == .Handshake_Complete, "step %d: responder step failed: %v", i, res_status) {
			return false
		}
	}
	delete(res_msg, allocator)

	hs_pub: ^ecdh.Public_Key
	if ini_s != nil {
		hs_pub, status = handshake_peer_identity(&res_hs)
		if !testing.expect(t, status == .Ok) {
			return false
		}
		if !testing.expectf(t, ecdh.public_key_equal(&ini_s._pub_key, hs_pub), "responder has incorrect initiator identity") {
			return false
		}
	}
	if res_s != nil {
		hs_pub, status = handshake_peer_identity(&ini_hs)
		if !testing.expect(t, status == .Ok) {
			return false
		}
		if !testing.expectf(t, ecdh.public_key_equal(&res_s._pub_key, hs_pub), "initiator has incorrect responder identity") {
			return false
		}
	}

	h1, h2: []byte
	h1, status = handshake_hash(&ini_hs)
	if !testing.expect(t, status == .Ok) {
		return false
	}
	h2, status = handshake_hash(&res_hs)
	if !testing.expect(t, status == .Ok) {
		return false
	}
	if !testing.expectf(t, bytes.equal(h1, h2), "handshake hash mismatch: %x != %x", h1, h2) {
		return false
	}

	ini_cs, res_cs: Cipher_States
	if !testing.expectf(t, .Ok == handshake_split(&ini_hs, &ini_cs), "failed to split initiator: %v") {
		return false
	}
	if !testing.expectf(t, .Ok == handshake_split(&res_hs, &res_cs), "failed to split responder: %v") {
		return false
	}

	handshake_reset(&ini_hs)
	handshake_reset(&res_hs)

	if !testing.expect(t, test_messages(t, &ini_cs, &res_cs, is_one_way, allocator), "message tests failed") {
		return false
	}

	cipherstates_reset(&ini_cs)
	cipherstates_reset(&res_cs)

	return true
}

@(private = "file")
test_messages :: proc(t: ^testing.T, ini_cs, res_cs: ^Cipher_States, is_one_way: bool, allocator := context.allocator) -> bool {
	ad_buf: [256]byte = ---
	payload_buf: [MAX_PACKET_SIZE-TAG_SIZE]byte = ---

	for i in 0..<10 {
		ad := ad_buf[:rand.int_max(len(ad_buf))]
		payload := payload_buf[:rand.int_max(len(payload_buf))]

		_ = rand.read(payload)
		_ = rand.read(ad)

		// Initiator -> Responder (allocate buffers)
		tx_msg, status := seal_message(ini_cs, ad, payload, allocator = allocator)
		defer delete(tx_msg, allocator)
		if !testing.expectf(t, status == .Ok, "i->r %d: seal failed: %v", i, status) {
			return false
		}

		rx_dst: []byte
		rx_dst, status = open_message(res_cs, ad, tx_msg, allocator = allocator)
		defer delete(rx_dst, allocator)
		if !testing.expectf(t, status == .Ok, "i->r %d: open failed: %v", i, status) {
			return false
		}

		if !testing.expectf(t, bytes.equal(rx_dst, payload), "i->r %d: payload mismatch") {
			return false
		}

		if i == 5 {
			status = cipherstates_rekey(ini_cs, true)
			if !testing.expectf(t, status == .Ok, "i %d: rekey failed: %v", i, status) {
				return false
			}
			status = cipherstates_rekey(res_cs, false)
			if !testing.expectf(t, status == .Ok, "r %d: rekey failed: %v", i, status) {
				return false
			}
		}

		if is_one_way {
			continue
		}

		// Responder -> Initiator (reuse allocated buffers)
		tx_msg, status = seal_message(res_cs, ad, payload, tx_msg)
		if !testing.expectf(t, status == .Ok, "r->i %d: seal failed: %v", i, status) {
			return false
		}

		_, status = open_message(ini_cs, ad, tx_msg, rx_dst)
		if !testing.expectf(t, status == .Ok, "r->i %d: open failed: %v", i, status) {
			return false
		}

		if !testing.expectf(t, bytes.equal(rx_dst, payload), "r-i %d: payload mismatch") {
			return false
		}
	}

	return true
}

@(private = "file")
Test_Protocol :: struct {
	handshake_pattern: Handshake_Pattern,
	dh: ecdh.Curve,
	cipher: aead.Algorithm,
	hash: hash.Algorithm,
}

@(private = "file")
test_protocol_string :: proc(protocol: ^Test_Protocol, allocator := context.allocator) -> string {
	dh: string
	#partial switch protocol.dh {
	case .X25519: dh = "25519"
	case .X448: dh = "448"
	case: panic("crypto/noise: unsupported DH")
	}

	cipher: string
	#partial switch protocol.cipher {
	case .AES_GCM_256: cipher = "AESGCM"
	case .CHACHA20POLY1305: cipher = "ChaChaPoly"
	case: panic("crypto/noise: unsupported cipher")
	}

	hash: string
	#partial switch protocol.hash {
	case .SHA256: hash = "SHA256"
	case .SHA512: hash = "SHA512"
	case .BLAKE2S: hash = "Blake2s"
	case .BLAKE2B: hash = "Blake2b"
	case: panic("crypto/noise: unsupported hash")
	}

	return fmt.aprintf("Noise_%v_%v_%v_%v", protocol.handshake_pattern, dh, cipher, hash, allocator = allocator)
}
