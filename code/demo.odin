#import "punity.odin" as pn

main :: proc() {
	init :: proc(c: ^pn.Core) {
	}

	step :: proc(c: ^pn.Core) {
		if pn.key_down(pn.Key.ESCAPE) {
			c.running = false
		}
	}

	pn.run(init, step)
}
