// #define PROF_TIMINGS

struct ProfInfo {
	String  name;
	HashKey hash;
	i32     count;
	i64     total_time;
};

struct Profiler {
	Map<ProfInfo> info; // Key: String
	isize max_name_len;
	i64 start_time;
};

gb_global Profiler global_profiler;

i64 prof_get_timestamp(void) {
	LARGE_INTEGER counter;
	QueryPerformanceCounter(&counter);
	return counter.QuadPart;
}

void prof_init(void) {
#if defined(PROF_TIMINGS)
	map_init(&global_profiler.info, gb_heap_allocator());
	global_profiler.start_time = prof_get_timestamp();
#endif
}




ProfInfo prof_begin(String name) {
	ProfInfo info = {};
	info.name = name;
	info.hash = hash_pointer(name.text); // NOTE(bill): Requires it to be unique

	info.total_time = prof_get_timestamp();
	return info;
}

void prof_end(ProfInfo info) {
	i64 dt = prof_get_timestamp() - info.total_time;
	info.total_time = dt;

	auto *found = map_get(&global_profiler.info, info.hash);
	if (found) {
		found->count++;
		found->total_time += info.total_time;
	} else {
		info.count++;
		map_set(&global_profiler.info, info.hash, info);
		if (global_profiler.max_name_len < info.name.len) {
			global_profiler.max_name_len = info.name.len;
		}
	}
}

struct ScopedProfInfo {
	ProfInfo info;
	ScopedProfInfo(String name) {
		info = prof_begin(name);
	}
	~ScopedProfInfo() {
		prof_end(info);
	}
};

#if defined(PROF_TIMINGS)
#define PROF_SCOPED(msg) ScopedProfInfo scoped_prof_info_##__COUNTER__ = ScopedProfInfo(make_string(cast(u8 *)msg, gb_size_of(msg)-1))
#else
#define PROF_SCOPED(msg) do {} while (0)
#endif
#define PROF_PROC() PROF_SCOPED(__FUNCTION__)

void prof_print_all(void) {
#if defined(PROF_TIMINGS)
	LARGE_INTEGER win32_perf_count_freq = {0};
	QueryPerformanceFrequency(&win32_perf_count_freq);
	GB_ASSERT(win32_perf_count_freq.QuadPart != 0);

	gb_printf("Profiler Timings\n");

	i32 string_offset = cast(int)global_profiler.max_name_len;
	char spaces[]  = "                                                                                ";
	char dashses[] = "--------------------------------------------------------------------------------";
	isize pad_len = gb_size_of(spaces)-1;

	isize info_count = global_profiler.info.entries.count;
	ProfInfo *info_data = gb_alloc_array(gb_heap_allocator(), ProfInfo, info_count);
	defer (gb_free(gb_heap_allocator(), info_data));
	for (isize i = 0; i < info_count; i++) {
		info_data[i] = global_profiler.info.entries[i].value;
	}

	gb_sort_array(info_data, info_count, gb_i64_cmp(gb_offset_of(ProfInfo, total_time)));

	for (isize i = info_count-1; i >= 0; i--) {
		auto entry = info_data + i;
		f64 dt = (1000.0*entry->total_time / cast(f64)win32_perf_count_freq.QuadPart);
		int pad = global_profiler.max_name_len - entry->name.len;
		pad = gb_max(pad, 0);
		gb_printf("%.*s%*.*s - %.3f ms - %.3f us\n",
		          LIT(entry->name),
		          pad, pad, spaces,
		          dt, 1000.0*dt/cast(f64)entry->count);
	}

	i64 total_time = prof_get_timestamp() - global_profiler.start_time;
	f64 total_time_ms = (1000.0*total_time / cast(f64)win32_perf_count_freq.QuadPart);


	gb_printf("%*.*s\n"
	          "%*.*s   %.3f ms\n",
	          global_profiler.max_name_len, global_profiler.max_name_len, dashses,
	          global_profiler.max_name_len, global_profiler.max_name_len, spaces,
	          total_time_ms);
#endif
}
