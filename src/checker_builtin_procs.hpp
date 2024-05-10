// checker_builtin_procs.hpp

enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_len,
	BuiltinProc_cap,

	BuiltinProc_size_of,
	BuiltinProc_align_of,
	BuiltinProc_offset_of,
	BuiltinProc_offset_of_by_string,
	BuiltinProc_type_of,
	BuiltinProc_type_info_of,
	BuiltinProc_typeid_of,
	

	BuiltinProc_swizzle,

	BuiltinProc_complex,
	BuiltinProc_quaternion,
	BuiltinProc_real,
	BuiltinProc_imag,
	BuiltinProc_jmag,
	BuiltinProc_kmag,
	BuiltinProc_conj,

	BuiltinProc_expand_values,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_soa_zip,
	BuiltinProc_soa_unzip,

	BuiltinProc_unreachable,

	BuiltinProc_raw_data,

	BuiltinProc_DIRECTIVE, // NOTE(bill): This is used for specialized hash-prefixed procedures

	// "Intrinsics"
	BuiltinProc_is_package_imported,

	BuiltinProc_has_target_feature,

	BuiltinProc_transpose,
	BuiltinProc_outer_product,
	BuiltinProc_hadamard_product,
	BuiltinProc_matrix_flatten,
	
	BuiltinProc_soa_struct,

	BuiltinProc_alloca,
	BuiltinProc_cpu_relax,
	BuiltinProc_trap,
	BuiltinProc_debug_trap,
	BuiltinProc_read_cycle_counter,

	BuiltinProc_count_ones,
	BuiltinProc_count_zeros,
	BuiltinProc_count_trailing_zeros,
	BuiltinProc_count_leading_zeros,
	BuiltinProc_reverse_bits,
	BuiltinProc_byte_swap,

	BuiltinProc_overflow_add,
	BuiltinProc_overflow_sub,
	BuiltinProc_overflow_mul,

	BuiltinProc_sqrt,
	BuiltinProc_fused_mul_add,

	BuiltinProc_mem_copy,
	BuiltinProc_mem_copy_non_overlapping,
	BuiltinProc_mem_zero,
	BuiltinProc_mem_zero_volatile,

	BuiltinProc_ptr_offset,
	BuiltinProc_ptr_sub,

	BuiltinProc_volatile_store,
	BuiltinProc_volatile_load,
	
	BuiltinProc_unaligned_store,
	BuiltinProc_unaligned_load,
	BuiltinProc_non_temporal_store,
	BuiltinProc_non_temporal_load,
	
	BuiltinProc_prefetch_read_instruction,
	BuiltinProc_prefetch_read_data,
	BuiltinProc_prefetch_write_instruction,
	BuiltinProc_prefetch_write_data,

	BuiltinProc_atomic_type_is_lock_free,
	BuiltinProc_atomic_thread_fence,
	BuiltinProc_atomic_signal_fence,
	BuiltinProc_atomic_store,
	BuiltinProc_atomic_store_explicit,
	BuiltinProc_atomic_load,
	BuiltinProc_atomic_load_explicit,
	BuiltinProc_atomic_add,
	BuiltinProc_atomic_add_explicit,
	BuiltinProc_atomic_sub,
	BuiltinProc_atomic_sub_explicit,
	BuiltinProc_atomic_and,
	BuiltinProc_atomic_and_explicit,
	BuiltinProc_atomic_nand,
	BuiltinProc_atomic_nand_explicit,
	BuiltinProc_atomic_or,
	BuiltinProc_atomic_or_explicit,
	BuiltinProc_atomic_xor,
	BuiltinProc_atomic_xor_explicit,
	BuiltinProc_atomic_exchange,
	BuiltinProc_atomic_exchange_explicit,
	BuiltinProc_atomic_compare_exchange_strong,
	BuiltinProc_atomic_compare_exchange_strong_explicit,
	BuiltinProc_atomic_compare_exchange_weak,
	BuiltinProc_atomic_compare_exchange_weak_explicit,

	BuiltinProc_fixed_point_mul,
	BuiltinProc_fixed_point_div,
	BuiltinProc_fixed_point_mul_sat,
	BuiltinProc_fixed_point_div_sat,

	BuiltinProc_expect,

BuiltinProc__simd_begin,
	BuiltinProc_simd_add,
	BuiltinProc_simd_sub,
	BuiltinProc_simd_mul,
	BuiltinProc_simd_div,
	BuiltinProc_simd_rem,
	BuiltinProc_simd_shl,        // Odin logic
	BuiltinProc_simd_shr,        // Odin logic
	BuiltinProc_simd_shl_masked, // C logic
	BuiltinProc_simd_shr_masked, // C logic

	BuiltinProc_simd_add_sat, // saturation arithmetic
	BuiltinProc_simd_sub_sat, // saturation arithmetic

	BuiltinProc_simd_bit_and,
	BuiltinProc_simd_bit_or,
	BuiltinProc_simd_bit_xor,
	BuiltinProc_simd_bit_and_not,

	BuiltinProc_simd_neg,
	BuiltinProc_simd_abs,

	BuiltinProc_simd_min,
	BuiltinProc_simd_max,
	BuiltinProc_simd_clamp,

	BuiltinProc_simd_lanes_eq,
	BuiltinProc_simd_lanes_ne,
	BuiltinProc_simd_lanes_lt,
	BuiltinProc_simd_lanes_le,
	BuiltinProc_simd_lanes_gt,
	BuiltinProc_simd_lanes_ge,

	BuiltinProc_simd_extract,
	BuiltinProc_simd_replace,

	BuiltinProc_simd_reduce_add_ordered,
	BuiltinProc_simd_reduce_mul_ordered,
	BuiltinProc_simd_reduce_min,
	BuiltinProc_simd_reduce_max,
	BuiltinProc_simd_reduce_and,
	BuiltinProc_simd_reduce_or,
	BuiltinProc_simd_reduce_xor,

	BuiltinProc_simd_shuffle,
	BuiltinProc_simd_select,

	BuiltinProc_simd_ceil,
	BuiltinProc_simd_floor,
	BuiltinProc_simd_trunc,
	BuiltinProc_simd_nearest,

	BuiltinProc_simd_to_bits,

	BuiltinProc_simd_lanes_reverse,
	BuiltinProc_simd_lanes_rotate_left,
	BuiltinProc_simd_lanes_rotate_right,


	// Platform specific SIMD intrinsics
	BuiltinProc_simd_x86__MM_SHUFFLE,
BuiltinProc__simd_end,
	
	// Platform specific intrinsics
	BuiltinProc_syscall,

	BuiltinProc_x86_cpuid,
	BuiltinProc_x86_xgetbv,

	// Constant type tests

BuiltinProc__type_begin,

	BuiltinProc_type_base_type,
	BuiltinProc_type_core_type,
	BuiltinProc_type_elem_type,

	BuiltinProc_type_convert_variants_to_pointers,
	BuiltinProc_type_merge,

BuiltinProc__type_simple_boolean_begin,
	BuiltinProc_type_is_boolean,
	BuiltinProc_type_is_integer,
	BuiltinProc_type_is_rune,
	BuiltinProc_type_is_float,
	BuiltinProc_type_is_complex,
	BuiltinProc_type_is_quaternion,
	BuiltinProc_type_is_string,
	BuiltinProc_type_is_typeid,
	BuiltinProc_type_is_any,

	BuiltinProc_type_is_endian_platform,
	BuiltinProc_type_is_endian_little,
	BuiltinProc_type_is_endian_big,
	BuiltinProc_type_is_unsigned,
	BuiltinProc_type_is_numeric,
	BuiltinProc_type_is_ordered,
	BuiltinProc_type_is_ordered_numeric,
	BuiltinProc_type_is_indexable,
	BuiltinProc_type_is_sliceable,
	BuiltinProc_type_is_comparable,
	BuiltinProc_type_is_simple_compare, // easily compared using memcmp
	BuiltinProc_type_is_dereferenceable,
	BuiltinProc_type_is_valid_map_key,
	BuiltinProc_type_is_valid_matrix_elements,

	BuiltinProc_type_is_named,
	BuiltinProc_type_is_pointer,
	BuiltinProc_type_is_multi_pointer,
	BuiltinProc_type_is_array,
	BuiltinProc_type_is_enumerated_array,
	BuiltinProc_type_is_slice,
	BuiltinProc_type_is_dynamic_array,
	BuiltinProc_type_is_map,
	BuiltinProc_type_is_struct,
	BuiltinProc_type_is_union,
	BuiltinProc_type_is_enum,
	BuiltinProc_type_is_proc,
	BuiltinProc_type_is_bit_set,
	BuiltinProc_type_is_simd_vector,
	BuiltinProc_type_is_matrix,

	BuiltinProc_type_is_specialized_polymorphic_record,
	BuiltinProc_type_is_unspecialized_polymorphic_record,

	BuiltinProc_type_has_nil,

BuiltinProc__type_simple_boolean_end,

	BuiltinProc_type_has_field,
	BuiltinProc_type_field_type,

	BuiltinProc_type_is_specialization_of,

	BuiltinProc_type_is_variant_of,
	BuiltinProc_type_union_tag_type,
	BuiltinProc_type_union_tag_offset,
	BuiltinProc_type_union_base_tag_value,
	BuiltinProc_type_union_variant_count,
	BuiltinProc_type_variant_type_of,
	BuiltinProc_type_variant_index_of,

	BuiltinProc_type_bit_set_elem_type,
	BuiltinProc_type_bit_set_underlying_type,

	BuiltinProc_type_struct_field_count,

	BuiltinProc_type_proc_parameter_count,
	BuiltinProc_type_proc_return_count,

	BuiltinProc_type_proc_parameter_type,
	BuiltinProc_type_proc_return_type,

	BuiltinProc_type_polymorphic_record_parameter_count,
	BuiltinProc_type_polymorphic_record_parameter_value,

	BuiltinProc_type_is_subtype_of,

	BuiltinProc_type_field_index_of,

	BuiltinProc_type_bit_set_backing_type,

	BuiltinProc_type_equal_proc,
	BuiltinProc_type_hasher_proc,
	BuiltinProc_type_map_info,
	BuiltinProc_type_map_cell_info,

BuiltinProc__type_end,

	BuiltinProc___entry_point,

	BuiltinProc_objc_send,
	BuiltinProc_objc_find_selector,
	BuiltinProc_objc_find_class,
	BuiltinProc_objc_register_selector,
	BuiltinProc_objc_register_class,

	BuiltinProc_constant_utf16_cstring,

	BuiltinProc_wasm_memory_grow,
	BuiltinProc_wasm_memory_size,
	BuiltinProc_wasm_memory_atomic_wait32,
	BuiltinProc_wasm_memory_atomic_notify32,

	BuiltinProc_valgrind_client_request,

	BuiltinProc_COUNT,
};
gb_global BuiltinProc builtin_procs[BuiltinProc_COUNT] = {
	{STR_LIT(""),                 0, false, Expr_Stmt, BuiltinProcPkg_builtin},

	{STR_LIT("len"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("cap"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("size_of"),          1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("align_of"),         1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("offset_of"),        1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("offset_of_by_string"),2, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("type_of"),          1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("type_info_of"),     1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("typeid_of"),        1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("swizzle"),          1, true,  Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("complex"),          2, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("quaternion"),       4, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("real"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("imag"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("jmag"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("kmag"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("conj"),             1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("expand_values"),    1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("min"),              1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("max"),              1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("abs"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("clamp"),            3, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("soa_zip"),          1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("soa_unzip"),        1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("unreachable"),      0, false, Expr_Expr, BuiltinProcPkg_builtin, /*diverging*/true},

	{STR_LIT("raw_data"),         1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT(""),                 0, true,  Expr_Expr, BuiltinProcPkg_builtin}, // DIRECTIVE


	// "Intrinsics"
	{STR_LIT("is_package_imported"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("has_target_feature"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("transpose"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("outer_product"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("hadamard_product"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("matrix_flatten"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
		
	{STR_LIT("soa_struct"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics}, // Type

	{STR_LIT("alloca"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("cpu_relax"), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("trap"),               0, false, Expr_Expr, BuiltinProcPkg_intrinsics, /*diverging*/true},
	{STR_LIT("debug_trap"),         0, false, Expr_Stmt, BuiltinProcPkg_intrinsics, /*diverging*/false},
	{STR_LIT("read_cycle_counter"), 0, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("count_ones"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("count_zeros"),          1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("count_trailing_zeros"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("count_leading_zeros"),  1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("reverse_bits"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("byte_swap"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("overflow_add"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("overflow_sub"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("overflow_mul"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("sqrt"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("fused_mul_add"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("mem_copy"),                 3, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("mem_copy_non_overlapping"), 3, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("mem_zero"),                 2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("mem_zero_volatile"),        2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("ptr_offset"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("ptr_sub"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("volatile_store"),  2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("volatile_load"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	
	{STR_LIT("unaligned_store"),  2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("unaligned_load"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("non_temporal_store"),  2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("non_temporal_load"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	
	{STR_LIT("prefetch_read_instruction"),  2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("prefetch_read_data"),         2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("prefetch_write_instruction"), 2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("prefetch_write_data"),        2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_type_is_lock_free"),                1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_thread_fence"),                     1, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_signal_fence"),                     1, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store"),                            2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_explicit"),                   3, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load"),                             1, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_load_explicit"),                    2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_add"),                              2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_add_explicit"),                     3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_sub"),                              2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_sub_explicit"),                     3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_and"),                              2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_and_explicit"),                     3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_nand"),                             2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_nand_explicit"),                    3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_or"),                               2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_or_explicit"),                      3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_xor"),                              2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_xor_explicit"),                     3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_exchange"),                         2, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_exchange_explicit"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_compare_exchange_strong"),          3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_compare_exchange_strong_explicit"), 5, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_compare_exchange_weak"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("atomic_compare_exchange_weak_explicit"),   5, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},

	{STR_LIT("fixed_point_mul"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("fixed_point_div"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("fixed_point_mul_sat"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("fixed_point_div_sat"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("expect"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_add"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_sub"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_mul"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_div"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_rem"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_shl"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_shr"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_shl_masked"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_shr_masked"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_add_sat"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_sub_sat"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_bit_and"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_bit_or"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_bit_xor"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_bit_and_not"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_neg"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_abs"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_min"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_max"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_clamp"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_lanes_eq"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_ne"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_lt"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_le"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_gt"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_ge"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_extract"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_replace"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_reduce_add_ordered"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_reduce_mul_ordered"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_reduce_min"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_reduce_max"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_reduce_and"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_reduce_or"),          1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_reduce_xor"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_shuffle"), 2, true,  Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_select"),  3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_ceil") , 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_floor"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_trunc"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_nearest"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_to_bits"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_lanes_reverse"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_rotate_left"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("simd_lanes_rotate_right"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("simd_x86__MM_SHUFFLE"), 4, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},


	{STR_LIT("syscall"), 1, true, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("x86_cpuid"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("x86_xgetbv"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},


	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_base_type"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_core_type"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_elem_type"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_convert_variants_to_pointers"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_merge"),                2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_boolean"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_integer"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_rune"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_float"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_complex"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_quaternion"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_string"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_typeid"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_any"),               1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_endian_platform"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_endian_little"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_endian_big"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_unsigned"),          1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_numeric"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_ordered"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_ordered_numeric"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_indexable"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_sliceable"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_comparable"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_simple_compare"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_dereferenceable"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_valid_map_key"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_valid_matrix_elements"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_named"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_pointer"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_multi_pointer"),      1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_array"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_enumerated_array"),  1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_slice"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_dynamic_array"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_map"),               1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_struct"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_union"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_enum"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_proc"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_bit_set"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_simd_vector"),       1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_matrix"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_specialized_polymorphic_record"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_unspecialized_polymorphic_record"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_has_nil"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_has_field"),            2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_field_type"),           2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_specialization_of"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_variant_of"),          2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_union_tag_type"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_union_tag_offset"),       1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_union_base_tag_value"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_union_variant_count"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_variant_type_of"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_variant_index_of"),       2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_bit_set_elem_type"),       1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_bit_set_underlying_type"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_struct_field_count"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_proc_parameter_count"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_proc_return_count"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_proc_parameter_type"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_proc_return_type"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_polymorphic_record_parameter_count"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_polymorphic_record_parameter_value"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_subtype_of"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_field_index_of"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_bit_set_backing_type"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_equal_proc"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_hasher_proc"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_map_info"),      1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_map_cell_info"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},


	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("__entry_point"), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("objc_send"),   3, true,  Expr_Expr, BuiltinProcPkg_intrinsics, false, true},

	{STR_LIT("objc_find_selector"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("objc_find_class"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("objc_register_selector"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},
	{STR_LIT("objc_register_class"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics, false, true},

	{STR_LIT("constant_utf16_cstring"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("wasm_memory_grow"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("wasm_memory_size"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("wasm_memory_atomic_wait32"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("wasm_memory_atomic_notify32"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("valgrind_client_request"), 7, false, Expr_Expr, BuiltinProcPkg_intrinsics},
};
