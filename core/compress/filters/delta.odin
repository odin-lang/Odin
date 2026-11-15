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
