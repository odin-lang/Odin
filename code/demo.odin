#import "fmt.odin"

main :: proc() {
	Thing :: struct {
		f: f32
		a: any
	}
	t := Thing{1, "Hello"}


	fmt.printf("Here % %\n", 123, 2.0)
}

