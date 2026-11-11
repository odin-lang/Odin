// Tests issue #8074 https://github.com/odin-lang/Odin/issues/8074
// An exit within a defer is an error, and the escape analysis must not run that defer again
package test_issues

E :: enum { None, Bad }

parse :: proc(s: string) -> (int, E) {
	if len(s) == 0 {
		return 0, .Bad
	}
	return 1, .None
}

return_in_defer :: proc() -> int {
	defer { return }
	return 1
}

or_return_in_defer :: proc() -> E {
	defer { v := parse("") or_return; _ = v }
	return .None
}

conditional_return_in_defer :: proc(c: bool) -> int {
	defer {
		if c {
			return
		}
	}
	return 1
}

nested_return_in_defer :: proc(c: bool) -> int {
	defer { _, _ = parse("outer") }
	{
		defer { _, _ = parse("inner") }
		defer { return }
		if c {
			return 2
		}
	}
	return 1
}

returns_in_two_defers :: proc() -> int {
	defer { return }
	defer { return }
	return 1
}

break_in_defer :: proc() {
	for {
		defer { break }
	}
}

or_break_in_defer :: proc() {
	for {
		defer { v := parse("") or_break; _ = v }
	}
}

// each runs the defers before it only once, or the analysis takes 2^25 steps
many_returns_in_defers :: proc() -> int {
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	defer { return }
	return 1
}

// valid: the loop and its branches are within the defer
loop_in_defer :: proc() -> int {
	defer {
		for i in 0..<3 {
			if i == 1 {
				continue
			}
			if i == 2 {
				break
			}
		}
	}
	return 1
}

// valid: an exit on one path leaves the defers pending for the others
paths_with_defers :: proc(c: bool) -> int {
	defer {
		for i in 0..<2 {
			if i == 1 {
				break
			}
		}
	}
	if c {
		return 2
	}
	defer { _, _ = parse("") }
	return 1
}
