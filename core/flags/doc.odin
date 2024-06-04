/*
package flags implements a command-line argument parser.

It works by using Odin's run-time type information to determine where and how
to store data on a struct provided by the user. Type conversion is handled
automatically and errors are reported with useful messages.


Command-Line Syntax:

Arguments are treated differently on how they're formatted. The format is
similar to the Odin binary's way of handling compiler flags.

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

Users of the `encoding/json` package may be familiar with using tags to
annotate struct metadata. The same technique is used here to annotate where
arguments should go and which are required.

Under the `args` tag:

 - `name=S`, alias a struct field to `S`
 - `pos=N`, place positional argument `N` into this field
 - `hidden`, hide this field from the usage documentation
 - `required`, cause verification to fail if this argument is not set

There is also the `usage` tag, which is a plain string to be printed alongside
the flag in the usage output.


Supported Field Datatypes:

- all `bool`s
- all `int`s
- all `float`s
- `string`, `cstring`
- `rune`
- `dynamic` arrays with element types of the above
- `map[string]`s with value types of the above


Validation:

The parser will ensure `required` arguments are set. This is on by default.


Strict:

The parser will return on the first error and stop parsing. This is on by
default. Otherwise, all arguments that can be parsed, will be, and only the
last error is returned.


Help:

By default, `-h` and `-help` are reserved flags which raise their own error
type when set, allowing the program to handle the request differently from
other errors.


Example:

```odin
	Options :: struct {
		file: string `args:"pos=0,required" usage:"input file"`,
		out: string `args:"pos=1" usage:"output file"`,
		retry_count: uint `args:"name=retries" usage:"times to retry process"`,
		debug: bool `args:"hidden" usage:"print debug info"`,
		collection: map[string]string `usage:"path aliases"`,
	}

	opt: Options
	flags.parse(&opt, {
		"main.odin",
		"-retries:3",
		"-collection:core=./core",
		"-debug",
	}, validate_args = true, strict = true)
```
*/
package flags
