// #load "basic.odin"
#import "runtime.odin"
#import "print.odin"


main :: proc() {
	println("% % % %", "Hellope", true, 6.28, {4}int{1, 2, 3, 4})
	x: struct #ordered {
		x, y: int
		z: f32
	}
	println("%", x)
}
