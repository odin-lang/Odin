#import "fmt.odin" as fmt
// #import "game.odin" as game

test_proc :: proc() {
	fmt.println("Hello?")
}


main :: proc() {
	x := 0
	// fmt.println("% % % %", "Hellope", true, 6.28, {4}int{1, 2, 3, 4})
	fmt.println("%(%)", #file, #line)
	// game.run()
}
