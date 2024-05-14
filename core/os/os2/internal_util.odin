//+private
package os2

import "base:intrinsics"
import "base:runtime"


// Splits pattern by the last wildcard "*", if it exists, and returns the prefix and suffix
// parts which are split by the last "*"
_prefix_and_suffix :: proc(pattern: string) -> (prefix, suffix: string, err: Error) {
	for i in 0..<len(pattern) {
		if is_path_separator(pattern[i]) {
			err = .Pattern_Has_Separator
			return
		}
	}
	prefix = pattern
	for i := len(pattern)-1; i >= 0; i -= 1 {
		if pattern[i] == '*' {
			prefix, suffix = pattern[:i], pattern[i+1:]
			break
		}
	}
	return
}

clone_string :: proc(s: string, allocator: runtime.Allocator) -> string {
	buf := make([]byte, len(s), allocator)
	copy(buf, s)
	return string(buf)
}


concatenate_strings_from_buffer :: proc(buf: []byte, strings: ..string) -> string {
	n := 0
	for s in strings {
		(n < len(buf)) or_break
		n += copy(buf[n:], s)
	}
	n = min(len(buf), n)
	return string(buf[:n])
}



@(private="file")
random_string_seed: [2]u64

@(init, private="file")
init_random_string_seed :: proc() {
	seed := u64(intrinsics.read_cycle_counter())
	s := &random_string_seed
	s[0] = 0
	s[1] = (seed << 1) | 1
	_ = next_random(s)
	s[1] += seed
	_ = next_random(s)
}

next_random :: proc(r: ^[2]u64) -> u64 {
	old_state := r[0]
	r[0] = old_state * 6364136223846793005 + (r[1]|1)
	xor_shifted := (((old_state >> 59) + 5) ~ old_state) * 12605985483714917081
	rot := (old_state >> 59)
	return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 63))
}

random_string :: proc(buf: []byte) -> string {
	@static digits := "0123456789"

	u := next_random(&random_string_seed)

	b :: 10
	i := len(buf)
	for u >= b {
		i -= 1
		buf[i] = digits[u % b]
		u /= b
	}
	i -= 1
	buf[i] = digits[u % b]
	return string(buf[i:])
}
