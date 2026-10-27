package other

counter: int

next :: proc "contextless" () -> int {
	counter += 1
	return counter
}

A := next()
B := next()

@(linkage="internal")
internal_value := next()

get_internal :: proc "contextless" () -> int {
	return internal_value
}

Point :: struct {
	x, y: int,
}

P      := Point{1, 2}
P_ptr  := &P
TABLE  := []^Point{&P}
boxed  := &Point{3, 4}
NAMES  := [3]string{"x", "y", "z"}
any_p: any = P

@(rodata)
RO := [4]int{1, 2, 3, 4}

callback := proc "contextless" () -> int {
	return 7
}
