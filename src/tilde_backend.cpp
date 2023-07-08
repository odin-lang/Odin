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

	TB_Arena *arena = tb_default_arena();

	TB_Global *str = nullptr;
	{
		TB_Global *str_data = nullptr;
		{
			str_data = tb_global_create(m, "csb$1", nullptr, TB_LINKAGE_PRIVATE);
			tb_global_set_storage(m, tb_module_get_rdata(m), str_data, 8, 1, 1);
			void *region = tb_global_add_region(m, str_data, 0, 8);
			memcpy(region, "Hellope\x00", 8);
		}

		str = tb_global_create(m, "global$str", nullptr, TB_LINKAGE_PRIVATE);
		tb_global_set_storage(m, tb_module_get_rdata(m), str, 16, 8, 2);
		tb_global_add_symbol_reloc(m, str, 0, cast(TB_Symbol *)str_data);
		void *len = tb_global_add_region(m, str, 8, 8);
		*cast(i64 *)len = 7;
	}

	{
		TB_PrototypeParam printf_ret = {TB_TYPE_I32};
		TB_PrototypeParam printf_params = {TB_TYPE_PTR};
		TB_FunctionPrototype *printf_proto = tb_prototype_create(m, TB_STDCALL, 1, &printf_params, 1, &printf_ret, true);
		TB_External *printf_proc = tb_extern_create(m, "printf", TB_EXTERNAL_SO_LOCAL);

		TB_PrototypeParam main_ret = {TB_TYPE_I32};
		TB_FunctionPrototype *main_proto = tb_prototype_create(m, TB_STDCALL, 0, nullptr, 1, &main_ret, false);
		TB_Function *         p = tb_function_create(m, "main", TB_LINKAGE_PUBLIC, TB_COMDAT_NONE);
		tb_function_set_prototype(p, main_proto, arena);


		auto str_ptr = tb_inst_get_symbol_address(p, cast(TB_Symbol *)str);
		auto str_data_ptr_ptr = tb_inst_member_access(p, str_ptr, 0);
		auto str_data_ptr = tb_inst_load(p, TB_TYPE_PTR, str_data_ptr_ptr, 1, false);
		auto str_len_ptr = tb_inst_member_access(p, str_ptr, 8);
		auto str_len = tb_inst_load(p, TB_TYPE_I64, str_len_ptr, 8, false);


		TB_Node *params[4] = {};
		params[0] = tb_inst_cstring(p, "%.*s %s!\n");
		params[1] = tb_inst_trunc(p, str_len, TB_TYPE_I32);
		params[2] = str_data_ptr;
		params[3] = tb_inst_cstring(p, "World");
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