package main

// =============================================================================
// Mnemonic Builder Generator
// =============================================================================
//
// This script generates mnemonic_builders.odin by iterating the encoder's ENCODING_TABLE
// and creating typed builder procedures with overloading for each mnemonic.
//
// Run with: odin run tools/gen_mnemonic_builders.odin -file
//
// Output: mnemonic_builders.odin (written to current directory, move to package root)

import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import x86 "../"

// Convert mnemonic to lowercase string
mnemonic_to_lower :: proc(m: x86.Mnemonic) -> string {
	name := fmt.tprintf("%v", m)
	return strings.to_lower(name)
}

// Operand signature for a specific encoding variant
Operand_Signature :: struct {
	types: [4]Operand_Info,
	count: int,
}

Operand_Info :: struct {
	op_type:   x86.Operand_Type,
	is_memory: bool, // For RM operands, distinguishes reg vs mem variant
}

// Collected procedure to generate
Proc_Entry :: struct {
	mnemonic:  x86.Mnemonic,
	sig:       Operand_Signature,
	proc_name: string,
}

main :: proc() {
	fmt.println("Generating mnemonic builders from ENCODING_TABLE...")

	sb := strings.builder_make()

	generate_header(&sb)
	generate_memory_wrappers(&sb)

	// Collect all procedures grouped by mnemonic
	procs_by_mnemonic: map[x86.Mnemonic][dynamic]Proc_Entry
	defer {
		for _, v in procs_by_mnemonic {
			delete(v)
		}
		delete(procs_by_mnemonic)
	}

	// Track unique procedure names to avoid duplicates (key = mnemonic + proc_name)
	seen_proc_names: map[string]bool
	defer delete(seen_proc_names)

	for mnemonic in x86.Mnemonic {
		if mnemonic == .INVALID { continue }

		encodings := x86.ENCODING_TABLE[mnemonic]
		if len(encodings) == 0 { continue }

		for enc in encodings {
			// Skip encodings we can't generate builders for (implicit-only operands, etc.)
			can_generate_builder(enc) or_continue

			// For RM operands, generate both register and memory variants
			variants := get_operand_variants(enc)

			for variant in variants {
				sig := variant
				proc_name := generate_proc_name(mnemonic, sig)

				// Use the generated procedure name as the dedup key
				// This catches cases like MOV {RM8, R8} vs MOV {R8, RM8} which both
				// generate mov_r8_r8 when RM8 is used as register
				if proc_name in seen_proc_names { continue }
				seen_proc_names[proc_name] = true

				entry := Proc_Entry{
					mnemonic = mnemonic,
					sig = sig,
					proc_name = proc_name,
				}

				if mnemonic not_in procs_by_mnemonic {
					procs_by_mnemonic[mnemonic] = make([dynamic]Proc_Entry)
				}
				append(&procs_by_mnemonic[mnemonic], entry)
			}
		}
	}

	// Generate all individual procedures
	strings.write_string(&sb, `// =============================================================================
// Individual Typed Builder Procedures
// =============================================================================

`)

	// Sort mnemonics for consistent output
	mnemonic_list: [dynamic]x86.Mnemonic
	defer delete(mnemonic_list)
	for m in procs_by_mnemonic {
		append(&mnemonic_list, m)
	}
	slice.sort_by(mnemonic_list[:], proc(a, b: x86.Mnemonic) -> bool {
		return int(a) < int(b)
	})

	max_name_padding := 0
	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		for entry in procs {
			max_name_padding = max(max_name_padding, len(entry.proc_name))
		}
	}


	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		for entry in procs {
			generate_proc(&sb, entry, max_name_padding)
		}
		for entry in procs {
			generate_emit_proc(&sb, entry, max_name_padding)
		}
	}

	// Generate overload groups
	strings.write_string(&sb, `
// =============================================================================
// Overload Groups
// =============================================================================

`)

	for mnemonic in mnemonic_list {
		procs := procs_by_mnemonic[mnemonic]
		if len(procs) == 0 { continue }

		mnemonic_lower := mnemonic_to_lower(mnemonic)

		// inst_ overload group
		strings.write_string(&sb, "inst_")
		strings.write_string(&sb, mnemonic_lower)
		for n := max_name_padding-len(mnemonic_lower); n > 0; n -= 1 {
			strings.write_byte(&sb, ' ')
		}
		if len(procs) == 1 {
			strings.write_string(&sb, " :: ")
			strings.write_string(&sb, procs[0].proc_name)
			strings.write_string(&sb, "\n")
		} else {
			strings.write_string(&sb, " :: proc{ ")
			for entry, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				strings.write_string(&sb, entry.proc_name)
			}
			strings.write_string(&sb, " }\n")
		}

		// emit_ overload group
		strings.write_string(&sb, "emit_")
		strings.write_string(&sb, mnemonic_lower)
		for n := max_name_padding-len(mnemonic_lower); n > 0; n -= 1 {
			strings.write_byte(&sb, ' ')
		}

		if len(procs) == 1 {
			emit_name := strings.concatenate({"emit_", procs[0].proc_name[5:]})

			strings.write_string(&sb, " :: ")
			strings.write_string(&sb, emit_name)
			strings.write_string(&sb, "\n")
		} else {
			strings.write_string(&sb, " :: proc{ ")

			for entry, i in procs {
				if i > 0 { strings.write_string(&sb, ", ") }
				// Replace "inst_" prefix with "emit_"
				emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})
				strings.write_string(&sb, emit_name)
			}
			strings.write_string(&sb, " }\n")
		}

	}

	output := strings.to_string(sb)

	err := os.write_entire_file("mnemonic_builders.odin", transmute([]u8)output)
	if err == nil {
		fmt.println("Generated mnemonic_builders.odin successfully!")
		fmt.printf("Total mnemonics with builders: %d\n", len(mnemonic_list))

		total_procs := 0
		for m in mnemonic_list {
			total_procs += len(procs_by_mnemonic[m])
		}
		fmt.printf("Total procedures generated: %d\n", total_procs)
	} else {
		fmt.eprintln("Failed to write mnemonic_builders.odin")
	}
}

generate_header :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `package rexcode_x86

// =============================================================================
// GENERATED FILE - DO NOT EDIT
// =============================================================================
//
// Generated by gen_mnemonic_builders.odin from ENCODING_TABLE
// Regenerate with: odin run tools/gen_mnemonic_builders.odin -file && mv mnemonic_builders.odin ../
//
// This file provides typed mnemonic builder procedures with overloading.
// Each mnemonic has multiple overloaded variants for different operand types.

`)
}

generate_memory_wrappers :: proc(sb: ^strings.Builder) {
	strings.write_string(sb, `// =============================================================================
// Typed Memory Wrapper Structs
// =============================================================================
// These provide type safety for memory operands of specific sizes.

Mem8   :: distinct struct { mem: Memory }
Mem16  :: distinct struct { mem: Memory }
Mem32  :: distinct struct { mem: Memory }
Mem64  :: distinct struct { mem: Memory }
Mem128 :: distinct struct { mem: Memory }
Mem256 :: distinct struct { mem: Memory }
Mem512 :: distinct struct { mem: Memory }

// Memory wrapper constructors
@(require_results)
mem8 :: #force_inline proc "contextless" (m: Memory) -> Mem8 {
	return Mem8{ mem = m }
}

@(require_results)
mem16 :: #force_inline proc "contextless" (m: Memory) -> Mem16 {
	return Mem16{ mem = m }
}

@(require_results)
mem32 :: #force_inline proc "contextless" (m: Memory) -> Mem32 {
	return Mem32{ mem = m }
}

@(require_results)
mem64 :: #force_inline proc "contextless" (m: Memory) -> Mem64 {
	return Mem64{ mem = m }
}

@(require_results)
mem128 :: #force_inline proc "contextless" (m: Memory) -> Mem128 {
	return Mem128{ mem = m }
}

@(require_results)
mem256 :: #force_inline proc "contextless" (m: Memory) -> Mem256 {
	return Mem256{ mem = m }
}

@(require_results)
mem512 :: #force_inline proc "contextless" (m: Memory) -> Mem512 {
	return Mem512{ mem = m }
}

`)
}

// Check if encoding can have a builder generated
// Returns true if:
// 1. All operands are NONE (no-operand instruction like RET, NOP)
// 2. At least one explicit (non-implicit) operand exists
can_generate_builder :: proc(enc: x86.Encoding) -> bool {
	has_any_operand := false
	has_explicit := false

	for op in enc.ops {
		if op == .NONE { continue }

		has_any_operand = true

		// Skip purely implicit operands
		#partial switch op {
		case .AL_IMPL, .AX_IMPL, .EAX_IMPL, .RAX_IMPL, .CL_IMPL, .DX_IMPL, .ONE_IMPL, .ST0_IMPL, .XMM0_IMPL:
			continue
		case .MOFFS8, .MOFFS16, .MOFFS32, .MOFFS64:
			// Skip moffs - special encoding
			continue
		case .PTR16_16, .PTR16_32, .PTR16_64, .M16_16, .M16_32, .M16_64:
			// Skip far pointers
			continue
		case .IMM8SX:
			// Skip sign-extended immediates for now
			continue
		case:
			has_explicit = true
		}
	}

	// Generate builder if: no operands at all, OR has explicit operands
	return !has_any_operand || has_explicit
}

// Get all variants for an encoding (expands RM operands into reg and mem variants)
get_operand_variants :: proc(enc: x86.Encoding) -> []Operand_Signature {
	result: [dynamic]Operand_Signature

	// Count RM operands
	rm_positions: [4]int
	rm_count := 0

	for op, i in enc.ops {
		if is_rm_operand(op) {
			rm_positions[rm_count] = i
			rm_count += 1
		}
	}

	// Generate all combinations
	// For N RM operands, we have 2^N variants
	variant_count := 1 << uint(rm_count)

	for variant_idx in 0..<variant_count {
		sig: Operand_Signature
		sig.count = 0

		valid := true
		for op, i in enc.ops {
			if op == .NONE { continue }

			// Skip implicit operands
			if is_implicit_operand(op) { continue }

			info := Operand_Info{
				op_type   = op,
				is_memory = false,
			}

			// Check if this is an RM operand
			if is_rm_operand(op) {
				// Find which RM position this is
				for j in 0..<rm_count {
					if rm_positions[j] == i {
						// Check bit j in variant_idx
						info.is_memory = (variant_idx & (1 << uint(j))) != 0
						break
					}
				}
			} else if is_memory_only_operand(op) {
				info.is_memory = true
			}

			// Validate this operand can be generated
			if !can_generate_operand(info) {
				valid = false
				break
			}

			sig.types[sig.count] = info
			sig.count += 1
		}

		if valid {
			append(&result, sig)
		}
	}

	// If no variants were generated but encoding has no operands, add empty signature
	if len(result) == 0 {
		has_any := false
		for op in enc.ops {
			if op != .NONE {
				has_any = true
				break
			}
		}
		if !has_any {
			append(&result, Operand_Signature{})
		}
	}

	return result[:]
}

is_rm_operand :: proc(op: x86.Operand_Type) -> bool {
	#partial switch op {
	case .RM8, .RM16, .RM32, .RM64:
		return true
	case .XMM_M32, .XMM_M64, .XMM_M128:
		return true
	case .YMM_M256:
		return true
	case .ZMM_M512:
		return true
	case .MM_M64:
		return true
	case .K_M8, .K_M16, .K_M32, .K_M64:
		return true
	}
	return false
}

is_memory_only_operand :: proc(op: x86.Operand_Type) -> bool {
	#partial switch op {
	case .M, .M8, .M16, .M32, .M64, .M80, .M128, .M256, .M512:
		return true
	}
	return false
}

is_implicit_operand :: proc(op: x86.Operand_Type) -> bool {
	#partial switch op {
	case .AL_IMPL, .AX_IMPL, .EAX_IMPL, .RAX_IMPL, .CL_IMPL, .DX_IMPL, .ONE_IMPL, .ST0_IMPL, .XMM0_IMPL:
		return true
	case .MOFFS8, .MOFFS16, .MOFFS32, .MOFFS64:
		return true
	case .PTR16_16, .PTR16_32, .PTR16_64, .M16_16, .M16_32, .M16_64:
		return true
	}
	return false
}

can_generate_operand :: proc(info: Operand_Info) -> bool {
	op := info.op_type

	#partial switch op {
	// GPR registers
	case .R8, .R16, .R32, .R64:
		return true
	// RM operands
	case .RM8, .RM16, .RM32, .RM64:
		return true
	// Memory only
	case .M, .M8, .M16, .M32, .M64, .M128, .M256, .M512:
		return true
	// Immediates
	case .IMM8, .IMM16, .IMM32, .IMM64:
		return true
	// Relatives
	case .REL8, .REL32:
		return true
	// Vector registers
	case .XMM, .YMM, .ZMM:
		return true
	// Vector reg or memory
	case .XMM_M32, .XMM_M64, .XMM_M128, .YMM_M256, .ZMM_M512:
		return true
	// MMX
	case .MM, .MM_M64:
		return true
	// Segment registers
	case .SREG:
		return true
	// Control/debug
	case .CR, .DR:
		return true
	// Opmask
	case .K, .K_M8, .K_M16, .K_M32, .K_M64:
		return true
	// x87
	case .STI:
		return true
	}
	return false
}

// Generate unique signature key for deduplication
signature_key :: proc(mnemonic: x86.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	fmt.sbprintf(&sb, "%v:", mnemonic)

	for i in 0..<sig.count {
		info := sig.types[i]
		fmt.sbprintf(&sb, "%v:%v,", info.op_type, info.is_memory)
	}

	return strings.clone(strings.to_string(sb))
}

// Generate procedure name from mnemonic and signature (without prefix)
generate_proc_name :: proc(mnemonic: x86.Mnemonic, sig: Operand_Signature) -> string {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)

	mnemonic_lower := mnemonic_to_lower(mnemonic)
	strings.write_string(&sb, "inst_")
	strings.write_string(&sb, mnemonic_lower)

	if sig.count == 0 {
		// No-operand instructions get _none suffix to avoid collision with overload group
		strings.write_string(&sb, "_none")
	} else {
		for i in 0..<sig.count {
			strings.write_string(&sb, "_")
			info := sig.types[i]
			strings.write_string(&sb, operand_suffix(info))
		}
	}

	return strings.clone(strings.to_string(sb))
}

// Get suffix for operand in procedure name
operand_suffix :: proc(info: Operand_Info) -> string {
	op := info.op_type

	// For RM operands, use r or m prefix based on is_memory flag
	if info.is_memory {
		#partial switch op {
		case .RM8:      return "m8"
		case .RM16:     return "m16"
		case .RM32:     return "m32"
		case .RM64:     return "m64"
		case .XMM_M32:  return "m32"
		case .XMM_M64:  return "m64"
		case .XMM_M128: return "m128"
		case .YMM_M256: return "m256"
		case .ZMM_M512: return "m512"
		case .MM_M64:   return "m64"
		case .K_M8:     return "m8"
		case .K_M16:    return "m16"
		case .K_M32:    return "m32"
		case .K_M64:    return "m64"
		case .M:        return "m"
		case .M8:       return "m8"
		case .M16:      return "m16"
		case .M32:      return "m32"
		case .M64:      return "m64"
		case .M128:     return "m128"
		case .M256:     return "m256"
		case .M512:     return "m512"
		}
	} else {
		#partial switch op {
		case .RM8:                          return "r8"
		case .RM16:                         return "r16"
		case .RM32:                         return "r32"
		case .RM64:                         return "r64"
		case .XMM_M32, .XMM_M64, .XMM_M128: return "xmm"
		case .YMM_M256:                     return "ymm"
		case .ZMM_M512:                     return "zmm"
		case .MM_M64:                       return "mm"
		case .K_M8, .K_M16, .K_M32, .K_M64: return "k"
		}
	}

	// Non-RM operands
	#partial switch op {
	case .R8:    return "r8"
	case .R16:   return "r16"
	case .R32:   return "r32"
	case .R64:   return "r64"
	case .XMM:   return "xmm"
	case .YMM:   return "ymm"
	case .ZMM:   return "zmm"
	case .MM:    return "mm"
	case .IMM8:  return "imm8"
	case .IMM16: return "imm16"
	case .IMM32: return "imm32"
	case .IMM64: return "imm64"
	case .REL8:  return "rel8"
	case .REL32: return "rel32"
	case .SREG:  return "sreg"
	case .CR:    return "cr"
	case .DR:    return "dr"
	case .K:     return "k"
	case .STI:   return "st"
	case .M:     return "m"
	case .M8:    return "m8"
	case .M16:   return "m16"
	case .M32:   return "m32"
	case .M64:   return "m64"
	case .M128:  return "m128"
	case .M256:  return "m256"
	case .M512:  return "m512"
	}

	return "unk"
}

// Get Odin type for operand
operand_odin_type :: proc(info: Operand_Info) -> string {
	op := info.op_type

	// For RM operands, use appropriate type based on is_memory flag
	if info.is_memory {
		#partial switch op {
		case .RM8, .K_M8:                      return "Mem8"
		case .RM16, .K_M16:                    return "Mem16"
		case .RM32, .XMM_M32, .K_M32:          return "Mem32"
		case .RM64, .XMM_M64, .MM_M64, .K_M64: return "Mem64"
		case .XMM_M128:                        return "Mem128"
		case .YMM_M256:                        return "Mem256"
		case .ZMM_M512:                        return "Mem512"
		case .M:                               return "Memory"
		case .M8:                              return "Mem8"
		case .M16:                             return "Mem16"
		case .M32:                             return "Mem32"
		case .M64:                             return "Mem64"
		case .M128:                            return "Mem128"
		case .M256:                            return "Mem256"
		case .M512:                            return "Mem512"
		}
	} else {
		#partial switch op {
		case .RM8:                          return "GPR8"
		case .RM16:                         return "GPR16"
		case .RM32:                         return "GPR32"
		case .RM64:                         return "GPR64"
		case .XMM_M32, .XMM_M64, .XMM_M128: return "XMM"
		case .YMM_M256:                     return "YMM"
		case .ZMM_M512:                     return "ZMM"
		case .MM_M64:                       return "MM"
		case .K_M8, .K_M16, .K_M32, .K_M64: return "KREG"
		}
	}

	// Non-RM operands
	#partial switch op {
	case .R8:    return "GPR8"
	case .R16:   return "GPR16"
	case .R32:   return "GPR32"
	case .R64:   return "GPR64"
	case .XMM:   return "XMM"
	case .YMM:   return "YMM"
	case .ZMM:   return "ZMM"
	case .MM:    return "MM"
	case .IMM8:  return "i8"
	case .IMM16: return "i16"
	case .IMM32: return "i32"
	case .IMM64: return "i64"
	case .REL8:  return "i8"
	case .REL32: return "i32"
	case .SREG:  return "SREG"
	case .CR:    return "CREG"
	case .DR:    return "DREG"
	case .K:     return "KREG"
	case .STI:   return "ST"
	case .M:     return "Memory"
	case .M8:    return "Mem8"
	case .M16:   return "Mem16"
	case .M32:   return "Mem32"
	case .M64:   return "Mem64"
	case .M128:  return "Mem128"
	case .M256:  return "Mem256"
	case .M512:  return "Mem512"
	}

	return "unknown"
}

// Get operand size in bytes
operand_size :: proc(info: Operand_Info) -> u8 {
	op := info.op_type

	#partial switch op {
	case .R8, .RM8, .M8, .IMM8, .K_M8:
		return 1
	case .R16, .RM16, .M16, .IMM16, .K_M16:
		return 2
	case .R32, .RM32, .M32, .IMM32, .XMM_M32, .K_M32, .REL32:
		return 4
	case .R64, .RM64, .M64, .IMM64, .XMM_M64, .MM, .MM_M64, .K_M64:
		return 8
	case .XMM, .XMM_M128, .M128:
		return 16
	case .YMM, .YMM_M256, .M256:
		return 32
	case .ZMM, .ZMM_M512, .M512:
		return 64
	case .REL8:
		return 1
	case .SREG:
		return 2
	case .CR, .DR:
		return 8
	case .K:
		return 8
	case .STI:
		return 10
	case .M:
		return 0 // Size not known for generic memory
	}
	return 0
}

// Generate operand expression for instruction building
generate_operand_expr :: proc(sb: ^strings.Builder, info: Operand_Info, param_name: string) {
	op := info.op_type

	if info.is_memory {
		// Memory operands use op_mem with the inner memory and size
		size := operand_size(info)
		if op == .M {
			// Generic memory - size is 0
			fmt.sbprintf(sb, "op_mem(%s, 0)", param_name)
		} else {
			fmt.sbprintf(sb, "op_mem(%s.mem, %d)", param_name, size)
		}
		return
	}

	// Register operands
	#partial switch op {
	case .R8, .RM8:                           fmt.sbprintf(sb, "op_gpr8(%s)", param_name)
	case .R16, .RM16:                         fmt.sbprintf(sb, "op_gpr16(%s)", param_name)
	case .R32, .RM32:                         fmt.sbprintf(sb, "op_gpr32(%s)", param_name)
	case .R64, .RM64:                         fmt.sbprintf(sb, "op_gpr64(%s)", param_name)
	case .XMM, .XMM_M32, .XMM_M64, .XMM_M128: fmt.sbprintf(sb, "op_xmm(%s)", param_name)
	case .YMM, .YMM_M256:                     fmt.sbprintf(sb, "op_ymm(%s)", param_name)
	case .ZMM, .ZMM_M512:                     fmt.sbprintf(sb, "op_zmm(%s)", param_name)
	case .MM, .MM_M64:                        fmt.sbprintf(sb, "op_mm(%s)", param_name)
	case .K, .K_M8, .K_M16, .K_M32, .K_M64:   fmt.sbprintf(sb, "op_kreg(%s)", param_name)
	case .SREG:                               fmt.sbprintf(sb, "op_sreg(%s)", param_name)
	case .CR:                                 fmt.sbprintf(sb, "op_creg(%s)", param_name)
	case .DR:                                 fmt.sbprintf(sb, "op_dreg(%s)", param_name)
	case .STI:                                fmt.sbprintf(sb, "op_st(%s)", param_name)
	case .IMM8:                               fmt.sbprintf(sb, "op_imm8(%s)", param_name)
	case .IMM16:                              fmt.sbprintf(sb, "op_imm16(%s)", param_name)
	case .IMM32:                              fmt.sbprintf(sb, "op_imm32(%s)", param_name)
	case .IMM64:                              fmt.sbprintf(sb, "op_imm64(%s)", param_name)
	case .REL8:                               fmt.sbprintf(sb, "op_rel8(%s)", param_name)
	case .REL32:                              fmt.sbprintf(sb, "op_rel32(%s)", param_name)
	case:
		strings.write_string(sb, "{}")
	}
}

// Generate parameter names for all operands
// This ensures unique names even when multiple operands have similar types
param_names :: proc(sig: Operand_Signature) -> [4]string {
	result: [4]string
	src_count := 0
	imm_count := 0

	for i in 0..<sig.count {
		info := sig.types[i]
		op := info.op_type

		#partial switch op {
		case .IMM8, .IMM16, .IMM32, .IMM64:
			if imm_count == 0 {
				result[i] = "imm"
			} else {
				result[i] = fmt.tprintf("imm%d", imm_count + 1)
			}
			imm_count += 1
		case .REL8, .REL32:
			result[i] = "offset"
		case:
			if i == 0 {
				result[i] = "dst"
			} else {
				if src_count == 0 {
					result[i] = "src"
				} else {
					result[i] = fmt.tprintf("src%d", src_count + 1)
				}
				src_count += 1
			}
		}
	}

	return result
}

// Operand category for pattern matching
Operand_Category :: enum {
	REG,   // Register operand
	MEM,   // Memory operand
	IMM,   // Immediate operand
	REL,   // Relative offset
}

// Get category for an operand
get_operand_category :: proc(info: Operand_Info) -> Operand_Category {
	if info.is_memory {
		return .MEM
	}
	op := info.op_type
	#partial switch op {
	case .IMM8, .IMM16, .IMM32, .IMM64:
		return .IMM
	case .REL8, .REL32:
		return .REL
	case:
		return .REG
	}
}

// Get pattern string for helper selection (e.g., "r_r", "r_m", "m_r", etc.)
get_pattern_string :: proc(sig: Operand_Signature) -> string {
	if sig.count == 0 { return "none" }

	sb := strings.builder_make()
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(&sb, "_") }
		cat := get_operand_category(sig.types[i])
		switch cat {
		case .REG: strings.write_string(&sb, "r")
		case .MEM: strings.write_string(&sb, "m")
		case .IMM: strings.write_string(&sb, "i")
		case .REL: strings.write_string(&sb, "rel")
		}
	}
	return strings.to_string(sb)
}

// Generate the helper call body for inst_ procedure
generate_helper_call :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	names := param_names(sig)
	pattern := get_pattern_string(sig)

	mnemonic_str := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnemonic_str)

	// Match pattern to existing helpers from instructions.odin
	switch pattern {
	case "none":
		// inst_none(mnemonic)
		strings.write_string(sb, "inst_none(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ")")

	case "r":
		// inst_r(mnemonic, r) - need Register cast
		strings.write_string(sb, "inst_r(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "))")

	case "m":
		// inst_m(mnemonic, m, size)
		size := operand_size(sig.types[0])
		strings.write_string(sb, "inst_m(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ")")

	case "r_r":
		// inst_r_r(mnemonic, dst, src)
		strings.write_string(sb, "inst_r_r(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "))")

	case "r_m":
		// inst_r_m(mnemonic, dst, src, size)
		size := operand_size(sig.types[1])
		strings.write_string(sb, "inst_r_m(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		write_memory_arg(sb, sig.types[1], names[1])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ")")

	case "m_r":
		// inst_m_r(mnemonic, dst, size, src)
		size := operand_size(sig.types[0])
		strings.write_string(sb, "inst_m_r(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "))")

	case "r_i":
		// inst_r_i(mnemonic, dst, imm, imm_size)
		imm_size := operand_size(sig.types[1])
		strings.write_string(sb, "inst_r_i(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), i64(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "m_i":
		// inst_m_i(mnemonic, dst, size, imm, imm_size)
		mem_size := operand_size(sig.types[0])
		imm_size := operand_size(sig.types[1])
		strings.write_string(sb, "inst_m_i(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", mem_size)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "i":
		// inst_i(mnemonic, imm, imm_size) - single immediate
		imm_size := operand_size(sig.types[0])
		strings.write_string(sb, "inst_i(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "r_m_i":
		// inst_r_m_i(mnemonic, dst, src, mem_size, imm, imm_size)
		mem_size := operand_size(sig.types[1])
		imm_size := operand_size(sig.types[2])
		strings.write_string(sb, "inst_r_m_i(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		write_memory_arg(sb, sig.types[1], names[1])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", mem_size)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "m_r_i":
		// inst_m_r_i(mnemonic, dst, mem_size, src, imm, imm_size)
		mem_size := operand_size(sig.types[0])
		imm_size := operand_size(sig.types[2])
		strings.write_string(sb, "inst_m_r_i(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", mem_size)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), i64(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "rel":
		// inst_rel_offset(mnemonic, offset, size) - raw offset for jumps
		rel_size := operand_size(sig.types[0])
		strings.write_string(sb, "inst_rel_offset(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", rel_size)
		strings.write_string(sb, ")")

	case "r_r_r":
		// inst_r_r_r(mnemonic, dst, src1, src2)
		strings.write_string(sb, "inst_r_r_r(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "))")

	case "r_r_m":
		// inst_r_r_m(mnemonic, dst, src1, src2, size)
		size := operand_size(sig.types[2])
		strings.write_string(sb, "inst_r_r_m(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), ")
		write_memory_arg(sb, sig.types[2], names[2])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ")")

	case "r_r_i":
		// inst_r_r_i(mnemonic, dst, src, imm, imm_size)
		imm_size := operand_size(sig.types[2])
		strings.write_string(sb, "inst_r_r_i(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), i64(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "r_r_r_r":
		// inst_r_r_r_r(mnemonic, dst, src1, src2, src3)
		strings.write_string(sb, "inst_r_r_r_r(.")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[3])
		strings.write_string(sb, "))")

	case:
		// Unknown pattern - fall back to raw Instruction construction
		generate_fallback_instruction(sb, entry)
	}
}

// Write memory argument - extract .mem from wrapper or use directly for Memory type
write_memory_arg :: proc(sb: ^strings.Builder, info: Operand_Info, name: string) {
	otype := operand_odin_type(info)
	if otype == "Memory" {
		strings.write_string(sb, name)
	} else {
		strings.write_string(sb, name)
		strings.write_string(sb, ".mem")
	}
}

// Fallback: generate raw Instruction{} literal for patterns without helpers
generate_fallback_instruction :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	names := param_names(sig)

	mnemonic_str := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnemonic_str)

	// Build ops expressions
	ops_sb := strings.builder_make()
	defer strings.builder_destroy(&ops_sb)
	for i in 0..<4 {
		if i > 0 { strings.write_string(&ops_sb, ", ") }
		if i < sig.count {
			info := sig.types[i]
			pname := names[i]
			generate_operand_expr(&ops_sb, info, pname)
		} else {
			strings.write_string(&ops_sb, "{}")
		}
	}
	ops := strings.to_string(ops_sb)

	strings.write_string(sb, "Instruction{ mnemonic = .")
	strings.write_string(sb, mnemonic_str)
	strings.write_string(sb, ", operand_count = ")
	fmt.sbprintf(sb, "%d", sig.count)
	strings.write_string(sb, ", ops = {")
	strings.write_string(sb, ops)
	strings.write_string(sb, "} }")
}

// Generate emit helper call
// Note: emit helpers in encoder.odin use different naming: emit_rr, emit_rm, etc. (no underscores)
generate_emit_helper_call :: proc(sb: ^strings.Builder, entry: Proc_Entry) {
	sig := entry.sig
	names := param_names(sig)
	pattern := get_pattern_string(sig)

	mnemonic_str := fmt.aprintf("%v", entry.mnemonic)
	defer delete(mnemonic_str)

	// Match pattern to existing helpers - emit_ versions (naming: emit_rr, emit_rm, etc.)
	switch pattern {
	case "none":
		strings.write_string(sb, "emit_none(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ")")

	case "r":
		strings.write_string(sb, "emit_r(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "))")

	case "m":
		size := operand_size(sig.types[0])
		strings.write_string(sb, "emit_m(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ")")

	case "r_r":
		// emit_rr (not emit_r_r)
		strings.write_string(sb, "emit_rr(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "))")

	case "r_m":
		// emit_rm (not emit_r_m)
		size := operand_size(sig.types[1])
		strings.write_string(sb, "emit_rm(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		write_memory_arg(sb, sig.types[1], names[1])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ")")

	case "m_r":
		// emit_mr (not emit_m_r)
		size := operand_size(sig.types[0])
		strings.write_string(sb, "emit_mr(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "))")

	case "r_i":
		// emit_ri (not emit_r_i)
		imm_size := operand_size(sig.types[1])
		strings.write_string(sb, "emit_ri(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), i64(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "m_i":
		// emit_mi (not emit_m_i)
		mem_size := operand_size(sig.types[0])
		imm_size := operand_size(sig.types[1])
		strings.write_string(sb, "emit_mi(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", mem_size)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "i":
		// emit_i - single immediate
		imm_size := operand_size(sig.types[0])
		strings.write_string(sb, "emit_i(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "r_m_i":
		// emit_rmi - reg mem imm
		mem_size := operand_size(sig.types[1])
		imm_size := operand_size(sig.types[2])
		strings.write_string(sb, "emit_rmi(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		write_memory_arg(sb, sig.types[1], names[1])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", mem_size)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "m_r_i":
		// emit_mri - mem reg imm
		mem_size := operand_size(sig.types[0])
		imm_size := operand_size(sig.types[2])
		strings.write_string(sb, "emit_mri(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", ")
		write_memory_arg(sb, sig.types[0], names[0])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", mem_size)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), i64(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "rel":
		// emit_rel_offset - relative offset for jumps
		rel_size := operand_size(sig.types[0])
		strings.write_string(sb, "emit_rel_offset(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", i64(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", rel_size)
		strings.write_string(sb, ")")

	case "r_r_r":
		// emit_rrr (not emit_r_r_r)
		strings.write_string(sb, "emit_rrr(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "))")

	case "r_r_m":
		// emit_rrm (not emit_r_r_m)
		size := operand_size(sig.types[2])
		strings.write_string(sb, "emit_rrm(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), ")
		write_memory_arg(sb, sig.types[2], names[2])
		strings.write_string(sb, ", ")
		fmt.sbprintf(sb, "%d", size)
		strings.write_string(sb, ")")

	case "r_r_i":
		// emit_rri (not emit_r_r_i)
		imm_size := operand_size(sig.types[2])
		strings.write_string(sb, "emit_rri(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), i64(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), ")
		fmt.sbprintf(sb, "%d", imm_size)
		strings.write_string(sb, ")")

	case "r_r_r_r":
		// emit_rrrr (not emit_r_r_r_r)
		strings.write_string(sb, "emit_rrrr(instructions, .")
		strings.write_string(sb, mnemonic_str)
		strings.write_string(sb, ", Register(")
		strings.write_string(sb, names[0])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[1])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[2])
		strings.write_string(sb, "), Register(")
		strings.write_string(sb, names[3])
		strings.write_string(sb, "))")

	case:
		// Unknown pattern - fall back to append with inst_ call
		strings.write_string(sb, "append(instructions, ")
		strings.write_string(sb, entry.proc_name)
		strings.write_string(sb, "(")
		for i in 0..<sig.count {
			if i > 0 { strings.write_string(sb, ", ") }
			strings.write_string(sb, names[i])
		}
		strings.write_string(sb, "))")
	}
}

// Generate a single inst_ procedure (compact one-line format)
generate_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, max_name_padding: int) {
	sig := entry.sig
	names := param_names(sig)

	// Build params string
	params_sb := strings.builder_make()
	defer strings.builder_destroy(&params_sb)
	for i in 0..<sig.count {
		if i > 0 { strings.write_string(&params_sb, ", ") }
		info := sig.types[i]
		pname := names[i]
		otype := operand_odin_type(info)
		strings.write_string(&params_sb, pname)
		strings.write_string(&params_sb, ": ")
		strings.write_string(&params_sb, otype)
	}
	params := strings.to_string(params_sb)

	// Write compact one-line procedure using helper call
	strings.write_string(sb, entry.proc_name)
	for n := max_name_padding - len(entry.proc_name); n > 0; n -= 1 {
		strings.write_byte(sb, ' ')
	}
	strings.write_string(sb, " :: #force_inline proc \"contextless\" (")
	strings.write_string(sb, params)
	strings.write_string(sb, ") -> Instruction { return ")
	generate_helper_call(sb, entry)
	strings.write_string(sb, " }\n")
}

// Generate a single emit_ procedure (compact one-line format)
// Note: emit procedures are NOT contextless because append requires context
generate_emit_proc :: proc(sb: ^strings.Builder, entry: Proc_Entry, max_name_padding: int) {
	sig := entry.sig
	names := param_names(sig)

	// Build params string (instructions param + original params)
	params_sb := strings.builder_make()
	defer strings.builder_destroy(&params_sb)
	strings.write_string(&params_sb, "instructions: ^[dynamic]Instruction")
	for i in 0..<sig.count {
		strings.write_string(&params_sb, ", ")
		info := sig.types[i]
		pname := names[i]
		otype := operand_odin_type(info)
		strings.write_string(&params_sb, pname)
		strings.write_string(&params_sb, ": ")
		strings.write_string(&params_sb, otype)
	}
	params := strings.to_string(params_sb)

	// Generate emit_ proc name from inst_ proc name
	emit_name := strings.concatenate({"emit_", entry.proc_name[5:]})

	// Write compact one-line procedure using emit helper call
	// NOT contextless - append requires context
	strings.write_string(sb, emit_name)
	for n := max_name_padding - len(entry.proc_name); n > 0; n -= 1 {
		strings.write_byte(sb, ' ')
	}
	strings.write_string(sb, " :: #force_inline proc(")
	strings.write_string(sb, params)
	strings.write_string(sb, ") { ")
	generate_emit_helper_call(sb, entry)
	strings.write_string(sb, " }\n")
}
