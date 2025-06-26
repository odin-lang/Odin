package test_internal

import "base:intrinsics"
import "core:testing"

/*
example_usage :: proc(#any_int x: int) -> intrinsics.type_integer_to_unsigned(type_of(x)) {
	T :: intrinsics.type_integer_to_unsigned(type_of(x))
	return 1<<T(x)
}
*/

@test
test_intrinsic_integer_to :: proc(t: ^testing.T) {
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i16le)), typeid_of(u16le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i32le)), typeid_of(u32le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i64le)), typeid_of(u64le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i128le)), typeid_of(u128le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i16be)), typeid_of(u16be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i32be)), typeid_of(u32be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i64be)), typeid_of(u64be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(i128be)), typeid_of(u128be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_unsigned(int)), typeid_of(uint))

	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u16le)), typeid_of(i16le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u32le)), typeid_of(i32le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u64le)), typeid_of(i64le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u128le)), typeid_of(i128le))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u16be)), typeid_of(i16be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u32be)), typeid_of(i32be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u64be)), typeid_of(i64be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(u128be)), typeid_of(i128be))
	testing.expect_value(t, typeid_of(intrinsics.type_integer_to_signed(uint)), typeid_of(int))
}
