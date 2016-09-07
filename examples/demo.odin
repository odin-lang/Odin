#load "basic.odin"
#load "math.odin"

main :: proc() {
	i: int
	s: struct {
		x, y, z: f32
	}
	p := ^s

	a: any = i

	println(137, "Hello", 1.25, true)
}
