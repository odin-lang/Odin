#import "fmt.odin"

str := "Hellope"

a: [12]u8
main :: proc() {
	v: [4]f32
	v[0] = 123
	fmt.println(str, v, v[0], a)
}
