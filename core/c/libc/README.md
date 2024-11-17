# C support

The following is a mostly-complete projection of the C11 standard library as defined by the C11 specification: N1570, or ISO/IEC 9899:2011. Only the macros, types, and functions as required by the standard are projected. Extensions to C, such as POSIX are not handled by these bindings, this is otherwise portable to any implementation which can support a hosted C runtime.

## Support matrix
| Header            | Status                                             |
|:------------------|:---------------------------------------------------|
| `<assert.h>`      | Not applicable, use Odin's `#assert`               |
| `<complex.h>`     | Mostly projected, see [limitations](#Limitations)  |
| `<ctype.h>`       | Fully projected                                    |
| `<errno.h>`       | Fully projected                                    |
| `<fenv.h>`        | Not projected                                      |
| `<float.h>`       | Not projected                                      |
| `<inttypes.h>`    | Fully projected                                    |
| `<iso646.h>`      | Not applicable, use Odin's operators               |
| `<limits.h>`      | Not projected                                      |
| `<locale.h>`      | Fully projected                                    |
| `<math.h>`        | Mostly projected, see [limitations](#Limitations)  |
| `<setjmp.h>`      | Fully projected                                    |
| `<signal.h>`      | Fully projected                                    |
| `<stdalign.h>`    | Not applicable, use Odin's `#align`                |
| `<stdarg.h>`      | Mostly projected, see [limitations](#Limitations)  |
| `<stdatomic.h>`   | Fully projected                                    |
| `<stdbool.h>`     | Not applicable, use Odin's `b32`                   |
| `<stddef.h>`      | Mostly projected, see [limitations](#Limitations)  |
| `<stdint.h>`      | Fully projected                                    |
| `<stdio.h>`       | Fully projected                                    |
| `<stdlib.h>`      | Fully projected                                    |
| `<stdnoreturn.h>` | Not applicable, use Odin's divergent return `!`    |
| `<string.h>`      | Fully projected                                    |
| `<tgmath.h>`      | Mostly projected, see [limitations](#Limitations)  |
| `<threads.h>`     | Fully projected                                    |
| `<time.h>`        | Fully projected                                    |
| `<uchar.h>`       | Fully projected                                    |
| `<wchar.h>`       | Fully projected                                    |
| `<wctype.h>`      | Fully projected                                    |

## Limitations
Not all C standard library functionality can be fully projected due to language differences. These limitations are listed here.

### `long double`
As Odin lacks a means to interact with `long double` in it's foreign interface, this projection effort does not bind or define anything requiring `long double` which is permitted by the C standard.

### `<complex.h>`
The special values `_Complex_I`, `_Imaginary_I` and the appropriate definition of `I` cannot be realized with the same type in Odin as it would be in C. The literal `1i` is tempting to use for these definitions but the semantics differ from C and would be confusing to use.

### `<math.h>`
The classification functions, e.g: `fpclassify` are required by C to be implemented as macros, meaning no implementation would expose functions in their library we could bind. Instead, we provide native Odin implementations with functionally equivalent semantics and behavior as the C ones. Unfortunately, since classification returns unspecified constant values this may be an ABI break where the value of those constants enter and exit native C code.

### `<stdarg.h>`
While Odin can interact with variable argument C functions through the use of the `#c_vararg` attribute within a foreign block, it's not actually possible to create procedures in Odin with bodies that have the same ABI as that of variable argument C functions, as a result `va_arg` is not projected.

### `<stddef.h>`
`offsetof` is not realizable in Odin, however you can use `offset_of` instead.

### `<tgmath.h>`
C has some strange promotion and type-coercion behavior for `<tgmath.h>` which isn't correctly handled by this projection, specifically involving the use of complex arithmetic and kernels. We do mostly support type-generic math through the use of Odin's explicit procedure overloading, however the semantic behavior of that doesn't match C and so literal expressions of complex type in C may not call the same underlying math kernel functions as they do in Odin through this projection.

## Caveats

In addition to limitations, there are some minor caveats you should be aware when using this projection.

* `errno()` is a function which returns `^int` rather than a macro.
* `MB_CUR_MAX()` is a function which return `size_t` rather than a macro.
* Currently only works on Windows (MSVCRT) and Linux (GLIBC or MUSL)

## License
Every file within this directory is made available under Odin's BSD-2 license
with the following copyright.

```
Copyright 2021 Dale Weiler <weilercdale@gmail.com>.
```
