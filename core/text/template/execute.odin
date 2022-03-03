package text_template

import "core:io"
import "core:reflect"
import "core:strings"
import "core:mem"
import "core:mem/virtual"
import "core:fmt"

import parse "parse"

Template :: struct {
	tree: ^parse.Tree,

	using config: Config,
}

Config :: struct {
	flags:       Flags,
	allocator:   mem.Allocator,
	left_delim:  string,
	right_delim: string,
}

Flags :: distinct bit_set[Flag; u64]
Flag :: enum u64 {
	Emit_Comments,
}

Parse_Error :: parse.Error
Execution_Error :: enum {
	Accumulated_Errors,

	Invalid_Node,
	Invalid_Command,
	Invalid_Value,

	Undeclared_Variable,
	Undefined_Function,

	Invalid_Break,
	Invalid_Continue,

	Invalid_Argument_Count,
	Invalid_Argument_Type,
	Out_Of_Bounds_Access,
}
Error :: union {
	io.Error,
	Execution_Error,
}

create_from_string :: proc(input: string, config: Maybe(Config) = nil) -> (t: ^Template, err: Parse_Error) {
	cfg, _ := config.?
	if cfg.allocator.procedure == nil {
		cfg.allocator = context.allocator
	}

	t = new(Template, cfg.allocator)
	t.config = cfg
	t.tree = nil
	t.tree, err = parse.parse(input, t.left_delim, t.right_delim, .Emit_Comments in t.flags, t.allocator)
	return
}

must :: proc(t: ^Template, err: Parse_Error) -> ^Template {
	assert(t != nil)
	assert(err == nil)
	return t
}

destroy :: proc(t: ^Template) {
	allocator := t.allocator
	parse.destroy_tree(t.tree)
	free(t, allocator)
}

execute :: proc(t: ^Template, w: io.Writer, data: any) -> Error {
	s := State{
		tmpl = t,
		w    = w,
	}
	context.allocator = virtual.arena_allocator(&s.arena)
	defer free_all(context.allocator)

	err := walk(&s, data,t.tree.root)
	if err == nil && s.error_count > 0 {
		err = .Accumulated_Errors
	}
	return err
}


State :: struct {
	arena: virtual.Growing_Arena,

	tmpl:  ^Template,
	w:     io.Writer,
	at:    ^parse.Node,
	vars:  [dynamic]Variable,
	depth: int,
	error_count: int,
}
Variable :: struct {
	name:  string,
	value: any,
}

walk :: proc(s: ^State, dot: any, node: ^parse.Node) -> Error {
	s.at = node

	switch n in node.variant {
	case ^parse.Node_Comment:
		// ignore
	case ^parse.Node_Text:
		io.write_string(s.w, n.text) or_return
		return nil
	case ^parse.Node_List:
		for elem in n.nodes {
			walk(s, dot, elem) or_return
		}
		return nil
	case ^parse.Node_Action:
		val := eval_pipeline(s, dot, n.pipe) or_return
		if len(n.pipe.decl) == 0 {
			print_value(s, n, val)
		}
		return nil
	case ^parse.Node_Pipeline:
		print_value(s, n, eval_pipeline(s, dot, n) or_return)
		return nil

	case ^parse.Node_Import:
		panic("TODO Node_Import")

	case ^parse.Node_If:
		return walk_if_or_with(s, .If, dot, n.pipe, n.list, n.else_list)
	case ^parse.Node_With:
		return walk_if_or_with(s, .With, dot, n.pipe, n.list, n.else_list)
	case ^parse.Node_For:
		return walk_for(s, dot, n)

	case ^parse.Node_Break:
		return .Invalid_Break
	case ^parse.Node_Continue:
		return .Invalid_Continue

	case ^parse.Node_Else,
	     ^parse.Node_End,
	     ^parse.Node_Nil,
	     ^parse.Node_Bool,
	     ^parse.Node_Number,
	     ^parse.Node_String,
	     ^parse.Node_Variable,
	     ^parse.Node_Identifier,
	     ^parse.Node_Operator,
	     ^parse.Node_Dot,
	     ^parse.Node_Field:
		return .Invalid_Node

	case ^parse.Node_Command:
		return .Invalid_Node
	case ^parse.Node_Chain:
		return .Invalid_Node
	}

	return .Invalid_Node
}

mark_vars :: proc(s: ^State) -> int {
	return len(s.vars)
}
pop_vars :: proc(s: ^State, n: int) {
	resize(&s.vars, n)
}

@(private, deferred_in_out=pop_vars)
SCOPE :: proc(s: ^State) -> int {
	return mark_vars(s)
}
walk_if_or_with :: proc(s: ^State, kind: enum{If, With}, dot: any,
                        pipe: ^parse.Node_Pipeline,
                        list: ^parse.Node_List,
                        else_list: ^parse.Node_List) -> Error {
	SCOPE(s)

	val := eval_pipeline(s, dot, pipe) or_return
	truth, ok := is_true(val)
	if !ok {
		error(s, "if/with cannot use %v", val)
	}
	if truth {
		if kind == .With {
			return walk(s, val, list)
		} else {
			return walk(s, dot, list)
		}
	} else if else_list != nil {
		return walk(s, dot, else_list)
	}
	return nil
}

walk_for :: proc(s: ^State, dot: any, f: ^parse.Node_For) -> Error {
	s.at = f
	SCOPE(s)

	val, _ := indirect(eval_pipeline(s, dot, f.pipe) or_return)

	mark := mark_vars(s)

	the_body :: proc(s: ^State, f: ^parse.Node_For, elem, index: any, mark: int) -> Error {
		if len(f.pipe.decl) > 0 {
			set_top_var(s, 1, index) or_return
		}
		if len(f.pipe.decl) > 1 {
			set_top_var(s, 2, elem) or_return
		}
		defer pop_vars(s, mark)
		return walk(s, elem, f.list)
	}

	original_id := val.id
	ti := reflect.type_info_base(type_info_of(val.id))
	val.id = ti.id
	#partial switch info in ti.variant {
	case reflect.Type_Info_Array,
	     reflect.Type_Info_Slice,
	     reflect.Type_Info_Dynamic_Array:
		n := reflect.length(val)
		if n == 0 {
			break
		}
		for i in 0..<n {
			the_body(s, f, reflect.index(val, i), i, mark) or_return
		}
		return nil
	case reflect.Type_Info_Map:
		if reflect.length(val) == 0 {
			break
		}

		gs := reflect.type_info_base(info.generated_struct).variant.(reflect.Type_Info_Struct)
		ed := reflect.type_info_base(gs.types[1]).variant.(reflect.Type_Info_Dynamic_Array)
		entry_type := ed.elem.variant.(reflect.Type_Info_Struct)
		key_offset :=  entry_type.offsets[2]
		value_offset :=  entry_type.offsets[3]
		entry_size := uintptr(ed.elem_size)
		key_type := entry_type.types[2]
		value_type := entry_type.types[3]

		rm := (^mem.Raw_Map)(val.data)

		data := uintptr(rm.entries.data)
		for i in 0..<rm.entries.len {
			key := any{rawptr(data + key_offset), key_type.id}
			value := any{rawptr(data + value_offset), value_type.id}

			the_body(s, f, key, value, mark) or_return

			data += entry_size
		}
		return nil

		// TODO
	case:
		error(s, "for cannot iterate over %v", original_id)
	}

	if f.else_list != nil {
		return walk(s, dot, f.else_list)
	}
	return nil
}

indirect :: proc(val: any) -> (v: any, is_nil: bool) {
	v = val
	for v != nil {
		ti := reflect.type_info_base(type_info_of(v.id))
		info, ok := ti.variant.(reflect.Type_Info_Pointer)
		if !ok {
			break
		}

		ptr := (^rawptr)(v.data)^
		if ptr == nil {
			return v, true
		}
		v = any{ptr, info.elem.id}
	}
	return v, false
}


error :: proc(s: ^State, format: string, args: ..any) {
	s.error_count += 1

	assert(s.at != nil)

	// NOTE(bill): the line and column are recalculated
	// each time here because errors are usually an early
	// out for this execution system

	pos := int(s.at.pos)
	text := s.tmpl.tree.input[:pos]
	col := strings.last_index(text, "\n")
	if col < 0 {
		col = pos
	} else {
		col += 1
		col = pos - col
	}

	line := 1 + strings.count(text, "\n")

	name := s.tmpl.tree.name
	if name == "" {
		name = "<input>"
	}
	fmt.eprintf("%s:%d:%d: ", name, line, col)
	fmt.eprintf(format, ..args)
	fmt.eprintln()
}

is_true :: proc(val: any) -> (truth, ok: bool) {
	check_trivial :: proc(v: any) -> (bool, bool) {
		data := reflect.as_bytes(v)
		for v in data {
			if v != 0 {
				return true, true
			}
		}
		return false, true
	}

	if val == nil {
		return false, true
	}

	ti := reflect.type_info_base(type_info_of(val.id))
	switch v in ti.variant {
	case reflect.Type_Info_Named:
		unreachable()
	case reflect.Type_Info_Integer,
	     reflect.Type_Info_Rune,
	     reflect.Type_Info_Float,
	     reflect.Type_Info_Complex,
	     reflect.Type_Info_Quaternion,
	     reflect.Type_Info_Boolean,
	     reflect.Type_Info_Bit_Set,
	     reflect.Type_Info_Enum:
	     return check_trivial(val)

	case reflect.Type_Info_String:
		if v.is_cstring {
			cstr := (^cstring)(val.data)^
			if cstr == nil {
				return false, true
			}
			return ([^]u8)(cstr)[0] != 0, true
		}
		str := (^string)(val.data)^
		return len(str) > 0, true

	case reflect.Type_Info_Any:
		return false, false
	case reflect.Type_Info_Type_Id:
		return (^typeid)(val.data)^ != nil, true
	case reflect.Type_Info_Pointer,
	     reflect.Type_Info_Multi_Pointer:
		return (^rawptr)(val.data)^ != nil, true

	case reflect.Type_Info_Procedure:
		return

	case reflect.Type_Info_Array:
		return v.count > 0, true
	case reflect.Type_Info_Enumerated_Array:
		return v.count > 0, true
	case reflect.Type_Info_Dynamic_Array:
		a := (^mem.Raw_Dynamic_Array)(val.data)
		return a.len > 0, true
	case reflect.Type_Info_Slice:
		a := (^mem.Raw_Slice)(val.data)
		return a.len > 0, true
	case reflect.Type_Info_Tuple:
		return
	case reflect.Type_Info_Struct:
		// All structs are always non nil
		return true, true
	case reflect.Type_Info_Union:
	     return reflect.union_variant_typeid(val) != nil, true
	case reflect.Type_Info_Map:
		m := (^mem.Raw_Map)(val.data)
		return m.entries.len > 0, true
	case reflect.Type_Info_Simd_Vector:
		return v.count > 0, true
	case reflect.Type_Info_Relative_Pointer:
		return check_trivial(val)
	case reflect.Type_Info_Relative_Slice:
		return check_trivial(val)
	case reflect.Type_Info_Matrix:
		return check_trivial(val)
	}
	return
}


eval_pipeline :: proc(s: ^State, dot: any, pipe: ^parse.Node_Pipeline) -> (value: any, err: Error) {
	if pipe == nil {
		return
	}
	s.at = pipe
	value = nil
	for cmd in pipe.cmds {
		value = eval_command(s, dot, cmd, value) or_return
	}
	for var in pipe.decl {
		if pipe.is_assign {
			set_var(s, var.name, value) or_return
		} else {
			push_var(s, var.name, value)
		}
	}
	return
}

set_var :: proc(s: ^State, name: string, value: any) -> Error {
	for i := mark_vars(s)-1; i >= 0; i -= 1 {
		if s.vars[i].name == name {
			s.vars[i].value = value
			return nil
		}
	}
	return .Undeclared_Variable
}

set_top_var :: proc(s: ^State, n: int, value: any) -> Error {
	if len(s.vars) > 0 {
		s.vars[len(s.vars)-n].value = value
		return nil
	}
	return .Undeclared_Variable
}

push_var :: proc(s: ^State, name: string, value: any) {
	append(&s.vars, Variable{name, value})
}
get_var :: proc(s: ^State, name: string) -> (value: any, err: Error) {
	for i := mark_vars(s)-1; i >= 0; i -= 1 {
		if s.vars[i].name == name {
			return s.vars[i].value, nil
		}
	}
	error(s, "undeclared variable $%s", name)
	return nil, .Undeclared_Variable

}

eval_command :: proc(s: ^State, dot: any, cmd: ^parse.Node_Command, final: any) -> (value: any, err: Error) {
	first_word := cmd.args[0]
	#partial switch n in first_word.variant {
	case ^parse.Node_Field:
		s.at = n
		return eval_fields(s, dot, n.idents)
	case ^parse.Node_Chain:
		return eval_chain(s, dot, n)
	case ^parse.Node_Identifier:
		return eval_function(s, dot, n.ident, cmd, final)
	case ^parse.Node_Operator:
		return eval_function(s, dot, n.value, cmd, final)
	case ^parse.Node_Pipeline:
		return eval_pipeline(s, dot, n)
	case ^parse.Node_Variable:
		s.at = n
		return get_var(s, n.name)
	}
	s.at = first_word
	#partial switch n in first_word.variant {
	case ^parse.Node_Bool:
		return new_any(n.ok), nil
	case ^parse.Node_Dot:
		return dot, nil
	case ^parse.Node_Nil:
		return nil, nil
	case ^parse.Node_Number:
		if i, ok := n.i.?; ok {
			return new_any(i), nil
		}
		if u, ok := n.u.?; ok {
			return new_any(u), nil
		}
		if f, ok := n.f.?; ok {
			return new_any(f), nil
		}
		return eval_function(s, dot, n.text, cmd, final)
	case ^parse.Node_String:
		return new_any(n.text), nil
	}

	error(s, "cannot evaluate command %v", first_word.variant)
	return nil, .Invalid_Command
}

eval_chain :: proc(s: ^State, dot: any, chain: ^parse.Node_Chain) -> (value: any, err: Error) {
	s.at = chain
	return eval_fields(s, eval_arg(s, dot, chain.node) or_return, chain.fields[:])
}

eval_fields :: proc(s: ^State, dot: any, idents: []string) -> (value: any, err: Error) {
	value = dot
	for ident in idents {
		value = eval_field(s, value, ident) or_return
	}
	return
}

eval_field :: proc(s: ^State, dot: any, ident: string) -> (value: any, err: Error) {
	if dot == nil {
		return nil, nil
	}

	ti := reflect.type_info_base(type_info_of(dot.id))
	#partial switch info in ti.variant {
	case reflect.Type_Info_Struct:
		value = reflect.struct_field_value_by_name(dot, ident, true)
		if value != nil {
			return
		}
	case reflect.Type_Info_Pointer:
		if dot.data != nil {
			deref := (^rawptr)(dot.data)^
			return eval_field(s, {deref, info.elem.id}, ident)
		}
	case reflect.Type_Info_Map:
		key_type := reflect.type_info_base(info.key)
		switch key_type.id {
		case typeid_of(string), typeid_of(cstring):
			gs := reflect.type_info_base(info.generated_struct).variant.(reflect.Type_Info_Struct)
			ed := reflect.type_info_base(gs.types[1]).variant.(reflect.Type_Info_Dynamic_Array)
			entry_type := ed.elem.variant.(reflect.Type_Info_Struct)
			key_offset :=  entry_type.offsets[2]
			value_offset :=  entry_type.offsets[3]
			entry_size := uintptr(ed.elem_size)

			rm := (^mem.Raw_Map)(dot.data)

			data := uintptr(rm.entries.data)
			for i in 0..<rm.entries.len {
				key: string
				switch key_type.id {
				case typeid_of(string):
					key = (^string)(data + key_offset)^
				case typeid_of(cstring):
					key = string((^cstring)(data + key_offset)^)
				}

				if key == ident {
					ptr := rawptr(data + value_offset)
					return any{ptr, entry_type.types[3].id}, nil
				}

				data += entry_size
			}
			return nil, nil
		}
	}


	error(s, "cannot evaluate field %s in type %v", ident, dot.id)
	return nil, .Invalid_Value
}

eval_function :: proc(s: ^State, dot: any, name: string, cmd: ^parse.Node_Command, final: any) -> (value: any, err: Error) {
	cmd_args := cmd.args[1:]

	switch name {
	case "+", "-":
		if len(cmd_args) < 1 {
			error(s, "%q expects at least 1 argument", name)
			return nil, .Invalid_Argument_Count
		}
		// TODO

		return nil, nil
	case "*":
		if len(cmd_args) < 1 {
			error(s, "%q expects at least 2 arguments, got %d", name, len(cmd_args))
			return nil, .Invalid_Argument_Count
		}
		// TODO
		return nil, nil
	}

	function, ok := builtin_funcs[name]
	if !ok {
		error(s, "%q is not a defined function", name)
		err = .Undefined_Function
		return
	}

	if function == nil {
		switch name {
		case "and":
			// TODO
		case "or":
			// TODO
		case:
			panic("unhandled built-in procedure")
		}
	}

	n := len(cmd_args)
	if final != nil {
		n += 1
	}
	args_to_call := make([dynamic]any, 0, n)
	for arg in cmd_args {
		append(&args_to_call, eval_arg(s, dot, arg) or_return)
	}
	if final != nil {
		append(&args_to_call, final)
	}

	return function(args_to_call[:])
}

eval_arg :: proc(s: ^State, dot: any, arg: ^parse.Node) -> (value: any, err: Error) {
	s.at = arg
	#partial switch n in arg.variant {
	case ^parse.Node_Dot:
		return dot, nil
	case ^parse.Node_Nil:
		return nil, nil
	case ^parse.Node_Bool:
		return new_any(n.ok), nil
	case ^parse.Node_Number:
		if i, ok := n.i.?; ok {
			return new_any(i), nil
		}
		if u, ok := n.u.?; ok {
			return new_any(u), nil
		}
		if f, ok := n.f.?; ok {
			return new_any(f), nil
		}
	case ^parse.Node_String:
		return new_any(n.text), nil

	case ^parse.Node_Field:
		return eval_fields(s, dot, n.idents)
	case ^parse.Node_Variable:
		return get_var(s, n.name)
	case ^parse.Node_Pipeline:
		return eval_pipeline(s, dot, n)
	case ^parse.Node_Chain:
		return eval_chain(s, dot, n)
	}
	return nil, .Invalid_Node
}


print_value :: proc(s: ^State, n: ^parse.Node, val: any) {
	s.at = n
	if val == nil {
		io.write_string(s.w, "nil")
	} else {
		fmt.wprint(s.w, val)
	}
}