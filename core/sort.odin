bubble_sort :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	assert(f != nil);
	count := len(array);

	init_j, last_j := 0, count-1;

	for {
		init_swap, prev_swap := -1, -1;

		for j in init_j..last_j {
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

bubble_sort :: proc(array: $A/[]$T) {
	count := len(array);

	init_j, last_j := 0, count-1;

	for {
		init_swap, prev_swap := -1, -1;

		for j in init_j..last_j {
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

quick_sort :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
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

	quick_sort(a[0..i], f);
	quick_sort(a[i..n], f);
}

quick_sort :: proc(array: $A/[]$T) {
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

	quick_sort(a[0..i]);
	quick_sort(a[i..n]);
}

_log2 :: proc(n: int) -> int {
	res := 0;
	for ; n != 0; n >>= 1 do res += 1;
	return res;
}

merge_sort :: proc(array: $A/[]$T, f: proc(T, T) -> int) {
	merge_slices :: proc(arr1, arr2, out: A, f: proc(T, T) -> int) {
		N1, N2 := len(arr1), len(arr2);
		i, j := 0, 0;
		for k in 0..N1+N2 {
			if j == N2 || i < N1 && j < N2 && f(arr1[i], arr2[j]) < 0 {
				out[k] = arr1[i];
				i += 1;
			} else {
				out[k] = arr2[j];
				j += 1;
			}
		}
	}

	assert(f != nil);

	arr1 := array;
	N := len(arr1);
	arr2 := make([]T, N);
	defer free(arr2);

	a, b, m, M := N/2, N, 1, _log2(N);

	for i in 0..M+1 {
		for j in 0..a {
			k := 2*j*m;
			merge_slices(arr1[k..k+m], arr1[k+m..k+m+m], arr2[k..], f);
		}
		if N-b > m {
			k := 2*a*m;
			merge_slices(arr1[k..k+m], arr1[k+m..k+m+(N-b)&(m-1)], arr2[k..], f);
		} else {
			copy(arr2[b..N], arr1[b..N]);
		}
		arr1, arr2 = arr2, arr1;
		m <<= 1;
		a >>= 1;
		b = a << uint(i) << 2;
	}

	if M & 1 == 0 do copy(arr2, arr1);
}

merge_sort :: proc(array: $A/[]$T) {
	merge_slices :: proc(arr1, arr2, out: A) {
		N1, N2 := len(arr1), len(arr2);
		i, j := 0, 0;
		for k in 0..N1+N2 {
			if j == N2 || i < N1 && j < N2 && arr1[i] < arr2[j] {
				out[k] = arr1[i];
				i += 1;
			} else {
				out[k] = arr2[j];
				j += 1;
			}
		}
	}

	arr1 := array;
	N := len(arr1);
	arr2 := make([]T, N);
	defer free(arr2);

	a, b, m, M := N/2, N, 1, _log2(N);

	for i in 0..M+1 {
		for j in 0..a {
			k := 2*j*m;
			merge_slices(arr1[k..k+m], arr1[k+m..k+m+m], arr2[k..]);
		}
		if N-b > m {
			k := 2*a*m;
			merge_slices(arr1[k..k+m], arr1[k+m..k+m+(N-b)&(m-1)], arr2[k..]);
		} else {
			copy(arr2[b..N], arr1[b..N]);
		}
		arr1, arr2 = arr2, arr1;
		m <<= 1;
		a >>= 1;
		b = a << uint(i) << 2;
	}

	if M & 1 == 0 do copy(arr2, arr1);
}



compare_ints :: proc(a, b: int) -> int {
	match delta := a - b; {
	case delta < 0: return -1;
	case delta > 0: return +1;
	}
	return 0;
}

compare_f32s :: proc(a, b: f32) -> int {
	match delta := a - b; {
	case delta < 0: return -1;
	case delta > 0: return +1;
	}
	return 0;
}
compare_f64s :: proc(a, b: f64) -> int {
	match delta := a - b; {
	case delta < 0: return -1;
	case delta > 0: return +1;
	}
	return 0;
}
compare_strings :: proc(a, b: string) -> int {
	return __string_cmp(a, b);
}
