void ssa_begin_procedure_body(ssaProcedure *proc) {
	array_init(&proc->blocks,      heap_allocator());
	array_init(&proc->defer_stmts, heap_allocator());
	array_init(&proc->children,    heap_allocator());

	proc->decl_block  = ssa_add_block(proc, proc->type_expr, "decls");
	proc->entry_block = ssa_add_block(proc, proc->type_expr, "entry");
	proc->curr_block  = proc->entry_block;

	if (proc->type->Proc.params != NULL) {
		auto *params = &proc->type->Proc.params->Tuple;
		for (isize i = 0; i < params->variable_count; i++) {
			Entity *e = params->variables[i];
			ssaValue *param = ssa_add_param(proc, e);
			array_add(&proc->params, param);
		}
	}
}


void ssa_end_procedure_body(ssaProcedure *proc) {
	if (proc->type->Proc.result_count == 0) {
		ssa_emit_return(proc, NULL);
	}

	if (proc->curr_block->instrs.count == 0) {
		ssa_emit_unreachable(proc);
	}

	proc->curr_block = proc->decl_block;
	ssa_emit_jump(proc, proc->entry_block);

	ssa_opt_proc(proc);

// Number registers
	i32 reg_index = 0;
	for_array(i, proc->blocks) {
		ssaBlock *b = proc->blocks[i];
		b->index = i;
		for_array(j, b->instrs) {
			ssaValue *value = b->instrs[j];
			GB_ASSERT(value->kind == ssaValue_Instr);
			ssaInstr *instr = &value->Instr;
			if (ssa_instr_type(instr) == NULL) { // NOTE(bill): Ignore non-returning instructions
				continue;
			}
			value->index = reg_index;
			reg_index++;
		}
	}
}


void ssa_insert_code_before_proc(ssaProcedure* proc, ssaProcedure *parent) {
	if (parent == NULL) {
		if (proc->name == "main") {
			ssa_emit_startup_runtime(proc);
		}
	}
}

void ssa_build_proc(ssaValue *value, ssaProcedure *parent) {
	ssaProcedure *proc = &value->Proc;

	proc->parent = parent;

	if (proc->entity != NULL) {
		ssaModule *m = proc->module;
		CheckerInfo *info = m->info;
		Entity *e = proc->entity;
		String filename = e->token.pos.file;
		AstFile **found = map_get(&info->files, hash_string(filename));
		GB_ASSERT(found != NULL);
		AstFile *f = *found;
		ssaDebugInfo *di_file = NULL;

		ssaDebugInfo **di_file_found = map_get(&m->debug_info, hash_pointer(f));
		if (di_file_found) {
			di_file = *di_file_found;
			GB_ASSERT(di_file->kind == ssaDebugInfo_File);
		} else {
			di_file = ssa_add_debug_info_file(proc, f);
		}

		ssa_add_debug_info_proc(proc, e, proc->name, di_file);
	}

	if (proc->body != NULL) {
		u32 prev_stmt_state_flags = proc->module->stmt_state_flags;
		defer (proc->module->stmt_state_flags = prev_stmt_state_flags);

		if (proc->tags != 0) {
			u32 in = proc->tags;
			u32 out = proc->module->stmt_state_flags;
			defer (proc->module->stmt_state_flags = out);

			if (in & ProcTag_bounds_check) {
				out |= StmtStateFlag_bounds_check;
				out &= ~StmtStateFlag_no_bounds_check;
			} else if (in & ProcTag_no_bounds_check) {
				out |= StmtStateFlag_no_bounds_check;
				out &= ~StmtStateFlag_bounds_check;
			}
		}


		ssa_begin_procedure_body(proc);
		ssa_insert_code_before_proc(proc, parent);
		ssa_build_stmt(proc, proc->body);
		ssa_end_procedure_body(proc);
	}
}


