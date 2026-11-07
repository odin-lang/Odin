package compress_pkzip_legacy

import "core:compress"

@(private)
refill_bits :: proc(z: ^compress.Context) -> (err: Error) #no_bounds_check {
	for z.num_bits <= 56 {
		if len(z.window) == 0 {
			refill_err := compress.refill_window(z, 1)
			if refill_err == .EOF {
				return nil
			}
			if refill_err != nil {
				return refill_err
			}
		}
		z.code_buffer |= u64(z.window[0]) << z.num_bits
		z.window       = z.window[1:]
		z.num_bits    += 8
	}
	return nil
}

@(private)
read_bits :: #force_inline proc(z: ^compress.Context, count: uint) -> (value: int, available: bool, err: Error) #no_bounds_check {
	if z.num_bits < u64(count) {
		refill_bits(z) or_return
		if z.num_bits < u64(count) {
			return 0, false, nil
		}
	}
	value = int(z.code_buffer & (u64(1) << count - 1))
	z.code_buffer >>= count
	z.num_bits     -= u64(count)
	return value, true, nil
}

@(private)
read_bits_required :: #force_inline proc(z: ^compress.Context, count: uint) -> (value: int, err: Error) {
	available: bool
	value, available = read_bits(z, count) or_return
	if !available {
		return 0, General_Error.Stream_Too_Short
	}
	return
}
