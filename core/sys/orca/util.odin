package orca

import "core:c"
import "core:fmt"
import "core:runtime"
import "core:intrinsics"

//----------------------------------------------------------------
// Arenas
//----------------------------------------------------------------

mem_reserve_proc :: proc "c" (ctx: ^base_allocator, size: u64)
mem_modify_proc :: proc "c" (ctx: ^base_allocator, ptr: rawptr, size: u64) 

base_allocator :: struct {
	reserve: mem_reserve_proc,
	commit: mem_modify_proc,
	decommit: mem_modify_proc,
	release: mem_modify_proc,
}

arena_chunk :: struct {
	listElt: list_elt,
	ptr: ^c.char,
	offset: u64,
	committed: u64,
	cap: u64,
}

arena :: struct {
	base: ^base_allocator,
	chunks: list,
	currentChunk: ^arena_chunk,
}

arena_scope :: struct {
	arena: ^arena,
	chunk: ^arena_chunk,
	offset: u64,
}

arena_options :: struct {
	base: ^base_allocator,
	reserve: u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	arena_init :: proc(arena: ^arena) ---
	arena_init_with_options :: proc(arena: ^arena, options: ^arena_options) ---
	arena_cleanup :: proc(arena: ^arena) ---

	arena_push :: proc(arena: ^arena, size: u64) -> rawptr ---
	arena_clear :: proc(arena: ^arena) ---

	arena_scope_begin :: proc(arena: ^arena) -> arena_scope ---
	arena_scope_end :: proc(scope: arena_scope) ---

	scratch_begin :: proc() -> arena_scope ---
	scratch_begin_next :: proc(used: ^arena) -> arena_scope ---
}

arena_push_type :: proc "c" (arena: ^arena, $T: typeid) -> ^T {
	return cast(^T) arena_push(arena, size_of(T))
}

arena_push_array :: proc "c" (arena: ^arena, $T: typeid, count: int) -> []T {
	return ([^]T)(arena_push(arena, size_of(T)))[:count]
}

scratch_end :: arena_scope_end

//----------------------------------------------------------------
// Pool
//----------------------------------------------------------------

pool :: struct {
	arena: arena,
	freeList: list,
	blockSize: u64,
}

pool_options :: struct {
	base: ^base_allocator,
	reserve: u64,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	pool_init :: proc(pool: ^pool, blockSize: u64) ---
	pool_init_with_options :: proc(pool: ^pool, blockSize: u64, options: ^pool_options) ---
	pool_cleanup :: proc(pool: ^pool) ---

	pool_alloc :: proc(pool: ^pool) -> rawptr ---
	pool_recycle :: proc(pool: ^pool, ptr: rawptr) ---
	pool_clear :: proc(pool: ^pool) ---
}

pool_alloc_type :: proc "c" (arena: ^arena, $T: typeid) -> ^T {
	return cast(^T) pool_alloc(arena)
}

// TODO support list macros?
// #define list_entry :: proc(ptr, type, member)
// #define list_next_entry :: proc(list, elt, type, member)
// #define list_prev_entry :: proc(list, elt, type, member)
// #define list_first_entry :: proc(list, type, member)
// #define list_last_entry :: proc(list, type, member)
// #define list_pop_entry :: proc(list, type, member)

// @(default_calling_convention="c", link_prefix="oc_")
// foreign {
// 	list_init :: proc(list: ^list) ---
// 	list_empty :: proc(list: ^list) -> c.bool ---

// 	list_begin :: proc(list: ^list) -> ^list_elt ---
// 	list_end :: proc(list: ^list) -> ^list_elt ---
// 	list_last :: proc(list: ^list) -> ^list_elt ---

// 	list_insert :: proc(list: ^list, afterElt: ^list_elt, elt: ^list_elt) ---
// 	list_insert_before :: proc(list: ^list, beforeElt: ^list_elt, elt: ^list_elt) ---
// 	list_remove :: proc(list: ^list, elt: ^list_elt) ---
// 	list_push :: proc(list: ^list, elt: ^list_elt) ---
// 	list_pop :: proc(list: ^list) -> ^list_elt ---
// 	list_push_back :: proc(list: ^list, elt: ^list_elt) ---
// 	list_pop_back :: proc(list: ^list) -> ^list_elt ---
// }

//------------------------------------------------------------------------------------------
// for iterators
//------------------------------------------------------------------------------------------

List_Iterator :: struct($T: typeid) {
	iterate: ^list,
	curr: ^list_elt,
	index: int,
	offset: uintptr,
}

// NOTE(Skytrias): intrusive list iterator
list_iter_init :: proc "c" (iterate: ^list, $T: typeid, $field_name: string) -> (res: List_Iterator(T))
	where intrinsics.type_has_field(T, field_name),
	      intrinsics.type_field_type(T, field_name) == list_elt {
	res.iterate = iterate
	res.curr = list_begin(iterate)
	res.offset = offset_of_by_string(T, field_name)
	return
}

list_iterate :: proc "c" (iter: ^List_Iterator($T)) -> (ptr: ^T, ok: bool) {
	node := iter.curr
	if node == nil {
		return nil, false
	}
	iter.index += 1
	iter.curr = node.next
	return (^T)(uintptr(node) - iter.offset), true
}

//----------------------------------------------------------------
// Strings / string lists / path strings
//----------------------------------------------------------------

// TODO use odin cstring when ^c.char is used?

str8 :: string
str32 :: []rune

str8_list :: struct {
	list: list,
	eltCount: u64,
	len: u64,
}

str8_elt :: struct {
	str: str8,
	listElt: list_elt,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	str8_push_buffer :: proc(arena: ^arena, len: u64, buffer: ^c.char) -> str8 ---
	str8_push_cstring :: proc(arena: ^arena, str: ^c.char) -> str8 ---
	str8_push_copy :: proc(arena: ^arena, s: str8) -> str8 ---
	str8_push_slice :: proc(arena: ^arena, s: str8, start: u64, end: u64) -> str8 ---
	
	// TODO get rid of these or wrap them
	str8_pushfv :: proc(arena: ^arena, format: cstring, args: c.va_list) -> str8 ---
	str8_pushf :: proc(arena: ^arena, format: cstring, #c_vararg args: ..any) -> str8 ---

	str8_to_cstring :: proc(arena: ^arena, string: str8) -> ^c.char ---

	str8_list_push :: proc(arena: ^arena, list: ^str8_list, str: str8) ---
	str8_list_pushf :: proc(arena: ^arena, list: ^str8_list, format: cstring, #c_vararg args: ..any) ---

	str8_list_collate :: proc(arena: ^arena, list: str8_list, prefix: str8, separator: str8, postfix: str8) -> str8 ---
	str8_list_join :: proc(arena: ^arena, list: str8_list) -> str8 ---
	str8_split :: proc(arena: ^arena, str: str8, separators: str8_list) -> str8_list ---

	path_slice_directory :: proc(path: str8) -> str8 ---
	path_slice_filename :: proc(path: str8) -> str8 ---
	path_split :: proc(arena: ^arena, path: str8) -> str8_list ---
	path_join :: proc(arena: ^arena, elements: str8_list) -> str8 ---
	path_append :: proc(arena: ^arena, parent: str8, relPath: str8) -> str8 ---
	path_is_absolute :: proc(path: str8) -> bool ---
}

//----------------------------------------------------------------
// Logging
//----------------------------------------------------------------

// TODO proper odin formatted strings

log_level :: enum c.int {
	ERROR,
	WARNING,
	INFO,
}

@(default_calling_convention="c", link_prefix="oc_")
foreign {
	log_ext :: proc(
		level: log_level,
		function: cstring,
		file: cstring,
		line: c.int,
		fmt: cstring,
		#c_vararg args: ..any,
	) ---
}

log_proc: [1028]u8
log_file: [1028]u8

log_temp :: proc "c" (loc: runtime.Source_Code_Location) -> (function, file: cstring) {
	copy(log_proc[:], loc.procedure)
	log_proc[len(loc.procedure)] = 0
	function = cstring(&log_proc[0])
	
	copy(log_file[:], loc.file_path)
	log_file[len(loc.file_path)] = 0
	file = cstring(&log_file[0])

	return
}

log_info :: proc "c" (format: cstring, args: ..any, loc := #caller_location) {
	function, file := log_temp(loc)
	// final := fmt.ctprintf(format, ..args)
	// log_ext(.INFO, function, file, loc.line, final, {})
	log_ext(.INFO, function, file, loc.line, format, {})
}

log_warning :: proc "c" (format: cstring, args: ..any, loc := #caller_location) {
	function, file := log_temp(loc)
	// final := fmt.ctprintf(format, ..args)
	// log_ext(.WARNING, function, file, loc.line, final, {})
	log_ext(.WARNING, function, file, loc.line, format, {})
}

log_error :: proc "c" (format: cstring, args: ..any, loc := #caller_location) {
	function, file := log_temp(loc)
	// final := fmt.ctprintf(format, ..args)
	// log_ext(.ERROR, function, file, loc.line, final, {})
	log_ext(.ERROR, function, file, loc.line, format, {})
}
