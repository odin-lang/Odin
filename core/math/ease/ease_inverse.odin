// Inverse easing procedures
// These are the mathematical inverses of the corresponding easing functions,
// allowing you to reverse the transformation:
//    if y = ease_fn(x), then x = ease_fn_inverse(y) + some_imprecision
package ease

@require import "core:math"
import "base:intrinsics"

// Helper for handling negative bases with fractional exponents
// since math.pow(negative, fraction) returns NaN
@(private)
_signed_pow :: proc "contextless" (x, exp: $T) -> T where intrinsics.type_is_float(T) {
	if x >= 0 {
		return math.pow(x, exp)
	} else {
		return -math.pow(-x, exp)
	}
}

@(private) PI_2_INV :: 2 / math.PI

// Inverse of quadratic_in
// x = sqrt(y)
@(require_results)
quadratic_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sqrt(p)
}

// Inverse of quadratic_out
// x = 1 - sqrt(1 - y)
@(require_results)
quadratic_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return 1 - math.sqrt(1 - p)
}

// Inverse of quadratic_in_out
// x = sqrt(y/2)         ; [0, 0.5)
// x = 1 - sqrt((1-y)/2) ; [0.5, 1]
@(require_results)
quadratic_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return math.sqrt(p * 0.5)
	} else {
		return 1 - math.sqrt((1 - p) * 0.5)
	}
}

// Inverse of cubic_in
// x = y^(1/3)
@(require_results)
cubic_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.pow(p, 1.0/3.0)
}

// Inverse of cubic_out
// x = (y - 1)^(1/3) + 1
@(require_results)
cubic_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return _signed_pow(p - 1, 1.0/3.0) + 1
}

// Inverse of cubic_in_out
// x = (y/4)^(1/3)           ; [0, 0.5)
// x = ((y-1)*2)^(1/3)/2 + 1 ; [0.5, 1]
@(require_results)
cubic_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return math.pow(p * 0.25, 1.0/3.0)
	} else {
		return _signed_pow((p - 1) * 2, 1.0/3.0) * 0.5 + 1
	}
}

// Inverse of quartic_in
// x = y^(1/4)
@(require_results)
quartic_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.pow(p, 0.25)
}

// Inverse of quartic_out
// x = 1 - (1 - y)^(1/4)
@(require_results)
quartic_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return 1 - math.pow(1 - p, 0.25)
}

// Inverse of quartic_in_out
// x = (y/8)^(1/4)         ; [0, 0.5)
// x = 1 - ((1-y)/8)^(1/4) ; [0.5, 1]
@(require_results)
quartic_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return math.pow(p * 0.125, 0.25)
	} else {
		return 1 - math.pow((1 - p) * 0.125, 0.25)
	}
}

// Inverse of quintic_in
// x = y^(1/5)
@(require_results)
quintic_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.pow(p, 0.2)
}

// Inverse of quintic_out
// x = (y - 1)^(1/5) + 1
@(require_results)
quintic_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return _signed_pow(p - 1, 0.2) + 1
}

// Inverse of quintic_in_out
// x = (y/16)^(1/5)          ; [0, 0.5)
// x = ((y-1)*2)^(1/5)/2 + 1 ; [0.5, 1]
@(require_results)
quintic_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		return math.pow(0.0625 * p, 0.2)
	} else {
		return _signed_pow((p - 1) * 2, 0.2) * 0.5 + 1
	}
}

// Inverse of sine_in
// x = asin(y - 1) * 2/π + 1
@(require_results)
sine_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.asin(p - 1) * PI_2_INV + 1
}

// Inverse of sine_out
// x = asin(y) * 2/π
@(require_results)
sine_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.asin(p) * PI_2_INV
}

// Inverse of sine_in_out
// x = acos(1 - 2y) / π
@(require_results)
sine_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.acos(1 - 2*p) / math.PI
}

// Inverse of circular_in
// x = sqrt(2y - y²)
@(require_results)
circular_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return math.sqrt(2*p - p*p)
}

// Inverse of circular_out
// x = 1 - sqrt(1 - y²)
@(require_results)
circular_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return 1 - math.sqrt(1 - p*p)
}

// Inverse of circular_in_out
// x = sqrt(1 - (1-2y)²) / 2     ; [0, 0.5)
// x = 1 - sqrt(1 - (2y-1)²) / 2 ; [0.5, 1]
@(require_results)
circular_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p < 0.5 {
		q := 1 - 2*p
		return 0.5 * math.sqrt(1 - q*q)
	} else {
		q := 2*p - 1
		return 1 - 0.5 * math.sqrt(1 - q*q)
	}
}

// Inverse of exponential_in
// x = log₂(y) / 10 + 1
@(require_results)
exponential_in_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p == 0.0 ? 0.0 : 0.1 * math.log2(p) + 1
}

// Inverse of exponential_out
// x = -log₂(1 - y) / 10
@(require_results)
exponential_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	return p == 1.0 ? 1.0 : 0.1 * -math.log2(1 - p)
}

// Inverse of exponential_in_out
// x = (log₂(2y) + 10) / 20     ; [0, 0.5)
// x = (10 - log₂(2(1-y))) / 20 ; [0.5, 1]
@(require_results)
exponential_in_out_inverse :: proc "contextless" (p: $T) -> T where intrinsics.type_is_float(T) {
	if p == 0.0 || p == 1.0 {
		return p
	}

	if p < 0.5 {
		return 0.05 * (math.log2(2*p) + 10)
	} else {
		return 0.05 * (10 - math.log2(2*(1-p)))
	}
}

// Additional enum variant

@(require_results)
ease_inverse :: proc "contextless" (type: Ease, p: $T) -> T where intrinsics.type_is_float(T) {
	switch type {
	case .Linear:             return p

	case .Quadratic_In:       return quadratic_in_inverse(p)
	case .Quadratic_Out:      return quadratic_out_inverse(p)
	case .Quadratic_In_Out:   return quadratic_in_out_inverse(p)

	case .Cubic_In:           return cubic_in_inverse(p)
	case .Cubic_Out:          return cubic_out_inverse(p)
	case .Cubic_In_Out:       return cubic_in_out_inverse(p)

	case .Quartic_In:         return quartic_in_inverse(p)
	case .Quartic_Out:        return quartic_out_inverse(p)
	case .Quartic_In_Out:     return quartic_in_out_inverse(p)

	case .Quintic_In:         return quintic_in_inverse(p)
	case .Quintic_Out:        return quintic_out_inverse(p)
	case .Quintic_In_Out:     return quintic_in_out_inverse(p)

	case .Sine_In:            return sine_in_inverse(p)
	case .Sine_Out:           return sine_out_inverse(p)
	case .Sine_In_Out:        return sine_in_out_inverse(p)

	case .Circular_In:        return circular_in_inverse(p)
	case .Circular_Out:       return circular_out_inverse(p)
	case .Circular_In_Out:    return circular_in_out_inverse(p)

	case .Exponential_In:     return exponential_in_inverse(p)
	case .Exponential_Out:    return exponential_out_inverse(p)
	case .Exponential_In_Out: return exponential_in_out_inverse(p)

	case .Elastic_In, .Elastic_Out, .Elastic_In_Out,
	     .Back_In, .Back_Out, .Back_In_Out,
	     .Bounce_In, .Bounce_Out, .Bounce_In_Out:
		// These do not have simple closed-form inverses
		return 0
	}

	// In case type was invalid
	return 0
}
