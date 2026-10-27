// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_x86

// =============================================================================
// MNEMONIC ALIASES  —  which of several names for one encoding a disassembler prints
// =============================================================================
//
// Some x86 instructions have several legal mnemonics for ONE encoding. SHL and
// SAL are both ModRM.reg=4 in the shift group; JE and JZ are both 0x74; there
// are 57 such pairs. A decoder has nothing to tell them apart with — the bytes
// are identical — so it must simply pick a name, and that choice has to be
// DECLARED. Left undeclared it falls out of wherever the entry happened to land
// in the (unstably sorted) decode table: correct, arbitrary, and free to move on
// any table regeneration. It did move once, and four tests that had always
// passed began reporting `SAL != expected SHL`.
//
// The canonical name here is the one **llvm-mc prints**, measured rather than
// chosen: llvm-mc is the ground truth every verifier in this library diffs
// against, so agreeing with it is what makes a disassembly comparable. Before
// this table, 52 of the 74 aliased encodings decoded to a name llvm-mc does not
// use (`0F 84` → JZ where it says JE, `A4` → MOVS where it says MOVSB, `DB E2` →
// FCLEX where it says FNCLEX).
//
// An alias stays fully ENCODABLE — `inst_r_r(.SAL, …)` emits the same bytes it
// always did. Only the decode direction is narrowed, and only where the
// canonical name covers the byte-identical encoding: that condition is what lets
// MOV be the alias at the `A0`-`A3`/`B8` moffs forms while remaining the only
// name for `88`/`89`. `tablegen/gen.odin` applies it when it collects decode
// entries, so an aliased mnemonic never reaches the decode tables at all.
//
// Adding an instruction whose mnemonic aliases another one's encoding requires a
// row here; `run_alias_table_test` in tests/ recomputes the ambiguity from the
// built tables and fails by name if one is missing, so it cannot be forgotten.

Mnemonic_Alias :: struct {
	alias:     Mnemonic, // never produced by the decoder
	canonical: Mnemonic, // produced instead, at the byte-identical encoding
}

@(rodata)
MNEMONIC_ALIASES := [?]Mnemonic_Alias{
	// -- Jcc, both the short 0x7x and near 0x0F 8x forms --------------------
	{.JNAE, .JB},  {.JC, .JB},
	{.JNB, .JAE},  {.JNC, .JAE},
	{.JZ, .JE},
	{.JNZ, .JNE},
	{.JNA, .JBE},
	{.JNBE, .JA},
	{.JPE, .JP},
	{.JPO, .JNP},
	{.JNGE, .JL},
	{.JNL, .JGE},
	{.JNG, .JLE},
	{.JNLE, .JG},

	// -- CMOVcc (0x0F 4x) ---------------------------------------------------
	{.CMOVNAE, .CMOVB},  {.CMOVC, .CMOVB},
	{.CMOVNB, .CMOVAE},  {.CMOVNC, .CMOVAE},
	{.CMOVZ, .CMOVE},
	{.CMOVNZ, .CMOVNE},
	{.CMOVNA, .CMOVBE},
	{.CMOVNBE, .CMOVA},
	{.CMOVPE, .CMOVP},
	{.CMOVPO, .CMOVNP},
	{.CMOVNGE, .CMOVL},
	{.CMOVNL, .CMOVGE},
	{.CMOVNG, .CMOVLE},
	{.CMOVNLE, .CMOVG},

	// -- SETcc (0x0F 9x) ----------------------------------------------------
	{.SETNAE, .SETB},  {.SETC, .SETB},
	{.SETNB, .SETAE},  {.SETNC, .SETAE},
	{.SETZ, .SETE},
	{.SETNZ, .SETNE},
	{.SETNA, .SETBE},
	{.SETNBE, .SETA},
	{.SETPE, .SETP},
	{.SETPO, .SETNP},
	{.SETNGE, .SETL},
	{.SETNL, .SETGE},
	{.SETNG, .SETLE},
	{.SETNLE, .SETG},

	// -- Shift group: SAL and SHL are both /4, the same encoding ------------
	{.SAL, .SHL},

	// -- String ops: the bare name against the explicitly byte-sized one ----
	{.CMPS, .CMPSB},
	{.LODS, .LODSB},
	{.MOVS, .MOVSB},
	{.SCAS, .SCASB},
	{.STOS, .STOSB},

	// -- x87: the assembler's wait-prefixed spelling of a no-wait opcode ----
	// (FSTENV is really `9B D9 /6`; the table gives it the bare `D9 /6`, which
	//  is FNSTENV. Modelling the 9B prefix is a separate question — until then
	//  the bare encoding decodes as the no-wait name, which is what it is.)
	{.FCLEX, .FNCLEX},
	{.FINIT, .FNINIT},
	{.FSAVE, .FNSAVE},
	{.FSTCW, .FNSTCW},
	{.FSTENV, .FNSTENV},
	{.FSTSW, .FNSTSW},

	// -- Odds --------------------------------------------------------------
	{.FWAIT, .WAIT},
	{.XLAT, .XLATB},
	// MOV aliases MOVABS only at the moffs (`A0`-`A3`) and imm64 (`B8+r`)
	// forms; the coverage rule leaves every other MOV encoding untouched.
	{.MOV, .MOVABS},
}

// The name a disassembler prints for `m`'s encoding — `m` itself unless it is a
// declared alias. Useful to an assembler front-end that accepts either spelling
// and wants to compare against decoder output.
canonical_mnemonic :: proc "contextless" (m: Mnemonic) -> Mnemonic {
	for entry in MNEMONIC_ALIASES {
		if entry.alias == m { return entry.canonical }
	}
	return m
}

// Is `m` a name the decoder never produces?
is_mnemonic_alias :: proc "contextless" (m: Mnemonic) -> bool {
	for entry in MNEMONIC_ALIASES {
		if entry.alias == m { return true }
	}
	return false
}
