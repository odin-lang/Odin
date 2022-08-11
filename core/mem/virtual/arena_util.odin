package mem_virtual

arena_init :: proc{
	static_arena_init,
	growing_arena_init,
}

arena_temp_begin :: proc{
	static_arena_temp_begin,
	growing_arena_temp_begin,
}

arena_temp_end :: proc{
	static_arena_temp_end,
	growing_arena_temp_end,
}

arena_check_temp :: proc{
	static_arena_check_temp,
	growing_arena_check_temp,
}

arena_allocator :: proc{
	static_arena_allocator,
	growing_arena_allocator,
}

arena_alloc :: proc{
	static_arena_alloc,
	growing_arena_alloc,
}

arena_free_all :: proc{
	static_arena_free_all,
	growing_arena_free_all,
}

arena_destroy :: proc{
	static_arena_destroy,
	growing_arena_destroy,
}