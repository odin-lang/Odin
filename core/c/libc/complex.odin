package libc

// 7.3 Complex arithmetic

when ODIN_OS == .Windows {
	foreign import libc "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import libc "system:System.framework"
} else {
	foreign import libc "system:c"
}

@(default_calling_convention="c")
foreign libc {
	// 7.3.5 Trigonometric functions
	cacos   :: proc(z: complex_double) -> complex_double ---
	cacosf  :: proc(z: complex_float) -> complex_float ---
	casin   :: proc(z: complex_double) -> complex_double ---
	casinf  :: proc(z: complex_float) -> complex_float ---
	catan   :: proc(z: complex_double) -> complex_double ---
	catanf  :: proc(z: complex_float) -> complex_float ---
	ccos    :: proc(z: complex_double) -> complex_double ---
	ccosf   :: proc(z: complex_float) -> complex_float ---
	csin    :: proc(z: complex_double) -> complex_double ---
	csinf   :: proc(z: complex_float) -> complex_float ---
	ctan    :: proc(z: complex_double) -> complex_double ---
	ctanf   :: proc(z: complex_float) -> complex_float ---

	// 7.3.6 Hyperbolic functions
	cacosh  :: proc(z: complex_double) -> complex_double ---
	cacoshf :: proc(z: complex_float) -> complex_float ---
	casinh  :: proc(z: complex_double) -> complex_double ---
	casinhf :: proc(z: complex_float) -> complex_float ---
	catanh  :: proc(z: complex_double) -> complex_double ---
	catanhf :: proc(z: complex_float) -> complex_float ---
	ccosh   :: proc(z: complex_double) -> complex_double ---
	ccoshf  :: proc(z: complex_float) -> complex_float ---
	csinh   :: proc(z: complex_double) -> complex_double ---
	csinhf  :: proc(z: complex_float) -> complex_float ---
	ctanh   :: proc(z: complex_double) -> complex_double ---
	ctanhf  :: proc(z: complex_float) -> complex_float ---

	// 7.3.7 Exponential and logarithmic functions
	cexp    :: proc(z: complex_double) -> complex_double ---
	cexpf   :: proc(z: complex_float) -> complex_float ---
	clog    :: proc(z: complex_double) -> complex_double ---
	clogf   :: proc(z: complex_float) -> complex_float ---

	// 7.3.8 Power and absolute-value functions
	cabs    :: proc(z: complex_double) -> double ---
	cabsf   :: proc(z: complex_float) -> float ---
	cpow    :: proc(x, y: complex_double) -> complex_double ---
	cpowf   :: proc(x, y: complex_float) -> complex_float ---
	csqrt   :: proc(z: complex_double) -> complex_double ---
	csqrtf  :: proc(z: complex_float) -> complex_float ---

	// 7.3.9 Manipulation functions
	carg    :: proc(z: complex_double) -> double ---
	cargf   :: proc(z: complex_float) -> float ---
	cimag   :: proc(z: complex_double) -> double ---
	cimagf  :: proc(z: complex_float) -> float ---
	conj    :: proc(z: complex_double) -> complex_double ---
	conjf   :: proc(z: complex_float) -> complex_float ---
	cproj   :: proc(z: complex_double) -> complex_double ---
	cprojf  :: proc(z: complex_float) -> complex_float ---
	creal   :: proc(z: complex_double) -> double ---
	crealf  :: proc(z: complex_float) -> float ---
}

import builtin "base:builtin"

complex_float  :: distinct builtin.complex64
complex_double :: distinct builtin.complex128

// Cannot implement _Complex_I or _Imaginary_I in Odin, thus
// complex and imaginary cannot be implement either.

CMPLX :: #force_inline proc(x, y: double) -> complex_double {
	return builtin.complex(x, y)
}

CMPLXF :: #force_inline proc(x, y: float) -> complex_float {
	return builtin.complex(x, y)
}
