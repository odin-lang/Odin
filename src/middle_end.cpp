#include "middle_end.hpp"

struct meGenerator {
	CheckerInfo *info;

	Array<String> output_object_paths;
	Array<String> output_temp_paths;
	String   output_base;
	String   output_name;
	PtrMap<AstPackage *, meModule *> modules;
	meModule default_module;

	PtrMap<Ast *, meProcedure *> anonymous_proc_lits;

	std::atomic<u32> global_array_index;
	std::atomic<u32> global_generated_index;
};

gb_internal meGenerator me_gen;

gb_global Arena global_me_arena = {};
gbAllocator me_allocator() {
	return arena_allocator(&global_me_arena);
}

#define me_new(TYPE) gb_alloc_item(me_allocator(), TYPE)

meValue me_value(meInstruction *instr) {
	meValue value = {meValue_Instruction};
	value.instr = instr;
	return value;
}
meValue me_value(ExactValue *constant) {
	meValue value = {meValue_ConstantValue};
	value.constant = constant;
	return value;
}
meValue me_value(meBlock *block) {
	meValue value = {meValue_Block};
	value.block = block;
	return value;
}
meValue me_value(meProcedure *proc) {
	meValue value = {meValue_Procedure};
	value.proc = proc;
	return value;
}
meValue me_value(meGlobalVariable *global) {
	meValue value = {meValue_GlobalVariable};
	value.global = global;
	return value;
}
meValue me_value(meParameter *param) {
	meValue value = {meValue_Parameter};
	value.param = param;
	return value;
}

meModule *me_pkg_module(AstPackage *pkg) {
	if (pkg != nullptr) {
		auto *found = map_get(&me_gen.modules, pkg);
		if (found) {
			return *found;
		}
	}
	return &me_gen.default_module;
}


void me_add_entity(meModule *m, Entity *e, meValue val) {
	if (e != nullptr) {
		map_set(&m->values, e, val);
	}
}
void me_add_member(meModule *m, String const &name, meValue val) {
	if (name.len > 0) {
		string_map_set(&m->members, name, val);
	}
}
void me_add_member(meModule *m, StringHashKey const &key, meValue val) {
	string_map_set(&m->members, key, val);
}
void me_add_procedure_value(meModule *m, meProcedure *p) {
	if (p->entity != nullptr) {
		map_set(&m->procedure_values, p, p->entity);
	}
	string_map_set(&m->procedures, p->name, p);
}


void me_add_foreign_library_path(meModule *m, Entity *e) {
	if (e == nullptr) {
		return;
	}
	GB_ASSERT(e->kind == Entity_LibraryName);
	GB_ASSERT(e->flags & EntityFlag_Used);

	for_array(i, e->LibraryName.paths) {
		String library_path = e->LibraryName.paths[i];
		if (library_path.len == 0) {
			continue;
		}

		bool ok = true;
		for_array(path_index, m->foreign_library_paths) {
			String path = m->foreign_library_paths[path_index];
	#if defined(GB_SYSTEM_WINDOWS)
			if (str_eq_ignore_case(path, library_path)) {
	#else
			if (str_eq(path, library_path)) {
	#endif
				ok = false;
				break;
			}
		}

		if (ok) {
			array_add(&m->foreign_library_paths, library_path);
		}
	}
}


String me_mangle_name(meModule *m, Entity *e) {
	String name = e->token.string;

	AstPackage *pkg = e->pkg;
	GB_ASSERT_MSG(pkg != nullptr, "Missing package for '%.*s'", LIT(name));
	String pkgn = pkg->name;
	GB_ASSERT(!rune_is_digit(pkgn[0]));
	if (pkgn == "llvm") {
		pkgn = str_lit("llvm$");
	}

	isize max_len = pkgn.len + 1 + name.len + 1;
	bool require_suffix_id = is_type_polymorphic(e->type, true);

	if ((e->scope->flags & (ScopeFlag_File | ScopeFlag_Pkg)) == 0) {
		require_suffix_id = true;
	} else if (is_blank_ident(e->token)) {
		require_suffix_id = true;
	}if (e->flags & EntityFlag_NotExported) {
		require_suffix_id = true;
	}

	if (require_suffix_id) {
		max_len += 21;
	}

	char *new_name = gb_alloc_array(permanent_allocator(), char, max_len);
	isize new_name_len = gb_snprintf(
		new_name, max_len,
		"%.*s.%.*s", LIT(pkgn), LIT(name)
	);
	if (require_suffix_id) {
		char *str = new_name + new_name_len-1;
		isize len = max_len-new_name_len;
		isize extra = gb_snprintf(str, len, "-%llu", cast(unsigned long long)e->id);
		new_name_len += extra-1;
	}

	String mangled_name = make_string((u8 const *)new_name, new_name_len-1);
	return mangled_name;
}

String me_set_nested_type_name_ir_mangled_name(Entity *e, meProcedure *p) {
	// NOTE(bill, 2020-03-08): A polymorphic procedure may take a nested type declaration
	// and as a result, the declaration does not have time to determine what it should be

	GB_ASSERT(e != nullptr && e->kind == Entity_TypeName);
	if (e->TypeName.ir_mangled_name.len != 0)  {
		return e->TypeName.ir_mangled_name;
	}
	GB_ASSERT((e->scope->flags & ScopeFlag_File) == 0);

	if (p == nullptr) {
		Entity *proc = nullptr;
		if (e->parent_proc_decl != nullptr) {
			proc = e->parent_proc_decl->entity;
		} else {
			Scope *scope = e->scope;
			while (scope != nullptr && (scope->flags & ScopeFlag_Proc) == 0) {
				scope = scope->parent;
			}
			GB_ASSERT(scope != nullptr);
			GB_ASSERT(scope->flags & ScopeFlag_Proc);
			proc = scope->procedure_entity;
		}
		GB_ASSERT(proc->kind == Entity_Procedure);
		if (proc->me_procedure != nullptr) {
			p = proc->me_procedure;
		}
	}

	// NOTE(bill): Generate a new name
	// parent_proc.name-guid
	String ts_name = e->token.string;

	if (p != nullptr) {
		isize name_len = p->name.len + 1 + ts_name.len + 1 + 10 + 1;
		char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
		u32 guid = ++p->module->nested_type_name_guid;
		name_len = gb_snprintf(name_text, name_len, "%.*s.%.*s-%u", LIT(p->name), LIT(ts_name), guid);

		String name = make_string(cast(u8 *)name_text, name_len-1);
		e->TypeName.ir_mangled_name = name;
		return name;
	} else {
		// NOTE(bill): a nested type be required before its parameter procedure exists. Just give it a temp name for now
		isize name_len = 9 + 1 + ts_name.len + 1 + 10 + 1;
		char *name_text = gb_alloc_array(permanent_allocator(), char, name_len);
		static u32 guid = 0;
		guid += 1;
		name_len = gb_snprintf(name_text, name_len, "_internal.%.*s-%u", LIT(ts_name), guid);

		String name = make_string(cast(u8 *)name_text, name_len-1);
		e->TypeName.ir_mangled_name = name;
		return name;
	}
}


String me_get_entity_name(meModule *m, Entity *e, String default_name) {
	if (e != nullptr && e->kind == Entity_TypeName && e->TypeName.ir_mangled_name.len != 0) {
		return e->TypeName.ir_mangled_name;
	}
	GB_ASSERT(e != nullptr);

	if (e->pkg == nullptr) {
		return e->token.string;
	}

	if (e->kind == Entity_TypeName && (e->scope->flags & ScopeFlag_File) == 0) {
		return me_set_nested_type_name_ir_mangled_name(e, nullptr);
	}

	String name = {};

	bool no_name_mangle = false;

	if (e->kind == Entity_Variable) {
		bool is_foreign = e->Variable.is_foreign;
		bool is_export  = e->Variable.is_export;
		no_name_mangle = e->Variable.link_name.len > 0 || is_foreign || is_export;
		if (e->Variable.link_name.len > 0) {
			return e->Variable.link_name;
		}
	} else if (e->kind == Entity_Procedure && e->Procedure.link_name.len > 0) {
		return e->Procedure.link_name;
	} else if (e->kind == Entity_Procedure && e->Procedure.is_export) {
		no_name_mangle = true;
	}

	if (!no_name_mangle) {
		name = me_mangle_name(m, e);
	}
	if (name.len == 0) {
		name = e->token.string;
	}

	if (e->kind == Entity_TypeName) {
		e->TypeName.ir_mangled_name = name;
	} else if (e->kind == Entity_Procedure) {
		e->Procedure.link_name = name;
	}

	return name;
}



void me_module_init(meModule *m, Checker *c) {
	m->info = &c->info;

	gbString module_name = gb_string_make(heap_allocator(), "odin_package");
	if (m->pkg) {
		module_name = gb_string_appendc(module_name, "-");
		module_name = gb_string_append_length(module_name, m->pkg->name.text, m->pkg->name.len);
	} else if (USE_SEPARATE_MODULES) {
		module_name = gb_string_appendc(module_name, "-builtin");
	}

	gbAllocator a = heap_allocator();
	map_init(&m->values, a);
	map_init(&m->soa_values, a);
	string_map_init(&m->members, a);
	map_init(&m->procedure_values, a);
	string_map_init(&m->procedures, a);
	string_map_init(&m->const_strings, a);
	map_init(&m->equal_procs, a);
	map_init(&m->hasher_procs, a);
	array_init(&m->procedures_to_generate, a, 0, 1024);
	array_init(&m->foreign_library_paths,  a, 0, 1024);
	array_init(&m->missing_procedures_to_check, a, 0, 16);

	string_map_init(&m->objc_classes, a);
	string_map_init(&m->objc_selectors, a);
}


bool me_generator_init(Checker *c) {
	if (global_error_collector.count != 0) {
		return false;
	}

	isize tc = c->parser->total_token_count;
	if (tc < 2) {
		return false;
	}

	meGenerator *gen = &me_gen;

	String init_fullpath = c->parser->init_fullpath;

	if (build_context.out_filepath.len == 0) {
		gen->output_name = remove_directory_from_path(init_fullpath);
		gen->output_name = remove_extension_from_path(gen->output_name);
		gen->output_name = string_trim_whitespace(gen->output_name);
		if (gen->output_name.len == 0) {
			gen->output_name = c->info.init_scope->pkg->name;
		}
		gen->output_base = gen->output_name;
	} else {
		gen->output_name = build_context.out_filepath;
		gen->output_name = string_trim_whitespace(gen->output_name);
		if (gen->output_name.len == 0) {
			gen->output_name = c->info.init_scope->pkg->name;
		}
		isize pos = string_extension_position(gen->output_name);
		if (pos < 0) {
			gen->output_base = gen->output_name;
		} else {
			gen->output_base = substring(gen->output_name, 0, pos);
		}
	}
	gbAllocator ha = heap_allocator();
	array_init(&gen->output_object_paths, ha);
	array_init(&gen->output_temp_paths, ha);

	gen->output_base = path_to_full_path(ha, gen->output_base);

	gbString output_file_path = gb_string_make_length(ha, gen->output_base.text, gen->output_base.len);
	output_file_path = gb_string_appendc(output_file_path, ".obj");
	defer (gb_string_free(output_file_path));

	gen->info = &c->info;

	map_init(&gen->modules, permanent_allocator(), gen->info->packages.entries.count*2);
	map_init(&gen->anonymous_proc_lits, heap_allocator(), 1024);

	if (USE_SEPARATE_MODULES) {
		for_array(i, gen->info->packages.entries) {
			AstPackage *pkg = gen->info->packages.entries[i].value;

			auto m = gb_alloc_item(permanent_allocator(), meModule);
			m->pkg = pkg;
			map_set(&gen->modules, pkg, m);
			me_module_init(m, c);
		}
	}

	map_set(&gen->modules, cast(AstPackage *)nullptr, &gen->default_module);
	me_module_init(&gen->default_module, c);
	return true;
}

meProcedure *me_procedure_create(meModule *m, Entity *entity, bool ignore_body) {
	GB_ASSERT(entity != nullptr);
	GB_ASSERT(entity->kind == Entity_Procedure);
	if (!entity->Procedure.is_foreign) {
		GB_ASSERT_MSG(entity->flags & EntityFlag_ProcBodyChecked, "%.*s :: %s", LIT(entity->token.string), type_to_string(entity->type));
	}

	String link_name = {};

	if (ignore_body) {
		meModule *other_module = me_pkg_module(entity->pkg);
		link_name = me_get_entity_name(other_module, entity);
	} else {
		link_name = me_get_entity_name(m, entity);
	}

	{
		StringHashKey key = string_hash_string(link_name);
		meValue *found = string_map_get(&m->members, key);
		if (found) {
			me_add_entity(m, entity, *found);
			return string_map_must_get(&m->procedures, key);
		}
	}

	meProcedure *p = me_new(meProcedure);

	p->module = m;
	entity->me_procedure = p;
	p->entity = entity;
	p->name = link_name;

	DeclInfo *decl = entity->decl_info;

	ast_node(pl, ProcLit, decl->proc_lit);
	Type *pt = base_type(entity->type);
	GB_ASSERT(pt->kind == Type_Proc);

	p->type           = entity->type;
	p->type_expr      = decl->type_expr;
	p->body           = pl->body;
	switch (pl->inlining) {
	case ProcInlining_none:
		break;
	case ProcInlining_inline:
		p->flags |= meProcedureFlag_Inline;
		break;
	case ProcInlining_no_inline:
		p->flags |= meProcedureFlag_NoInline;
		break;
	}
	if (entity->Procedure.is_foreign) {
		p->flags |= meProcedureFlag_Foreign;
	}
	if (entity->Procedure.is_export) {
		p->flags |= meProcedureFlag_Export;
	}
	p->flags &= ~meProcedureFlag_EntryPoint;

	gbAllocator a = heap_allocator();
	p->children.allocator      = a;
	p->defer_stmts.allocator   = a;
	p->blocks.allocator        = a;
	p->branch_blocks.allocator = a;
	p->context_stack.allocator = a;
	p->scope_stack.allocator   = a;

	if (p->flags & meProcedureFlag_Foreign) {
		me_add_foreign_library_path(p->module, entity->Procedure.foreign_library);
	}

	if (entity->flags & EntityFlag_Cold) {
		p->flags |= meProcedureFlag_Cold;
	}

	meValue proc_value = me_value(p);
	me_add_entity(m, entity,  proc_value);
	me_add_member(m, p->name, proc_value);
	me_add_procedure_value(m, p);

	p->linkage = meLinkage_Strong; // default

	if (p->flags & meProcedureFlag_Export) {
		p->linkage = meLinkage_Export;
	} else if (!(p->flags & meProcedureFlag_Foreign)) {
		if (!USE_SEPARATE_MODULES) {
			p->linkage = meLinkage_Internal;
			// NOTE(bill): if a procedure is defined in package runtime and uses a custom link name,
			// then it is very likely it is required by LLVM and thus cannot have internal linkage
			if (entity->pkg != nullptr && entity->pkg->kind == Package_Runtime && p->body != nullptr) {
				GB_ASSERT(entity->kind == Entity_Procedure);
				String link_name = entity->Procedure.link_name;
				if (entity->flags & EntityFlag_CustomLinkName &&
				    link_name != "") {
					if (string_starts_with(link_name, str_lit("__"))) {
						p->linkage = meLinkage_Strong;
					} else {
						p->linkage = meLinkage_Internal;
					}
				}
			}
		}
	}
	if (entity->flags & EntityFlag_CustomLinkage_Internal) {
		p->linkage = meLinkage_Internal;
	} else if (entity->flags & EntityFlag_CustomLinkage_Strong) {
		p->linkage = meLinkage_Strong;
	} else if (entity->flags & EntityFlag_CustomLinkage_Weak) {
		p->linkage = meLinkage_Weak;
	} else if (entity->flags & EntityFlag_CustomLinkage_LinkOnce) {
		p->linkage = meLinkage_LinkOnce;
	}

	if (ignore_body) {
		p->body = nullptr;
		p->linkage = meLinkage_Strong;
	}

	return p;
}

meBlock *me_block_create(meProcedure *p, char const *name) {
	auto *b = me_new(meBlock);
	b->scope = p->curr_scope;
	b->scope_index = p->scope_index;

	b->preds.allocator = heap_allocator();
	b->succs.allocator = heap_allocator();

	array_add(&p->blocks, b);

	return b;
}

void me_block_start(meProcedure *p, meBlock *b) {
	p->curr_block = b;
}

void me_build_stmt(meProcedure *p, Ast *stmt) {

}

meContextData *me_push_context_onto_stack_from_implicit_parameter(meProcedure *p) {
	// TODO(bill): me_push_context_onto_stack_from_implicit_parameter
	return nullptr;
}


void me_procedure_body_begin(meProcedure *p) {
	DeclInfo *decl = decl_info_of_entity(p->entity);
	if (decl != nullptr) {
		for_array(i, decl->labels) {
			BlockLabel bl = decl->labels[i];
			meBranchBlocks bb = {bl.label, nullptr, nullptr};
			array_add(&p->branch_blocks, bb);
		}
	}

	p->decl_block  = me_block_create(p, "decls");
	p->entry_block = me_block_create(p, "entry");
	me_block_start(p, p->entry_block);

	GB_ASSERT(p->type != nullptr);

	{
		// TODO(bill): parameter types
	}
	if (p->type->Proc.calling_convention == ProcCC_Odin) {
		me_push_context_onto_stack_from_implicit_parameter(p);
	}

	me_block_start(p, p->entry_block);
}

void me_procedure_body_end(meProcedure *p) {
	// TODO(bill): me_procedure_body_end
}


void me_generate_procedure(meModule *m, meProcedure *p) {
	if (p->is_done) {
		return;
	}
	if (p->body != nullptr) {
		m->curr_procedure = p;
		me_procedure_body_begin(p);
		me_build_stmt(p, p->body);
		me_procedure_body_end(p);
		p->is_done = true;
		m->curr_procedure = nullptr;
	}

	gb_printf_err("[procedure] %.*s\n", LIT(p->name));

	// Add Flags
	if (p->body != nullptr) {
		if (p->name == "memcpy" || p->name == "memmove" ||
		    p->name == "runtime.mem_copy" || p->name == "mem_copy_non_overlapping" ||
		    string_starts_with(p->name, str_lit("llvm.memcpy")) ||
		    string_starts_with(p->name, str_lit("llvm.memmove"))) {
			p->flags |= meProcedureFlag_WithoutMemcpy;
		}
	}
}



bool me_generate(Checker *c) {
	if (!me_generator_init(c)) {
		return false;
	}
	CheckerInfo *info = &c->info;
	auto *min_dep_set = &info->minimum_dependency_set;


	for_array(i, info->entities) {
		Entity *e = info->entities[i];
		String  name  = e->token.string;
		Scope * scope = e->scope;

		if ((scope->flags & ScopeFlag_File) == 0) {
			continue;
		}

		Scope *package_scope = scope->parent;
		GB_ASSERT(package_scope->flags & ScopeFlag_Pkg);

		switch (e->kind) {
		case Entity_Variable:
			// NOTE(bill): Handled above as it requires a specific load order
			continue;
		case Entity_ProcGroup:
		case Entity_TypeName:
			continue;

		case Entity_Procedure:
			break;
		}

		if (!ptr_set_exists(min_dep_set, e)) {
			// NOTE(bill): Nothing depends upon it so doesn't need to be built
			continue;
		}

		meModule *m = me_pkg_module(e->pkg);
		String mangled_name = me_get_entity_name(m, e);

		switch (e->kind) {
		case Entity_Procedure:
			array_add(&m->procedures_to_generate, me_procedure_create(m, e));
			break;
		}
	}

	for_array(j, me_gen.modules.entries) {
		meModule *m = me_gen.modules.entries[j].value;
		for_array(i, m->procedures_to_generate) {
			meProcedure *p = m->procedures_to_generate[i];
			me_generate_procedure(m, p);
		}
	}

	gb_printf_err("[middle end pass done]\n");
	gb_exit(0);
	return true;
}