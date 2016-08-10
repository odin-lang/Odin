#include "ssa.cpp"
#include "print_llvm.cpp"

struct ssaGen {
	ssaModule module;
	gbFile output_file;
};

b32 ssa_gen_init(ssaGen *s, Checker *c) {
	if (c->error_collector.count != 0)
		return false;

	gb_for_array(i, c->parser->files) {
		AstFile *f = &c->parser->files[i];
		if (f->error_collector.count != 0)
			return false;
		if (f->tokenizer.error_count != 0)
			return false;
	}

	ssa_module_init(&s->module, c);

	// TODO(bill): generate appropriate output name
	isize pos = string_extension_position(c->parser->init_fullpath);
	gbFileError err = gb_file_create(&s->output_file, gb_bprintf("%.*s.ll", pos, c->parser->init_fullpath.text));
	if (err != gbFileError_None)
		return false;

	return true;
}

void ssa_gen_destroy(ssaGen *s) {
	ssa_module_destroy(&s->module);
	gb_file_close(&s->output_file);
}

void ssa_gen_code(ssaGen *s) {
	if (v_zero == NULL) {
		v_zero   = ssa_make_value_constant(gb_heap_allocator(), t_int, make_exact_value_integer(0));
		v_one    = ssa_make_value_constant(gb_heap_allocator(), t_int, make_exact_value_integer(1));
		v_zero32 = ssa_make_value_constant(gb_heap_allocator(), t_i32, make_exact_value_integer(0));
		v_one32  = ssa_make_value_constant(gb_heap_allocator(), t_i32, make_exact_value_integer(1));
		v_two32  = ssa_make_value_constant(gb_heap_allocator(), t_i32, make_exact_value_integer(2));
	}

	ssaModule *m = &s->module;
	CheckerInfo *info = m->info;
	gbAllocator a = m->allocator;
	ssaProcedure dummy_proc = {};
	dummy_proc.module = m;

	gb_for_array(i, info->entities.entries) {
		auto *entry = &info->entities.entries[i];
		Entity *e = cast(Entity *)cast(uintptr)entry->key;
		DeclInfo *decl = entry->value;

		String name = e->token.string;

		switch (e->kind) {
		case Entity_TypeName: {
			ssaValue *t = ssa_make_value_type_name(a, e);
			map_set(&m->members, hash_string(name), t);
		} break;

		case Entity_Variable: {
			ssaValue *value = ssa_build_expr(&dummy_proc, decl->init_expr);
			if (value->kind == ssaValue_Instr) {
				ssaInstr *i = &value->instr;
				if (i->kind == ssaInstr_Load) {
					value = i->load.address;
				}
			}
			ssaValue *g = ssa_make_value_global(a, e, value);
			map_set(&m->values, hash_pointer(e), g);
			map_set(&m->members, hash_string(name), g);
		} break;

		case Entity_Procedure: {
			ssaValue *p = ssa_make_value_procedure(a, e, decl, m);
			map_set(&m->values, hash_pointer(e), p);
			map_set(&m->members, hash_string(name), p);
		} break;
		}
	}

	gb_for_array(i, m->members.entries) {
		auto *entry = &m->members.entries[i];
		ssaValue *v = entry->value;
		if (v->kind == ssaValue_Proc)
			ssa_build_proc(v);
	}

	// m->layout = make_string("e-p:64:64:64");

	ssa_print_llvm_ir(&s->output_file, &s->module);
}


