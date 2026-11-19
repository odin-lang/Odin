#include "check_asm_cfg.cpp"

// Bit-width the operand's Odin type occupies in a register/immediate slot.
// Integers/floats/bools/pointers -> their size; #simd -> total vector width. 0 if unknown.
gb_internal i32 check_asm_operand_bit_width(Type *type) {
	if (type == nullptr || type == t_invalid) {
		return 0;
	}
	if (is_type_untyped(type)) {
		return -1;
	}
	i64 sz = type_size_of(base_type(type));
	if (sz <= 0) {
		return 0;
	}
	return cast(i32)(sz * 8);
}

gb_internal bool check_asm_target_supports_label_memory_operand(void) {
	switch (build_context.metrics.arch) {
	case TargetArch_amd64:
		return true;
	}
	return false;
}

gb_internal AsmRegClass check_asm_reg_class_from_type(Type *type) {
	if (is_type_integer(type)) {
		return AsmRegClass_Integer;
	}
	if (is_type_float(type)) {
		return AsmRegClass_Float;
	}
	if (is_type_boolean(type)) {
		return AsmRegClass_Integer;
	}
	if (is_type_internally_pointer_like(type)) {
		return AsmRegClass_Integer;
	}
	if (is_type_simd_vector(type)) {
		return AsmRegClass_Vector;
	}
	return AsmRegClass_Unknown;
}

gb_internal bool is_valid_asm_parameter_type(Type *type) {
	if (is_type_integer(type) && type_size_of(type) > 8) {
		return false; // NOTE(bill): do not allow 128-bit integers
	}
	return check_asm_reg_class_from_type(type) != AsmRegClass_Unknown;
}

gb_internal bool check_asm_parameter_type(Ast *node, Type *type) {
	if (is_valid_asm_parameter_type(type)) {
		return true;
	}
	gbString s = type_to_string(type);
	error(node, "Invalid type for an asm template. It must be an integer, float, boolean, pointer, multi-pointer, or #simd vector, got '%s'", s);
	gb_string_free(s);
	return false;
}

gb_internal void check_asm_redeclaration_error(Token name, Entity *found) {
	error(name,
	      "Redeclaration of '%.*s' in this scope\n"
	      "\tat %s",
	      LIT(name.string), token_pos_to_string(found->token.pos));
}

gb_internal AsmOperandKind determine_asm_operand_kind(Operand const *operand) {
	if (operand->mode == Addressing_Constant) {
		return AsmOperand_Immediate;
	}
	Ast *expr = operand->expr;
	switch (expr->kind) {
	case_ast_node(label, AsmLabelDecl, expr);
		return AsmOperand_Label;
	case_end;
	case_ast_node(reg, AsmRegister, expr);
		return AsmOperand_Register;
	case_end;
	case_ast_node(reg, AsmMemoryOperand, expr);
		return AsmOperand_Memory;
	case_end;
	case_ast_node(se, SelectorExpr, expr);
		// NOTE(bill): a procedure from another package, which is called directly like a label
		Entity *e = entity_of_node(expr);
		if (e != nullptr && (e->kind == Entity_Procedure || e->kind == Entity_ProcGroup)) {
			return AsmOperand_Label;
		}
		return AsmOperand_Invalid;
	case_end;
	case_ast_node(ident, Ident, expr);
		// TODO(bill): Is this correct?
		if (expr->tav.mode == Addressing_Constant) {
			return AsmOperand_Immediate;
		}
		Entity *e = entity_of_node(expr);
		if (e != nullptr && (e->kind == Entity_Procedure || e->kind == Entity_ProcGroup)) {
			return AsmOperand_Label; // NOTE(bill): a procedure named in the body is called directly like a label
		}
		if (e != nullptr && e->kind == Entity_Variable && (e->flags & EntityFlag_PolyConst) != 0) {
			return AsmOperand_Immediate;
		}
		return AsmOperand_Register;
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		return AsmOperand_Lane;
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		return AsmOperand_RegisterShift;
	case_end;

	}
	return AsmOperand_Invalid;
}

gb_internal bool asm_operand_kind_fits(AsmOperandKind dst, AsmOperandKind src) {
	if (dst == src) {
		return true;
	}
	switch (dst) {
	case AsmOperand_Register_Or_Memory:
		return src == AsmOperand_Register || src == AsmOperand_Memory;
	case AsmOperand_RegisterShift:
		return src == AsmOperand_Register;
	}
	return false;
}

gb_internal bool asm_reg_class_compatible(AsmRegClass want, AsmRegClass got) {
	switch (want) {
	case AsmRegClass_Integer:
		return got == AsmRegClass_Integer;
	case AsmRegClass_Float:
	case AsmRegClass_Vector:
		// A scalar float uses only the low lane, so it is valid in any vector
		// register slot; a #simd vector matches the vector class exactly.
		return got == AsmRegClass_Vector || got == AsmRegClass_Float;
	case AsmRegClass_Mask:
		return got == AsmRegClass_Mask;
	}
	return true;
}

gb_internal void check_asm_pin_type_compat(AsmRegClass reg_class, i32 reg_w, Type *decl_type,
                                           Ast *at, String pin_name, String param_name) {
	if (reg_class == AsmRegClass_Unknown ||
	    reg_w == 0 ||
	    decl_type == nullptr || decl_type == t_invalid) {
		return;
	}
	AsmRegClass got_class = check_asm_reg_class_from_type(decl_type);
	i32         got_w     = check_asm_operand_bit_width(decl_type);

	if (!asm_reg_class_compatible(reg_class, got_class)) {
		error(at, "Parameter '%.*s' is pinned to %%%.*s, but its type is in the wrong register class for that register",
		      LIT(param_name), LIT(pin_name));
		return;
	}
	// got_w < 0 == untyped constant: skip. Otherwise the value must fit the register.
	if (got_w > 0 && got_w > reg_w) {
		error(at, "Parameter '%.*s' (%d-bit) is wider than its pinned register %%%.*s (%d-bit)",
		      LIT(param_name), cast(int)got_w, LIT(pin_name), cast(int)reg_w);
	}
}


// NOTE(bill): what a template's body names: the parameters and immediates it refers to, and the registers it uses
// explicitly or implicitly, both as clobber bits and as register families. A pinned parameter is used through its register.
struct AsmBodyRefs {
	PtrSet<Entity *> entities;
	u16              bits;
	StringSet        families;
	bool             calls_out; // the callee may take any register as an argument
};

// Reads Ident.entity, which check_asm_instruction_operand populates during operand checking.
template <typename AsmCtx>
gb_internal void check_asm_collect_refs(AsmCtx *asm_ctx, AsmBodyRefs *refs, Ast *expr) {
	if (expr == nullptr) {
		return;
	}
	switch (expr->kind) {
	case Ast_Ident:
		if (expr->Ident.entity != nullptr) {
			ptr_set_add(&refs->entities, cast(Entity *)expr->Ident.entity);
		}
		return;
	case Ast_AsmRegister: {
		String family = asm_register_family_name(asm_ctx, expr->AsmRegister.name.string);
		if (family.len != 0) {
			string_set_add(&refs->families, family);
		}
		refs->bits |= asm_ctx->clobber_bit_for_reg_name(expr->AsmRegister.name.string);
		return;
	}
	case Ast_AsmMemoryTerm:
		check_asm_collect_refs(asm_ctx, refs, expr->AsmMemoryTerm.operand);
		check_asm_collect_refs(asm_ctx, refs, expr->AsmMemoryTerm.scale);
		return;
	case Ast_AsmMemoryOperand:
		check_asm_collect_refs(asm_ctx, refs, expr->AsmMemoryOperand.segment_override);
		for (Ast *term : expr->AsmMemoryOperand.terms) {
			check_asm_collect_refs(asm_ctx, refs, term);
		}
		return;
	case Ast_IndexExpr:
		check_asm_collect_refs(asm_ctx, refs, expr->IndexExpr.expr);
		check_asm_collect_refs(asm_ctx, refs, expr->IndexExpr.index);
		return;
	case Ast_UnaryExpr:
		check_asm_collect_refs(asm_ctx, refs, expr->UnaryExpr.expr);
		return;
	case Ast_BinaryExpr:
		check_asm_collect_refs(asm_ctx, refs, expr->BinaryExpr.left);
		check_asm_collect_refs(asm_ctx, refs, expr->BinaryExpr.right);
		return;
	}
}

template <typename AsmCtx>
gb_internal void asm_body_refs_init(AsmCtx *asm_ctx, AsmBodyRefs *refs, AstAsmTemplate *at) {
	ptr_set_init(&refs->entities);
	string_set_init(&refs->families);
	for (Ast *node : at->instructions) {
		if (node->kind == Ast_AsmDirective) {
			for (Ast *op : node->AsmDirective.operands) {
				check_asm_collect_refs(asm_ctx, refs, op);
			}
		}
		if (node->kind != Ast_AsmInstruction) {
			continue;
		}
		for (Ast *op : node->AsmInstruction.operands) {
			check_asm_collect_refs(asm_ctx, refs, op);
		}
		// NOTE(bill): an implicit read (e.g. CQO reads RAX, CPUID reads EAX/ECX) uses the register too
		if (AsmInstructionFacts *facts = node->AsmInstruction.facts) {
			refs->bits      |= facts->read_regs;
			refs->calls_out |= facts->calls_out;
		}
	}
}

gb_internal void asm_body_refs_destroy(AsmBodyRefs *refs) {
	ptr_set_destroy(&refs->entities);
	string_set_destroy(&refs->families);
}

template <typename AsmCtx>
gb_internal bool asm_body_refs_register(AsmCtx *asm_ctx, AsmBodyRefs *refs, String reg) {
	u16 bit = asm_ctx->clobber_bit_for_reg_name(reg);
	if ((refs->bits & bit) != 0) {
		return true;
	}
	String family = asm_register_family_name(asm_ctx, reg);
	return family.len != 0 && string_set_exists(&refs->families, family);
}
enum AsmMismatch : u8 {
	AsmMismatch_None,
	AsmMismatch_Size,      // register / vector width mismatch
	AsmMismatch_Class,     // register class mismatch
	AsmMismatch_ImmRange,  // constant immediate does not fit the slot width
	AsmMismatch_ImmType,   // non-integer constant where an integer immediate is required
	AsmMismatch_NamedReg,  // slot only a named hardware register can fill
	AsmMismatch_Writeback, // memory operand whose #pre/#post writeback differs from the slot's
};

gb_global char const *asm_writeback_names[AsmMemoryOperand_COUNT] = {"", "pre", "post"};

// NOTE(bill): the writeback a memory slot takes. Only AArch64 has pre- and post-indexed addressing.
template <typename AsmCtx>
gb_internal AsmMemoryOperandKind asm_slot_writeback(AsmCtx *asm_ctx, typename AsmCtx::OperandType slot) {
	return AsmMemoryOperand_Default;
}
gb_internal AsmMemoryOperandKind asm_slot_writeback(Asm_arm64 *asm_ctx, Asm_arm64::OperandType slot) {
	switch (slot) {
	case Asm_arm64::OP_MEM_PRE:  return AsmMemoryOperand_Pre;
	case Asm_arm64::OP_MEM_POST: return AsmMemoryOperand_Post;
	}
	return AsmMemoryOperand_Default;
}

gb_internal AsmMemoryOperandKind asm_operand_writeback(Operand const *operand) {
	return operand->expr->kind == Ast_AsmMemoryOperand ? operand->expr->AsmMemoryOperand.kind : AsmMemoryOperand_Default;
}

// Does a constant immediate value fit a slot of `bits` width (0 == unconstrained)?
// Accepts either a signed or an unsigned interpretation of the bit pattern, which
// matches how the assembler treats imm fields (e.g. both 200 and -56 fit imm8).
gb_internal bool check_asm_immediate_value_fits(ExactValue ev, i32 bits, i32 *needed_, AsmMismatch *mismatch_) {
	if (ev.kind == ExactValue_Float || ev.kind == ExactValue_Rational) {
		// Try to convert it if possible to an integer
		ev = exact_value_to_integer(ev);
	}

	switch (ev.kind) {
	case ExactValue_Bool:
		// Encodes as 0 or 1; fits any immediate slot with a non-zero width.
		if (needed_) *needed_ = 1;
		return true;

	case ExactValue_Integer: {
		mp_int const *v = &ev.value_integer;
		i32 mag_bits = cast(i32)mp_count_bits(v);
		if (needed_) *needed_ = mag_bits;

		if (bits == 0) {
			// TODO(bill): is this a decent width?!
			bits = 64; // slot does not pin a width, just set a decent default
		}
		if (mp_iszero(v)) {
			return true;
		}
		if (!mp_isneg(v)) {
			// Non-negative: fits if the unsigned bit pattern is <= `bits` wide.
			if (mag_bits <= bits) {
				return true;
			}
		} else {
			// Negative: fits signed in `bits` iff mp_count_bits(-v - 1) <= bits-1.
			// (-v-1 ranges 0 .. 2^(bits-1)-1 for the representable negatives.)
			mp_int tmp = {};
			mp_init(&tmp);
			defer (mp_clear(&tmp));
			mp_neg(v, &tmp);         // tmp = -v  (positive magnitude)
			mp_sub_d(&tmp, 1, &tmp); // tmp = -v - 1
			i32 nb = cast(i32)mp_count_bits(&tmp);
			if (needed_) *needed_ = nb + 1; // signed bit-width, for the diagnostic
			if (nb <= bits-1) {
				return true;
			}
		}
		if (mismatch_) *mismatch_ = AsmMismatch_ImmRange;
		return false;
	}

	case ExactValue_Float:
		// TODO(bill): does any architecture support floating-point immediates?
		// amd64 has no floating-point instruction immediates.
		if (needed_) *needed_ = 0;
		if (mismatch_) *mismatch_ = AsmMismatch_ImmType;
		return false;
	}
	if (mismatch_) *mismatch_ = AsmMismatch_ImmType;
	return false;
}

template <typename AsmCtx>
gb_internal bool asm_register_is_mask(AsmCtx *asm_ctx, String name) {
	return false;
}
gb_internal bool asm_register_is_mask(Asm_amd64 *asm_ctx, String name) {
	auto r = asm_ctx->register_lookup(name);
	return r != Asm_amd64::REG_INVALID && asm_ctx->reg_class(asm_ctx->register_codes[r]) == Asm_amd64::REG_CLASS_K;
}

template <typename AsmCtx>
gb_internal String asm_register_name_from_code(AsmCtx *asm_ctx, u32 code) {
	for (isize r = 1; r < AsmCtx::REG_COUNT; r++) {
		if (asm_ctx->register_codes[r] == code) {
			return asm_ctx->register_strings[r];
		}
	}
	return {};
}

// NOTE(bill): the whole register a named register is part of (e.g. %r8d -> r8, %ymm3 -> xmm3), spelt as LLVM clobbers it.
// Empty for the registers a clobber never names: the stack pointer, the zero registers, and system registers.
gb_internal String asm_register_family_name(Asm_amd64 *asm_ctx, String name) {
	auto r = asm_ctx->register_lookup(name);
	if (r == Asm_amd64::REG_INVALID) {
		return {};
	}
	u16 code = asm_ctx->register_codes[r];
	u16 num  = code & 0xFF;
	u16 full = 0;
	switch (asm_ctx->reg_class(code)) {
	case Asm_amd64::REG_CLASS_GPR64:
	case Asm_amd64::REG_CLASS_GPR32:
	case Asm_amd64::REG_CLASS_GPR16:
	case Asm_amd64::REG_CLASS_GPR8:
		full = Asm_amd64::REG_CLASS_GPR64 | num;
		break;
	case Asm_amd64::REG_CLASS_GPR8H: // %ah, %ch, %dh, and %bh are encoded as 4 to 7
		full = Asm_amd64::REG_CLASS_GPR64 | (num - 4);
		break;
	case Asm_amd64::REG_CLASS_XMM:
	case Asm_amd64::REG_CLASS_YMM:
	case Asm_amd64::REG_CLASS_ZMM:
		full = Asm_amd64::REG_CLASS_XMM | num;
		break;
	case Asm_amd64::REG_CLASS_K:
		full = code;
		break;
	default:
		return {};
	}
	if (full == (Asm_amd64::REG_CLASS_GPR64 | 4)) { // %rsp
		return {};
	}
	return asm_register_name_from_code(asm_ctx, full);
}

gb_internal String asm_register_family_name(Asm_arm64 *asm_ctx, String name) {
	auto r = asm_ctx->register_lookup(name);
	if (r == Asm_arm64::REG_INVALID) {
		return {};
	}
	u32 code = asm_ctx->register_codes[r];
	u32 num  = code & 0xFF;
	u32 full = 0;
	switch (asm_ctx->reg_class(code)) {
	case Asm_arm64::REG_CLASS_X:
	case Asm_arm64::REG_CLASS_W:
		if (num == 31) { // %xzr, %wzr
			return {};
		}
		full = Asm_arm64::REG_CLASS_X | num;
		break;
	case Asm_arm64::REG_CLASS_V:
	case Asm_arm64::REG_CLASS_B:
	case Asm_arm64::REG_CLASS_H:
	case Asm_arm64::REG_CLASS_S:
	case Asm_arm64::REG_CLASS_D:
	case Asm_arm64::REG_CLASS_Q:
		full = Asm_arm64::REG_CLASS_V | num;
		break;
	default:
		return {};
	}
	return asm_register_name_from_code(asm_ctx, full);
}

gb_internal String asm_register_family_name(Asm_riscv *asm_ctx, String name) {
	auto r = asm_ctx->register_lookup(name);
	if (r == Asm_riscv::REG_INVALID) {
		return {};
	}
	u16 code = asm_ctx->register_codes[r];
	u16 num  = code & 0xFF;
	switch (asm_ctx->reg_class(code)) {
	case Asm_riscv::REG_CLASS_GPR:
		switch (num) {
		case 0: // zero
		case 2: // sp
		case 3: // gp
		case 4: // tp
			return {};
		}
		return asm_ctx->register_strings[r];
	case Asm_riscv::REG_CLASS_FPR:
		return asm_ctx->register_strings[r];
	}
	return {};
}

// NOTE(bill): the registers a call out of a template may write, which is every register but the stack and frame pointers,
// as the callee's calling convention is not assumed. Below them are the registers an operand is pinned to when a template calls out,
// in order of preference.
gb_internal void asm_call_clobber_families(Asm_amd64 *asm_ctx, Array<String> *families) {
	for (u16 num = 0; num < 16; num++) {
		if (num == 4 || num == 5) { // %rsp, %rbp
			continue;
		}
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_GPR64 | num));
	}
	for (u16 num = 0; num < 32; num++) {
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_XMM | num));
	}
	for (u16 num = 0; num < 8; num++) {
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_K | num));
	}
}
gb_internal void asm_call_pin_candidates(Asm_amd64 *asm_ctx, AsmRegClass reg_class, Array<String> *candidates) {
	switch (reg_class) {
	case AsmRegClass_Integer: {
		static u16 const nums[] = {3, 12, 13, 14, 15, 6, 7, 8, 9, 10, 11, 1, 2, 0}; // %rbx, %r12 to %r15, then the rest
		for (u16 num : nums) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_GPR64 | num));
		}
		break;
	}
	case AsmRegClass_Float:
	case AsmRegClass_Vector:
		for (u16 i = 0; i < 16; i++) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_XMM | ((i + 8) % 16)));
		}
		break;
	case AsmRegClass_Mask:
		for (u16 num = 1; num < 8; num++) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_K | num));
		}
		break;
	}
}

gb_internal bool asm_arm64_x18_is_reserved(void) {
	// NOTE(bill): LLVM reserves x18 as the platform register on these by default
	return build_context.metrics.os == TargetOs_darwin || selected_subtarget == Subtarget_Android;
}
gb_internal void asm_call_clobber_families(Asm_arm64 *asm_ctx, Array<String> *families) {
	for (u32 num = 0; num < 31; num++) {
		if (num == 29 || (num == 18 && asm_arm64_x18_is_reserved())) { // the frame pointer, and the platform register
			continue;
		}
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_arm64::REG_CLASS_X | num));
	}
	for (u32 num = 0; num < 32; num++) {
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_arm64::REG_CLASS_V | num));
	}
}
gb_internal void asm_call_pin_candidates(Asm_arm64 *asm_ctx, AsmRegClass reg_class, Array<String> *candidates) {
	switch (reg_class) {
	case AsmRegClass_Integer: {
		static u32 const nums[] = {19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 9, 10, 11, 12, 13, 14, 15, 0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 17};
		for (u32 num : nums) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_arm64::REG_CLASS_X | num));
		}
		break;
	}
	case AsmRegClass_Float:
	case AsmRegClass_Vector:
		for (u32 i = 0; i < 32; i++) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_arm64::REG_CLASS_V | ((i + 8) % 32)));
		}
		break;
	}
}

gb_internal void asm_call_clobber_families(Asm_riscv *asm_ctx, Array<String> *families) {
	for (u16 num = 1; num < 32; num++) {
		switch (num) {
		case 2: // sp
		case 3: // gp
		case 4: // tp
		case 8: // s0, the frame pointer
			continue;
		}
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_riscv::REG_CLASS_GPR | num));
	}
	for (u16 num = 0; num < 32; num++) {
		array_add(families, asm_register_name_from_code(asm_ctx, Asm_riscv::REG_CLASS_FPR | num));
	}
}
gb_internal void asm_call_pin_candidates(Asm_riscv *asm_ctx, AsmRegClass reg_class, Array<String> *candidates) {
	switch (reg_class) {
	case AsmRegClass_Integer: {
		// s1 to s11, then t0 to t6, then a0 to a7
		static u16 const nums[] = {9, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 5, 6, 7, 28, 29, 30, 31, 10, 11, 12, 13, 14, 15, 16, 17};
		for (u16 num : nums) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_riscv::REG_CLASS_GPR | num));
		}
		break;
	}
	case AsmRegClass_Float:
	case AsmRegClass_Vector: {
		// fs0 to fs11, then ft0 to ft11, then fa0 to fa7
		static u16 const nums[] = {8, 9, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 0, 1, 2, 3, 4, 5, 6, 7, 28, 29, 30, 31, 10, 11, 12, 13, 14, 15, 16, 17};
		for (u16 num : nums) {
			array_add(candidates, asm_register_name_from_code(asm_ctx, Asm_riscv::REG_CLASS_FPR | num));
		}
		break;
	}
	}
}

// NOTE(bill): an output's register is already declared as written, and clobbering it as well
// lets LLVM drop the moves into it of an input tied to that output
template <typename AsmCtx>
gb_internal bool asm_register_family_is_pinned_output(AsmCtx *asm_ctx, Entity *tmpl_entity, String family) {
	for (auto const &ed : tmpl_entity->AsmTemplate.decls) {
		if (ed.param_group != AsmTemplateEntityDeclParamGroup_Output || ed.pin.len == 0) {
			continue;
		}
		if (asm_register_family_name(asm_ctx, ed.pin) == family) {
			return true;
		}
	}
	return false;
}

template <typename AsmCtx>
gb_internal void asm_clobber_written_register(AsmCtx *asm_ctx, Entity *tmpl_entity, String reg_name) {
	String family = asm_register_family_name(asm_ctx, reg_name);
	if (family.len == 0) {
		return;
	}
	if (asm_register_family_is_pinned_output(asm_ctx, tmpl_entity, family)) {
		return;
	}
	string_set_add(&tmpl_entity->AsmTemplate.clobber_registers_set, family);
}

// NOTE(bill): name each register by its family (%eax as rax) so the same register is never named twice;
// a register with no family, such as the stack pointer, keeps its name
template <typename AsmCtx>
gb_internal void asm_normalize_register_names(AsmCtx *asm_ctx, StringSet *set) {
	TEMPORARY_ALLOCATOR_GUARD();
	auto names = array_make<String>(temporary_allocator());
	for (String const &reg : *set) {
		String family = asm_register_family_name(asm_ctx, reg);
		if (family.len == 0) {
			family = reg;
		}
		array_add(&names, family);
	}
	string_set_clear(set);
	for (String const &name : names) {
		string_set_add(set, name);
	}
}

gb_internal bool asm_instruction_is_call(Asm_amd64 *asm_ctx, u16 mnemonic, Asm_amd64::Clobber const &clobber, u16 produced) {
	return mnemonic == Asm_amd64::M_CALL;
}
gb_internal bool asm_instruction_is_call(Asm_arm64 *asm_ctx, u16 mnemonic, Asm_arm64::Clobber const &clobber, u16 produced) {
	// bl, blr, and their authenticated forms write the link register
	return clobber.has_control() && (cast(u32)clobber.implicit_wr & Asm_arm64::ClobberReg_LR) != 0;
}
gb_internal bool asm_instruction_is_call(Asm_riscv *asm_ctx, u16 mnemonic, Asm_riscv::Clobber const &clobber, u16 produced) {
	// jal and jalr are calls when they link through ra, and jumps when they link through zero
	return clobber.has_control() && (produced & Asm_riscv::ClobberReg_RA) != 0;
}

// NOTE(bill): a call returns to the next instruction unless its callee is declared diverging (-> !).
// Nothing is assumed about the callee's calling convention: it may take any register as an argument,
// and every register and flag holds a value once it returns.
template <typename AsmCtx>
gb_internal void check_asm_call_facts(AsmCtx *asm_ctx, Entity *tmpl_entity, AsmInstructionFacts *facts, Slice<Operand> const &operands) {
	bool internal = false;
	bool diverges = false;
	for (auto const &op : operands) {
		if (op.expr->kind == Ast_AsmLabelDecl) {
			internal = true;
			continue;
		}
		Entity *e = entity_of_node(op.expr);
		if (e == nullptr || e->type == nullptr) {
			continue;
		}
		Type *t = base_type(e->type);
		if (t->kind != Type_Proc) {
			continue;
		}
		if (t->Proc.calling_convention == ProcCC_Odin) {
			error(op.expr,
			      "'%.*s' uses the Odin calling convention, whose hidden 'context' argument an 'asm' template cannot pass; "
			      "give it another calling convention, such as \"c\" or \"contextless\"",
			      LIT(e->token.string));
		}
		if (t->Proc.diverging) {
			diverges = true;
		}
	}

	facts->is_call     = true;
	facts->calls_out   = !internal;
	facts->is_terminal = diverges;

	facts->reads_every_register = true;

	facts->gen_regs  |= asm_ctx->CLOBBER_REGS_NAMED;
	facts->gen_flags  = cast(u16)~cast(u16)0;

	u8 full = cast(u8)(build_context.metrics.ptr_size*8);
	for (i32 idx = 0; idx < ASM_WIDTH_REG_COUNT; idx++) {
		if ((asm_ctx->CLOBBER_REGS_NAMED & (1u << idx)) != 0) {
			facts->gen_reg_w.e[idx] = full;
		}
	}

	for (auto const &ed : tmpl_entity->AsmTemplate.decls) {
		if (ed.param_group == AsmTemplateEntityDeclParamGroup_Output && ed.pin.len != 0) {
			array_add(&facts->gen_params, ed.entity);
		}
	}
}

template <typename AsmCtx>
gb_internal void asm_clobber_implicit_vector_registers(AsmCtx *asm_ctx, Entity *tmpl_entity, u32 implicit_wr) {
	// only AMD64 has instructions which implicitly write every vector register
}
gb_internal void asm_clobber_implicit_vector_registers(Asm_amd64 *asm_ctx, Entity *tmpl_entity, u32 implicit_wr) {
	if ((implicit_wr & Asm_amd64::ClobberReg_VECTOR) == 0) {
		return;
	}
	// NOTE(bill): e.g. vzeroall and vzeroupper write %ymm0 to %ymm15
	for (u16 num = 0; num < 16; num++) {
		String name = asm_register_name_from_code(asm_ctx, Asm_amd64::REG_CLASS_XMM | num);
		asm_clobber_written_register(asm_ctx, tmpl_entity, name);
	}
}

// How an operand failed to fit a form's slot, and the widths involved, for a precise diagnostic
struct AsmSlotFit {
	AsmMismatch mismatch;
	i32         want_bits;
	i32         got_bits;
};

// Returns true if the operand's Odin type is size/class-compatible with the form's slot.
// `slot` here is the resolved OperandType at the correct (implicit-skipped) slot.
template <typename AsmCtx>
gb_internal bool check_asm_operand_size_class(AsmCtx *asm_ctx, typename AsmCtx::OperandType slot, Operand const *operand, AsmSlotFit *fit) {
	*fit = {};

	// e.g. `ldr r, #post [p + 8]` fills only a post-indexed slot, and `ldr r, [p + 8]` none.
	// Other targets have no writeback, and report #pre/#post on their own.
	if (build_context.metrics.arch == TargetArch_arm64 && asm_operand_writeback(operand) != asm_slot_writeback(asm_ctx, slot)) {
		fit->mismatch = AsmMismatch_Writeback;
		return false;
	}

	AsmOperandKind slot_kind = asm_ctx->kind_from_operand_type(slot);
	if (slot_kind == AsmOperand_Immediate) {
		fit->want_bits = asm_ctx->operand_type_bit_width(slot); // 32 for OP_IMM32
		if (operand->mode != Addressing_Constant) {
			return true; // $-immediate, bound per instantiation; defer
		}
		return check_asm_immediate_value_fits(operand->value, fit->want_bits, &fit->got_bits, &fit->mismatch);
	}
	Entity *e = entity_of_node(operand->expr);
	if (slot_kind == AsmOperand_Label && e != nullptr && (e->kind == Entity_Procedure || e->kind == Entity_ProcGroup)) {
		return true; // a procedure named in the body, which the assembler resolves like a label
	}

	// Register / memory-sized slots
	AsmRegClass want_class = asm_ctx->operand_type_reg_class(slot);
	i32         want_w     = asm_ctx->operand_type_bit_width(slot);
	Ast *       reg        = operand->expr->kind == Ast_AsmRegister ? operand->expr : nullptr;

	// A slot only a named hardware register can fill (segment/control/debug/x87/MMX)
	// carries no class and, apart from MMX, no width either. Nothing below would
	// reject a template parameter standing in for one.
	u16 want_named = asm_ctx->operand_type_named_reg_class(slot);
	if (want_named != 0) {
		bool ok = false;
		if (reg != nullptr) {
			auto r = asm_ctx->register_lookup(reg->AsmRegister.name.string);
			ok = r && asm_ctx->reg_class(asm_ctx->register_codes[r]) == want_named;
		}
		if (!ok) {
			fit->mismatch = AsmMismatch_NamedReg;
		}
		return ok;
	}

	// An opmask register has no Odin type of its own (it is typed as an integer), so it
	// fills an opmask slot whatever its width, and nothing else.
	if (reg != nullptr && asm_register_is_mask(asm_ctx, reg->AsmRegister.name.string)) {
		if (want_class != AsmRegClass_Mask) {
			fit->mismatch = AsmMismatch_Class;
		}
		return want_class == AsmRegClass_Mask;
	}

	// A pure-label / sizeless slot imposes no reg width/class.
	if (want_class == AsmRegClass_Unknown && want_w == 0) {
		return true;
	}
	fit->want_bits = want_w;

	// Determine the type whose width/class we actually measure.
	//
	// Memory operands encode their *access* type as a pointer: `[p]:u8` -> `^u8`,
	// with a bare `rawptr` meaning "unsized" (no explicit `:type` annotation). A
	// register/immediate/parameter operand measures its own type directly.
	Type *measured  = operand->type;
	bool  is_memory = determine_asm_operand_kind(operand) == AsmOperand_Memory;
	if (is_memory) {
		if (are_types_identical(measured, t_rawptr)) {
			// Unsized memory operand: the width is inferred elsewhere (from the
			// register operand or deferred), so nothing to check against here.
			return true;
		}
		measured = type_deref(measured); // ^u8 -> u8
	}

	AsmRegClass got_class = check_asm_reg_class_from_type(measured);
	i32         got_w     = check_asm_operand_bit_width(measured);
	if (got_w < 0) {
		// Untyped constant: width is a property of the value, not the type.
		if (operand->mode == Addressing_Constant && operand->value.kind == ExactValue_Integer) {
			got_w = gb_max(cast(i32)mp_count_bits(&operand->value.value_integer), 1); // zero still occupies a slot
		} else {
			got_w = 0; // unknown; skip the width comparison rather than fake a pass
		}
	}
	fit->got_bits = got_w;

	// Class check (only when the slot constrains a class).
	//
	// A *memory* operand against a register-or-memory slot (e.g. OP_XMM_M64) has no
	// lane semantics -- it is just N bytes of memory -- so its integer/vector class
	// must not be held against the slot's register class. Only width matters for the
	// memory interpretation. Register operands still get the full class check.
	bool is_lane = asm_ctx->operand_type_is_lane(slot);
	if (want_class != AsmRegClass_Unknown && !is_memory && !is_lane && !asm_reg_class_compatible(want_class, got_class)) {
		fit->mismatch = AsmMismatch_Class;
		return false;
	}

	// Width check.
	bool width_ok = true;
	if (want_w != 0 && got_w != 0) {
		if (want_class == AsmRegClass_Vector && !is_memory) {
			// A scalar float uses only the low lane, so it may be narrower than the
			// slot; a #simd vector or a lane element must match the width exactly.
			width_ok = (got_class == AsmRegClass_Float && !is_lane) ? got_w <= want_w : got_w == want_w;
		} else if (!is_memory &&
		           ((want_class == AsmRegClass_Float && got_class == AsmRegClass_Float && !asm_ctx->float_reg_width_is_exact()) ||
		            (want_class == AsmRegClass_Integer && !asm_ctx->integer_reg_width_is_exact()))) {
			// NOTE(bill): architectures such as RISC-V have registers which are
			// always the architecture width
			width_ok = got_w <= want_w;
		} else {
			// Integer/mask registers on exact-width targets, and all memory operands.
			width_ok = got_w == want_w;
		}
	}
	if (!width_ok) {
		fit->mismatch = AsmMismatch_Size;
	}
	return width_ok;
}


enum AsmAddrRole {
	AsmAddr_Base,
	AsmAddr_Index,
};

// Validate that a resolved base/index operand is a 32- or 64-bit integer register.
// `reg_name` is the literal register string when the operand was an AstAsmRegister
// (so rsp/esp-as-index can be caught), else the empty string.
gb_internal bool check_asm_addr_register(Operand const *operand, AsmAddrRole role, String reg_name, i32 *width_) {
	char const *role_name = (role == AsmAddr_Base) ? "base" : "index";

	AsmRegClass cls = check_asm_reg_class_from_type(operand->type);
	i32         w   = check_asm_operand_bit_width(operand->type);
	if (width_) *width_ = w;

	if (cls != AsmRegClass_Integer) {
		char const *got = "non-integer";
		if (cls == AsmRegClass_Vector) {
			got = "vector";
		} else if (cls == AsmRegClass_Mask) {
			got = "mask";
		}
		error(operand->expr, "A memory operand's %s must be an integer register, got a %s value", role_name, got);
		return false;
	}
	if (w != 32 && w != 64) {
		error(operand->expr, "A memory operand's %s must be a 32-bit or 64-bit register, got a %d-bit register", role_name, cast(int)w);
		return false;
	}
	if (role == AsmAddr_Index && reg_name.len != 0) {
		if (build_context.metrics.arch == TargetArch_amd64) {
			// TODO(bill): This is a complete bodge for AMD64, and I need to see if regnalize this further
			// rsp/esp cannot be encoded as an index register.
			if (reg_name == "rsp" || reg_name == "esp") {
				error(operand->expr, "%%%.*s cannot be used as an index register", LIT(reg_name));
				return false;
			}
		}
	}
	return true;
}


gb_internal Type *check_asm_template_signature_params(CheckerContext *ctx, Scope *scope, Ast *_params, bool input_parameters, Array<AsmTemplateEntityDecl> *asm_template_entity_decls) {
	Type *tuple = alloc_type_tuple();
	if (_params == nullptr) {
		return tuple;
	}
	ast_node(field_list, FieldList, _params);
	Slice<Ast *> params = field_list->list;

	Array<Entity *> variables = {};
	variables.allocator = heap_allocator();

	i32 param_index = 0;
	for (Ast *param : params) {
		ast_node(field, Field, param);

		bool prev = ctx->allow_polymorphic_types;
		ctx->allow_polymorphic_types = false;
		Type *type = check_type(ctx, field->type);
		ctx->allow_polymorphic_types = prev;

		if (!check_asm_parameter_type(field->type, type)) {
			continue;
		}

		for_array(j, field->names) {
			Ast *name = field->names[j];

			bool is_poly_name = false;

			switch (name->kind) {
			case Ast_Ident:
				break;
			case Ast_PolyType:
				GB_ASSERT(name->PolyType.specialization == nullptr);
				is_poly_name = true;
				name = name->PolyType.type;
				break;
			}

			if (!ast_node_expect(name, Ast_Ident)) {
				continue;
			}

			if (is_blank_ident(name)) {
				error(name, "All parameters must have a name in an asm template");
				continue;
			}
			Token name_token = name->Ident.token;

			Entity *entity = alloc_entity_param(scope, name_token, type, false, /*is_value*/true);
			if (is_poly_name) {
				entity->flags |= EntityFlag_PolyConst;
				if (is_type_internally_pointer_like(type)) {
					error(name, "Parameters with a pointer-like type cannot be used as $ immediates");
				}
			}

			Entity *found = scope_insert(scope, entity);
			if (found != nullptr) {
				check_asm_redeclaration_error(name_token, found);
				continue;
			}
			array_add(&variables, entity);

			AsmTemplateEntityDecl ed = asm_template_entity_decl_default(entity);
			if (is_poly_name) {
				ed.kind = AsmTemplateEntityDecl_Immediate;
			}
			if (input_parameters) {
				ed.param_group = AsmTemplateEntityDeclParamGroup_Input;
				ed.param_index = param_index++;
				ed.result_index = -1;
			} else {
				ed.param_group = AsmTemplateEntityDeclParamGroup_Output;
				ed.param_index  = -1;
				ed.result_index = param_index++;
			}

			ed.total_index = cast(i32)asm_template_entity_decls->count;
			array_add(asm_template_entity_decls, ed);
		}
	}

	tuple->Tuple.variables = slice_from_array(variables);

	return tuple;
}

gb_internal AsmTemplateEntityDecl *check_asm_find_decl(Entity *entity, Array<AsmTemplateEntityDecl> const &decls) {
	for_array(i, decls) {
		if (decls.data[i].entity == entity) {
			return &decls.data[i];
		}
	}
	return nullptr;
}

gb_internal AsmTemplateEntityDeclKind check_asm_find_kind(Entity *entity, Array<AsmTemplateEntityDecl> const &decls) {
	AsmTemplateEntityDecl *ed = check_asm_find_decl(entity, decls);
	return ed ? ed->kind : AsmTemplateEntityDecl_Invalid;
}

// NOTE(bill): LLVM forbids writing an input-only operand.
// An input the template writes, itself or through a width-view, is tied to a discarded output.
gb_internal void check_asm_mark_input_written(Array<AsmTemplateEntityDecl> const &decls, AsmTemplateEntityDecl *ed) {
	if (ed != nullptr && ed->view_of >= 0) {
		ed = &decls.data[ed->view_of];
	}
	if (ed != nullptr && ed->param_group == AsmTemplateEntityDeclParamGroup_Input && ed->tie < 0) {
		ed->overwritten = true;
	}
}

gb_internal bool check_asm_is_immediate_param(Entity *tmpl_entity, Operand const *o) {
	Entity *pe = entity_of_node(o->expr);
	if (pe != nullptr && pe->kind == Entity_Variable) {
		return check_asm_find_kind(pe, tmpl_entity->AsmTemplate.decls) == AsmTemplateEntityDecl_Immediate;
	}
	return false;
}

// NOTE(bill): a template opting in to a feature with @(require_target_feature) or @(enable_target_feature)
// must not be rejected because the global build did not enable it
gb_internal bool check_asm_template_feature_is_enabled(Entity *tmpl_entity, String const &feature) {
	if (check_target_feature_is_enabled(feature, nullptr)) {
		return true;
	}
	Type *pt = tmpl_entity->AsmTemplate.proc_type;
	GB_ASSERT(pt->kind == Type_Proc);
	String req = pt->Proc.require_target_feature;
	String en  = pt->Proc.enable_target_feature;

	if (req.len != 0 && check_target_feature_is_superset_of(req, feature, nullptr)) {
		return true;
	}
	if (en.len != 0 && check_target_feature_is_superset_of(en, feature, nullptr)) {
		return true;
	}
	return false;
}


template <typename AsmCtx>
gb_internal void check_asm_specs(AsmCtx *asm_ctx, CheckerContext *ctx, Scope *scope, Slice<Ast *> const &specs, Array<AsmTemplateEntityDecl> *asm_template_entity_decls) {
	StringSet pin_set = {};
	string_set_init(&pin_set, specs.count);
	defer (string_set_destroy(&pin_set));

	StringSet pin_flag_set = {};
	string_set_init(&pin_flag_set, specs.count);
	defer (string_set_destroy(&pin_flag_set));

	for (Ast *spec_ : specs) {
		if (spec_->kind != Ast_AsmSpec) {
			continue;
		}
		ast_node(spec, AsmSpec, spec_);

		GB_ASSERT(spec->name->kind == Ast_Ident);

		Entity *input = scope_lookup_current(scope, spec->name->Ident.interned, spec->name->Ident.hash);
		add_entity_use(ctx, spec->name, input);

		Entity *other_scratch = nullptr;

		String pin = {};
		String pin_flag = {};
		AsmRegClass pin_reg_class = AsmRegClass_Unknown;
		i32         pin_reg_w     = 0;
		if (spec->value != nullptr) {
			if (spec->value->kind == Ast_Ident) {
				other_scratch = scope_lookup_current(scope, spec->value->Ident.interned, spec->value->Ident.hash);
				if (other_scratch) {
					add_entity_use(ctx, spec->value, other_scratch);
					if (check_asm_find_decl(other_scratch, *asm_template_entity_decls) == nullptr) {
						error(spec->value, "This must be another parameter, got %.*s", LIT(other_scratch->token.string));
					}
				} else {
					error(spec->value, "Undefined parameter declaration '%.*s'", LIT(spec->value->Ident.token.string));
				}
			} else {
				if (spec->value->kind != Ast_AsmRegister) {
					gbString s = expr_to_string(spec->value);
					error(spec->value, "Expected an asm register or scratch parameter, got %s", s);
					gb_string_free(s);
					continue;
				}

				ast_node(reg, AsmRegister, spec->value);
				pin = reg->name.string;
				if (pin.len != 0) {
					Operand op = {};
					if (check_register(asm_ctx, &op, reg)) {
						if (reg->flag.string.len != 0) {
							GB_ASSERT(pin == "flags");
							pin_flag = reg->flag.string;
							if (string_set_update(&pin_flag_set, pin_flag)) {
								error(spec->value, "Pinned register flag %%%.*s.%.*s has already been assigned", LIT(pin), LIT(pin_flag));
							}
						}
						if (string_set_update(&pin_set, pin) && pin != "flags") {
							error(spec->value, "Pinned register %%%.*s has already been assigned", LIT(pin));
						}
						if (reg->flag.string.len == 0) {
							pin_reg_class = check_asm_reg_class_from_type(op.type);
							pin_reg_w     = check_asm_operand_bit_width(op.type);
						}
					}
				}
			}
		}

		if (spec->tied_name == nullptr) {
			if (spec->type != nullptr) {
				Type *type = check_type(ctx, spec->type);
				if (!check_asm_parameter_type(spec->type, type)) {
					continue;
				}

				Token name_token = spec->name->Ident.token;

				Entity *entity = alloc_entity_param(scope, name_token, type, false, /*is_value*/true);
				entity->flags |= EntityFlag_Used;

				Entity *found = scope_insert(scope, entity);
				if (found == nullptr) {
					AsmTemplateEntityDecl ed = asm_template_entity_decl_default(entity);
					ed.param_group = AsmTemplateEntityDeclParamGroup_Scratch;
					ed.total_index = cast(i32)asm_template_entity_decls->count;
					ed.pin = pin;
					ed.pin_flag = pin_flag;
					if (pin.len != 0) {
						check_asm_pin_type_compat(pin_reg_class, pin_reg_w, type, spec->value, pin,
						                          spec->name->Ident.token.string);
					}

					if (other_scratch != nullptr) {
						// Width-view of another operand: `p0b: u8 = p0`.
						// p0b shares p0's register, viewed at p0b's declared width.
						AsmTemplateEntityDecl *src = check_asm_find_decl(other_scratch, *asm_template_entity_decls);

						// 1. The source must already exist and be a register-class operand
						//    (you cannot take a width-view of an immediate or memory operand).
						if (src == nullptr) {
							error(spec->value, "'%.*s' must refer to a previously declared parameter", LIT(other_scratch->token.string));
						} else {
							if (src->kind == AsmTemplateEntityDecl_Immediate || src->kind == AsmTemplateEntityDecl_Memory) {
								error(spec->value, "A width-view can only be taken of a register operand, not '%.*s'", LIT(other_scratch->token.string));
							}

							// 2. The view width must be a legal sub-register width and no wider
							//    than the source (only narrowing views exist).
							i32 view_w = check_asm_operand_bit_width(type);          // this decl's type (u8 -> 8)
							i32 src_w  = check_asm_operand_bit_width(src->entity->type);
							AsmRegClass view_class = check_asm_reg_class_from_type(type);
							AsmRegClass src_class  = check_asm_reg_class_from_type(src->entity->type);

							if (view_class != AsmRegClass_Integer || src_class != AsmRegClass_Integer) {
								error(spec->type, "Width-views are only supported for integer registers");
							} else {
								switch (view_w) {
								case 8: case 16: case 32: case 64:
									if (view_w > src_w) {
										error(spec->type, "A width-view (%d-bit) cannot be wider than its source '%.*s' (%d-bit)",
										      cast(int)view_w, LIT(other_scratch->token.string), cast(int)src_w);
									}
									break;
								default:
									error(spec->type, "A width-view must be an 8, 16, 32, or 64-bit integer type, got a %d-bit type", cast(int)view_w);
									break;
								}
							}

							// 3. A view does not carry its own pin; it inherits the source's register.
							if (pin.len != 0) {
								error(spec->value, "A width-view cannot also be pinned to a register; it inherits the source operand's register");
							}

							ed.kind       = AsmTemplateEntityDecl_Register;
							ed.view_of    = src->total_index;
							ed.view_bits  = view_w;
							// A view is not itself an input/output/scratch slot for allocation:
							// mark it so the lowering passes skip it. Reuse the Scratch group but
							// with view_of >= 0 as the discriminator (see lowering note).
						}
					}

					if (other_scratch == nullptr && check_asm_reg_class_from_type(type) != AsmRegClass_Unknown) {
						ed.kind = AsmTemplateEntityDecl_Register;
					}

					array_add(asm_template_entity_decls, ed);
				} else {
					check_asm_redeclaration_error(name_token, found);
					continue;
				}
			} else if (input == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			} else {
				AsmTemplateEntityDecl *i = check_asm_find_decl(input, *asm_template_entity_decls);
				GB_ASSERT(i != nullptr);
				if (i->pin.len == 0) {
					i->pin = pin;
					i->pin_flag = pin_flag;
					if (pin_flag.len != 0 && i->param_group != AsmTemplateEntityDeclParamGroup_Output) {
						error(spec->value, "Input parameters cannot be pinned to a flag style register");
					} else if (pin.len != 0 && pin_flag.len == 0) {
						check_asm_pin_type_compat(pin_reg_class, pin_reg_w, input->type, spec->value, pin,
						                          input->token.string);
					}
				} else {
					error(spec_, "Asm register has already been pinned");
				}

				if (other_scratch != nullptr) {
					error(spec->value, "Another parameter must be assigned/paired with a scratch parameter declaration");
				}
			}
		} else {
			GB_ASSERT(spec->tied_name->kind == Ast_Ident);

			if (spec->type != nullptr) {
				error(spec->type, "Tied register definitions cannot have a defined type since the values are already defined");
			}

			if (input == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			}
			Entity *output = scope_lookup_current(scope, spec->tied_name->Ident.interned, spec->tied_name->Ident.hash);
			if (output == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			}

			AsmTemplateEntityDecl *i = check_asm_find_decl(input,  *asm_template_entity_decls);
			AsmTemplateEntityDecl *o = check_asm_find_decl(output, *asm_template_entity_decls);
			if (i == nullptr || i->param_group != AsmTemplateEntityDeclParamGroup_Input) {
				error(input->token, "Parameter tied with '%.*s' must be an input parameter", LIT(output->token.string));
				continue;
			}
			if (o == nullptr || o->param_group != AsmTemplateEntityDeclParamGroup_Output) {
				error(output->token, "Parameter tied with '%.*s' must be an output parameter", LIT(input->token.string));
				continue;
			}

			i->tie = o->total_index;
			o->tie = i->total_index;

			i->pin = pin;
			o->pin = pin;
			if (pin.len != 0) {
				check_asm_pin_type_compat(pin_reg_class, pin_reg_w, input->type,  spec->value, pin, input->token.string);
				check_asm_pin_type_compat(pin_reg_class, pin_reg_w, output->type, spec->value, pin, output->token.string);
			}
			// Tied parameters share one physical register, so they must be the same register family (both integer, or both vector/float).
			// Width may legitimately differ (a narrow read feeding a wide write), so width is intentionally NOT checked.
			bool input_is_int  = check_asm_reg_class_from_type(input->type)  == AsmRegClass_Integer;
			bool output_is_int = check_asm_reg_class_from_type(output->type) == AsmRegClass_Integer;
			if (input_is_int != output_is_int) {
				error(spec->name, "Tied parameters '%.*s' and '%.*s' share a register but are in different register classes",
				      LIT(input->token.string), LIT(output->token.string));
			}

			if (other_scratch != nullptr) {
				error(spec->value, "Another parameter must be assigned/paired with a scratch parameter declaration, not a tie");
			}

			if (pin_flag.len != 0) {
				error(spec->value, "Input parameters, and thus tied parameters, cannot be pinned to a flag style register");
			}
		}


		for (Ast *dir_ : spec->directives) {
			ast_node(dir, BasicDirective, dir_);
			String name = dir->name.string;
			if (name == "no_init") {
				if (AsmTemplateEntityDecl *i = check_asm_find_decl(input, *asm_template_entity_decls)) {
					i->no_init = true;
					if (i->tie >= 0) {
						(*asm_template_entity_decls)[i->tie].no_init = true;
					}
				}
			} else {
				error(dir_, "Invalid directive for an asm specification, got '#%.*s'", LIT(name));
			}
		}
	}
}

template <typename AsmCtx>
gb_internal bool check_register(AsmCtx *asm_ctx, Operand *operand, AstAsmRegister *asm_reg) {
	String name = asm_reg->name.string;
	if (asm_reg->flag.kind == Token_Ident) {
		bool ok = true;
		i32 width = 0;

		String flag = asm_reg->flag.string;
		if (name != "flags") {
			error(asm_reg->name, "Register flags can only be called on %%flags");
			ok = false;
		} else {
			i32 bit = asm_ctx->flag_bit_from_name(flag, &width);
			if (bit < 0) {
				error(asm_reg->flag, "Unknown register %%flags name: %.*s", LIT(flag));
				ok = false;
			}
		}

		operand->type = t_bool;
		if (width > 1) {
			operand->type = t_u8;
		}
		return ok;
	}

	auto r = asm_ctx->register_lookup(name);
	if (r) {
		operand->mode = Addressing_Value;

		u16 width_in_bits = asm_ctx->reg_size(r);
		switch (width_in_bits) {
		case 0:
			// a register whose class the width table cannot describe, `%rip` being the only one.
			// anchored on the name rather than the operand, which clobbers and pins do not have
			error(asm_reg->name, "Asm registers with no operand width are not supported: %%%.*s", LIT(name));
			return false;
		case 8:
			operand->type = t_u8;
			break;
		case 16:
			operand->type = t_u16;
			break;
		case 32:
			operand->type = t_u32;
			break;
		case 64:
			operand->type = t_u64;
			break;
		case 80:
			error(asm_reg->name, "80-bit width asm registers are not supported");
			return false;
		case 128:
			operand->type = alloc_type_simd_vector(4, t_f32);
			break;
		case 256:
			operand->type = alloc_type_simd_vector(8, t_f32);
			break;
		case 512:
			operand->type = alloc_type_simd_vector(16, t_f32);
			break;
		default:
			error(asm_reg->name, "%d-bit width asm registers are not supported", width_in_bits);
			return false;
		}

		return true;
	}

	ERROR_BLOCK();
	error(asm_reg->name, "Unknown register for this target platform: %%%.*s", LIT(name));
	{
		auto dym = did_you_mean_make(heap_allocator(), asm_ctx->register_map.count, name);
		defer (did_you_mean_destroy(&dym));
		for (auto const &entry : asm_ctx->register_map) {
			did_you_mean_append(&dym, entry.key);
		}
		check_did_you_mean_print(&dym);
	}
	return false;
}

enum CheckMnemomicResult {
	CheckMnemomic_Invalid,
	CheckMnemomic_Mnemonic,
	CheckMnemomic_PseudoMnemonic,
	CheckMnemomic_PseudoMacroMnemonic,
	CheckMnemomic_Prefix,
};

template <typename AsmCtx>
gb_internal bool check_pseudo_macro_mnemonic(AsmCtx *asm_ctx, Entity *tmpl_entity,
                                             AstAsmInstruction *instr, Slice<Operand> const &operands) {
	if (build_context.metrics.arch != TargetArch_riscv64) {
		return false;
	}

	/*
		NOTE(bill): this is probably not even a complete list when it comes to
		of the pseudo macro mnemonics, but this currently covers most of them.
		It just handles those edge cases directly as the LLVM assembler will
		handle them directly any way.
	*/

	int const XLEN = cast(int)(build_context.metrics.ptr_size*8);

	String name = instr->name->Ident.token.string;

	auto want_int_reg = [&](Operand const *o, char const *role) {
		if (determine_asm_operand_kind(o) != AsmOperand_Register ||
		    check_asm_reg_class_from_type(o->type) != AsmRegClass_Integer) {
			error(o->expr, "'%.*s' %s must be an integer register", LIT(name), role);
			return false;
		}
		int width = check_asm_operand_bit_width(o->type);
		if (width > XLEN) {
			error(o->expr, "'%.*s' %s is wider than the %d-bit register width, got %d-bits", LIT(name), role, XLEN, width);
			return false;
		}
		return true;
	};

	if (name != "li" && name != "la" && name != "lla") {
		return false;
	}
	if (operands.count != 2) {
		error(instr->name, "'%.*s' expects 2 operands, got %td", LIT(name), operands.count);
		return true; // NOTE(bill): it exists but incorrectly handled
	}
	want_int_reg(&operands[0], "destination");

	if (name == "li") { // li rd, imm  — dest reg + assemble-time integer that fits XLEN (or a $-immediate)
		Operand const *imm = &operands[1];
		if (imm->mode == Addressing_Constant) {
			ExactValue ev = exact_value_to_integer(imm->value);
			if (ev.kind != ExactValue_Integer) {
				error(imm->expr, "'%.*s' immediate must be an integer constant", LIT(name));
				return true;
			}
			AsmMismatch m = AsmMismatch_None; i32 needed = 0;
			if (!check_asm_immediate_value_fits(ev, XLEN, &needed, &m)) {
				gbString vs = exact_value_to_string(ev);
				error(imm->expr, "'%.*s' immediate %s does not fit in a %d-bit register (needs %d bits)", LIT(name), vs, XLEN, needed);
				gb_string_free(vs);
			}
		} else if (!check_asm_is_immediate_param(tmpl_entity, imm)) {
			error(imm->expr, "'li' source must be a constant integer or a $ immediate parameter");
		}
	} else if (determine_asm_operand_kind(&operands[1]) != AsmOperand_Label) { // la / lla rd, symbol  — dest reg + a label
		error(operands[1].expr, "'%.*s' source must be a label", LIT(name));
	}
	return true;
}

template <typename AsmCtx>
gb_internal CheckMnemomicResult check_mnemonic_name(AsmCtx *asm_ctx, AstAsmInstruction *instr, u16 *mnemonic_, u8 *suffix_flags_) {
	Token token = instr->name->Ident.token;
	GB_ASSERT_MSG(token.kind == Token_Ident || token_is_keyword(token.kind), "got %.*s of kind %.*s", LIT(token.string), LIT(token_strings[token.kind]));
	String name = token.string;
	if (auto p = asm_ctx->prefix_lookup(name)) {
		*mnemonic_ = cast(u16)p;
		return CheckMnemomic_Prefix;
	}
	if (auto m = asm_ctx->mnemonic_lookup(name)) {
		*mnemonic_ = cast(u16)m;
		return CheckMnemomic_Mnemonic;
	}
	if (auto pm = asm_ctx->pseudo_mnemonic_lookup(name)) {
		*mnemonic_ = cast(u16)pm;
		return CheckMnemomic_PseudoMnemonic;
	}
	if (auto om = asm_ctx->mnemonic_lookup_ordered(name, suffix_flags_)) {
		*mnemonic_ = cast(u16)om;
		return CheckMnemomic_Mnemonic;
	}
	if (auto pmm = asm_ctx->pseudo_macro_mnemonic_lookup(name)) {
		*mnemonic_ = cast(u16)pmm;
		return CheckMnemomic_PseudoMacroMnemonic;
	}

	ERROR_BLOCK();
	if (instr->operands.count == 0) {
		error(instr->name, "Unknown mnemonic/prefix for this target platform: %.*s", LIT(name));
	} else {
		error(instr->name, "Unknown mnemonic for this target platform: %.*s", LIT(name));

	}
	auto dym = did_you_mean_make(heap_allocator(), asm_ctx->MNEMONIC_COUNT, name);
	defer (did_you_mean_destroy(&dym));
	for (u16 i = asm_ctx->M_INVALID+1; i < asm_ctx->MNEMONIC_COUNT; i++) {
		String str = asm_ctx->mnemonic_strings[i];
		did_you_mean_append(&dym, str);
	}
	if (instr->operands.count == 0) {
		for (u16 i = asm_ctx->PREFIX_INVALID+1; i < asm_ctx->PREFIX_COUNT; i++) {
			String str = asm_ctx->prefix_strings[i];
			did_you_mean_append(&dym, str);
		}
	}
	check_did_you_mean_print(&dym);
	return CheckMnemomic_Invalid;
}

gb_internal bool check_asm_instr_targets_internal_label(AstAsmInstruction *instr) {
	for (Ast *op : instr->operands) {
		if (op->kind == Ast_AsmLabelDecl) {
			return true; // resolved against label_scope during operand checking
		}
	}
	return false;
}


template <typename AsmCtx>
gb_internal void check_operand_constraints(AsmCtx *asm_ctx, Slice<Operand> const &operands, u16 mnemonic, String const &name) {
	i32 word_bits = cast(i32)(build_context.metrics.ptr_size * 8);

	// Value-range constraints (shift-count in range, non-zero divisor). Every mnemonic
	// decision lives in asm_ctx->operand_value_constraint; the logic below names none.
	for_array(i, operands) {
		Operand const *op = &operands[i];
		if (op->mode != Addressing_Constant) {
			continue; // register count (cl/rs2) or $-immediate: not knowable here
		}
		ExactValue ev = exact_value_to_integer(op->value);
		if (ev.kind != ExactValue_Integer) {
			continue;
		}

		AsmOperandConstraint c = asm_ctx->operand_value_constraint(mnemonic, cast(int)i);
		switch (c.kind) {
		case AsmOperandConstraint_ShiftCount: {
			i32 width = 0;
			if (c.width_operand < 0) {
				width = word_bits;
			} else if (c.width_operand < operands.count) {
				width = check_asm_operand_bit_width(operands[c.width_operand].type);
			}
			if (width <= 0) {
				break; // unknown target width; nothing to compare against
			}
			mp_int const *v = &ev.value_integer;
			bool too_big = mp_count_bits(v) > 63;
			i64  count   = too_big ? 0 : exact_value_to_i64(ev);
			if (mp_isneg(v) || too_big || count >= width) {
				gbString vs = exact_value_to_string(ev);
				error(op->expr, "'%.*s' shift count %s is out of range for the %d-bit operand (must be 0..<%d)",
				      LIT(name), vs, cast(int)width, cast(int)width);
				gb_string_free(vs);
			}
		} break;

		case AsmOperandConstraint_NonZeroDivisor:
			if (mp_iszero(&ev.value_integer)) {
				error(op->expr, "'%.*s' divides by a constant zero", LIT(name));
			}
			break;

		case AsmOperandConstraint_None:
			break;
		}
	}
}

template <typename AsmCtx>
gb_internal bool check_mnemonic(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *tmpl_entity, AstAsmInstruction *instr,
                                u16 mnemonic, u16 pseudo_mnemonic, Slice<Operand> const &operands,
                                u8 previous_prefix, Ast *previous_prefix_instr,
                                AsmCfg *cfg) {
	GB_ASSERT(mnemonic > 0);
	auto   forms         = asm_ctx->encoding_forms(mnemonic);
	auto   clobber_forms = asm_ctx->clobber_forms(mnemonic);
	String name          = asm_ctx->mnemonic_strings[mnemonic];

	auto alias = asm_ctx->pseudo_alias(cast(u16)pseudo_mnemonic);
	if (pseudo_mnemonic) {
		name = asm_ctx->pseudo_mnemonic_strings[pseudo_mnemonic];
	}

	AsmInstructionFacts *facts = gb_alloc_item(permanent_allocator(), AsmInstructionFacts);
	facts->node = instr;
	facts->name = name;
	facts->gen_params.allocator  = heap_allocator();
	facts->read_params.allocator = heap_allocator();

	defer ({
		for (auto const &op : operands) {
			if (op.expr->kind != Ast_AsmLabelDecl) {
				continue;
			}
			Entity *e = op.expr->AsmLabelDecl.name->Ident.entity;
			if (e == nullptr || e->kind != Entity_Label) {
				continue;
			}
			facts->branch_target = e;
			break;
		}

		instr->facts = facts;
	});


	bool is_pseudo             = pseudo_mnemonic != 0;
	int  target_explicit_count = is_pseudo ? alias.nargs : -1;

	auto form_user_operand_count = [&](typename AsmCtx::Encoding const &form) -> int {
		int count = is_pseudo ? target_explicit_count : cast(int)form.explicit_count();
		GB_ASSERT_MSG(count <= 4, "%d", count);
		return gb_max(count, 0);
	};

	auto pseudo_alias_arg_operand_index = [](AsmCtx *asm_ctx, auto a, int arg_index) -> int {
		if (arg_index < 0 || arg_index > 2) {
			return -1;
		}
		auto want = cast(typename AsmCtx::AliasSrc)(asm_ctx->AliasSrc_ARG0 + arg_index);
		for (int i = 0; i < gb_count_of(a.src); i++) {
			if (a.src[i] == want) {
				return i;
			}
		}
		return -1;
	};

	auto user_operand_target_index = [&](int user_i) -> int {
		if (!is_pseudo) {
			return user_i;
		}
		return pseudo_alias_arg_operand_index(asm_ctx, alias, user_i);
	};

	auto operand_slot_type = [&](typename AsmCtx::Encoding const &form, int user_index) -> typename AsmCtx::OperandType {
		int raw_slot = -1;
		if (is_pseudo) {
			raw_slot = user_operand_target_index(user_index);
		} else {
			raw_slot = asm_ctx->form_explicit_slot(form, user_index);
		}
		if (0 <= raw_slot && raw_slot < cast(int)gb_count_of(form.ops)) {
			return form.ops[raw_slot];
		}
		return asm_ctx->OP_NONE;
	};

	auto describe_form = [&](typename AsmCtx::Encoding const &form, typename AsmCtx::Clobber const &clobber, isize max_count) -> gbString {
		gbString s = gb_string_make(heap_allocator(), "");
		int count = form_user_operand_count(form);
		for (int i = 0; i < count; i++) {
			auto slot = operand_slot_type(form, i);
			AsmOperandKind k = asm_ctx->kind_from_operand_type(slot);
			AsmRegClass    c = asm_ctx->operand_type_reg_class(slot);
			i32            w = asm_ctx->operand_type_bit_width(slot);

			if (k == AsmOperand_Label) {
				s = gb_string_appendc(s, "label");
			} else if (k == AsmOperand_Immediate) {
				s = (w > 0) ? gb_string_append_fmt(s, "imm%d", cast(int)w)
				            : gb_string_appendc(s, "imm");
			} else {
				char const *reg = "reg";
				switch (c) {
				case AsmRegClass_Integer: reg = "r";   break;
				case AsmRegClass_Float:   reg = "f";   break;
				case AsmRegClass_Vector:  reg = "v";   break;
				case AsmRegClass_Mask:    reg = "k";   break;
				default:                  reg = "reg"; break;
				}
				switch (k) {
				case AsmOperand_Register:
					s = (w > 0) ? gb_string_append_fmt(s, "%s%d", reg, cast(int)w)
					            : gb_string_appendc(s, reg);
					break;
				case AsmOperand_Lane:
					s = (w > 0) ? gb_string_append_fmt(s, "v%d[i]", cast(int)w)
					            : gb_string_appendc(s, "v[i]");
					break;
				case AsmOperand_Memory:
					if (AsmMemoryOperandKind wb = asm_slot_writeback(asm_ctx, slot)) {
						s = gb_string_append_fmt(s, "#%s ", asm_writeback_names[wb]);
					}
					s = (w > 0) ? gb_string_append_fmt(s, "m%d", cast(int)w)
					            : gb_string_appendc(s, "m");
					break;
				case AsmOperand_Register_Or_Memory:
					s = (w > 0) ? gb_string_append_fmt(s, "%s/m%d", reg, cast(int)w)
					            : gb_string_append_fmt(s, "%s/m", reg);
					break;
				case AsmOperand_RegisterShift:
					s = (w > 0) ? gb_string_append_fmt(s, "%s%d{,sh}", reg, cast(int)w)
					            : gb_string_append_fmt(s, "%s{,sh}", reg);
					break;
				default:
					s = gb_string_appendc(s, "operand");
					break;
				}
			}

			if (i+1 < count) {
				s = gb_string_appendc(s, ", ");
			}

			if (max_count > 1) {
				switch (k) {
				case AsmOperand_Label: // 5 characters
					break;
				case AsmOperand_Immediate: // 3+ characters
				case AsmOperand_Register_Or_Memory:
					if (w == 0) {
						s = gb_string_appendc(s, "   ");
					} else if (w < 10) {
						s = gb_string_appendc(s, "  ");
					} else if (w < 100) {
						s = gb_string_appendc(s, " ");
					}
					break;
				case AsmOperand_Register: // 1+ characters
				case AsmOperand_Lane:
				case AsmOperand_Memory:
					if (w == 0) {
						s = gb_string_appendc(s, "    ");
					} else if (w < 10) {
						s = gb_string_appendc(s, "   ");
					} else if (w < 100) {
						s = gb_string_appendc(s, "  ");
					} else {
						s = gb_string_appendc(s, " ");
					}
					break;
				case AsmOperand_RegisterShift: // "<reg><w>{,sh}" — 5 trailing chars beyond the register arm
					if (w == 0) {
						s = gb_string_appendc(s, " ");
					}
					break;
				}
			}
		}
		bool all_implicit = true;
		for (int i = 0; i < count; i++) {
			auto slot = operand_slot_type(form, i);
			AsmOperandKind k = asm_ctx->kind_from_operand_type(slot);
			switch (k) {
			case AsmOperand_Label:
			case AsmOperand_Register:
			case AsmOperand_RegisterShift:
			case AsmOperand_Lane:
			case AsmOperand_Memory:
			case AsmOperand_Register_Or_Memory:
				all_implicit = false;
				break;
			case AsmOperand_Immediate:
				break;
			}

			if (!all_implicit) {
				break;
			}
		}
		if (all_implicit) {
			auto print_set = [&](char const *name, u16 bits) {
				if (bits == 0) {
					return;
				}
				int count = 0;
				s = gb_string_appendc(s, " ");
				s = gb_string_appendc(s, name);
				s = gb_string_appendc(s, "={");
				for (u16 bit = 1; bit != 0; bit <<= 1) {
					if ((bits & bit) == 0) {
						continue;
					}
					char const *rname = asm_ctx->clobber_reg_bit_name(bit);
					if (count++ > 0) {
						s = gb_string_appendc(s, ", ");
					}
					s = gb_string_appendc(s, rname);
				}
				s = gb_string_appendc(s, "}");
			};

			u16 implicit_wr = clobber.implicit_wr & asm_ctx->CLOBBER_REGS_NAMED;
			u16 implicit_rd = clobber.implicit_rd & asm_ctx->CLOBBER_REGS_NAMED;

			u16 implicit_rw = implicit_wr | implicit_rd;

			if (implicit_rw != 0) {
				s = gb_string_appendc(s, "         //");
			}

			implicit_wr &= ~implicit_rw;
			implicit_rd &= ~implicit_rw;

			print_set("read/writes", implicit_rw);
			print_set("writes",      implicit_wr);
			print_set("reads",       implicit_rd);
		}


		return s;
	};

	auto print_closest_form = [&](isize form_index) {
		if (form_index < 0) {
			return;
		}

		gbString desc = describe_form(forms[form_index], clobber_forms[form_index], 1);
		defer (gb_string_free(desc));
		String line = make_string(cast(u8 const *)desc, gb_string_length(desc));
		line = string_trim_trailing_whitespace(line);
		if (line.len == 0) {
			error_line("\tClosest form: '%.*s'\n", LIT(name));
		} else {
			error_line("\tClosest form: '%.*s %.*s'\n", LIT(name), LIT(line));
		}
	};

	auto print_possible_forms = [&]() {
		Array<gbString> lines = {};
		lines.allocator = heap_allocator();
		defer (array_free(&lines));
		defer (
			for_array(i, lines) {
				gb_string_free(lines[i]);
			}
		);

		for_array(fi, forms) {
			gbString desc = describe_form(forms[fi], clobber_forms[fi], forms.count);
			bool dup = false;
			for (auto const &l : lines) {
				if (gb_string_are_equal(l, desc)) {
					dup = true;
					break;
				}
			}
			if (dup) {
				gb_string_free(desc);
			} else {
				array_add(&lines, desc);
			}
		}
		if (lines.count == 0) {
			return;
		}

		error_line("\tPossible forms for '%.*s':\n", LIT(name));
		error_line("\t\t(r: int, v: vector, f: float, k: mask, m: memory,\n");
		error_line("\t\t r/m: reg-or-mem, imm: immediate; number: bit=width)\n");

		isize const MAX_SHOWN = 32;
		isize shown = gb_min(lines.count, MAX_SHOWN);
		for (isize i = 0; i < shown; i++) {
			String line = make_string(cast(u8 const *)lines[i], gb_string_length(lines[i]));
			if (line.len == 0) {
				error_line("\t\t%.*s\n", LIT(name)); // zero-operand form
			} else {
				error_line("\t\t%.*s %.*s\n", LIT(name), LIT(line));
			}
		}
		if (lines.count > shown) {
			isize rest = lines.count - shown;
			error_line("\t\t... and %td more form%s\n", rest, rest == 1 ? "" : "s");
		}
	};

	int min_count = I32_MAX;
	int max_count = -1;

	for (auto form : forms) {
		int explicit_count = cast(int)form.explicit_count();
		min_count = gb_min(min_count, explicit_count);
		max_count = gb_max(max_count, explicit_count);
	}
	min_count = gb_max(min_count, 0);
	max_count = gb_max(max_count, 0);

	if (is_pseudo) {
		min_count = gb_min(min_count, target_explicit_count);
		max_count = gb_min(max_count, target_explicit_count);
	}

	// A prefix that none of this mnemonic's forms can take is unconditionally wrong,
	// independent of whether the operands match — catch it even on a match failure.
	if (previous_prefix > 0) {
		bool any_form_accepts = false;
		for (auto &form : forms) {
			bool req_mem = false;
			if (asm_ctx->prefix_kind_okay(previous_prefix, form, &req_mem)) {
				any_form_accepts = true;
				break;
			}
		}
		if (!any_form_accepts) {
			error(previous_prefix_instr ? previous_prefix_instr : instr->name,
			      "Asm prefix cannot be applied to '%.*s'", LIT(name));
		}
	}

	auto valid_spots = slice_make<bool>(heap_allocator(), max_count);
	defer (slice_free(&valid_spots, heap_allocator()));

	auto possible_kinds = slice_make<AsmOperandKind>(heap_allocator(), max_count);
	defer (slice_free(&possible_kinds, heap_allocator()));

	auto possible_class_kinds = slice_make<AsmRegClass>(heap_allocator(), max_count);
	defer (slice_free(&possible_class_kinds, heap_allocator()));

	bool  matched          = false;
	isize valid_form_index = -1;

	// Some instructions have no explicit operands but encode an implicit register
	// (exp. in/out use AL, AX, or EAX with DX). The template exposes this
	// register as a pinned parameter, whose width determines the encoding.
	//
	// Without this check, all zero-operand forms score equally, and the first
	// matching table entry wins.
	auto implicit_operands_match_pins = [&](typename AsmCtx::Encoding const &form) {
		GB_ASSERT(tmpl_entity->kind == Entity_AsmTemplate);
		auto const &decls = tmpl_entity->AsmTemplate.decls;

		for (auto slot : form.ops) {
			if (slot == asm_ctx->OP_NONE || !asm_ctx->operand_type_is_implicit(slot)) {
				continue;
			}

			u16 implicit_bit = asm_ctx->clobber_bit_for_reg_name(asm_ctx->implicit_reg_name(slot));
			i32 implicit_width = asm_ctx->operand_type_bit_width(slot);
			if (implicit_bit == 0 || implicit_width == 0) {
				continue;
			}

			for (auto const &decl : decls) {
				if (decl.pin.len == 0 || asm_ctx->clobber_bit_for_reg_name(decl.pin) != implicit_bit) {
					continue;
				}
				// A pin names a physical register family: %eax and %al share
				// RAX clobber bit -> its type supplies the sub-register width
				if (decl.entity != nullptr && check_asm_operand_bit_width(decl.entity->type) != implicit_width) {
					return false;
				}
			}
		}
		return true;
	};

	isize best_form  = -1;
	int   best_score = -1;
	int   best_dist  = I32_MAX; // secondary: prefer smaller width distance
	int   best_pref  = -1;      // tertiary: prefer wider slots (r64 over r32)

	for_array(form_index, forms) {
		auto &form = forms[form_index];

		if (is_pseudo && cast(int)form.explicit_count() < target_explicit_count) {
			continue;
		} else if (operands.count != cast(int)form.explicit_count()) {
			continue;
		}
		if (!implicit_operands_match_pins(form)) {
			continue;
		}

		int score      = 0;
		int width_dist = 0;
		int width_pref = 0;

		for_array(i, operands) {
			auto type = operand_slot_type(form, cast(int)i);
			Operand const *operand = &operands[i];
			AsmOperandKind dst = asm_ctx->kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(operand);

			bool kind_ok = asm_operand_kind_fits(dst, src);

			// Bias toward wider register slots so an r64 form outranks an otherwise-equal r32 form.
			width_pref += cast(int)asm_ctx->operand_type_bit_width(type);

			bool       spot_ok = false;
			AsmSlotFit fit     = {};
			if (kind_ok) {
				bool mem_unsized = (src == AsmOperand_Memory) && are_types_identical(operand->type, t_rawptr);

				if (dst == AsmOperand_Register_Or_Memory && src == AsmOperand_Memory && mem_unsized) {
					spot_ok = true; // memory form accepts memory; no size check
				} else {
					spot_ok = check_asm_operand_size_class(asm_ctx, type, operand, &fit);
					bool width_mismatch = fit.mismatch == AsmMismatch_Size || fit.mismatch == AsmMismatch_ImmRange;
					if (!spot_ok && width_mismatch && fit.want_bits > 0 && fit.got_bits > 0) {
						width_dist += gb_abs(fit.want_bits - fit.got_bits);
					}
				}
			}

			if (spot_ok) {
				score += 2;
			} else if (kind_ok && fit.mismatch != AsmMismatch_NamedReg && fit.mismatch != AsmMismatch_Writeback) {
				// A slot wanting a named hardware register or another writeback is not a near miss.
				// It must not outrank a form that merely has the widths wrong.
				score += 1; // kind matched, only value/size/class failed
			}
		}

		if (score == operands.count * 2) {
			matched = true;
			valid_form_index = form_index;
			break;
		}

		// Lexicographic rank: score desc, then width_dist asc, then width_pref desc.
		bool better = false;
		if (score != best_score) {
			better = score > best_score;
		} else if (width_dist != best_dist) {
			better = width_dist < best_dist;
		} else {
			better = width_pref > best_pref;
		}
		if (better) {
			best_score = score;
			best_dist  = width_dist;
			best_pref  = width_pref;
			best_form  = form_index;
		}
	}

	if (operands.count < min_count || operands.count > max_count) {
		ERROR_BLOCK();
		if (min_count == max_count) {
			error(instr->name, "The asm instruction '%.*s' expects %d operands, got %td", LIT(name), max_count, operands.count);
		} else {
			error(instr->name, "The asm instruction '%.*s' expects %d..=%d operands, got %td", LIT(name), min_count, max_count, operands.count);
		}
		print_possible_forms();
		return false;
	}

	if (matched) {
		if (previous_prefix > 0) {
			bool requires_memory_dest = false;
			if (asm_ctx->prefix_kind_okay(previous_prefix, forms[valid_form_index], &requires_memory_dest)) {
				if (operands.count != 0 && determine_asm_operand_kind(&operands[0]) != AsmOperand_Memory) {
					error(previous_prefix_instr ? previous_prefix_instr : instr->name,
					      "Asm prefix requires '%.*s' to have a memory destination operand", LIT(name));
				}
			}
		}

		auto *ate = &tmpl_entity->AsmTemplate;

		instr->mnemonic = mnemonic;
		instr->valid_form_index = cast(i32)valid_form_index;

		check_operand_constraints(asm_ctx, operands, mnemonic, name);


		// NOTE(bill): The scaled-index shift must equal log2(transfer size) on targets that require it
		// e.g. on AArch64 register-offset loads/stores.
		// Generic: forms with form_transfer_bytes()==0, or operands with no constant scale, impose nothing.
		{
			u16 tb = asm_ctx->form_transfer_bytes(forms[valid_form_index]);
			if (build_context.metrics.arch == TargetArch_arm64 && tb != 0) {
				i64 want = cast(i64)floor_log2(cast(u32)tb);
				for_array(oi, operands) {
					Ast *e = operands[oi].expr;
					if (e->kind != Ast_AsmMemoryOperand) {
						continue;
					}
					auto *m = &e->AsmMemoryOperand;
					if (m->classify.scale == nullptr || m->classify.scale->tav.mode != Addressing_Constant) {
						continue;
					}
					i64 raw = exact_value_to_i64(exact_value_to_integer(m->classify.scale->tav.value()));
					// Normalise the '*' form to a shift amount; '<<'/'>>' are already shifts.
					i64 shift = raw;
					if (m->classify.scale_op.kind == Token_Mul) {
						shift = (is_power_of_two(raw) && raw <= 16) ? cast(i64)floor_log2(cast(u32)raw) : -1;
					}
					// shift 0 (unscaled) is always legal; otherwise it must match log2(size).
					if (shift != 0 && shift != want) {
						if (m->classify.scale_op.kind == Token_Mul) {
							error(m->classify.scale, "'%.*s' scaled-index multiplier must be %lld (the %u-byte transfer size), got %lld",
							      LIT(name), cast(long long)(cast(i64)1 << want), cast(unsigned)tb, cast(long long)raw);
						} else {
							error(m->classify.scale, "'%.*s' scaled-index shift must be %lld (log2 of the %u-byte transfer), got %lld",
							      LIT(name), cast(long long)want, cast(unsigned)tb, cast(long long)shift);
						}
					}
				}
			}
		}
		{
			// NOTE(bill): Feature Gating
			// The matched form may require a target feature (crc32b needs +crc, LSE atomics need +lse, ...).
			// The form carries its Feature. It is satisfied if the feature is globally enabled for the target,
			// OR if this template's own signature declares it via @(require_target_feature) / @(enable_target_feature)
			// see `check_asm_template_feature_is_enabled`
			String feat = asm_ctx->feature_name_from_form(forms[valid_form_index]);
			if (feat.len != 0) {
				bool ok = check_asm_template_feature_is_enabled(tmpl_entity, feat);

				if (!ok) {
					error(instr->name,
					      "'%.*s' requires the target feature '%.*s', which is not enabled; "
					      "enable it on this 'asm' template (e.g. @(enable_target_feature=\"%.*s\")), "
					      "or globally via '-target-features:\"%.*s\"' or a matching micro-architecture",
					      LIT(name), LIT(feat), LIT(feat), LIT(feat));
				}
			}
		}

		// Handle clobbering from mnemonic
		auto clobber = clobber_forms[valid_form_index];

		facts->read_regs = cast(u16)clobber.implicit_rd & asm_ctx->CLOBBER_REGS_NAMED;

		// NOTE(bill): reads_mem/writes_mem are per-FORM capability bits.
		// A form with an r/m slot (e.g. add r/m32, imm32) carries them even
		// when the operand resolved to a register, e.g. `add x, 123`.
		// Count a real access only when an operand actually resolved to memory,
		// or the access is implicit (no r/m slot exists to carry the bit: movs/stos/...).
		bool has_mem_operand = false;
		bool has_rm_slot     = false;
		auto const &valid_form = forms[valid_form_index];
		for_array(i, operands) {
			if (determine_asm_operand_kind(&operands[i]) == AsmOperand_Memory) {
				has_mem_operand = true;
			}
			AsmOperandKind op_kind = asm_ctx->kind_from_operand_type(operand_slot_type(valid_form, cast(int)i));
			if (op_kind == AsmOperand_Memory || op_kind == AsmOperand_Register_Or_Memory) {
				has_rm_slot = true;
			}
		}
		bool mem_is_real = has_mem_operand || (!has_rm_slot && operands.count > 0) || clobber.has_implicit_mem();

		bool internal_branch = clobber.has_control() && check_asm_instr_targets_internal_label(instr);

		bool effective_side_effects = clobber.implies_side_effects() && !internal_branch;

		ate->clobber_flags  |= clobber.implies_clobber_flags();
		ate->clobber_memory |= clobber.implies_clobber_memory() && mem_is_real;
		ate->is_volatile    |= effective_side_effects;

		ate->has_observable_side_effect |= effective_side_effects;
		ate->has_observable_side_effect |= clobber.writes_mem && mem_is_real;

		u16 output_pinned_mask = 0;
		for_array(i, ate->decls) {
			if (ate->decls[i].param_group == AsmTemplateEntityDeclParamGroup_Output) {
				output_pinned_mask |= asm_decl_resolve_pin_bit(asm_ctx, ate->decls, cast(i32)i);
			}
		}

		u16 produced = cast(u16)clobber.implicit_wr & asm_ctx->CLOBBER_REGS_NAMED;
		u16 explicit_writes = 0;

		u16 written_ops = cast(u16)clobber.written;
		u16 pinned_param_writes = 0;
		for_array(i, operands) {
			int tslot = user_operand_target_index(cast(int)i);
			if (tslot < 0 || tslot >= 4 || (written_ops & (1u << tslot)) == 0) {
				continue;
			}
			Ast *e = operands[i].expr;
			if (e->kind == Ast_AsmRegister) {
				u16 b = asm_ctx->clobber_bit_for_reg_name(e->AsmRegister.name.string);
				produced |= b;
				explicit_writes |= b;
				asm_clobber_written_register(asm_ctx, tmpl_entity, e->AsmRegister.name.string);
				continue;
			}
			// NOTE(bill): A lane operand `v[idx]` is an IndexExpr with no entity of its own
			if (e->kind == Ast_IndexExpr) {
				e = e->IndexExpr.expr;
			}
			Entity *pe = entity_of_node(e);
			if (pe != nullptr && pe->kind == Entity_Variable) {
				AsmTemplateEntityDecl *d = check_asm_find_decl(pe, ate->decls);
				check_asm_mark_input_written(ate->decls, d);
				u16 pin_bit = asm_decl_resolve_pin_bit(asm_ctx, ate->decls, d ? d->total_index : -1);
				pinned_param_writes |= pin_bit;

				// NOTE(bill): A write through a pinned parameter defines its register at the operand's width
				i32 idx = asm_reg_index_from_bit(pin_bit);
				i32 w   = check_asm_operand_bit_width(operands[i].type);
				if (idx >= 0 && w > 0) {
					facts->gen_reg_w.e[idx] = cast(u8)gb_max(cast(i32)facts->gen_reg_w.e[idx], w);
				}
 			}
		}

		if (is_pseudo &&
		    build_context.metrics.arch == TargetArch_riscv64) {
			// Synthesized register sources (e.g. ra in `jal off` -> `jal ra, off`) also
			// write a physical register; record them so ra is treated as produced/clobbered.
			u16 synth = 0;
			for (int i = 0; i < gb_count_of(alias.src); i++) {
				if ((written_ops & (1u << i)) == 0) {
					continue;
				}
				if (alias.src[i] == asm_ctx->AliasSrc_LINK) {
					synth |= 1<<0; // ClobberReg_RA
				}
			}
			produced        |= synth;
			explicit_writes |= synth;
		}

		facts->gen_regs   = produced | pinned_param_writes;
		facts->gen_flags  = cast(u16)clobber.flags_wr_call();
		facts->read_flags = cast(u16)clobber.flags_rd_call();

		// NOTE(bill): mnemonics such as `xor r, r` / `sub r, r` act as zeroing the destination
		// independent of its prior value: the read is architecturally dead, so it must not count as a use.
		bool self_zeroing = false;
		if (asm_ctx->is_self_zeroing_idiom(cast(u16)mnemonic) && operands.count >= 2) {
			Entity *e0 = entity_of_node(operands[0].expr);
			bool all_same = (e0 != nullptr);
			for (isize k = 1; all_same && k < operands.count; k++) {
				all_same = entity_of_node(operands[k].expr) == e0;
			}
			// also treat literal %reg == %reg as self-zeroing (no entity, compare reg bits)
			if (!all_same && operands[0].expr->kind == Ast_AsmRegister) {
				u16 b0 = asm_ctx->clobber_bit_for_reg_name(operands[0].expr->AsmRegister.name.string);
				all_same = b0 != 0;
				for (isize k = 1; all_same && k < operands.count; k++) {
					all_same = operands[k].expr->kind == Ast_AsmRegister &&
					           asm_ctx->clobber_bit_for_reg_name(operands[k].expr->AsmRegister.name.string) == b0;
				}
			}
			self_zeroing = all_same;
		}


		for_array(i, operands) { // Sub-register widths for explicit named-register operands
			auto const &op = operands[i];
			Ast *e = op.expr;
			if (e->kind != Ast_AsmRegister) {
				continue;
			}
			u16 bit = asm_ctx->clobber_bit_for_reg_name(e->AsmRegister.name.string);
			i32 idx = asm_reg_index_from_bit(bit);
			if (idx < 0) {
				continue;
			}
			i32 w = check_asm_operand_bit_width(op.type);
			if (w <= 0) {
				w = 0;
				// Fallback to the register's intrinsic width for a bare %reg.
				auto r = asm_ctx->register_lookup(e->AsmRegister.name.string);
				if (r) {
					w = asm_ctx->reg_size(r);
				}
			}
			if (w == 0) {
				continue;
			}
			int tslot = user_operand_target_index(cast(int)i);
			if (0 <= tslot && tslot < 4) {
				if (!self_zeroing && cast(u16)clobber.read & (1u << tslot)) {
					facts->read_reg_w.e[idx] = cast(u8)w;
					facts->read_regs |= bit; // NOTE(bill): let liveness + coarse rbw see the explicit read
				}
				if (cast(u16)clobber.written & (1u << tslot)) {
					facts->gen_reg_w.e [idx] = cast(u8)w;
				}
			}
		}

		{
			// NOTE(bill): A written register with no operand width, e.g. an implicit write such as RDTSC -> EDX:EAX,
			// is treated as a full-width definition, matching asm_full_kill_mask
			u8 full = cast(u8)(build_context.metrics.ptr_size*8);
			for (i32 idx = 0; idx < ASM_WIDTH_REG_COUNT; idx++) {
				if ((facts->gen_regs & (1u << idx)) != 0 && facts->gen_reg_w.e[idx] == 0) {
					facts->gen_reg_w.e[idx] = full;
				}
			}
		}


		bool writes_back_stack_pointer = false; // e.g. `stp %x29, %x30, #pre [%sp - 16]`
		for_array(i, operands) {
			int slot = user_operand_target_index(cast(int)i);
			if (slot < 0) {
				continue;
			}
			// A pre/post-index memory operand writes back (and reads) its base
			// register. The operand kind is Memory, so the register/lane path below
			// won't see it; record the base's def+use here so liveness sees the
			// cursor advance and a later read of it isn't flagged undefined.
			if (operands[i].expr->kind == Ast_AsmMemoryOperand) {
				auto *m    = &operands[i].expr->AsmMemoryOperand;
				Ast  *base = m->classify.base; // NOTE(bill): a missing base was already reported
				if (m->kind != AsmMemoryOperand_Default && base != nullptr) {
					Entity *be = entity_of_node(base);
					if (be != nullptr && be->kind == Entity_Variable) {
						array_add(&facts->gen_params,  be);
						array_add(&facts->read_params, be);
						check_asm_mark_input_written(ate->decls, check_asm_find_decl(be, ate->decls));
					}
					if (base->kind == Ast_AsmRegister) {
						asm_clobber_written_register(asm_ctx, tmpl_entity, base->AsmRegister.name.string);
						u16 base_bit = asm_ctx->clobber_bit_for_reg_name(base->AsmRegister.name.string);
						writes_back_stack_pointer |= (base_bit & asm_stack_pointer_bit(asm_ctx)) != 0;
					}
				}
			}
			Entity *pe = entity_of_node(operands[i].expr);
			if (pe == nullptr || pe->kind != Entity_Variable) {
				continue;
			}

			bool reads  = !self_zeroing && (cast(u16)clobber.read & (1u << slot)) != 0;
			bool writes = (cast(u16)clobber.written & (1u << slot)) != 0;
			if (reads) {
				array_add(&facts->read_params, pe);
			}
			if (writes) {
				array_add(&facts->gen_params, pe);
			}

			// View aliasing: a view decl shares its source's physical register.
			AsmTemplateEntityDecl *view = check_asm_find_decl(pe, ate->decls);
			if (view != nullptr && view->view_of >= 0) {
				Entity *src_e = ate->decls[view->view_of].entity;

				// A read of the view is a read of the source
				if (reads) {
					array_add(&facts->read_params, src_e);
				}

				// A write of the view defines the source only if it covers the parent
				if (writes) {
					i32 parent_w = check_asm_operand_bit_width(src_e->type);
					if (view->view_bits == 32 || view->view_bits == parent_w) {
						array_add(&facts->gen_params, src_e);
					}
				}
			}
		}

		{
			// Terminality for a #diverging template: this instruction ends straight-line
			// flow off the end (jmp/ret/etc. -> CONTROL, hlt/ud2 -> HALT). A conditional
			// branch does NOT terminate (it can fall through), so require that the form
			// is not merely CONTROL-with-fallthrough. We approximate "unconditional" as
			// CONTROL|HALT with no explicit label/operand fallthrough below.

			bool control = clobber.has_control();
			bool halt    = clobber.has_halt();
			// A conditional branch reads a flag and can fall through -> not terminal.
			bool conditional = clobber.is_conditional(valid_form);

			facts->is_control  = control;
			facts->is_terminal = halt || (control && !conditional);

			// NOTE(bill): e.g. ret, or a jump through a register or parameter, rather than to one of the template's labels
			bool to_label = check_asm_instr_targets_internal_label(instr);
			facts->reads_every_register = control && !conditional && !halt && !to_label;
		}
		if (asm_instruction_is_call(asm_ctx, mnemonic, clobber, produced)) {
			check_asm_call_facts(asm_ctx, tmpl_entity, facts, operands);
			cfg->calls_out |= facts->calls_out;
		} else {
			for (auto const &op : operands) {
				Entity *e = entity_of_node(op.expr);
				if (e != nullptr && e->kind == Entity_Procedure) {
					error(op.expr, "A procedure can only be named in an 'asm' template as the target of a call");
				}
			}
		}

		if (cfg->stack_use == nullptr) {
			u16  stack_pointer_bit = asm_stack_pointer_bit(asm_ctx);
			bool pushes            = (cast(u32)clobber.implicit_wr & stack_pointer_bit) != 0 && clobber.writes_mem;
			bool writes_sp         = (explicit_writes & stack_pointer_bit) != 0 || writes_back_stack_pointer;

			char const *stack_use = nullptr;
			if (facts->is_call) {
				stack_use = "makes a call";
			} else if (pushes) {
				stack_use = "pushes onto the stack";
			} else if (writes_sp) {
				stack_use = "writes the stack pointer";
			}
			if (stack_use != nullptr) {
				cfg->stack_use      = stack_use;
				cfg->stack_use_node = instr->name;
			}
		}
		// NOTE(bill): an output's register is already declared as written.
		// Clobbering it as well lets LLVM drop the moves into it of an input tied to that output.
		// LLVM reserves the stack pointer, and a template must leave it as it found it.
		u16 implicit_clobbers = produced & ~output_pinned_mask & ~asm_stack_pointer_bit(asm_ctx);
		asm_ctx->clobber_implicit_regs(&ate->clobber_registers_set, implicit_clobbers);
		asm_clobber_implicit_vector_registers(asm_ctx, tmpl_entity, cast(u32)clobber.implicit_wr);

		// Purity inference
		if (cfg->can_be_pure) {
			// NOTE(bill): Only the first violating instruction is recorded
			// The later ones don't overwrite the reason.
			char const *why = nullptr;

			if (clobber.writes_mem && mem_is_real) {
				why = "it writes to memory";
			} else if (clobber.reads_mem && mem_is_real) {
				// A load's result depends on memory, which is not a value input.
				why = "it reads from memory";
			} else if (clobber.is_nondeterministic() ||
			           (is_pseudo && alias.is_nondeterministic())) {
				// rdtsc/rdrand/cpuid on x86
				// counter/entropy CSR reads on RISC-V.
				why = "it is nondeterministic";
			} else if (clobber.implies_clobber_memory() && mem_is_real) {
				why = "it accesses memory the compiler cannot see";
			} else if (effective_side_effects) {
				why = "it has an observable side effect";
			} else if (!internal_branch && clobber.has_control()) {
				// Internal jmp/jcc/ret over the template's own labels stays pure; a call
				// or an indirect/external transfer does not.
				why = "it possibly transfers control outside the inline 'asm' template";
			}

			if (why != nullptr) {
				cfg->can_be_pure        = false;
				cfg->impure_reason      = why;
				cfg->impure_reason_node = instr->name;
			}

			// NOTE(bill): return true even on a purity test because the instruction is still good
		}
		return true;
	}

	// NOTE(bill): Failure path
	auto fits = slice_make<AsmSlotFit>(heap_allocator(), max_count);
	defer (slice_free(&fits, heap_allocator()));
	if (best_form >= 0) {
		auto &form = forms[best_form];
		for_array(i, operands) {
			auto type = operand_slot_type(form, cast(int)i);
			AsmOperandKind dst = asm_ctx->kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(&operands[i]);

			possible_kinds      [i] = dst;
			possible_class_kinds[i] = asm_ctx->reg_class_from_operand_type(type);

			valid_spots[i] = asm_operand_kind_fits(dst, src) &&
			                 check_asm_operand_size_class(asm_ctx, type, &operands[i], &fits[i]);
		}
	}

	begin_error_block();

	bool nearly = best_score >= gb_max(operands.count*2 - 2, 0);
	if (nearly) {
		error(instr->name, "'%.*s' operands nearly matched the expected encoding forms", LIT(name));
	} else {
		error(instr->name, "'%.*s' operands matched none of the expected encoding forms", LIT(name));
	}

	for_array(i, valid_spots) {
		if (valid_spots[i] || i >= operands.count) {
			continue;
		}
		auto dst = possible_kinds[i];
		AsmOperandKind src = determine_asm_operand_kind(&operands[i]);

		AsmRegClass dst_reg_class = possible_class_kinds[i];
		AsmRegClass src_reg_class = check_asm_reg_class_from_type(operands[i].type);

		AsmSlotFit const &fit = fits[i];
		AsmMismatch       m   = fit.mismatch;

		end_error_block();
		begin_error_block();

		if (m == AsmMismatch_ImmRange) {
			ExactValue ev = operands[i].value;
			gbString vs = exact_value_to_string(ev);
			i32 bits_required = 0;
			check_asm_immediate_value_fits(ev, fit.want_bits, &bits_required, nullptr);
			if (bits_required > 0) {
				error(operands[i].expr, "'%.*s' operand-%td is a %d-bit immediate value, but the value %s does not fit in the %d-bit immediate this form encodes",
				      LIT(name), i, bits_required, vs, cast(int)fit.want_bits);
			} else {
				error(operands[i].expr, "'%.*s' operand-%td is an immediate value, but the value %s does not fit in the %d-bit immediate this form encodes",
				      LIT(name), i, vs, cast(int)fit.want_bits);
			}
			gb_string_free(vs);
		} else if (m == AsmMismatch_ImmType) {
			error(operands[i].expr, "'%.*s' operand-%td: a floating-point constant cannot be used as an immediate",
			      LIT(name), i);
		} else if (m == AsmMismatch_Size && fit.want_bits && fit.got_bits) {
			error(operands[i].expr, "'%.*s' operand-%td has the wrong size: expected a %u-bit %.*s operand, got %u-bit",
			      LIT(name), i,
			      cast(unsigned)fit.want_bits, LIT(asm_reg_class_strings[dst_reg_class]),
			      cast(unsigned)fit.got_bits);
		} else if (m == AsmMismatch_Class) {
			error(operands[i].expr, "'%.*s' operand-%td is in the wrong register class, expected %d-bit %.*s %.*s, got %d-bit %.*s %.*s",
			      LIT(name), i,
			      fit.want_bits, LIT(asm_reg_class_strings[dst_reg_class]), LIT(asm_operand_kind_strings[dst]),
			      fit.got_bits,  LIT(asm_reg_class_strings[src_reg_class]), LIT(asm_operand_kind_strings[src]));
		} else if (m == AsmMismatch_Writeback) {
			auto slot = operand_slot_type(forms[best_form], cast(int)i);
			AsmMemoryOperandKind want = asm_slot_writeback(asm_ctx, slot);
			if (want == AsmMemoryOperand_Default) {
				error(operands[i].expr, "'%.*s' operand-%td is #%s, but no form of '%.*s' writes back its base register",
				      LIT(name), i, asm_writeback_names[asm_operand_writeback(&operands[i])], LIT(name));
			} else {
				error(operands[i].expr, "'%.*s' operand-%td must be a #%s memory operand",
				      LIT(name), i, asm_writeback_names[want]);
			}
		} else if (m == AsmMismatch_NamedReg) {
			auto slot = operand_slot_type(forms[best_form], cast(int)i);
			error(operands[i].expr, "'%.*s' operand-%td must be a named %.*s register, got a %.*s",
			      LIT(name), i,
			      LIT(asm_ctx->named_reg_class_string(asm_ctx->operand_type_named_reg_class(slot))),
			      LIT(asm_operand_kind_strings[src]));
		} else if (dst == AsmOperand_Immediate) {
			error(operands[i].expr, "'%.*s' operand-%td must be an assemble-time constant or a $ immediate parameter, got a %.*s",
			      LIT(name), i, LIT(asm_operand_kind_strings[src]));
		} else if (dst) {
			error(operands[i].expr, "'%.*s' operand-%td has an invalid kind, expected %.*s operand",
			      LIT(name), i, LIT(asm_operand_kind_expected_strings[dst]));
		} else {
			error(operands[i].expr, "'%.*s' operand-%td has an invalid kind", LIT(name), i);
		}
	}

	if (nearly && best_form >= 0) {
		print_closest_form(best_form);
	} else {
		print_possible_forms();
	}
	end_error_block();

	return false;
}


enum AsmTermCategory : u8 {
	AsmTermCategory_Other,
	AsmTermCategory_Register,
	AsmTermCategory_Const,
	AsmTermCategory_Immediate,
	AsmTermCategory_Label,
};

gb_internal AsmTermCategory check_asm_mem_term_category(Operand *o, Array<AsmTemplateEntityDecl> const &decls) {
	if (o == nullptr || o->expr == nullptr) {
		return AsmTermCategory_Other;
	}
	if (o->expr->kind == Ast_AsmLabelDecl) {
		return AsmTermCategory_Label;
	}
	if (o->expr->kind == Ast_AsmRegister) {
		return AsmTermCategory_Register;
	}
	if (o->mode == Addressing_Constant) {
		return AsmTermCategory_Const;
	}
	Entity *pe = entity_of_node(o->expr);
	if (pe != nullptr && pe->kind == Entity_Variable) {
		switch (check_asm_find_kind(pe, decls)) {
		case AsmTemplateEntityDecl_Immediate:
			return AsmTermCategory_Immediate;
		case AsmTemplateEntityDecl_Register:
		case AsmTemplateEntityDecl_Memory:
			return AsmTermCategory_Register;
		}
	}
	return AsmTermCategory_Other;
}

// NOTE(bill): a procedure named in the body, which may only be the target of a call
gb_internal void check_asm_procedure_operand(CheckerContext *ctx, Operand *operand, Ast *expr, bool allow_memory_operands) {
	if (operand->mode == Addressing_Invalid) {
		return;
	}
	defer (if (operand->mode == Addressing_Invalid) {
		operand->type = t_invalid;
	});

	Entity *e = entity_of_node(expr);
	if (operand->mode == Addressing_ProcGroup || (e != nullptr && e->kind == Entity_ProcGroup)) {
		error(expr, "A procedure group cannot be called from an 'asm' template; name one of its procedures instead");
		operand->mode = Addressing_Invalid;
		return;
	}
	if (e == nullptr || e->kind != Entity_Procedure) {
		error(expr, "Only asm parameters, constants, or procedures are allowed to be used within an 'asm' template");
		operand->mode = Addressing_Invalid;
		return;
	}
	if (!allow_memory_operands) {
		error(expr, "A procedure can only be named in an 'asm' template as the target of a call");
		operand->mode = Addressing_Invalid;
		return;
	}
	if (is_type_polymorphic(e->type)) {
		error(expr, "A polymorphic procedure cannot be called from an 'asm' template");
		operand->mode = Addressing_Invalid;
		return;
	}
	operand->mode = Addressing_Value;
	operand->type = e->type;
	add_type_and_value(ctx, expr, operand->mode, operand->type, {});
}

// NOTE(bill): a memory operand's base or index: a 32-bit or 64-bit integer register, or a register parameter.
// A pointer or integer parameter lowers to a register operand, so either kind of parameter is accepted.
template <typename AsmCtx>
gb_internal bool check_asm_mem_address_register(AsmCtx *asm_ctx, Operand *o, AsmAddrRole role, Array<AsmTemplateEntityDecl> const &decls, i32 *width_) {
	if (o->expr->kind == Ast_AsmRegister) {
		String reg_name = o->expr->AsmRegister.name.string;
		return check_register(asm_ctx, o, &o->expr->AsmRegister) &&
		       check_asm_addr_register(o, role, reg_name, width_);
	}

	Entity *pe = entity_of_node(o->expr);
	bool is_param = pe != nullptr && pe->kind == Entity_Variable;
	AsmTemplateEntityDeclKind kind = is_param ? check_asm_find_kind(pe, decls) : AsmTemplateEntityDecl_Invalid;
	if (kind == AsmTemplateEntityDecl_Register || kind == AsmTemplateEntityDecl_Memory) {
		return check_asm_addr_register(o, role, {}, width_);
	}

	gbString s = expr_to_string(o->expr);
	if (role == AsmAddr_Base) {
		error(o->expr, "A base value must be a register parameter, got %s", s);
	} else if (!is_param) {
		error(o->expr, "An index value must be an integer register, got %s", s);
	} else {
		gbString t = type_to_string(o->type);
		error(o->expr, "An index must be an integer register, got %s of type %s", s, t);
		gb_string_free(t);
	}
	gb_string_free(s);
	return false;
}

// NOTE(bill): a scale: a constant 1, 2, 4, or 8 (or a shift by 0 to 3), or a $ immediate parameter
gb_internal void check_asm_mem_scale(CheckerContext *ctx, Operand *scale, Token op, Array<AsmTemplateEntityDecl> const &decls) {
	bool    is_constant  = scale->mode == Addressing_Constant;
	Entity *pe           = entity_of_node(scale->expr);
	bool    is_immediate = pe != nullptr && pe->kind == Entity_Variable &&
	                       check_asm_find_kind(pe, decls) == AsmTemplateEntityDecl_Immediate;
	if (!is_type_integer(scale->type) || (!is_constant && !is_immediate)) {
		gbString s = expr_to_string(scale->expr);
		error(scale->expr, "A scale must be a constant integer or an immediate, got %s", s);
		gb_string_free(s);
		return;
	}
	if (!is_constant) {
		return;
	}

	gbString s = exact_value_to_string(scale->value);
	defer (gb_string_free(s));
	if (scale->value.kind != ExactValue_Integer) {
		error(scale->expr, "A scale must be a constant integer or an immediate, got %s", s);
		return;
	}

	i64 v = exact_value_to_i64(scale->value);
	switch (op.kind) {
	case Token_Mul:
		if (v != 1 && v != 2 && v != 4 && v != 8) {
			error(scale->expr, "A scale using '*' must be a constant integer or an immediate with the value 1, 2, 4, or 8, got %s", s);
		}
		break;
	case Token_Shl:
	case Token_Shr:
		if (v < 0 || v > 3) {
			error(scale->expr, "A shifting scale using '%.*s' must be a constant integer or an immediate with the value 0, 1, 2, or 3, got %s", LIT(op.string), s);
		}
		break;
	default:
		error(op, "Unknown/unhandled scaling operator '%.*s'", LIT(op.string));
		break;
	}
	if (op.kind == Token_Shr && build_context.metrics.arch != TargetArch_arm64) {
		error(op, "The target platform does not support '%.*s' for shifting scale parameters in memory operands", LIT(op.string));
	}
	add_type_and_value(ctx, scale->expr, scale->mode, scale->type, scale->value);
}

// NOTE(bill): a displacement: an integer constant which fits a signed 32-bit value (12-bit on RISC-V),
// a $ immediate parameter, or a label
gb_internal void check_asm_mem_displacement(Operand *disp, bool has_register, Array<AsmTemplateEntityDecl> const &decls) {
	Ast *expr = disp->expr;
	if (expr->kind == Ast_AsmRegister) {
		error(expr, "A displacement must be a constant integer value, got a register");
		return;
	}
	if (expr->kind == Ast_AsmLabelDecl) {
		// NOTE(bill): The label was resolved (and marked used) by the recursive operand check,
		// so all that is left is rejecting the encodings that cannot carry it.
		if (!check_asm_target_supports_label_memory_operand()) {
			error(expr, "The target platform does not support label references within memory operands");
		} else if (has_register) {
			error(expr, "A label reference within a memory operand cannot be combined with a base, index, or scale; it is always relative to the instruction pointer");
		}
		return;
	}

	// A displacement must be assemble-time constant. A register-valued
	// parameter belongs in the index slot, not the displacement.
	if (disp->mode == Addressing_Constant && disp->value.kind == ExactValue_Integer) {
		AsmMismatch m = AsmMismatch_None;
		i32 needed = 0;
		gbString vs = exact_value_to_string(disp->value);
		defer (gb_string_free(vs));
		if (!check_asm_immediate_value_fits(disp->value, 32, &needed, &m)) {
			error(expr, "A memory displacement must fit in a signed 32-bit value, got %s (needs %d bits)", vs, cast(int)needed);
		} else if (build_context.metrics.arch == TargetArch_riscv64) {
			i64 v = exact_value_to_i64(disp->value);
			if (v < -2048 || v > 2047) {
				error(expr, "A RISC-V memory displacement must be from -2048 to 2047, got %s", vs);
			}
		}
		return;
	}

	Entity *pe = entity_of_node(expr);
	if (pe != nullptr && pe->kind == Entity_Variable) {
		switch (check_asm_find_kind(pe, decls)) {
		case AsmTemplateEntityDecl_Immediate:
			return; // A $-immediate parameter is a legal (assemble-time) displacement.
		case AsmTemplateEntityDecl_Register:
			error(expr, "A register parameter cannot be a displacement; use it as an index, e.g. [base + %.*s]", LIT(expr->Ident.token.string));
			return;
		}
	}

	gbString s = expr_to_string(expr);
	error(expr, "A displacement must be a constant integer or immediate, got %s", s);
	gb_string_free(s);
}

template <typename AsmCtx>
gb_internal void check_asm_instruction_operand(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *entity, Operand *operand, Ast *expr, bool allow_memory_operands) {
	operand->expr = expr;
	operand->mode = Addressing_Invalid;
	operand->type = t_invalid;

	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;

	Scope *param_scope = ate->param_scope;
	Scope *label_scope = ate->label_scope;

	switch (expr->kind) {
	case_ast_node(ue, UnaryExpr, expr);
		check_expr(ctx, operand, expr);
		if (operand->mode != Addressing_Constant) {
			error(expr, "Asm operands within unary operands (+ - ~) can only compile time constants");
		}
		return;
	case_end;
	case_ast_node(pe, ParenExpr, expr);
		check_expr(ctx, operand, expr);
		if (operand->mode != Addressing_Constant) {
			error(expr, "Asm operands within parentheses must be compile time constants");
			return;
		}

		Ast *inner = pe->expr;
		bool trivial = false;
		switch (inner->kind) {
		case Ast_BasicLit:
		case Ast_Ident:
			trivial = true;
			break;
		case Ast_UnaryExpr:
			// `(-3)` / `(~x)` — a unary on an atom parses fine unparenthesised.
			trivial = inner->UnaryExpr.expr->kind == Ast_BasicLit ||
			          inner->UnaryExpr.expr->kind == Ast_Ident;
			break;
		}
		if (trivial) {
			warning(expr, "Redundant parentheses around a single asm operand; the parentheses can be removed");
		}

		return;
	case_end;

	case_ast_node(i, Ident, expr);
		Entity *found = scope_lookup_current(param_scope, i->interned, i->hash);
		if (found != nullptr) {
			i->entity = found;
			operand->mode = Addressing_Value;
			operand->type = found->type;
			return;
		}
		found = scope_lookup(param_scope->parent, i->interned, i->hash);
		if (found == nullptr) {
			u32 cond_code = 0;
			if (asm_ctx->is_cond_code_name(i->token.string, &cond_code)) {
				// A condition code (e.g. `eq` in `csinc r, a, b, eq`) is not built-in:
				// condition codes are ordinary constants in Odin. Point the user at the
				// fix rather than the generic "undeclared" message.
				char bits[5] = {
					char('0' + ((cond_code >> 3) & 1)),
					char('0' + ((cond_code >> 2) & 1)),
					char('0' + ((cond_code >> 1) & 1)),
					char('0' + ( cond_code       & 1)),
					0,
				};
				error(expr, "Condition code '%.*s' is not defined in scope. Condition codes are ordinary constants in Odin, "
				            "define it e.g. `%.*s :: 0b%s` (%u)",
				            LIT(i->token.string), LIT(i->token.string), bits, cond_code);

				// NOTE(bill): Add this here to improve error propagation because this is the most likely result
				operand->mode  = Addressing_Constant;
				operand->value = exact_value_i64(cond_code);
				operand->type  = t_untyped_integer;

				add_type_and_value(ctx, expr, operand->mode, operand->type, operand->value);

				return;
			}
			error(expr, "Undeclared asm parameter or constant '%.*s'", LIT(i->token.string));
			return;
		}

		// NOTE(bill): resolved like any other identifier, as the constant may not have been checked yet,
		// e.g. one declared later in the same block, or one in a lazy file
		found = resolve_alias_entity(ctx, found, nullptr);
		if (found->kind == Entity_Procedure || found->kind == Entity_ProcGroup) {
			GB_ASSERT(ctx->scope == param_scope->parent);
			check_ident(ctx, operand, expr, nullptr, nullptr, false);
			i->entity = found; // NOTE(bill): check_ident leaves a procedure group's unset
			check_asm_procedure_operand(ctx, operand, expr, allow_memory_operands);
			return;
		}
		if (found->kind == Entity_Constant) {
			GB_ASSERT(ctx->scope == param_scope->parent);
			check_ident(ctx, operand, expr, nullptr, nullptr, false);
			if (operand->mode == Addressing_Invalid) {
				// NOTE(bill): already reported, e.g. an illegal declaration cycle
				return;
			}
		}
		if (operand->mode != Addressing_Constant) {
			error(expr, "Only asm parameters or constants are allowed to be used within an 'asm' template");
			operand->mode = Addressing_Invalid;
			operand->type = t_invalid;
			return;
		}

		add_type_and_value(ctx, expr, operand->mode, operand->type, operand->value);
		return;
	case_end;
	case_ast_node(bl, BasicLit, expr);
		check_expr(ctx, operand, expr);
		return;
	case_end;
	case_ast_node(asm_reg, AsmRegister, expr);
		check_register(asm_ctx, operand, asm_reg);
		return;
	case_end;
	case_ast_node(mem_op, AsmMemoryOperand, expr);
		operand->type = t_rawptr;
		operand->mode = Addressing_Value;

		if (!allow_memory_operands) {
			break;
		}

		if (Ast *seg = mem_op->segment_override) {
			Operand segment_override = {};
			check_asm_instruction_operand(asm_ctx, ctx, entity, &segment_override, seg, false);
			bool is_segment = seg->kind == Ast_AsmRegister &&
			                  asm_ctx->reg_is_segment(cast(u16)asm_ctx->register_lookup(seg->AsmRegister.name.string));
			if (!is_segment) {
				gbString s = expr_to_string(seg);
				error(seg, "A segment override must be a selector register parameter, got %s", s);
				gb_string_free(s);
			}
		}

		Operand base  = {};
		Operand index = {};
		Operand scale = {};
		Operand disp  = {};
		Token   scale_op = {};
		i64  disp_total     = 0;
		bool has_disp_const = false;
		Ast *disp_host      = nullptr; // node to host a folded constant displacement
		Ast *label_node     = nullptr;
		bool class_ok       = true;

		for (Ast *term_ast : mem_op->terms) {
			if (term_ast->kind != Ast_AsmMemoryTerm) {
				continue;
			}
			ast_node(term, AsmMemoryTerm, term_ast);
			bool neg = term->op.kind == Token_Sub;

			Operand o = {};
			check_asm_instruction_operand(asm_ctx, ctx, entity, &o, term->operand, false);
			AsmTermCategory operand_cat = check_asm_mem_term_category(&o, ate->decls);

			if (term->scale != nullptr) {
				Operand s = {};
				check_asm_instruction_operand(asm_ctx, ctx, entity, &s, term->scale, false);
				AsmTermCategory scale_cat = check_asm_mem_term_category(&s, ate->decls);

				bool scale_is_const = scale_cat == AsmTermCategory_Const || scale_cat == AsmTermCategory_Immediate;
				if (operand_cat == AsmTermCategory_Register && scale_is_const) {
					// reg*scale -> a genuine scaled index
					if (neg) {
						error(term->operand, "A memory index register cannot be negated");
						class_ok = false;
					} else if (index.expr != nullptr) {
						error(term->operand, "A memory operand may only have a single index register");
						class_ok = false;
					} else {
						index    = o;
						scale    = s;
						scale_op = term->scale_op;
					}
				} else if (operand_cat == AsmTermCategory_Const && scale_cat == AsmTermCategory_Const &&
				           o.value.kind == ExactValue_Integer && s.value.kind == ExactValue_Integer) {
					i64 iv = exact_value_to_i64(o.value);
					i64 sv = exact_value_to_i64(s.value);
					i64 v  = 0;
					// TODO(bill): should this be in big-int math or not?
					switch (term->scale_op.kind) {
					case Token_Shl:
					case Token_Shr:
						// A shift by a negative amount or by >= the width is undefined;
						// guard it rather than fold UB into the displacement.
						if (sv < 0 || sv >= 64) {
							error(term->scale_op, "A constant shift amount must be within 0 ..< 64, got %lld", cast(long long)sv);
							class_ok = false;
							sv = gb_clamp(sv, 0, 63);
							break;
						}
						v = (term->scale_op.kind == Token_Shl) ? (iv << sv) : (iv >> sv);
						break;
					case Token_Mul:
						v = iv * sv;
						break;
					default:
						error(term->scale_op, "Unknown/unhandled scaling operator '%.*s'", LIT(term->scale_op.string));
						class_ok = false;
						break;
					}
					disp_total += neg ? -v : v;
					has_disp_const = true;
					if (disp_host == nullptr) {
						disp_host = term->operand;
					}
				} else {
					error(term->operand, "A scaled term in a memory operand must be 'register*constant'");
					class_ok = false;
				}
				continue;
			}


			switch (operand_cat) {
			case AsmTermCategory_Register:
				if (neg) {
					error(term->operand, "A base or index register cannot be negated");
					class_ok = false;
				} else if (base.expr == nullptr) {
					base = o;
				} else if (index.expr == nullptr) {
					index = o;
				} else {
					error(term->operand, "A memory operand may have at most a base and an index register");
					class_ok = false;
				}
				break;
			case AsmTermCategory_Const:
				if (o.value.kind == ExactValue_Integer) {
					i64 v = exact_value_to_i64(o.value);
					disp_total += neg ? -v : v;
					has_disp_const = true;
					if (disp_host == nullptr) {
						disp_host = term->operand;
					}
				} else {
					// non-integer constant: let the displacement check below report it
					disp = o;
				}
				break;
			case AsmTermCategory_Immediate:
				// A $-immediate parameter is a legal assemble-time displacement.
				if (disp.expr != nullptr) {
					error(term->operand, "A memory operand may only have a single immediate displacement");
					class_ok = false;
				} else {
					disp = o;
				}
				break;
			case AsmTermCategory_Label:
				if (label_node != nullptr) {
					error(term->operand, "A memory operand may only reference a single label");
					class_ok = false;
				} else {
					label_node = term->operand;
					disp       = o;
				}
				break;
			default:
				{
					gbString s = expr_to_string(term->operand);
					error(term->operand, "Invalid term in a memory operand, got %s", s);
					gb_string_free(s);
					class_ok = false;
				}
				break;
			}
		}

		// Materialise a single displacement operand from the folded constant, unless a
		// label or immediate already occupies the displacement.
		if (disp.expr == nullptr && has_disp_const && disp_host != nullptr) {
			ExactValue folded = exact_value_i64(disp_total);
			add_type_and_value(ctx, disp_host, Addressing_Constant, t_untyped_integer, folded);
			disp.expr  = disp_host;
			disp.mode  = Addressing_Constant;
			disp.type  = t_untyped_integer;
			disp.value = folded;
		}

		mem_op->classify.base           = base.expr;
		mem_op->classify.index          = index.expr;
		mem_op->classify.scale          = scale.expr;
		mem_op->classify.scale_op       = scale_op;
		mem_op->classify.label          = label_node;
		mem_op->classify.disp_total     = disp_total;
		mem_op->classify.has_disp_const = has_disp_const;
		mem_op->classify.ok             = class_ok;

		// Defensive: a well-formed memory operand always classifies to at least one
		// of base / index / label / displacement. If none is set, the term list
		// reached the checker empty or malformed — e.g. a bare `[reg]` whose sole
		// term the parser dropped (it pushes terms only inside the +/- loop). Catch
		// that here rather than silently emitting a memory operand with no address.
		// A term which was already reported as invalid classifies to nothing.
		GB_ASSERT_MSG(!class_ok ||
		              !(base.expr == nullptr && index.expr == nullptr &&
		                label_node == nullptr && !has_disp_const && disp.expr == nullptr),
		              "asm: memory operand produced no base/index/displacement "
		              "(terms.count = %td); the parser likely dropped a single-term '[operand]'",
		              cast(isize)mem_op->terms.count);

		i32  base_w     = 0;
		i32  index_w    = 0;
		bool have_base  = base.expr  != nullptr && check_asm_mem_address_register(asm_ctx, &base,  AsmAddr_Base,  ate->decls, &base_w);
		bool have_index = index.expr != nullptr && check_asm_mem_address_register(asm_ctx, &index, AsmAddr_Index, ate->decls, &index_w);

		// base and index must be the same width
		// AArch64 register-offset addressing allows a 32-bit index with a 64-bit base
		// (extended-register form: uxtw/sxtw). Other targets require equal widths.
		bool ext_index_ok = build_context.metrics.arch == TargetArch_arm64 &&
		                    base_w == 64 && index_w == 32;
		if (have_base && have_index && base_w != index_w && !ext_index_ok) {
			error(base.expr,
			      "A memory operand's base and index registers must be the same width, got a %d-bit base and a %d-bit index",
			      cast(int)base_w, cast(int)index_w);
		}

		if (scale.expr != nullptr) {
			// a scale factor is meaningless without an index
			if (index.expr == nullptr) {
				error(scale.expr, "A scale factor requires an index register");
			}
			check_asm_mem_scale(ctx, &scale, scale_op, ate->decls);
		}
		if (disp.expr != nullptr) {
			bool has_register = base.expr != nullptr || index.expr != nullptr || scale.expr != nullptr;
			check_asm_mem_displacement(&disp, has_register, ate->decls);
		}

		if (!asm_ctx->supports_memory_index_not_just_disp()) {
			if (index.expr != nullptr) {
				error(index.expr, "The target platform does not support memory indexing within memory operands, only displacements");
			}
			if (scale.expr != nullptr) {
				error(scale.expr, "The target platform does not support memory index scaling within memory operands");
			}
		}

		if (build_context.metrics.arch == TargetArch_arm64 && class_ok && base.expr == nullptr && label_node == nullptr) {
			// NOTE(bill): AArch64 has no absolute addressing. Base register 31 is sp, not xzr.
			error(expr, "An AArch64 memory operand needs a base register");
		} else if (mem_op->kind != AsmMemoryOperand_Default) {
			// NOTE(bill): a writeback moves the base register by a constant offset, e.g. `[x1, #8]!` or `[x1], #8`
			if (build_context.metrics.arch != TargetArch_arm64) {
				error(expr, "#pre/#post asm memory operands are not supported by the target platform");
			} else if (base.expr == nullptr || index.expr != nullptr || label_node != nullptr) {
				error(expr, "A #%s memory operand takes only a base register and a constant offset", asm_writeback_names[mem_op->kind]);
			}
		}

		if (mem_op->type) {
			Type *t = check_type(ctx, mem_op->type);
			if (t != nullptr && t != t_invalid) {
				if (is_valid_asm_parameter_type(t) && !is_type_internally_pointer_like(t)) {
					operand->type = alloc_type_pointer(t);
				} else {
					gbString s = type_to_string(t);
					error(mem_op->type, "Asm memory operands type interpretation must be either an integer, boolean, float, or #simd vector, got %s", s);
					gb_string_free(s);
					// leave operand->type == t_rawptr ("unsized")
				}
			}
		}

		return;
	case_end;
	case_ast_node(label, AsmLabelDecl, expr);
		ast_node(name, Ident, label->name);
		Entity *found = scope_lookup_current(label_scope, name->interned, name->hash);
		if (found == nullptr) {
			error(expr, "Undeclared asm label '.%.*s'", LIT(name->token.string));
			return;
		}
		add_entity_use(ctx, label->name, found);
		add_type_and_value(ctx, expr, Addressing_Value, found->type, {});
		return;
	case_end;

	case_ast_node(ie, IndexExpr, expr);
		if (!allow_memory_operands) {
			error(expr, "Invalid use of an index expression in an asm operand");
			return;
		}

		Operand lhs = {};
		Operand rhs = {};
		check_asm_instruction_operand(asm_ctx, ctx, entity, &lhs, ie->expr,  false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &rhs, ie->index, false);

		auto lhs_kind = determine_asm_operand_kind(&lhs);
		if (lhs_kind != AsmOperand_Register) {
			gbString s = expr_to_string(lhs.expr);
			error(lhs.expr, "Expected a vector register, got '%s' which is %.*s",
			      s, LIT(asm_operand_kind_expected_strings[lhs_kind]));
			gb_string_free(s);
		} else if (!is_type_simd_vector(lhs.type)) {
			gbString s = type_to_string(lhs.type);
			error(lhs.expr, "Expected a vector register, got %s", s);
			gb_string_free(s);
		}

		auto rhs_kind = determine_asm_operand_kind(&rhs);
		if (rhs_kind != AsmOperand_Immediate) {
			gbString s = expr_to_string(rhs.expr);
			error(rhs.expr, "Expected an integer immediate as an index, got '%s' which is %.*s",
			      s, LIT(asm_operand_kind_expected_strings[rhs_kind]));
			gb_string_free(s);
		} else if (!is_type_integer(rhs.type)) {
			gbString s = type_to_string(rhs.type);
			error(rhs.expr, "Expected an integer immediate as an index, got %s", s);
			gb_string_free(s);
		} else if (rhs.mode != Addressing_Constant || rhs.value.kind != ExactValue_Integer) {
			Entity *pe = entity_of_node(rhs.expr);
			bool is_poly_const = pe != nullptr && pe->kind == Entity_Variable &&
			                     (pe->flags & EntityFlag_PolyConst) != 0;
			if (!is_poly_const) {
				error(rhs.expr, "A vector lane index must be an assemble-time integer constant");
			}
		}

		if (build_context.metrics.arch != TargetArch_arm64) {
			error(expr, "The target platform does not support vector element extraction syntax");
		}

		operand->expr = expr;
		operand->mode = Addressing_Value;
		operand->type = base_array_type(lhs.type);
		operand->value = {};

		add_type_and_value(ctx, operand->expr, operand->mode, operand->type, operand->value);

		if (rhs.mode == Addressing_Constant) {
			add_type_and_value(ctx, rhs.expr, rhs.mode, rhs.type, rhs.value);
		}
		return;
	case_end;

	case_ast_node(be, BinaryExpr, expr);
		switch (be->op.kind) {
		case Token_Shl:
		case Token_Shr:
		case Token_Mul:
			break;
		default:
			error(be->op, "Unsupported operator '%.*s' in an asm operand; only a register shift/scale ('<<', '>>', '*') is allowed here", LIT(be->op.string));
			return;
		}

		if (build_context.metrics.arch != TargetArch_arm64) {
			error(expr, "Asm shifted/scaled register operands are not supported by the target platform");
			return;
		}

		Operand reg    = {};
		Operand amount = {};
		check_asm_instruction_operand(asm_ctx, ctx, entity, &reg,    be->left,  false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &amount, be->right, false);
		if (reg.mode == Addressing_Invalid || amount.mode == Addressing_Invalid) {
			return;
		}
		if (determine_asm_operand_kind(&reg) != AsmOperand_Register) {
			gbString s = expr_to_string(reg.expr);
			error(reg.expr, "The left-hand side of a register shift/scale must be a register, got %s", s);
			gb_string_free(s);
			return;
		}

		if (determine_asm_operand_kind(&amount) != AsmOperand_Immediate) {
			error(amount.expr, "The right side of a register shift/scale must be an immediate");
			return;
		}

		if (amount.mode == Addressing_Constant && amount.value.kind == ExactValue_Integer) {
			i64 amt = exact_value_to_i64(amount.value);
			if (be->op.kind == Token_Mul) {
				if (amt <= 0 || (amt & (amt-1)) != 0) {
					error(be->right, "A register scale using '*' must be a positive power of two, got %lld", cast(long long)amt);
					return;
				}
			} else {
				i64 max_shift = 63;
				if (reg.type != nullptr && is_type_integer(reg.type)) {
					max_shift = 8*cast(i64)type_size_of(reg.type) - 1;
				}
				if (amt < 0 || amt > max_shift) {
					error(be->right, "A register shift amount must be within 0..=%lld, got %lld", cast(long long)max_shift, cast(long long)amt);
					return;
				}
			}
		}

		operand->mode = reg.mode;
		operand->type = reg.type;
		return;
	case_end;

	case_ast_node(se, SelectorExpr, expr);
		// NOTE(bill): a procedure or constant from another package, e.g. `call libc.strlen`
		check_expr(ctx, operand, expr);
		if (operand->mode == Addressing_Invalid || operand->mode == Addressing_Constant) {
			return;
		}
		check_asm_procedure_operand(ctx, operand, expr, allow_memory_operands);
		return;
	case_end;
	}

	{
		gbString s = expr_to_string(expr);
		error(expr, "Invalid asm operand, got %s", s);
		gb_string_free(s);
	}
	return;
}

// NOTE(bill): a call out of a template may write any register (see `asm_call_clobber_families`), so all of them are clobbered.
// That leaves LLVM nowhere to allocate a register operand, so each unpinned one is pinned to a register the template does not
// otherwise name: LLVM already knows the template writes an output or scratch, and an input there is tied to a discarded output.
template <typename AsmCtx>
gb_internal void check_asm_template_call_clobbers(AsmCtx *asm_ctx, Entity *entity, AstAsmTemplate *at) {
	auto *ate = &entity->AsmTemplate;

	// NOTE(bill): the registers the template already uses: those it names or reads implicitly (e.g. %rdx for div),
	// those its parameters are pinned to, and those it clobbers (which includes every register it writes)
	AsmBodyRefs refs = {};
	asm_body_refs_init(asm_ctx, &refs, at);
	defer (asm_body_refs_destroy(&refs));

	StringSet *taken = &refs.families;
	for (u16 bit = 1; bit != 0; bit <<= 1) {
		if ((refs.bits & bit) != 0) {
			String name   = make_string_c(asm_ctx->clobber_reg_bit_name(bit));
			String family = asm_register_family_name(asm_ctx, name);
			string_set_add(taken, family.len != 0 ? family : name);
		}
	}
	for (auto const &ed : ate->decls) {
		String family = asm_register_family_name(asm_ctx, ed.pin);
		if (family.len != 0) {
			string_set_add(taken, family);
		}
	}
	for (String const &reg : ate->clobber_registers_set) {
		string_set_add(taken, reg);
	}

	StringSet written_operands = {}; // the registers of outputs and scratch
	string_set_init(&written_operands);
	defer (string_set_destroy(&written_operands));

	TEMPORARY_ALLOCATOR_GUARD();

	for (auto &ed : ate->decls) {
		if (ed.view_of >= 0) {
			continue;
		}
		bool in_register = false;
		switch (ed.param_group) {
		case AsmTemplateEntityDeclParamGroup_Input:
			in_register = ed.tie < 0 && (ed.kind == AsmTemplateEntityDecl_Register || ed.kind == AsmTemplateEntityDecl_Memory);
			break;
		case AsmTemplateEntityDeclParamGroup_Output:
			in_register = ed.kind == AsmTemplateEntityDecl_Register || ed.kind == AsmTemplateEntityDecl_Memory;
			break;
		case AsmTemplateEntityDeclParamGroup_Scratch:
			in_register = ed.kind == AsmTemplateEntityDecl_Register;
			break;
		}
		if (!in_register) {
			continue;
		}

		if (ed.pin.len == 0) {
			auto candidates = array_make<String>(temporary_allocator());
			asm_call_pin_candidates(asm_ctx, ed.reg_class, &candidates);
			for (String const &candidate : candidates) {
				if (!string_set_exists(taken, candidate)) {
					ed.pin = candidate;
					break;
				}
			}
			if (ed.pin.len == 0) {
				error(ed.entity->token,
				      "'asm' parameter '%.*s' needs a register, but this template calls out of itself, "
				      "which may write every register, and every register it could use is already named or pinned in the template",
				      LIT(ed.entity->token.string));
				continue;
			}
			string_set_add(taken, ed.pin);
		}

		if (ed.param_group != AsmTemplateEntityDeclParamGroup_Input) {
			String family = asm_register_family_name(asm_ctx, ed.pin);
			if (family.len != 0) {
				string_set_add(&written_operands, family);
			}
		}
	}

	auto families = array_make<String>(temporary_allocator());
	asm_call_clobber_families(asm_ctx, &families);
	for (String const &family : families) {
		if (string_set_exists(&written_operands, family)) {
			continue;
		}
		asm_clobber_written_register(asm_ctx, entity, family);
	}
	ate->clobber_flags  = true;
	ate->clobber_memory = true;
}

// NOTE(bill): the signature is everything needed to call an asm template, the rest is checked by `check_asm_template_body`
gb_internal bool check_asm_template_signature(CheckerContext *ctx, Entity *entity, DeclInfo *d) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;

	ast_node(at, AsmTemplate, d->init_expr);

	GB_ASSERT(at->signature != nullptr);
	if (at->signature->kind != Ast_ProcType) {
		error(at->signature, "Expected a valid signature, got %.*s", LIT(ast_strings[at->signature->kind]));
		entity->type = t_invalid;
		return false;
	}
	AstProcType *pt = &at->signature->ProcType;

	ate->param_scope = create_scope(ctx->info, ctx->scope);
	ate->label_scope = create_scope(ctx->info, ctx->scope);

	ate->decls.allocator = heap_allocator();

	Type *params  = check_asm_template_signature_params(ctx, ate->param_scope, pt->params,  true,  &ate->decls);
	Type *results = check_asm_template_signature_params(ctx, ate->param_scope, pt->results, false, &ate->decls);

	Type *type = alloc_type_proc(ate->param_scope, params, params->Tuple.variables.count, results, results->Tuple.variables.count, false, pt->calling_convention);
	type->Proc.diverging = pt->diverging;
	if (!type->Proc.diverging && results->Tuple.variables.count != 0) {
		// always require the results of `asm` templates
		type->Proc.require_results = true;
	}
	entity->type   = type;
	ate->proc_type = type;

	AttributeContext ac = make_attribute_context({}, {});
	check_decl_attributes(ctx, d->attributes, proc_decl_attribute, &ac);
	check_target_feature_attributes(ac, entity, type);
	return true;
}

// NOTE(bill): the specification block, the clobbers, and the instructions
template <typename AsmCtx>
gb_internal void check_asm_template_body(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *entity, DeclInfo *d) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;

	ast_node(at, AsmTemplate, d->init_expr);

	Type *type = ate->proc_type;
	GB_ASSERT(type != nullptr && type->kind == Type_Proc);

	check_asm_specs(asm_ctx, ctx, ate->param_scope, at->specs, &ate->decls);

	auto set_once = [](bool *flag, Token name) {
		if (*flag) {
			error(name, "#%.*s has already been defined as an asm specification", LIT(name.string));
		}
		*flag = true;
	};

	bool is_pure_annotated = false;
	{ // check clobbers
		auto *clobber_registers_set  = &ate->clobber_registers_set;
		auto *preserve_registers_set = &ate->preserve_registers_set;

		for (Ast *clobber_ : at->clobbers) {
			ast_node(clobber, AsmClobber, clobber_);

			if (clobber->value == nullptr) {
				if (clobber->name.string == "volatile") {
					set_once(&ate->is_volatile, clobber->name);
				} else if (clobber->name.string == "align_stack") {
					set_once(&ate->is_align_stack, clobber->name);
				} else if (clobber->name.string == "pure") {
					set_once(&is_pure_annotated, clobber->name);
				} else {
					error(clobber->name, "Unknown clobber directive '#%.*s'", LIT(clobber->name.string));
				}
				continue;
			}

			if (clobber->name.string != "preserve" && clobber->name.string != "clobber") {
				error(clobber->name, "Unknown clobber directive '#%.*s'", LIT(clobber->name.string));
				continue;
			}

			bool is_preserve = clobber->name.string == "preserve";
			auto *target_set = is_preserve ? preserve_registers_set : clobber_registers_set;

			switch (clobber->value->kind) {
			case_ast_node(asm_reg, AsmRegister, clobber->value)
				String reg = asm_reg->name.string;

				if (reg == "flags") {
					// `%flags` clobbers all condition flags — the preferred spelling.
					// A specific flag bit (`%flags.z`) can't be individually clobbered,
					// and flags are meaningless for `#preserve`.
					if (asm_reg->flag.string != "") {
						error(asm_reg->flag, "#%.*s on a specific flag ('%%flags.%.*s') is not allowed; use '%%flags' to clobber all condition flags",
						      LIT(clobber->name.string), LIT(asm_reg->flag.string));
					} else if (is_preserve) {
						error(clobber->value, "Expected a register for a '#preserve' specification, got '%%flags'");
					} else if (ate->clobber_flags) {
						error(clobber->value, "#clobber %%flags has already been defined");
					} else {
						ate->clobber_flags = true;
					}
				} else {
					if (asm_reg->flag.string != "") {
						error(asm_reg->flag, "#%.*s on specific flags is not allowed", LIT(clobber->name.string));
					}
					Operand operand = {};
					if (check_register(asm_ctx, &operand, asm_reg)) {
						if (string_set_update(target_set, reg)) {
							error(clobber->value, "#%.*s %%%.*s has already been defined", LIT(clobber->name.string), LIT(reg));
						}
					}
				}
			case_end;
			case_ast_node(ident, Ident, clobber->value);
				String str = ident->token.string;
				if (is_preserve) {
					// #preserve applies only to registers, not flags/memory.
					error(clobber->value, "Expected a register for a '#preserve' specification, got '%.*s'", LIT(str));
				} else if (str == "flags") {
					// Deprecated bare-identifier spelling; `%flags` is the register form.
					warning(clobber->value, "#clobber flags is deprecated; use '#clobber %%flags' instead");
					if (ate->clobber_flags) {
						error(clobber->value, "#clobber flags has already been defined");
					}
					ate->clobber_flags = true;
				} else if (str == "memory") {
					if (ate->clobber_memory) {
						error(clobber->value, "#clobber memory has already been defined");
					}
					ate->clobber_memory = true;
				} else {
					error(clobber->value, "Expected either a register, 'flags', or 'memory' for a '#%.*s' specification, got '%.*s'", LIT(clobber->name.string), LIT(str));
				}
			case_end;
			default:
				error(clobber->value, "Expected a register%s for a '#%.*s' specification",
				      is_preserve ? "" : ", 'flags', or 'memory'",
				      LIT(clobber->name.string));
				break;
			}
		}

		asm_normalize_register_names(asm_ctx, clobber_registers_set);
		asm_normalize_register_names(asm_ctx, preserve_registers_set);
	}


	// Two distinct operands pinned to the same physical register only makes sense when
	// they are tied (they intentionally share one register). Compared by register family so
	// %eax and %rax collide. Flag pins ("flags") have no family and are skipped.
	for_array(i, ate->decls) {
		auto const &a = ate->decls[i];
		if (a.pin.len == 0) {
			continue;
		}
		String afamily = asm_register_family_name(asm_ctx, a.pin);
		if (afamily.len == 0) {
			continue;
		}
		for (isize j = i+1; j < ate->decls.count; j++) {
			auto const &b = ate->decls[j];
			if (b.pin.len == 0 || asm_register_family_name(asm_ctx, b.pin) != afamily) {
				continue;
			}
			bool tied = (a.tie == cast(i32)j) || (b.tie == cast(i32)i);
			if (tied) {
				continue;
			}
			error(b.entity ? b.entity->token : entity->token,
			      "Parameters '%.*s' and '%.*s' are both pinned to %%%.*s but are not tied",
			      LIT(a.entity->token.string), LIT(b.entity->token.string),
			      LIT(afamily));
		}
	}

	// NOTE(bill): LLVM does not allow a clobber of a register that is also an output
	for (auto const &ed : ate->decls) {
		if (ed.param_group != AsmTemplateEntityDeclParamGroup_Output || ed.pin.len == 0) {
			continue;
		}
		String family = asm_register_family_name(asm_ctx, ed.pin);
		if (family.len == 0) {
			continue;
		}
		if (string_set_exists(&ate->clobber_registers_set, family)) {
			error(ed.entity->token,
			      "'asm' output '%.*s' is pinned to %%%.*s, which '#clobber' also names; an output's register is already written, so remove the '#clobber'",
			      LIT(ed.entity->token.string), LIT(ed.pin));
		}
	}

	// collect label decls
	for (Ast *instruction_ : at->instructions) {
		switch (instruction_->kind) {
		case_ast_node(label, AsmLabelDecl, instruction_);
			GB_ASSERT(label->name->kind == Ast_Ident);
			Ast *name = label->name;
			if (is_blank_ident(name)) {
				error(name, "Asm label definition cannot be '_'");
				continue;
			}
			Entity *label_entity = alloc_entity_label(ate->label_scope, name->Ident.token, nullptr, instruction_, nullptr);
			Entity *found = scope_insert(ate->label_scope, label_entity);
			if (found != nullptr) {
				TokenPos pos = found->token.pos;
				error(name,
				      "Redeclaration of the label '%.*s' in this scope\n"
				      "\tat %s",
				      LIT(name->Ident.token.string), token_pos_to_string(pos));
				continue;
			}
			name->Ident.entity = label_entity;
		case_end;
		}
	}

	// NOTE(bill, 2026-08-24): Construct a control-flow graph (CFG) from the instructions
	// to do further analysis which is not possible with an conservative straight-line approximation
	// Using a CFG is a much sounder approach for calculating:
	// * read-before-writes
	//   * sub-register width checks
	//   * `%flags` checks
	// * divergence
	// * unreachable code
	// * liveness checks (forward and backwards)

	// NOTE(bill): the AsmCfg structure also hold information which is used to in the linear pass
	// mainly because it will be used later on by it, so it makes sense to keep them together as
	// one unit rather than two separate structures.

	AsmCfg cfg = {};
	asm_cfg_init(&cfg);
	defer (asm_cfg_destroy(&cfg));

	Array<Operand> operands = {};
	operands.allocator = heap_allocator();
	array_reserve(&operands, 16);
	defer (array_free(&operands));

	u8 previous_prefix = 0;
	Ast *previous_prefix_instr = nullptr; // for a good error location
	bool all_instructions_good = true;

	for (Ast *instruction_ : at->instructions) {
		switch (instruction_->kind) {
		case_ast_node(instr, AsmInstruction, instruction_);
			GB_ASSERT(instr->name->kind == Ast_Ident);

			u16 mnemonic     = 0;
			u8  suffix_flags = 0;
			CheckMnemomicResult res = check_mnemonic_name(asm_ctx, instr, &mnemonic, &suffix_flags);

			array_clear(&operands);
			for (Ast *expr : instr->operands) {
				Operand operand = {};
				check_asm_instruction_operand(asm_ctx, ctx, entity, &operand, expr, /*allow_memory_operands*/true);
				array_add(&operands, operand);
			}

			if (res == CheckMnemomic_Prefix) {
				if (instr->operands.count != 0) {
					error(instr->name, "A prefix must not have any operands, and be separate from the instruction it is prefixing");
				}
				if (previous_prefix != 0) {
					error(instr->name, "A prefix cannot immediately follow another prefix");
				}
				previous_prefix = cast(u8)mnemonic;
				previous_prefix_instr = instruction_;
				break;
			}

			instr->suffix_flags = suffix_flags;
			switch (res) {
			case CheckMnemomic_Mnemonic:
				all_instructions_good &= check_mnemonic(asm_ctx, ctx, entity, instr, mnemonic, 0, slice_from_array(operands),
				                                        previous_prefix, previous_prefix_instr,
				                                        &cfg);
				break;
			case CheckMnemomic_PseudoMnemonic: {
				u16 target_mnemonic = cast(u16)asm_ctx->pseudo_alias(mnemonic).target;
				all_instructions_good &= check_mnemonic(asm_ctx, ctx, entity, instr, target_mnemonic, mnemonic, slice_from_array(operands),
				                                        previous_prefix, previous_prefix_instr,
				                                        &cfg);
				break;
			}
			case CheckMnemomic_PseudoMacroMnemonic:
				all_instructions_good &= check_pseudo_macro_mnemonic(asm_ctx, entity, instr, slice_from_array(operands));
				break;
			}
			cfg.saw_any_instructions |= res != CheckMnemomic_Invalid;

			// NOTE(bill): an invalid mnemonic was already reported, and a pending prefix now has no target
			previous_prefix = 0;
			previous_prefix_instr = nullptr;
		case_end;

		case_ast_node(label, AsmLabelDecl, instruction_);
			if (previous_prefix != 0) {
				error(previous_prefix_instr, "A prefix must be immediately followed by an instruction, but a label declaration was found");
				previous_prefix = 0;
				previous_prefix_instr = nullptr;
			}
		case_end;

		case_ast_node(dir, AsmDirective, instruction_);
			String name     = dir->name.string;
			bool   is_byte  = name == "byte";
			bool   is_align = name == "align";
			if (!is_byte && !is_align && name != "skip" && name != "nop") {
				error(dir->name, "Unknown asm directive: #%.*s", LIT(name));
				break;
			}
			if (is_byte && dir->operands.count == 0) {
				error(dir->name, "Expected 1 or more integers for the asm directive #%.*s", LIT(name));
				break;
			}
			if (!is_byte && dir->operands.count != 1) {
				error(dir->name, "Expected 1 integer for the asm directive #%.*s", LIT(name));
				break;
			}

			array_clear(&operands);
			for (Ast *expr : dir->operands) {
				Operand operand = {};
				check_asm_instruction_operand(asm_ctx, ctx, entity, &operand, expr, /*allow_memory_operands*/true);
				array_add(&operands, operand);
			}

			char const *expected = is_byte ? "an integer" : is_align ? "a power-of-two integer" : "an integer >0";
			for (auto &op : operands) {
				ExactValue ev = exact_value_to_integer(op.value);
				if (op.mode != Addressing_Constant || (!is_byte && ev.kind != ExactValue_Integer)) {
					error(op.expr, "Expected %s for the asm directive #%.*s", expected, LIT(name));
					continue;
				}
				if (is_byte) {
					check_assignment(ctx, &op, t_u8, str_lit("asm '#byte' directive"));
					continue;
				}
				i64 i = exact_value_to_i64(ev);
				if (i < 0 || (is_align && !is_power_of_two(i))) {
					error(op.expr, "Expected %s for the asm directive #%.*s, got %lld", expected, LIT(name), cast(long long)i);
				}
			}
		case_end;

		default:
			error(instruction_, "Unexpected instruction in asm template");
			break;
		}
	}
	if (previous_prefix != 0) {
		error(previous_prefix_instr, "A prefix must be immediately followed by an instruction, but the template ended");
	}


	for (auto const &ed : ate->decls) {
		if (is_type_simd_vector(ed.entity->type)) {
			i32 vw = cast(i32)(type_size_of(ed.entity->type) * 8);
			String feat = asm_ctx->required_vector_feature(vw);
			if (feat.len != 0 && !check_asm_template_feature_is_enabled(entity, feat)) {
				error(ed.entity->token,
				      "'asm' vector operand '%.*s' is %d-bit, which requires the '%.*s' target feature",
				      LIT(ed.entity->token.string), vw, LIT(feat));
			}
		}

		if (ed.param_group == AsmTemplateEntityDeclParamGroup_Output) {
			if (ed.tie >= 0 || ed.no_init) {
				// ignore
			} else if (ed.pin.len != 0) {
				auto r = asm_ctx->register_lookup(ed.pin);
				if (asm_ctx->reg_is_non_allocateable(r)) {
					error(ed.entity->token,
					      "'asm' output '%.*s' is pinned to a register '%%%.*s' which cannot be an output; "
					      "read it into a general-purpose register in the body instead "
					      "(e.g. on AMD64, 'mov %%rax, %%%.*s' with the output pinned to %%rax)",
					      LIT(ed.entity->token.string), LIT(ed.pin), LIT(ed.pin));
				}
			}
		}
	}

	// NOTE(bill): After the linear collection pass of the mnemonics,
	// now do the CFG building, analysis, and liveness checks (only if everything was correct)

	check_asm_cfg_build(asm_ctx, &cfg, d->init_expr, entity);
	check_asm_cfg_analyse(asm_ctx, &cfg, entity);
	if (all_instructions_good) {
		check_asm_cfg_liveness(asm_ctx, &cfg, entity);
	}


	AstFile *file = ctx->file ? ctx->file : entity->file;
	if (ast_file_vet_flags(file) & VetFlag_UnusedVariables) {
		for (auto const &entry : ate->label_scope->elements) {
			Entity *le = entry.value;
			if ((le->flags & EntityFlag_Used) == 0) {
				error(le->token, "'asm' label '.%.*s' is declared but never referenced by any instruction", LIT(le->token.string));
			}
		}

		AsmBodyRefs refs = {};
		asm_body_refs_init(asm_ctx, &refs, at);
		defer (asm_body_refs_destroy(&refs));

		for (auto const &ed : ate->decls) {
			bool is_scratch   = ed.param_group == AsmTemplateEntityDeclParamGroup_Scratch && ed.view_of < 0;
			bool is_immediate = ed.kind        == AsmTemplateEntityDecl_Immediate;
			bool is_input     = ed.param_group == AsmTemplateEntityDeclParamGroup_Input;
			if (!is_scratch && !is_immediate && !is_input) {
				continue;
			}
			// Used if its identifier is referenced, or for a pinned one, if its register is
			// touched in the body or the body calls out (the callee may take it as an argument).
			if (ptr_set_exists(&refs.entities, ed.entity)) {
				continue;
			}
			if (ed.pin.len != 0 && (refs.calls_out || asm_body_refs_register(asm_ctx, &refs, ed.pin))) {
				continue;
			}
			if (ed.tie >= 0) {
				// TODO(bill): Handle this edge case?
				continue;
			}

			char const *what = is_immediate ? "immediate" :
			                   is_input     ? "input" :
			                                  "scratch";
			error(ed.entity->token, "'asm' %s parameter '%.*s' is declared but never used", what, LIT(ed.entity->token.string));
		}
	}

	if (type->Proc.result_count == 0 && !ate->is_volatile && !ate->clobber_memory && ate->has_observable_side_effect) {
		warning(entity->token,
		        "This asm template has an observable effect but declares no outputs "
		        "and does not #volatile in the specification block; it may be optimized away. "
		        "Please add #volatile if the effect is intended.");
	}

	// NOTE(bill): without #align_stack, the stack need not be aligned for a call, and LLVM may keep a procedure's values below
	// the stack pointer (the red zone on SysV), where a push or call in the template would overwrite them
	if (cfg.stack_use != nullptr && !ate->is_align_stack) {
		error(cfg.stack_use_node,
		      "This 'asm' template must declare #align_stack as it %s here; without it, the stack may not be aligned for a call, "
		      "and the procedure may keep values below the stack pointer, where the template would overwrite them",
		      cfg.stack_use);
	} else if (ate->is_align_stack && cfg.stack_use == nullptr) {
		warning(entity->token,
		        "#align_stack is redundant; this template neither pushes onto the stack, makes a call, nor writes the stack pointer");
	}

	bool declared_effects = ate->is_volatile || ate->clobber_memory || ate->has_observable_side_effect;
	ate->is_pure = cfg.can_be_pure && !declared_effects && !type->Proc.diverging;
	if (is_pure_annotated && !ate->is_pure) {
		char const *why = cfg.impure_reason;
		if (why == nullptr) {
			if (type->Proc.diverging) {
				why = "it is declared diverging (-> !) and computes no outputs";
			} else if (ate->clobber_memory) {
				why = "it declares '#clobber memory'";
			} else if (ate->is_volatile) {
				why = "it is declared '#volatile'";
			} else {
				why = "it declares an observable effect";
			}
		}
		Token tok = cfg.impure_reason_node ? ast_token(cfg.impure_reason_node) : entity->token;
		error(tok, "'asm' template is marked #pure but it is not pure: %s", why);
	}

	if (cfg.calls_out) {
		check_asm_template_call_clobbers(asm_ctx, entity, at);
	}

	// NOTE(bill): a pinned input whose register is written by name or implicitly is tied, not clobbered.
	// See `check_asm_mark_input_written` for writes through the parameter.
	for (auto &ed : ate->decls) {
		if (ed.param_group != AsmTemplateEntityDeclParamGroup_Input ||
		    ed.tie         >= 0                                     ||
		    ed.view_of     >= 0                                     ||
		    ed.pin.len     == 0) {
			continue;
		}
		// NOTE(bill): a pointer or procedure input is passed in a register too
		if (ed.kind != AsmTemplateEntityDecl_Register &&
		    ed.kind != AsmTemplateEntityDecl_Memory) {
			continue;
		}
		String family = asm_register_family_name(asm_ctx, ed.pin);
		u16    bit    = asm_ctx->clobber_bit_for_reg_name(ed.pin);
		if (family.len == 0 && bit == 0) {
			continue;
		}

		TEMPORARY_ALLOCATOR_GUARD();
		auto names = array_make<String>(temporary_allocator());
		for (String const &reg : ate->clobber_registers_set) {
			// NOTE(bill): an implicit clobber may be named by its bit (e.g. lr) rather than its family (x30)
			bool same_family = family.len != 0 && asm_register_family_name(asm_ctx, reg) == family;
			bool same_bit    = bit != 0 && asm_ctx->clobber_bit_for_reg_name(reg) == bit;
			if (same_family || same_bit) {
				array_add(&names, reg);
			}
		}
		for (String const &reg : names) {
			string_set_remove(&ate->clobber_registers_set, reg);
		}
		ed.overwritten |= names.count != 0;
	}
}

gb_internal void check_asm_template_from_entity(CheckerContext *c, Entity *e, DeclInfo *d) {
	GB_ASSERT(e->decl_info == d);
	if (!check_asm_template_signature(c, e, d)) {
		return;
	}
	switch (build_context.metrics.arch) {
	case TargetArch_amd64:
	case TargetArch_riscv64:
	case TargetArch_arm64:
		check_asm_template_body_later(c, e);
		break;
	default:
		error(e->token, "asm templates are not currently supported for this target");
		break;
	}
}

gb_internal void check_asm_template_body_from_entity(CheckerContext *c, Entity *e) {
	GB_ASSERT(e->kind == Entity_AsmTemplate);
	DeclInfo *d = e->decl_info;
	GB_ASSERT(d != nullptr);

	Entity *anonymous_entity = e->AsmTemplate.node->AsmTemplate.anonymous_entity;
	if (anonymous_entity != nullptr && anonymous_entity != e) {
		// NOTE(bill): the call it is in was checked again and only the entity it made last is used
		return;
	}

	CheckerContext ctx = *c;
	ctx.scope = d->scope;
	ctx.decl  = d;

	if (build_context.metrics.arch == TargetArch_amd64) {
		check_asm_template_body(&g_asm_amd64, &ctx, e, d);
	} else if (build_context.metrics.arch == TargetArch_riscv64) {
		check_asm_template_body(&g_asm_riscv, &ctx, e, d);
	} else if (build_context.metrics.arch == TargetArch_arm64) {
		check_asm_template_body(&g_asm_arm64, &ctx, e, d);
	} else {
		GB_PANIC("asm templates are not supported for this target");
	}

	add_deps_from_child_to_parent(d);
	e->flags |= EntityFlag_ProcBodyChecked;
}
