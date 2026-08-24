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

gb_internal bool is_valid_asm_parameter_type(Type *type) {
	if (is_type_integer(type)) {
		// NOTE(bill): do not allow 128-bit integers
		return type_size_of(type) <= 8;
	}
	if (is_type_float(type)) {
		return true;
	}
	if (is_type_boolean(type)) {
		return true;
	}
	if (is_type_internally_pointer_like(type)) {
		return true;
	}
	if (is_type_simd_vector(type)) {
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
	case_ast_node(ident, Ident, expr);
		// TODO(bill): Is this correct?
		if (expr->tav.mode == Addressing_Constant) {
			return AsmOperand_Immediate;
		}
		Entity *e = entity_of_node(expr);
		if (e != nullptr && e->kind == Entity_Variable && (e->flags & EntityFlag_PolyConst) != 0) {
			return AsmOperand_Immediate;
		}
		return AsmOperand_Register;
	case_end;
	}
	return AsmOperand_Invalid;
}

gb_internal bool asm_reg_class_compatible(AsmRegClass want, AsmRegClass got) {
	switch (want) {
	case AsmRegClass_Integer:
		return got == AsmRegClass_Integer;
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


// Collect param/immediate entities referenced anywhere in an operand expr (incl.
// nested memory sub-operands). Reads Ident.entity, which check_asm_instruction_operand
// populates during operand checking.
template <typename AsmCtx>
gb_internal void check_asm_collect_refs(AsmCtx *asm_ctx, PtrSet<Entity *> *refs, Ast *expr, u16 *touched_regs_) {
	if (expr == nullptr) {
		return;
	}
	switch (expr->kind) {
	case Ast_Ident:
		if (expr->Ident.entity != nullptr) {
			ptr_set_add(refs, cast(Entity *)expr->Ident.entity);
		}
		return;
	case Ast_AsmRegister:
		// A literal %reg touches a physical register. A pinned scratch/immediate is
		// referenced in the body via its pinned register, not its identifier, so record
		// the bit; the unused check maps decl pins back through this mask.
		if (touched_regs_) *touched_regs_ |= asm_ctx->clobber_bit_for_reg_name(expr->AsmRegister.name.string);
		return;
	case Ast_AsmMemoryOperand: {
		auto *m = &expr->AsmMemoryOperand;
		check_asm_collect_refs(asm_ctx, refs, m->segment_override, touched_regs_);
		check_asm_collect_refs(asm_ctx, refs, m->base,             touched_regs_);
		check_asm_collect_refs(asm_ctx, refs, m->index,            touched_regs_);
		check_asm_collect_refs(asm_ctx, refs, m->scale,            touched_regs_);
		check_asm_collect_refs(asm_ctx, refs, m->disp,             touched_regs_);
		return;
	}
	}
}
enum AsmMismatch : u8 {
	AsmMismatch_None,
	AsmMismatch_Size,      // register / vector width mismatch
	AsmMismatch_Class,     // register class mismatch
	AsmMismatch_ImmRange,  // constant immediate does not fit the slot width
	AsmMismatch_ImmType,   // non-integer constant where an integer immediate is required
	AsmMismatch_NamedReg,  // slot only a named hardware register can fill
};

// Does a constant immediate value fit a slot of `bits` width (0 == unconstrained)?
// Accepts either a signed or an unsigned interpretation of the bit pattern, which
// matches how the assembler treats imm fields (e.g. both 200 and -56 fit imm8).
gb_internal bool check_asm_immediate_value_fits(ExactValue ev, i32 bits, i32 *needed_, AsmMismatch *mismatch_) {
	if (ev.kind == ExactValue_Float) {
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

// Returns true if the operand's Odin type is size/class-compatible with the form's slot.
// On mismatch, fills *mismatch_ for a precise diagnostic. `slot` here is the
// resolved OperandType at the correct (implicit-skipped) slot.
template <typename AsmCtx>
gb_internal bool check_asm_operand_size_class(AsmCtx *asm_ctx, typename AsmCtx::OperandType slot, Operand const *operand,
                                              AsmMismatch *mismatch_, i32 *want_bits_, i32 *got_bits_) {
	if (mismatch_) *mismatch_ = AsmMismatch_None;

	AsmOperandKind slot_kind = asm_ctx->kind_from_operand_type(slot);
	if (slot_kind == AsmOperand_Immediate) {
		i32 want_w = asm_ctx->operand_type_bit_width(slot);   // 32 for OP_IMM32
		if (want_bits_) *want_bits_ = want_w;
		if (operand->mode != Addressing_Constant) {
			return true;   // $-immediate, bound per instantiation; defer
		}
		i32 needed = 0;
		ExactValue ev = operand->value;
		bool ok = check_asm_immediate_value_fits(ev, want_w, &needed, mismatch_);
		if (got_bits_) *got_bits_ = needed;
		return ok;
	}

	// Register / memory-sized slots
	AsmRegClass want_class = asm_ctx->operand_type_reg_class(slot);
	i32         want_w     = asm_ctx->operand_type_bit_width(slot);

	// A slot only a named hardware register can fill (segment/control/debug/x87/MMX)
	// carries no class and, apart from MMX, no width either. Nothing below would
	// reject a template parameter standing in for one.
	u16 want_named = asm_ctx->operand_type_named_reg_class(slot);
	if (want_named != 0) {
		bool ok = false;
		if (operand->expr != nullptr && operand->expr->kind == Ast_AsmRegister) {
			auto r = asm_ctx->register_lookup(operand->expr->AsmRegister.name.string);
			ok = r && asm_ctx->reg_class(asm_ctx->register_codes[r]) == want_named;
		}
		if (!ok) {
			if (mismatch_) *mismatch_ = AsmMismatch_NamedReg;
			return false;
		}
		return true;
	}

	// A pure-label / sizeless slot imposes no reg width/class.
	if (want_class == AsmRegClass_Unknown && want_w == 0) {
		return true;
	}

	// Determine the type whose width/class we actually measure.
	//
	// Memory operands encode their *access* type as a pointer: `[p]:u8` -> `^u8`,
	// with a bare `rawptr` meaning "unsized" (no explicit `:type` annotation). A
	// register/immediate/parameter operand measures its own type directly.
	Type      *measured   = operand->type;
	bool       is_memory  = (determine_asm_operand_kind(operand) == AsmOperand_Memory);
	if (is_memory) {
		if (are_types_identical(measured, t_rawptr)) {
			// Unsized memory operand: the width is inferred elsewhere (from the
			// register operand or deferred), so nothing to check against here.
			if (want_bits_) *want_bits_ = want_w;
			return true;
		}
		measured = type_deref(measured); // ^u8 -> u8
	}

	AsmRegClass got_class = check_asm_reg_class_from_type(measured);
	i32         got_w     = check_asm_operand_bit_width(measured);
	if (got_w < 0) {
		// Untyped constant: width is a property of the value, not the type.
		if (operand->mode == Addressing_Constant && operand->value.kind == ExactValue_Integer) {
			got_w = cast(i32)mp_count_bits(&operand->value.value_integer);
			if (got_w == 0) {
				got_w = 1; // zero still occupies a slot
			}
		} else {
			got_w = 0; // unknown; skip the width comparison rather than fake a pass
		}
	}
	if (want_bits_) *want_bits_ = want_w;
	if (got_bits_)  *got_bits_  = got_w;

	// Class check (only when the slot constrains a class).
	//
	// A *memory* operand against a register-or-memory slot (e.g. OP_XMM_M64) has no
	// lane semantics -- it is just N bytes of memory -- so its integer/vector class
	// must not be held against the slot's register class. Only width matters for the
	// memory interpretation. Register operands still get the full class check.
	if (want_class != AsmRegClass_Unknown && !is_memory) {
		if (!asm_reg_class_compatible(want_class, got_class)) {
			if (mismatch_) *mismatch_ = AsmMismatch_Class;
			return false;
		}
	}

	// Width check.
	if (want_w != 0 && got_w != 0) {
		if (want_class == AsmRegClass_Vector && !is_memory) {
			// A scalar float uses only the low lane, so it may be narrower than the
			// slot; a #simd vector must match the vector width exactly.
			bool width_ok = (got_class == AsmRegClass_Float) ? (got_w <= want_w) : (got_w == want_w);
			if (!width_ok) {
				if (mismatch_) *mismatch_ = AsmMismatch_Size;
				return false;
			}
		} else if (want_class == AsmRegClass_Float &&
		           got_class  == AsmRegClass_Float && !is_memory &&
		           !asm_ctx->float_reg_width_is_exact()) {
			// NOTE(bill): architectures such as RISC-V have registers which are
			// always the architecture width
			if (got_w > want_w) {
				if (mismatch_) *mismatch_ = AsmMismatch_Size;
				return false;
			}
		} else if (want_class == AsmRegClass_Integer && !is_memory &&
		           !asm_ctx->integer_reg_width_is_exact()) {
			// NOTE(bill): architectures such as RISC-V have registers which are
			// always the architecture width
			if (got_w > want_w) {
				if (mismatch_) *mismatch_ = AsmMismatch_Size;
				return false;
			}
		} else {
			// Integer/mask registers on exact-width targets, and all memory operands.
			if (want_w != got_w) {
				if (mismatch_) *mismatch_ = AsmMismatch_Size;
				return false;
			}
		}
	}
	return true;
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

		if (!is_valid_asm_parameter_type(type)) {
			gbString s = type_to_string(type);
			error(field->type, "Invalid type for an asm template. It must be an integer, float, boolean, pointer, multi-pointer, or #simd vector, got '%s'", s);
			gb_string_free(s);
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
				TokenPos pos = found->token.pos;
				error(name_token,
				      "Redeclaration of '%.*s' in this scope\n"
				      "\tat %s",
				      LIT(name_token.string), token_pos_to_string(pos));
				entity = found;
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

gb_internal AsmTemplateEntityDeclParamGroup check_asm_find_group(Entity *entity, Array<AsmTemplateEntityDecl> const &asm_template_entity_decls, i32 *index_) {
	for_array(i, asm_template_entity_decls) {
		auto const &ed = asm_template_entity_decls[i];
		if (ed.entity == entity) {
			if (index_) *index_ = cast(i32)i;
			return ed.param_group;
		}
	}
	if (index_) *index_ = -1;
	return AsmTemplateEntityDeclParamGroup_Unknown;
};

gb_internal AsmTemplateEntityDeclKind check_asm_find_kind(Entity *entity, Array<AsmTemplateEntityDecl> const &asm_template_entity_decls) {
	for (auto const &ed : asm_template_entity_decls) {
		if (ed.entity == entity) {
			return ed.kind;
		}
	}
	return AsmTemplateEntityDecl_Invalid;
};

gb_internal bool check_asm_is_immediate_param(Entity *tmpl_entity, Operand const *o) {
	Entity *pe = entity_of_node(o->expr);
	if (pe != nullptr && pe->kind == Entity_Variable) {
		return check_asm_find_kind(pe, tmpl_entity->AsmTemplate.decls) == AsmTemplateEntityDecl_Immediate;
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
					auto group = check_asm_find_group(other_scratch, *asm_template_entity_decls, nullptr);
					if (!group) {
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
				if (!is_valid_asm_parameter_type(type)) {
					gbString s = type_to_string(type);
					error(spec->type, "Invalid type for an asm template. It must be an integer, float, boolean, pointer, multi-pointer, or #simd vector, got '%s'", s);
					gb_string_free(s);
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
						GB_ASSERT(spec->value != nullptr);

						i32 src_index = -1;
						auto src_group = check_asm_find_group(other_scratch, *asm_template_entity_decls, &src_index);

						// 1. The source must already exist and be a register-class operand
						//    (you cannot take a width-view of an immediate or memory operand).
						if (src_index < 0) {
							error(spec->value, "'%.*s' must refer to a previously declared parameter", LIT(other_scratch->token.string));
						} else {
							auto &src = (*asm_template_entity_decls)[src_index];

							bool src_is_reg = src_group == AsmTemplateEntityDeclParamGroup_Input  ||
							                  src_group == AsmTemplateEntityDeclParamGroup_Output ||
							                  src_group == AsmTemplateEntityDeclParamGroup_Scratch;
							if (src.kind == AsmTemplateEntityDecl_Immediate || src.kind == AsmTemplateEntityDecl_Memory) {
								src_is_reg = false;
							}
							if (!src_is_reg) {
								error(spec->value, "A width-view can only be taken of a register operand, not '%.*s'", LIT(other_scratch->token.string));
							}

							// 2. The view width must be a legal sub-register width and no wider
							//    than the source (only narrowing views exist).
							i32 view_w = check_asm_operand_bit_width(type);          // this decl's type (u8 -> 8)
							i32 src_w  = check_asm_operand_bit_width(src.entity->type);
							AsmRegClass view_class = check_asm_reg_class_from_type(type);
							AsmRegClass src_class  = check_asm_reg_class_from_type(src.entity->type);

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
							ed.view_of    = src_index;
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
					TokenPos pos = found->token.pos;
					error(name_token,
					      "Redeclaration of '%.*s' in this scope\n"
					      "\tat %s",
					      LIT(name_token.string), token_pos_to_string(pos));
					entity = found;
					continue;
				}
			} else if (input == nullptr) {
				error(spec->name, "Undefined parameter declaration '%.*s'", LIT(spec->name->Ident.token.string));
				continue;
			} else {
				i32 index = -1;
				auto group = check_asm_find_group(input, *asm_template_entity_decls, &index);
				GB_ASSERT(index >= 0);
				auto *i = &(*asm_template_entity_decls)[index];
				if (i->pin.len == 0) {
					i->pin = pin;
					i->pin_flag = pin_flag;
					if (pin_flag.len != 0 && group != AsmTemplateEntityDeclParamGroup_Output) {
						error(spec->value, "Input parameters cannot be pinned to a flag style register");
					} else if (pin.len != 0 && pin_flag.len == 0) {
						check_asm_pin_type_compat(pin_reg_class, pin_reg_w, input->type, spec->value, pin,
						                          input->token.string);
					}
				} else {
					error(spec_, "Asm register has already been pinned");
				}

				if (other_scratch != nullptr) {
					GB_ASSERT(spec->value != nullptr);
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

			i32 input_index  = -1;
			i32 output_index = -1;

			auto input_group  = check_asm_find_group(input,  *asm_template_entity_decls, &input_index);
			auto output_group = check_asm_find_group(output, *asm_template_entity_decls, &output_index);
			if (input_group != AsmTemplateEntityDeclParamGroup_Input) {
				error(input->token, "Parameter tied with '%.*s' must be an input parameter", LIT(output->token.string));
				continue;
			}
			if (output_group != AsmTemplateEntityDeclParamGroup_Output) {
				error(output->token, "Parameter tied with '%.*s' must be an output parameter", LIT(input->token.string));
				continue;
			}

			GB_ASSERT(input_index >= 0);
			GB_ASSERT(output_index >= 0);

			auto *i = &(*asm_template_entity_decls)[input_index];
			auto *o = &(*asm_template_entity_decls)[output_index];

			i->tie = output_index;
			o->tie = input_index;

			i->pin = pin;
			o->pin = pin;
			if (pin.len != 0) {
				check_asm_pin_type_compat(pin_reg_class, pin_reg_w, input->type,  spec->value, pin, input->token.string);
				check_asm_pin_type_compat(pin_reg_class, pin_reg_w, output->type, spec->value, pin, output->token.string);
			}
			// Tied parameters share one physical register, so they must be the same register family (both integer, or both vector/float).
			// Width may legitimately differ (a narrow read feeding a wide write), so width is intentionally NOT checked.
			{
				AsmRegClass ic = check_asm_reg_class_from_type(input->type);
				AsmRegClass oc = check_asm_reg_class_from_type(output->type);
				bool i_int = (ic == AsmRegClass_Integer);
				bool o_int = (oc == AsmRegClass_Integer);
				bool i_vec = (ic == AsmRegClass_Vector || ic == AsmRegClass_Float);
				bool o_vec = (oc == AsmRegClass_Vector || oc == AsmRegClass_Float);
				if ((i_int && o_vec) || (i_vec && o_int)) {
					error(spec->name, "Tied parameters '%.*s' and '%.*s' share a register but are in different register classes",
					      LIT(input->token.string), LIT(output->token.string));
				}
			}

			if (other_scratch != nullptr) {
				GB_ASSERT(spec->value != nullptr);
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
				i32 input_index = -1;
				check_asm_find_group(input, *asm_template_entity_decls, &input_index);
				if (input_index >= 0) {
					auto *i = &(*asm_template_entity_decls)[input_index];
					i->no_init = true;
					if (i->tie >= 0) {
						auto *o = &(*asm_template_entity_decls)[i->tie];
						o->no_init = true;
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

		u16 reg_class = asm_ctx->reg_class(r);
		if (reg_class == asm_ctx->REG_CLASS_K) {
			// Opmask register: classify as a mask, not a 64-bit integer.
			// operand->type = t_asm_mask; // see note if this type does not yet exist
			// return true;
		}

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

	if (name == "li") { // li rd, imm  — dest reg + assemble-time integer that fits XLEN (or a $-immediate)
		if (operands.count != 2) {
			error(instr->name, "'%.*s' expects 2 operands, got %td", LIT(name), operands.count);
			return true; // it exists but incorrectly handled
		}
		want_int_reg(&operands[0], "destination");
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
		return true;
	} else if (name == "la" || name == "lla") { // la / lla rd, symbol  — dest reg + a label (or symbol, once representable)
		if (operands.count != 2) {
			error(instr->name, "'%.*s' expects 2 operands, got %td", LIT(name), operands.count);
			// NOTE(bill): it exists but incorrectly handled
			return true;
		}
		want_int_reg(&operands[0], "destination");
		if (determine_asm_operand_kind(&operands[1]) != AsmOperand_Label) {
			error(operands[1].expr, "'%.*s' source must be a label", LIT(name));
		}
		return true;
	}

	return false;
}

template <typename AsmCtx>
gb_internal CheckMnemomicResult check_mnemonic_name(AsmCtx *asm_ctx, AstAsmInstruction *instr, u16 *mnemonic_, u8 *suffix_flags_) {
	Token token = instr->name->Ident.token;
	GB_ASSERT_MSG(token.kind == Token_Ident || token_is_keyword(token.kind), "got %.*s of kind %.*s", LIT(token.string), LIT(token_strings[token.kind]));
	String name = token.string;
	auto p = asm_ctx->prefix_lookup(name);
	if (p) {
		if (mnemonic_) *mnemonic_ = cast(u16)p;
		return CheckMnemomic_Prefix;
	}
	auto m = asm_ctx->mnemonic_lookup(name);
	if (m) {
		if (mnemonic_) *mnemonic_ = cast(u16)m;
		return CheckMnemomic_Mnemonic;
	}
	auto pm = asm_ctx->pseudo_mnemonic_lookup(name);
	if (pm) {
		if (mnemonic_) *mnemonic_ = pm;
		return CheckMnemomic_PseudoMnemonic;
	}

	u8 suffix_flags = 0;
	auto om = asm_ctx->mnemonic_lookup_ordered(name, &suffix_flags);
	if (om) {
		if (mnemonic_)     *mnemonic_     = cast(u16)om;
		if (suffix_flags_) *suffix_flags_ = suffix_flags;
		return CheckMnemomic_Mnemonic;
	}

	auto pmm = asm_ctx->pseudo_macro_mnemonic_lookup(name);
	if (pmm) {
		if (mnemonic_) *mnemonic_ = cast(u16)pmm;
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
	bool saw_label = false;
	for (Ast *op : instr->operands) {
		if (op->kind == Ast_AsmLabelDecl) {
			saw_label = true; // resolved against label_scope during operand checking
		}
	}
	return saw_label;
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
gb_internal void check_mnemonic(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *tmpl_entity, AstAsmInstruction *instr,
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

	auto describe_form = [&](typename AsmCtx::Encoding const &form, typename AsmCtx::Clobber const &clobber) -> gbString {
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
				case AsmOperand_Memory:
					s = (w > 0) ? gb_string_append_fmt(s, "m%d", cast(int)w)
					            : gb_string_appendc(s, "m");
					break;
				case AsmOperand_Register_Or_Memory:
					s = (w > 0) ? gb_string_append_fmt(s, "%s/m%d", reg, cast(int)w)
					            : gb_string_append_fmt(s, "%s/m", reg);
					break;
				default:
					s = gb_string_appendc(s, "operand");
					break;
				}
			}

			if (i+1 < count) {
				s = gb_string_appendc(s, ", ");
			}

			switch (k) {
			case AsmOperand_Label: // 5 characters
				break;
			case AsmOperand_Immediate: // 3+ characters
			case AsmOperand_Register_Or_Memory:
				if (w == 0) {
					s = gb_string_appendc(s, "  ");
				} else if (w < 10) {
					s = gb_string_appendc(s, " ");
				}
				break;
			case AsmOperand_Register: // 1+ characters
			case AsmOperand_Memory:
				if (w == 0) {
					s = gb_string_appendc(s, "    ");
				} else if (w < 10) {
					s = gb_string_appendc(s, "   ");
				} else if (w < 100) {
					s = gb_string_appendc(s, "  ");
				}
				break;
			}
		}
		bool all_implicit = true;
		for (int i = 0; i < count; i++) {
			auto slot = operand_slot_type(form, i);
			AsmOperandKind k = asm_ctx->kind_from_operand_type(slot);
			switch (k) {
			case AsmOperand_Label:
			case AsmOperand_Register:
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

		gbString desc = describe_form(forms[form_index], clobber_forms[form_index]);
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
			gbString desc = describe_form(forms[fi], clobber_forms[fi]);
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

		int score      = 0;
		int width_dist = 0;
		int width_pref = 0;

		for_array(i, operands) {
			auto type = operand_slot_type(form, cast(int)i);
			Operand const *operand = &operands[i];
			AsmOperandKind dst = asm_ctx->kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(operand);

			bool kind_ok = (dst == src) ||
			               (dst == AsmOperand_Register_Or_Memory && (src == AsmOperand_Register || src == AsmOperand_Memory));

			// Bias toward wider register slots so an r64 form outranks an otherwise-equal r32 form.
			width_pref += cast(int)asm_ctx->operand_type_bit_width(type);

			bool spot_ok = false;
			AsmMismatch m = AsmMismatch_None;
			if (kind_ok) {
				bool mem_unsized = (src == AsmOperand_Memory) && are_types_identical(operand->type, t_rawptr);

				if (dst == AsmOperand_Register_Or_Memory && src == AsmOperand_Memory && mem_unsized) {
					spot_ok = true; // memory form accepts memory; no size check
				} else {
					i32 wb_ = 0, gb_ = 0;
					spot_ok = check_asm_operand_size_class(asm_ctx, type, operand, &m, &wb_, &gb_);
					if (!spot_ok && (m == AsmMismatch_Size || m == AsmMismatch_ImmRange) && wb_ > 0 && gb_ > 0) {
						int d = cast(int)wb_ - cast(int)gb_;
						width_dist += (d < 0) ? -d : d;
					}
				}
			}

			if (spot_ok) {
				score += 2;
				valid_spots[i] = true;
			} else if (kind_ok && m != AsmMismatch_NamedReg) {
				// A slot wanting a named hardware register is not a near miss for anything
				// else, so it must not outrank a form that merely has the widths wrong.
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
		return;
	}

	if (matched) {
		if (valid_form_index >= 0 && previous_prefix > 0) {
			auto &form = forms[valid_form_index];

			bool requires_memory_dest = false;
			if (asm_ctx->prefix_kind_okay(previous_prefix, form, &requires_memory_dest)) {
				if (operands.count != 0 && determine_asm_operand_kind(&operands[0]) != AsmOperand_Memory) {
					error(previous_prefix_instr ? previous_prefix_instr : instr->name,
					      "Asm prefix requires '%.*s' to have a memory destination operand", LIT(name));
				}
			}
		}

		GB_ASSERT(tmpl_entity->kind == Entity_AsmTemplate);

		GB_ASSERT(valid_form_index >= 0);
		instr->mnemonic = mnemonic;
		instr->valid_form_index = cast(i32)valid_form_index;

		check_operand_constraints(asm_ctx, operands, mnemonic, name);

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

		tmpl_entity->AsmTemplate.clobber_flags  |= clobber.implies_clobber_flags();
		tmpl_entity->AsmTemplate.clobber_memory |= clobber.implies_clobber_memory() && mem_is_real;
		tmpl_entity->AsmTemplate.is_volatile    |= effective_side_effects;

		tmpl_entity->AsmTemplate.has_observable_side_effect |= effective_side_effects;
		tmpl_entity->AsmTemplate.has_observable_side_effect |= clobber.writes_mem && mem_is_real;

		// #align_stack only matters if the body makes a call (which requires the stack
		// aligned at the call boundary) or manipulates RSP directly. Plain memory access
		// through a parameter pointer does NOT require stack realignment, so
		// implies_clobber_memory() is intentionally NOT used here.
		if (clobber.is_call_or_mem()) {
			cfg->saw_call_or_mem = true;
		}

		u16 pinned_mask = 0;
		for_array(i, tmpl_entity->AsmTemplate.decls) {
			pinned_mask |= asm_decl_resolve_pin_bit(asm_ctx, tmpl_entity->AsmTemplate.decls, cast(i32)i);
		}

		u16 produced = cast(u16)clobber.implicit_wr & asm_ctx->CLOBBER_REGS_NAMED;
		u16 explicit_writes = 0;

		u16 written_ops = cast(u16)clobber.written;
		u16 pinned_param_writes = 0;
		auto const &decls = tmpl_entity->AsmTemplate.decls;
		for_array(i, operands) {
			int tslot = user_operand_target_index(cast(int)i);
			if (tslot < 0 || tslot >= 4 || (written_ops & (1u << tslot)) == 0) {
				continue;
			}
			Ast *e = operands[i].expr;
			if (e != nullptr && e->kind == Ast_AsmRegister) {
				u16 b = asm_ctx->clobber_bit_for_reg_name(e->AsmRegister.name.string);
				produced |= b;
				explicit_writes |= b;
				continue;
			}
			Entity *pe = entity_of_node(operands[i].expr);
			if (pe != nullptr && pe->kind == Entity_Variable) {
				i32 di = -1;
				check_asm_find_group(pe, decls, &di);         // reuse existing index finder
				pinned_param_writes |= asm_decl_resolve_pin_bit(asm_ctx, decls, di);
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
					GB_ASSERT(build_context.metrics.arch == TargetArch_riscv64);
					synth |= 1<<0; // ClobberReg_RA
				}
			}
			produced        |= synth;
			explicit_writes |= synth;
		}

		facts->gen_regs  = produced | pinned_param_writes;
		facts->gen_flags = cast(u16)clobber.flags_wr;

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


		for_array(i, operands) {
			int slot = user_operand_target_index(cast(int)i);
			if (slot < 0) {
				continue;
			}
			Entity *pe = entity_of_node(operands[i].expr);
			if (pe == nullptr || pe->kind != Entity_Variable) {
				continue;
			}

			if (!self_zeroing && (cast(u16)clobber.read & (1u << slot))) {
				array_add(&facts->read_params, pe);
			}
			if (cast(u16)clobber.written & (1u << slot)) {
				array_add(&facts->gen_params, pe);
			}


			{ // View aliasing: a view decl shares its source's physical register.
				auto const &decls = tmpl_entity->AsmTemplate.decls;
				i32 di = -1;
				check_asm_find_group(pe, decls, &di);
				if (di >= 0 && decls[di].view_of >= 0) {
					i32 src_i = decls[di].view_of;
					Entity *src_e = decls[src_i].entity;
					if (src_e != nullptr) {
						GB_ASSERT_MSG(asm_decl_resolve_pin_bit(asm_ctx, decls, cast(i32)di) == 0 &&
						              asm_decl_resolve_pin_bit(asm_ctx, decls, src_i)      == 0,
						              "view/source share a reg bit; fix the width gate on the reg-bit path, not gen_params");

						// A read of the view is a read of the source
						if (cast(u16)clobber.read & (1u << slot)) {
							array_add(&facts->read_params, src_e);
						}
						// A write of the view defines the source only if it covers the parent
						if (cast(u16)clobber.written & (1u << slot)) {
							i32 parent_w = check_asm_operand_bit_width(src_e->type);
							if (decls[di].view_bits == 32 || decls[di].view_bits == parent_w) {
								array_add(&facts->gen_params, src_e);
							}
						}
					}
				}
			}
		}

		{
			// Registers this form clobbers implicitly (RDTSC->RAX:RDX, etc.), for the
			// redundant-#clobber hint. Union across the template; pinned regs excluded
			// so a legitimate output pin is never called "redundant".
			u16 implicit_wr = cast(u16)clobber.implicit_wr & asm_ctx->CLOBBER_REGS_NAMED;
			cfg->implicit_clobbered_regs |= implicit_wr & ~pinned_mask;

			// Approximate staleness. An output that was explicitly produced (literal %reg write)
			// and is later implicitly clobbered — without this same instruction re-producing it —
			// is marked stale. Explicit re-production clears it. Implicitly-produced outputs
			// (RDTSC->RDX) are never tracked, so they never false-fire.
			cfg->explicitly_produced_regs |= explicit_writes;
			cfg->stale_outputs            &= ~explicit_writes;
			cfg->stale_outputs |= implicit_wr & cfg->explicitly_produced_regs & ~explicit_writes;
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
			bool conditional = clobber.is_conditional();

			facts->is_control = control;
			facts->is_conditional = conditional;
			facts->is_terminal = halt || (control && !conditional);
		}
		asm_ctx->clobber_implicit_regs(&tmpl_entity->AsmTemplate.clobber_registers_set, produced);

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
		}
		return;
	}

	// NOTE(bill): Failure path
	enum { MAX_VARIANT_COUNT = 8 };
	AsmMismatch mismatch [MAX_VARIANT_COUNT] = {};
	i32         want_bits[MAX_VARIANT_COUNT] = {};
	i32         got_bits [MAX_VARIANT_COUNT] = {};
	if (best_form >= 0) {
		auto &form = forms[best_form];
		for_array(i, operands) {
			auto type = operand_slot_type(form, cast(int)i);
			AsmOperandKind dst = asm_ctx->kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(&operands[i]);

			possible_kinds      [i] = dst;
			possible_class_kinds[i] = asm_ctx->reg_class_from_operand_type(type);

			bool kind_ok = (dst == src) ||
			               (dst == AsmOperand_Register_Or_Memory
			                && (src == AsmOperand_Register || src == AsmOperand_Memory));
			if (!kind_ok) {
				valid_spots[i] = false;
			} else {
				AsmMismatch m = AsmMismatch_None;
				i32 wb_ = 0;
				i32 gb_ = 0;
				bool ok = check_asm_operand_size_class(asm_ctx, type, &operands[i], &m, &wb_, &gb_);
				valid_spots[i] = ok;
				if (!ok && i < MAX_VARIANT_COUNT) {
					mismatch[i]  = m;
					want_bits[i] = wb_;
					got_bits[i]  = gb_;
				}
			}
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

		AsmMismatch m = (i < MAX_VARIANT_COUNT) ? mismatch[i] : AsmMismatch_None;

		end_error_block();
		begin_error_block();

		if (m == AsmMismatch_ImmRange) {
			ExactValue ev = operands[i].value;
			gbString vs = exact_value_to_string(ev);
			i32 bits_required = 0;
			check_asm_immediate_value_fits(ev, want_bits[i], &bits_required, nullptr);
			if (bits_required > 0) {
				error(operands[i].expr, "'%.*s' operand-%td is a %d-bit immediate value, but the value %s does not fit in the %d-bit immediate this form encodes",
				      LIT(name), i, bits_required, vs, cast(int)want_bits[i]);
			} else {
				error(operands[i].expr, "'%.*s' operand-%td is an immediate value, but the value %s does not fit in the %d-bit immediate this form encodes",
				      LIT(name), i, vs, cast(int)want_bits[i]);
			}
			gb_string_free(vs);
		} else if (m == AsmMismatch_ImmType) {
			error(operands[i].expr, "'%.*s' operand-%td: a floating-point constant cannot be used as an immediate",
			      LIT(name), i);
		} else if (m == AsmMismatch_Size && want_bits[i] && got_bits[i]) {
			error(operands[i].expr, "'%.*s' operand-%td has the wrong size: expected a %u-bit %.*s operand, got %u-bit",
			      LIT(name), i,
			      cast(unsigned)want_bits[i], LIT(asm_reg_class_strings[dst_reg_class]),
			      cast(unsigned)got_bits[i]);
		} else if (m == AsmMismatch_Class) {
			error(operands[i].expr, "'%.*s' operand-%td is in the wrong register class, expected %d-bit %.*s %.*s, got %d-bit %.*s %.*s",
			      LIT(name), i,
			      want_bits[i], LIT(asm_reg_class_strings[dst_reg_class]), LIT(asm_operand_kind_strings[dst]),
			      got_bits[i],  LIT(asm_reg_class_strings[src_reg_class]), LIT(asm_operand_kind_strings[src]));
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
}


template <typename AsmCtx>
gb_internal void check_asm_instruction_operand(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *entity, Operand *operand, Ast *expr, bool allow_memory_operands) {
	if (expr == nullptr) {
		return;
	}

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
			error(expr, "Asm operands within parentheses can only compile time constants, if they were supported");
		} else {
			error(expr, "Asm operands with parentheses are not currently supported");
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
			error(expr, "Undeclared asm parameter or constant '%.*s'", LIT(i->token.string));
			return;
		}

		if (found->kind != Entity_Constant) {
			error(expr, "Only asm parameters or constants are allowed to be used within an 'asm' template");
			return;
		}

		add_entity_use(ctx, expr, entity);
		operand->mode  = Addressing_Constant;
		operand->value = found->Constant.value;
		operand->type  = found->type;

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

		Operand segment_override = {};
		check_asm_instruction_operand(asm_ctx, ctx, entity, &segment_override, mem_op->segment_override, false);

		if (segment_override.expr == nullptr) {
			// okay
		} else if (segment_override.expr->kind == Ast_AsmRegister) {
			String reg_name = segment_override.expr->AsmRegister.name.string;
			auto reg = asm_ctx->register_lookup(reg_name);
			auto reg_class = asm_ctx->reg_class(asm_ctx->register_codes[reg]);
			if (reg_class != asm_ctx->REG_CLASS_SEG) {
				gbString s = expr_to_string(segment_override.expr);
				error(segment_override.expr, "A segment override must be a selector register parameter, got %s", s);
				gb_string_free(s);
			}
		} else {
			gbString s = expr_to_string(segment_override.expr);
			error(segment_override.expr, "A segment override must be a selector register parameter, got %s", s);
			gb_string_free(s);
		}

		Operand base  = {};
		Operand index = {};
		Operand scale = {};
		Operand disp  = {};
		check_asm_instruction_operand(asm_ctx, ctx, entity, &base,  mem_op->base,  false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &index, mem_op->index, false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &scale, mem_op->scale, false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &disp,  mem_op->disp,  false);

		// NOTE(bill): if the base/index is actually an immediate and there is no scale nor disp,
		// then treat it as a disp, and modify the AST too
		if (index.expr != nullptr && scale.expr == nullptr && disp.expr == nullptr) {
			bool do_swap = index.mode == Addressing_Constant;
			if (!do_swap) {
				Entity *param_entity = entity_of_node(index.expr);
				if (param_entity != nullptr && param_entity->kind == Entity_Variable) {
					auto kind = check_asm_find_kind(param_entity, ate->decls);
					do_swap = kind == AsmTemplateEntityDecl_Immediate;
				}
			}
			if (do_swap) {
				disp = index;
				index = {};

				mem_op->disp = mem_op->index;
				mem_op->index = nullptr;

				mem_op->disp_op = mem_op->index_op;
				mem_op->index_op = {};
			}
		}
		if (base.expr != nullptr && index.expr == nullptr && scale.expr == nullptr && disp.expr == nullptr) {
			bool do_swap = base.mode == Addressing_Constant;
			if (!do_swap) {
				Entity *param_entity = entity_of_node(base.expr);
				if (param_entity != nullptr && param_entity->kind == Entity_Variable) {
					auto kind = check_asm_find_kind(param_entity, ate->decls);
					do_swap = kind == AsmTemplateEntityDecl_Immediate;
				}
			}
			if (do_swap) {
				disp = base;
				base = {};

				mem_op->disp = mem_op->base;
				mem_op->base = nullptr;
			}
		}

		i32  base_w     = 0;
		i32  index_w    = 0;
		bool have_base  = false;
		bool have_index = false;

		// base: must resolve to a 32/64-bit integer register
		if (base.expr) {
			String reg_name = {};
			bool ok_kind = true;
			if (base.expr->kind == Ast_AsmRegister) {
				reg_name = base.expr->AsmRegister.name.string;
				ok_kind = check_register(asm_ctx, &base, &base.expr->AsmRegister);
			} else {
				Entity *param_entity = entity_of_node(base.expr);
				if (param_entity == nullptr || param_entity->kind != Entity_Variable) {
					gbString s = expr_to_string(base.expr);
					error(base.expr, "A base value must be a register parameter, got %s", s);
					gb_string_free(s);
					ok_kind = false;
				} else {
					auto kind = check_asm_find_kind(param_entity, ate->decls);
					// A pointer/integer parameter used as an address base lowers to a
					// register operand, so accept both Register and Memory kinds here.
					if (kind != AsmTemplateEntityDecl_Register && kind != AsmTemplateEntityDecl_Memory) {
						gbString s = expr_to_string(base.expr);
						error(base.expr, "A base value must be a register parameter, got %s", s);
						gb_string_free(s);
						ok_kind = false;
					}
				}
			}
			if (ok_kind) {
				have_base = check_asm_addr_register(&base, AsmAddr_Base, reg_name, &base_w);
			}
		}

		// index: must resolve to a 32/64-bit integer register, and not rsp/esp
		if (index.expr) {
			String reg_name = {};
			bool ok_kind = true;
			if (index.expr->kind == Ast_AsmRegister) {
				reg_name = index.expr->AsmRegister.name.string;
				ok_kind = check_register(asm_ctx, &index, &index.expr->AsmRegister);
			} else {
				Entity *param_entity = entity_of_node(index.expr);
				if (param_entity == nullptr || param_entity->kind != Entity_Variable) {
					gbString s = expr_to_string(index.expr);
					error(index.expr, "An index value must be an integer register, got %s", s);
					gb_string_free(s);
					ok_kind = false;
				} else {
					auto kind = check_asm_find_kind(param_entity, ate->decls);
					switch (kind) {
					case AsmTemplateEntityDecl_Register:
					case AsmTemplateEntityDecl_Immediate:
						// okay
						break;
					default:
						{
							gbString s = expr_to_string(index.expr);
							gbString t = type_to_string(index.type);
							error(index.expr, "An index must be an integer register, got %s of type %s", s, t);
							gb_string_free(t);
							gb_string_free(s);
							ok_kind = false;
						}
						break;
					}
				}
			}
			if (ok_kind) {
				have_index = check_asm_addr_register(&index, AsmAddr_Index, reg_name, &index_w);
			}
		}

		// base and index must be the same width
		if (have_base && have_index && base_w != index_w) {
			Ast *at = mem_op->base ? mem_op->base : expr;
			error(at, "A memory operand's base and index registers must be the same width, got a %d-bit base and a %d-bit index",
			      cast(int)base_w, cast(int)index_w);
		}

		// a scale factor is meaningless without an index
		if (scale.expr && !index.expr) {
			error(scale.expr, "A scale factor requires an index register");
		}

		// scale: constant 1/2/4/8, or an immediate parameter
		for (int i = 0; scale.expr && i == 0; i++) {
			if (!is_type_integer(scale.type)) {
				gbString s = expr_to_string(scale.expr);
				error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
				gb_string_free(s);
				break;
			}
			if (scale.mode == Addressing_Constant) {
				gbString s = exact_value_to_string(scale.value);
				defer (gb_string_free(s));
				if (scale.value.kind != ExactValue_Integer) {
					error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
					break;
				} else {
					i64 v = exact_value_to_i64(scale.value);

					Token op = mem_op->scale_op;
					switch (op.kind) {
					case Token_Mul:
						switch (v) {
						case 1: case 2: case 4: case 8:
							// okay
							break;
						default:
							error(scale.expr, "A scale using '*' must be a constant integer or an immediate with the value 1, 2, 4, or 8, got %s", s);
							break;
						}
						break;
					case Token_Shl:
					case Token_Shr:
						switch (v) {
						case 0: case 1: case 2: case 3:
							// okay
							break;
						default:
							error(scale.expr, "A shifting scale using '%.*s' must be a constant integer or an immediate with the value 0, 1, 2, or 3, got %s", LIT(op.string), s);
							break;
						}
						break;
					default:
						error(op, "Unknown/unhandled scaling operator '%.*s'", LIT(op.string));
						break;
					}

					if (op.kind == Token_Shr) {
						if (build_context.metrics.arch != TargetArch_arm64) {
							error(op, "The target platform does not support '%.*s' for shifting scale parameters in memory operands", LIT(op.string));
						}
					}
				}
			} else {
				Entity *param_entity = entity_of_node(scale.expr);
				if (param_entity == nullptr || param_entity->kind != Entity_Variable) {
					gbString s = expr_to_string(scale.expr);
					error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
					gb_string_free(s);
					break;
				}
				auto kind = check_asm_find_kind(param_entity, ate->decls);
				if (kind != AsmTemplateEntityDecl_Immediate) {
					gbString s = expr_to_string(scale.expr);
					error(scale.expr, "A scale must be a constant integer or an immediate, got %s", s);
					gb_string_free(s);
					break;
				}
			}
		}

		// displacement: an integer that fits a signed 32-bit value
		for (int i = 0; disp.expr && i == 0; i++) {
			if (disp.expr->kind == Ast_AsmRegister) {
				error(disp.expr, "A displacement must be a constant integer value, got a register");
				break;
			}

			// A displacement must be assemble-time constant. A register-valued
			// parameter belongs in the index slot, not the displacement.
			if (disp.mode == Addressing_Constant && disp.value.kind == ExactValue_Integer) {
				AsmMismatch m = AsmMismatch_None;
				i32 needed = 0;
				if (!check_asm_immediate_value_fits(disp.value, 32, &needed, &m)) {
					gbString vs = exact_value_to_string(disp.value);
					error(disp.expr, "A memory displacement must fit in a signed 32-bit value, got %s (needs %d bits)", vs, cast(int)needed);
					gb_string_free(vs);
				}
				break;
			}

			Entity *param_entity = entity_of_node(disp.expr);
			if (param_entity != nullptr && param_entity->kind == Entity_Variable) {
				auto kind = check_asm_find_kind(param_entity, ate->decls);
				if (kind == AsmTemplateEntityDecl_Immediate) {
					// A $-immediate parameter is a legal (assemble-time) displacement.
					break;
				}
				if (kind == AsmTemplateEntityDecl_Register) {
					error(disp.expr, "A register parameter cannot be a displacement; use it as an index, e.g. [base + %.*s]", LIT(disp.expr->Ident.token.string));
					break;
				}
			}

			gbString s = expr_to_string(disp.expr);
			error(disp.expr, "A displacement must be a constant integer or immediate, got %s", s);
			gb_string_free(s);
		}

		if (index.expr != nullptr) {
			if (!asm_ctx->supports_memory_index_not_just_disp()) {
				error(index.expr, "The target platform does not support memory indexing within memory operands, only displacements");
			}
		}
		if (scale.expr != nullptr) {
			if (!asm_ctx->supports_memory_index_not_just_disp()) {
				error(scale.expr, "The target platform does not support memory index scaling within memory operands");
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
	}

	{
		gbString s = expr_to_string(expr);
		error(expr, "Invalid asm operand, got %s", s);
		gb_string_free(s);
	}
	return;
}


template <typename AsmCtx>
gb_internal void check_asm_template(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *entity, DeclInfo *d) {
	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	auto *ate = &entity->AsmTemplate;

	String asm_template_name = entity->token.string;
	gb_unused(asm_template_name);

	ast_node(at, AsmTemplate, d->init_expr);

	GB_ASSERT(at->signature != nullptr);
	if (at->signature->kind != Ast_ProcType) {
		error(at->signature, "Expected a valid signature, got %.*s", LIT(ast_strings[at->signature->kind]));
		return;
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

	entity->type = type;

	bool is_volatile       = false;
	bool is_align_stack    = false;
	bool is_pure_annotated = false;
	auto *clobber_registers_set = &entity->AsmTemplate.clobber_registers_set;

	check_asm_specs(asm_ctx, ctx, ate->param_scope, at->specs, &ate->decls);
	{ // check clobbers
		bool clobber_flags  = false;
		bool clobber_memory = false;

		for (Ast *clobber_ : at->clobbers) {
			ast_node(clobber, AsmClobber, clobber_);

			if (clobber->value == nullptr) {
				if (clobber->name.string == "volatile") {
					if (is_volatile) {
						error(clobber->name, "#volatile has already been defined as an asm specification");
					}
					is_volatile = true;
				} else if (clobber->name.string == "align_stack") {
					if (is_align_stack) {
						error(clobber->name, "#align_stack has already been defined as an asm specification");
					}
					is_align_stack = true;
				} else if (clobber->name.string == "pure") {
					if (is_pure_annotated) {
						error(clobber->name, "#pure has already been defined as an asm specification");
					}
					is_pure_annotated = true;
				} else {
					error(clobber->name, "Unknown clobber directive '#%.*s'", LIT(clobber->name.string));
				}
				continue;
			}

			switch (clobber->value->kind) {
			case_ast_node(asm_reg, AsmRegister, clobber->value)
				String reg = asm_reg->name.string;
				if (asm_reg->flag.string != "") {
					error(asm_reg->flag, "#clobber on specific flags is not allowed");
				}
				Operand operand = {};
				if (check_register(asm_ctx, &operand, asm_reg)) {
					if (string_set_update(clobber_registers_set, reg)) {
						error(clobber->value, "#clobber %%%.*s has already been defined", LIT(reg));
					}
				}
			case_end;
			case_ast_node(ident, Ident, clobber->value);
				String str = ident->token.string;
				if (str == "flags") {
					if (clobber_flags) {
						error(clobber->value, "#clobber flags has already been defined");
					}
					clobber_flags = true;
				} else if (str == "memory") {
					if (clobber_memory) {
						error(clobber->value, "#clobber memory has already been defined");
					}
					clobber_memory = true;
				} else {
					error(clobber->value, "Expected either a register, 'flags', or 'memory' for a '#clobber' specification, got '%.*s'", LIT(str));
				}
			case_end;
			default:
				error(clobber->value, "Expected either a register, 'flags', or 'memory' for a '#clobber' specification");
				break;
			}
		}

		entity->AsmTemplate.clobber_flags  = clobber_flags;
		entity->AsmTemplate.clobber_memory = clobber_memory;
		entity->AsmTemplate.is_volatile    = is_volatile;
		entity->AsmTemplate.is_align_stack = is_align_stack;
	}

	// add normalizations for the reigsters too
	for (String const &reg : *clobber_registers_set) {
		u16 bit = asm_ctx->clobber_bit_for_reg_name(reg);
		String rname = make_string_c(asm_ctx->clobber_reg_bit_name(bit));
		if (rname != reg) {
			string_set_update(clobber_registers_set, rname);
		}
	}

	// Two distinct operands pinned to the same physical register only makes sense when
	// they are tied (they intentionally share one register). Compared by bit so %eax
	// and %rax collide. Flag pins ("flags") yield bit 0 and are skipped.
	for_array(i, ate->decls) {
		auto const &a = ate->decls[i];
		if (a.pin.len == 0) {
			continue;
		}
		u16 abit = asm_ctx->clobber_bit_for_reg_name(a.pin);
		if (abit == 0) {
			continue;
		}
		for (isize j = i+1; j < ate->decls.count; j++) {
			auto const &b = ate->decls[j];
			if (b.pin.len == 0 || asm_ctx->clobber_bit_for_reg_name(b.pin) != abit) {
				continue;
			}
			bool tied = (a.tie == cast(i32)j) || (b.tie == cast(i32)i);
			if (tied) {
				continue;
			}
			error(b.entity ? b.entity->token : entity->token,
			      "Parameters '%.*s' and '%.*s' are both pinned to %%%s but are not tied",
			      LIT(a.entity->token.string), LIT(b.entity->token.string),
			      asm_ctx->clobber_reg_bit_name(abit));
		}
	}

	// NOTE(bill, 2026-08-24): Construct a control-flow graph (CFG) from the instructions
	// to do further analysis which is not possible with an conservative straight-line approximation
	// Using a CFG is a much sounder approach for calculating:
	// * reads before writes
	// * divergence
	// * unreachable code

	AsmCfg cfg = {};
	asm_cfg_init(&cfg);
	defer (asm_cfg_destroy(&cfg));

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

	Array<Operand> operands = {};
	operands.allocator = heap_allocator();
	array_reserve(&operands, 16);
	defer (array_free(&operands));

	u8 previous_prefix = 0;
	Ast *previous_prefix_instr = nullptr; // for a good error location

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
			} else if (res == CheckMnemomic_Mnemonic) {
				instr->suffix_flags = suffix_flags;
				check_mnemonic(asm_ctx, ctx, entity, instr, mnemonic, 0, slice_from_array(operands),
				               previous_prefix, previous_prefix_instr,
				               &cfg);

				cfg.saw_any_instructions = true;

				previous_prefix = 0;
				previous_prefix_instr = nullptr;
			} else if (res == CheckMnemomic_PseudoMnemonic) {
				instr->suffix_flags = suffix_flags;

				u16 pseudo_mnemonic = cast(u16)mnemonic;
				auto alias = asm_ctx->pseudo_alias(cast(u16)pseudo_mnemonic);
				u16 target_mnemonic = cast(u16)alias.target;
				check_mnemonic(asm_ctx, ctx, entity, instr, target_mnemonic, pseudo_mnemonic, slice_from_array(operands),
				               previous_prefix, previous_prefix_instr,
				               &cfg);

				cfg.saw_any_instructions = true;

				previous_prefix = 0;
				previous_prefix_instr = nullptr;
			} else if (res == CheckMnemomic_PseudoMacroMnemonic) {
				instr->suffix_flags = suffix_flags;
				check_pseudo_macro_mnemonic(asm_ctx, entity, instr, slice_from_array(operands));

				cfg.saw_any_instructions = true;

				previous_prefix = 0;
				previous_prefix_instr = nullptr;
			} else {
				// invalid mnemonic already reported; a pending prefix now has no target
				previous_prefix = 0;
				previous_prefix_instr = nullptr;
			}
		case_end;

		case_ast_node(label, AsmLabelDecl, instruction_);
			if (previous_prefix != 0) {
				error(previous_prefix_instr, "A prefix must be immediately followed by an instruction, but a label declaration was found");
				previous_prefix = 0;
				previous_prefix_instr = nullptr;
			}
		case_end;

		case_ast_node(dir, AsmDirective, instruction_);
			String name = dir->name.string;
			if (name == "byte") {
				if (dir->operands.count == 0) {
					error(dir->name, "Expected 1 or more integers for the asm directive #%.*s", LIT(name));
					break;
				}
				array_clear(&operands);
				for (Ast *expr : dir->operands) {
					Operand operand = {};
					check_asm_instruction_operand(asm_ctx, ctx, entity, &operand, expr, /*allow_memory_operands*/true);
					array_add(&operands, operand);
				}
				for (auto &op : operands) {
					if (op.mode != Addressing_Constant) {
						error(op.expr, "Expected an integer for the asm directive #%.*s", LIT(name));
						continue;
					}
					check_assignment(ctx, &op, t_u8, str_lit("asm '#byte' directive"));
				}
			} else if (name == "align") {
				if (dir->operands.count != 1) {
					error(dir->name, "Expected 1 integer for the asm directive #%.*s", LIT(name));
					break;
				}
				array_clear(&operands);
				for (Ast *expr : dir->operands) {
					Operand operand = {};
					check_asm_instruction_operand(asm_ctx, ctx, entity, &operand, expr, /*allow_memory_operands*/true);
					array_add(&operands, operand);
				}
				for (auto const &op : operands) {
					if (op.mode != Addressing_Constant) {
						error(op.expr, "Expected a power-of-two integer for the asm directive #%.*s", LIT(name));
						continue;
					}
					ExactValue ev = exact_value_to_integer(op.value);
					if (ev.kind != ExactValue_Integer) {
						error(op.expr, "Expected a power-of-two integer for the asm directive #%.*s", LIT(name));
						continue;
					}
					i64 i = exact_value_to_i64(ev);
					if (i < 0 || !is_power_of_two(i)) {
						error(op.expr, "Expected a power-of-two integer for the asm directive #%.*s, got %lld", LIT(name), cast(long long)i);
						continue;
					}
				}

			} else if (name == "skip" ||
			           name == "nop") {
				if (dir->operands.count != 1) {
					error(dir->name, "Expected 1 integer for the asm directive #%.*s", LIT(name));
					break;
				}
				array_clear(&operands);
				for (Ast *expr : dir->operands) {
					Operand operand = {};
					check_asm_instruction_operand(asm_ctx, ctx, entity, &operand, expr, /*allow_memory_operands*/true);
					array_add(&operands, operand);
				}
				for (auto const &op : operands) {
					if (op.mode != Addressing_Constant) {
						error(op.expr, "Expected an integer >0 for the asm directive #%.*s", LIT(name));
						continue;
					}
					ExactValue ev = exact_value_to_integer(op.value);
					if (ev.kind != ExactValue_Integer) {
						error(op.expr, "Expected an integer >0 for the asm directive #%.*s", LIT(name));
						continue;
					}
					i64 i = exact_value_to_i64(ev);
					if (i < 0) {
						error(op.expr, "Expected an integer >0 for the asm directive #%.*s, got %lld", LIT(name), cast(long long)i);
						continue;
					}
				}
			} else {
				error(dir->name, "Unknown asm directive: #%.*s", LIT(name));
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

	check_asm_cfg_build(asm_ctx, &cfg, d->init_expr, entity);
	check_asm_cfg_analyse(asm_ctx, &cfg, ctx, entity);

	bool vet_unused = false;
	{
		AstFile *file = ctx->file;
		if (file == nullptr) {
			file = entity->file;
		}

		vet_unused = (ast_file_vet_flags(file) & VetFlag_UnusedVariables) != 0;
	}

	if (vet_unused) {
		for (auto const &entry : ate->label_scope->elements) {
			Entity *le = entry.value;
			GB_ASSERT(le != nullptr);
			if ((le->flags & EntityFlag_Used) == 0) {
				error(le->token, "'asm' label '.%.*s' is declared but never referenced by any instruction", LIT(le->token.string));
			}
		}
	}

	if (vet_unused) {
		PtrSet<Entity *> refs = {};
		ptr_set_init(&refs);
		defer (ptr_set_destroy(&refs));
		u16 touched_regs = 0;

		for (Ast *instruction_ : at->instructions) {
			if (instruction_->kind == Ast_AsmInstruction) {
				for (Ast *op : instruction_->AsmInstruction.operands) {
					check_asm_collect_refs(asm_ctx, &refs, op, &touched_regs);
				}
			} else if (instruction_->kind == Ast_AsmDirective) {
				for (Ast *op : instruction_->AsmDirective.operands) {
					check_asm_collect_refs(asm_ctx, &refs, op, &touched_regs);
				}
			}
		}

		for (auto const &ed : ate->decls) {
			bool is_scratch   = ed.param_group == AsmTemplateEntityDeclParamGroup_Scratch && ed.view_of < 0;
			bool is_immediate = ed.kind        == AsmTemplateEntityDecl_Immediate;
			bool is_input     = ed.param_group == AsmTemplateEntityDeclParamGroup_Input;
			if ((!is_scratch && !is_immediate && !is_input) || ed.entity == nullptr) {
				continue;
			}
			// Used if its identifier is referenced OR (for a pinned scratch) its pinned
			// register is touched in the body. Immediates are never register-touched, so
			// they fall through to the entity check as before.
			if (ptr_set_exists(&refs, ed.entity)) {
				continue;
			}
			if (ed.pin.len != 0) {
				u16 pin_bit = asm_ctx->clobber_bit_for_reg_name(ed.pin);
				if (pin_bit != 0 && (touched_regs & pin_bit) != 0) {
					continue;
				}
			}
			if (ed.tie > 0) {
				// TODO(bill): Handle this edge case?
				continue;
			}

			char const *what = is_immediate ? "immediate" :
			                   is_input     ? "input" :
			                                  "scratch";
			error(ed.entity->token, "'asm' %s parameter '%.*s' is declared but never used", what, LIT(ed.entity->token.string));
		}
	}

	GB_ASSERT(entity->kind == Entity_AsmTemplate);
	if (results->Tuple.variables.count == 0 && !entity->AsmTemplate.is_volatile &&
	    !entity->AsmTemplate.clobber_memory &&
	    entity->AsmTemplate.has_observable_side_effect) {
		warning(entity->token,
		        "This asm template has an observable effect but declares no outputs "
		        "and does not #volatile in the specification block; it may be optimized away. "
		        "Please add #volatile if the effect is intended.");
	}

	if (entity->AsmTemplate.is_align_stack && !cfg.saw_call_or_mem) {
		warning(entity->token,
		        "#align_stack is redundant; this template makes no call and touches no memory "
		        "that would require the stack to be realigned");
	}

	{
		bool declared_effects = entity->AsmTemplate.is_volatile ||
		                        entity->AsmTemplate.clobber_memory ||
		                        entity->AsmTemplate.has_observable_side_effect;
		bool is_pure = cfg.can_be_pure && !declared_effects && !type->Proc.diverging;
		entity->AsmTemplate.is_pure = is_pure;

		if (is_pure_annotated && !is_pure) {
			Ast *node = cfg.impure_reason_node;
			char const *why = cfg.impure_reason;
			if (why == nullptr) {
				if (type->Proc.diverging) {
					why = "it is declared diverging (-> !) and computes no outputs";
				} else if (entity->AsmTemplate.clobber_memory) {
					why = "it declares '#clobber memory'";
				} else if (entity->AsmTemplate.is_volatile) {
					why = "it is declared '#volatile'";
				} else {
					why = "it declares an observable effect";
				}
			}
			Token tok = node ? ast_token(node): entity->token;
			error(tok, "'asm' template is marked #pure but it is not pure: %s", why);
		}
	}
}

gb_internal void check_asm_template_from_entity(CheckerContext *c, Entity *e, DeclInfo *d) {
	if (build_context.metrics.arch == TargetArch_amd64) {
		check_asm_template(&g_asm_amd64, c, e, d);
	} else if (build_context.metrics.arch == TargetArch_riscv64) {
		// check_asm_template(&g_asm_riscv, c, e, d);
	} else {
		error(e->token, "asm templates are not currently supported for this target");
	}
}