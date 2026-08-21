package cpp_gen

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:slice"
import "core:reflect"
import "core:rexcode/isa/riscv"

import gen ".."

ISA_NAME :: "riscv"

main :: proc() {
	raw_encode_runs   := #load("../../tables/riscv.encode_runs.bin",  []riscv.Encode_Run)
	raw_encode_forms  := #load("../../tables/riscv.encode_forms.bin", []u8)
	raw_clobber_forms := #load("../../tables/riscv.clobber_forms.bin", []u8)
	raw_pseudo_aliases_ := &riscv.PSEUDO_ALIASES
	raw_pseudo_aliases := ([^]byte)(raw_pseudo_aliases_)[:size_of(raw_pseudo_aliases_^)]

	sb := strings.builder_make()

	strings.write_string(&sb, """
	// =============================================================================
	// GENERATED FILE - DO NOT EDIT
	// =============================================================================
	//
	// Produces a C++ equivalent of the encoding table from core:rexcode written in Odin
	//   odin run tablegen              # Stage A: ENCODING_TABLE -> generated/ + this file
	//   odin run tablegen/generated    # Stage B: typed Odin literals -> tables/*.bin
	//   odin run tablegen/cpp-compiler # Stage C: typed Odin literals -> C++ literals
	//
	\n\n
	""")


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

	strings.write_string(&sb, "\tstatic String const mnemonic_strings[MNEMONIC_COUNT];\n")

	{
		strings.write_string(&sb, "\n")
		strings.write_string(&sb, """
			enum Prefix : u8 {
				PREFIX_INVALID,
				PREFIX_COUNT
			};
			enum PrefixKind : u8 { PrefixKind_None };
			\n
		""")
	}
	{
		strings.write_string(&sb, "\n")
		strings.write_string(&sb, """
			static const u16 REG_CLASS_NONE  = 0x000;
			static const u16 REG_CLASS_GPR64 = 0x100;
			static const u16 REG_CLASS_GPR32 = 0x200;
			static const u16 REG_CLASS_GPR16 = 0x300;
			static const u16 REG_CLASS_GPR8  = 0x400;
			static const u16 REG_CLASS_GPR8H = 0x500;  // AH, CH, DH, BH - legacy high byte regs
			static const u16 REG_CLASS_XMM   = 0x600;
			static const u16 REG_CLASS_YMM   = 0x700;
			static const u16 REG_CLASS_ZMM   = 0x800;
			static const u16 REG_CLASS_K     = 0x900;  // opmask
			static const u16 REG_CLASS_SEG   = 0xA00;  // segment
			static const u16 REG_CLASS_CR    = 0xB00;  // control
			static const u16 REG_CLASS_DR    = 0xC00;  // debug
			static const u16 REG_CLASS_BND   = 0xD00;  // bound
			static const u16 REG_CLASS_MM    = 0xE00;  // MMX
			static const u16 REG_CLASS_ST    = 0xF00;  // x87 FPU
			\n
		""")
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
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, """

		enum ClobberFFlags : u8 {
			ClobberFFlag_NV = 1<<0, // invalid operation
			ClobberFFlag_DZ = 1<<1, // divide by zero
			ClobberFFlag_OF = 1<<2, // overflow
			ClobberFFlag_UF = 1<<3, // underflow
			ClobberFFlag_NX = 1<<4, // inexact
		};

		enum ClobberRegs : u8 {
			ClobberReg_RA = 1<<0, // x1, implicit link on C.JAL / C.JALR
			ClobberReg_SP = 1<<1, // x2, implicit base on the *SP compressed forms
		};

		static u8 const CLOBBER_REGS_NAMED = ClobberReg_RA|ClobberReg_SP;

		enum SideEffectFlags : u8 {
			SideEffectFlag_CONTROL     = 1<<0, // writes pc: branches, jumps, and trap redirects
			SideEffectFlag_TRAP        = 1<<1, // synchronous environment trap (ECALL / EBREAK)
			SideEffectFlag_FENCE       = 1<<2, // explicit memory-ordering barrier (FENCE)
			SideEffectFlag_IFENCE      = 1<<3, // instruction-fetch synchronization (FENCE.I)
			SideEffectFlag_ATOMIC      = 1<<4, // indivisible memory RMW (AMO*, and the LR/SC pair)
			SideEffectFlag_RESERVATION = 1<<5, // sets or tests an LR/SC reservation
		};

		enum OperandSet : u8 {
			OperandSet_OP0 = 1<<0,
			OperandSet_OP1 = 1<<1,
			OperandSet_OP2 = 1<<2,
			OperandSet_OP3 = 1<<3,
		};

		u16 clobber_bit_for_reg_name(String const &pin) {
			static const struct { String name; u16 bit; } table[] = {
				{str_lit(\"ra\"),  ClobberReg_RA},
				{str_lit(\"sp\"),  ClobberReg_SP},
				{str_lit(\"x1\"),  ClobberReg_RA},
				{str_lit(\"x2\"),  ClobberReg_SP},
			};
			for (auto const &t : table) {
				if (pin == t.name) {
					return t.bit;
				}
			}
			return 0;
		}

		char const *clobber_reg_bit_name(u16 bit) {
			switch (bit) {
			case ClobberReg_RA: return \"ra\";
			case ClobberReg_SP: return \"sp\";
			}
			return \"<reg>\";
		}

		i32 flag_bit_from_name(String const &name, i32 *width_) {
			static const struct { String name; i32 bit; } table[] = {
				// fflags: accrued FP exception flags (fcsr[4:0])
				{str_lit(\"nx\"),  0}, // Inexact
				{str_lit(\"uf\"),  1}, // Underflow
				{str_lit(\"of\"),  2}, // Overflow
				{str_lit(\"dz\"),  3}, // Divide by Zero
				{str_lit(\"nv\"),  4}, // Invalid Operation
				// frm: rounding mode (fcsr[7:5], 3-bit field, low bit)
				{str_lit(\"frm\"), 5}, // Rounding Mode
			};

			for (auto const &t : table) {
				if (name == t.name) {
					if (width_) {
						if (t.name == \"frm\") {
							*width_ = 3;
						} else {
							*width_ = 1;
						}
					}
					return t.bit;
				}
			}
			return -1;
		}


		struct Clobber {
			OperandSet         written;     // operand slots whose register/CSR is written
			OperandSet         read;        // operand slots whose register/CSR/mem-base is read
			ClobberRegs        implicit_wr; // implicit reg writes (ra on C.JAL/C.JALR)
			ClobberRegs        implicit_rd; // implicit reg reads (sp on the *SP forms)
			ClobberFFlags      fflags_wr;   // accrued exception flags this op may raise
			bool               reads_frm;   // consumes the dynamic rounding mode from fcsr
			bool               writes_mem;
			bool               reads_mem;
			SideEffectFlags side_effects;

			bool implies_clobber_flags() const {
				return (fflags_wr != 0);
			}
			bool implies_clobber_memory() const {
				return writes_mem || reads_mem ||
					(side_effects & (SideEffectFlag_FENCE|SideEffectFlag_ATOMIC)) != 0;
			}
			bool implies_side_effects() const {
				return side_effects != 0;
			}
			u8 is_call_or_mem() const {
				return (cast(u16)side_effects & SideEffectFlag_CONTROL) != 0 ||
					(cast(u16)implicit_wr & ClobberReg_SP) != 0;
			}
			bool has_control() const {
				return (cast(u16)side_effects & SideEffectFlag_CONTROL) != 0;
			}
			bool has_halt() const {
				return (cast(u16)side_effects & SideEffectFlag_TRAP) != 0;
			}
			bool is_conditional() const {
				return has_control();
			}
		};

		void clobber_implicit_regs(StringSet *clobber_registers_set, u16 implicit_regs) {
			u8 regs = cast(u8)implicit_regs;

			for (u8 bit = 1; bit != 0; bit <<= 1) {
				if ((regs & bit) == 0) {
					continue;
				}
				char const *rname = clobber_reg_bit_name(bit);
				string_set_update(clobber_registers_set, make_string_c(rname));
			}
		}
	""")
	strings.write_string(&sb, "\n")

	strings.write_string(&sb, "\n")
	{
		strings.write_string(&sb, """
			enum AliasSrc : u8 {
				AliasSrc_NONE,    // slot unused
				AliasSrc_ARG0,    // user's 1st operand
				AliasSrc_ARG1,    // user's 2nd operand
				AliasSrc_ARG2,    // user's 3rd operand
				AliasSrc_ZERO,    // hardwired zero (x0)
				AliasSrc_LINK,    // link register (ra / x1)
				AliasSrc_LIT,     // the `lit` field below (immediate literal)
				AliasSrc_CSR_LIT, // the `csr` field below (fixed 12-bit CSR address)
			};

			struct PseudoAlias {
				Mnemonic target;    // real instruction emitted
				AliasSrc src[4];    // how to fill target's four operand slots
				i16      lit;       // immediate when a src slot is AliasSrc_LIT
				u16      csr;       // CSR address when a src slot is AliasSrc_CSR_LIT
				u8       nargs;     // operands the user supplies (ARG0..<ARGn)
				bool     rv32_only; // base gate (the *h counter reads)
			};

			enum PseudoMnemonic : u16 {
		""")
		i := 0
		for pm in riscv.Pseudo_Mnemonic {
			if i%4 == 0 {
				fmt.sbprintf(&sb, "\n\t\t")
			}
			fmt.sbprintf(&sb, "PM_%s, ", pm)
			i += 1
		}
		strings.write_string(&sb, "\n\t\tPSEUDO_MNEMONIC_COUNT")
		strings.write_string(&sb, "\n\t};\n")

		strings.write_string(&sb, """
			PseudoMnemonic pseudo_mnemonic_lookup(String const &name) {
				PseudoMnemonic *found = string_map_get(&pseudo_mnemonic_map, name);
				return found ? *found : PM_INVALID;
			}

			PseudoAlias pseudo_alias(u16 pm) {
				PseudoAlias *pa = (PseudoAlias *)raw_pseudo_aliases;
				return pa[pm];
			}
		""")

		strings.write_string(&sb, "\tstatic String const pseudo_mnemonic_strings[PSEUDO_MNEMONIC_COUNT];\n")
		strings.write_string(&sb, "\n")
	}




	strings.write_string(&sb, "\tstatic u16    const register_codes  [REG_COUNT];\n")
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
	strings.write_string(&sb, "\n\n")
	{
		strings.write_string(&sb, "\tenum Feature : u16 {\n")
		defer strings.write_string(&sb, "\t};\n")
		for op in Feature {
			fmt.sbprintf(&sb, "\t\tENC_%s,\n", op)
		}

	}
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, "\ttypedef u8 EncodingFlags; // cannot use a C++ bit field to due lack of portability\n")
	strings.write_string(&sb, "\n")
	{
		defer strings.write_string(&sb, "\tGB_STATIC_ASSERT(gb_size_of(Encoding) == 21);\n")

		strings.write_string(&sb, "\t#pragma pack(push, 1)\n")
		defer strings.write_string(&sb, "\t#pragma pack(pop)\n")
		strings.write_string(&sb, "\tstruct Encoding {\n")
		defer strings.write_string(&sb, "\t};\n")
		strings.write_string(&sb, """
				Mnemonic        mnemonic;
				OperandType     ops[4];
				OperandEncoding enc[4];
				u32             bits;
				u32             mask;
				Feature         feature;
				EncodingFlags   flags;
		\n
		""")
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
		// {
		// 	bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "op_count")
		// 	bit_size   := intrinsics.type_field_bit_size(Encoding_Flags, "op_count")
		// 	strings.write_string(&sb, "\t\tu8   op_count      () const { ")
		// 	fmt.sbprintf(&sb, "return cast(u8)((flags>>%du)&((1u<<%d)-1));", bit_offset, bit_size)
		// 	strings.write_string(&sb, " }\n")
		// }
		// {
		// 	bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "lock_ok")
		// 	strings.write_string(&sb, "\t\tbool lock_ok       () const { ")
		// 	fmt.sbprintf(&sb, "return ((flags>>%du)&1) != 0;", bit_offset)
		// 	strings.write_string(&sb, " }\n")
		// }
		// {
		// 	bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "rep_ok")
		// 	strings.write_string(&sb, "\t\tbool rep_ok        () const { ")
		// 	fmt.sbprintf(&sb, "return ((flags>>%du)&1) != 0;", bit_offset)
		// 	strings.write_string(&sb, " }\n")
		// }
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
	fmt.sbprintf(&sb, "\tstatic EncodeRun const raw_encode_runs   [%d];\n", len(raw_encode_runs))
	fmt.sbprintf(&sb, "\tstatic u8        const raw_encode_forms  [%d];\n", len(raw_encode_forms))
	fmt.sbprintf(&sb, "\tstatic u8        const raw_clobber_forms [%d];\n", len(raw_clobber_forms))
	fmt.sbprintf(&sb, "\tstatic u8        const raw_pseudo_aliases[%d];\n", len(raw_pseudo_aliases))
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, "\tStringMap<Mnemonic> mnemonic_map;\n")
	strings.write_string(&sb, "\tStringMap<Register> register_map;\n")
	strings.write_string(&sb, "\tStringMap<PseudoMnemonic> pseudo_mnemonic_map;\n")

	strings.write_string(&sb, """

		u16 XLEN;
		u16 FLEN;

		bool init(i64 word_size) {
			XLEN = cast(u16)word_size;
			FLEN = cast(u16)word_size;

			string_map_init(&mnemonic_map, MNEMONIC_COUNT*2);
			for (u16 m = M_INVALID+1; m < MNEMONIC_COUNT; m++) {
				string_map_set(&mnemonic_map, mnemonic_strings[m], cast(Mnemonic)m);
			}

			string_map_init(&pseudo_mnemonic_map, PSEUDO_MNEMONIC_COUNT*2);
			for (u16 m = PM_INVALID+1; m < PSEUDO_MNEMONIC_COUNT; m++) {
				string_map_set(&pseudo_mnemonic_map, pseudo_mnemonic_strings[m], cast(PseudoMnemonic)m);
			}

			string_map_init(&register_map, REG_COUNT*2);
			for (u16 r = REG_INVALID+1; r < REG_COUNT; r++) {
				string_map_set(&register_map, register_strings[r], cast(Register)r);
			}
			return true;
		}


		enum MnemonicSuffix : u8 {
			MnemonicSuffix_None = 0,
			MnemonicSuffix_AQ = 1<<0, // Acquire
			MnemonicSuffix_RL = 1<<1, // Release
		};

		bool mnemonic_accepts_suffix(u16 m) const {
			auto forms = encoding_forms(m);
			for (auto const &form : forms) {
				for (auto const &enc : form.enc)  {
					if (enc == ENC_AQRL) {
						return true;
					}
				}
			}
			auto clobbers = clobber_forms(m);
			for (auto const &c : clobbers) {
				if ((cast(u16)c.side_effects & (SideEffectFlag_ATOMIC | SideEffectFlag_RESERVATION)) != 0) {
					return true;
				}
			}
			return false;
		}

		Mnemonic mnemonic_lookup_ordered(String const &name, u8 *suffixes_) {
			u8 suffixes = 0;
			String base = {};
			if (string_ends_with(name, str_lit(\"_aqrl\"))) {
				suffixes = MnemonicSuffix_AQ | MnemonicSuffix_RL;
				base = substring(name, 0, name.len - 5);
			} else if (string_ends_with(name, str_lit(\"_aq\"))) {
				suffixes = MnemonicSuffix_AQ;
				base = substring(name, 0, name.len - 3);
			} else if (string_ends_with(name, str_lit(\"_rl\"))) {
				suffixes = MnemonicSuffix_RL;
				base = substring(name, 0, name.len - 3);
			} else {
				return M_INVALID;
			}
			Mnemonic m = mnemonic_lookup(base);
			if (m == M_INVALID || !mnemonic_accepts_suffix(cast(u16)m)) {
				return M_INVALID;
			}
			if (suffixes_) *suffixes_ = suffixes;
			return m;
		}

		Mnemonic mnemonic_lookup(String const &name) {
			Mnemonic *found = string_map_get(&mnemonic_map, name);
			return found ? *found : M_INVALID;
		}
		Prefix prefix_lookup(String const &name) {
			return PREFIX_INVALID;
		}
		static String const prefix_strings[PREFIX_COUNT];

		Register register_lookup(String const &name) {
			Register *found = string_map_get(&register_map, name);
			return found ? *found : REG_INVALID;
		}
		Slice<Encoding> encoding_forms(/*Mnemonic*/ u16 m) const {
			EncodeRun r = raw_encode_runs[m];
			Encoding *ENCODE_FORMS = cast(Encoding *)raw_encode_forms;
			return Slice<Encoding>{ENCODE_FORMS+r.start, r.count};
		}
		Slice<Clobber> clobber_forms(/*Mnemonic*/ u16 m) const {
			EncodeRun r = raw_encode_runs[m];
			Clobber *CLOBBER_FORMS = cast(Clobber *)raw_clobber_forms;
			return Slice<Clobber>{CLOBBER_FORMS+r.start, r.count};
		}
		u16 reg_class(/*Register*/ u16 r) const {
			return 0xFF00 & r;
		}
		// size in bits for register
		u16 reg_size(Register r) const {
			switch (reg_class(register_codes[r])) {
			case REG_CLASS_GPR64: return 64;
			case REG_CLASS_GPR32: return 32;
			case REG_CLASS_GPR16: return 16;
			case REG_CLASS_GPR8:  return 8;
			case REG_CLASS_GPR8H: return 8;
			case REG_CLASS_XMM:   return 128;
			case REG_CLASS_YMM:   return 256;
			case REG_CLASS_ZMM:   return 512;
			case REG_CLASS_K:     return 64;
			case REG_CLASS_MM:    return 64;
			case REG_CLASS_ST:    return 80;
			case REG_CLASS_SEG:   return 16;
			case REG_CLASS_CR:    return 64;
			case REG_CLASS_DR:    return 64;
			case REG_CLASS_BND:   return 128;
			}
			return 0;
		}

		bool integer_reg_width_is_exact() const {
			return false;
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmOperandKind kind_from_operand_type(OperandType type) const {
			switch (type) {
			case OP_NONE:
				return AsmOperand_Invalid;

			// Registers
			case OP_GPR:
			case OP_FPR:
			case OP_GPR_C:
			case OP_GPR_SP:
			case OP_GPR_NONZERO:
			case OP_FPR_C:
				return AsmOperand_Register;

			case OP_CSR: // 12-bit CSR address; treat as immediate (no CSR reg class exists)
			             // TODO(bill): what should this be?
				return AsmOperand_Immediate;

			// Immediates (incl. things that ultimately encode as an immediate field:
			// CSR address, fence flags, rounding mode).
			case OP_IMM12:
			case OP_IMM12U:
			case OP_IMM5:
			case OP_IMM6:
			case OP_IMM20:
			case OP_FENCE_FLAGS:  // iorw mask -> 4-bit immediate field
			case OP_ROUND_MODE:   // rm -> 3-bit immediate field
			case OP_ZIMM5:
			case OP_IMM_C6S:
			case OP_IMM_C6U:
			case OP_IMM_C8U:
			case OP_IMM_C10S:
			case OP_IMM_C18S:
				return AsmOperand_Immediate;

			// Branch/jump targets are written as labels.
			case OP_REL13:
			case OP_REL21:
			case OP_REL9:
			case OP_REL12:
				return AsmOperand_Label;

			// Memory
			case OP_MEM:
			case OP_MEM_C_W:
			case OP_MEM_C_D:
			case OP_MEM_C_SP_W:
			case OP_MEM_C_SP_D:
				return AsmOperand_Memory;
			}
			return AsmOperand_Invalid;
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmRegClass reg_class_from_operand_type(OperandType type) const {
			switch (type) {
			case OP_GPR:
			case OP_GPR_C:
			case OP_GPR_SP:
			case OP_GPR_NONZERO:
				return AsmRegClass_Integer;

			case OP_FPR:
			case OP_FPR_C:
				return AsmRegClass_Float;

			// No vector/mask operand types are present in this list; everything
			// else (immediates, memory, labels, CSR, etc.) has no register class.
			default:
				return AsmRegClass_Unknown;
			}
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		bool operand_type_is_implicit(OperandType t) const {
			switch (t) {
			// sp is fixed by the mnemonic (c.addi16sp / c.*sp bases) and isn't a
			// register the user freely chooses, so it's encoded implicitly.
			// If your parser actually reads `sp` from the operand text, flip this.
			case OP_GPR_SP:
				return true;
			default:
				return false;
			}
		}
	""")

	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmRegClass operand_type_reg_class(OperandType t) const {
			// Same mapping as reg_class_from_operand_type — these two look
			// redundant; consider collapsing them into one.
			return reg_class_from_operand_type(t);
		}
	""")


	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		u16 operand_type_bit_width(OperandType t) const {
			switch (t) {
			case OP_NONE:
				return 0;

			// Registers -> architectural register data width (like OP_R*, OP_XMM).
			// RISC-V doesn't encode width in the operand type: GPR is XLEN, FPR is
			// FLEN, both target-config dependent -> treat as data-dependent = 0,
			// same as x86 OP_K. (Or hardcode 32/64 if your assembler is fixed-config.)
			// The _C / _SP / _NONZERO variants only restrict *which* regs, not width.
			case OP_GPR:
			case OP_GPR_C:
			case OP_GPR_SP:
			case OP_GPR_NONZERO:
				return XLEN;
			case OP_FPR:
			case OP_FPR_C:
				return FLEN;

			// Memory -> access size (like OP_M*). Base OP_MEM's size comes from the opcode.
			// Compressed forms name the size.
			case OP_MEM:
				return 0;
			case OP_MEM_C_W:
			case OP_MEM_C_SP_W:
				return 32;
			case OP_MEM_C_D:
			case OP_MEM_C_SP_D:
				return 64;

			// Immediates -> value width
			case OP_IMM12:
			case OP_IMM12U:
			case OP_CSR:
				return 12;
			case OP_IMM5:
			case OP_ZIMM5:
				return 5;
			case OP_IMM6:
				return 6;
			case OP_IMM20:
				return 20;
			case OP_FENCE_FLAGS:
				return 4;
			case OP_ROUND_MODE:
				return 3;
			case OP_IMM_C6S:
			case OP_IMM_C6U:
				return 6;
			case OP_IMM_C8U:
				return 8;
			case OP_IMM_C10S:
				return 10;
			case OP_IMM_C18S:
				return 18;

			// Rels -> displacement value width
			case OP_REL13:
				return 13;
			case OP_REL21:
				return 21;
			case OP_REL9:
				return 9;
			case OP_REL12:
				return 12;
			}
			return 0;
		}
	""")

	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		int form_explicit_slot(Encoding const &form, int explicit_index) const {
			int seen = 0;
			for (int j = 0; j < gb_count_of(form.ops); j++) {
				auto t = form.ops[j];
				if (!t) {
					break;
				}
				if (operand_type_is_implicit(t)) {
					continue;
				}
				if (seen == explicit_index) {
					return j;
				}
				seen += 1;
			}
			return -1;
		}
	""")

	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		bool prefix_kind_okay(u8 prefix, Encoding const &form, bool *requires_memory_dest_) const {
			// RISC-V does not have prefixes
			return false;
		}
	""")

	strings.write_string(&sb, "\n};\n")

	strings.write_string(&sb, "\n\n\n")

	fmt.sbprintf(&sb, "gb_global Asm_{0:s} g_asm_{0:s};\n", ISA_NAME)

	strings.write_string(&sb, "\n\n\n")

	fmt.sbprintf(&sb, "String const Asm_{0:s}::prefix_strings[Asm_{0:s}::PREFIX_COUNT]{{}};\n", ISA_NAME)

	{
		fmt.sbprintf(&sb, "String const Asm_{0:s}::mnemonic_strings[Asm_{0:s}::MNEMONIC_COUNT] {{\n", ISA_NAME)
		defer strings.write_string(&sb, "};\n");

		count := uint(0)
		ROW_COUNT :: 16
		for mnemonic in gen.Mnemonic {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}

			#partial switch mnemonic {
			case .INVALID:
				strings.write_string(&sb, "str_lit(\"\"), ")
			case:
				str := strings.to_lower(reflect.enum_string(mnemonic))
				fmt.sbprintf(&sb, "str_lit(%q), ", str)
				delete(str)
			}

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n")
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
		strings.write_string(&sb, "\n")
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
		strings.write_string(&sb, "\n")
	}

	{
		fmt.sbprintf(&sb, "String const Asm_{0:s}::pseudo_mnemonic_strings[Asm_{0:s}::PSEUDO_MNEMONIC_COUNT] {{\n", ISA_NAME)
		defer strings.write_string(&sb, "};\n");

		count := uint(0)
		ROW_COUNT :: 8
		for pm in riscv.Pseudo_Mnemonic {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}

			if pm == .INVALID {
				strings.write_string(&sb, "str_lit(\"\"), ")
			} else {
				str := strings.to_lower(reflect.enum_string(pm))
				fmt.sbprintf(&sb, "str_lit(%q), ", str)
				delete(str)
			}

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		strings.write_string(&sb, "\n")
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
		defer strings.write_string(&sb, "\n")
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
		defer strings.write_string(&sb, "\n")
	}
	{
		fmt.sbprintf(&sb, "u8 const Asm_{0:s}::raw_clobber_forms[%d] = {{\n", ISA_NAME, len(raw_clobber_forms))
		defer strings.write_string(&sb, "};\n");
		ROW_COUNT :: 64
		count := 0
		for the_byte in raw_clobber_forms {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}
			fmt.sbprintf(&sb, "%#02x, ", the_byte)

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		defer strings.write_string(&sb, "\n")
	}
	{
		fmt.sbprintf(&sb, "u8 const Asm_{0:s}::raw_pseudo_aliases[%d] = {{\n", ISA_NAME, len(raw_pseudo_aliases))
		defer strings.write_string(&sb, "};\n");
		ROW_COUNT :: 64
		count := 0
		for the_byte in raw_pseudo_aliases {
			if count == 0 {
				strings.write_string(&sb, "\t")
			}
			fmt.sbprintf(&sb, "%#02x, ", the_byte)

			if count == ROW_COUNT-1 {
				strings.write_string(&sb, "\n")
			}

			count = (count + 1) % ROW_COUNT
		}
		defer strings.write_string(&sb, "\n")
	}



	path := fmt.tprintf("%s/src/asm_tables_%s.cpp", ODIN_ROOT, ISA_NAME)

	if err := os.write_entire_file(path, strings.to_string(sb)); err != nil {
		fmt.eprintfln("rexcode tablegen: failed to write %s: %v", path, err)
		os.exit(1)
	}
}

Operand_Encoding :: type_of(gen.Encoding{}.enc[0])
Feature          :: type_of(gen.Encoding{}.feature)



Register :: enum u16 {
	INVALID,
	ZERO,
	RA,
	SP,
	GP,
	TP,
	T0,
	T1,
	T2,
	S0,
	S1,
	A0,
	A1,
	A2,
	A3,
	A4,
	A5,
	A6,
	A7,
	S2,
	S3,
	S4,
	S5,
	S6,
	S7,
	S8,
	S9,
	S10,
	S11,
	T3,
	T4,
	T5,
	T6,
	FT0,
	FT1,
	FT2,
	FT3,
	FT4,
	FT5,
	FT6,
	FT7,
	FS0,
	FS1,
	FA0,
	FA1,
	FA2,
	FA3,
	FA4,
	FA5,
	FA6,
	FA7,
	FS2,
	FS3,
	FS4,
	FS5,
	FS6,
	FS7,
	FS8,
	FS9,
	FS10,
	FS11,
	FT8,
	FT9,
	FT10,
	FT11,
}

REG_NONE :: 0x0000
REG_GPR  :: 0x0100   // x0..x31
REG_FPR  :: 0x0200   // f0..f31

@(rodata)
REG_CODES := [Register]riscv.Register{
	.INVALID = 0,

	.ZERO = riscv.Register(REG_GPR | 0),
	.RA   = riscv.Register(REG_GPR | 1),
	.SP   = riscv.Register(REG_GPR | 2),
	.GP   = riscv.Register(REG_GPR | 3),
	.TP   = riscv.Register(REG_GPR | 4),
	.T0   = riscv.Register(REG_GPR | 5),   .T1  = riscv.Register(REG_GPR | 6),   .T2 = riscv.Register(REG_GPR | 7),
	.S0   = riscv.Register(REG_GPR | 8),   .S1  = riscv.Register(REG_GPR | 9),
	.A0   = riscv.Register(REG_GPR | 10),  .A1  = riscv.Register(REG_GPR | 11),  .A2 = riscv.Register(REG_GPR | 12),  .A3 = riscv.Register(REG_GPR | 13),
	.A4   = riscv.Register(REG_GPR | 14),  .A5  = riscv.Register(REG_GPR | 15),  .A6 = riscv.Register(REG_GPR | 16),  .A7 = riscv.Register(REG_GPR | 17),
	.S2   = riscv.Register(REG_GPR | 18),  .S3  = riscv.Register(REG_GPR | 19),  .S4 = riscv.Register(REG_GPR | 20),  .S5 = riscv.Register(REG_GPR | 21),
	.S6   = riscv.Register(REG_GPR | 22),  .S7  = riscv.Register(REG_GPR | 23),  .S8 = riscv.Register(REG_GPR | 24),  .S9 = riscv.Register(REG_GPR | 25),
	.S10  = riscv.Register(REG_GPR | 26),  .S11 = riscv.Register(REG_GPR | 27),
	.T3   = riscv.Register(REG_GPR | 28),  .T4  = riscv.Register(REG_GPR | 29),  .T5 = riscv.Register(REG_GPR | 30),  .T6 = riscv.Register(REG_GPR | 31),

	.FT0  = riscv.Register(REG_FPR | 0),  .FT1  = riscv.Register(REG_FPR | 1),  .FT2  = riscv.Register(REG_FPR | 2),  .FT3  = riscv.Register(REG_FPR | 3),
	.FT4  = riscv.Register(REG_FPR | 4),  .FT5  = riscv.Register(REG_FPR | 5),  .FT6  = riscv.Register(REG_FPR | 6),  .FT7  = riscv.Register(REG_FPR | 7),
	.FS0  = riscv.Register(REG_FPR | 8),  .FS1  = riscv.Register(REG_FPR | 9),
	.FA0  = riscv.Register(REG_FPR | 10), .FA1  = riscv.Register(REG_FPR | 11), .FA2  = riscv.Register(REG_FPR | 12), .FA3  = riscv.Register(REG_FPR | 13),
	.FA4  = riscv.Register(REG_FPR | 14), .FA5  = riscv.Register(REG_FPR | 15), .FA6  = riscv.Register(REG_FPR | 16), .FA7  = riscv.Register(REG_FPR | 17),
	.FS2  = riscv.Register(REG_FPR | 18), .FS3  = riscv.Register(REG_FPR | 19), .FS4  = riscv.Register(REG_FPR | 20), .FS5  = riscv.Register(REG_FPR | 21),
	.FS6  = riscv.Register(REG_FPR | 22), .FS7  = riscv.Register(REG_FPR | 23), .FS8  = riscv.Register(REG_FPR | 24), .FS9  = riscv.Register(REG_FPR | 25),
	.FS10 = riscv.Register(REG_FPR | 26), .FS11 = riscv.Register(REG_FPR | 27),
	.FT8  = riscv.Register(REG_FPR | 28), .FT9  = riscv.Register(REG_FPR | 29), .FT10 = riscv.Register(REG_FPR | 30), .FT11 = riscv.Register(REG_FPR | 31),

}