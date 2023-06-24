package c_frontend_preprocess

import "../tokenizer"

import "core:strings"
import "core:strconv"
import "core:path/filepath"
import "core:unicode/utf8"
import "core:unicode/utf16"
import "core:os"
import "core:io"

@(private)
Tokenizer :: tokenizer.Tokenizer
@(private)
Token :: tokenizer.Token

Error_Handler :: tokenizer.Error_Handler

Macro_Param :: struct {
	next: ^Macro_Param,
	name: string,
}

Macro_Arg :: struct {
	next: ^Macro_Arg,
	name: string,
	tok: ^Token,
	is_va_args: bool,
}

Macro_Kind :: enum u8 {
	Function_Like,
	Value_Like,
}

Macro_Handler :: #type proc(^Preprocessor, ^Token) -> ^Token

Macro :: struct {
	name: string,
	kind: Macro_Kind,
	params: ^Macro_Param,
	va_args_name: string,
	body: ^Token,
	handler: Macro_Handler,
}

Cond_Incl_State :: enum u8 {
	In_Then,
	In_Elif,
	In_Else,
}

Cond_Incl :: struct {
	next: ^Cond_Incl,
	tok:  ^Token,
	state:    Cond_Incl_State,
	included: bool,
}

Pragma_Handler :: #type proc(^Preprocessor, ^Token)

Preprocessor :: struct {
	// Lookup tables
	macros:         map[string]^Macro,
	pragma_once:    map[string]bool,
	include_guards: map[string]string,
	filepath_cache: map[string]string,

	// Include path data
	include_paths: []string,

	// Counter for __COUNTER__ macro
	counter: i64,

	// Include information
	cond_incl: ^Cond_Incl,
	include_level: int,
	include_next_index: int,

	wide_char_size: int,

	// Mutable data
	err:  Error_Handler,
	warn: Error_Handler,
	pragma_handler: Pragma_Handler,
	error_count:   int,
	warning_count: int,
}

MAX_INCLUDE_LEVEL :: 1024

error :: proc(cpp: ^Preprocessor, tok: ^Token, msg: string, args: ..any) {
	if cpp.err != nil {
		cpp.err(tok.pos, msg, ..args)
	}
	cpp.error_count += 1
}

warn :: proc(cpp: ^Preprocessor, tok: ^Token, msg: string, args: ..any) {
	if cpp.warn != nil {
		cpp.warn(tok.pos, msg, ..args)
	}
	cpp.warning_count += 1
}

is_hash :: proc(tok: ^Token) -> bool {
	return tok.at_bol && tok.lit == "#"
}

skip_line :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Token {
	tok := tok
	if tok.at_bol {
		return tok
	}
	warn(cpp, tok, "extra token")
	for tok.at_bol {
		tok = tok.next
	}
	return tok
}


append_token :: proc(a, b: ^Token) -> ^Token {
	if a.kind == .EOF {
		return b
	}

	head: Token
	curr := &head

	for tok := a; tok.kind != .EOF; tok = tok.next {
		curr.next = tokenizer.copy_token(tok)
		curr = curr.next
	}
	curr.next = b
	return head.next
}


is_hex_digit :: proc(x: byte) -> bool {
	switch x {
	case '0'..='9', 'a'..='f', 'A'..='F':
		return true
	}
	return false
}
from_hex :: proc(x: byte) -> i32 {
	switch x {
	case '0'..='9':
		return i32(x) - '0'
	case 'a'..='f':
		return i32(x) - 'a' + 10
	case 'A'..='F':
		return i32(x) - 'A' + 10
	}
	return 16
}


convert_pp_number :: proc(tok: ^Token) {
	convert_pp_int :: proc(tok: ^Token) -> bool {
		p := tok.lit
		base := 10
		if len(p) > 2 {
			if strings.equal_fold(p[:2], "0x") && is_hex_digit(p[2]) {
				p = p[2:]
				base = 16
			} else if strings.equal_fold(p[:2], "0b") && p[2] == '0' || p[2] == '1' {
				p = p[2:]
				base = 2
			}
		}
		if base == 10 && p[0] == '0' {
			base = 8
		}


		tok.val, _ = strconv.parse_i64_of_base(p, base)

		l, u: int

		suf: [3]byte
		suf_n := 0
		i := len(p)-1
		for /**/; i >= 0 && suf_n < len(suf); i -= 1 {
			switch p[i] {
			case 'l', 'L':
				suf[suf_n] = 'l'
				l += 1
				suf_n += 1
			case 'u', 'U':
				suf[suf_n] = 'u'
				u += 1
				suf_n += 1
			}
		}
		if i < len(p) {
			if !is_hex_digit(p[i]) && p[i] != '.' {
				return false
			}
		}
		if u > 1 {
			return false
		}

		if l > 2 {
			return false
		}

		if u == 1 {
			switch l {
			case 0: tok.type_hint = .Unsigned_Int
			case 1: tok.type_hint = .Unsigned_Long
			case 2: tok.type_hint = .Unsigned_Long_Long
			}
		} else {
			switch l {
			case 0: tok.type_hint = .Int
			case 1: tok.type_hint = .Long
			case 2: tok.type_hint = .Long_Long
			}
		}
		return true
	}

	if convert_pp_int(tok) {
		return
	}

	fval, _ := strconv.parse_f64(tok.lit)
	tok.val = fval

	end := tok.lit[len(tok.lit)-1]
	switch end {
	case 'f', 'F':
		tok.type_hint = .Float
	case 'l', 'L':
		tok.type_hint = .Long_Double
	case:
		tok.type_hint = .Double
	}

}

convert_pp_char :: proc(tok: ^Token) {
	assert(len(tok.lit) >= 2)
	r, _, _, _ := unquote_char(tok.lit, tok.lit[0])
	tok.val = i64(r)

	tok.type_hint = .Int
	switch tok.prefix {
	case "u": tok.type_hint = .UTF_16
	case "U": tok.type_hint = .UTF_32
	case "L": tok.type_hint = .UTF_Wide
	}
}

wide_char_size :: proc(cpp: ^Preprocessor) -> int {
	char_size := 4
	if cpp.wide_char_size > 0 {
		char_size = clamp(cpp.wide_char_size, 1, 4)
		assert(char_size & (char_size-1) == 0)
	}
	return char_size
}

convert_pp_string :: proc(cpp: ^Preprocessor, tok: ^Token) {
	assert(len(tok.lit) >= 2)
	str, _, _ := unquote_string(tok.lit)
	tok.val = str

	char_size := 1

	switch tok.prefix {
	case "u8":
		tok.type_hint = .UTF_8
		char_size = 1
	case "u":
		tok.type_hint = .UTF_16
		char_size = 2
	case "U":
		tok.type_hint = .UTF_32
		char_size = 4
	case "L":
		tok.type_hint = .UTF_Wide
		char_size = wide_char_size(cpp)
	}

	switch char_size {
	case 2:
		n: int
		buf := make([]u16, len(str))
		for c in str {
			ch := c
			if ch < 0x10000 {
				buf[n] = u16(ch)
				n += 1
			} else {
				ch -= 0x10000
				buf[n+0] = 0xd800 + u16((ch >> 10) & 0x3ff)
				buf[n+1] = 0xdc00 + u16(ch & 0x3ff)
				n += 2
			}
		}
		tok.val = buf[:n]
	case 4:
		n: int
		buf := make([]u32, len(str))
		for ch in str {
			buf[n] = u32(ch)
			n += 1
		}
		tok.val = buf[:n]
	}

}

convert_pp_token :: proc(cpp: ^Preprocessor, t: ^Token, is_keyword: tokenizer.Is_Keyword_Proc) {
	switch {
	case t.kind == .Char:
		convert_pp_char(t)
	case t.kind == .String:
		convert_pp_string(cpp, t)
	case is_keyword != nil && is_keyword(t):
		t.kind = .Keyword
	case t.kind == .PP_Number:
		convert_pp_number(t)
	}
}
convert_pp_tokens :: proc(cpp: ^Preprocessor, tok: ^Token, is_keyword: tokenizer.Is_Keyword_Proc) {
	for t := tok; t != nil && t.kind != .EOF; t = t.next {
		convert_pp_token(cpp, tok, is_keyword)
	}
}

join_adjacent_string_literals :: proc(cpp: ^Preprocessor, initial_tok: ^Token) {
	for tok1 := initial_tok; tok1.kind != .EOF; /**/ {
		if tok1.kind != .String || tok1.next.kind != .String {
			tok1 = tok1.next
			continue
		}

		type_hint := tokenizer.Token_Type_Hint.None
		char_size := 1

		start := tok1
		for t := tok1; t != nil && t.kind == .String; t = t.next {
			if t.val == nil {
				convert_pp_string(cpp, t)
			}
			tok1 = t.next
			if type_hint != t.type_hint {
				if t.type_hint != .None && type_hint != .None {
					error(cpp, t, "unsupported non-standard concatenation of string literals of different types")
				}
				prev_char_size := char_size

				#partial switch type_hint {
				case .UTF_8:    char_size = max(char_size, 1)
				case .UTF_16:   char_size = max(char_size, 2)
				case .UTF_32:   char_size = max(char_size, 4)
				case .UTF_Wide: char_size = max(char_size, wide_char_size(cpp))
				}

				if type_hint == .None || prev_char_size < char_size {
					type_hint = t.type_hint
				}
			}
		}

		// NOTE(bill): Verbose logic in order to correctly concantenate strings, even if they different in type
		max_len := 0
		switch char_size {
		case 1:
			for t := start; t != nil && t.kind == .String; t = t.next {
				#partial switch v in t.val {
				case string: max_len += len(v)
				case []u16:  max_len += 2*len(v)
				case []u32:  max_len += 4*len(v)
				}
			}
			n := 0
			buf := make([]byte, max_len)
			for t := start; t != nil && t.kind == .String; t = t.next {
				#partial switch v in t.val {
				case string:
					n += copy(buf[n:], v)
				case []u16:
					for i := 0; i < len(v); /**/ {
						c1 := v[i]
						r: rune
						if !utf16.is_surrogate(rune(c1)) {
							r = rune(c1)
							i += 1
						} else if i+1 == len(v) {
							r = utf16.REPLACEMENT_CHAR
							i += 1
						} else {
							c2 := v[i+1]
							i += 2
							r = utf16.decode_surrogate_pair(rune(c1), rune(c2))
						}

						b, w := utf8.encode_rune(r)
						n += copy(buf[n:], b[:w])
					}
				case []u32:
					for r in v {
						b, w := utf8.encode_rune(rune(r))
						n += copy(buf[n:], b[:w])
					}
				}
			}

			new_tok := tokenizer.copy_token(start)
			new_tok.lit = ""
			new_tok.val = string(buf[:n])
			new_tok.next = tok1
			new_tok.type_hint = type_hint
			start^ = new_tok^
		case 2:
			for t := start; t != nil && t.kind == .String; t = t.next {
				#partial switch v in t.val {
				case string: max_len += len(v)
				case []u16:  max_len += len(v)
				case []u32:  max_len += 2*len(v)
				}
			}
			n := 0
			buf := make([]u16, max_len)
			for t := start; t != nil && t.kind == .String; t = t.next {
				#partial switch v in t.val {
				case string:
					for r in v {
						if r >= 0x10000 {
							c1, c2 := utf16.encode_surrogate_pair(r)
							buf[n+0] = u16(c1)
							buf[n+1] = u16(c2)
							n += 2
						} else {
							buf[n] = u16(r)
							n += 1
						}
					}
				case []u16:
					n += copy(buf[n:], v)
				case []u32:
					for r in v {
						if r >= 0x10000 {
							c1, c2 := utf16.encode_surrogate_pair(rune(r))
							buf[n+0] = u16(c1)
							buf[n+1] = u16(c2)
							n += 2
						} else {
							buf[n] = u16(r)
							n += 1
						}
					}
				}
			}

			new_tok := tokenizer.copy_token(start)
			new_tok.lit = ""
			new_tok.val = buf[:n]
			new_tok.next = tok1
			new_tok.type_hint = type_hint
			start^ = new_tok^
		case 4:
			for t := start; t != nil && t.kind == .String; t = t.next {
				#partial switch v in t.val {
				case string: max_len += len(v)
				case []u16:  max_len += len(v)
				case []u32:  max_len += len(v)
				}
			}
			n := 0
			buf := make([]u32, max_len)
			for t := start; t != nil && t.kind == .String; t = t.next {
				#partial switch v in t.val {
				case string:
					for r in v {
						buf[n] = u32(r)
						n += 1
					}
				case []u16:
					for i := 0; i < len(v); /**/ {
						c1 := v[i]
						if !utf16.is_surrogate(rune(c1)) {
							buf[n] = u32(c1)
							n += 1
							i += 1
						} else if i+1 == len(v) {
							buf[n] = utf16.REPLACEMENT_CHAR
							n += 1
							i += 1
						} else {
							c2 := v[i+1]
							i += 2
							r := utf16.decode_surrogate_pair(rune(c1), rune(c2))
							buf[n] = u32(r)
							n += 1
						}
					}
				case []u32:
					n += copy(buf[n:], v)
				}
			}

			new_tok := tokenizer.copy_token(start)
			new_tok.lit = ""
			new_tok.val = buf[:n]
			new_tok.next = tok1
			new_tok.type_hint = type_hint
			start^ = new_tok^
		}
	}
}


quote_string :: proc(s: string) -> []byte {
	b := strings.builder_make(0, len(s)+2)
	io.write_quoted_string(strings.to_writer(&b), s, '"')
	return b.buf[:]
}


_init_tokenizer_from_preprocessor :: proc(t: ^Tokenizer, cpp: ^Preprocessor) -> ^Tokenizer {
	t.warn = cpp.warn
	t.err = cpp.err
	return t
}

new_string_token :: proc(cpp: ^Preprocessor, str: string, tok: ^Token) -> ^Token {
	assert(tok != nil)
	assert(str != "")
	t := _init_tokenizer_from_preprocessor(&Tokenizer{}, cpp)
	src := quote_string(str)
	return tokenizer.inline_tokenize(t, tok, src)
}

stringize :: proc(cpp: ^Preprocessor, hash, arg: ^Token) -> ^Token {
	s := join_tokens(arg, nil)
	return new_string_token(cpp, s, hash)
}


new_number_token :: proc(cpp: ^Preprocessor, i: i64, tok: ^Token) -> ^Token {
	t := _init_tokenizer_from_preprocessor(&Tokenizer{}, cpp)
	buf: [32]byte
	n := len(strconv.append_int(buf[:], i, 10))
	src := make([]byte, n)
	copy(src, buf[:n])
	return tokenizer.inline_tokenize(t, tok, src)
}


find_macro :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Macro {
	if tok.kind != .Ident {
		return nil
	}
	return cpp.macros[tok.lit]
}

add_macro :: proc(cpp: ^Preprocessor, name: string, kind: Macro_Kind, body: ^Token) -> ^Macro {
	m := new(Macro)
	m.name = name
	m.kind = kind
	m.body = body
	cpp.macros[name] = m
	return m
}


undef_macro :: proc(cpp: ^Preprocessor, name: string) {
	delete_key(&cpp.macros, name)
}

add_builtin :: proc(cpp: ^Preprocessor, name: string, handler: Macro_Handler) -> ^Macro {
	m := add_macro(cpp, name, .Value_Like, nil)
	m.handler = handler
	return m
}


skip :: proc(cpp: ^Preprocessor, tok: ^Token, op: string) -> ^Token {
	if tok.lit != op {
		error(cpp, tok, "expected '%q'", op)
	}
	return tok.next
}

consume :: proc(rest: ^^Token, tok: ^Token, lit: string) -> bool {
	if tok.lit == lit {
		rest^ = tok.next
		return true
	}
	rest^ = tok
	return false
}

read_macro_params :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) -> (param: ^Macro_Param, va_args_name: string) {
	head: Macro_Param
	curr := &head

	tok := tok
	for tok.lit != ")" && tok.kind != .EOF {
		if curr != &head {
			tok = skip(cpp, tok, ",")
		}

		if tok.lit == "..." {
			va_args_name = "__VA_ARGS__"
			rest^ = skip(cpp, tok.next, ")")
			param = head.next
			return
		}

		if tok.kind != .Ident {
			error(cpp, tok, "expected an identifier")
		}

		if tok.next.lit == "..." {
			va_args_name = tok.lit
			rest^ = skip(cpp, tok.next.next, ")")
			param = head.next
			return
		}

		m := new(Macro_Param)
		m.name = tok.lit
		curr.next = m
		curr = curr.next
		tok = tok.next
	}


	rest^ = tok.next
	param = head.next
	return
}

copy_line :: proc(rest: ^^Token, tok: ^Token) -> ^Token {
	head: Token
	curr := &head

	tok := tok
	for ; !tok.at_bol; tok = tok.next {
		curr.next = tokenizer.copy_token(tok)
		curr = curr.next
	}
	curr.next = tokenizer.new_eof(tok)
	rest^ = tok
	return head.next
}

read_macro_definition :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) {
	tok := tok
	if tok.kind != .Ident {
		error(cpp, tok, "macro name must be an identifier")
	}
	name := tok.lit
	tok = tok.next

	if !tok.has_space && tok.lit == "(" {
		params, va_args_name := read_macro_params(cpp, &tok, tok.next)

		m := add_macro(cpp, name, .Function_Like, copy_line(rest, tok))
		m.params = params
		m.va_args_name = va_args_name
	} else {
		add_macro(cpp, name, .Value_Like, copy_line(rest, tok))
	}
}


join_tokens :: proc(tok, end: ^Token) -> string {
	n := 1
	for t := tok; t != end && t.kind != .EOF; t = t.next {
		if t != tok && t.has_space {
			n += 1
		}
		n += len(t.lit)
	}

	buf := make([]byte, n)

	pos := 0
	for t := tok; t != end && t.kind != .EOF; t = t.next {
		if t != tok && t.has_space {
			buf[pos] = ' '
			pos += 1
		}
		copy(buf[pos:], t.lit)
		pos += len(t.lit)
	}

	return string(buf[:pos])
}

read_include_filename :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) -> (filename: string, is_quote: bool) {
	tok := tok

	if tok.kind == .String {
		rest^ = skip_line(cpp, tok.next)
		filename = tok.lit[1:len(tok.lit)-1]
		is_quote = true
		return
	}

	if tok.lit == "<" {
		start := tok
		for ; tok.kind != .EOF; tok = tok.next {
			if tok.at_bol || tok.kind == .EOF {
				error(cpp, tok, "expected '>'")
			}
			is_quote = false
			if tok.lit == ">" {
				break
			}
		}
		rest^ = skip_line(cpp, tok.next)
		filename = join_tokens(start.next, tok)
		return
	}

	if tok.kind == .Ident {
		tok2 := preprocess_internal(cpp, copy_line(rest, tok))
		return read_include_filename(cpp, &tok2, tok2)
	}

	error(cpp, tok, "expected a filename")
	return
}

skip_cond_incl :: proc(tok: ^Token) -> ^Token {
	next_skip :: proc(tok: ^Token) -> ^Token {
		tok := tok
		for tok.kind != .EOF {
			if is_hash(tok) {
				switch tok.next.lit {
				case "if", "ifdef", "ifndef":
					tok = next_skip(tok.next.next)
					continue

				case "endif":
					return tok.next.next
				}
			}
			tok = tok.next
		}
		return tok
	}

	tok := tok

	loop: for tok.kind != .EOF {
		if is_hash(tok) {
			switch tok.next.lit {
			case "if", "ifdef", "ifndef":
				tok = next_skip(tok.next.next)
				continue loop

			case "elif", "else", "endif":
				break loop
			}
		}

		tok = tok.next
	}
	return tok
}

check_for_include_guard :: proc(tok: ^Token) -> (guard: string, ok: bool) {
	if !is_hash(tok) || tok.next.lit != "ifndef" {
		return
	}
	tok := tok
	tok = tok.next.next

	if tok.kind != .Ident {
		return
	}

	m := tok.lit
	tok = tok.next

	if !is_hash(tok) || tok.next.lit != "define" || tok.next.lit != "macro" {
		return
	}

	for tok.kind != .EOF {
		if !is_hash(tok) {
			tok = tok.next
			continue
		}

		if tok.next.lit == "endif" && tok.next.next.kind == .EOF {
			return m, true
		}

		switch tok.lit {
		case "if", "ifdef", "ifndef":
			tok = skip_cond_incl(tok.next)
		case:
			tok = tok.next
		}
	}
	return
}

include_file :: proc(cpp: ^Preprocessor, tok: ^Token, path: string, filename_tok: ^Token) -> ^Token {
	if cpp.pragma_once[path] {
		return tok
	}

	guard_name, guard_name_found := cpp.include_guards[path]
	if guard_name_found && cpp.macros[guard_name] != nil {
		return tok
	}

	if !os.exists(path) {
		error(cpp, filename_tok, "%s: cannot open file", path)
		return tok
	}

	cpp.include_level += 1
	if cpp.include_level > MAX_INCLUDE_LEVEL {
		error(cpp, tok, "exceeded maximum nest amount: %d", MAX_INCLUDE_LEVEL)
		return tok
	}

	t := _init_tokenizer_from_preprocessor(&Tokenizer{}, cpp)
	tok2 := tokenizer.tokenize_file(t, path, /*file.id*/1)
	if tok2 == nil {
		error(cpp, filename_tok, "%s: cannot open file", path)
	}
	cpp.include_level -= 1

	guard_name, guard_name_found = check_for_include_guard(tok2)
	if guard_name_found {
		cpp.include_guards[path] = guard_name
	}

	return append_token(tok2, tok)
}

find_arg :: proc(args: ^Macro_Arg, tok: ^Token) -> ^Macro_Arg {
	for ap := args; ap != nil; ap = ap.next {
		if tok.lit == ap.name {
			return ap
		}
	}
	return nil
}

paste :: proc(cpp: ^Preprocessor, lhs, rhs: ^Token) -> ^Token {
	buf := strings.concatenate({lhs.lit, rhs.lit})
	t := _init_tokenizer_from_preprocessor(&Tokenizer{}, cpp)
	tok := tokenizer.inline_tokenize(t, lhs, transmute([]byte)buf)
	if tok.next.kind != .EOF {
		error(cpp, lhs, "pasting forms '%s', an invalid token", buf)
	}
	return tok
}

has_varargs :: proc(args: ^Macro_Arg) -> bool {
	for ap := args; ap != nil; ap = ap.next {
		if ap.name == "__VA_ARGS__" {
			return ap.tok.kind != .EOF
		}
	}
	return false
}

substitute_token :: proc(cpp: ^Preprocessor, tok: ^Token, args: ^Macro_Arg) -> ^Token {
	head: Token
	curr := &head
	tok := tok
	for tok.kind != .EOF {
		if tok.lit == "#" {
			arg := find_arg(args, tok.next)
			if arg == nil {
				error(cpp, tok.next, "'#' is not followed by a macro parameter")
			}
			arg_tok := arg.tok if arg != nil else tok.next
			curr.next = stringize(cpp, tok, arg_tok)
			curr = curr.next
			tok = tok.next.next
			continue
		}

		if tok.lit == "," && tok.next.lit == "##" {
			if arg := find_arg(args, tok.next.next); arg != nil && arg.is_va_args {
				if arg.tok.kind == .EOF {
					tok = tok.next.next.next
				} else {
					curr.next = tokenizer.copy_token(tok)
					curr = curr.next
					tok = tok.next.next
				}
				continue
			}
		}

		if tok.lit == "##" {
			if curr == &head {
				error(cpp, tok, "'##' cannot appear at start of macro expansion")
			}
			if tok.next.kind == .EOF {
				error(cpp, tok, "'##' cannot appear at end of macro expansion")
			}

			if arg := find_arg(args, tok.next); arg != nil {
				if arg.tok.kind != .EOF {
					curr^ = paste(cpp, curr, arg.tok)^
					for t := arg.tok.next; t.kind != .EOF; t = t.next {
						curr.next = tokenizer.copy_token(t)
						curr = curr.next
					}
				}
				tok = tok.next.next
				continue
			}

			curr^ = paste(cpp, curr, tok.next)^
			tok = tok.next.next
			continue
		}

		arg := find_arg(args, tok)

		if arg != nil && tok.next.lit == "##" {
			rhs := tok.next.next

			if arg.tok.kind == .EOF {
				args2 := find_arg(args, rhs)
				if args2 != nil {
					for t := args.tok; t.kind != .EOF; t = t.next {
						curr.next = tokenizer.copy_token(t)
						curr = curr.next
					}
				} else {
					curr.next = tokenizer.copy_token(rhs)
					curr = curr.next
				}
				tok = rhs.next
				continue
			}

			for t := arg.tok; t.kind != .EOF; t = t.next {
				curr.next = tokenizer.copy_token(t)
				curr = curr.next
			}
			tok = tok.next
			continue
		}

		if tok.lit == "__VA_OPT__" && tok.next.lit == "(" {
			opt_arg := read_macro_arg_one(cpp, &tok, tok.next.next, true)
			if has_varargs(args) {
				for t := opt_arg.tok; t.kind != .EOF; t = t.next {
					curr.next = t
					curr = curr.next
				}
			}
			tok = skip(cpp, tok, ")")
			continue
		}

		if arg != nil {
			t := preprocess_internal(cpp, arg.tok)
			t.at_bol = tok.at_bol
			t.has_space = tok.has_space
			for ; t.kind != .EOF; t = t.next {
				curr.next = tokenizer.copy_token(t)
				curr = curr.next
			}
			tok = tok.next
			continue
		}

		curr.next = tokenizer.copy_token(tok)
		curr = curr.next
		tok = tok.next
		continue
	}

	curr.next = tok
	return head.next
}

read_macro_arg_one :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token, read_rest: bool) -> ^Macro_Arg {
	tok := tok
	head: Token
	curr := &head
	level := 0
	for {
		if level == 0 && tok.lit == ")" {
			break
		}
		if level == 0 && !read_rest && tok.lit == "," {
			break
		}

		if tok.kind == .EOF {
			error(cpp, tok, "premature end of input")
		}

		switch tok.lit {
		case "(": level += 1
		case ")": level -= 1
		}

		curr.next = tokenizer.copy_token(tok)
		curr = curr.next
		tok = tok.next
	}
	curr.next = tokenizer.new_eof(tok)

	arg := new(Macro_Arg)
	arg.tok = head.next
	rest^ = tok
	return arg
}

read_macro_args :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token, params: ^Macro_Param, va_args_name: string) -> ^Macro_Arg {
	tok := tok
	start := tok
	tok = tok.next.next

	head: Macro_Arg
	curr := &head

	pp := params
	for ; pp != nil; pp = pp.next {
		if curr != &head {
			tok = skip(cpp, tok, ",")
		}
		curr.next = read_macro_arg_one(cpp, &tok, tok, false)
		curr = curr.next
		curr.name = pp.name
	}

	if va_args_name != "" {
		arg: ^Macro_Arg
		if tok.lit == ")" {
			arg = new(Macro_Arg)
			arg.tok = tokenizer.new_eof(tok)
		} else {
			if pp != params {
				tok = skip(cpp, tok, ",")
			}
			arg = read_macro_arg_one(cpp, &tok, tok, true)
		}
		arg.name = va_args_name
		arg.is_va_args = true
		curr.next = arg
		curr = curr.next
	} else if pp != nil {
		error(cpp, start, "too many arguments")
	}

	skip(cpp, tok, ")")
	rest^ = tok
	return head.next
}

expand_macro :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) -> bool {
	if tokenizer.hide_set_contains(tok.hide_set, tok.lit) {
		return false
	}
	tok := tok
	m := find_macro(cpp, tok)
	if m == nil {
		return false
	}

	if m.handler != nil {
		rest^ = m.handler(cpp, tok)
		rest^.next = tok.next
		return true
	}

	if m.kind == .Value_Like {
		hs := tokenizer.hide_set_union(tok.hide_set, tokenizer.new_hide_set(m.name))
		body := tokenizer.add_hide_set(m.body, hs)
		for t := body; t.kind != .EOF; t = t.next {
			t.origin = tok
		}
		rest^ = append_token(body, tok.next)
		rest^.at_bol = tok.at_bol
		rest^.has_space = tok.has_space
		return true
	}

	if tok.next.lit != "(" {
		return false
	}

	macro_token := tok
	args := read_macro_args(cpp, &tok, tok, m.params, m.va_args_name)
	close_paren := tok

	hs := tokenizer.hide_set_intersection(macro_token.hide_set, close_paren.hide_set)
	hs = tokenizer.hide_set_union(hs, tokenizer.new_hide_set(m.name))

	body := substitute_token(cpp, m.body, args)
	body = tokenizer.add_hide_set(body, hs)
	for t := body; t.kind != .EOF; t = t.next {
		t.origin = macro_token
	}
	rest^ = append_token(body, tok.next)
	rest^.at_bol = macro_token.at_bol
	rest^.has_space = macro_token.has_space
	return true
}

search_include_next :: proc(cpp: ^Preprocessor, filename: string) -> (path: string, ok: bool) {
	for ; cpp.include_next_index < len(cpp.include_paths); cpp.include_next_index += 1 {
		tpath := filepath.join({cpp.include_paths[cpp.include_next_index], filename}, allocator=context.temp_allocator)
		if os.exists(tpath) {
			return strings.clone(tpath), true
		}
	}
	return
}

search_include_paths :: proc(cpp: ^Preprocessor, filename: string) -> (path: string, ok: bool) {
	if filepath.is_abs(filename) {
		return filename, true
	}

	if path, ok = cpp.filepath_cache[filename]; ok {
		return
	}

	for include_path in cpp.include_paths {
		tpath := filepath.join({include_path, filename}, allocator=context.temp_allocator)
		if os.exists(tpath) {
			path, ok = strings.clone(tpath), true
			cpp.filepath_cache[filename] = path
			return
		}
	}

	return
}

read_const_expr :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) -> ^Token {
	tok := tok
	tok = copy_line(rest, tok)
	head: Token
	curr := &head
	for tok.kind != .EOF {
		if tok.lit == "defined" {
			start := tok
			has_paren := consume(&tok, tok.next, "(")
			if tok.kind != .Ident {
				error(cpp, start, "macro name must be an identifier")
			}
			m := find_macro(cpp, tok)
			tok = tok.next

			if has_paren {
				tok = skip(cpp, tok, ")")
			}

			curr.next = new_number_token(cpp, 1 if m != nil else 0, start)
			curr = curr.next
			continue
		}

		curr.next = tok
		curr = curr.next
		tok = tok.next
	}

	curr.next = tok
	return head.next
}

eval_const_expr :: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) -> (val: i64) {
	tok := tok
	start := tok
	expr := read_const_expr(cpp, rest, tok.next)
	expr = preprocess_internal(cpp, expr)

	if expr.kind == .EOF {
		error(cpp, start, "no expression")
	}

	for t := expr; t.kind != .EOF; t = t.next {
		if t.kind == .Ident {
			next := t.next
			t^ = new_number_token(cpp, 0, t)^
			t.next = next
		}
	}

	val = 1
	convert_pp_tokens(cpp, expr, tokenizer.default_is_keyword)

	rest2: ^Token
	val = const_expr(&rest2, expr)
	if rest2 != nil && rest2.kind != .EOF {
		error(cpp, rest2, "extra token")
	}
	return
}

push_cond_incl :: proc(cpp: ^Preprocessor, tok: ^Token, included: bool) -> ^Cond_Incl {
	ci := new(Cond_Incl)
	ci.next = cpp.cond_incl
	ci.state = .In_Then
	ci.tok = tok
	ci.included = included
	cpp.cond_incl = ci
	return ci
}

read_line_marker:: proc(cpp: ^Preprocessor, rest: ^^Token, tok: ^Token) {
	tok := tok
	start := tok
	tok = preprocess(cpp, copy_line(rest, tok))
	if tok.kind != .Number {
		error(cpp, tok, "invalid line marker")
	}
	ival, _ := tok.val.(i64)
	start.file.line_delta = int(ival - i64(start.pos.line))
	tok = tok.next
	if tok.kind == .EOF {
		return
	}

	if tok.kind != .String {
		error(cpp, tok, "filename expected")
	}
	start.file.display_name = tok.lit
}

preprocess_internal :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Token {
	head: Token
	curr := &head

	tok := tok
	for tok != nil && tok.kind != .EOF {
		if expand_macro(cpp, &tok, tok) {
			continue
		}

		if !is_hash(tok) {
			if tok.file != nil {
				tok.line_delta = tok.file.line_delta
			}
			curr.next = tok
			curr = curr.next
			tok = tok.next
			continue
		}

		start := tok
		tok = tok.next

		switch tok.lit {
		case "include":
			filename, is_quote := read_include_filename(cpp, &tok, tok.next)
			is_absolute := filepath.is_abs(filename)
			if is_absolute {
				tok = include_file(cpp, tok, filename, start.next.next)
				continue
			}

			if is_quote {
				dir := ""
				if start.file != nil {
					dir = filepath.dir(start.file.name)
				}
				path := filepath.join({dir, filename})
				if os.exists(path) {
					tok = include_file(cpp, tok, path, start.next.next)
					continue
				}
			}

			path, ok := search_include_paths(cpp, filename)
			if !ok {
				path = filename
			}
			tok = include_file(cpp, tok, path, start.next.next)
			continue

		case "include_next":
			filename, _ := read_include_filename(cpp, &tok, tok.next)
			path, ok := search_include_next(cpp, filename)
			if !ok {
				path = filename
			}
			tok = include_file(cpp, tok, path, start.next.next)
			continue

		case "define":
			read_macro_definition(cpp, &tok, tok.next)
			continue

		case "undef":
			tok = tok.next
			if tok.kind != .Ident {
				error(cpp, tok, "macro name must be an identifier")
			}
			undef_macro(cpp, tok.lit)
			tok = skip_line(cpp, tok.next)
			continue

		case "if":
			val := eval_const_expr(cpp, &tok, tok)
			push_cond_incl(cpp, start, val != 0)
			if val == 0 {
				tok = skip_cond_incl(tok)
			}
			continue

		case "ifdef":
			defined := find_macro(cpp, tok.next)
			push_cond_incl(cpp, tok, defined != nil)
			tok = skip_line(cpp, tok.next.next)
			if defined == nil {
				tok = skip_cond_incl(tok)
			}
			continue

		case "ifndef":
			defined := find_macro(cpp, tok.next)
			push_cond_incl(cpp, tok, defined != nil)
			tok = skip_line(cpp, tok.next.next)
			if !(defined == nil) {
				tok = skip_cond_incl(tok)
			}
			continue

		case "elif":
			if cpp.cond_incl == nil || cpp.cond_incl.state == .In_Else {
				error(cpp, start, "stray #elif")
			}
			if cpp.cond_incl != nil {
				cpp.cond_incl.state = .In_Elif
			}

			if (cpp.cond_incl != nil && !cpp.cond_incl.included) && eval_const_expr(cpp, &tok, tok) != 0 {
				cpp.cond_incl.included = true
			} else {
				tok = skip_cond_incl(tok)
			}
			continue

		case "else":
			if cpp.cond_incl == nil || cpp.cond_incl.state == .In_Else {
				error(cpp, start, "stray #else")
			}
			if cpp.cond_incl != nil {
				cpp.cond_incl.state = .In_Else
			}
			tok = skip_line(cpp, tok.next)

			if cpp.cond_incl != nil {
				tok = skip_cond_incl(tok)
			}
			continue

		case "endif":
			if cpp.cond_incl == nil {
				error(cpp, start, "stray #endif")
			} else {
				cpp.cond_incl = cpp.cond_incl.next
			}
			tok = skip_line(cpp, tok.next)
			continue

		case "line":
			read_line_marker(cpp, &tok, tok.next)
			continue

		case "pragma":
			if tok.next.lit == "once" {
				cpp.pragma_once[tok.pos.file] = true
				tok = skip_line(cpp, tok.next.next)
				continue
			}

			pragma_tok, pragma_end := tok, tok

			for tok != nil && tok.kind != .EOF {
				pragma_end = tok
				tok = tok.next
				if tok.at_bol {
					break
				}
			}
			pragma_end.next = tokenizer.new_eof(tok)
			if cpp.pragma_handler != nil {
				cpp.pragma_handler(cpp, pragma_tok.next)
				continue
			}

			continue

		case "error":
			error(cpp, tok, "error")
		}

		if tok.kind == .PP_Number {
			read_line_marker(cpp, &tok, tok)
			continue
		}

		if !tok.at_bol {
			error(cpp, tok, "invalid preprocessor directive")
		}
	}

	curr.next = tok
	return head.next
}


preprocess :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Token {
	tok := tok
	tok = preprocess_internal(cpp, tok)
	if cpp.cond_incl != nil {
		error(cpp, tok, "unterminated conditional directive")
	}
	convert_pp_tokens(cpp, tok, tokenizer.default_is_keyword)
	join_adjacent_string_literals(cpp, tok)
	for t := tok; t != nil; t = t.next {
		t.pos.line += t.line_delta
	}
	return tok
}


define_macro :: proc(cpp: ^Preprocessor, name, def: string) {
	src := transmute([]byte)def

	file := new(tokenizer.File)
	file.id = -1
	file.src = src
	file.name = "<built-in>"
	file.display_name = file.name


	t := _init_tokenizer_from_preprocessor(&Tokenizer{}, cpp)
	tok := tokenizer.tokenize(t, file)
	add_macro(cpp, name, .Value_Like, tok)
}


file_macro :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Token {
	tok := tok
	for tok.origin != nil {
		tok = tok.origin
	}
	i := i64(tok.pos.line + tok.file.line_delta)
	return new_number_token(cpp, i, tok)
}
line_macro :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Token {
	tok := tok
	for tok.origin != nil {
		tok = tok.origin
	}
	return new_string_token(cpp, tok.file.display_name, tok)
}
counter_macro :: proc(cpp: ^Preprocessor, tok: ^Token) -> ^Token {
	i := cpp.counter
	cpp.counter += 1
	return new_number_token(cpp, i, tok)
}

init_default_macros :: proc(cpp: ^Preprocessor) {
	define_macro(cpp, "__C99_MACRO_WITH_VA_ARGS", "1")
	define_macro(cpp, "__alignof__", "_Alignof")
	define_macro(cpp, "__const__", "const")
	define_macro(cpp, "__inline__", "inline")
	define_macro(cpp, "__signed__", "signed")
	define_macro(cpp, "__typeof__", "typeof")
	define_macro(cpp, "__volatile__", "volatile")

	add_builtin(cpp, "__FILE__", file_macro)
	add_builtin(cpp, "__LINE__", line_macro)
	add_builtin(cpp, "__COUNTER__", counter_macro)
}

init_lookup_tables :: proc(cpp: ^Preprocessor, allocator := context.allocator) {
	context.allocator = allocator
	reserve(&cpp.macros,         max(16, cap(cpp.macros)))
	reserve(&cpp.pragma_once,    max(16, cap(cpp.pragma_once)))
	reserve(&cpp.include_guards, max(16, cap(cpp.include_guards)))
	reserve(&cpp.filepath_cache, max(16, cap(cpp.filepath_cache)))
}


init_defaults :: proc(cpp: ^Preprocessor, lookup_tables_allocator := context.allocator) {
	if cpp.warn == nil {
		cpp.warn = tokenizer.default_warn_handler
	}
	if cpp.err == nil {
		cpp.err = tokenizer.default_error_handler
	}
	init_lookup_tables(cpp, lookup_tables_allocator)
	init_default_macros(cpp)
}
