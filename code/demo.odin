#import "fmt.odin"
#import "game.odin"

variadic :: proc(args: ..any) {
	for i := 0; i < args.count; i++ {
		match type a : args[i] {
		case int:    fmt.println("int", a)
		case f32:    fmt.println("f32", a)
		case f64:    fmt.println("f64", a)
		case string: fmt.println("string", a)
		}
	}
}

main :: proc() {
	fmt.println("Hellope, everybody!")

	variadic(1, 1.0 as f32, 1.0 as f64, "Hellope")
}
