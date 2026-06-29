package test_core_crypto

import "core:encoding/hex"
import "core:testing"

import field "core:crypto/_fiat/field_curve25519"
import "core:crypto/ristretto255"

@(test)
test_edwards25519_sqrt_ratio_m1 :: proc(t: ^testing.T) {
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

@(private="file")
ge_str :: proc(ge: ^ristretto255.Group_Element) -> string {
	b: [ristretto255.ELEMENT_SIZE]byte
	ristretto255.ge_bytes(ge, b[:])
	return string(hex.encode(b[:], context.temp_allocator))
}

@(private="file")
fe_str :: proc(fe: ^field.Tight_Field_Element) -> string {
	b: [32]byte
	field.fe_to_bytes(&b, fe)
	return string(hex.encode(b[:], context.temp_allocator))
}
