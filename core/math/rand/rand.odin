package rand

import "core:intrinsics"
import "core:math"

Rand :: struct {
	state: u64,
	inc:   u64,
}


@(private)
global_rand := create(u64(intrinsics.read_cycle_counter()))

set_global_seed :: proc(seed: u64) {
	init(&global_rand, seed)
}

create :: proc(seed: u64) -> Rand {
	r: Rand
	init(&r, seed)
	return r
}

init :: proc(r: ^Rand, seed: u64) {
	r.state = 0
	r.inc = (seed << 1) | 1
	_random(r)
	r.state += seed
	_random(r)
}

_random :: proc(r: ^Rand) -> u32 {
	r := r
	if r == nil {
		// NOTE(bill, 2020-09-07): Do this so that people can
		// enforce the global random state if necessary with `nil`
		r = &global_rand
	}
	old_state := r.state
	r.state = old_state * 6364136223846793005 + (r.inc|1)
	xor_shifted := u32(((old_state>>18) ~ old_state) >> 27)
	rot := u32(old_state >> 59)
	return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 31))
}

uint32 :: proc(r: ^Rand = nil) -> u32 { return _random(r) }

uint64 :: proc(r: ^Rand = nil) -> u64 {
	a := u64(_random(r))
	b := u64(_random(r))
	return (a<<32) | b
}

uint128 :: proc(r: ^Rand = nil) -> u128 {
	a := u128(_random(r))
	b := u128(_random(r))
	c := u128(_random(r))
	d := u128(_random(r))
	return (a<<96) | (b<<64) | (c<<32) | d
}

int31  :: proc(r: ^Rand = nil) -> i32  { return i32(uint32(r) << 1 >> 1) }
int63  :: proc(r: ^Rand = nil) -> i64  { return i64(uint64(r) << 1 >> 1) }
int127 :: proc(r: ^Rand = nil) -> i128 { return i128(uint128(r) << 1 >> 1) }

int31_max :: proc(n: i32, r: ^Rand = nil) -> i32 {
	if n <= 0 {
		panic("Invalid argument to int31_max")
	}
	if n&(n-1) == 0 {
		return int31(r) & (n-1)
	}
	max := i32((1<<31) - 1 - (1<<31)%u32(n))
	v := int31(r)
	for v > max {
		v = int31(r)
	}
	return v % n
}

int63_max :: proc(n: i64, r: ^Rand = nil) -> i64 {
	if n <= 0 {
		panic("Invalid argument to int63_max")
	}
	if n&(n-1) == 0 {
		return int63(r) & (n-1)
	}
	max := i64((1<<63) - 1 - (1<<63)%u64(n))
	v := int63(r)
	for v > max {
		v = int63(r)
	}
	return v % n
}

int127_max :: proc(n: i128, r: ^Rand = nil) -> i128 {
	if n <= 0 {
		panic("Invalid argument to int127_max")
	}
	if n&(n-1) == 0 {
		return int127(r) & (n-1)
	}
	max := i128((1<<127) - 1 - (1<<127)%u128(n))
	v := int127(r)
	for v > max {
		v = int127(r)
	}
	return v % n
}

int_max :: proc(n: int, r: ^Rand = nil) -> int {
	if n <= 0 {
		panic("Invalid argument to int_max")
	}
	when size_of(int) == 4 {
		return int(int31_max(i32(n), r))
	} else {
		return int(int63_max(i64(n), r))
	}
}

// Uniform random distribution [0, 1)
float64 :: proc(r: ^Rand = nil) -> f64 { return f64(int63_max(1<<53, r)) / (1 << 53) }
// Uniform random distribution [0, 1)
float32 :: proc(r: ^Rand = nil) -> f32 { return f32(float64(r)) }

float64_range :: proc(lo, hi: f64, r: ^Rand = nil) -> f64 { return (hi-lo)*float64(r) + lo }
float32_range :: proc(lo, hi: f32, r: ^Rand = nil) -> f32 { return (hi-lo)*float32(r) + lo }
float64_uniform :: float64_range
float32_uniform :: float32_range


// Triangular Distribution
// See: http://wikipedia.org/wiki/Triangular_distribution
float64_trianglular :: proc(lo, hi: f64, mode: Maybe(f64), r: ^Rand = nil) -> f64 {
	if hi-lo == 0 {
		return lo
	}
	lo, hi := lo, hi
	u := float64(r)
	c := f64(0.5) if mode == nil else clamp((mode.?-lo) / (hi-lo), 0, 1)
	if u > c {
		u = 1-u
		c = 1-c
		lo, hi = hi, lo
	}
	return lo + (hi - lo) * math.sqrt(u * c)

}
// Triangular Distribution
// See: http://wikipedia.org/wiki/Triangular_distribution
float32_trianglular :: proc(lo, hi: f32, mode: Maybe(f32), r: ^Rand = nil) -> f32 {

	if hi-lo == 0 {
		return lo
	}
	lo, hi := lo, hi
	u := float32(r)
	c := f32(0.5) if mode == nil else clamp((mode.?-lo) / (hi-lo), 0, 1)
	if u > c {
		u = 1-u
		c = 1-c
		lo, hi = hi, lo
	}
	return lo + (hi - lo) * math.sqrt(u * c)
}


// Normal/Gaussian Distribution
float64_normal :: proc(mean, stddev: f64, r: ^Rand = nil) -> f64 {
	return norm_float64(r) * stddev + mean
}
// Normal/Gaussian Distribution
float32_normal :: proc(mean, stddev: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_normal(f64(mean), f64(stddev), r))
}


// Log Normal Distribution
float64_log_normal :: proc(mean, stddev: f64, r: ^Rand = nil) -> f64 {
	return math.ln(float64_normal(mean, stddev, r))
}
// Log Normal Distribution
float32_log_normal :: proc(mean, stddev: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_log_normal(f64(mean), f64(stddev), r))
}


// Exponential Distribution
// `lambda` is 1.0/(desired mean). It should be non-zero.
// Return values range from
//     0 to positive infinity if lambda >  0
//     negative infinity to 0 if lambda <= 0
float64_exponential :: proc(lambda: f64, r: ^Rand = nil) -> f64 {
	return - math.ln(1 - float64(r)) / lambda
}
// Exponential Distribution
// `lambda` is 1.0/(desired mean). It should be non-zero.
// Return values range from
//     0 to positive infinity if lambda >  0
//     negative infinity to 0 if lambda <= 0
float32_exponential :: proc(lambda: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_exponential(f64(lambda), r))
}


// Gamma Distribution (NOT THE GAMMA FUNCTION)
//
// Required: alpha > 0 and beta > 0
//
//             math.pow(x, alpha-1) * math.exp(-x / beta)
//   pdf(x) = --------------------------------------------
//              math.gamma(alpha) * math.pow(beta, alpha)
//
// mean is alpha*beta, variance is math.pow(alpha*beta, 2)
float64_gamma :: proc(alpha, beta: f64, r: ^Rand = nil) -> f64 {
	if alpha <= 0 || beta <= 0 {
		panic(#procedure + ": alpha and beta must be > 0.0")
	}

	LOG4 :: 1.3862943611198906188344642429163531361510002687205105082413600189
	SG_MAGIC_CONST :: 2.5040773967762740733732583523868748412194809812852436493487

	switch {
	case alpha > 1:
		// R.C.H. Cheng, "The generation of Gamma variables with non-integral shape parameters", Applied Statistics, (1977), 26, No. 1, p71-74

		ainv := math.sqrt(2 * alpha - 1)
		bbb := alpha - LOG4
		ccc := alpha + ainv
		for {
			u1 := float64(r)
			if !(1e-7 < u1 && u1 < 0.9999999) {
				continue
			}
			u2 := 1 - float64(r)
			v := math.ln(u1 / (1 - u1)) / ainv
			x := alpha * math.exp(v)
			z := u1 * u1 * u2
			t := bbb + ccc*v - x
			if t + SG_MAGIC_CONST - 4.5 * z >= 0 || t >= math.ln(z) {
				return x * beta
			}
		}
	case alpha == 1:
		// float64_exponential(1/beta)
		return -math.ln(1 - float64(r)) * beta
	case:
		// ALGORITHM GS of Statistical Computing - Kennedy & Gentle
		x: f64
		for {
			u := float64(r)
			b := (math.e + alpha) / math.e
			p := b * u
			if p <= 1 {
				x = math.pow(p, 1/alpha)
			} else {
				x = -math.ln((b - p) / alpha)
			}
			u1 := float64(r)
			if p > 1 {
				if u1 <= math.pow(x, alpha-1) {
					break
				}
			} else if u1 <= math.exp(-x) {
				break
			}
		}
		return x * beta
	}
}
// Gamma Distribution (NOT THE GAMMA FUNCTION)
//
// Required: alpha > 0 and beta > 0
//
//             math.pow(x, alpha-1) * math.exp(-x / beta)
//   pdf(x) = --------------------------------------------
//              math.gamma(alpha) * math.pow(beta, alpha)
//
// mean is alpha*beta, variance is math.pow(alpha*beta, 2)
float32_gamma :: proc(alpha, beta: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_gamma(f64(alpha), f64(beta), r))
}


// Beta Distribution
//
// Required: alpha > 0 and beta > 0
//
// Return values range between 0 and 1
float64_beta :: proc(alpha, beta: f64, r: ^Rand = nil) -> f64 {
	if alpha <= 0 || beta <= 0 {
		panic(#procedure + ": alpha and beta must be > 0.0")
	}
	// Knuth Vol 2 Ed 3 pg 134 "the beta distribution"
	y := float64_gamma(alpha, 1.0, r)
	if y != 0 {
		return y / (y + float64_gamma(beta, 1.0, r))
	}
	return 0
}
// Beta Distribution
//
// Required: alpha > 0 and beta > 0
//
// Return values range between 0 and 1
float32_beta :: proc(alpha, beta: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_beta(f64(alpha), f64(beta), r))
}


// Pareto distribution, `alpha` is the shape parameter.
// https://wikipedia.org/wiki/Pareto_distribution
float64_pareto :: proc(alpha: f64, r: ^Rand = nil) -> f64 {
	return math.pow(1 - float64(r), -1.0 / alpha)
}
// Pareto distribution, `alpha` is the shape parameter.
// https://wikipedia.org/wiki/Pareto_distribution
float32_pareto :: proc(alpha, beta: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_pareto(f64(alpha), r))
}


// Weibull distribution, `alpha` is the scale parameter, `beta` is the shape parameter.
float64_weibull :: proc(alpha, beta: f64, r: ^Rand = nil) -> f64 {
	u := 1 - float64(r)
	return alpha * math.pow(-math.ln(u), 1.0/beta)
}
// Weibull distribution, `alpha` is the scale parameter, `beta` is the shape parameter.
float32_weibull :: proc(alpha, beta: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_weibull(f64(alpha), f64(beta), r))
}


// Circular Data (von Mises) Distribution
// `mean_angle` is the in mean angle between 0 and 2pi radians
// `kappa` is the concentration parameter which must be >= 0
// When `kappa` is zero, the Distribution is a uniform Distribution over the range 0 to 2pi
float64_von_mises :: proc(mean_angle, kappa: f64, r: ^Rand = nil) -> f64 {
	// Fisher, N.I., "Statistical Analysis of Circular Data", Cambridge University Press, 1993.

	mu := mean_angle
	if kappa <= 1e-6 {
		return math.TAU * float64(r)
	}

	s := 0.5 / kappa
	t := s + math.sqrt(1 + s*s)
	z: f64
	for {
		u1 := float64(r)
		z = math.cos(math.TAU * 0.5 * u1)

		d := z / (t + z)
		u2 := float64(r)
		if u2 < 1 - d*d || u2 <= (1-d)*math.exp(d) {
			break
		}
	}

	q := 1.0 / t
	f := (q + z) / (1 + q*z)
	u3 := float64(r)
	if u3 > 0.5 {
		return math.mod(mu + math.acos(f), math.TAU)
	} else {
		return math.mod(mu - math.acos(f), math.TAU)
	}
}
// Circular Data (von Mises) Distribution
// `mean_angle` is the in mean angle between 0 and 2pi radians
// `kappa` is the concentration parameter which must be >= 0
// When `kappa` is zero, the Distribution is a uniform Distribution over the range 0 to 2pi
float32_von_mises :: proc(mean_angle, kappa: f32, r: ^Rand = nil) -> f32 {
	return f32(float64_von_mises(f64(mean_angle), f64(kappa), r))
}



read :: proc(p: []byte, r: ^Rand = nil) -> (n: int) {
	pos := i8(0)
	val := i64(0)
	for n = 0; n < len(p); n += 1 {
		if pos == 0 {
			val = int63(r)
			pos = 7
		}
		p[n] = byte(val)
		val >>= 8
		pos -= 1
	}
	return
}

// perm returns a slice of n ints in a pseudo-random permutation of integers in the range [0, n)
perm :: proc(n: int, r: ^Rand = nil, allocator := context.allocator) -> []int {
	m := make([]int, n, allocator)
	for i := 0; i < n; i += 1 {
		j := int_max(i+1, r)
		m[i] = m[j]
		m[j] = i
	}
	return m
}


shuffle :: proc(array: $T/[]$E, r: ^Rand = nil) {
	n := i64(len(array))
	if n < 2 {
		return
	}

	for i := i64(0); i < n; i += 1 {
		j := int63_max(n, r)
		array[i], array[j] = array[j], array[i]
	}
}
