package test_internal

import "core:testing"

// A deferred procedure gets the arguments as they were at the call, whatever their size or how they are passed.

@(private="file")
Big :: struct {
	a, b, c, d: int,
	tag:        u8,
}

@(private="file")
Seen :: struct {
	big:    int,
	str:    string,
	small:  int,
	result: int,
}

@(private="file", deferred_in=end_scope)
begin_scope :: #force_no_inline proc(seen: ^Seen, big: Big, str: string, small: int) {}

@(private="file")
end_scope :: #force_no_inline proc(seen: ^Seen, big: Big, str: string, small: int) {
	seen.big   = big.a
	seen.str   = str
	seen.small = small
}

@(test)
test_deferred_in_args :: proc(t: ^testing.T) {
	seen: Seen
	big   := Big{a = 1}
	str   := "before"
	small := 1
	{
		begin_scope(&seen, big, str, small)
		big.a = 2
		str   = "after"
		small = 2
	}
	testing.expect_value(t, seen.big,   1)
	testing.expect_value(t, seen.str,   "before")
	testing.expect_value(t, seen.small, 1)
}

@(private="file", deferred_in=end_written)
begin_written :: #force_no_inline proc(seen: ^Seen, big_ptr: ^Big, big: Big) {
	big_ptr.a = 3
}

@(private="file")
end_written :: #force_no_inline proc(seen: ^Seen, big_ptr: ^Big, big: Big) {
	seen.big = big.a
}

// The call itself writing to an argument does not change what the deferred procedure gets
@(test)
test_deferred_in_args_written_by_call :: proc(t: ^testing.T) {
	seen: Seen
	big := Big{a = 1}
	{
		begin_written(&seen, &big, big)
	}
	testing.expect_value(t, seen.big, 1)
	testing.expect_value(t, big.a,    3)
}

@(private="file", deferred_in_out=end_in_out)
begin_in_out :: #force_no_inline proc(seen: ^Seen, big: Big) -> Big {
	return {a = big.a+10}
}

@(private="file")
end_in_out :: #force_no_inline proc(seen: ^Seen, big: Big, result: Big) {
	seen.big    = big.a
	seen.result = result.a
}

@(test)
test_deferred_in_out_args :: proc(t: ^testing.T) {
	seen: Seen
	big := Big{a = 1}
	{
		result := begin_in_out(&seen, big)
		big.a    = 2
		result.a = 3
		testing.expect_value(t, result.a, 3)
	}
	testing.expect_value(t, seen.big,    1)
	testing.expect_value(t, seen.result, 11)
}
