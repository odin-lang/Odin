#import "fmt.odin"
#import "utf8.odin"
#import "hash.odin"
#import "mem.odin"


A :: struct { using e: [12]int }
Vector2 :: raw_union {
	using _xy: struct #ordered { x, y: f32 }
	using v: {2}f32
	e: [2]f32
}

main :: proc() {
	v: Vector2
	v.x = 123
	v[1] = 321
	fmt.println(v)
}
