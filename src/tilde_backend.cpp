#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4200)
	#pragma warning(disable: 4201)
	#define restrict gb_restrict
#endif

#include "tilde/tb.h"

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif


bool tb_generate_code(Checker *c) {
	TB_FeatureSet feature_set = {};
	bool is_jit = false;
	TB_Module *m = tb_module_create(TB_ARCH_X86_64, TB_SYSTEM_WINDOWS, &feature_set, is_jit);
	defer (tb_module_destroy(m));
	tb_module_set_tls_index(m, "_tls_index");


	TB_Arena *arena = nullptr;

	{
		TB_PrototypeParam printf_ret = {TB_TYPE_I32};
		TB_PrototypeParam printf_params = {TB_TYPE_PTR};
		TB_FunctionPrototype *printf_proto = tb_prototype_create(m, TB_STDCALL, 1, &printf_params, 1, &printf_ret, true);
		TB_External *printf_proc = tb_extern_create(m, "printf", TB_EXTERNAL_SO_LOCAL);

		TB_PrototypeParam main_ret = {TB_TYPE_I32};
		TB_FunctionPrototype *main_proto = tb_prototype_create(m, TB_STDCALL, 0, nullptr, 1, &main_ret, false);
		TB_Function *         p = tb_function_create(m, "main", TB_LINKAGE_PUBLIC, TB_COMDAT_NONE);
		tb_function_set_prototype(p, main_proto, arena);


		TB_Node *params[2] = {};
		params[0] = tb_inst_cstring(p, "Hellope %s!\n");
		params[1] = tb_inst_cstring(p, "World");
		TB_MultiOutput output = tb_inst_call(p, printf_proto, tb_inst_get_symbol_address(p, cast(TB_Symbol *)printf_proc), gb_count_of(params), params);
		gb_unused(output);

		TB_Node *value = tb_inst_uint(p, TB_TYPE_I32, 0);
		tb_inst_ret(p, 1, &value);

		tb_module_compile_function(m, p, TB_ISEL_FAST);

		TB_ExportBuffer export_buffer = tb_module_object_export(m, TB_DEBUGFMT_NONE);
		defer (tb_export_buffer_free(export_buffer));

		char const *path = "W:/Odin/tilde_main.obj";
		GB_ASSERT(tb_export_buffer_to_file(export_buffer, path));
	}
	return false;
}