package encoding_xml

/*
	An XML 1.0 / 1.1 parser

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	A from-scratch XML implementation, loosely modeled on the [spec](https://www.w3.org/TR/2006/REC-xml11-20060816).

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/


import "core:io"
import "core:fmt"

/*
	Just for debug purposes.
*/
print :: proc(writer: io.Writer, doc: ^Document) -> (written: int, err: io.Error) {
	if doc == nil { return }
	write_strings(writer, &written, "[XML Prolog]\n") or_return

	for attr in doc.prologue {
		write_strings(writer, &written, "\t", attr.key, ": ", attr.val, "\n") or_return
	}

	encoding, _ := fmt.enum_value_to_string(doc.encoding)
	write_strings(writer, &written, "[Encoding] ", encoding, "\n") or_return

	if len(doc.doctype.ident) > 0 {
		write_strings(writer, &written, "[DOCTYPE]  ", doc.doctype.ident, "\n") or_return

		if len(doc.doctype.rest) > 0 {
			write_strings(writer, &written, "\t", doc.doctype.rest, "\n") or_return
		}
	}

	for comment in doc.comments {
		write_strings(writer, &written, "[Pre-root comment]  ", comment, "\n") or_return
	}

	if len(doc.elements) > 0 {
		write_strings(writer, &written, " --- \n") or_return
		n: int
		n, err = print_element(writer, doc, 0)
		written += n
		if err != nil { return }
		write_strings(writer, &written, " --- \n") or_return
	}

	return
}

print_element :: proc(writer: io.Writer, doc: ^Document, element_id: Element_ID, indent := 0) -> (written: int, err: io.Error) {
	tab :: proc(writer: io.Writer, written: ^int, indent: int) -> io.Error {
		for _ in 0..=indent {
			write_strings(writer, written, "\t") or_return
		}
		return nil
	}

	tab(writer, &written, indent) or_return

	element := doc.elements[element_id]

	if element.kind == .Element {
		write_strings(writer, &written, "<", element.ident, ">\n") or_return

		for value in element.value {
			switch v in value {
			case string:
				tab(writer, &written, indent + 1) or_return
				write_strings(writer, &written, "[Value] ", v, "\n") or_return
			case Element_ID:
				n: int
				n, err = print_element(writer, doc, v, indent + 1)
				written += n
				if err != nil { return }
			}
		}

		for attr in element.attribs {
			tab(writer, &written, indent + 1) or_return
			write_strings(writer, &written, "[Attr] ", attr.key, ": ", attr.val, "\n") or_return
		}
	} else if element.kind == .Comment {
		write_strings(writer, &written, "[COMMENT] ") or_return
		for value in element.value {
			if text, is_text := value.(string); is_text {
				write_strings(writer, &written, text) or_return
			}
		}
		write_strings(writer, &written, "\n") or_return
	}

	return
}

@(private)
write_strings :: proc(writer: io.Writer, written: ^int, parts: ..string) -> io.Error {
	for s in parts {
		io.write_string(writer, s, written) or_return
	}
	return nil
}
