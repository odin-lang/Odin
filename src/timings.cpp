struct TimeStamp {
	u64    start;
	u64    finish;
	String label;
};

struct Timings {
	TimeStamp        total;
	Array<TimeStamp> sections;
	u64              freq;
	f64              total_time_seconds;
};


#if defined(GB_SYSTEM_WINDOWS)
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

#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)

#include <time.h>

u64 unix_time_stamp_time_now(void) {
	struct timespec ts;
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts);

	return (ts.tv_sec * 1000000000) + ts.tv_nsec;
}

u64 unix_time_stamp__freq(void) {
	gb_local_persist u64 freq = 0;

	if (freq == 0) {
		struct timespec ts;
		clock_getres(CLOCK_PROCESS_CPUTIME_ID, &ts);
		freq = cast(u64) ((1.0 / ts.tv_nsec) * 1000000000.0);
	}

	return freq;
}

#else
#error Implement system
#endif

u64 time_stamp_time_now(void) {
#if defined(GB_SYSTEM_WINDOWS)
	return win32_time_stamp_time_now();
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
	return unix_time_stamp_time_now();
#else
#error time_stamp_time_now
#endif
}

u64 time_stamp__freq(void) {
#if defined(GB_SYSTEM_WINDOWS)
	return win32_time_stamp__freq();
#elif defined(GB_SYSTEM_OSX) || defined(GB_SYSTEM_UNIX)
	return unix_time_stamp__freq();
#else
#error time_stamp__freq
#endif
}

TimeStamp make_time_stamp(String label) {
	TimeStamp ts = {0};
	ts.start = time_stamp_time_now();
	ts.label = label;
	return ts;
}

void timings_init(Timings *t, String label, isize buffer_size) {
	array_init(&t->sections, heap_allocator(), buffer_size);
	t->total = make_time_stamp(label);
	t->freq  = time_stamp__freq();
}

void timings_destroy(Timings *t) {
	array_free(&t->sections);
}

void timings__stop_current_section(Timings *t) {
	if (t->sections.count > 0) {
		t->sections[t->sections.count-1].finish = time_stamp_time_now();
	}
}

void timings_start_section(Timings *t, String label) {
	timings__stop_current_section(t);
	array_add(&t->sections, make_time_stamp(label));
}

f64 time_stamp_as_second(TimeStamp ts, u64 freq) {
	GB_ASSERT_MSG(ts.finish >= ts.start, "time_stamp_as_ms - %.*s", LIT(ts.label));
	return cast(f64)(ts.finish - ts.start) / cast(f64)freq;
}

f64 time_stamp_as_ms(TimeStamp ts, u64 freq) {
	return 1000.0*time_stamp_as_second(ts, freq);
}

void timings_print_all(Timings *t) {
	char const SPACES[] = "                                                                ";
	isize max_len;

	timings__stop_current_section(t);
	t->total.finish = time_stamp_time_now();

	max_len = t->total.label.len;
	for_array(i, t->sections) {
		TimeStamp ts = t->sections[i];
		max_len = gb_max(max_len, ts.label.len);
	}

	GB_ASSERT(max_len <= gb_size_of(SPACES)-1);

	t->total_time_seconds = time_stamp_as_second(t->total, t->freq);

	f64 total_ms = time_stamp_as_ms(t->total, t->freq);

	gb_printf("%.*s%.*s - % 9.3f ms - %6.2f%%\n",
	          LIT(t->total.label),
	          cast(int)(max_len-t->total.label.len), SPACES,
	          total_ms,
	          cast(f64)100.0);

	for_array(i, t->sections) {
		TimeStamp ts = t->sections[i];
		f64 section_ms = time_stamp_as_ms(ts, t->freq);
		gb_printf("%.*s%.*s - % 9.3f ms - %6.2f%%\n",
		          LIT(ts.label),
	              cast(int)(max_len-ts.label.len), SPACES,
		          section_ms, 100*section_ms/total_ms);
	}
}
