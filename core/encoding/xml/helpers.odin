package encoding_xml

/*
	An XML 1.0 / 1.1 parser

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	This file contains helper functions.
*/


// Find parent's nth child with a given ident.
find_child_by_ident :: proc(doc: ^Document, parent_id: Element_ID, ident: string, nth := 0) -> (res: Element_ID, found: bool) {
	tag := doc.elements[parent_id]

	count := 0
	for v in tag.value {
		switch child_id in v {
		case string: continue
		case Element_ID:
			child := doc.elements[child_id]
			/*
				Skip commments. They have no name.
			*/
			if child.kind != .Element { continue }

			/*
				If the ident matches and it's the nth such child, return it.
			*/
			if child.ident == ident {
				if count == nth { return child_id, true }
				count += 1
			}
		}

	}
	return 0, false
}

// Find an attribute by key.
find_attribute_val_by_key :: proc(doc: ^Document, parent_id: Element_ID, key: string) -> (val: string, found: bool) {
	tag := doc.elements[parent_id]

	for attr in tag.attribs {
		/*
			If the ident matches, we're done. There can only ever be one attribute with the same name.
		*/
		if attr.key == key { return attr.val, true }
	}
	return "", false
}
