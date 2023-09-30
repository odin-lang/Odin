#
#	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
#	Made available under Odin's BSD-3 license.
#
#	A BigInt implementation in Odin.
#	For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
#	The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.
#

from ctypes import *
from random import *
import math
import os
import platform
import time
import gc
from enum import Enum
import argparse

parser = argparse.ArgumentParser(
	description     = "Odin core:math/big test suite",
	epilog          = "By default we run regression and random tests with preset parameters.",
    formatter_class = argparse.ArgumentDefaultsHelpFormatter,
)

#
# Normally, we report the number of passes and fails. With this option set, we exit at first fail.
#
parser.add_argument(
	"-exit-on-fail",
	help    = "Exit when a test fails",
	action  = "store_true",
)

#
# We skip randomized tests altogether if this is set.
#
no_random = parser.add_mutually_exclusive_group()

no_random.add_argument(
	"-no-random",
	help    = "No random tests",
	action  = "store_true",
)

#
# Normally we run a given number of cycles on each test.
# Timed tests budget 1 second per 20_000 bits instead.
#
# For timed tests we budget a second per `n` bits and iterate until we hit that time.
#
timed_or_fast = no_random.add_mutually_exclusive_group()

timed_or_fast.add_argument(
	"-timed",
	type    = bool,
	default = False,
	help    = "Timed tests instead of a preset number of iterations.",
)
parser.add_argument(
	"-timed-bits",
	type    = int,
	metavar = "BITS",
	default = 20_000,
	help    = "Timed tests. Every `BITS` worth of input is given a second of running time.",
)

#
# For normal tests (non-timed), `-fast-tests` cuts down on the number of iterations.
#
timed_or_fast.add_argument(
	"-fast-tests",
	help    = "Cut down on the number of iterations of each test",
	action  = "store_true",
)

args = parser.parse_args()

EXIT_ON_FAIL = args.exit_on_fail

#
# How many iterations of each random test do we want to run?
#
BITS_AND_ITERATIONS = [
	(   120, 10_000),
	( 1_200,  1_000),
	( 4_096,    100),
	(12_000,     10),
]

if args.fast_tests:
	for k in range(len(BITS_AND_ITERATIONS)):
		b, i = BITS_AND_ITERATIONS[k]
		BITS_AND_ITERATIONS[k] = (b, i // 10 if i >= 100 else 5)

if args.no_random:
	BITS_AND_ITERATIONS = []

#
# Where is the DLL? If missing, build using: `odin build . -build-mode:shared`
#
if platform.system() == "Windows":
	LIB_PATH = os.getcwd() + os.sep + "math_big_test_library.dll"
elif platform.system() == "Linux":
	LIB_PATH = os.getcwd() + os.sep + "math_big_test_library.so"
elif platform.system() == "Darwin":
	LIB_PATH = os.getcwd() + os.sep + "math_big_test_library.dylib"
else:
	print("Platform is unsupported.")
	exit(1)


TOTAL_TIME  = 0
UNTIL_TIME  = 0
UNTIL_ITERS = 0

def we_iterate():
	if args.timed:
		return TOTAL_TIME < UNTIL_TIME
	else:
		global UNTIL_ITERS
		UNTIL_ITERS -= 1
		return UNTIL_ITERS != -1

#
# Error enum values
#
class Error(Enum):
	Okay                    = 0
	Out_Of_Memory           = 1
	Invalid_Pointer         = 2
	Invalid_Argument        = 3
	Unknown_Error           = 4
	Assignment_To_Immutable = 10
	Max_Iterations_Reached  = 11
	Buffer_Overflow         = 12
	Integer_Overflow        = 13
	Integer_Underflow       = 14
	Division_by_Zero        = 30
	Math_Domain_Error       = 31
	Cannot_Open_File        = 50
	Cannot_Read_File        = 51
	Cannot_Write_File       = 52
	Unimplemented           = 127

#
# Disable garbage collection
#
gc.disable()

#
# Set up exported procedures
#
try:
	l = cdll.LoadLibrary(LIB_PATH)
except:
 	print("Couldn't find or load " + LIB_PATH + ".")
 	exit(1)

def load(export_name, args, res):
	export_name.argtypes = args
	export_name.restype  = res
	return export_name



#
# Result values will be passed in a struct { res: cstring, err: Error }
#
class Res(Structure):
	_fields_ = [("res", c_char_p), ("err", c_uint64)]

initialize_constants = load(l.test_initialize_constants, [], c_uint64)

NAILS    = initialize_constants()
LEG_BITS = 64 - NAILS

print("LEG BITS: ", LEG_BITS)

error_string = load(l.test_error_string, [c_byte], c_char_p)

add        =     load(l.test_add,        [c_char_p, c_char_p  ], Res)
sub        =     load(l.test_sub,        [c_char_p, c_char_p  ], Res)
mul        =     load(l.test_mul,        [c_char_p, c_char_p  ], Res)
sqr        =     load(l.test_sqr,        [c_char_p            ], Res)
div        =     load(l.test_div,        [c_char_p, c_char_p  ], Res)

# Powers and such
int_log    =     load(l.test_log,        [c_char_p, c_longlong], Res)
int_pow    =     load(l.test_pow,        [c_char_p, c_longlong], Res)
int_sqrt   =     load(l.test_sqrt,       [c_char_p            ], Res)
int_root_n =     load(l.test_root_n,     [c_char_p, c_longlong], Res)

# Logical operations
int_shl_leg    = load(l.test_shl_leg,    [c_char_p, c_longlong], Res)
int_shr_leg    = load(l.test_shr_leg,    [c_char_p, c_longlong], Res)
int_shl        = load(l.test_shl,        [c_char_p, c_longlong], Res)
int_shr        = load(l.test_shr,        [c_char_p, c_longlong], Res)
int_shr_signed = load(l.test_shr_signed, [c_char_p, c_longlong], Res)

int_factorial  = load(l.test_factorial,  [c_uint64            ], Res)
int_gcd        = load(l.test_gcd,        [c_char_p, c_char_p  ], Res)
int_lcm        = load(l.test_lcm,        [c_char_p, c_char_p  ], Res)

is_square      = load(l.test_is_square,  [c_char_p            ], Res)

def test(test_name: "", res: Res, param=[], expected_error = Error.Okay, expected_result = "", radix=16):
	passed = True
	r = None
	err = Error(res.err)

	if err != expected_error:
		error_loc  = res.res.decode('utf-8')
		error = "{}: {} in '{}'".format(test_name, err, error_loc)

		if len(param):
			error += " with params {}".format(param)

		print(error, flush=True)
		passed = False
	elif err == Error.Okay:
		r = None
		try:
			r = res.res.decode('utf-8')
			r = int(res.res, radix)
		except:
			pass

		if r != expected_result:
			error = "{}: Result was '{}', expected '{}'".format(test_name, r, expected_result)
			if len(param):
				error += " with params {}".format(param)

			print(error, flush=True)
			passed = False

	if EXIT_ON_FAIL and not passed: exit(res.err)

	return passed

def arg_to_odin(a):
	if a >= 0:
		s = hex(a)[2:]
	else:
		s = '-' + hex(a)[3:]
	return s.encode('utf-8')


def big_integer_sqrt(src):
	# The Python version on Github's CI doesn't offer math.isqrt.
	# We implement our own
	count = src.bit_length()
	a, b = count >> 1, count & 1

	x = 1 << (a + b)

	while True:
		# y = (x + n // x) // 2
		t1 = src // x
		t2 = t1  + x
		y = t2 >> 1

		if y >= x:
			return x

		x, y = y, x

def big_integer_lcm(a, b):
	# Computes least common multiple as `|a*b|/gcd(a,b)`
	# Divide the smallest by the GCD.

	if a == 0 or b == 0:
		return 0

	if abs(a) < abs(b):
		# Store quotient in `t2` such that `t2 * b` is the LCM.
		lcm = a // math.gcd(a, b)
		return abs(b * lcm)
	else:
		# Store quotient in `t2` such that `t2 * a` is the LCM.
		lcm = b // math.gcd(a, b)
		return abs(a * lcm)

def test_add(a = 0, b = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a), arg_to_odin(b)]
	res  = add(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a + b
	return test("test_add", res, [a, b], expected_error, expected_result)

def test_sub(a = 0, b = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a), arg_to_odin(b)]
	res  = sub(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a - b
	return test("test_sub", res, [a, b], expected_error, expected_result)

def test_mul(a = 0, b = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a), arg_to_odin(b)]
	try:
		res  = mul(*args)
	except OSError as e:
		print("{} while trying to multiply {} x {}.".format(e, a, b))
		if EXIT_ON_FAIL: exit(3)
		return False

	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a * b
	return test("test_mul", res, [a, b], expected_error, expected_result)

def test_sqr(a = 0, b = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a)]
	try:
		res  = sqr(*args)
	except OSError as e:
		print("{} while trying to square {}.".format(e, a))
		if EXIT_ON_FAIL: exit(3)
		return False

	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a * a
	return test("test_sqr", res, [a], expected_error, expected_result)

def test_div(a = 0, b = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a), arg_to_odin(b)]
	try:
		res  = div(*args)
	except OSError as e:
		print("{} while trying divide to {} / {}.".format(e, a, b))
		if EXIT_ON_FAIL: exit(3)
		return False
	expected_result = None
	if expected_error == Error.Okay:
		#
		# We don't round the division results, so if one component is negative, we're off by one.
		#
		if a < 0 and b > 0:
			expected_result = int(-(abs(a) // b))
		elif b < 0 and a > 0:
			expected_result = int(-(a // abs((b))))
		else:
			expected_result = a // b if b != 0 else None
	return test("test_div", res, [a, b], expected_error, expected_result)


def test_log(a = 0, base = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a), base]
	res  = int_log(*args)

	expected_result = None
	if expected_error == Error.Okay:
		expected_result = int(math.log(a, base))
	return test("test_log", res, [a, base], expected_error, expected_result)

def test_pow(base = 0, power = 0, expected_error = Error.Okay):
	args = [arg_to_odin(base), power]
	res  = int_pow(*args)

	expected_result = None
	if expected_error == Error.Okay:
		if power < 0:
			expected_result = 0
		else:
			# NOTE(Jeroen): Don't use `math.pow`, it's a floating point approximation.
			#               Use built-in `pow` or `a**b` instead.
			expected_result = pow(base, power)
	return test("test_pow", res, [base, power], expected_error, expected_result)

def test_sqrt(number = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(number)]
	try:
		res = int_sqrt(*args)
	except OSError as e:
		print("{} while trying to sqrt {}.".format(e, number))
		if EXIT_ON_FAIL: exit(3)
		return False

	expected_result = None
	if expected_error == Error.Okay:
		if number < 0:
			expected_result = 0
		else:
			expected_result = big_integer_sqrt(number)
	return test("test_sqrt", res, [number], expected_error, expected_result)

def root_n(number, root):
	u, s = number, number + 1
	while u < s:
		s = u
		t = (root-1) * s + number // pow(s, root - 1)
		u = t // root
	return s

def test_root_n(number = 0, root = 0, expected_error = Error.Okay):
	args = [arg_to_odin(number), root]
	res  = int_root_n(*args)
	expected_result = None
	if expected_error == Error.Okay:
		if number < 0:
			expected_result = 0
		else:
			expected_result = root_n(number, root)

	return test("test_root_n", res, [number, root], expected_error, expected_result)

def test_shl_leg(a = 0, digits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), digits]
	res   = int_shl_leg(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a << (digits * LEG_BITS)
	return test("test_shl_leg", res, [a, digits], expected_error, expected_result)

def test_shr_leg(a = 0, digits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), digits]
	res   = int_shr_leg(*args)
	expected_result = None
	if expected_error == Error.Okay:
		if a < 0:
			# Don't pass negative numbers. We have a shr_signed.
			return False
		else:
			expected_result = a >> (digits * LEG_BITS)
		
	return test("test_shr_leg", res, [a, digits], expected_error, expected_result)

def test_shl(a = 0, bits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), bits]
	res   = int_shl(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a << bits
	return test("test_shl", res, [a, bits], expected_error, expected_result)

def test_shr(a = 0, bits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), bits]
	res   = int_shr(*args)
	expected_result = None
	if expected_error == Error.Okay:
		if a < 0:
			# Don't pass negative numbers. We have a shr_signed.
			return False
		else:
			expected_result = a >> bits
		
	return test("test_shr", res, [a, bits], expected_error, expected_result)

def test_shr_signed(a = 0, bits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), bits]
	res   = int_shr_signed(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a >> bits
		
	return test("test_shr_signed", res, [a, bits], expected_error, expected_result)

def test_factorial(number = 0, expected_error = Error.Okay):
	args  = [number]
	try:
		res = int_factorial(*args)
	except OSError as e:
		print("{} while trying to factorial {}.".format(e, number))
		if EXIT_ON_FAIL: exit(3)
		return False

	expected_result = None
	if expected_error == Error.Okay:
		expected_result = math.factorial(number)
		
	return test("test_factorial", res, [number], expected_error, expected_result)

def test_gcd(a = 0, b = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), arg_to_odin(b)]
	res   = int_gcd(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = math.gcd(a, b)
		
	return test("test_gcd", res, [a, b], expected_error, expected_result)

def test_lcm(a = 0, b = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), arg_to_odin(b)]
	res   = int_lcm(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = big_integer_lcm(a, b)
		
	return test("test_lcm", res, [a, b], expected_error, expected_result)

def test_is_square(a = 0, b = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a)]
	res   = is_square(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = str(big_integer_sqrt(a) ** 2 == a) if a > 0 else "False"
		
	return test("test_is_square", res, [a], expected_error, expected_result)

# TODO(Jeroen): Make sure tests cover edge cases, fast paths, and so on.
#
# The last two arguments in tests are the expected error and expected result.
#
# The expected error defaults to None.
# By default the Odin implementation will be tested against the Python one.
# You can override that by supplying an expected result as the last argument instead.

TESTS = {
	test_add: [
		[ 1234,   5432],
	],
	test_sub: [
		[ 1234,   5432],
	],
	test_mul: [
		[ 1234,   5432],
		[ 0xd3b4e926aaba3040e1c12b5ea553b5, 0x1a821e41257ed9281bee5bc7789ea7 ],
		[ 1 << 21_105, 1 << 21_501 ],
		[
			0x200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
			0x200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
		]
	],
	test_sqr: [
		[ 5432],
		[ 0xd3b4e926aaba3040e1c12b5ea553b5 ],
	],
	test_div: [
		[ 54321,	12345],
		[ 55431,		0, Error.Division_by_Zero],
		[ 12980742146337069150589594264770969721, 4611686018427387904 ],
		[   831956404029821402159719858789932422, 243087903122332132 ],
	],
	test_log: [
		[ 3192,			1, Error.Invalid_Argument],
		[ -1234,		2, Error.Math_Domain_Error],
		[ 0,			2, Error.Math_Domain_Error],
		[ 1024,			2],
	],
	test_pow: [
		[ 0,  -1, Error.Math_Domain_Error ], # Math
		[ 0,   0 ], # 1
		[ 0,   2 ], # 0
		[ 42, -1,], # 0
		[ 42,  1 ], # 1
		[ 42,  0 ], # 42
		[ 42,  2 ], # 42*42
		[ 1023423462055631945665902260039819522, 6],
		[ 2351415513563017480724958108064794964140712340951636081608226461329298597792428177392182921045756382154475969841516481766099091057155043079113409578271460350765774152509347176654430118446048617733844782454267084644777022821998489944144604889308377152515711394170267839394315842510152114743680838721625924309675796181595284284935359605488617487126635442626578631, 4],
	],
	test_sqrt: [
		[  -1, Error.Invalid_Argument, ],
		[  42, Error.Okay, ],
		[  12345678901234567890, Error.Okay, ],
		[  1298074214633706907132624082305024, Error.Okay, ],
		[  0xa85e79177036820e9e63d14514884413c283db3dba2771f66ec888ae94fe253826ed3230efc1de0cbb4a2ba16fede5fe980d232472cca9e8f339714c56a9e64b5cff7538c33773f128898e8cad47234e8a086b4ce5b902231e2da75cc6cb510d892feb9c9c19ee5f5b7967cb7f081fb79099afe2d20203b0693ecc95c656e5515e0903a4ebc84d22fc2a176ba36dd795195535cfdf473e547930fbd6eae51ad11e974198b4733a10115f391c0fefd22654f5acd63c6415d4cbdaad6c1fc1812333d701b64bb230307fb37911561f5287efd67c2eec5a26a694931aec299c67874881bab0c42941cf0f4ef8ca3548e1adcc7f712eb714762184d656385ceacc7b9f75620dfa7ec62b70ee92a5998cee14ad2b9df3f0c861678bc3311c1fe78c5ce4ed30b90c56d18d50261a4f46fdbf6af94737920b50adf1229503edea8b32900000697f366eba632074a66dcd9999a1510ccefa6110bac2207602b16cd4ce42a36fbf276b5b14550faf75194256f175a867169ff30f8e4770d094b617e3df29612359e33d2a3e8f4e12acf243a22b2732e35a5039fea630886e80f49fb310cb34cd1ecb0dc3036761ac8eed5e2e3d6ea88c5b2f552405149fcb100f50368e969c7d1d45db10ea868838dddc3fbc54c9b658761522c31e46661f46205a6c8783d60638db10bc9515ece8509aa181332207c5a2753ee4a8297a65695fbd8184de, Error.Okay, ],
	],
	test_root_n: [
		[  1298074214633706907132624082305024, 2, Error.Okay, ],	
	],
	test_shl_leg: [
		[ 3192,			1 ],
		[ 1298074214633706907132624082305024, 2 ],
		[ 1024,			3 ],
	],
	test_shr_leg: [
		[ 3680125442705055547392, 1 ],
		[ 1725436586697640946858688965569256363112777243042596638790631055949824, 2 ],
		[ 219504133884436710204395031992179571, 2 ],
	],
	test_shl: [
		[ 3192,			1 ],
		[ 1298074214633706907132624082305024, 2 ],
		[ 1024,			3 ],
	],
	test_shr: [
		[ 3680125442705055547392, 1 ],
		[ 1725436586697640946858688965569256363112777243042596638790631055949824, 2 ],
		[ 219504133884436710204395031992179571, 2 ],
	],
	test_shr_signed: [
		[ -611105530635358368578155082258244262, 12 ],
		[ -149195686190273039203651143129455, 12 ],
		[ 611105530635358368578155082258244262, 12 ],
		[ 149195686190273039203651143129455, 12 ],
	],
	test_factorial: [
		[  6_000 ],   # Regular factorial, see cutoff in common.odin.
		[ 12_345 ],   # Binary split factorial
	],
	test_gcd: [
		[  23, 25, ],
		[ 125, 25, ],
		[ 125, 0,  ],
		[   0, 0,  ],
		[   0, 125,],
	],
	test_lcm: [
		[  23,  25,],
		[ 125, 25, ],
		[ 125, 0,  ],
		[   0, 0,  ],
		[   0, 125,],
	],
	test_is_square: [
		[ 12, ],
		[ 0x4fa3f9fe4edb58bfae7bab80b94ffce6e02cdd067c509f75a5918e510d002a8b41949dee96f482678b6e593ee2a984aa68809af5bdc3c0ee839c588b3b619e0f4a5267a7533765f8621dd20994a9a5bdd7faca4aab4f84a72f4f30d623a44cbc974d48e7ab63259d3141da5467e0a2225d90e6388f8d05e0bcdcb67f6d11c4e17d4c168b9fb23bf0932d6082ed82241b01d7d80bb43bf516fc650d86d62e13df218557df8b3f2e4eb295485e3f221c01130791c0b1b4c77fae4ae98e000e42d943a1dff9bfd960fdabe6a729913f99d74b1a7736c213b6c134bbc6914e0b5ae9d1909a32c2084af5a49a99a97a8c3856fdf1e4ff39306ede6234f85f0dca94382a118d97058d0be641c7b0cecead08450042a56dff16808115f78857d8844df61d8e930427d410ee33a63c79, ]
	],
}

if not args.fast_tests:
	TESTS[test_factorial].append(
		# This one on its own takes around 800ms, so we exclude it for FAST_TESTS
		[ 10_000 ],
	)

total_passes   = 0
total_failures = 0

#
# test_shr_signed also tests shr, so we're not going to test shr randomly.
#
RANDOM_TESTS = [
	test_add,     test_sub,     test_mul,       test_sqr,
	test_log,     test_pow,     test_sqrt,      test_root_n,
	test_shl_leg, test_shr_leg, test_shl,       test_shr_signed,
	test_gcd,     test_lcm,     test_is_square, test_div,
]
SKIP_LARGE   = [
	test_pow, test_root_n, # test_gcd,
]
SKIP_LARGEST = []

# Untimed warmup.
for test_proc in TESTS:
	for t in TESTS[test_proc]:
		res   = test_proc(*t)

if __name__ == '__main__':
	print("\n---- math/big tests ----")
	print()

	max_name = 0
	for test_proc in TESTS:
		max_name = max(max_name, len(test_proc.__name__))

	fmt_string = "{name:>{max_name}}: {count_pass:7,} passes and {count_fail:7,} failures in {timing:9.3f} ms."
	fmt_string = fmt_string.replace("{max_name}", str(max_name))

	for test_proc in TESTS:
		count_pass = 0
		count_fail = 0
		TIMINGS    = {}
		for t in TESTS[test_proc]:
			start = time.perf_counter()
			res   = test_proc(*t)
			diff  = time.perf_counter() - start
			TOTAL_TIME += diff

			if test_proc not in TIMINGS:
				TIMINGS[test_proc] = diff
			else:
				TIMINGS[test_proc] += diff

			if res:
				count_pass     += 1
				total_passes   += 1
			else:
				count_fail     += 1
				total_failures += 1

		print(fmt_string.format(name=test_proc.__name__, count_pass=count_pass, count_fail=count_fail, timing=TIMINGS[test_proc] * 1_000))

	for BITS, ITERATIONS in BITS_AND_ITERATIONS:
		print()		
		print("---- math/big with two random {bits:,} bit numbers ----".format(bits=BITS))
		print()

		#
		# We've already tested up to the 10th root.
		#
		TEST_ROOT_N_PARAMS = [2, 3, 4, 5, 6]

		for test_proc in RANDOM_TESTS:
			if BITS >  1_200 and test_proc in SKIP_LARGE: continue
			if BITS >  4_096 and test_proc in SKIP_LARGEST: continue

			count_pass = 0
			count_fail = 0
			TIMINGS    = {}

			UNTIL_ITERS = ITERATIONS
			if test_proc == test_root_n and BITS == 1_200:
				UNTIL_ITERS /= 10

			UNTIL_TIME  = TOTAL_TIME + BITS / args.timed_bits
			# We run each test for a second per 20k bits

			index = 0

			while we_iterate():
				a = randint(-(1 << BITS), 1 << BITS)
				b = randint(-(1 << BITS), 1 << BITS)

				if test_proc == test_div:
					# We've already tested division by zero above.
					bits = int(BITS * 0.6)
					b = randint(-(1 << bits), 1 << bits)
					if b == 0:
						b == 42
				elif test_proc == test_log:
					# We've already tested log's domain errors.
					a = randint(1, 1 << BITS)
					b = randint(2, 1 << 60)
				elif test_proc == test_pow:
					b = randint(1, 10)
				elif test_proc == test_sqrt:
					a = randint(1, 1 << BITS)
					b = Error.Okay
				elif test_proc == test_root_n:
					a = randint(1, 1 << BITS)
					b = TEST_ROOT_N_PARAMS[index]
					index = (index + 1) % len(TEST_ROOT_N_PARAMS)
				elif test_proc == test_shl_leg:
					b = randint(0, 10);
				elif test_proc == test_shr_leg:
					a = abs(a)
					b = randint(0, 10);
				elif test_proc == test_shl:
					b = randint(0, min(BITS, 120))
				elif test_proc == test_shr_signed:
					b = randint(0, min(BITS, 120))
				elif test_proc == test_is_square:
					a = randint(0, 1 << BITS)
				elif test_proc == test_lcm:
					smallest = min(a, b)
					biggest  = max(a, b)

					# Randomly swap biggest and smallest
					if randint(1, 11) % 2 == 0:
						smallest, biggest = biggest, smallest

					a, b = smallest, biggest
				else:
					b = randint(0, 1 << BITS)

				res = None

				start = time.perf_counter()
				res   = test_proc(a, b)
				diff  = time.perf_counter() - start

				TOTAL_TIME += diff

				if test_proc not in TIMINGS:
					TIMINGS[test_proc] = diff
				else:
					TIMINGS[test_proc] += diff

				if res:
					count_pass     += 1; total_passes   += 1
				else:
					count_fail     += 1; total_failures += 1

			print(fmt_string.format(name=test_proc.__name__, count_pass=count_pass, count_fail=count_fail, timing=TIMINGS[test_proc] * 1_000))

	print()		
	print("---- THE END ----")
	print()
	print(fmt_string.format(name="total", count_pass=total_passes, count_fail=total_failures, timing=TOTAL_TIME * 1_000))

	if total_failures:
		exit(1)