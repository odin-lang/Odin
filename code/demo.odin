#import "fmt.odin"
#import "os.odin"
#import "mem.odin"


main :: proc() {
	y :: proc() -> (int, int) {
		return x()
	}
	x :: proc() -> (int, int) {
		return 1, 2
	}

	fmt.println(y())

	arena: mem.Arena
	mem.init_arena_from_context(^arena, 1000)
	defer mem.free_arena(^arena)

	push_allocator mem.arena_allocator(^arena) {
		x := new(int)
		x^ = 1337
		fmt.println(x^)
	}
}
