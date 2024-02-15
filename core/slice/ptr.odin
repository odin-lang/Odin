package slice

import "base:builtin"
import "base:runtime"

ptr_add :: proc(p: $P/^$T, x: int) -> ^T {
	return ([^]T)(p)[x:]
}
ptr_sub :: proc(p: $P/^$T, x: int) -> ^T {
	return ([^]T)(p)[-x:]
}

ptr_swap_non_overlapping :: proc(x, y: rawptr, len: int) {
	if len <= 0 {
		return
	}
	if x == y { // Ignore pointers that are the same
		return
	}

	Block :: distinct [4]u64
	BLOCK_SIZE :: size_of(Block)

	i := 0
	t := &Block{}
	for ; i + BLOCK_SIZE <= len; i += BLOCK_SIZE {
		a := rawptr(uintptr(x) + uintptr(i))
		b := rawptr(uintptr(y) + uintptr(i))

		runtime.mem_copy(t, a, BLOCK_SIZE)
		runtime.mem_copy(a, b, BLOCK_SIZE)
		runtime.mem_copy(b, t, BLOCK_SIZE)
	}

	if i < len {
		rem := len - i

		a := rawptr(uintptr(x) + uintptr(i))
		b := rawptr(uintptr(y) + uintptr(i))

		runtime.mem_copy(t, a, rem)
		runtime.mem_copy(a, b, rem)
		runtime.mem_copy(b, t, rem)
	}
}

ptr_swap_overlapping :: proc(x, y: rawptr, len: int) {
	if len <= 0 {
		return
	}
	if x == y {
		return
	}
	
	N :: 512
	buffer: [N]byte = ---
	
	a, b := ([^]byte)(x), ([^]byte)(y)
	
	for n := len; n > 0; n -= N {
		m := builtin.min(n, N)
		runtime.mem_copy(&buffer, a, m)
		runtime.mem_copy(a, b, m)
		runtime.mem_copy(b, &buffer, m)
		
		a, b = a[N:], b[N:]
	}
}


ptr_rotate :: proc(left: int, mid: ^$T, right: int) {
	when size_of(T) != 0 {
		left, mid, right := left, mid, right

		// TODO(bill): Optimization with a buffer for smaller ranges
		for left > 0 && right > 0 {
			if left >= right {
				for {
					ptr_swap_non_overlapping(ptr_sub(mid, right), mid, right * size_of(T))
					mid = ptr_sub(mid, right)

					left -= right
					if left < right {
						break
					}
				}
			} else {
				for {
					ptr_swap_non_overlapping(ptr_sub(mid, left), mid, left * size_of(T))
					mid = ptr_add(mid, left)

					right -= left
					if right < left {
						break
					}
				}
			}
		}
	}
}
