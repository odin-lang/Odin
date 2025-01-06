package regex_compiler

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "base:intrinsics"
import "core:io"
import "core:text/regex/common"
import "core:text/regex/virtual_machine"

get_jump_targets :: proc(code: []Opcode) -> (jump_targets: map[int]int) {
	iter := virtual_machine.Opcode_Iterator{ code, 0 }
	for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
		#partial switch opcode {
		case .Jump:
			jmp   := cast(int)intrinsics.unaligned_load(cast(^u16)&code[pc+1])
			jump_targets[jmp] = pc
		case .Split:
			jmp_x := cast(int)intrinsics.unaligned_load(cast(^u16)&code[pc+1])
			jmp_y := cast(int)intrinsics.unaligned_load(cast(^u16)&code[pc+3])
			jump_targets[jmp_x] = pc
			jump_targets[jmp_y] = pc
		}
	}
	return
}

trace :: proc(w: io.Writer, code: []Opcode) {
	jump_targets := get_jump_targets(code)
	defer delete(jump_targets)

	iter := virtual_machine.Opcode_Iterator{ code, 0 }
	for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
		if src, ok := jump_targets[pc]; ok {
			io.write_string(w, "--")
			common.write_padded_hex(w, src, 4)
			io.write_string(w, "--> ")
		} else {
			io.write_string(w, "            ")
		}

		io.write_string(w, "[PC: ")
		common.write_padded_hex(w, pc, 4)
		io.write_string(w, "] ")
		io.write_string(w, virtual_machine.opcode_to_name(opcode))
		io.write_byte(w, ' ')

		#partial switch opcode {
		case .Byte:
			operand := cast(rune)code[pc+1]
			io.write_encoded_rune(w, operand)
		case .Rune:
			operand := intrinsics.unaligned_load(cast(^rune)&code[pc+1])
			io.write_encoded_rune(w, operand)
		case .Rune_Class, .Rune_Class_Negated:
			operand := cast(u8)code[pc+1]
			common.write_padded_hex(w, operand, 2)
		case .Jump:
			jmp   := intrinsics.unaligned_load(cast(^u16)&code[pc+1])
			io.write_string(w, "-> $")
			common.write_padded_hex(w, jmp, 4)
		case .Split:
			jmp_x := intrinsics.unaligned_load(cast(^u16)&code[pc+1])
			jmp_y := intrinsics.unaligned_load(cast(^u16)&code[pc+3])
			io.write_string(w, "=> $")
			common.write_padded_hex(w, jmp_x, 4)
			io.write_string(w, ", $")
			common.write_padded_hex(w, jmp_y, 4)
		case .Save:
			operand := cast(u8)code[pc+1]
			common.write_padded_hex(w, operand, 2)
		case .Wait_For_Byte:
			operand := cast(rune)code[pc+1]
			io.write_encoded_rune(w, operand)
		case .Wait_For_Rune:
			operand := (cast(^rune)&code[pc+1])^
			io.write_encoded_rune(w, operand)
		case .Wait_For_Rune_Class:
			operand := cast(u8)code[pc+1]
			common.write_padded_hex(w, operand, 2)
		case .Wait_For_Rune_Class_Negated:
			operand := cast(u8)code[pc+1]
			common.write_padded_hex(w, operand, 2)
		}

		io.write_byte(w, '\n')
	}
}
