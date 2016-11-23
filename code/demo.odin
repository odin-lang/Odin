#import "fmt.odin"

variadic :: proc(args: ..any) {
	for i := 0; i < args.count; i++ {
		match type a : args[i] {
		case u128: fmt.println("u128", a)
		case i128: fmt.println("i128", a)
		}
	}

	fmt.println(..args)
}

main :: proc() {
	fmt.println("Hellope, everybody!")

	variadic(1 as u128, 1 as i128)

	// x: i128 = 321312321
	// y: i128 = 123123123
	// z: i128
	// x *= x; x *= x
	// y *= y; y *= y
	// fmt.println("x =", x)
	// fmt.println("y =", y)
	// z = x + y; fmt.println("x + y", z)
	// z = x - y; fmt.println("x - y", z)
	// z = x * y; fmt.println("x * y", z)
	// z = x / y; fmt.println("x / y", z)
	// z = x % y; fmt.println("x % y", z)
	// z = x & y; fmt.println("x & y", z)
	// z = x ~ y; fmt.println("x ~ y", z)
	// z = x | y; fmt.println("x | y", z)
	// z = x &~ y; fmt.println("x &~ y", z)

	// z = -x
	// z = ~x

	// b: bool
	// b = x == y; fmt.println("x == y", b)
	// b = x != y; fmt.println("x != y", b)
	// b = x <  y; fmt.println("x <  y", b)
	// b = x <= y; fmt.println("x <= y", b)
	// b = x >  y; fmt.println("x >  y", b)
	// b = x >= y; fmt.println("x >= y", b)
}
