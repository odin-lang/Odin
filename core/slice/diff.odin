// An implementation of Myers' O(ND) Difference Algorithm for slices of
// arbitrary types that can be simply compared.
//
// See https://publications.mpi-cbg.de/Myers_1986_6330.pdf
package slice

import "base:intrinsics"

import "core:mem"

// A kind of difference in an edit script.
Diff_Kind :: enum {
	// A value should be inserted in the original slice.
	Insert,
	// A value should be deleted from the original slice.
	Delete,
	// A value should be kept in the original slice.
	Keep,
}

// A difference in an edit script.
Diff :: struct($T: typeid) {
	kind:       Diff_Kind,
	begin, end: int,
	values:     []T,
}

/*
Calculates the difference list between a given original list and its expected
sequence of elements as an edit script.

Inputs:
- value: The original slice.
- expected: The expected slice.
- allocator: The allocator used to create the edit script (default is context.allocator).

Returns:
- result: The edit script to transform the original list in the expected list.
- err: An `Allocator_Error`, if allocation failed.
*/
diff :: proc(
	value, expected: []$T,
	allocator := context.allocator,
) -> (
	result: []Diff(T),
	err: mem.Allocator_Error,
) where intrinsics.type_is_simple_compare(T) #optional_allocator_error {
	a := value
	b := expected

	deletes := make(map[int]int, allocator)
	defer delete(deletes)
	inserts := make(map[int][dynamic]int, allocator)
	defer {
		for k in inserts {
			delete(inserts[k])
		}

		delete(inserts)
	}
	keeps := make(map[int]int, allocator)
	defer delete(keeps)
	end_inserts := make([dynamic]int, allocator)
	defer delete(end_inserts)

	stack := make([dynamic]Subproblem, allocator)
	defer delete(stack)
	append(&stack, Subproblem{ax = 0, ay = 0, bx = len(a), by = len(b)}) or_return

	for len(stack) != 0 {
		p := pop(&stack)

		n := p.bx - p.ax
		m := p.by - p.ay

		if n > 0 && m == 0 {
			for i in p.ax ..< p.bx {
				deletes[i] = i
			}

			continue
		}

		if n == 0 && m > 0 {
			if p.ax < len(a) {
				if !(p.ax in inserts) {
					inserts[p.ax] = make([dynamic]int, allocator)
				}

				for j in p.ay ..< p.by {
					append(&inserts[p.ax], j) or_return
				}
			} else {
				for j in p.ay ..< p.by {
					append(&end_inserts, j) or_return
				}
			}

			continue
		}

		if n == 0 && m == 0 {
			continue
		}

		sms := find_middle_snake(a, b, p, allocator) or_return

		if sms == nil {
			for i in p.ax ..< p.bx {
				deletes[i] = i
			}

			if p.ax < len(a) {
				for j in p.ay ..< p.by {
					if !(p.ax in inserts) {
						inserts[p.ax] = make([dynamic]int, allocator)
					}

					append(&inserts[p.ax], j) or_return
				}
			} else {
				for j in p.ay ..< p.by {
					append(&end_inserts, j) or_return
				}
			}

			continue
		}

		for i in sms.?.x ..< sms.?.u {
			keeps[i] = i
		}

		append(&stack, Subproblem{ax = sms.?.u, ay = sms.?.v, bx = p.bx, by = p.by}) or_return
		append(&stack, Subproblem{ax = p.ax, ay = p.ay, bx = sms.?.x, by = sms.?.y}) or_return
	}

	script := make([dynamic]Diff(T), allocator)
	defer if err != nil {delete(script)}

	for i in 0 ..= len(a) {
		if i in inserts {
			for insert in inserts[i] {
				append_diff(&script, a, b, .Insert, insert) or_return
			}
		}

		if i < len(a) {
			if i in deletes {
				append_diff(&script, a, b, .Delete, deletes[i]) or_return
			} else if i in keeps {
				append_diff(&script, a, b, .Keep, keeps[i]) or_return
			}
		}
	}

	for insert in end_inserts {
		append_diff(&script, a, b, .Insert, insert) or_return
	}

	return script[:], nil

	// A boundary box within the edit graph matrix.
	Subproblem :: struct {
		ax, ay: int,
		bx, by: int,
	}

	// The overlapping match point that splits the problem.
	Middle_Snake :: struct {
		x, y: int,
		u, v: int,
	}

	// Finds the middle snake.
	@(require_results)
	find_middle_snake :: proc(
		a, b: []$T,
		p: Subproblem,
		allocator := context.allocator,
	) -> (
		result: Maybe(Middle_Snake),
		err: mem.Allocator_Error,
	) {
		n := p.bx - p.ax
		m := p.by - p.ay
		delta := n - m
		odd := (delta % 2 != 0)

		// TODO: Convert to fixed-length slices.
		vf := make(map[int]int, allocator)
		defer delete(vf)

		vr := make(map[int]int, allocator)
		defer delete(vr)

		vf[1] = 0
		vr[delta] = n

		max_d := (n + m + 1) / 2

		for d in 0 ..= max_d {
			for k := -d; k <= d; k += 2 {
				x: int
				if d == 0 {
					x = vf[1]
				} else if k == -d || (k != d && vf[k - 1] < vf[k + 1]) {
					x = vf[k + 1]
				} else {
					x = vf[k - 1] + 1
				}

				y := x - k

				x_start := x
				y_start := y
				for x < n && y < m && a[p.ax + x] == b[p.ay + y] {
					x += 1
					y += 1
				}
				vf[k] = x

				if odd && (delta - d < k) && (k < delta + d) {
					if k in vf && vf[k] >= vr[k] {
						return Middle_Snake {
								x = p.ax + x_start,
								y = p.ay + y_start,
								u = p.ax + x,
								v = p.ay + y,
							},
							nil
					}
				}
			}

			for k := -d + delta; k <= d + delta; k += 2 {
				x: int
				if d == 0 {
					x = vr[delta]
				} else if k == d + delta || (k != -d + delta && vr[k - 1] > vr[k + 1]) {
					x = vr[k - 1]
				} else {
					x = vr[k + 1] - 1
				}
				y := x - k

				x_start := x
				y_start := y
				for x > 0 && y > 0 && a[p.ax + x - 1] == b[p.ay + y - 1] {
					x -= 1
					y -= 1
				}
				vr[k] = x

				if !odd && -d <= k && k <= d {
					if k in vf && vf[k] >= vr[k] {
						return Middle_Snake {
								x = p.ax + x,
								y = p.ay + y,
								u = p.ax + x_start,
								v = p.ay + y_start,
							},
							nil
					}
				}
			}
		}

		return nil, nil
	}

	append_diff :: proc(
		diffs: ^[dynamic]Diff(T),
		a, b: []T,
		kind: Diff_Kind,
		position: int,
	) -> (
		err: mem.Allocator_Error,
	) {
		if len(diffs) > 0 {
			last := &diffs[len(diffs) - 1]

			if last.kind == kind && last.end == position {
				last.end = position + 1

				switch last.kind {
				case .Insert:
					last.values = b[last.begin:last.end]
				case .Delete, .Keep:
					last.values = a[last.begin:last.end]
				}

				return nil
			}
		}

		values: []T
		switch kind {
		case .Insert:
			values = b[position:position+1]
		case .Delete, .Keep:
			values = a[position:position+1]
		}

		append(diffs, Diff(T){kind=kind, begin=position,end=position+1,values=values}) or_return

		return nil
	}
}
