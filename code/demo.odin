#import "fmt.odin"

main :: proc() {
	foo :: proc(x: i64) -> i64 {
		return -x + 1
	}

	x, y: i64 = 123, 321
	y = x + 2 - y
	x = foo(y)
}
