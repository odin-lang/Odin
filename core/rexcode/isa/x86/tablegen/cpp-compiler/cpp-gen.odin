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
	raw_encode_runs   := #load("../../tables/x86.encode_runs.bin",  []x86.Encode_Run)
	raw_encode_forms  := #load("../../tables/x86.encode_forms.bin", []u8)
	raw_clobber_forms := #load("../../tables/x86.clobber_forms.bin", []u8)

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
		strings.write_string(&sb, "\tenum PrefixKind : u8 { PrefixKind_None, PrefixKind_Lock, PrefixKind_Rep, PrefixKind_Repne, PrefixKind_Other };\n");
		strings.write_string(&sb, "\n");
	}

	{
		strings.write_string(&sb, "\n");
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
	strings.write_string(&sb, "\n");
	strings.write_string(&sb, """
		enum ClobberFlags : u16 {
			ClobberFlag_CF = 1<<0,
			ClobberFlag_PF = 1<<1,
			ClobberFlag_AF = 1<<2,
			ClobberFlag_ZF = 1<<3,
			ClobberFlag_SF = 1<<4,
			ClobberFlag_OF = 1<<5,
			ClobberFlag_DF = 1<<6,
			ClobberFlag_IF = 1<<7,
			ClobberFlag_TF = 1<<8,
		};
		static u16 const CLOBBER_FLAGS_COND = ClobberFlag_CF|ClobberFlag_PF|ClobberFlag_AF|ClobberFlag_ZF|ClobberFlag_SF|ClobberFlag_OF;

		char const *clobber_flag_bit_name(u16 bit) {
			switch (bit) {
			case ClobberFlag_CF: return \"c\"; case ClobberFlag_PF: return \"p\";
			case ClobberFlag_AF: return \"a\"; case ClobberFlag_ZF: return \"z\";
			case ClobberFlag_SF: return \"s\"; case ClobberFlag_OF: return \"o\";
			}
			return \"?\";
		}

		enum SideEffectFlags : u16 {
			SideEffectFlag_FENCE       = 1<<0, // memory-ordering barrier (LFENCE/SFENCE/MFENCE, LOCK)
			SideEffectFlag_SERIALIZING = 1<<1, // architecturally serializing (drains pipeline)
			SideEffectFlag_HINT        = 1<<2, // microarchitectural hint, architecturally inert (PAUSE/PREFETCH*/ENDBR)
			SideEffectFlag_CACHE       = 1<<3, // cache-line maintenance with coherence effects (CLFLUSH/CLWB)
			SideEffectFlag_TRAP        = 1<<4, // may deliberately raise a fault (#UD/#BR): UD0-2, BOUND
			SideEffectFlag_INTERRUPT   = 1<<5, // software interrupt / syscall gate
			SideEffectFlag_HALT        = 1<<6, // stops execution until an external event
			SideEffectFlag_PRIVILEGED  = 1<<7, // requires CPL0 / reads-writes supervisor machine state
			SideEffectFlag_CONTROL     = 1<<8, // alters control flow (writes RIP): branches, calls, returns
			SideEffectFlag_CET         = 1<<9, // control-flow-enforcement: landing pads, shadow-stack ops
			SideEffectFlag_NONDETERMINISTIC = 1<<10,
		};
		enum ClobberRegs : u16 {
			ClobberReg_RAX    = 1<<0,
			ClobberReg_RBX    = 1<<1,
			ClobberReg_RCX    = 1<<2,
			ClobberReg_RDX    = 1<<3,
			ClobberReg_RSI    = 1<<4,
			ClobberReg_RDI    = 1<<5,
			ClobberReg_RSP    = 1<<6,
			ClobberReg_RBP    = 1<<7,
			ClobberReg_R11    = 1<<8,
			ClobberReg_XMM0   = 1<<9,
			ClobberReg_VECTOR = 1<<10,
			ClobberReg_MXCSR  = 1<<11,
			ClobberReg_FPU_ST = 1<<12,
			ClobberReg_FPU_SW = 1<<13,
		};

		static u16 const CLOBBER_REGS_NAMED =
		    ClobberReg_RAX|ClobberReg_RBX|ClobberReg_RCX|ClobberReg_RDX|
		    ClobberReg_RSI|ClobberReg_RDI|ClobberReg_RBP|ClobberReg_R11|
		    ClobberReg_XMM0;

		enum OperandSet : u8 {
			OperandSet_OP0 = 1<<0,
			OperandSet_OP1 = 1<<1,
			OperandSet_OP2 = 1<<2,
			OperandSet_OP3 = 1<<3,
		};

		u16 clobber_bit_for_reg_name(String const &pin) {
			static const struct { String name; u16 bit; } table[] = {
				{str_lit(\"rax\"),  ClobberReg_RAX}, {str_lit(\"eax\"),  ClobberReg_RAX}, {str_lit(\"ax\"), ClobberReg_RAX}, {str_lit(\"al\"), ClobberReg_RAX}, {str_lit(\"ah\"), ClobberReg_RAX},
				{str_lit(\"rbx\"),  ClobberReg_RBX}, {str_lit(\"ebx\"),  ClobberReg_RBX}, {str_lit(\"bx\"), ClobberReg_RBX}, {str_lit(\"bl\"), ClobberReg_RBX}, {str_lit(\"bh\"), ClobberReg_RBX},
				{str_lit(\"rcx\"),  ClobberReg_RCX}, {str_lit(\"ecx\"),  ClobberReg_RCX}, {str_lit(\"cx\"), ClobberReg_RCX}, {str_lit(\"cl\"), ClobberReg_RCX}, {str_lit(\"ch\"), ClobberReg_RCX},
				{str_lit(\"rdx\"),  ClobberReg_RDX}, {str_lit(\"edx\"),  ClobberReg_RDX}, {str_lit(\"dx\"), ClobberReg_RDX}, {str_lit(\"dl\"), ClobberReg_RDX}, {str_lit(\"dh\"), ClobberReg_RDX},
				{str_lit(\"rsi\"),  ClobberReg_RSI}, {str_lit(\"esi\"),  ClobberReg_RSI}, {str_lit(\"si\"), ClobberReg_RSI}, {str_lit(\"sil\"), ClobberReg_RSI},
				{str_lit(\"rdi\"),  ClobberReg_RDI}, {str_lit(\"edi\"),  ClobberReg_RDI}, {str_lit(\"di\"), ClobberReg_RDI}, {str_lit(\"dil\"), ClobberReg_RDI},
				{str_lit(\"rsp\"),  ClobberReg_RSP}, {str_lit(\"esp\"),  ClobberReg_RSP},
				{str_lit(\"rbp\"),  ClobberReg_RBP}, {str_lit(\"ebp\"),  ClobberReg_RBP},
				{str_lit(\"r11\"),  ClobberReg_R11}, {str_lit(\"r11d\"), ClobberReg_R11},
				{str_lit(\"r11w\"), ClobberReg_R11}, {str_lit(\"r11b\"), ClobberReg_R11},
				{str_lit(\"xmm0\"), ClobberReg_XMM0},
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
			case ClobberReg_RAX:  return \"rax\";
			case ClobberReg_RBX:  return \"rbx\";
			case ClobberReg_RCX:  return \"rcx\";
			case ClobberReg_RDX:  return \"rdx\";
			case ClobberReg_RSI:  return \"rsi\";
			case ClobberReg_RDI:  return \"rdi\";
			case ClobberReg_RSP:  return \"rsp\";
			case ClobberReg_RBP:  return \"rbp\";
			case ClobberReg_R11:  return \"r11\";
			case ClobberReg_XMM0: return \"xmm0\";
			}
			return \"<reg>\";
		}

		i32 flag_bit_from_name(String const &name, i32 *width_) {
			static const struct {String name; i32 bit; } table[] = {
				{str_lit(\"c\"),    0}, // Carry
				{str_lit(\"p\"),    2}, // Parity
				{str_lit(\"a\"),    4}, // Auxiliary Carry
				{str_lit(\"z\"),    6}, // Zero
				{str_lit(\"s\"),    7}, // Sign
				{str_lit(\"t\"),    8}, // Trap
				{str_lit(\"i\"),    9}, // Interrupt Enable
				{str_lit(\"d\"),   10}, // Direction
				{str_lit(\"o\"),   11}, // Overflow
				{str_lit(\"iopl\"),12}, // I/O Privilege Level (2-bit field: bits 12-13, low bit)
				{str_lit(\"nt\"),  14}, // Nested Task
				{str_lit(\"r\"),   16}, // Resume
				{str_lit(\"vm\"),  17}, // Virtual-8086 Mode
				{str_lit(\"ac\"),  18}, // Alignment Check / Access Control
				{str_lit(\"vi\"),  19}, // Virtual Interrupt Flag
				{str_lit(\"vip\"), 20}, // Virtual Interrupt Pending
				{str_lit(\"id\"),  21}, // Identification
			};

			for (auto const &t : table) {
				if (name == t.name) {
					if (width_) {
						if (t.name == \"iopl\") {
							*width_ = 2;
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
			OperandSet      written;
			OperandSet      read;
			ClobberRegs     implicit_wr;
			ClobberRegs     implicit_rd;
			ClobberFlags    flags_wr;
			ClobberFlags    flags_undef;
			ClobberFlags    flags_rd;
			bool            writes_mem;
			bool            reads_mem;
			SideEffectFlags side_effects;

			bool implies_clobber_flags() const {
				u16 const FLAGS_MASK = ClobberFlag_CF|ClobberFlag_PF|ClobberFlag_AF|
				                       ClobberFlag_ZF|ClobberFlag_SF|ClobberFlag_OF;
				return ((flags_wr | flags_undef) & FLAGS_MASK) != 0;
			}
			bool implies_clobber_memory() const {
				return writes_mem || reads_mem ||
					(side_effects & (SideEffectFlag_FENCE |
					                 SideEffectFlag_CACHE |
					                 SideEffectFlag_SERIALIZING)) != 0;
			}
			bool implies_side_effects() const {
				u16 const VOLATILE_SE =
					SideEffectFlag_FENCE       |
					SideEffectFlag_SERIALIZING |
					SideEffectFlag_CACHE       |
					SideEffectFlag_TRAP        |
					SideEffectFlag_INTERRUPT   |
					SideEffectFlag_HALT        |
					SideEffectFlag_PRIVILEGED  |
					SideEffectFlag_CONTROL     |
					SideEffectFlag_CET         |
					SideEffectFlag_NONDETERMINISTIC;
					// NOTE: SideEffectFlag_HINT deliberately excluded — inert, may be DCE'd.
				return ((side_effects & VOLATILE_SE) != 0);
			}

			u8 is_call_or_mem() const {
				return (cast(u16)side_effects & SideEffectFlag_CONTROL) != 0 ||
					(cast(u16)implicit_wr & ClobberReg_RSP) != 0;
			}
			bool has_control() const {
				return (cast(u16)side_effects & SideEffectFlag_CONTROL) != 0;
			}
			bool has_halt() const {
				return (cast(u16)side_effects & SideEffectFlag_HALT) != 0;
			}
			bool is_conditional() const {
				return has_control() && (cast(u16)flags_rd != 0);
			}
			bool is_nondeterministic() const {
				return (cast(u16)side_effects & SideEffectFlag_NONDETERMINISTIC) != 0;
			}
		};

		void clobber_implicit_regs(StringSet *clobber_registers_set, u16 implicit_regs) {
			u16 regs = implicit_regs & CLOBBER_REGS_NAMED;

			for (u16 bit = 1; bit != 0; bit <<= 1) {
				if ((regs & bit) == 0) {
					continue;
				}
				char const *rname = clobber_reg_bit_name(bit);
				string_set_update(clobber_registers_set, make_string_c(rname));
			}
		}
	""")
	strings.write_string(&sb, "\n");
	strings.write_string(&sb, "\n");
	strings.write_string(&sb, """
		enum AliasSrc : u8 {
			AliasSrc_NONE,    // slot unused
			AliasSrc_ARG0,    // user's 1st operand
			AliasSrc_ARG1,    // user's 2nd operand
			AliasSrc_ARG2,    // user's 3rd operand
			AliasSrc_ZERO,    // hardwired zero
			AliasSrc_LINK,    // link register
			AliasSrc_LIT,
		};

		// NOTE(bill): These are completely dummy things as it is only needed by RISC-V and not x86
		struct PseudoAlias {
			Mnemonic target; // real instruction emitted
			AliasSrc src[4]; // how to fill target's four operand slots
			i16      lit;    // immediate when a src slot is AliasSrc_LIT
			u16      csr;    // CSR address when a src slot is AliasSrc_CSR_LIT
			u8       nargs;  // operands the user supplies (ARG0..<ARGn)

			bool is_nondeterministic() const {
				return false;
			}
		};
		enum PseudoMnemonic : u16 {
			PM_INVALID,
			PSEUDO_MNEMONIC_COUNT
		};

		PseudoMnemonic pseudo_mnemonic_lookup(String const &name) {
			return PM_INVALID;
		}

		PseudoAlias pseudo_alias(u16 pm) {
			return {};
		}
	""")

	strings.write_string(&sb, "\tstatic String const pseudo_mnemonic_strings[PSEUDO_MNEMONIC_COUNT];\n")
	strings.write_string(&sb, "\n")


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
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, "\ttypedef u32 EncodingFlags; // cannot use a C++ bit field to due lack of portability\n")
	strings.write_string(&sb, "\n")
	{
		defer strings.write_string(&sb, "\tGB_STATIC_ASSERT(gb_size_of(Encoding) == 16);\n")

		strings.write_string(&sb, "\t#pragma pack(push, 1)\n")
		defer strings.write_string(&sb, "\t#pragma pack(pop)\n")
		strings.write_string(&sb, "\tstruct Encoding {\n")
		defer strings.write_string(&sb, "\t};\n")
		strings.write_string(&sb, """
				Mnemonic        mnemonic;
				OperandType     ops[4];
				OperandEncoding enc[4];
				u8              opcode;
				u8              ext;
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
		{
			bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "lock_ok")
			strings.write_string(&sb, "\t\tbool lock_ok       () const { ")
			fmt.sbprintf(&sb, "return ((flags>>%du)&1) != 0;", bit_offset)
			strings.write_string(&sb, " }\n")
		}
		{
			bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "rep_ok")
			strings.write_string(&sb, "\t\tbool rep_ok        () const { ")
			fmt.sbprintf(&sb, "return ((flags>>%du)&1) != 0;", bit_offset)
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
	fmt.sbprintf(&sb, "\tstatic EncodeRun const raw_encode_runs  [%d];\n", len(raw_encode_runs))
	fmt.sbprintf(&sb, "\tstatic u8        const raw_encode_forms [%d];\n", len(raw_encode_forms))
	fmt.sbprintf(&sb, "\tstatic u8        const raw_clobber_forms[%d];\n", len(raw_clobber_forms))
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, "\tStringMap<Mnemonic> mnemonic_map;\n")
	strings.write_string(&sb, "\tStringMap<Prefix>   prefix_map;\n")
	strings.write_string(&sb, "\tStringMap<Register> register_map;\n")

	strings.write_string(&sb, """

		bool init(i64 word_size) {
			gb_unused(word_size);
			string_map_init(&mnemonic_map, MNEMONIC_COUNT*2);
			for (u16 m = M_INVALID+1; m < MNEMONIC_COUNT; m++) {
				string_map_set(&mnemonic_map, mnemonic_strings[m], cast(Mnemonic)m);
			}
			string_map_init(&prefix_map, PREFIX_COUNT*2);
			for (u8 r = PREFIX_INVALID+1; r < PREFIX_COUNT; r++) {
				string_map_set(&prefix_map, prefix_strings[r], cast(Prefix)r);
			}
			string_map_init(&register_map, REG_COUNT*2);
			for (u16 r = REG_INVALID+1; r < REG_COUNT; r++) {
				string_map_set(&register_map, register_strings[r], cast(Register)r);
			}
			return true;
		}


		enum MnemonicSuffix : u8 {
			MnemonicSuffix_None = 0,
		};

		bool mnemonic_accepts_suffix(u16 m) const {
			return false;
		}

		Mnemonic mnemonic_lookup_ordered(String const &name, u8 *suffixes_) {
			// NOTE(bill): Do any instructions need a suffix idea?
			return M_INVALID;
		}

		enum PseudoMacroMnemonic : u8 {
			PseudoMacroMnemonic_INVALID,
			PseudoMacroMnemonic_COUNT
		};

		PseudoMacroMnemonic pseudo_macro_mnemonic_lookup(String const &name) {
			return PseudoMacroMnemonic_INVALID;
		}

		Mnemonic mnemonic_lookup(String const &name) {
			Mnemonic *found = string_map_get(&mnemonic_map, name);
			return found ? *found : M_INVALID;
		}
		Prefix prefix_lookup(String const &name) {
			Prefix *found = string_map_get(&prefix_map, name);
			return found ? *found : PREFIX_INVALID;
		}
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
			return true;
		}
		bool float_reg_width_is_exact() const {
			return true;
		}
		bool supports_memory_index_not_just_disp() const {
			return true;
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmOperandKind kind_from_operand_type(OperandType type) const {
			switch (type) {
			case OP_R8:  case OP_R16: case OP_R32: case OP_R64:
			case OP_SREG: case OP_CR: case OP_DR:
			case OP_XMM: case OP_YMM: case OP_ZMM:
			case OP_MM:  case OP_K:   case OP_STI:
			case OP_AL_IMPL:  case OP_AX_IMPL: case OP_EAX_IMPL: case OP_RAX_IMPL:
			case OP_CL_IMPL:  case OP_DX_IMPL:
			case OP_ST0_IMPL: case OP_XMM0_IMPL:
				return AsmOperand_Register;
			case OP_RM8: case OP_RM16: case OP_RM32: case OP_RM64:
			case OP_XMM_M32: case OP_XMM_M64: case OP_XMM_M128:
			case OP_YMM_M256: case OP_ZMM_M512:
			case OP_MM_M64:
			case OP_K_M8: case OP_K_M16: case OP_K_M32: case OP_K_M64:
				return AsmOperand_Register_Or_Memory;
			case OP_M:   case OP_M8:  case OP_M16: case OP_M32: case OP_M64:
			case OP_M80: case OP_M128: case OP_M256: case OP_M512:
			case OP_MOFFS8: case OP_MOFFS16: case OP_MOFFS32: case OP_MOFFS64:
			case OP_M16_16: case OP_M16_32: case OP_M16_64:
				return AsmOperand_Memory;
			case OP_IMM8: case OP_IMM16: case OP_IMM32: case OP_IMM64:
			case OP_IMM8SX:
			case OP_ONE_IMPL:
			case OP_PTR16_16: case OP_PTR16_32: case OP_PTR16_64:
				return AsmOperand_Immediate;
			case OP_REL8: case OP_REL32:
				return AsmOperand_Label;
			case OP_NONE:
			default:
				return AsmOperand_Invalid;
			}
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmRegClass reg_class_from_operand_type(OperandType type) const {
			switch (type) {
			case OP_R8:  case OP_R16: case OP_R32: case OP_R64:
			case OP_RM8: case OP_RM16: case OP_RM32: case OP_RM64:
			case OP_AL_IMPL:  case OP_AX_IMPL: case OP_EAX_IMPL: case OP_RAX_IMPL:
			case OP_CL_IMPL:  case OP_DX_IMPL:
				return AsmRegClass_Integer;

			case OP_XMM: case OP_YMM: case OP_ZMM:
			case OP_XMM_M32: case OP_XMM_M64: case OP_XMM_M128:
			case OP_YMM_M256: case OP_ZMM_M512:
			case OP_XMM0_IMPL:
				return AsmRegClass_Vector;

			case OP_K:
			case OP_K_M8: case OP_K_M16: case OP_K_M32: case OP_K_M64:
				return AsmRegClass_Mask;

			case OP_STI:
			case OP_ST0_IMPL:
				return AsmRegClass_Float;

			case OP_MM:
			case OP_MM_M64:
				return AsmRegClass_Vector;

			case OP_SREG: case OP_CR: case OP_DR:
			case OP_M:    case OP_M8: case OP_M16: case OP_M32: case OP_M64:
			case OP_M80:  case OP_M128: case OP_M256: case OP_M512:
			case OP_MOFFS8: case OP_MOFFS16: case OP_MOFFS32: case OP_MOFFS64:
			case OP_M16_16: case OP_M16_32: case OP_M16_64:
			case OP_IMM8: case OP_IMM16: case OP_IMM32: case OP_IMM64:
			case OP_IMM8SX:
			case OP_ONE_IMPL:
			case OP_PTR16_16: case OP_PTR16_32: case OP_PTR16_64:
			case OP_REL8: case OP_REL32:
			case OP_NONE:
			default:
				return AsmRegClass_Unknown;
			}
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		bool operand_type_is_implicit(OperandType t) const {
			switch (t) {
			case OP_AL_IMPL:  case OP_AX_IMPL:
			case OP_EAX_IMPL: case OP_RAX_IMPL:
			case OP_CL_IMPL:  case OP_DX_IMPL:
			case OP_ONE_IMPL:
			case OP_ST0_IMPL: case OP_XMM0_IMPL:
				return true;
			}
			return false;
		}
	""")

	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmRegClass operand_type_reg_class(OperandType t) const {
			switch (t) {
			case OP_R8:  case OP_R16:  case OP_R32:  case OP_R64:
			case OP_RM8: case OP_RM16: case OP_RM32: case OP_RM64:
			case OP_AL_IMPL: case OP_AX_IMPL: case OP_EAX_IMPL: case OP_RAX_IMPL:
			case OP_CL_IMPL: case OP_DX_IMPL:
				return AsmRegClass_Integer;
			case OP_XMM: case OP_YMM: case OP_ZMM:
			case OP_XMM_M32: case OP_XMM_M64: case OP_XMM_M128:
			case OP_YMM_M256: case OP_ZMM_M512:
			case OP_XMM0_IMPL:
				return AsmRegClass_Vector; // xmm/ymm/zmm; float scalars also land here (see note)
			case OP_K:
			case OP_K_M8: case OP_K_M16: case OP_K_M32: case OP_K_M64:
				return AsmRegClass_Mask;
			}
			return AsmRegClass_Unknown; // OP_M*, OP_IMM*, OP_REL*, OP_SREG/CR/DR/MM/STi, moffs, ptr, m16_16... : no GPR/XMM class constraint here
		}
	""")


	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		// Slots only a specific named hardware register can fill. They carry no GPR/vector
		// class and, apart from OP_MM, no width either. Nothing else in the size/class
		// check constrains them and a template parameter would otherwise slip through.
		u16 operand_type_named_reg_class(OperandType t) const {
			switch (t) {
			case OP_SREG: return REG_CLASS_SEG;
			case OP_CR:   return REG_CLASS_CR;
			case OP_DR:   return REG_CLASS_DR;
			case OP_STI:  return REG_CLASS_ST;
			case OP_MM:   return REG_CLASS_MM;
			}
			return REG_CLASS_NONE;
		}

		String named_reg_class_string(u16 reg_class) const {
			switch (reg_class) {
			case REG_CLASS_SEG: return str_lit("segment");
			case REG_CLASS_CR:  return str_lit("control");
			case REG_CLASS_DR:  return str_lit("debug");
			case REG_CLASS_ST:  return str_lit("x87 stack");
			case REG_CLASS_MM:  return str_lit("MMX");
			}
			return str_lit("hardware");
		}
	""")


	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		u16 operand_type_bit_width(OperandType t) const {
			switch (t) {
			case OP_R8:  case OP_RM8:  case OP_M8:  case OP_AL_IMPL:  case OP_CL_IMPL: case OP_K_M8:  return 8;
			case OP_R16: case OP_RM16: case OP_M16: case OP_AX_IMPL:  case OP_DX_IMPL: case OP_K_M16: return 16;
			case OP_R32: case OP_RM32: case OP_M32: case OP_EAX_IMPL: case OP_XMM_M32: case OP_K_M32: return 32;
			case OP_R64: case OP_RM64: case OP_M64: case OP_RAX_IMPL: case OP_XMM_M64: case OP_K_M64: case OP_MM: case OP_MM_M64: return 64;
			case OP_M128: case OP_XMM: case OP_XMM_M128: case OP_XMM0_IMPL: return 128;
			case OP_M256: case OP_YMM: case OP_YMM_M256: return 256;
			case OP_M512: case OP_ZMM: case OP_ZMM_M512: return 512;
			case OP_IMM8:  return 8;
			case OP_IMM16: return 16;
			case OP_IMM32: return 32;
			case OP_IMM64: return 64;
			case OP_REL8:  return 8;
			case OP_REL32: return 32;
			case OP_IMM8SX: return 8;
			}
			return 0; // OP_M (sizeless), OP_K (opmask width is data-dependent), OP_ONE_IMPL, moffs, ptr, sreg/cr/dr, etc.
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
			PrefixKind kind = PrefixKind_None;
			if (prefix != 0) {
				switch (prefix) {
				case PREFIX_LOCK:  kind = PrefixKind_Lock;  break;
				case PREFIX_REP:   kind = PrefixKind_Rep;   break;
				case PREFIX_REPNE: kind = PrefixKind_Repne; break;
				default:           kind = PrefixKind_Other; break;
				}
			}
			switch (kind) {
			case PrefixKind_Lock:
				if (!form.lock_ok()) {
					return false;
				}
				if (requires_memory_dest_) *requires_memory_dest_ = true;
				return true;
			case PrefixKind_Rep:
				return form.rep_ok();
			case PrefixKind_Repne:
				return form.rep_ok();
			case PrefixKind_Other:
			case PrefixKind_None:
				return true;
			}
			return true;
		}
	""")

	strings.write_string(&sb, "\n};\n")

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

	fmt.sbprintf(&sb, "String const Asm_{0:s}::pseudo_mnemonic_strings[Asm_{0:s}::PSEUDO_MNEMONIC_COUNT] {{}};\n", ISA_NAME)

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