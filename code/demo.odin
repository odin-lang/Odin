#import "punity.odin" as pn
#import "fmt.odin" as fmt

test :: proc() {
	thing :: proc() {
		thing :: proc() {
			fmt.println("Hello1")
		}

		fmt.println("Hello")
	}
}

main :: proc() {
	test()

	init :: proc(c: ^pn.Core) {

	}

	step :: proc(c: ^pn.Core) {
		if pn.key_down(pn.Key.ESCAPE) {
			c.running = false
		}
	}

	pn.run(init, step)
}
