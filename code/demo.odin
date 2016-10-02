#import "fmt.odin"
#import "utf8.odin"
#import "hash.odin"
#import "mem.odin"
#import "game.odin"

main :: proc() {
	Vector3 :: struct {
		x, y, z: f32
	}
	Entity :: struct {
		guid:     u64
		position: Vector3
	}

}
