package _weierstrass

/*
This implements prime order short Weierstrass curves defined over a field
k with char(k) != 2, 3 (`y^2 = x^3 + ax + b`). for the purpose of
implementing ECDH and ECDSA.  Use of this package for other purposes is
NOT RECOMMENDED.

As an explicit simplicity/performance tradeoff, projective representation
was chosen so that it is possible to use the complete addition
formulas.

See:
- https://eprint.iacr.org/2015/1060.pdf
- https://hyperelliptic.org/EFD/g1p/auto-shortw-projective.html

WARNING: The point addition and doubling formulas are specialized for
`a = -3`, which covers secp256r1, secp384r1, secp521r1, FRP256v1, SM2,
and GOST 34.10.  The brainpool curves and secp256k1 are NOT SUPPORTED
and would require slightly different formulas.
*/

Point_p256r1 :: struct {
	x: Field_Element_p256r1,
	y: Field_Element_p256r1,
	z: Field_Element_p256r1,
}

@(require_results)
pt_set_xy_bytes :: proc "contextless" (p: ^$T, x_raw, y_raw: []byte) -> bool {
	when T == Point_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
		x, y: Field_Element_p256r1
		defer fe_clear_vec([]^Field_Element_p256r1{&x, &y})
	} else {
		#panic("weierstrass: invalid curve")
	}

	if len(x_raw) != FE_SZ || len(y_raw) != FE_SZ {
		return false
	}

	if !fe_set_bytes(&x, x_raw) {
		return false
	}
	if !fe_set_bytes(&y, y_raw) {
		return false
	}
	if !is_on_curve(&x, &y) {
		return false
	}

	fe_set(&p.x, &x)
	fe_set(&p.y, &y)
	fe_one(&p.z)

	return true
}

@(require_results)
pt_set_x_bytes :: proc "contextless" (p: ^$T, x_raw: []byte, y_is_odd: int) -> bool {
	when T == Point_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
		x, y, yy, y_neg: Field_Element_p256r1
		defer fe_clear_vec([]^Field_Element_p256r1{&x, &y, &yy, &y_neg})
	} else {
		#panic("weierstrass: invalid curve")
	}

	if len(x_raw) != FE_SZ {
		return false
	}

	if !fe_set_bytes(&x, x_raw) {
		return false
	}
	set_yy_candidate(&yy, &x)
	if fe_sqrt(&y, &yy) != 1 {
		return false
	}

	// Pick the correct y-coordinate.
	fe_negate(&y_neg, &y)
	parity_neq := (y_is_odd ~ fe_is_odd(&y)) & 1

	fe_set(&p.x, &x)
	fe_cond_select(&p.y, &y, &y_neg, parity_neq)
	fe_one(&p.z)

	return true
}

@(require_results)
pt_bytes :: proc "contextless" (x, y: []byte, p: ^$T) -> bool {
	when T == Point_p256r1 {
		FE_SZ :: FE_SIZE_P256R1
	} else {
		#panic("weierstrass: invalid curve")
	}

	if pt_is_identity(p) == 1 {
		return false
	}

	// Convert to affine coordinates.
	pt_rescale(p, p)

	switch len(x) {
	case 0:
	case FE_SZ:
		fe_bytes(x, &p.x)
	case:
		panic_contextless("weierstrass: invalid x buffer")
	}
	switch len(y) {
	case 0:
	case FE_SZ:
		fe_bytes(y, &p.y)
	case:
		panic_contextless("weierstrass: invalid y buffer")
	}

	return true
}

pt_set :: proc "contextless" (p, q: ^$T) {
	fe_set(&p.x, &q.x)
	fe_set(&p.y, &q.y)
	fe_set(&p.z, &q.z)
}

pt_identity :: proc "contextless" (p: ^$T) {
	fe_zero(&p.x)
	fe_one(&p.y)
	fe_zero(&p.z)
}

pt_generator :: proc "contextless" (p: ^$T) {
	fe_gen_x(&p.x)
	fe_gen_y(&p.y)
	fe_one(&p.z)
}

pt_clear :: proc "contextless" (p: ^$T) {
	fe_clear(&p.x)
	fe_clear(&p.y)
	fe_clear(&p.z)
}

pt_clear_vec :: proc "contextless" (arg: []^$T) {
	for p in arg {
		pt_clear(p)
	}
}

pt_add :: proc "contextless" (p, a, b: ^$T) {
	// Algorithm 4 from "Complete addition formulas for prime
	// order elliptic curves" by Renes, Costello, and Batina.
	//
	// The formula is complete in that it is valid for all a and b,
	// without exceptions or extra assumptions about the inputs.
	//
	// The operation costs are `12M + 2mb + 29a`.

	when T == Point_p256r1 {
		t0, t1, t2, t3, t4, b_fe: Field_Element_p256r1
		x3, y3, z3: Field_Element_p256r1
		defer fe_clear_vec([]^Field_Element_p256r1{&t0, &t1, &t2, &t3, &t4, &x3, &y3, &z3})
	} else {
		#panic("weierstrass: invalid curve")
	}

	x1, y1, z1 := &a.x, &a.y, &a.z
	x2, y2, z2 := &b.x, &b.y, &b.z

	fe_b(&b_fe)

	// t0 := X1 * X2 ; t1 := Y1 * Y2 ; t2 := Z1 * Z2 ;
	fe_mul(&t0, x1, x2)
	fe_mul(&t1, y1, y2)
	fe_mul(&t2, z1, z2)

	// t3 := X1 + Y1 ; t4 := X2 + Y2 ; t3 := t3 * t4 ;
	fe_add(&t3, x1, y1)
	fe_add(&t4, x2, y2)
	fe_mul(&t3, &t3, &t4)

	// t4 := t0 + t1 ; t3 := t3 - t4 ; t4 := Y1 + Z1 ;
	fe_add(&t4, &t0, &t1)
	fe_sub(&t3, &t3, &t4)
	fe_add(&t4, y1, z1)

	// X3 := Y2 + Z2 ; t4 := t4 * X3 ; X3 := t1 + t2 ;
	fe_add(&x3, y2, z2)
	fe_mul(&t4, &t4, &x3)
	fe_add(&x3, &t1, &t2)

	// t4 := t4 - X3 ; X3 := X1 + Z1 ; Y3 := X2 + Z2 ;
	fe_sub(&t4, &t4, &x3)
	fe_add(&x3, x1, z1)
	fe_add(&y3, x2, z2)

	// X3 := X3 * Y3 ; Y3 := t0 + t2 ; Y3 := X3 - Y3 ;
	fe_mul(&x3, &x3, &y3)
	fe_add(&y3, &t0, &t2)
	fe_sub(&y3, &x3, &y3)

	// Z3 := b * t2 ; X3 := Y3 - Z3 ; Z3 := X3 + X3 ;
	fe_mul(&z3, &b_fe, &t2)
	fe_sub(&x3, &y3, &z3)
	fe_add(&z3, &x3, &x3)

	// X3 := X3 + Z3 ; Z3 := t1 - X3 ; X3 := t1 + X3 ;
	fe_add(&x3, &x3, &z3)
	fe_sub(&z3, &t1, &x3)
	fe_add(&x3, &t1, &x3)

	// Y3 := b * Y3 ; t1 := t2 + t2 ; t2 := t1 + t2 ;
	fe_mul(&y3, &b_fe, &y3)
	fe_add(&t1, &t2, &t2)
	fe_add(&t2, &t1, &t2)

	// Y3 := Y3 - t2 ; Y3 := Y3 - t0 ; t1 := Y3 + Y3 ;
	fe_sub(&y3, &y3, &t2)
	fe_sub(&y3, &y3, &t0)
	fe_add(&t1, &y3, &y3)

	// Y3 := t1 + Y3 ; t1 := t0 + t0 ; t0 := t1 + t0 ;
	fe_add(&y3, &t1, &y3)
	fe_add(&t1, &t0, &t0)
	fe_add(&t0, &t1, &t0)

	// t0 := t0 - t2 ; t1 := t4 * Y3 ; t2 := t0 * Y3 ;
	fe_sub(&t0, &t0, &t2)
	fe_mul(&t1, &t4, &y3)
	fe_mul(&t2, &t0, &y3)

	// Y3 := X3 * Z3 ; Y3 := Y3 + t2 ; X3 := t3 * X3 ;
	fe_mul(&y3, &x3, &z3)
	fe_add(&y3, &y3, &t2)
	fe_mul(&x3, &t3, &x3)

	// X3 := X3 - t1 ; Z3 := t4 * Z3 ; t1 := t3 * t0 ;
	fe_sub(&x3, &x3, &t1)
	fe_mul(&z3, &t4, &z3)
	fe_mul(&t1, &t3, &t0)

	// Z3 := Z3 + t1 ;
	fe_add(&z3, &z3, &t1)

	// return X3 , Y3 , Z3 ;
	fe_set(&p.x, &x3)
	fe_set(&p.y, &y3)
	fe_set(&p.z, &z3)
}

@(private)
pt_add_mixed :: proc "contextless" (p, a: ^$T, x2, y2: ^$U) {
	// Algorithm 5 from "Complete addition formulas for prime
	// order elliptic curves" by Renes, Costello, and Batina.
	//
	// The formula is mixed in that it assumes the z-coordinate
	// of the addend (`Z2`) is `1`, meaning that it CAN NOT
	// handle the addend being the point at infinity.
	//
	// The operation costs are `11M + 2mb + 23a` saving
	// `1M + 6a` over `pt_add`.

	when T == Point_p256r1 && U == Field_Element_p256r1 {
		t0, t1, t2, t3, t4, b_fe: Field_Element_p256r1
		x3, y3, z3: Field_Element_p256r1
		defer fe_clear_vec([]^Field_Element_p256r1{&t0, &t1, &t2, &t3, &t4, &x3, &y3, &z3})
	} else {
		#panic("weierstrass: invalid curve")
	}

	x1, y1, z1 := &a.x, &a.y, &a.z

	fe_b(&b_fe)

	// t0 := X1 * X2 ; t1 := Y1 * Y2 ; t3 := X2 + Y2 ;
	fe_mul(&t0, x1, x2)
	fe_mul(&t1, y1, y2)
	fe_add(&t3, x2, y2)

	// t4 := X1 + Y1 ; t3 := t3 * t4 ; t4 := t0 + t1 ;
	fe_add(&t4, x1, y1)
	fe_mul(&t3, &t3, &t4)
	fe_add(&t4, &t0, &t1)

	// t3 := t3 − t4 ; t4 := Y2 * Z1 ; t4 := t4 + Y1 ;
	fe_sub(&t3, &t3, &t4)
	fe_mul(&t4, y2, z1)
	fe_add(&t4, &t4, y1)

	// Y3 := X2 * Z1 ; Y3 := Y3 + X1 ; Z3 := b * Z1 ;
	fe_mul(&y3, x2, z1)
	fe_add(&y3, &y3, x1)
	fe_mul(&z3, &b_fe, z1)

	// X3 := Y3 − Z3 ; Z3 := X3 + X3 ; X3 := X3 + Z3 ;
	fe_sub(&x3, &y3, &z3)
	fe_add(&z3, &x3, &x3)
	fe_add(&x3, &x3, &z3)

	// Z3 := t1 − X3 ; X3 := t1 + X3 ;. Y3 := b * Y3 ;
	fe_sub(&z3, &t1, &x3)
	fe_add(&x3, &t1, &x3)
	fe_mul(&y3, &b_fe, &y3)

	// t1 := Z1 + Z1 ; t2 := t1 + Z1 ; Y3 := Y3 − t2 ;
	fe_add(&t1, z1, z1)
	fe_add(&t2, &t1, z1)
	fe_sub(&y3, &y3, &t2)

	// Y3 := Y3 − t0 ; t1 := Y3 + Y3 ; Y3 := t1 + Y3 ;
	fe_sub(&y3, &y3, &t0)
	fe_add(&t1, &y3, &y3)
	fe_add(&y3, &t1, &y3)

	// t1 := t0 + t0 ; t0 := t1 + t0 ; t0 := t0 − t2 ;
	fe_add(&t1, &t0, &t0)
	fe_add(&t0, &t1, &t0)
	fe_sub(&t0, &t0, &t2)

	// t1 := t4 * Y3 ; t2 := t0 * Y3 ; Y3 := X3 * Z3 ;
	fe_mul(&t1, &t4, &y3)
	fe_mul(&t2, &t0, &y3)
	fe_mul(&y3, &x3, &z3)

	// Y3 := Y3 + t2 ; X3 := t3 * X3 ; X3 := X3 − t1 ;
	fe_add(&y3, &y3, &t2)
	fe_mul(&x3, &t3, &x3)
	fe_sub(&x3, &x3, &t1)

	// Z3 := t4 * Z3 ; t1 := t3 * t0 ; Z3 := Z3 + t1 ;
	fe_mul(&z3, &t4, &z3)
	fe_mul(&t1, &t3, &t0)
	fe_add(&z3, &z3, &t1)

	// return X3 , Y3 , Z3 ;
	fe_set(&p.x, &x3)
	fe_set(&p.y, &y3)
	fe_set(&p.z, &z3)
}

pt_double :: proc "contextless" (p, a: ^$T) {
	// Algorithm 6 from "Complete addition formulas for prime
	// order elliptic curves" by Renes, Costello, and Batina.
	//
	// The formula is complete in that it is valid for all a,
	// without exceptions or extra assumptions about the inputs.
	//
	// The operation costs are `8M + 3S + 2mb + 21a`.

	when T == Point_p256r1 {
		t0, t1, t2, t3, b_fe: Field_Element_p256r1
		x3, y3, z3: Field_Element_p256r1
		defer fe_clear_vec([]^Field_Element_p256r1{&t0, &t1, &t2, &t3, &x3, &y3, &z3})
	} else {
		#panic("weierstrass: invalid curve")
	}

	x, y, z := &a.x, &a.y, &a.z

	fe_b(&b_fe)

	// t0 := X ^2; t1 := Y ^2; t2 := Z ^2;
	fe_square(&t0, x)
	fe_square(&t1, y)
	fe_square(&t2, z)

	// t3 := X * Y ; t3 := t3 + t3 ; Z3 := X * Z ;
	fe_mul(&t3, x, y)
	fe_add(&t3, &t3, &t3)
	fe_mul(&z3, x, z)

	// Z3 := Z3 + Z3 ; Y3 := b * t2 ; Y3 := Y3 - Z3 ;
	fe_add(&z3, &z3, &z3)
	fe_mul(&y3, &b_fe, &t2)
	fe_sub(&y3, &y3, &z3)

	// X3 := Y3 + Y3 ; Y3 := X3 + Y3 ; X3 := t1 - Y3 ;
	fe_add(&x3, &y3, &y3)
	fe_add(&y3, &x3, &y3)
	fe_sub(&x3, &t1, &y3)

	// Y3 := t1 + Y3 ; Y3 := X3 * Y3 ; X3 := X3 * t3 ;
	fe_add(&y3, &t1, &y3)
	fe_mul(&y3, &x3, &y3)
	fe_mul(&x3, &x3, &t3)

	// t3 := t2 + t2 ; t2 := t2 + t3 ; Z3 := b * Z3 ;
	fe_add(&t3, &t2, &t2)
	fe_add(&t2, &t2, &t3)
	fe_mul(&z3, &b_fe, &z3)

	// Z3 := Z3 - t2 ; Z3 := Z3 - t0 ; t3 := Z3 + Z3 ;
	fe_sub(&z3, &z3, &t2)
	fe_sub(&z3, &z3, &t0)
	fe_add(&t3, &z3, &z3)

	// Z3 := Z3 + t3 ; t3 := t0 + t0 ; t0 := t3 + t0 ;
	fe_add(&z3, &z3, &t3)
	fe_add(&t3, &t0, &t0)
	fe_add(&t0, &t3, &t0)

	// t0 := t0 - t2 ; t0 := t0 * Z3 ; Y3 := Y3 + t0 ;
	fe_sub(&t0, &t0, &t2)
	fe_mul(&t0, &t0, &z3)
	fe_add(&y3, &y3, &t0)

	// t0 := Y * Z ; t0 := t0 + t0 ; Z3 := t0 * Z3 ;
	fe_mul(&t0, y, z)
	fe_add(&t0, &t0, &t0)
	fe_mul(&z3, &t0, &z3)

	// X3 := X3 - Z3 ; Z3 := t0 * t1 ; Z3 := Z3 + Z3 ;
	fe_sub(&x3, &x3, &z3)
	fe_mul(&z3, &t0, &t1)
	fe_add(&z3, &z3, &z3)

	// Z3 := Z3 + Z3 ;
	fe_add(&z3, &z3, &z3)

	// return X3 , Y3 , Z3 ;
	fe_set(&p.x, &x3)
	fe_set(&p.y, &y3)
	fe_set(&p.z, &z3)
}

pt_sub :: proc "contextless" (p, a, b: ^$T) {
	b_neg: T
	pt_negate(&b_neg, b)
	pt_add(p, a, &b_neg)

	fe_clear(&b_neg)
}

pt_negate :: proc "contextless" (p, a: ^$T) {
	fe_set(&p.x, &a.x)
	fe_negate(&p.y, &a.y)
	fe_set(&p.z, &a.z)
}

pt_rescale :: proc "contextless" (p, a: ^$T) {
	// A = 1/Z1
	// X3 = A*X1
	// Y3 = A*Y1
	// Z3 = 1
	//
	// As per "From A to Z: Projective coordinates leakage in the wild"
	// leaking the Z-coordinate is bad. The modular inversion algorithm
	// used in this library is based on Fermat's Little Theorem.
	//
	// See: https://eprint.iacr.org/2020/432.pdf

	was_identity := pt_is_identity(a)

	when T == Point_p256r1 {
		z_inv: Field_Element_p256r1
	} else {
		#panic("weierstrass: invalid curve")
	}

	ident: T
	fe_inv(&z_inv, &a.z)
	fe_mul(&p.x, &a.x, &z_inv)
	fe_mul(&p.y, &a.y, &z_inv)
	fe_one(&p.z)

	pt_identity(&ident)
	pt_cond_select(p, p, &ident, was_identity)

	fe_clear(&z_inv)
}

pt_cond_select :: proc "contextless" (p, a, b: ^$T, ctrl: int) {
	fe_cond_select(&p.x, &a.x, &b.x, ctrl)
	fe_cond_select(&p.y, &a.y, &b.y, ctrl)
	fe_cond_select(&p.z, &a.z, &b.z, ctrl)
}

@(require_results)
pt_equal :: proc "contextless" (a, b: ^$T) -> int {
	when T == Point_p256r1 {
		x1z2, x2z1, y1z2, y2z1: Field_Element_p256r1
	} else {
		#panic("weierstrass: invalid curve")
	}

	// Check X1Z2 == X2Z1 && Y1Z2 == Y2Z1
	fe_mul(&x1z2, &a.x, &b.z)
	fe_mul(&x2z1, &b.x, &a.z)

	fe_mul(&y1z2, &a.y, &b.z)
	fe_mul(&y2z1, &b.y, &a.z)

	return fe_equal(&x1z2, &x2z1) & fe_equal(&y1z2, &y2z1)
}

@(require_results)
pt_is_identity :: proc "contextless" (p: ^$T) -> int {
	return fe_is_zero(&p.z)
}

@(require_results)
pt_is_y_odd :: proc "contextless" (p: ^$T) -> int {
	tmp: T
	defer pt_clear(&tmp)

	fe_set(&tmp, p)
	pt_rescale(&tmp)

	return fe_is_odd(&tmp.y)
}

@(private)
is_on_curve :: proc "contextless" (x, y: ^$T) -> bool {
	maybe_yy, yy: T
	defer fe_clear_vec([]^T{&maybe_yy, &yy})

	// RHS: x^3 + ax + b
	set_yy_candidate(&maybe_yy, x)

	// LHS: y^2
	fe_square(&yy, y)

	return fe_equal(&maybe_yy, &yy) == 1
}

@(private)
set_yy_candidate :: proc "contextless" (maybe_yy, x: ^$T) {
	// RHS: x^3 + ax + b
	rhs, tmp: T

	fe_square(&tmp, x)
	fe_mul(&rhs, &tmp, x)

	fe_a(&tmp)
	fe_mul(&tmp, &tmp, x)
	fe_add(&rhs, &rhs, &tmp)

	fe_b(&tmp)
	fe_add(maybe_yy, &rhs, &tmp)

	fe_clear(&rhs)
}
