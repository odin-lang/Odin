package xml
/*
	An XML 1.0 / 1.1 parser

	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

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
	using fmt

	written += wprintf(writer, "[XML Prolog]\n")

	for attr in doc.prolog {
		written += wprintf(writer, "\t%v: %v\n", attr.key, attr.val)
	}

	written += wprintf(writer, "[Encoding] %v\n", doc.encoding)
	written += wprintf(writer, "[DOCTYPE]  %v\n", doc.doctype.ident)

	if len(doc.doctype.rest) > 0 {
	 	wprintf(writer, "\t%v\n", doc.doctype.rest)
	}

	if doc.root != nil {
	 	wprintln(writer, " --- ")
	 	print_element(writer, doc.root)
	 	wprintln(writer, " --- ")		
	 }

	return written, .None
}

print_element :: proc(writer: io.Writer, element: ^Element, indent := 0) -> (written: int, err: io.Error) {
	if element == nil { return }
	using fmt

	tab :: proc(writer: io.Writer, indent: int) {
		for _ in 0..=indent {
			wprintf(writer, "\t")
		}
	}

	tab(writer, indent)

	if element.kind == .Element {
		wprintf(writer, "<%v>\n", element.ident)
		if len(element.value) > 0 {
			tab(writer, indent + 1)
			wprintf(writer, "[Value] %v\n", element.value)
		}

		for attr in element.attribs {
			tab(writer, indent + 1)
			wprintf(writer, "[Attr] %v: %v\n", attr.key, attr.val)
		}

		for child in element.children {
			print_element(writer, child, indent + 1)
		}
	} else if element.kind == .Comment {
		wprintf(writer, "[COMMENT] %v\n", element.value)
	}

	return written, .None
}