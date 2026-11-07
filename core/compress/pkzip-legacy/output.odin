package compress_pkzip_legacy

import "base:runtime"
import "core:compress"

@(private)
output_limit :: proc(z: ^compress.Context, expected_output_size, max_output_size, expansion_max: int) -> (expected: int, err: Error) {
	expected = expected_output_size
	if expected < 0 && z.size_unpacked >= 0 && z.size_unpacked <= i64(max(int)) {
		expected = int(z.size_unpacked)
	}
	if expected < 0 || max_output_size < 0 {
		return expected, General_Error.Incompatible_Options
	}
	if expected > max_output_size {
		return expected, General_Error.Output_Too_Short
	}

	input_size := compress.input_size(z)

	bound := -1
	if input_size >= 0 && input_size < max(int) / expansion_max {
		bound = input_size * expansion_max
	}
	if expected > 0 {
		non_zero_reserve(z.output, len(z.output) + compress.output_reservation(expected, bound, input_size)) or_return
	}
	return
}

@(private)
grow :: proc(z: ^compress.Context, start, limit, need: int) -> (err: Error) {
	non_zero_reserve(z.output, start + compress.output_grow_capacity(cap(z.output) - start, need, limit)) or_return
	return nil
}

@(private)
write_literal :: #force_inline proc(z: ^compress.Context, start, limit: int, value: u8) -> (err: Error) #no_bounds_check {
	at := len(z.output)
	if at - start >= limit {
		return General_Error.Output_Too_Short
	}
	if at == cap(z.output) {
		grow(z, start, limit, at - start + 1) or_return
	}
	(^runtime.Raw_Dynamic_Array)(z.output).len = at + 1
	z.output[at] = value
	return nil
}

@(private)
write_bytes :: proc(z: ^compress.Context, start, limit: int, data: []u8) -> (err: Error) #no_bounds_check {
	at := len(z.output)
	if at - start + len(data) > limit {
		return General_Error.Output_Too_Short
	}
	if at + len(data) > cap(z.output) {
		grow(z, start, limit, at - start + len(data)) or_return
	}
	(^runtime.Raw_Dynamic_Array)(z.output).len = at + len(data)
	copy(z.output[at:], data)
	return nil
}

@(private)
write_match :: proc(z: ^compress.Context, start, limit, distance, length: int) -> (err: Error) #no_bounds_check {
	at := len(z.output)
	if at - start + length > limit {
		return General_Error.Output_Too_Short
	}
	if at + length > cap(z.output) {
		grow(z, start, limit, at - start + length) or_return
	}
	(^runtime.Raw_Dynamic_Array)(z.output).len = at + length
	buffer := z.output[:]

	from := at - distance
	i    := 0
	for ; i < length && from + i < start; i += 1 {
		buffer[at + i] = 0
	}
	if distance >= length - i {
		copy(buffer[at + i:at + length], buffer[from + i:from + length])
	} else {
		for ; i < length; i += 1 {
			buffer[at + i] = buffer[from + i]
		}
	}
	return nil
}
