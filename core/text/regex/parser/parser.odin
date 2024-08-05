package regex_parser

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "base:intrinsics"
import "core:strconv"
import "core:strings"
import "core:text/regex/common"
import "core:text/regex/tokenizer"
import "core:unicode"
import "core:unicode/utf8"

Token      :: tokenizer.Token
Token_Kind :: tokenizer.Token_Kind
Tokenizer  :: tokenizer.Tokenizer

Rune_Class_Range :: struct {
	lower, upper: rune,
}
Rune_Class_Data :: struct {
	runes: [dynamic]rune,
	ranges: [dynamic]Rune_Class_Range,
}


Node_Rune :: struct {
	data: rune,
}

Node_Rune_Class :: struct {
	negating: bool,
	using data: Rune_Class_Data,
}

Node_Wildcard :: struct {}

Node_Alternation :: struct {
	left, right: Node,
}

Node_Concatenation :: struct {
	nodes: [dynamic]Node,
}

Node_Repeat_Zero :: struct {
	inner: Node,
}
Node_Repeat_Zero_Non_Greedy :: struct {
	inner: Node,
}
Node_Repeat_One :: struct {
	inner: Node,
}
Node_Repeat_One_Non_Greedy :: struct {
	inner: Node,
}

Node_Repeat_N :: struct {
	inner: Node,
	lower, upper: int,
}

Node_Optional :: struct {
	inner: Node,
}
Node_Optional_Non_Greedy :: struct {
	inner: Node,
}

Node_Group :: struct {
	inner: Node,
	capture_id: int,
	capture: bool,
}

Node_Anchor :: struct {
	start: bool,
}
Node_Word_Boundary :: struct {
	non_word: bool,
}

Node_Match_All_And_Escape :: struct {}

Node :: union {
	^Node_Rune,
	^Node_Rune_Class,
	^Node_Wildcard,
	^Node_Concatenation,
	^Node_Alternation,
	^Node_Repeat_Zero,
	^Node_Repeat_Zero_Non_Greedy,
	^Node_Repeat_One,
	^Node_Repeat_One_Non_Greedy,
	^Node_Repeat_N,
	^Node_Optional,
	^Node_Optional_Non_Greedy,
	^Node_Group,
	^Node_Anchor,
	^Node_Word_Boundary,

	// Optimized nodes (not created by the Parser):
	^Node_Match_All_And_Escape,
}


left_binding_power :: proc(kind: Token_Kind) -> int {
	#partial switch kind {
	case .Alternate:                return 1
	case .Concatenate:              return 2
	case .Repeat_Zero, .Repeat_One,
	     .Repeat_Zero_Non_Greedy, .Repeat_One_Non_Greedy,
	     .Repeat_N:                 return 3
	case .Optional,
	     .Optional_Non_Greedy:      return 4
	case .Open_Paren,
	     .Open_Paren_Non_Capture:   return 9
	}
	return 0
}


Expected_Token :: struct {
	pos: int,
	kind: Token_Kind,
}

Invalid_Repetition :: struct {
	pos: int,
}

Invalid_Token :: struct {
	pos: int,
	kind: Token_Kind,
}

Invalid_Unicode :: struct {
	pos: int,
}

Too_Many_Capture_Groups :: struct {
	pos: int,
}

Unexpected_EOF :: struct {
	pos: int,
}

Error :: union {
	Expected_Token,
	Invalid_Repetition,
	Invalid_Token,
	Invalid_Unicode,
	Too_Many_Capture_Groups,
	Unexpected_EOF,
}


Parser :: struct {
	flags: common.Flags,
	t: Tokenizer,

	cur_token: Token,

	groups: int,
}


@require_results
advance :: proc(p: ^Parser) -> Error {
	p.cur_token = tokenizer.scan(&p.t)
	if p.cur_token.kind == .Invalid {
		return Invalid_Unicode { pos = 0 }
	}
	return nil
}

expect :: proc(p: ^Parser, kind: Token_Kind) -> (err: Error) {
	if p.cur_token.kind == kind {
		advance(p) or_return
		return
	}

	return Expected_Token{
		pos = p.t.offset,
		kind = kind,
	}
}

null_denotation :: proc(p: ^Parser, token: Token) -> (result: Node, err: Error) {
	#partial switch token.kind {
	case .Rune:
		r: rune
		for ru in token.text {
			r = ru
			break
		}
		assert(r != 0, "Parsed an empty Rune token.")

		if .Case_Insensitive in p.flags {
			lower := unicode.to_lower(r)
			upper := unicode.to_upper(r)
			if lower != upper {
				node := new(Node_Rune_Class)
				append(&node.runes, lower)
				append(&node.runes, upper)
				return node, nil
			}
		}

		node := new(Node_Rune)
		node ^= { r }
		return node, nil

	case .Rune_Class:
		if len(token.text) == 0 {
			return nil, nil
		}

		node := new(Node_Rune_Class)

		#no_bounds_check for i := 0; i < len(token.text); /**/ {
			r, size := utf8.decode_rune(token.text[i:])
			if i == 0 && r == '^' {
				node.negating = true
				i += size
				continue
			}
			i += size

			assert(size > 0, "RegEx tokenizer passed an incomplete Rune_Class to the parser.")

			if r == '\\' {
				next_r, next_size := utf8.decode_rune(token.text[i:])
				i += next_size
				assert(next_size > 0, "RegEx tokenizer passed an incomplete Rune_Class to the parser.")

				// @MetaCharacter
				// NOTE: These must be kept in sync with the tokenizer.
				switch next_r {
				case 'f': append(&node.runes, '\f')
				case 'n': append(&node.runes, '\n')
				case 'r': append(&node.runes, '\r')
				case 't': append(&node.runes, '\t')

				case 'd':
					append(&node.ranges, Rune_Class_Range{ '0', '9' })
				case 's':
					append(&node.runes, '\t')
					append(&node.runes, '\n')
					append(&node.runes, '\f')
					append(&node.runes, '\r')
					append(&node.runes, ' ')
				case 'w':
					append(&node.ranges, Rune_Class_Range{ '0', '9' })
					append(&node.ranges, Rune_Class_Range{ 'A', 'Z' })
					append(&node.runes, '_')
					append(&node.ranges, Rune_Class_Range{ 'a', 'z' })
				case 'D':
					append(&node.ranges, Rune_Class_Range{        0,  '0' - 1  })
					append(&node.ranges, Rune_Class_Range{  '9' + 1, max(rune) })
				case 'S':
					append(&node.ranges, Rune_Class_Range{        0, '\t' - 1  })
					// \t and \n are adjacent.
					append(&node.runes, '\x0b') // Vertical Tab
					append(&node.ranges, Rune_Class_Range{ '\r' + 1,  ' ' - 1  })
					append(&node.ranges, Rune_Class_Range{  ' ' + 1, max(rune) })
				case 'W':
					append(&node.ranges, Rune_Class_Range{        0,  '0' - 1  })
					append(&node.ranges, Rune_Class_Range{  '9' + 1,  'A' - 1  })
					append(&node.ranges, Rune_Class_Range{  'Z' + 1,  '_' - 1  })
					append(&node.ranges, Rune_Class_Range{  '_' + 1,  'a' - 1  })
					append(&node.ranges, Rune_Class_Range{  'z' + 1, max(rune) })
				case:
					append(&node.runes, next_r)
				}
				continue
			}

			if r == '-' && len(node.runes) > 0 {
				next_r, next_size := utf8.decode_rune(token.text[i:])
				if next_size > 0 {
					last := pop(&node.runes)
					i += next_size

					append(&node.ranges, Rune_Class_Range{ last, next_r })
					continue
				}
			}

			append(&node.runes, r)
		}

		if .Case_Insensitive in p.flags {
			// These two loops cannot be in the form of `for x in y` because
			// they append to the data that they iterate over.
			length := len(node.runes)
			#no_bounds_check for i := 0; i < length; i += 1 {
				r := node.runes[i]
				lower := unicode.to_lower(r)
				upper := unicode.to_upper(r)

				if lower != upper {
					if lower != r {
						append(&node.runes, lower)
					} else {
						append(&node.runes, upper)
					}
				}
			}

			length = len(node.ranges)
			#no_bounds_check for i := 0; i < length; i += 1 {
				range := &node.ranges[i]

				min_lower := unicode.to_lower(range.lower)
				max_lower := unicode.to_lower(range.upper)

				min_upper := unicode.to_upper(range.lower)
				max_upper := unicode.to_upper(range.upper)

				if min_lower != min_upper && max_lower != max_upper {
					range.lower = min_lower
					range.upper = max_lower
					append(&node.ranges, Rune_Class_Range{ min_upper, max_upper })
				}
			}
		}

		result = node

	case .Wildcard:
		node := new(Node_Wildcard)
		result = node

	case .Open_Paren:
		// Because of the recursive nature of the token parser, we take the
		// group number first instead of afterwards, in order to construct
		// group matches from the outside in.
		p.groups += 1
		if p.groups == common.MAX_CAPTURE_GROUPS {
			return nil, Too_Many_Capture_Groups{ pos = token.pos }
		}
		this_group := p.groups

		node := new(Node_Group)
		node.capture = true
		node.capture_id = this_group

		node.inner = parse_expression(p, 0) or_return
		expect(p, .Close_Paren) or_return
		result = node
	case .Open_Paren_Non_Capture:
		node := new(Node_Group)
		node.inner = parse_expression(p, 0) or_return
		expect(p, .Close_Paren) or_return
		result = node
	case .Close_Paren:
		node := new(Node_Rune)
		node ^= { ')' }
		return node, nil
		
	case .Anchor_Start:
		node := new(Node_Anchor)
		node.start = true
		result = node
	case .Anchor_End:
		node := new(Node_Anchor)
		result = node
	case .Word_Boundary:
		node := new(Node_Word_Boundary)
		result = node
	case .Non_Word_Boundary:
		node := new(Node_Word_Boundary)
		node.non_word = true
		result = node

	case .Alternate:
		// A unary alternation with a left-side empty path, i.e. `|a`.
		right, right_err := parse_expression(p, left_binding_power(.Alternate))
		#partial switch specific in right_err {
		case Unexpected_EOF:
			// This token is a NOP, i.e. `|`.
			break
		case nil:
			break
		case:
			return nil, right_err
		}

		node := new(Node_Alternation)
		node.right = right
		result = node

	case .EOF:
		return nil, Unexpected_EOF{ pos = token.pos }

	case:
		return nil, Invalid_Token{ pos = token.pos, kind = token.kind }
	}

	return
}

left_denotation :: proc(p: ^Parser, token: Token, left: Node) -> (result: Node, err: Error) {
	#partial switch token.kind {
	case .Alternate:
		if p.cur_token.kind == .Close_Paren {
			// `(a|)`
			// parse_expression will fail, so intervene here.
			node := new(Node_Alternation)
			node.left = left
			return node, nil
		}

		right, right_err := parse_expression(p, left_binding_power(.Alternate))

		#partial switch specific in right_err {
		case nil:
			break
		case Unexpected_EOF:
			// EOF is okay in an alternation; it's an edge case in the way of
			// expressing an optional such as `a|`.
			break
		case:
			return nil, right_err
		}

		node := new(Node_Alternation)
		node.left = left
		node.right = right
		result = node

	case .Concatenate:
		right := parse_expression(p, left_binding_power(.Concatenate)) or_return

		// There should be no need to check if right is Node_Concatenation, due
		// to how the parsing direction works.
		#partial switch specific in left {
		case ^Node_Concatenation:
			append(&specific.nodes, right)
			result = specific
		case:
			node := new(Node_Concatenation)
			append(&node.nodes, left)
			append(&node.nodes, right)
			result = node
		}

	case .Repeat_Zero:
		node := new(Node_Repeat_Zero)
		node.inner = left
		result = node
	case .Repeat_Zero_Non_Greedy:
		node := new(Node_Repeat_Zero_Non_Greedy)
		node.inner = left
		result = node
	case .Repeat_One:
		node := new(Node_Repeat_One)
		node.inner = left
		result = node
	case .Repeat_One_Non_Greedy:
		node := new(Node_Repeat_One_Non_Greedy)
		node.inner = left
		result = node

	case .Repeat_N:
		node := new(Node_Repeat_N)
		node.inner = left

		comma := strings.index_byte(token.text, ',')

		switch comma {
		case -1: // {N}
			exact, ok := strconv.parse_u64_of_base(token.text, base = 10)
			if !ok {
				return nil, Invalid_Repetition{ pos = token.pos }
			}
			if exact == 0 {
				return nil, Invalid_Repetition{ pos = token.pos }
			}

			node.lower = cast(int)exact
			node.upper = cast(int)exact

		case 0: // {,M}
			upper, ok := strconv.parse_u64_of_base(token.text[1:], base = 10)
			if !ok {
				return nil, Invalid_Repetition{ pos = token.pos }
			}
			if upper == 0 {
				return nil, Invalid_Repetition{ pos = token.pos }
			}

			node.lower = -1
			node.upper = cast(int)upper

		case len(token.text) - 1: // {N,}
			lower, ok := strconv.parse_u64_of_base(token.text[:comma], base = 10)
			if !ok {
				return nil, Invalid_Repetition{ pos = token.pos }
			}

			node.lower = cast(int)lower
			node.upper = -1

		case: // {N,M}
			lower, lower_ok := strconv.parse_u64_of_base(token.text[:comma], base = 10)
			if !lower_ok {
				return nil, Invalid_Repetition{ pos = token.pos }
			}
			upper, upper_ok := strconv.parse_u64_of_base(token.text[comma+1:], base = 10)
			if !upper_ok {
				return nil, Invalid_Repetition{ pos = token.pos }
			}
			if lower > upper {
				return nil, Invalid_Repetition{ pos = token.pos }
			}
			if upper == 0 {
				return nil, Invalid_Repetition{ pos = token.pos }
			}

			node.lower = cast(int)lower
			node.upper = cast(int)upper
		}

		result = node

	case .Optional:
		node := new(Node_Optional)
		node.inner = left
		result = node
	case .Optional_Non_Greedy:
		node := new(Node_Optional_Non_Greedy)
		node.inner = left
		result = node

	case .EOF:
		return nil, Unexpected_EOF{ pos = token.pos }

	case:
		return nil, Invalid_Token{ pos = token.pos, kind = token.kind }
	}

	return
}

parse_expression :: proc(p: ^Parser, rbp: int) -> (result: Node, err: Error) {
	token := p.cur_token

	advance(p) or_return
	left := null_denotation(p, token) or_return

	token = p.cur_token
	for rbp < left_binding_power(token.kind) {
		advance(p) or_return
		left = left_denotation(p, token, left) or_return
		token = p.cur_token
	}

	return left, nil
}

parse :: proc(str: string, flags: common.Flags) -> (result: Node, err: Error) {
	if len(str) == 0 {
		node := new(Node_Group)
		return node, nil
	}

	p: Parser
	p.flags = flags

	tokenizer.init(&p.t, str, flags)

	p.cur_token = tokenizer.scan(&p.t)
	if p.cur_token.kind == .Invalid {
		return nil, Invalid_Unicode { pos = 0 }
	}

	node := parse_expression(&p, 0) or_return
	result = node

	return
}
