package c_frontend_preprocess

import "core:c/frontend/tokenizer"

const_expr :: proc(rest: ^^Token, tok: ^Token) -> i64 {
	// TODO(bill): Handle const_expr correctly
	// This is effectively a mini-parser

	assert(rest != nil)
	assert(tok != nil)
	rest^ = tokenizer.new_eof(tok)
	switch v in tok.val {
	case i64:
		return v
	case f64:
		return i64(v)
	case string:
		return 0
	case []u16:
		// TODO
	case []u32:
		// TODO
	}
	return 0
}
