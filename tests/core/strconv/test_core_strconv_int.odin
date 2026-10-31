package test_core_strconv

import "core:strconv"
import "core:testing"

// `write_bits` and `write_bits_128` have fast paths for base 10 and powers of two.
// These references are the plain digit loops they had before, and both must agree for every base.

@(private="file")
ref_write_bits :: proc(buf: []byte, x: u64, base: int, is_signed: bool, bit_size: int, digits: string, flags: strconv.Int_Flags) -> string {
	a: [129]byte
	i := len(a)
	u, neg := strconv.is_integer_negative(x, is_signed, bit_size)
	b := u64(base)
	for u >= b {
		i -= 1; a[i] = digits[u % b]
		u /= b
	}
	i -= 1; a[i] = digits[u % b]

	if .Prefix in flags {
		ok := true
		switch base {
		case  2: i -= 1; a[i] = 'b'
		case  8: i -= 1; a[i] = 'o'
		case 12: i -= 1; a[i] = 'z'
		case 16: i -= 1; a[i] = 'x'
		case: ok = false
		}
		if ok {
			i -= 1; a[i] = '0'
		}
	}
	switch {
	case neg:            i -= 1; a[i] = '-'
	case .Plus in flags: i -= 1; a[i] = '+'
	}

	out := a[i:]
	copy(buf, out)
	return string(buf[:len(out)])
}

@(private="file")
ref_write_bits_128 :: proc(buf: []byte, x: u128, base: int, is_signed: bool, bit_size: int, digits: string, flags: strconv.Int_Flags) -> string {
	a: [140]byte
	i := len(a)
	u, neg := strconv.is_integer_negative_128(x, is_signed, bit_size)
	b := u128(base)
	for u >= b {
		i -= 1; a[i] = digits[u64(u % b)]
		u /= b
	}
	i -= 1; a[i] = digits[u64(u % b)]

	if .Prefix in flags {
		ok := true
		switch base {
		case  2: i -= 1; a[i] = 'b'
		case  8: i -= 1; a[i] = 'o'
		case 10: i -= 1; a[i] = 'd'
		case 12: i -= 1; a[i] = 'z'
		case 16: i -= 1; a[i] = 'x'
		case: ok = false
		}
		if ok {
			i -= 1; a[i] = '0'
		}
	}
	switch {
	case neg:            i -= 1; a[i] = '-'
	case .Plus in flags: i -= 1; a[i] = '+'
	}

	out := a[i:]
	copy(buf, out)
	return string(buf[:len(out)])
}

@(private="file")
DIGIT_SETS := [?]string{
	"0123456789abcdefghijklmnopqrstuvwxyz",
	"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	"zyxwvutsrqponmlkjihgfedcba9876543210",
}

@(private="file")
FLAG_SETS := [?]strconv.Int_Flags{{}, {.Prefix}, {.Plus}, {.Prefix, .Plus}}

@(private="file")
FLAG_VALUES := [?]u64{0, 1, 7, 10, 99, 100, 255, 1 << 31, max(u64) - 1, max(u64)}

@(private="file")
Signedness :: struct {
	is_signed: bool,
	bit_size:  int,
}

@(private="file")
next_random :: proc(state: ^u64) -> u64 {
	// xorshift64*
	x := state^
	x ~= x >> 12
	x ~= x << 25
	x ~= x >> 27
	state^ = x
	return x * 0x2545F4914F6CDD1D
}

// Small numbers, powers of every base and their neighbours, and the limits of every size
@(private="file")
edge_values_u64 :: proc(values: ^[dynamic]u64) {
	for v in u64(0)..=300 {
		append(values, v)
	}
	for base in u64(2)..=32 {
		for p := base; ; p *= base {
			append(values, p-1, p, p+1)
			if p > max(u64)/base {
				break
			}
		}
	}
	for bits in ([]uint{8, 16, 32, 63, 64}) {
		m := max(u64) >> (64 - bits)
		append(values, m-1, m, m+1, ~m, ~m + 1)
	}
}

@(private="file")
check_u64 :: proc(t: ^testing.T, failures: ^int, v: u64, base: int, s: Signedness, digits: string, flags: strconv.Int_Flags) -> bool {
	buf, ref_buf: [140]byte
	got  := strconv.write_bits(buf[:], v, base, s.is_signed, s.bit_size, digits, flags)
	want := ref_write_bits(ref_buf[:], v, base, s.is_signed, s.bit_size, digits, flags)
	if got != want {
		testing.expectf(t, false, "write_bits(%v, base=%v, signed=%v, bits=%v, digits=%q, flags=%v) = %q, want %q", v, base, s.is_signed, s.bit_size, digits, flags, got, want)
		failures^ += 1
	}
	return failures^ < 10
}

@(private="file")
check_u128 :: proc(t: ^testing.T, failures: ^int, v: u128, base: int, s: Signedness, digits: string, flags: strconv.Int_Flags) -> bool {
	buf, ref_buf: [140]byte
	got  := strconv.write_bits_128(buf[:], v, base, s.is_signed, s.bit_size, digits, flags)
	want := ref_write_bits_128(ref_buf[:], v, base, s.is_signed, s.bit_size, digits, flags)
	if got != want {
		testing.expectf(t, false, "write_bits_128(%v, base=%v, signed=%v, bits=%v, digits=%q, flags=%v) = %q, want %q", v, base, s.is_signed, s.bit_size, digits, flags, got, want)
		failures^ += 1
	}
	return failures^ < 10
}

@(test)
test_write_bits_matches_reference :: proc(t: ^testing.T) {
	values: [dynamic]u64
	defer delete(values)
	edge_values_u64(&values)
	edge_count := len(values)

	state := u64(0x9E3779B97F4A7C15)
	for _ in 0..<1000 {
		r := next_random(&state)
		append(&values, r >> (next_random(&state) % 64))
	}

	signedness := [?]Signedness{{false, 64}, {true, 8}, {true, 16}, {true, 32}, {true, 64}}
	failures := 0

	for v in values {
		for base in 2..=32 {
			for s in signedness {
				if !check_u64(t, &failures, v, base, s, DIGIT_SETS[0], {}) { return }
			}
		}
	}
	for v in values[:edge_count] {
		for base in 2..=32 {
			for digits in DIGIT_SETS[1:] {
				if !check_u64(t, &failures, v, base, {false, 64}, digits, {}) { return }
			}
		}
	}
	for v in FLAG_VALUES {
		for base in 2..=32 {
			for s in signedness {
				for flags in FLAG_SETS {
					if !check_u64(t, &failures, v, base, s, DIGIT_SETS[0], flags) { return }
				}
			}
		}
	}
}

@(test)
test_write_bits_128_matches_reference :: proc(t: ^testing.T) {
	values: [dynamic]u128
	defer delete(values)

	small: [dynamic]u64
	defer delete(small)
	edge_values_u64(&small)
	for v in small {
		append(&values, u128(v))
	}
	for base in u128(2)..=32 {
		for p := base; ; p *= base {
			append(&values, p-1, p, p+1)
			if p > max(u128)/base {
				break
			}
		}
	}
	for bits in ([]uint{64, 65, 127, 128}) {
		m := max(u128) >> (128 - bits)
		append(&values, m-1, m, m+1, ~m, ~m + 1)
	}

	state := u64(0xD1B54A32D192ED03)
	for _ in 0..<1000 {
		r := u128(next_random(&state)) << 64 | u128(next_random(&state))
		append(&values, r >> (next_random(&state) % 128))
	}

	signedness := [?]Signedness{{false, 128}, {true, 64}, {true, 128}}
	failures := 0

	for v in values {
		for base in 2..=32 {
			for s in signedness {
				if !check_u128(t, &failures, v, base, s, DIGIT_SETS[0], {}) { return }
			}
		}
	}
	for v in values[:200] {
		for base in 2..=32 {
			for digits in DIGIT_SETS[1:] {
				if !check_u128(t, &failures, max(u128) - v, base, {false, 128}, digits, {}) { return }
			}
		}
	}
	for v in FLAG_VALUES {
		for base in 2..=32 {
			for s in signedness {
				for flags in FLAG_SETS {
					if !check_u128(t, &failures, u128(v), base, s, DIGIT_SETS[0], flags) { return }
					if !check_u128(t, &failures, max(u128) - u128(v), base, s, DIGIT_SETS[0], flags) { return }
				}
			}
		}
	}
}
