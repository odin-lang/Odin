# `core:flags`

`core:flags` is a complete command-line argument parser for the Odin programming
language.

It works by using Odin's run-time type information to determine where and how
to store data on a struct provided by the user. Type conversion is handled
automatically and errors are reported with useful messages.

## Struct Tags

Users of the `encoding/json` package may be familiar with using tags to
annotate struct metadata. The same technique is used here to annotate where
arguments should go and which are required.

Under the `flags` tag:

 - `name=S`, alias a struct field to `S`
 - `pos=N`, place positional argument `N` into this field
 - `hidden`, hide this field from the usage documentation
 - `required`, cause verification to fail if this argument is not set

There is also the `usage` tag, which is a plain string to be printed alongside
the flag in the usage output.

## Syntax

Arguments are treated differently on how they're formatted. The format is
similar to the Odin binary's way of handling compiler flags.

```
type                  handling
------------          ------------------------
<positional>          depends on struct layout
-<flag>               set a bool to true
-<flag:option>        set flag to option
-<flag=option>        set flag to option, alternative syntax
-<map>:<key>=<value>  set map[key] to value
```

## Complete Example

```odin
package main

import "core:fmt"
import "core:mem"
import "core:os"
import "core:path/filepath"

import "core:flags"

main :: proc() {
	Options :: struct {
		file: string `flags:"pos=0,required" usage:"input file"`,
		out: string `flags:"pos=1" usage:"output file"`,
		retry_count: uint `flags:"name=retries" usage:"times to retry process"`,
		debug: bool `flags:"hidden" usage:"print debug info"`,
		collection: map[string]string `usage:"path aliases"`,
	}

	opt: Options
	program: string
	args: []string

	switch len(os.args) {
	case 0:
		flags.print_usage(&opt)
		os.exit(0)
	case:
		program = filepath.base(os.args[0])
		args = os.args[1:]
	}

	err := flags.parse(&opt, args)

	switch subtype in err {
	case mem.Allocator_Error:
		fmt.println("allocation error:", subtype)
		os.exit(1)
	case flags.Parse_Error:
		fmt.println(subtype.message)
		os.exit(1)
	case flags.Validation_Error:
		fmt.println(subtype.message)
		os.exit(1)
	case flags.Help_Request:
		flags.print_usage(&opt, program)
		os.exit(0)
	}

	fmt.printf("%#v\n", opt)
}
```

```
$ ./odin-flags
required argument `file` was not set

$ ./odin-flags -help

Usage:
	odin-flags file [out] [-collection] [-retries]
Flags:
	-file:<string>                   input file
	-out:<string>                    output file
	-collection:<string>=<string>    path aliases
	-retries:<uint>                  times to retry process

$ ./odin-flags -retries:-3
unable to set `retries` of type uint to `-3`

$ ./odin-flags data -retries:3 -collection:core=./core -collection:runtime=./runtime
Options{
	file = "data",
	out = "",
	retry_count = 3,
	debug = false,
	collection = map[
		core = "./core",
		runtime = "./runtime",
	],
}
```
