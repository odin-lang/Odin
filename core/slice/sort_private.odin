#+private
package slice

import "base:builtin"
import "base:intrinsics"

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
	
	// insertion sort
	// TODO(bill): use a different algorithm as insertion sort is O(n^2)
	n := len(data)
	for i in 1..<n {
		for j := i; j > 0 && less(data[j], data[j-1], call); j -= 1 {
			swap(data, j, j-1)
		}
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

@(require_results)
_quick_sort_max_depth :: proc(n: int) -> (depth: int) { // 2*ceil(log2(n+1))
	for i := n; i > 0; i >>= 1 {
		depth += 1
	}
	return depth * 2
}

_quick_sort_general :: proc(data: $T/[]$E, a, b, max_depth: int, call: $P, $KIND: Sort_Kind) where (intrinsics.type_is_ordered(E) && KIND == .Ordered) || (KIND != .Ordered) #no_bounds_check {
	a, b, max_depth := a, b, max_depth
	
	// Manual tail call loop
	for b-a > 64 {
		if max_depth == 0 {
			heap_sort(data, a, b, call)
			return
		}
		max_depth -= 1
		mlo, mhi := do_pivot(data, a, b, call)
		if mlo-a < b-mhi {
			_quick_sort_general(data, a, mlo, max_depth, call, KIND)
			a = mhi
		} else {
			_quick_sort_general(data, mhi, b, max_depth, call, KIND)
			b = mlo
		}
	}
	
	if b-a > 1 {
		// Shell short
		for i in a+16..<b {
			if less(data[i], data[i-16], call) {
				swap(data, i, i-16)
			}
		}
		insertion_sort(data, a, b, call)
	}
	
	return
	
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

	insertion_sort :: #force_inline proc(data: $T/[]$E, a, b: int, call: P) #no_bounds_check {
		for i in a+1..<b {
			val := data[i]
			j := i
			for ; j > a && less(val, data[j-1], call); j -= 1 {
				data[j] = data[j-1]
			}
			data[j] = val
		}
	}

	heap_sort :: proc(data: $T/[]$E, a, b: int, call: P) #no_bounds_check {
		sift_down :: proc(data: T, lo, hi, first: int, call: P) #no_bounds_check {
			root := lo
			for {
				child := 2*root + 1
				if child >= hi {
					break
				}
				if child+1 < hi && less(data[first+child], data[first+child+1], call) {
					child += 1
				}
				if !less(data[first+root], data[first+child], call) {
					return
				}
				swap(data, first+root, first+child)
				root = child
			}
		}


		first, lo, hi := a, 0, b-a

		for i := (hi-1)/2; i >= 0; i -= 1 {
			sift_down(data, i, hi, first, call)
		}

		for i := hi-1; i >= 0; i -= 1 {
			swap(data, first, first+i)
			sift_down(data, lo, i, first, call)
		}
	}

	median3 :: proc(data: T, m1, m0, m2: int, call: P) #no_bounds_check {
		if less(data[m1], data[m0], call) {
			swap(data, m1, m0)
		}
		if less(data[m2], data[m1], call) {
			swap(data, m2, m1)
			if less(data[m1], data[m0], call) {
				swap(data, m1, m0)
			}
		}
	}

	do_pivot :: proc(data: T, lo, hi: int, call: P) -> (midlo, midhi: int) #no_bounds_check {
		m := int(uint(lo+hi)>>1)
		// Tukey's ninther
		if hi-lo > 40 {
			s := (hi-lo)/8
			median3(data, lo, lo+s, lo+s*2, call)
			median3(data, m, m-s, m+s, call)
			median3(data, hi-1, hi-1-s, hi-1-s*2, call)
		}
		median3(data, lo, m, hi-1, call)

		pivot := lo
		a, c := lo+1, hi-1


		for ; a < c && less(data[a], data[pivot], call); a += 1 {
		}
		b := a

		for {
			for ; b < c && !less(data[pivot], data[b], call); b += 1 { // data[b] <= pivot
			}
			for ; b < c && less(data[pivot], data[c-1], call); c -=1 { // data[c-1] > pivot
			}
			if b >= c {
				break
			}

			swap(data, b, c-1)
			b += 1
			c -= 1
		}

		protect := hi-c < 5
		if !protect && hi-c < (hi-lo)/4 {
			dups := 0
			if !less(data[pivot], data[hi-1], call) {
				swap(data, c, hi-1)
				c += 1
				dups += 1
			}
			if !less(data[b-1], data[pivot], call) {
				b -= 1
				dups += 1
			}

			if !less(data[m], data[pivot], call) {
				swap(data, m, b-1)
				b -= 1
				dups += 1
			}
			protect = dups > 1
		}
		if protect {
			for {
				for ; a < b && !less(data[b-1], data[pivot], call); b -= 1 {
				}
				for ; a < b && less(data[a], data[pivot], call); a += 1 {
				}
				if a >= b {
					break
				}
				swap(data, a, b-1)
				a += 1
				b -= 1
			}
		}
		swap(data, pivot, b-1)
		return b-1, c
	}
}
