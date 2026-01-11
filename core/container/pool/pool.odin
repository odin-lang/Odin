package container_pool

import "base:intrinsics"
import "base:sanitizer"

import "core:mem"
import "core:sync"

_ :: sanitizer

DEFAULT_BLOCK_SIZE :: _DEFAULT_BLOCK_SIZE

Pool_Arena :: _Pool_Arena

/*
A thread-safe (between init and destroy) object pool backed by virtual growing arena returning stable pointers.
The element type requires an intrusive link node.

Example:
	Elem :: struct {
		link: ^Elem,
	}

	p: pool.Pool(Elem)
	pool.init(&p, "link")
*/
Pool :: struct($T: typeid) {
	arena:           Pool_Arena,
	num_outstanding: int,
	num_ready:       int,
	link_off:        uintptr,
	free_list:       ^T,
}

@(require_results)
init :: proc(p: ^Pool($T), $link_field: string, block_size: uint = DEFAULT_BLOCK_SIZE) -> (err: mem.Allocator_Error)
	where intrinsics.type_has_field(T, link_field),
	      intrinsics.type_field_type(T, link_field) == ^T {
	p.link_off = offset_of_by_string(T, link_field)
	return _pool_arena_init(&p.arena, block_size)
}

destroy :: proc(p: ^Pool($T)) {
	for elem := p.free_list; elem != nil; elem = _get_next(p, elem) {
		_unpoison_elem(p, elem)
		free(elem, _pool_arena_allocator(&p.arena))
	}

	_pool_arena_destroy(&p.arena)
}

@(require_results)
get :: proc(p: ^Pool($T)) -> (elem: ^T, err: mem.Allocator_Error) #optional_allocator_error {
	sync.atomic_add_explicit(&p.num_outstanding, 1, .Relaxed)

	for {
		elem = sync.atomic_load(&p.free_list)
		if elem == nil {
			// NOTE: pool arena has an internal lock.
			return new(T, _pool_arena_allocator(&p.arena))
		}

		if _, ok := sync.atomic_compare_exchange_weak(&p.free_list, elem, _get_next(p, elem)); ok {
			_set_next(p, elem, nil)
			_unpoison_elem(p, elem)
			sync.atomic_sub_explicit(&p.num_ready, 1, .Relaxed)
			return
		}
	}
}

put :: proc(p: ^Pool($T), elem: ^T) {
	mem.zero_item(elem)
	_poison_elem(p, elem)

	defer sync.atomic_sub_explicit(&p.num_outstanding, 1, .Relaxed)
	defer sync.atomic_add_explicit(&p.num_ready, 1, .Relaxed)

	for {
		head := sync.atomic_load(&p.free_list)
		_set_next(p, elem, head)
		if _, ok := sync.atomic_compare_exchange_weak(&p.free_list, head, elem); ok {
			return
		}
	}
}

num_outstanding :: proc(p: ^Pool($T)) -> int {
	return sync.atomic_load(&p.num_outstanding)
}

num_ready :: proc(p: ^Pool($T)) -> int {
	return sync.atomic_load(&p.num_ready)
}

cap :: proc(p: ^Pool($T)) -> int {
	return sync.atomic_load(&p.num_ready) + sync.atomic_load(&p.num_outstanding)
}

_get_next :: proc(p: ^Pool($T), elem: ^T) -> ^T {
	return (^^T)(uintptr(elem) + p.link_off)^
}

_set_next :: proc(p: ^Pool($T), elem: ^T, next: ^T) {
	(^^T)(uintptr(elem) + p.link_off)^ = next
}

@(disabled=.Address not_in ODIN_SANITIZER_FLAGS)
_poison_elem :: proc(p: ^Pool($T), elem: ^T) {
	if p.link_off > 0 {
		sanitizer.address_poison_rawptr(elem, int(p.link_off))
	}

	len := size_of(T) - p.link_off - size_of(rawptr)
	if len > 0 {
		ptr := rawptr(uintptr(elem) + p.link_off + size_of(rawptr))
		sanitizer.address_poison_rawptr(ptr, int(len))
	}
}

@(disabled=.Address not_in ODIN_SANITIZER_FLAGS)
_unpoison_elem :: proc(p: ^Pool($T), elem: ^T) {
	if p.link_off > 0 {
		sanitizer.address_unpoison_rawptr(elem, int(p.link_off))
	}

	len := size_of(T) - p.link_off - size_of(rawptr)
	if len > 0 {
		ptr := rawptr(uintptr(elem) + p.link_off + size_of(rawptr))
		sanitizer.address_unpoison_rawptr(ptr, int(len))
	}
}
