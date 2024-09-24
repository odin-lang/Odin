/*
	2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	available under Odin's BSD-3 license.

	List of contributors:
	- Jeroen van Rijn: Initial implementation.
*/

package encoding_xml
// An XML 1.0 / 1.1 parser

import "core:bytes"
import "core:encoding/entity"
import "base:intrinsics"
import "core:mem"
import "core:os"
import "core:strings"
import "base:runtime"

likely :: intrinsics.expect

DEFAULT_OPTIONS :: Options{
	flags = {.Ignore_Unsupported},
	expected_doctype = "",
}

Option_Flag :: enum {
	// If the caller says that input may be modified, we can perform in-situ parsing.
	// If this flag isn't provided, the XML parser first duplicates the input so that it can.
	Input_May_Be_Modified,

	// Document MUST start with `<?xml` prologue.
	Must_Have_Prolog,

	// Document MUST have a `<!DOCTYPE`.
	Must_Have_DocType,

	// By default we skip comments. Use this option to intern a comment on a parented Element.
	Intern_Comments,

	// How to handle unsupported parts of the specification, like <! other than <!DOCTYPE and <![CDATA[
	Error_on_Unsupported,
	Ignore_Unsupported,

	// By default CDATA tags are passed-through as-is.
	// This option unwraps them when encountered.
	Unbox_CDATA,

	// By default SGML entities like `&gt;`, `&#32;` and `&#x20;` are passed-through as-is.
	// This option decodes them when encountered.
	Decode_SGML_Entities,

	// If a tag body has a comment, it will be stripped unless this option is given.
	Keep_Tag_Body_Comments,
}
Option_Flags :: bit_set[Option_Flag; u16]

Document :: struct {
	elements:      [dynamic]Element,
	element_count: Element_ID,

	prologue: Attributes,
	encoding: Encoding,

	doctype: struct {
		// We only scan the <!DOCTYPE IDENT part and skip the rest.
		ident:   string,
		rest:    string,
	},

	// If we encounter comments before the root node, and the option to intern comments is given, this is where they'll live.
	// Otherwise they'll be in the element tree.
	comments: [dynamic]string,

	// Internal
	tokenizer: ^Tokenizer,
	allocator: mem.Allocator,

	// Input. Either the original buffer, or a copy if `.Input_May_Be_Modified` isn't specified.
	input:           []u8,
	strings_to_free: [dynamic]string,
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
}

parse_bytes :: proc(data: []u8, options := DEFAULT_OPTIONS, path := "", error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	data := data
	context.allocator = allocator

	opts := validate_options(options) or_return

	// If `.Input_May_Be_Modified` is not specified, we duplicate the input so that we can modify it in-place.
	if .Input_May_Be_Modified not_in opts.flags {
		data = bytes.clone(data)
	}

	t := &Tokenizer{}
	init(t, string(data), path, error_handler)

	doc = new(Document)
	doc.allocator = allocator
	doc.tokenizer = t
	doc.input     = data

	doc.elements = make([dynamic]Element, 1024, 1024, allocator)

	err = .Unexpected_Token
	element, parent: Element_ID
	open: Token

	// If a DOCTYPE is present, the root tag has to match.
	// If an expected DOCTYPE is given in options (i.e. it's non-empty), the DOCTYPE (if present) and root tag have to match.
	expected_doctype := options.expected_doctype

	loop: for {
		skip_whitespace(t)
		// NOTE(Jeroen): This is faster as a switch.
		switch t.ch {
		case '<':
			// Consume peeked `<`
			advance_rune(t)

			open = scan(t)
			// NOTE(Jeroen): We're not using a switch because this if-else chain ordered by likelihood is 2.5% faster at -o:size and -o:speed.
			if likely(open.kind, Token_Kind.Ident) == .Ident {
				// e.g. <odin - Start of new element.
				element = new_element(doc)
				if element == 0 { // First Element
					parent = element
				} else {
					append(&doc.elements[parent].value, element)
				}

				doc.elements[element].parent = parent
				doc.elements[element].ident  = open.text

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

				case .Slash:
					// Empty tag. Close it.
					expect(t, .Gt) or_return
					parent  = doc.elements[element].parent
					element = parent

				case:
					error(t, t.offset, "Expected close tag, got: %#v\n", end_token)
					return
				}

			} else if open.kind == .Slash {
				// Close tag.
				ident := expect(t, .Ident) or_return
				_      = expect(t, .Gt)    or_return

				if doc.elements[element].ident != ident.text {
					error(t, t.offset, "Mismatched Closing Tag. Expected %v, got %v\n", doc.elements[element].ident, ident.text)
					return doc, .Mismatched_Closing_Tag
				}
				parent  = doc.elements[element].parent
				element = parent

			} else if open.kind == .Exclaim {
				// <!
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
						if .Error_on_Unsupported in opts.flags {
							error(t, t.offset, "Unhandled: <!%v\n", next.text)
							return doc, .Unhandled_Bang
						}
						skip_element(t) or_return
					}

				case .Dash:
					// Comment: <!-- -->.
					// The grammar does not allow a comment to end in --->
					expect(t, .Dash)
					comment := scan_comment(t) or_return

					if .Intern_Comments in opts.flags {
						if len(doc.elements) == 0 {
							append(&doc.comments, comment)
						} else {
							el := new_element(doc)
							doc.elements[el].parent = element
							doc.elements[el].kind   = .Comment
							append(&doc.elements[el].value, comment)
							append(&doc.elements[element].value, el)
						}
					}

				case:
					error(t, t.offset, "Invalid Token after <!. Expected .Ident, got %#v\n", next)
					return
				}

			} else if open.kind == .Question {
				// <?xml
				next := scan(t)
				#partial switch next.kind {
				case .Ident:
					if len(next.text) == 3 && strings.equal_fold(next.text, "xml") {
						parse_prologue(doc) or_return
					} else if len(doc.prologue) > 0 {
						// We've already seen a prologue.
						return doc, .Too_Many_Prologs
					} else {
						// Could be `<?xml-stylesheet`, etc. Ignore it.
						skip_element(t) or_return
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
			body_text        := scan_string(t, t.offset) or_return
			needs_processing := .Unbox_CDATA          in opts.flags
			needs_processing |= .Decode_SGML_Entities in opts.flags

			if !needs_processing {
				append(&doc.elements[element].value, body_text)
				continue
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

			decoded, decode_err := entity.decode_xml(body_text, decode_opts)
			if decode_err == .None {
				append(&doc.elements[element].value, decoded)
				append(&doc.strings_to_free, decoded)
			} else {
				append(&doc.elements[element].value, body_text)
			}
		}
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

	return parse_bytes(_data, options, path, error_handler, allocator)
}

parse :: proc { parse_string, parse_bytes }

// Load an XML file
load_from_file :: proc(filename: string, options := DEFAULT_OPTIONS, error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	context.allocator = allocator
	options := options

	data, data_ok := os.read_entire_file(filename)
	if !data_ok { return {}, .File_Error }

	options.flags += { .Input_May_Be_Modified }

	return parse_bytes(data, options, filename, error_handler, allocator)
}

destroy :: proc(doc: ^Document) {
	if doc == nil { return }

	for el in doc.elements {
		delete(el.attribs)
		delete(el.value)
	}
	delete(doc.elements)

	delete(doc.prologue)
	delete(doc.comments)
	delete(doc.input)

	for s in doc.strings_to_free {
		delete(s)
	}
	delete(doc.strings_to_free)

	free(doc)
}

/*
	Helpers.
*/

validate_options :: proc(options: Options) -> (validated: Options, err: Error) {
	validated = options

	if .Error_on_Unsupported in validated.flags && .Ignore_Unsupported in validated.flags {
		return options, .Conflicting_Options
	}
	return validated, .None
}

expect :: proc(t: ^Tokenizer, kind: Token_Kind, multiline_string := false) -> (tok: Token, err: Error) {
	tok = scan(t, multiline_string=multiline_string)
	if tok.kind == kind { return tok, .None }

	error(t, t.offset, "Expected \"%v\", got \"%v\".", kind, tok.kind)
	return tok, .Unexpected_Token
}

parse_attribute :: proc(doc: ^Document) -> (attr: Attribute, offset: int, err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	key    := expect(t, .Ident)  or_return
	offset  = t.offset - len(key.text)

	_       = expect(t, .Eq)     or_return
	value  := expect(t, .String, multiline_string=true) or_return

	normalized, normalize_err := entity.decode_xml(value.text, {.Normalize_Whitespace}, doc.allocator)
	if normalize_err == .None {
		append(&doc.strings_to_free, normalized)
		value.text = normalized
	}

	attr.key = key.text
	attr.val = value.text

	err = .None
	return
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

	for peek(t).kind == .Ident {
		attr, offset := parse_attribute(doc)                  or_return
		check_duplicate_attributes(t, attribs^, attr, offset) or_return
		append(attribs, attr)
	}
	skip_whitespace(t)
	return .None
}

parse_prologue :: proc(doc: ^Document) -> (err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	offset := t.offset
	parse_attributes(doc, &doc.prologue) or_return

	for attr in doc.prologue {
		switch attr.key {
		case "version":
			switch attr.val {
			case "1.0", "1.1":
			case:
				error(t, offset, "[parse_prologue] Warning: Unhandled XML version: %v\n", attr.val)
			}

		case "encoding":
			runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD()
			switch strings.to_lower(attr.val, context.temp_allocator) {
			case "utf-8", "utf8":
				doc.encoding = .UTF_8

			case "latin-1", "latin1", "iso-8859-1":
				doc.encoding = .LATIN_1

			case:
				// Unrecognized encoding, assume UTF-8.
				error(t, offset, "[parse_prologue] Warning: Unrecognized encoding: %v\n", attr.val)
			}

		case:
			// Ignored.
		}
	}

	_ = expect(t, .Question) or_return
	_ = expect(t, .Gt)       or_return

	return .None
}

skip_element :: proc(t: ^Tokenizer) -> (err: Error) {
	close := 1

	loop: for {
		tok := scan(t)
		#partial switch tok.kind {
		case .EOF:
			error(t, t.offset, "[skip_element] Premature EOF\n")
			return .Premature_EOF

		case .Lt:
			close += 1

		case .Gt:
			close -= 1
			if close == 0 {
				break loop
			}

		case:

		}
	}
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

Element_ID :: u32

new_element :: proc(doc: ^Document) -> (id: Element_ID) {
	element_space := len(doc.elements)

	// Need to resize
	if int(doc.element_count) + 1 > element_space {
		if element_space < 65536 {
			element_space *= 2
		} else {
			element_space += 65536
		}
		resize(&doc.elements, element_space)
	}

	cur := doc.element_count
	doc.element_count += 1
	return cur
}
