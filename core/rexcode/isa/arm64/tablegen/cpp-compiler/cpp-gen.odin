package cpp_gen

import "base:intrinsics"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:reflect"
import "core:rexcode/isa/arm64"

import gen ".."

ISA_NAME :: "arm64"

main :: proc() {
	raw_encode_runs   := #load("../../tables/arm64.encode_runs.bin",  []arm64.Encode_Run)
	raw_encode_forms  := #load("../../tables/arm64.encode_forms.bin", []u8)
	raw_clobber_forms := #load("../../tables/arm64.clobber_forms.bin", []u8)
	// NOTE: arm64 has no pseudo-alias table (unlike riscv). Nothing to load here.

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
		// arm64 has no instruction prefixes. Keep dummy symbols so the shared
		// C++ front-end still has Prefix / PrefixKind to name.
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
			static const u16 REG_CLASS_NONE = 0x0000;
			static const u16 REG_CLASS_X    = 0x0100; // X0..X30, XZR
			static const u16 REG_CLASS_W    = 0x0200; // W0..W30, WZR
			static const u16 REG_CLASS_XSP  = 0x0300; // SP  (opt-in, distinct from X)
			static const u16 REG_CLASS_WSP  = 0x0400; // WSP (opt-in, distinct from W)
			static const u16 REG_CLASS_V    = 0x0500; // V0..V31 (full 128-bit SIMD&FP)
			static const u16 REG_CLASS_B    = 0x0600; // B0..B31 (byte view)
			static const u16 REG_CLASS_H    = 0x0700; // H0..H31 (half view)
			static const u16 REG_CLASS_S    = 0x0800; // S0..S31 (single view)
			static const u16 REG_CLASS_D    = 0x0900; // D0..D31 (double view)
			static const u16 REG_CLASS_Q    = 0x0A00; // Q0..Q31 (quad view)
			static const u16 REG_CLASS_Z    = 0x0B00; // Z0..Z31 SVE scalable vector
			static const u16 REG_CLASS_P    = 0x0C00; // P0..P15 SVE predicate
			static const u16 REG_CLASS_PN   = 0x0D00; // PN8..PN15 SME2 predicate-as-counter
			static const u16 REG_CLASS_ZT   = 0x0E00; // ZT0 SME2 lookup table
			static const u16 REG_CLASS_ZA   = 0x0F00; // ZA0..ZA15 SME accumulator tiles
			static const u16 REG_CLASS_SYS  = 0x1000; // MRS/MSR system registers
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
		strings.write_string(&sb, "\tenum Feature : u8 {\n")
		defer strings.write_string(&sb, "\t};\n")
		for op in Feature {
			fmt.sbprintf(&sb, "\t\tF_%s,\n", op)
		}

	}
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, "\ttypedef u8 EncodingFlags; // cannot use a C++ bit field to due lack of portability\n")
	strings.write_string(&sb, "\n")
	{
		defer strings.write_string(&sb, "\tGB_STATIC_ASSERT(gb_size_of(Encoding) == 22);\n")

		strings.write_string(&sb, "\t#pragma pack(push, 1)\n")
		defer strings.write_string(&sb, "\t#pragma pack(pop)\n")
		strings.write_string(&sb, "\tstruct Encoding {\n")
		defer strings.write_string(&sb, "\t};\n")
		strings.write_string(&sb, """
				Mnemonic        mnemonic;
				OperandType     ops[5];
				OperandEncoding enc[5];
				u32             bits;
				u32             mask;
				Feature         feature;
				EncodingFlags   flags;
		\n
		""")
		Encoding_Flags :: type_of(gen.Encoding{}.flags)

		{
			strings.write_string(&sb, "\t\tbool has_implicit  () const { ")
			strings.write_string(&sb, "return false;")
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
			bit_offset := intrinsics.type_field_bit_offset(Encoding_Flags, "cond_branch")
			strings.write_string(&sb, "\t\tbool is_conditional() const { ")
			fmt.sbprintf(&sb, "return ((flags>>%du)&1) != 0;", bit_offset)
			strings.write_string(&sb, " }\n")
		}
	}
	strings.write_string(&sb, "\n")
	strings.write_string(&sb, """

		// Condition flags (PSTATE.NZCV). Named ClobberFlags to match the shared
		// C++ front-end's "flags" concept (x86 EFLAGS / riscv fcsr exceptions).
		enum ClobberFlags : u8 {
			ClobberFlag_N = 1<<0, // negative result
			ClobberFlag_Z = 1<<1, // zero result
			ClobberFlag_C = 1<<2, // carry-out / no-borrow (unsigned sense)
			ClobberFlag_V = 1<<3, // signed overflow
		};
		static u16 const CLOBBER_FLAGS_COND = ClobberFlag_N|ClobberFlag_Z|ClobberFlag_C|ClobberFlag_V;

		char const *clobber_flag_bit_name(u16 bit) {
			switch (bit) {
			case ClobberFlag_N: return \"n\";
			case ClobberFlag_Z: return \"z\";
			case ClobberFlag_C: return \"c\";
			case ClobberFlag_V: return \"v\";
			}
			return \"?\";
		}

		// FPSR cumulative FP exception / saturation flags (separate register from NZCV).
		enum FPSRFlags : u8 {
			FPSRFlag_IOC = 1<<0, // invalid operation
			FPSRFlag_DZC = 1<<1, // divide by zero
			FPSRFlag_OFC = 1<<2, // overflow
			FPSRFlag_UFC = 1<<3, // underflow
			FPSRFlag_IXC = 1<<4, // inexact
			FPSRFlag_IDC = 1<<5, // input denormal
			FPSRFlag_QC  = 1<<6, // cumulative saturation (Advanced SIMD)
		};

		char const *fpsr_flag_bit_name(u16 bit) {
			switch (bit) {
			case FPSRFlag_IOC: return \"ioc\";
			case FPSRFlag_DZC: return \"dzc\";
			case FPSRFlag_OFC: return \"ofc\";
			case FPSRFlag_UFC: return \"ufc\";
			case FPSRFlag_IXC: return \"ixc\";
			case FPSRFlag_IDC: return \"idc\";
			case FPSRFlag_QC:  return \"qc\";
			}
			return \"?\";
		}

		enum ClobberRegs : u8 {
			ClobberReg_LR  = 1<<0, // x30, implicit link written by BL/BLR, read by RET
			ClobberReg_SP  = 1<<1, // sp,  implicit base on PACIASP/AUTIASP + stack forms
			ClobberReg_X16 = 1<<2, // implicit modifier register for PAC*1716 / AUT*1716
			ClobberReg_X17 = 1<<3, // implicit pointer register for PAC*1716 / AUT*1716
		};

		static u8 const CLOBBER_REGS_NAMED =
			ClobberReg_LR|ClobberReg_SP|ClobberReg_X16|ClobberReg_X17;

		enum SideEffectFlags : u16 {
			SideEffectFlag_CONTROL          = 1<<0,  // writes pc: B/BL/BR/BLR/RET, B.cond, CBZ/CBNZ, TBZ/TBNZ
			SideEffectFlag_EXCEPTION        = 1<<1,  // exception-generating call: SVC / HVC / SMC
			SideEffectFlag_TRAP             = 1<<2,  // deliberately faults: BRK, UDF
			SideEffectFlag_FENCE            = 1<<3,  // memory-ordering barrier: DMB/DSB, acquire/release
			SideEffectFlag_ISYNC            = 1<<4,  // instruction-stream / context sync: ISB
			SideEffectFlag_ATOMIC           = 1<<5,  // indivisible RMW: LDXR/STXR pair, LSE
			SideEffectFlag_RESERVATION      = 1<<6,  // sets/tests/clears the local monitor: LDXR/STXR, CLREX
			SideEffectFlag_CACHE            = 1<<7,  // cache maintenance with coherence effects: DC, IC
			SideEffectFlag_HINT             = 1<<8,  // architecturally-inert hint: NOP/YIELD/PRFM/SEV/ESB/CSDB
			SideEffectFlag_BTI              = 1<<9,  // branch-target-identification landing pad (CFI)
			SideEffectFlag_PAC              = 1<<10, // pointer authentication: reads an implicit key, may fault
			SideEffectFlag_WAIT             = 1<<11, // suspends execution until event/interrupt: WFI/WFE
			SideEffectFlag_PRIVILEGED       = 1<<12, // reads/writes system state: MSR/MRS, ERET, TLBI, AT, DAIF
			SideEffectFlag_FFR              = 1<<13, // reads/writes the SVE first-fault register
			SideEffectFlag_NONDETERMINISTIC = 1<<14, // RNDR/RNDRRS, counter/timer reads (CNTVCT), TSTART
		};

		enum OperandSet : u8 {
			OperandSet_OP0 = 1<<0,
			OperandSet_OP1 = 1<<1,
			OperandSet_OP2 = 1<<2,
			OperandSet_OP3 = 1<<3,
		};

		u16 clobber_bit_for_reg_name(String const &pin) {
			static const struct { String name; u16 bit; } table[] = {
				{str_lit(\"lr\"),  ClobberReg_LR},
				{str_lit(\"x30\"), ClobberReg_LR},
				{str_lit(\"w30\"), ClobberReg_LR},
				{str_lit(\"sp\"),  ClobberReg_SP},
				{str_lit(\"wsp\"), ClobberReg_SP},
				{str_lit(\"x16\"), ClobberReg_X16},
				{str_lit(\"w16\"), ClobberReg_X16},
				{str_lit(\"x17\"), ClobberReg_X17},
				{str_lit(\"w17\"), ClobberReg_X17},
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
			case ClobberReg_LR:  return \"lr\";
			case ClobberReg_SP:  return \"sp\";
			case ClobberReg_X16: return \"x16\";
			case ClobberReg_X17: return \"x17\";
			}
			return \"<reg>\";
		}


		u16 flag_from_name(String const &name) {
			// NZCV condition flags.
			static const struct { String name; ClobberFlags flag; } table[] = {
				{str_lit(\"n\"), ClobberFlag_N},
				{str_lit(\"z\"), ClobberFlag_Z},
				{str_lit(\"c\"), ClobberFlag_C},
				{str_lit(\"v\"), ClobberFlag_V},
			};
			for (auto const &t : table) {
				if (name == t.name) {
					return cast(u16)t.flag;
				}
			}
			return 0;
		}

		u16 fpsr_flag_from_name(String const &name) {
			static const struct { String name; FPSRFlags flag; } table[] = {
				{str_lit(\"ioc\"), FPSRFlag_IOC}, // Invalid Operation
				{str_lit(\"dzc\"), FPSRFlag_DZC}, // Divide by Zero
				{str_lit(\"ofc\"), FPSRFlag_OFC}, // Overflow
				{str_lit(\"ufc\"), FPSRFlag_UFC}, // Underflow
				{str_lit(\"ixc\"), FPSRFlag_IXC}, // Inexact
				{str_lit(\"idc\"), FPSRFlag_IDC}, // Input Denormal
				{str_lit(\"qc\"),  FPSRFlag_QC},  // Cumulative Saturation
			};
			for (auto const &t : table) {
				if (name == t.name) {
					return cast(u16)t.flag;
				}
			}
			return 0;
		}


		i32 flag_bit_from_name(String const &name, i32 *width_) {
			// Real PSTATE.NZCV bit positions (as read/written via MRS/MSR NZCV, bits 31:28).
			static const struct { String name; i32 bit; } table[] = {
				{str_lit(\"v\"), 28}, // Overflow
				{str_lit(\"c\"), 29}, // Carry
				{str_lit(\"z\"), 30}, // Zero
				{str_lit(\"n\"), 31}, // Negative
			};
			for (auto const &t : table) {
				if (name == t.name) {
					if (width_) {
						*width_ = 1;
					}
					return t.bit;
				}
			}
			return -1;
		}


		struct Clobber {
			OperandSet      written;     // operand slots whose register/SIMD reg is written
			OperandSet      read;        // operand slots whose register / mem-base is read
			ClobberRegs     implicit_wr; // implicit reg writes (LR on BL/BLR)
			ClobberRegs     implicit_rd; // implicit reg reads (LR on RET, SP on PAC*SP)
			ClobberFlags    nzcv_wr;     // condition flags written (ADDS/SUBS/ANDS, CMP, FCMP, CCMP...)
			ClobberFlags    nzcv_undef;  // condition flags left UNKNOWN (rare on A64, usually empty)
			ClobberFlags    nzcv_rd;     // condition flags read (B.cond, CSEL, ADC/SBC, CCMP...)
			FPSRFlags       fpsr_wr;     // FP cumulative exception/saturation flags this op may raise
			bool            reads_fpcr;  // consumes the rounding mode / FP control from FPCR
			bool            writes_mem;
			bool            reads_mem;
			SideEffectFlags side_effects;

			ClobberFlags flags_rd_call() const {
				return nzcv_rd;
			}
			ClobberFlags flags_wr_call() const {
				return nzcv_wr;
			}

			bool implies_clobber_flags() const {
				return ((cast(u16)nzcv_wr | cast(u16)nzcv_undef) != 0) ||
					(cast(u16)fpsr_wr != 0);
			}
			bool implies_clobber_memory() const {
				return writes_mem || reads_mem ||
					(cast(u16)side_effects & (SideEffectFlag_FENCE|SideEffectFlag_ATOMIC|SideEffectFlag_CACHE)) != 0;
			}
			bool implies_side_effects() const {
				u16 const VOLATILE_SE =
					SideEffectFlag_CONTROL     |
					SideEffectFlag_EXCEPTION   |
					SideEffectFlag_TRAP        |
					SideEffectFlag_FENCE       |
					SideEffectFlag_ISYNC       |
					SideEffectFlag_ATOMIC      |
					SideEffectFlag_RESERVATION |
					SideEffectFlag_CACHE       |
					SideEffectFlag_BTI         |
					SideEffectFlag_PAC         |
					SideEffectFlag_WAIT        |
					SideEffectFlag_PRIVILEGED  |
					SideEffectFlag_FFR         |
					SideEffectFlag_NONDETERMINISTIC;
					// NOTE: SideEffectFlag_HINT deliberately excluded — inert, may be DCE'd.
				return (cast(u16)side_effects & VOLATILE_SE) != 0;
			}
			u8 is_call_or_mem() const {
				return (cast(u16)side_effects & SideEffectFlag_CONTROL) != 0 ||
					(cast(u16)implicit_wr & (ClobberReg_LR|ClobberReg_SP)) != 0;
			}
			bool has_control() const {
				return (cast(u16)side_effects & SideEffectFlag_CONTROL) != 0;
			}
			bool has_halt() const {
				// WFI/WFE suspend execution (x86 HLT analog); SVC/HVC/SMC gate out.
				return (cast(u16)side_effects & (SideEffectFlag_WAIT|SideEffectFlag_EXCEPTION)) != 0;
			}
			bool is_conditional(struct Encoding const &valid_form) const {
				if (valid_form.is_conditional()) {
					return true;
				}
				return has_control() && (cast(u16)nzcv_rd != 0);
			}
			bool is_nondeterministic() const {
				return (cast(u16)side_effects & SideEffectFlag_NONDETERMINISTIC) != 0;
			}
			bool has_implicit_mem() const {
				if (!writes_mem && !reads_mem) {
					return false;
				}
				u16 implicit = cast(u16)implicit_rd | cast(u16)implicit_wr;
				bool is_atomic = (cast(u16)side_effects & SideEffectFlag_ATOMIC) != 0;
				return (implicit & ClobberReg_SP) != 0 || is_atomic;
			}

			bool is_status_snapshot() const {
				u16 flags = cast(u16)this->flags_rd_call();
				return gb_count_set_bits(flags & CLOBBER_FLAGS_COND) >= 4;
			}
		};

		void clobber_implicit_regs(StringSet *clobber_registers_set, u16 implicit_regs) {
			u8 regs = cast(u8)implicit_regs & CLOBBER_REGS_NAMED;

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
		// arm64 has no pseudo-alias expansion table. These are dummy definitions
		// (as in the x86 generator) so the shared C++ front-end still links.
		strings.write_string(&sb, """
			enum AliasSrc : u8 {
				AliasSrc_NONE,    // slot unused
				AliasSrc_ARG0,    // user's 1st operand
				AliasSrc_ARG1,    // user's 2nd operand
				AliasSrc_ARG2,    // user's 3rd operand
				AliasSrc_ZERO,    // hardwired zero
				AliasSrc_LINK,    // link register
				AliasSrc_LIT,     // immediate literal
			};

			// NOTE(arm64): dummy — only riscv needs pseudo aliases; arm64 has none.
			struct PseudoAlias {
				Mnemonic target;   // real instruction emitted
				AliasSrc src[4];   // how to fill target's four operand slots
				i16      lit;      // immediate when a src slot is AliasSrc_LIT
				u16      csr;      // unused on arm64
				u8       nargs;    // operands the user supplies (ARG0..<ARGn)

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

			static String const pseudo_mnemonic_strings[PSEUDO_MNEMONIC_COUNT];
			\n\n
		""")
	}


	strings.write_string(&sb, "\tstatic u32    const register_codes  [REG_COUNT];\n")
	strings.write_string(&sb, "\tstatic String const register_strings[REG_COUNT];\n")

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
	strings.write_string(&sb, "\tStringMap<Register> register_map;\n")

	strings.write_string(&sb, """

		bool init(i64 word_size) {
			gb_unused(word_size); // A64 is fixed 64-bit; W views are the 32-bit half.

			string_map_init(&mnemonic_map, MNEMONIC_COUNT*2);
			for (u16 m = M_INVALID+1; m < MNEMONIC_COUNT; m++) {
				string_map_set(&mnemonic_map, mnemonic_strings[m], cast(Mnemonic)m);
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
			// A64 acquire/release/atomic variants are distinct mnemonics (LDAR, STLR,
			// LDADDA...), not textual suffixes on a base mnemonic.
			gb_unused(m);
			return false;
		}

		Mnemonic mnemonic_lookup_ordered(String const &name, u8 *suffixes_) {
			gb_unused(name);
			gb_unused(suffixes_);
			return M_INVALID;
		}

		enum PseudoMacroMnemonic : u8 {
			PseudoMacroMnemonic_INVALID,
			PseudoMacroMnemonic_COUNT
			// NOTE: MOV-wide-immediate expansion (MOV -> MOVZ/MOVN/MOVK sequence) could
			// be modelled here if the front-end wants macro lowering for arm64.
		};

		PseudoMacroMnemonic pseudo_macro_mnemonic_lookup(String const &name) {
			gb_unused(name);
			return PseudoMacroMnemonic_INVALID;
		}

		Mnemonic mnemonic_lookup(String const &name) {
			Mnemonic *found = string_map_get(&mnemonic_map, name);
			return found ? *found : M_INVALID;
		}
		Prefix prefix_lookup(String const &name) {
			gb_unused(name);
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
		u16 reg_class(u32 r) const {
			return 0xFF00 & r;
		}
		// size in bits for register
		u16 reg_size(Register r) const {
			switch (reg_class(register_codes[r])) {
			case REG_CLASS_X:   return 64;
			case REG_CLASS_W:   return 32;
			case REG_CLASS_XSP: return 64;
			case REG_CLASS_WSP: return 32;
			case REG_CLASS_V:   return 128;
			case REG_CLASS_B:   return 8;
			case REG_CLASS_H:   return 16;
			case REG_CLASS_S:   return 32;
			case REG_CLASS_D:   return 64;
			case REG_CLASS_Q:   return 128;
			case REG_CLASS_Z:   return 0;   // SVE scalable (VL, implementation-defined)
			case REG_CLASS_P:   return 0;   // SVE predicate (scalable)
			case REG_CLASS_PN:  return 0;   // SME2 predicate-as-counter (scalable)
			case REG_CLASS_ZT:  return 512; // ZT0 is a fixed 512-bit table
			case REG_CLASS_ZA:  return 0;   // SME ZA tile (scalable)
			case REG_CLASS_SYS: return 64;  // 'word size'
			}
			return 0;
		}

		bool reg_is_segment(u32 r) {
			gb_unused(r);
			return false; // arm64 has no segment registers
		}

		bool integer_reg_width_is_exact() const {
			return true; // X = 64, W = 32 always
		}
		bool float_reg_width_is_exact() const {
			return true; // B/H/S/D/Q scalar views are exact widths
		}
		bool supports_memory_index_not_just_disp() const {
			return true; // base + (optionally extended/shifted) index register
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmOperandKind kind_from_operand_type(OperandType type) const {
			switch (type) {
			case OP_NONE:
				return AsmOperand_Invalid;

			// ---- Registers ----
			// Integer GPR / GPR-or-SP, including shifted- and extended-register forms.
			case OP_W_REG:      case OP_X_REG:
			case OP_WSP_REG:    case OP_XSP_REG:
			case OP_W_SHIFTED:  case OP_X_SHIFTED:
			case OP_W_EXTENDED: case OP_X_EXTENDED:
			// SIMD&FP scalar views.
			case OP_B_REG: case OP_H_REG: case OP_S_REG: case OP_D_REG: case OP_Q_REG:
			// NEON vector: plain, arrangement, FP16, element-indexed.
			case OP_V_REG:
			case OP_V_8B: case OP_V_16B: case OP_V_4H: case OP_V_8H:
			case OP_V_2S: case OP_V_4S: case OP_V_1D: case OP_V_2D:
			case OP_V_4H_FP16: case OP_V_8H_FP16:
			case OP_V_ELEM_B: case OP_V_ELEM_H: case OP_V_ELEM_S: case OP_V_ELEM_D:
			// SVE vector + predicate registers.
			case OP_Z_REG_B: case OP_Z_REG_H: case OP_Z_REG_S: case OP_Z_REG_D:
			case OP_P_REG: case OP_P_REG_MERGE: case OP_P_REG_ZERO: case OP_P_REG_GOV:
			// SME ZA tiles (ZA0.B .. ZAn.Q) — register-like tile operands.
			case OP_ZA_TILE_B: case OP_ZA_TILE_H: case OP_ZA_TILE_S:
			case OP_ZA_TILE_D: case OP_ZA_TILE_Q:
			case OP_SYS_REG:     // MRS/MSR system-register name -> 16-bit field (cf. riscv CSR)
				return AsmOperand_Register;

			// ---- Immediates (numeric literals and immediate-encoded selectors) ----
			case OP_IMM_2:  case OP_IMM_3:  case OP_IMM_4:  case OP_IMM_5:
			case OP_IMM_6:  case OP_IMM_8:  case OP_IMM_12: case OP_IMM_16:
			case OP_NZCV_IMM:
			case OP_HW_SHIFT:
			case OP_BITMASK_IMM:
			case OP_LSE_SIZE:
			case OP_LSL_SHIFT_W: case OP_LSL_SHIFT_X: case OP_ROR_SHIFT:
			case OP_FCMLA_ROT:   case OP_FCADD_ROT:
			case OP_SVE_PRFOP:
			case OP_VEC_SHIFT:   case OP_VEC_INDEX:
			// Enum-like tokens that encode into an immediate field:
			case OP_COND:        // condition code (EQ/NE/...) -> 4-bit field
			case OP_COND_NOT_AL: // same, minus AL/NV (cset/cinc/cinv/cneg/csetm)
			case OP_SME_PATTERN: case OP_SVE_PATTERN: // pattern / tile-list selectors
			// JUDGMENT CALL: the following are register/tile-slice constructs
			// syntactically, but this table models each as a single packed immediate
			// descriptor (see Operand_Type comments). If the front-end parses their
			// bracketed tile-slice / [Xn,#imm] syntax, reclassify as Register/Memory.
			case OP_SME_SLICE_B: case OP_SME_SLICE_H: case OP_SME_SLICE_W:
			case OP_SME_SLICE_D: case OP_SME_SLICE_Q:
			case OP_LDRAA_IMM10: // signed imm10 displacement of the PAC-load address form
				return AsmOperand_Immediate;

			// ---- Branch / PC-relative targets (written as labels) ----
			case OP_REL_26: case OP_REL_19: case OP_REL_14: case OP_REL_PG21:
				return AsmOperand_Label;

			// ---- Memory addressing modes ----
			case OP_MEM_OFFSET:  case OP_MEM_PRE:  case OP_MEM_POST:
			case OP_MEM_REG:     case OP_MEM_EXT:
			case OP_MEM_SVE_SS:  case OP_MEM_SVE_SI:
			case OP_MEM_SVE_VEC: case OP_MEM_SVE_VB:
				return AsmOperand_Memory;
			}
			return AsmOperand_Invalid;
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmRegClass reg_class_from_operand_type(OperandType type) const {
			switch (type) {
			// Integer GPRs (incl. GPR-or-SP and shifted/extended register forms).
			case OP_W_REG:      case OP_X_REG:
			case OP_WSP_REG:    case OP_XSP_REG:
			case OP_W_SHIFTED:  case OP_X_SHIFTED:
			case OP_W_EXTENDED: case OP_X_EXTENDED:
				return AsmRegClass_Integer;

			// SIMD&FP scalar views share the V register file; treated as the float class.
			case OP_B_REG: case OP_H_REG: case OP_S_REG: case OP_D_REG: case OP_Q_REG:
				return AsmRegClass_Float;

			// NEON vectors (plain / arrangement / FP16 / element-indexed), SVE Z
			// vectors, and SME2 Z register-lists — all the vector register file.
			case OP_V_REG:
			case OP_V_8B: case OP_V_16B: case OP_V_4H: case OP_V_8H:
			case OP_V_2S: case OP_V_4S: case OP_V_1D: case OP_V_2D:
			case OP_V_4H_FP16: case OP_V_8H_FP16:
			case OP_V_ELEM_B: case OP_V_ELEM_H: case OP_V_ELEM_S: case OP_V_ELEM_D:
			case OP_Z_REG_B: case OP_Z_REG_H: case OP_Z_REG_S: case OP_Z_REG_D:
				return AsmRegClass_Vector;

			// SVE predicate registers.
			case OP_P_REG: case OP_P_REG_MERGE: case OP_P_REG_ZERO: case OP_P_REG_GOV:
				return AsmRegClass_Mask;

			// Everything else has no GPR/vector/mask class:
			//  - immediates, selectors, memory, labels, cond, sysreg, patterns.
			//  - ZA_TILE_* are SME ZA-tile registers, but AsmRegClass has no
			//    matrix/tile class, so they fall through to Unknown here (still
			//    Register-kind, the same shape as x86 SREG/CR/DR).
			default:
				return AsmRegClass_Unknown;
			}
		}
	""")
	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		bool operand_type_is_implicit(OperandType t) const {
			// A64 operands are written explicitly; fixed regs (LR on RET, SP/X16/X17
			// on PAC*) are tracked via the Clobber implicit_rd/implicit_wr sets, not
			// as implicit operand-type slots.
			gb_unused(t);
			return false;
		}
	""")

	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		AsmRegClass operand_type_reg_class(OperandType t) const {
			// Same mapping as reg_class_from_operand_type.
			return reg_class_from_operand_type(t);
		}
	""")


	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		// A64 has no operand slot that only one named hardware register can fill
		// (SP-taking slots accept any Xn or SP via the *_SP classes).
		u16 operand_type_named_reg_class(OperandType t) const {
			if (t == OP_SYS_REG) {
				return REG_CLASS_SYS;
			}
			return REG_CLASS_NONE;
		}

		String named_reg_class_string(u16 reg_class) const {
			if (reg_class == REG_CLASS_SYS) {
				return str_lit("system");
			}
			return str_lit("hardware");
		}
	""")


	strings.write_string(&sb, "\n\n")

	strings.write_string(&sb, """
		u16 operand_type_bit_width(OperandType t) const {
			switch (t) {
			case OP_NONE:
				return 0;

			// ---- Integer registers (incl. shifted/extended forms) -> data width ----
			case OP_W_REG: case OP_WSP_REG: case OP_W_SHIFTED: case OP_W_EXTENDED:
				return 32;
			case OP_X_REG: case OP_XSP_REG: case OP_X_SHIFTED: case OP_X_EXTENDED:
				return 64;

			// ---- SIMD&FP scalar views ----
			case OP_B_REG: return 8;
			case OP_H_REG: return 16;
			case OP_S_REG: return 32;
			case OP_D_REG: return 64;
			case OP_Q_REG: return 128;

			// ---- NEON vectors: total register width of the arrangement ----
			case OP_V_REG:
				return 128; // full V (Q view)
			case OP_V_8B: case OP_V_4H: case OP_V_2S: case OP_V_1D:
			case OP_V_4H_FP16:
				return 64;  // 64-bit (D-register) arrangements
			case OP_V_16B: case OP_V_8H: case OP_V_4S: case OP_V_2D:
			case OP_V_8H_FP16:
				return 128; // 128-bit (Q-register) arrangements

			// ---- Element-indexed vector: width of the indexed element ----
			case OP_V_ELEM_B: return 8;
			case OP_V_ELEM_H: return 16;
			case OP_V_ELEM_S: return 32;
			case OP_V_ELEM_D: return 64;

			// ---- Immediates -> value / encoded-field width ----
			case OP_IMM_2:  return 2;
			case OP_IMM_3:  return 3;
			case OP_IMM_4:  return 4;
			case OP_IMM_5:  return 5;
			case OP_IMM_6:  return 6;
			case OP_IMM_8:  return 8;
			case OP_IMM_12: return 12;
			case OP_IMM_16: return 16;
			case OP_NZCV_IMM:    return 4;
			case OP_HW_SHIFT:    return 2;  // 2-bit LSL hw (0/16/32/48)
			case OP_LSE_SIZE:    return 2;
			case OP_SYS_REG:     return 15; // op0:op1:CRn:CRm:op2 packed
			case OP_LSL_SHIFT_W: return 5;  // 0..31
			case OP_LSL_SHIFT_X: return 6;  // 0..63
			case OP_ROR_SHIFT:   return 6;  // imms field
			case OP_FCMLA_ROT:   return 2;
			case OP_FCADD_ROT:   return 1;
			case OP_SVE_PRFOP:   return 4;
			case OP_LDRAA_IMM10: return 10;
			case OP_COND:        return 4;
			case OP_COND_NOT_AL: return 4;
			case OP_SVE_PATTERN: return 5;  // 5-bit pattern field (PTRUE)

			// ---- PC-relative displacement value widths ----
			case OP_REL_26:   return 26;
			case OP_REL_19:   return 19;
			case OP_REL_14:   return 14;
			case OP_REL_PG21: return 21; // ADR/ADRP imm21 (ADRP scaled << 12)

			// ---- Width is scalable, data-dependent, or set elsewhere -> 0 ----
			case OP_Z_REG_B: case OP_Z_REG_H: case OP_Z_REG_S: case OP_Z_REG_D: // SVE VL-scaled
			case OP_P_REG: case OP_P_REG_MERGE: case OP_P_REG_ZERO: case OP_P_REG_GOV: // predicate (VL/8)
			case OP_ZA_TILE_B: case OP_ZA_TILE_H: case OP_ZA_TILE_S:
			case OP_ZA_TILE_D: case OP_ZA_TILE_Q:                                 // SME tiles (scalable)
			case OP_SME_PATTERN:                                                  // selector, no data width
			case OP_SME_SLICE_B: case OP_SME_SLICE_H: case OP_SME_SLICE_W:
			case OP_SME_SLICE_D: case OP_SME_SLICE_Q:                             // packed slice descriptor
			case OP_BITMASK_IMM:                                                  // value width = operand width (32/64)
			case OP_VEC_SHIFT:                                                    // element-size dependent
			case OP_VEC_INDEX:                                                    // element-size dependent
			case OP_MEM_OFFSET:  case OP_MEM_PRE:  case OP_MEM_POST:
			case OP_MEM_REG:     case OP_MEM_EXT:
			case OP_MEM_SVE_SS:  case OP_MEM_SVE_SI:
			case OP_MEM_SVE_VEC: case OP_MEM_SVE_VB:                              // access size from opcode
				return 0;
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
			// arm64 does not have instruction prefixes.
			gb_unused(prefix);
			gb_unused(form);
			gb_unused(requires_memory_dest_);
			return false;
		}
	""")

	strings.write_string(&sb, "\n")

	strings.write_string(&sb, """
		AsmOperandConstraint operand_value_constraint(u16 m, int op) const {
			switch (m) {
			case M_LSL: case M_LSR: case M_ASR: case M_ROR:
				if (op == 2) return {AsmOperandConstraint_ShiftCount, /*reg width*/-1};
				break;
			// NOTE: A64 SDIV/UDIV by zero returns 0 (no fault), so no
			// NonZeroDivisor constraint is emitted for division.
			}
			return {AsmOperandConstraint_None, -1};
		}
	""")

	strings.write_string(&sb, """
		bool is_self_zeroing_idiom(u16 m) const {
			switch (m) {
			case M_EOR: // x ^ x == 0
			case M_SUB: // x - x == 0
			case M_BIC: // x & ~x == 0
				return true;
			}
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
		fmt.sbprintf(&sb, "u32 const Asm_{0:s}::register_codes[Asm_{0:s}::REG_COUNT] {{\n", ISA_NAME)
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

	// arm64 has no pseudo mnemonics.
	fmt.sbprintf(&sb, "String const Asm_{0:s}::pseudo_mnemonic_strings[Asm_{0:s}::PSEUDO_MNEMONIC_COUNT] {{}};\n", ISA_NAME)

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
	X0,
	X1,
	X2,
	X3,
	X4,
	X5,
	X6,
	X7,
	X8,
	X9,
	X10,
	X11,
	X12,
	X13,
	X14,
	X15,
	X16,
	X17,
	X18,
	X19,
	X20,
	X21,
	X22,
	X23,
	X24,
	X25,
	X26,
	X27,
	X28,
	X29,
	X30,
	XZR,
	SP,
	W0,
	W1,
	W2,
	W3,
	W4,
	W5,
	W6,
	W7,
	W8,
	W9,
	W10,
	W11,
	W12,
	W13,
	W14,
	W15,
	W16,
	W17,
	W18,
	W19,
	W20,
	W21,
	W22,
	W23,
	W24,
	W25,
	W26,
	W27,
	W28,
	W29,
	W30,
	WZR,
	WSP,
	V0,
	V1,
	V2,
	V3,
	V4,
	V5,
	V6,
	V7,
	V8,
	V9,
	V10,
	V11,
	V12,
	V13,
	V14,
	V15,
	V16,
	V17,
	V18,
	V19,
	V20,
	V21,
	V22,
	V23,
	V24,
	V25,
	V26,
	V27,
	V28,
	V29,
	V30,
	V31,

	PN8,
	PN9,
	PN10,
	PN11,
	PN12,
	PN13,
	PN14,
	PN15,

	ZT0,

	// System Registers
	AFSR0_EL1,
	AFSR1_EL1,
	CURRENT_EL,
	DAIF,
	ELR_EL1,
	ELR_EL2,
	ELR_EL3,
	ESR_EL1,
	ESR_EL2,
	FAR_EL1,
	FAR_EL2,
	ISR_EL1,
	NZCV,
	SPSR_EL1,
	SPSR_EL2,
	SPSR_EL3,
	SP_EL0,
	SP_EL1,
	VBAR_EL1,
	VBAR_EL2,
	VBAR_EL3,
	FPCR,
	FPSR,
	MVFR0_EL1,
	MVFR1_EL1,
	MVFR2_EL1,
	CONTEXTIDR_EL1,
	TPIDR2_EL0,
	TPIDRRO_EL0,
	TPIDR_EL0,
	TPIDR_EL1,
	TPIDR_EL2,
	TPIDR_EL3,
	CCSIDR_EL1,
	CLIDR_EL1,
	CSSELR_EL1,
	CTR_EL0,
	DCZID_EL0,
	GMID_EL1,
	ID_AA64AFR0_EL1,
	ID_AA64AFR1_EL1,
	ID_AA64DFR0_EL1,
	ID_AA64DFR1_EL1,
	ID_AA64DFR2_EL1,
	ID_AA64ISAR0_EL1,
	ID_AA64ISAR1_EL1,
	ID_AA64ISAR2_EL1,
	ID_AA64ISAR3_EL1,
	ID_AA64MMFR0_EL1,
	ID_AA64MMFR1_EL1,
	ID_AA64MMFR2_EL1,
	ID_AA64PFR0_EL1,
	ID_AA64PFR1_EL1,
	ID_AA64SMFR0_EL1,
	ID_AA64ZFR0_EL1,
	ID_AFR0_EL1,
	ID_DFR0_EL1,
	ID_ISAR0_EL1,
	ID_ISAR1_EL1,
	ID_ISAR2_EL1,
	ID_ISAR3_EL1,
	ID_ISAR4_EL1,
	ID_ISAR5_EL1,
	ID_ISAR6_EL1,
	ID_MMFR0_EL1,
	ID_MMFR1_EL1,
	ID_MMFR2_EL1,
	ID_MMFR3_EL1,
	ID_MMFR4_EL1,
	ID_MMFR5_EL1,
	ID_PFR0_EL1,
	ID_PFR1_EL1,
	ID_PFR2_EL1,
	MIDR_EL1,
	MPIDR_EL1,
	APDAKEYHI_EL1,
	APDAKEYLO_EL1,
	APDBKEYHI_EL1,
	APDBKEYLO_EL1,
	APGAKEYHI_EL1,
	APGAKEYLO_EL1,
	APIAKEYHI_EL1,
	APIAKEYLO_EL1,
	APIBKEYHI_EL1,
	APIBKEYLO_EL1,
	GCR_EL1,
	RGSR_EL1,
	TFSRE0_EL1,
	TFSR_EL1,
	SMCR_EL1,
	SMCR_EL2,
	SVCR,
	ZCR_EL1,
	ZCR_EL2,
	ZCR_EL3,
	ACTLR_EL1,
	AMAIR_EL1,
	CPACR_EL1,
	LORC_EL1,
	LOREA_EL1,
	LORID_EL1,
	LORN_EL1,
	LORSA_EL1,
	MAIR_EL1,
	PAR_EL1,
	SCTLR_EL1,
	SCTLR_EL2,
	SCTLR_EL3,
	TCR_EL1,
	TTBR0_EL1,
	TTBR1_EL1,
	CNTFRQ_EL0,
	CNTHCTL_EL2,
	CNTHP_CTL_EL2,
	CNTHP_CVAL_EL2,
	CNTHP_TVAL_EL2,
	CNTHV_CTL_EL2,
	CNTHV_CVAL_EL2,
	CNTHV_TVAL_EL2,
	CNTKCTL_EL1,
	CNTPCT_EL0,
	CNTPS_CTL_EL1,
	CNTPS_CVAL_EL1,
	CNTPS_TVAL_EL1,
	CNTP_CTL_EL0,
	CNTP_CVAL_EL0,
	CNTP_TVAL_EL0,
	CNTVCT_EL0,
	CNTVOFF_EL2,
	CNTV_CTL_EL0,
	CNTV_CVAL_EL0,
	CNTV_TVAL_EL0,
	PMBIDR_EL1,
	PMBLIMITR_EL1,
	PMBPTR_EL1,
	PMBSR_EL1,
	PMSCR_EL1,
	PMSELR_EL0,
	PMSEVFR_EL1,
	PMSFCR_EL1,
	PMSICR_EL1,
	PMSIDR_EL1,
	PMSIRR_EL1,
	PMSLATFR_EL1,
	PMSWINC_EL0,
	PMCCFILTR_EL0,
	PMCCNTR_EL0,
	PMCEID0_EL0,
	PMCEID1_EL0,
	PMCNTENCLR_EL0,
	PMCNTENSET_EL0,
	PMCR_EL0,
	PMINTENCLR_EL1,
	PMINTENSET_EL1,
	PMOVSCLR_EL0,
	PMUSERENR_EL0,
	TRBBASER_EL1,
	TRBIDR_EL1,
	TRBLIMITR_EL1,
	TRBMAR_EL1,
	TRBPTR_EL1,
	TRBSR_EL1,
	TRBTRG_EL1,
	DBGAUTHSTATUS_EL1,
	DBGCLAIMCLR_EL1,
	DBGCLAIMSET_EL1,
	DBGDTRRX_EL0,
	DBGDTRTX_EL0,
	DBGDTR_EL0,
	DBGPRCR_EL1,
	DLR_EL0,
	DSPSR_EL0,
	MDCCINT_EL1,
	MDRAR_EL1,
	MDSCR_EL1,
	OSLAR_EL1,
	OSLSR_EL1,
	PRSELR_EL1,
	ICC_ASGI1R_EL1,
	ICC_BPR0_EL1,
	ICC_BPR1_EL1,
	ICC_CTLR_EL1,
	ICC_CTLR_EL3,
	ICC_DIR_EL1,
	ICC_EOIR0_EL1,
	ICC_EOIR1_EL1,
	ICC_HPPIR0_EL1,
	ICC_HPPIR1_EL1,
	ICC_IAR0_EL1,
	ICC_IAR1_EL1,
	ICC_IGRPEN0_EL1,
	ICC_IGRPEN1_EL1,
	ICC_IGRPEN1_EL3,
	ICC_PMR_EL1,
	ICC_RPR_EL1,
	ICC_SGI0R_EL1,
	ICC_SGI1R_EL1,
	ICC_SRE_EL1,
	ICC_SRE_EL2,
	ICC_SRE_EL3,
	ICH_EISR_EL2,
	ICH_ELRSR_EL2,
	ICH_HCR_EL2,
	ICH_MISR_EL2,
	ICH_VMCR_EL2,
	ICH_VTR_EL2,
	DISR_EL1,
	ERRIDR_EL1,
	ERRSELR_EL1,
	ERXADDR_EL1,
	ERXCTLR_EL1,
	ERXFR_EL1,
	ERXMISC0_EL1,
	ERXMISC1_EL1,
	ERXMISC2_EL1,
	ERXMISC3_EL1,
	ERXSTATUS_EL1,
	VDISR_EL2,
	VSESR_EL2,
	GPCCR_EL3,
	GPTBR_EL3,
	HCR_EL2,
	HSTR_EL2,
	MDCR_EL2,
	MFAR_EL3,
	VTCR_EL2,
	VTTBR_EL2,
	DACR32_EL2,
	FPEXC32_EL2,
	RNDR,
	RNDRRS,
}

REG_NONE :: 0x0000
REG_X    :: 0x0100   // X0..X30, XZR (X31 = ZR semantically)
REG_W    :: 0x0200   // W0..W30, WZR
REG_XSP  :: 0x0300   // SP (only -- distinct class from X to opt-in)
REG_WSP  :: 0x0400   // WSP
REG_V    :: 0x0500   // V0..V31 (full 128-bit; used in NEON vector form)
REG_B    :: 0x0600   // B0..B31 (byte view)
REG_H    :: 0x0700   // H0..H31 (half view)
REG_S    :: 0x0800   // S0..S31 (single view)
REG_D    :: 0x0900   // D0..D31 (double view)
REG_Q    :: 0x0A00   // Q0..Q31 (quad view)
REG_Z    :: 0x0B00   // Z0..Z31 SVE scalable vector (low 128 aliased with V)
REG_P    :: 0x0C00   // P0..P15 SVE predicate
REG_PN   :: 0x0D00   // PN8..PN15 SME2 predicate-as-counter
REG_ZT   :: 0x0E00   // ZT0, the SME2 lookup table
REG_ZA   :: 0x0F00   // ZA0..ZA15, SME's accumulator tiles
REG_SYS  :: 0x1000   // system registers (MRS/MSR); the field is in bits 16-30


@(rodata)
REG_CODES := [Register]arm64.Register{
	.INVALID = 0,

	.X0  = arm64.Register(REG_X | 0),  .X1  = arm64.Register(REG_X | 1),  .X2  = arm64.Register(REG_X | 2),  .X3  = arm64.Register(REG_X | 3),
	.X4  = arm64.Register(REG_X | 4),  .X5  = arm64.Register(REG_X | 5),  .X6  = arm64.Register(REG_X | 6),  .X7  = arm64.Register(REG_X | 7),
	.X8  = arm64.Register(REG_X | 8),  .X9  = arm64.Register(REG_X | 9),  .X10 = arm64.Register(REG_X | 10), .X11 = arm64.Register(REG_X | 11),
	.X12 = arm64.Register(REG_X | 12), .X13 = arm64.Register(REG_X | 13), .X14 = arm64.Register(REG_X | 14), .X15 = arm64.Register(REG_X | 15),
	.X16 = arm64.Register(REG_X | 16), .X17 = arm64.Register(REG_X | 17), .X18 = arm64.Register(REG_X | 18), .X19 = arm64.Register(REG_X | 19),
	.X20 = arm64.Register(REG_X | 20), .X21 = arm64.Register(REG_X | 21), .X22 = arm64.Register(REG_X | 22), .X23 = arm64.Register(REG_X | 23),
	.X24 = arm64.Register(REG_X | 24), .X25 = arm64.Register(REG_X | 25), .X26 = arm64.Register(REG_X | 26), .X27 = arm64.Register(REG_X | 27),
	.X28 = arm64.Register(REG_X | 28), .X29 = arm64.Register(REG_X | 29), .X30 = arm64.Register(REG_X | 30),
	.XZR = arm64.Register(REG_X | 31),

	.SP  = arm64.Register(REG_XSP | 31),

	// -----------------------------------------------------------------------------
	// 32-bit GPRs (W0..W30, WZR, WSP)
	// -----------------------------------------------------------------------------

	.W0  = arm64.Register(REG_W | 0),  .W1  = arm64.Register(REG_W | 1),  .W2  = arm64.Register(REG_W | 2),  .W3  = arm64.Register(REG_W | 3),
	.W4  = arm64.Register(REG_W | 4),  .W5  = arm64.Register(REG_W | 5),  .W6  = arm64.Register(REG_W | 6),  .W7  = arm64.Register(REG_W | 7),
	.W8  = arm64.Register(REG_W | 8),  .W9  = arm64.Register(REG_W | 9),  .W10 = arm64.Register(REG_W | 10), .W11 = arm64.Register(REG_W | 11),
	.W12 = arm64.Register(REG_W | 12), .W13 = arm64.Register(REG_W | 13), .W14 = arm64.Register(REG_W | 14), .W15 = arm64.Register(REG_W | 15),
	.W16 = arm64.Register(REG_W | 16), .W17 = arm64.Register(REG_W | 17), .W18 = arm64.Register(REG_W | 18), .W19 = arm64.Register(REG_W | 19),
	.W20 = arm64.Register(REG_W | 20), .W21 = arm64.Register(REG_W | 21), .W22 = arm64.Register(REG_W | 22), .W23 = arm64.Register(REG_W | 23),
	.W24 = arm64.Register(REG_W | 24), .W25 = arm64.Register(REG_W | 25), .W26 = arm64.Register(REG_W | 26), .W27 = arm64.Register(REG_W | 27),
	.W28 = arm64.Register(REG_W | 28), .W29 = arm64.Register(REG_W | 29), .W30 = arm64.Register(REG_W | 30),
	.WZR = arm64.Register(REG_W | 31),
	.WSP = arm64.Register(REG_WSP | 31),

	// -----------------------------------------------------------------------------
	// SIMD/FP register views (full Vn; scalar Bn/Hn/Sn/Dn/Qn are operand-type views)
	// -----------------------------------------------------------------------------

	.V0  = arm64.Register(REG_V | 0),  .V1  = arm64.Register(REG_V | 1),  .V2  = arm64.Register(REG_V | 2),  .V3  = arm64.Register(REG_V | 3),
	.V4  = arm64.Register(REG_V | 4),  .V5  = arm64.Register(REG_V | 5),  .V6  = arm64.Register(REG_V | 6),  .V7  = arm64.Register(REG_V | 7),
	.V8  = arm64.Register(REG_V | 8),  .V9  = arm64.Register(REG_V | 9),  .V10 = arm64.Register(REG_V | 10), .V11 = arm64.Register(REG_V | 11),
	.V12 = arm64.Register(REG_V | 12), .V13 = arm64.Register(REG_V | 13), .V14 = arm64.Register(REG_V | 14), .V15 = arm64.Register(REG_V | 15),
	.V16 = arm64.Register(REG_V | 16), .V17 = arm64.Register(REG_V | 17), .V18 = arm64.Register(REG_V | 18), .V19 = arm64.Register(REG_V | 19),
	.V20 = arm64.Register(REG_V | 20), .V21 = arm64.Register(REG_V | 21), .V22 = arm64.Register(REG_V | 22), .V23 = arm64.Register(REG_V | 23),
	.V24 = arm64.Register(REG_V | 24), .V25 = arm64.Register(REG_V | 25), .V26 = arm64.Register(REG_V | 26), .V27 = arm64.Register(REG_V | 27),
	.V28 = arm64.Register(REG_V | 28), .V29 = arm64.Register(REG_V | 29), .V30 = arm64.Register(REG_V | 30), .V31 = arm64.Register(REG_V | 31),

	// -----------------------------------------------------------------------------
	// SME2 predicate-as-counter (PN8..PN15) and the ZT0 lookup table
	// -----------------------------------------------------------------------------

	.PN8  = arm64.Register(REG_PN |  8), .PN9  = arm64.Register(REG_PN |  9), .PN10 = arm64.Register(REG_PN | 10), .PN11 = arm64.Register(REG_PN | 11),
	.PN12 = arm64.Register(REG_PN | 12), .PN13 = arm64.Register(REG_PN | 13), .PN14 = arm64.Register(REG_PN | 14), .PN15 = arm64.Register(REG_PN | 15),

	.ZT0  = arm64.Register(REG_ZT | 0),


	// -----------------------------------------------------------------------------
	// System Registers
	// -----------------------------------------------------------------------------

	.AFSR0_EL1         = arm64.Register(REG_SYS | 0x4288_0000),
	.AFSR1_EL1         = arm64.Register(REG_SYS | 0x4289_0000),
	.CURRENT_EL        = arm64.Register(REG_SYS | 0x4212_0000),
	.DAIF              = arm64.Register(REG_SYS | 0x5A11_0000),
	.ELR_EL1           = arm64.Register(REG_SYS | 0x4201_0000),
	.ELR_EL2           = arm64.Register(REG_SYS | 0x6201_0000),
	.ELR_EL3           = arm64.Register(REG_SYS | 0x7201_0000),
	.ESR_EL1           = arm64.Register(REG_SYS | 0x4290_0000),
	.ESR_EL2           = arm64.Register(REG_SYS | 0x6290_0000),
	.FAR_EL1           = arm64.Register(REG_SYS | 0x4300_0000),
	.FAR_EL2           = arm64.Register(REG_SYS | 0x6300_0000),
	.ISR_EL1           = arm64.Register(REG_SYS | 0x4608_0000),
	.NZCV              = arm64.Register(REG_SYS | 0x5A10_0000),
	.SPSR_EL1          = arm64.Register(REG_SYS | 0x4200_0000),
	.SPSR_EL2          = arm64.Register(REG_SYS | 0x6200_0000),
	.SPSR_EL3          = arm64.Register(REG_SYS | 0x7200_0000),
	.SP_EL0            = arm64.Register(REG_SYS | 0x4208_0000),
	.SP_EL1            = arm64.Register(REG_SYS | 0x6208_0000),
	.VBAR_EL1          = arm64.Register(REG_SYS | 0x4600_0000),
	.VBAR_EL2          = arm64.Register(REG_SYS | 0x6600_0000),
	.VBAR_EL3          = arm64.Register(REG_SYS | 0x7600_0000),
	.FPCR              = arm64.Register(REG_SYS | 0x5A20_0000),
	.FPSR              = arm64.Register(REG_SYS | 0x5A21_0000),
	.MVFR0_EL1         = arm64.Register(REG_SYS | 0x4018_0000),
	.MVFR1_EL1         = arm64.Register(REG_SYS | 0x4019_0000),
	.MVFR2_EL1         = arm64.Register(REG_SYS | 0x401A_0000),
	.CONTEXTIDR_EL1    = arm64.Register(REG_SYS | 0x4681_0000),
	.TPIDR2_EL0        = arm64.Register(REG_SYS | 0x5E85_0000),
	.TPIDRRO_EL0       = arm64.Register(REG_SYS | 0x5E83_0000),
	.TPIDR_EL0         = arm64.Register(REG_SYS | 0x5E82_0000),
	.TPIDR_EL1         = arm64.Register(REG_SYS | 0x4684_0000),
	.TPIDR_EL2         = arm64.Register(REG_SYS | 0x6682_0000),
	.TPIDR_EL3         = arm64.Register(REG_SYS | 0x7682_0000),
	.CCSIDR_EL1        = arm64.Register(REG_SYS | 0x4800_0000),
	.CLIDR_EL1         = arm64.Register(REG_SYS | 0x4801_0000),
	.CSSELR_EL1        = arm64.Register(REG_SYS | 0x5000_0000),
	.CTR_EL0           = arm64.Register(REG_SYS | 0x5801_0000),
	.DCZID_EL0         = arm64.Register(REG_SYS | 0x5807_0000),
	.GMID_EL1          = arm64.Register(REG_SYS | 0x4804_0000),
	.ID_AA64AFR0_EL1   = arm64.Register(REG_SYS | 0x402C_0000),
	.ID_AA64AFR1_EL1   = arm64.Register(REG_SYS | 0x402D_0000),
	.ID_AA64DFR0_EL1   = arm64.Register(REG_SYS | 0x4028_0000),
	.ID_AA64DFR1_EL1   = arm64.Register(REG_SYS | 0x4029_0000),
	.ID_AA64DFR2_EL1   = arm64.Register(REG_SYS | 0x402A_0000),
	.ID_AA64ISAR0_EL1  = arm64.Register(REG_SYS | 0x4030_0000),
	.ID_AA64ISAR1_EL1  = arm64.Register(REG_SYS | 0x4031_0000),
	.ID_AA64ISAR2_EL1  = arm64.Register(REG_SYS | 0x4032_0000),
	.ID_AA64ISAR3_EL1  = arm64.Register(REG_SYS | 0x4033_0000),
	.ID_AA64MMFR0_EL1  = arm64.Register(REG_SYS | 0x4038_0000),
	.ID_AA64MMFR1_EL1  = arm64.Register(REG_SYS | 0x4039_0000),
	.ID_AA64MMFR2_EL1  = arm64.Register(REG_SYS | 0x403A_0000),
	.ID_AA64PFR0_EL1   = arm64.Register(REG_SYS | 0x4020_0000),
	.ID_AA64PFR1_EL1   = arm64.Register(REG_SYS | 0x4021_0000),
	.ID_AA64SMFR0_EL1  = arm64.Register(REG_SYS | 0x4025_0000),
	.ID_AA64ZFR0_EL1   = arm64.Register(REG_SYS | 0x4024_0000),
	.ID_AFR0_EL1       = arm64.Register(REG_SYS | 0x400B_0000),
	.ID_DFR0_EL1       = arm64.Register(REG_SYS | 0x400A_0000),
	.ID_ISAR0_EL1      = arm64.Register(REG_SYS | 0x4010_0000),
	.ID_ISAR1_EL1      = arm64.Register(REG_SYS | 0x4011_0000),
	.ID_ISAR2_EL1      = arm64.Register(REG_SYS | 0x4012_0000),
	.ID_ISAR3_EL1      = arm64.Register(REG_SYS | 0x4013_0000),
	.ID_ISAR4_EL1      = arm64.Register(REG_SYS | 0x4014_0000),
	.ID_ISAR5_EL1      = arm64.Register(REG_SYS | 0x4015_0000),
	.ID_ISAR6_EL1      = arm64.Register(REG_SYS | 0x4017_0000),
	.ID_MMFR0_EL1      = arm64.Register(REG_SYS | 0x400C_0000),
	.ID_MMFR1_EL1      = arm64.Register(REG_SYS | 0x400D_0000),
	.ID_MMFR2_EL1      = arm64.Register(REG_SYS | 0x400E_0000),
	.ID_MMFR3_EL1      = arm64.Register(REG_SYS | 0x400F_0000),
	.ID_MMFR4_EL1      = arm64.Register(REG_SYS | 0x4016_0000),
	.ID_MMFR5_EL1      = arm64.Register(REG_SYS | 0x401E_0000),
	.ID_PFR0_EL1       = arm64.Register(REG_SYS | 0x4008_0000),
	.ID_PFR1_EL1       = arm64.Register(REG_SYS | 0x4009_0000),
	.ID_PFR2_EL1       = arm64.Register(REG_SYS | 0x401C_0000),
	.MIDR_EL1          = arm64.Register(REG_SYS | 0x4000_0000),
	.MPIDR_EL1         = arm64.Register(REG_SYS | 0x4005_0000),
	.APDAKEYHI_EL1     = arm64.Register(REG_SYS | 0x4111_0000),
	.APDAKEYLO_EL1     = arm64.Register(REG_SYS | 0x4110_0000),
	.APDBKEYHI_EL1     = arm64.Register(REG_SYS | 0x4113_0000),
	.APDBKEYLO_EL1     = arm64.Register(REG_SYS | 0x4112_0000),
	.APGAKEYHI_EL1     = arm64.Register(REG_SYS | 0x4119_0000),
	.APGAKEYLO_EL1     = arm64.Register(REG_SYS | 0x4118_0000),
	.APIAKEYHI_EL1     = arm64.Register(REG_SYS | 0x4109_0000),
	.APIAKEYLO_EL1     = arm64.Register(REG_SYS | 0x4108_0000),
	.APIBKEYHI_EL1     = arm64.Register(REG_SYS | 0x410B_0000),
	.APIBKEYLO_EL1     = arm64.Register(REG_SYS | 0x410A_0000),
	.GCR_EL1           = arm64.Register(REG_SYS | 0x4086_0000),
	.RGSR_EL1          = arm64.Register(REG_SYS | 0x4085_0000),
	.TFSRE0_EL1        = arm64.Register(REG_SYS | 0x42B1_0000),
	.TFSR_EL1          = arm64.Register(REG_SYS | 0x42B0_0000),
	.SMCR_EL1          = arm64.Register(REG_SYS | 0x4096_0000),
	.SMCR_EL2          = arm64.Register(REG_SYS | 0x6096_0000),
	.SVCR              = arm64.Register(REG_SYS | 0x5A12_0000),
	.ZCR_EL1           = arm64.Register(REG_SYS | 0x4090_0000),
	.ZCR_EL2           = arm64.Register(REG_SYS | 0x6090_0000),
	.ZCR_EL3           = arm64.Register(REG_SYS | 0x7090_0000),
	.ACTLR_EL1         = arm64.Register(REG_SYS | 0x4081_0000),
	.AMAIR_EL1         = arm64.Register(REG_SYS | 0x4518_0000),
	.CPACR_EL1         = arm64.Register(REG_SYS | 0x4082_0000),
	.LORC_EL1          = arm64.Register(REG_SYS | 0x4523_0000),
	.LOREA_EL1         = arm64.Register(REG_SYS | 0x4521_0000),
	.LORID_EL1         = arm64.Register(REG_SYS | 0x4527_0000),
	.LORN_EL1          = arm64.Register(REG_SYS | 0x4522_0000),
	.LORSA_EL1         = arm64.Register(REG_SYS | 0x4520_0000),
	.MAIR_EL1          = arm64.Register(REG_SYS | 0x4510_0000),
	.PAR_EL1           = arm64.Register(REG_SYS | 0x43A0_0000),
	.SCTLR_EL1         = arm64.Register(REG_SYS | 0x4080_0000),
	.SCTLR_EL2         = arm64.Register(REG_SYS | 0x6080_0000),
	.SCTLR_EL3         = arm64.Register(REG_SYS | 0x7080_0000),
	.TCR_EL1           = arm64.Register(REG_SYS | 0x4102_0000),
	.TTBR0_EL1         = arm64.Register(REG_SYS | 0x4100_0000),
	.TTBR1_EL1         = arm64.Register(REG_SYS | 0x4101_0000),
	.CNTFRQ_EL0        = arm64.Register(REG_SYS | 0x5F00_0000),
	.CNTHCTL_EL2       = arm64.Register(REG_SYS | 0x6708_0000),
	.CNTHP_CTL_EL2     = arm64.Register(REG_SYS | 0x6711_0000),
	.CNTHP_CVAL_EL2    = arm64.Register(REG_SYS | 0x6712_0000),
	.CNTHP_TVAL_EL2    = arm64.Register(REG_SYS | 0x6710_0000),
	.CNTHV_CTL_EL2     = arm64.Register(REG_SYS | 0x6719_0000),
	.CNTHV_CVAL_EL2    = arm64.Register(REG_SYS | 0x671A_0000),
	.CNTHV_TVAL_EL2    = arm64.Register(REG_SYS | 0x6718_0000),
	.CNTKCTL_EL1       = arm64.Register(REG_SYS | 0x4708_0000),
	.CNTPCT_EL0        = arm64.Register(REG_SYS | 0x5F01_0000),
	.CNTPS_CTL_EL1     = arm64.Register(REG_SYS | 0x7F11_0000),
	.CNTPS_CVAL_EL1    = arm64.Register(REG_SYS | 0x7F12_0000),
	.CNTPS_TVAL_EL1    = arm64.Register(REG_SYS | 0x7F10_0000),
	.CNTP_CTL_EL0      = arm64.Register(REG_SYS | 0x5F11_0000),
	.CNTP_CVAL_EL0     = arm64.Register(REG_SYS | 0x5F12_0000),
	.CNTP_TVAL_EL0     = arm64.Register(REG_SYS | 0x5F10_0000),
	.CNTVCT_EL0        = arm64.Register(REG_SYS | 0x5F02_0000),
	.CNTVOFF_EL2       = arm64.Register(REG_SYS | 0x6703_0000),
	.CNTV_CTL_EL0      = arm64.Register(REG_SYS | 0x5F19_0000),
	.CNTV_CVAL_EL0     = arm64.Register(REG_SYS | 0x5F1A_0000),
	.CNTV_TVAL_EL0     = arm64.Register(REG_SYS | 0x5F18_0000),
	.PMBIDR_EL1        = arm64.Register(REG_SYS | 0x44D7_0000),
	.PMBLIMITR_EL1     = arm64.Register(REG_SYS | 0x44D0_0000),
	.PMBPTR_EL1        = arm64.Register(REG_SYS | 0x44D1_0000),
	.PMBSR_EL1         = arm64.Register(REG_SYS | 0x44D3_0000),
	.PMSCR_EL1         = arm64.Register(REG_SYS | 0x44C8_0000),
	.PMSELR_EL0        = arm64.Register(REG_SYS | 0x5CE5_0000),
	.PMSEVFR_EL1       = arm64.Register(REG_SYS | 0x44CD_0000),
	.PMSFCR_EL1        = arm64.Register(REG_SYS | 0x44CC_0000),
	.PMSICR_EL1        = arm64.Register(REG_SYS | 0x44CA_0000),
	.PMSIDR_EL1        = arm64.Register(REG_SYS | 0x44CF_0000),
	.PMSIRR_EL1        = arm64.Register(REG_SYS | 0x44CB_0000),
	.PMSLATFR_EL1      = arm64.Register(REG_SYS | 0x44CE_0000),
	.PMSWINC_EL0       = arm64.Register(REG_SYS | 0x5CE4_0000),
	.PMCCFILTR_EL0     = arm64.Register(REG_SYS | 0x5F7F_0000),
	.PMCCNTR_EL0       = arm64.Register(REG_SYS | 0x5CE8_0000),
	.PMCEID0_EL0       = arm64.Register(REG_SYS | 0x5CE6_0000),
	.PMCEID1_EL0       = arm64.Register(REG_SYS | 0x5CE7_0000),
	.PMCNTENCLR_EL0    = arm64.Register(REG_SYS | 0x5CE2_0000),
	.PMCNTENSET_EL0    = arm64.Register(REG_SYS | 0x5CE1_0000),
	.PMCR_EL0          = arm64.Register(REG_SYS | 0x5CE0_0000),
	.PMINTENCLR_EL1    = arm64.Register(REG_SYS | 0x44F2_0000),
	.PMINTENSET_EL1    = arm64.Register(REG_SYS | 0x44F1_0000),
	.PMOVSCLR_EL0      = arm64.Register(REG_SYS | 0x5CE3_0000),
	.PMUSERENR_EL0     = arm64.Register(REG_SYS | 0x5CF0_0000),
	.TRBBASER_EL1      = arm64.Register(REG_SYS | 0x44DA_0000),
	.TRBIDR_EL1        = arm64.Register(REG_SYS | 0x44DF_0000),
	.TRBLIMITR_EL1     = arm64.Register(REG_SYS | 0x44D8_0000),
	.TRBMAR_EL1        = arm64.Register(REG_SYS | 0x44DC_0000),
	.TRBPTR_EL1        = arm64.Register(REG_SYS | 0x44D9_0000),
	.TRBSR_EL1         = arm64.Register(REG_SYS | 0x44DB_0000),
	.TRBTRG_EL1        = arm64.Register(REG_SYS | 0x44DE_0000),
	.DBGAUTHSTATUS_EL1 = arm64.Register(REG_SYS | 0x03F6_0000),
	.DBGCLAIMCLR_EL1   = arm64.Register(REG_SYS | 0x03CE_0000),
	.DBGCLAIMSET_EL1   = arm64.Register(REG_SYS | 0x03C6_0000),
	.DBGDTRRX_EL0      = arm64.Register(REG_SYS | 0x1828_0000),
	.DBGDTRTX_EL0      = arm64.Register(REG_SYS | 0x1828_0000),
	.DBGDTR_EL0        = arm64.Register(REG_SYS | 0x1820_0000),
	.DBGPRCR_EL1       = arm64.Register(REG_SYS | 0x00A4_0000),
	.DLR_EL0           = arm64.Register(REG_SYS | 0x5A29_0000),
	.DSPSR_EL0         = arm64.Register(REG_SYS | 0x5A28_0000),
	.MDCCINT_EL1       = arm64.Register(REG_SYS | 0x0010_0000),
	.MDRAR_EL1         = arm64.Register(REG_SYS | 0x0080_0000),
	.MDSCR_EL1         = arm64.Register(REG_SYS | 0x0012_0000),
	.OSLAR_EL1         = arm64.Register(REG_SYS | 0x0084_0000),
	.OSLSR_EL1         = arm64.Register(REG_SYS | 0x008C_0000),
	.PRSELR_EL1        = arm64.Register(REG_SYS | 0x4311_0000),
	.ICC_ASGI1R_EL1    = arm64.Register(REG_SYS | 0x465E_0000),
	.ICC_BPR0_EL1      = arm64.Register(REG_SYS | 0x4643_0000),
	.ICC_BPR1_EL1      = arm64.Register(REG_SYS | 0x4663_0000),
	.ICC_CTLR_EL1      = arm64.Register(REG_SYS | 0x4664_0000),
	.ICC_CTLR_EL3      = arm64.Register(REG_SYS | 0x7664_0000),
	.ICC_DIR_EL1       = arm64.Register(REG_SYS | 0x4659_0000),
	.ICC_EOIR0_EL1     = arm64.Register(REG_SYS | 0x4641_0000),
	.ICC_EOIR1_EL1     = arm64.Register(REG_SYS | 0x4661_0000),
	.ICC_HPPIR0_EL1    = arm64.Register(REG_SYS | 0x4642_0000),
	.ICC_HPPIR1_EL1    = arm64.Register(REG_SYS | 0x4662_0000),
	.ICC_IAR0_EL1      = arm64.Register(REG_SYS | 0x4640_0000),
	.ICC_IAR1_EL1      = arm64.Register(REG_SYS | 0x4660_0000),
	.ICC_IGRPEN0_EL1   = arm64.Register(REG_SYS | 0x4666_0000),
	.ICC_IGRPEN1_EL1   = arm64.Register(REG_SYS | 0x4667_0000),
	.ICC_IGRPEN1_EL3   = arm64.Register(REG_SYS | 0x7667_0000),
	.ICC_PMR_EL1       = arm64.Register(REG_SYS | 0x4230_0000),
	.ICC_RPR_EL1       = arm64.Register(REG_SYS | 0x465B_0000),
	.ICC_SGI0R_EL1     = arm64.Register(REG_SYS | 0x465F_0000),
	.ICC_SGI1R_EL1     = arm64.Register(REG_SYS | 0x465D_0000),
	.ICC_SRE_EL1       = arm64.Register(REG_SYS | 0x4665_0000),
	.ICC_SRE_EL2       = arm64.Register(REG_SYS | 0x664D_0000),
	.ICC_SRE_EL3       = arm64.Register(REG_SYS | 0x7665_0000),
	.ICH_EISR_EL2      = arm64.Register(REG_SYS | 0x665B_0000),
	.ICH_ELRSR_EL2     = arm64.Register(REG_SYS | 0x665D_0000),
	.ICH_HCR_EL2       = arm64.Register(REG_SYS | 0x6658_0000),
	.ICH_MISR_EL2      = arm64.Register(REG_SYS | 0x665A_0000),
	.ICH_VMCR_EL2      = arm64.Register(REG_SYS | 0x665F_0000),
	.ICH_VTR_EL2       = arm64.Register(REG_SYS | 0x6659_0000),
	.DISR_EL1          = arm64.Register(REG_SYS | 0x4609_0000),
	.ERRIDR_EL1        = arm64.Register(REG_SYS | 0x4298_0000),
	.ERRSELR_EL1       = arm64.Register(REG_SYS | 0x4299_0000),
	.ERXADDR_EL1       = arm64.Register(REG_SYS | 0x42A3_0000),
	.ERXCTLR_EL1       = arm64.Register(REG_SYS | 0x42A1_0000),
	.ERXFR_EL1         = arm64.Register(REG_SYS | 0x42A0_0000),
	.ERXMISC0_EL1      = arm64.Register(REG_SYS | 0x42A8_0000),
	.ERXMISC1_EL1      = arm64.Register(REG_SYS | 0x42A9_0000),
	.ERXMISC2_EL1      = arm64.Register(REG_SYS | 0x42AA_0000),
	.ERXMISC3_EL1      = arm64.Register(REG_SYS | 0x42AB_0000),
	.ERXSTATUS_EL1     = arm64.Register(REG_SYS | 0x42A2_0000),
	.VDISR_EL2         = arm64.Register(REG_SYS | 0x6609_0000),
	.VSESR_EL2         = arm64.Register(REG_SYS | 0x6293_0000),
	.GPCCR_EL3         = arm64.Register(REG_SYS | 0x710E_0000),
	.GPTBR_EL3         = arm64.Register(REG_SYS | 0x710C_0000),
	.HCR_EL2           = arm64.Register(REG_SYS | 0x6088_0000),
	.HSTR_EL2          = arm64.Register(REG_SYS | 0x608B_0000),
	.MDCR_EL2          = arm64.Register(REG_SYS | 0x6089_0000),
	.MFAR_EL3          = arm64.Register(REG_SYS | 0x7305_0000),
	.VTCR_EL2          = arm64.Register(REG_SYS | 0x610A_0000),
	.VTTBR_EL2         = arm64.Register(REG_SYS | 0x6108_0000),
	.DACR32_EL2        = arm64.Register(REG_SYS | 0x6180_0000),
	.FPEXC32_EL2       = arm64.Register(REG_SYS | 0x6298_0000),
	.RNDR              = arm64.Register(REG_SYS | 0x5920_0000),
	.RNDRRS            = arm64.Register(REG_SYS | 0x5921_0000),
}
