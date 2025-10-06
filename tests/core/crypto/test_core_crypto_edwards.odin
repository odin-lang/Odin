package test_core_crypto

import "core:encoding/hex"
import "core:testing"

import field "core:crypto/_fiat/field_curve25519"
import "core:crypto/ed25519"
import "core:crypto/ristretto255"
import "core:crypto/x25519"
import "core:crypto/x448"

@(test)
test_sqrt_ratio_m1 :: proc(t: ^testing.T) {
	test_vectors := []struct {
		u: string,
		v: string,
		r: string,
		was_square: bool,
	} {
		{
			"0000000000000000000000000000000000000000000000000000000000000000",
			"0000000000000000000000000000000000000000000000000000000000000000",
			"0000000000000000000000000000000000000000000000000000000000000000",
			true,
		},
		{
			"0000000000000000000000000000000000000000000000000000000000000000",
			"0100000000000000000000000000000000000000000000000000000000000000",
			"0000000000000000000000000000000000000000000000000000000000000000",
			true,
		},
		{
			"0100000000000000000000000000000000000000000000000000000000000000",
			"0000000000000000000000000000000000000000000000000000000000000000",
			"0000000000000000000000000000000000000000000000000000000000000000",
			false,
		},
		{
			"0200000000000000000000000000000000000000000000000000000000000000",
			"0100000000000000000000000000000000000000000000000000000000000000",
			"3c5ff1b5d8e4113b871bd052f9e7bcd0582804c266ffb2d4f4203eb07fdb7c54",
			false,
		},
		{
			"0400000000000000000000000000000000000000000000000000000000000000",
			"0100000000000000000000000000000000000000000000000000000000000000",
			"0200000000000000000000000000000000000000000000000000000000000000",
			true,
		},
		{
			"0100000000000000000000000000000000000000000000000000000000000000",
			"0400000000000000000000000000000000000000000000000000000000000000",
			"f6ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff3f",
			true,
		},
	}
	for v, _ in test_vectors {
		u_bytes, _ := hex.decode(transmute([]byte)(v.u), context.temp_allocator)
		v_bytes, _ := hex.decode(transmute([]byte)(v.v), context.temp_allocator)
		r_bytes, _ := hex.decode(transmute([]byte)(v.r), context.temp_allocator)

		u_ := (^[32]byte)(raw_data(u_bytes))
		v_ := (^[32]byte)(raw_data(v_bytes))
		r_ := (^[32]byte)(raw_data(r_bytes))

		u, vee, r: field.Tight_Field_Element
		field.fe_from_bytes(&u, u_)
		field.fe_from_bytes(&vee, v_)
		was_square := field.fe_carry_sqrt_ratio_m1(
			&r,
			field.fe_relax_cast(&u),
			field.fe_relax_cast(&vee),
		)

		testing.expectf(
			t,
			(was_square == 1) == v.was_square && field.fe_equal_bytes(&r, r_) == 1,
			"Expected (%v, %s) for SQRT_RATIO_M1(%s, %s), got %s",
			v.was_square,
			v.r,
			v.u,
			v.v,
			fe_str(&r),
		)
	}
}

@(test)
test_ristretto255 :: proc(t: ^testing.T) {
	ge_gen: ristretto255.Group_Element
	ristretto255.ge_generator(&ge_gen)

	// Invalid encodings.
	bad_encodings := []string {
		// Non-canonical field encodings.
		"00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
		"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
		"f3ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
		"edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",

		// Negative field elements.
		"0100000000000000000000000000000000000000000000000000000000000000",
		"01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
		"ed57ffd8c914fb201471d1c3d245ce3c746fcbe63a3679d51b6a516ebebe0e20",
		"c34c4e1826e5d403b78e246e88aa051c36ccf0aafebffe137d148a2bf9104562",
		"c940e5a4404157cfb1628b108db051a8d439e1a421394ec4ebccb9ec92a8ac78",
		"47cfc5497c53dc8e61c91d17fd626ffb1c49e2bca94eed052281b510b1117a24",
		"f1c6165d33367351b0da8f6e4511010c68174a03b6581212c71c0e1d026c3c72",
		"87260f7a2f12495118360f02c26a470f450dadf34a413d21042b43b9d93e1309",

		// Non-square x^2.
		"26948d35ca62e643e26a83177332e6b6afeb9d08e4268b650f1f5bbd8d81d371",
		"4eac077a713c57b4f4397629a4145982c661f48044dd3f96427d40b147d9742f",
		"de6a7b00deadc788eb6b6c8d20c0ae96c2f2019078fa604fee5b87d6e989ad7b",
		"bcab477be20861e01e4a0e295284146a510150d9817763caf1a6f4b422d67042",
		"2a292df7e32cababbd9de088d1d1abec9fc0440f637ed2fba145094dc14bea08",
		"f4a9e534fc0d216c44b218fa0c42d99635a0127ee2e53c712f70609649fdff22",
		"8268436f8c4126196cf64b3c7ddbda90746a378625f9813dd9b8457077256731",
		"2810e5cbc2cc4d4eece54f61c6f69758e289aa7ab440b3cbeaa21995c2f4232b",

		// Negative x * y value.
		"3eb858e78f5a7254d8c9731174a94f76755fd3941c0ac93735c07ba14579630e",
		"a45fdc55c76448c049a1ab33f17023edfb2be3581e9c7aade8a6125215e04220",
		"d483fe813c6ba647ebbfd3ec41adca1c6130c2beeee9d9bf065c8d151c5f396e",
		"8a2e1d30050198c65a54483123960ccc38aef6848e1ec8f5f780e8523769ba32",
		"32888462f8b486c68ad7dd9610be5192bbeaf3b443951ac1a8118419d9fa097b",
		"227142501b9d4355ccba290404bde41575b037693cef1f438c47f8fbf35d1165",
		"5c37cc491da847cfeb9281d407efc41e15144c876e0170b499a96a22ed31e01e",
		"445425117cb8c90edcbc7c1cc0e74f747f2c1efa5630a967c64f287792a48a4b",

		// s = -1, which causes y = 0.
		"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
	}
	for x, _ in bad_encodings {
		b, _ := hex.decode(transmute([]byte)(x), context.temp_allocator)

		ge: ristretto255.Group_Element
		ok := ristretto255.ge_set_bytes(&ge, b)
		testing.expectf(t, !ok, "Expected false for %s", x)
	}

	generator_multiples := []string {
		"0000000000000000000000000000000000000000000000000000000000000000",
		"e2f2ae0a6abc4e71a884a961c500515f58e30b6aa582dd8db6a65945e08d2d76",
		"6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919",
		"94741f5d5d52755ece4f23f044ee27d5d1ea1e2bd196b462166b16152a9d0259",
		"da80862773358b466ffadfe0b3293ab3d9fd53c5ea6c955358f568322daf6a57",
		"e882b131016b52c1d3337080187cf768423efccbb517bb495ab812c4160ff44e",
		"f64746d3c92b13050ed8d80236a7f0007c3b3f962f5ba793d19a601ebb1df403",
		"44f53520926ec81fbd5a387845beb7df85a96a24ece18738bdcfa6a7822a176d",
		"903293d8f2287ebe10e2374dc1a53e0bc887e592699f02d077d5263cdd55601c",
		"02622ace8f7303a31cafc63f8fc48fdc16e1c8c8d234b2f0d6685282a9076031",
		"20706fd788b2720a1ed2a5dad4952b01f413bcf0e7564de8cdc816689e2db95f",
		"bce83f8ba5dd2fa572864c24ba1810f9522bc6004afe95877ac73241cafdab42",
		"e4549ee16b9aa03099ca208c67adafcafa4c3f3e4e5303de6026e3ca8ff84460",
		"aa52e000df2e16f55fb1032fc33bc42742dad6bd5a8fc0be0167436c5948501f",
		"46376b80f409b29dc2b5f6f0c52591990896e5716f41477cd30085ab7f10301e",
		"e0c418f7c8d9c4cdd7395b93ea124f3ad99021bb681dfc3302a9d99a2e53e64e",
	}
	ges: [16]ristretto255.Group_Element
	for x, i in generator_multiples {
		b, _ := hex.decode(transmute([]byte)(x), context.temp_allocator)

		ge := &ges[i]
		ok := ristretto255.ge_set_bytes(ge, b)
		testing.expectf(t, ok, "Expected true for %s", x)

		x_check := ge_str(ge)

		testing.expectf(
			t,
			x == x_check,
			"Expected %s (round-trip) but got %s instead",
			x,
			x_check,
		)

		if i == 1 {
			testing.expect(
				t,
				ristretto255.ge_equal(ge, &ge_gen) == 1,
				"Expected element 1 to be the generator",
			)
		}
	}

	// Addition/Multiplication.
	for _, i in ges {
		sc: ristretto255.Scalar
		ristretto255.sc_set_u64(&sc, u64(i))

		ge_check: ristretto255.Group_Element

		ristretto255.ge_scalarmult_generator(&ge_check, &sc)
		x_check := ge_str(&ge_check)
		testing.expectf(
			t,
			x_check == generator_multiples[i],
			"Expected %s for G * %d (specialized), got %s",
			generator_multiples[i],
			i,
			x_check,
		)

		ristretto255.ge_scalarmult(&ge_check, &ges[1], &sc)
		x_check = ge_str(&ge_check)
		testing.expectf(
			t,
			x_check == generator_multiples[i],
			"Expected %s for G * %d (generic), got %s (slow compare)",
			generator_multiples[i],
			i,
			x_check,
		)

		ristretto255.ge_scalarmult_vartime(&ge_check, &ges[1], &sc)
		x_check = ge_str(&ge_check)
		testing.expectf(
			t,
			x_check == generator_multiples[i],
			"Expected %s for G * %d (generic vartime), got %s (slow compare)",
			generator_multiples[i],
			i,
			x_check,
		)

		switch i {
		case 0:
		case:
			ge_prev := &ges[i-1]
			ristretto255.ge_add(&ge_check, ge_prev, &ge_gen)

			x_check = ge_str(&ge_check)
			testing.expectf(
				t,
				x_check == generator_multiples[i],
				"Expected %s for ges[%d] + ges[%d], got %s (slow compare)",
				generator_multiples[i],
				i-1,
				1,
				x_check,
			)

			testing.expectf(
				t,
				ristretto255.ge_equal(&ges[i], &ge_check) == 1,
				"Expected %s for ges[%d] + ges[%d], got %s (fast compare)",
				generator_multiples[i],
				i-1,
				1,
				x_check,
			)
		}
	}

	wide_test_vectors := []struct {
		input: string,
		output: string,
	} {
		{
			"5d1be09e3d0c82fc538112490e35701979d99e06ca3e2b5b54bffe8b4dc772c14d98b696a1bbfb5ca32c436cc61c16563790306c79eaca7705668b47dffe5bb6",
			"3066f82a1a747d45120d1740f14358531a8f04bbffe6a819f86dfe50f44a0a46",
		},
		{
			"f116b34b8f17ceb56e8732a60d913dd10cce47a6d53bee9204be8b44f6678b270102a56902e2488c46120e9276cfe54638286b9e4b3cdb470b542d46c2068d38",
			"f26e5b6f7d362d2d2a94c5d0e7602cb4773c95a2e5c31a64f133189fa76ed61b",
		},
		{
			"8422e1bbdaab52938b81fd602effb6f89110e1e57208ad12d9ad767e2e25510c27140775f9337088b982d83d7fcf0b2fa1edffe51952cbe7365e95c86eaf325c",
			"006ccd2a9e6867e6a2c5cea83d3302cc9de128dd2a9a57dd8ee7b9d7ffe02826",
		},
		{
			"ac22415129b61427bf464e17baee8db65940c233b98afce8d17c57beeb7876c2150d15af1cb1fb824bbd14955f2b57d08d388aab431a391cfc33d5bafb5dbbaf",
			"f8f0c87cf237953c5890aec3998169005dae3eca1fbb04548c635953c817f92a",
		},
		{
			"165d697a1ef3d5cf3c38565beefcf88c0f282b8e7dbd28544c483432f1cec7675debea8ebb4e5fe7d6f6e5db15f15587ac4d4d4a1de7191e0c1ca6664abcc413",
			"ae81e7dedf20a497e10c304a765c1767a42d6e06029758d2d7e8ef7cc4c41179",
		},
		{
			"a836e6c9a9ca9f1e8d486273ad56a78c70cf18f0ce10abb1c7172ddd605d7fd2979854f47ae1ccf204a33102095b4200e5befc0465accc263175485f0e17ea5c",
			"e2705652ff9f5e44d3e841bf1c251cf7dddb77d140870d1ab2ed64f1a9ce8628",
		},
		{
			"2cdc11eaeb95daf01189417cdddbf95952993aa9cb9c640eb5058d09702c74622c9965a697a3b345ec24ee56335b556e677b30e6f90ac77d781064f866a3c982",
			"80bd07262511cdde4863f8a7434cef696750681cb9510eea557088f76d9e5065",
		},
		// These all produce the same output.
		{
			"edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1200000000000000000000000000000000000000000000000000000000000000",
			"304282791023b73128d277bdcb5c7746ef2eac08dde9f2983379cb8e5ef0517f",
		},
		{
			"edffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
			"304282791023b73128d277bdcb5c7746ef2eac08dde9f2983379cb8e5ef0517f",
		},
		{
			"0000000000000000000000000000000000000000000000000000000000000080ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff7f",
			"304282791023b73128d277bdcb5c7746ef2eac08dde9f2983379cb8e5ef0517f",
		},
		{
			"00000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000080",
			"304282791023b73128d277bdcb5c7746ef2eac08dde9f2983379cb8e5ef0517f",
		},
	}
	for v, _ in wide_test_vectors {
		in_bytes, _ := hex.decode(transmute([]byte)(v.input), context.temp_allocator)

		ge: ristretto255.Group_Element
		ristretto255.ge_set_wide_bytes(&ge, in_bytes)

		ge_check := ge_str(&ge)
		testing.expectf(
			t,
			ge_check == v.output,
			"Expected %s for %s, got %s",
			v.output,
			ge_check,
		)
	}
}

@(test)
test_ed25519 :: proc(t: ^testing.T) {
	test_vectors_rfc := []struct {
		priv_key: string,
		pub_key:  string,
		msg:      string,
		sig:      string,
	} {
		// Test vectors from RFC 8032
		{
			"9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60",
			"d75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a",
			"",
			"e5564300c360ac729086e2cc806e828a84877f1eb8e5d974d873e065224901555fb8821590a33bacc61e39701cf9b46bd25bf5f0595bbe24655141438e7a100b",
		},
		{
			"4ccd089b28ff96da9db6c346ec114e0f5b8a319f35aba624da8cf6ed4fb8a6fb",
			"3d4017c3e843895a92b70aa74d1b7ebc9c982ccf2ec4968cc0cd55f12af4660c",
			"72",
			"92a009a9f0d4cab8720e820b5f642540a2b27b5416503f8fb3762223ebdb69da085ac1e43e15996e458f3613d0f11d8c387b2eaeb4302aeeb00d291612bb0c00",
		},
		{
			"c5aa8df43f9f837bedb7442f31dcb7b166d38535076f094b85ce3a2e0b4458f7",
			"fc51cd8e6218a1a38da47ed00230f0580816ed13ba3303ac5deb911548908025",
			"af82",
			"6291d657deec24024827e69c3abe01a30ce548a284743a445e3680d7db5ac3ac18ff9b538d16f290ae67f760984dc6594a7c15e9716ed28dc027beceea1ec40a",
		},
		// TEST 1024 omitted for brevity, because all that does is add more to SHA-512
		{
			"833fe62409237b9d62ec77587520911e9a759cec1d19755b7da901b96dca3d42",
			"ec172b93ad5e563bf4932c70e1245034c35467ef2efd4d64ebf819683467e2bf",
			"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
			"dc2a4459e7369633a52b1bf277839a00201009a3efbf3ecb69bea2186c26b58909351fc9ac90b3ecfdfbc7c66431e0303dca179c138ac17ad9bef1177331a704",
		},
	}
	for v, _ in test_vectors_rfc {
		priv_bytes, _ := hex.decode(transmute([]byte)(v.priv_key), context.temp_allocator)
		pub_bytes, _ := hex.decode(transmute([]byte)(v.pub_key), context.temp_allocator)
		msg_bytes, _ := hex.decode(transmute([]byte)(v.msg), context.temp_allocator)
		sig_bytes, _ := hex.decode(transmute([]byte)(v.sig), context.temp_allocator)

		priv_key: ed25519.Private_Key
		ok := ed25519.private_key_set_bytes(&priv_key, priv_bytes)
		testing.expectf(
			t,
			ok,
			"Expected %s to be a valid private key",
			v.priv_key,
		)

		key_bytes: [32]byte
		ed25519.private_key_bytes(&priv_key, key_bytes[:])
		testing.expectf(
			t,
			ok,
			"Expected private key %s round-trip, got %s",
			v.priv_key,
			string(hex.encode(key_bytes[:], context.temp_allocator)),
		)

		pub_key: ed25519.Public_Key
		ok = ed25519.public_key_set_bytes(&pub_key, pub_bytes)
		testing.expectf(
			t,
			ok,
			"Expected %s to be a valid public key (priv->pub: %s)",
			v.pub_key,
			string(hex.encode(priv_key._pub_key._b[:], context.temp_allocator)),
		)

		ed25519.public_key_bytes(&pub_key, key_bytes[:])
		testing.expectf(
			t,
			ok,
			"Expected public key %s round-trip, got %s",
			v.pub_key,
			string(hex.encode(key_bytes[:], context.temp_allocator)),
		)

		sig: [ed25519.SIGNATURE_SIZE]byte
		ed25519.sign(&priv_key, msg_bytes, sig[:])
		x := string(hex.encode(sig[:], context.temp_allocator))
		testing.expectf(
			t,
			x == v.sig,
			"Expected %s for sign(%s, %s), got %s",
			v.sig,
			v.priv_key,
			v.msg,
			x,
		)

		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok,
			"Expected true for verify(%s, %s, %s)",
			v.pub_key,
			v.msg,
			v.sig,
		)

		ok = ed25519.verify(&priv_key._pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok,
			"Expected true for verify(pub(%s), %s %s)",
			v.priv_key,
			v.msg,
			v.sig,
		)

		// Corrupt the message and make sure verification fails.
		switch len(msg_bytes) {
		case 0:
			tmp_msg := []byte{69}
			msg_bytes = tmp_msg[:]
		case:
			msg_bytes[0] = msg_bytes[0] ~ 69
		}
		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok == false,
			"Expected false for verify(%s, %s (corrupted), %s)",
			v.pub_key,
			v.msg,
			v.sig,
		)
	}

	// Test cases from "Taming the many EdDSAs", which aim to exercise
	// all of the ed25519 edge cases/implementation differences.
	//
	// - https://eprint.iacr.org/2020/1244
	// - https://github.com/novifinancial/ed25519-speccheck
	test_vectors_speccheck := []struct {
		pub_key:        string,
		msg:            string,
		sig:            string,
		pub_key_ok:     bool,
		sig_ok:         bool,
		sig_ok_relaxed: bool, // Ok if the small-order A check is relaxed.
	} {
		// S = 0, small-order A, small-order R
		{
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa",
			"8c93255d71dcab10e8f379c26200f3c7bd5f09d9bc3068d3ef4edeb4853022b6",
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac037a0000000000000000000000000000000000000000000000000000000000000000",
			true,
			false,
			true,
		},
		// 0 < S < L, small-order A, mixed-order R
		{
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa",
			"9bd9f44f4dcc75bd531b56b2cd280b0bb38fc1cd6d1230e14861d861de092e79",
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43a5bb704786be79fc476f91d3f3f89b03984d8068dcf1bb7dfc6637b45450ac04",
			true,
			false,
			true,
		},
		// 0 < S < L, mixed-order A, small-order R
		{
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43",
			"aebf3f2601a0c8c5d39cc7d8911642f740b78168218da8471772b35f9d35b9ab",
			"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c4bd45aecaca5b24fb97bc10ac27ac8751a7dfe1baff8b953ec9f5833ca260e",
			true,
			true,
			true,
		},
		// 0 < S < L, mixed-order A, mixed-order R
		{
			"cdb267ce40c5cd45306fa5d2f29731459387dbf9eb933b7bd5aed9a765b88d4d",
			"9bd9f44f4dcc75bd531b56b2cd280b0bb38fc1cd6d1230e14861d861de092e79",
			"9046a64750444938de19f227bb80485e92b83fdb4b6506c160484c016cc1852f87909e14428a7a1d62e9f22f3d3ad7802db02eb2e688b6c52fcd6648a98bd009",
			true,
			true,
			true,
		},
		// 0 < S < L, mixed-order A, mixed-order R
		{
			"cdb267ce40c5cd45306fa5d2f29731459387dbf9eb933b7bd5aed9a765b88d4d",
			"e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec4011eaccd55b53f56c",
			"160a1cb0dc9c0258cd0a7d23e94d8fa878bcb1925f2c64246b2dee1796bed5125ec6bc982a269b723e0668e540911a9a6a58921d6925e434ab10aa7940551a09",
			true,
			true, // cofactored-only
			true,
		},
		// 0 < S < L, mixed-order A, L-order R
		{
			"cdb267ce40c5cd45306fa5d2f29731459387dbf9eb933b7bd5aed9a765b88d4d",
			"e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec4011eaccd55b53f56c",
			"21122a84e0b5fca4052f5b1235c80a537878b38f3142356b2c2384ebad4668b7e40bc836dac0f71076f9abe3a53f9c03c1ceeeddb658d0030494ace586687405",
			true,
			true, // cofactored only, (fail if 8h is pre-reduced)
			true,
		},
		// S > L, L-order A, L-order R
		{
			"442aad9f089ad9e14647b1ef9099a1ff4798d78589e66f28eca69c11f582a623",
			"85e241a07d148b41e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec40",
			"e96f66be976d82e60150baecff9906684aebb1ef181f67a7189ac78ea23b6c0e547f7690a0e2ddcd04d87dbc3490dc19b3b3052f7ff0538cb68afb369ba3a514",
			true,
			false,
			false,
		},
		// S >> L, L-order A, L-order R
		{
			"442aad9f089ad9e14647b1ef9099a1ff4798d78589e66f28eca69c11f582a623",
			"85e241a07d148b41e47d62c63f830dc7a6851a0b1f33ae4bb2f507fb6cffec40",
			"8ce5b96c8f26d0ab6c47958c9e68b937104cd36e13c33566acd2fe8d38aa19427e71f98a473474f2f13f06f97c20d58cc3f54b8bd0d272f42b695dd7e89a8c22",
			true,
			false,
			false,
		},
		// 0 < S < L, mixed-order A, small-order R (non-canonical R, reduced for hash)
		{
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43",
			"9bedc267423725d473888631ebf45988bad3db83851ee85c85e241a07d148b41",
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff03be9678ac102edcd92b0210bb34d7428d12ffc5df5f37e359941266a4e35f0f",
			true,
			false,
			false,
		},
		// 0 < S < L, mixed-order A, small-order R (non-canonical R, not reduced for hash)
		{
			"f7badec5b8abeaf699583992219b7b223f1df3fbbea919844e3f7c554a43dd43",
			"9bedc267423725d473888631ebf45988bad3db83851ee85c85e241a07d148b41",
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffca8c5b64cd208982aa38d4936621a4775aa233aa0505711d8fdcfdaa943d4908",
			true,
			false,
			false,
		},
		// 0 < S < L, small-order A, mixed-order R (non-canonical A, reduced for hash)
		{
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
			"e96b7021eb39c1a163b6da4e3093dcd3f21387da4cc4572be588fafae23c155b",
			"a9d55260f765261eb9b84e106f665e00b867287a761990d7135963ee0a7d59dca5bb704786be79fc476f91d3f3f89b03984d8068dcf1bb7dfc6637b45450ac04",
			false,
			false,
			false,
		},
		// 0 < S < L, small-order A, mixed-order R (non-canonical A, not reduced for hash)
		{
			"ecffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
			"39a591f5321bbe07fd5a23dc2f39d025d74526615746727ceefd6e82ae65c06f",
			"a9d55260f765261eb9b84e106f665e00b867287a761990d7135963ee0a7d59dca5bb704786be79fc476f91d3f3f89b03984d8068dcf1bb7dfc6637b45450ac04",
			false,
			false,
			false,
		},
	}
	for v, i in test_vectors_speccheck {
		pub_bytes, _ := hex.decode(transmute([]byte)(v.pub_key), context.temp_allocator)
		msg_bytes, _ := hex.decode(transmute([]byte)(v.msg), context.temp_allocator)
		sig_bytes, _ := hex.decode(transmute([]byte)(v.sig), context.temp_allocator)

		pub_key: ed25519.Public_Key
		ok := ed25519.public_key_set_bytes(&pub_key, pub_bytes)
		testing.expectf(
			t,
			ok == v.pub_key_ok,
			"speccheck/%d: Expected %s to be a (in)valid public key, got %v",
			i,
			v.pub_key,
			ok,
		)

		// If A is rejected for being non-canonical, skip signature check.
		if !v.pub_key_ok {
			continue
		}

		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes)
		testing.expectf(
			t,
			ok == v.sig_ok,
			"speccheck/%d Expected %v for verify(%s, %s, %s)",
			i,
			v.sig_ok,
			v.pub_key,
			v.msg,
			v.sig,
		)

		// If the signature is accepted, skip the relaxed signature check.
		if v.sig_ok {
			continue
		}

		ok = ed25519.verify(&pub_key, msg_bytes, sig_bytes, true)
		testing.expectf(
			t,
			ok == v.sig_ok_relaxed,
			"speccheck/%d Expected %v for verify(%s, %s, %s, true)",
			i,
			v.sig_ok_relaxed,
			v.pub_key,
			v.msg,
			v.sig,
		)
	}
}

@(test)
test_x25519 :: proc(t: ^testing.T) {
	// Local copy of this so that the base point doesn't need to be exported.
	_BASE_POINT: [32]byte = {
		9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	}

	test_vectors := []struct {
		scalar:  string,
		point:   string,
		product: string,
	} {
		// Test vectors from RFC 7748
		{
			"a546e36bf0527c9d3b16154b82465edd62144c0ac1fc5a18506a2244ba449ac4",
			"e6db6867583030db3594c1a424b15f7c726624ec26b3353b10a903a6d0ab1c4c",
			"c3da55379de9c6908e94ea4df28d084f32eccf03491c71f754b4075577a28552",
		},
		{
			"4b66e9d4d1b4673c5ad22691957d6af5c11b6421e0ea01d42ca4169e7918ba0d",
			"e5210f12786811d3f4b7959d0538ae2c31dbe7106fc03c3efc4cd549c715a493",
			"95cbde9476e8907d7aade45cb4b873f88b595a68799fa152e6f8f7647aac7957",
		},
	}
	for v, _ in test_vectors {
		scalar, _ := hex.decode(transmute([]byte)(v.scalar), context.temp_allocator)
		point, _ := hex.decode(transmute([]byte)(v.point), context.temp_allocator)

		derived_point: [x25519.POINT_SIZE]byte
		x25519.scalarmult(derived_point[:], scalar[:], point[:])
		derived_point_str := string(hex.encode(derived_point[:], context.temp_allocator))

		testing.expectf(
			t,
			derived_point_str == v.product,
			"Expected %s for %s * %s, but got %s instead",
			v.product,
			v.scalar,
			v.point,
			derived_point_str,
			)

		// Abuse the test vectors to sanity-check the scalar-basepoint multiply.
		p1, p2: [x25519.POINT_SIZE]byte
		x25519.scalarmult_basepoint(p1[:], scalar[:])
		x25519.scalarmult(p2[:], scalar[:], _BASE_POINT[:])
		p1_str := string(hex.encode(p1[:], context.temp_allocator))
		p2_str := string(hex.encode(p2[:], context.temp_allocator))
		testing.expectf(
			t,
			p1_str == p2_str,
			"Expected %s for %s * basepoint, but got %s instead",
			p2_str,
			v.scalar,
			p1_str,
		)
	}
}

@(test)
test_x448 :: proc(t: ^testing.T) {
	// Local copy of this so that the base point doesn't need to be exported.
	_BASE_POINT: [56]byte = {
		5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 0, 0, 0, 0, 0,
	}

	test_vectors := []struct {
		scalar:  string,
		point:   string,
		product: string,
	} {
		// Test vectors from RFC 7748
		{
			"3d262fddf9ec8e88495266fea19a34d28882acef045104d0d1aae121700a779c984c24f8cdd78fbff44943eba368f54b29259a4f1c600ad3",
			"06fce640fa3487bfda5f6cf2d5263f8aad88334cbd07437f020f08f9814dc031ddbdc38c19c6da2583fa5429db94ada18aa7a7fb4ef8a086",
			"ce3e4ff95a60dc6697da1db1d85e6afbdf79b50a2412d7546d5f239fe14fbaadeb445fc66a01b0779d98223961111e21766282f73dd96b6f",
		},
		{
			"203d494428b8399352665ddca42f9de8fef600908e0d461cb021f8c538345dd77c3e4806e25f46d3315c44e0a5b4371282dd2c8d5be3095f",
			"0fbcc2f993cd56d3305b0b7d9e55d4c1a8fb5dbb52f8e9a1e9b6201b165d015894e56c4d3570bee52fe205e28a78b91cdfbde71ce8d157db",
			"884a02576239ff7a2f2f63b2db6a9ff37047ac13568e1e30fe63c4a7ad1b3ee3a5700df34321d62077e63633c575c1c954514e99da7c179d",
		},
	}
	for v, _ in test_vectors {
		scalar, _ := hex.decode(transmute([]byte)(v.scalar), context.temp_allocator)
		point, _ := hex.decode(transmute([]byte)(v.point), context.temp_allocator)

		derived_point: [x448.POINT_SIZE]byte
		x448.scalarmult(derived_point[:], scalar[:], point[:])
		derived_point_str := string(hex.encode(derived_point[:], context.temp_allocator))

		testing.expectf(
			t,
			derived_point_str == v.product,
			"Expected %s for %s * %s, but got %s instead",
			v.product,
			v.scalar,
			v.point,
			derived_point_str,
			)

		// Abuse the test vectors to sanity-check the scalar-basepoint multiply.
		p1, p2: [x448.POINT_SIZE]byte
		x448.scalarmult_basepoint(p1[:], scalar[:])
		x448.scalarmult(p2[:], scalar[:], _BASE_POINT[:])
		p1_str := string(hex.encode(p1[:], context.temp_allocator))
		p2_str := string(hex.encode(p2[:], context.temp_allocator))
		testing.expectf(
			t,
			p1_str == p2_str,
			"Expected %s for %s * basepoint, but got %s instead",
			p2_str,
			v.scalar,
			p1_str,
		)
	}
}

@(private)
ge_str :: proc(ge: ^ristretto255.Group_Element) -> string {
	b: [ristretto255.ELEMENT_SIZE]byte
	ristretto255.ge_bytes(ge, b[:])
	return string(hex.encode(b[:], context.temp_allocator))
}

@(private)
fe_str :: proc(fe: ^field.Tight_Field_Element) -> string {
	b: [32]byte
	field.fe_to_bytes(&b, fe)
	return string(hex.encode(b[:], context.temp_allocator))
}