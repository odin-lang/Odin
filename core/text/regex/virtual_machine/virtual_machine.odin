package regex_vm

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "base:intrinsics"
@require import "core:io"
import "core:slice"
import "core:text/regex/common"
import "core:text/regex/parser"
import "core:unicode/utf8"

Rune_Class_Range  :: parser.Rune_Class_Range

// NOTE: This structure differs intentionally from the one in `regex/parser`,
// as this data doesn't need to be a dynamic array once it hits the VM.
Rune_Class_Data :: struct {
	runes: []rune,
	ranges: []Rune_Class_Range,
}

Opcode :: enum u8 {
	                                    // | [ operands ]
	Match                       = 0x00, // |
	Match_And_Exit              = 0x01, // |
	Byte                        = 0x02, // | u8
	Rune                        = 0x03, // | i32
	Rune_Class                  = 0x04, // | u8
	Rune_Class_Negated          = 0x05, // | u8
	Wildcard                    = 0x06, // |
	Jump                        = 0x07, // | u16
	Split                       = 0x08, // | u16, u16
	Save                        = 0x09, // | u8
	Assert_Start                = 0x0A, // |
	Assert_End                  = 0x0B, // |
	Assert_Word_Boundary        = 0x0C, // |
	Assert_Non_Word_Boundary    = 0x0D, // |
	Multiline_Open              = 0x0E, // |
	Multiline_Close             = 0x0F, // |
	Wait_For_Byte               = 0x10, // | u8
	Wait_For_Rune               = 0x11, // | i32
	Wait_For_Rune_Class         = 0x12, // | u8
	Wait_For_Rune_Class_Negated = 0x13, // | u8
	Match_All_And_Escape        = 0x14, // |
}

Thread :: struct {
	pc: int,
	saved: ^[2 * common.MAX_CAPTURE_GROUPS]int,
}

Program :: []Opcode

Machine :: struct {
	// Program state
	memory: string,
	class_data: []Rune_Class_Data,
	code: Program,

	// Thread state
	top_thread: int,
	threads: [^]Thread,
	next_threads: [^]Thread,

	// The busy map is used to merge threads based on their program counters.
	busy_map: []u64,

	// Global state
	string_pointer: int,

	current_rune: rune,
	current_rune_size: int,
	next_rune: rune,
	next_rune_size: int,
}


// @MetaCharacter
// NOTE: This must be kept in sync with the compiler & tokenizer.
is_word_class :: #force_inline proc "contextless" (r: rune) -> bool {
	switch r {
	case '0'..='9', 'A'..='Z', '_', 'a'..='z':
		return true
	case:
		return false
	}
}

set_busy_map :: #force_inline proc "contextless" (vm: ^Machine, pc: int) -> bool #no_bounds_check {
	slot := cast(u64)pc >> 6
	bit: u64 = 1 << (cast(u64)pc & 0x3F)
	if vm.busy_map[slot] & bit > 0 {
		return false
	}
	vm.busy_map[slot] |= bit
	return true
}

check_busy_map :: #force_inline proc "contextless" (vm: ^Machine, pc: int) -> bool #no_bounds_check {
	slot := cast(u64)pc >> 6
	bit: u64 = 1 << (cast(u64)pc & 0x3F)
	return vm.busy_map[slot] & bit > 0
}

add_thread :: proc(vm: ^Machine, saved: ^[2 * common.MAX_CAPTURE_GROUPS]int, pc: int) #no_bounds_check {
	if check_busy_map(vm, pc) {
		return
	}

	saved := saved
	pc := pc

	resolution_loop: for {
		if !set_busy_map(vm, pc) {
			return
		}

		when common.ODIN_DEBUG_REGEX {
			io.write_string(common.debug_stream, "Thread [PC:")
			common.write_padded_hex(common.debug_stream, pc, 4)
			io.write_string(common.debug_stream, "] thinking about ")
			io.write_string(common.debug_stream, opcode_to_name(vm.code[pc]))
			io.write_rune(common.debug_stream, '\n')
		}

		#partial switch vm.code[pc] {
		case .Jump:
			pc = cast(int)intrinsics.unaligned_load(cast(^u16)&vm.code[pc + size_of(Opcode)])
			continue

		case .Split:
			jmp_x := cast(int)intrinsics.unaligned_load(cast(^u16)&vm.code[pc + size_of(Opcode)])
			jmp_y := cast(int)intrinsics.unaligned_load(cast(^u16)&vm.code[pc + size_of(Opcode) + size_of(u16)])

			add_thread(vm, saved, jmp_x)
			pc = jmp_y
			continue

		case .Save:
			new_saved := new([2 * common.MAX_CAPTURE_GROUPS]int)
			new_saved ^= saved^
			saved = new_saved

			index := vm.code[pc + size_of(Opcode)]
			sp := vm.string_pointer+vm.current_rune_size
			saved[index] = sp

			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "Thread [PC:")
				common.write_padded_hex(common.debug_stream, pc, 4)
				io.write_string(common.debug_stream, "] saving state: (slot ")
				io.write_int(common.debug_stream, cast(int)index)
				io.write_string(common.debug_stream, " = ")
				io.write_int(common.debug_stream, sp)
				io.write_string(common.debug_stream, ")\n")
			}

			pc += size_of(Opcode) + size_of(u8)
			continue

		case .Assert_Start:
			sp := vm.string_pointer+vm.current_rune_size
			if sp == 0 {
				pc += size_of(Opcode)
				continue
			}
		case .Assert_End:
			sp := vm.string_pointer+vm.current_rune_size
			if sp == len(vm.memory) {
				pc += size_of(Opcode)
				continue
			}
		case .Multiline_Open:
			sp := vm.string_pointer+vm.current_rune_size
			if sp == 0 || sp == len(vm.memory) {
				if vm.next_rune == '\r' || vm.next_rune == '\n' {
					// The VM is currently on a newline at the string boundary,
					// so consume the newline next frame.
					when common.ODIN_DEBUG_REGEX {
						io.write_string(common.debug_stream, "*** New thread added [PC:")
						common.write_padded_hex(common.debug_stream, pc, 4)
						io.write_string(common.debug_stream, "]\n")
					}
					vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
					vm.top_thread += 1
				} else {
					// Skip the `Multiline_Close` opcode.
					pc += 2 * size_of(Opcode)
					continue
				}
			} else {
				// Not on a string boundary.
				// Try to consume a newline next frame in the other opcode loop.
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "*** New thread added [PC:")
					common.write_padded_hex(common.debug_stream, pc, 4)
					io.write_string(common.debug_stream, "]\n")
				}
				vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
				vm.top_thread += 1
			}
		case .Assert_Word_Boundary:
			sp := vm.string_pointer+vm.current_rune_size
			if sp == 0 || sp == len(vm.memory) {
				pc += size_of(Opcode)
				continue
			} else {
				last_rune_is_wc := is_word_class(vm.current_rune)
				this_rune_is_wc := is_word_class(vm.next_rune)

				if last_rune_is_wc && !this_rune_is_wc || !last_rune_is_wc && this_rune_is_wc {
					pc += size_of(Opcode)
					continue
				}
			}
		case .Assert_Non_Word_Boundary:
			sp := vm.string_pointer+vm.current_rune_size
			if sp != 0 && sp != len(vm.memory) {
				last_rune_is_wc := is_word_class(vm.current_rune)
				this_rune_is_wc := is_word_class(vm.next_rune)

				if last_rune_is_wc && this_rune_is_wc || !last_rune_is_wc && !this_rune_is_wc {
					pc += size_of(Opcode)
					continue
				}
			}

		case .Wait_For_Byte:
			operand := cast(rune)vm.code[pc + size_of(Opcode)]
			if vm.next_rune == operand {
				add_thread(vm, saved, pc + size_of(Opcode) + size_of(u8))
			}

			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "*** New thread added [PC:")
				common.write_padded_hex(common.debug_stream, pc, 4)
				io.write_string(common.debug_stream, "]\n")
			}
			vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
			vm.top_thread += 1

		case .Wait_For_Rune:
			operand := intrinsics.unaligned_load(cast(^rune)&vm.code[pc + size_of(Opcode)])
			if vm.next_rune == operand {
				add_thread(vm, saved, pc + size_of(Opcode) + size_of(rune))
			}

			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "*** New thread added [PC:")
				common.write_padded_hex(common.debug_stream, pc, 4)
				io.write_string(common.debug_stream, "]\n")
			}
			vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
			vm.top_thread += 1

		case .Wait_For_Rune_Class:
			operand := cast(u8)vm.code[pc + size_of(Opcode)]
			class_data := vm.class_data[operand]
			next_rune := vm.next_rune

			check: {
				for r in class_data.runes {
					if next_rune == r {
						add_thread(vm, saved, pc + size_of(Opcode) + size_of(u8))
						break check
					}
				}
				for range in class_data.ranges {
					if range.lower <= next_rune && next_rune <= range.upper {
						add_thread(vm, saved, pc + size_of(Opcode) + size_of(u8))
						break check
					}
				}
			}
			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "*** New thread added [PC:")
				common.write_padded_hex(common.debug_stream, pc, 4)
				io.write_string(common.debug_stream, "]\n")
			}
			vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
			vm.top_thread += 1

		case .Wait_For_Rune_Class_Negated:
			operand := cast(u8)vm.code[pc + size_of(Opcode)]
			class_data := vm.class_data[operand]
			next_rune := vm.next_rune

			check_negated: {
				for r in class_data.runes {
					if next_rune == r {
						break check_negated
					}
				}
				for range in class_data.ranges {
					if range.lower <= next_rune && next_rune <= range.upper {
						break check_negated
					}
				}
				add_thread(vm, saved, pc + size_of(Opcode) + size_of(u8))
			}
			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "*** New thread added [PC:")
				common.write_padded_hex(common.debug_stream, pc, 4)
				io.write_string(common.debug_stream, "]\n")
			}
			vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
			vm.top_thread += 1

		case:
			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "*** New thread added [PC:")
				common.write_padded_hex(common.debug_stream, pc, 4)
				io.write_string(common.debug_stream, "]\n")
			}
			vm.next_threads[vm.top_thread] = Thread{ pc = pc, saved = saved }
			vm.top_thread += 1
		}

		break resolution_loop
	}

	return
}

run :: proc(vm: ^Machine, $UNICODE_MODE: bool) -> (saved: ^[2 * common.MAX_CAPTURE_GROUPS]int, ok: bool) #no_bounds_check {
	when UNICODE_MODE {
		vm.next_rune, vm.next_rune_size = utf8.decode_rune_in_string(vm.memory)
	} else {
		if len(vm.memory) > 0 {
			vm.next_rune = cast(rune)vm.memory[0]
			vm.next_rune_size = 1
		}
	}

	when common.ODIN_DEBUG_REGEX {
		io.write_string(common.debug_stream, "### Adding initial thread.\n")
	}

	{
		starter_saved := new([2 * common.MAX_CAPTURE_GROUPS]int)
		starter_saved ^= -1

		add_thread(vm, starter_saved, 0)
	}

	// `add_thread` adds to `next_threads` by default, but we need to put this
	// thread in the current thread buffer.
	vm.threads, vm.next_threads = vm.next_threads, vm.threads

	when common.ODIN_DEBUG_REGEX {
		io.write_string(common.debug_stream, "### VM starting.\n")
		defer io.write_string(common.debug_stream, "### VM finished.\n")
	}

	for {
		slice.zero(vm.busy_map[:])

		assert(vm.string_pointer <= len(vm.memory), "VM string pointer went out of bounds.")

		current_rune := vm.next_rune
		vm.current_rune = current_rune
		vm.current_rune_size = vm.next_rune_size
		when UNICODE_MODE {
			vm.next_rune, vm.next_rune_size = utf8.decode_rune_in_string(vm.memory[vm.string_pointer+vm.current_rune_size:])
		} else {
			if vm.string_pointer+size_of(u8) < len(vm.memory) {
				vm.next_rune = cast(rune)vm.memory[vm.string_pointer+size_of(u8)]
				vm.next_rune_size = size_of(u8)
			} else {
				vm.next_rune = 0
				vm.next_rune_size = 0
			}
		}

		when common.ODIN_DEBUG_REGEX {
			io.write_string(common.debug_stream, ">>> Dispatching rune: ")
			io.write_encoded_rune(common.debug_stream, current_rune)
			io.write_byte(common.debug_stream, '\n')
		}

		thread_count := vm.top_thread
		vm.top_thread = 0
		thread_loop: for i := 0; i < thread_count; i += 1 {
			t := vm.threads[i]

			when common.ODIN_DEBUG_REGEX {
				io.write_string(common.debug_stream, "Thread [PC:")
				common.write_padded_hex(common.debug_stream, t.pc, 4)
				io.write_string(common.debug_stream, "] stepping on ")
				io.write_string(common.debug_stream, opcode_to_name(vm.code[t.pc]))
				io.write_byte(common.debug_stream, '\n')
			}

			#partial opcode: switch vm.code[t.pc] {
			case .Match:
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "Thread matched!\n")
				}
				saved = t.saved
				ok = true
				break thread_loop

			case .Match_And_Exit:
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "Thread matched! (Exiting)\n")
				}
				return nil, true

			case .Byte:
				operand := cast(rune)vm.code[t.pc + size_of(Opcode)]
				if current_rune == operand {
					add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
				}

			case .Rune:
				operand := intrinsics.unaligned_load(cast(^rune)&vm.code[t.pc + size_of(Opcode)])
				if current_rune == operand {
					add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(rune))
				}

			case .Rune_Class:
				operand := cast(u8)vm.code[t.pc + size_of(Opcode)]
				class_data := vm.class_data[operand]

				for r in class_data.runes {
					if current_rune == r {
						add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
						break opcode
					}
				}
				for range in class_data.ranges {
					if range.lower <= current_rune && current_rune <= range.upper {
						add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
						break opcode
					}
				}

			case .Rune_Class_Negated:
				operand := cast(u8)vm.code[t.pc + size_of(Opcode)]
				class_data := vm.class_data[operand]
				for r in class_data.runes {
					if current_rune == r {
						break opcode
					}
				}
				for range in class_data.ranges {
					if range.lower <= current_rune && current_rune <= range.upper {
						break opcode
					}
				}
				add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))

			case .Wildcard:
				add_thread(vm, t.saved, t.pc + size_of(Opcode))

			case .Multiline_Open:
				if current_rune == '\n' {
					// UNIX newline.
					add_thread(vm, t.saved, t.pc + 2 * size_of(Opcode))
				} else if current_rune == '\r' {
					if vm.next_rune == '\n' {
						// Windows newline. (1/2)
						add_thread(vm, t.saved, t.pc + size_of(Opcode))
					} else {
						// Mac newline.
						add_thread(vm, t.saved, t.pc + 2 * size_of(Opcode))
					}
				}
			case .Multiline_Close:
				if current_rune == '\n' {
					// Windows newline. (2/2)
					add_thread(vm, t.saved, t.pc + size_of(Opcode))
				}

			case .Wait_For_Byte:
				operand := cast(rune)vm.code[t.pc + size_of(Opcode)]
				if vm.next_rune == operand {
					add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
				}
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "*** New thread added [PC:")
					common.write_padded_hex(common.debug_stream, t.pc, 4)
					io.write_string(common.debug_stream, "]\n")
				}
				vm.next_threads[vm.top_thread] = Thread{ pc = t.pc, saved = t.saved }
				vm.top_thread += 1

			case .Wait_For_Rune:
				operand := intrinsics.unaligned_load(cast(^rune)&vm.code[t.pc + size_of(Opcode)])
				if vm.next_rune == operand {
					add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(rune))
				}
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "*** New thread added [PC:")
					common.write_padded_hex(common.debug_stream, t.pc, 4)
					io.write_string(common.debug_stream, "]\n")
				}
				vm.next_threads[vm.top_thread] = Thread{ pc = t.pc, saved = t.saved }
				vm.top_thread += 1

			case .Wait_For_Rune_Class:
				operand := cast(u8)vm.code[t.pc + size_of(Opcode)]
				class_data := vm.class_data[operand]
				next_rune := vm.next_rune

				check: {
					for r in class_data.runes {
						if next_rune == r {
							add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
							break check
						}
					}
					for range in class_data.ranges {
						if range.lower <= next_rune && next_rune <= range.upper {
							add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
							break check
						}
					}
				}
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "*** New thread added [PC:")
					common.write_padded_hex(common.debug_stream, t.pc, 4)
					io.write_string(common.debug_stream, "]\n")
				}
				vm.next_threads[vm.top_thread] = Thread{ pc = t.pc, saved = t.saved }
				vm.top_thread += 1

			case .Wait_For_Rune_Class_Negated:
				operand := cast(u8)vm.code[t.pc + size_of(Opcode)]
				class_data := vm.class_data[operand]
				next_rune := vm.next_rune

				check_negated: {
					for r in class_data.runes {
						if next_rune == r {
							break check_negated
						}
					}
					for range in class_data.ranges {
						if range.lower <= next_rune && next_rune <= range.upper {
							break check_negated
						}
					}
					add_thread(vm, t.saved, t.pc + size_of(Opcode) + size_of(u8))
				}
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "*** New thread added [PC:")
					common.write_padded_hex(common.debug_stream, t.pc, 4)
					io.write_string(common.debug_stream, "]\n")
				}
				vm.next_threads[vm.top_thread] = Thread{ pc = t.pc, saved = t.saved }
				vm.top_thread += 1

			case .Match_All_And_Escape:
				t.pc += size_of(Opcode)
				// The point of this loop is to walk out of wherever this
				// opcode lives to the end of the program, while saving the
				// index to the length of the string at each pass on the way.
				escape_loop: for {
					#partial switch vm.code[t.pc] {
					case .Match, .Match_And_Exit:
						break escape_loop

					case .Jump:
						t.pc = cast(int)intrinsics.unaligned_load(cast(^u16)&vm.code[t.pc + size_of(Opcode)])

					case .Save:
						index := vm.code[t.pc + size_of(Opcode)]
						t.saved[index] = len(vm.memory)
						t.pc += size_of(Opcode) + size_of(u8)

					case .Match_All_And_Escape:
						// Layering these is fine.
						t.pc += size_of(Opcode)

					// If the loop has to process any opcode not listed above,
					// it means someone did something odd like `a(.*$)b`, in
					// which case, just fail. Technically, the expression makes
					// no sense.
					case:
						break opcode
					}
				}

				saved = t.saved
				ok = true
				return

			case:
				when common.ODIN_DEBUG_REGEX {
					io.write_string(common.debug_stream, "Opcode: ")
					io.write_int(common.debug_stream, cast(int)vm.code[t.pc])
					io.write_string(common.debug_stream, "\n")
				}
				panic("Invalid opcode in RegEx thread loop.")
			}
		}

		vm.threads, vm.next_threads = vm.next_threads, vm.threads

		when common.ODIN_DEBUG_REGEX {
			io.write_string(common.debug_stream, "<<< Frame ended. (Threads: ")
			io.write_int(common.debug_stream, vm.top_thread)
			io.write_string(common.debug_stream, ")\n")
		}

		if vm.string_pointer == len(vm.memory) || vm.top_thread == 0 {
			break
		}

		vm.string_pointer += vm.current_rune_size
	}

	return
}

opcode_count :: proc(code: Program) -> (opcodes: int) {
	iter := Opcode_Iterator{ code, 0 }
	for _ in iterate_opcodes(&iter) {
		opcodes += 1
	}
	return
}

create :: proc(code: Program, str: string) -> (vm: Machine) {
	assert(len(code) > 0, "RegEx VM has no instructions.")

	vm.memory = str
	vm.code = code

	sizing := len(code) >> 6 + (1 if len(code) & 0x3F > 0 else 0)
	assert(sizing > 0)
	vm.busy_map = make([]u64, sizing)

	max_possible_threads := max(1, opcode_count(vm.code) - 1)

	vm.threads = make([^]Thread, max_possible_threads)
	vm.next_threads = make([^]Thread, max_possible_threads)

	return
}
