package test_core_crypto

import "core:encoding/hex"
import "core:fmt"
import "core:testing"

import "core:crypto/hash"
import "core:crypto/pbkdf2"

@(test)
test_kdf :: proc(t: ^testing.T) {
	log(t, "Testing KDFs")

	test_pbkdf2(t)
}

@(test)
test_pbkdf2 :: proc(t: ^testing.T) {
	log(t, "Testing PBKDF2")

	tmp: [64]byte // 512-bits is enough for every output for now.

	test_vectors := []struct {
		algo:       hash.Algorithm,
		password:   string,
		salt:       string,
		iterations: u32,
		dk:         string,
	} {
		// SHA-1
		// - https://www.rfc-editor.org/rfc/rfc2898
		{
			hash.Algorithm.Insecure_SHA1,
			"password",
			"salt",
			1,
			"0c60c80f961f0e71f3a9b524af6012062fe037a6",
		},
		{
			hash.Algorithm.Insecure_SHA1,
			"password",
			"salt",
			2,
			"ea6c014dc72d6f8ccd1ed92ace1d41f0d8de8957",
		},
		{
			hash.Algorithm.Insecure_SHA1,
			"password",
			"salt",
			4096,
			"4b007901b765489abead49d926f721d065a429c1",
		},
		// This passes but takes a about 8 seconds on a modern-ish system.
		//
		// {
		// 	hash.Algorithm.Insecure_SHA1,
		// 	"password",
		// 	"salt",
		// 	16777216,
		// 	"eefe3d61cd4da4e4e9945b3d6ba2158c2634e984",
		// },
		{
			hash.Algorithm.Insecure_SHA1,
			"passwordPASSWORDpassword",
			"saltSALTsaltSALTsaltSALTsaltSALTsalt",
			4096,
			"3d2eec4fe41c849b80c8d83662c0e44a8b291a964cf2f07038",
		},
		{
			hash.Algorithm.Insecure_SHA1,
			"pass\x00word",
			"sa\x00lt",
			4096,
			"56fa6aa75548099dcc37d7f03425e0c3",
		},

		// SHA-256
		// - https://www.rfc-editor.org/rfc/rfc7914
		{
			hash.Algorithm.SHA256,
			"passwd",
			"salt",
			1,
			"55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783",
		},
		{
			hash.Algorithm.SHA256,
			"Password",
			"NaCl",
			80000,
			"4ddcd8f60b98be21830cee5ef22701f9641a4418d04c0414aeff08876b34ab56a1d425a1225833549adb841b51c9b3176a272bdebba1d078478f62b397f33c8d",
		},
	}
	for v, _ in test_vectors {
		algo_name := hash.ALGORITHM_NAMES[v.algo]
		dst := tmp[:len(v.dk) / 2]

		password := transmute([]byte)(v.password)
		salt := transmute([]byte)(v.salt)

		pbkdf2.derive(v.algo, password, salt, v.iterations, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		expect(
			t,
			dst_str == v.dk,
			fmt.tprintf(
				"HMAC-%s: Expected: %s for input of (%s, %s, %d), but got %s instead",
				algo_name,
				v.dk,
				v.password,
				v.salt,
				v.iterations,
				dst_str,
			),
		)
	}
}
