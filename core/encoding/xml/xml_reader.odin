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
	// Parse in the caller's buffer instead of a copy of it. Line ends are normalised in place, and the document's strings point into the buffer.
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

	// By default CDATA tags are passed-through as-is.
	// This option unwraps them when encountered.
	Unbox_CDATA,

	// By default SGML entities like `&gt;`, `&#32;` and `&#x20;` in a tag's body are passed-through as-is.
	// This option decodes them when encountered.
	// Entities in attribute values are always decoded, as the XML spec requires.
	Decode_SGML_Entities,

	// If a tag body has a comment, it will be stripped unless this option is given.
	Keep_Tag_Body_Comments,
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
	// Comments inside it that come right after a tag or another such comment become `.Comment` elements.
	comments: [dynamic]string        `fmt:"-"`,

	// Internal
	tokenizer: ^Tokenizer            `fmt:"-"`,
	allocator: mem.Allocator         `fmt:"-"`,

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
	General_Error,
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
	Comment_Before_Root_Element,
	Invalid_Sequence_In_Comment,

	Unsupported_Version,
	Unsupported_Encoding,

	// <!FOO are usually skipped.
	Unhandled_Bang,

	Duplicate_Attribute,
	Conflicting_Options,

	// An allocation failed.
	Allocation_Failed,
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
		skip_whitespace(t)
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
					// Unread the `<![` and let `parse_body` handle the CDATA.
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

	key, value := scan_attribute(t) or_return
	value = strings.trim_right(value, " \t\r\n")

	// Estimate decoded size based on input text.
	builder, builder_err := strings.builder_make_len_cap(0, len(value) + 10, doc.extra_strings_allocator)
	if builder_err != nil {
		return attr, offset, .Allocation_Failed
	}
	normalized, normalize_err := entity.decode_xml_sb(&builder, value, {.Normalize_Whitespace}, doc.allocator)
	if normalize_err == .None {
		value = normalized
	}

	attr.key = key
	attr.val = value

	err = .None
	return
}

@(private)
scan_attribute :: proc(t: ^Tokenizer) -> (key: string, value: string, err: Error) {
	key_token := expect(t, .Ident) or_return
	_          = expect(t, .Eq)    or_return
	skip_whitespace(t)

	quote := t.ch
	if quote != '"' && quote != '\'' {
		error(t, t.offset, "Expected a quoted attribute value\n")
		return key_token.text, "", .Unexpected_Token
	}
	start := t.offset + 1
	end   := strings.index_byte(t.src[start:], u8(quote))
	if end < 0 {
		error(t, t.offset, "Attribute value was not terminated\n")
		return key_token.text, "", .Premature_EOF
	}
	value = t.src[start:][:end]
	if lt := strings.index_byte(value, '<'); lt >= 0 {
		jump_to(t, start + lt)
		error(t, t.offset, "`<` is not allowed in an attribute value\n")
		return key_token.text, value, .Invalid_Tag_Value
	}
	jump_to(t, start + end + 1)
	return key_token.text, value, .None
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
		attr, offset := parse_attribute(doc)                  or_return
		check_duplicate_attributes(t, attribs^, attr, offset) or_return
		if attribs^ == nil {
			attribs^ = make_dynamic_array(Attributes, doc.extra_strings_allocator)
		}
		if _, alloc_err := append(attribs, attr); alloc_err != nil {
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
		key_offset := t.offset
		key, val   := scan_attribute(t) or_return

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

	skip_whitespace(t)
	offset := t.offset
	skip_element(t) or_return

	// 	-1 because the current offset is that of the closing tag, so the rest of the DOCTYPE tag ends just before it.
	doc.doctype.rest = string(t.src[offset : t.offset - 1])
	return .None
}

parse_body :: proc(doc: ^Document, element: Element_ID, opts: Options) -> (err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	body_text        := scan_string(t, t.offset) or_return
	needs_processing := .Unbox_CDATA          in opts.flags
	needs_processing |= .Decode_SGML_Entities in opts.flags

	if !needs_processing {
		if _, alloc_err := append(&doc.elements[element].value, body_text); alloc_err != nil {
			return .Allocation_Failed
		}
		return
	}

	decode_opts := entity.XML_Decode_Options{}
	if .Keep_Tag_Body_Comments not_in opts.flags {
		decode_opts += { .Comment_Strip }
	}

	if .Decode_SGML_Entities not_in opts.flags {
		decode_opts += { .No_Entity_Decode }
	}

	if .Unbox_CDATA in opts.flags {
		decode_opts += { .Unbox_CDATA }
		if .Decode_SGML_Entities in opts.flags {
			decode_opts += { .Decode_CDATA }
		}
	}

	builder, builder_err := strings.builder_make_len_cap(0, len(body_text) + 10, doc.extra_strings_allocator)
	if builder_err != nil {
		return .Allocation_Failed
	}
	decoded, decode_err := entity.decode_xml_sb(&builder, body_text, decode_opts)
	if decode_err != .None {
		decoded = body_text
	}
	if _, alloc_err := append(&doc.elements[element].value, decoded); alloc_err != nil {
		return .Allocation_Failed
	}

	return
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
