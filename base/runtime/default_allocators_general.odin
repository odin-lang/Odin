package runtime

when ODIN_DEFAULT_TO_NIL_ALLOCATOR {
	default_allocator_proc :: nil_allocator_proc
	default_allocator :: nil_allocator
} else when ODIN_DEFAULT_TO_PANIC_ALLOCATOR {
	default_allocator_proc :: panic_allocator_proc
	default_allocator :: panic_allocator
} else {
	default_allocator :: heap_allocator
	default_allocator_proc :: heap_allocator_proc
}
