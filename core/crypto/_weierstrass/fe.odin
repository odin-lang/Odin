package _weierstrass

import "core:math/bits"
import p256r1 "core:crypto/_fiat/field_p256r1"

Field_Element_p256r1 :: p256r1.Montgomery_Domain_Field_Element

FE_SIZE_P256R1 :: 32

fe_clear :: proc {
	p256r1.fe_clear,
}

fe_clear_vec :: proc {
	p256r1.fe_clear_vec,
}

fe_set_bytes :: proc {
	p256r1.fe_from_bytes,
}
fe_bytes :: proc {
	p256r1.fe_to_bytes,
}

fe_set :: proc {
	p256r1.fe_set,
}

fe_zero :: proc {
	p256r1.fe_zero,
}

fe_a :: proc {
	fe_a_p256r1,
}

fe_b :: proc {
	fe_b_p256r1,
}

fe_gen_x :: proc {
	fe_gen_x_p256r1,
}

fe_gen_y :: proc {
	fe_gen_y_p256r1,
}

fe_one :: proc {
	p256r1.fe_one,
}

fe_add :: proc {
	p256r1.fe_add,
}

fe_sub :: proc {
	p256r1.fe_sub,
}

fe_negate :: proc {
	p256r1.fe_opp,
}

fe_mul :: proc {
	p256r1.fe_mul,
}

fe_square :: proc {
	p256r1.fe_square,
}

fe_inv :: proc {
	p256r1.fe_inv,
}

fe_sqrt :: proc {
	p256r1.fe_sqrt,
}

fe_equal :: proc {
	p256r1.fe_equal,
}

fe_is_odd :: proc {
	p256r1.fe_is_odd,
}

fe_is_zero :: proc {
	fe_is_zero_p256r1,
}

fe_cond_select :: proc {
	p256r1.fe_cond_select,
}

fe_a_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// a = 0xffffffff00000001000000000000000000000000fffffffffffffffffffffffc
	//   = -3 mod p
	fe[0] = 18158513697507508224
	fe[1] = 144115188059078655
	fe[2] = 72057589793292288
	fe[3] = 216172786492637184
}

fe_b_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// b = 0x5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b
	fe[0] = 2979529574677938707
	fe[1] = 16443271603273783221
	fe[2] = 7662178891097169697
	fe[3] = 4322198778257916024
}

fe_gen_x_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// G_x = 0x6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296
	fe[0] = 433742654557116119
	fe[1] = 15796249253281334771
	fe[2] = 17272630429700079060
	fe[3] =  2389116281086019998
}

fe_gen_y_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) {
	// G_y = 0x4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5
	fe[0] = 7870488993788815934
	fe[1] = 5773808706922869196
	fe[2] = 7471191399242744833
	fe[3] = 12943927140747999588
}

@(require_results)
fe_is_zero_p256r1 :: proc "contextless" (fe: ^Field_Element_p256r1) -> int {
	ctrl := p256r1.fe_non_zero(fe)
	_, borrow := bits.sub_uint(0, uint(ctrl), 0)
	return int(borrow)
}
