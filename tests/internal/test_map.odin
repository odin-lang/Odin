package test_internal

import "core:log"
import "base:intrinsics"
import "base:runtime"
import "core:math/rand"
import "core:testing"

ENTRY_COUNTS := []int{11, 101, 1_001, 10_001, 100_001, 1_000_001}

@test
map_insert_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]i64
		if entries >= 100_000 {
			m = make_map_cap(map[i64]i64, entries * 2)
		}
		defer delete(m)

		unique_keys := 0
		rand.reset(t.seed + seed_incr)
		for _ in 0..<entries {
			k := rand.int63()
			v := rand.int63()

			if k not_in m {
				unique_keys += 1
			}
			m[k] = v
		}

		key_count := 0
		for _ in m {
			key_count += 1
		}

		testing.expectf(t, key_count == unique_keys, "Expected key_count to equal %v, got %v", unique_keys, key_count)
		testing.expectf(t, len(m)    == unique_keys, "Expected len(map) to equal %v, got %v",  unique_keys, len(m))

		// Reset randomizer and verify
		rand.reset(t.seed + seed_incr)

		num_fails := 0
		for _ in 0..<entries {
			k := rand.int63()
			v := rand.int63()

			cond := m[k] == v
			if !cond {
				num_fails += 1
				if num_fails > 5 {
					log.info("... and more")
					break
				}
				testing.expectf(t, false, "Unexpected value. Expected m[%v] = %v, got %v", k, v, m[k])
			}
		}
		seed_incr += 1
	}
}

@test
map_update_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]i64
		if entries >= 100_000 {
			m = make_map_cap(map[i64]i64, entries * 2)
		}
		defer delete(m)

		unique_keys := 0
		rand.reset(t.seed + seed_incr)

		for _ in 0..<entries {
			k := rand.int63()
			v := rand.int63()

			if k not_in m {
				unique_keys += 1
			}
			m[k] = v
		}

		key_count := 0
		for _ in m {
			key_count += 1
		}

		testing.expectf(t, key_count == unique_keys, "Expected key_count to equal %v, got %v", unique_keys, key_count)
		testing.expectf(t, len(m)    == unique_keys, "Expected len(map) to equal %v, got %v",  unique_keys, len(m))

		half_entries := entries / 2

		// Reset randomizer and update half the entries
		rand.reset(t.seed + seed_incr)

		for _ in 0..<half_entries {
			k := rand.int63()
			v := rand.int63()

			m[k] = v + 42
		}

		// Reset randomizer and verify
		rand.reset(t.seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63()
			v := rand.int63()

			diff := i64(42) if i < half_entries else i64(0)
			cond := m[k] == (v + diff)
			if !cond {
				num_fails += 1
				if num_fails > 5 {
					log.info("... and more")
					break
				}
				testing.expectf(t, false, "Unexpected value. Expected m[%v] = %v, got %v", k, v, m[k])
			}
		}
		seed_incr += 1
	}
}

@test
map_delete_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]i64
		if entries >= 100_000 {
			m = make_map_cap(map[i64]i64, entries * 2)
		}
		defer delete(m)

		unique_keys := 0
		rand.reset(t.seed + seed_incr)

		for _ in 0..<entries {
			k := rand.int63()
			v := rand.int63()

			if k not_in m {
				unique_keys += 1
			}
			m[k] = v
		}

		key_count := 0
		for _ in m {
			key_count += 1
		}

		testing.expectf(t, key_count == unique_keys, "Expected key_count to equal %v, got %v", unique_keys, key_count)
		testing.expectf(t, len(m)    == unique_keys, "Expected len(map) to equal %v, got %v",  unique_keys, len(m))

		half_entries := entries / 2

		// Reset randomizer and delete half the entries
		rand.reset(t.seed + seed_incr)

		for _ in 0..<half_entries {
			k := rand.int63()
			_  = rand.int63()

			delete_key(&m, k)
		}

		// Reset randomizer and verify
		rand.reset(t.seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63()
			v := rand.int63()

			if i < half_entries {
				if k in m {
					num_fails += 1
					if num_fails > 5 {
						log.info("... and more")
						break
					}
					testing.expectf(t, false, "Unexpected key present. Expected m[%v] to have been deleted, got %v", k, m[k])
				}
			} else {
				if k not_in m {
					num_fails += 1
					if num_fails > 5 {
						log.info("... and more")
						break
					}
					testing.expectf(t, false, "Expected key not present. Expected m[%v] = %v", k, v)
				} else if m[k] != v {
					num_fails += 1
					if num_fails > 5 {
						log.info("... and more")
						break
					}
					testing.expectf(t, false, "Unexpected value. Expected m[%v] = %v, got %v", k, v, m[k])
				}
			}
		}
		seed_incr += 1
	}
}

@test
map_shrink :: proc(t: ^testing.T) {
	m: map[int]int
	defer delete(m)

	{
		reserve(&m, 8)
		did_shrink, err := shrink(&m)
		testing.expect_value(t, did_shrink, false)
		testing.expect_value(t, err, runtime.Allocator_Error.None)
		testing.expect_value(t, cap(m), 8)
	}

	{
		reserve(&m, 64)
		did_shrink, err := shrink(&m)
		testing.expect_value(t, did_shrink, true)
		testing.expect_value(t, err, runtime.Allocator_Error.None)
		testing.expect_value(t, cap(m), 8)
	}

	{
		reserve(&m, 128)

		for i in 0 ..< 50 {
			m[i] = i
		}

		did_shrink, err := shrink(&m)
		testing.expect_value(t, did_shrink, false)
		testing.expect_value(t, err, runtime.Allocator_Error.None)
		testing.expect_value(t, cap(m), 128)
	}

	{
		reserve(&m, 256)

		for i in 0 ..< 50 {
			m[i] = i
		}

		did_shrink, err := shrink(&m)
		testing.expect_value(t, did_shrink, true)
		testing.expect_value(t, err, runtime.Allocator_Error.None)
		testing.expect_value(t, cap(m), 128)
	}
}

@test
set_insert_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]struct{}
		if entries >= 100_000 {
			m = make_map_cap(map[i64]struct{}, entries * 2)
		}
		defer delete(m)

		unique_keys := 0
		rand.reset(t.seed + seed_incr)

		for _ in 0..<entries {
			k := rand.int63()
			if k not_in m {
				unique_keys += 1
			}
			m[k] = {}
		}

		key_count := 0
		for _ in m {
			key_count += 1
		}

		testing.expectf(t, key_count == unique_keys, "Expected key_count to equal %v, got %v", unique_keys, key_count)
		testing.expectf(t, len(m)    == unique_keys, "Expected len(map) to equal %v, got %v",  unique_keys, len(m))

		// Reset randomizer and verify
		rand.reset(t.seed + seed_incr)

		num_fails := 0
		for _ in 0..<entries {
			k := rand.int63()

			cond := k in m
			if !cond {
				num_fails += 1
				if num_fails > 5 {
					log.info("... and more")
					break
				}
				testing.expectf(t, false, "Unexpected value. Expected m[%v] to exist", k)
			}
		}
		seed_incr += 1
	}
}

@test
set_delete_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]struct{}
		if entries >= 100_000 {
			m = make_map_cap(map[i64]struct{}, entries * 2)
		}
		defer delete(m)

		unique_keys := 0
		rand.reset(t.seed + seed_incr)

		for _ in 0..<entries {
			k := rand.int63()

			if k not_in m {
				unique_keys += 1
			}
			m[k] = {}
		}

		key_count := 0
		for _ in m {
			key_count += 1
		}

		testing.expectf(t, key_count == unique_keys, "Expected key_count to equal %v, got %v", unique_keys, key_count)
		testing.expectf(t, len(m)    == unique_keys, "Expected len(map) to equal %v, got %v",  unique_keys, len(m))

		half_entries := entries / 2

		// Reset randomizer and delete half the entries
		rand.reset(t.seed + seed_incr)

		for _ in 0..<half_entries {
			k := rand.int63()
			delete_key(&m, k)
		}

		// Reset randomizer and verify
		rand.reset(t.seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63()

			if i < half_entries {
				if k in m {
					num_fails += 1
					if num_fails > 5 {
						log.info("... and more")
						break
					}
					testing.expectf(t, false, "Unexpected key present. Expected m[%v] to have been deleted", k)
				}
			} else {
				if k not_in m {
					num_fails += 1
					if num_fails > 5 {
						log.info("... and more")
						break
					}
					testing.expectf(t, false, "Expected key not present. Expected m[%v] to exist", k)
				}
			}
		}
		seed_incr += 1
	}
}

@test
test_union_key_should_not_be_hashing_specifc_variant :: proc(t: ^testing.T) {
	Vec2 :: [2]f32
	BoneId :: distinct int
	VertexId :: distinct int
	Id :: union {
		BoneId,
		VertexId,
	}

	m: map[Id]Vec2
	defer delete(m)

	bone_1: BoneId = 69
	m[bone_1] = {4, 20}

	testing.expect_value(t, bone_1 in m, true)
	testing.expect_value(t, Id(bone_1) in m, true)
}

@test
test_map_range_by_ref :: proc(t: ^testing.T) {
	m: map[u32]int
	defer delete(m)

	m[0] = 0
	m[1] = 0

	for _, &v in m {
		v = 1
	}

	for k, v in m {
		testing.expectf(t, v == 1, "Expected m[%v] to be 1, got %v", k, v)
	}
}

// A `string16` length counts u16 units, so hashing it as a `string` covered only half its bytes,
// and a `cstring16` was read as a `string16`.
@test
map_utf16_string_keys :: proc(t: ^testing.T) {
	hasher := intrinsics.type_hasher_proc(string16)
	a: string16 = "abcd"
	b: string16 = "abXY"
	testing.expect(t, hasher(&a, 0) != hasher(&b, 0))
	testing.expect_value(t, hasher(&a, 0), runtime.default_hasher_fixed(raw_data(a), 0, len(a)*size_of(u16)))

	m: map[string16]int
	defer delete(m)
	m[a] = 1
	m[b] = 2
	testing.expect_value(t, m[a], 1)
	testing.expect_value(t, m[b], 2)

	chasher := intrinsics.type_hasher_proc(cstring16)
	c: cstring16 = "abcd"
	testing.expect_value(t, chasher(&c, 0), hasher(&a, 0))

	mc: map[cstring16]int
	defer delete(mc)
	d: cstring16 = "abXY"
	mc[c] = 1
	mc[d] = 2
	testing.expect_value(t, len(mc), 2)
	testing.expect_value(t, mc[c], 1)
	testing.expect_value(t, mc[d], 2)
}
