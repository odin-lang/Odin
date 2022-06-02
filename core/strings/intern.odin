package strings

import "core:runtime"

// custom string entry struct
Intern_Entry :: struct {
	len:  int,
	str:  [1]byte, // string is allocated inline with the entry to keep allocations simple
}

// "intern" is a more memory efficient string map
// `allocator` is used to allocate the actual `Intern_Entry` strings
Intern :: struct {
	allocator: runtime.Allocator,
	entries: map[string]^Intern_Entry,
}

// initialize the entries map and set the allocator for the string entries
intern_init :: proc(m: ^Intern, allocator := context.allocator, map_allocator := context.allocator) {
	m.allocator = allocator
	m.entries = make(map[string]^Intern_Entry, 16, map_allocator)
}

// free the map and all its content allocated using the `.allocator`
intern_destroy :: proc(m: ^Intern) {
	for _, value in m.entries {
		free(value, m.allocator)
	}
	delete(m.entries)
}

// returns the `text` string from the intern map - gets set if it didnt exist yet
// the returned string lives as long as the map entry lives
intern_get :: proc(m: ^Intern, text: string) -> string {
	entry := _intern_get_entry(m, text)
	#no_bounds_check return string(entry.str[:entry.len])
}

// returns the `text` cstring from the intern map - gets set if it didnt exist yet
// the returned cstring lives as long as the map entry lives
intern_get_cstring :: proc(m: ^Intern, text: string) -> cstring {
	entry := _intern_get_entry(m, text)
	return cstring(&entry.str[0])
}

// looks up wether the `text` string exists in the map, returns the entry
// sets & allocates the entry if it wasnt set yet
_intern_get_entry :: proc(m: ^Intern, text: string) -> ^Intern_Entry #no_bounds_check {
	if prev, ok := m.entries[text]; ok {
		return prev
	}
	if m.allocator.procedure == nil {
		m.allocator = context.allocator
	}

	entry_size := int(offset_of(Intern_Entry, str)) + len(text) + 1
	ptr, _ := runtime.mem_alloc(entry_size, align_of(Intern_Entry), m.allocator)
	new_entry := (^Intern_Entry)(ptr)

	new_entry.len = len(text)
	copy(new_entry.str[:new_entry.len], text)
	new_entry.str[new_entry.len] = 0

	key := string(new_entry.str[:new_entry.len])
	m.entries[key] = new_entry
	return new_entry
}
