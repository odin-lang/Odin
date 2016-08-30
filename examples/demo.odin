// Demo 001
#load "basic.odin"
#load "game.odin"

main :: proc() {
	Vec3   :: type struct { x, y, z: f32 }
	Entity :: type struct {
		using pos: Vec3
		name:      string
	}

	Frog :: type struct {
		using entity: Entity
		jump_height:  f32
	}

	f := Frog{}
	f.name = "ribbit"

	print_name :: proc(using e: Entity) {
		print_string(name); nl()
	}

	print_name(f.entity)
	print_name(f)


}


nl :: proc() #inline { print_nl() }

