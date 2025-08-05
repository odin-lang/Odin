// This is purely for documentation
package builtin

import "base:runtime"

nil   :: nil
false :: 0!=0
true  :: 0==0

// The following constants are added in `checker.cpp`'s `init_universal` procedure.

/*
	An `enum` value indicating the target's CPU architecture.
	Possible values are: `.amd64`, `.i386`, `.arm32`, `.arm64`, `.wasm32`, `.wasm64p32`, and `.riscv64`.
*/
ODIN_ARCH                       :: ODIN_ARCH

/*
	A `string` indicating the target's CPU architecture.
	Possible values are: "amd64", "i386", "arm32", "arm64", "wasm32", "wasm64p32", "riscv64".
*/
ODIN_ARCH_STRING                :: ODIN_ARCH_STRING

/*
	An `enum` value indicating the type of compiled output, chosen using `-build-mode`.
	Possible values are: `.Executable`, `.Dynamic`, `.Static`, `.Object`, `.Assembly`, and `.LLVM_IR`.
*/
ODIN_BUILD_MODE                 :: ODIN_BUILD_MODE

/*
	A `string` containing the name of the folder that contains the entry point,
	e.g. for `%ODIN_ROOT%/examples/demo`, this would contain `demo`.
*/
ODIN_BUILD_PROJECT_NAME         :: ODIN_BUILD_PROJECT_NAME

/*
	An `i64` containing the time at which the executable was compiled, in nanoseconds.
	This is compatible with the `time.Time` type, i.e. `time.Time{_nsec=ODIN_COMPILE_TIMESTAMP}`
*/
ODIN_COMPILE_TIMESTAMP          :: ODIN_COMPILE_TIMESTAMP

/*
	`true` if the `-debug` command line switch is passed, which enables debug info generation.
*/
ODIN_DEBUG                      :: ODIN_DEBUG

/*
	`true` if the `-default-to-nil-allocator` command line switch is passed,
	which sets the initial `context.allocator` to an allocator that does nothing.
*/
ODIN_DEFAULT_TO_NIL_ALLOCATOR   :: ODIN_DEFAULT_TO_NIL_ALLOCATOR

/*
	`true` if the `-default-to-panic-allocator` command line switch is passed,
	which sets the initial `context.allocator` to an allocator that panics if allocated from.
*/
ODIN_DEFAULT_TO_PANIC_ALLOCATOR :: ODIN_DEFAULT_TO_PANIC_ALLOCATOR

/*
	`true` if the `-disable-assert` command line switch is passed,
	which removes all calls to `assert` from the program.
*/
ODIN_DISABLE_ASSERT             :: ODIN_DISABLE_ASSERT

/*
	An `enum` value indicating the endianness of the target.
	Possible values are: `.Little` and `.Big`.
*/
ODIN_ENDIAN                     :: ODIN_ENDIAN

/*
	An `string` indicating the endianness of the target.
	Possible values are: "little" and "big".
*/
ODIN_ENDIAN_STRING              :: ODIN_ENDIAN_STRING

/*
	An `enum` value set using the `-error-pos-style` switch, indicating the source location style used for compile errors and warnings.
	Possible values are: `.Default` (Odin-style) and `.Unix`.
*/
ODIN_ERROR_POS_STYLE            :: ODIN_ERROR_POS_STYLE

/*
	`true` if the `-foreign-error-procedures` command line switch is passed,
	which inhibits generation of runtime error procedures, so that they can be in a separate compilation unit.
*/
ODIN_FOREIGN_ERROR_PROCEDURES   :: ODIN_FOREIGN_ERROR_PROCEDURES

/*
	A `string` describing the microarchitecture used for code generation.
	If not set using the `-microarch` command line switch, the compiler will pick a default.
	Possible values include, but are not limited to: "sandybridge", "x86-64-v2".
*/
ODIN_MICROARCH_STRING           :: ODIN_MICROARCH_STRING

/*
	An `int` value representing the minimum OS version given to the linker, calculated as `major * 10_000 + minor * 100 + revision`.
	If not set using the `-minimum-os-version` command line switch, it defaults to `0`, except on Darwin, where it's `11_00_00`.
*/
ODIN_MINIMUM_OS_VERSION         :: ODIN_MINIMUM_OS_VERSION

/*
	`true` if the `-no-bounds-check` command line switch is passed, which disables bounds checking at runtime.
*/
ODIN_NO_BOUNDS_CHECK            :: ODIN_NO_BOUNDS_CHECK

/*
	`true` if the `-no-crt` command line switch is passed, which inhibits linking with the C Runtime Library, a.k.a. LibC.
*/
ODIN_NO_CRT                     :: ODIN_NO_CRT

/*
	`true` if the `-no-entry-point` command line switch is passed, which makes the declaration of a `main` procedure optional.
*/
ODIN_NO_ENTRY_POINT             :: ODIN_NO_ENTRY_POINT

/*
	`true` if the `-no-rtti` command line switch is passed, which inhibits generation of full Runtime Type Information.
*/
ODIN_NO_RTTI                    :: ODIN_NO_RTTI

/*
	`true` if the `-no-type-assert` command line switch is passed, which disables type assertion checking program wide.
*/
ODIN_NO_TYPE_ASSERT             :: ODIN_NO_TYPE_ASSERT

/*
	An `enum` value indicating the optimization level selected using the `-o` command line switch.
	Possible values are: `.None`, `.Minimal`, `.Size`, `.Speed`, and `.Aggressive`.

	If `ODIN_OPTIMIZATION_MODE` is anything other than `.None` or `.Minimal`, the compiler will also perform a unity build,
	and `ODIN_USE_SEPARATE_MODULES` will be set to `false` as a result.
*/
ODIN_OPTIMIZATION_MODE          :: ODIN_OPTIMIZATION_MODE

/*
	An `enum` value indicating what the target operating system is.
*/
ODIN_OS                         :: ODIN_OS

/*
	A `string` indicating what the target operating system is.
*/
ODIN_OS_STRING                  :: ODIN_OS_STRING

/*
	An `enum` value indicating the platform subtarget, chosen using the `-subtarget` switch.
	Possible values are: `.Default` `.iPhone`, .iPhoneSimulator, and `.Android`.
*/
ODIN_PLATFORM_SUBTARGET         :: ODIN_PLATFORM_SUBTARGET

/*
	A `string` representing the path of the folder containing the Odin compiler,
	relative to which we expect to find the `base` and `core` package collections.
*/
ODIN_ROOT                       :: ODIN_ROOT

/*
	A `bit_set` indicating the sanitizer flags set using the `-sanitize` command line switch.
	Supported flags are `.Address`, `.Memory`, and `.Thread`.
*/
ODIN_SANITIZER_FLAGS            :: ODIN_SANITIZER_FLAGS

/*
	`true` if the code is being compiled via an invocation of `odin test`.
*/
ODIN_TEST                       :: ODIN_TEST

/*
	`true` if built using the experimental Tilde backend.
*/
ODIN_TILDE                      :: ODIN_TILDE

/*
	`true` by default, meaning each each package is built into its own object file, and then linked together.
	`false` if the `-use-single-module` command line switch to force a unity build is provided.

	If `ODIN_OPTIMIZATION_MODE` is anything other than `.None` or `.Minimal`, the compiler will also perform a unity build,
	and this constant will also be set to `false`.
*/
ODIN_USE_SEPARATE_MODULES       :: ODIN_USE_SEPARATE_MODULES

/*
	`true` if Valgrind integration is supported on the target.
*/
ODIN_VALGRIND_SUPPORT           :: ODIN_VALGRIND_SUPPORT

/*
	A `string` which identifies the compiler being used. The official compiler sets this to `"odin"`.
*/
ODIN_VENDOR                     :: ODIN_VENDOR

/*
	A `string` containing the version of the Odin compiler, typically in the format `dev-YYYY-MM`.
*/
ODIN_VERSION                    :: ODIN_VERSION

/*
	A `string` containing the Git hash part of the Odin version.
	Empty if `.git` could not be detected at the time the compiler was built.
*/
ODIN_VERSION_HASH               :: ODIN_VERSION_HASH

/*
	An `enum` set by the `-subsystem` flag, specifying which Windows subsystem the PE file was created for.
	Possible values are:
		`.Unknown` - Default and only value on non-Windows platforms
		`.Console` - Default on Windows
		`.Windows` - Can be used by graphical applications so Windows doesn't open an empty console

	There are some other possible values for e.g. EFI applications, but only Console and Windows are supported.

	See also: https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-image_optional_header64
*/
ODIN_WINDOWS_SUBSYSTEM          :: ODIN_WINDOWS_SUBSYSTEM

/*
	An `string` set by the `-subsystem` flag, specifying which Windows subsystem the PE file was created for.
	Possible values are:
		"UNKNOWN" - Default and only value on non-Windows platforms
		"CONSOLE" - Default on Windows
		"WINDOWS" - Can be used by graphical applications so Windows doesn't open an empty console

	There are some other possible values for e.g. EFI applications, but only Console and Windows are supported.

	See also: https://learn.microsoft.com/en-us/windows/win32/api/winnt/ns-winnt-image_optional_header64
*/
ODIN_WINDOWS_SUBSYSTEM_STRING   :: ODIN_WINDOWS_SUBSYSTEM_STRING

/*
	`true` if LLVM supports the f16 type.
*/
__ODIN_LLVM_F16_SUPPORTED       :: __ODIN_LLVM_F16_SUPPORTED



byte :: u8 // alias

bool          :: bool
b8            :: b8
b16           :: b16
b32           :: b32
b64           :: b64

i8            :: i8
u8            :: u8
i16           :: i16
u16           :: u16
i32           :: i32
u32           :: u32
i64           :: i64
u64           :: u64

i128          :: i128
u128          :: u128

rune          :: rune

f16           :: f16
f32           :: f32
f64           :: f64

complex32     :: complex32
complex64     :: complex64
complex128    :: complex128

quaternion64  :: quaternion64
quaternion128 :: quaternion128
quaternion256 :: quaternion256

int           :: int
uint          :: uint
uintptr       :: uintptr

rawptr        :: rawptr
string        :: string
cstring       :: cstring
any           :: any

typeid        :: typeid

// Endian Specific Types
i16le         :: i16le
u16le         :: u16le
i32le         :: i32le
u32le         :: u32le
i64le         :: i64le
u64le         :: u64le
i128le        :: i128le
u128le        :: u128le

i16be         :: i16be
u16be         :: u16be
i32be         :: i32be
u32be         :: u32be
i64be         :: i64be
u64be         :: u64be
i128be        :: i128be
u128be        :: u128be


f16le         :: f16le
f32le         :: f32le
f64le         :: f64le

f16be         :: f16be
f32be         :: f32be
f64be         :: f64be



// Procedures
len :: proc(array: Array_Type) -> int ---
cap :: proc(array: Array_Type) -> int ---

size_of      :: proc($T: typeid) -> int ---
align_of     :: proc($T: typeid) -> int ---

// e.g. offset_of(t.f), where t is an instance of the type T
offset_of_selector :: proc(selector: $T) -> uintptr ---
// e.g. offset_of(T, f), where T can be the type instead of a variable
offset_of_member   :: proc($T: typeid, member: $M) -> uintptr ---
offset_of :: proc{offset_of_selector, offset_of_member}
// e.g. offset_of(T, "f"), where T can be the type instead of a variable
offset_of_by_string :: proc($T: typeid, member: string) -> uintptr ---

type_of      :: proc(x: expr) -> type ---
type_info_of :: proc($T: typeid) -> ^runtime.Type_Info ---
typeid_of    :: proc($T: typeid) -> typeid ---

swizzle :: proc(x: [N]T, indices: ..int) -> [len(indices)]T ---

complex    :: proc(real, imag: Float) -> Complex_Type ---
quaternion :: proc(imag, jmag, kmag, real: Float) -> Quaternion_Type --- // fields must be named
real       :: proc(value: Complex_Or_Quaternion) -> Float ---
imag       :: proc(value: Complex_Or_Quaternion) -> Float ---
jmag       :: proc(value: Quaternion) -> Float ---
kmag       :: proc(value: Quaternion) -> Float ---
conj       :: proc(value: Complex_Or_Quaternion) -> Complex_Or_Quaternion ---

expand_values   :: proc(value: Struct_Or_Array) -> (A, B, C, ...) ---
compress_values :: proc(values: ...) -> Struct_Or_Array_Like_Type ---

min   :: proc(values: ..T) -> T ---
max   :: proc(values: ..T) -> T ---
abs   :: proc(value: T) -> T ---
clamp :: proc(value, minimum, maximum: T) -> T ---

soa_zip :: proc(slices: ...) -> #soa[]Struct ---
soa_unzip :: proc(value: $S/#soa[]$E) -> (slices: ...) ---

unreachable :: proc() -> ! ---

// Where T is a string, slice, dynamic array, or pointer to an array type
raw_data :: proc(t: $T) -> rawptr