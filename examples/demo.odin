#load "basic.odin"

main :: proc() {
	Vector4 :: struct {
		x: i8
		y: i32
		z: i16
		w: i16
	}

	v := Vector4{1, 4, 9, 16}

	t := type_info(v)

	println(123, "Hello", true, 6.28)
	println([4]int{1, 2, 3, 4})
	println(v)
}
