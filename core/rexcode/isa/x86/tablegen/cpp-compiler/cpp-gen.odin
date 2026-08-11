package cpp_gen

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import "core:reflect"
import "core:rexcode/isa/x86"

import gen ".."

ISA_NAME :: "amd64"

main :: proc() {
	raw_encode_runs  := #load("../../tables/x86.encode_runs.bin",  []x86.Encode_Run)
	raw_encode_forms := #load("../../tables/x86.encode_forms.bin", []u8)

	sb := strings.builder_make()

	strings.write_string(&sb, "// =============================================================================\n")
	strings.write_string(&sb, "// GENERATED FILE - DO NOT EDIT\n")
	strings.write_string(&sb, "// =============================================================================\n")
	strings.write_string(&sb, "//\n")
	strings.write_string(&sb, "// Produces a C++ equivalent of the encoding table from core:rexcode written in Odin\n")
	strings.write_string(&sb, "//   odin run tablegen              # Stage A: ENCODING_TABLE -> generated/ + this file\n")
	strings.write_string(&sb, "//   odin run tablegen/generated    # Stage B: typed Odin literals -> tables/*.bin\n")
	strings.write_string(&sb, "//   odin run tablegen/cpp-compiler # Stage C: typed Odin literals -> C++ literals\n")
	strings.write_string(&sb, "//\n\n\n")


	// strings.write_string(&sb, "struct Asm_a
	fmt.sbprintf(&sb, "struct Asm_%s {{\n", ISA_NAME)
	{
		strings.write_string(&sb, "\tenum Mnemonic : u16 {\n")
		defer strings.write_string(&sb, "\t};\n");

		iota := 0

		count := uint(0)
		ROW_COUNT :: 16
		for mnemonic in gen.Mnemonic {
			if count == 0 {
				strings.write_string(&sb, "\t\t")
			}
			assert(int(mnemonic) == iota)
			fmt.sbprintf(&sb, "M_%s, ", mnemonic)

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			iota += 1
			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n\n");
		strings.write_string(&sb, "\t\tMNEMONIC_COUNT\n");
	}

	{
		strings.write_string(&sb, "\tenum Prefix : u8 {\n")
		defer strings.write_string(&sb, "\t};\n");

		count := uint(0)
		ROW_COUNT :: 16
		for prefix in Prefix {
			if count == 0 {
				strings.write_string(&sb, "\t\t")
			}
			fmt.sbprintf(&sb, "PREFIX_%s, ", prefix)

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n\n");
		strings.write_string(&sb, "\t\tPREFIX_COUNT\n");
	}

	strings.write_string(&sb, "\tstatic String const mnemonic_strings[MNEMONIC_COUNT];\n")
	strings.write_string(&sb, "\tstatic String const prefix_strings[PREFIX_COUNT];\n")

	{
		strings.write_string(&sb, "\n");
		strings.write_string(&sb, "\t// Register classes (upper byte)\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_NONE  = 0x000;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_GPR64 = 0x100;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_GPR32 = 0x200;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_GPR16 = 0x300;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_GPR8  = 0x400;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_GPR8H = 0x500;  // AH, CH, DH, BH - legacy high byte regs\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_XMM   = 0x600;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_YMM   = 0x700;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_ZMM   = 0x800;\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_K     = 0x900;  // opmask\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_SEG   = 0xA00;  // segment\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_CR    = 0xB00;  // control\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_DR    = 0xC00;  // debug\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_BND   = 0xD00;  // bound\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_MM    = 0xE00;  // MMX\n")
		strings.write_string(&sb, "\tstatic const u16 REG_CLASS_ST    = 0xF00;  // x87 FPU\n")
		strings.write_string(&sb, "\n");
		{
			count := uint(0)
			ROW_COUNT :: 16
			strings.write_string(&sb, "\tenum Register : u16 {\n")
			for reg in Register {
				if count == 0 {
					strings.write_string(&sb, "\t\t")
				}
				fmt.sbprintf(&sb, "REG_%s, ", reg)

				if count == ROW_COUNT-1 {
					strings.write_string(&sb, "\n")
				}
				count = (count + 1) % ROW_COUNT
			}
			strings.write_string(&sb, "\n")
			strings.write_string(&sb, "\t\tREG_COUNT\n")
			strings.write_string(&sb, "\t};\n")
		}
	}


	strings.write_string(&sb, "\tstatic u16 const register_codes[REG_COUNT];\n")
	strings.write_string(&sb, "\tstatic String const register_strings[REG_COUNT];\n")

	strings.write_string(&sb, "\n\n")
	{
		strings.write_string(&sb, "\tenum OperandType : u8 {\n")
		defer strings.write_string(&sb, "\t};\n")
		for op in type_of(gen.Encoding{}.ops[0]) {
			fmt.sbprintf(&sb, "\t\tOP_%s,\n", op)
		}

	}
	strings.write_string(&sb, "\n\n")
	{
		strings.write_string(&sb, "\tenum OperandEncoding : u8 {\n")
		defer strings.write_string(&sb, "\t};\n")
		for op in Operand_Encoding {
			fmt.sbprintf(&sb, "\t\tENC_%s,\n", op)
		}

	}
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, "\ttypedef u32 EncodingFlags; // cannot use a C++ bit field to due lack of portability\n")
	strings.write_string(&sb, "\n")
	{
		defer strings.write_string(&sb, "\tGB_STATIC_ASSERT(gb_size_of(Encoding) == 16);\n")

		strings.write_string(&sb, "\t#pragma pack(push, 1)\n")
		defer strings.write_string(&sb, "\t#pragma pack(pop)\n")
		strings.write_string(&sb, "\tstruct Encoding {\n")
		defer strings.write_string(&sb, "\t};\n")
		strings.write_string(&sb, "\t\tMnemonic        mnemonic;\n")
		strings.write_string(&sb, "\t\tOperandType     ops[4];\n")
		strings.write_string(&sb, "\t\tOperandEncoding enc[4];\n")
		strings.write_string(&sb, "\t\tu8              opcode;\n")
		strings.write_string(&sb, "\t\tu8              ext;\n")
		strings.write_string(&sb, "\t\tEncodingFlags   flags;\n")


		strings.write_string(&sb, "\n")
		Encoding_Flags :: type_of(gen.Encoding{}.flags)

		{
			bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "has_implicit")
			strings.write_string(&sb, "\t\tbool has_implicit  () const { ")
			fmt.sbprintf(&sb, "return ((flags>>%du)&1) != 0;", bit_offset)
			strings.write_string(&sb, " }\n")
		}
		{
			bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "explicit_count")
			bit_size   := intrinsics.type_field_bit_size(Encoding_Flags, "explicit_count")
			strings.write_string(&sb, "\t\tu8   explicit_count() const { ")
			fmt.sbprintf(&sb, "return cast(u8)((flags>>%du)&((1u<<%d)-1));", bit_offset, bit_size)
			strings.write_string(&sb, " }\n")
		}
		{
			bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "op_count")
			bit_size   := intrinsics.type_field_bit_size(Encoding_Flags, "op_count")
			strings.write_string(&sb, "\t\tu8   op_count      () const { ")
			fmt.sbprintf(&sb, "return cast(u8)((flags>>%du)&((1u<<%d)-1));", bit_offset, bit_size)
			strings.write_string(&sb, " }\n")
		}
	}
	strings.write_string(&sb, "\n\n")
	{
		strings.write_string(&sb, "\t// Companion run index: ENCODE_RUNS[mnemonic] -> contiguous run in ENCODE_FORMS.\n")
		strings.write_string(&sb, "\tstruct EncodeRun {\n")
		strings.write_string(&sb, "\t\tu32 start; // start index in ENCODE_FORMS\n")
		strings.write_string(&sb, "\t\tu32 count; // number of forms for this mnemonic\n")
		strings.write_string(&sb, "\t};\n")
	}

	strings.write_string(&sb, "\n\n")
	fmt.sbprintf(&sb, "\tstatic EncodeRun const raw_encode_runs[%d];\n", len(raw_encode_runs))
	fmt.sbprintf(&sb, "\tstatic u8 const raw_encode_forms[%d];\n", len(raw_encode_forms))

	strings.write_string(&sb, "\tStringMap<Mnemonic> mnemonic_map;\n")
	strings.write_string(&sb, "\tStringMap<Prefix>   prefix_map;\n")
	strings.write_string(&sb, "\tStringMap<Register> register_map;\n")

	{
		strings.write_string(&sb, "\tbool init() {\n")
		defer strings.write_string(&sb, "\t}\n")

		strings.write_string(&sb, "\t\tstring_map_init(&mnemonic_map, MNEMONIC_COUNT*2);\n")
		strings.write_string(&sb, "\t\tfor (u16 m = M_INVALID+1; m < MNEMONIC_COUNT; m++) {\n")
		strings.write_string(&sb, "\t\t\tstring_map_set(&mnemonic_map, mnemonic_strings[m], cast(Mnemonic)m);\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\tstring_map_init(&prefix_map, PREFIX_COUNT*2);\n")
		strings.write_string(&sb, "\t\tfor (u8 r = PREFIX_INVALID+1; r < PREFIX_COUNT; r++) {\n")
		strings.write_string(&sb, "\t\t\tstring_map_set(&prefix_map, prefix_strings[r], cast(Prefix)r);\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\tstring_map_init(&register_map, REG_COUNT*2);\n")
		strings.write_string(&sb, "\t\tfor (u16 r = REG_INVALID+1; r < REG_COUNT; r++) {\n")
		strings.write_string(&sb, "\t\t\tstring_map_set(&register_map, register_strings[r], cast(Register)r);\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\treturn true;\n")
	}
	{
		strings.write_string(&sb, "\tMnemonic mnemonic_lookup(String const &name) {\n")
		defer strings.write_string(&sb, "\t}\n")

		strings.write_string(&sb, "\t\tMnemonic *found = string_map_get(&mnemonic_map, name);\n")
		strings.write_string(&sb, "\t\treturn found ? *found : M_INVALID;\n")
	}
	{
		strings.write_string(&sb, "\tPrefix prefix_lookup(String const &name) {\n")
		defer strings.write_string(&sb, "\t}\n")

		strings.write_string(&sb, "\t\tPrefix *found = string_map_get(&prefix_map, name);\n")
		strings.write_string(&sb, "\t\treturn found ? *found : PREFIX_INVALID;\n")
	}
	{
		strings.write_string(&sb, "\tRegister register_lookup(String const &name) {\n")
		defer strings.write_string(&sb, "\t}\n")

		strings.write_string(&sb, "\t\tRegister *found = string_map_get(&register_map, name);\n")
		strings.write_string(&sb, "\t\treturn found ? *found : REG_INVALID;\n")
	}
	{
		strings.write_string(&sb, "\tSlice<Encoding> encoding_forms(/*Mnemonic*/ u16 m) const {\n")
		defer strings.write_string(&sb, "\t}\n")

		strings.write_string(&sb, "\t\tEncodeRun r = raw_encode_runs[m];\n")
		strings.write_string(&sb, "\t\tEncoding *ENCODE_FORMS = cast(Encoding *)raw_encode_forms;\n")
		strings.write_string(&sb, "\t\treturn Slice<Encoding>{ENCODE_FORMS+r.start, r.count};\n")
	}
	{
		strings.write_string(&sb, "\tu16 reg_class(/*Register*/ u16 r) const {\n")
		strings.write_string(&sb, "\t\treturn 0xFF00 & r;\n")
		strings.write_string(&sb, "\t}\n")
	}
	{
		strings.write_string(&sb, "\t// size in bits for register\n")
		strings.write_string(&sb, "\tu16 reg_size(Register r) const {\n")
		strings.write_string(&sb, "\t\tswitch (reg_class(register_codes[r])) {\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_GPR64: return 64;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_GPR32: return 32;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_GPR16: return 16;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_GPR8:  return 8;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_GPR8H: return 8;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_XMM:   return 128;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_YMM:   return 256;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_ZMM:   return 512;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_K:     return 64;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_MM:    return 64;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_ST:    return 80;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_SEG:   return 16;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_CR:    return 64;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_DR:    return 64;\n")
		strings.write_string(&sb, "\t\tcase REG_CLASS_BND:   return 128;\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\treturn 0;\n")
		strings.write_string(&sb, "\t}\n")
	}
	strings.write_string(&sb, "\n")
	{
		strings.write_string(&sb, "\tAsmOperandKind kind_from_operand_type(OperandType type) {\n")
		strings.write_string(&sb, "\t\tswitch (type) {\n")
		strings.write_string(&sb, "\t\tcase OP_R8:  case OP_R16: case OP_R32: case OP_R64:\n")
		strings.write_string(&sb, "\t\tcase OP_SREG: case OP_CR: case OP_DR:\n")
		strings.write_string(&sb, "\t\tcase OP_XMM: case OP_YMM: case OP_ZMM:\n")
		strings.write_string(&sb, "\t\tcase OP_MM:  case OP_K:   case OP_STI:\n")
		strings.write_string(&sb, "\t\tcase OP_AL_IMPL:  case OP_AX_IMPL: case OP_EAX_IMPL: case OP_RAX_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_CL_IMPL:  case OP_DX_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_ST0_IMPL: case OP_XMM0_IMPL:\n")
		strings.write_string(&sb, "\t\t\treturn AsmOperand_Register;\n")
		strings.write_string(&sb, "\t\tcase OP_RM8: case OP_RM16: case OP_RM32: case OP_RM64:\n")
		strings.write_string(&sb, "\t\tcase OP_XMM_M32: case OP_XMM_M64: case OP_XMM_M128:\n")
		strings.write_string(&sb, "\t\tcase OP_YMM_M256: case OP_ZMM_M512:\n")
		strings.write_string(&sb, "\t\tcase OP_MM_M64:\n")
		strings.write_string(&sb, "\t\tcase OP_K_M8: case OP_K_M16: case OP_K_M32: case OP_K_M64:\n")
		strings.write_string(&sb, "\t\t\treturn AsmOperand_Register_Or_Memory;\n")
		strings.write_string(&sb, "\t\tcase OP_M:   case OP_M8:  case OP_M16: case OP_M32: case OP_M64:\n")
		strings.write_string(&sb, "\t\tcase OP_M80: case OP_M128: case OP_M256: case OP_M512:\n")
		strings.write_string(&sb, "\t\tcase OP_MOFFS8: case OP_MOFFS16: case OP_MOFFS32: case OP_MOFFS64:\n")
		strings.write_string(&sb, "\t\tcase OP_M16_16: case OP_M16_32: case OP_M16_64:\n")
		strings.write_string(&sb, "\t\t\treturn AsmOperand_Memory;\n")
		strings.write_string(&sb, "\t\tcase OP_IMM8: case OP_IMM16: case OP_IMM32: case OP_IMM64:\n")
		strings.write_string(&sb, "\t\tcase OP_IMM8SX:\n")
		strings.write_string(&sb, "\t\tcase OP_ONE_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_PTR16_16: case OP_PTR16_32: case OP_PTR16_64:\n")
		strings.write_string(&sb, "\t\t\treturn AsmOperand_Immediate;\n")
		strings.write_string(&sb, "\t\tcase OP_REL8: case OP_REL32:\n")
		strings.write_string(&sb, "\t\t\treturn AsmOperand_Label;\n")
		strings.write_string(&sb, "\t\tcase OP_NONE:\n")
		strings.write_string(&sb, "\t\tdefault:\n")
		strings.write_string(&sb, "\t\t\treturn AsmOperand_Invalid;\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t}\n")
	}
	strings.write_string(&sb, "\n")
	{
		strings.write_string(&sb, "\tbool operand_type_is_implicit(OperandType t) {\n")
		strings.write_string(&sb, "\t\tswitch (t) {\n")
		strings.write_string(&sb, "\t\tcase OP_AL_IMPL:  case OP_AX_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_EAX_IMPL: case OP_RAX_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_CL_IMPL:  case OP_DX_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_ONE_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_ST0_IMPL: case OP_XMM0_IMPL:\n")
		strings.write_string(&sb, "\t\t\treturn true;\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\treturn false;\n")
		strings.write_string(&sb, "\t}\n")
	}
	strings.write_string(&sb, "\n")
	{
		strings.write_string(&sb, "\tAsmRegClass operand_type_reg_class(OperandType t) {\n")
		strings.write_string(&sb, "\t\tswitch (t) {\n")
		strings.write_string(&sb, "\t\tcase OP_R8:  case OP_R16:  case OP_R32:  case OP_R64:\n")
		strings.write_string(&sb, "\t\tcase OP_RM8: case OP_RM16: case OP_RM32: case OP_RM64:\n")
		strings.write_string(&sb, "\t\tcase OP_AL_IMPL: case OP_AX_IMPL: case OP_EAX_IMPL: case OP_RAX_IMPL:\n")
		strings.write_string(&sb, "\t\tcase OP_CL_IMPL: case OP_DX_IMPL:\n")
		strings.write_string(&sb, "\t\t\treturn AsmRegClass_Integer;\n")
		strings.write_string(&sb, "\t\tcase OP_XMM: case OP_YMM: case OP_ZMM:\n")
		strings.write_string(&sb, "\t\tcase OP_XMM_M32: case OP_XMM_M64: case OP_XMM_M128:\n")
		strings.write_string(&sb, "\t\tcase OP_YMM_M256: case OP_ZMM_M512:\n")
		strings.write_string(&sb, "\t\tcase OP_XMM0_IMPL:\n")
		strings.write_string(&sb, "\t\t\treturn AsmRegClass_Vector; // xmm/ymm/zmm; float scalars also land here (see note)\n")
		strings.write_string(&sb, "\t\tcase OP_K:\n")
		strings.write_string(&sb, "\t\tcase OP_K_M8: case OP_K_M16: case OP_K_M32: case OP_K_M64:\n")
		strings.write_string(&sb, "\t\t\treturn AsmRegClass_Mask;\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\treturn AsmRegClass_Unknown; // OP_M*, OP_IMM*, OP_REL*, OP_SREG/CR/DR/MM/STi, moffs, ptr, m16_16... : no GPR/XMM class constraint here\n")
		strings.write_string(&sb, "\t}\n")
	}
	strings.write_string(&sb, "\n")
	{
		strings.write_string(&sb, "\tu16 operand_type_bit_width(OperandType t) {\n")
		strings.write_string(&sb, "\t\tswitch (t) {\n")
		strings.write_string(&sb, "\t\tcase OP_R8:  case OP_RM8:  case OP_M8:  case OP_AL_IMPL:  case OP_CL_IMPL: case OP_K_M8:  return 8;\n")
		strings.write_string(&sb, "\t\tcase OP_R16: case OP_RM16: case OP_M16: case OP_AX_IMPL:  case OP_DX_IMPL: case OP_K_M16: return 16;\n")
		strings.write_string(&sb, "\t\tcase OP_R32: case OP_RM32: case OP_M32: case OP_EAX_IMPL: case OP_XMM_M32: case OP_K_M32: return 32;\n")
		strings.write_string(&sb, "\t\tcase OP_R64: case OP_RM64: case OP_M64: case OP_RAX_IMPL: case OP_XMM_M64: case OP_K_M64: case OP_MM: case OP_MM_M64: return 64;\n")
		strings.write_string(&sb, "\t\tcase OP_M128: case OP_XMM: case OP_XMM_M128: case OP_XMM0_IMPL: return 128;\n")
		strings.write_string(&sb, "\t\tcase OP_M256: case OP_YMM: case OP_YMM_M256: return 256;\n")
		strings.write_string(&sb, "\t\tcase OP_M512: case OP_ZMM: case OP_ZMM_M512: return 512;\n")
		strings.write_string(&sb, "\t\t}\n")
		strings.write_string(&sb, "\t\treturn 0; // OP_M (sizeless), OP_IMM*, OP_REL*, OP_K (opmask width is data-dependent), etc.\n")
		strings.write_string(&sb, "\t}\n")
	}


	strings.write_string(&sb, "};\n")

	strings.write_string(&sb, "\n\n\n")

	fmt.sbprintf(&sb, "gb_global Asm_{0:s} g_asm_{0:s};\n", ISA_NAME)

	strings.write_string(&sb, "\n\n\n")

	{
		fmt.sbprintf(&sb, "String const Asm_{0:s}::mnemonic_strings[Asm_{0:s}::MNEMONIC_COUNT] {{\n", ISA_NAME)
		defer strings.write_string(&sb, "};\n");

		count := uint(0)
		ROW_COUNT :: 16
		for mnemonic in gen.Mnemonic {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}

			if mnemonic == .INVALID {
				strings.write_string(&sb, "str_lit(\"\"), ")
			} else if mnemonic == .MOVSD_SSE {
				strings.write_string(&sb, "str_lit(\"movsd\"), ")
			} else {
				str := strings.to_lower(reflect.enum_string(mnemonic))
				fmt.sbprintf(&sb, "str_lit(%q), ", str)
				delete(str)
			}

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n");
	}
	{
		fmt.sbprintf(&sb, "String const Asm_{0:s}::prefix_strings[Asm_{0:s}::PREFIX_COUNT] {{\n", ISA_NAME)
		defer strings.write_string(&sb, "};\n");

		count := uint(0)
		ROW_COUNT :: 16
		for prefix in Prefix {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}

			if prefix == .INVALID {
				strings.write_string(&sb, "str_lit(\"\"), ")
			} else {
				str := strings.to_lower(reflect.enum_string(prefix))
				fmt.sbprintf(&sb, "str_lit(%q), ", str)
				delete(str)
			}

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n");
	}

	{
		fmt.sbprintf(&sb, "u16 const Asm_{0:s}::register_codes[Asm_{0:s}::REG_COUNT] {{\n", ISA_NAME)
		defer strings.write_string(&sb, "};\n");

		count := uint(0)
		ROW_COUNT :: 16
		for reg in Register {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}

			fmt.sbprintf(&sb, "%d, ", REG_CODES[reg])

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n");
	}

	{
		fmt.sbprintf(&sb, "String const Asm_{0:s}::register_strings[Asm_{0:s}::REG_COUNT] {{\n", ISA_NAME)
		defer strings.write_string(&sb, "};\n");

		count := uint(0)
		ROW_COUNT :: 16
		for reg in Register {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}

			if reg == .INVALID {
				strings.write_string(&sb, "str_lit(\"\"), ")
			} else {
				str := strings.to_lower(reflect.enum_string(reg))
				fmt.sbprintf(&sb, "str_lit(%q), ", str)
				delete(str)
			}

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n");
	}

	{
		fmt.sbprintf(&sb, "Asm_{0:s}::EncodeRun const Asm_{0:s}::raw_encode_runs[{1:d}] = {{\n", ISA_NAME, len(raw_encode_runs))
		defer strings.write_string(&sb, "};\n");

		ROW_COUNT :: 16
		count := 0
		for run in raw_encode_runs {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}
			fmt.sbprintf(&sb, "{{% 4d, % 2d}}, ", run.start, run.count)

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		defer strings.write_string(&sb, "\n");
	}
	{
		fmt.sbprintf(&sb, "u8 const Asm_{0:s}::raw_encode_forms[%d] = {{\n", ISA_NAME, len(raw_encode_forms))
		defer strings.write_string(&sb, "};\n");
		ROW_COUNT :: 64
		count := 0
		for the_byte in raw_encode_forms {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}
			fmt.sbprintf(&sb, "%#02x, ", the_byte)

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		defer strings.write_string(&sb, "\n");
	}



	path := fmt.tprintf("%s/src/asm_tables_%s.cpp", ODIN_ROOT, ISA_NAME)

	if err := os.write_entire_file(path, strings.to_string(sb)); err != nil {
		fmt.eprintfln("rexcode tablegen: failed to write %s: %v", path, err)
		os.exit(1)
	}
}

Operand_Encoding :: type_of(gen.Encoding{}.enc[0])

Asm_Operand_Kind :: enum u8 {
	Invalid,
	Register,
	Memory,
	Register_Or_Memory,
	Immediate,
	Label,
}


@(rodata)
operand_encoding_to_kind := [Operand_Encoding]Asm_Operand_Kind{
	.NONE  = .Invalid,
	.MR    = .Register_Or_Memory,
	.REG   = .Register,
	.VVVV  = .Register,
	.OP_R  = .Register,
	.IS4   = .Register,
	.AAA   = .Register,
	.IMPL  = .Register,
	.IB    = .Immediate,
	.IW    = .Immediate,
	.ID    = .Immediate,
	.IQ    = .Immediate,
}


Prefix :: enum u8 {
	INVALID,
	ES,
	CS,
	SS,
	DS,
	REX,
	EVEX,
	FS,
	GS,
	VEX,
	LOCK,
	REPNE,
	REP,
}



Register :: enum u16 {
	INVALID,
	RAX,
	RCX,
	RDX,
	RBX,
	RSP,
	RBP,
	RSI,
	RDI,
	R8,
	R9,
	R10,
	R11,
	R12,
	R13,
	R14,
	R15,
	EAX,
	ECX,
	EDX,
	EBX,
	ESP,
	EBP,
	ESI,
	EDI,
	R8D,
	R9D,
	R10D,
	R11D,
	R12D,
	R13D,
	R14D,
	R15D,
	AX,
	CX,
	DX,
	BX,
	SP,
	BP,
	SI,
	DI,
	R8W,
	R9W,
	R10W,
	R11W,
	R12W,
	R13W,
	R14W,
	R15W,
	AL,
	CL,
	DL,
	BL,
	SPL,
	BPL,
	SIL,
	DIL,
	R8B,
	R9B,
	R10B,
	R11B,
	R12B,
	R13B,
	R14B,
	R15B,
	AH,
	CH,
	DH,
	BH,
	XMM0,
	XMM1,
	XMM2,
	XMM3,
	XMM4,
	XMM5,
	XMM6,
	XMM7,
	XMM8,
	XMM9,
	XMM10,
	XMM11,
	XMM12,
	XMM13,
	XMM14,
	XMM15,
	XMM16,
	XMM17,
	XMM18,
	XMM19,
	XMM20,
	XMM21,
	XMM22,
	XMM23,
	XMM24,
	XMM25,
	XMM26,
	XMM27,
	XMM28,
	XMM29,
	XMM30,
	XMM31,
	YMM0,
	YMM1,
	YMM2,
	YMM3,
	YMM4,
	YMM5,
	YMM6,
	YMM7,
	YMM8,
	YMM9,
	YMM10,
	YMM11,
	YMM12,
	YMM13,
	YMM14,
	YMM15,
	YMM16,
	YMM17,
	YMM18,
	YMM19,
	YMM20,
	YMM21,
	YMM22,
	YMM23,
	YMM24,
	YMM25,
	YMM26,
	YMM27,
	YMM28,
	YMM29,
	YMM30,
	YMM31,
	ZMM0,
	ZMM1,
	ZMM2,
	ZMM3,
	ZMM4,
	ZMM5,
	ZMM6,
	ZMM7,
	ZMM8,
	ZMM9,
	ZMM10,
	ZMM11,
	ZMM12,
	ZMM13,
	ZMM14,
	ZMM15,
	ZMM16,
	ZMM17,
	ZMM18,
	ZMM19,
	ZMM20,
	ZMM21,
	ZMM22,
	ZMM23,
	ZMM24,
	ZMM25,
	ZMM26,
	ZMM27,
	ZMM28,
	ZMM29,
	ZMM30,
	ZMM31,
	K0,
	K1,
	K2,
	K3,
	K4,
	K5,
	K6,
	K7,
	ES,
	CS,
	SS,
	DS,
	FS,
	GS,
	CR0,
	CR2,
	CR3,
	CR4,
	CR8,
	DR0,
	DR1,
	DR2,
	DR3,
	DR6,
	DR7,
	BND0,
	BND1,
	BND2,
	BND3,
	MM0,
	MM1,
	MM2,
	MM3,
	MM4,
	MM5,
	MM6,
	MM7,
	ST0,
	ST1,
	ST2,
	ST3,
	ST4,
	ST5,
	ST6,
	ST7,
	RIP,

}

@(rodata)
REG_CODES := [Register]x86.Register{
	.INVALID = 0,

	// GPR 64-bit
	.RAX = x86.Register(x86.REG_GPR64 | 0),  .RCX = x86.Register(x86.REG_GPR64 | 1),
	.RDX = x86.Register(x86.REG_GPR64 | 2),  .RBX = x86.Register(x86.REG_GPR64 | 3),
	.RSP = x86.Register(x86.REG_GPR64 | 4),  .RBP = x86.Register(x86.REG_GPR64 | 5),
	.RSI = x86.Register(x86.REG_GPR64 | 6),  .RDI = x86.Register(x86.REG_GPR64 | 7),
	.R8  = x86.Register(x86.REG_GPR64 | 8),  .R9  = x86.Register(x86.REG_GPR64 | 9),
	.R10 = x86.Register(x86.REG_GPR64 | 10), .R11 = x86.Register(x86.REG_GPR64 | 11),
	.R12 = x86.Register(x86.REG_GPR64 | 12), .R13 = x86.Register(x86.REG_GPR64 | 13),
	.R14 = x86.Register(x86.REG_GPR64 | 14), .R15 = x86.Register(x86.REG_GPR64 | 15),

	// -----------------------------------------------------------------------------
	// SECTION: 1.3 GPR 32-bit Registers (EAX-R15D)
	// -----------------------------------------------------------------------------

	// GPR 32-bit
	.EAX  = x86.Register(x86.REG_GPR32 | 0),  .ECX  = x86.Register(x86.REG_GPR32 | 1),
	.EDX  = x86.Register(x86.REG_GPR32 | 2),  .EBX  = x86.Register(x86.REG_GPR32 | 3),
	.ESP  = x86.Register(x86.REG_GPR32 | 4),  .EBP  = x86.Register(x86.REG_GPR32 | 5),
	.ESI  = x86.Register(x86.REG_GPR32 | 6),  .EDI  = x86.Register(x86.REG_GPR32 | 7),
	.R8D  = x86.Register(x86.REG_GPR32 | 8),  .R9D  = x86.Register(x86.REG_GPR32 | 9),
	.R10D = x86.Register(x86.REG_GPR32 | 10), .R11D = x86.Register(x86.REG_GPR32 | 11),
	.R12D = x86.Register(x86.REG_GPR32 | 12), .R13D = x86.Register(x86.REG_GPR32 | 13),
	.R14D = x86.Register(x86.REG_GPR32 | 14), .R15D = x86.Register(x86.REG_GPR32 | 15),

	// -----------------------------------------------------------------------------
	// SECTION: 1.4 GPR 16-bit Registers (AX-R15W)
	// -----------------------------------------------------------------------------

	// GPR 16-bit
	.AX   = x86.Register(x86.REG_GPR16 | 0),  .CX   = x86.Register(x86.REG_GPR16 | 1),
	.DX   = x86.Register(x86.REG_GPR16 | 2),  .BX   = x86.Register(x86.REG_GPR16 | 3),
	.SP   = x86.Register(x86.REG_GPR16 | 4),  .BP   = x86.Register(x86.REG_GPR16 | 5),
	.SI   = x86.Register(x86.REG_GPR16 | 6),  .DI   = x86.Register(x86.REG_GPR16 | 7),
	.R8W  = x86.Register(x86.REG_GPR16 | 8),  .R9W  = x86.Register(x86.REG_GPR16 | 9),
	.R10W = x86.Register(x86.REG_GPR16 | 10), .R11W = x86.Register(x86.REG_GPR16 | 11),
	.R12W = x86.Register(x86.REG_GPR16 | 12), .R13W = x86.Register(x86.REG_GPR16 | 13),
	.R14W = x86.Register(x86.REG_GPR16 | 14), .R15W = x86.Register(x86.REG_GPR16 | 15),

	// -----------------------------------------------------------------------------
	// SECTION: 1.5 GPR 8-bit Registers (AL-R15B, AH-BH)
	// -----------------------------------------------------------------------------

	// GPR 8-bit (low)
	.AL   = x86.Register(x86.REG_GPR8 | 0),   .CL   = x86.Register(x86.REG_GPR8 | 1),
	.DL   = x86.Register(x86.REG_GPR8 | 2),   .BL   = x86.Register(x86.REG_GPR8 | 3),
	.SPL  = x86.Register(x86.REG_GPR8 | 4),   .BPL  = x86.Register(x86.REG_GPR8 | 5),
	.SIL  = x86.Register(x86.REG_GPR8 | 6),   .DIL  = x86.Register(x86.REG_GPR8 | 7),
	.R8B  = x86.Register(x86.REG_GPR8 | 8),   .R9B  = x86.Register(x86.REG_GPR8 | 9),
	.R10B = x86.Register(x86.REG_GPR8 | 10),  .R11B = x86.Register(x86.REG_GPR8 | 11),
	.R12B = x86.Register(x86.REG_GPR8 | 12),  .R13B = x86.Register(x86.REG_GPR8 | 13),
	.R14B = x86.Register(x86.REG_GPR8 | 14),  .R15B = x86.Register(x86.REG_GPR8 | 15),

	// GPR 8-bit (high) - no REX allowed with these
	.AH = x86.Register(x86.REG_GPR8H | 4),   .CH = x86.Register(x86.REG_GPR8H | 5),
	.DH = x86.Register(x86.REG_GPR8H | 6),   .BH = x86.Register(x86.REG_GPR8H | 7),

	// -----------------------------------------------------------------------------
	// SECTION: 1.6 XMM Registers (XMM0-XMM31)
	// -----------------------------------------------------------------------------

	// XMM (0-31)
	.XMM0  = x86.Register(x86.REG_XMM | 0),   .XMM1  = x86.Register(x86.REG_XMM | 1),
	.XMM2  = x86.Register(x86.REG_XMM | 2),   .XMM3  = x86.Register(x86.REG_XMM | 3),
	.XMM4  = x86.Register(x86.REG_XMM | 4),   .XMM5  = x86.Register(x86.REG_XMM | 5),
	.XMM6  = x86.Register(x86.REG_XMM | 6),   .XMM7  = x86.Register(x86.REG_XMM | 7),
	.XMM8  = x86.Register(x86.REG_XMM | 8),   .XMM9  = x86.Register(x86.REG_XMM | 9),
	.XMM10 = x86.Register(x86.REG_XMM | 10),  .XMM11 = x86.Register(x86.REG_XMM | 11),
	.XMM12 = x86.Register(x86.REG_XMM | 12),  .XMM13 = x86.Register(x86.REG_XMM | 13),
	.XMM14 = x86.Register(x86.REG_XMM | 14),  .XMM15 = x86.Register(x86.REG_XMM | 15),
	.XMM16 = x86.Register(x86.REG_XMM | 16),  .XMM17 = x86.Register(x86.REG_XMM | 17),
	.XMM18 = x86.Register(x86.REG_XMM | 18),  .XMM19 = x86.Register(x86.REG_XMM | 19),
	.XMM20 = x86.Register(x86.REG_XMM | 20),  .XMM21 = x86.Register(x86.REG_XMM | 21),
	.XMM22 = x86.Register(x86.REG_XMM | 22),  .XMM23 = x86.Register(x86.REG_XMM | 23),
	.XMM24 = x86.Register(x86.REG_XMM | 24),  .XMM25 = x86.Register(x86.REG_XMM | 25),
	.XMM26 = x86.Register(x86.REG_XMM | 26),  .XMM27 = x86.Register(x86.REG_XMM | 27),
	.XMM28 = x86.Register(x86.REG_XMM | 28),  .XMM29 = x86.Register(x86.REG_XMM | 29),
	.XMM30 = x86.Register(x86.REG_XMM | 30),  .XMM31 = x86.Register(x86.REG_XMM | 31),

	// -----------------------------------------------------------------------------
	// SECTION: 1.7 YMM Registers (YMM0-YMM31)
	// -----------------------------------------------------------------------------

	// YMM (0-31)
	.YMM0  = x86.Register(x86.REG_YMM | 0),   .YMM1  = x86.Register(x86.REG_YMM | 1),
	.YMM2  = x86.Register(x86.REG_YMM | 2),   .YMM3  = x86.Register(x86.REG_YMM | 3),
	.YMM4  = x86.Register(x86.REG_YMM | 4),   .YMM5  = x86.Register(x86.REG_YMM | 5),
	.YMM6  = x86.Register(x86.REG_YMM | 6),   .YMM7  = x86.Register(x86.REG_YMM | 7),
	.YMM8  = x86.Register(x86.REG_YMM | 8),   .YMM9  = x86.Register(x86.REG_YMM | 9),
	.YMM10 = x86.Register(x86.REG_YMM | 10),  .YMM11 = x86.Register(x86.REG_YMM | 11),
	.YMM12 = x86.Register(x86.REG_YMM | 12),  .YMM13 = x86.Register(x86.REG_YMM | 13),
	.YMM14 = x86.Register(x86.REG_YMM | 14),  .YMM15 = x86.Register(x86.REG_YMM | 15),
	.YMM16 = x86.Register(x86.REG_YMM | 16),  .YMM17 = x86.Register(x86.REG_YMM | 17),
	.YMM18 = x86.Register(x86.REG_YMM | 18),  .YMM19 = x86.Register(x86.REG_YMM | 19),
	.YMM20 = x86.Register(x86.REG_YMM | 20),  .YMM21 = x86.Register(x86.REG_YMM | 21),
	.YMM22 = x86.Register(x86.REG_YMM | 22),  .YMM23 = x86.Register(x86.REG_YMM | 23),
	.YMM24 = x86.Register(x86.REG_YMM | 24),  .YMM25 = x86.Register(x86.REG_YMM | 25),
	.YMM26 = x86.Register(x86.REG_YMM | 26),  .YMM27 = x86.Register(x86.REG_YMM | 27),
	.YMM28 = x86.Register(x86.REG_YMM | 28),  .YMM29 = x86.Register(x86.REG_YMM | 29),
	.YMM30 = x86.Register(x86.REG_YMM | 30),  .YMM31 = x86.Register(x86.REG_YMM | 31),

	// -----------------------------------------------------------------------------
	// SECTION: 1.8 ZMM Registers (ZMM0-ZMM31)
	// -----------------------------------------------------------------------------

	// ZMM (0-31)
	.ZMM0  = x86.Register(x86.REG_ZMM | 0),   .ZMM1  = x86.Register(x86.REG_ZMM | 1),
	.ZMM2  = x86.Register(x86.REG_ZMM | 2),   .ZMM3  = x86.Register(x86.REG_ZMM | 3),
	.ZMM4  = x86.Register(x86.REG_ZMM | 4),   .ZMM5  = x86.Register(x86.REG_ZMM | 5),
	.ZMM6  = x86.Register(x86.REG_ZMM | 6),   .ZMM7  = x86.Register(x86.REG_ZMM | 7),
	.ZMM8  = x86.Register(x86.REG_ZMM | 8),   .ZMM9  = x86.Register(x86.REG_ZMM | 9),
	.ZMM10 = x86.Register(x86.REG_ZMM | 10),  .ZMM11 = x86.Register(x86.REG_ZMM | 11),
	.ZMM12 = x86.Register(x86.REG_ZMM | 12),  .ZMM13 = x86.Register(x86.REG_ZMM | 13),
	.ZMM14 = x86.Register(x86.REG_ZMM | 14),  .ZMM15 = x86.Register(x86.REG_ZMM | 15),
	.ZMM16 = x86.Register(x86.REG_ZMM | 16),  .ZMM17 = x86.Register(x86.REG_ZMM | 17),
	.ZMM18 = x86.Register(x86.REG_ZMM | 18),  .ZMM19 = x86.Register(x86.REG_ZMM | 19),
	.ZMM20 = x86.Register(x86.REG_ZMM | 20),  .ZMM21 = x86.Register(x86.REG_ZMM | 21),
	.ZMM22 = x86.Register(x86.REG_ZMM | 22),  .ZMM23 = x86.Register(x86.REG_ZMM | 23),
	.ZMM24 = x86.Register(x86.REG_ZMM | 24),  .ZMM25 = x86.Register(x86.REG_ZMM | 25),
	.ZMM26 = x86.Register(x86.REG_ZMM | 26),  .ZMM27 = x86.Register(x86.REG_ZMM | 27),
	.ZMM28 = x86.Register(x86.REG_ZMM | 28),  .ZMM29 = x86.Register(x86.REG_ZMM | 29),
	.ZMM30 = x86.Register(x86.REG_ZMM | 30),  .ZMM31 = x86.Register(x86.REG_ZMM | 31),

	// -----------------------------------------------------------------------------
	// SECTION: 1.9 Opmask Registers (K0-K7)
	// -----------------------------------------------------------------------------

	// Opmask registers
	.K0 = x86.Register(x86.REG_K | 0), .K1 = x86.Register(x86.REG_K | 1),
	.K2 = x86.Register(x86.REG_K | 2), .K3 = x86.Register(x86.REG_K | 3),
	.K4 = x86.Register(x86.REG_K | 4), .K5 = x86.Register(x86.REG_K | 5),
	.K6 = x86.Register(x86.REG_K | 6), .K7 = x86.Register(x86.REG_K | 7),

	// -----------------------------------------------------------------------------
	// SECTION: 1.10 Segment Registers (ES-GS)
	// -----------------------------------------------------------------------------

	// Segment registers
	.ES = x86.Register(x86.REG_SEG | 0), .CS = x86.Register(x86.REG_SEG | 1),
	.SS = x86.Register(x86.REG_SEG | 2), .DS = x86.Register(x86.REG_SEG | 3),
	.FS = x86.Register(x86.REG_SEG | 4), .GS = x86.Register(x86.REG_SEG | 5),

	// -----------------------------------------------------------------------------
	// SECTION: 1.11 Control and Debug Registers
	// -----------------------------------------------------------------------------

	// Control registers
	.CR0 = x86.Register(x86.REG_CR | 0),  .CR2 = x86.Register(x86.REG_CR | 2),
	.CR3 = x86.Register(x86.REG_CR | 3),  .CR4 = x86.Register(x86.REG_CR | 4),
	.CR8 = x86.Register(x86.REG_CR | 8),

	// Debug registers
	.DR0 = x86.Register(x86.REG_DR | 0), .DR1 = x86.Register(x86.REG_DR | 1),
	.DR2 = x86.Register(x86.REG_DR | 2), .DR3 = x86.Register(x86.REG_DR | 3),
	.DR6 = x86.Register(x86.REG_DR | 6), .DR7 = x86.Register(x86.REG_DR | 7),

	// -----------------------------------------------------------------------------
	// SECTION: 1.12 Other Registers (BND, MM, ST)
	// -----------------------------------------------------------------------------

	// Bound registers (MPX)
	.BND0 = x86.Register(x86.REG_BND | 0), .BND1 = x86.Register(x86.REG_BND | 1),
	.BND2 = x86.Register(x86.REG_BND | 2), .BND3 = x86.Register(x86.REG_BND | 3),

	// MMX registers
	.MM0 = x86.Register(x86.REG_MM | 0), .MM1 = x86.Register(x86.REG_MM | 1),
	.MM2 = x86.Register(x86.REG_MM | 2), .MM3 = x86.Register(x86.REG_MM | 3),
	.MM4 = x86.Register(x86.REG_MM | 4), .MM5 = x86.Register(x86.REG_MM | 5),
	.MM6 = x86.Register(x86.REG_MM | 6), .MM7 = x86.Register(x86.REG_MM | 7),

	// x87 FPU registers
	.ST0 = x86.Register(x86.REG_ST | 0), .ST1 = x86.Register(x86.REG_ST | 1),
	.ST2 = x86.Register(x86.REG_ST | 2), .ST3 = x86.Register(x86.REG_ST | 3),
	.ST4 = x86.Register(x86.REG_ST | 4), .ST5 = x86.Register(x86.REG_ST | 5),
	.ST6 = x86.Register(x86.REG_ST | 6), .ST7 = x86.Register(x86.REG_ST | 7),

	// Special: RIP for RIP-relative addressing
	.RIP = x86.Register(0xFFFE),
}