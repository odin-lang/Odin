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
gb_internal u64 win32_time_stamp_time_now(void) {
	LARGE_INTEGER counter;
	QueryPerformanceCounter(&counter);
	return counter.QuadPart;
}

gb_internal u64 win32_time_stamp__freq(void) {
	gb_local_persist LARGE_INTEGER win32_perf_count_freq = {0};
	if (!win32_perf_count_freq.QuadPart) {
		QueryPerformanceFrequency(&win32_perf_count_freq);
		GB_ASSERT(win32_perf_count_freq.QuadPart != 0);
	}

	return win32_perf_count_freq.QuadPart;
}

#elif defined(GB_SYSTEM_OSX)

#include <mach/mach_time.h>

gb_internal mach_timebase_info_data_t osx_init_timebase_info(void) {
	mach_timebase_info_data_t data;
	data.numer = 0;
	data.denom = 0;
	kern_return_t r = mach_timebase_info(&data);
	GB_ASSERT(r == KERN_SUCCESS);

	return data;
}

gb_internal u64 osx_time_stamp_time_now(void) {
	return mach_absolute_time();
}

gb_internal u64 osx_time_stamp__freq(void) {
	gb_local_persist mach_timebase_info_data_t data = osx_init_timebase_info();
	return 1000000000ull * cast(u64)data.denom / cast(u64)data.numer;
}

#elif defined(GB_SYSTEM_UNIX)

#include <time.h>

gb_internal u64 unix_time_stamp_time_now(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);

	return (ts.tv_sec * 1000000000) + ts.tv_nsec;
}

gb_internal u64 unix_time_stamp__freq(void) {
	gb_local_persist u64 freq = 0;

	if (freq == 0) {
		struct timespec ts;
		clock_getres(CLOCK_MONOTONIC, &ts);
		freq = cast(u64) ((1.0 / ts.tv_nsec) * 1000000000.0);
	}

	return freq;
}



#else
#error Implement system
#endif

gb_internal u64 time_stamp_time_now(void) {
#if defined(GB_SYSTEM_WINDOWS)
	return win32_time_stamp_time_now();
#elif defined(GB_SYSTEM_OSX)
	return osx_time_stamp_time_now();
#elif defined(GB_SYSTEM_UNIX)
	return unix_time_stamp_time_now();
#else
#error time_stamp_time_now
#endif
}

gb_internal u64 time_stamp__freq(void) {
#if defined(GB_SYSTEM_WINDOWS)
	return win32_time_stamp__freq();
#elif defined(GB_SYSTEM_OSX)
	return osx_time_stamp__freq();
#elif defined(GB_SYSTEM_UNIX)
	return unix_time_stamp__freq();
#else
#error time_stamp__freq
#endif
}

gb_internal TimeStamp make_time_stamp(String const &label) {
	TimeStamp ts = {0};
	ts.start = time_stamp_time_now();
	ts.label = label;
	return ts;
}

gb_internal void timings_init(Timings *t, String const &label, isize buffer_size) {
	array_init(&t->sections, heap_allocator(), 0, buffer_size);
	t->total = make_time_stamp(label);
	t->freq  = time_stamp__freq();
}

gb_internal void timings_destroy(Timings *t) {
	array_free(&t->sections);
}

gb_internal void timings__stop_current_section(Timings *t) {
	if (t->sections.count > 0) {
		t->sections[t->sections.count-1].finish = time_stamp_time_now();
	}
}

gb_internal void timings_start_section(Timings *t, String const &label) {
	timings__stop_current_section(t);
	array_add(&t->sections, make_time_stamp(label));
}

gb_internal f64 time_stamp_as_s(TimeStamp const &ts, u64 freq) {
	GB_ASSERT_MSG(ts.finish >= ts.start, "time_stamp_as_ms - %.*s", LIT(ts.label));
	return cast(f64)(ts.finish - ts.start) / cast(f64)freq;
}

gb_internal f64 time_stamp_as_ms(TimeStamp const &ts, u64 freq) {
	return 1000.0*time_stamp_as_s(ts, freq);
}

gb_internal f64 time_stamp_as_us(TimeStamp const &ts, u64 freq) {
	return 1000000.0*time_stamp_as_s(ts, freq);
}

#define MAIN_TIME_SECTION(str)               do { debugf("[Section] %s\n", str);                                      timings_start_section(&global_timings, str_lit(str));                } while (0)
#define MAIN_TIME_SECTION_WITH_LEN(str, len) do { debugf("[Section] %s\n", str);                                      timings_start_section(&global_timings, make_string((u8 *)str, len)); } while (0)
#define TIME_SECTION(str)                    do { debugf("[Section] %s\n", str); if (build_context.show_more_timings) timings_start_section(&global_timings, str_lit(str));                } while (0)
#define TIME_SECTION_WITH_LEN(str, len)      do { debugf("[Section] %s\n", str); if (build_context.show_more_timings) timings_start_section(&global_timings, make_string((u8 *)str, len)); } while (0)


enum TimingUnit {
	TimingUnit_Second,
	TimingUnit_Millisecond,
	TimingUnit_Microsecond,

	TimingUnit_COUNT,
};

char const *timing_unit_strings[TimingUnit_COUNT] = {"s", "ms", "us"};

gb_internal f64 time_stamp(TimeStamp const &ts, u64 freq, TimingUnit unit) {
	switch (unit) {
	case TimingUnit_Millisecond: return time_stamp_as_ms(ts, freq);
	case TimingUnit_Microsecond: return time_stamp_as_us(ts, freq);
	default: /*fallthrough*/
	case TimingUnit_Second:      return time_stamp_as_s (ts, freq);
	}
}

gb_internal void timings_print_all(Timings *t, TimingUnit unit = TimingUnit_Millisecond, bool timings_are_finalized = false) {
	isize const SPACES_LEN = 256;
	char SPACES[SPACES_LEN+1] = {0};
	gb_memset(SPACES, ' ', SPACES_LEN);

	/*
		NOTE(Jeroen): Whether we call `timings_print_all()`, then `timings_export_all()`, the other way around,
		or just one of them, we only need to stop the clock once.
	*/
	if (!timings_are_finalized) {
		timings__stop_current_section(t);
		t->total.finish = time_stamp_time_now();
	}

	isize max_len = gb_min(36, t->total.label.len);
	for_array(i, t->sections) {
		TimeStamp ts = t->sections[i];
		max_len = gb_max(max_len, ts.label.len);
	}

	GB_ASSERT(max_len <= SPACES_LEN);

	t->total_time_seconds = time_stamp_as_s(t->total, t->freq);

	f64 total_time = time_stamp(t->total, t->freq, unit);

	gb_printf("%.*s%.*s - % 9.3f %s - %6.2f%%\n",
	          LIT(t->total.label),
	          cast(int)(max_len-t->total.label.len), SPACES,
	          total_time,
	          timing_unit_strings[unit],
	          cast(f64)100.0);

	for_array(i, t->sections) {
		TimeStamp ts = t->sections[i];
		f64 section_time = time_stamp(ts, t->freq, unit);
		gb_printf("%.*s%.*s - % 9.3f %s - %6.2f%%\n",
		          LIT(ts.label),
	              cast(int)(max_len-ts.label.len), SPACES,
		          section_time,
		          timing_unit_strings[unit],
		          100.0*section_time/total_time);
	}
}