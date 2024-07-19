package strings

import "base:runtime"
import "core:mem"

// Custom string entry struct
Intern_Entry :: struct {
	len:  int,
	str:  [1]byte, // string is allocated inline with the entry to keep allocations simple
}
/*
Intern is a more memory efficient string map

Uses Specified Allocator for `Intern_Entry` strings

Fields:
- allocator: The allocator used for the Intern_Entry strings
- entries: A map of strings to interned string entries
*/
Intern :: struct {
	allocator: runtime.Allocator,
	entries: map[string]^Intern_Entry,
}
/*
Initializes the entries map and sets the allocator for the string entries

*Allocates Using Provided Allocators*

Inputs:
- m: A pointer to the Intern struct to be initialized
- allocator: The allocator for the Intern_Entry strings (Default: context.allocator)
- map_allocator: The allocator for the map of entries (Default: context.allocator)

Returns:
- err: An allocator error if one occured, `nil` otherwise
*/
intern_init :: proc(m: ^Intern, allocator := context.allocator, map_allocator := context.allocator, loc := #caller_location) -> (err: mem.Allocator_Error) {
	m.allocator = allocator
	m.entries = make(map[string]^Intern_Entry, 16, map_allocator, loc) or_return
	return nil
}
/*
Frees the map and all its content allocated using the `.allocator`.

Inputs:
- m: A pointer to the Intern struct to be destroyed
*/
intern_destroy :: proc(m: ^Intern) {
	for _, value in m.entries {
		free(value, m.allocator)
	}
	delete(m.entries)
}
/*
Returns an interned copy of the given text, adding it to the map if not already present.

*Allocate using the Intern's Allocator (First time string is seen only)*

Inputs:
- m: A pointer to the Intern struct
- text: The string to be interned

NOTE: The returned string lives as long as the map entry lives.

Returns:
- str: The interned string
- err: An allocator error if one occured, `nil` otherwise
*/
intern_get :: proc(m: ^Intern, text: string) -> (str: string, err: runtime.Allocator_Error) {
	entry := _intern_get_entry(m, text) or_return
	#no_bounds_check return string(entry.str[:entry.len]), nil
}
/*
Returns an interned copy of the given text as a cstring, adding it to the map if not already present.

*Allocate using the Intern's Allocator  (First time string is seen only)*

Inputs:
- m: A pointer to the Intern struct
- text: The string to be interned

NOTE: The returned cstring lives as long as the map entry lives

Returns:
- str: The interned cstring
- err: An allocator error if one occured, `nil` otherwise
*/
intern_get_cstring :: proc(m: ^Intern, text: string) -> (str: cstring, err: runtime.Allocator_Error) {
	entry := _intern_get_entry(m, text) or_return
	return cstring(&entry.str[0]), nil
}
/*
Internal function to lookup whether the text string exists in the map, returns the entry
Sets and allocates the entry if it wasn't set yet

*Allocate using the Intern's Allocator  (First time string is seen only)*

Inputs:
- m: A pointer to the Intern struct
- text: The string to be looked up or interned

Returns:
- new_entry: The interned cstring
- err: An allocator error if one occured, `nil` otherwise
*/
_intern_get_entry :: proc(m: ^Intern, text: string) -> (new_entry: ^Intern_Entry, err: runtime.Allocator_Error) #no_bounds_check {
	if prev, ok := m.entries[text]; ok {
		return prev, nil
	}
	if m.allocator.procedure == nil {
		m.allocator = context.allocator
	}

	entry_size := int(offset_of(Intern_Entry, str)) + len(text) + 1
	bytes := runtime.mem_alloc(entry_size, align_of(Intern_Entry), m.allocator) or_return
	new_entry = (^Intern_Entry)(raw_data(bytes))

	new_entry.len = len(text)
	copy(new_entry.str[:new_entry.len], text)
	new_entry.str[new_entry.len] = 0

	key := string(new_entry.str[:new_entry.len])
	m.entries[key] = new_entry
	return new_entry, nil
}
