#import "fmt.odin"

main :: proc() {
	x, y: i64 = 123, 321
	y = x + 2 - y
}
