package xml
/*
	An XML 1.0 / 1.1 parser

	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A from-scratch XML implementation, loosely modeled on the [spec](https://www.w3.org/TR/2006/REC-xml11-20060816).

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import "core:fmt"

/*
	Just for debug purposes.
*/
print :: proc(doc: ^Document) {
	assert(doc != nil)

	using fmt
	println("[XML Prolog]")

	for attr in doc.prolog {
		printf("\t%v: %v\n", attr.key, attr.val)
	}

	printf("[Encoding] %v\n",  doc.encoding)
	printf("[DOCTYPE]  %v\n",  doc.doctype.ident)

	if len(doc.doctype.rest) > 0 {
		printf("\t%v\n", doc.doctype.rest)
	}

	if doc.root != nil {
		println(" --- ")
		print_element(0, doc.root)
		println(" --- ")		
	}
}

print_element :: proc(indent: int, element: ^Element) {
	if element == nil { return }
	using fmt

	tab :: proc(indent: int) {
		tabs := "\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"

		i := max(0, min(indent, len(tabs)))
		printf("%v", tabs[:i])
	}

	tab(indent)

	if element.kind == .Element {
		printf("<%v>\n", element.ident)
		if len(element.value) > 0 {
			tab(indent + 1)
			printf("[Value] %v\n", element.value)
		}

		for attr in element.attribs {
			tab(indent + 1)
			printf("[Attr] %v: %v\n", attr.key, attr.val)
		}

		for child in element.children {
			print_element(indent + 1, child)
		}
	} else if element.kind == .Comment {
		printf("[COMMENT] %v\n", element.value)
	}
}