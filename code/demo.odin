#import "print.odin"

test_proc :: proc() {
	println("Hello?")
}


main :: proc() {
	println("% % % %", "Hellope", true, 6.28, {4}int{1, 2, 3, 4})
}
