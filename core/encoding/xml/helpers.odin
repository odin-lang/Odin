package xml
/*
	An XML 1.0 / 1.1 parser

	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	This file contains helper functions.
*/


/*
	Find `tag`'s nth child with a given ident.
*/
find_child_by_ident :: proc(tag: ^Element, ident: string, nth := 0) -> (res: ^Element, found: bool) {
	if tag == nil                                 { return nil, false }

	count := 0
	for child in tag.children {
		/*
			Skip commments. They have no name.
		*/
		if child.kind  != .Element                { continue }

		/*
			If the ident matches and it's the nth such child, return it.
		*/
		if child.ident == ident {
			if count == nth                       { return child, true }
			count += 1
		}
	}
	return nil, false
}

/*
	Find an attribute by key.
*/
find_attribute_val_by_key :: proc(tag: ^Element, key: string) -> (val: string, found: bool) {
	if tag == nil            { return "", false }

	for attr in tag.attribs {
		/*
			If the ident matches, we're done. There can only ever be one attribute with the same name.
		*/
		if attr.key == key { return attr.val, true }
	}
	return "", false
}