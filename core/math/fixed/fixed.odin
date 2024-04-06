package math_fixed

import "core:math"
import "core:strconv"
import "base:intrinsics"
_, _, _ :: intrinsics, strconv, math

Fixed :: struct($Backing: typeid, $Fraction_Width: uint)
	where
		intrinsics.type_is_integer(Backing),
		0 <= Fraction_Width,
		Fraction_Width <= 8*size_of(Backing) {
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


init_from_f64 :: proc(x: ^$T/Fixed($Backing, $Fraction_Width), val: f64) {
	i, f := math.modf(math.abs(val))
	x.i  = Backing(f * (1<<Fraction_Width))
	x.i &= 1<<Fraction_Width - 1
	x.i |= Backing(i) << Fraction_Width
	if val < 0 {
		x.i *= -1
	}
}

init_from_parts :: proc(x: ^$T/Fixed($Backing, $Fraction_Width), integer, fraction: Backing) {
	x.i  = fraction
	x.i &= 1<<Fraction_Width - 1
	x.i |= integer
}

to_f64 :: proc(x: $T/Fixed($Backing, $Fraction_Width)) -> f64 {
	sign := -1.0 if x.i < 0 else 1.0
	num := math.abs(x.i)
	res := f64(num >> Fraction_Width)
	res += f64(num & (1<<Fraction_Width-1)) / f64(1<<Fraction_Width)
	return res * sign
}


@(require_results)
add :: proc(x, y: $T/Fixed) -> T {
	return {x.i + y.i}
}
@(require_results)
sub :: proc(x, y: $T/Fixed) -> T {
	return {x.i - y.i}
}

@(require_results)
mul :: proc(x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_mul(x.i, y.i, Fraction_Width)
	return
}
@(require_results)
mul_sat :: proc(x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_mul_sat(x.i, y.i, Fraction_Width)
	return
}

@(require_results)
div :: proc(x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_div(x.i, y.i, Fraction_Width)
	return
}
@(require_results)
div_sat :: proc(x, y: $T/Fixed($Backing, $Fraction_Width)) -> (z: T) {
	z.i = intrinsics.fixed_point_div_sat(x.i, y.i, Fraction_Width)
	return
}


@(require_results)
floor :: proc(x: $T/Fixed($Backing, $Fraction_Width)) -> Backing {
	if x.i >= 0 {
		return x.i >> Fraction_Width
	} else {
		return (x.i - (1 << (Fraction_Width - 1)) + (1 << (Fraction_Width - 2))) >> Fraction_Width
	}
}
@(require_results)
ceil :: proc(x: $T/Fixed($Backing, $Fraction_Width)) -> Backing {
	return (x.i + (1 << Fraction_Width - 1)) >> Fraction_Width
}
@(require_results)
round :: proc(x: $T/Fixed($Backing, $Fraction_Width)) -> Backing {
	return (x.i + (1 << (Fraction_Width - 1))) >> Fraction_Width
}



@(require_results)
append :: proc(dst: []byte, x: $T/Fixed($Backing, $Fraction_Width)) -> string {
	x := x
	buf: [48]byte
	i := 0
	if x.i < 0 {
		buf[i] = '-'
		i += 1
		x.i = -x.i
	}

	integer := x.i >> Fraction_Width
	fraction := x.i & (1<<Fraction_Width - 1)

	s := strconv.append_uint(buf[i:], u64(integer), 10)
	i += len(s)
	if fraction != 0 {
		buf[i] = '.'
		i += 1
		for fraction > 0 {
			fraction *= 10
			buf[i] = byte('0' + (fraction>>Fraction_Width))
			i += 1
			fraction &= 1<<Fraction_Width - 1
		}
	}



	n := copy(dst, buf[:i])
	return string(dst[:i])
}


@(require_results)
to_string :: proc(x: $T/Fixed($Backing, $Fraction_Width), allocator := context.allocator) -> string {
	buf: [48]byte
	s := append(buf[:], x)
	str := make([]byte, len(s), allocator)
	copy(str, s)
	return string(str)
}
