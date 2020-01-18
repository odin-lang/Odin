// checker_builtin_procs.hpp

enum BuiltinProcId {
	BuiltinProc_Invalid,

	BuiltinProc_len,
	BuiltinProc_cap,

	BuiltinProc_size_of,
	BuiltinProc_align_of,
	BuiltinProc_offset_of,
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

	BuiltinProc_expand_to_tuple,

	BuiltinProc_min,
	BuiltinProc_max,
	BuiltinProc_abs,
	BuiltinProc_clamp,

	BuiltinProc_DIRECTIVE, // NOTE(bill): This is used for specialized hash-prefixed procedures

	// "Intrinsics"
	BuiltinProc_simd_vector,
	BuiltinProc_soa_struct,

	BuiltinProc_atomic_fence,
	BuiltinProc_atomic_fence_acq,
	BuiltinProc_atomic_fence_rel,
	BuiltinProc_atomic_fence_acqrel,

	BuiltinProc_atomic_store,
	BuiltinProc_atomic_store_rel,
	BuiltinProc_atomic_store_relaxed,
	BuiltinProc_atomic_store_unordered,

	BuiltinProc_atomic_load,
	BuiltinProc_atomic_load_acq,
	BuiltinProc_atomic_load_relaxed,
	BuiltinProc_atomic_load_unordered,

	BuiltinProc_atomic_add,
	BuiltinProc_atomic_add_acq,
	BuiltinProc_atomic_add_rel,
	BuiltinProc_atomic_add_acqrel,
	BuiltinProc_atomic_add_relaxed,
	BuiltinProc_atomic_sub,
	BuiltinProc_atomic_sub_acq,
	BuiltinProc_atomic_sub_rel,
	BuiltinProc_atomic_sub_acqrel,
	BuiltinProc_atomic_sub_relaxed,
	BuiltinProc_atomic_and,
	BuiltinProc_atomic_and_acq,
	BuiltinProc_atomic_and_rel,
	BuiltinProc_atomic_and_acqrel,
	BuiltinProc_atomic_and_relaxed,
	BuiltinProc_atomic_nand,
	BuiltinProc_atomic_nand_acq,
	BuiltinProc_atomic_nand_rel,
	BuiltinProc_atomic_nand_acqrel,
	BuiltinProc_atomic_nand_relaxed,
	BuiltinProc_atomic_or,
	BuiltinProc_atomic_or_acq,
	BuiltinProc_atomic_or_rel,
	BuiltinProc_atomic_or_acqrel,
	BuiltinProc_atomic_or_relaxed,
	BuiltinProc_atomic_xor,
	BuiltinProc_atomic_xor_acq,
	BuiltinProc_atomic_xor_rel,
	BuiltinProc_atomic_xor_acqrel,
	BuiltinProc_atomic_xor_relaxed,

	BuiltinProc_atomic_xchg,
	BuiltinProc_atomic_xchg_acq,
	BuiltinProc_atomic_xchg_rel,
	BuiltinProc_atomic_xchg_acqrel,
	BuiltinProc_atomic_xchg_relaxed,

	BuiltinProc_atomic_cxchg,
	BuiltinProc_atomic_cxchg_acq,
	BuiltinProc_atomic_cxchg_rel,
	BuiltinProc_atomic_cxchg_acqrel,
	BuiltinProc_atomic_cxchg_relaxed,
	BuiltinProc_atomic_cxchg_failrelaxed,
	BuiltinProc_atomic_cxchg_failacq,
	BuiltinProc_atomic_cxchg_acq_failrelaxed,
	BuiltinProc_atomic_cxchg_acqrel_failrelaxed,

	BuiltinProc_atomic_cxchgweak,
	BuiltinProc_atomic_cxchgweak_acq,
	BuiltinProc_atomic_cxchgweak_rel,
	BuiltinProc_atomic_cxchgweak_acqrel,
	BuiltinProc_atomic_cxchgweak_relaxed,
	BuiltinProc_atomic_cxchgweak_failrelaxed,
	BuiltinProc_atomic_cxchgweak_failacq,
	BuiltinProc_atomic_cxchgweak_acq_failrelaxed,
	BuiltinProc_atomic_cxchgweak_acqrel_failrelaxed,


	// Constant type tests

BuiltinProc__type_begin,

	BuiltinProc_type_base_type,
	BuiltinProc_type_core_type,
	BuiltinProc_type_elem_type,

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

	BuiltinProc_type_is_endian_little,
	BuiltinProc_type_is_endian_big,
	BuiltinProc_type_is_unsigned,
	BuiltinProc_type_is_numeric,
	BuiltinProc_type_is_ordered,
	BuiltinProc_type_is_ordered_numeric,
	BuiltinProc_type_is_indexable,
	BuiltinProc_type_is_sliceable,
	BuiltinProc_type_is_simple_compare, // easily compared using memcmp
	BuiltinProc_type_is_dereferenceable,
	BuiltinProc_type_is_valid_map_key,

	BuiltinProc_type_is_named,
	BuiltinProc_type_is_pointer,
	BuiltinProc_type_is_opaque,
	BuiltinProc_type_is_array,
	BuiltinProc_type_is_enumerated_array,
	BuiltinProc_type_is_slice,
	BuiltinProc_type_is_dynamic_array,
	BuiltinProc_type_is_map,
	BuiltinProc_type_is_struct,
	BuiltinProc_type_is_union,
	BuiltinProc_type_is_enum,
	BuiltinProc_type_is_proc,
	BuiltinProc_type_is_bit_field,
	BuiltinProc_type_is_bit_field_value,
	BuiltinProc_type_is_bit_set,
	BuiltinProc_type_is_simd_vector,

	BuiltinProc_type_is_specialized_polymorphic_record,
	BuiltinProc_type_is_unspecialized_polymorphic_record,

	BuiltinProc_type_has_nil,

BuiltinProc__type_simple_boolean_end,

	BuiltinProc_type_is_specialization_of,

	BuiltinProc_type_proc_parameter_count,
	BuiltinProc_type_proc_return_count,

	BuiltinProc_type_polymorphic_record_parameter_count,
	BuiltinProc_type_polymorphic_record_parameter_value,

BuiltinProc__type_end,


	BuiltinProc_COUNT,
};
gb_global BuiltinProc builtin_procs[BuiltinProc_COUNT] = {
	{STR_LIT(""),                 0, false, Expr_Stmt, BuiltinProcPkg_builtin},

	{STR_LIT("len"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("cap"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("size_of"),          1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("align_of"),         1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("offset_of"),        2, false, Expr_Expr, BuiltinProcPkg_builtin},
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

	{STR_LIT("expand_to_tuple"),  1, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT("min"),              1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("max"),              1, true,  Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("abs"),              1, false, Expr_Expr, BuiltinProcPkg_builtin},
	{STR_LIT("clamp"),            3, false, Expr_Expr, BuiltinProcPkg_builtin},

	{STR_LIT(""),                 0, true,  Expr_Expr, BuiltinProcPkg_builtin}, // DIRECTIVE


	// "Intrinsics"
	{STR_LIT("simd_vector"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics}, // Type
	{STR_LIT("soa_struct"),  2, false, Expr_Expr, BuiltinProcPkg_intrinsics}, // Type

	{STR_LIT("atomic_fence"),        0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_fence_acq"),    0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_fence_rel"),    0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_fence_acqrel"), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_store"),           2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_rel"),       2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_relaxed"),   2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_store_unordered"), 2, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_load"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load_acq"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load_relaxed"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_load_unordered"),  1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_add"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_add_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_sub_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_and_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand"),            2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_acq"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_rel"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_acqrel"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_nand_relaxed"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or"),              2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_acq"),          2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_rel"),          2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_acqrel"),       2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_or_relaxed"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor"),             2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_acq"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_rel"),         2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_acqrel"),      2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xor_relaxed"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_xchg"),            2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_acq"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_rel"),        2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_acqrel"),     2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_xchg_relaxed"),    2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_cxchg"),                    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acq"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_rel"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acqrel"),             3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_relaxed"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_failrelaxed"),        3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_failacq"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acq_failrelaxed"),    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchg_acqrel_failrelaxed"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("atomic_cxchgweak"),                    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acq"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_rel"),                3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acqrel"),             3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_relaxed"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_failrelaxed"),        3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_failacq"),            3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acq_failrelaxed"),    3, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("atomic_cxchgweak_acqrel_failrelaxed"), 3, false, Expr_Expr, BuiltinProcPkg_intrinsics},


	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_base_type"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_core_type"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_elem_type"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

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

	{STR_LIT("type_is_endian_little"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_endian_big"),        1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_unsigned"),          1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_numeric"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_ordered"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_ordered_numeric"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_indexable"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_sliceable"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_simple_compare"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_dereferenceable"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_valid_map_key"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_named"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_pointer"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_opaque"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_array"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_enumerated_array"),  1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_slice"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_dynamic_array"),     1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_map"),               1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_struct"),            1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_union"),             1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_enum"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_proc"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_bit_field"),         1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_bit_field_value"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_bit_set"),           1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_simd_vector"),       1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_specialized_polymorphic_record"),   1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_is_unspecialized_polymorphic_record"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_has_nil"),              1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_is_specialization_of"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_proc_parameter_count"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_proc_return_count"),    1, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT("type_polymorphic_record_parameter_count"), 1, false, Expr_Expr, BuiltinProcPkg_intrinsics},
	{STR_LIT("type_polymorphic_record_parameter_value"), 2, false, Expr_Expr, BuiltinProcPkg_intrinsics},

	{STR_LIT(""), 0, false, Expr_Stmt, BuiltinProcPkg_intrinsics},
};
