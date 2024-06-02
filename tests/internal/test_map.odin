package test_internal_map

import "core:log"
import "base:intrinsics"
import "core:math/rand"
import "core:testing"

ENTRY_COUNTS := []int{11, 101, 1_001, 10_001, 100_001, 1_000_001}

@test
map_insert_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]i64
		defer delete(m)

		unique_keys := 0
		r := rand.create(t.seed + seed_incr)
		for _ in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

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
		r = rand.create(t.seed + seed_incr)

		num_fails := 0
		for _ in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

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
		defer delete(m)

		unique_keys := 0
		r := rand.create(t.seed + seed_incr)
		for _ in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

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
		r = rand.create(t.seed + seed_incr)
		for _ in 0..<half_entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

			m[k] = v + 42
		}

		// Reset randomizer and verify
		r = rand.create(t.seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

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
		defer delete(m)

		unique_keys := 0
		r := rand.create(t.seed + seed_incr)
		for _ in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

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
		r = rand.create(t.seed + seed_incr)
		for _ in 0..<half_entries {
			k := rand.int63(&r)
			_  = rand.int63(&r)

			delete_key(&m, k)
		}

		// Reset randomizer and verify
		r = rand.create(t.seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

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
set_insert_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		log.infof("Testing %v entries", entries)
		m: map[i64]struct{}
		defer delete(m)

		unique_keys := 0
		r := rand.create(t.seed + seed_incr)
		for _ in 0..<entries {
			k := rand.int63(&r)
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
		r = rand.create(t.seed + seed_incr)

		num_fails := 0
		for _ in 0..<entries {
			k := rand.int63(&r)

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
		defer delete(m)

		unique_keys := 0
		r := rand.create(t.seed + seed_incr)
		for _ in 0..<entries {
			k := rand.int63(&r)

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
		r = rand.create(t.seed + seed_incr)
		for _ in 0..<half_entries {
			k := rand.int63(&r)
			delete_key(&m, k)
		}

		// Reset randomizer and verify
		r = rand.create(t.seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63(&r)

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