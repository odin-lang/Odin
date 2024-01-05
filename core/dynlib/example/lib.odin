package library

@(export)
foo_add :: proc "c" (a, b: int) -> (res: int) {
	return a + b
}

@(export)
bar_sub :: proc "c" (a, b: int) -> (res: int) {
	return a - b
}

@(export)
foo_hellope: i32 = 42