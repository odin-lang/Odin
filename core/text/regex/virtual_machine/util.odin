package regex_vm

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

Opcode_Iterator :: struct {
	code: Program,
	pc: int,
}

iterate_opcodes :: proc(iter: ^Opcode_Iterator) -> (opcode: Opcode, pc: int, ok: bool) {
	if iter.pc >= len(iter.code) {
		return
	}

	opcode = iter.code[iter.pc]
	pc = iter.pc
	ok = true

	switch opcode {
	case .Match:                       iter.pc += size_of(Opcode)
	case .Match_And_Exit:              iter.pc += size_of(Opcode)
	case .Byte:                        iter.pc += size_of(Opcode) + size_of(u8)
	case .Rune:                        iter.pc += size_of(Opcode) + size_of(rune)
	case .Rune_Class:                  iter.pc += size_of(Opcode) + size_of(u8)
	case .Rune_Class_Negated:          iter.pc += size_of(Opcode) + size_of(u8)
	case .Wildcard:                    iter.pc += size_of(Opcode)
	case .Jump:                        iter.pc += size_of(Opcode) + size_of(u16)
	case .Split:                       iter.pc += size_of(Opcode) + 2 * size_of(u16)
	case .Save:                        iter.pc += size_of(Opcode) + size_of(u8)
	case .Assert_Start:                iter.pc += size_of(Opcode)
	case .Assert_End:                  iter.pc += size_of(Opcode)
	case .Assert_Word_Boundary:        iter.pc += size_of(Opcode)
	case .Assert_Non_Word_Boundary:    iter.pc += size_of(Opcode)
	case .Multiline_Open:              iter.pc += size_of(Opcode)
	case .Multiline_Close:             iter.pc += size_of(Opcode)
	case .Wait_For_Byte:               iter.pc += size_of(Opcode) + size_of(u8)
	case .Wait_For_Rune:               iter.pc += size_of(Opcode) + size_of(rune)
	case .Wait_For_Rune_Class:         iter.pc += size_of(Opcode) + size_of(u8)
	case .Wait_For_Rune_Class_Negated: iter.pc += size_of(Opcode) + size_of(u8)
	case .Match_All_And_Escape:        iter.pc += size_of(Opcode)
	case:
		panic("Invalid opcode found in RegEx program.")
	}

	return
}

opcode_to_name :: proc(opcode: Opcode) -> (str: string) {
	switch opcode {
	case .Match:                       str = "Match"
	case .Match_And_Exit:              str = "Match_And_Exit"
	case .Byte:                        str = "Byte"
	case .Rune:                        str = "Rune"
	case .Rune_Class:                  str = "Rune_Class"
	case .Rune_Class_Negated:          str = "Rune_Class_Negated"
	case .Wildcard:                    str = "Wildcard"
	case .Jump:                        str = "Jump"
	case .Split:                       str = "Split"
	case .Save:                        str = "Save"
	case .Assert_Start:                str = "Assert_Start"
	case .Assert_End:                  str = "Assert_End"
	case .Assert_Word_Boundary:        str = "Assert_Word_Boundary"
	case .Assert_Non_Word_Boundary:    str = "Assert_Non_Word_Boundary"
	case .Multiline_Open:              str = "Multiline_Open"
	case .Multiline_Close:             str = "Multiline_Close"
	case .Wait_For_Byte:               str = "Wait_For_Byte"
	case .Wait_For_Rune:               str = "Wait_For_Rune"
	case .Wait_For_Rune_Class:         str = "Wait_For_Rune_Class"
	case .Wait_For_Rune_Class_Negated: str = "Wait_For_Rune_Class_Negated"
	case .Match_All_And_Escape:        str = "Match_All_And_Escape"
	case:                              str = "<UNKNOWN>"
	}

	return
}
