#import "fmt.odin"

A :: {2}f32{1, 2}
B :: {2}f32{3, 4}

main :: proc() {
	Fruit :: union {
		A: int
		B: f32
		C: struct {
			x: int
		}
	}
}

