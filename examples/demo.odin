// Demo 001
#load "basic.odin"
#load "game.odin"

main :: proc() {
	Entity :: type union {
		FROG: struct {
			jump_height: f32
		}
		HELICOPTER: struct {
			weight:     f32
			blade_code: int
		}
	}

	e: Entity
	f: Entity = Entity.FROG{1};
	h: Entity = Entity.HELICOPTER{123, 4};

}

nl :: proc() { print_nl() }

