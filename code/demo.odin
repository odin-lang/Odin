#import "fmt.odin"
#import "utf8.odin"
#import "hash.odin"
#import "mem.odin"



main :: proc() {
	Vec3 :: struct {
		x, y: i16
		z: int
	}

	z := 123
	v := Vec3{x = 4, y = 5, z = z}
	fmt.println(v)
}
