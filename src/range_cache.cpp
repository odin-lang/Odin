
// Integers only
struct RangeValue {
	i64 lo;
	i64 hi;
};

struct RangeCache {
	Array<RangeValue> ranges;
};


RangeCache range_cache_make(gbAllocator a) {
	RangeCache cache = {};
	array_init(&cache.ranges, a);
	return cache;
}

void range_cache_destroy(RangeCache *c) {
	array_free(&c->ranges);
}

bool range_cache_add_index(RangeCache *c, i64 index) {
	for_array(i, c->ranges) {
		RangeValue v = c->ranges[i];
		if (v.lo <= index && index <= v.hi) {
			return false;
		}
	}
	RangeValue v = {index, index};
	array_add(&c->ranges, v);
	return true;
}


bool range_cache_add_range(RangeCache *c, i64 lo, i64 hi) {
	GB_ASSERT(lo <= hi);
	for_array(i, c->ranges) {
		RangeValue v = c->ranges[i];
		if (hi < v.lo) {
			continue;
		}
		if (lo > v.hi) {
			continue;
		}

		if (v.hi < hi) {
			v.hi = hi;
		}
		if (lo < v.lo) {
			v.lo = lo;
		}
		c->ranges[i] = v;
		return false;
	}
	RangeValue v = {lo, hi};
	array_add(&c->ranges, v);
	return true;
}


bool range_cache_index_exists(RangeCache *c, i64 index) {
	for_array(i, c->ranges) {
		RangeValue v = c->ranges[i];
		if (v.lo <= index && index <= v.hi) {
			return true;
		}
	}
	return false;
}
