package strings

import "core:mem"

Intern_Entry :: struct {
	len:  int,
	str:  [1]byte, // string is allocated inline with the entry to keep allocations simple
}

Intern :: struct {
	allocator: mem.Allocator,
	entries: map[string]^Intern_Entry,
}

intern_init :: proc(m: ^Intern, allocator := context.allocator, map_allocator := context.allocator) {
	m.allocator = allocator;
	m.entries = make(map[string]^Intern_Entry, 16, map_allocator);
}

intern_destroy :: proc(m: ^Intern) {
	for _, value in m.entries {
		free(value, m.allocator);
	}
	delete(m.entries);
}

intern_get :: proc(m: ^Intern, text: string) -> string {
	entry := _intern_get_entry(m, text);
	return #no_bounds_check string(entry.str[:entry.len]);
}
intern_get_cstring :: proc(m: ^Intern, text: string) -> cstring {
	entry := _intern_get_entry(m, text);
	return cstring(&entry.str[0]);
}

_intern_get_entry :: proc(m: ^Intern, text: string) -> ^Intern_Entry #no_bounds_check {
	if prev, ok := m.entries[text]; ok {
		return prev;
	}
	if m.allocator.procedure == nil {
		m.allocator = context.allocator;
	}

	entry_size := int(offset_of(Intern_Entry, str)) + len(text) + 1;
	new_entry := (^Intern_Entry)(mem.alloc(entry_size, align_of(Intern_Entry), m.allocator));

	new_entry.len = len(text);
	copy(new_entry.str[:new_entry.len], text);
	new_entry.str[new_entry.len] = 0;

	key := string(new_entry.str[:new_entry.len]);
	m.entries[key] = new_entry;
	return new_entry;
}
