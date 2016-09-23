#import "fmt.odin"
#import "os.odin"
#import "mem.odin"

main :: proc() {

	arena: mem.Arena
	mem.init_arena_from_context(^arena, 1000)
	defer mem.free_arena(^arena)

	push_allocator mem.arena_allocator(^arena) {
		x := new(int)
		x^ = 1337
		fmt.println(x^)
	}
}
