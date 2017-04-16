#import "fmt.odin";
#import "os.odin";
#import "strconv.odin";
#import "utf8.odin";

Error :: enum {
	NONE,
}

Style_Type :: enum {
	ITALIC,
	BOLD,
	STRIKE,
}

Node :: union {
	children:       [dynamic]Node,
	content:        []byte,
	inline_content: ^Node,
	line_number:    int,

	// Block Variants
	Header{level: int},
	Document{},
	Paragraph{},
	Quote{},
	Code_Block{language: string},
	Horizontal_Rule{},

	// Inline Variants
	Multiple_Inline{},
	String_Inline{},
	Soft_Line_Break{},
	Hard_Line_Break{},
	Code_Span{},
	Style{
		type: Style_Type,
	}
}


Parser :: struct {
	data:  []byte,
	nodes: [dynamic]Node,
}

parse :: proc(data: []byte) -> ([]Node, Error) {
	p := Parser{
		data = data,
	};
	err := parse(^p);

	if err != Error.NONE {
		return nil, err;
	}

	return p.nodes[..], Error.NONE;
}

parse :: proc(p: ^Parser) -> Error {
	is_blank :: proc(line: []byte) -> bool {
		line = trim_whitespace(line);
		return len(line) == 0;
	}

	is_horizontal_rule :: proc(line: []byte) -> bool {
		char: byte;
		count := 0;
		for c, i in line {
			if c != ' ' && c != '\n' {
				if c != '-' && c != '_' && c != '*' {
					return false;
				}
				if char == 0 {
					if i >= 4 {
						return false;
					}
					char = c;
					count = 1;
				} else if c == char {
					count++;
				} else {
					return false;
				}
			}
		}


		return count >= 3;
	}

	nodes := make([dynamic]Node);

	line_number: int = 0;
	prev_was_blank := false;
	in_code_block := false;
	code_language := "";
	code_block_start := 0;

	pos := 0;
	end := len(p.data);
	for pos < len(p.data) {
		line_start := pos;
		line_end := pos;
		for p.data[line_end] != '\n' {
			line_end++;
		}
		line := p.data[pos..line_end];
		pos = line_end+1;
		line_number++;

		line = tabs_to_spaces_and_append_newline(line);
		str := cast(string)line;

		skip := in_code_block;

		node: Node;
		if len(line) > 3 && cast(string)line[..3] == "```" {
			if !in_code_block {
				code_block_start = line_start+3;
				in_code_block = true;
				code_language = "";
				rest := trim_whitespace(line[3..]);
				if len(rest) > 0 {
					code_language = cast(string)rest;
				}
			} else {
				end := line_start-1;
				str := p.data[code_block_start..end];
				node = Node.Code_Block{content = str, language = code_language};
				in_code_block = false;
			}
			skip = true;
		}

		indent_char := line[indentation(line)];
		if skip {

		} else if indent_char == '>' {
			node = Node.Quote{content = line};
		} else if indent_char == '*' {
			// fmt.println("List Item");
		} else if level, content := parse_header(line); level > 0 {
			node = Node.Header{content = content, level = level};
		} else if is_horizontal_rule(line) {
			node = Node.Horizontal_Rule{};
		} else if !is_blank(line) {
			node = Node.Paragraph{content = line};
		}

		if node != nil {
			node.line_number = line_number;
			append(nodes, node);
		}
	}


	for _, i in nodes {
		using Node;
		match n in nodes[i] {
		case Paragraph, Horizontal_Rule, Header, Code_Block:
			append(p.nodes, nodes[i]);
		case Quote:
			// fmt.println("Quote");
		}
	}

	for _, i in p.nodes {
		process_inlines(^p.nodes[i]);
	}


	return Error.NONE;
}

process_inlines :: proc(node: ^Node) {
	using Node;
	match n in node {
	case Header:
		n.inline_content = parse_inlines(n.content);
	case Paragraph:
		n.inline_content = parse_inlines(trim_right_space(n.content));
	}

	for _, i in node.children {
		process_inlines(^node.children[i]);
	}
}

Inline_Parser :: struct {
	data:         []byte,
	pos:          int,
	string_start: int,
	root:         ^Node,
}

parse_inlines :: proc(data: []byte) -> ^Node {
	reset_string :: proc(p: ^Inline_Parser) {
		p.string_start = p.pos;
	}
	finalize_string :: proc(p: ^Inline_Parser) {
		if p.string_start >= p.pos {
			return;
		}


		str := p.data[p.string_start..p.pos];
		append(p.root.children, Node.String_Inline{content = trim_right_whitespace(str)});
	}

	p := Inline_Parser{
		data = data,
		root = new(Node),
	};
	p.root^ = Node.Multiple_Inline{};

	using Node;

	for p.pos < len(p.data) {
		node: Node;
		match p.data[p.pos] {
		default: p.pos++;

		case '\n':
			hard_break := false;
			new_line_pos := p.pos;

			if p.pos >= 2 && p.data[p.pos-1] == ' ' && p.data[p.pos-2] == ' ' {
				hard_break = true;
				p.pos -= 2;
			}

			if p.pos >= 1 && p.data[p.pos-1] == '\\' {
				hard_break = true;
				p.pos--;
			}


			for p.pos > 0 && p.data[p.pos-1] == ' ' {
				p.pos--;
			}
			finalize_string(^p);

			if hard_break {
				node = Hard_Line_Break{};
			} else {
				node = Soft_Line_Break{};
			}

			p.pos = new_line_pos + 1;

			for p.pos < len(p.data) && p.data[p.pos] == ' ' {
				p.pos++;
			}
			reset_string(^p);

		case '`':
			// "A backtick string is a string of one or more backtick
			// characters (`) that is neither preceded nor followed by a
			// backtick."
			backtick_count: int;
			for p.pos+backtick_count < len(p.data) && p.data[p.pos+backtick_count] == '`' {
				backtick_count++;
			}
			closing := char_string_index(p.data, '`', p.pos+backtick_count, backtick_count);
			if closing == -1 {
				p.pos += backtick_count;
				break;
			}

			finalize_string(^p);
			p.pos += backtick_count;

			content := p.data[p.pos..closing];
			content = collapse_space(trim_whitespace(content));

			node = Code_Span{content = content};

			p.pos = closing + backtick_count;
			reset_string(^p);

		case '\\':
			// "Backslashes before other characters are treated as literal backslashes."
			if p.pos+1 >= len(p.data) || !is_ascii_punc(p.data[p.pos+1]) {
				p.pos++;
				break;
			}
			// "Any ASCII punctuation character may be backslash-escaped."
			finalize_string(^p);
			p.pos++;
			node = String_Inline{content = p.data[p.pos..p.pos+1]};
			p.pos++;
			reset_string(^p);

		case '&':
			// "[A]ll valid HTML entities in any context are recognized as such
			// and converted into unicode characters before they are stored in
			// the AST."
			semicolon := -1;
			for c, i in p.data[p.pos+1..] {
				if c == ';' {
					semicolon = i;
					break;
				}
			}

			if semicolon < 0 {
				p.pos++;
				break;
			}

			semicolon += p.pos+1;
			entity := cast(string)p.data[p.pos+1..semicolon];

			codepoints := make([dynamic]byte, 0, 6);

			if len(entity) > 0 {
				if entity[0] != '#' {
					append(codepoints, '&');
					append(codepoints, ..cast([]byte)entity);
					append(codepoints, ';');
				} else {
					if len(entity) > 1 {
						base := 10;
						if entity[1] == 'x' || entity[1] == 'X' {
							// "Hexadecimal entities consist of &# + either X or x + a
							// string of 1-8 hexadecimal digits + ;."
							base = 16;
						} else {
							// "Decimal entities consist of &# + a string of 1–8 arabic
							// digits + ;. Again, these entities need to be recognised and
							// tranformed into their corresponding UTF8 codepoints. Invalid
							// Unicode codepoints will be written as the “unknown
							// codepoint” character (0xFFFD)."
						}
						codepoint := strconv.parse_uint(entity[2..], base);
						data, len := utf8.encode_rune(cast(rune)codepoint);
						append(codepoints, ..data[..len]);
					}
				}
			}

			if len(codepoints) == 0 {
				p.pos++;
				break;
			}

			finalize_string(^p);
			node = String_Inline{content = codepoints[..]};
			p.pos = semicolon+1;
			reset_string(^p);
		}

		if node != nil {
			append(p.root.children, node);
		}
	}

	finalize_string(^p);

	return p.root;
}

is_ascii_punc :: proc(char: byte) -> bool {
	match char {
	case '!', '"', '#', '$', '%',
	     '&', '\'', '(', ')',
	     '*', '+', ',', '-',
	     '.', '/', ':', ';',
	     '<', '=', '>', '?', '@', '[', '\\', ']',
	     '^', '_', '`', '{', '|', '}', '~':
		return true;
	}
	return false;
}

char_string_index :: proc(data: []byte, char: byte, start, length: int) -> int {
	count: int;
	for i in start..len(data) {
		if data[i] == char {
			count++;
			if count == length {
				if i+1 >= len(data) || data[i+1] != char {
					return i+1 - count;
				}
			}
		} else {
			count = 0;
		}
	}
	return -1;
}

collapse_space :: proc(data: []byte) -> []byte {
	out := make([]byte, 0, len(data));
	prev_was_space := false;
	for c in data {
		if c == ' ' || c == '\n' {
			if !prev_was_space {
				append(out, ' ');
				prev_was_space = true;
			}
		} else {
			append(out, c);
			prev_was_space = false;
		}
	}

	return out;
}


parse_header :: proc(line: []byte) -> (int, []byte) {
	// "The opening # character may be indented 0-3 spaces."
	indent := indentation(line);
	if indent > 3 {
		return -1, nil;
	}
	line = line[indent..];

	// "The header level is equal to the number of # characters in the opening sequence."
	level := 0;
	for c, i in line {
		if c != '#' {
			level = i;
			break;
		}
	}

	if level < 1 || level > 6 {
		return -1, nil;
	}
	line = line[level..];
	// "The opening sequence of # characters cannot be followed directly by a
	// nonspace character."
	if line[0] != ' ' && line[0] != '\n' {
		return -1, nil;
	}
	// "The optional closing sequence of #s [...] may be followed by spaces
	// only."

	trailer_start := len(line) - 1;
	for trailer_start > 0 && line[trailer_start-1] == ' ' {
		trailer_start--;
	}
	for trailer_start > 0 && line[trailer_start-1] == '#' {
		trailer_start--;
	}
	// "The optional closing sequence of #s must be preceded by a space [...]."
	// Note that (if the header is empty) this may be the same space as after
	// the opening sequence.
	if trailer_start > 0 && line[trailer_start-1] == ' ' {
		line = line[..trailer_start];
	}

	// "The raw contents of the header are stripped of leading and trailing
	// spaces before being parsed as inline content."
	line = trim_space(line);
	return level, line;

}

indentation :: proc(line: []byte) -> int {
	for c, i in line {
		if c != ' ' {
			return i;
		}
	}
	panic("indentation() expects line to end in newline character");
	return 0;
}


TAB_STOP :: 4;

tabs_to_spaces_and_append_newline :: proc(line: []byte) -> []byte {
	tab_count: int;
	for c in line {
		if c == '\t' {
			tab_count++;
		}
	}

	out := make([]byte, 0, len(line) + tab_count*(TAB_STOP-1) + 1);

	rune_count: int;
	for r in cast(string)line {
		if r == '\t' {
			spaces_count := TAB_STOP - rune_count%TAB_STOP;
			for i in 0..spaces_count {
				append(out, ' ');
			}
			rune_count += spaces_count;
		} else {
			match r {
			case '\r', '\v', '\f':
				append(out, ' ');
			default:
				c, l := utf8.encode_rune(r);
				append(out, ..c[0..l]);
			}
			rune_count++;
		}
	}
	append(out, '\n');
	return out;
}

trim_right_whitespace :: proc(data: []byte) -> []byte {
	c := data;
	for i := len(c)-1; i >= 0; i-- {
		match c[i] {
		case ' ', '\t', '\v', '\f', '\r', '\n':
			c = c[..i];
			continue;
		}
		break;
	}

	return c;
}


trim_right_space :: proc(data: []byte) -> []byte {
	c := data;
	for i := len(c)-1; i >= 0; i-- {
		if c[i] != ' ' {
			break;
		}
		c = c[..i];
	}

	return c;
}

trim_whitespace :: proc(data: []byte) -> []byte {
	data = trim_right_whitespace(data);
	index := 0;
	for c in data {
		match c {
		case ' ', '\t', '\v', '\f', '\r':
			index++;
			continue;
		}
		break;
	}
	return data[index..];
}

trim_space :: proc(data: []byte) -> []byte {
	index := 0;
	for c in data {
		if c != ' ' {
			break;
		}
		index++;
	}
	data = data[index..];

	for i := len(data)-1; i >= 0; i-- {
		if data[i] != ' ' {
			break;
		}
		data = data[..i];
	}

	return data;
}

escape_map := map[byte]string{
	'"' = "&quot;",
	'&' = "&amp;",
	'<' = "&lt;",
	'>' = "&gt;",
};


main :: proc() {
	data, ok := os.read_entire_file("W:/Odin/misc/markdown_test.md");
	if !ok {
		fmt.println("Failure to load file");
		return;
	}

	nodes, err := parse(data);
	if err != Error.NONE {
		fmt.println("Failure to parse file");
		return;
	}

	write_espaced :: proc(data: []byte) {
		start: int;
		for c, i in data {
			if escaped, ok := escape_map[c]; ok {
				fmt.print(cast(string)data[start..i]);
				fmt.print(escaped);
				start = i+1;
			}
		}
		fmt.print(cast(string)data[start..]);
	}

	print_inline_as_html :: proc(node: ^Node) {
		using Node;
		match n in node {
		case Multiple_Inline:
			for _, i in n.children {
				print_inline_as_html(^n.children[i]);
			}
		case String_Inline:
			write_espaced(n.content);
		case Soft_Line_Break:
			// fmt.println();
		case Hard_Line_Break:
			fmt.println("<br>");
		case Code_Span:
			fmt.print("<code>");
			write_espaced(n.content);
			fmt.print("</code>");
		}
	}

	print_node_as_html :: proc(node: ^Node) {
		using Node;
		match n in node {
		case Header:
			fmt.printf("<h%d>", n.level);
			print_inline_as_html(n.inline_content);
			fmt.printf("</h%d>\n", n.level);
		case Paragraph:
			fmt.print("<p>");
			print_inline_as_html(n.inline_content);
			fmt.println("</p>");
		case Horizontal_Rule:
			fmt.println("<hr>");
		case Code_Block:
			if n.language != "" {
				fmt.printf("<pre><code class=\"language-%s\">", n.language);
			} else {
				fmt.print("<pre><code>");
			}
			fmt.print(cast(string)n.content);
			fmt.println("</code></pre>");
		case Quote:
		}
	}

	for _, i in nodes {
		print_node_as_html(^nodes[i]);
	}
}
