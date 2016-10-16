#import "fmt.odin"

main :: proc() {
	Entity :: union {
		Apple: int
		Banana: f32
		Goat: struct {
			x, y: int
			z, w: f32
		}
	}

	a := 123 as Entity.Apple
	e: Entity = a
	fmt.println(a)

	if apple, ok := ^e union_cast ^Entity.Apple; ok {
		apple^ = 321
		e = apple^
	}

	apple, ok := e union_cast Entity.Apple
	fmt.println(apple)
}

