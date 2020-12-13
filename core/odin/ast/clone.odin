package odin_ast

import "core:mem"
import "core:fmt"
import "core:odin/tokenizer"

new :: proc($T: typeid, pos, end: tokenizer.Pos) -> ^T {
	n := mem.new(T);
	n.pos = pos;
	n.end = end;
	n.derived = n^;
	base: ^Node = n; // dummy check
	_ = base; // "Use" type to make -vet happy
	return n;
}

clone :: proc{
	clone_node,
	clone_expr,
	clone_stmt,
	clone_decl,
	clone_array,
	clone_dynamic_array,
};

clone_array :: proc(array: $A/[]^$T) -> A {
	if len(array) == 0 {
		return nil;
	}
	res := make(A, len(array));
	for elem, i in array {
		res[i] = auto_cast clone(elem);
	}
	return res;
}

clone_dynamic_array :: proc(array: $A/[dynamic]^$T) -> A {
	if len(array) == 0 {
		return nil;
	}
	res := make(A, len(array));
	for elem, i in array {
		res[i] = auto_cast clone(elem);
	}
	return res;
}

clone_expr :: proc(node: ^Expr) -> ^Expr {
	return cast(^Expr)clone_node(node);
}
clone_stmt :: proc(node: ^Stmt) -> ^Stmt {
	return cast(^Stmt)clone_node(node);
}
clone_decl :: proc(node: ^Decl) -> ^Decl {
	return cast(^Decl)clone_node(node);
}
clone_node :: proc(node: ^Node) -> ^Node {
	if node == nil {
		return nil;
	}

	size := size_of(Node);
	align := align_of(Node);
	ti := type_info_of(node.derived.id);
	if ti != nil {
		size = ti.size;
		align = ti.align;
	}

	switch in node.derived {
	case Package, File:
		panic("Cannot clone this node type");
	}

	res := cast(^Node)mem.alloc(size, align);
	src: rawptr = node;
	if node.derived != nil {
		src = node.derived.data;
	}
	mem.copy(res, src, size);
	res.derived.data = rawptr(res);
	res.derived.id = node.derived.id;

	switch r in &res.derived {
	case Bad_Expr:
	case Ident:
	case Implicit:
	case Undef:
	case Basic_Lit:

	case Ellipsis:
		r.expr = clone(r.expr);
	case Proc_Lit:
		r.type = auto_cast clone(r.type);
		r.body = clone(r.body);
	case Comp_Lit:
		r.type  = clone(r.type);
		r.elems = clone(r.elems);

	case Tag_Expr:
		r.expr = clone(r.expr);
	case Unary_Expr:
		r.expr = clone(r.expr);
	case Binary_Expr:
		r.left  = clone(r.left);
		r.right = clone(r.right);
	case Paren_Expr:
		r.expr = clone(r.expr);
	case Selector_Expr:
		r.expr = clone(r.expr);
		r.field = auto_cast clone(r.field);
	case Implicit_Selector_Expr:
		r.field = auto_cast clone(r.field);
	case Selector_Call_Expr:
		r.expr = clone(r.expr);
		r.call = auto_cast clone(r.call);
	case Index_Expr:
		r.expr = clone(r.expr);
		r.index = clone(r.index);
	case Deref_Expr:
		r.expr = clone(r.expr);
	case Slice_Expr:
		r.expr = clone(r.expr);
		r.low  = clone(r.low);
		r.high = clone(r.high);
	case Call_Expr:
		r.expr = clone(r.expr);
		r.args = clone(r.args);
	case Field_Value:
		r.field = clone(r.field);
		r.value = clone(r.value);
	case Ternary_Expr:
		r.cond = clone(r.cond);
		r.x    = clone(r.x);
		r.y    = clone(r.y);
	case Ternary_If_Expr:
		r.x    = clone(r.x);
		r.cond = clone(r.cond);
		r.y    = clone(r.y);
	case Ternary_When_Expr:
		r.x    = clone(r.x);
		r.cond = clone(r.cond);
		r.y    = clone(r.y);
	case Type_Assertion:
		r.expr = clone(r.expr);
		r.type = clone(r.type);
	case Type_Cast:
		r.type = clone(r.type);
		r.expr = clone(r.expr);
	case Auto_Cast:
		r.expr = clone(r.expr);
	case Inline_Asm_Expr:
		r.param_types        = clone(r.param_types);
		r.return_type        = clone(r.return_type);
		r.constraints_string = clone(r.constraints_string);
		r.asm_string         = clone(r.asm_string);

	case Bad_Stmt:
		// empty
	case Empty_Stmt:
		// empty
	case Expr_Stmt:
		r.expr = clone(r.expr);
	case Tag_Stmt:
		r.stmt = clone(r.stmt);

	case Assign_Stmt:
		r.lhs = clone(r.lhs);
		r.rhs = clone(r.rhs);
	case Block_Stmt:
		r.label = auto_cast clone(r.label);
		r.stmts = clone(r.stmts);
	case If_Stmt:
		r.label     = auto_cast clone(r.label);
		r.init      = clone(r.init);
		r.cond      = clone(r.cond);
		r.body      = clone(r.body);
		r.else_stmt = clone(r.else_stmt);
	case When_Stmt:
		r.cond      = clone(r.cond);
		r.body      = clone(r.body);
		r.else_stmt = clone(r.else_stmt);
	case Return_Stmt:
		r.results = clone(r.results);
	case Defer_Stmt:
		r.stmt = clone(r.stmt);
	case For_Stmt:
		r.label = auto_cast clone(r.label);
		r.init = clone(r.init);
		r.cond = clone(r.cond);
		r.post = clone(r.post);
		r.body = clone(r.body);
	case Range_Stmt:
		r.label = auto_cast clone(r.label);
		r.val0 = clone(r.val0);
		r.val1 = clone(r.val1);
		r.expr = clone(r.expr);
		r.body = clone(r.body);
	case Case_Clause:
		r.list = clone(r.list);
		r.body = clone(r.body);
	case Switch_Stmt:
		r.label = auto_cast clone(r.label);
		r.init = clone(r.init);
		r.cond = clone(r.cond);
		r.body = clone(r.body);
	case Type_Switch_Stmt:
		r.label = auto_cast clone(r.label);
		r.tag  = clone(r.tag);
		r.expr = clone(r.expr);
		r.body = clone(r.body);
	case Branch_Stmt:
		r.label = auto_cast clone(r.label);
	case Using_Stmt:
		r.list = clone(r.list);
	case Bad_Decl:
	case Value_Decl:
		r.attributes = clone(r.attributes);
		r.names      = clone(r.names);
		r.type       = clone(r.type);
		r.values     = clone(r.values);
	case Package_Decl:
	case Import_Decl:
	case Foreign_Block_Decl:
		r.attributes      = clone(r.attributes);
		r.foreign_library = clone(r.foreign_library);
		r.body            = clone(r.body);
	case Foreign_Import_Decl:
		r.name = auto_cast clone(r.name);
	case Proc_Group:
		r.args = clone(r.args);
	case Attribute:
		r.elems = clone(r.elems);
	case Field:
		r.names         = clone(r.names);
		r.type          = clone(r.type);
		r.default_value = clone(r.default_value);
	case Field_List:
		r.list = clone(r.list);
	case Typeid_Type:
		r.specialization = clone(r.specialization);
	case Helper_Type:
		r.type = clone(r.type);
	case Distinct_Type:
		r.type = clone(r.type);
	case Opaque_Type:
		r.type = clone(r.type);
	case Poly_Type:
		r.type = auto_cast clone(r.type);
		r.specialization = clone(r.specialization);
	case Proc_Type:
		r.params  = auto_cast clone(r.params);
		r.results = auto_cast clone(r.results);
	case Pointer_Type:
		r.elem = clone(r.elem);
	case Array_Type:
		r.len  = clone(r.len);
		r.elem = clone(r.elem);
	case Dynamic_Array_Type:
		r.elem = clone(r.elem);
	case Struct_Type:
		r.poly_params = auto_cast clone(r.poly_params);
		r.align = clone(r.align);
		r.fields = auto_cast clone(r.fields);
	case Union_Type:
		r.poly_params = auto_cast clone(r.poly_params);
		r.align = clone(r.align);
		r.variants = clone(r.variants);
	case Enum_Type:
		r.base_type = clone(r.base_type);
		r.fields = clone(r.fields);
	case Bit_Field_Type:
		r.fields = clone(r.fields);
	case Bit_Set_Type:
		r.elem = clone(r.elem);
		r.underlying = clone(r.underlying);
	case Map_Type:
		r.key = clone(r.key);
		r.value = clone(r.value);

	case:
		fmt.panicf("Unhandled node kind: %T", r);
	}

	return res;
}
