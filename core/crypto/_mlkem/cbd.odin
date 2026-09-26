#+private
package _mlkem

import "core:encoding/endian"

unchecked_get_u24le :: #force_inline proc "contextless" (b: []byte) -> u32 #no_bounds_check {
	r := u32(b[0])
	r |= u32(b[1]) << 8
	r |= u32(b[2]) << 16
	return r
}

cbd3 :: proc "contextless" (r: ^Poly, buf: ^[3*N/4]byte) #no_bounds_check {
	for i in 0..<N/4 {
		t := unchecked_get_u24le(buf[3*i:])
		d := t & 0x00249249
		d += (t>>1) & 0x00249249
		d += (t>>2) & 0x00249249

		for j in uint(0)..<4 {
			a := i16((d >> (6*j+0)) & 0x7)
			b := i16((d >> (6*j+3)) & 0x7)
			r.coeffs[4*i+int(j)] = a - b
		}
	}
}

cbd2 :: proc "contextless" (r: ^Poly, buf: ^[2*N/4]byte) #no_bounds_check {
	for i in 0..<N/8 {
		t := endian.unchecked_get_u32le(buf[4*i:])
		d := t & 0x55555555
		d += (t>>1) & 0x55555555

		for j in uint(0)..<8 {
			a := i16((d >> (4*j+0)) & 0x3)
			b := i16((d >> (4*j+2)) & 0x3)
			r.coeffs[8*i+int(j)] = a - b
		}
	}
}

poly_cbd_eta1_512 :: proc "contextless" (r: ^Poly, buf: ^[ETA1_512*N/4]byte) {
	cbd3(r, buf)
}

poly_cbd_eta1 :: proc "contextless" (r: ^Poly, buf: ^[ETA1*N/4]byte) {
	cbd2(r, buf)
}

poly_cbd_eta2 :: proc "contextless" (r: ^Poly, buf: ^[ETA2*N/4]byte) {
	cbd2(r, buf)
}
