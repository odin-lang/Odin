package _weierstrass

import p256r1 "core:crypto/_fiat/field_scalarp256r1"
import subtle "core:crypto/_subtle"

Scalar_p256r1 :: p256r1.Montgomery_Domain_Field_Element

SC_SIZE_P256R1 :: 32

sc_clear :: proc {
	p256r1.fe_clear,
}

sc_clear_vec :: proc {
	p256r1.fe_clear_vec,
}

sc_set_bytes :: proc {
	p256r1.fe_from_bytes,
}
sc_bytes :: proc {
	p256r1.fe_to_bytes,
}

sc_set :: proc {
	p256r1.fe_set,
}

sc_zero :: proc {
	p256r1.fe_zero,
}

sc_one_p256r1 :: proc {
	p256r1.fe_one,
}

sc_add :: proc {
	p256r1.fe_add,
}

sc_sub :: proc {
	p256r1.fe_sub,
}

sc_negate :: proc {
	p256r1.fe_opp,
}

sc_mul :: proc {
	p256r1.fe_mul,
}

sc_square :: proc {
	p256r1.fe_square,
}

sc_cond_assign :: proc {
	p256r1.fe_cond_assign,
}

sc_equal :: proc {
	p256r1.fe_equal,
}

sc_is_odd :: proc {
	p256r1.fe_is_odd,
}

sc_is_zero :: proc {
	sc_is_zero_p256r1,
}

@(require_results)
sc_is_zero_p256r1 :: proc "contextless" (fe: ^Scalar_p256r1) -> int {
	return int(subtle.u64_is_zero(p256r1.fe_non_zero(fe)))
}
