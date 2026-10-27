#+private
package diff

import "base:intrinsics"

/*
	Interning gives every token of `a`, then `b`, a dense ID in order of first appearance. The algorithms then
	only ever compare `i32`s. An open-addressing hash table in the scratch buffer finds equal tokens.
	The algorithm reuses that space once interning is done.
*/

// An empty slot has `token == 0`. Otherwise `token - 1` indexes the first token seen with this value.
Intern_Slot :: struct {
	token: i32,
	hash:  u32,
}

// The table is a power of two, at least twice the number of tokens. It stays at most half full.
@(require_results)
intern_table_len :: proc "contextless" (tokens: int) -> int {
	size := 2
	for size < 2*tokens {
		size <<= 1
	}
	return size
}

@(require_results)
intern_scratch_size :: proc "contextless" (tokens: int) -> int {
	return scratch_bytes(Intern_Slot, intern_table_len(tokens))
}

// One string's tokens, without a slice of them. `starts` holds where each token starts, then the string's length.
Text_Tokens :: struct {
	text:   string,
	starts: []i32,
}

@(require_results)
slice_tokens_len :: #force_inline proc "contextless" (s: []$T) -> int {
	return len(s)
}

@(require_results)
text_tokens_len :: #force_inline proc "contextless" (s: Text_Tokens) -> int {
	return len(s.starts) - 1
}

@(require_results)
slice_token_at :: #force_inline proc "contextless" (s: []$T, k: int) -> T {
	return s[k]
}

@(require_results)
text_token_at :: #force_inline proc "contextless" (s: Text_Tokens, k: int) -> string {
	return s.text[s.starts[k]:s.starts[k+1]]
}

tokens_len :: proc{
	slice_tokens_len,
	text_tokens_len,
}

token_at :: proc{
	slice_token_at,
	text_token_at,
}

// Fills `ids` with the ID of each token of `a`, then of `b`, and returns how many distinct IDs there are.
@(require_results)
intern :: proc(
	a, b:      $S, // `[]T` or `Text_Tokens`
	$T:        typeid,
	equal:     proc(x, y: T, user_data: rawptr) -> bool,
	hash:      proc(x: T,    user_data: rawptr) -> u64,
	user_data: rawptr,
	ids:       []i32,
	table:     []Intern_Slot,
) -> (id_count: int) {
	// Token `k` of `a`, then of `b`, where `a` has `n`
	@(require_results)
	token :: #force_inline proc "contextless" (a, b: S, n, k: int) -> T {
		if k < n {
			return token_at(a, k)
		}
		return token_at(b, k - n)
	}


	for &slot in table {
		slot = {}
	}

	// Fibonacci hashing: the top bits of the product pick the slot
	shift := 64 - uint(intrinsics.count_trailing_zeros(u64(len(table))))
	mask  := len(table) - 1

	n := tokens_len(a)
	for k in 0..<n + tokens_len(b) {
		x   := token(a, b, n, k)
		h   := hash(x, user_data)
		pos := int((h * 0x9e3779b97f4a7c15) >> shift)
		tag := u32(h)

		for {
			slot := &table[pos]
			if slot.token == 0 {
				slot^ = {token = i32(k + 1), hash = tag}
				ids[k] = i32(id_count)
				id_count += 1
				break
			}

			if slot.hash == tag {
				first := int(slot.token - 1)
				if equal(x, token(a, b, n, first), user_data) {
					ids[k] = ids[first]
					break
				}
			}
			pos = (pos + 1) & mask
		}
	}
	return
}
