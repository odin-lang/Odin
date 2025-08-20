
/*
Declarations which are required by the compiler

## Descriptions of files

There are a lot of files in this package and below is described roughly what
kind of functionality is placed in different files:

| File pattern         | Description
|----------------------|------------------------------------------------------|
| `core.odin`          | Contains the declarations that compiler will require to be present. Contains context-related declarations, `Type_Info` declarations and some other types used to implement the runtime and other packages. |
| `core_builtin*.odin` | Contain `@(builtin)` declarations that can be used without importing the package. Most of them aren't required by the compiler |
| `default_*.odin`     | Contain default implementations for context allocators |
| `entry_*.odin`       | Contain OS-specific entry points |
| `os_specific_*.odin` | Contain OS-specific utility procedures |
| `*internal*.odin`    | Contain implementations for internal procedures that can be called by the compiler |

## Implementing custom runtime

For embedded and kernel development it might be required to re-implement parts
of the `base:runtime` package. This can include changing the default printing
procedures that handle console output when the program panics, custom
entry-points, tailored for a specific platform or execution environment, or
simply switching up implementations of some procedures.

In case this is required, the following is suggested:

1. Define `$ODIN_ROOT` environment variable to point to a directory within your
   project that contains the following directories: `base/`, `core/` and `vendor/`.
2. Inside the `$ODIN_ROOT/base` subdirectory, implement the *necessary
   declarations*.

What constitutes the necessary definitions is described below.

### Context-related

The compiler will require these declarations as they concern the `context`
variable.

* `Maybe`
* `Source_Code_Location`
* `Context`
* `Allocator`
* `Random_Generator`
* `Logger`
* `__init_context`

### Runtime initialization/cleanup

These are not strictly required for compilation, but if global variables or
`@(init)`/`@(fini)` blocks are used, these procedures need to be called inside
the entry point.

* `_startup_runtime`
* `_cleanup_runtime`

### Type assertion check

These procedures are called every time `.(Type)` expressions are used in order
to check the union tag or the underlying type of `any` before returning the
value of the underlying type. These are not required if `-no-type-assert` is
specified.

* `type_assertion_check`
* `type_assertion_check2` (takes in typeid)

### Bounds checking procedures

These procedures are called every time index or slicing expression are used in
order to perform bounds-checking before the actual operation. These are not
required if the `-no-bounds-check` option is specified.

* `bounds_check_error`
* `matrix_bounds_check_error`
* `slice_expr_error_hi`
* `slice_expr_error_lo_hi`
* `multi_pointer_slice_expr_error`

### cstring calls

If `cstring` or `cstring16` types are used, these procedures are required.

* `cstring_to_string`
* `cstring_len`
* `cstring16_to_string16`
* `cstring16_len`

### Comparison

These procedures are required for comparison operators between strings and other
compound types to function properly. If strings, structs nor unions are compared,
only `string_eq` procedure is required.

* `memory_equal`
* `memory_compare`
* `memory_compare_zero`
* `cstring_eq`
* `cstring16_eq`
* `cstring_ne`
* `cstring16_ne`
* `cstring_lt`
* `cstring16_lt`
* `cstring_gt`
* `cstring16_gt`
* `cstring_le`
* `cstring16_le`
* `cstring_ge`
* `cstring16_ge`
* `string_eq`
* `string16_eq`
* `string_ne`
* `string16_ne`
* `string_lt`
* `string16_lt`
* `string_gt`
* `string16_gt`
* `string_le`
* `string16_le`
* `string_ge`
* `string16_ge`
* `complex32_eq`
* `complex32_ne`
* `complex64_eq`
* `complex64_ne`
* `complex128_eq`
* `complex128_ne`
* `quaternion64_eq`
* `quaternion64_ne`
* `quaternion128_eq`
* `quaternion128_ne`
* `quaternion256_eq`
* `quaternion256_ne`

### for-in `string` type

These procedures are required to iterate strings using `for ... in` loop. If this
kind of loop isn't used, these procedures aren't required.

* `string_decode_rune`
* `string_decode_last_rune` (for `#reverse for`)

### Required when RTTI is enabled (the vast majority of targets)

These declarations are required unless the `-no-rtti` compiler option is
specified. Note that in order to be useful, some other procedures need to be
implemented. Those procedures aren't mentioned here as the compiler won't
complain if they're missing.

* `Type_Info`
* `type_table`
* `__type_info_of`

### Hashing

Required if maps are used

* `default_hasher`
* `default_hasher_cstring`
* `default_hasher_string`

### Pseudo-CRT required procedured due to LLVM but useful in general

* `memset`
* `memcpy`
* `memove`

### Procedures required by the LLVM backend if u128/i128 is used

* `umodti3`
* `udivti3`
* `modti3`
* `divti3`
* `fixdfti`
* `fixunsdfti`
* `fixunsdfdi`
* `floattidf`
* `floattidf_unsigned`
* `truncsfhf2`
* `truncdfhf2`
* `gnu_h2f_ieee`
* `gnu_f2h_ieee`
* `extendhfsf2`

### Procedures required by the LLVM backend if f16 is used (WASM only)

* `__ashlti3`
* `__multi3`

### When -no-crt is defined (windows only)

* `_tls_index`
* `_fltused`

### Arithmetic

* `quo_complex32`
* `quo_complex64`
* `quo_complex128`

* `mul_quaternion64`
* `mul_quaternion128`
* `mul_quaternion256`

* `quo_quaternion64`
* `quo_quaternion128`
* `quo_quaternion256`

* `abs_complex32`
* `abs_complex64`
* `abs_complex128`

* `abs_quaternion64`
* `abs_quaternion128`
* `abs_quaternion256`

## Map specific calls

* `map_seed_from_map_data`
* `__dynamic_map_check_grow` (for static map calls)
* `map_insert_hash_dynamic`  (for static map calls)
* `__dynamic_map_get` (for dynamic map calls)
* `__dynamic_map_set` (for dynamic map calls)

## Dynamic literals (`[dynamic]T` and `map[K]V`) (can be disabled with `-no-dynamic-literals`)

* `__dynamic_array_reserve`
* `__dynamic_array_append`
* `__dynamic_map_reserve`

### Objective-C specific

* `objc_lookUpClass`
* `sel_registerName`
* `objc_allocateClassPair`

### Other required declarations

This is required without conditions.

* `Load_Directory_File`

*/
package runtime
