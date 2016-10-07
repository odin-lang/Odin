#import "fmt.odin"


main :: proc() {
	maybe_print :: proc(x: ?int) {
		if v, ok := x?; ok {
			fmt.println(v)
		} else {
			fmt.println("nowt")
		}
	}

	maybe_print(123) // 123
	maybe_print(nil) // nowt
}

