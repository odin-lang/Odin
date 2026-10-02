package test_core_crypto

import "base:runtime"
import "core:encoding/hex"
import "core:testing"
import "core:crypto/argon2id"
import "core:crypto/hash"
import "core:crypto/hkdf"
import "core:crypto/pbkdf2"
import "core:crypto/scrypt"

@(test)
test_argon2id :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	test_vectors := []struct {
		params:   ^argon2id.Parameters,
		password: string,
		salt:     string,
		secret:   string,
		ad:       string,
		tag:      string,
	} {
		// RFC 9106 5.3.
		{
			&argon2id.Parameters{
				32,
				3,
				4,
			},
			"0101010101010101010101010101010101010101010101010101010101010101",
			"02020202020202020202020202020202",
			"0303030303030303",
			"040404040404040404040404",
			"0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659",
		},
	}
	for v, _ in test_vectors {
		tag := make([]byte, len(v.tag)/2, context.temp_allocator)

		password, _ := hex.decode(transmute([]byte)(v.password), context.temp_allocator)
		salt, _ := hex.decode(transmute([]byte)(v.salt), context.temp_allocator)
		secret, _ := hex.decode(transmute([]byte)(v.secret), context.temp_allocator)
		ad, _ := hex.decode(transmute([]byte)(v.ad), context.temp_allocator)

		_ = argon2id.derive(v.params, password, salt, tag, secret, ad)

		tag_str := string(hex.encode(tag, context.temp_allocator))

		testing.expectf(
			t,
			tag_str == v.tag,
			"argon2id: Expected: %s for input of (%s, %s, %s, %s), but got %s instead",
			v.tag,
			v.password,
			v.salt,
			v.secret,
			v.ad,
			tag_str,
		)
	}
}

@(test)
test_hkdf :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tmp: [128]byte // Good enough.

	test_vectors := []struct {
		algo: hash.Algorithm,
		ikm:  string,
		salt: string,
		info: string,
		okm:  string,
	} {
		// SHA-256
		// - https://www.rfc-editor.org/rfc/rfc5869
		{
			hash.Algorithm.SHA256,
			"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
			"000102030405060708090a0b0c",
			"f0f1f2f3f4f5f6f7f8f9",
			"3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865",
		},
		{
			hash.Algorithm.SHA256,
			"000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f",
			"606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeaf",
			"b0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfeff",
			"b11e398dc80327a1c8e7f78c596a49344f012eda2d4efad8a050cc4c19afa97c59045a99cac7827271cb41c65e590e09da3275600c2f09b8367793a9aca3db71cc30c58179ec3e87c14c01d5c1f3434f1d87",
		},
		{
			hash.Algorithm.SHA256,
			"0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b",
			"",
			"",
			"8da4e775a563c18f715f802a063c5a31b8a11f5c5ee1879ec3454e5f3c738d2d9d201395faa4b61a96c8",
		},
	}
	for v, _ in test_vectors {
		algo_name := hash.ALGORITHM_NAMES[v.algo]
		dst := tmp[:len(v.okm) / 2]

		ikm, _ := hex.decode(transmute([]byte)(v.ikm), context.temp_allocator)
		salt, _ := hex.decode(transmute([]byte)(v.salt), context.temp_allocator)
		info, _ := hex.decode(transmute([]byte)(v.info), context.temp_allocator)

		hkdf.extract_and_expand(v.algo, salt, ikm, info, dst)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		testing.expectf(
			t,
			dst_str == v.okm,
			"HKDF-%s: Expected: %s for input of (%s, %s, %s), but got %s instead",
			algo_name,
			v.okm,
			v.ikm,
			v.salt,
			v.info,
			dst_str,
		)
	}
}

@(test)
test_pbkdf2 :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

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

		testing.expectf(
			t,
			dst_str == v.dk,
			"PBKDF2-%s: Expected: %s for input of (%s, %s, %d), but got %s instead",
			algo_name,
			v.dk,
			v.password,
			v.salt,
			v.iterations,
			dst_str,
		)
	}
}

@(test)
test_scrypt :: proc(t: ^testing.T) {
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()

	tmp: [128]byte // The largest derived key in the test vectors is 77 bytes.

	test_vectors := []struct {
		password: string,
		salt:     string,
		N, r, p:  int,
		dk:       string,
	} {
		// RFC 7914 12.
		{
			"",
			"",
			16, 1, 1,
			"77d6576238657b203b19ca42c18a0497f16b4844e3074ae8dfdffa3fede21442fcd0069ded0948f8326a753a0fc81f17e8d3e0fb2e0d3628cf35e20c38d18906",
		},
		{
			"password",
			"NaCl",
			1024, 8, 16,
			"fdbabe1c9d3472007856e7190d01e9fe7c6ad7cbc8237830e77376634b3731622eaf30d92e22a3886ff109279d9830dac727afb94a83ee6d8360cbdfa2cc0640",
		},
		{
			"pleaseletmein",
			"SodiumChloride",
			16384, 8, 1,
			"7023bdcb3afd7348461c06cd81fd38ebfda8fbba904f8e3ea9b543f6545da1f2d5432955613f0fcf62d49705242a9af9e61e85dc0d651e40dfcf017b45575887",
		},

		// golang.org/x/crypto/scrypt.
		{
			"password",
			"salt",
			2, 10, 10,
			"482c858e229055e62f41e0ec819a5ee18bdb87251a534f75acd95ac5e50aa15f",
		},
		{
			"password",
			"salt",
			16, 100, 100,
			"88bd5edb52d1dd00188772ad36171290224e74829525b18d7323a57f91963c37",
		},
		{
			"this is a long \x00 password",
			"and this is a long \x00 salt",
			16384, 8, 1,
			"c3f182ee2dec846e70a6942fb529985a3a09765ef04c612923b17f18555a37076deb2b9830d69de5492651e4506ae5776d96d40f67aaee37e1777b8ad5c3111432bb3b6f7e1264401879e641ae",
		},
		{
			"p",
			"s",
			2, 1, 1,
			"48b0d2a8a3272611984c50ebd630af52",
		},
	}
	for v, i in test_vectors {
		password := transmute([]byte)v.password
		salt := transmute([]byte)v.salt
		dst := tmp[:len(v.dk) / 2]

		// Exercise the sanitize opt-out as well.
		sanitize := i < len(test_vectors) - 1

		err := scrypt.derive(
			password,
			salt,
			v.N,
			v.r,
			v.p,
			dst,
			sanitize,
			context.temp_allocator,
		)
		testing.expectf(t, err == .None, "scrypt: unexpected allocation error: %v", err)

		dst_str := string(hex.encode(dst, context.temp_allocator))

		testing.expectf(
			t,
			dst_str == v.dk,
			"scrypt: Expected: %s for input of (%s, %s, %d, %d, %d), but got %s instead",
			v.dk,
			v.password,
			v.salt,
			v.N,
			v.r,
			v.p,
			dst_str,
		)
	}
}

@(test)
test_scrypt_invalid_n :: proc(t: ^testing.T) {
	testing.expect_assert_message(t, "crypto/scrypt: N must be > 1 and a power of 2")

	password := []byte{'p'}
	salt := []byte{'s'}
	dst: [32]byte

	_ = scrypt.derive(password, salt, 7, 8, 1, dst[:])
	testing.expect(t, false, "scrypt: expected a panic for an invalid N")
}

@(test)
test_scrypt_invalid_r_p :: proc(t: ^testing.T) {
	testing.expect_assert_message(t, "crypto/scrypt: r and p must be > 0")

	password := []byte{'p'}
	salt := []byte{'s'}
	dst: [32]byte

	_ = scrypt.derive(password, salt, 16, 0, 1, dst[:])
	testing.expect(t, false, "scrypt: expected a panic for a zero r")
}

@(test)
test_scrypt_negative_r_p :: proc(t: ^testing.T) {
	testing.expect_assert_message(t, "crypto/scrypt: r and p must be > 0")

	password := []byte{'p'}
	salt := []byte{'s'}
	dst: [32]byte

	_ = scrypt.derive(password, salt, 16, 1, -1, dst[:])
	testing.expect(t, false, "scrypt: expected a panic for a negative p")
}

@(test)
test_scrypt_too_large :: proc(t: ^testing.T) {
	testing.expect_assert_message(t, "crypto/scrypt: parameters are too large")

	password := []byte{'p'}
	salt := []byte{'s'}
	dst: [32]byte
	max_int := max(int)

	_ = scrypt.derive(password, salt, 16, max_int / 2, max_int / 2, dst[:])
	testing.expect(t, false, "scrypt: expected a panic for oversized parameters")
}
