// Multiple precision decimal numbers
// NOTE: This is only for floating point printing and nothing else
package strconv_decimal

Decimal :: struct {
	digits:        [384]byte, // big-endian digits
	count:         int,
	decimal_point: int,
	neg, trunc:    bool,
}
/*
Sets a Decimal from a given string `s`. The string is expected to represent a float. Stores parsed number in the given Decimal structure.
If parsing fails, the Decimal will be left in an undefined state.

**Inputs**  
- d: Pointer to a Decimal struct where the parsed result will be stored
- s: The input string representing the floating-point number

**Returns**  
- ok: A boolean indicating whether the parsing was successful
*/
set :: proc(d: ^Decimal, s: string) -> (ok: bool) {
	d^ = {}

	if len(s) == 0 {
		return
	}

	i := 0
	switch s[i] {
	case '+': i += 1
	case '-': i += 1; d.neg = true
	}

	// digits
	saw_dot := false
	saw_digits := false
	for ; i < len(s); i += 1 {
		switch {
		case s[i] == '_':
			// ignore underscores
			continue
		case s[i] == '.':
			if saw_dot {
				return
			}
			saw_dot = true
			d.decimal_point = d.count
			continue

		case '0' <= s[i] && s[i] <= '9':
			saw_digits = true
			if s[i] == '0' && d.count == 0 {
				d.decimal_point -= 1
				continue
			}
			if d.count < len(d.digits) {
				d.digits[d.count] = s[i]
				d.count += 1
			} else if s[i] != '0' {
				d.trunc = true
			}
			continue
		}
		break
	}
	if !saw_digits {
		return
	}
	if !saw_dot {
		d.decimal_point = d.count
	}

	lower :: #force_inline proc "contextless" (ch: byte) -> byte { return ('a' - 'A') | ch }

	if i < len(s) && lower(s[i]) == 'e' {
		i += 1
		if i >= len(s) {
			return
		}
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
				// ignore underscores
				continue
			}
			if e < 1e4 {
				e = e*10 + int(s[i]) - '0'
			}
		}
		d.decimal_point += e * exp_sign
	}

	return i == len(s)
}
/*
Converts a Decimal to a string representation, using the provided buffer as storage.

**Inputs**  
- buf: A byte slice buffer to hold the resulting string
- a: The struct to be converted to a string

**Returns**  
- A string representation of the Decimal
*/
decimal_to_string :: proc(buf: []byte, a: ^Decimal) -> string {
	digit_zero :: proc(buf: []byte) -> int {
		for _, i in buf {
			buf[i] = '0'
		}
		return len(buf)
	}

	n := 10 + a.count + abs(a.decimal_point)

	// TODO(bill): make this work with a buffer that's not big enough
	assert(len(buf) >= n)
	b := buf[0:n]

	if a.count == 0 {
		b[0] = '0'
		return string(b[0:1])
	}

	w := 0
	if a.decimal_point <= 0 {
		b[w] = '0'; w += 1
		b[w] = '.'; w += 1
		w += digit_zero(b[w : w-a.decimal_point])
		w += copy(b[w:], a.digits[0:a.count])
	} else if a.decimal_point < a.count {
		w += copy(b[w:], a.digits[0:a.decimal_point])
		b[w] = '.'; w += 1
		w += copy(b[w:], a.digits[a.decimal_point : a.count])
	} else {
		w += copy(b[w:], a.digits[0:a.count])
		w += digit_zero(b[w : w+a.decimal_point-a.count])
	}

	return string(b[0:w])
}
/*
Trims trailing zeros in the given Decimal, updating the count and decimal_point values as needed.

**Inputs**  
- a: Pointer to the Decimal struct to be trimmed
*/
trim :: proc(a: ^Decimal) {
	for a.count > 0 && a.digits[a.count-1] == '0' {
		a.count -= 1
	}
	if a.count == 0 {
		a.decimal_point = 0
	}
}
/*
Converts a given u64 integer `idx` to its Decimal representation in the provided Decimal struct.

**Used for internal Decimal Operations.**

**Inputs**  
- a: Where the result will be stored
- idx: The value to be assigned to the Decimal
*/
assign :: proc(a: ^Decimal, idx: u64) {
	buf: [64]byte
	n := 0
	for i := idx; i > 0;  {
		j := i/10
		i -= 10*j
		buf[n] = byte('0'+i)
		n += 1
		i = j
	}

	a.count = 0
	for n -= 1; n >= 0; n -= 1 {
		a.digits[a.count] = buf[n]
		a.count += 1
	}
	a.decimal_point = a.count
	trim(a)
}
/*
Shifts the Decimal value to the right by k positions. 

**Used for internal Decimal Operations.**

**Inputs**  
- a: The Decimal struct to be shifted
- k: The number of positions to shift right
*/
shift_right :: proc(a: ^Decimal, k: uint) {
	r := 0 // read index
	w := 0 // write index

	n: uint
	for ; n>>k == 0; r += 1 {
		if r >= a.count {
			if n == 0 {
				// Just in case
				a.count = 0
				return
			}
			for n>>k == 0 {
				n = n * 10
				r += 1
			}
			break
		}
		c := uint(a.digits[r])
		n = n*10 + c - '0'
	}
	a.decimal_point -= r-1

	mask: uint = (1<<k) - 1

	for ; r < a.count; r += 1 {
		c := uint(a.digits[r])
		dig := n>>k
		n &= mask
		a.digits[w] = byte('0' + dig)
		w += 1
		n = n*10 + c - '0'
	}

	for n > 0 {
		dig := n>>k
		n &= mask
		if w < len(a.digits) {
			a.digits[w] = byte('0' + dig)
			w += 1
		} else if dig > 0 {
			a.trunc = true
		}
		n *= 10
	}


	a.count = w
	trim(a)
}

import "base:runtime"
println :: proc(args: ..any) {
	for arg, i in args {
		if i != 0 {
			runtime.print_string(" ")
		}
		switch v in arg {
		case string:  runtime.print_string(v)
		case rune:    runtime.print_rune(v)
		case int:     runtime.print_int(v)
		case uint:    runtime.print_uint(v)
		case u8:      runtime.print_u64(u64(v))
		case u16:     runtime.print_u64(u64(v))
		case u32:     runtime.print_u64(u64(v))
		case u64:     runtime.print_u64(v)
		case i8:      runtime.print_i64(i64(v))
		case i16:     runtime.print_i64(i64(v))
		case i32:     runtime.print_i64(i64(v))
		case i64:     runtime.print_i64(v)
		case uintptr: runtime.print_uintptr(v)
		case bool:    runtime.print_string("true" if v else "false")
		}
	}
	runtime.print_string("\n")
}

@(private="file")
_shift_left_offsets := [?]struct{delta: int, cutoff: string}{
	{ 0, ""},
	{ 1, "5"},
	{ 1, "25"},
	{ 1, "125"},
	{ 2, "625"},
	{ 2, "3125"},
	{ 2, "15625"},
	{ 3, "78125"},
	{ 3, "390625"},
	{ 3, "1953125"},
	{ 4, "9765625"},
	{ 4, "48828125"},
	{ 4, "244140625"},
	{ 4, "1220703125"},
	{ 5, "6103515625"},
	{ 5, "30517578125"},
	{ 5, "152587890625"},
	{ 6, "762939453125"},
	{ 6, "3814697265625"},
	{ 6, "19073486328125"},
	{ 7, "95367431640625"},
	{ 7, "476837158203125"},
	{ 7, "2384185791015625"},
	{ 7, "11920928955078125"},
	{ 8, "59604644775390625"},
	{ 8, "298023223876953125"},
	{ 8, "1490116119384765625"},
	{ 9, "7450580596923828125"},
	{ 9, "37252902984619140625"},
	{ 9, "186264514923095703125"},
	{10, "931322574615478515625"},
	{10, "4656612873077392578125"},
	{10, "23283064365386962890625"},
	{10, "116415321826934814453125"},
	{11, "582076609134674072265625"},
	{11, "2910383045673370361328125"},
	{11, "14551915228366851806640625"},
	{12, "72759576141834259033203125"},
	{12, "363797880709171295166015625"},
	{12, "1818989403545856475830078125"},
	{13, "9094947017729282379150390625"},
	{13, "45474735088646411895751953125"},
	{13, "227373675443232059478759765625"},
	{13, "1136868377216160297393798828125"},
	{14, "5684341886080801486968994140625"},
	{14, "28421709430404007434844970703125"},
	{14, "142108547152020037174224853515625"},
	{15, "710542735760100185871124267578125"},
	{15, "3552713678800500929355621337890625"},
	{15, "17763568394002504646778106689453125"},
	{16, "88817841970012523233890533447265625"},
	{16, "444089209850062616169452667236328125"},
	{16, "2220446049250313080847263336181640625"},
	{16, "11102230246251565404236316680908203125"},
	{17, "55511151231257827021181583404541015625"},
	{17, "277555756156289135105907917022705078125"},
	{17, "1387778780781445675529539585113525390625"},
	{18, "6938893903907228377647697925567626953125"},
	{18, "34694469519536141888238489627838134765625"},
	{18, "173472347597680709441192448139190673828125"},
	{19, "867361737988403547205962240695953369140625"},
}
/*
Shifts the decimal of the input value to the left by `k` places

WARNING: asserts `k < 61`

**Inputs**  
- a: The Decimal to be modified
- k: The number of places to shift the decimal to the left
*/
shift_left :: proc(a: ^Decimal, k: uint) #no_bounds_check {
	prefix_less :: #force_inline proc "contextless" (b: []byte, s: string) -> bool #no_bounds_check {
		for i in 0..<len(s) {
			if i >= len(b) {
				return true
			}
			if b[i] != s[i] {
				return b[i] < s[i]
			}
		}
		return false
	}

	assert(k < 61)

	delta := _shift_left_offsets[k].delta
	if prefix_less(a.digits[:a.count], _shift_left_offsets[k].cutoff) {
		delta -= 1
	}

	read_index  := a.count
	write_index := a.count+delta

	n: uint
	for read_index -= 1; read_index >= 0; read_index -= 1 {
		n += (uint(a.digits[read_index]) - '0') << k
		quo := n/10
		rem := n - 10*quo
		write_index -= 1
		if write_index < len(a.digits) {
			a.digits[write_index] = byte('0' + rem)
		} else if rem != 0 {
			a.trunc = true
		}
		n = quo
	}

	for n > 0 {
		quo := n/10
		rem := n - 10*quo
		write_index -= 1
		if write_index < len(a.digits) {
			a.digits[write_index] = byte('0' + rem)
		} else if rem != 0 {
			a.trunc = true
		}
		n = quo
	}

	a.decimal_point += delta

	a.count = clamp(a.count+delta, 0, len(a.digits))
	trim(a)
}
/*
Shifts the decimal of the input value by the specified number of places

**Inputs**  
- a: The Decimal to be modified
- i: The number of places to shift the decimal (positive for left shift, negative for right shift)
*/
shift :: proc(a: ^Decimal, i: int) {
	uint_size :: 8*size_of(uint)
	max_shift :: uint_size-4

	switch k := i; {
	case a.count == 0:
		// no need to update
	case k > 0:
		for k > max_shift {
			shift_left(a, max_shift)
			k -= max_shift
		}
		shift_left(a, uint(k))


	case k < 0:
		for k < -max_shift {
			shift_right(a, max_shift)
			k += max_shift
		}
		shift_right(a, uint(-k))
	}
}
/*
Determines if the Decimal can be rounded up at the given digit index

**Inputs**  
- a: The Decimal to check
- nd: The digit index to consider for rounding up

**Returns**   Boolean if can be rounded up at the given index (>=5)
*/
can_round_up :: proc(a: ^Decimal, nd: int) -> bool {
	if nd < 0 || nd >= a.count { return false  }
	if a.digits[nd] == '5' && nd+1 == a.count {
		if a.trunc {
			return true
		}
		return nd > 0 && (a.digits[nd-1]-'0')%2 != 0
	}

	return a.digits[nd] >= '5'
}
/*
Rounds the Decimal at the given digit index

**Inputs**  
- a: The Decimal to be modified
- nd: The digit index to round
*/
round :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return }
	if can_round_up(a, nd) {
		round_up(a, nd)
	} else {
		round_down(a, nd)
	}
}
/*
Rounds the Decimal up at the given digit index

**Inputs**  
- a: The Decimal to be modified
- nd: The digit index to round up
*/
round_up :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return }

	for i := nd-1; i >= 0; i -= 1 {
		if c := a.digits[i]; c < '9' {
			a.digits[i] += 1
			a.count = i+1
			return
		}
	}

	// Number is just 9s
	a.digits[0] = '1'
	a.count = 1
	a.decimal_point += 1
}
/*
Rounds down the decimal value to the specified number of decimal places

**Inputs**  
- a: The Decimal value to be rounded down
- nd: The number of decimal places to round down to

Example:

	import "core:fmt"
	import "core:strconv/decimal"
	round_down_example :: proc() {
		d: decimal.Decimal
		str := [64]u8{}
		ok := decimal.set(&d, "123.456")
		decimal.round_down(&d, 5)
		fmt.println(decimal.decimal_to_string(str[:], &d))
	}

Output:

	123.45

*/
round_down :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return }
	a.count = nd
	trim(a)
}
/*
Extracts the rounded integer part of a decimal value

**Inputs**  
- a: A pointer to the Decimal value to extract the rounded integer part from

WARNING: There are no guarantees about overflow.

**Returns**   The rounded integer part of the input decimal value

Example:

	import "core:fmt"
	import "core:strconv/decimal"
	rounded_integer_example :: proc() {
		d: decimal.Decimal
		ok := decimal.set(&d, "123.456")
		fmt.println(decimal.rounded_integer(&d))
	}

Output:

	123

*/
rounded_integer :: proc(a: ^Decimal) -> u64 {
	if a.decimal_point > 20 {
		return 0xffff_ffff_ffff_ffff
	}
	i: int = 0
	n: u64 = 0
	m := min(a.decimal_point, a.count)
	for ; i < m; i += 1 {
		n = n*10 + u64(a.digits[i]-'0')
	}
	for ; i < a.decimal_point; i += 1 {
		n *= 10
	}
	if can_round_up(a, a.decimal_point) {
		n += 1
	}
	return n
}
