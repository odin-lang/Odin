package odin_ast

import "core:fmt"

// A Visitor's visit procedure is invoked for each node encountered by walk
// If the result visitor is not nil, walk visits each of the children of node with the new visitor,
// followed by a call of v.visit(v, nil)
Visitor :: struct {
	visit: proc(visitor: ^Visitor, node: ^Node) -> ^Visitor,
	data:  rawptr,
}


// inspect traverses an AST in depth-first order
// It starts by calling f(node), and node must be non-nil
// If f returns true, inspect invokes f recursively for each of the non-nil children of node,
// followed by a call of f(nil)
inspect :: proc(node: ^Node, f: proc(^Node) -> bool) {
	v := &Visitor{
		visit = proc(v: ^Visitor, node: ^Node) -> ^Visitor {
			f := (proc(^Node) -> bool)(v.data)
			if f(node) {
				return v
			}
			return nil
		},
		data = rawptr(f),
	}
	walk(v, node)
}



// walk traverses an AST in depth-first order: It starts by calling v.visit(v, node), and node must not be nil
// If the visitor returned by v.visit(v, node) is not nil, walk is invoked recursively with the new visitor for
// each of the non-nil children of node, followed by a call of the new visit procedure
walk :: proc(v: ^Visitor, node: ^Node) {
	walk_expr_list :: proc(v: ^Visitor, list: []^Expr) {
		for x in list {
			walk(v, x)
		}
	}

	walk_stmt_list :: proc(v: ^Visitor, list: []^Stmt) {
		for x in list {
			walk(v, x)
		}
	}
	walk_attribute_list :: proc(v: ^Visitor, list: []^Attribute) {
		for x in list {
			walk(v, x)
		}
	}

	v := v
	if v == nil || node == nil {
		return
	}

	if v = v->visit(node); v == nil {
		return
	}

	switch n in node.derived {
	case ^File:
		if n.docs != nil {
			walk(v, n.docs)
		}
		walk_stmt_list(v, n.decls[:])
	case ^Package:
		for _, f in n.files {
			walk(v, f)
		}

	case ^Comment_Group:
		// empty
	case ^Bad_Expr:
	case ^Ident:
	case ^Implicit:
	case ^Undef:
	case ^Basic_Lit:
	case ^Basic_Directive:
	case ^Ellipsis:
		if n.expr != nil {
			walk(v, n.expr)
		}
	case ^Proc_Lit:
		walk(v, n.type)
		walk(v, n.body)
		walk_expr_list(v, n.where_clauses)
	case ^Comp_Lit:
		if n.type != nil {
			walk(v, n.type)
		}
		walk_expr_list(v, n.elems)
	case ^Tag_Expr:
		walk(v, n.expr)
	case ^Unary_Expr:
		walk(v, n.expr)
	case ^Binary_Expr:
		walk(v, n.left)
		walk(v, n.right)
	case ^Paren_Expr:
		walk(v, n.expr)
	case ^Selector_Expr:
		walk(v, n.expr)
		walk(v, n.field)
	case ^Implicit_Selector_Expr:
		walk(v, n.field)
	case ^Selector_Call_Expr:
		walk(v, n.expr)
		walk(v, n.call)
	case ^Index_Expr:
		walk(v, n.expr)
		walk(v, n.index)
	case ^Matrix_Index_Expr:
		walk(v, n.expr)
		walk(v, n.row_index)
		walk(v, n.column_index)
	case ^Deref_Expr:
		walk(v, n.expr)
	case ^Slice_Expr:
		walk(v, n.expr)
		if n.low != nil {
			walk(v, n.low)
		}
		if n.high != nil {
			walk(v, n.high)
		}
	case ^Call_Expr:
		walk(v, n.expr)
		walk_expr_list(v, n.args)
	case ^Field_Value:
		walk(v, n.field)
		walk(v, n.value)
	case ^Ternary_If_Expr:
		walk(v, n.x)
		walk(v, n.cond)
		walk(v, n.y)
	case ^Ternary_When_Expr:
		walk(v, n.x)
		walk(v, n.cond)
		walk(v, n.y)
	case ^Or_Else_Expr:
		walk(v, n.x)
		walk(v, n.y)
	case ^Or_Return_Expr:
		walk(v, n.expr)
	case ^Or_Branch_Expr:
		walk(v, n.expr)
		if n.label != nil {
			walk(v, n.label)
		}
	case ^Type_Assertion:
		walk(v, n.expr)
		if n.type != nil {
			walk(v, n.type)
		}
	case ^Type_Cast:
		walk(v, n.type)
		walk(v, n.expr)
	case ^Auto_Cast:
		walk(v, n.expr)
	case ^Inline_Asm_Expr:
		walk_expr_list(v, n.param_types)
		walk(v, n.return_type)
		walk(v, n.constraints_string)
		walk(v, n.asm_string)


	case ^Bad_Stmt:
	case ^Empty_Stmt:
	case ^Expr_Stmt:
		walk(v, n.expr)
	case ^Tag_Stmt:
		walk(v, n.stmt)
	case ^Assign_Stmt:
		walk_expr_list(v, n.lhs)
		walk_expr_list(v, n.rhs)
	case ^Block_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		walk_stmt_list(v, n.stmts)
	case ^If_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		if n.init != nil {
			walk(v, n.init)
		}
		walk(v, n.cond)
		walk(v, n.body)
		if n.else_stmt != nil {
			walk(v, n.else_stmt)
		}
	case ^When_Stmt:
		walk(v, n.cond)
		walk(v, n.body)
		if n.else_stmt != nil {
			walk(v, n.else_stmt)
		}
	case ^Return_Stmt:
		walk_expr_list(v, n.results)
	case ^Defer_Stmt:
		walk(v, n.stmt)
	case ^For_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		if n.init != nil {
			walk(v, n.init)
		}
		if n.cond != nil {
			walk(v, n.cond)
		}
		if n.post != nil {
			walk(v, n.post)
		}
		walk(v, n.body)
	case ^Range_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		for val in n.vals {
			if val != nil {
				walk(v, val)
			}
		}
		walk(v, n.expr)
		walk(v, n.body)
	case ^Inline_Range_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		if n.val0 != nil {
			walk(v, n.val0)
		}
		if n.val1 != nil {
			walk(v, n.val1)
		}
		walk(v, n.expr)
		walk(v, n.body)
	case ^Case_Clause:
		walk_expr_list(v, n.list)
		walk_stmt_list(v, n.body)
	case ^Switch_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		if n.init != nil {
			walk(v, n.init)
		}
		if n.cond != nil {
			walk(v, n.cond)
		}
		walk(v, n.body)
	case ^Type_Switch_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
		if n.tag != nil {
			walk(v, n.tag)
		}
		if n.expr != nil {
			walk(v, n.expr)
		}
		walk(v, n.body)
	case ^Branch_Stmt:
		if n.label != nil {
			walk(v, n.label)
		}
	case ^Using_Stmt:
		walk_expr_list(v, n.list)


	case ^Bad_Decl:
	case ^Value_Decl:
		if n.docs != nil {
			walk(v, n.docs)
		}
		walk_attribute_list(v, n.attributes[:])
		walk_expr_list(v, n.names)
		if n.type != nil {
			walk(v, n.type)
		}
		walk_expr_list(v, n.values)
		if n.comment != nil {
			walk(v, n.comment)
		}
	case ^Package_Decl:
		if n.docs != nil {
			walk(v, n.docs)
		}
		if n.comment != nil {
			walk(v, n.comment)
		}
	case ^Import_Decl:
		if n.docs != nil {
			walk(v, n.docs)
		}
		if n.comment != nil {
			walk(v, n.comment)
		}
	case ^Foreign_Block_Decl:
		if n.docs != nil {
			walk(v, n.docs)
		}
		walk_attribute_list(v, n.attributes[:])
		if n.foreign_library != nil {
			walk(v, n.foreign_library)
		}
		walk(v, n.body)
	case ^Foreign_Import_Decl:
		if n.docs != nil {
			walk(v, n.docs)
		}
		walk_attribute_list(v, n.attributes[:])
		walk(v, n.name)
		if n.comment != nil {
			walk(v, n.comment)
		}
		walk_expr_list(v, n.fullpaths)

	case ^Proc_Group:
		walk_expr_list(v, n.args)
	case ^Attribute:
		walk_expr_list(v, n.elems)
	case ^Field:
		if n.docs != nil {
			walk(v, n.docs)
		}
		walk_expr_list(v, n.names)
		if n.type != nil {
			walk(v, n.type)
		}
		if n.default_value != nil {
			walk(v, n.default_value)
		}
		if n.comment != nil {
			walk(v, n.comment)
		}
	case ^Field_List:
		for x in n.list {
			walk(v, x)
		}
	case ^Typeid_Type:
		if n.specialization != nil {
			walk(v, n.specialization)
		}
	case ^Helper_Type:
		walk(v, n.type)
	case ^Distinct_Type:
		walk(v, n.type)
	case ^Poly_Type:
		walk(v, n.type)
		if n.specialization != nil {
			walk(v, n.specialization)
		}
	case ^Proc_Type:
		walk(v, n.params)
		walk(v, n.results)
	case ^Pointer_Type:
		walk(v, n.elem)
	case ^Multi_Pointer_Type:
		walk(v, n.elem)
	case ^Array_Type:
		if n.tag != nil {
			walk(v, n.tag)
		}
		if n.len != nil {
			walk(v, n.len)
		}
		walk(v, n.elem)
	case ^Dynamic_Array_Type:
		if n.tag != nil {
			walk(v, n.tag)
		}
		walk(v, n.elem)
	case ^Struct_Type:
		if n.poly_params != nil {
			walk(v, n.poly_params)
		}
		if n.align != nil {
			walk(v, n.align)
		}
		walk_expr_list(v, n.where_clauses)
		walk(v, n.fields)
	case ^Union_Type:
		if n.poly_params != nil {
			walk(v, n.poly_params)
		}
		if n.align != nil {
			walk(v, n.align)
		}
		walk_expr_list(v, n.where_clauses)
		walk_expr_list(v, n.variants)
	case ^Enum_Type:
		if n.base_type != nil {
			walk(v, n.base_type)
		}
		walk_expr_list(v, n.fields)
	case ^Bit_Set_Type:
		walk(v, n.elem)
		if n.underlying != nil {
			walk(v, n.underlying)
		}
	case ^Map_Type:
		walk(v, n.key)
		walk(v, n.value)
	case ^Relative_Type:
		walk(v, n.tag)
		walk(v, n.type)
	case ^Matrix_Type:
		walk(v, n.row_count)
		walk(v, n.column_count)
		walk(v, n.elem)
	case ^Bit_Field_Type:
		walk(v, n.backing_type)
		for f in n.fields {
			walk(v, f)
		}
	case ^Bit_Field_Field:
		walk(v, n.name)
		walk(v, n.type)
		walk(v, n.bit_size)
	case:
		fmt.panicf("ast.walk: unexpected node type %T", n)
	}

	v->visit(nil)
}

