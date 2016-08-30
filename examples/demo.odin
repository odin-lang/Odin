// Demo 001
#load "basic.odin"
#load "game.odin"

main :: proc() {

	Thing :: type struct {
		using x: struct { a, b: int }
	}

	{
		using t := new(Thing)
		defer delete(t)
		a = 321
		print_int(a); nl()
	}

	// {
	// 	using t := new(Thing)
	// 	defer delete(t)
	// 	a = 1337
	// 	print_int(a); nl()
	// }

	// run_game()
}


nl :: proc() #inline { print_nl() }

