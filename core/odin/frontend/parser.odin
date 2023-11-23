package odin_frontend

import "core:sync"
import "core:fmt"

import "core:intrinsics"

/*c++
struct Parser {
	String                 init_fullpath;

	StringSet              imported_files; // fullpath
	BlockingMutex          imported_files_mutex;

	Array<AstPackage *>    packages;
	BlockingMutex          packages_mutex;

	std::atomic<isize>     file_to_process_count;
	std::atomic<isize>     total_token_count;
	std::atomic<isize>     total_line_count;

	// TODO(bill): What should this mutex be per?
	//  * Parser
	//  * Package
	//  * File
	BlockingMutex          file_decl_mutex;

	BlockingMutex          file_error_mutex;
	ParseFileErrorNode *   file_error_head;
	ParseFileErrorNode *   file_error_tail;
};
*/

Parser :: struct {
	file: ^File,
	tok: Tokenizer,

	warn: Warning_Handler,
	err: Error_Handler,

	prev_tok: Token,
	curr_tok: Token,

	// >= 0: In Expression
	// <  0: In Control Clause
	// NOTE(bill): Used to prevent type literals in control clauses
	expr_level: int,
	allow_range: bool,
	allow_in_expr: bool,
	in_foreign_block: bool,
	allow_type: bool,

	lead_comment: ^Comment_Group,
	line_comment: ^Comment_Group,

	curr_proc: ^Node,

	error_count: int,
	fix_count: int,
	fix_prev_pos: Pos,

	peeking: bool,
}

MAX_FIX_COUNT :: 10

default_parser :: proc() -> Parser {
	return Parser {
		err = default_error_handler,
		warn = default_warning_handler,
	}
}

Stmt_Allow_Flag :: enum {
	In,
	Label,
}
Stmt_Allow_Flags :: distinct bit_set[Stmt_Allow_Flag]

Import_Decl_Kind :: enum {
	Standard,
	Using,
}

parse_file :: proc(p: ^Parser, file: ^File) -> bool {
	p.file = file
	
	tokenizer_init(&p.tok, file.src, file.fullpath, p.err)
	if p.tok.ch <= 0 {
		return true
	}

	advance_token(p)
	unimplemented()
}

advance_token :: proc(p: ^Parser) -> Token {
	p.lead_comment = nil
	p.line_comment = nil
	p.prev_tok = p.curr_tok
	prev := p.prev_tok
	if next_token0(p) {
		consume_comment_groups(p, prev)
	}
	return prev
}

next_token0 :: proc(p: ^Parser) -> bool {
	p.curr_tok = scan(&p.tok)
	if p.curr_tok.kind == .EOF {
		error(p, p.curr_tok.pos, "token is EOF")
		return false
	}

	return true
}

consume_comment_groups :: proc(p: ^Parser, prev: Token) {
	unimplemented()
}

consume_comment_group :: proc(p: ^Parser, n: int) -> (comments: ^Comment_Group, end_line: int) {
	unimplemented()
}