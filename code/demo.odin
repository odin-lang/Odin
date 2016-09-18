#import "punity.odin"   as pn
#import "test.odin"     as t1
#import "sub/test.odin" as t2

main :: proc() {
	t1.thing()
	t2.thing()

	// init :: proc(c: ^pn.Core) {
	// }

	// step :: proc(c: ^pn.Core) {
	// 	if pn.key_down(pn.Key.ESCAPE) {
	// 		c.running = false
	// 	}
	// }

	// pn.run(init, step)
}
