package compress_pkzip_legacy

import "base:intrinsics"
import "base:runtime"
import "core:compress"

unshrink :: proc{unshrink_from_bytes, unshrink_from_context}

unshrink_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return unshrink_from_context(&ctx, expected_output_size, options, allocator)
}

unshrink_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}

	expected := output_limit(z, expected_output_size, options, compress.SHRINK_EXPANSION_MAX, size_of(Unshrink) + size_of(Unshrink_Cache)) or_return
	if expected == 0 {
		return nil
	}

	start := len(z.output)
	defer z.bytes_written = i64(len(z.output) - start)

	p: Output_Progress
	progress_begin(&p, z, expected, options)

	raw := runtime.mem_alloc_non_zeroed(size_of(Unshrink), align_of(Unshrink)) or_return
	s   := (^Unshrink)(raw_data(raw))
	defer free(s)
	unshrink_init(s)

	cache_raw := runtime.mem_alloc_non_zeroed(size_of(Unshrink_Cache), align_of(Unshrink_Cache)) or_return
	c         := (^Unshrink_Cache)(raw_data(cache_raw))
	defer free(c)
	c.length = {}

	code_size := uint(SHRINK_MIN_CODE_SIZE)
	next_free := SHRINK_FIRST_FREE_CODE

	b := Bits{z.code_buffer, z.num_bits}
	defer {
		z.code_buffer = b.buffer
		z.num_bits    = b.count
	}

	o := out_load(z)
	defer out_store(z, &o)

	previous, available := unshrink_read_code_bits(z, &p.pulled, &b, s, &code_size, &next_free) or_return
	if available {
		if previous > 255 {
			return PKZIP_Legacy_Error.Invalid_First_Code
		}
		out_literal(z, &o, start, expected, u8(previous)) or_return
	}
	first_byte      := u8(previous)
	previous_at     := start
	previous_length := 1

	for available && o.at - start < expected {
		if o.at - start >= p.mark {
			progress_report(&p, z, o.at - start, b.count) or_return
		}
		code: int
		code, available = unshrink_read_code_bits(z, &p.pulled, &b, s, &code_size, &next_free) or_return
		if !available {
			break
		}

		at     := o.at
		length := int(c.length[code])
		cached := length > 0 && s.used[code]
		sp     := len(s.stack)
		if cached {
			first_byte = o.data[c.position[code]]
		} else {
			current     := code
			substituted := false
			for current > 255 {
				if current == SHRINK_CONTROL_CODE {
					return PKZIP_Legacy_Error.Invalid_Code
				}
				if !s.used[current] {
					if current != next_free || substituted || sp <= 1 {
						return PKZIP_Legacy_Error.Invalid_Code
					}
					substituted = true
					sp -= 1
					s.stack[sp] = first_byte
					current = previous
					continue
				}
				if sp <= 1 || int(s.parent[current]) == current {
					return PKZIP_Legacy_Error.Invalid_Code
				}
				sp -= 1
				s.stack[sp] = s.value[current]
				current = int(s.parent[current])
			}
			sp -= 1
			s.stack[sp] = u8(current)
			first_byte  = u8(current)
			length      = len(s.stack) - sp
		}

		if next_free < SHRINK_TABLE_SIZE {
			parent_used := s.used[previous]
			unshrink_add(s, next_free, previous, first_byte)
			c.length[next_free]   = u16(previous_length + 1) if parent_used else 0
			c.position[next_free] = previous_at
			next_free = unshrink_next_free(s, next_free + 1)
		}

		if cached {
			out_match(z, &o, start, expected, at - c.position[code], length) or_return
		} else {
			out_bytes(z, &o, start, expected, s.stack[sp:]) or_return
		}
		if code > 255 {
			c.length[code]   = u16(length)
			c.position[code] = at
		}
		previous        = code
		previous_at     = at
		previous_length = length
	}

	if o.at - start != expected {
		return General_Error.Stream_Too_Short
	}
	if o.at - start >= p.mark {
		return progress_report(&p, z, o.at - start, b.count)
	}
	return nil
}

@(private)
unshrink_init :: proc(s: ^Unshrink) {
	s.used      = {}
	s.children  = {}
	s.leaf_next = {}
	s.free      = {}
	s.leaf_head = SHRINK_LEAF_END
	for i in 0..<256 {
		s.used[i]   = true
		s.value[i]  = u8(i)
		s.parent[i] = u16(i)
	}
	s.used[SHRINK_CONTROL_CODE] = true
	for &word in s.free[SHRINK_FIRST_FREE_CODE >> 6:] {
		word = ~u64(0)
	}
	s.free[SHRINK_FIRST_FREE_CODE >> 6] &~= (1 << uint(SHRINK_FIRST_FREE_CODE & 63)) - 1
}

@(private)
unshrink_read_code :: proc(z: ^compress.Context, pulled: ^i64, s: ^Unshrink, code_size: ^uint, next_free: ^int) -> (code: int, available: bool, err: Error) {
	for {
		code, available = read_bits(z, pulled, code_size^) or_return
		if !available || code != SHRINK_CONTROL_CODE {
			return
		}

		command: int
		command, available = read_bits(z, pulled, code_size^) or_return
		if !available {
			return 0, false, General_Error.Stream_Too_Short
		}

		switch command {
		case SHRINK_INCREASE_CODE_SIZE:
			if code_size^ >= SHRINK_MAX_CODE_SIZE {
				return 0, false, PKZIP_Legacy_Error.Code_Size_Too_Large
			}
			code_size^ += 1
		case SHRINK_PARTIAL_CLEAR:
			unshrink_partial_clear(s)
			next_free^ = unshrink_next_free(s, SHRINK_FIRST_FREE_CODE)
		case:
			return 0, false, PKZIP_Legacy_Error.Invalid_Control_Code
		}
	}
}

@(private)
unshrink_read_code_bits :: #force_inline proc(z: ^compress.Context, pulled: ^i64, b: ^Bits, s: ^Unshrink, code_size: ^uint, next_free: ^int) -> (code: int, available: bool, err: Error) {
	code, available = bits_read(z, pulled, b, code_size^) or_return
	if available && code == SHRINK_CONTROL_CODE {
		z.code_buffer = b.buffer
		z.num_bits    = b.count
		size, free := code_size^, next_free^
		code, available, size, free, err = unshrink_control(z, pulled, s, size, free)
		code_size^ = size
		next_free^ = free
		b.buffer = z.code_buffer
		b.count  = z.num_bits
	}
	return
}

@(private)
unshrink_control :: proc(z: ^compress.Context, pulled: ^i64, s: ^Unshrink, code_size: uint, next_free: int) -> (code: int, available: bool, size: uint, free: int, err: Error) {
	size, free = code_size, next_free
	code = SHRINK_CONTROL_CODE
	for code == SHRINK_CONTROL_CODE {
		command: int
		command, available = read_bits(z, pulled, size) or_return
		if !available {
			return 0, false, size, free, General_Error.Stream_Too_Short
		}
		switch command {
		case SHRINK_INCREASE_CODE_SIZE:
			if size >= SHRINK_MAX_CODE_SIZE {
				return 0, false, size, free, PKZIP_Legacy_Error.Code_Size_Too_Large
			}
			size += 1
		case SHRINK_PARTIAL_CLEAR:
			unshrink_partial_clear(s)
			free = unshrink_next_free(s, SHRINK_FIRST_FREE_CODE)
		case:
			return 0, false, size, free, PKZIP_Legacy_Error.Invalid_Control_Code
		}
		code, available = read_bits(z, pulled, size) or_return
		if !available {
			return
		}
	}
	return
}

@(private)
unshrink_add :: proc(s: ^Unshrink, code, parent: int, value: u8) #no_bounds_check {
	s.used[code]   = true
	s.parent[code] = u16(parent)
	s.value[code]  = value
	s.free[code >> 6] &~= 1 << uint(code & 63)
	s.children[parent] += 1
	if s.children[code] == 0 {
		s.leaf_next[code] = s.leaf_head
		s.leaf_head       = u16(code)
	}
}

@(private)
unshrink_push_leaf :: proc(s: ^Unshrink, code: int) #no_bounds_check {
	if s.leaf_next[code] == 0 {
		s.leaf_next[code] = s.leaf_head
		s.leaf_head       = u16(code)
	}
}

@(private)
unshrink_partial_clear :: proc(s: ^Unshrink) #no_bounds_check {
	doomed := u16(SHRINK_LEAF_END)
	node   := s.leaf_head
	s.leaf_head = SHRINK_LEAF_END
	for node != SHRINK_LEAF_END {
		next := s.leaf_next[node]
		s.leaf_next[node] = 0
		if s.used[node] && s.children[node] == 0 {
			s.leaf_next[node] = doomed
			doomed = node
		}
		node = next
	}

	for doomed != SHRINK_LEAF_END {
		code := int(doomed)
		doomed = s.leaf_next[code]
		s.leaf_next[code] = 0
		s.used[code] = false
		s.free[code >> 6] |= 1 << uint(code & 63)
		parent := int(s.parent[code])
		s.children[parent] -= 1
		if parent >= SHRINK_FIRST_FREE_CODE && s.used[parent] && s.children[parent] == 0 {
			unshrink_push_leaf(s, parent)
		}
	}
}

@(private)
unshrink_next_free :: proc(s: ^Unshrink, from: int) -> int #no_bounds_check {
	if from >= SHRINK_TABLE_SIZE {
		return SHRINK_TABLE_SIZE
	}
	if !s.used[from] {
		return from
	}
	word := from >> 6
	bits := s.free[word] & (~u64(0) << uint(from & 63))
	for {
		if bits != 0 {
			return word << 6 + int(intrinsics.count_trailing_zeros(bits))
		}
		word += 1
		if word >= len(s.free) {
			return SHRINK_TABLE_SIZE
		}
		bits = s.free[word]
	}
}
