package c_frontend_tokenizer

// NOTE(bill): This is a really dumb approach for a hide set,
// but it's really simple and probably fast enough in practice


Hide_Set :: struct {
	next: ^Hide_Set,
	name: string,
}


new_hide_set :: proc(name: string) -> ^Hide_Set {
	hs := new(Hide_Set)
	hs.name = name
	return hs
}

hide_set_contains :: proc(hs: ^Hide_Set, name: string) -> bool {
	for h := hs; h != nil; h = h.next {
		if h.name == name {
			return true
		}
	}
	return false
}


hide_set_union :: proc(a, b: ^Hide_Set) -> ^Hide_Set {
	head: Hide_Set
	curr := &head

	for h := a; h != nil; h = h.next {
		curr.next = new_hide_set(h.name)
		curr = curr.next
	}
	curr.next = b
	return head.next
}


hide_set_intersection :: proc(a, b: ^Hide_Set) -> ^Hide_Set {
	head: Hide_Set
	curr := &head

	for h := a; h != nil; h = h.next {
		if hide_set_contains(b, h.name) {
			curr.next = new_hide_set(h.name)
			curr = curr.next
		}
	}
	return head.next
}


add_hide_set :: proc(tok: ^Token, hs: ^Hide_Set) -> ^Token {
	head: Token
	curr := &head

	tok := tok
	for ; tok != nil; tok = tok.next {
		t := copy_token(tok)
		t.hide_set = hide_set_union(t.hide_set, hs)
		curr.next = t
		curr = curr.next
	}
	return head.next
}
