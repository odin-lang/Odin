/*
package flags implements a command-line argument parser.

It works by using Odin's run-time type information to determine where and how
to store data on a struct provided by the program. Type conversion is handled
automatically and errors are reported with useful messages.


Command-Line Syntax:

Arguments are treated differently depending on how they're formatted.
The format is similar to the Odin binary's way of handling compiler flags.

```
type                  handling
------------          ------------------------
<positional>          depends on struct layout
-<flag>               set a bool true
-<flag:option>        set flag to option
-<flag=option>        set flag to option, alternative syntax
-<map>:<key>=<value>  set map[key] to value
```


Struct Tags:

Users of the `core:encoding/json` package may be familiar with using tags to
annotate struct metadata. The same technique is used here to annotate where
arguments should go and which are required.

Under the `args` tag, there are the following subtags:

- `name=S`: set `S` as the flag's name.
- `pos=N`: place positional argument `N` into this flag.
- `hidden`: hide this flag from the usage documentation.
- `required`: cause verification to fail if this argument is not set.
- `variadic`: take all remaining arguments when set, UNIX-style only.
- `file`: for `os.Handle` types, file open mode.
- `perms`: for `os.Handle` types, file open permissions.
- `indistinct`: allow the setting of distinct types by their base type.

`required` may be given a range specifier in the following formats:
```
min
<max
min<max
```

`max` is not inclusive in this range, as noted by the less-than `<` sign, so if
you want to require 3 and only 3 arguments in a dynamic array, you would
specify `required=3<4`.


`variadic` may be given a number (`variadic=N`) above 1 to limit how many extra
arguments it consumes.


`file` determines the file open mode for an `os.Handle`.
It accepts a string of flags that can be mixed together:
- r: read
- w: write
- c: create, create the file if it doesn't exist
- a: append, add any new writes to the end of the file
- t: truncate, erase the file on open


`perms` determines the file open permissions for an `os.Handle`.

The permissions are represented by three numbers in octal format. The first
number is the owner, the second is the group, and the third is other. Read is
represented by 4, write by 2, and execute by 1.

These numbers are added together to get combined permissions. For example, 644
represents read/write for the owner, read for the group, and read for other.

Note that this may only have effect on UNIX-like platforms. By default, `perms`
is set to 444 when only reading and 644 when writing.


`indistinct` tells the parser that it's okay to treat distinct types as their
underlying base type. Normally, the parser will hand those types off to the
custom type setter (more about that later) if one is available, if it doesn't
know how to handle the type.


Usage Tag:

There is also the `usage` tag, which is a plain string to be printed alongside
the flag in the usage output. If `usage` contains a newline, it will be
properly aligned when printed.

All surrounding whitespace is trimmed when formatting with multiple lines.


Supported Flag Data Types:

- all booleans
- all integers
- all floats
- all enums
- all complex numbers
- all quaternions
- all bit_sets
- `string` and `cstring`
- `rune`
- `os.Handle`
- `time.Time`
- `datetime.DateTime`
- `net.Host_Or_Endpoint`,
- additional custom types, see Custom Types below
- `dynamic` arrays with element types of the above
- `map[string]`s or `map[cstring]`s with value types of the above


Validation:

The parser will ensure `required` arguments are set, if no errors occurred
during parsing. This is on by default.

Additionally, you may call `register_flag_checker` to set your own argument
validation procedure that will be called after the default checker.


Strict:

The parser will return on the first error and stop parsing. This is on by
default. Otherwise, all arguments that can be parsed, will be, and only the
last error is returned.


Error Messages:

All error message strings are allocated using the context's `temp_allocator`,
so if you need them to persist, make sure to clone the underlying `message`.


Help:

By default, `-h` and `-help` are reserved flags which raise their own error
type when set, allowing the program to handle the request differently from
other errors.


Custom Types:

You may specify your own type setter for program-specific structs and other
named types. Call `register_type_setter` with an appropriate proc before
calling any of the parsing procs.

A compliant `Custom_Type_Setter` must return three values:
- an error message if one occurred,
- a boolean indicating if the proc handles the type, and
- an `Allocator_Error` if any occurred.

If the setter does not handle the type, simply return without setting any of
the values.


UNIX-style:

This package also supports parsing arguments in a limited flavor of UNIX.
Odin and UNIX style are mutually exclusive, and which one to be used is chosen
at parse time.

```
--flag
--flag=argument
--flag argument
--flag argument repeating-argument
```

`-flag` may also be substituted for `--flag`.

Do note that map flags are not currently supported in this parsing style.


Example:

A complete example is given in the `example` subdirectory.
*/
package flags
