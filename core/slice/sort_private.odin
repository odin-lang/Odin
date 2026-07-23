#+private
package slice

import "base:builtin"
import "base:intrinsics"
_ :: intrinsics

ORD :: intrinsics.type_is_ordered

Sort_Kind :: enum {
	Ordered,
	Less,
	Cmp,
}


_stable_sort_general :: proc(data: $T/[]$E, call: $P, $KIND: Sort_Kind) where (ORD(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
	less :: #force_inline proc(a, b: E, call: P) -> bool {
		when KIND == .Ordered {
			return a < b
		} else when KIND == .Less {
			return call(a, b)
		} else when KIND == .Cmp {
			return call(a, b) == .Less
		} else {
			#panic("unhandled Sort_Kind")
		}
	}
	if len(data) < 1000 {
		insertion_sort(data, call)
		return
	}
	rotate_merge(data, call)
	// O(nlog²n)
	rotate_merge :: proc(arr: $T/[]$E, call: $P){
        if len(arr) < 32 {
            insertion_sort(arr, call)
            return
        }
		mid := len(arr) >> 1

		rotate_merge(arr[:mid], call)
		rotate_merge(arr[mid:], call)

		stable_merge(arr, mid, len(arr) - mid, call)
	}

	insertion_sort :: #force_inline proc(arr: $A/[]$T, call: $P) #no_bounds_check {
		for i in 1..<len(arr) {
			x := arr[i]
			j := i
			for ; j > 0 && less(x, arr[j - 1], call); j -= 1 {
				arr[j] = arr[j - 1]
			}
			arr[j] = x
		}
	}

	bin_search_left :: #force_inline proc(arr: $A/[]$T, value: T,  call: $P) -> int #no_bounds_check {
		from := 0
		len := len(arr)

		for len > 0 {
			half := len / 2
			mid := from + half

			if less(arr[mid], value, call){
				from = mid + 1
				len -= half + 1
			} else {
				len = half
			}
		}
		return from
	}

	bin_search_right :: #force_inline proc(arr: $A/[]$T, value: T,  call: $P) -> int #no_bounds_check {
		from := 0
		len := len(arr)

		for len > 0 {
			half := len / 2
			mid := from + half

			if less(value, arr[mid], call){
				len = half
			} else {
				from = mid + 1
				len -= half + 1
			}
		}
		return from
	}

	stable_merge :: proc(arr: $T/[]$E, left, right: int, call: $P) #no_bounds_check {
		if left == 0 || right == 0 {
			return
		}
		if left + right == 2 {
			if less(arr[1],arr[0],call) {
				swap(arr,0,1)
			}
			return
		} 
		first_cut, second_cut : int
		left2, right2 : int
		if left > right {
			left2 = left >> 1
			first_cut = left2

			second_cut = left + bin_search_left(arr[left:], arr[first_cut], call)
			right2 = second_cut - left
		} else {
			right2 = right >> 1
			second_cut = left + right2

			first_cut = bin_search_right(arr[:left], arr[second_cut],call)
			left2 = first_cut
		}
		
		rotate_left(arr[first_cut:second_cut], left - first_cut)
		new_mid := first_cut + right2

		stable_merge(arr[:new_mid], left2, 		right2,		  call)
		stable_merge(arr[new_mid:], left-left2, right-right2, call)
	}
}

@(private)
_smoothsort :: proc(base: [^]byte, nel: uint, width: uint, cmp: Generic_Cmp, arg: rawptr) {
	pntz :: proc "contextless" (p: [2]uint) -> int {
		r := intrinsics.count_trailing_zeros(p[0] - 1)
		if r != 0 {
			return int(r)
		}
		r = (8*size_of(uint) + intrinsics.count_trailing_zeros(p[1]))
		if r != 8*size_of(uint) {
			return int(r)
		}
		return 0
	}

	shl :: proc "contextless" (p: []uint, n: int) {
		n := n
		if n >= 8*size_of(uint) {
			n -= 8*size_of(uint)
			p[1] = p[0]
			p[0] = 0
		}
		p[1] <<= uint(n)
		p[0] |= p[0] >> uint(8*size_of(uint) - n)
		p[0] <<= uint(n)
	}
	shr :: proc "contextless" (p: []uint, n: int) {
		n := n
		if n >= 8*size_of(uint) {
			n -= 8*size_of(uint)
			p[0] = p[1]
			p[1] = 0
		}
		p[0] >>= uint(n)
		p[0] |= p[1] << uint(8*size_of(uint) - n)
		p[1] >>= uint(n)
	}

	cycle :: proc "contextless" (width: uint, data: [][^]byte, n: int) {
		if len(data) < 2 {
			return
		}
		buf: [256]u8 = ---
		data[n] = raw_data(buf[:])
		width := width
		for width != 0 {
			l := builtin.min(size_of(buf), int(width))
			copy(data[n][:l], data[0][:l])
			for i in 0..<n {
				copy(data[i][:l], data[i+1][:l])
				data[i] = data[i][l:]
			}
			width -= uint(l)
		}
	}

	sift :: proc(head: [^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr, pshift: int, lp: []uint) {
		head := head
		buf: [14*size_of(uint)+1][^]byte = ---
		buf[0] = head
		i := 1
		pshift := pshift
		for pshift > 1 {
			rt := head[-width:]
			lf := head[-width:][-lp[pshift - 2]:]
			if cmp(buf[0], lf, arg) >= .Equal && cmp(buf[0], rt, arg) >= .Equal {
				break
			}
			if cmp(lf, rt, arg) >= .Equal {
				buf[i], head = lf, lf
				pshift -= 1
			} else {
				buf[i], head = rt, rt
				pshift -= 2
			}
			i += 1
		}
		cycle(width, buf[:], i)
	}

	trinkle :: proc(head: [^]byte, width: uint, cmp: Generic_Cmp, arg: rawptr, pp: []uint, pshift: int, trusty: bool, lp: []uint) {
		head := head

		p := [2]uint{pp[0], pp[1]}

		buf: [14*size_of(uint)+1][^]byte = ---
		buf[0] = head

		i := 1
		trail := 0
		pshift := pshift
		trusty := trusty
		for p[0] != 1 || p[1] != 0 {
			stepson := head[-lp[pshift]:]
			if cmp(stepson, buf[0], arg) <= .Equal {
				break
			}
			if !trusty && pshift > 1 {
				rt := head[-width:]
				lf := head[-width:][-lp[pshift-2]:]
				if cmp(rt, stepson, arg) >= .Equal || cmp(lf, stepson, arg) >= .Equal {
					break
				}
			}
			buf[i] = stepson
			head = stepson
			trail = pntz(p)
			shr(p[:], trail)
			pshift += trail
			trusty = false
			i += 1
		}
		if trusty {
			return
		}
		cycle(width, buf[:], i)
		sift(head, width, cmp, arg, pshift, lp)
	}

	size := nel * width
	if size == 0 {
		return
	}

	lp: [12*size_of(uint)]uint = ---
	lp[1] = width
	lp[0] = lp[1]
	for i := 2; true; i += 1 {
		lp[i] = lp[i-2] + lp[i-1] + width
		if lp[i] >= size {
			break
		}
	}

	head := base
	high := head[size - width:]
	p := [2]uint{1, 0}
	pshift := 1
	for head < high {
		if (p[0] & 3) == 3 {
			sift(head, width, cmp, arg, pshift, lp[:])
			shr(p[:], 2)
			pshift += 2
		} else {
			if lp[pshift - 1] >= uint(uintptr(high) - uintptr(head)) {
				trinkle(head, width, cmp, arg, p[:], pshift, false, lp[:])
			} else {
				sift(head, width, cmp, arg, pshift, lp[:])
			}
			if pshift == 1 {
				shl(p[:], 1)
				pshift = 0
			} else {
				shl(p[:], pshift - 1)
				pshift = 1
			}
		}
		p[0] |= 1
		head = head[width:]
	}
	trinkle(head, width, cmp, arg, p[:], pshift, false, lp[:])
	for pshift != 1 || p[0] != 1 || p[1] != 0 {
		if pshift <= 1 {
			trail := pntz(p)
			shr(p[:], trail)
			pshift += trail
		} else {
			shl(p[:], 2)
			pshift -= 2
			p[0] ~= 7
			shr(p[:], 1)
			trinkle(head[-width:][-lp[pshift]:], width, cmp, arg, p[:], pshift + 1, true, lp[:])
			shl(p[:], 1)
			p[0] |= 1
			trinkle(head[-width:], width, cmp, arg, p[:], pshift, true, lp[:])
		}
		head = head[-width:]
	}
}
