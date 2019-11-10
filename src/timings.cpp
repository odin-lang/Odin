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

#elif defined(GB_SYSTEM_OSX)

#include <mach/mach_time.h>

u64 osx_time_stamp_time_now(void) {
	return mach_absolute_time();
}

u64 osx_time_stamp__freq(void) {
	mach_timebase_info_data_t data;
	data.numer = 0;
	data.denom = 0;
	mach_timebase_info(&data);
	return (data.numer / data.denom) * 1000000000;
}

#elif defined(GB_SYSTEM_UNIX)

#include <time.h>

u64 unix_time_stamp_time_now(void) {
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);

	return (ts.tv_sec * 1000000000) + ts.tv_nsec;
}

u64 unix_time_stamp__freq(void) {
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

u64 time_stamp_time_now(void) {
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

u64 time_stamp__freq(void) {
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

TimeStamp make_time_stamp(String label) {
	TimeStamp ts = {0};
	ts.start = time_stamp_time_now();
	ts.label = label;
	return ts;
}

void timings_init(Timings *t, String label, isize buffer_size) {
	array_init(&t->sections, heap_allocator(), 0, buffer_size);
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

f64 time_stamp_as_s(TimeStamp const &ts, u64 freq) {
	GB_ASSERT_MSG(ts.finish >= ts.start, "time_stamp_as_ms - %.*s", LIT(ts.label));
	return cast(f64)(ts.finish - ts.start) / cast(f64)freq;
}

f64 time_stamp_as_ms(TimeStamp const &ts, u64 freq) {
	return 1000.0*time_stamp_as_s(ts, freq);
}

f64 time_stamp_as_us(TimeStamp const &ts, u64 freq) {
	return 1000000.0*time_stamp_as_s(ts, freq);
}

enum TimingUnit {
	TimingUnit_Second,
	TimingUnit_Millisecond,
	TimingUnit_Microsecond,

	TimingUnit_COUNT,
};

char const *timing_unit_strings[TimingUnit_COUNT] = {"s", "ms", "us"};

f64 time_stamp(TimeStamp const &ts, u64 freq, TimingUnit unit) {
	switch (unit) {
	case TimingUnit_Millisecond: return time_stamp_as_ms(ts, freq);
	case TimingUnit_Microsecond: return time_stamp_as_us(ts, freq);
	default: /*fallthrough*/
	case TimingUnit_Second:      return time_stamp_as_s (ts, freq);
	}
}

void timings_print_all(Timings *t, TimingUnit unit = TimingUnit_Millisecond) {
	isize const SPACES_LEN = 256;
	char SPACES[SPACES_LEN+1] = {0};
	gb_memset(SPACES, ' ', SPACES_LEN);


	timings__stop_current_section(t);
	t->total.finish = time_stamp_time_now();

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
