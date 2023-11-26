package odin_frontend

import "core:fmt"

Warning_Handler :: #type proc(pos: Pos, format: string, args: ..any)
Error_Handler   :: #type proc(pos: Pos, format: string, args: ..any)

default_warning_handler  :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d): Warning: ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}

default_error_handler :: proc(pos: Pos, msg: string, args: ..any) {
	fmt.eprintf("%s(%d:%d): ", pos.file, pos.line, pos.column)
	fmt.eprintf(msg, ..args)
	fmt.eprintf("\n")
}

tokenizer_error :: proc(t: ^Tokenizer, offset: int, msg: string, args: ..any) {
	pos := offset_to_pos(t, offset)
	if t.err != nil {
		t.err(pos, msg, ..args)
	}
	t.error_count += 1
}

parser_error :: proc(p: ^Parser, pos: Pos, msg: string, args: ..any) {
	if p.err != nil {
		p.err(pos, msg, ..args)
	}
	//p.file.syntax_error_count += 1
	//p.error_count += 1
	// TODO(Dragos): Modify this
}

parser_warn :: proc(p: ^Parser, pos: Pos, msg: string, args: ..any) {
	if p.warn != nil {
		p.warn(pos, msg, ..args)
	}
	//p.file.syntax_warning_count += 1
}

error :: proc {
	tokenizer_error,
	parser_error,
}

warn :: proc {
	parser_warn,
}

