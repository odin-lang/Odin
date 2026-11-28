package test_core_math_big

import "core:math/big"
import "core:mem"
import "core:os"
import "core:testing"

@(private="file")
Leak_Fail_State :: struct {
	backing: mem.Allocator,
	count:   int,
	fail_at: int,
	fail_as: mem.Allocator_Error,
}

@(private="file")
leak_fail_proc :: proc(data: rawptr, mode: mem.Allocator_Mode, size, alignment: int, old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
	st := (^Leak_Fail_State)(data)
	#partial switch mode {
	case .Alloc, .Alloc_Non_Zeroed, .Resize, .Resize_Non_Zeroed:
		st.count += 1
		if st.count == st.fail_at {
			return nil, st.fail_as
		}
	}
	return st.backing.procedure(st.backing.data, mode, size, alignment, old_memory, old_size, loc)
}

@(private="file")
leak_expect :: proc(t: ^testing.T, a: ^big.Int, expected: string, loc := #caller_location) {
	s, err := big.int_itoa_string(a, 10, false, context.temp_allocator)
	testing.expect_value(t, err, nil, loc=loc)
	testing.expect_value(t, s, expected, loc=loc)
}

@(test)
test_leak_big_grow_passes_allocator_error :: proc(t: ^testing.T) {
	fails := [?]mem.Allocator_Error{.Out_Of_Memory, .Invalid_Pointer, .Invalid_Argument}
	for fail_as in fails {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		st := Leak_Fail_State{backing = mem.tracking_allocator(&track), fail_as = fail_as}
		alloc := mem.Allocator{procedure = leak_fail_proc, data = &st}

		a := &big.Int{}
		testing.expect_value(t, big.int_set_from_integer(a, 12345, false, alloc), nil)

		st.fail_at = st.count + 1
		testing.expect_value(t, big.internal_int_grow(a, 200), big.Error(fail_as))
		testing.expect_value(t, st.count, st.fail_at)
		leak_expect(t, a, "12345")

		testing.expect_value(t, big.internal_int_grow(a, 200), nil)
		testing.expect_value(t, len(a.digit), 200)

		st.fail_at = st.count + 1
		testing.expect_value(t, big.internal_int_shrink(a), big.Error(fail_as))
		testing.expect_value(t, st.count, st.fail_at)
		testing.expect_value(t, len(a.digit), 200)
		leak_expect(t, a, "12345")

		testing.expect_value(t, big.internal_int_shrink(a), nil)
		testing.expect(t, len(a.digit) < 200)
		leak_expect(t, a, "12345")

		big.destroy(a)
		testing.expectf(t, len(track.allocation_map) == 0, "%v: %v leaked", fail_as, len(track.allocation_map))
		mem.tracking_allocator_destroy(&track)
	}
}

@(test)
test_leak_big_divmod_uninitialized_quotient_oom :: proc(t: ^testing.T) {
	n, d := &big.Int{}, &big.Int{}
	defer big.destroy(n, d)
	testing.expect_value(t, big.atoi(n, "5"), nil)
	testing.expect_value(t, big.power_of_two(d, 200), nil)

	for fail_at in 0..=1 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		st := Leak_Fail_State{backing = mem.tracking_allocator(&track), fail_at = fail_at, fail_as = .Out_Of_Memory}

		q := &big.Int{}
		err := big.internal_int_divmod(q, nil, n, d, mem.Allocator{procedure = leak_fail_proc, data = &st})
		if fail_at == 1 {
			testing.expect_value(t, err, big.Error.Out_Of_Memory)
		} else {
			testing.expect_value(t, err, nil)
			leak_expect(t, q, "0")
		}
		big.destroy(q)
		testing.expectf(t, len(track.allocation_map) == 0, "allocation %v failed: %v leaked", fail_at, len(track.allocation_map))
		mem.tracking_allocator_destroy(&track)
	}
}

@(test)
test_leak_big_frobenius_underwood_oom :: proc(t: ^testing.T) {
	n := &big.Int{}
	defer big.destroy(n)
	testing.expect_value(t, big.atoi(n, "618970019642690137449562111"), nil)

	for fail_at in 1..=100_000 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		st := Leak_Fail_State{backing = mem.tracking_allocator(&track), fail_at = fail_at, fail_as = .Out_Of_Memory}

		result, err := big.internal_int_prime_frobenius_underwood(n, mem.Allocator{procedure = leak_fail_proc, data = &st})
		reached := st.count >= fail_at
		if reached {
			testing.expectf(t, err == .Out_Of_Memory, "allocation %v failed: err = %v", fail_at, err)
		} else {
			testing.expect_value(t, err, nil)
			testing.expect_value(t, result, true)
		}
		testing.expectf(t, len(track.allocation_map) == 0, "allocation %v failed: %v leaked", fail_at, len(track.allocation_map))
		mem.tracking_allocator_destroy(&track)
		if !reached {
			break
		}
	}
}

@(test)
test_leak_big_int_log_oom_returns_minus_one :: proc(t: ^testing.T) {
	a := &big.Int{}
	defer big.destroy(a)
	testing.expect_value(t, big.atoi(a, "123456789012345678901234567890"), nil)

	for fail_at in 1..=1_000 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		st := Leak_Fail_State{backing = mem.tracking_allocator(&track), fail_at = fail_at, fail_as = .Out_Of_Memory}

		res, err := big.internal_int_log(a, 10, mem.Allocator{procedure = leak_fail_proc, data = &st})
		reached := st.count >= fail_at
		if reached {
			testing.expectf(t, err == .Out_Of_Memory && res == -1, "allocation %v failed: %v, %v", fail_at, res, err)
		} else {
			testing.expect_value(t, err, nil)
			testing.expect_value(t, res, 29)
		}
		testing.expectf(t, len(track.allocation_map) == 0, "allocation %v failed: %v leaked", fail_at, len(track.allocation_map))
		mem.tracking_allocator_destroy(&track)
		if !reached {
			break
		}
	}
}

@(test)
test_leak_big_read_from_ascii_file_oom :: proc(t: ^testing.T) {
	root, root_err := os.make_directory_temp("", "odin-math-big-leak-*", context.temp_allocator)
	if !testing.expect_value(t, root_err, nil) {
		return
	}
	defer os.remove_all(root)

	VALUE :: "-123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
	path, _ := os.join_path({root, "value.txt"}, context.temp_allocator)
	testing.expect_value(t, os.write_entire_file(path, VALUE + "\n"), nil)

	for fail_at in 1..=1_000 {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		st := Leak_Fail_State{backing = mem.tracking_allocator(&track), fail_at = fail_at, fail_as = .Out_Of_Memory}

		b := &big.Int{}
		err := big.internal_int_read_from_ascii_file(b, path, 10, mem.Allocator{procedure = leak_fail_proc, data = &st})
		reached := st.count >= fail_at
		if reached {
			testing.expectf(t, err == .Out_Of_Memory, "allocation %v failed: err = %v", fail_at, err)
		} else {
			testing.expect_value(t, err, nil)
			leak_expect(t, b, VALUE)
		}
		big.destroy(b)
		testing.expectf(t, len(track.allocation_map) == 0, "allocation %v failed: %v leaked", fail_at, len(track.allocation_map))
		mem.tracking_allocator_destroy(&track)
		if !reached {
			break
		}
	}

	st := Leak_Fail_State{backing = context.allocator, fail_at = 1, fail_as = .Invalid_Argument}
	b := &big.Int{}
	defer big.destroy(b)
	testing.expect_value(t, big.internal_int_read_from_ascii_file(b, path, 10, mem.Allocator{procedure = leak_fail_proc, data = &st}), big.Error.Invalid_Argument)

	missing, _ := os.join_path({root, "missing.txt"}, context.temp_allocator)
	testing.expect_value(t, big.internal_int_read_from_ascii_file(b, missing), big.Error.Cannot_Read_File)
}
