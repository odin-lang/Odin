package rand

import "core:math"

float64_uniform :: float64_range
float32_uniform :: float32_range

// Triangular Distribution
// See: http://wikipedia.org/wiki/Triangular_distribution
@(require_results)
float64_triangular :: proc(lo, hi: f64, mode: Maybe(f64), gen := context.random_generator) -> f64 {
	if hi-lo == 0 {
		return lo
	}
	lo, hi := lo, hi
	u := float64(gen)
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
@(require_results)
float32_triangular :: proc(lo, hi: f32, mode: Maybe(f32), gen := context.random_generator) -> f32 {
	if hi-lo == 0 {
		return lo
	}
	lo, hi := lo, hi
	u := float32(gen)
	c := f32(0.5) if mode == nil else clamp((mode.?-lo) / (hi-lo), 0, 1)
	if u > c {
		u = 1-u
		c = 1-c
		lo, hi = hi, lo
	}
	return lo + (hi - lo) * math.sqrt(u * c)
}


// Normal/Gaussian Distribution
@(require_results)
float64_normal :: proc(mean, stddev: f64, gen := context.random_generator) -> f64 {
	return norm_float64(gen) * stddev + mean
}
// Normal/Gaussian Distribution
@(require_results)
float32_normal :: proc(mean, stddev: f32, gen := context.random_generator) -> f32 {
	return f32(float64_normal(f64(mean), f64(stddev), gen))
}


// Log Normal Distribution
@(require_results)
float64_log_normal :: proc(mean, stddev: f64, gen := context.random_generator) -> f64 {
	return math.exp(float64_normal(mean, stddev, gen))
}
// Log Normal Distribution
@(require_results)
float32_log_normal :: proc(mean, stddev: f32, gen := context.random_generator) -> f32 {
	return f32(float64_log_normal(f64(mean), f64(stddev), gen))
}


// Exponential Distribution
// `lambda` is 1.0/(desired mean). It should be non-zero.
// Return values range from
//     0 to positive infinity if lambda >  0
//     negative infinity to 0 if lambda <= 0
@(require_results)
float64_exponential :: proc(lambda: f64, gen := context.random_generator) -> f64 {
	return - math.ln(1 - float64(gen)) / lambda
}
// Exponential Distribution
// `lambda` is 1.0/(desired mean). It should be non-zero.
// Return values range from
//     0 to positive infinity if lambda >  0
//     negative infinity to 0 if lambda <= 0
@(require_results)
float32_exponential :: proc(lambda: f32, gen := context.random_generator) -> f32 {
	return f32(float64_exponential(f64(lambda), gen))
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
@(require_results)
float64_gamma :: proc(alpha, beta: f64, gen := context.random_generator) -> f64 {
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
			u1 := float64(gen)
			if !(1e-7 < u1 && u1 < 0.9999999) {
				continue
			}
			u2 := 1 - float64(gen)
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
		return -math.ln(1 - float64(gen)) * beta
	case:
		// ALGORITHM GS of Statistical Computing - Kennedy & Gentle
		x: f64
		for {
			u := float64(gen)
			b := (math.e + alpha) / math.e
			p := b * u
			if p <= 1 {
				x = math.pow(p, 1/alpha)
			} else {
				x = -math.ln((b - p) / alpha)
			}
			u1 := float64(gen)
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
@(require_results)
float32_gamma :: proc(alpha, beta: f32, gen := context.random_generator) -> f32 {
	return f32(float64_gamma(f64(alpha), f64(beta), gen))
}


// Beta Distribution
//
// Required: alpha > 0 and beta > 0
//
// Return values range between 0 and 1
@(require_results)
float64_beta :: proc(alpha, beta: f64, gen := context.random_generator) -> f64 {
	if alpha <= 0 || beta <= 0 {
		panic(#procedure + ": alpha and beta must be > 0.0")
	}
	// Knuth Vol 2 Ed 3 pg 134 "the beta distribution"
	y := float64_gamma(alpha, 1.0, gen)
	if y != 0 {
		return y / (y + float64_gamma(beta, 1.0, gen))
	}
	return 0
}
// Beta Distribution
//
// Required: alpha > 0 and beta > 0
//
// Return values range between 0 and 1
@(require_results)
float32_beta :: proc(alpha, beta: f32, gen := context.random_generator) -> f32 {
	return f32(float64_beta(f64(alpha), f64(beta), gen))
}


// Pareto distribution, `alpha` is the shape parameter.
// https://wikipedia.org/wiki/Pareto_distribution
@(require_results)
float64_pareto :: proc(alpha: f64, gen := context.random_generator) -> f64 {
	return math.pow(1 - float64(gen), -1.0 / alpha)
}
// Pareto distribution, `alpha` is the shape parameter.
// https://wikipedia.org/wiki/Pareto_distribution
@(require_results)
float32_pareto :: proc(alpha, beta: f32, gen := context.random_generator) -> f32 {
	return f32(float64_pareto(f64(alpha), gen))
}


// Weibull distribution, `alpha` is the scale parameter, `beta` is the shape parameter.
@(require_results)
float64_weibull :: proc(alpha, beta: f64, gen := context.random_generator) -> f64 {
	u := 1 - float64(gen)
	return alpha * math.pow(-math.ln(u), 1.0/beta)
}
// Weibull distribution, `alpha` is the scale parameter, `beta` is the shape parameter.
@(require_results)
float32_weibull :: proc(alpha, beta: f32, gen := context.random_generator) -> f32 {
	return f32(float64_weibull(f64(alpha), f64(beta), gen))
}


// Circular Data (von Mises) Distribution
// `mean_angle` is the in mean angle between 0 and 2pi radians
// `kappa` is the concentration parameter which must be >= 0
// When `kappa` is zero, the Distribution is a uniform Distribution over the range 0 to 2pi
@(require_results)
float64_von_mises :: proc(mean_angle, kappa: f64, gen := context.random_generator) -> f64 {
	// Fisher, N.I., "Statistical Analysis of Circular Data", Cambridge University Press, 1993.

	mu := mean_angle
	if kappa <= 1e-6 {
		return math.TAU * float64(gen)
	}

	s := 0.5 / kappa
	t := s + math.sqrt(1 + s*s)
	z: f64
	for {
		u1 := float64(gen)
		z = math.cos(math.TAU * 0.5 * u1)

		d := z / (t + z)
		u2 := float64(gen)
		if u2 < 1 - d*d || u2 <= (1-d)*math.exp(d) {
			break
		}
	}

	q := 1.0 / t
	f := (q + z) / (1 + q*z)
	u3 := float64(gen)
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
@(require_results)
float32_von_mises :: proc(mean_angle, kappa: f32, gen := context.random_generator) -> f32 {
	return f32(float64_von_mises(f64(mean_angle), f64(kappa), gen))
}


// Cauchy-Lorentz Distribution
// `x_0` is the location, `gamma` is the scale where `gamma` > 0
@(require_results)
float64_cauchy_lorentz :: proc(x_0, gamma: f64, gen := context.random_generator) -> f64 {
	assert(gamma > 0)

	// Calculated from the inverse CDF

	return math.tan(math.PI * (float64(gen) - 0.5))*gamma + x_0
}
// Cauchy-Lorentz Distribution
// `x_0` is the location, `gamma` is the scale where `gamma` > 0
@(require_results)
float32_cauchy_lorentz :: proc(x_0, gamma: f32, gen := context.random_generator) -> f32 {
	return f32(float64_cauchy_lorentz(f64(x_0), f64(gamma), gen))
}


// Log Cauchy-Lorentz Distribution
// `x_0` is the location, `gamma` is the scale where `gamma` > 0
@(require_results)
float64_log_cauchy_lorentz :: proc(x_0, gamma: f64, gen := context.random_generator) -> f64 {
	assert(gamma > 0)
	return math.exp(math.tan(math.PI * (float64(gen) - 0.5))*gamma + x_0)
}
// Log Cauchy-Lorentz Distribution
// `x_0` is the location, `gamma` is the scale where `gamma` > 0
@(require_results)
float32_log_cauchy_lorentz :: proc(x_0, gamma: f32, gen := context.random_generator) -> f32 {
	return f32(float64_log_cauchy_lorentz(f64(x_0), f64(gamma), gen))
}


// Laplace Distribution
// `b` is the scale where `b` > 0
@(require_results)
float64_laplace :: proc(mean, b: f64, gen := context.random_generator) -> f64 {
	assert(b > 0)
	p := float64(gen)-0.5
	return -math.sign(p)*math.ln(1 - 2*abs(p))*b + mean
}
// Laplace Distribution
// `b` is the scale where `b` > 0
@(require_results)
float32_laplace :: proc(mean, b: f32, gen := context.random_generator) -> f32 {
	return f32(float64_laplace(f64(mean), f64(b), gen))
}


// Gompertz Distribution
// `eta` is the shape, `b` is the scale
// Both `eta` and `b` must be > 0
@(require_results)
float64_gompertz :: proc(eta, b: f64, gen := context.random_generator) -> f64 {
	if eta <= 0 || b <= 0 {
		panic(#procedure + ": eta and b must be > 0.0")
	}

	p := float64(gen)
	return math.ln(1 - math.ln(1 - p)/eta)/b
}
// Gompertz Distribution
// `eta` is the shape, `b` is the scale
// Both `eta` and `b` must be > 0
@(require_results)
float32_gompertz :: proc(eta, b: f32, gen := context.random_generator) -> f32 {
	return f32(float64_gompertz(f64(eta), f64(b), gen))
}
