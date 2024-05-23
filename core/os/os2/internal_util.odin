//+private
package os2

import "base:intrinsics"
import "base:runtime"


// Splits pattern by the last wildcard "*", if it exists, and returns the prefix and suffix
// parts which are split by the last "*"
@(require_results)
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

@(require_results)
clone_string :: proc(s: string, allocator: runtime.Allocator) -> (res: string, err: runtime.Allocator_Error) {
	buf := make([]byte, len(s), allocator) or_return
	copy(buf, s)
	return string(buf), nil
}


@(require_results)
clone_to_cstring :: proc(s: string, allocator: runtime.Allocator) -> (res: cstring, err: runtime.Allocator_Error) {
	res = "" // do not use a `nil` cstring
	buf := make([]byte, len(s)+1, allocator) or_return
	copy(buf, s)
	buf[len(s)] = 0
	return cstring(&buf[0]), nil
}

@(require_results)
temp_cstring :: proc(s: string) -> (cstring, runtime.Allocator_Error) {
	return clone_to_cstring(s, temp_allocator())
}

@(require_results)
string_from_null_terminated_bytes :: proc(b: []byte) -> (res: string) {
	s := string(b)
	i := 0
	for ; i < len(s); i += 1 {
		if s[i] == 0 {
			break
		}
	}
	return s[:i]
}

@(require_results)
concatenate_strings_from_buffer :: proc(buf: []byte, strings: ..string) -> string {
	n := 0
	for s in strings {
		(n < len(buf)) or_break
		n += copy(buf[n:], s)
	}
	n = min(len(buf), n)
	return string(buf[:n])
}

@(require_results)
concatenate :: proc(strings: []string, allocator: runtime.Allocator) -> (res: string, err: runtime.Allocator_Error) {
	n := 0
	for s in strings {
		n += len(s)
	}
	buf := make([]byte, n) or_return
	n = 0
	for s in strings {
		n += copy(buf[n:], s)
	}
	return string(buf), nil
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

@(require_results)
next_random :: proc(r: ^[2]u64) -> u64 {
	old_state := r[0]
	r[0] = old_state * 6364136223846793005 + (r[1]|1)
	xor_shifted := (((old_state >> 59) + 5) ~ old_state) * 12605985483714917081
	rot := (old_state >> 59)
	return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 63))
}

@(require_results)
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
