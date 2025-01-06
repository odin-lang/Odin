package math_big

/*
	With `n` items, calculate how many ways that `r` of them can be ordered.
*/
permutations_with_repetition :: int_pow_int

/*
	With `n` items, calculate how many ways that `r` of them can be ordered without any repeats.
*/
permutations_without_repetition :: proc(dest: ^Int, n, r: int) -> (error: Error)  {
	if n == r {
		return factorial(dest, n)
	}

	tmp := &Int{}
	defer internal_destroy(tmp)

	//    n!
	// --------
	// (n - r)!
	factorial(dest, n)     or_return
	factorial(tmp,  n - r) or_return
	div(dest, dest, tmp)   or_return

	return
}

/*
	With `n` items, calculate how many ways that `r` of them can be chosen.

	Also known as the multiset coefficient or (n multichoose k).
*/
combinations_with_repetition :: proc(dest: ^Int, n, r: int) -> (error: Error) {
	// (n + r - 1)!
	// ------------
	// r!  (n - 1)!
	return combinations_without_repetition(dest, n + r - 1, r)
}

/*
	With `n` items, calculate how many ways that `r` of them can be chosen without any repeats.

	Also known as the binomial coefficient or (n choose k).
*/
combinations_without_repetition :: proc(dest: ^Int, n, r: int) -> (error: Error) {
	tmp_a, tmp_b := &Int{}, &Int{}
	defer internal_destroy(tmp_a, tmp_b)

	//      n! 
	// ------------
	// r!  (n - r)!
	factorial(dest, n)       or_return
	factorial(tmp_a, r)      or_return
	factorial(tmp_b, n - r)  or_return
	mul(tmp_a, tmp_a, tmp_b) or_return
	div(dest, dest, tmp_a)   or_return

	return
}
