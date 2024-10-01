package odin_ast

import "base:intrinsics"
import "core:mem"
import "core:fmt"
import "core:reflect"
import "core:odin/tokenizer"
_ :: intrinsics

new_from_positions :: proc($T: typeid, pos, end: tokenizer.Pos) -> ^T {
	n, _ := mem.new(T)
	n.pos = pos
	n.end = end
	n.derived = n
	base: ^Node = n // dummy check
	_ = base // "Use" type to make -vet happy
	when intrinsics.type_has_field(T, "derived_expr") {
		n.derived_expr = n
	}
	when intrinsics.type_has_field(T, "derived_stmt") {
		n.derived_stmt = n
	}
	return n
}

new_from_pos_and_end_node :: proc($T: typeid, pos: tokenizer.Pos, end: ^Node) -> ^T {
	return new(T, pos, end != nil ? end.end : pos)
}

new :: proc {
	new_from_positions,
	new_from_pos_and_end_node,
}

clone :: proc{
	clone_node,
	clone_expr,
	clone_stmt,
	clone_decl,
	clone_array,
	clone_dynamic_array,
}

clone_array :: proc(array: $A/[]^$T) -> A {
	if len(array) == 0 {
		return nil
	}
	res := make(A, len(array))
	for elem, i in array {
		res[i] = (^T)(clone(elem))
	}
	return res
}

clone_dynamic_array :: proc(array: $A/[dynamic]^$T) -> A {
	if len(array) == 0 {
		return nil
	}
	res := make(A, len(array))
	for elem, i in array {
		res[i] = (^T)(clone(elem))
	}
	return res
}

clone_expr :: proc(node: ^Expr) -> ^Expr {
	return cast(^Expr)clone_node(node)
}
clone_stmt :: proc(node: ^Stmt) -> ^Stmt {
	return cast(^Stmt)clone_node(node)
}
clone_decl :: proc(node: ^Decl) -> ^Decl {
	return cast(^Decl)clone_node(node)
}
clone_node :: proc(node: ^Node) -> ^Node {
	if node == nil {
		return nil
	}

	size  := size_of(Node)
	align := align_of(Node)
	ti := reflect.union_variant_type_info(node.derived)
	if ti != nil {
		elem := ti.variant.(reflect.Type_Info_Pointer).elem
		size  = elem.size
		align = elem.align
	}

	#partial switch _ in node.derived {
	case ^Package, ^File:
		panic("Cannot clone this node type")
	}

	res := cast(^Node)(mem.alloc(size, align) or_else nil)
	if res == nil {
		// allocation failure
		return nil
	}
	src: rawptr = node
	if node.derived != nil {
		src = (^rawptr)(&node.derived)^
	}
	mem.copy(res, src, size)
	res_ptr_any: any
	res_ptr_any.data = &res
	res_ptr_any.id = ti.id

	reflect.set_union_value(res.derived, res_ptr_any)

	res_ptr := reflect.deref(res_ptr_any)

	if de := reflect.struct_field_value_by_name(res_ptr, "derived_expr", true); de != nil {
		reflect.set_union_value(de, res_ptr_any)
	}
	if ds := reflect.struct_field_value_by_name(res_ptr, "derived_stmt", true); ds != nil {
		reflect.set_union_value(ds, res_ptr_any)
	}

	if res.derived != nil {
		switch r in res.derived {
		case ^Package, ^File:
		case ^Bad_Expr:
		case ^Ident:
		case ^Implicit:
		case ^Undef:
		case ^Basic_Lit:
		case ^Basic_Directive:
		case ^Comment_Group:

		case ^Ellipsis:
			r.expr = clone(r.expr)
		case ^Proc_Lit:
			r.type = auto_cast clone(r.type)
			r.body = clone(r.body)
		case ^Comp_Lit:
			r.type  = clone(r.type)
			r.elems = clone(r.elems)

		case ^Tag_Expr:
			r.expr = clone(r.expr)
		case ^Unary_Expr:
			r.expr = clone(r.expr)
		case ^Binary_Expr:
			r.left  = clone(r.left)
			r.right = clone(r.right)
		case ^Paren_Expr:
			r.expr = clone(r.expr)
		case ^Selector_Expr:
			r.expr = clone(r.expr)
			r.field = auto_cast clone(r.field)
		case ^Implicit_Selector_Expr:
			r.field = auto_cast clone(r.field)
		case ^Selector_Call_Expr:
			r.expr = clone(r.expr)
			r.call = auto_cast clone(r.call)
		case ^Index_Expr:
			r.expr = clone(r.expr)
			r.index = clone(r.index)
		case ^Matrix_Index_Expr:
			r.expr         = clone(r.expr)
			r.row_index    = clone(r.row_index)
			r.column_index = clone(r.column_index)
		case ^Deref_Expr:
			r.expr = clone(r.expr)
		case ^Slice_Expr:
			r.expr = clone(r.expr)
			r.low  = clone(r.low)
			r.high = clone(r.high)
		case ^Call_Expr:
			r.expr = clone(r.expr)
			r.args = clone(r.args)
		case ^Field_Value:
			r.field = clone(r.field)
			r.value = clone(r.value)
		case ^Ternary_If_Expr:
			r.x    = clone(r.x)
			r.cond = clone(r.cond)
			r.y    = clone(r.y)
		case ^Ternary_When_Expr:
			r.x    = clone(r.x)
			r.cond = clone(r.cond)
			r.y    = clone(r.y)
		case ^Or_Else_Expr:
			r.x    = clone(r.x)
			r.y    = clone(r.y)
		case ^Or_Return_Expr:
			r.expr = clone(r.expr)
		case ^Or_Branch_Expr:
			r.expr  = clone(r.expr)
			r.label = clone(r.label)
		case ^Type_Assertion:
			r.expr = clone(r.expr)
			r.type = clone(r.type)
		case ^Type_Cast:
			r.type = clone(r.type)
			r.expr = clone(r.expr)
		case ^Auto_Cast:
			r.expr = clone(r.expr)
		case ^Inline_Asm_Expr:
			r.param_types        = clone(r.param_types)
			r.return_type        = clone(r.return_type)
			r.constraints_string = clone(r.constraints_string)
			r.asm_string         = clone(r.asm_string)

		case ^Bad_Stmt:
			// empty
		case ^Empty_Stmt:
			// empty
		case ^Expr_Stmt:
			r.expr = clone(r.expr)
		case ^Tag_Stmt:
			r.stmt = clone(r.stmt)

		case ^Assign_Stmt:
			r.lhs = clone(r.lhs)
			r.rhs = clone(r.rhs)
		case ^Block_Stmt:
			r.label = clone(r.label)
			r.stmts = clone(r.stmts)
		case ^If_Stmt:
			r.label     = clone(r.label)
			r.init      = clone(r.init)
			r.cond      = clone(r.cond)
			r.body      = clone(r.body)
			r.else_stmt = clone(r.else_stmt)
		case ^When_Stmt:
			r.cond      = clone(r.cond)
			r.body      = clone(r.body)
			r.else_stmt = clone(r.else_stmt)
		case ^Return_Stmt:
			r.results = clone(r.results)
		case ^Defer_Stmt:
			r.stmt = clone(r.stmt)
		case ^For_Stmt:
			r.label = clone(r.label)
			r.init = clone(r.init)
			r.cond = clone(r.cond)
			r.post = clone(r.post)
			r.body = clone(r.body)
		case ^Range_Stmt:
			r.label = clone(r.label)
			r.vals = clone(r.vals)
			r.expr = clone(r.expr)
			r.body = clone(r.body)
		case ^Inline_Range_Stmt:
			r.label = clone(r.label)
			r.val0 = clone(r.val0)
			r.val1 = clone(r.val1)
			r.expr = clone(r.expr)
			r.body = clone(r.body)
		case ^Case_Clause:
			r.list = clone(r.list)
			r.body = clone(r.body)
		case ^Switch_Stmt:
			r.label = clone(r.label)
			r.init = clone(r.init)
			r.cond = clone(r.cond)
			r.body = clone(r.body)
		case ^Type_Switch_Stmt:
			r.label = clone(r.label)
			r.tag  = clone(r.tag)
			r.expr = clone(r.expr)
			r.body = clone(r.body)
		case ^Branch_Stmt:
			r.label = auto_cast clone(r.label)
		case ^Using_Stmt:
			r.list = clone(r.list)
		case ^Bad_Decl:
		case ^Value_Decl:
			r.attributes = clone(r.attributes)
			r.names      = clone(r.names)
			r.type       = clone(r.type)
			r.values     = clone(r.values)
		case ^Package_Decl:
		case ^Import_Decl:
		case ^Foreign_Block_Decl:
			r.attributes      = clone(r.attributes)
			r.foreign_library = clone(r.foreign_library)
			r.body            = clone(r.body)
		case ^Foreign_Import_Decl:
			r.attributes = clone_dynamic_array(r.attributes)
			r.name = auto_cast clone(r.name)
			r.fullpaths  = clone_array(r.fullpaths)
		case ^Proc_Group:
			r.args = clone(r.args)
		case ^Attribute:
			r.elems = clone(r.elems)
		case ^Field:
			r.names         = clone(r.names)
			r.type          = clone(r.type)
			r.default_value = clone(r.default_value)
		case ^Field_List:
			r.list = clone(r.list)
		case ^Typeid_Type:
			r.specialization = clone(r.specialization)
		case ^Helper_Type:
			r.type = clone(r.type)
		case ^Distinct_Type:
			r.type = clone(r.type)
		case ^Poly_Type:
			r.type = auto_cast clone(r.type)
			r.specialization = clone(r.specialization)
		case ^Proc_Type:
			r.params  = auto_cast clone(r.params)
			r.results = auto_cast clone(r.results)
		case ^Pointer_Type:
			r.elem = clone(r.elem)
			r.tag  = clone(r.tag)
		case ^Multi_Pointer_Type:
			r.elem = clone(r.elem)
		case ^Array_Type:
			r.len  = clone(r.len)
			r.elem = clone(r.elem)
		case ^Dynamic_Array_Type:
			r.elem = clone(r.elem)
		case ^Struct_Type:
			r.poly_params = auto_cast clone(r.poly_params)
			r.align = clone(r.align)
			r.min_field_align = clone(r.min_field_align)
			r.max_field_align = clone(r.max_field_align)
			r.fields = auto_cast clone(r.fields)
		case ^Union_Type:
			r.poly_params = auto_cast clone(r.poly_params)
			r.align = clone(r.align)
			r.variants = clone(r.variants)
		case ^Enum_Type:
			r.base_type = clone(r.base_type)
			r.fields = clone(r.fields)
		case ^Bit_Set_Type:
			r.elem = clone(r.elem)
			r.underlying = clone(r.underlying)
		case ^Map_Type:
			r.key = clone(r.key)
			r.value = clone(r.value)
		case ^Matrix_Type:
			r.row_count = clone(r.row_count)
			r.column_count = clone(r.column_count)
			r.elem = clone(r.elem)
		case ^Relative_Type:
			r.tag = clone(r.tag)
			r.type = clone(r.type)
		case ^Bit_Field_Type:
			r.backing_type = clone(r.backing_type)
			r.fields       = auto_cast clone(r.fields)
		case ^Bit_Field_Field:
			r.name     = clone(r.name)
			r.type     = clone(r.type)
			r.bit_size = clone(r.bit_size)
		case:
			fmt.panicf("Unhandled node kind: %v", r)
		}
	}

	return res
}
