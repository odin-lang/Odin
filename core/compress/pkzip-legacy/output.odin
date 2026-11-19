package compress_pkzip_legacy

import "base:intrinsics"
import "base:runtime"
import "core:compress"

@(private)
output_limit :: proc(z: ^compress.Context, expected_output_size: int, options: compress.Options, expansion_max, memory: int) -> (expected: int, err: Error) {
	check_options(options) or_return
	expected = compress.declared_size(expected_output_size)
	if expected < 0 {
		return expected, General_Error.Incompatible_Options
	}
	if expected > compress.output_limit(options) {
		return expected, General_Error.Output_Too_Short
	}
	if expected == 0 {
		return
	}
	if memory > compress.memory_limit(options) {
		return expected, General_Error.Memory_Limit_Exceeded
	}

	input_size := compress.input_size(z)

	bound := -1
	if input_size >= 0 && input_size < max(int) / expansion_max {
		bound = input_size * expansion_max
	}
	non_zero_reserve(z.output, len(z.output) + compress.output_reservation(expected, bound, input_size)) or_return
	return
}

@(private)
grow :: proc(z: ^compress.Context, start, limit, need: int) -> (err: Error) {
	return non_zero_reserve(z.output, start + compress.output_grow_capacity(cap(z.output) - start, need, limit))
}

@(private)
out_load :: #force_inline proc "contextless" (z: ^compress.Context) -> Out {
	raw := (^runtime.Raw_Dynamic_Array)(z.output)
	return Out{([^]u8)(raw.data), raw.len, raw.cap}
}

@(private)
out_store :: #force_inline proc "contextless" (z: ^compress.Context, o: ^Out) {
	(^runtime.Raw_Dynamic_Array)(z.output).len = o.at
}

@(private)
out_grow :: proc(z: ^compress.Context, at, start, limit, need: int) -> (o: Out, err: Error) {
	(^runtime.Raw_Dynamic_Array)(z.output).len = at
	err = grow(z, start, limit, need)
	o = out_load(z)
	return
}

@(private)
out_literal :: #force_inline proc(z: ^compress.Context, o: ^Out, start, limit: int, value: u8) -> (err: Error) #no_bounds_check {
	if o.at - start >= limit {
		return General_Error.Size_Mismatch
	}
	if o.at == o.capacity {
		o^, err = out_grow(z, o.at, start, limit, o.at - start + 1)
		if err != nil {
			return
		}
	}
	o.data[o.at] = value
	o.at += 1
	return nil
}

@(private)
out_bytes :: #force_inline proc(z: ^compress.Context, o: ^Out, start, limit: int, data: []u8) -> (err: Error) #no_bounds_check {
	at := o.at
	if at - start + len(data) > limit {
		return General_Error.Size_Mismatch
	}
	if at + len(data) > o.capacity {
		o^, err = out_grow(z, at, start, limit, at - start + len(data))
		if err != nil {
			return
		}
	}
	intrinsics.mem_copy_non_overlapping(&o.data[at], raw_data(data), len(data))
	o.at = at + len(data)
	return nil
}

@(private)
out_match :: #force_inline proc(z: ^compress.Context, o: ^Out, start, limit, distance, length: int) -> (err: Error) #no_bounds_check {
	at := o.at
	if at - start + length > limit {
		return General_Error.Size_Mismatch
	}
	if at + length > o.capacity {
		o^, err = out_grow(z, at, start, limit, at - start + length)
		if err != nil {
			return
		}
	}
	buffer := o.data
	from   := at - distance
	o.at    = at + length
	if from >= start && distance >= 8 && at + length + 8 <= min(o.capacity, start + limit) {
		for i := 0; i < length; i += 8 {
			intrinsics.unaligned_store((^u64)(&buffer[at + i]), intrinsics.unaligned_load((^u64)(&buffer[from + i])))
		}
		return nil
	}
	i := 0
	for ; i < length && from + i < start; i += 1 {
		buffer[at + i] = 0
	}
	if distance >= length - i {
		intrinsics.mem_copy_non_overlapping(&buffer[at + i], &buffer[from + i], length - i)
	} else {
		for ; i < length; i += 1 {
			buffer[at + i] = buffer[from + i]
		}
	}
	return nil
}
