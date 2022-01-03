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
print("initialize_constants: ", initialize_constants())

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
		expected_result = a << (digits * 60)
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
			expected_result = a >> (digits * 60)
		
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
			173004933678092711595681968608438676197664938049685629580473369038276067962252149849992137878499957004027167192528224484422792651325494750576045326575192523336303001671022352945361111415009621435887687154421568093235309739789712262198437509247413339305329497725569854838050177916573285176333823036357809376376943910260917175826874681608696011310688249945838730766954221195270491215735657686196197276859390555442097852858099538655435952022373382168804035693259946090364200459398925822409006620020581154544932834287498500493698903815194968031524898191572004112487639615367525474654486686702814920335097674444543522512652079806417137634398429663483880342291830129825498498266559990237937370546883578196978980740085725633735638339396194856748820486678256166151654274189472152526337659649593450641533067118593429068213979694143941138460490166499537827371056997450571675288614527333833389183236670004876202325474156930725159975823723377378142909191805151879968682441708428808365144816539538003938101536036377397167312131249840525093160096636827188896948609087411177646634330696412864701655550914720295992852549509128531377840035494550154760612260817404942645828390665460501727276278939486253063145637867588599661852098846639168829579853325380976531641088281099169083706523900752046676600412743168902225391991113540794792663807700542665104853501317581055952425547235489720209822160202334365130769309259459536091633357471279331156609674023250517423592679667076262586704279365513023852198502520449455143108696482539320574251585287452328848503405547872536288968807039383427804216453780376385105591433123917812238083510876697607703414344156760229124307798668772500003950977613426925594836567946200550628674963535569296767800013740376929401629707406015975995831733383818310296157724735308039189938092543701923236188365802146800862672634099863375801869300779142093358816982181010104945819832550001771695168169680801289329726192927681542189728996443394227068811958343521648576614426009056076544129487725821255054033710251876249912907488823432296322937857856798881671582230101070940307539378998977067552777185413291207231526060090979247403347566537048882205501357270333142136625025385796130133023886483084445829260500591432537561824973303162353693462453685234361651566105368117395526963873711694723894824954862981982799884695945074972536980498627192774958204598029928991777698867789510409474596245251249168095604577282355540403000316293774044384586746974690440802522389578280788685523953798913242300637211960086820597313360484476956979114560801644403294619102020057653424339419391280109172272224151977752690650512476390021198293707261871516181856514568530692731519932281887686061219794123626078224317259804516115673425942206693200289351256141931098182585127299985894998333743689030236534466648141672024806131184517810473589270567586415987303198985381658678703339003467339930252704896900057159705650047179948561960768296116399660545868090051814230264090024434793745087039625876868640787717705881261004354982249593051334210130168537726795070902391312311818481048046928036356256488465383197020166743258560361561949049422469397299805302737523011870980192630003407905301896175873043733232525225135087120385628858101472951411956002814870218091511713339807936382910393052968504459236721625536719034418226279583189139676134537948655300361907729082737983492411849235299127845197021586098516135974048921897904877184863073456177234041396228296195180483962519204352654110085913576966438935353965363038761678654332293642984322611477630386486151169508850675463807141318342507515741203334487811043679524863379331947870659078789402911489037387730864761248047513521404946496397896066890282729825706306870717649535554139697652969879144346177010713479829293966682425086590668663669829819712127520861739979889390966316989099653644358241504753616553617595122893909537026229754073954703051725596695254725770214596794901207220102851130185271879436431942024462144689232905355324614814411208134936162444277177238875590731696443847885921827590973723352594903631757103399576610592766078913138825157122785455397427939970849605195638086338459362096895997148552923064905388148403174518142665517867684801775305240761117259864499401505591524646035468884862442287685783534173584216134602254020470252226715845860298485982659996154502226029631627661417805366381349640830179450372516309926381629324035330926202572812300868943350565866328506252388063168169877192161255780247606176524063956158859526581729432323397025083784057519440746423422297908447407795803778583538166658268787752006794327854401708795863970512954260128505882428557272511660175157745401461506456269140668244395329095519068277285767326916642023949758136739378998482778435910601090690705863173042820325203851750762888654661290926733093369511466990991565889994765598596616981189226241742716670168541187753740468242883574347716326797978072508203439305663660888155247641110202645907846530051669433827791654309050289582791709222786017090016946725717367407404046842131919647349198017831706487325061475819628758434500209483186116806361607715172026386394966520253764583904093528570769944236436156364305603335814857278765438664438262342731252565609306490248486760047559160614817615776624501731032353136843210815012856040104848034550739587476521487143917356552305150335043981788222235277078996654082661880293228955275762675382106245639478656468434529208683376459252520443625975029868923130235180687230451510513567788065239837672153784845270614860800457870824353896067043857428179903232229796281205096031206964909619125091706917710921259525810646231789184098152911486418467467125052588578112013379561016311707156873180883310350125807259489482214646867530138601789035429089169566452732346460059489746130976353918437401434853111995893079354785728979722542287963930457948116425636200981713404337570563841972734427878596144295848173387452734040583840835814458252628248126861947119158769599635259777920115279528112423889008255213274318566878535642226885906636687807126929015970094415559086647671233235471865353716680903879881713826461781475629645884350519368611260867854577444879176887053568076613169798214595268853569595240890318102154466760965786272278413839097866010690990596039871050036876065754858890788129638718425677306250721022444685302309631901424401107405891314785542588430460724443042466862273012234254563377534784989375711721584550706027692032,
			27921373056168038161257363712029738425883469078710601930545962210544316372483465257896797850023481327274033810503043334035215874819993724587326836320749466553772269405862923195362824332887851405213533433081208077156850648821375930352989166783200833746615959106127755671557019089964388317139498837845502815699228224576224832082010692514229182534082681124312513588088460719847011662533322825168476247349637810548383203683788060854075780036705184536653420460018898323931191179813417633106229797607551549089026756638561795791707955494700054097641970714383000674899021750893302230644329497266339848911912171769235723440313194551652213901008256355889302387122112229006307559169315600942861958053017566728562253629002443850692334093148048005559610551121569158961794952095315210914353826025959066814535892039604093309786815342207016366272954482114925150885518563022063368206889248765418628524333157795784017392551438673161938072258257150883329120797624519879153149913280879378693068701852318396001627324681045815861522360007508243109952378642933430762868134726919084609821795490362157999016116064231034860639681441806435957537781045208562955713722103156767070718592688233144071201419766753972173367317507959950852320315507306016060444592155708893619839649184725346685260069511235840139246081015702346048774483210928885566032379712442026511097124621617457735476863128849586131720300576998529551409490562338285216488100148921640151321534350115714453812413337804225371235554224356096298621201743011245230555215764853803543016714701416612120135738613518840557707629149064958859492225609997288249516884401079342273741541186798177437118085288099547388493592900012094967231746552401413599245524633300588813714064766002830979707229930540022588341901036417799649742533569314603600481627728046014460223994310150793171127674615782367612880131607895396414724397621811552220542148980904127280622955717313779398680717189852828686708843557572244315079273457323723041632800998667368727218921046369617181011435686023454689440463983820722252718343013045726108154912390300992917678826287705538156556621758381877110997187922902095265140917070240889656250342587076337793732433462686483290111539332867700431044178095521248081021368966759940895472785930040730153629684635995965788085543085208194776007093991688316742552338141659784385260564644783610783915703019597479512896823750877844542548758322212972052239012888385630605427035936855277508691449937276903894116061956462348195722494495672432544657400064829861415069347640839580936967350820269034590696679765474765160468903961916672270696236023987243935299572074869302371087278165987032523363724772714477346208742592577951283227941915447718054110253967647110209756879542998676114595263890839641099619474409784706275886498148665913033288931998613751613519583111929535476102752261935114458933224121324795776056432597367967005026776276762670411084627024982610652943026725110496912230298567784614134993889023729853254893543811138284001285160996437535564318062528241338453532027185407578241810084261507643858275906100222466448888360917092102502563981410513125139429289542814362352032125673290748931506233519795206784901394602073496408432914119355845669971921611206591398026467420563740223489661593842720925269702370179245643633444935353522942663811405494524391973367251708873816973768868670467493235943431916108424956497368257423161191304276994434754577135984784663467013822984203379501201099957586074307014285676723507079014080927933067729733620324679419782039849016981965321079742660611838438556389842201932201637058869179931697403014787176863501380615739484487415468573855359079212387368551692910628723440977929579930078782255702184840705464727654359256672319160541618101408889768244966379114134194579290092691830062053199840454186374987682037197782617554498504972123539223333197139111223340123431349005989161322706046448294549136345275636294040585686238109527559986400330781564511555132675600354845435740430195387843392918716292423250123841352049448829542813895534778791521891241856409599135740777633463825220674104706642419298985035183765602197431989429173915463411013465768550277612276157418128572127814622862912815904038151008662664231788968389993262883675073896148539523284673482644482548483650586168693376441889016946969955978380722594975748782506306008391421791306366225409928561739591390044573904256656957924246937531253036012624225677004090039680930516873227440444945938274357618114661440761649503158071532529359890361758900851579655708804155875515793218083554490058616347116332425676666301140415486423553320048153504238362373557855535779046905557828526263489747753395212155760397974082306317825624337661338876792738708674499286422559685173420182076306148908180037293202372013787170146701071605439119147392804755048236116840492061241352342396494262648613338171065533649263180829503174821400418274800779191254479284048946851570095174570247223581902756503786185677330697753498186730412069147629747609772838632317338351257920938494712870708108038934101858579447001128824612055853807631590752239142182960806895654726819917774980738692457659411911279127194423188770547312066019180523243169061317538583293927239186467763609863895766055561960747766546253694008644745054199737969293100912901784372603816131617671119155727053285875943648840248351161629947740946487434471715418378491879022464648862542696518000435077035228171974321300460080123902690324244967059745295054118693613269773067619624107387063059985176967572604219180317779786496083874303004124515445219452102075067471953429040119355742883891822452982864094025598028112115866711428585736838632820309749474510868162545829275146258077311244956467165215185174229175240810808694596057113599171098718605793050842043814323849939995836210279724499252205942768969083291862735219152587270457233948203020805477393844251381142530356605396377253291045107451365714635714156250079771050546004769806588881695574400621078157503613361567127625244561059281382952366547354082230802366776019129544180040782867889636785460187181683255211572956144897104392064626327350385247491880762073139154625615894769102398511621294884969897760564967615974545842772162201569120603067788742145776137782588656202210677005605640511483705690705376956476307810433238043720219619341572756300400535126782583804935228625157182123927165307735705469066125233392716412346136127486029948714957553659655924443537095499722362708631898523515388985062426376618128327856053637342559468074942610162506146919250102684545838473478543490121885655498752,
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
		[  686885735734829009541949746871140768343076607029752932751182108475420900392874228486622313727012705619148037570309621219533087263900443932890792804879473795673302686046941536636874184361869252299636701671980034458333859202703255467709267777184095435235980845369829397344182319113372092844648570818726316581751114346501124871729572474923695509057166373026411194094493240101036672016770945150422252961487398124677567028263059046193391737576836378376192651849283925197438927999526058932679219572030021792914065825542626400207956134072247020690107136531852625253942429167557531123651471221455967386267137846791963149859804549891438562641323068751514370656287452006867713758971418043865298618635213551059471668293725548570452377976322899027050925842868079489675596835389444833567439058609775325447891875359487104691935576723532407937236505941186660707032433807075470656782452889754501872408562496805517394619388777930253411467941214807849472083814447498068636264021405175653742244368865090604940094889189800007448083930490871954101880815781177612910234741529950538835837693870921008635195545246771593130784786737543736434086434015200264933536294884482218945403958647118802574342840790536176272341586020230110889699633073513016344826709214, Error.Okay, ],
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
		[ 92232459121502451677697058974826760244863271517919321608054113675118660929276431348516553336313179167211015633639725554914519355444316239500734169769447134357534241879421978647995614218985202290368055757891124109355450669008628757662409138767505519391883751112010824030579849970582074544353971308266211776494228299586414907715854328360867232691292422194412634523666770452490676515117702116926803826546868467146319938818238521874072436856528051486567230096290549225463582766830777324099589751817442141036031904145041055454639783559905920619197290800070679733841430619962318433709503256637256772215111521321630777950145713049902839937043785039344243357384899099910837463164007565230287809026956254332260375327814271845678201, ]
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