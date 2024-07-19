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
	x.i |= (integer << Fraction_Width)
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
	Integer_Width :: 8*size_of(Backing) - Fraction_Width

	x := x
	buf: [48]byte
	i := 0

	if !intrinsics.type_is_unsigned(Backing) && x.i == min(Backing) {
		// edge case handling for signed numbers
		buf[i] = '-'
		i += 1
		i += copy(buf[i:], _power_of_two_table[Integer_Width])
	} else {
		if x.i < 0 {
			buf[i] = '-'
			i += 1
			x.i = -x.i
		}

		when size_of(Backing) < 16 {
			T :: u64
			append_uint :: strconv.append_uint
		} else {
			T :: u128
			append_uint :: strconv.append_u128
		}

		integer := T(x.i) >> Fraction_Width
		fraction := T(x.i) & (1<<Fraction_Width - 1)

		s := append_uint(buf[i:], integer, 10)
		i += len(s)
		if fraction != 0 {
			buf[i] = '.'
			i += 1
			for fraction > 0 {
				fraction *= 10
				buf[i] = byte('0' + (fraction>>Fraction_Width) % 10)
				i += 1
				fraction &= 1<<Fraction_Width - 1
			}
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


@(private)
_power_of_two_table := [129]string{
	"0.5",
	"1",
	"2",
	"4",
	"8",
	"16",
	"32",
	"64",
	"128",
	"256",
	"512",
	"1024",
	"2048",
	"4096",
	"8192",
	"16384",
	"32768",
	"65536",
	"131072",
	"262144",
	"524288",
	"1048576",
	"2097152",
	"4194304",
	"8388608",
	"16777216",
	"33554432",
	"67108864",
	"134217728",
	"268435456",
	"536870912",
	"1073741824",
	"2147483648",
	"4294967296",
	"8589934592",
	"17179869184",
	"34359738368",
	"68719476736",
	"137438953472",
	"274877906944",
	"549755813888",
	"1099511627776",
	"2199023255552",
	"4398046511104",
	"8796093022208",
	"17592186044416",
	"35184372088832",
	"70368744177664",
	"140737488355328",
	"281474976710656",
	"562949953421312",
	"1125899906842624",
	"2251799813685248",
	"4503599627370496",
	"9007199254740992",
	"18014398509481984",
	"36028797018963968",
	"72057594037927936",
	"144115188075855872",
	"288230376151711744",
	"576460752303423488",
	"1152921504606846976",
	"2305843009213693952",
	"4611686018427387904",
	"9223372036854775808",
	"18446744073709551616",
	"36893488147419103232",
	"73786976294838206464",
	"147573952589676412928",
	"295147905179352825856",
	"590295810358705651712",
	"1180591620717411303424",
	"2361183241434822606848",
	"4722366482869645213696",
	"9444732965739290427392",
	"18889465931478580854784",
	"37778931862957161709568",
	"75557863725914323419136",
	"151115727451828646838272",
	"302231454903657293676544",
	"604462909807314587353088",
	"1208925819614629174706176",
	"2417851639229258349412352",
	"4835703278458516698824704",
	"9671406556917033397649408",
	"19342813113834066795298816",
	"38685626227668133590597632",
	"77371252455336267181195264",
	"154742504910672534362390528",
	"309485009821345068724781056",
	"618970019642690137449562112",
	"1237940039285380274899124224",
	"2475880078570760549798248448",
	"4951760157141521099596496896",
	"9903520314283042199192993792",
	"19807040628566084398385987584",
	"39614081257132168796771975168",
	"79228162514264337593543950336",
	"158456325028528675187087900672",
	"316912650057057350374175801344",
	"633825300114114700748351602688",
	"1267650600228229401496703205376",
	"2535301200456458802993406410752",
	"5070602400912917605986812821504",
	"10141204801825835211973625643008",
	"20282409603651670423947251286016",
	"40564819207303340847894502572032",
	"81129638414606681695789005144064",
	"162259276829213363391578010288128",
	"324518553658426726783156020576256",
	"649037107316853453566312041152512",
	"1298074214633706907132624082305024",
	"2596148429267413814265248164610048",
	"5192296858534827628530496329220096",
	"10384593717069655257060992658440192",
	"20769187434139310514121985316880384",
	"41538374868278621028243970633760768",
	"83076749736557242056487941267521536",
	"166153499473114484112975882535043072",
	"332306998946228968225951765070086144",
	"664613997892457936451903530140172288",
	"1329227995784915872903807060280344576",
	"2658455991569831745807614120560689152",
	"5316911983139663491615228241121378304",
	"10633823966279326983230456482242756608",
	"21267647932558653966460912964485513216",
	"42535295865117307932921825928971026432",
	"85070591730234615865843651857942052864",
	"170141183460469231731687303715884105728",
}
