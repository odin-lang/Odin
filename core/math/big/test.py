from  math import *
from ctypes import *
from random import *
import os
import time

#
# Where is the DLL? If missing, build using: `odin build . -build-mode:dll`
#
LIB_PATH = os.getcwd() + os.sep + "big.dll"

#
# How many iterations of each random test do we want to run?
#
RANDOM_ITERATIONS = 10_000

#
# Result values will be passed in a struct { res: cstring, err: Error }
#
class Res(Structure):
	_fields_ = [("res", c_char_p), ("err", c_byte)]

#
# Error enum values
#
E_None                   = 0
E_Out_Of_Memory          = 1
E_Invalid_Pointer        = 2
E_Invalid_Argument       = 3
E_Unknown_Error          = 4
E_Max_Iterations_Reached = 5
E_Buffer_Overflow        = 6
E_Integer_Overflow       = 7
E_Division_by_Zero       = 8
E_Math_Domain_Error      = 9
E_Unimplemented          = 127

#
# Set up exported procedures
#

try:
	l = cdll.LoadLibrary(LIB_PATH)
except:
	print("Couldn't find or load " + LIB_PATH + ".")
	exit(1)

#
# res = a + b, err
#
try:
	l.test_add_two.argtypes = [c_char_p, c_char_p, c_longlong]
	l.test_add_two.restype  = Res
except:
	print("Couldn't find exported function 'test_add_two'")
	exit(2)

add_two = l.test_add_two

#
# res = a - b, err
#
try:
	l.test_sub_two.argtypes = [c_char_p, c_char_p, c_longlong]
	l.test_sub_two.restype  = Res
except:
	print("Couldn't find exported function 'test_sub_two'")
	exit(2)

sub_two = l.test_sub_two

#
# res = a * b, err
#
try:
	l.test_mul_two.argtypes = [c_char_p, c_char_p, c_longlong]
	l.test_mul_two.restype  = Res
except:
	print("Couldn't find exported function 'test_add_two'")
	exit(2)

mul_two = l.test_mul_two

#
# res = a / b, err
#
try:
	l.test_div_two.argtypes = [c_char_p, c_char_p, c_longlong]
	l.test_div_two.restype  = Res
except:
	print("Couldn't find exported function 'test_div_two'")
	exit(2)

div_two = l.test_div_two



try:
	l.test_error_string.argtypes = [c_byte]
	l.test_error_string.restype  = c_char_p
except:
	print("Couldn't find exported function 'test_error_string'")
	exit(2)

def test(test_name: "", res: Res, param=[], expected_error = E_None, expected_result = ""):
	passed = True
	r = None

	if res.err != expected_error:
		error_type = l.test_error_string(res.err).decode('utf-8')
		error_loc  = res.res.decode('utf-8')

		error_string = "{}: '{}' error in '{}'".format(test_name, error_type, error_loc)
		if len(param):
			error_string += " with params {}".format(param)

		print(error_string, flush=True)
		passed = False
	elif res.err == E_None:
		try:
			r = res.res.decode('utf-8')
		except:
			pass

		r = eval(res.res)
		if r != expected_result:
			error_string = "{}: Result was '{}', expected '{}'".format(test_name, r, expected_result)
			if len(param):
				error_string += " with params {}".format(param)

			print(error_string, flush=True)
			passed = False

	return passed

def test_add_two(a = 0, b = 0, radix = 10, expected_error = E_None, expected_result = None):
	sa   = str(a)
	sb   = str(b)
	sa_c = sa.encode('utf-8')
	sb_c = sb.encode('utf-8')
	res  = add_two(sa_c, sb_c, radix)
	if expected_result == None:
		expected_result = a + b
	return test("test_add_two", res, [sa, sb, radix], expected_error, expected_result)

def test_sub_two(a = 0, b = 0, radix = 10, expected_error = E_None, expected_result = None):
	sa   = str(a)
	sb   = str(b)
	sa_c = sa.encode('utf-8')
	sb_c = sb.encode('utf-8')
	res  = sub_two(sa_c, sb_c, radix)
	if expected_result == None:
		expected_result = a - b
	return test("test_sub_two", res, [sa_c, sb_c, radix], expected_error, expected_result)

def test_mul_two(a = 0, b = 0, radix = 10, expected_error = E_None, expected_result = None):
	sa   = str(a)
	sb   = str(b)
	sa_c = sa.encode('utf-8')
	sb_c = sb.encode('utf-8')
	res  = mul_two(sa_c, sb_c, radix)
	if expected_result == None:
		expected_result = a * b
	return test("test_mul_two", res, [sa_c, sb_c, radix], expected_error, expected_result)

def test_div_two(a = 0, b = 0, radix = 10, expected_error = E_None, expected_result = None):
	sa   = str(a)
	sb   = str(b)
	sa_c = sa.encode('utf-8')
	sb_c = sb.encode('utf-8')
	try:
		res  = div_two(sa_c, sb_c, radix)
	except:
		print("Exception with arguments:", a, b, radix)
		return False
	if expected_result == None:
		expected_result = a // b if b != 0 else None
	return test("test_div_two", res, [sa_c, sb_c, radix], expected_error, expected_result)

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
		[ 1234,   5432,   110, E_Invalid_Argument, ],
	],
	test_sub_two: [
		[ 1234,   5432,    10, ],
	],
	test_mul_two: [
		[ 1234,   5432,    10, ],
		[ 1099243943008198766717263669950239669, 137638828577110581150675834234248871, 10, ]
	],
	test_div_two: [
		[ 54321, 12345,    10, ],
		[ 55431,     0,    10, E_Division_by_Zero, ],
	],
}

TIMINGS = {}

if __name__ == '__main__':
	print()
	print("---- core:math/big tests ----")
	print()

	for test_proc in TESTS:
		count_pass = 0
		count_fail = 0
		for t in TESTS[test_proc]:
			start = time.perf_counter()
			res   = test_proc(*t)
			diff  = time.perf_counter() - start
			if test_proc not in TIMINGS:
				TIMINGS[test_proc] = diff
			else:
				TIMINGS[test_proc] += diff

			if res:
				count_pass += 1
			else:
				count_fail += 1

		print("{name}: {count_pass:,} passes, {count_fail:,} failures.".format(name=test_proc.__name__, count_pass=count_pass, count_fail=count_fail))

	print()		
	print("---- core:math/big random tests ----")
	print()

	for test_proc in [test_add_two, test_sub_two, test_mul_two, test_div_two]:
		count_pass = 0
		count_fail = 0

		for i in range(RANDOM_ITERATIONS):
			a = randint(0, 1 << 120)
			b = randint(0, 1 << 120)
			res = None

			# We've already tested division by zero above.
			if b == 0 and test_proc == test_div_two:
				b = b + 1

			start = time.perf_counter()
			res   = test_proc(a, b)
			diff  = time.perf_counter() - start
			if test_proc not in TIMINGS:
				TIMINGS[test_proc] = diff
			else:
				TIMINGS[test_proc] += diff

			if res:
				count_pass += 1
			else:
				count_fail += 1

		print("{name}: {count_pass:,} passes, {count_fail:,} failures.".format(name=test_proc.__name__, count_pass=count_pass, count_fail=count_fail))

	print()
	total = 0
	for k in TIMINGS:
		print("{name}: {total:.3f} ms in {calls:,} calls".format(name=k.__name__, total=TIMINGS[k] * 1_000, calls=RANDOM_ITERATIONS + len(TESTS[k])))
		total += TIMINGS[k]
	print("\ntotal: {0:.3f} ms".format(total * 1_000))