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
		return true;
	}
	if (is_type_float(type)) {
		return true;
	}
	if (is_type_boolean(type)) {
		return true;
	}
	if (is_type_pointer(type) || is_type_multi_pointer(type)) {
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
	if (is_type_pointer(type) || is_type_multi_pointer(type)) {
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

enum AsmMismatch : u8 {
	AsmMismatch_None,
	AsmMismatch_Size,      // register / vector width mismatch
	AsmMismatch_Class,     // register class mismatch
	AsmMismatch_ImmRange,  // constant immediate does not fit the slot width
	AsmMismatch_ImmType,   // non-integer constant where an integer immediate is required
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
		bool class_ok;
		switch (want_class) {
		case AsmRegClass_Integer:
			class_ok = (got_class == AsmRegClass_Integer);
			break;
		case AsmRegClass_Vector:
			// A scalar float uses only the low lane, so it is valid in any vector
			// register slot; a #simd vector matches the vector class exactly.
			class_ok = (got_class == AsmRegClass_Vector || got_class == AsmRegClass_Float);
			break;
		case AsmRegClass_Mask:
			class_ok = (got_class == AsmRegClass_Mask);
			break;
		default:
			class_ok = true;
			break;
		}
		if (!class_ok) {
			if (mismatch_) *mismatch_ = AsmMismatch_Class;
			return false;
		}
	}

	// Width check.
	if (want_w != 0 && got_w != 0) {
		if (want_class == AsmRegClass_Vector && !is_memory) {
			// A scalar float uses only the low lane, so it is valid in any vector
			// register slot as long as it fits; a #simd vector must match exactly.
			bool width_ok = (got_class == AsmRegClass_Float) ? (got_w <= want_w) : (got_w == want_w);
			if (!width_ok) {
				if (mismatch_) *mismatch_ = AsmMismatch_Size;
				return false;
			}
		} else {
			// Integer/mask registers, and all memory operands: exact width.
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
		// rsp/esp cannot be encoded as an index register.
		if (reg_name == "rsp" || reg_name == "esp") {
			error(operand->expr, "%%%.*s cannot be used as an index register", LIT(reg_name));
			return false;
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
			entity->flags |= EntityFlag_Used;
			if (is_poly_name) {
				entity->flags |= EntityFlag_PolyConst;
				if (is_type_internally_pointer_like(type)) {
					error(name, "Parameters with a pointer-like type cannot be used as $ immediates");
				}
			}

			Entity *found = scope_insert(scope, entity);
			if (found == nullptr) {
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
			} else {
				TokenPos pos = found->token.pos;
				error(name_token,
				      "Redeclaration of '%.*s' in this scope\n"
				      "\tat %s",
				      LIT(name_token.string), token_pos_to_string(pos));
				entity = found;
			}
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


template <typename AsmCtx>
gb_internal void check_asm_specs(AsmCtx *asm_ctx, CheckerContext *ctx, Scope *scope, Slice<Ast *> const &specs, Array<AsmTemplateEntityDecl> *asm_template_entity_decls) {
	StringSet pin_set = {};
	string_set_init(&pin_set, specs.count);
	defer (string_set_destroy(&pin_set));

	for (Ast *spec_ : specs) {
		if (spec_->kind != Ast_AsmSpec) {
			continue;
		}
		ast_node(spec, AsmSpec, spec_);

		GB_ASSERT(spec->name->kind == Ast_Ident);

		Entity *input = scope_lookup(scope, spec->name->Ident.interned, spec->name->Ident.hash);
		Entity *other_scratch = nullptr;

		String pin = {};
		if (spec->value != nullptr) {
			if (spec->value->kind == Ast_Ident) {
				other_scratch = scope_lookup(scope, spec->value->Ident.interned, spec->value->Ident.hash);
				if (other_scratch) {
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
					check_register(asm_ctx, &op, reg);
					if (string_set_update(&pin_set, pin)) {
						error(spec->value, "Pinned register %%%.*s has already been assigned", LIT(pin));
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
				gb_unused(group);
				GB_ASSERT(index >= 0);
				auto *i = &(*asm_template_entity_decls)[index];
				if (i->pin.len == 0) {
					i->pin = pin;
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
			Entity *output = scope_lookup(scope, spec->tied_name->Ident.interned, spec->tied_name->Ident.hash);
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

			if (other_scratch != nullptr) {
				GB_ASSERT(spec->value != nullptr);
				error(spec->value, "Another parameter must be assigned/paired with a scratch parameter declaration, not a tie");
			}
		}
	}
}

template <typename AsmCtx>
gb_internal bool check_register(AsmCtx *asm_ctx, Operand *operand, AstAsmRegister *asm_reg) {
	String name = asm_reg->name.string;
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
			error(operand->expr, "80-bit width asm registers are not supported");
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
			GB_PANIC("Unhandled register width size: %d", width_in_bits);
			break;
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
	CheckMnemomic_Prefix,
};

template <typename AsmCtx>
gb_internal CheckMnemomicResult check_mnemonic_name(AsmCtx *asm_ctx, AstAsmInstruction *instr, u16 *mnemonic_) {
	String name = instr->name->Ident.token.string;
	auto m = asm_ctx->mnemonic_lookup(name);
	if (m) {
		if (mnemonic_) *mnemonic_ = cast(u16)m;
		return CheckMnemomic_Mnemonic;
	}
	auto p = asm_ctx->prefix_lookup(name);
	if (p) {
		if (mnemonic_) *mnemonic_ = cast(u16)p;
		return CheckMnemomic_Prefix;
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


template <typename AsmCtx>
gb_internal void check_mnemonic(AsmCtx *asm_ctx, CheckerContext *ctx, Entity *tmpl_entity, AstAsmInstruction *instr,
                                u16 mnemonic, Slice<Operand> const &operands,
                                u8 previous_prefix, Ast *previous_prefix_instr) {
	GB_ASSERT(mnemonic > 0);
	auto forms = asm_ctx->encoding_forms(mnemonic);
	String name = asm_ctx->mnemonic_strings[mnemonic];

	int min_count = I32_MAX;
	int max_count = -1;

	for (auto form : forms) {
		int explicit_count = cast(int)form.explicit_count();
		min_count = gb_min(min_count, explicit_count);
		max_count = gb_max(max_count, explicit_count);
	}
	min_count = gb_max(min_count, 0);
	max_count = gb_max(max_count, 0);


	auto valid_spots = slice_make<bool>(heap_allocator(), max_count);
	defer (slice_free(&valid_spots, heap_allocator()));

	auto possible_kinds = slice_make<AsmOperandKind>(heap_allocator(), max_count);
	defer (slice_free(&possible_kinds, heap_allocator()));

	bool  matched          = false;
	isize valid_form_index = -1;

	isize best_form  = -1;
	int   best_score = -1;
	int   best_dist  = I32_MAX; // secondary: prefer smaller width distance
	int   best_pref  = -1;      // tertiary: prefer wider slots (r64 over r32)

	for_array(form_index, forms) {
		auto &form = forms[form_index];
		if (operands.count != cast(int)form.explicit_count()) {
			continue;
		}

		int score      = 0;
		int width_dist = 0;
		int width_pref = 0;

		for_array(i, operands) {
			int slot = asm_ctx->form_explicit_slot(form, cast(int)i);
			auto type = (slot >= 0) ? form.ops[slot] : asm_ctx->OP_NONE;
			Operand const *operand = &operands[i];
			AsmOperandKind dst = asm_ctx->kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(operand);

			bool kind_ok = (dst == src) ||
			               (dst == AsmOperand_Register_Or_Memory && (src == AsmOperand_Register || src == AsmOperand_Memory));

			// Tertiary key: bias toward wider register slots so an r64 form outranks
			// an otherwise-equal r32 form.
			width_pref += cast(int)asm_ctx->operand_type_bit_width(type);

			bool spot_ok = false;
			if (kind_ok) {
				bool mem_unsized = (src == AsmOperand_Memory) && are_types_identical(operand->type, t_rawptr);

				if (dst == AsmOperand_Register_Or_Memory && src == AsmOperand_Memory && mem_unsized) {
					spot_ok = true; // memory form accepts memory; no size check
				} else {
					AsmMismatch m = AsmMismatch_None;
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
			} else if (kind_ok) {
				score += 1; // kind matched, only value/size/class failed
			}
		}

		if (score == operands.count * 2) {
			matched = true;
			valid_form_index = form_index;
			break;
		}

		// Lexicographic rank: score desc, then width_dist asc, then width_pref desc.
		bool better;
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
		if (min_count == max_count) {
			error(instr->name, "The asm instruction '%.*s' expects %d operands, got %td", LIT(name), max_count, operands.count);
		} else {
			error(instr->name, "The asm instruction '%.*s' expects %d..=%d operands, got %td", LIT(name), min_count, max_count, operands.count);
		}
		return;
	}
	if (matched) {
		if (valid_form_index >= 0 && previous_prefix > 0) {
			auto &form = forms[valid_form_index];

			bool requires_memory_dest = false;
			bool ok = asm_ctx->prefix_kind_okay(previous_prefix, form, &requires_memory_dest);
			if (ok) {
				if (operands.count != 0 && determine_asm_operand_kind(&operands[0]) != AsmOperand_Memory) {
					error(previous_prefix_instr ? previous_prefix_instr : instr->name,
					      "Asm prefix requires '%.*s' to have a memory destination operand", LIT(name));
				}
			} else {
				error(instr->name, "Asm prefix cannot be applied to '%.*s'", LIT(name));
			}
		}

		GB_ASSERT(tmpl_entity->kind == Entity_AsmTemplate);

		// Handle clobbering from mnemonic
		auto clobber = asm_ctx->clobber(mnemonic);

		tmpl_entity->AsmTemplate.clobber_cc       |= clobber.implies_clobber_cc();
		tmpl_entity->AsmTemplate.clobber_memory   |= clobber.implies_clobber_memory();
		tmpl_entity->AsmTemplate.is_volatile |= clobber.implies_side_effects();
		return;
	}

	// failure path
	enum { MAX_VARIANT_COUNT = 32 };
	AsmMismatch mismatch[MAX_VARIANT_COUNT] = {}; // parallels valid_spots for the best form
	i32         want_bits[MAX_VARIANT_COUNT] = {};
	i32         got_bits[MAX_VARIANT_COUNT]  = {};
	if (best_form >= 0) {
		auto &form = forms[best_form];
		for_array(i, operands) {
			int slot = asm_ctx->form_explicit_slot(form, cast(int)i);
			auto type = (slot >= 0) ? form.ops[slot] : asm_ctx->OP_NONE;
			AsmOperandKind dst = asm_ctx->kind_from_operand_type(type);
			AsmOperandKind src = determine_asm_operand_kind(&operands[i]);
			possible_kinds[i] = dst;

			bool kind_ok = (dst == src) ||
			               (dst == AsmOperand_Register_Or_Memory && (src == AsmOperand_Register || src == AsmOperand_Memory));
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

	{
		if (best_score >= gb_max(operands.count*2 - 2, 0)) {
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

			AsmMismatch m = (i < MAX_VARIANT_COUNT) ? mismatch[i] : AsmMismatch_None;

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
				error(operands[i].expr, "'%.*s' operand-%td has the wrong size: expected a %u-bit operand, got %u-bit",
				      LIT(name), i, cast(unsigned)want_bits[i], cast(unsigned)got_bits[i]);
			} else if (m == AsmMismatch_Class) {
				error(operands[i].expr, "'%.*s' operand-%td is in the wrong register class, expected %.*s operand, got %.*s",
				      LIT(name), i, LIT(asm_operand_kind_expected_strings[dst]), LIT(asm_operand_kind_expected_strings[src]));
			} else if (dst) {
				error(operands[i].expr, "'%.*s' operand-%td has an invalid kind, expected %.*s operand",
				      LIT(name), i, LIT(asm_operand_kind_expected_strings[dst]));
			} else {
				error(operands[i].expr, "'%.*s' operand-%td has an invalid kind", LIT(name), i);
			}
		}
	}
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
	gb_unused(param_scope);
	gb_unused(label_scope);

	switch (expr->kind) {
	case_ast_node(i, Ident, expr);
		Entity *found = scope_lookup(param_scope, i->interned, i->hash);
		if (found == nullptr) {
			error(expr, "Undeclared asm parameter '%.*s'", LIT(i->token.string));
			return;
		}
		i->entity = found;
		operand->mode = Addressing_Value;
		operand->type = found->type;
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

		Operand base  = {};
		Operand index = {};
		Operand scale = {};
		Operand disp  = {};
		check_asm_instruction_operand(asm_ctx, ctx, entity, &base,  mem_op->base,  false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &index, mem_op->index, false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &scale, mem_op->scale, false);
		check_asm_instruction_operand(asm_ctx, ctx, entity, &disp,  mem_op->disp,  false);

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

		if (mem_op->type) {
			Type *t = check_type(ctx, mem_op->type);
			if (t != nullptr && t != t_invalid) {
				if (is_valid_asm_parameter_type(t) && !is_type_pointer(t)) {
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
		Entity *found = scope_lookup(label_scope, name->interned, name->hash);
		if (found == nullptr) {
			error(expr, "Undeclared asm label '.%.*s'", LIT(name->token.string));
		}
		name->entity = found;
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

	ate->param_scope = create_scope(nullptr, nullptr);
	ate->label_scope = create_scope(nullptr, nullptr);

	ate->decls.allocator = heap_allocator();

	Type *params  = check_asm_template_signature_params(ctx, ate->param_scope, pt->params,  true,  &ate->decls);
	Type *results = check_asm_template_signature_params(ctx, ate->param_scope, pt->results, false, &ate->decls);

	Type *type = alloc_type_proc(ate->param_scope, params, params->Tuple.variables.count, results, results->Tuple.variables.count, false, pt->calling_convention);
	type->Proc.diverging = pt->diverging;

	entity->type = type;


	bool is_volatile = false;
	bool is_align_stack   = false;
	auto *clobber_registers_set = &entity->AsmTemplate.clobber_registers_set;

	check_asm_specs(asm_ctx, ctx, ate->param_scope, at->specs, &ate->decls);
	{ // check clobbers
		bool clobber_cc     = false;
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
				} else {
					error(clobber->name, "Unknown clobber directive '#%.*s'", LIT(clobber->name.string));
				}
				continue;
			}

			switch (clobber->value->kind) {
			case_ast_node(asm_reg, AsmRegister, clobber->value)
				String reg = asm_reg->name.string;
				Operand operand = {};
				if (check_register(asm_ctx, &operand, asm_reg)) {
					if (string_set_update(clobber_registers_set, reg)) {
						error(clobber->value, "#clobber %%%.*s has already been defined", LIT(reg));
					}
				}
			case_end;
			case_ast_node(ident, Ident, clobber->value);
				String str = ident->token.string;
				if (str == "cc") {
					if (clobber_cc) {
						error(clobber->value, "#clobber cc has already been defined");
					}
					clobber_cc = true;
				} else if (str == "memory") {
					if (clobber_memory) {
						error(clobber->value, "#clobber memory has already been defined");
					}
					clobber_memory = true;
				} else {
					error(clobber->value, "Expected either a register, 'cc', or 'memory' for a '#clobber' specification, got '%.*s'", LIT(str));
				}
			case_end;
			default:
				error(clobber->value, "Expected either a register, 'cc', or 'memory' for a '#clobber' specification");
				break;
			}
		}

		entity->AsmTemplate.clobber_cc       = clobber_cc;
		entity->AsmTemplate.clobber_memory   = clobber_memory;
		entity->AsmTemplate.is_volatile = is_volatile;
		entity->AsmTemplate.is_align_stack   = is_align_stack;
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

			u16 mnemonic = 0;
			CheckMnemomicResult res = check_mnemonic_name(asm_ctx, instr, &mnemonic);

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
				check_mnemonic(asm_ctx, ctx, entity, instr, mnemonic, slice_from_array(operands), previous_prefix, previous_prefix_instr);
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

		default:
			error(instruction_, "Unexpected instruction in asm template");
			break;
		}
	}
	if (previous_prefix != 0) {
		error(previous_prefix_instr, "A prefix must be immediately followed by an instruction, but the template ended");
	}
}