package strconv

import "base:intrinsics"

Int_Flag :: enum {
	// Prefixes the integer depending on the base:
	// - `0b`: base 2
	// - `0o`: base 8
	// - `0z`: base 12
	// - `0x`: base 16
	//
	// NOTE: A base 10 integer receives no prefix, even if this flag is specified.
	Prefix,

	// Prepend a `+` sign before positive integers.
	Plus,
}
Int_Flags :: bit_set[Int_Flag]

MAX_BASE :: 32
digits := "0123456789abcdefghijklmnopqrstuvwxyz"

/*
Determines whether the given unsigned 64-bit integer is a negative value by interpreting it as a signed integer with the specified bit size.

**Inputs**
- x: The unsigned 64-bit integer to check for negativity
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, or 64)

**Returns**
- u: The absolute value of the input integer
- neg: A boolean indicating whether the input integer is negative
*/
is_integer_negative :: proc(x: u64, is_signed: bool, bit_size: int) -> (u: u64, neg: bool) {
	u = x
	if is_signed {
		switch bit_size {
		case 8:
			i := i8(u)
			neg = i < 0
			u = u64(abs(i64(i)))
		case 16:
			i := i16(u)
			neg = i < 0
			u = u64(abs(i64(i)))
		case 32:
			i := i32(u)
			neg = i < 0
			u = u64(abs(i64(i)))
		case 64:
			i := i64(u)
			neg = i < 0
			u = u64(abs(i))
		case:
			panic("is_integer_negative: Unknown integer size")
		}
	}
	return
}
/*
Writes the string representation of an integer to a buffer with specified base, flags, and digit set.

**Inputs**
- buf: The buffer to append the integer representation to
- x: The integer value to convert
- base: The base for the integer representation (2 <= base <= MAX_BASE)
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, or 64)
- digits: The digit set used for the integer representation
- flags: The Int_Flags bit set to control integer formatting

**Returns**
- The string containing the integer representation appended to the buffer
*/
write_bits :: proc(buf: []byte, x: u64, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to write_bits")
	}

	a: [129]byte = ---
	u, neg := is_integer_negative(x, is_signed, bit_size)
	i := _write_digits(a[:], u, base, digits)

	if .Prefix in flags {
		ok := true
		switch base {
		case  2: i-=1; a[i] = 'b'
		case  8: i-=1; a[i] = 'o'
		// case 10: i-=1; a[i] = 'd';
		case 12: i-=1; a[i] = 'z'
		case 16: i-=1; a[i] = 'x'
		case: ok = false
		}
		if ok {
			i-=1; a[i] = '0'
		}
	}

	switch {
	case neg:
		i-=1; a[i] = '-'
	case .Plus in flags:
		i-=1; a[i] = '+'
	}

	out := a[i:]
	copy(buf, out)
	return string(buf[0:len(out)])
}
/*
Determines whether the given unsigned 128-bit integer is a negative value by interpreting it as a signed integer with the specified bit size.

**Inputs**
- x: The unsigned 128-bit integer to check for negativity
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, 64, or 128)

**Returns**
- u: The absolute value of the input integer
- neg: A boolean indicating whether the input integer is negative
*/
is_integer_negative_128 :: proc(x: u128, is_signed: bool, bit_size: int) -> (u: u128, neg: bool) {
	u = x
	if is_signed {
		switch bit_size {
		case 8:
			i := i8(u)
			neg = i < 0
			u = u128(abs(i128(i)))
		case 16:
			i := i16(u)
			neg = i < 0
			u = u128(abs(i128(i)))
		case 32:
			i := i32(u)
			neg = i < 0
			u = u128(abs(i128(i)))
		case 64:
			i := i64(u)
			neg = i < 0
			u = u128(abs(i128(i)))
		case 128:
			i := i128(u)
			neg = i < 0
			u = u128(abs(i))
		case:
			panic("is_integer_negative: Unknown integer size")
		}
	}
	return
}
/*
Writes the string representation of a 128-bit integer to a buffer with specified base, flags, and digit set.

**Inputs**
- buf: The buffer to append the integer representation to
- x: The 128-bit integer value to convert
- base: The base for the integer representation (2 <= base <= MAX_BASE)
- is_signed: A boolean indicating if the input should be treated as a signed integer
- bit_size: The bit size of the signed integer representation (8, 16, 32, 64, or 128)
- digits: The digit set used for the integer representation
- flags: The Int_Flags bit set to control integer formatting

**Returns**
- The string containing the integer representation written to the buffer
*/
write_bits_128 :: proc(buf: []byte, x: u128, base: int, is_signed: bool, bit_size: int, digits: string, flags: Int_Flags) -> string {
	if base < 2 || base > MAX_BASE {
		panic("strconv: illegal base passed to write_bits")
	}

	a: [140]byte = ---
	u, neg := is_integer_negative_128(x, is_signed, bit_size)
	i := _write_digits_128(a[:], u, base, digits)

	if .Prefix in flags {
		ok := true
		switch base {
		case  2: i-=1; a[i] = 'b'
		case  8: i-=1; a[i] = 'o'
		case 10: i-=1; a[i] = 'd'
		case 12: i-=1; a[i] = 'z'
		case 16: i-=1; a[i] = 'x'
		case: ok = false
		}
		if ok {
			i-=1; a[i] = '0'
		}
	}

	switch {
	case neg:
		i-=1; a[i] = '-'
	case .Plus in flags:
		i-=1; a[i] = '+'
	}

	out := a[i:]
	copy(buf, out)
	return string(buf[0:len(out)])
}

@(private, require_results)
_write_digits :: proc(a: []byte, u: u64, base: int, digits: string) -> (i: int) {
	i = len(a)
	u := u
	b := u64(base)
	if !(2 <= base && base <= len(digits) && 64 <= len(a)) {
		for {
			i -= 1
			a[i] = digits[u % b]
			u /= b
			if u == 0 {
				return
			}
		}
	}

	#no_bounds_check switch {
	case base == 10:
		// NOTE(bill): Two digits per step. Dividing by a constant compiles to a multiply.
		for u >= 100 {
			r := u % 100
			u /= 100
			i -= 2
			a[i]   = digits[r / 10]
			a[i+1] = digits[r % 10]
		}
		if u >= 10 {
			i -= 2
			a[i]   = digits[u / 10]
			a[i+1] = digits[u % 10]
			return
		}
	case base & (base-1) == 0:
		shift := uint(intrinsics.count_trailing_zeros(base))
		for u >= b {
			i -= 1
			a[i] = digits[u & (b-1)]
			u >>= shift
		}
	case:
		for u >= b {
			i -= 1
			a[i] = digits[u % b]
			u /= b
		}
	}
	i -= 1
	#no_bounds_check a[i] = digits[u]
	return
}

// Writes the digits of `u` to the end of `a` and returns the index of the first digit.
@(private, require_results)
_write_digits_128 :: proc(a: []byte, u: u128, base: int, digits: string) -> (i: int) {
	i = len(a)
	u := u
	b := u128(base)
	if !(2 <= base && base <= len(digits) && 128 <= len(a)) {
		for {
			i -= 1
			a[i] = digits[u64(u % b)]
			u /= b
			if u == 0 {
				return
			}
		}
	}

	#no_bounds_check if base == 10 {
		// NOTE(bill): One 128-bit division per 19 digits rather than one per digit
		TEN_19 :: 10_000_000_000_000_000_000
		for u > u128(max(u64)) {
			q := u / TEN_19
			r := u64(u - q*TEN_19)
			u = q
			for _ in 0..<9 {
				d := r % 100
				r /= 100
				i -= 2
				a[i]   = digits[d / 10]
				a[i+1] = digits[d % 10]
			}
			i -= 1
			a[i] = digits[r]
		}
	}
	if u <= u128(max(u64)) {
		return _write_digits(a[:i], u64(u), base, digits)
	}
	#no_bounds_check if base & (base-1) == 0 {
		shift := uint(intrinsics.count_trailing_zeros(base))
		for u >= b {
			i -= 1
			a[i] = digits[u64(u & (b-1))]
			u >>= shift
		}
	} else {
		for u >= b {
			i -= 1
			a[i] = digits[u64(u % b)]
			u /= b
		}
	}
	i -= 1
	#no_bounds_check a[i] = digits[u64(u)]
	return
}
