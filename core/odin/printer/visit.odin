package odin_printer

import "core:odin/ast"
import "core:odin/tokenizer"
import "core:strings"
import "core:runtime"
import "core:fmt"
import "core:unicode/utf8"
import "core:mem"

@(private)
push_format_token :: proc(p: ^Printer, line: int, kind: tokenizer.Token_Kind, text: string, spaces_before: int) {
 
    if len(p.lines) <= line {
        return;
    }
    
    p.lines[line].used = true;
    
    format_token := Format_Token {
        spaces_before = spaces_before,
        kind = kind,
        text = text,
    };

    append(&p.lines[line].format_tokens, format_token); 
}

set_source_position :: proc(p: ^Printer, pos: tokenizer.Pos) {
	p.source_position = pos;
}

/*


print_expr :: proc(p: ^Printer, expr: ^ast.Expr) {

	using ast;

	if expr == nil {
		return;
	}

	set_source_position(p, expr.pos);

	switch v in expr.derived {
	case Inline_Asm_Expr:
		//TEMP
		//this is probably not fully done, but need more examples
		/*
			Inline_Asm_Expr :: struct {
			using node: Expr,
			tok:                tokenizer.Token,
			param_types:        []^Expr,
			return_type:        ^Expr,
			has_side_effects:   bool,
			is_align_stack:     bool,
			dialect:            Inline_Asm_Dialect,
			open:               tokenizer.Pos,
			constraints_string: ^Expr,
			asm_string:         ^Expr,
			close:              tokenizer.Pos,
			}
		*/

		/*
			cpuid :: proc(ax, cx: u32) -> (eax, ebc, ecx, edx: u32) {
			return expand_to_tuple(asm(u32, u32) -> struct{eax, ebc, ecx, edx: u32} {
			"cpuid",
			"={ax},={bx},={cx},={dx},{ax},{cx}",
			}(ax, cx));
			}
		*/

		print(p, v.tok, space, lparen);
		print_exprs(p, v.param_types, ", ");
		print(p, rparen, space);

		print(p, "->", space);

		print_expr(p, v.return_type);

		print(p, space);

		print(p, lbrace);
		print_expr(p, v.asm_string);
		print(p, ", ");
		print_expr(p, v.constraints_string);
		print(p, rbrace);

	case Undef:
		print(p, "---");
	case Auto_Cast:
		print(p, v.op, space);
		print_expr(p, v.expr);
	case Ternary_Expr:
		print_expr(p, v.cond);
		print(p, space, v.op1, space);
		print_expr(p, v.x);
		print(p, space, v.op2, space);
		print_expr(p, v.y);
	case Ternary_If_Expr:
		print_expr(p, v.x);
		print(p, space, v.op1, space);
		print_expr(p, v.cond);
		print(p, space, v.op2, space);
		print_expr(p, v.y);
	case Ternary_When_Expr:
		print_expr(p, v.x);
		print(p, space, v.op1, space);
		print_expr(p, v.cond);
		print(p, space, v.op2, space);
		print_expr(p, v.y);
	case Selector_Call_Expr:
		print_expr(p, v.call.expr);
		print(p, lparen);
		print_exprs(p, v.call.args, ", ");
		print(p, rparen);
	case Ellipsis:
		print(p, "..");
		print_expr(p, v.expr);
	case Relative_Type:
		print_expr(p, v.tag);
		print(p, space);
		print_expr(p, v.type);
	case Slice_Expr:
		print_expr(p, v.expr);
		print(p, lbracket);
		print_expr(p, v.low);
		print(p, v.interval);
		print_expr(p, v.high);
		print(p, rbracket);
	case Ident:
		print(p, v);
	case Deref_Expr:
		print_expr(p, v.expr);
		print(p, v.op);
	case Type_Cast:
		print(p, v.tok, lparen);
		print_expr(p, v.type);
		print(p, rparen);
		print_expr(p, v.expr);
	case Basic_Directive:
		print(p, v.tok, v.name);
	case Distinct_Type:
		print(p, "distinct", space);
		print_expr(p, v.type);
	case Dynamic_Array_Type:
		print_expr(p, v.tag);
		print(p, lbracket, "dynamic", rbracket);
		print_expr(p, v.elem);
	case Bit_Set_Type:
		print(p, "bit_set", lbracket);
		print_expr(p, v.elem);

		if v.underlying != nil {
			print(p, semicolon, space);
			print_expr(p, v.underlying);
		}

		print(p, rbracket);
	case Union_Type:
		print(p, "union");

		if v.poly_params != nil {
			print(p, lparen);
			print_field_list(p, v.poly_params, ", ");
			print(p, rparen);
		}

		if v.is_maybe {
			print(p, space, "#maybe");
		}

		if v.variants != nil && (len(v.variants) == 0 || v.pos.line == v.end.line) {
			print(p, space, lbrace);
			set_source_position(p, v.variants[len(v.variants) - 1].pos);
			print_exprs(p, v.variants, ", ");
			print(p, rbrace);
		} else {
			print_begin_brace(p, v.pos, .Generic);
			print(p, newline);
			set_source_position(p, v.variants[len(v.variants) - 1].pos);
			print_exprs(p, v.variants, ",", true);
			print_end_brace(p, v.end);
		}
	case Enum_Type:
		print(p, "enum");

		if v.base_type != nil {
			print(p, space);
			print_expr(p, v.base_type);
		}

		if v.fields != nil && (len(v.fields) == 0 || v.pos.line == v.end.line) {
			print(p, space, lbrace);
			set_source_position(p, v.fields[len(v.fields) - 1].pos);
			print_exprs(p, v.fields, ", ");
			print(p, rbrace);
		} else {
			print_begin_brace(p, v.pos, .Generic);
			print(p, newline);
			set_source_position(p, v.fields[len(v.fields) - 1].pos);
			print_enum_fields(p, v.fields, ",");
			print_end_brace(p, v.end);
		}

		set_source_position(p, v.end);
	case Struct_Type:
		print(p, "struct");

		if v.is_packed {
			print(p, space, "#packed");
		}

		if v.is_raw_union {
			print(p, space, "#raw_union");
		}

		if v.align != nil {
			print(p, space, "#align", space);
			print_expr(p, v.align);
		}

		if v.poly_params != nil {
			print(p, lparen);
			print_field_list(p, v.poly_params, ", ");
			print(p, rparen);
		}

		if v.fields != nil && (len(v.fields.list) == 0 || v.pos.line == v.end.line) {
			print(p, space, lbrace);
			set_source_position(p, v.fields.pos);
			print_field_list(p, v.fields, ", ");
			print(p, rbrace);
		} else {
			print_begin_brace(p, v.pos, .Generic);
			print(p, newline);
			set_source_position(p, v.fields.pos);
			print_struct_field_list(p, v.fields, ",");
			print_end_brace(p, v.end);
		}

		set_source_position(p, v.end);
	case Proc_Lit:

		if v.inlining == .Inline {
			print(p, "#force_inline", space);
		}

		print_proc_type(p, v.type^);

		if v.where_clauses != nil {
			print(p, space);
			newline_until_pos(p, v.where_clauses[0].pos);
			print(p, "where", space);
			print_exprs(p, v.where_clauses, ", ");
		}

		if v.body != nil {
			set_source_position(p, v.body.pos);
			print_stmt(p, v.body, .Proc);
		} else {
			print(p, space, "---");
		}
	case Proc_Type:
		print_proc_type(p, v);
	case Basic_Lit:
		print(p, v.tok);
	case Binary_Expr:
		print_binary_expr(p, v);
	case Implicit_Selector_Expr:
		print(p, dot, v.field^);
	case Call_Expr:
		print_expr(p, v.expr);
		print(p, lparen);

		padding := get_length_of_names({v.expr});

		print_call_exprs(p, v.args, ", ", v.ellipsis.kind == .Ellipsis, padding);
		print(p, rparen);
	case Typeid_Type:
		print(p, "typeid");
		if v.specialization != nil {
			print(p, "/");
			print_expr(p, v.specialization);
		}
	case Selector_Expr:
		print_expr(p, v.expr);
		print(p, v.op);
		print_expr(p, v.field);
	case Paren_Expr:
		print(p, lparen);
		print_expr(p, v.expr);
		print(p, rparen);
	case Index_Expr:
		print_expr(p, v.expr);
		print(p, lbracket);
		print_expr(p, v.index);
		print(p, rbracket);
	case Proc_Group:

		print(p, v.tok);

		if len(v.args) != 0 && v.pos.line != v.args[len(v.args) - 1].pos.line {
			print_begin_brace(p, v.pos, .Generic);
			print(p, newline);
			set_source_position(p, v.args[len(v.args) - 1].pos);
			print_exprs(p, v.args, ",", true);
			print_end_brace(p, v.end);
		} else {
			print(p, space, lbrace);
			print_exprs(p, v.args, ", ");
			print(p, rbrace);
		}
	case Comp_Lit:

		if v.type != nil {
			print_expr(p, v.type);
			print(p, space);
		}

		if len(v.elems) != 0 && v.pos.line != v.elems[len(v.elems) - 1].pos.line {
			print_begin_brace(p, v.pos, .Comp_Lit);
			print(p, newline);
			set_source_position(p, v.elems[len(v.elems) - 1].pos);
			print_exprs(p, v.elems, ",", true);
			print_end_brace(p, v.end);
		} else {
			print(p, lbrace);
			print_exprs(p, v.elems, ", ");
			print(p, rbrace);
		}
	case Unary_Expr:
		print(p, v.op);
		print_expr(p, v.expr);
	case Field_Value:
		print_expr(p, v.field);
		print(p, space, "=", space);
		print_expr(p, v.value);
	case Type_Assertion:
		print_expr(p, v.expr);

		if unary, ok := v.type.derived.(Unary_Expr); ok && unary.op.text == "?" {
			print(p, dot);
			print_expr(p, v.type);
		} else {
			print(p, dot, lparen);
			print_expr(p, v.type);
			print(p, rparen);
		}

	case Pointer_Type:
		print(p, "^");
		print_expr(p, v.elem);
	case Implicit:
		print(p, v.tok);
	case Poly_Type:
		print(p, "$");
		print_expr(p, v.type);

		if v.specialization != nil {
			print(p, "/");
			print_expr(p, v.specialization);
		}
	case Array_Type:
		print_expr(p, v.tag);
		print(p, lbracket);
		print_expr(p, v.len);
		print(p, rbracket);
		print_expr(p, v.elem);
	case Map_Type:
		print(p, "map", lbracket);
		print_expr(p, v.key);
		print(p, rbracket);
		print_expr(p, v.value);
	case Helper_Type:
		print_expr(p, v.type);
	case:
		panic(fmt.aprint(expr.derived));
	}
}

print_proc_type :: proc(p: ^Printer, proc_type: ast.Proc_Type) {

	print(p, "proc"); //TOOD(ast is missing proc token)

	if proc_type.calling_convention != .Odin {
		print(p, space);
	}

	switch proc_type.calling_convention {
	case .Odin:
	case .Contextless:
		print(p, "\"contextless\"", space);
	case .C_Decl:
		print(p, "\"c\"", space);
	case .Std_Call:
		print(p, "\"std\"", space);
	case .Fast_Call:
		print(p, "\"fast\"", space);
	case .None:
			//nothing i guess
	case .Invalid:
			//nothing i guess
	case .Foreign_Block_Default:
	}

	print(p, lparen);
	print_signature_list(p, proc_type.params, ", ", false);
	print(p, rparen);

	if proc_type.results != nil {
		print(p, space, "->", space);

		use_parens := false;
		use_named  := false;

		if len(proc_type.results.list) > 1 {
			use_parens = true;
		} else if len(proc_type.results.list) == 1 {

			for name in proc_type.results.list[0].names {
				if ident, ok := name.derived.(ast.Ident); ok {
					if ident.name != "_" {
						use_parens = true;
					}
				}
			}
		}

		if use_parens {
			print(p, lparen);
			print_signature_list(p, proc_type.results, ", ");
			print(p, rparen);
		} else {
			print_signature_list(p, proc_type.results, ", ");
		}
	}
}

print_enum_fields :: proc(p: ^Printer, list: []^ast.Expr, sep := " ") {

	//print enum fields is like print_exprs, but it can contain fields that can be aligned.

	if len(list) == 0 {
		return;
	}

	if list[0].pos.line == list[len(list) - 1].pos.line {
		//if everything is on one line, then it can be treated the same way as print_exprs
		print_exprs(p, list, sep);
		return;
	}

	largest          := 0;
	last_field_value := 0;

	//first find all the field values and find the largest name
	for expr, i in list {

		if field_value, ok := expr.derived.(ast.Field_Value); ok {

			if ident, ok := field_value.field.derived.(ast.Ident); ok {
				largest = max(largest, strings.rune_count(ident.name));
			}
		}
	}

	for expr, i in list {

		newline_until_pos_limit(p, expr.pos, 1);

		if field_value, ok := expr.derived.(ast.Field_Value); ok && p.config.align_assignments {

			if ident, ok := field_value.field.derived.(ast.Ident); ok {
				print_expr(p, field_value.field);
				print_space_padding(p, largest - strings.rune_count(ident.name) + 1);
				print(p, "=", space);
				print_expr(p, field_value.value);
			} else {
				print_expr(p, expr);
			}
		} else {
			print_expr(p, expr);
		}

		if i != len(list) - 1 {
			print(p, sep);
		} else {
			print(p, strings.trim_space(sep));
		}
	}
}

print_call_exprs :: proc(p: ^Printer, list: []^ast.Expr, sep := " ", ellipsis := false, padding := 0) {

	if len(list) == 0 {
		return;
	}

	//all the expression are on the line
	if list[0].pos.line == list[len(list) - 1].pos.line {

		for expr, i in list {

			if i == len(list) - 1 && ellipsis {
				print(p, "..");
			}

			print_expr(p, expr);

			if i != len(list) - 1 {
				print(p, sep);
			}
		}
	} else {

		for expr, i in list {

			//we have to newline the expressions to respect the source
			if newline_until_pos_limit(p, expr.pos, 1) {
				print_space_padding(p, padding);
			}

			if i == len(list) - 1 && ellipsis {
				print(p, "..");
			}

			print_expr(p, expr);

			if i != len(list) - 1 {
				print(p, sep);
			}
		}
	}
}

print_exprs :: proc(p: ^Printer, list: []^ast.Expr, sep := " ", trailing := false) {

	if len(list) == 0 {
		return;
	}

	//we have to newline the expressions to respect the source
	for expr, i in list {

		newline_until_pos_limit(p, expr.pos, 1);

		print_expr(p, expr);

		if i != len(list) - 1 {
			print(p, sep);
		} else if trailing {
			print(p, strings.trim_space(sep));
		}
	}
}

print_binary_expr :: proc(p: ^Printer, binary: ast.Binary_Expr) {

	newline_until_pos(p, binary.left.pos);

	if v, ok := binary.left.derived.(ast.Binary_Expr); ok {
		print_binary_expr(p, v);
	} else {
		print_expr(p, binary.left);
	}

	if binary.op.kind == .Ellipsis || binary.op.kind == .Range_Half {
		print(p, binary.op);
	} else {
		print(p, space, binary.op, space);
	}

	newline_until_pos(p, binary.right.pos);

	if v, ok := binary.right.derived.(ast.Binary_Expr); ok {
		print_binary_expr(p, v);
	} else {
		print_expr(p, binary.right);
	}
}

print_struct_field_list :: proc(p: ^Printer, list: ^ast.Field_List, sep := "") {

	if list.list == nil {
		return;
	}

	largest    := 0;
	using_size := len("using ");

	//NOTE(Daniel): Is there any other variables than using in structs?

	for field, i in list.list {
		if .Using in field.flags {
			largest = max(largest, get_length_of_names(field.names) + using_size);
		} else {
			largest = max(largest, get_length_of_names(field.names));
		}
	}

	for field, i in list.list {

		newline_until_pos_limit(p, field.pos, 1);

		if .Using in field.flags {
			print(p, "using", space);
		}

		print_exprs(p, field.names, ", ");

		if len(field.names) != 0 {
			print(p, ": ");
		}

		if field.type == nil {
			panic("struct field has to have types");
		}

		if .Using in field.flags {
			print_space_padding(p, largest - get_length_of_names(field.names) - using_size);
		} else {
			print_space_padding(p, largest - get_length_of_names(field.names));
		}

		print_expr(p, field.type);

		if field.tag.text != "" {
			print(p, space, field.tag);
		}

		if i != len(list.list) - 1 {
			print(p, sep);
		} else {
			print(p, strings.trim_space(sep));
		}
	}
}

print_field_list :: proc(p: ^Printer, list: ^ast.Field_List, sep := "") {

	if list.list == nil {
		return;
	}

	for field, i in list.list {

		newline_until_pos_limit(p, field.pos, 1);

		if .Using in field.flags {
			print(p, "using", space);
		}

		print_exprs(p, field.names, ", ");

		if len(field.names) != 0 {
			print(p, ": ");
		}

		if field.type != nil {
			print_expr(p, field.type);
		} else {
			print(p, ":= ");
			print_expr(p, field.default_value);
		}

		if field.tag.text != "" {
			print(p, space, field.tag);
		}

		if i != len(list.list) - 1 {
			print(p, sep);
		}
	}
}

print_signature_list :: proc(p: ^Printer, list: ^ast.Field_List, sep := "", remove_blank := true) {

	if list.list == nil {
		return;
	}

	for field, i in list.list {

		newline_until_pos_limit(p, field.pos, 1);

		if .Using in field.flags {
			print(p, "using", space);
		}

		named := false;

		for name in field.names {
			if ident, ok := name.derived.(ast.Ident); ok {
				//for some reason the parser uses _ to mean empty
				if ident.name != "_" || !remove_blank {
					named = true;
				}
			} else {
				//alternative is poly names
				named = true;
			}
		}

		if named {
			print_exprs(p, field.names, ", ");

			if len(field.names) != 0 && field.type != nil {
				print(p, ": ");
			} else {
				print(p, space);
			}
		}

		if field.type != nil && field.default_value != nil {
			print_expr(p, field.type);
			print(p, space, "=", space);
			print_expr(p, field.default_value);
		} else if field.type != nil {
			print_expr(p, field.type);
		} else {
			print(p, ":= ");
			print_expr(p, field.default_value);
		}

		if i != len(list.list) - 1 {
			print(p, sep);
		}
	}
}

print_stmt :: proc(p: ^Printer, stmt: ^ast.Stmt, block_type: Block_Type = .Generic, empty_block := false, block_stmt := false) {

	using ast;

	if stmt == nil {
		return;
	}

	switch v in stmt.derived {
	case Value_Decl:
		print_decl(p, cast(^Decl)stmt, true);
		return;
	case Foreign_Import_Decl:
		print_decl(p, cast(^Decl)stmt, true);
		return;
	case Foreign_Block_Decl:
		print_decl(p, cast(^Decl)stmt, true);
		return;
	}

	switch v in stmt.derived {
	case Using_Stmt:
		newline_until_pos(p, v.pos);
		print(p, "using", space);
		print_exprs(p, v.list, ", ");

		if p.config.semicolons {
			print(p, semicolon);
		}
	case Block_Stmt:
		newline_until_pos(p, v.pos);

		if v.pos.line == v.end.line && len(v.stmts) > 1 && p.config.split_multiple_stmts {

			if !empty_block {
				print_begin_brace(p, v.pos, block_type);
			}

			set_source_position(p, v.pos);

			print_block_stmts(p, v.stmts, true);

			set_source_position(p, v.end);

			if !empty_block {
				print_end_brace(p, v.end);
			}
		} else if v.pos.line == v.end.line {
			if !empty_block {
				print(p, lbrace);
			}

			set_source_position(p, v.pos);

			print_block_stmts(p, v.stmts);

			set_source_position(p, v.end);

			if !empty_block {
				print(p, rbrace);
			}
		} else {
			if !empty_block {
				print_begin_brace(p, v.pos, block_type);
			}

			set_source_position(p, v.pos);

			print_block_stmts(p, v.stmts);

			set_source_position(p, v.end);

			if !empty_block {
				print_end_brace(p, v.end);
			}
		}
	case If_Stmt:
		newline_until_pos(p, v.pos);

		if v.label != nil {
			print_expr(p, v.label);
			print(p, ":", space);
		}

		print(p, "if", space);

		if v.init != nil {
			p.skip_semicolon = true;
			print_stmt(p, v.init);
			p.skip_semicolon = false;
			print(p, semicolon, space);
		}

		print_expr(p, v.cond);

		uses_do := false;

		if check_stmt, ok := v.body.derived.(Block_Stmt); ok && check_stmt.uses_do {
			uses_do = true;
		}

		if uses_do && !p.config.convert_do {
			print(p, space, "do", space);
			print_stmt(p, v.body, .If_Stmt, true);
		} else {
			if uses_do {
				print(p, newline);
			}

			print_stmt(p, v.body, .If_Stmt);
		}

		if v.else_stmt != nil {

			if p.config.brace_style == .Allman || p.config.brace_style == .Stroustrup {
				print(p, newline);
			} else {
				print(p, space);
			}

			print(p, "else");

			if if_stmt, ok := v.else_stmt.derived.(ast.If_Stmt); ok {
				print(p, space);
			}

			set_source_position(p, v.else_stmt.pos);

			print_stmt(p, v.else_stmt);
		}
	case Switch_Stmt:
		newline_until_pos(p, v.pos);

		if v.label != nil {
			print_expr(p, v.label);
			print(p, ":", space);
		}

		if v.partial {
			print(p, "#partial", space);
		}

		print(p, "switch");

		if v.init != nil || v.cond != nil {
			print(p, space);
		}

		if v.init != nil {
			p.skip_semicolon = true;
			print_stmt(p, v.init);
			p.skip_semicolon = false;
		}

		if v.init != nil && v.cond != nil {
			print(p, semicolon, space);
		}

		print_expr(p, v.cond);
		print_stmt(p, v.body);
	case Case_Clause:
		newline_until_pos(p, v.pos);

		if !p.config.indent_cases {
			print(p, unindent);
		}

		print(p, "case", indent);

		if v.list != nil {
			print(p, space);
			print_exprs(p, v.list, ",");
		}

		print(p, v.terminator);

		print_block_stmts(p, v.body);

		print(p, unindent);

		if !p.config.indent_cases {
			print(p, indent);
		}
	case Type_Switch_Stmt:
		newline_until_pos(p, v.pos);

		if v.label != nil {
			print_expr(p, v.label);
			print(p, ":", space);
		}

		if v.partial {
			print(p, "#partial", space);
		}

		print(p, "switch", space);

		print_stmt(p, v.tag);
		print_stmt(p, v.body);
	case Assign_Stmt:
		newline_until_pos(p, v.pos);

		/*
			if len(v.lhs) == 1 {

			if ident, ok := v.lhs[0].derived.(Ident); ok && ident.name == "_" {
			print(p, v.op, space);
			print_exprs(p, v.rhs, ", ");
			return;
			}

			}
		*/

		print_exprs(p, v.lhs, ", ");

		if p.config.align_assignments && p.align_info.assign_aligned_begin_line <= v.pos.line && v.pos.line <= p.align_info.assign_aligned_end_line {
			print_space_padding(p, p.align_info.assign_aligned_padding - get_length_of_names(v.lhs));
		}

		print(p, space, v.op, space);

		print_exprs(p, v.rhs, ", ");

		if block_stmt && p.config.semicolons {
			print(p, semicolon);
		}
	case Expr_Stmt:
		newline_until_pos(p, v.pos);
		print_expr(p, v.expr);
		if block_stmt && p.config.semicolons {
			print(p, semicolon);
		}
	case For_Stmt:
		//this should be simplified
		newline_until_pos(p, v.pos);

		if v.label != nil {
			print_expr(p, v.label);
			print(p, ":", space);
		}

		print(p, "for");

		if v.init != nil || v.cond != nil || v.post != nil {
			print(p, space);
		}

		if v.init != nil {
			p.skip_semicolon = true;
			print_stmt(p, v.init);
			p.skip_semicolon = false;
			print(p, semicolon, space);
		} else if v.post != nil {
			print(p, semicolon, space);
		}

		if v.cond != nil {
			print_expr(p, v.cond);
		}

		if v.post != nil {
			print(p, semicolon);
			print(p, space);
			print_stmt(p, v.post);
		} else if v.post == nil && v.cond != nil && v.init != nil {
			print(p, semicolon);
		}

		print_stmt(p, v.body);
	case Inline_Range_Stmt:

		newline_until_pos(p, v.pos);

		if v.label != nil {
			print_expr(p, v.label);
			print(p, ":", space);
		}

		print(p, "#unroll", space);

		print(p, "for", space);
		print_expr(p, v.val0);

		if v.val1 != nil {
			print(p, ",", space);
			print_expr(p, v.val1);
			print(p, space);
		}

		print(p, "in", space);
		print_expr(p, v.expr);

		print_stmt(p, v.body);
	case Range_Stmt:

		newline_until_pos(p, v.pos);

		if v.label != nil {
			print_expr(p, v.label);
			print(p, ":", space);
		}

		print(p, "for", space);

		if len(v.vals) >= 1 {
			print_expr(p, v.vals[0]);
		}

		if len(v.vals) >= 2 {
			print(p, ",", space);
			print_expr(p, v.vals[1]);
			print(p, space);
		} else {
			print(p, space);
		}

		print(p, "in", space);
		print_expr(p, v.expr);

		print_stmt(p, v.body);
	case Return_Stmt:
		newline_until_pos(p, v.pos);
		print(p, "return");

		if v.results != nil {
			print(p, space);
			print_exprs(p, v.results, ", ");
		}

		if block_stmt && p.config.semicolons {
			print(p, semicolon);
		}
	case Defer_Stmt:
		newline_until_pos(p, v.pos);
		print(p, "defer");

		if block, ok := v.stmt.derived.(ast.Block_Stmt); !ok {
			print(p, space);
		}

		print_stmt(p, v.stmt);

		if p.config.semicolons {
			print(p, semicolon);
		}
	case When_Stmt:
		newline_until_pos(p, v.pos);
		print(p, "when", space);
		print_expr(p, v.cond);

		print_stmt(p, v.body);

		if v.else_stmt != nil {

			if p.config.brace_style == .Allman {
				print(p, newline);
			} else {
				print(p, space);
			}

			print(p, "else");

			if when_stmt, ok := v.else_stmt.derived.(ast.When_Stmt); ok {
				print(p, space);
			}

			set_source_position(p, v.else_stmt.pos);

			print_stmt(p, v.else_stmt);
		}

	case Branch_Stmt:

		newline_until_pos(p, v.pos);

		print(p, v.tok);

		if v.label != nil {
			print(p, space);
			print_expr(p, v.label);
		}

		if p.config.semicolons {
			print(p, semicolon);
		}
	case:
		panic(fmt.aprint(stmt.derived));
	}

	set_source_position(p, stmt.end);
}

print_decl :: proc(p: ^Printer, decl: ^ast.Decl, called_in_stmt := false) {

	using ast;

	if decl == nil {
		return;
	}

	switch v in decl.derived {
	case Expr_Stmt:
		newline_until_pos(p, decl.pos);
		print_expr(p, v.expr);
		if p.config.semicolons {
			print(p, semicolon);
		}
	case When_Stmt:
		print_stmt(p, cast(^Stmt)decl);
	case Foreign_Import_Decl:
		if len(v.attributes) > 0 {
			newline_until_pos(p, v.attributes[0].pos);
		} else {
			newline_until_pos(p, decl.pos);
		}

		print_attributes(p, v.attributes);

		if v.name != nil {
			print(p, v.foreign_tok, space, v.import_tok, space, v.name^, space);
		} else {
			print(p, v.foreign_tok, space, v.import_tok, space);
		}

		for path in v.fullpaths {
			print(p, path);
		}
	case Foreign_Block_Decl:

		if len(v.attributes) > 0 {
			newline_until_pos(p, v.attributes[0].pos);
		} else {
			newline_until_pos(p, decl.pos);
		}

		print_attributes(p, v.attributes);

		print(p, newline, "foreign", space);
		print_expr(p, v.foreign_library);
		print_stmt(p, v.body);
	case Import_Decl:
		newline_until_pos(p, decl.pos);

		if v.name.text != "" {
			print(p, v.import_tok, " ", v.name, " ", v.fullpath);
		} else {
			print(p, v.import_tok, " ", v.fullpath);
		}

	case Value_Decl:
		if len(v.attributes) > 0 {
			newline_until_pos(p, v.attributes[0].pos);
			print_attributes(p, v.attributes);
		}

		newline_until_pos(p, decl.pos);

		if v.is_using {
			print(p, "using", space);
		}

		print_exprs(p, v.names, ", ");

		seperator := ":";

		if !v.is_mutable && v.type == nil {
			seperator = ":: ";
		} else if !v.is_mutable && v.type != nil {
			seperator = " :";
		}

		if in_value_decl_alignment(p, v) && p.config.align_style == .Align_On_Colon_And_Equals {
			print_space_padding(p, p.align_info.value_decl_aligned_padding - get_length_of_names(v.names));
		}

		if v.type != nil {
			print(p, seperator, space);

			if in_value_decl_alignment(p, v) && p.config.align_style == .Align_On_Type_And_Equals {
				print_space_padding(p, p.align_info.value_decl_aligned_padding - get_length_of_names(v.names));
			} else if in_value_decl_alignment(p, v) && p.config.align_style == .Align_On_Colon_And_Equals {
				print_space_padding(p, p.align_info.value_decl_aligned_type_padding - (v.type.end.column - v.type.pos.column));
			}

			print_expr(p, v.type);

			if in_value_decl_alignment(p, v) && p.config.align_style == .Align_On_Type_And_Equals && len(v.values) != 0 {
				print_space_padding(p, p.align_info.value_decl_aligned_type_padding - (v.type.end.column - v.type.pos.column));
			}
		} else {
			if in_value_decl_alignment(p, v) && p.config.align_style == .Align_On_Type_And_Equals {
				print_space_padding(p, p.align_info.value_decl_aligned_padding - get_length_of_names(v.names));
			}
			print(p, space, seperator);
		}

		if v.is_mutable && v.type != nil && len(v.values) != 0 {
			print(p, space, "=", space);
		} else if v.is_mutable && v.type == nil && len(v.values) != 0 {
			print(p, "=", space);
		} else if !v.is_mutable && v.type != nil {
			print(p, space, ":", space);
		}

		print_exprs(p, v.values, ", ");

		add_semicolon := true;

		for value in v.values {
			switch a in value.derived {
			case Proc_Lit,Union_Type,Enum_Type,Struct_Type:
				add_semicolon = false || called_in_stmt;
			}
		}

		if add_semicolon && p.config.semicolons && !p.skip_semicolon {
			print(p, semicolon);
		}

	case:
		panic(fmt.aprint(decl.derived));
	}
}

print_attributes :: proc(p: ^Printer, attributes: [dynamic]^ast.Attribute) {

	if len(attributes) == 0 {
		return;
	}

	for attribute, i in attributes {

		print(p, "@", lparen);
		print_exprs(p, attribute.elems, ", ");
		print(p, rparen);

		if len(attributes) - 1 != i {
			print(p, newline);
		}
	}
}

print_file :: proc(p: ^Printer, file: ^ast.File) {

	p.comments = file.comments;
	p.file     = file;

	newline_until_pos(p, file.pkg_token.pos);

	print(p, file.pkg_token, space, file.pkg_name);

	for decl, i in file.decls {

		if value_decl, ok := decl.derived.(ast.Value_Decl); ok {
			set_value_decl_alignment_padding(p, value_decl, file.decls[i + 1:]);
		}

		print_decl(p, cast(^ast.Decl)decl);
	}

	//todo(probably check if there already is a newline, but there really shouldn't be)
	print(p, newline); //finish document with newline
	write_whitespaces(p, p.current_whitespace);
}

print_begin_brace :: proc(p: ^Printer, begin: tokenizer.Pos, type: Block_Type) {

	set_source_position(p, begin);

	newline_braced := p.config.brace_style == .Allman;
	newline_braced |= p.config.brace_style == .K_And_R && type == .Proc;
	newline_braced &= p.config.brace_style != ._1TBS;

	if newline_braced {
		print(p, newline);
		print(p, lbrace);
		print(p, indent);
	} else {

		if type != .Comp_Lit && p.last_out_position.line == (p.out_position.line + get_current_newlines(p)) {
			print(p, space);
		}
		print(p, lbrace);
		print(p, indent);
	}
}

print_end_brace :: proc(p: ^Printer, end: tokenizer.Pos) {
	set_source_position(p, end);
	print(p, newline, unindent, rbrace);
}

print_block_stmts :: proc(p: ^Printer, stmts: []^ast.Stmt, newline_each := false) {
	for stmt, i in stmts {

		if newline_each {
			print(p, newline);
		}

		if value_decl, ok := stmt.derived.(ast.Value_Decl); ok {
			set_value_decl_alignment_padding(p, value_decl, stmts[i + 1:]);
		} else if assignment_stmt, ok := stmt.derived.(ast.Assign_Stmt); ok {
			set_assign_alignment_padding(p, assignment_stmt, stmts[i + 1:]);
		}

		print_stmt(p, stmt, .Generic, false, true);
	}
}
*/


