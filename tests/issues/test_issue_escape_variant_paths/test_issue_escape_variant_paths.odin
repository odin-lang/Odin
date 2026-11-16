// A variant of a type switch holds the pointers of what is switched on anywhere within it, and each field of it a call
// read gave the string parameter's pointers the path of that field, which a string does not have. With each call the
// paths grew a field longer and sixteen times more in number, so `odin check` took seconds rather than milliseconds
package test_issues

Fields :: struct {
	a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p: string,
}

Refused :: struct {}

Reading :: union {
	Fields,
	Refused,
}

read :: proc(s: string) -> Reading {
	return Fields{s, s, s, s, s, s, s, s, s, s, s, s, s, s, s, s}
}

keep :: proc(x: Fields, out: ^Fields) -> Reading {
	out.a = x.a
	return Fields{
		x.a, x.b, x.c, x.d, x.e, x.f, x.g, x.h,
		x.i, x.j, x.k, x.l, x.m, x.n, x.o, x.p,
	}
}

keep_all :: proc(s: string, out: ^Fields) {
	switch r1 in read(s) {
	case Fields:
		switch r2 in keep(r1, out) {
		case Fields:
			switch r3 in keep(r2, out) {
			case Fields:
				switch r4 in keep(r3, out) {
				case Fields:
					switch r5 in keep(r4, out) {
					case Fields:
						_ = keep(r5, out)
					case Refused:
					}
				case Refused:
				}
			case Refused:
			}
		case Refused:
		}
	case Refused:
	}
}
