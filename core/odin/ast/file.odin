package odin_ast

import "core:odin/tokenizer"

Package_Kind :: enum {
	Normal,
	Runtime,
	Init,
}

Package :: struct {
	kind:     Package_Kind,
	id:       int,
	name:     string,
	fullpath: string,
	files:    []^File,

	user_data: rawptr,
}

File :: struct {
	id: int,
	pkg: ^Package,

	fullpath: string,
	src:      []byte,

	pkg_decl:  ^Package_Decl,
	pkg_token: tokenizer.Token,
	pkg_name:  string,

	decls:   [dynamic]^Stmt,
	imports: [dynamic]^Import_Decl,
	directive_count: int,

	comments: [dynamic]^Comment_Group,

	syntax_warning_count: int,
	syntax_error_count:   int,
}
