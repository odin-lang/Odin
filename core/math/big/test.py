from  math import *
from ctypes import *
from random import *
import os
import platform
import time
from enum import Enum

#
# How many iterations of each random test do we want to run?
#
BITS_AND_ITERATIONS = [
	(   120, 10_000),
	( 1_200,  1_000),
	( 4_096,    100),
	(12_000,     10),
]

#
# For timed tests we budget a second per `n` bits and iterate until we hit that time.
# Otherwise, we specify the number of iterations per bit depth in BITS_AND_ITERATIONS.
#
TIMED_TESTS = False
TIMED_BITS_PER_SECOND = 20_000

#
# If TIMED_TESTS == False and FAST_TESTS == True, we cut down the number of iterations.
# See below.
#
FAST_TESTS = True

if FAST_TESTS:
	for k in range(len(BITS_AND_ITERATIONS)):
		b, i = BITS_AND_ITERATIONS[k]
		BITS_AND_ITERATIONS[k] = (b, i // 10 if i >= 100 else 5)

#
# Where is the DLL? If missing, build using: `odin build . -build-mode:shared`
#
if platform.system() == "Windows":
	LIB_PATH = os.getcwd() + os.sep + "big.dll"
elif platform.system() == "Linux":
	LIB_PATH = os.getcwd() + os.sep + "big.so"
elif platform.system() == "Darwin":
	LIB_PATH = os.getcwd() + os.sep + "big.dylib"
else:
	print("Platform is unsupported.")
	exit(1)


TOTAL_TIME  = 0
UNTIL_TIME  = 0
UNTIL_ITERS = 0

def we_iterate():
	if TIMED_TESTS:
		return TOTAL_TIME < UNTIL_TIME
	else:
		global UNTIL_ITERS
		UNTIL_ITERS -= 1
		return UNTIL_ITERS != -1

#
# Error enum values
#
class Error(Enum):
	Okay                   = 0
	Out_Of_Memory          = 1
	Invalid_Pointer        = 2
	Invalid_Argument       = 3
	Unknown_Error          = 4
	Max_Iterations_Reached = 5
	Buffer_Overflow        = 6
	Integer_Overflow       = 7
	Division_by_Zero       = 8
	Math_Domain_Error      = 9
	Unimplemented          = 127

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

error_string = load(l.test_error_string, [c_byte], c_char_p)

add_two = load(l.test_add_two, [c_char_p, c_char_p, c_longlong], Res)
sub_two = load(l.test_sub_two, [c_char_p, c_char_p, c_longlong], Res)
mul_two = load(l.test_mul_two, [c_char_p, c_char_p, c_longlong], Res)
div_two = load(l.test_div_two, [c_char_p, c_char_p, c_longlong], Res)

int_log = load(l.test_log, [c_char_p, c_longlong, c_longlong], Res)


def test(test_name: "", res: Res, param=[], expected_error = Error.Okay, expected_result = ""):
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
			r = int(res.res, 10)
		except:
			pass

		if r != expected_result:
			error = "{}: Result was '{}', expected '{}'".format(test_name, r, expected_result)
			if len(param):
				error += " with params {}".format(param)

			print(error, flush=True)
			passed = False

	if not passed:
		exit()

	return passed


def test_add_two(a = 0, b = 0, radix = 10, expected_error = Error.Okay):
	args = [str(a), str(b), radix]
	sa_c, sb_c = args[0].encode('utf-8'), args[1].encode('utf-8')
	res  = add_two(sa_c, sb_c, radix)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a + b
	return test("test_add_two", res, args, expected_error, expected_result)

def test_sub_two(a = 0, b = 0, radix = 10, expected_error = Error.Okay):
	sa,     sb = str(a), str(b)
	sa_c, sb_c = sa.encode('utf-8'), sb.encode('utf-8')
	res  = sub_two(sa_c, sb_c, radix)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a - b
	return test("test_sub_two", res, [sa_c, sb_c, radix], expected_error, expected_result)

def test_mul_two(a = 0, b = 0, radix = 10, expected_error = Error.Okay):
	sa,     sb = str(a), str(b)
	sa_c, sb_c = sa.encode('utf-8'), sb.encode('utf-8')
	res  = mul_two(sa_c, sb_c, radix)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a * b
	return test("test_mul_two", res, [sa_c, sb_c, radix], expected_error, expected_result)

def test_div_two(a = 0, b = 0, radix = 10, expected_error = Error.Okay):
	sa,     sb = str(a), str(b)
	sa_c, sb_c = sa.encode('utf-8'), sb.encode('utf-8')
	try:
		res  = div_two(sa_c, sb_c, radix)
	except:
		print("Exception with arguments:", a, b, radix)
		return False
	expected_result = None
	if expected_error == Error.Okay:
		#
		# We don't round the division results, so if one component is negative, we're off by one.
		#
		if a < 0 and b > 0:
			expected_result = int(-(abs(a) / b))
		elif b < 0 and a > 0:
			expected_result = int(-(a / abs((b))))
		else:
			expected_result = a // b if b != 0 else None
	return test("test_div_two", res, [sa_c, sb_c, radix], expected_error, expected_result)


def test_log(a = 0, base = 0, radix = 10, expected_error = Error.Okay):
	args  = [str(a), base, radix]
	sa_c  = args[0].encode('utf-8')
	res   = int_log(sa_c, base, radix)

	expected_result = None
	if expected_error == Error.Okay:
		expected_result = int(log(a, base))
	return test("test_log", res, args, expected_error, expected_result)


# TODO(Jeroen): Make sure tests cover edge cases, fast paths, and so on.
#
# The last two arguments in tests are the expected error and expected result.
#
# The expected error defaults to None.
# By default the Odin implementation will be tested against the Python one.
# You can override that by supplying an expected result as the last argument instead.

TESTS = {
	test_add_two: [
		[ 1234,   5432,    10, ],
		[ 1234,   5432,   110, Error.Invalid_Argument],
	],
	test_sub_two: [
		[ 1234,   5432,    10, ],
	],
	test_mul_two: [
		[ 1234,   5432,    10, ],
		[ 0xd3b4e926aaba3040e1c12b5ea553b5, 0x1a821e41257ed9281bee5bc7789ea7, 10, ]
	],
	test_div_two: [
		[ 54321,	12345,		10, ],
		[ 55431,		0,		10,		Error.Division_by_Zero],
	],
	test_log: [
		[ 3192,			1,		10,		Error.Invalid_Argument],
		[ -1234,		2,		10,		Error.Math_Domain_Error],
		[ 0,			2,		10,		Error.Math_Domain_Error],
		[ 1024,			2,		10, ],
	],
}

RANDOM_TESTS = [test_add_two, test_sub_two, test_mul_two, test_div_two, test_log]

total_passes   = 0
total_failures = 0


if __name__ == '__main__':

	test_log(1234, 2, 10)

	print("---- core:math/big tests ----")
	print()

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

		print("{name}: {count_pass:,} passes and {count_fail:,} failures in {timing:.3f} ms.".format(name=test_proc.__name__, count_pass=count_pass, count_fail=count_fail, timing=TIMINGS[test_proc] * 1_000))

	for BITS, ITERATIONS in BITS_AND_ITERATIONS:
		print()		
		print("---- core:math/big with two random {bits:,} bit numbers ----".format(bits=BITS))
		print()

		for test_proc in RANDOM_TESTS:
			count_pass = 0
			count_fail = 0
			TIMINGS    = {}

			UNTIL_ITERS = ITERATIONS
			UNTIL_TIME  = TOTAL_TIME + BITS / TIMED_BITS_PER_SECOND
			# We run each test for a second per 20k bits

			while we_iterate():
				a = randint(-(1 << BITS), 1 << BITS)
				b = randint(-(1 << BITS), 1 << BITS)

				if test_proc == test_div_two:
					# We've already tested division by zero above.
					if b == 0:
						b == 42
				elif test_proc == test_log:
					# We've already tested log's domain errors.
					a = randint(1, 1 << BITS)
					b = randint(2, 1 << 60)
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

			print("{name}: {count_pass:,} passes and {count_fail:,} failures in {timing:.3f} ms.".format(name=test_proc.__name__, count_pass=count_pass, count_fail=count_fail, timing=TIMINGS[test_proc] * 1_000))

	print()		
	print("---- THE END ----")
	print()
	print("total: {count_pass:,} passes and {count_fail:,} failures in {timing:.3f} ms.".format(count_pass=total_passes, count_fail=total_failures, timing=TOTAL_TIME * 1_000))

	if total_failures:
		exit(1)