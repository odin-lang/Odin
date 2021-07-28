from  math import *
from ctypes import *
import os

#
# Where is the DLL? If missing, build using: `odin build . -build-mode:dll`
#
LIB_PATH = os.getcwd() + os.sep + "big.dll"

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

try:
	l.test_add_two.argtypes = [c_char_p, c_char_p, c_longlong]
	l.test_add_two.restype  = Res
except:
	print("Couldn't find exported function 'test_add_two'")
	exit(2)

add_two = l.test_add_two

try:
	l.test_error_string.argtypes = [c_byte]
	l.test_error_string.restype  = c_char_p
except:
	print("Couldn't find exported function 'test_error_string'")
	exit(2)

def test(test_name: "", res: Res, param=[], expected_result = "", expected_error = E_None):
	had_error = False
	r = None

	if res.err != expected_error:
		error_type = l.test_error_string(res.err).decode('utf-8')
		error_loc  = res.res.decode('utf-8')

		error_string = "{}: '{}' error in '{}'".format(test_name, error_type, error_loc)
		if len(param):
			error_string += " with params {}".format(param)

		print(error_string, flush=True)
		had_error = True
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
			had_error = True

	return had_error

def test_add_two(a = 0, b = 0, radix = 10, expected_result = "", expected_error = E_None):
	res = add_two(str(a).encode('utf-8'), str(b).encode('utf-8'), radix)
	return test("test_add_two", res, [str(a), str(b), radix], expected_result, expected_error)


ADD_TESTS = [
	[	1234, 5432, 10,
		6666, E_None, ],
	[ 	1234, 5432, 110,
		6666, E_Invalid_Argument, ],
]

if __name__ == '__main__':
	print("---- core:math/big tests ----")
	print()

	count_pass = 0
	count_fail = 0

	for t in ADD_TESTS:
		res = test_add_two(*t)
		if res:
			count_fail += 1
		else:
			count_pass += 1

	print("ADD_TESTS: {} passes, {} failures.".format(count_pass, count_fail))