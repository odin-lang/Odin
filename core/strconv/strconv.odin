package strconv

import "core:unicode/utf8"
import "decimal"
/*
Parses a boolean value from the input string

**Inputs**  
- s: The input string  
  - true: "1", "t", "T", "true", "TRUE", "True"
  - false: "0", "f", "F", "false", "FALSE", "False"
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

**Returns**  
- result: The parsed boolean value (default: false)
- ok: A boolean indicating whether the parsing was successful
*/
parse_bool :: proc(s: string, n: ^int = nil) -> (result: bool = false, ok: bool) {
	switch s {
	case "1", "t", "T", "true", "TRUE", "True":
		if n != nil { n^ = len(s) }
		return true, true
	case "0", "f", "F", "false", "FALSE", "False":
		if n != nil { n^ = len(s) }
		return false, true
	}
	return
}
/*
Finds the integer value of the given rune

**Inputs**  
- r: The input rune to find the integer value of

**Returns**   The integer value of the given rune
*/
_digit_value :: proc(r: rune) -> int {
	ri := int(r)
	v: int = 16
	switch r {
	case '0'..='9': v = ri-'0'
	case 'a'..='z': v = ri-'a'+10
	case 'A'..='Z': v = ri-'A'+10
	}
	return v
}
/*
Parses an integer value from the input string in the given base, without a prefix

**Inputs**  
- str: The input string to parse the integer value from
- base: The base of the integer value to be parsed (must be between 1 and 16)
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:

	import "core:fmt"
	import "core:strconv"
	parse_i64_of_base_example :: proc() {
		n, ok := strconv.parse_i64_of_base("-1234e3", 10)
		fmt.println(n, ok)
	}

Output:

	-1234 false

**Returns**  
- value: Parses an integer value from a string, in the given base, without a prefix.
- ok: ok=false if no numeric value of the appropriate base could be found, or if the input string contained more than just the number.
*/
parse_i64_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: i64, ok: bool) {
	assert(base <= 16, "base must be 1-16")

	s := str

	defer if n != nil { n^ = len(str)-len(s) }

	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i64(_digit_value(r))
		if v >= i64(base) {
			break
		}
		value *= i64(base)
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}
/*
Parses an integer value from the input string in base 10, unless there's a prefix

**Inputs**  
- str: The input string to parse the integer value from
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:
	
	import "core:fmt"
	import "core:strconv"
	parse_i64_maybe_prefixed_example :: proc() {
		n, ok := strconv.parse_i64_maybe_prefixed("1234")
		fmt.println(n,ok)

		n, ok = strconv.parse_i64_maybe_prefixed("0xeeee")
		fmt.println(n,ok)
	}
	
Output:

	1234 true
	61166 true

**Returns**  
- value: The parsed integer value
- ok: ok=false if a valid integer could not be found, or if the input string contained more than just the number.
*/
parse_i64_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: i64, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	base: i64 = 10
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i64(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}
//
parse_i64 :: proc{parse_i64_maybe_prefixed, parse_i64_of_base}
/*
Parses an unsigned 64-bit integer value from the input string without a prefix, using the specified base

**Inputs**  
- str: The input string to parse
- base: The base of the number system to use for parsing
  - Must be between 1 and 16 (inclusive)
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:
	
	import "core:fmt"
	import "core:strconv"
	parse_u64_of_base_example :: proc() {
		n, ok := strconv.parse_u64_of_base("1234e3", 10)
		fmt.println(n,ok)

		n, ok = strconv.parse_u64_of_base("5678eee",16)
		fmt.println(n,ok)
	}
	
Output:

	1234 false
	90672878 true

**Returns**  
- value: The parsed uint64 value
- ok: A boolean indicating whether the parsing was successful
*/
parse_u64_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: u64, ok: bool) {
	assert(base <= 16, "base must be 1-16")
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u64(_digit_value(r))
		if v >= u64(base) {
			break
		}
		value *= u64(base)
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}
/*
Parses an unsigned 64-bit integer value from the input string, using the specified base or inferring the base from a prefix

**Inputs**  
- str: The input string to parse
- base: The base of the number system to use for parsing (default: 0)
  - If base is 0, it will be inferred based on the prefix in the input string (e.g. '0x' for hexadecimal)
  - If base is not 0, it will be used for parsing regardless of any prefix in the input string
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:
	
	import "core:fmt"
	import "core:strconv"
	parse_u64_maybe_prefixed_example :: proc() {
		n, ok := strconv.parse_u64_maybe_prefixed("1234")
		fmt.println(n,ok)

		n, ok = strconv.parse_u64_maybe_prefixed("0xee")
		fmt.println(n,ok)
	}
	
Output:

	1234 true
	238 true

**Returns**  
- value: The parsed uint64 value
- ok: ok=false if a valid integer could not be found, if the value was negative, or if the input string contained more than just the number.
*/
parse_u64_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: u64, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}


	base := u64(10)
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u64(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}
//
parse_u64 :: proc{parse_u64_maybe_prefixed, parse_u64_of_base}
/*
Parses a signed integer value from the input string, using the specified base or inferring the base from a prefix

**Inputs**  
- s: The input string to parse
- base: The base of the number system to use for parsing (default: 0)
  - If base is 0, it will be inferred based on the prefix in the input string (e.g. '0x' for hexadecimal)
  - If base is not 0, it will be used for parsing regardless of any prefix in the input string

Example:
	
	import "core:fmt"
	import "core:strconv"
	parse_int_example :: proc() {
		n, ok := strconv.parse_int("1234") // without prefix, inferred base 10
		fmt.println(n,ok)

		n, ok = strconv.parse_int("ffff", 16) // without prefix, explicit base
		fmt.println(n,ok)

		n, ok = strconv.parse_int("0xffff") // with prefix and inferred base
		fmt.println(n,ok)
	}
	
Output:

	1234 true
	65535 true
	65535 true

**Returns**  
- value: The parsed int value
- ok: `false` if no appropriate value could be found, or if the input string contained more than just the number.
*/
parse_int :: proc(s: string, base := 0, n: ^int = nil) -> (value: int, ok: bool) {
	v: i64 = ---
	switch base {
	case 0:  v, ok = parse_i64_maybe_prefixed(s, n)
	case:    v, ok = parse_i64_of_base(s, base, n)
	}
	value = int(v)
	return
}
/*
Parses an unsigned integer value from the input string, using the specified base or inferring the base from a prefix

**Inputs**  
- s: The input string to parse
- base: The base of the number system to use for parsing (default: 0, inferred)
  - If base is 0, it will be inferred based on the prefix in the input string (e.g. '0x' for hexadecimal)
  - If base is not 0, it will be used for parsing regardless of any prefix in the input string

Example:
	
	import "core:fmt"
	import "core:strconv"
	parse_uint_example :: proc() {
		n, ok := strconv.parse_uint("1234") // without prefix, inferred base 10
		fmt.println(n,ok)

		n, ok = strconv.parse_uint("ffff", 16) // without prefix, explicit base
		fmt.println(n,ok)

		n, ok = strconv.parse_uint("0xffff") // with prefix and inferred base
		fmt.println(n,ok)
	}
	
Output:

	1234 true
	65535 true
	65535 true

**Returns**  

value: The parsed uint value
ok: `false` if no appropriate value could be found; the value was negative; he input string contained more than just the number
*/
parse_uint :: proc(s: string, base := 0, n: ^int = nil) -> (value: uint, ok: bool) {
	v: u64 = ---
	switch base {
	case 0:  v, ok = parse_u64_maybe_prefixed(s, n)
	case:    v, ok = parse_u64_of_base(s, base, n)
	}
	value = uint(v)
	return
}
/*
Parses an integer value from a string in the given base, without any prefix

**Inputs**  
- str: The input string containing the integer value
- base: The base (radix) to use for parsing the integer (1-16)
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:

	import "core:fmt"
	import "core:strconv"
	parse_i128_of_base_example :: proc() {
		n, ok := strconv.parse_i128_of_base("-1234eeee", 10)
		fmt.println(n,ok)
	}
	
Output:

	-1234 false

**Returns**  
- value: The parsed i128 value
- ok: false if no numeric value of the appropriate base could be found, or if the input string contained more than just the number.
*/
parse_i128_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: i128, ok: bool) {
	assert(base <= 16, "base must be 1-16")

	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i128(_digit_value(r))
		if v >= i128(base) {
			break
		}
		value *= i128(base)
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}
/*
Parses an integer value from a string in base 10, unless there's a prefix

**Inputs**  
- str: The input string containing the integer value
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:

	import "core:fmt"
	import "core:strconv"
	parse_i128_maybe_prefixed_example :: proc() {
		n, ok := strconv.parse_i128_maybe_prefixed("1234")
		fmt.println(n, ok)

		n, ok = strconv.parse_i128_maybe_prefixed("0xeeee")
		fmt.println(n, ok)
	}
	
Output:

	1234 true
	61166 true
	
**Returns**  
- value: The parsed i128 value
- ok: `false` if a valid integer could not be found, or if the input string contained more than just the number.
*/
parse_i128_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: i128, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	neg := false
	if len(s) > 1 {
		switch s[0] {
		case '-':
			neg = true
			s = s[1:]
		case '+':
			s = s[1:]
		}
	}


	base: i128 = 10
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}


	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := i128(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	if neg {
		value = -value
	}
	ok = len(s) == 0
	return
}
//
parse_i128 :: proc{parse_i128_maybe_prefixed, parse_i128_of_base}
/*
Parses an unsigned integer value from a string in the given base, without any prefix

**Inputs**  
- str: The input string containing the integer value
- base: The base (radix) to use for parsing the integer (1-16)
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:

	import "core:fmt"
	import "core:strconv"
	parse_u128_of_base_example :: proc() {
		n, ok := strconv.parse_u128_of_base("1234eeee", 10)
		fmt.println(n, ok)

		n, ok = strconv.parse_u128_of_base("5678eeee", 16)
		fmt.println(n, ok)
	}
	
Output:

	1234 false
	1450766062 true
	
**Returns**  
- value: The parsed u128 value
- ok: `false` if no numeric value of the appropriate base could be found, or if the input string contained more than just the number.
*/
parse_u128_of_base :: proc(str: string, base: int, n: ^int = nil) -> (value: u128, ok: bool) {
	assert(base <= 16, "base must be 1-16")
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u128(_digit_value(r))
		if v >= u128(base) {
			break
		}
		value *= u128(base)
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}
/*
Parses an unsigned integer value from a string in base 10, unless there's a prefix

**Inputs**  
- str: The input string containing the integer value
- n: An optional pointer to an int to store the length of the parsed substring (default: nil)

Example:

	import "core:fmt"
	import "core:strconv"
	parse_u128_maybe_prefixed_example :: proc() {
		n, ok := strconv.parse_u128_maybe_prefixed("1234")
		fmt.println(n, ok)

		n, ok = strconv.parse_u128_maybe_prefixed("5678eeee")
		fmt.println(n, ok)
	}
	
Output:

	1234 true
	5678 false
	
**Returns**  
- value: The parsed u128 value
- ok: false if a valid integer could not be found, if the value was negative, or if the input string contained more than just the number.
*/
parse_u128_maybe_prefixed :: proc(str: string, n: ^int = nil) -> (value: u128, ok: bool) {
	s := str
	defer if n != nil { n^ = len(str)-len(s) }
	if s == "" {
		return
	}

	if len(s) > 1 && s[0] == '+' {
		s = s[1:]
	}


	base := u128(10)
	if len(s) > 2 && s[0] == '0' {
		switch s[1] {
		case 'b': base =  2;  s = s[2:]
		case 'o': base =  8;  s = s[2:]
		case 'd': base = 10;  s = s[2:]
		case 'z': base = 12;  s = s[2:]
		case 'x': base = 16;  s = s[2:]
		}
	}

	i := 0
	for r in s {
		if r == '_' {
			i += 1
			continue
		}
		v := u128(_digit_value(r))
		if v >= base {
			break
		}
		value *= base
		value += v
		i += 1
	}
	s = s[i:]

	ok = len(s) == 0
	return
}
//
parse_u128 :: proc{parse_u128_maybe_prefixed, parse_u128_of_base}
/*
Converts a byte to lowercase

**Inputs**  
- ch: A byte character to be converted to lowercase.

**Returns**  
- A lowercase byte character.
*/
@(private)
lower :: #force_inline proc "contextless" (ch: byte) -> byte { return ('a' - 'A') | ch }
/*
Parses a 32-bit floating point number from a string

**Inputs**  
- s: The input string containing a 32-bit floating point number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_f32_example :: proc() {
		n, ok := strconv.parse_f32("1234eee")
		fmt.printfln("%.3f %v", n, ok)

		n, ok = strconv.parse_f32("5678e2")
		fmt.printfln("%.3f %v", n, ok)
	}
	
Output:

	0.000 false
	567800.000 true
	
**Returns**  
- value: The parsed 32-bit floating point number.
- ok: `false` if a base 10 float could not be found, or if the input string contained more than just the number.
*/
parse_f32 :: proc(s: string, n: ^int = nil) -> (value: f32, ok: bool) {
	v: f64 = ---
	v, ok = parse_f64(s, n)
	return f32(v), ok
}
/*
Parses a 64-bit floating point number from a string

**Inputs**  
- str: The input string containing a 64-bit floating point number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_f64_example :: proc() {
		n, ok := strconv.parse_f64("1234eee")
		fmt.printfln("%.3f %v", n, ok)

		n, ok = strconv.parse_f64("5678e2")
		fmt.printfln("%.3f %v", n, ok)
	}
	
Output:

	0.000 false
	567800.000 true
	
**Returns**  
- value: The parsed 64-bit floating point number.
- ok: `false` if a base 10 float could not be found, or if the input string contained more than just the number.
*/
parse_f64 :: proc(str: string, n: ^int = nil) -> (value: f64, ok: bool) {
	nr: int
	value, nr, ok = parse_f64_prefix(str)
	if ok && len(str) != nr {
		ok = false
	}
	if n != nil { n^ = nr }
	return
}
/*
Parses a 32-bit floating point number from a string and returns the parsed number, the length of the parsed substring, and a boolean indicating whether the parsing was successful

**Inputs**  
- str: The input string containing a 32-bit floating point number.

Example:

	import "core:fmt"
	import "core:strconv"
	parse_f32_prefix_example :: proc() {
		n, _, ok := strconv.parse_f32_prefix("1234eee")
		fmt.printfln("%.3f %v", n, ok)

		n, _, ok = strconv.parse_f32_prefix("5678e2")
		fmt.printfln("%.3f %v", n, ok)
	}
	
Output:

	0.000 false
	567800.000 true
	

**Returns**  
- value: The parsed 32-bit floating point number.
- nr: The length of the parsed substring.
- ok: A boolean indicating whether the parsing was successful.
*/
parse_f32_prefix :: proc(str: string) -> (value: f32, nr: int, ok: bool) {
	f: f64
	f, nr, ok = parse_f64_prefix(str)
	value = f32(f)
	return
}
/*
Parses a 64-bit floating point number from a string and returns the parsed number, the length of the parsed substring, and a boolean indicating whether the parsing was successful

**Inputs**  
- str: The input string containing a 64-bit floating point number.

Example:

	import "core:fmt"
	import "core:strconv"
	parse_f64_prefix_example :: proc() {
		n, _, ok := strconv.parse_f64_prefix("12.34eee")
		fmt.printfln("%.3f %v", n, ok)

		n, _, ok = strconv.parse_f64_prefix("12.34e2")
		fmt.printfln("%.3f %v", n, ok)

		n, _, ok = strconv.parse_f64_prefix("13.37 hellope")
		fmt.printfln("%.3f %v", n, ok)
	}

Output:

	0.000 false
	1234.000 true
	13.370 true

**Returns**  
- value: The parsed 64-bit floating point number.
- nr: The length of the parsed substring.
- ok: `false` if a base 10 float could not be found
*/
parse_f64_prefix :: proc(str: string) -> (value: f64, nr: int, ok: bool) {
	common_prefix_len_ignore_case :: proc "contextless" (s, prefix: string) -> int {
		n := len(prefix)
		if n > len(s) {
			n = len(s)
		}
		for i in 0..<n {
			c := s[i]
			if 'A' <= c && c <= 'Z' {
				c += 'a' - 'A'
			}
			if c != prefix[i] {
				return i
			}
		}
		return n
	}
	check_special :: proc "contextless" (s: string) -> (f: f64, n: int, ok: bool) {
		s := s
		if len(s) > 0 {
			sign := 1
			nsign := 0
			switch s[0] {
			case '+', '-':
				if s[0] == '-' {
					sign = -1
				}
				nsign = 1
				s = s[1:]
				fallthrough
			case 'i', 'I':
				m := common_prefix_len_ignore_case(s, "infinity")
				if 3 <= m && m < 9 { // "inf" to "infinity"
					f = 0h7ff00000_00000000 if sign == 1 else 0hfff00000_00000000
					if m == 8 {
						// We only count the entire prefix if it is precisely "infinity".
						n = nsign + m
					} else {
						// The string was either only "inf" or incomplete.
						n = nsign + 3
					}
					ok = true
					return
				}
			case 'n', 'N':
				if common_prefix_len_ignore_case(s, "nan") == 3 {
					f = 0h7ff80000_00000001
					n = nsign + 3
					ok = true
					return
				}
			}
		}
		return
	}
	parse_components :: proc "contextless" (s: string) -> (mantissa: u64, exp: int, neg, trunc, hex: bool, i: int, ok: bool) {
		if len(s) == 0 {
			return
		}
		switch s[i] {
		case '+': i += 1
		case '-': i += 1; neg = true
		}

		base := u64(10)
		MAX_MANT_DIGITS := 19
		exp_char := byte('e')
		// support stupid 0x1.ABp100 hex floats even if Odin doesn't
		if i+2 < len(s) && s[i] == '0' && lower(s[i+1]) == 'x' {
			base = 16
			MAX_MANT_DIGITS = 16
			i += 2
			exp_char = 'p'
			hex = true
		}

		underscores := false
		saw_dot, saw_digits := false, false
		nd := 0
		nd_mant := 0
		decimal_point := 0
		trailing_zeroes_nd := -1
		loop: for ; i < len(s); i += 1 {
			switch c := s[i]; true {
			case c == '_':
				underscores = true
				continue loop
			case c == '.':
				if saw_dot {
					break loop
				}
				saw_dot = true
				decimal_point = nd
				continue loop

			case '0' <= c && c <= '9':
				saw_digits = true
				if c == '0' {
					if nd == 0 {
						decimal_point -= 1
						continue loop
					}
					if trailing_zeroes_nd == -1 {
						trailing_zeroes_nd = nd
					}
				} else {
					trailing_zeroes_nd = -1
				}
				nd += 1
				if nd_mant < MAX_MANT_DIGITS {
					mantissa *= base
					mantissa += u64(c - '0')
					nd_mant += 1
				} else if c != '0' {
					trunc = true
				}
				continue loop
			case base == 16 && 'a' <= lower(c) && lower(c) <= 'f':
				saw_digits = true
				nd += 1
				if nd_mant < MAX_MANT_DIGITS {
					mantissa *= 16
					mantissa += u64(lower(c) - 'a' + 10)
					nd_mant += 1
				} else {
					trunc = true
				}
				continue loop
			}
			break loop
		}

		if !saw_digits {
			return
		}
		if !saw_dot {
			decimal_point = nd
		}
		if trailing_zeroes_nd > 0 {
			trailing_zeroes_nd = nd_mant - trailing_zeroes_nd
		}
		for /**/; trailing_zeroes_nd > 0; trailing_zeroes_nd -= 1 {
			mantissa /= base
			nd_mant -= 1
			nd -= 1
		}
		if base == 16 {
			decimal_point *= 4
			nd_mant *= 4
		}

		if i < len(s) && lower(s[i]) == exp_char {
			i += 1
			if i >= len(s) { return }
			exp_sign := 1
			switch s[i] {
			case '+': i += 1
			case '-': i += 1; exp_sign = -1
			}
			if i >= len(s) || s[i] < '0' || s[i] > '9' {
				return
			}
			e := 0
			for ; i < len(s) && ('0' <= s[i] && s[i] <= '9' || s[i] == '_'); i += 1 {
				if s[i] == '_' {
					underscores = true
					continue
				}
				if e < 1e5 {
					e = e*10 + int(s[i]) - '0'
				}
			}
			decimal_point += e * exp_sign
		} else if base == 16 {
			return
		}

		if mantissa != 0 {
			exp = decimal_point - nd_mant
		}
		ok = true
		return
	}

	parse_hex :: proc "contextless" (s: string, mantissa: u64, exp: int, neg, trunc: bool) -> (f64, bool) {
		info := &_f64_info

		mantissa, exp := mantissa, exp

		MAX_EXP := 1<<info.expbits + info.bias - 2
		MIN_EXP := info.bias + 1
		exp += int(info.mantbits)

		for mantissa != 0 && mantissa >> (info.mantbits+2) == 0 {
			mantissa <<= 1
			exp -= 1
		}
		if trunc {
			mantissa |= 1
		}

		for mantissa != 0 && mantissa >> (info.mantbits+2) == 0 {
			mantissa = mantissa>>1 | mantissa&1
			exp += 1
		}

		// denormalize
		if mantissa > 1 && exp < MIN_EXP-2 {
			mantissa = mantissa>>1 | mantissa&1
			exp += 1
		}

		round := mantissa & 3
		mantissa >>= 2
		round |= mantissa & 1 // round to even
		exp += 2
		if round == 3 {
			mantissa += 1
			if mantissa == 1 << (1 + info.mantbits) {
				mantissa >>= 1
				exp += 1
			}
		}
		if mantissa>>info.mantbits == 0 {
			// zero or denormal
			exp = info.bias
		}

		ok := true
		if exp > MAX_EXP {
			// infinity or invalid
			mantissa = 1<<info.mantbits
			exp = MAX_EXP + 1
			ok = false
		}

		bits := mantissa & (1<<info.mantbits - 1)
		bits |= u64((exp-info.bias) & (1<<info.expbits - 1)) << info.mantbits
		if neg {
			bits |= 1 << info.mantbits << info.expbits
		}
		return transmute(f64)bits, ok
	}


	if value, nr, ok = check_special(str); ok {
		return
	}

	mantissa: u64
	exp:      int
	neg, trunc, hex: bool
	mantissa, exp, neg, trunc, hex, nr = parse_components(str) or_return

	if hex {
		value, ok = parse_hex(str, mantissa, exp, neg, trunc)
		return
	}

	trunc_block: if !trunc {
		@(static, rodata) pow10 := [?]f64{
			1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,  1e8,  1e9,
			1e10, 1e11, 1e12, 1e13, 1e14, 1e15, 1e16, 1e17, 1e18, 1e19,
			1e20, 1e21, 1e22,
		}

		if mantissa>>_f64_info.mantbits != 0 {
			break trunc_block
		}
		f := f64(mantissa)
		if neg {
			f = -f
		}
		switch {
		case exp == 0:
			return f, nr, true
		case exp > 0 && exp <= 15+22:
			if exp > 22 {
				f *= pow10[exp-22]
				exp = 22
			}
			if f > 1e15 || f < 1e-15 {
				break trunc_block
			}
			return f * pow10[exp], nr, true
		case -22 <= exp && exp < 0:
			return f / pow10[-exp], nr, true
		}
	}
	d: decimal.Decimal
	decimal.set(&d, str[:nr])
	b, overflow := decimal_to_float_bits(&d, &_f64_info)
	value = transmute(f64)b
	ok = !overflow
	return
}
/*
Parses a 128-bit complex number from a string

**Inputs**  
- str: The input string containing a 128-bit complex number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_complex128_example :: proc() {
		n: int
		c, ok := strconv.parse_complex128("3+1i", &n)
		fmt.printfln("%v %i %t", c, n, ok)

		c, ok = strconv.parse_complex128("5+7i hellope", &n)
		fmt.printfln("%v %i %t", c, n, ok)
	}
	
Output:

	3+1i 4 true
	5+7i 4 false
	
**Returns**  
- value: The parsed 128-bit complex number.
- ok: `false` if a complex number could not be found, or if the input string contained more than just the number.
*/
parse_complex128 :: proc(str: string, n: ^int = nil) -> (value: complex128, ok: bool) {
	real_value, imag_value: f64
	nr_r, nr_i: int

	real_value, nr_r, _ = parse_f64_prefix(str)
	imag_value, nr_i, _ = parse_f64_prefix(str[nr_r:])

	i_parsed := len(str) >= nr_r + nr_i + 1 && str[nr_r + nr_i] == 'i'
	if !i_parsed {
		// No `i` means we refuse to treat the second float we parsed as an
		// imaginary value.
		imag_value = 0
		nr_i = 0
	}

	ok = i_parsed && len(str) == nr_r + nr_i + 1

	if n != nil {
		n^ = nr_r + nr_i + (1 if i_parsed else 0)
	}

	value = complex(real_value, imag_value)
	return 
}
/*
Parses a 64-bit complex number from a string

**Inputs**  
- str: The input string containing a 64-bit complex number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_complex64_example :: proc() {
		n: int
		c, ok := strconv.parse_complex64("3+1i", &n)
		fmt.printfln("%v %i %t", c, n, ok)

		c, ok = strconv.parse_complex64("5+7i hellope", &n)
		fmt.printfln("%v %i %t", c, n, ok)
	}
	
Output:

	3+1i 4 true
	5+7i 4 false
	
**Returns**  
- value: The parsed 64-bit complex number.
- ok: `false` if a complex number could not be found, or if the input string contained more than just the number.
*/
parse_complex64 :: proc(str: string, n: ^int = nil) -> (value: complex64, ok: bool) {
	v: complex128 = ---
	v, ok = parse_complex128(str, n)
	return cast(complex64)v, ok
}
/*
Parses a 32-bit complex number from a string

**Inputs**  
- str: The input string containing a 32-bit complex number.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_complex32_example :: proc() {
		n: int
		c, ok := strconv.parse_complex32("3+1i", &n)
		fmt.printfln("%v %i %t", c, n, ok)

		c, ok = strconv.parse_complex32("5+7i hellope", &n)
		fmt.printfln("%v %i %t", c, n, ok)
	}
	
Output:

	3+1i 4 true
	5+7i 4 false
	
**Returns**  
- value: The parsed 32-bit complex number.
- ok: `false` if a complex number could not be found, or if the input string contained more than just the number.
*/
parse_complex32 :: proc(str: string, n: ^int = nil) -> (value: complex32, ok: bool) {
	v: complex128 = ---
	v, ok = parse_complex128(str, n)
	return cast(complex32)v, ok
}
/*
Parses a 256-bit quaternion from a string

**Inputs**  
- str: The input string containing a 256-bit quaternion.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_quaternion256_example :: proc() {
		n: int
		q, ok := strconv.parse_quaternion256("1+2i+3j+4k", &n)
		fmt.printfln("%v %i %t", q, n, ok)

		q, ok = strconv.parse_quaternion256("1+2i+3j+4k hellope", &n)
		fmt.printfln("%v %i %t", q, n, ok)
	}
	
Output:

	1+2i+3j+4k 10 true
	1+2i+3j+4k 10 false
	
**Returns**  
- value: The parsed 256-bit quaternion.
- ok: `false` if a quaternion could not be found, or if the input string contained more than just the quaternion.
*/
parse_quaternion256 :: proc(str: string, n: ^int = nil) -> (value: quaternion256, ok: bool) {
	iterate_and_assign :: proc (iter: ^string, terminator: byte, nr_total: ^int, state: bool) -> (value: f64, ok: bool) {
		if !state {
			return
		}

		nr: int
		value, nr, _ = parse_f64_prefix(iter^)
		iter^ = iter[nr:]

		if len(iter) > 0 && iter[0] == terminator {
			iter^ = iter[1:]
			nr_total^ += nr + 1
			ok = true
		} else {
			value = 0
		}

		return
	}

	real_value, imag_value, jmag_value, kmag_value: f64
	nr: int

	real_value, nr, _ = parse_f64_prefix(str)
	iter := str[nr:]

	// Need to have parsed at least something in order to get started.
	ok = nr > 0

	// Quaternion parsing is done this way to honour the rest of the API with
	// regards to partial parsing. Otherwise, we could error out early.
	imag_value, ok = iterate_and_assign(&iter, 'i', &nr, ok)
	jmag_value, ok = iterate_and_assign(&iter, 'j', &nr, ok)
	kmag_value, ok = iterate_and_assign(&iter, 'k', &nr, ok)

	if len(iter) != 0 {
		ok = false
	}

	if n != nil {
		n^ = nr
	}

	value = quaternion(
		real = real_value,
		imag = imag_value,
		jmag = jmag_value,
		kmag = kmag_value)
	return
}
/*
Parses a 128-bit quaternion from a string

**Inputs**  
- str: The input string containing a 128-bit quaternion.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_quaternion128_example :: proc() {
		n: int
		q, ok := strconv.parse_quaternion128("1+2i+3j+4k", &n)
		fmt.printfln("%v %i %t", q, n, ok)

		q, ok = strconv.parse_quaternion128("1+2i+3j+4k hellope", &n)
		fmt.printfln("%v %i %t", q, n, ok)
	}
	
Output:

	1+2i+3j+4k 10 true
	1+2i+3j+4k 10 false
	
**Returns**  
- value: The parsed 128-bit quaternion.
- ok: `false` if a quaternion could not be found, or if the input string contained more than just the quaternion.
*/
parse_quaternion128 :: proc(str: string, n: ^int = nil) -> (value: quaternion128, ok: bool) {
	v: quaternion256 = ---
	v, ok = parse_quaternion256(str, n)
	return cast(quaternion128)v, ok
}
/*
Parses a 64-bit quaternion from a string

**Inputs**  
- str: The input string containing a 64-bit quaternion.
- n: An optional pointer to an int to store the length of the parsed substring (default: nil).

Example:

	import "core:fmt"
	import "core:strconv"
	parse_quaternion64_example :: proc() {
		n: int
		q, ok := strconv.parse_quaternion64("1+2i+3j+4k", &n)
		fmt.printfln("%v %i %t", q, n, ok)

		q, ok = strconv.parse_quaternion64("1+2i+3j+4k hellope", &n)
		fmt.printfln("%v %i %t", q, n, ok)
	}
	
Output:

	1+2i+3j+4k 10 true
	1+2i+3j+4k 10 false
	
**Returns**  
- value: The parsed 64-bit quaternion.
- ok: `false` if a quaternion could not be found, or if the input string contained more than just the quaternion.
*/
parse_quaternion64 :: proc(str: string, n: ^int = nil) -> (value: quaternion64, ok: bool) {
	v: quaternion256 = ---
	v, ok = parse_quaternion256(str, n)
	return cast(quaternion64)v, ok
}
/* 
Appends a boolean value as a string to the given buffer

**Inputs**  
- buf: The buffer to append the boolean value to
- b: The boolean value to be appended

Example:

	import "core:fmt"
	import "core:strconv"
	append_bool_example :: proc() {
		buf: [6]byte
		result := strconv.append_bool(buf[:], true)
		fmt.println(result, buf)
	}

Output:

	true [116, 114, 117, 101, 0, 0]

**Returns**  
- The resulting string after appending the boolean value
*/
append_bool :: proc(buf: []byte, b: bool) -> string {
	n := 0
	if b {
		n = copy(buf, "true")
	} else {
		n = copy(buf, "false")
	}
	return string(buf[:n])
}
/* 
Appends an unsigned integer value as a string to the given buffer with the specified base

**Inputs**  
- buf: The buffer to append the unsigned integer value to
- u: The unsigned integer value to be appended
- base: The base to use for converting the integer value

Example:

	import "core:fmt"
	import "core:strconv"
	append_uint_example :: proc() {
		buf: [4]byte
		result := strconv.append_uint(buf[:], 42, 16)
		fmt.println(result, buf)
	}

Output:

	2a [50, 97, 0, 0]

**Returns**  
- The resulting string after appending the unsigned integer value
*/
append_uint :: proc(buf: []byte, u: u64, base: int) -> string {
	return append_bits(buf, u, base, false, 8*size_of(uint), digits, nil)
}
/* 
Appends a signed integer value as a string to the given buffer with the specified base

**Inputs**  
- buf: The buffer to append the signed integer value to
- i: The signed integer value to be appended
- base: The base to use for converting the integer value

Example:

	import "core:fmt"
	import "core:strconv"
	append_int_example :: proc() {
		buf: [4]byte
		result := strconv.append_int(buf[:], -42, 10)
		fmt.println(result, buf)
	}

Output:

	-42 [45, 52, 50, 0]

**Returns**  
- The resulting string after appending the signed integer value
*/
append_int :: proc(buf: []byte, i: i64, base: int) -> string {
	return append_bits(buf, u64(i), base, true, 8*size_of(int), digits, nil)
}



append_u128 :: proc(buf: []byte, u: u128, base: int) -> string {
	return append_bits_128(buf, u, base, false, 8*size_of(uint), digits, nil)
}

/* 
Converts an integer value to a string and stores it in the given buffer

**Inputs**  
- buf: The buffer to store the resulting string
- i: The integer value to be converted

Example:

	import "core:fmt"
	import "core:strconv"
	itoa_example :: proc() {
		buf: [4]byte
		result := strconv.itoa(buf[:], 42)
		fmt.println(result, buf) // "42"
	}

Output:

	42 [52, 50, 0, 0]

**Returns**  
- The resulting string after converting the integer value
*/
itoa :: proc(buf: []byte, i: int) -> string {
	return append_int(buf, i64(i), 10)
}
/*
Converts a string to an integer value

**Inputs**  
- s: The string to be converted

Example:

	import "core:fmt"
	import "core:strconv"
	atoi_example :: proc() {
		fmt.println(strconv.atoi("42"))
	}

Output:

	42

**Returns**  
- The resulting integer value
*/
atoi :: proc(s: string) -> int {
	v, _ := parse_int(s)
	return v
}
/* 
Converts a string to a float64 value

**Inputs**  
- s: The string to be converted

Example:

	import "core:fmt"
	import "core:strconv"
	atof_example :: proc() {
		fmt.printfln("%.3f", strconv.atof("3.14"))
	}

Output:

	3.140

**Returns**  
- The resulting float64 value after converting the string
*/
atof :: proc(s: string) -> f64 {
	v, _  := parse_f64(s)
	return v
}
// Alias to `append_float`
ftoa :: append_float
/* 
Appends a float64 value as a string to the given buffer with the specified format and precision

**Inputs**  
- buf: The buffer to append the float64 value to
- f: The float64 value to be appended
- fmt: The byte specifying the format to use for the conversion
- prec: The precision to use for the conversion
- bit_size: The size of the float in bits (32 or 64)

Example:

	import "core:fmt"
	import "core:strconv"
	append_float_example :: proc() {
		buf: [8]byte
		result := strconv.append_float(buf[:], 3.14159, 'f', 2, 64)
		fmt.println(result, buf)
	}

Output:

	+3.14 [43, 51, 46, 49, 52, 0, 0, 0]

**Returns**  
- The resulting string after appending the float
*/
append_float :: proc(buf: []byte, f: f64, fmt: byte, prec, bit_size: int) -> string {
	return string(generic_ftoa(buf, f, fmt, prec, bit_size))
}
/*
Appends a quoted string representation of the input string to a given byte slice and returns the result as a string

**Inputs**  
- buf: The byte slice to which the quoted string will be appended
- str: The input string to be quoted

!! ISSUE !! NOT EXPECTED -- "\"hello\"" was expected  

Example:

	import "core:fmt"
	import "core:strconv"
	quote_example :: proc() {
		buf: [20]byte
		result := strconv.quote(buf[:], "hello")
		fmt.println(result, buf)
	}

Output:

	"'h''e''l''l''o'" [34, 39, 104, 39, 39, 101, 39, 39, 108, 39, 39, 108, 39, 39, 111, 39, 34, 0, 0, 0]

**Returns**  
- The resulting string after appending the quoted string representation
*/
quote :: proc(buf: []byte, str: string) -> string {
	write_byte :: proc(buf: []byte, i: ^int, bytes: ..byte) {
		if i^ >= len(buf) {
			return
		}
		n := copy(buf[i^:], bytes[:])
		i^ += n
	}

	if buf == nil {
		return ""
	}

	c :: '"'
	i := 0
	s := str

	write_byte(buf, &i, c)
	for width := 0; len(s) > 0; s = s[width:] {
		r := rune(s[0])
		width = 1
		if r >= utf8.RUNE_SELF {
			r, width = utf8.decode_rune_in_string(s)
		}
		if width == 1 && r == utf8.RUNE_ERROR {
			write_byte(buf, &i, '\\', 'x')
			write_byte(buf, &i, digits[s[0]>>4])
			write_byte(buf, &i, digits[s[0]&0xf])
		}
		if i < len(buf) {
			x := quote_rune(buf[i:], r)
			i += len(x)
		}
	}
	write_byte(buf, &i, c)
	return string(buf[:i])
}
/*
Appends a quoted rune representation of the input rune to a given byte slice and returns the result as a string

**Inputs**  
- buf: The byte slice to which the quoted rune will be appended
- r: The input rune to be quoted

Example:

	import "core:fmt"
	import "core:strconv"
	quote_rune_example :: proc() {
		buf: [4]byte
		result := strconv.quote_rune(buf[:], 'A')
		fmt.println(result, buf)
	}

Output:

	'A' [39, 65, 39, 0]

**Returns**  
- The resulting string after appending the quoted rune representation
*/
quote_rune :: proc(buf: []byte, r: rune) -> string {
	write_byte :: proc(buf: []byte, i: ^int, bytes: ..byte) {
		if i^ < len(buf) {
			n := copy(buf[i^:], bytes[:])
			i^ += n
		}
	}
	write_string :: proc(buf: []byte, i: ^int, s: string) {
		if i^ < len(buf) {
			n := copy(buf[i^:], s)
			i^ += n
		}
	}
	write_rune :: proc(buf: []byte, i: ^int, r: rune) {
		if i^ < len(buf) {
			b, w := utf8.encode_rune(r)
			n := copy(buf[i^:], b[:w])
			i^ += n
		}
	}

	if buf == nil {
		return ""
	}

	i := 0
	write_byte(buf, &i, '\'')

	switch r {
	case '\a': write_string(buf, &i, "\\a")
	case '\b': write_string(buf, &i, "\\b")
	case '\e': write_string(buf, &i, "\\e")
	case '\f': write_string(buf, &i, "\\f")
	case '\n': write_string(buf, &i, "\\n")
	case '\r': write_string(buf, &i, "\\r")
	case '\t': write_string(buf, &i, "\\t")
	case '\v': write_string(buf, &i, "\\v")
	case:
		if r < 32 {
			write_string(buf, &i, "\\x")
			b: [2]byte
			s := append_bits(b[:], u64(r), 16, true, 64, digits, nil)
			switch len(s) {
			case 0: write_string(buf, &i, "00")
			case 1: write_rune(buf, &i, '0')
			case 2: write_string(buf, &i, s)
			}
		} else {
			write_rune(buf, &i, r)
		}
	}
	write_byte(buf, &i, '\'')

	return string(buf[:i])
}
/*
Unquotes a single character from the input string, considering the given quote character

**Inputs**  
- str: The input string containing the character to unquote
- quote: The quote character to consider (e.g., '"')

Example:  

	import "core:fmt"
	import "core:strconv"
	unquote_char_example :: proc() {
		src:="\'The\' raven"
		r, multiple_bytes, tail_string, success  := strconv.unquote_char(src,'\'')
		fmt.println("Source:", src)
		fmt.printf("r: <%v>, multiple_bytes:%v, tail_string:<%s>, success:%v\n",r, multiple_bytes, tail_string, success)
	}

Output:  

	Source: 'The' raven
	r: <'>, multiple_bytes:false, tail_string:<The' raven>, success:true

**Returns**  
- r: The unquoted rune
- multiple_bytes: A boolean indicating if the rune has multiple bytes
- tail_string: The remaining portion of the input string after unquoting the character
- success: A boolean indicating whether the unquoting was successful
*/
unquote_char :: proc(str: string, quote: byte) -> (r: rune, multiple_bytes: bool, tail_string: string, success: bool) {
	hex_to_int :: proc(c: byte) -> int {
		switch c {
		case '0'..='9': return int(c-'0')
		case 'a'..='f': return int(c-'a')+10
		case 'A'..='F': return int(c-'A')+10
		}
		return -1
	}
	w: int

	if str[0] == quote && quote == '"' {
		return
	} else if str[0] >= 0x80 {
		r, w = utf8.decode_rune_in_string(str)
		return r, true, str[w:], true
	} else if str[0] != '\\' {
		return rune(str[0]), false, str[1:], true
	}

	if len(str) <= 1 {
		return
	}
	s := str
	c := s[1]
	s = s[2:]

	switch c {
	case:
		return

	case 'a':  r = '\a'
	case 'b':  r = '\b'
	case 'f':  r = '\f'
	case 'n':  r = '\n'
	case 'r':  r = '\r'
	case 't':  r = '\t'
	case 'v':  r = '\v'
	case '\\': r = '\\'

	case '"':  r = '"'
	case '\'': r = '\''

	case '0'..='7':
		v := int(c-'0')
		if len(s) < 2 {
			return
		}
		for i in 0..<len(s) {
			d := int(s[i]-'0')
			if d < 0 || d > 7 {
				return
			}
			v = (v<<3) | d
		}
		s = s[2:]
		if v > 0xff {
			return
		}
		r = rune(v)

	case 'x', 'u', 'U':
		count: int
		switch c {
		case 'x': count = 2
		case 'u': count = 4
		case 'U': count = 8
		}

		if len(s) < count {
			return
		}

		for i in 0..<count {
			d := hex_to_int(s[i])
			if d < 0 {
				return
			}
			r = (r<<4) | rune(d)
		}
		s = s[count:]
		if c == 'x' {
			break
		}
		if r > utf8.MAX_RUNE {
			return
		}
		multiple_bytes = true
	}

	success = true
	tail_string = s
	return
}
/*
Unquotes the input string considering any type of quote character and returns the unquoted string

**Inputs**  
- lit: The input string to unquote
- allocator: (default: context.allocator)

WARNING: This procedure gives unexpected results if the quotes are not the first and last characters.

Example:  

	import "core:fmt"
	import "core:strconv"
	unquote_string_example :: proc() {
		src:="\"The raven Huginn is black.\""
		s, allocated, ok := strconv.unquote_string(src)
		fmt.println(src)
		fmt.printf("Unquoted: <%s>, alloc:%v, ok:%v\n\n", s, allocated, ok)

		src="\'The raven Huginn\' is black."
		s, allocated, ok = strconv.unquote_string(src)
		fmt.println(src)
		fmt.printf("Unquoted: <%s>, alloc:%v, ok:%v\n\n", s, allocated, ok)

		src="The raven \'Huginn\' is black."
		s, allocated, ok = strconv.unquote_string(src) // Will produce undesireable results
		fmt.println(src)
		fmt.printf("Unquoted: <%s>, alloc:%v, ok:%v\n", s, allocated, ok) 
	}

Output:  

	"The raven Huginn is black."
	Unquoted: <The raven Huginn is black.>, alloc:false, ok:true

	'The raven Huginn' is black.
	Unquoted: <The raven Huginn' is black>, alloc:false, ok:true

	The raven 'Huginn' is black.
	Unquoted: <he raven 'Huginn' is black>, alloc:false, ok:true

**Returns**  
- res: The resulting unquoted string
- allocated: A boolean indicating if the resulting string was allocated using the provided allocator
- success: A boolean indicating whether the unquoting was successful

NOTE: If unquoting is unsuccessful, the allocated memory for the result will be freed.
*/
unquote_string :: proc(lit: string, allocator := context.allocator) -> (res: string, allocated, success: bool) {
	contains_rune :: proc(s: string, r: rune) -> int {
		for c, offset in s {
			if c == r {
				return offset
			}
		}
		return -1
	}

	if len(lit) < 2 {
		return
	}
	if lit[0] == '`' {
		return lit[1:len(lit)-1], false, true
	}

	s := lit
	quote := '"'

	if s == `""` {
		return "", false, true
	}
	s = s[1:len(s)-1]

	if contains_rune(s, '\n') >= 0 {
		return s, false, false
	}

	if contains_rune(s, '\\') < 0 && contains_rune(s, quote) < 0 {
		if quote == '"' {
			return s, false, true
		}
	}
	
	context.allocator = allocator

	buf_len := 3*len(s) / 2
	buf := make([]byte, buf_len)
	offset := 0
	for len(s) > 0 {
		r, multiple_bytes, tail_string, ok := unquote_char(s, byte(quote))
		if !ok {
			delete(buf)
			return s, false, false
		}
		s = tail_string
		if r < 0x80 || !multiple_bytes {
			buf[offset] = byte(r)
			offset += 1
		} else {
			b, w := utf8.encode_rune(r)
			copy(buf[offset:], b[:w])
			offset += w
		}
	}

	new_string := string(buf[:offset])

	return new_string, true, true
}
