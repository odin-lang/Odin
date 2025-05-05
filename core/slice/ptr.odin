package slice

import "base:builtin"
import "base:runtime"

/*
Add to a pointer.

**WARNING: No bounds checking is performed!**

Inputs:
- `p`: The pointer to add to
- `x`: The element count to offset the pointer by

Example:

	import "core:slice"
	import "core:fmt"

	ptr_add_example :: proc() {
		data := []rune{'A', 'B', 'C', 'D', 'E'}
		ptr := &data[1]
		next := slice.ptr_add(ptr, 2)^
		fmt.println(next)
	}

Outputs:

	D
*/
ptr_add :: proc(p: $P/^$T, x: int) -> ^T {
	return ([^]T)(p)[x:]
}

/*
Subtract from a pointer.

**WARNING: No bounds checking is performed!**

Inputs:
- `p`: The pointer to from to
- `x`: The element count to offset the pointer by

Example:

	import "core:slice"
	import "core:fmt"

	ptr_add_example :: proc() {
		data := []rune{'A', 'B', 'C', 'D', 'E'}
		ptr := &data[3]
		prev := slice.ptr_sub(ptr, 2)^
		fmt.println(prev)
	}

Outputs:

	B
*/
ptr_sub :: proc(p: $P/^$T, x: int) -> ^T {
	return ([^]T)(p)[-x:]
}

/*
Swap the memory at the pointer addresses.

This function assumes that the data ranges do not overlap.

**WARNING: No bounds checking is performed!**

Inputs:
- `x`, `y`: pointers to the memory to swap
- `len`: number of bytes to swap
*/
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

/*
Swap the memory at the pointer addresses.

This function allows the data to overlap.

**WARNING: No bounds checking is performed!**

Inputs:
- `x`, `y`: pointers to the memory to swap
- `len`: number of bytes to swap
*/
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

/*
Shift elements so that what was at position mid becomes the new start, and everything else wraps around while
maintaining relative ordering.

Inputs:
- `left`: The number of elements to the left of `mid`
- `mid`: A pointer to the middle element (the new first element after rotation)
- `right`: The number of elements to the right of `mid` (inclusive of `mid`)
*/
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
