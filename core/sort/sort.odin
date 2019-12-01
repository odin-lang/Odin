package sort

import "core:mem"
import "intrinsics"

bubble_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	assert(f != nil);
	count := len(array);

	init_j, last_j := 0, count-1;

	for {
		init_swap, prev_swap := -1, -1;

		for j in init_j..<last_j {
			if f(array[j], array[j+1]) > 0 {
				array[j], array[j+1] = array[j+1], array[j];
				prev_swap = j;
				if init_swap == -1 do init_swap = j;
			}
		}

		if prev_swap == -1 do return;

		init_j = max(init_swap-1, 0);
		last_j = prev_swap;
	}
}

bubble_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	count := len(array);

	init_j, last_j := 0, count-1;

	for {
		init_swap, prev_swap := -1, -1;

		for j in init_j..<last_j {
			if array[j] > array[j+1] {
				array[j], array[j+1] = array[j+1], array[j];
				prev_swap = j;
				if init_swap == -1 do init_swap = j;
			}
		}

		if prev_swap == -1 do return;

		init_j = max(init_swap-1, 0);
		last_j = prev_swap;
	}
}

quick_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	assert(f != nil);
	a := array;
	n := len(a);
	if n < 2 do return;

	p := a[n/2];
	i, j := 0, n-1;

	loop: for {
		for f(a[i], p) < 0 do i += 1;
		for f(p, a[j]) < 0 do j -= 1;

		if i >= j do break loop;

		a[i], a[j] = a[j], a[i];
		i += 1;
		j -= 1;
	}

	quick_sort_proc(a[0:i], f);
	quick_sort_proc(a[i:n], f);
}

quick_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	a := array;
	n := len(a);
	if n < 2 do return;

	p := a[n/2];
	i, j := 0, n-1;

	loop: for {
		for a[i] < p do i += 1;
		for p < a[j] do j -= 1;

		if i >= j do break loop;

		a[i], a[j] = a[j], a[i];
		i += 1;
		j -= 1;
	}

	quick_sort(a[0:i]);
	quick_sort(a[i:n]);
}

_log2 :: proc(x: int) -> int {
	res := 0;
	for n := x; n != 0; n >>= 1 do res += 1;
	return res;
}

merge_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) where intrinsics.type_is_ordered(T) {
	merge :: proc(a: A, start, mid, end: int, f: proc(T, T) -> int) {
		s, m := start, mid;

		s2 := m + 1;
		if f(a[m], a[s2]) <= 0 {
			return;
		}

		for s <= m && s2 <= end {
			if f(a[s], a[s2]) <= 0 {
				s += 1;
			} else {
				v := a[s2];
				i := s2;

				for i != s {
					a[i] = a[i-1];
					i -= 1;
				}
				a[s] = v;

				s  += 1;
				m  += 1;
				s2 += 1;
			}
		}
	}
	internal_sort :: proc(a: A, l, r: int, f: proc(T, T) -> int) {
		if l < r {
			m := l + (r - l) / 2;

			internal_sort(a, l, m, f);
			internal_sort(a, m+1, r, f);
			merge(a, l, m, r, f);
		}
	}

	internal_sort(array, 0, len(array)-1, f);
}

merge_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	merge :: proc(a: A, start, mid, end: int) {
		s, m := start, mid;

		s2 := m + 1;
		if a[m] <= a[s2] {
			return;
		}

		for s <= m && s2 <= end {
			if a[s] <= a[s2] {
				s += 1;
			} else {
				v := a[s2];
				i := s2;

				for i != s {
					a[i] = a[i-1];
					i -= 1;
				}
				a[s] = v;

				s  += 1;
				m  += 1;
				s2 += 1;
			}
		}
	}
	internal_sort :: proc(a: A, l, r: int) {
		if l < r {
			m := l + (r - l) / 2;

			internal_sort(a, l, m);
			internal_sort(a, m+1, r);
			merge(a, l, m, r);
		}
	}

	internal_sort(array, 0, len(array)-1);
}


heap_sort_proc :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	sift_proc :: proc(a: A, pi: int, n: int, f: proc(T, T) -> int) #no_bounds_check {
		p := pi;
		v := a[p];
		m := p*2 + 1;
		for m <= n {
			if (m < n) && f(a[m+1], a[m]) > 0 {
				m += 1;
			}
			if f(v, a[m]) >= 0 {
				break;
			}
			a[p] = a[m];
			p = m;
			m += m+1;
			a[p] = v;
		}
	}

	n := len(array);
	if n == 0 do return;

	for i := n/2; i >= 0; i -= 1 {
		sift_proc(array, i, n-1, f);
	}

	for i := n-1; i >= 1; i -= 1 {
		array[0], array[i] = array[i], array[0];
		sift_proc(array, 0, i-1, f);
	}
}

heap_sort :: proc(array: $A/[]$T) where intrinsics.type_is_ordered(T) {
	sift :: proc(a: A, pi: int, n: int) #no_bounds_check {
		p := pi;
		v := a[p];
		m := p*2 + 1;
		for m <= n {
			if (m < n) && (a[m+1] > a[m]) {
				m += 1;
			}
			if v >= a[m] {
				break;
			}
			a[p] = a[m];
			p = m;
			m += m+1;
			a[p] = v;
		}
	}

	n := len(array);
	if n == 0 do return;

	for i := n/2; i >= 0; i -= 1 {
		sift(array, i, n-1);
	}

	for i := n-1; i >= 1; i -= 1 {
		array[0], array[i] = array[i], array[0];
		sift(array, 0, i-1);
	}
}

compare_bools :: proc(a, b: bool) -> int {
	switch {
	case !a && b: return -1;
	case a && !b: return +1;
	}
	return 0;
}


compare_ints :: proc(a, b: int) -> int {
	switch delta := a - b; {
	case delta < 0: return -1;
	case delta > 0: return +1;
	}
	return 0;
}

compare_f32s :: proc(a, b: f32) -> int {
	switch delta := a - b; {
	case delta < 0: return -1;
	case delta > 0: return +1;
	}
	return 0;
}
compare_f64s :: proc(a, b: f64) -> int {
	switch delta := a - b; {
	case delta < 0: return -1;
	case delta > 0: return +1;
	}
	return 0;
}
compare_strings :: proc(a, b: string) -> int {
	x := transmute(mem.Raw_String)a;
	y := transmute(mem.Raw_String)b;
	return mem.compare_byte_ptrs(x.data, y.data, min(x.len, y.len));
}
