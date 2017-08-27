#import "fmt.odin";
#import "os.odin";
#import "utf8.odin";
#import win32 "sys/windows.odin";

alloc_ucs2_to_utf8 :: proc(wstr: ^u16) -> string {
	wstr_len := 0;
	for (wstr+wstr_len)^ != 0 {
		wstr_len++;
	}
	len := 2*wstr_len-1;
	buf := new_slice(byte, len+1);
	str := slice_ptr(wstr, wstr_len+1);


	i, j := 0, 0;
	for str[j] != 0 {
		match {
		case str[j] < 0x80:
			if i+1 > len {
				return "";
			}
			buf[i] = cast(byte)str[j]; i++;
			j++;
		case str[j] < 0x800:
			if i+2 > len {
				return "";
			}
			buf[i] = cast(byte)(0xc0 + (str[j]>>6));   i++;
			buf[i] = cast(byte)(0x80 + (str[j]&0x3f)); i++;
			j++;
		case 0xd800 <= str[j] && str[j] < 0xdc00:
			if i+4 > len {
				return "";
			}
			c := cast(rune)((str[j] - 0xd800) << 10) + cast(rune)((str[j+1]) - 0xdc00) + 0x10000;
			buf[i] = cast(byte)(0xf0 +  (c >> 18));         i++;
			buf[i] = cast(byte)(0x80 + ((c >> 12) & 0x3f)); i++;
			buf[i] = cast(byte)(0x80 + ((c >>  6) & 0x3f)); i++;
			buf[i] = cast(byte)(0x80 + ((c      ) & 0x3f)); i++;
			j += 2;
		case 0xdc00 <= str[j] && str[j] < 0xe000:
			return "";
		default:
			if i+3 > len {
				return "";
			}
			buf[i] = 0xe0 + cast(byte) (str[j] >> 12);         i++;
			buf[i] = 0x80 + cast(byte)((str[j] >>  6) & 0x3f); i++;
			buf[i] = 0x80 + cast(byte)((str[j]      ) & 0x3f); i++;
			j++;
		}
	}

	return cast(string)buf[..i];
}

is_whitespace :: proc(b: byte) -> bool {
	match b {
	case ' ', '\t', '\n', '\r', '\v', '\f':
		return true;
	}
	return false;
}

is_letter :: proc(b: byte) -> bool {
	match  {
	case 'A' <= b && b <= 'Z',
	     'a' <= b && b <= 'z',
	     '_' == b:
		return true;
	}
	return false;
}

is_digit :: proc(b: byte) -> bool {
	match  {
	case '0' <= b && b <= '9':
		return true;
	}
	return false;
}


trim :: proc(s: string) -> string {
	return trim_right(trim_left(s));
}

trim_left :: proc(s: string) -> string {
	start := 0;
	for i in 0..s.count {
		if is_whitespace(s[i]) {
			start++;
		} else {
			break;
		}
	}

	return s[start..];
}


trim_right :: proc(s: string) -> string {
	end := s.count;
	for i := end-1; i >= 0; i-- {
		if is_whitespace(s[i]) {
			end--;
		} else {
			break;
		}
	}

	return s[0..end];
}

errorf :: proc(format: string, args: ..any) {
	fmt.fprintf(os.stderr, format, ..args);
	os.exit(1);
}

errorln :: proc(args: ..any) {
	fmt.fprintln(os.stderr, ..args);
	os.exit(1);
}

output_filename :: proc(s: string) -> string {
	ext := "metagen";
	cext := "c";

	i := s.count-ext.count;
	str := new_slice(byte, i+cext.count);
	copy(str, cast([]byte)s[..i]);
	str[i] = 'c';
	return cast(string)str;
}

Tokenizer :: struct {
	filename:   string,
	data:       []byte,
	curr:       int,
	read_curr:  int,
	line:       int,
	line_count: int,

	curr_rune:   rune,
	error_count: int,
}

Token_Kind :: enum {
	INVALID,
	IDENT,
	STRING,
	EQUAL,
	COMMA,
	SEMICOLON,
	OTHER,
	EOF,
}

Token :: struct {
	kind:   Token_Kind,
	text:   string,
	line:   int,
	column: int,
}

tokenizer_err :: proc(t: ^Tokenizer, msg: string, args: ..any) {
	column := max(t.read_curr - t.line+1, 1);

	fmt.fprintf(os.stderr, "%s(%d:%d) Syntax error: ", t.filename, t.line_count, column);
	fmt.fprintf(os.stderr, msg, ..args);
	fmt.fprintln(os.stderr);
	t.error_count++;

	if t.error_count > 10 {
		os.exit(1);
	}
}

advance_to_next_rune :: proc(t: ^Tokenizer) {
	if t.read_curr < t.data.count {
		t.curr = t.read_curr;
		if t.curr_rune == '\n' {
			t.line = t.curr;
			t.line_count++;
		}
		r := cast(rune)t.data[t.read_curr];
		width := 1;
		if r == 0 {
			tokenizer_err(t, "Illegal character NULL");
		} else if r >= 0x80 {
			r, width = utf8.decode_rune(t.data[t.read_curr..]);
			if r == utf8.RUNE_ERROR && width == 1 {
				tokenizer_err(t, "Illegal UTF-8 encoding");
			} else if r == utf8.RUNE_BOM && t.curr > 0 {
				tokenizer_err(t, "Illegal byte order mark");
			}
		}
		t.read_curr += width;
		t.curr_rune = r;
	} else {
		t.curr = t.data.count;
		if t.curr_rune == '\n' {
			t.line = t.curr;
			t.line_count++;
		}
		t.curr_rune = utf8.RUNE_EOF;
	}
}

skip_whitespace :: proc(t: ^Tokenizer) {
	for t.curr_rune == ' ' ||
	    t.curr_rune == '\t' ||
	    t.curr_rune == '\n' ||
	    t.curr_rune == '\r' {
		advance_to_next_rune(t);
	}
}
scan_escape :: proc(t: ^Tokenizer, quote: rune) -> bool {
	advance_to_next_rune(t);

	r := t.curr_rune;
	match r {
	case 'a', 'b', 'f', 'n', 'r', 't', 'v', '\\', quote:
		advance_to_next_rune(t);
		return true;
	default:
		if t.curr_rune < 0 {
			tokenizer_err(t, "Escape sequence was not terminated");
		} else {
			tokenizer_err(t, "Unknown espace sequence");
		}
		return false;
	}
}

next_token :: proc(t: ^Tokenizer) -> Token {
	using Token_Kind;
	skip_whitespace(t);

	token := Token{
		line   = t.line,
		column = t.curr-t.line+1,
	};

	prev := t.curr;
	curr_rune := t.curr_rune;
	if is_letter(cast(byte)t.curr_rune) {
		for is_letter(cast(byte)t.curr_rune) || is_digit(cast(byte)t.curr_rune) {
	    	advance_to_next_rune(t);
	    }

	    token.text = cast(string)t.data[prev..t.curr];
	    token.kind = IDENT;
	} else {
		advance_to_next_rune(t);
		token.text = cast(string)t.data[prev..t.curr];
		match curr_rune {
		default: token.kind = OTHER;
		case utf8.RUNE_EOF: token.kind = EOF;

		case '/':
			if t.curr_rune != '/' {
				token.kind = OTHER;
			} else {
				token.text = "";
				for t.curr_rune != '\n' && t.curr_rune != utf8.RUNE_EOF {
					advance_to_next_rune(t);
				}
				if t.curr_rune == utf8.RUNE_EOF {
					token.kind = EOF;
					token.text = cast(string)t.data[t.curr..t.curr+1];
					return token;
				}
				return next_token(t);
			}



		case '=': token.kind = EQUAL;
		case ',': token.kind = COMMA;
		case ';': token.kind = SEMICOLON;

		case '"':
			for {
				r := t.curr_rune;
				if r == '\n' || r < 0 {
					tokenizer_err(t, "String literal not terminated");
					break;
				}
				advance_to_next_rune(t);
				if r == '"' {
					break;
				}
				if r == '\\' {
					scan_escape(t, '"');
				}
			}

			token.text = cast(string)t.data[prev+1..t.curr-1];
			token.kind = STRING;
		}
	}

	return token;
}

expect_token :: proc(t: ^Tokenizer, kind: Token_Kind) -> Token {
	tok := next_token(t);
	if tok.kind != kind {
		tokenizer_err(t, "Expected %s, got %s", kind, tok.kind);
	}
	return tok;
}


alloc_command_line_arguments :: proc() -> []string {
	arg_count: i32;
	arg_list_ptr := win32.CommandLineToArgvW(win32.GetCommandLineW(), ^arg_count);
	arg_list := new_slice(string, arg_count);
	for _, i in arg_list {
		arg_list[i] = alloc_ucs2_to_utf8((arg_list_ptr+i)^);
	}
	return arg_list;
}

main :: proc() {
	arg_list := alloc_command_line_arguments();

	if arg_list.count < 2 {
		errorln("Expected a .metagen file");
		return;
	}
	if arg_list.count != 2 {
		errorln("Expected only one .metagen file");
		return;
	}

	filename := arg_list[1];
	{ // Is extension valid?
		i := filename.count-1;
		for i >= 0 {
			if filename[i] == '.' {
				break;
			}
			i--;
		}
		if ext := filename[i..]; ext != ".metagen" {
			errorf("Expected a .metagen file, got %s\n", filename);
			return;
		}
	}

	data, file_ok := os.read_entire_file(filename);
	if !file_ok {
		errorf("Unable to read file %s\n", filename);
		return;
	}

	tokenizer := Tokenizer{
		data = data,
		filename = filename,
		line_count = 1,
	};
	t := ^tokenizer;
	advance_to_next_rune(t);
	if t.curr_rune == utf8.RUNE_BOM {
		advance_to_next_rune(t);
	}

	type:          string;
	prefix:        string;
	string_prefix: string;
	settings_done := false;

	for !settings_done {
		using Token_Kind;
		token := next_token(t);
		if token.kind == Token_Kind.EOF {
			break;
		}
		if token.kind != IDENT {
			tokenizer_err(t, "Expected an identifer");
			continue;
		}
		match token.text {
		case "type", "prefix", "string":
		default:
			tokenizer_err(t, "Unknown setting %s", token.text);
		}

		eq := expect_token(t, EQUAL);
		ident := expect_token(t, IDENT);
		match token.text {
		case "type":   type = ident.text;
		case "prefix": prefix = ident.text;
		case "string": string_prefix = ident.text;
		}

		expect_token(t, SEMICOLON);
		if type != "" && prefix != "" && string_prefix != "" {
			settings_done = true;
		}
	}

	if !settings_done {
		errorln("Incomplete metagen settings");
		return;
	}


	new_filename := output_filename(filename);

	file, file_err := os.open(new_filename, os.O_CREAT|os.O_TRUNC, 0);
	if file_err != os.ERROR_NONE {
		errorf("Unable to create file %s\n", new_filename);
		return;
	}
	defer os.close(file);

	match type {
	case "enum":
		Meta_Enum :: struct {
			name:    string,
			comment: string,
		}
		enums: [dynamic]Meta_Enum;

		for {
			using Token_Kind;
			ident := next_token(t);
			if ident.kind == EOF {
				break;
			}
			if ident.kind != IDENT {
				tokenizer_err(t, "Expected an identifer, got %s", ident.text);
			}
			expect_token(t, COMMA);
			comment := expect_token(t, STRING);
			expect_token(t, SEMICOLON);

			match ident.text {
			case "Kind", "COUNT":
				tokenizer_err(t, "A tag cannot be called %s", ident.text);
				continue;
			}

			append(enums, Meta_Enum{name = ident.text, comment = comment.text});
		}

		if t.error_count > 0 {
			return;
		}

		fmt.fprintf(file, "typedef enum %sKind %sKind;\n", prefix, prefix);
		fmt.fprintf(file, "enum %sKind {\n", prefix);
		for e in enums {
			fmt.fprintf(file, "\t%s_%s,\n", prefix, e.name);
		}
		fmt.fprintf(file, "\t%s_COUNT\n", prefix);
		fmt.fprintf(file, "};\n");

		fmt.fprintf(file, "String const %s_strings[] = {\n", string_prefix);
		for e, i in enums {
			fmt.fprintf(file, "\t{\"%s\", %d}", e.comment, e.comment.count);
			if i+1 < enums.count {
				fmt.fprint(file, ",");
			}
			fmt.fprintln(file, );
		}
		fmt.fprintf(file, "};\n\n");

	case "union":
		Meta_Union :: struct {
			name:    string,
			comment: string,
			type:    string,
		}

		unions: [dynamic]Meta_Union;

		for {
			using Token_Kind;
			ident := next_token(t);
			if ident.kind == EOF {
				break;
			}
			if ident.kind != IDENT {
				tokenizer_err(t, "Expected an identifer, got %s", ident.text);
			}
			expect_token(t, COMMA);
			comment_string := expect_token(t, STRING);
			expect_token(t, COMMA);

			brace_level := 0;
			start := next_token(t);
			curr := start;
			ok := true;
			for ok && (curr.kind != SEMICOLON || brace_level > 0) {
				curr = next_token(t);
				match curr.kind {
				case EOF:
					ok = false;
				case OTHER:
					match curr.text {
					case "{": brace_level++;
					case "}": brace_level--;
					}
				}
			}

			name := ident.text;

			if name == "" {
				continue;
			}


			if name == "Kind" {
				tokenizer_err(t, "A tag cannot be called Kind");
				continue;
			}

			comment := comment_string.text;
			if comment != "" && comment[0] == '_' {
				comment = "";
			}

			type := start.text;
			type.count = curr.text.data - type.data;
			type = trim(type);

			append(unions, Meta_Union{name = name, comment = comment, type = type});
		}

		if t.error_count > 0 {
			return;
		}

		fmt.fprintf(file, "typedef enum %sKind %sKind;\n", prefix, prefix);
		fmt.fprintf(file, "enum %sKind {\n", prefix);
		for u in unions {
			if u.name[0] != '_' {
				fmt.fprintf(file, "\t");
			}
			fmt.fprintf(file, "%s_%s,\n", prefix, u.name);
		}
		fmt.fprintf(file, "\t%s_COUNT\n", prefix);
		fmt.fprintf(file, "};\n");

		fmt.fprintf(file, "String const %s_strings[] = {\n", string_prefix);
		for u, i in unions {
			fmt.fprintf(file, "\t{\"%s\", %d}", u.comment, u.comment.count);
			if i+1 < unions.count {
				fmt.fprint(file, ",");
			}
			fmt.fprintln(file, );
		}
		fmt.fprintf(file, "};\n\n");


		for u, i in unions {
			fmt.fprintf(file, "typedef %s %s%s;\n", u.type, prefix, u.name);
		}

		fmt.fprintf(file, "\n\n");
		fmt.fprintf(file, "struct %s{\n", prefix);
		fmt.fprintf(file, "\t%sKind kind;\n", prefix);
		fmt.fprintf(file, "\tunion {\n",);
		for u, i in unions {
			fmt.fprintf(file, "\t\t%s%s %s;\n", prefix, u.name, u.name);
		}
		fmt.fprintf(file, "\t};\n");
		fmt.fprintf(file, "};\n\n");

		fmt.fprintf(file,
`
#define %s(n_, Kind_, node_) GB_JOIN2(%s, Kind_) *n_ = &(node_)->Kind_; GB_ASSERT((node_)->kind == GB_JOIN2(%s_, Kind_))
#define case_%s(n_, Kind_, node_) case GB_JOIN2(%s_, Kind_): { %s(n_, Kind_, node_);
#ifndef case_end
#define case_end } break;
#endif
`,
		prefix, prefix, prefix, prefix, prefix);

		fmt.fprintf(file, "\n\n");

		return;

	default:
		errorf("%s is not a valid type for metagen\n", type);
		return;
	}

}
