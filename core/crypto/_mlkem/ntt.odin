#+private
package _mlkem

@(rodata)
ZETAS := [128]i16 {
	-1044,  -758,  -359, -1517,  1493,  1422,   287,   202,
	 -171,   622,  1577,   182,   962, -1202, -1474,  1468,
	  573, -1325,   264,   383,  -829,  1458, -1602,  -130,
	 -681,  1017,   732,   608, -1542,   411,  -205, -1571,
	 1223,   652,  -552,  1015, -1293,  1491,  -282, -1544,
	  516,    -8,  -320,  -666, -1618, -1162,   126,  1469,
	 -853,   -90,  -271,   830,   107, -1421,  -247,  -951,
	 -398,   961, -1508,  -725,   448, -1065,   677, -1275,
	-1103,   430,   555,   843, -1251,   871,  1550,   105,
	  422,   587,   177,  -235,  -291,  -460,  1574,  1653,
	 -246,   778,  1159,  -147,  -777,  1483,  -602,  1119,
	-1590,   644,  -872,   349,   418,   329,  -156,   -75,
	  817,  1097,   603,   610,  1322, -1285, -1465,   384,
	-1215,  -136,  1218, -1335,  -874,   220, -1187, -1659,
	-1185, -1530, -1278,   794, -1510,  -854,  -870,   478,
	 -108,  -308,   996,   991,   958, -1460,  1522,  1628,
}

@(require_results)
fqmul :: #force_inline proc "contextless" (a, b: i16) -> i16 {
	return montgomery_reduce(i32(a) * i32(b))
}

ntt :: proc "contextless" (r: ^[N]i16) #no_bounds_check {
	j, k := 0, 1
	for l := 128; l >= 2; l >>= 1 {
		for start := 0; start < N; start = j + l {
			zeta := ZETAS[k]
			k += 1
			for j = start; j < start + l; j += 1 {
				t := fqmul(zeta, r[j+l])
				r[j+l] = r[j] - t
				r[j] = r[j] + t
			}
		}
	}
}

invntt :: proc "contextless" (r: ^[N]i16) #no_bounds_check {
	F : i16 : 1441 // mont^2/128

	j, k := 0, 127
	for l := 2; l <= 128; l <<= 1 {
		for start := 0; start < 256; start = j+l {
			zeta := ZETAS[k]
			k -= 1
			for j = start; j < start + l; j += 1 {
				t := r[j]
				r[j] = barrett_reduce(t + r[j+l])
				r[j+l] = r[j+l] - t
				r[j+l] = fqmul(zeta, r[j+l])
			}
		}
	}

	for v, i in r {
		r[i] = fqmul(v, F)
	}
}

@(require_results)
base_case_multiply :: proc "contextless" (a_0, a_1, b_0, b_1, zeta: i16) -> (i16, i16) {
	r_0 := fqmul(a_1, b_1)
	r_0 = fqmul(r_0, zeta)
	r_0 += fqmul(a_0, b_0)
	r_1 := fqmul(a_0, b_1)
	r_1 += fqmul(a_1, b_0)

	return r_0, r_1
}
