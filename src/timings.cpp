struct TimeStamp {
	u64    start;
	u64    finish;
	String label;
};

struct Timings {
	TimeStamp        total;
	Array(TimeStamp) sections;
	u64              freq;
};


u64 win32_time_stamp_time_now(void) {
	LARGE_INTEGER counter;
	QueryPerformanceCounter(&counter);
	return counter.QuadPart;
}

u64 win32_time_stamp__freq(void) {
	gb_local_persist LARGE_INTEGER win32_perf_count_freq = {0};
	if (!win32_perf_count_freq.QuadPart) {
		QueryPerformanceFrequency(&win32_perf_count_freq);
		GB_ASSERT(win32_perf_count_freq.QuadPart != 0);
	}

	return win32_perf_count_freq.QuadPart;
}

u64 time_stamp_time_now(void) {
#if defined(GB_SYSTEM_WINDOWS)
	return win32_time_stamp_time_now();
#else
#error time_stamp_time_now
#endif
}

u64 time_stamp__freq(void) {
#if defined(GB_SYSTEM_WINDOWS)
	return win32_time_stamp__freq();
#else
#error time_stamp__freq
#endif
}

TimeStamp make_time_stamp(String label) {
	TimeStamp ts = {};
	ts.start = time_stamp_time_now();
	ts.label = label;
	return ts;
}

void timings_init(Timings *t, String label, isize buffer_size) {
	array_init_reserve(&t->sections, heap_allocator(), buffer_size);
	t->total = make_time_stamp(label);
	t->freq  = time_stamp__freq();
}

void timings_destroy(Timings *t) {
	array_free(&t->sections);
}

void timings__stop_current_section(Timings *t) {
	if (t->sections.count > 0) {
		t->sections.e[t->sections.count-1].finish = time_stamp_time_now();
	}
}

void timings_start_section(Timings *t, String label) {
	timings__stop_current_section(t);
	array_add(&t->sections, make_time_stamp(label));
}

f64 time_stamp_as_ms(TimeStamp ts, u64 freq) {
	GB_ASSERT_MSG(ts.finish >= ts.start, "time_stamp_as_ms - %.*s", LIT(ts.label));
	return 1000.0 * cast(f64)(ts.finish - ts.start) / cast(f64)freq;
}

void timings_print_all(Timings *t) {
	timings__stop_current_section(t);
	t->total.finish = time_stamp_time_now();

	char const SPACES[] = "                                                                ";

	isize max_len = t->total.label.len;
	for_array(i, t->sections) {
		TimeStamp ts = t->sections.e[i];
		max_len = gb_max(max_len, ts.label.len);
	}

	GB_ASSERT(max_len <= gb_size_of(SPACES)-1);

	gb_printf("%.*s%.*s - %.3f ms\n",
	          LIT(t->total.label),
	          cast(int)(max_len-t->total.label.len), SPACES,
	          time_stamp_as_ms(t->total, t->freq));

	for_array(i, t->sections) {
		TimeStamp ts = t->sections.e[i];
		gb_printf("%.*s%.*s - %.3f ms\n",
		          LIT(ts.label),
	              cast(int)(max_len-ts.label.len), SPACES,
		          time_stamp_as_ms(ts, t->freq));
	}
}
