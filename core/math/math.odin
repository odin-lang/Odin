package math

import "intrinsics"
_ :: intrinsics;

Float_Class :: enum {
	Normal,    // an ordinary nonzero floating point value
	Subnormal, // a subnormal floating point value
	Zero,      // zero
	Neg_Zero,  // the negative zero
	NaN,       // Not-A-Number (NaN)
	Inf,       // positive infinity
	Neg_Inf    // negative infinity
};

TAU          :: 6.28318530717958647692528676655900576;
PI           :: 3.14159265358979323846264338327950288;

E            :: 2.71828182845904523536;

τ :: TAU;
π :: PI;
e :: E;

SQRT_TWO     :: 1.41421356237309504880168872420969808;
SQRT_THREE   :: 1.73205080756887729352744634150587236;
SQRT_FIVE    :: 2.23606797749978969640917366873127623;

LN2          :: 0.693147180559945309417232121458176568;
LN10         :: 2.30258509299404568401799145468436421;

MAX_F64_PRECISION :: 16; // Maximum number of meaningful digits after the decimal point for 'f64'
MAX_F32_PRECISION ::  8; // Maximum number of meaningful digits after the decimal point for 'f32'

RAD_PER_DEG :: TAU/360.0;
DEG_PER_RAD :: 360.0/TAU;


@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.sqrt.f32")
	sqrt_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.sqrt.f64")
	sqrt_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.sin.f32")
	sin_f32 :: proc(θ: f32) -> f32 ---;
	@(link_name="llvm.sin.f64")
	sin_f64 :: proc(θ: f64) -> f64 ---;

	@(link_name="llvm.cos.f32")
	cos_f32 :: proc(θ: f32) -> f32 ---;
	@(link_name="llvm.cos.f64")
	cos_f64 :: proc(θ: f64) -> f64 ---;

	@(link_name="llvm.pow.f32")
	pow_f32 :: proc(x, power: f32) -> f32 ---;
	@(link_name="llvm.pow.f64")
	pow_f64 :: proc(x, power: f64) -> f64 ---;

	@(link_name="llvm.fmuladd.f32")
	fmuladd_f32 :: proc(a, b, c: f32) -> f32 ---;
	@(link_name="llvm.fmuladd.f64")
	fmuladd_f64 :: proc(a, b, c: f64) -> f64 ---;

	@(link_name="llvm.log.f32")
	ln_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.log.f64")
	ln_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.exp.f32")
	exp_f32 :: proc(x: f32) -> f32 ---;
	@(link_name="llvm.exp.f64")
	exp_f64 :: proc(x: f64) -> f64 ---;

	@(link_name="llvm.ldexp.f32")
	ldexp_f32 :: proc(val: f32, exp: i32) -> f32 ---;

	@(link_name="llvm.ldexp.f64")
	ldexp_f64 :: proc(val: f64, exp: i32) -> f64 ---;
}

sqrt      :: proc{sqrt_f32, sqrt_f64};
sin       :: proc{sin_f32, sin_f64};
cos       :: proc{cos_f32, cos_f64};
pow       :: proc{pow_f32, pow_f64};
fmuladd   :: proc{fmuladd_f32, fmuladd_f64};
ln        :: proc{ln_f32, ln_f64};
exp       :: proc{exp_f32, exp_f64};

ldexp :: proc{ldexp_f32, ldexp_f64};

log_f32 :: proc(x, base: f32) -> f32 { return ln(x) / ln(base); }
log_f64 :: proc(x, base: f64) -> f64 { return ln(x) / ln(base); }
log     :: proc{log_f32, log_f64};

log2_f32 :: proc(x: f32) -> f32 { return ln(x)/LN2; }
log2_f64 :: proc(x: f64) -> f64 { return ln(x)/LN2; }
log2     :: proc{log2_f32, log2_f64};

log10_f32 :: proc(x: f32) -> f32 { return ln(x)/LN10; }
log10_f64 :: proc(x: f64) -> f64 { return ln(x)/LN10; }
log10     :: proc{log10_f32, log10_f64};


tan_f32 :: proc "c" (θ: f32) -> f32 { return sin(θ)/cos(θ); }
tan_f64 :: proc "c" (θ: f64) -> f64 { return sin(θ)/cos(θ); }
tan     :: proc{tan_f32, tan_f64};

lerp :: proc(a, b: $T, t: $E) -> (x: T) { return a*(1-t) + b*t; }

unlerp_f32 :: proc(a, b, x: f32) -> (t: f32) { return (x-a)/(b-a); }
unlerp_f64 :: proc(a, b, x: f64) -> (t: f64) { return (x-a)/(b-a); }
unlerp     :: proc{unlerp_f32, unlerp_f64};


wrap :: proc(x, y: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	tmp := mod(x, y);
	return y + tmp if tmp < 0 else tmp;
}
angle_diff :: proc(a, b: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {

	dist := wrap(b - a, TAU);
	return wrap(dist*2, TAU) - dist;
}

angle_lerp :: proc(a, b, t: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	return a + angle_diff(a, b) * t;
}

step :: proc(edge, x: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	return 0 if x < edge else 1;
}

smoothstep :: proc(edge0, edge1, x: $T) -> T where intrinsics.type_is_numeric(T), !intrinsics.type_is_array(T) {
	t := clamp((x - edge0) / (edge1 - edge0), 0, 1);
	return t * t * (3 - 2*t);
}

bias :: proc(t, b: $T) -> T where intrinsics.type_is_numeric(T) {
	return t / (((1/b) - 2) * (1 - t) + 1);
}
gain :: proc(t, g: $T) -> T where intrinsics.type_is_numeric(T) {
	if t < 0.5 {
		return bias(t*2, g)*0.5;
	}
	return bias(t*2 - 1, 1 - g)*0.5 + 0.5;
}


sign_f32 :: proc(x: f32) -> f32 { return f32(int(0 < x) - int(x < 0)); }
sign_f64 :: proc(x: f64) -> f64 { return f64(int(0 < x) - int(x < 0)); }
sign     :: proc{sign_f32, sign_f64};

sign_bit_f32 :: proc(x: f32) -> bool {
	return (transmute(u32)x) & (1<<31) != 0;
}
sign_bit_f64 :: proc(x: f64) -> bool {
	return (transmute(u64)x) & (1<<63) != 0;
}
sign_bit :: proc{sign_bit_f32, sign_bit_f64};

copy_sign_f32 :: proc(x, y: f32) -> f32 {
	ix := transmute(u32)x;
	iy := transmute(u32)y;
	ix &= 0x7fff_ffff;
	ix |= iy & 0x8000_0000;
	return transmute(f32)ix;
}
copy_sign_f64 :: proc(x, y: f64) -> f64 {
	ix := transmute(u64)x;
	iy := transmute(u64)y;
	ix &= 0x7fff_ffff_ffff_ffff;
	ix |= iy & 0x8000_0000_0000_0000;
	return transmute(f64)ix;
}
copy_sign :: proc{copy_sign_f32, copy_sign_f64};


to_radians_f32 :: proc(degrees: f32) -> f32 { return degrees * RAD_PER_DEG; }
to_radians_f64 :: proc(degrees: f64) -> f64 { return degrees * RAD_PER_DEG; }
to_degrees_f32 :: proc(radians: f32) -> f32 { return radians * DEG_PER_RAD; }
to_degrees_f64 :: proc(radians: f64) -> f64 { return radians * DEG_PER_RAD; }
to_radians     :: proc{to_radians_f32, to_radians_f64};
to_degrees     :: proc{to_degrees_f32, to_degrees_f64};

trunc_f32 :: proc(x: f32) -> f32 {
	trunc_internal :: proc(f: f32) -> f32 {
		mask :: 0xff;
		shift :: 32 - 9;
		bias :: 0x7f;

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f);
			case f == 0: return f;
			case:        return 0;
			}
		}

		x := transmute(u32)f;
		e := (x >> shift) & mask - bias;

		if e < shift {
			x &= ~(1 << (shift-e)) - 1;
		}
		return transmute(f32)x;
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x;
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x);
}

trunc_f64 :: proc(x: f64) -> f64 {
	trunc_internal :: proc(f: f64) -> f64 {
		mask :: 0x7ff;
		shift :: 64 - 12;
		bias :: 0x3ff;

		if f < 1 {
			switch {
			case f < 0:  return -trunc_internal(-f);
			case f == 0: return f;
			case:        return 0;
			}
		}

		x := transmute(u64)f;
		e := (x >> shift) & mask - bias;

		if e < shift {
			x &= ~(1 << (shift-e)) - 1;
		}
		return transmute(f64)x;
	}
	switch classify(x) {
	case .Zero, .Neg_Zero, .NaN, .Inf, .Neg_Inf:
		return x;
	case .Normal, .Subnormal: // carry on
	}
	return trunc_internal(x);
}

trunc :: proc{trunc_f32, trunc_f64};

round_f32 :: proc(x: f32) -> f32 {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round_f64 :: proc(x: f64) -> f64 {
	return ceil(x - 0.5) if x < 0 else floor(x + 0.5);
}
round :: proc{round_f32, round_f64};


ceil_f32 :: proc(x: f32) -> f32 { return -floor(-x); }
ceil_f64 :: proc(x: f64) -> f64 { return -floor(-x); }
ceil :: proc{ceil_f32, ceil_f64};

floor_f32 :: proc(x: f32) -> f32 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x;
	}
	if x < 0 {
		d, fract := modf(-x);
		if fract != 0.0 {
			d = d + 1;
		}
		return -d;
	}
	d, _ := modf(x);
	return d;
}
floor_f64 :: proc(x: f64) -> f64 {
	if x == 0 || is_nan(x) || is_inf(x) {
		return x;
	}
	if x < 0 {
		d, fract := modf(-x);
		if fract != 0.0 {
			d = d + 1;
		}
		return -d;
	}
	d, _ := modf(x);
	return d;
}
floor :: proc{floor_f32, floor_f64};


floor_div :: proc(x, y: $T) -> T
	where intrinsics.type_is_integer(T) {
	a := x / y;
	r := x % y;
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		a -= 1;
	}
	return a;
}

floor_mod :: proc(x, y: $T) -> T
	where intrinsics.type_is_integer(T) {
	r := x % y;
	if (r > 0 && y < 0) || (r < 0 && y > 0) {
		r += y;
	}
	return r;
}


modf_f32 :: proc(x: f32) -> (int: f32, frac: f32) {
	shift :: 32 - 8 - 1;
	mask  :: 0xff;
	bias  :: 127;

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x);
			return -int, -frac;
		case x == 0:
			return x, x;
		}
		return 0, x;
	}

	i := transmute(u32)x;
	e := uint(i>>shift)&mask - bias;

	if e < shift {
		i &~= 1<<(shift-e) - 1;
	}
	int = transmute(f32)i;
	frac = x - int;
	return;
}
modf_f64 :: proc(x: f64) -> (int: f64, frac: f64) {
	shift :: 64 - 11 - 1;
	mask  :: 0x7ff;
	bias  :: 1023;

	if x < 1 {
		switch {
		case x < 0:
			int, frac = modf(-x);
			return -int, -frac;
		case x == 0:
			return x, x;
		}
		return 0, x;
	}

	i := transmute(u64)x;
	e := uint(i>>shift)&mask - bias;

	if e < shift {
		i &~= 1<<(shift-e) - 1;
	}
	int = transmute(f64)i;
	frac = x - int;
	return;
}
modf :: proc{modf_f32, modf_f64};
split_decimal :: modf;

mod_f32 :: proc(x, y: f32) -> (n: f32) {
	z := abs(y);
	n = remainder(abs(x), z);
	if sign(n) < 0 {
		n += z;
	}
	return copy_sign(n, x);
}
mod_f64 :: proc(x, y: f64) -> (n: f64) {
	z := abs(y);
	n = remainder(abs(x), z);
	if sign(n) < 0 {
		n += z;
	}
	return copy_sign(n, x);
}
mod :: proc{mod_f32, mod_f64};

remainder_f32 :: proc(x, y: f32) -> f32 { return x - round(x/y) * y; }
remainder_f64 :: proc(x, y: f64) -> f64 { return x - round(x/y) * y; }
remainder :: proc{remainder_f32, remainder_f64};



gcd :: proc(x, y: $T) -> T
	where intrinsics.type_is_ordered_numeric(T) {
	x, y := x, y;
	for y != 0 {
		x %= y;
		x, y = y, x;
	}
	return abs(x);
}

lcm :: proc(x, y: $T) -> T
	where intrinsics.type_is_ordered_numeric(T) {
	return x / gcd(x, y) * y;
}

frexp_f32 :: proc(x: f32) -> (significand: f32, exponent: int) {
	switch {
	case x == 0:
		return 0, 0;
	case x < 0:
		significand, exponent = frexp(-x);
		return -significand, exponent;
	}
	ex := trunc(log2(x));
	exponent = int(ex);
	significand = x / pow(2.0, ex);
	if abs(significand) >= 1 {
		exponent += 1;
		significand /= 2;
	}
	if exponent == 1024 && significand == 0 {
		significand = 0.99999999999999988898;
	}
	return;
}
frexp_f64 :: proc(x: f64) -> (significand: f64, exponent: int) {
	switch {
	case x == 0:
		return 0, 0;
	case x < 0:
		significand, exponent = frexp(-x);
		return -significand, exponent;
	}
	ex := trunc(log2(x));
	exponent = int(ex);
	significand = x / pow(2.0, ex);
	if abs(significand) >= 1 {
		exponent += 1;
		significand /= 2;
	}
	if exponent == 1024 && significand == 0 {
		significand = 0.99999999999999988898;
	}
	return;
}
frexp :: proc{frexp_f32, frexp_f64};




binomial :: proc(n, k: int) -> int {
	switch {
	case k <= 0:  return 1;
	case 2*k > n: return binomial(n, n-k);
	}

	b := n;
	for i in 2..<k {
		b = (b * (n+1-i))/i;
	}
	return b;
}

factorial :: proc(n: int) -> int {
	when size_of(int) == size_of(i64) {
		@static table := [21]int{
			1,
			1,
			2,
			6,
			24,
			120,
			720,
			5_040,
			40_320,
			362_880,
			3_628_800,
			39_916_800,
			479_001_600,
			6_227_020_800,
			87_178_291_200,
			1_307_674_368_000,
			20_922_789_888_000,
			355_687_428_096_000,
			6_402_373_705_728_000,
			121_645_100_408_832_000,
			2_432_902_008_176_640_000,
		};
	} else {
		@static table := [13]int{
			1,
			1,
			2,
			6,
			24,
			120,
			720,
			5_040,
			40_320,
			362_880,
			3_628_800,
			39_916_800,
			479_001_600,
		};
	}

	assert(n >= 0, "parameter must not be negative");
	assert(n < len(table), "parameter is too large to lookup in the table");
	return 0;
}

classify_f32 :: proc(x: f32) -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i32)x;
		if i < 0 {
			return .Neg_Zero;
		}
		return .Zero;
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf;
		}
		return .Inf;
	case !(x == x):
		return .NaN;
	}

	u := transmute(u32)x;
	exp := int(u>>23) & (1<<8 - 1);
	if exp == 0 {
		return .Subnormal;
	}
	return .Normal;
}
classify_f64 :: proc(x: f64) -> Float_Class {
	switch {
	case x == 0:
		i := transmute(i64)x;
		if i < 0 {
			return .Neg_Zero;
		}
		return .Zero;
	case x*0.5 == x:
		if x < 0 {
			return .Neg_Inf;
		}
		return .Inf;
	case !(x == x):
		return .NaN;
	}
	u := transmute(u64)x;
	exp := int(u>>52) & (1<<11 - 1);
	if exp == 0 {
		return .Subnormal;
	}
	return .Normal;
}
classify :: proc{classify_f32, classify_f64};

is_nan_f32 :: proc(x: f32) -> bool { return classify(x) == .NaN; }
is_nan_f64 :: proc(x: f64) -> bool { return classify(x) == .NaN; }
is_nan :: proc{is_nan_f32, is_nan_f64};


// is_inf reports whether f is an infinity, according to sign.
// If sign > 0, is_inf reports whether f is positive infinity.
// If sign < 0, is_inf reports whether f is negative infinity.
// If sign == 0, is_inf reports whether f is either infinity.
is_inf_f32 :: proc(x: f32, sign: int = 0) -> bool {
	class := classify(abs(x));
	switch {
	case sign > 0:
		return class == .Inf;
	case sign < 0:
		return class == .Neg_Inf;
	}
	return class == .Inf || class == .Neg_Inf;
}
is_inf_f64 :: proc(x: f64, sign: int = 0) -> bool {
	class := classify(abs(x));
	switch {
	case sign > 0:
		return class == .Inf;
	case sign < 0:
		return class == .Neg_Inf;
	}
	return class == .Inf || class == .Neg_Inf;
}
is_inf :: proc{is_inf_f32, is_inf_f64};



is_power_of_two :: proc(x: int) -> bool {
	return x > 0 && (x & (x-1)) == 0;
}

next_power_of_two :: proc(x: int) -> int {
	k := x -1;
	when size_of(int) == 8 {
		k = k | (k >> 32);
	}
	k = k | (k >> 16);
	k = k | (k >> 8);
	k = k | (k >> 4);
	k = k | (k >> 2);
	k = k | (k >> 1);
	k += 1 + int(x <= 0);
	return k;
}

sum :: proc(x: $T/[]$E) -> (res: E)
	where intrinsics.type_is_numeric(E) {
	for i in x {
		res += i;
	}
	return;
}

prod :: proc(x: $T/[]$E) -> (res: E)
	where intrinsics.type_is_numeric(E) {
	for i in x {
		res *= i;
	}
	return;
}

cumsum_inplace :: proc(x: $T/[]$E) -> T
	where intrinsics.type_is_numeric(E) {
	for i in 1..<len(x) {
		x[i] = x[i-1] + x[i];
	}
}


cumsum :: proc(dst, src: $T/[]$E) -> T
	where intrinsics.type_is_numeric(E) {
	N := min(len(dst), len(src));
	if N > 0 {
		dst[0] = src[0];
		for i in 1..<N {
			dst[i] = dst[i-1] + src[i];
		}
	}
	return dst[:N];
}



atan2_f32 :: proc(y, x: f32) -> f32 {
	// TODO(bill): Better atan2_f32
	return f32(atan2_f64(f64(y), f64(x)));
}

atan2_f64 :: proc(y, x: f64) -> f64 {
	// TODO(bill): Faster atan2_f64 if possible

	// The original C code:
	//   Stephen L. Moshier
	//   moshier@na-net.ornl.gov

	NAN :: 0h7fff_ffff_ffff_ffff;
	INF :: 0h7FF0_0000_0000_0000;
	PI  :: 0h4009_21fb_5444_2d18;

	atan :: proc(x: f64) -> f64 {
		if x == 0 {
			return x;
		}
		if x > 0 {
			return s_atan(x);
		}
		return -s_atan(-x);
	}
	// s_atan reduces its argument (known to be positive) to the range [0, 0.66] and calls x_atan.
	s_atan :: proc(x: f64) -> f64 {
		MORE_BITS :: 6.123233995736765886130e-17; // pi/2 = PIO2 + MORE_BITS
		TAN3PI08  :: 2.41421356237309504880;      // tan(3*pi/8)
		if x <= 0.66 {
			return x_atan(x);
		}
		if x > TAN3PI08 {
			return PI/2 - x_atan(1/x) + MORE_BITS;
		}
		return PI/4 + x_atan((x-1)/(x+1)) + 0.5*MORE_BITS;
	}
	// x_atan evaluates a series valid in the range [0, 0.66].
	x_atan :: proc(x: f64) -> f64 {
		P0 :: -8.750608600031904122785e-01;
		P1 :: -1.615753718733365076637e+01;
		P2 :: -7.500855792314704667340e+01;
		P3 :: -1.228866684490136173410e+02;
		P4 :: -6.485021904942025371773e+01;
		Q0 :: +2.485846490142306297962e+01;
		Q1 :: +1.650270098316988542046e+02;
		Q2 :: +4.328810604912902668951e+02;
		Q3 :: +4.853903996359136964868e+02;
		Q4 :: +1.945506571482613964425e+02;

		z := x * x;
		z = z * ((((P0*z+P1)*z+P2)*z+P3)*z + P4) / (((((z+Q0)*z+Q1)*z+Q2)*z+Q3)*z + Q4);
		z = x*z + x;
		return z;
	}

	switch {
	case is_nan(y) || is_nan(x):
		return NAN;
	case y == 0:
		if x >= 0 && !sign_bit(x) {
			return copy_sign(0.0, y);
		}
		return copy_sign(PI, y);
	case x == 0:
		return copy_sign(PI*0.5, y);
	case is_inf(x, 0):
		if is_inf(x, 1) {
			if is_inf(y, 0) {
				return copy_sign(PI*0.25, y);
			}
			return copy_sign(0, y);
		}
		if is_inf(y, 0) {
			return copy_sign(PI*0.75, y);
		}
		return copy_sign(PI, y);
	case is_inf(y, 0):
		return copy_sign(PI*0.5, y);
	}

	q := atan(y / x);
	if x < 0 {
		if q <= 0 {
			return q + PI;
		}
		return q - PI;
	}
	return q;
}


atan2 :: proc{atan2_f32, atan2_f64};

atan_f32 :: proc(x: f32) -> f32 {
	return atan2_f32(x, 1);
}
atan_f64 :: proc(x: f64) -> f64 {
	return atan2_f64(x, 1);
}
atan :: proc{atan_f32, atan_f64};

asin_f32 :: proc(x: f32) -> f32 {
	return atan2_f32(x, 1 + sqrt_f32(1 - x*x));
}
asin_f64 :: proc(x: f64) -> f64 {
	return atan2_f64(x, 1 + sqrt_f64(1 - x*x));
}
asin :: proc{asin_f32, asin_f64};

acos_f32 :: proc(x: f32) -> f32 {
	return 2 * atan2_f32(sqrt_f32(1 - x), sqrt_f32(1 + x));
}
acos_f64 :: proc(x: f64) -> f64 {
	return 2 * atan2_f64(sqrt_f64(1 - x), sqrt_f64(1 + x));
}
acos :: proc{acos_f32, acos_f64};


sinh_f32 :: proc(x: f32) -> f32 {
	return (exp(x) - exp(-x))*0.5;
}
sinh_f64 :: proc(x: f64) -> f64 {
	return (exp(x) - exp(-x))*0.5;
}
sinh :: proc{sinh_f32, sinh_f64};

cosh_f32 :: proc(x: f32) -> f32 {
	return (exp(x) + exp(-x))*0.5;
}
cosh_f64 :: proc(x: f64) -> f64 {
	return (exp(x) + exp(-x))*0.5;
}
cosh :: proc{cosh_f32, cosh_f64};

tanh_f32 :: proc(x: f32) -> f32 {
	t := exp(2*x);
	return (t - 1) / (t + 1);
}
tanh_f64 :: proc(x: f64) -> f64 {
	t := exp(2*x);
	return (t - 1) / (t + 1);
}
tanh :: proc{tanh_f32, tanh_f64};


F32_DIG        :: 6;
F32_EPSILON    :: 1.192092896e-07;
F32_GUARD      :: 0;
F32_MANT_DIG   :: 24;
F32_MAX        :: 3.402823466e+38;
F32_MAX_10_EXP :: 38;
F32_MAX_EXP    :: 128;
F32_MIN        :: 1.175494351e-38;
F32_MIN_10_EXP :: -37;
F32_MIN_EXP    :: -125;
F32_NORMALIZE  :: 0;
F32_RADIX      :: 2;
F32_ROUNDS     :: 1;

F64_DIG        :: 15;                       // # of decimal digits of precision
F64_EPSILON    :: 2.2204460492503131e-016;  // smallest such that 1.0+F64_EPSILON != 1.0
F64_MANT_DIG   :: 53;                       // # of bits in mantissa
F64_MAX        :: 1.7976931348623158e+308;  // max value
F64_MAX_10_EXP :: 308;                      // max decimal exponent
F64_MAX_EXP    :: 1024;                     // max binary exponent
F64_MIN        :: 2.2250738585072014e-308;  // min positive value
F64_MIN_10_EXP :: -307;                     // min decimal exponent
F64_MIN_EXP    :: -1021;                    // min binary exponent
F64_RADIX      :: 2;                        // exponent radix
F64_ROUNDS     :: 1;                        // addition rounding: near
