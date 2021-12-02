package xml
/*
	An XML 1.0 / 1.1 parser

	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A from-scratch XML implementation, loosely modelled on the [spec](https://www.w3.org/TR/2006/REC-xml11-20060816).

	Features:
		- Supports enough of the XML 1.0/1.1 spec to handle the 99.9% of XML documents in common current usage.
		- Simple to understand and use. Small.

	Caveats:
		- We do NOT support HTML in this package, as that may or may not be valid XML.
		  If it works, great. If it doesn't, that's not considered a bug.

		- We do NOT support UTF-16. If you have a UTF-16 XML file, please convert it to UTF-8 first. Also, our condolences.
		- <[!ELEMENT and <[!ATTLIST are not supported, and will be either ignored or return an error depending on the parser options.

	TODO:
	- Optional CDATA unboxing.
	- Optional `&gt;`, `&#32;`, `&#x20;` and other escape substitution in tag bodies.

	MAYBE:
	- XML writer?
	- Serialize/deserialize Odin types?

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/

import "core:strings"
import "core:mem"
import "core:os"

DEFAULT_Options :: Options{
	flags            = {
		.Ignore_Unsupported,
	},
	expected_doctype = "",
}

Option_Flag :: enum {
	/*
		Document MUST start with `<?xml` prolog.
	*/
	Must_Have_Prolog,

	/*
		Document MUST have a `<!DOCTYPE`.
	*/
	Must_Have_DocType,

	/*
		By default we skip comments. Use this option to intern a comment on a parented Element.
	*/
	Intern_Comments,

	/*
		How to handle unsupported parts of the specification, like <! other than <!DOCTYPE and <![CDATA[
	*/
	Error_on_Unsupported,
	Ignore_Unsupported,

	/*
		By default CDATA tags are passed-through as-is.
		This option unwraps them when encountered.
	*/
	Unbox_CDATA,

	/*
		By default SGML entities like `&gt;`, `&#32;` and `&#x20;` are passed-through as-is.
		This option decodes them when encountered.
	*/
	Decode_SGML_Entities,
}
Option_Flags :: bit_set[Option_Flag; u8]

Document :: struct {
	root:     ^Element,
	prolog:   Attributes,
	encoding: Encoding,

	doctype: struct {
		/*
			We only scan the <!DOCTYPE IDENT part and skip the rest.
		*/
		ident:   string,
		rest:    string,
	},

	/*
		If we encounter comments before the root node, and the option to intern comments is given, this is where they'll live.
		Otherwise they'll be in the element tree.
	*/
	comments: [dynamic]string,

	/*
		Internal
	*/
	tokenizer: ^Tokenizer,
	allocator: mem.Allocator,
	intern:    strings.Intern,
}

Element :: struct {
	ident:   string,
	value:   string,
	attribs: Attributes,

	kind: enum {
		Element = 0,
		Comment,
	},

	parent:   ^Element,
	children: [dynamic]^Element,
}

Attr :: struct {
	key: string,
	val: string,
}

Attributes :: [dynamic]Attr

Options :: struct {
	flags:            Option_Flags,
	expected_doctype: string,
}

Encoding :: enum {
	Unknown,

	UTF_8,
	ISO_8859_1,

	/*
		Aliases
	*/
	LATIN_1 = ISO_8859_1,
}

Error :: enum {
	/*
		General return values.
	*/
	None = 0,
	General_Error,
	Unexpected_Token,
	Invalid_Token,

	/*
		Couldn't find, open or read file.
	*/
	File_Error,

	/*
		File too short.
	*/
	Premature_EOF,

	/*
		XML-specific errors.
	*/
	No_Prolog,
	Invalid_Prolog,
	Too_Many_Prologs,

	No_DocType,
	Too_Many_DocTypes,
	DocType_Must_Proceed_Elements,

	/*
		If a DOCTYPE is present _or_ the caller
		asked for a specific DOCTYPE and the DOCTYPE
		and root tag don't match, we return `.Invalid_DocType`.
	*/
	Invalid_DocType,

	Invalid_Tag_Value,
	Mismatched_Closing_Tag,

	Unclosed_Comment,
	Comment_Before_Root_Element,
	Invalid_Sequence_In_Comment,

	Unsupported_Version,
	Unsupported_Encoding,

	/*
		<!FOO are usually skipped.
	*/
	Unhandled_Bang,

	Duplicate_Attribute,
	Conflicting_Options,

	/*
		Unhandled TODO:
	*/
	Unhandled_CDATA_Unboxing,
	Unhandled_SGML_Entity_Decoding,
}

/*
	Implementation starts here.
*/
parse_from_slice :: proc(data: []u8, options := DEFAULT_Options, path := "", error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	context.allocator = allocator

	opts := validate_options(options) or_return

	t := &Tokenizer{}
	init(t, string(data), path, error_handler)

	doc = new(Document)
	doc.allocator = allocator
	doc.tokenizer = t

	strings.intern_init(&doc.intern, allocator, allocator)

	err =               .Unexpected_Token
	element, parent:    ^Element

	tag_is_open := false

	/*
		If a DOCTYPE is present, the root tag has to match.
		If an expected DOCTYPE is given in options (i.e. it's non-empty), the DOCTYPE (if present) and root tag have to match.
	*/
	expected_doctype := options.expected_doctype

	loop: for {
		skip_whitespace(t)
		switch t.ch {
		case '<':
			/*
				Consume peeked `<`
			*/
			advance_rune(t)

			open := scan(t)
			#partial switch open.kind {

			case .Question:
				/*
					<?xml
				*/
				next := scan(t)
				#partial switch next.kind {
				case .Ident:
					if len(next.text) == 3 && strings.to_lower(next.text, context.temp_allocator) == "xml" {
						parse_prolog(doc) or_return
					} else if len(doc.prolog) > 0 {
						/*
							We've already seen a prolog.
						*/
						return doc, .Too_Many_Prologs
					} else {
						/*
							Could be `<?xml-stylesheet`, etc. Ignore it.
						*/
						skip_element(t) or_return
					}
				case:
					error(t, t.offset, "Expected \"<?xml\", got \"<?%v\".", next.text)
					return
				}

			case .Exclaim:
				/*
					<!
				*/
				next := scan(t)
				#partial switch next.kind {
				case .Ident:
					switch next.text {
					case "DOCTYPE":
						if len(doc.doctype.ident) > 0 {
							return doc, .Too_Many_DocTypes
						}
						if doc.root != nil {
							return doc, .DocType_Must_Proceed_Elements
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
							err = .Unhandled_Bang
							return	
						}
						skip_element(t) or_return
					}

				case .Dash:
					/*
						Comment: <!-- -->.
						The grammar does not allow a comment to end in --->
					*/
					expect(t, .Dash)
					comment := scan_comment(t) or_return

					if .Intern_Comments in opts.flags {
						comment = strings.intern_get(&doc.intern, comment)

						if doc.root == nil {
							append(&doc.comments, comment)
						} else {
							el := new(Element)
							el.parent = element
							el.kind   = .Comment
							el.value  = comment
							append(&element.children, el)
						}
					}

				case:
					error(t, t.offset, "Invalid Token after <!. Expected .Ident, got %#v\n", next)
					return
				}

			case .Ident:
				/*
					e.g. <odin - Start of new element.
				*/
				element = new(Element)
				tag_is_open = true

				if doc.root == nil {
					/*
						First element.
					*/
					doc.root = element
					parent   = element
				} else {
					append(&parent.children, element)
				}

				element.parent = parent
				element.ident  = strings.intern_get(&doc.intern, open.text)

				parse_attributes(doc, &element.attribs) or_return

				/*
					If a DOCTYPE is present _or_ the caller
					asked for a specific DOCTYPE and the DOCTYPE
					and root tag don't match, we return .Invalid_Root_Tag.
				*/
				if element == doc.root {
					if len(expected_doctype) > 0 && expected_doctype != open.text {
						error(t, t.offset, "Root Tag doesn't match DOCTYPE. Expected: %v, got: %v\n", expected_doctype, open.text)
						return doc, .Invalid_DocType
					}
				}

				/*
					One of these should follow:
					- `>`,  which means we've just opened this tag and expect a later element to close it.
					- `/>`, which means this is an 'empty' or self-closing tag.
				*/
				end_token := scan(t)
				#partial switch end_token.kind {
				case .Gt:
					/*
						We're now the new parent.
					*/
					parent = element

				case .Slash:
					/*
						Empty tag. Close it.
					*/
					expect(t, .Gt) or_return
					parent      = element.parent
					element     = parent
					tag_is_open = false

				case:
					error(t, t.offset, "Expected close tag, got: %#v\n", end_token)
					return
				}

			case .Slash:
				/*
					Close tag.
				*/
				ident := expect(t, .Ident) or_return
				_      = expect(t, .Gt)    or_return

				if element.ident != ident.text {
					error(t, t.offset, "Mismatched Closing Tag. Expected %v, got %v\n", element.ident, ident.text)
					return doc, .Mismatched_Closing_Tag
				}
				parent      = element.parent
				element     = parent
				tag_is_open = false

			case:
				error(t, t.offset, "Invalid Token after <: %#v\n", open)
				return
			}

		case -1:
			/*
				End of file.
			*/
			if tag_is_open {
				return doc, .Premature_EOF
			}
			break loop

		case:
			/*
				This should be a tag's body text.
			*/
			body_text    := scan_string(t, t.offset) or_return
			element.value = strings.intern_get(&doc.intern, body_text)
		}
	}

	if .Must_Have_Prolog in opts.flags && len(doc.prolog) == 0 {
		return doc, .No_Prolog
	}

	if .Must_Have_DocType in opts.flags && len(doc.doctype.ident) == 0 {
		return doc, .No_DocType
	}

	return doc, .None
}

parse_from_file :: proc(filename: string, options := DEFAULT_Options, error_handler := default_error_handler, allocator := context.allocator) -> (doc: ^Document, err: Error) {
	context.allocator = allocator

	data, data_ok := os.read_entire_file(filename)
	defer delete(data)

	if !data_ok { return {}, .File_Error }

	return parse_from_slice(data, options, filename, error_handler, allocator)
}

parse :: proc { parse_from_file, parse_from_slice }

free_element :: proc(element: ^Element) {
	if element == nil { return }

	for child in element.children {
		/*
			NOTE: Recursive.

			Could be rewritten so it adds them to a list of pointers to free.
		*/
		free_element(child)
	}
	delete(element.attribs)
	delete(element.children)
	free(element)
}

destroy :: proc(doc: ^Document) {
	if doc == nil { return }

	free_element(doc.root)
	strings.intern_destroy(&doc.intern)

	delete(doc.prolog)
	delete(doc.comments)
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

	if .Unbox_CDATA in validated.flags {
		return options, .Unhandled_CDATA_Unboxing
	}

	if .Decode_SGML_Entities in validated.flags {
		return options, .Unhandled_SGML_Entity_Decoding
	}

	return validated, .None
}

expect :: proc(t: ^Tokenizer, kind: Token_Kind) -> (tok: Token, err: Error) {
	tok = scan(t)
	if tok.kind == kind { return tok, .None }

	error(t, t.offset, "Expected \"%v\", got \"%v\".", kind, tok.kind)
	return tok, .Unexpected_Token
}

parse_attribute :: proc(doc: ^Document) -> (attr: Attr, offset: int, err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	key    := expect(t, .Ident)  or_return
	offset  = t.offset - len(key.text)

	_       = expect(t, .Eq)     or_return
	value  := expect(t, .String) or_return

	error(t, t.offset, "String: %v\n", value)

	attr.key = strings.intern_get(&doc.intern, key.text)
	attr.val = strings.intern_get(&doc.intern, value.text)

	err = .None
	return
}

check_duplicate_attributes :: proc(t: ^Tokenizer, attribs: Attributes, attr: Attr, offset: int) -> (err: Error) {
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

parse_prolog :: proc(doc: ^Document) -> (err: Error) {
	assert(doc != nil)
	context.allocator = doc.allocator
	t := doc.tokenizer

	offset := t.offset
	parse_attributes(doc, &doc.prolog) or_return

	for attr in doc.prolog {
		switch attr.key {
		case "version":
			switch attr.val {
			case "1.0", "1.1":
			case:
				error(t, offset, "[parse_prolog] Warning: Unhandled XML version: %v\n", attr.val)
			}

		case "encoding":
			switch strings.to_lower(attr.val, context.temp_allocator) {
			case "utf-8", "utf8":
				doc.encoding = .UTF_8

			case "latin-1", "latin1", "iso-8859-1":
				doc.encoding = .LATIN_1

			case:
				/*
					Unrecognized encoding, assume UTF-8.
				*/
				error(t, offset, "[parse_prolog] Warning: Unrecognized encoding: %v\n", attr.val)
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
	doc.doctype.ident = strings.intern_get(&doc.intern, tok.text)

	skip_whitespace(t)
	offset := t.offset
	skip_element(t) or_return

	/*
		-1 because the current offset is that of the closing tag, so the rest of the DOCTYPE tag ends just before it.
	*/
	doc.doctype.rest = strings.intern_get(&doc.intern, string(t.src[offset : t.offset - 1]))
	return .None
}