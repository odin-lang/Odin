package test_internal

import "base:intrinsics"
import "core:testing"

// A parameter is a value. When the caller passes its own variable and that variable changes during the call,
// the parameter must keep the value it had on entry, also after it is passed on to another procedure.

@(private="file")
Three :: struct {
	a, b, c: u8,
}

@(private="file")
Packed :: struct #packed {
	a: u8,
	b: u64,
}

@(private="file")
Padded :: struct {
	a: f32,
	b: f64,
}

@(private="file", require_results)
snapshot :: proc(value: $T, original: ^T, changed: T) -> (ok: bool) where intrinsics.type_is_comparable(T) {
	before := value
	original^ = changed
	return value == before && forward(value, before)
}

@(private="file", require_results)
forward :: proc(value: $T, before: T) -> bool {
	return value == before
}

@(private="file", require_results)
snapshot_any :: proc(value: any, original: ^any, changed: any) -> (ok: bool) {
	before := value
	original^ = changed
	return value.data == before.data && value.id == before.id && forward_any(value, before)
}

@(private="file", require_results)
forward_any :: proc(value: any, before: any) -> bool {
	return value.data == before.data && value.id == before.id
}

@(test)
test_small_parameter_copy :: proc(t: ^testing.T) {
	check :: proc(t: ^testing.T, ok: bool, loc := #caller_location) {
		testing.expect(t, ok, "a parameter changed when the caller's variable did", loc=loc)
	}

	s := "hello"
	check(t, snapshot(s, &s, "other"))

	x, y := 1, 2
	a: any = x
	check(t, snapshot_any(a, &a, y))

	f := [3]f32{1, 2, 3}
	check(t, snapshot(f, &f, [3]f32{4, 5, 6}))

	three := Three{1, 2, 3}
	check(t, snapshot(three, &three, Three{4, 5, 6}))

	packed := Packed{1, 0x0102030405060708}
	check(t, snapshot(packed, &packed, Packed{2, 9}))

	padded := Padded{1.5, 2.5}
	check(t, snapshot(padded, &padded, Padded{3.5, 4.5}))

	big := i128(-1) << 100
	check(t, snapshot(big, &big, 7))

	c := complex128(1 + 2i)
	check(t, snapshot(c, &c, 3 + 4i))

	bytes := [16]u8{0 = 1, 15 = 2}
	check(t, snapshot(bytes, &bytes, [16]u8{}))
}
