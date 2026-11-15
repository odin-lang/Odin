package a

// A proc literal in a constant is emitted in each module that uses the constant
H :: [1]proc() -> [3]int{
	proc() -> [3]int {
		@(static) n: int
		@(thread_local) t: int
		@(static) v: any = 40
		n += 1
		t += 1
		return {n, t, v.(int)}
	},
}
