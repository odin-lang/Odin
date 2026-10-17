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

// The tokens of `a` then `b` as one sequence.
Slice_Source :: struct($T: typeid) {
	a, b: []T,
}

// The tokens of two strings, without a slice of them. Each `starts` holds where every token starts, then the length.
Text_Source :: struct {
	a, b:               string,
	a_starts, b_starts: []i32,
}

@(require_results)
slice_source_len :: #force_inline proc "contextless" (src: Slice_Source($T)) -> int {
	return len(src.a) + len(src.b)
}

@(require_results)
slice_source_token :: #force_inline proc "contextless" (src: Slice_Source($T), k: int) -> T {
	return k < len(src.a) ? src.a[k] : src.b[k - len(src.a)]
}

@(require_results)
text_source_len :: #force_inline proc "contextless" (src: Text_Source) -> int {
	return len(src.a_starts) - 1 + len(src.b_starts) - 1
}

@(require_results)
text_source_token :: #force_inline proc "contextless" (src: Text_Source, k: int) -> string {
	n := len(src.a_starts) - 1
	if k < n {
		return src.a[src.a_starts[k]:src.a_starts[k + 1]]
	}
	return src.b[src.b_starts[k - n]:src.b_starts[k - n + 1]]
}

source_len :: proc{slice_source_len, text_source_len}

source_token :: proc{slice_source_token, text_source_token}

// Fills `ids` with the ID of each token of `src`, and returns how many distinct IDs there are.
@(require_results)
intern :: proc(
	src:       $S,
	$T:        typeid,
	equal:     proc(x, y: T, user_data: rawptr) -> bool,
	hash:      proc(x: T, user_data: rawptr) -> u64,
	user_data: rawptr,
	ids:       []i32,
	table:     []Intern_Slot,
) -> (id_count: int) {

	for &slot in table {
		slot = {}
	}

	// Fibonacci hashing: the top bits of the product pick the slot
	shift := 64 - uint(intrinsics.count_trailing_zeros(u64(len(table))))
	mask  := len(table) - 1

	for k in 0..<source_len(src) {
		x   := source_token(src, k)
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
				if equal(x, source_token(src, first), user_data) {
					ids[k] = ids[first]
					break
				}
			}
			pos = (pos + 1) & mask
		}
	}
	return
}
