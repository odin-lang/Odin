package encoding_xml
/*
	An XML 1.0 / 1.1 parser

	2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	available under Odin's license.

	List of contributors:
	- Jeroen van Rijn: Initial implementation.
*/

import    "base:runtime"
import    "core:encoding/entity"
import    "base:intrinsics"
import    "core:mem"
import    "core:slice"
import    "core:strings"

likely :: intrinsics.expect

DEFAULT_OPTIONS :: Options{
	flags = {.Ignore_Unsupported},
	expected_doctype = "",
}

Option_Flag :: enum {
	// Parse in the caller's buffer instead of a copy of it. Line ends are normalised and bodies and attribute values decoded in place, and the document's strings point into the buffer.
	// `parse_string` ignores this flag, since string data may be read-only.
	Input_May_Be_Modified,

	// Document MUST start with `<?xml` prologue.
	Must_Have_Prolog,

	// Document MUST have a `<!DOCTYPE`.
	Must_Have_DocType,

	// By default we skip comments. Use this option to intern a comment on a parented Element.
	Intern_Comments,

	// How to handle unsupported parts of the specification, like <! other than <!DOCTYPE and <![CDATA[
	Error_On_Unsupported,
	Error_on_Unsupported = Error_On_Unsupported,
	Ignore_Unsupported,

	// Also decode the HTML, MathML and ISO 8879 names from `unicode.xml`, in bodies and attribute values.
	// The 5 predefined entities and character references are always decoded. Other names are `.Unknown_Entity`,
	// unless `.Ignore_Unsupported` is set and the DOCTYPE has an internal subset or external ID: then they're kept as they are.
	Decode_SGML_Entities,

	// If a tag body has a comment, it will be stripped unless this option is given.
	Keep_Tag_Body_Comments,

	// Trim whitespace around body text, so whitespace between elements is dropped, and collapse and trim attribute values.
	Trim_Whitespace,
}
Option_Flags :: bit_set[Option_Flag; u16]

Document :: struct {
	elements:      [dynamic]Element `fmt:"v,element_count"`,
	element_count: Element_ID,

	prologue: Attributes,
	encoding: Encoding,

	doctype: struct {
		// We only scan the <!DOCTYPE IDENT part and skip the rest.
		ident:   string,
		rest:    string,
	},

	// With `.Intern_Comments`, comments outside the root element, before or after it, live here.
	// Comments inside it become `.Comment` elements, except those `.Keep_Tag_Body_Comments` keeps in the body text.
	comments: [dynamic]string        `fmt:"-"`,

	// Internal
	tokenizer: ^Tokenizer            `fmt:"-"`,
	allocator: mem.Allocator         `fmt:"-"`,
	options:   Options               `fmt:"-"`,

	// Buffer the document allocated and `destroy` frees: the copy made when `.Input_May_Be_Modified` isn't specified, or the file `load_from_file` read.
	// Empty otherwise: the caller owns the buffer, and must keep it alive while the document's strings point into it.
	input:           []u8            `fmt:"-"`,

	// An arena for small strings, especially for attribute key-value pairs.
	// This is a hot path optimization for large XML files.
	extra_strings_arena: mem.Dynamic_Arena `fmt:"-"`,
	extra_strings_allocator: mem.Allocator `fmt:"-"`,
}

Element :: struct {
	ident:   string,
	value:   [dynamic]Value,
	attribs: Attributes,

	kind: enum {
		Element = 0,
		Comment,
	},
	parent:   Element_ID,
}

Value :: union {
	string,
	Element_ID,
}

Attribute :: struct {
	key: string,
	val: string,
}

Attributes :: [dynamic]Attribute

Options :: struct {
	flags:            Option_Flags,
	expected_doctype: string,
}

Encoding :: enum {
	Unknown,

	UTF_8,
	ISO_8859_1,

	// Aliases
	LATIN_1 = ISO_8859_1,
}

Error :: enum {
	// General return values.
	None = 0,
	Unexpected_Token,
	Invalid_Token,

	// Couldn't find, open or read file.
	File_Error,

	// File too short.
	Premature_EOF,

	// XML-specific errors.
	No_Prolog,
	Invalid_Prolog,
	Too_Many_Prologs,

	No_DocType,
	Too_Many_DocTypes,
	DocType_Must_Preceed_Elements,

	// If a DOCTYPE is present _or_ the caller
	// asked for a specific DOCTYPE and the DOCTYPE
	// and root tag don't match, we return `.Invalid_DocType`.
	Invalid_DocType,

	Invalid_Tag_Value,
	Mismatched_Closing_Tag,

	Unclosed_Comment,
	Invalid_Sequence_In_Comment,

	Unsupported_Version,

	// <!FOO are usually skipped.
	Unhandled_Bang,

	Duplicate_Attribute,
	Conflicting_Options,

	// An allocation failed.
	Allocation_Failed,

	Unknown_Entity,
}

parse_bytes :: proc(data: []u8, options := DEFAULT_OPTIONS, path := "", error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	data := data
	context.allocator = allocator

	opts := validate_options(options) or_return

	// Everything below is owned by `doc`, so `destroy` frees whatever was allocated before a failure.
	alloc_err: mem.Allocator_Error
	if doc, alloc_err = new(Document); alloc_err != nil {
		return nil, .Allocation_Failed
	}
	doc.allocator = allocator
	doc.options   = opts

	// If `.Input_May_Be_Modified` is not specified, we duplicate the input so that we can modify it in-place.
	if .Input_May_Be_Modified not_in opts.flags {
		if data, alloc_err = slice.clone(data); alloc_err != nil {
			return doc, .Allocation_Failed
		}
		doc.input = data
	}

	length, illegal, valid := normalize_input(data)
	if !valid {
		report_illegal_input(error_handler, path, data[:length], illegal)
		return doc, .Invalid_Token
	}
	data = data[:length]

	if doc.tokenizer, alloc_err = new(Tokenizer); alloc_err != nil {
		return doc, .Allocation_Failed
	}
	t := doc.tokenizer
	init(t, string(data), path, error_handler)

	// Initialize arena allocator for small strings.
	// Estimate the block size based on input size, but don't splurge on memory for very small XML documents.
	dynamic_arena_block_size := max(256, len(data) / 4)
	mem.dynamic_arena_init(&doc.extra_strings_arena, allocator, allocator, dynamic_arena_block_size)
	doc.extra_strings_allocator = mem.dynamic_arena_allocator(&doc.extra_strings_arena)

	if doc.elements, alloc_err = make([dynamic]Element, 1024, 1024, allocator); alloc_err != nil {
		return doc, .Allocation_Failed
	}

	err = .Unexpected_Token
	element, parent: Element_ID
	open: Token

	// If a DOCTYPE is present, the root tag has to match.
	// If an expected DOCTYPE is given in options (i.e. it's non-empty), the DOCTYPE (if present) and root tag have to match.
	expected_doctype := options.expected_doctype

	depth     := 0
	doc_start := t.offset
	seen_xml  := false

	loop: for {
		if depth == 0 || .Trim_Whitespace in opts.flags {
			skip_whitespace(t)
		}
		switch t.ch {
		case '<':
			// Consume peeked `<`
			lt_offset := t.offset
			advance_rune(t)
			expect_no_space(t) or_return

			open = scan(t)
			// NOTE(Jeroen): We're not using a switch because this if-else chain ordered by likelihood is 2.5% faster at -o:size and -o:speed.
			if likely(open.kind, Token_Kind.Ident) == .Ident {
				// e.g. <odin - Start of new element.
				if doc.element_count > 0 && depth == 0 {
					error(t, lt_offset, "A document can only have one root element\n")
					return doc, .Unexpected_Token
				}
				element = new_element(doc) or_return
				if element == 0 { // First Element
					parent = element
				} else if _, alloc_err = append(&doc.elements[parent].value, element); alloc_err != nil {
					return doc, .Allocation_Failed
				}

				doc.elements[element].parent = parent
				doc.elements[element].ident  = open.text

				// PERF: Hot
				parse_attributes(doc, &doc.elements[element].attribs) or_return

				// If a DOCTYPE is present _or_ the caller
				// asked for a specific DOCTYPE and the DOCTYPE
				// and root tag don't match, we return .Invalid_Root_Tag.
				if element == 0 { // Root tag?
					if len(expected_doctype) > 0 && expected_doctype != open.text {
						error(t, t.offset, "Root Tag doesn't match DOCTYPE. Expected: %v, got: %v\n", expected_doctype, open.text)
						return doc, .Invalid_DocType
					}
				}

				// One of these should follow:
				// - `>`,  which means we've just opened this tag and expect a later element to close it.
				// - `/>`, which means this is an 'empty' or self-closing tag.
				end_token := scan(t)
				#partial switch end_token.kind {
				case .Gt:
					// We're now the new parent.
					parent = element
					depth += 1

				case .Slash:
					// Empty tag. Close it.
					expect_no_space(t) or_return
					expect(t, .Gt) or_return
					parent  = doc.elements[element].parent
					element = parent

				case:
					error(t, t.offset, "Expected close tag, got: %#v\n", end_token)
					return
				}

			} else if open.kind == .Slash {
				// Close tag.
				expect_no_space(t) or_return
				ident := expect(t, .Ident) or_return
				_      = expect(t, .Gt)    or_return

				if depth == 0 {
					error(t, lt_offset, "Closing tag without a start tag: %v\n", ident.text)
					return doc, .Mismatched_Closing_Tag
				}
				if doc.elements[element].ident != ident.text {
					error(t, t.offset, "Mismatched Closing Tag. Expected %v, got %v\n", doc.elements[element].ident, ident.text)
					return doc, .Mismatched_Closing_Tag
				}
				parent  = doc.elements[element].parent
				element = parent
				depth  -= 1

			} else if open.kind == .Exclaim {
				// <!
				expect_no_space(t) or_return
				next := scan(t)
				#partial switch next.kind {
				case .Ident:
					switch next.text {
					case "DOCTYPE":
						if len(doc.doctype.ident) > 0 {
							return doc, .Too_Many_DocTypes
						}
						if doc.element_count > 0 {
							return doc, .DocType_Must_Preceed_Elements
						}
						parse_doctype(doc) or_return

						if len(expected_doctype) > 0 && expected_doctype != doc.doctype.ident {
							error(t, t.offset, "Invalid DOCTYPE. Expected: %v, got: %v\n", expected_doctype, doc.doctype.ident)
							return doc, .Invalid_DocType
						}
						expected_doctype = doc.doctype.ident

					case:
						if .Error_On_Unsupported in opts.flags {
							error(t, t.offset, "Unhandled: <!%v\n", next.text)
							return doc, .Unhandled_Bang
						}
						skip_element(t) or_return
					}

				case .Dash:
					// Comment: <!-- -->.
					// The grammar does not allow a comment to end in --->
					if !strings.has_prefix(t.src[lt_offset:], COMMENT_START) {
						error(t, lt_offset, "Expected a comment after <!-\n")
						return doc, .Unexpected_Token
					}
					jump_to(t, lt_offset + len(COMMENT_START))
					comment := scan_comment(t) or_return

					if .Intern_Comments in opts.flags {
						if depth == 0 {
							if _, alloc_err = append(&doc.comments, comment); alloc_err != nil {
								return doc, .Allocation_Failed
							}
						} else {
							el := new_element(doc) or_return
							doc.elements[el].parent = element
							doc.elements[el].kind   = .Comment
							if _, alloc_err = append(&doc.elements[el].value, comment); alloc_err != nil {
								return doc, .Allocation_Failed
							}
							if _, alloc_err = append(&doc.elements[element].value, el); alloc_err != nil {
								return doc, .Allocation_Failed
							}
						}
					}

				case .Open_Bracket:
					// Only `<![CDATA[` can be part of a body, inside the root element; any other `<![` is unsupported.
					// Unread the `<![` and let `parse_body` unbox the CDATA.
					if !strings.has_prefix(t.src[lt_offset:], CDATA_START) {
						if .Error_On_Unsupported in opts.flags {
							error(t, lt_offset, "Unhandled: <![\n")
							return doc, .Unhandled_Bang
						}
						skip_element(t) or_return
						continue loop
					}
					if depth == 0 {
						error(t, lt_offset, "CDATA outside the root element\n")
						return doc, .Unexpected_Token
					}
					t.read_offset = lt_offset
					advance_rune(t)

					// Instead of calling `parse_body` here, we could also `continue loop`
					// and fall through to the `case:` at the bottom of the outer loop.
					// This makes the intent clearer.
					parse_body(doc, element, opts) or_return

				case:
					error(t, t.offset, "Unexpected Token after <!: %#v", next)
					return doc, .Unexpected_Token
				}

			} else if open.kind == .Question {
				// <?xml
				expect_no_space(t) or_return
				next := scan(t)
				#partial switch next.kind {
				case .Ident:
					if len(next.text) == 3 && strings.equal_fold(next.text, "xml") {
						if next.text != "xml" {
							error(t, lt_offset, "Reserved processing instruction target: %v\n", next.text)
							return doc, .Invalid_Prolog
						}
						if seen_xml {
							error(t, lt_offset, "Only one XML declaration is allowed\n")
							return doc, .Too_Many_Prologs
						}
						if lt_offset != doc_start {
							error(t, lt_offset, "The XML declaration must come first\n")
							return doc, .Invalid_Prolog
						}
						seen_xml = true
						parse_prologue(doc) or_return
					} else {
						// Could be `<?xml-stylesheet`, etc. Ignore it.
						if !is_space(t.ch) && !strings.has_prefix(t.src[t.offset:], "?>") {
							error(t, t.offset, "Expected whitespace or ?> after the processing instruction target\n")
							return doc, .Unexpected_Token
						}
						skip_pi(t) or_return
					}
				case:
					error(t, t.offset, "Expected \"<?xml\", got \"<?%v\".", next.text)
					return
				}

			} else {
				error(t, t.offset, "Invalid Token after <: %#v\n", open)
				return
			}

		case -1:
			// End of file.
			break loop

		case:
			// This should be a tag's body text.
			if depth == 0 {
				error(t, t.offset, "Text outside the root element\n")
				return doc, .Unexpected_Token
			}
			parse_body(doc, element, opts) or_return
		}
	}

	if doc.element_count == 0 {
		error(t, t.offset, "No root element\n")
		return doc, .Premature_EOF
	}

	if depth > 0 {
		error(t, t.offset, "Unclosed element: %v\n", doc.elements[element].ident)
		return doc, .Premature_EOF
	}

	if .Must_Have_Prolog in opts.flags && len(doc.prologue) == 0 {
		return doc, .No_Prolog
	}

	if .Must_Have_DocType in opts.flags && len(doc.doctype.ident) == 0 {
		return doc, .No_DocType
	}

	resize(&doc.elements, int(doc.element_count))
	return doc, .None
}

parse_string :: proc(data: string, options := DEFAULT_OPTIONS, path := "", error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	_data := transmute([]u8)data

	options := options
	options.flags -= {.Input_May_Be_Modified}
	return parse_bytes(_data, options, path, error_handler, allocator)
}

parse :: proc { parse_string, parse_bytes }

destroy :: proc(doc: ^Document, allocator := context.allocator) {
	if doc == nil { return }
	context.allocator = doc.allocator

	for el in doc.elements {
		delete(el.attribs)
		delete(el.value)
	}
	delete(doc.elements)

	delete(doc.prologue)
	delete(doc.comments)
	delete(doc.input)

	mem.dynamic_arena_destroy(&doc.extra_strings_arena)

	free(doc.tokenizer)
	free(doc)
}

/*
	Helpers.
*/

validate_options :: proc(options: Options) -> (validated: Options, err: Error) {
	validated = options

	if .Error_On_Unsupported in validated.flags && .Ignore_Unsupported in validated.flags {
		return options, .Conflicting_Options
	}
	return validated, .None
}

expect :: #force_inline proc(t: ^Tokenizer, kind: Token_Kind, multiline_string := false) -> (tok: Token, err: Error) {
	tok = scan(t, multiline_string=multiline_string)
	if tok.kind == kind { return tok, .None }

	error(t, t.offset, "Expected \"%v\", got \"%v\".", kind, tok.kind)
	return tok, .Unexpected_Token
}

parse_attribute :: proc(doc: ^Document) -> (attr: Attribute, offset: int, err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	value: string
	attr.key, value, offset = scan_attribute(t)               or_return
	attr.val                = decode_attribute_value(doc, value) or_return
	return attr, offset, .None
}

@(private)
decode_attribute_value :: proc(doc: ^Document, raw: string) -> (decoded: string, err: Error) {
	collapse := .Trim_Whitespace in doc.options.flags
	needs    := strings.index_byte(raw, '&') >= 0
	if !needs {
		for c in transmute([]u8)raw {
			if c == '\t' || c == '\n' || c == '\r' || (collapse && c == ' ') {
				needs = true
				break
			}
		}
	}
	if !needs {
		return raw, .None
	}

	options := entity_options(doc)
	options += {.Collapse_Whitespace} if collapse else {.Normalize_Attribute}
	start := int(uintptr(raw_data(raw)) - uintptr(raw_data(doc.tokenizer.src)))
	return decode_in_place(doc, start, raw, options)
}

@(private)
scan_attribute :: proc(t: ^Tokenizer) -> (key: string, value: string, offset: int, err: Error) {
	key_token := expect(t, .Ident) or_return
	_          = expect(t, .Eq)    or_return
	skip_whitespace(t)

	key    = key_token.text
	offset = key_token.pos.offset

	quote := t.ch
	if quote != '"' && quote != '\'' {
		error(t, t.offset, "Expected a quoted attribute value\n")
		return key, "", offset, .Unexpected_Token
	}
	start := t.offset + 1
	end   := strings.index_byte(t.src[start:], u8(quote))
	if end < 0 {
		error(t, t.offset, "Attribute value was not terminated\n")
		return key, "", offset, .Premature_EOF
	}
	value = t.src[start:][:end]
	if lt := strings.index_byte(value, '<'); lt >= 0 {
		jump_to(t, start + lt)
		error(t, t.offset, "`<` is not allowed in an attribute value\n")
		return key, value, offset, .Invalid_Tag_Value
	}
	jump_to(t, start + end + 1)
	return key, value, offset, .None
}

check_duplicate_attributes :: proc(t: ^Tokenizer, attribs: Attributes, attr: Attribute, offset: int) -> (err: Error) {
	for a in attribs {
		if attr.key == a.key {
			error(t, offset, "Duplicate attribute: %v\n", attr.key)
			return .Duplicate_Attribute
		}
	}
	return .None
}

parse_attributes :: proc(doc: ^Document, attribs: ^Attributes) -> (err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	MAP_FROM :: 32
	keys: map[string]struct{}
	defer delete(keys)

	// PERF: Hot
	for {
		space := is_space(t.ch)
		if peek(t).kind != .Ident {
			break
		}
		if !space {
			error(t, t.offset, "Expected whitespace before an attribute\n")
			return .Unexpected_Token
		}
		key, value, offset := scan_attribute(t) or_return
		if len(attribs^) < MAP_FROM {
			check_duplicate_attributes(t, attribs^, Attribute{key = key}, offset) or_return
		} else {
			if len(keys) == 0 {
				if reserve(&keys, 2 * MAP_FROM) != nil {
					return .Allocation_Failed
				}
				for a in attribs^ {
					keys[a.key] = {}
				}
			}
			_, _, inserted, alloc_err := map_entry(&keys, key)
			if alloc_err != nil {
				return .Allocation_Failed
			}
			if !inserted {
				error(t, offset, "Duplicate attribute: %v\n", key)
				return .Duplicate_Attribute
			}
		}
		val := decode_attribute_value(doc, value) or_return

		if attribs^ == nil {
			attribs^ = make_dynamic_array(Attributes, doc.extra_strings_allocator)
		}
		if _, alloc_err := append(attribs, Attribute{key = key, val = val}); alloc_err != nil {
			return .Allocation_Failed
		}
	}

	skip_whitespace(t)

	return .None
}

parse_prologue :: proc(doc: ^Document) -> (err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	offset := t.offset
	step   := 0
	for {
		space := is_space(t.ch)
		skip_whitespace(t)
		if t.ch == '?' {
			break
		}
		if !space {
			error(t, t.offset, "[parse_prologue] Expected whitespace\n")
			return .Invalid_Prolog
		}
		key, val, key_offset := scan_attribute(t) or_return

		switch {
		case key == "version" && step == 0:
			if !is_version_num(val) {
				error(t, key_offset, "[parse_prologue] Unsupported XML version: %v\n", val)
				return .Unsupported_Version
			}
			step = 1

		case key == "encoding" && step == 1:
			if !is_encoding_name(val) {
				error(t, key_offset, "[parse_prologue] Invalid encoding name: %v\n", val)
				return .Invalid_Prolog
			}
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			switch strings.to_lower(val, context.temp_allocator) {
			case "utf-8", "utf8":
				doc.encoding = .UTF_8

			case "latin-1", "latin1", "iso-8859-1":
				doc.encoding = .LATIN_1

			case:
				// Unrecognized encoding, assume UTF-8.
				error(t, offset, "[parse_prologue] Warning: Unrecognized encoding: %v\n", val)
			}
			step = 2

		case key == "standalone" && (step == 1 || step == 2):
			if val != "yes" && val != "no" {
				error(t, key_offset, "[parse_prologue] Invalid standalone value: %v\n", val)
				return .Invalid_Prolog
			}
			step = 3

		case:
			error(t, key_offset, "[parse_prologue] Unexpected %v\n", key)
			return .Invalid_Prolog
		}

		if doc.prologue == nil {
			doc.prologue = make_dynamic_array(Attributes, doc.extra_strings_allocator)
		}
		if _, alloc_err := append(&doc.prologue, Attribute{key = key, val = val}); alloc_err != nil {
			return .Allocation_Failed
		}
	}

	if step == 0 {
		error(t, offset, "[parse_prologue] Missing version\n")
		return .Invalid_Prolog
	}

	_ = expect(t, .Question) or_return
	expect_no_space(t)       or_return
	_ = expect(t, .Gt)       or_return

	return .None
}

@(private)
is_version_num :: proc(s: string) -> bool {
	if len(s) < 3 || s[:2] != "1." {
		return false
	}
	for r in s[2:] {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

@(private)
is_encoding_name :: proc(s: string) -> bool {
	for r, i in s {
		switch r {
		case 'A'..='Z', 'a'..='z':
		case '0'..='9', '.', '_', '-':
			if i == 0 {
				return false
			}
		case:
			return false
		}
	}
	return len(s) > 0
}

skip_element :: proc(t: ^Tokenizer) -> (err: Error) {
	src   := t.src
	i     := t.offset
	close := 1

	loop: for i < len(src) {
		switch src[i] {
		case '"', '\'':
			end := strings.index_byte(src[i + 1:], src[i])
			if end < 0 {
				break loop
			}
			i += end + 2
			continue loop

		case '<':
			rest := src[i:]
			if strings.has_prefix(rest, COMMENT_START) {
				end := strings.index(rest[len(COMMENT_START):], COMMENT_END)
				if end < 0 {
					break loop
				}
				i += len(COMMENT_START) + end + len(COMMENT_END)
				continue loop
			}
			if strings.has_prefix(rest, "<?") {
				end := strings.index(rest[2:], "?>")
				if end < 0 {
					break loop
				}
				i += 2 + end + 2
				continue loop
			}
			close += 1

		case '>':
			close -= 1
			if close == 0 {
				jump_to(t, i + 1)
				return .None
			}
		}
		i += 1
	}
	jump_to(t, len(src))
	error(t, t.offset, "[skip_element] Premature EOF\n")
	return .Premature_EOF
}

skip_pi :: proc(t: ^Tokenizer) -> (err: Error) {
	end := strings.index(t.src[t.offset:], "?>")
	if end < 0 {
		jump_to(t, len(t.src))
		error(t, t.offset, "[skip_pi] Premature EOF\n")
		return .Premature_EOF
	}
	jump_to(t, t.offset + end + 2)
	return .None
}

parse_doctype :: proc(doc: ^Document) -> (err: Error) {
	/*
	<!DOCTYPE greeting SYSTEM "hello.dtd">

	<!DOCTYPE greeting [
		<!ELEMENT greeting (#PCDATA)>
	]>
	*/
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	tok := expect(t, .Ident) or_return
	doc.doctype.ident = tok.text

	if !is_space(t.ch) && t.ch != '[' && t.ch != '>' {
		error(t, t.offset, "[parse_doctype] Expected whitespace, `[` or `>` after the DOCTYPE name\n")
		return .Unexpected_Token
	}

	skip_whitespace(t)
	offset := t.offset
	skip_element(t) or_return

	// 	-1 because the current offset is that of the closing tag, so the rest of the DOCTYPE tag ends just before it.
	doc.doctype.rest = string(t.src[offset : t.offset - 1])

	if !internal_subset_closed(doc.doctype.rest) {
		error(t, t.offset - 1, "[parse_doctype] Internal subset not closed with `]`\n")
		return .Unexpected_Token
	}
	return .None
}

@(private)
internal_subset_closed :: proc(rest: string) -> bool {
	for i := 0; i < len(rest); i += 1 {
		switch rest[i] {
		case '"', '\'':
			end := strings.index_byte(rest[i + 1:], rest[i])
			if end < 0 {
				return true
			}
			i += end + 1
		case '[':
			return strings.has_suffix(strings.trim_right(rest, " \t\r\n"), "]")
		}
	}
	return true
}

parse_body :: proc(doc: ^Document, element: Element_ID, opts: Options) -> (err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	start := t.offset
	stop_at_comments := .Intern_Comments in opts.flags && .Keep_Tag_Body_Comments not_in opts.flags
	_ = scan_string(t, start, stop_at_comments=stop_at_comments) or_return

	body_text := t.src[start:t.offset]
	if .Trim_Whitespace in opts.flags {
		body_text = strings.trim_right(body_text, " \t\r\n")
	}

	if strings.index_byte(body_text, '&') >= 0 || strings.index_byte(body_text, '<') >= 0 {
		decode_opts := entity_options(doc)
		if .Keep_Tag_Body_Comments in opts.flags {
			decode_opts += {.Keep_Comments}
		}
		body_text = decode_in_place(doc, start, body_text, decode_opts) or_return
	}

	if _, alloc_err := append(&doc.elements[element].value, body_text); alloc_err != nil {
		return .Allocation_Failed
	}
	return
}

@(private)
entity_options :: proc(doc: ^Document) -> (options: entity.XML_Decode_Options) {
	if .Decode_SGML_Entities in doc.options.flags {
		options += {.HTML_Entities}
	}
	if .Ignore_Unsupported in doc.options.flags && len(doc.doctype.rest) > 0 {
		options += {.Keep_Unknown_Entities}
	}
	return
}

@(private)
decode_in_place :: proc(doc: ^Document, start: int, text: string, options: entity.XML_Decode_Options) -> (decoded: string, err: Error) {
	t   := doc.tokenizer
	end := start + len(text)

	clean_line_offset := t.clean_line_offset
	if nl := strings.last_index_byte(t.src[t.clean_offset:end], '\n'); nl >= 0 {
		clean_line_offset = t.clean_offset + nl + 1
	}

	decode_err: entity.Error
	err_offset: int
	decoded, decode_err, err_offset = entity.decode_xml_in_place(transmute([]u8)text, options)
	#partial switch decode_err {
	case .None:
		t.clean_offset      = end
		t.clean_line_offset = clean_line_offset
		return decoded, .None

	case .Buffer_Too_Small:
		builder, builder_err := strings.builder_make_len_cap(0, len(text) + len(text) / 4 + 8, doc.extra_strings_allocator)
		if builder_err != nil {
			return text, .Allocation_Failed
		}
		decoded, decode_err = entity.decode_xml_sb(&builder, text, options)
		if decode_err == .None {
			return decoded, .None
		}
		err_offset = 0

	case .Unknown_Entity:
		error(t, start + err_offset, "Unknown entity\n")
		return text, .Unknown_Entity
	}
	error(t, start + err_offset, "Invalid entity reference: %v\n", decode_err)
	return text, .Invalid_Token
}

Element_ID :: u32

new_element :: proc(doc: ^Document) -> (id: Element_ID, err: Error) {
	element_space := len(doc.elements)

	// Need to resize
	if int(doc.element_count) + 1 > element_space {
		if element_space < 65536 {
			element_space *= 2
		} else {
			element_space += 65536
		}
		if resize(&doc.elements, element_space) != nil {
			return 0, .Allocation_Failed
		}
	}

	cur := doc.element_count
	doc.element_count += 1
	return cur, .None
}
