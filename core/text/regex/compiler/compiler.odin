package regex_compiler

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "base:intrinsics"
import "core:text/regex/common"
import "core:text/regex/parser"
import "core:text/regex/tokenizer"
import "core:text/regex/virtual_machine"
import "core:unicode"

Token      :: tokenizer.Token
Token_Kind :: tokenizer.Token_Kind
Tokenizer  :: tokenizer.Tokenizer

Rune_Class_Range            :: parser.Rune_Class_Range
Rune_Class_Data             :: parser.Rune_Class_Data

Node                        :: parser.Node
Node_Rune                   :: parser.Node_Rune
Node_Rune_Class             :: parser.Node_Rune_Class
Node_Wildcard               :: parser.Node_Wildcard
Node_Concatenation          :: parser.Node_Concatenation
Node_Alternation            :: parser.Node_Alternation
Node_Repeat_Zero            :: parser.Node_Repeat_Zero
Node_Repeat_Zero_Non_Greedy :: parser.Node_Repeat_Zero_Non_Greedy
Node_Repeat_One             :: parser.Node_Repeat_One
Node_Repeat_One_Non_Greedy  :: parser.Node_Repeat_One_Non_Greedy
Node_Repeat_N               :: parser.Node_Repeat_N
Node_Optional               :: parser.Node_Optional
Node_Optional_Non_Greedy    :: parser.Node_Optional_Non_Greedy
Node_Group                  :: parser.Node_Group
Node_Anchor                 :: parser.Node_Anchor
Node_Word_Boundary          :: parser.Node_Word_Boundary
Node_Match_All_And_Escape   :: parser.Node_Match_All_And_Escape

Opcode :: virtual_machine.Opcode
Program  :: [dynamic]Opcode

JUMP_SIZE  :: size_of(Opcode) + 1 * size_of(u16)
SPLIT_SIZE :: size_of(Opcode) + 2 * size_of(u16)


Compiler :: struct {
	flags: common.Flags,
	class_data: [dynamic]Rune_Class_Data,
}


Error :: enum {
	None,
	Program_Too_Big,
	Too_Many_Classes,
}

classes_are_exact :: proc(q, w: ^Rune_Class_Data) -> bool #no_bounds_check {
	assert(q != nil)
	assert(w != nil)

	if q == w {
		return true
	}

	if len(q.runes) != len(w.runes) || len(q.ranges) != len(w.ranges) {
		return false
	}

	for r, i in q.runes {
		if r != w.runes[i] {
			return false
		}
	}

	for r, i in q.ranges {
		if r.lower != w.ranges[i].lower || r.upper != w.ranges[i].upper {
			return false
		}
	}

	return true
}

map_all_classes :: proc(tree: Node, collection: ^[dynamic]Rune_Class_Data) {
	if tree == nil {
		return
	}

	switch specific in tree {
	case ^Node_Rune: break
	case ^Node_Wildcard: break
	case ^Node_Anchor: break
	case ^Node_Word_Boundary: break
	case ^Node_Match_All_And_Escape: break

	case ^Node_Concatenation:
		for subnode in specific.nodes {
			map_all_classes(subnode, collection)
		}

	case ^Node_Repeat_Zero:
		map_all_classes(specific.inner, collection)
	case ^Node_Repeat_Zero_Non_Greedy:
		map_all_classes(specific.inner, collection)
	case ^Node_Repeat_One:
		map_all_classes(specific.inner, collection)
	case ^Node_Repeat_One_Non_Greedy:
		map_all_classes(specific.inner, collection)
	case ^Node_Repeat_N:
		map_all_classes(specific.inner, collection)
	case ^Node_Optional:
		map_all_classes(specific.inner, collection)
	case ^Node_Optional_Non_Greedy:
		map_all_classes(specific.inner, collection)
	case ^Node_Group:
		map_all_classes(specific.inner, collection)

	case ^Node_Alternation:
		map_all_classes(specific.left, collection)
		map_all_classes(specific.right, collection)

	case ^Node_Rune_Class:
		unseen := true
		for &value in collection {
			if classes_are_exact(&specific.data, &value) {
				unseen = false
				break
			}
		}

		if unseen {
			append(collection, specific.data)
		}
	}
}

append_raw :: #force_inline proc(code: ^Program, data: $T) {
	// NOTE: This is system-dependent endian.
	for b in transmute([size_of(T)]byte)data {
		append(code, cast(Opcode)b)
	}
}
inject_raw :: #force_inline proc(code: ^Program, start: int, data: $T) {
	// NOTE: This is system-dependent endian.
	for b, i in transmute([size_of(T)]byte)data {
		inject_at(code, start + i, cast(Opcode)b)
	}
}

@require_results
generate_code :: proc(c: ^Compiler, node: Node) -> (code: Program) {
	if node == nil {
		return
	}

	// NOTE: For Jump/Split arguments, we write as i16 and will reinterpret
	// this later when relative jumps are turned into absolute jumps.

	switch specific in node {
	// Atomic Nodes:
	case ^Node_Rune:
		if .Unicode not_in c.flags || specific.data < unicode.MAX_LATIN1 {
			append(&code, Opcode.Byte)
			append(&code, cast(Opcode)specific.data)
		} else {
			append(&code, Opcode.Rune)
			append_raw(&code, specific.data)
		}

	case ^Node_Rune_Class:
		if specific.negating {
			append(&code, Opcode.Rune_Class_Negated)
		} else {
			append(&code, Opcode.Rune_Class)
		}

		index := -1
		for &data, i in c.class_data {
			if classes_are_exact(&data, &specific.data) {
				index = i
				break
			}
		}
		assert(index != -1, "Unable to find collected Rune_Class_Data index.")

		append(&code, Opcode(index))

	case ^Node_Wildcard:
		append(&code, Opcode.Wildcard)

	case ^Node_Anchor:
		if .Multiline in c.flags {
			append(&code, Opcode.Multiline_Open)
			append(&code, Opcode.Multiline_Close)
		} else {
			if specific.start {
				append(&code, Opcode.Assert_Start)
			} else {
				append(&code, Opcode.Assert_End)
			}
		}
	case ^Node_Word_Boundary:
		if specific.non_word {
			append(&code, Opcode.Assert_Non_Word_Boundary)
		} else {
			append(&code, Opcode.Assert_Word_Boundary)
		}

	// Compound Nodes:
	case ^Node_Group:
		code = generate_code(c, specific.inner)

		if specific.capture && .No_Capture not_in c.flags {
			inject_at(&code, 0, Opcode.Save)
			inject_at(&code, 1, Opcode(2 * specific.capture_id))

			append(&code, Opcode.Save)
			append(&code, Opcode(2 * specific.capture_id + 1))
		}

	case ^Node_Alternation:
		left := generate_code(c, specific.left)
		right := generate_code(c, specific.right)

		left_len := len(left)

		// Avoiding duplicate allocation by reusing `left`.
		code = left

		inject_at(&code, 0, Opcode.Split)
		inject_raw(&code, size_of(byte)               , i16(SPLIT_SIZE))
		inject_raw(&code, size_of(byte) + size_of(i16), i16(SPLIT_SIZE + left_len + JUMP_SIZE))

		append(&code, Opcode.Jump)
		append_raw(&code, i16(len(right) + JUMP_SIZE))

		for opcode in right {
			append(&code, opcode)
		}

	case ^Node_Concatenation:
		for subnode in specific.nodes {
			subnode_code := generate_code(c, subnode)
			for opcode in subnode_code {
				append(&code, opcode)
			}
		}

	case ^Node_Repeat_Zero:
		code = generate_code(c, specific.inner)
		original_len := len(code)

		inject_at(&code, 0, Opcode.Split)
		inject_raw(&code, size_of(byte)               , i16(SPLIT_SIZE))
		inject_raw(&code, size_of(byte) + size_of(i16), i16(SPLIT_SIZE + original_len + JUMP_SIZE))

		append(&code, Opcode.Jump)
		append_raw(&code, i16(-original_len - SPLIT_SIZE))

	case ^Node_Repeat_Zero_Non_Greedy:
		code = generate_code(c, specific.inner)
		original_len := len(code)

		inject_at(&code, 0, Opcode.Split)
		inject_raw(&code, size_of(byte)               , i16(SPLIT_SIZE + original_len + JUMP_SIZE))
		inject_raw(&code, size_of(byte) + size_of(i16), i16(SPLIT_SIZE))

		append(&code, Opcode.Jump)
		append_raw(&code, i16(-original_len - SPLIT_SIZE))

	case ^Node_Repeat_One:
		code = generate_code(c, specific.inner)
		original_len := len(code)

		append(&code, Opcode.Split)
		append_raw(&code, i16(-original_len))
		append_raw(&code, i16(SPLIT_SIZE))

	case ^Node_Repeat_One_Non_Greedy:
		code = generate_code(c, specific.inner)
		original_len := len(code)

		append(&code, Opcode.Split)
		append_raw(&code, i16(SPLIT_SIZE))
		append_raw(&code, i16(-original_len))

	case ^Node_Repeat_N:
		inside := generate_code(c, specific.inner)
		original_len := len(inside)

		if specific.lower == specific.upper { // {N}
			// e{N} ... evaluates to ... e^N
			for i := 0; i < specific.upper; i += 1 {
				for opcode in inside {
					append(&code, opcode)
				}
			}

		} else if specific.lower == -1 && specific.upper > 0 { // {,M}
			// e{,M} ... evaluates to ... e?^M
			for i := 0; i < specific.upper; i += 1 {
				append(&code, Opcode.Split)
				append_raw(&code, i16(SPLIT_SIZE))
				append_raw(&code, i16(SPLIT_SIZE + original_len))
				for opcode in inside {
					append(&code, opcode)
				}
			}

		} else if specific.lower >= 0 && specific.upper == -1 { // {N,}
			// e{N,} ... evaluates to ... e^N e*
			for i := 0; i < specific.lower; i += 1 {
				for opcode in inside {
					append(&code, opcode)
				}
			}

			append(&code, Opcode.Split)
			append_raw(&code, i16(SPLIT_SIZE))
			append_raw(&code, i16(SPLIT_SIZE + original_len + JUMP_SIZE))

			for opcode in inside {
				append(&code, opcode)
			}

			append(&code, Opcode.Jump)
			append_raw(&code, i16(-original_len - SPLIT_SIZE))

		} else if specific.lower >= 0 && specific.upper > 0 {
			// e{N,M}  evaluates to ... e^N e?^(M-N)
			for i := 0; i < specific.lower; i += 1 {
				for opcode in inside {
					append(&code, opcode)
				}
			}
			for i := 0; i < specific.upper - specific.lower; i += 1 {
				append(&code, Opcode.Split)
				append_raw(&code, i16(SPLIT_SIZE + original_len))
				append_raw(&code, i16(SPLIT_SIZE))
				for opcode in inside {
					append(&code, opcode)
				}
			}

		} else {
			panic("RegEx compiler received invalid repetition group.")
		}

	case ^Node_Optional:
		code = generate_code(c, specific.inner)
		original_len := len(code)

		inject_at(&code, 0, Opcode.Split)
		inject_raw(&code, size_of(byte)               , i16(SPLIT_SIZE))
		inject_raw(&code, size_of(byte) + size_of(i16), i16(SPLIT_SIZE + original_len))

	case ^Node_Optional_Non_Greedy:
		code = generate_code(c, specific.inner)
		original_len := len(code)

		inject_at(&code, 0, Opcode.Split)
		inject_raw(&code, size_of(byte)               , i16(SPLIT_SIZE + original_len))
		inject_raw(&code, size_of(byte) + size_of(i16), i16(SPLIT_SIZE))

	case ^Node_Match_All_And_Escape:
		append(&code, Opcode.Match_All_And_Escape)
	}

	return
}

@require_results
compile :: proc(tree: Node, flags: common.Flags) -> (code: Program, class_data: [dynamic]Rune_Class_Data, err: Error) {
	if tree == nil {
		if .No_Capture not_in flags {
			append(&code, Opcode.Save); append(&code, Opcode(0x00))
			append(&code, Opcode.Save); append(&code, Opcode(0x01))
			append(&code, Opcode.Match)
		} else {
			append(&code, Opcode.Match_And_Exit)
		}
		return
	}

	c: Compiler
	c.flags = flags

	map_all_classes(tree, &class_data)
	if len(class_data) >= common.MAX_CLASSES {
		err = .Too_Many_Classes
		return
	}
	c.class_data = class_data

	code = generate_code(&c, tree)

	pc_open := 0

	add_global: if .Global in flags {
		// Check if the opening to the pattern is predictable.
		// If so, use one of the optimized Wait opcodes.
		iter := virtual_machine.Opcode_Iterator{ code[:], 0 }
		seek_loop: for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
			#partial switch opcode {
			case .Byte:
				inject_at(&code, pc_open, Opcode.Wait_For_Byte)
				pc_open += size_of(Opcode)
				inject_at(&code, pc_open, Opcode(code[pc + size_of(Opcode) + pc_open]))
				pc_open += size_of(u8)
				break add_global

			case .Rune:
				operand := intrinsics.unaligned_load(cast(^rune)&code[pc+1])
				inject_at(&code, pc_open, Opcode.Wait_For_Rune)
				pc_open += size_of(Opcode)
				inject_raw(&code, pc_open, operand)
				pc_open += size_of(rune)
				break add_global

			case .Rune_Class:
				inject_at(&code, pc_open, Opcode.Wait_For_Rune_Class)
				pc_open += size_of(Opcode)
				inject_at(&code, pc_open, Opcode(code[pc + size_of(Opcode) + pc_open]))
				pc_open += size_of(u8)
				break add_global

			case .Rune_Class_Negated:
				inject_at(&code, pc_open, Opcode.Wait_For_Rune_Class_Negated)
				pc_open += size_of(Opcode)
				inject_at(&code, pc_open, Opcode(code[pc + size_of(Opcode) + pc_open]))
				pc_open += size_of(u8)
				break add_global

			case .Save:
				continue
			case:
				break seek_loop
			}
		}

		// `.*?`
		inject_at(&code, pc_open, Opcode.Split)
		pc_open += size_of(byte)
		inject_raw(&code, pc_open, i16(SPLIT_SIZE + size_of(byte) + JUMP_SIZE))
		pc_open += size_of(i16)
		inject_raw(&code, pc_open, i16(SPLIT_SIZE))
		pc_open += size_of(i16)

		inject_at(&code, pc_open, Opcode.Wildcard)
		pc_open += size_of(byte)

		inject_at(&code, pc_open, Opcode.Jump)
		pc_open += size_of(byte)
		inject_raw(&code, pc_open, i16(-size_of(byte) - SPLIT_SIZE))
		pc_open += size_of(i16)

	}

	if .No_Capture not_in flags {
		// `(` <generated code>
		inject_at(&code, pc_open, Opcode.Save)
		inject_at(&code, pc_open + size_of(byte), Opcode(0x00))

		// `)`
		append(&code, Opcode.Save); append(&code, Opcode(0x01))

		append(&code, Opcode.Match)
	} else {
		append(&code, Opcode.Match_And_Exit)
	}

	if len(code) >= common.MAX_PROGRAM_SIZE {
		err = .Program_Too_Big
		return
	}

	// NOTE: No further opcode addition beyond this point, as we've already
	// checked the program size. Removal or transformation is fine.

	// Post-Compile Optimizations:

	// * Jump Extension
	//
	// A:RelJmp(1) -> B:RelJmp(2) => A:RelJmp(2)
	if .No_Optimization not_in flags {
		for passes_left := 1; passes_left > 0; passes_left -= 1 {
			do_another_pass := false

			iter := virtual_machine.Opcode_Iterator{ code[:], 0 }
			for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
				#partial switch opcode {
				case .Jump:
					jmp   := cast(^i16)&code[pc+size_of(Opcode)]
					jmp_value := intrinsics.unaligned_load(jmp)
					if code[cast(i16)pc+jmp_value] == .Jump {
						next_jmp := intrinsics.unaligned_load(cast(^i16)&code[cast(i16)pc+jmp_value+size_of(Opcode)])
						intrinsics.unaligned_store(jmp, jmp_value + next_jmp)
						do_another_pass = true
					}
				case .Split:
					jmp_x := cast(^i16)&code[pc+size_of(Opcode)]
					jmp_x_value := intrinsics.unaligned_load(jmp_x)
					if code[cast(i16)pc+jmp_x_value] == .Jump {
						next_jmp := intrinsics.unaligned_load(cast(^i16)&code[cast(i16)pc+jmp_x_value+size_of(Opcode)])
						intrinsics.unaligned_store(jmp_x, jmp_x_value + next_jmp)
						do_another_pass = true
					}
					jmp_y := cast(^i16)&code[pc+size_of(Opcode)+size_of(i16)]
					jmp_y_value := intrinsics.unaligned_load(jmp_y)
					if code[cast(i16)pc+jmp_y_value] == .Jump {
						next_jmp := intrinsics.unaligned_load(cast(^i16)&code[cast(i16)pc+jmp_y_value+size_of(Opcode)])
						intrinsics.unaligned_store(jmp_y, jmp_y_value + next_jmp)
						do_another_pass = true
					}
				}
			}

			if do_another_pass {
				passes_left += 1
			}
		}
	}

	// * Relative Jump to Absolute Jump
	//
	// RelJmp{PC +/- N} => AbsJmp{M}
	iter := virtual_machine.Opcode_Iterator{ code[:], 0 }
	for opcode, pc in virtual_machine.iterate_opcodes(&iter) {
		// NOTE: The virtual machine implementation depends on this.
		#partial switch opcode {
		case .Jump:
			jmp   := cast(^u16)&code[pc+size_of(Opcode)]
			intrinsics.unaligned_store(jmp, intrinsics.unaligned_load(jmp) + cast(u16)pc)
		case .Split:
			jmp_x := cast(^u16)&code[pc+size_of(Opcode)]
			intrinsics.unaligned_store(jmp_x, intrinsics.unaligned_load(jmp_x) + cast(u16)pc)
			jmp_y := cast(^u16)&code[pc+size_of(Opcode)+size_of(i16)]
			intrinsics.unaligned_store(jmp_y, intrinsics.unaligned_load(jmp_y) + cast(u16)pc)
		}
	}

	return
}
