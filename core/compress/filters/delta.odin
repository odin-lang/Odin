package compress_filters

import "base:intrinsics"

delta_init :: proc "contextless" (state: ^Delta_State, distance: int) -> bool {
	if distance < DELTA_DISTANCE_MIN || distance > DELTA_DISTANCE_MAX {
		return false
	}
	state^ = {distance = distance}
	return true
}

delta_encode :: proc "contextless" (state: ^Delta_State, data: []u8) #no_bounds_check {
	d := state.distance
	n := len(data)
	if n == 0 || d < DELTA_DISTANCE_MIN || d > DELTA_DISTANCE_MAX {
		return
	}
	if n < d {
		original: [DELTA_DISTANCE_MAX]u8 = ---
		copy(original[:n], data)
		for i in 0..<n {
			data[i] -= state.history[i]
		}
		copy(state.history[:d - n], state.history[n:d])
		copy(state.history[d - n:d], original[:n])
		return
	}
	previous := state.history
	copy(state.history[:d], data[n - d:])
	i := n
	for i - 16 >= d {
		a := intrinsics.unaligned_load((^#simd[16]u8)(&data[i - 16]))
		b := intrinsics.unaligned_load((^#simd[16]u8)(&data[i - 16 - d]))
		intrinsics.unaligned_store((^#simd[16]u8)(&data[i - 16]), a - b)
		i -= 16
	}
	for i -= 1; i >= d; i -= 1 {
		data[i] -= data[i - d]
	}
	for j in 0..<d {
		data[j] -= previous[j]
	}
}

delta_decode :: proc "contextless" (state: ^Delta_State, data: []u8) #no_bounds_check {
	d := state.distance
	n := len(data)
	if n == 0 || d < DELTA_DISTANCE_MIN || d > DELTA_DISTANCE_MAX {
		return
	}
	if n < d {
		for i in 0..<n {
			data[i] += state.history[i]
		}
		copy(state.history[:d - n], state.history[n:d])
		copy(state.history[d - n:d], data)
		return
	}
	if n >= 16 && (d == 1 || d == 2 || d == 4 || d == 8) {
		done: int
		switch d {
		case 1: done = delta_decode_prefix(state, data, 1)
		case 2: done = delta_decode_prefix(state, data, 2)
		case 4: done = delta_decode_prefix(state, data, 4)
		case:   done = delta_decode_prefix(state, data, 8)
		}
		for ; done < n; done += 1 {
			data[done] += data[done - d]
		}
		copy(state.history[:d], data[n - d:])
		return
	}
	for i in 0..<d {
		data[i] += state.history[i]
	}
	i := d
	if d >= 16 {
		for i <= n - 16 {
			a := intrinsics.unaligned_load((^#simd[16]u8)(&data[i]))
			b := intrinsics.unaligned_load((^#simd[16]u8)(&data[i - d]))
			intrinsics.unaligned_store((^#simd[16]u8)(&data[i]), a + b)
			i += 16
		}
	}
	for ; i < n; i += 1 {
		data[i] += data[i - d]
	}
	copy(state.history[:d], data[n - d:])
}

@(private)
Delta_Lanes :: #simd[16]u8

@(private)
delta_shift :: #force_inline proc "contextless" (x: Delta_Lanes, $S: int) -> Delta_Lanes {
	zero: Delta_Lanes
	when S == 1 {
		return intrinsics.simd_shuffle(x, zero, 16, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
	} else when S == 2 {
		return intrinsics.simd_shuffle(x, zero, 16, 16, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13)
	} else when S == 4 {
		return intrinsics.simd_shuffle(x, zero, 16, 16, 16, 16, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)
	} else {
		return intrinsics.simd_shuffle(x, zero, 16, 16, 16, 16, 16, 16, 16, 16, 0, 1, 2, 3, 4, 5, 6, 7)
	}
}

@(private)
delta_tail :: #force_inline proc "contextless" (x: Delta_Lanes, $D: int) -> Delta_Lanes {
	when D == 1 {
		return intrinsics.simd_shuffle(x, x, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15)
	} else when D == 2 {
		return intrinsics.simd_shuffle(x, x, 14, 15, 14, 15, 14, 15, 14, 15, 14, 15, 14, 15, 14, 15, 14, 15)
	} else when D == 4 {
		return intrinsics.simd_shuffle(x, x, 12, 13, 14, 15, 12, 13, 14, 15, 12, 13, 14, 15, 12, 13, 14, 15)
	} else {
		return intrinsics.simd_shuffle(x, x, 8, 9, 10, 11, 12, 13, 14, 15, 8, 9, 10, 11, 12, 13, 14, 15)
	}
}

@(private)
delta_decode_prefix :: #force_inline proc "contextless" (state: ^Delta_State, data: []u8, $D: int) -> (done: int) #no_bounds_check {
	seed: [16]u8
	for j in 0..<16 {
		seed[j] = state.history[j % D]
	}
	carry := intrinsics.unaligned_load((^Delta_Lanes)(&seed))
	last  := len(data) - 16
	for done <= last {
		x := intrinsics.unaligned_load((^Delta_Lanes)(&data[done]))
		when D <= 1 {
			x += delta_shift(x, 1)
		}
		when D <= 2 {
			x += delta_shift(x, 2)
		}
		when D <= 4 {
			x += delta_shift(x, 4)
		}
		x += delta_shift(x, 8)
		x += carry
		intrinsics.unaligned_store((^Delta_Lanes)(&data[done]), x)
		carry = delta_tail(x, D)
		done += 16
	}
	return
}
