package _weierstrass

import "core:encoding/hex"
import "core:testing"

import "core:fmt"

@(private = "file")
G_X :: "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296"
@(private = "file")
G_Y :: "4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5"

@(private = "file")
G_UNCOMPRESSED :: "04" + G_X + G_Y

@(test)
test_p256_a :: proc(t: ^testing.T) {
	a_str := "ffffffff00000001000000000000000000000000fffffffffffffffffffffffc"

	fe, a_fe: Field_Element_p256r1
	fe_a(&fe)
	fe_a(&a_fe)

	b: [32]byte
	fe_bytes(b[:], &fe)

	s := (string)(hex.encode(b[:], context.temp_allocator))

	testing.expect(t, s == a_str)

	fe_zero(&fe)
	fe_set_bytes(&fe, b[:])

	testing.expect(t, fe_equal(&fe, &a_fe) == 1)
}

@(test)
test_p256_b :: proc(t: ^testing.T) {
	b_str := "5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b"

	fe, b_fe: Field_Element_p256r1
	fe_b(&fe)
	fe_b(&b_fe)

	b: [32]byte
	fe_bytes(b[:], &fe)

	s := (string)(hex.encode(b[:], context.temp_allocator))

	testing.expect(t, s == b_str)

	fe_zero(&fe)
	fe_set_bytes(&fe, b[:])

	testing.expect(t, fe_equal(&fe, &b_fe) == 1)
}

@(test)
test_p256_g_x :: proc(t: ^testing.T) {
	fe, x_fe: Field_Element_p256r1
	fe_gen_x(&fe)
	fe_gen_x(&x_fe)

	b: [32]byte
	fe_bytes(b[:], &fe)

	s := (string)(hex.encode(b[:], context.temp_allocator))
	testing.expect(t, s == G_X)

	fe_zero(&fe)
	fe_set_bytes(&fe, b[:])

	testing.expect(t, fe_equal(&fe, &x_fe) == 1)
}

@(test)
test_p256_g_y :: proc(t: ^testing.T) {
	fe, y_fe: Field_Element_p256r1
	fe_gen_y(&fe)
	fe_gen_y(&y_fe)

	b: [32]byte
	fe_bytes(b[:], &fe)

	s := (string)(hex.encode(b[:], context.temp_allocator))
	testing.expect(t, s == G_Y)

	fe_zero(&fe)
	fe_set_bytes(&fe, b[:])

	testing.expect(t, fe_equal(&fe, &y_fe) == 1)
}

@(test)
test_p256_scalarmul :: proc(t: ^testing.T) {
	p, q, r: Point_p256r1
	sc: Scalar_p256r1
	b: [1]byte
	tmp: [32]byte

	pt_generator(&p)
	pt_identity(&q)
	pt_identity(&r)

	for i in 0..<16 {
		b[0] = byte(i)
		_ = sc_set_bytes(&sc, b[:])

		sc_bytes(tmp[:], &sc)
		s := string(hex.encode(tmp[:], context.temp_allocator))

		if i != 0 {
			pt_add(&q, &q, &p)
		}
		pt_scalar_mul(&r, &p, &sc)
		pt_rescale(&q, &q)
		pt_rescale(&r, &r)

		testing.expectf(t, pt_equal(&q, &r) == 1, "sc: %s, %v %v", s, q, r)
	}
}

@(test)
test_p256_is_on_curve :: proc(t: ^testing.T) {
	x, y, lhs, rhs: Field_Element_p256r1
	tmp: [32]byte

	fe_gen_x(&x)
	fe_gen_y(&y)

	set_yy_candidate(&rhs, &x)
	fe_square(&lhs, &y)

	fe_bytes(tmp[:], &rhs)
	rhs_s := string(hex.encode(tmp[:], context.temp_allocator))

	fe_bytes(tmp[:], &lhs)
	lhs_s := string(hex.encode(tmp[:], context.temp_allocator))
	testing.expectf(t, lhs_s == rhs_s, "lhs: %s rhs: %s", lhs_s, rhs_s)
}

@(test)
test_p256_s11n_sec_identity ::proc(t: ^testing.T) {
	p: Point_p256r1

	pt_generator(&p)
	ok := pt_set_sec_bytes(&p, []byte{0x00})
	testing.expect(t, ok)
	testing.expectf(t, pt_is_identity(&p) == 1, "%v", p)

	b := []byte{0xff}
	ok = pt_sec_bytes(b, &p, true)
	testing.expect(t, ok)
	testing.expect(t, b[0] == 0x00)

	b = []byte{0xff}
	ok = pt_sec_bytes(b, &p, false)
	testing.expect(t, ok)
	testing.expect(t, b[0] == 0x00)
}

@(test)
test_p256_s11n_sec_generator ::proc(t: ^testing.T) {
	p, g: Point_p256r1

	pt_generator(&g)
	pt_identity(&p)

	b: [65]byte
	ok := pt_sec_bytes(b[:], &g, false)
	testing.expect(t, ok)
	s := (string)(hex.encode(b[:], context.temp_allocator))
	testing.expectf(t, s == G_UNCOMPRESSED, "g: %v bytes: %v, %v", g, G_UNCOMPRESSED, s)

	ok = pt_set_sec_bytes(&p, b[:])
	testing.expectf(t, ok, "%s", s)
	testing.expect(t, pt_equal(&g, &p) == 1)
}
