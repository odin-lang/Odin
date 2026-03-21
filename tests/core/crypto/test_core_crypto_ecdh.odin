package test_core_crypto

import "core:encoding/hex"
import "core:testing"

import "core:crypto/ecdh"

@(test)
test_ecdh :: proc(t: ^testing.T) {
	test_vectors := []struct {
		curve:   ecdh.Curve,
		scalar:  string,
		point:   string,
		product: string,
	} {
		// X25519 Test vectors from RFC 7748
		{
			.X25519,
			"a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
			"e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
			"c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
		},
		{
			.X25519,
			"4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
			"e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
			"95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
		},
		// X448 Test vectors from RFC 7748
		{
			.X448,
			"3d262fddf9ec8e88495266fea19a34d28882acef045104d0d1aae121700a779c984c24f8cdd78fbff44943eba368f54b29259a4f1c600ad3",
			"06fce640fa3487bfda5f6cf2d5263f8aad88334cbd07437f020f08f9814dc031ddbdc38c19c6da2583fa5429db94ada18aa7a7fb4ef8a086",
			"ce3e4ff95a60dc6697da1db1d85e6afbdf79b50a2412d7546d5f239fe14fbaadeb445fc66a01b0779d98223961111e21766282f73dd96b6f",
		},
		{
			.X448,
			"203d494428b8399352665ddca42f9de8fef600908e0d461cb021f8c538345dd77c3e4806e25f46d3315c44e0a5b4371282dd2c8d5be3095f",
			"0fbcc2f993cd56d3305b0b7d9e55d4c1a8fb5dbb52f8e9a1e9b6201b165d015894e56c4d3570bee52fe205e28a78b91cdfbde71ce8d157db",
			"884a02576239ff7a2f2f63b2db6a9ff37047ac13568e1e30fe63c4a7ad1b3ee3a5700df34321d62077e63633c575c1c954514e99da7c179d",
		},
		// secp256r1 Test vectors (subset) from NIST CAVP
		{
			.SECP256R1,
			"7d7dc5f71eb29ddaf80d6214632eeae03d9058af1fb6d22ed80badb62bc1a534",
			"04700c48f77f56584c5cc632ca65640db91b6bacce3a4df6b42ce7cc838833d287db71e509e3fd9b060ddb20ba5c51dcc5948d46fbf640dfe0441782cab85fa4ac",
			"46fc62106420ff012e54a434fbdd2d25ccc5852060561e68040dd7778997bd7b",
		},
		{
			.SECP256R1,
			"38f65d6dce47676044d58ce5139582d568f64bb16098d179dbab07741dd5caf5",
			"04809f04289c64348c01515eb03d5ce7ac1a8cb9498f5caa50197e58d43a86a7aeb29d84e811197f25eba8f5194092cb6ff440e26d4421011372461f579271cda3",
			"057d636096cb80b67a8c038c890e887d1adfa4195e9b3ce241c8a778c59cda67",
		},
		// secp384r1 Test vectors (subset) from NIST CAVP
		{
			.SECP384R1,
			"3cc3122a68f0d95027ad38c067916ba0eb8c38894d22e1b15618b6818a661774ad463b205da88cf699ab4d43c9cf98a1",
			"04a7c76b970c3b5fe8b05d2838ae04ab47697b9eaf52e764592efda27fe7513272734466b400091adbf2d68c58e0c50066ac68f19f2e1cb879aed43a9969b91a0839c4c38a49749b661efedf243451915ed0905a32b060992b468c64766fc8437a",
			"5f9d29dc5e31a163060356213669c8ce132e22f57c9a04f40ba7fcead493b457e5621e766c40a2e3d4d6a04b25e533f1",
		},
		{
			.SECP384R1,
			"92860c21bde06165f8e900c687f8ef0a05d14f290b3f07d8b3a8cc6404366e5d5119cd6d03fb12dc58e89f13df9cd783",
			"0430f43fcf2b6b00de53f624f1543090681839717d53c7c955d1d69efaf0349b7363acb447240101cbb3af6641ce4b88e025e46c0c54f0162a77efcc27b6ea792002ae2ba82714299c860857a68153ab62e525ec0530d81b5aa15897981e858757",
			"a23742a2c267d7425fda94b93f93bbcc24791ac51cd8fd501a238d40812f4cbfc59aac9520d758cf789c76300c69d2ff",
		},
	}

	for v, _ in test_vectors {
		raw_scalar, _ := hex.decode(transmute([]byte)(v.scalar), context.temp_allocator)
		raw_point, _ := hex.decode(transmute([]byte)(v.point), context.temp_allocator)

		pub_key: ecdh.Public_Key
		priv_key: ecdh.Private_Key

		ok := ecdh.private_key_set_bytes(&priv_key, v.curve, raw_scalar)
		testing.expectf(t, ok, "failed to deserialize private key: %v %x", v.curve, raw_scalar)

		ok = ecdh.public_key_set_bytes(&pub_key, v.curve, raw_point)
		testing.expectf(t, ok, "failed to deserialize public key: %v %x", v.curve, raw_scalar)

		shared_secret := make([]byte, ecdh.shared_secret_size(&pub_key), context.temp_allocator)
		ok = ecdh.ecdh(&priv_key, &pub_key, shared_secret)
		testing.expectf(t, ok, "ecdh failed: %v %v %v", v.curve, &priv_key, &pub_key)

		ss_str := string(hex.encode(shared_secret, context.temp_allocator))
		testing.expectf(
			t,
			ss_str == v.product,
			"Expected %s for %v %s * %s, but got %s instead",
			v.product,
			v.curve,
			v.scalar,
			v.point,
			ss_str,
		)
	}
}

@(test)
test_ecdh_scalar_basemult :: proc(t: ^testing.T) {
	test_vectors := []struct {
		curve:   ecdh.Curve,
		scalar : string,
		point: string,
	} {
		// X25519 from RFC 7748 6.1
		{
			.X25519,
			"77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a",
			"8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a",
		},
		{
			.X25519,
			"5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb",
			"de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f",
		},
		// X448 from RFC 7748 6.2
		{
			.X448,
			"9a8f4925d1519f5775cf46b04b5800d4ee9ee8bae8bc5565d498c28dd9c9baf574a9419744897391006382a6f127ab1d9ac2d8c0a598726b",
			"9b08f7cc31b7e3e67d22d5aea121074a273bd2b83de09c63faa73d2c22c5d9bbc836647241d953d40c5b12da88120d53177f80e532c41fa0",
		},
		{
			.X448,
			"1c306a7ac2a0e2e0990b294470cba339e6453772b075811d8fad0d1d6927c120bb5ee8972b0d3e21374c9c921b09d1b0366f10b65173992d",
			"3eb7a829b0cd20f5bcfc0b599b6feccf6da4627107bdb0d4f345b43027d8b972fc3e34fb4232a13ca706dcb57aec3dae07bdc1c67bf33609",
		},
		// secp256r1 Test vectors (subset) from NIST CAVP
		{
			.SECP256R1,
			"7d7dc5f71eb29ddaf80d6214632eeae03d9058af1fb6d22ed80badb62bc1a534",
			"04ead218590119e8876b29146ff89ca61770c4edbbf97d38ce385ed281d8a6b23028af61281fd35e2fa7002523acc85a429cb06ee6648325389f59edfce1405141",
		},
		{
			.SECP256R1,
			"38f65d6dce47676044d58ce5139582d568f64bb16098d179dbab07741dd5caf5",
			"04119f2f047902782ab0c9e27a54aff5eb9b964829ca99c06b02ddba95b0a3f6d08f52b726664cac366fc98ac7a012b2682cbd962e5acb544671d41b9445704d1d",
		},
	}

	for v, _ in test_vectors {
		raw_scalar, _ := hex.decode(transmute([]byte)(v.scalar), context.temp_allocator)

		priv_key: ecdh.Private_Key
		pub_key: ecdh.Public_Key

		ok := ecdh.private_key_set_bytes(&priv_key, v.curve, raw_scalar)
		testing.expectf(t, ok, "failed to deserialize private key: %v %x", v.curve, raw_scalar)

		ecdh.public_key_set_priv(&pub_key, &priv_key)
		b := make([]byte, ecdh.key_size(&pub_key), context.temp_allocator)
		ecdh.public_key_bytes(&pub_key, b)

		pub_str := string(hex.encode(b, context.temp_allocator))
		testing.expectf(
			t,
			pub_str == v.point,
			"Expected %s for %v %s * G, but got %s instead",
			v.point,
			v.curve,
			v.scalar,
			pub_str,
		)
	}
}