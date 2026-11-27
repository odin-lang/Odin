package test_core_crypto

import "core:crypto/ecdsa"
import "core:crypto/hash"
import "core:mem"
import "core:os"
import "core:testing"

@(test)
test_leak_hash_file_read_error :: proc(t: ^testing.T) {
	dir, dir_err := os.temp_directory(context.temp_allocator)
	if !testing.expect_value(t, dir_err, nil) {
		return
	}
	path, join_err := os.join_path({dir, "odin_crypto_hash_leak_test.bin"}, context.temp_allocator)
	if !testing.expect_value(t, join_err, nil) {
		return
	}
	if !testing.expect_value(t, os.write_entire_file(path, "some data to hash"), nil) {
		return
	}
	defer os.remove(path)

	f, open_err := os.open(path, {.Write})
	if !testing.expect_value(t, open_err, nil) {
		return
	}
	defer os.close(f)

	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	defer mem.tracking_allocator_destroy(&track)
	track.bad_free_callback = mem.tracking_allocator_bad_free_callback_add_to_array

	digest, err := hash.hash_file_by_handle(.SHA256, f, true, mem.tracking_allocator(&track))
	testing.expect(t, err != nil)
	testing.expect(t, digest == nil)
	testing.expect(t, track.total_allocation_count > 0)
	testing.expect_value(t, len(track.allocation_map), 0)
	testing.expect_value(t, len(track.bad_free_array), 0)
}

@(private="file")
oom_allocator_proc :: proc(
	allocator_data: rawptr,
	mode: mem.Allocator_Mode,
	size, alignment: int,
	old_memory: rawptr,
	old_size: int,
	loc := #caller_location,
) -> ([]byte, mem.Allocator_Error) {
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		return nil, .Out_Of_Memory
	}
	return nil, nil
}

@(test)
test_ecdsa_sign_asn1_oom :: proc(t: ^testing.T) {
	oom := mem.Allocator{procedure = oom_allocator_proc}
	msg := transmute([]byte)string("sign me")
	key_bytes: [48]byte
	for i in 0 ..< len(key_bytes) {
		key_bytes[i] = byte(i + 1)
	}
	for curve in ([]ecdsa.Curve{.SECP256R1, .SECP384R1}) {
		priv_key: ecdsa.Private_Key
		defer ecdsa.private_key_clear(&priv_key)
		ok := ecdsa.private_key_set_bytes(&priv_key, curve, key_bytes[:ecdsa.PRIVATE_KEY_SIZES[curve]])
		if !testing.expectf(t, ok, "%v: private_key_set_bytes", curve) {
			continue
		}

		sig, sig_ok := ecdsa.sign_asn1(&priv_key, .SHA256, msg, oom, true)
		testing.expectf(t, !sig_ok && sig == nil, "%v: OOM gave %v, %x", curve, sig_ok, sig)

		sig, sig_ok = ecdsa.sign_asn1(&priv_key, .SHA256, msg, context.allocator, true)
		testing.expectf(t, sig_ok && len(sig) > 0, "%v: sign_asn1 failed", curve)
		testing.expectf(t, ecdsa.verify_asn1(&priv_key._pub_key, .SHA256, msg, sig), "%v: verify_asn1 failed", curve)
		delete(sig)
	}
}
