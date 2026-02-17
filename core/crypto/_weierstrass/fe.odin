package _weierstrass

import p256r1 "core:crypto/_fiat/field_p256r1"
import p384r1 "core:crypto/_fiat/field_p384r1"
import subtle "core:crypto/_subtle"

Field_Element_p256r1 :: p256r1.Montgomery_Domain_Field_Element
Field_Element_p384r1 :: p384r1.Montgomery_Domain_Field_Element

FE_SIZE_P256R1 :: 32
FE_SIZE_P384R1 :: 48

fe_clear :: proc {
	p256r1.fe_clear,
	p384r1.fe_clear,
}

fe_clear_vec :: proc {
	p256r1.fe_clear_vec,
	p384r1.fe_clear_vec,
}

fe_set_bytes :: proc {
	p256r1.fe_from_bytes,
	p384r1.fe_from_bytes,
}

fe_bytes :: proc {
	p256r1.fe_to_bytes,
	p384r1.fe_to_bytes,
}

fe_set :: proc {
	p256r1.fe_set,
	p384r1.fe_set,
}

fe_zero :: proc {
	p256r1.fe_zero,
	p384r1.fe_zero,
}

fe_a :: proc {
	fe_a_p256r1,
	fe_a_p384r1,
}

fe_b :: proc {
	fe_b_p256r1,
	fe_b_p384r1,
}

fe_gen_x :: proc {
	fe_gen_x_p256r1,
	fe_gen_x_p384r1,
}

fe_gen_y :: proc {
	fe_gen_y_p256r1,
	fe_gen_y_p384r1,
}

fe_one :: proc {
	p256r1.fe_one,
	p384r1.fe_one,
}

fe_add :: proc {
	p256r1.fe_add,
	p384r1.fe_add,
}

fe_sub :: proc {
	p256r1.fe_sub,
	p384r1.fe_sub,
}

fe_negate :: proc {
	p256r1.fe_opp,
	p384r1.fe_opp,
}

fe_mul :: proc {
	p256r1.fe_mul,
	p384r1.fe_mul,
}

fe_square :: proc {
	p256r1.fe_square,
	p384r1.fe_square,
}

fe_inv :: proc {
	p256r1.fe_inv,
	p384r1.fe_inv,
}

fe_sqrt :: proc {
	p256r1.fe_sqrt,
	p384r1.fe_sqrt,
}

fe_equal :: proc {
	p256r1.fe_equal,
	p384r1.fe_equal,
}

fe_is_odd :: proc {
	p256r1.fe_is_odd,
	p384r1.fe_is_odd,
}

fe_is_zero :: proc {
	fe_is_zero_p256r1,
	fe_is_zero_p384r1,
}

fe_cond_select :: proc {
	p256r1.fe_cond_select,
	p384r1.fe_cond_select,
}

fe_a_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// a = 0xffffffff00000001000000000000000000000000fffffffffffffffffffffffc
	//   = -3 mod p
	fe[0] = 18446744073709551612
	fe[1] = 17179869183
	fe[2] = 0
	fe[3] = 18446744056529682436
}

fe_b_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// b = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b
	fe[0] = 15608596021259845087
	fe[1] = 12461466548982526096
	fe[2] = 16546823903870267094
	fe[3] = 15866188208926050356
}

fe_gen_x_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// G_x = 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296
	fe[0] = 8784043285714375740
	fe[1] = 8483257759279461889
	fe[2] = 8789745728267363600
	fe[3] = 1770019616739251654
}

fe_gen_y_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// G_y = 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5
	fe[0] = 15992936863339206154
	fe[1] = 10037038012062884956
	fe[2] = 15197544864945402661
	fe[3] = 9615747158586711429
}

fe_a_p384r1 :: proc "contextless" (fe: ^Field_Element_p384r1) {
	// a = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc
	//   = -3 mod p
	fe[0] = 17179869180
	fe[1] = 18446744056529682432
	fe[2] = 18446744073709551611
	fe[3] = 18446744073709551615
	fe[4] = 18446744073709551615
	fe[5] = 18446744073709551615
}

fe_b_p384r1 :: proc "contextless" (fe: ^Field_Element_p384r1) {
	// b = 0xb3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef
	fe[0] = 581395848458481100
	fe[1] = 17809957346689692396
	fe[2] = 8643006485390950958
	fe[3] = 16372638458395724514
	fe[4] = 13126622871277412500
	fe[5] = 14774077593024970745
}

fe_gen_x_p384r1 :: proc "contextless" (fe: ^Field_Element_p384r1) {
	// G_x = 0xaa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7
	fe[0] = 4454189113653900584
	fe[1] = 2369870743683386936
	fe[2] = 9771750146904378734
	fe[3] = 7229551204834152191
	fe[4] = 9308930686126579243
	fe[5] = 5564951339003155731
}

fe_gen_y_p384r1 :: proc "contextless" (fe: ^Field_Element_p384r1) {
	// G_y = 0x3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f
	fe[0] = 2523209505731486974
	fe[1] = 11655219901025790380
	fe[2] = 10064955099576512592
	fe[3] = 14322381509056856025
	fe[4] = 15960759442596276288
	fe[5] = 3132442392059561449
}

@(require_results)
fe_is_zero_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) -> int {
	return int(subtle.u64_is_zero(p256r1.fe_non_zero(fe)))
}

@(require_results)
fe_is_zero_p384r1 :: proc "contextless" (fe: ^Field_Element_p384r1) -> int {
	return int(subtle.u64_is_zero(p384r1.fe_non_zero(fe)))
}
