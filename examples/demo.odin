// Demo 001
#load "basic.odin"
#load "game.odin"

main :: proc() {
	print_int(min(1, 2)); nl()
	print_int(max(1, 2)); nl()
	print_int(abs(-1337)); nl()

	a, b, c := 1, 2, -1337

	print_int(min(a, b)); nl()
	print_int(max(a, b)); nl()
	print_int(abs(c) as int); nl()

	nl()
/*
	Vec3   :: type struct { x, y, z: f32 }
	Entity :: type struct {
		using pos: Vec3
		name:      string
	}

	Amp :: type struct {
		using entity: Entity
		jump_height:  f32
	}
	Frog :: type struct {
		using amp: Amp
		volume: f64
	}

	f := Frog{};
	f.name = "ribbit"
	f.jump_height = 1337

	e := ^f.entity
	parent := e down_cast ^Frog

	print_name :: proc(using e: Entity, v: Vec3) {
		print_string(name); nl()
		print_int(v.x as int); nl()
	}

	print_f32(f.jump_height); nl()
	print_f32(parent.jump_height); nl()

	print_name(f, Vec3{1, 2, 3})
	print_name(parent, Vec3{3, 2, 1})
*/
}

nl :: proc() { print_nl() }

