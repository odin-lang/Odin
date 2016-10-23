#import "fmt.odin"

main :: proc() {
	v: {4}f32
	v[0] = 123
	fmt.println("Hellope!", v, v[0])
}


