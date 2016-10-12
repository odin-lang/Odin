#import "fmt.odin"

main :: proc() {
	Vec3 :: struct {
		x, y: i16
		z: ?i32
	}
	a := [..]int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
	offset: u8 = 2
	ptr := ^a[4]


	fmt.println((ptr+offset) - ptr)
}

