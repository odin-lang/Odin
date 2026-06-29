#+private
package _mldsa

CRHBYTES :: 64
TRBYTES :: 64

N :: 256
Q :: 8380417
D :: 13

K_MAX :: 8
L_MAX :: 7

POLYZ_PACKEDBYTES_MAX :: 640

POLYT1_PACKEDBYTES :: 320
POLYT0_PACKEDBYTES :: 416

POLYVECT1_PACKEDBYTES_MAX :: K_MAX * POLYT1_PACKEDBYTES
POLYW1_PACKEDBYTES_MAX :: 192

CTILDBYTES_MAX :: 64

@(require_results)
polyeta_packedbytes :: #force_inline proc "contextless" (params: ^Params) -> int {
	POLYETA_PACKEDBYTES_2 :: 96
	POLYETA_PACKEDBYTES_4 :: 128

	switch params.eta {
	case 2:
		return POLYETA_PACKEDBYTES_2
	case 4:
		return POLYETA_PACKEDBYTES_4
	case:
		unreachable()
	}
}

@(require_results)
polyz_packedbytes :: #force_inline proc "contextless" (params: ^Params) -> int {
	POLYZ_PACKEDBYTES_GAMMA1_17 :: 576
	POLYZ_PACKEDBYTES_GAMMA1_19 :: 640

	switch params.gamma1 {
	case 1 << 17:
		return POLYZ_PACKEDBYTES_GAMMA1_17
	case 1 << 19:
		return POLYZ_PACKEDBYTES_GAMMA1_19
	case:
		unreachable()
	}
}

@(require_results)
polyw1_packedbytes :: #force_inline proc "contextless" (params: ^Params) -> int {
	POLYW1_PACKEDBYTES_GAMMA2_95232 :: 192
	POLYW1_PACKEDBYTES_GAMMA2_261888 :: 128

	switch params.gamma2 {
	case (Q-1)/88:
		return POLYW1_PACKEDBYTES_GAMMA2_95232
	case (Q-1)/32:
		return POLYW1_PACKEDBYTES_GAMMA2_261888
	case:
		unreachable()
	}
}

@(require_results)
polyvech_packedbytes :: #force_inline proc "contextless" (params: ^Params) -> int {
	return params.omega + params.k
}
