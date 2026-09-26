package test_noise

import "core:crypto/ecdh"
import "core:crypto/noise"
import "core:log"
import "core:mem"
import "core:os"
import "core:strings"
import "core:testing"

import "../common"

ARENA_SIZE :: 8 * 1024 * 1024

BASE_PATH :: ODIN_ROOT + "tests/core/assets/Noise"

@(test)
print_test_vector_path :: proc(t: ^testing.T) {
	log.infof("noise path: %s", BASE_PATH)
}

@(test)
test_vectors_snow :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("noise/snow: starting")

	F :: "snow.txt"
	fn, _ := os.join_path([]string{BASE_PATH, F}, context.allocator)
	defer delete(fn)
	test_vectors: Test_Vectors
	testing.expectf(t, load(&test_vectors, fn), "unable to load {}", fn)

	run_test_vectors(t, F, &test_vectors)
}

@(test)
test_vectors_noise_c_basic :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("noise/noise-c-basic: starting")

	F :: "noise-c-basic.txt"
	fn, _ := os.join_path([]string{BASE_PATH, F}, context.allocator)
	defer delete(fn)
	test_vectors: Test_Vectors
	testing.expectf(t, load(&test_vectors, fn), "unable to load {}", fn)

	run_test_vectors(t, F, &test_vectors)
}

@(test)
test_vectors_cacophony :: proc(t: ^testing.T) {
	arena: mem.Arena
	arena_backing := make([]byte, ARENA_SIZE)
	defer delete(arena_backing)
	mem.arena_init(&arena, arena_backing)
	context.allocator = mem.arena_allocator(&arena)

	log.debug("noise/cacophony: starting")

	F :: "cacophony.txt"
	fn, _ := os.join_path([]string{BASE_PATH, F}, context.allocator)
	defer delete(fn)
	test_vectors: Test_Vectors
	testing.expectf(t, load(&test_vectors, fn), "unable to load {}", fn)

	run_test_vectors(t, F, &test_vectors)
}

run_test_vectors :: proc(t: ^testing.T, f: string, tvs: ^Test_Vectors) {
	num_ran, num_passed, num_failed, num_skipped: int
	tv_loop: for &v, i in tvs.vectors {
		num_ran += 1

		protocol_name: string
		switch {
		case v.protocol_name != "":
			protocol_name = v.protocol_name
		case v.name != "":
			// Old test vector format used by the C impl.
			v.protocol_name = v.name
			protocol_name = v.name
		}

		// Skip unsupported test vectors
		if v.fail {
			num_skipped += 1
			log.debugf("%s[%d]: %s - skipped, fail tests not supported", f, i, protocol_name)
			continue
		}
		if v.fallback {
			num_skipped += 1
			log.debugf("%s[%d]: %s - skipped, fallback patterns not supported", f, i, protocol_name)
			continue
		}
		if strings.has_prefix(protocol_name, "NoisePSK") {
			num_skipped += 1
			log.debugf("%s[%d]: %s - skipped, Old PSK not supported", f, i, protocol_name)
			continue
		}
		if len(v.init_psks) > 1 || len(v.resp_psks) > 1 {
			num_skipped += 1
			log.debugf("%s[%d]: %s - skipped, Multi-PSK not supported", f, i, protocol_name)
			continue
		}

		// Initialize Handshake_Statuses
		pattern, dh, _, _, status := noise.split_protocol_string(protocol_name)
		if !testing.expectf(t, status == .Ok, "%s[%d]: failed to parse protocol '%s': %v", f, i, protocol_name, status) {
			num_failed += 1
			continue
		}
		ini_hs, res_hs: noise.Handshake_State
		if !testing.expect(t, handshake_states_from_tv(t, &ini_hs, &res_hs, &v, dh, f, i)) {
			num_failed += 1
			continue
		}
		defer noise.handshake_reset(&ini_hs)
		defer noise.handshake_reset(&res_hs)

		// Play back the messages
		if !testing.expectf(
			t,
			replay_messages_from_tv_rw(t, &ini_hs, &v, pattern, f),
			"%s[%d]: %s - failed to playback messages (initiator)", f, i, protocol_name,
		) {
			num_failed += 1
			continue
		}
		if !testing.expectf(
			t,
			replay_messages_from_tv_rw(t, &res_hs, &v, pattern, f),
			"%s[%d]: %s - failed to playback messages (responder)", f, i, protocol_name,
		) {
			num_failed += 1
			continue
		}

		// Check handshake hash/peer identities.
		if v.handshake_hash != "" {
			ini_hash, _ := noise.handshake_hash(&ini_hs)
			res_hash, _ := noise.handshake_hash(&res_hs)
			if !testing.expectf(
				t,
				common.hexbytes_compare(v.handshake_hash, ini_hash),
				"%s[%d]: %s - invalid initiator handshake hash: %x expected: %s", f, i, protocol_name, ini_hash, v.handshake_hash,
			) {
				num_failed += 1
				continue
			}
			if !testing.expectf(
				t,
				common.hexbytes_compare(v.handshake_hash, res_hash),
				"%s[%d]: %s - invalid responder handshake hash: %x expected: %s", f, i, protocol_name, res_hash, v.handshake_hash,
			) {
				num_failed += 1
				continue
			}
		}
		if ecdh.curve(&ini_hs.s) != .Invalid {
			pub_key, _ := noise.handshake_peer_identity(&res_hs)
			if !testing.expectf(
				t,
				pub_key != nil && ecdh.public_key_equal(&ini_hs.s._pub_key, pub_key),
				"%s[%d]: %s - invalid initiator static public key known by responder", f, i, protocol_name,
			) {
				num_failed += 1
				continue
			}
		}
		if ecdh.curve(&res_hs.s) != .Invalid {
			pub_key, _ := noise.handshake_peer_identity(&ini_hs)
			if !testing.expectf(
				t,
				pub_key != nil && ecdh.public_key_equal(&res_hs.s._pub_key, pub_key),
				"%s[%d]: %s - invalid responder static public key known by initiator", f, i, protocol_name,
			) {
				num_failed += 1
				continue
			}
		}

		log.debugf("%s[%d]: %s - Passed", f, i, protocol_name)
		num_passed += 1
	}

	assert(num_ran == len(tvs.vectors))
	assert(num_passed + num_failed + num_skipped == num_ran)

	log.infof(
		"%s: ran %d, passed %d, failed %d, skipped %d",
		f,
		num_ran,
		num_passed,
		num_failed,
		num_skipped,
	)
}

handshake_states_from_tv :: proc(
	t: ^testing.T,
	ini_hs, res_hs: ^noise.Handshake_State,
	v: ^Vector,
	dh: ecdh.Curve,
	f: string,
	i: int,
) -> bool {
	protocol_name := v.protocol_name

	ini_static, ini_ephemeral: ecdh.Private_Key
	res_static, res_ephemeral: ecdh.Private_Key
	ini_res_static, res_ini_static: ecdh.Public_Key

	ini_s, ini_e: ^ecdh.Private_Key
	ini_s_p, ini_e_p: ^ecdh.Public_Key
	ini_r_s: ^ecdh.Public_Key
	if len(v.init_static) != 0 {
		if !testing.expectf(
			t,
			ecdh.private_key_set_bytes(&ini_static, dh, common.hexbytes_decode(v.init_static)),
			"%s[%d]: %s - failed to parse init_static", f, i,  protocol_name,
		) {
			return false
		}
		ini_s = &ini_static
		ini_s_p = &ini_s._pub_key
	}
	if len(v.init_ephemeral) != 0 {
		if !testing.expectf(
			t,
			ecdh.private_key_set_bytes(&ini_ephemeral, dh, common.hexbytes_decode(v.init_ephemeral)),
			"%s[%d]: %s - failed to parse init_ephemeral", f, i, protocol_name,
		) {
			return false
		}
		ini_e = &ini_ephemeral
		ini_e_p = &ini_e._pub_key
	}
	if len(v.init_remote_static) != 0 {
		if !testing.expectf(
			t,
			ecdh.public_key_set_bytes(&ini_res_static, dh, common.hexbytes_decode(v.init_remote_static)),
			"%s[%d]: %s - failed to parse init_remote_static", f, i, protocol_name,
		) {
			return false
		}
		ini_r_s = &ini_res_static
	}

	res_s, res_e: ^ecdh.Private_Key
	res_s_p, res_e_p: ^ecdh.Public_Key
	res_i_s: ^ecdh.Public_Key
	if len(v.resp_static) != 0 {
		if !testing.expectf(
			t,
			ecdh.private_key_set_bytes(&res_static, dh, common.hexbytes_decode(v.resp_static)),
			"%s[%d]: %s - failed to parse resp_static", f, i, protocol_name,
		) {
			return false
		}
		res_s = &res_static
		res_s_p = &res_s._pub_key
	}
	if len(v.resp_ephemeral) != 0 {
		if !testing.expectf(
			t,
			ecdh.private_key_set_bytes(&res_ephemeral, dh, common.hexbytes_decode(v.resp_ephemeral)),
			"%s[%d]: %s - failed to parse resp_ephemeral", f, i, protocol_name,
		) {
			return false
		}
		res_e = &res_ephemeral
		res_e_p = &res_e._pub_key
	}
	if len(v.resp_remote_static) != 0 {
		if !testing.expectf(
			t,
			ecdh.public_key_set_bytes(&res_ini_static, dh, common.hexbytes_decode(v.resp_remote_static)),
			"%s[%d]: %s - failed to parse remote_init_static", f, i, protocol_name,
		) {
			return false
		}
		res_i_s = &res_ini_static
	}

	ini_psk, res_psk: []byte
	if len(v.init_psks) > 0 {
		ini_psk = common.hexbytes_decode(v.init_psks[0])
	}
	if len(v.resp_psks) > 0 {
		res_psk = common.hexbytes_decode(v.resp_psks[0])
	}

	status := noise.handshake_init(
		ini_hs,
		true,
		common.hexbytes_decode(v.init_prologue),
		ini_s,
		ini_r_s,
		protocol_name,
		ini_psk,
		ini_e,
	)
	if !testing.expectf(
		t,
		status == .Ok,
		"%s[%d]: %s - failed to initialize ini_hs: %v", f, i, protocol_name, status,
	) {
		return false
	}

	status = noise.handshake_init(
		res_hs,
		false,
		common.hexbytes_decode(v.resp_prologue),
		res_s,
		res_i_s,
		protocol_name,
		res_psk,
		res_e,
	)
	if !testing.expectf(
		t,
		status == .Ok,
		"%s[%d]: %s - failed to initialize res_hs: %v", f, i, protocol_name, status,
	) {
		return false
	}

	return true
}

replay_messages_from_tv_rw :: proc(
	t: ^testing.T,
	hs: ^noise.Handshake_State,
	v: ^Vector,
	pattern: noise.Handshake_Pattern,
	f: string,
) -> bool {
	protocol_name := v.protocol_name
	pattern_is_one_way := noise.pattern_is_one_way(pattern)
	is_initiator := hs.initiator

	cs: noise.Cipher_States

	defer noise.cipherstates_reset(&cs)

	hs_done: bool
	for &msg, i in &v.messages {
		dst: []byte
		status: noise.Status
		expected: common.Hex_Bytes

		switch hs_done {
		case false:
			if (i & 1 == 0) == is_initiator {
				dst, status = noise.handshake_write_message(hs, common.hexbytes_decode(msg.payload))
				expected = msg.ciphertext
			} else {
				dst, status = noise.handshake_read_message(hs, common.hexbytes_decode(msg.ciphertext))
				expected = msg.payload
			}
			defer delete(dst)

			if !testing.expectf(
				t,
				status == .Handshake_Pending || status == .Handshake_Complete,
				 "%s: %s[%d] - unexpected handshake status: %v", f, protocol_name, i, status,
			) {
				return false
			}
			if !testing.expectf(
				t,
				common.hexbytes_compare(expected, dst),
				"%s: %s[%d] - unexpected message/payload: %x expected: %s", f, protocol_name, i, dst, expected,
			) {
				return false
			}
			if status == .Handshake_Complete {
				status = noise.handshake_split(hs, &cs)
				if !testing.expectf(
					t,
					status == .Ok,
					"%s: %s[%d] - handshake_split failed: %v", f, protocol_name, i, status,
				) {
					return false
				}
				hs_done = true
			}
		case true:
			// The messages that use the derived cipherstates just follow the
			// handshake message(s), and the flow continues.
			if pattern_is_one_way {
				// Except one-way patterns which go from initiator to responder.
				if is_initiator {
					dst, status = noise.seal_message(&cs, nil, common.hexbytes_decode(msg.payload))
					expected = msg.ciphertext
				} else {
					dst, status = noise.open_message(&cs, nil, common.hexbytes_decode(msg.ciphertext))
					expected = msg.payload
				}
			} else {
				if (i & 1 == 0) == is_initiator {
					dst, status = noise.seal_message(&cs, nil, common.hexbytes_decode(msg.payload))
					expected = msg.ciphertext
				} else {
					dst, status = noise.open_message(&cs, nil, common.hexbytes_decode(msg.ciphertext))
					expected = msg.payload
				}
			}
			defer delete(dst)

			if !testing.expectf(
				t,
				status == .Ok,
				"%s: %s[%d] - seal/open failed: %v", f, protocol_name, i, status,
			) {
				return false
			}
			if !testing.expectf(
				t,
				common.hexbytes_compare(expected, dst),
				"%s: %s[%d] - unexpected ciphertext/plaintext: %x expected: %s", f, protocol_name, i, dst, expected,
			) {
				return false
			}
		}
	}

	return true
}
