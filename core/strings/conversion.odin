package strings

import "core:io"
import "core:unicode"
import "core:unicode/utf8"

/*
Converts invalid UTF-8 sequences in the input string `s` to the `replacement` string.

*Allocates Using Provided Allocator*

**Inputs**  
- s: Input string that may contain invalid UTF-8 sequences.
- replacement: String to replace invalid UTF-8 sequences with.
- allocator: (default: context.allocator).

WARNING: Allocation does not occur when len(s) == 0

**Returns**  
A valid UTF-8 string with invalid sequences replaced by `replacement`.
*/
to_valid_utf8 :: proc(s, replacement: string, allocator := context.allocator) -> string {
	if len(s) == 0 {
		return ""
	}

	b: Builder
	builder_init(&b, 0, 0, allocator)

	s := s
	for c, i in s {
		if c != utf8.RUNE_ERROR {
			continue
		}

		_, w := utf8.decode_rune_in_string(s[i:])
		if w == 1 {
			builder_grow(&b, len(s) + len(replacement))
			write_string(&b, s[:i])
			s = s[i:]
			break
		}
	}

	if builder_cap(b) == 0 {
		return clone(s, allocator)
	}

	invalid := false

	for i := 0; i < len(s);  /**/{
		c := s[i]
		if c < utf8.RUNE_SELF {
			i += 1
			invalid = false
			write_byte(&b, c)
			continue
		}

		_, w := utf8.decode_rune_in_string(s[i:])
		if w == 1 {
			i += 1
			if !invalid {
				invalid = true
				write_string(&b, replacement)
			}
			continue
		}
		invalid = false
		write_string(&b, s[i:][:w])
		i += w
	}
	return to_string(b)
}
/*
Converts the input string `s` to all lowercase characters.

*Allocates Using Provided Allocator*

**Inputs**  
- s: Input string to be converted.
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_lower_example :: proc() {
		fmt.println(strings.to_lower("TeST"))
	}

Output:

	test

**Returns**  
A new string with all characters converted to lowercase.
*/
to_lower :: proc(s: string, allocator := context.allocator) -> string {
	b: Builder
	builder_init(&b, 0, len(s), allocator)
	for r in s {
		write_rune(&b, unicode.to_lower(r))
	}
	return to_string(b)
}
/*
Converts the input string `s` to all uppercase characters.

*Allocates Using Provided Allocator*

**Inputs**  
- s: Input string to be converted.
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_upper_example :: proc() {
		fmt.println(strings.to_upper("Test"))
	}

Output:

	TEST

**Returns**  
A new string with all characters converted to uppercase.
*/
to_upper :: proc(s: string, allocator := context.allocator) -> string {
	b: Builder
	builder_init(&b, 0, len(s), allocator)
	for r in s {
		write_rune(&b, unicode.to_upper(r))
	}
	return to_string(b)
}
/*
Checks if the rune `r` is a delimiter (' ', '-', or '_').

**Inputs**  
- r: Rune to check for delimiter status.

**Returns**  
True if `r` is a delimiter, false otherwise.
*/
is_delimiter :: proc(r: rune) -> bool {
	return r == '-' || r == '_' || is_space(r)
}
/*
Checks if the rune `r` is a non-alphanumeric or space character.

**Inputs**  
- r: Rune to check for separator status.

**Returns**  
True if `r` is a non-alpha or `unicode.is_space` rune.
*/
is_separator :: proc(r: rune) -> bool {
	if r <= 0x7f {
		switch r {
		case '0' ..= '9':
			return false
		case 'a' ..= 'z':
			return false
		case 'A' ..= 'Z':
			return false
		case '_':
			return false
		}
		return true
	}

	// TODO(bill): unicode categories
	// if unicode.is_letter(r) || unicode.is_digit(r) {
	// 	return false;
	// }

	return unicode.is_space(r)
}
/*
Iterates over a string, calling a callback for each rune with the previous, current, and next runes as arguments.

**Inputs**  
- w: An io.Writer to be used by the callback for writing output.
- s: The input string to be iterated over.
- callback: A procedure to be called for each rune in the string, with arguments (w: io.Writer, prev, curr, next: rune).
The callback can utilize the provided io.Writer to write output during the iteration.

Example:

	import "core:fmt"
	import "core:strings"
	import "core:io"

	strings_string_case_iterator_example :: proc() {
		my_callback :: proc(w: io.Writer, prev, curr, next: rune) {
			fmt.println("my_callback", curr) // <-- Custom logic here
		}
		s := "hello"
		b: strings.Builder
		strings.builder_init_len(&b, len(s))
		w := strings.to_writer(&b)
		strings.string_case_iterator(w, s, my_callback)
	}

Output:

	my_callback h
	my_callback e
	my_callback l
	my_callback l
	my_callback o

*/
string_case_iterator :: proc(
	w: io.Writer,
	s: string,
	callback: proc(w: io.Writer, prev, curr, next: rune),
) {
	prev, curr: rune
	for next in s {
		if curr == 0 {
			prev = curr
			curr = next
			continue
		}

		callback(w, prev, curr, next)

		prev = curr
		curr = next
	}

	if len(s) > 0 {
		callback(w, prev, curr, 0)
	}
}
// Alias to `to_camel_case`
to_lower_camel_case :: to_camel_case
/*
Converts the input string `s` to "lowerCamelCase".

*Allocates Using Provided Allocator*

**Inputs**  
- s: Input string to be converted.
- allocator: (default: context.allocator).

**Returns**  
A "lowerCamelCase" formatted string.
*/
to_camel_case :: proc(s: string, allocator := context.allocator) -> string {
	s := s
	s = trim_space(s)
	b: Builder
	builder_init(&b, 0, len(s), allocator)
	w := to_writer(&b)

	string_case_iterator(w, s, proc(w: io.Writer, prev, curr, next: rune) {
		if !is_delimiter(curr) {
			if is_delimiter(prev) {
				io.write_rune(w, unicode.to_upper(curr))
			} else if unicode.is_lower(prev) {
				io.write_rune(w, curr)
			} else {
				io.write_rune(w, unicode.to_lower(curr))
			}
		}
	})

	return to_string(b)
}
// Alias to `to_pascal_case`
to_upper_camel_case :: to_pascal_case
/*
Converts the input string `s` to "UpperCamelCase" (PascalCase).

*Allocates Using Provided Allocator*

**Inputs**  
- s: Input string to be converted.
- allocator: (default: context.allocator).

**Returns**  
A "PascalCase" formatted string.
*/
to_pascal_case :: proc(s: string, allocator := context.allocator) -> string {
	s := s
	s = trim_space(s)
	b: Builder
	builder_init(&b, 0, len(s), allocator)
	w := to_writer(&b)

	string_case_iterator(w, s, proc(w: io.Writer, prev, curr, next: rune) {
		if !is_delimiter(curr) {
			if is_delimiter(prev) || prev == 0 {
				io.write_rune(w, unicode.to_upper(curr))
			} else if unicode.is_lower(prev) {
				io.write_rune(w, curr)
			} else {
				io.write_rune(w, unicode.to_lower(curr))
			}
		}
	})

	return to_string(b)
}
/*
Returns a string converted to a delimiter-separated case with configurable casing

*Allocates Using Provided Allocator*

**Inputs**  
- s: The input string to be converted
- delimiter: The rune to be used as the delimiter between words
- all_upper_case: A boolean indicating if the output should be all uppercased (true) or lowercased (false)
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_delimiter_case_example :: proc() {
		fmt.println(strings.to_delimiter_case("Hello World", '_', false))
		fmt.println(strings.to_delimiter_case("Hello World", ' ', true))
		fmt.println(strings.to_delimiter_case("aBC", '_', false))
	}

Output:

	hello_world
	HELLO WORLD
	a_bc

**Returns**  
The converted string
*/
to_delimiter_case :: proc(
	s: string,
	delimiter: rune,
	all_upper_case: bool,
	allocator := context.allocator,
) -> string {
	s := s
	s = trim_space(s)
	b: Builder
	builder_init(&b, 0, len(s), allocator)
	w := to_writer(&b)

	adjust_case := unicode.to_upper if all_upper_case else unicode.to_lower

	prev, curr: rune

	for next in s {
		if is_delimiter(curr) {
			if !is_delimiter(prev) {
				io.write_rune(w, delimiter)
			}
		} else if unicode.is_upper(curr) {
			if unicode.is_lower(prev) || (unicode.is_upper(prev) && unicode.is_lower(next)) {
				io.write_rune(w, delimiter)
			}
			io.write_rune(w, adjust_case(curr))
		} else if curr != 0 {
			io.write_rune(w, adjust_case(curr))
		}

		prev = curr
		curr = next
	}

	if len(s) > 0 {
		if unicode.is_upper(curr) && unicode.is_lower(prev) && prev != 0 {
			io.write_rune(w, delimiter)
		}
		io.write_rune(w, adjust_case(curr))
	}

	return to_string(b)
}
/*
Converts a string to "snake_case" with all runes lowercased

*Allocates Using Provided Allocator*

**Inputs**  
- s: The input string to be converted
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_snake_case_example :: proc() {
		fmt.println(strings.to_snake_case("HelloWorld"))
		fmt.println(strings.to_snake_case("Hello World"))
	}

Output:

	hello_world
	hello_world

```
**Returns**  
The converted string
*/
to_snake_case :: proc(s: string, allocator := context.allocator) -> string {
	return to_delimiter_case(s, '_', false, allocator)
}
// Alias for `to_upper_snake_case`
to_screaming_snake_case :: to_upper_snake_case
/*
Converts a string to "SNAKE_CASE" with all runes uppercased

*Allocates Using Provided Allocator*

**Inputs**  
- s: The input string to be converted
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_upper_snake_case_example :: proc() {
		fmt.println(strings.to_upper_snake_case("HelloWorld"))
	}

Output:

	HELLO_WORLD

**Returns**  
The converted string
*/
to_upper_snake_case :: proc(s: string, allocator := context.allocator) -> string {
	return to_delimiter_case(s, '_', true, allocator)
}
/*
Converts a string to "kebab-case" with all runes lowercased

*Allocates Using Provided Allocator*

**Inputs**  
- s: The input string to be converted
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_kebab_case_example :: proc() {
		fmt.println(strings.to_kebab_case("HelloWorld"))
	}

Output:

	hello-world

**Returns**  
The converted string
*/
to_kebab_case :: proc(s: string, allocator := context.allocator) -> string {
	return to_delimiter_case(s, '-', false, allocator)
}
/*
Converts a string to "KEBAB-CASE" with all runes uppercased

*Allocates Using Provided Allocator*

**Inputs**  
- s: The input string to be converted
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_upper_kebab_case_example :: proc() {
		fmt.println(strings.to_upper_kebab_case("HelloWorld"))
	}

Output:

	HELLO-WORLD

**Returns**  
The converted string
*/
to_upper_kebab_case :: proc(s: string, allocator := context.allocator) -> string {
	return to_delimiter_case(s, '-', true, allocator)
}
/*
Converts a string to "Ada_Case"

*Allocates Using Provided Allocator*

**Inputs**  
- s: The input string to be converted
- allocator: (default: context.allocator).

Example:

	import "core:fmt"
	import "core:strings"

	strings_to_ada_case_example :: proc() {
		fmt.println(strings.to_ada_case("HelloWorld"))
	}

Output:

	Hello_World

**Returns**  
The converted string
*/
to_ada_case :: proc(s: string, allocator := context.allocator) -> string {
	s := s
	s = trim_space(s)
	b: Builder
	builder_init(&b, 0, len(s), allocator)
	w := to_writer(&b)

	string_case_iterator(w, s, proc(w: io.Writer, prev, curr, next: rune) {
		if !is_delimiter(curr) {
			if is_delimiter(prev) || prev == 0 || (unicode.is_lower(prev) && unicode.is_upper(curr)) {
				if prev != 0 {
					io.write_rune(w, '_')
				}
				io.write_rune(w, unicode.to_upper(curr))
			} else {
				io.write_rune(w, unicode.to_lower(curr))
			}
		}
	})

	return to_string(b)
}
