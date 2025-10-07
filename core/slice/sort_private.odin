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