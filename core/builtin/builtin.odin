// This is purely for documentation
package builtin

nil   :: nil;
false :: 0!==0;
true  :: 0==0;

ODIN_OS      :: ODIN_OS;
ODIN_ARCH    :: ODIN_ARCH;
ODIN_ENDIAN  :: ODIN_ENDIAN;
ODIN_VENDOR  :: ODIN_VENDOR;
ODIN_VERSION :: ODIN_VERSION;
ODIN_ROOT    :: ODIN_ROOT;
ODIN_DEBUG   :: ODIN_DEBUG;

byte :: u8; // alias

bool          :: bool;
b8            :: b8;
b16           :: b16;
b32           :: b32;
b64           :: b64;

i8            :: i8;
u8            :: u8;
i16           :: i16;
u16           :: u16;
i32           :: i32;
u32           :: u32;
i64           :: i64;
u64           :: u64;

i128          :: i128;
u128          :: u128;

rune          :: rune;

f16           :: f16;
f32           :: f32;
f64           :: f64;

complex32     :: complex32;
complex64     :: complex64;
complex128    :: complex128;

quaternion128 :: quaternion128;
quaternion256 :: quaternion256;

int           :: int;
uint          :: uint;
uintptr       :: uintptr;

rawptr        :: rawptr;
string        :: string;
cstring       :: cstring;
any           :: any;

typeid        :: typeid;

// Endian Specific Types
i16le         :: i16le;
u16le         :: u16le;
i32le         :: i32le;
u32le         :: u32le;
i64le         :: i64le;
u64le         :: u64le;
i128le        :: i128le;
u128le        :: u128le;

i16be         :: i16be;
u16be         :: u16be;
i32be         :: i32be;
u32be         :: u32be;
i64be         :: i64be;
u64be         :: u64be;
i128be        :: i128be;
u128be        :: u128be;

// Procedures
len :: proc(array: Array_Type) -> int ---
cap :: proc(array: Array_Type) -> int ---

size_of      :: proc($T: typeid) -> int ---
align_of     :: proc($T: typeid) -> int ---
offset_of    :: proc($T: typeid) -> uintptr ---
type_of      :: proc(x: expr) -> type ---
type_info_of :: proc($T: typeid) -> ^runtime.Type_Info ---
typeid_of    :: proc($T: typeid) -> typeid ---

swizzle :: proc(x: [N]T, indices: ..int) -> [len(indices)]T ---

complex    :: proc(real, imag: Float) -> Complex_Type ---
quaternion :: proc(real, imag, jmag, kmag: Float) -> Quaternion_Type ---
real       :: proc(value: Complex_Or_Quaternion) -> Float ---
imag       :: proc(value: Complex_Or_Quaternion) -> Float ---
jmag       :: proc(value: Quaternion) -> Float ---
kmag       :: proc(value: Quaternion) -> Float ---
conj       :: proc(value: Complex_Or_Quaternion) -> Complex_Or_Quaternion ---

expand_to_tuple :: proc(value: Struct_Or_Array) -> (A, B, C, ...) ---

min   :: proc(values: ..T) -> T ---
max   :: proc(values: ..T) -> T ---
abs   :: proc(value: T) -> T ---
clamp :: proc(value, minimum, maximum: T) -> T ---
