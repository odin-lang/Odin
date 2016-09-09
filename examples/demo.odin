#load "basic.odin"

Vector3 :: struct { x, y, z: f32 }
main :: proc() {

	v := Vector3{1, 4, 9}

	println(123, "Hello", true, 6.28)
	println([4]int{1, 2, 3, 4})
}
