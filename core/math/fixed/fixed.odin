// Fixed-point rational numbers and conversion to/from `f64`.
package math_fixed

import "core:math"
import "core:strconv"
import "base:intrinsics"
_, _, _ :: intrinsics, strconv, math

Fixed :: struct($Backing: typeid, $Fraction_Width: uint)
	where
		intrinsics.type_is_integer(Backing),
		0 <= Fraction_Width,
		Fraction_Width <= 8*size_of(Backing),
		Fraction_Width < 8*size_of(Backing) || intrinsics.type_is_unsigned(Backing) {
	i: Backing,
}

Fixed4_4  :: distinct Fixed(i8, 4)
Fixed5_3  :: distinct Fixed(i8, 3)
Fixed6_2  :: distinct Fixed(i8, 2)
Fixed7_1  :: distinct Fixed(i8, 1)

Fixed8_8  :: distinct Fixed(i16, 8)
Fixed13_3 :: distinct Fixed(i16, 3)

Fixed16_16 :: distinct Fixed(i32, 16)
Fixed26_6  :: distinct Fixed(i32,  6)

Fixed32_32 :: distinct Fixed(i64, 32)
Fixed52_12 :: distinct Fixed(i64, 12)


init_from_f64 :: proc "contextless" (x: ^$T/Fixed($Backing, $Fraction_Width), val: f64) -> (ok: bool) {
	when intrinsics.type_is_unsigned(Backing) {
		LOWER :: 0.0
		UPPER :: f64(1 << (8*size_of(Backing)))
	} else {
		LOWER :: -f64(1 << (8*size_of(Backing) - 1))
		UPPER :: f64(1 << (8*size_of(Backing) - 1))
	}

	scaled := math.trunc(val * (1<<Fraction_Width))
	switch {
	case math.is_nan(scaled):
		x.i = 0
	case scaled < LOWER:
		x.i = min(Backing)
	case scaled >= UPPER:
		x.i = max(Backing)
	case:
		x.i = Backing(scaled)
		return true
	}
	return false
}

init_from_parts :: proc "contextless" (x: ^$T/Fixed($Backing, $Fraction_Width), integer, fraction: Backing) {
	x.i  = fraction
	x.i &= 1<<Fraction_Width - 1
	x.i |= (integer << Fraction_Width)
}

to_f64 :: proc "contextless" (x: $T/Fixed($Backing, $Fraction_Width)) -> f64 {
	return f64(x.i) / (1<<Fraction_Width)
}


@(require_results)
add :: proc "contextless" (x, y: $T/Fixed) -> T {
	return {x.i + y.i}
}
@(require_results)
sub :: proc "contextless" (x, y: $T/Fixed) -> T {
	return {x.i - y.i}
}

@(require_results)
mul :: proc "contextless" (x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_mul(x.i, y.i, Fraction_Width)
	return
}
@(require_results)
mul_sat :: proc "contextless" (x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_mul_sat(x.i, y.i, Fraction_Width)
	return
}

@(require_results)
div :: proc "contextless" (x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_div(x.i, y.i, Fraction_Width)
	return
}
@(require_results)
div_sat :: proc "contextless" (x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_div_sat(x.i, y.i, Fraction_Width)
	return
}


@(require_results)
floor :: proc "contextless" (x: $T/Fixed($Backing, $Fraction_Width)) -> Backing {
	return x.i >> Fraction_Width
}
@(require_results)
ceil :: proc "contextless" (x: $T/Fixed($Backing, $Fraction_Width)) -> Backing {
	return (x.i >> Fraction_Width) + Backing(x.i & (1<<Fraction_Width - 1) != 0)
}
@(require_results)
round :: proc "contextless" (x: $T/Fixed($Backing, $Fraction_Width)) -> Backing {
	when Fraction_Width == 0 {
		return x.i
	} else {
		return (x.i >> Fraction_Width) + ((x.i >> (Fraction_Width - 1)) & 1)
	}
}

// Writes `x` as a decimal number into `dst` and returns the written part of `dst` as a string.
// Returns "" if `dst` isn't large enough to hold the result.
@(require_results)
write :: proc(dst: []byte, x: $T/Fixed($Backing, $Fraction_Width)) -> string {
	when size_of(Backing) < 16 && Fraction_Width <= 60 {
		U :: u64
		write_uint :: strconv.write_uint
	} else {
		U :: u128
		write_uint :: strconv.write_u128
	}

	buf: [3 + 8*size_of(Backing)]byte
	i := 0

	magnitude := U(x.i)
	if x.i < 0 {
		buf[i] = '-'
		i += 1
		magnitude = -magnitude
	}

	integer := magnitude >> Fraction_Width
	fraction := magnitude & (1<<Fraction_Width - 1)

	s := write_uint(buf[i:], integer, 10)
	i += len(s)
	if fraction != 0 {
		buf[i] = '.'
		i += 1
		for fraction > 0 {
			when Fraction_Width + 4 <= 8*size_of(U) {
				fraction *= 10
				buf[i] = byte('0' + (fraction >> Fraction_Width))
				fraction &= 1<<Fraction_Width - 1
			} else {
				LOW :: Fraction_Width - 4
				lo := (fraction & (1<<LOW - 1)) * 10
				hi := (fraction >> LOW) * 10 + (lo >> LOW)
				buf[i] = byte('0' + (hi >> 4))
				fraction = (hi & 15) << LOW | (lo & (1<<LOW - 1))
			}
			i += 1
		}
	}

	if len(dst) < i {
		return ""
	}
	copy(dst, buf[:i])
	return string(dst[:i])
}


@(require_results)
to_string :: proc(x: $T/Fixed($Backing, $Fraction_Width), allocator := context.allocator) -> string {
	buf: [3 + 8*size_of(Backing)]byte
	s := write(buf[:], x)
	str := make([]byte, len(s), allocator)
	copy(str, s)
	return string(str)
}
