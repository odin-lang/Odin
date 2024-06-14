/*
package fmt implements formatted I/O with procedures similar to C's printf and Python's format.
The format 'verbs' are derived from C's but simpler.

Printing

The verbs:

General:
	%v     the value in a default format
	%#v    an expanded format of %v with newlines and indentation
	%w     an Odin-syntax representation of the value
	%T     an Odin-syntax representation of the type of the value
	%%     a literal percent sign; consumes no value
	{{     a literal open brace; consumes no value
	}}     a literal close brace; consumes no value
	{:v}   equivalent to %v (Python-like formatting syntax)

Boolean:
	%t    the word "true" or "false"
Integer:
	%b    base 2
	%c    the character represented by the corresponding Unicode code point
	%r    synonym for %c
	%o    base 8
	%d    base 10
	%i    base 10
	%z    base 12
	%x    base 16, with lower-case letters for a-f
	%X    base 16, with upper-case letters for A-F
	%U    Unicode format: U+1234; same as "U+%04X"
Floating-point, complex numbers, and quaternions:
	%e    scientific notation, e.g. -1.23456e+78
	%E    scientific notation, e.g. -1.23456E+78
	%f    decimal point but no exponent, e.g. 123.456
	%F    synonym for %f
	%g    synonym for %f with default maximum precision
	%G    synonym for %g
	%h    hexadecimal (lower-case) representation with 0h prefix (0h01234abcd)
	%H    hexadecimal (upper-case) representation with 0H prefix (0h01234ABCD)
	%m    number of bytes in the best unit of measurement, e.g. 123.45mib
	%M    number of bytes in the best unit of measurement, e.g. 123.45MiB
String and slice of bytes
	%s    the uninterpreted bytes of the string or slice
	%q    a double-quoted string safely escaped with Odin syntax
	%x    base 16, lower-case, two characters per byte
	%X    base 16, upper-case, two characters per byte
Slice and dynamic array:
	%p    address of the 0th element in base 16 notation (upper-case), with leading 0x
Pointer:
	%p    base 16 notation (upper-case), with leading 0x
	The %b, %d, %o, %z, %x, %X verbs also work with pointers,
	treating it as if it was an integer
Enums:
	%s    prints the name of the enum field
	The %i, %d, %f verbs also work with enums,
	treating it as if it was a number

For compound values, the elements are printed using these rules recursively; laid out like the following:
	struct:            {name0 = field0, name1 = field1, ...}
	array              [elem0, elem1, elem2, ...]
	enumerated array   [key0 = elem0, key1 = elem1, key2 = elem2, ...]
	maps:              map[key0 = value0, key1 = value1, ...]
	bit sets           {key0 = elem0, key1 = elem1, ...}
	pointer to above:  &{}, &[], &map[]

Width is specified by an optional decimal number immediately after the '%'.
If not present, the width is whatever is necessary to represent the value.
Precision is specified after the (optional) width by a period followed by a decimal number.
If no period is present, a default precision is used.
A period with no following number specifies a precision of 0.

Examples:
	%f     default width, default precision
	%8f    width 8, default precision
	%.2f   default width, precision 2
	%8.3f  width 8, precision 3
	%8.f   width 8, precision 0

Width and precision are measured in units of Unicode code points (runes).
n.b. C's printf uses units of bytes.


Other flags:
	+      always print a sign for numeric values
	-      pad with spaces on the right rather the left (left-justify the field)
	#      alternate format:
	               add leading 0b for binary (%#b)
	               add leading 0o for octal (%#o)
	               add leading 0z for dozenal (%#z)
	               add leading 0x or 0X for hexadecimal (%#x or %#X)
	               remove leading 0x for %p (%#p)
	               add a space between bytes and the unit of measurement (%#m or %#M)
	' '    (space) leave a space for elided sign in numbers (% d)
	0      pad with leading zeros rather than spaces


Flags are ignored by verbs that don't expect them.


For each printf-like procedure, there is a print function that takes no
format, and is equivalent to doing %v for every value and inserts a separator
between each value (default is a single space).
Another procedure println which has the same functionality as print but appends a newline.

Explicit argument indices:

In printf-like procedures, the default behaviour is for each formatting verb to format successive
arguments passed in the call. However, the notation [n] immediately before the verb indicates that
the nth zero-index argument is to be formatted instead.
The same notation before an '*' for a width or precision specifier selects the argument index
holding the value.
Python-like syntax with argument indices differs for selecting the argument index: {n:v}

Examples:
	fmt.printfln("%[1]d %[0]d", 13, 37) // C-like syntax
	fmt.printfln("{1:d} {0:d}", 13, 37) // Python-like syntax
prints "37 13", whilst:
	fmt.printfln("%*[2].*[1][0]f", 17.0, 2, 6) // C-like syntax
	fmt.printfln("{0:*[2].*[1]f}", 17.0, 2, 6) // Python-like syntax
is equivalent to:
	fmt.printfln("%6.2f",   17.0) // C-like syntax
	fmt.printfln("{:6.2f}", 17.0) // Python-like syntax
and prints "17.00".

Format errors:

If an invalid argument is given for a verb, such as providing a string to %d, the generated string
will contain a description of the problem. For example:

	Bad enum value:
		%!(BAD ENUM VALUE)
	Too many arguments:
		%!(EXTRA <value>, <value>, ...)
	Too few arguments:
		%!(MISSING ARGUMENT)
	Invalid width or precision
		%!(BAD WIDTH)
		%!(BAD PRECISION)
	Missing verb:
		%!(NO VERB)
	Invalid or invalid use of argument index:
		%!(BAD ARGUMENT NUMBER)
	Missing close brace when using Python-like formatting syntax:
		%!(MISSING CLOSE BRACE)

*/
package fmt
