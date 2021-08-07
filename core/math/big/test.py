from ctypes import *
from random import *
import math
import os
import platform
import time
from enum import Enum

#
# Normally, we report the number of passes and fails.
# With EXIT_ON_FAIL set, we exit at the first fail.
#
EXIT_ON_FAIL = True
EXIT_ON_FAIL = False

#
# We skip randomized tests altogether if NO_RANDOM_TESTS is set.
#
NO_RANDOM_TESTS = True
#NO_RANDOM_TESTS = False

#
# If TIMED_TESTS == False and FAST_TESTS == True, we cut down the number of iterations.
# See below.
#
FAST_TESTS = True

#
# For timed tests we budget a second per `n` bits and iterate until we hit that time.
# Otherwise, we specify the number of iterations per bit depth in BITS_AND_ITERATIONS.
#
TIMED_TESTS = False
TIMED_BITS_PER_SECOND = 20_000

#
# How many iterations of each random test do we want to run?
#
BITS_AND_ITERATIONS = [
	(   120, 10_000),
	( 1_200,  1_000),
	( 4_096,    100),
	(12_000,     10),
]

if FAST_TESTS:
	for k in range(len(BITS_AND_ITERATIONS)):
		b, i = BITS_AND_ITERATIONS[k]
		BITS_AND_ITERATIONS[k] = (b, i // 10 if i >= 100 else 5)

if NO_RANDOM_TESTS:
	BITS_AND_ITERATIONS = []

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

# try:
l = cdll.LoadLibrary(LIB_PATH)
# except:
# 	print("Couldn't find or load " + LIB_PATH + ".")
# 	exit(1)

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
initialize_constants()

error_string = load(l.test_error_string, [c_byte], c_char_p)

add  = load(l.test_add, [c_char_p, c_char_p], Res)
sub  = load(l.test_sub, [c_char_p, c_char_p], Res)
mul  = load(l.test_mul, [c_char_p, c_char_p], Res)
div  = load(l.test_div, [c_char_p, c_char_p], Res)

# Powers and such
int_log    = load(l.test_log,  [c_char_p, c_longlong], Res)
int_pow    = load(l.test_pow,  [c_char_p, c_longlong], Res)
int_sqrt   = load(l.test_sqrt, [c_char_p], Res)
int_root_n = load(l.test_root_n, [c_char_p, c_longlong], Res)

# Logical operations

int_shl_digit  = load(l.test_shl_digit, [c_char_p, c_longlong], Res)
int_shr_digit  = load(l.test_shr_digit, [c_char_p, c_longlong], Res)
int_shl        = load(l.test_shl, [c_char_p, c_longlong], Res)
int_shr        = load(l.test_shr, [c_char_p, c_longlong], Res)
int_shr_signed = load(l.test_shr_signed, [c_char_p, c_longlong], Res)

int_factorial  = load(l.test_factorial, [c_uint64], Res)
int_gcd        = load(l.test_gcd, [c_char_p, c_char_p], Res)
int_lcm        = load(l.test_lcm, [c_char_p, c_char_p], Res)

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

def test_div(a = 0, b = 0, expected_error = Error.Okay):
	args = [arg_to_odin(a), arg_to_odin(b)]
	res  = div(*args)
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
			expected_result = int(math.isqrt(number))
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

def test_shl_digit(a = 0, digits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), digits]
	res   = int_shl_digit(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = a << (digits * 60)
	return test("test_shl_digit", res, [a, digits], expected_error, expected_result)

def test_shr_digit(a = 0, digits = 0, expected_error = Error.Okay):
	args  = [arg_to_odin(a), digits]
	res   = int_shr_digit(*args)
	expected_result = None
	if expected_error == Error.Okay:
		if a < 0:
			# Don't pass negative numbers. We have a shr_signed.
			return False
		else:
			expected_result = a >> (digits * 60)
		
	return test("test_shr_digit", res, [a, digits], expected_error, expected_result)

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

def test_factorial(n = 0, expected_error = Error.Okay):
	args  = [n]
	res   = int_factorial(*args)
	expected_result = None
	if expected_error == Error.Okay:
		expected_result = math.factorial(n)
		
	return test("test_factorial", res, [n], expected_error, expected_result)

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
		expected_result = math.lcm(a, b)
		
	return test("test_lcm", res, [a, b], expected_error, expected_result)

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
		[ 0xd3b4e926aaba3040e1c12b5ea553b5, 0x1a821e41257ed9281bee5bc7789ea7],
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
	],
	test_sqrt: [
		[  -1, Error.Invalid_Argument, ],
		[  42, Error.Okay, ],
		[  12345678901234567890, Error.Okay, ],
		[  1298074214633706907132624082305024, Error.Okay, ],
		[  686885735734829009541949746871140768343076607029752932751182108475420900392874228486622313727012705619148037570309621219533087263900443932890792804879473795673302686046941536636874184361869252299636701671980034458333859202703255467709267777184095435235980845369829397344182319113372092844648570818726316581751114346501124871729572474923695509057166373026411194094493240101036672016770945150422252961487398124677567028263059046193391737576836378376192651849283925197438927999526058932679219572030021792914065825542626400207956134072247020690107136531852625253942429167557531123651471221455967386267137846791963149859804549891438562641323068751514370656287452006867713758971418043865298618635213551059471668293725548570452377976322899027050925842868079489675596835389444833567439058609775325447891875359487104691935576723532407937236505941186660707032433807075470656782452889754501872408562496805517394619388777930253411467941214807849472083814447498068636264021405175653742244368865090604940094889189800007448083930490871954101880815781177612910234741529950538835837693870921008635195545246771593130784786737543736434086434015200264933536294884482218945403958647118802574342840790536176272341586020230110889699633073513016344826709214, Error.Okay, ],
	],
	test_root_n: [
		[  1298074214633706907132624082305024, 2, Error.Okay, ],	
	],
	test_shl_digit: [
		[ 3192,			1 ],
		[ 1298074214633706907132624082305024, 2 ],
		[ 1024,			3 ],
	],
	test_shr_digit: [
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
		[ 100_000 ],
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
}

total_passes   = 0
total_failures = 0

#
# test_shr_signed also tests shr, so we're not going to test shr randomly.
#
RANDOM_TESTS = [
	test_add, test_sub, test_mul, test_div,
	test_log, test_pow, test_sqrt, test_root_n,
	test_shl_digit, test_shr_digit, test_shl, test_shr_signed,
	test_gcd, test_lcm,
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
	print("---- math/big tests ----")
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
		print("---- math/big with two random {bits:,} bit numbers ----".format(bits=BITS))
		print()

		for test_proc in RANDOM_TESTS:
			if BITS >  1_200 and test_proc in SKIP_LARGE: continue
			if BITS >  4_096 and test_proc in SKIP_LARGEST: continue

			count_pass = 0
			count_fail = 0
			TIMINGS    = {}

			UNTIL_ITERS = ITERATIONS
			if test_proc == test_root_n and BITS == 1_200:
				UNTIL_ITERS /= 10

			UNTIL_TIME  = TOTAL_TIME + BITS / TIMED_BITS_PER_SECOND
			# We run each test for a second per 20k bits

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
					b = randint(1, 10);
				elif test_proc == test_shl_digit:
					b = randint(0, 10);
				elif test_proc == test_shr_digit:
					a = abs(a)
					b = randint(0, 10);
				elif test_proc == test_shl:
					b = randint(0, min(BITS, 120));
				elif test_proc == test_shr_signed:
					b = randint(0, min(BITS, 120));
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