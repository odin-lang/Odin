package runtime

/*

package runtime has numerous entities (declarations) which are required by the compiler to function.


## Basic types and calls (and anything they rely on)

Source_Code_Location
Context
Allocator
Logger

__init_context
_cleanup_runtime


## cstring calls

cstring_to_string
cstring_len



## Required when RTTI is enabled (the vast majority of targets)

Type_Info

type_table
__type_info_of


## Hashing

default_hasher
default_hasher_cstring
default_hasher_string


## Pseudo-CRT required procedured due to LLVM but useful in general
memset
memcpy
memove


## Procedures required by the LLVM backend if u128/i128 is used
umodti3
udivti3
modti3
divti3
fixdfti
fixunsdfti
fixunsdfdi
floattidf
floattidf_unsigned
truncsfhf2
truncdfhf2
gnu_h2f_ieee
gnu_f2h_ieee
extendhfsf2

## Procedures required by the LLVM backend if f16 is used
__ashlti3 // wasm specific
__multi3  // wasm specific


## Required an entry point is defined (i.e. 'main')

args__


## When -no-crt is defined (and not a wasm target) (mostly due to LLVM)
_tls_index
_fltused


## Bounds checking procedures (when not disabled with -no-bounds-check)

bounds_check_error
matrix_bounds_check_error
slice_expr_error_hi
slice_expr_error_lo_hi
multi_pointer_slice_expr_error


## Type assertion check

type_assertion_check
type_assertion_check2 // takes in typeid


## Arithmetic

quo_complex32
quo_complex64
quo_complex128

mul_quaternion64
mul_quaternion128
mul_quaternion256

quo_quaternion64
quo_quaternion128
quo_quaternion256

abs_complex32
abs_complex64
abs_complex128

abs_quaternion64
abs_quaternion128
abs_quaternion256


## Comparison

memory_equal
memory_compare
memory_compare_zero

cstring_eq
cstring_ne
cstring_lt
cstring_gt
cstring_le
cstring_gt

string_eq
string_ne
string_lt
string_gt
string_le
string_gt

complex32_eq
complex32_ne
complex64_eq
complex64_ne
complex128_eq
complex128_ne

quaternion64_eq
quaternion64_ne
quaternion128_eq
quaternion128_ne
quaternion256_eq
quaternion256_ne


## Map specific calls

map_seed_from_map_data
__dynamic_map_check_grow // static map calls
map_insert_hash_dynamic  // static map calls
__dynamic_map_get // dynamic map calls
__dynamic_map_set // dynamic map calls


## Dynamic literals ([dynamic]T and map[K]V) (can be disabled with -no-dynamic-literals)

__dynamic_array_reserve
__dynamic_array_append

__dynamic_map_reserve


## Objective-C specific

objc_lookUpClass
sel_registerName
objc_allocateClassPair


## for-in `string` type

string_decode_rune
string_decode_last_rune // #reverse for

*/