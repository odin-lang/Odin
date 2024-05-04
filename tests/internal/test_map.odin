package test_internal_map

import "core:fmt"
import "base:intrinsics"
import "core:math/rand"
import "core:mem"
import "core:os"
import "core:testing"

seed: u64

ENTRY_COUNTS := []int{11, 101, 1_001, 10_001, 100_001, 1_000_001}

@test
map_insert_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		fmt.printf("[map_insert_random_key_value] Testing %v entries.\n", entries)
		m: map[i64]i64
		defer delete(m)

		unique_keys := 0
		r := rand.create(seed + seed_incr)
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

		expect(t, key_count == unique_keys, fmt.tprintf("Expected key_count to equal %v, got %v", unique_keys, key_count))
		expect(t, len(m)    == unique_keys, fmt.tprintf("Expected len(map) to equal %v, got %v",  unique_keys, len(m)))

		// Reset randomizer and verify
		r = rand.create(seed + seed_incr)

		num_fails := 0
		for _ in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

			cond := m[k] == v
			if !cond {
				num_fails += 1
				if num_fails > 5 {
					fmt.println("... and more")
					break
				}
				expect(t, false, fmt.tprintf("Unexpected value. Expected m[%v] = %v, got %v", k, v, m[k]))
			}
		}
		seed_incr += 1
	}
}

@test
map_update_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		fmt.printf("[map_update_random_key_value] Testing %v entries.\n", entries)
		m: map[i64]i64
		defer delete(m)

		unique_keys := 0
		r := rand.create(seed + seed_incr)
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

		expect(t, key_count == unique_keys, fmt.tprintf("Expected key_count to equal %v, got %v", unique_keys, key_count))
		expect(t, len(m)    == unique_keys, fmt.tprintf("Expected len(map) to equal %v, got %v",  unique_keys, len(m)))

		half_entries := entries / 2

		// Reset randomizer and update half the entries
		r = rand.create(seed + seed_incr)
		for _ in 0..<half_entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

			m[k] = v + 42
		}

		// Reset randomizer and verify
		r = rand.create(seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

			diff := i64(42) if i < half_entries else i64(0)
			cond := m[k] == (v + diff)
			if !cond {
				num_fails += 1
				if num_fails > 5 {
					fmt.println("... and more")
					break
				}
				expect(t, false, fmt.tprintf("Unexpected value. Expected m[%v] = %v, got %v", k, v, m[k]))
			}
		}
		seed_incr += 1
	}
}

@test
map_delete_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		fmt.printf("[map_delete_random_key_value] Testing %v entries.\n", entries)
		m: map[i64]i64
		defer delete(m)

		unique_keys := 0
		r := rand.create(seed + seed_incr)
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

		expect(t, key_count == unique_keys, fmt.tprintf("Expected key_count to equal %v, got %v", unique_keys, key_count))
		expect(t, len(m)    == unique_keys, fmt.tprintf("Expected len(map) to equal %v, got %v",  unique_keys, len(m)))

		half_entries := entries / 2

		// Reset randomizer and delete half the entries
		r = rand.create(seed + seed_incr)
		for _ in 0..<half_entries {
			k := rand.int63(&r)
			_  = rand.int63(&r)

			delete_key(&m, k)
		}

		// Reset randomizer and verify
		r = rand.create(seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63(&r)
			v := rand.int63(&r)

			if i < half_entries {
				if k in m {
					num_fails += 1
					if num_fails > 5 {
						fmt.println("... and more")
						break
					}
					expect(t, false, fmt.tprintf("Unexpected key present. Expected m[%v] to have been deleted, got %v", k, m[k]))
				}
			} else {
				if k not_in m {
					num_fails += 1
					if num_fails > 5 {
						fmt.println("... and more")
						break
					}
					expect(t, false, fmt.tprintf("Expected key not present. Expected m[%v] = %v", k, v))
				} else if m[k] != v {
					num_fails += 1
					if num_fails > 5 {
						fmt.println("... and more")
						break
					}
					expect(t, false, fmt.tprintf("Unexpected value. Expected m[%v] = %v, got %v", k, v, m[k]))
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
		fmt.printf("[set_insert_random_key_value] Testing %v entries.\n", entries)
		m: map[i64]struct{}
		defer delete(m)

		unique_keys := 0
		r := rand.create(seed + seed_incr)
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

		expect(t, key_count == unique_keys, fmt.tprintf("Expected key_count to equal %v, got %v", unique_keys, key_count))
		expect(t, len(m)    == unique_keys, fmt.tprintf("Expected len(map) to equal %v, got %v",  unique_keys, len(m)))

		// Reset randomizer and verify
		r = rand.create(seed + seed_incr)

		num_fails := 0
		for _ in 0..<entries {
			k := rand.int63(&r)

			cond := k in m
			if !cond {
				num_fails += 1
				if num_fails > 5 {
					fmt.println("... and more")
					break
				}
				expect(t, false, fmt.tprintf("Unexpected value. Expected m[%v] to exist", k))
			}
		}
		seed_incr += 1
	}
}

@test
set_delete_random_key_value :: proc(t: ^testing.T) {
	seed_incr := u64(0)
	for entries in ENTRY_COUNTS {
		fmt.printf("[set_delete_random_key_value] Testing %v entries.\n", entries)
		m: map[i64]struct{}
		defer delete(m)

		unique_keys := 0
		r := rand.create(seed + seed_incr)
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

		expect(t, key_count == unique_keys, fmt.tprintf("Expected key_count to equal %v, got %v", unique_keys, key_count))
		expect(t, len(m)    == unique_keys, fmt.tprintf("Expected len(map) to equal %v, got %v",  unique_keys, len(m)))

		half_entries := entries / 2

		// Reset randomizer and delete half the entries
		r = rand.create(seed + seed_incr)
		for _ in 0..<half_entries {
			k := rand.int63(&r)
			delete_key(&m, k)
		}

		// Reset randomizer and verify
		r = rand.create(seed + seed_incr)

		num_fails := 0
		for i in 0..<entries {
			k := rand.int63(&r)

			if i < half_entries {
				if k in m {
					num_fails += 1
					if num_fails > 5 {
						fmt.println("... and more")
						break
					}
					expect(t, false, fmt.tprintf("Unexpected key present. Expected m[%v] to have been deleted", k))
				}
			} else {
				if k not_in m {
					num_fails += 1
					if num_fails > 5 {
						fmt.println("... and more")
						break
					}
					expect(t, false, fmt.tprintf("Expected key not present. Expected m[%v] to exist", k))
				}
			}
		}
		seed_incr += 1
	}
}

// -------- -------- -------- -------- -------- -------- -------- -------- -------- --------

main :: proc() {
	t := testing.T{}

	// Allow tests to be repeatable
	SEED :: #config(SEED, -1)
	when SEED > 0 {
		seed = u64(SEED)
	} else {
		seed = u64(intrinsics.read_cycle_counter())
	}
	fmt.println("Initialized seed to", seed)

	mem_track_test(&t, map_insert_random_key_value)
	mem_track_test(&t, map_update_random_key_value)
	mem_track_test(&t, map_delete_random_key_value)

	mem_track_test(&t, set_insert_random_key_value)
	mem_track_test(&t, set_delete_random_key_value)

	fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
	if TEST_fail > 0 {
		os.exit(1)
	}
}

mem_track_test :: proc(t: ^testing.T, test: proc(t: ^testing.T)) {
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	test(t)

	expect(t, len(track.allocation_map) == 0, "Expected no leaks.")
	expect(t, len(track.bad_free_array) == 0, "Expected no leaks.")

	for _, leak in track.allocation_map {
		fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
	}
	for bad_free in track.bad_free_array {
		fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
	}
}

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v] %v\n", loc, message)
			return
		}
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}
