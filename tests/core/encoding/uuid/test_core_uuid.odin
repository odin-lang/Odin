package test_core_uuid

import "core:crypto"
import "core:encoding/uuid"
import uuid_legacy "core:encoding/uuid/legacy"
import "core:log"
import "core:slice"
import "core:testing"
import "core:time"

@(test)
test_version_and_variant :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	v1 := uuid.generate_v1(0)
	v3 := uuid_legacy.generate_v3(uuid.Namespace_DNS, "")
	v4 := uuid.generate_v4()
	v5 := uuid_legacy.generate_v5(uuid.Namespace_DNS, "")
	v6 := uuid.generate_v6()
	v7 := uuid.generate_v7()

	_v8_array: [16]u8 = 0xff
	v8_int := uuid.stamp_v8(max(u128))
	v8_array := uuid.stamp_v8(_v8_array)
	v8_slice := uuid.stamp_v8(_v8_array[:])

	v8_hash := uuid.generate_v8_hash(uuid.Namespace_DNS, "", .SHA512)

	testing.expect_value(t, uuid.version(v1), 1)
	testing.expect_value(t, uuid.variant(v1), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v3), 3)
	testing.expect_value(t, uuid.variant(v3), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v4), 4)
	testing.expect_value(t, uuid.variant(v4), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v5), 5)
	testing.expect_value(t, uuid.variant(v5), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v6), 6)
	testing.expect_value(t, uuid.variant(v6), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v7), 7)
	testing.expect_value(t, uuid.variant(v7), uuid.Variant_Type.RFC_4122)

	testing.expect_value(t, uuid.version(v8_int), 8)
	testing.expect_value(t, uuid.variant(v8_int), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v8_array), 8)
	testing.expect_value(t, uuid.variant(v8_array), uuid.Variant_Type.RFC_4122)
	testing.expect_value(t, uuid.version(v8_slice), 8)
	testing.expect_value(t, uuid.variant(v8_slice), uuid.Variant_Type.RFC_4122)

	testing.expect_value(t, uuid.version(v8_hash), 8)
	testing.expect_value(t, uuid.variant(v8_hash), uuid.Variant_Type.RFC_4122)
}

@(test)
test_timestamps :: proc(t: ^testing.T) {
	// This test makes sure that timestamps are recoverable and have not been
	// overwritten by neighboring bits, taking into account precision loss.
	context.random_generator = crypto.random_generator()

	N :: max(i64)

	max_time := time.Time { N }

	mac: [6]byte
	v1 := uuid.generate_v1(0, mac, max_time)
	v6 := uuid.generate_v6(0, mac, max_time)
	v7 := uuid.generate_v7(max_time)
	// The counter version keeps its time in the same place as the basic version,
	// this is just for the sake of completeness.
	v7_counter := uuid.generate_v7(0, max_time)

	v1_time := uuid.time_v1(v1)
	v6_time := uuid.time_v6(v6)
	v7_time := uuid.time_v7(v7)
	v7_counter_time := uuid.time_v7(v7_counter)

	// I hope the compiler doesn't ever optimize this out.
	max_time_hns_resolution := time.Time { N / 100 * 100 }
	max_time_ms_resolution  := time.Time { N / 1e6 * 1e6 }

	testing.expectf(t,
		time.diff(max_time_hns_resolution, v1_time) == 0,
		"v1 UUID timestamp is invalid, expected %x, got %x",
		max_time_hns_resolution, v1_time)

	testing.expectf(t,
		time.diff(max_time_hns_resolution, v6_time) == 0,
		"v6 UUID timestamp is invalid, expected %x, got %x",
		max_time_hns_resolution, v6_time)

	testing.expectf(t,
		time.diff(max_time_ms_resolution, v7_time) == 0,
		"v7 UUID timestamp is invalid, expected %x, got %x",
		max_time_ms_resolution, v7_time)

	testing.expectf(t,
		time.diff(max_time_ms_resolution, v7_counter_time) == 0,
		"v7 UUID (with counter) timestamp is invalid, expected %x, got %x",
		max_time_ms_resolution, v7_counter_time)
}

@(test)
test_v8_hash_implementation :: proc(t: ^testing.T) {
	// This example and its results are derived from RFC 9562.
	// https://www.rfc-editor.org/rfc/rfc9562.html#name-example-of-a-uuidv8-value-n

	id := uuid.generate_v8_hash(uuid.Namespace_DNS, "www.example.com", .SHA256)
	id_str := uuid.to_string(id)
	defer delete(id_str)
	testing.expect_value(t, id_str, "5c146b14-3c52-8afd-938a-375d0df1fbf6")
}

@(test)
test_legacy_namespaced_uuids :: proc(t: ^testing.T) {
	TEST_NAME :: "0123456789ABCDEF0123456789ABCDEF"

	Expected_Result :: struct {
		namespace: uuid.Identifier,
		v3, v5: string,
	}

	Expected_Results := [?]Expected_Result {
		{ uuid.Namespace_DNS,  "80147f37-36db-3b82-b78f-810c3c6504ba", "18394c41-13a2-593f-abf2-a63e163c2860" },
		{ uuid.Namespace_URL,  "8136789b-8e16-3fbd-800b-1587e2f22521", "07337422-eb77-5fd3-99af-c7f59e641e13" },
		{ uuid.Namespace_OID,  "adbb95bc-ea50-3226-9a75-20c34a6030f8", "24db9b0f-70b8-53c4-a301-f695ce17276d" },
		{ uuid.Namespace_X500, "a8965ad1-0e54-3d65-b933-8b7cca8e8313", "3012bf2d-fac4-5187-9825-493e6636b936" },
	}

	for exp in Expected_Results {
		v3 := uuid_legacy.generate_v3(exp.namespace, TEST_NAME)
		v5 := uuid_legacy.generate_v5(exp.namespace, TEST_NAME)

		v3_str := uuid.to_string(v3)
		defer delete(v3_str)

		v5_str := uuid.to_string(v5)
		defer delete(v5_str)

		testing.expect_value(t, v3_str, exp.v3)
		testing.expect_value(t, v5_str, exp.v5)
	}
}

@(test)
test_v1 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	point_a := time.unix(1, 0)
	point_b := time.unix(3, 0)
	point_c := time.unix(5, 0)

	CLOCK :: 0x3A1A
	mac := [6]u8{0xFF, 0x10, 0xAA, 0x55, 0x01, 0xFF}

	v1_a := uuid.generate_v1(CLOCK, mac, point_a)
	v1_b := uuid.generate_v1(CLOCK, mac, point_b)
	v1_c := uuid.generate_v1(CLOCK, mac, point_c)

	testing.expect_value(t, uuid.clock_seq(v1_a), CLOCK)

	extracted_mac := uuid.node(v1_a)
	for i in 0 ..< len(mac) {
		testing.expect(t, mac[i] == extracted_mac[i])
	}

	time_a := uuid.time_v1(v1_a)
	time_b := uuid.time_v1(v1_b)
	time_c := uuid.time_v1(v1_c)

	log.debugf("A: %02x, %v", v1_a, time_a)
	log.debugf("B: %02x, %v", v1_b, time_b)
	log.debugf("C: %02x, %v", v1_c, time_c)

	testing.expect(t, time.diff(time_a, time_b) > 0, "The time on the later-generated v1 UUID is earlier than its successor.")
	testing.expect(t, time.diff(time_b, time_c) > 0, "The time on the later-generated v1 UUID is earlier than its successor.")
	testing.expect(t, time.diff(time_a, time_c) > 0, "The time on the later-generated v1 UUID is earlier than its successor.")
}

@(test)
test_v6 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	point_a := time.unix(1, 0)
	point_b := time.unix(3, 0)
	point_c := time.unix(5, 0)

	CLOCK :: 0x3A1A
	mac := [6]u8{0xFF, 0x10, 0xAA, 0x55, 0x01, 0xFF}

	v6_a := uuid.generate_v6(CLOCK, mac, point_a)
	v6_b := uuid.generate_v6(CLOCK, mac, point_b)
	v6_c := uuid.generate_v6(CLOCK, mac, point_c)

	testing.expect_value(t, uuid.clock_seq(v6_a), CLOCK)

	extracted_mac := uuid.node(v6_a)
	for i in 0 ..< len(mac) {
		testing.expect(t, mac[i] == extracted_mac[i])
	}

	time_a := uuid.time_v6(v6_a)
	time_b := uuid.time_v6(v6_b)
	time_c := uuid.time_v6(v6_c)

	log.debugf("A: %02x, %v", v6_a, time_a)
	log.debugf("B: %02x, %v", v6_b, time_b)
	log.debugf("C: %02x, %v", v6_c, time_c)

	testing.expect(t, time.diff(time_a, time_b) > 0, "The time on the later-generated v6 UUID is earlier than its successor.")
	testing.expect(t, time.diff(time_b, time_c) > 0, "The time on the later-generated v6 UUID is earlier than its successor.")
	testing.expect(t, time.diff(time_a, time_c) > 0, "The time on the later-generated v6 UUID is earlier than its successor.")
}

@(test)
test_v7 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	point_a := time.unix(1, 0)
	point_b := time.unix(3, 0)
	point_c := time.unix(5, 0)

	v7_a := uuid.generate_v7(point_a)
	v7_b := uuid.generate_v7(point_b)
	v7_c := uuid.generate_v7(point_c)

	time_a := uuid.time_v7(v7_a)
	time_b := uuid.time_v7(v7_b)
	time_c := uuid.time_v7(v7_c)

	log.debugf("A: %02x, %v", v7_a, time_a)
	log.debugf("B: %02x, %v", v7_b, time_b)
	log.debugf("C: %02x, %v", v7_c, time_c)

	testing.expect(t, time.diff(time_a, time_b) > 0, "The time on the later-generated v7 UUID is earlier than its successor.")
	testing.expect(t, time.diff(time_b, time_c) > 0, "The time on the later-generated v7 UUID is earlier than its successor.")
	testing.expect(t, time.diff(time_a, time_c) > 0, "The time on the later-generated v7 UUID is earlier than its successor.")

	v7_with_counter := uuid.generate_v7(0x555)
	log.debugf("D: %02x", v7_with_counter)
	testing.expect_value(t, uuid.counter_v7(v7_with_counter), 0x555)
}

@(test)
test_sorting_v1 :: proc(t: ^testing.T) {
	// This test is to make sure that the v1 UUIDs do _not_ sort.
	// They are incapable of sorting properly by the nature their time bit ordering.
	//
	// Something is very strange if they do sort correctly.
	point_a := time.unix(1, 0)
	point_b := time.unix(3, 0)
	point_c := time.unix(5, 0)
	point_d := time.unix(7, 0)
	point_e := time.unix(11, 0)

	mac: [6]byte
	v1_a := uuid.generate_v1(0, mac, point_a)
	v1_b := uuid.generate_v1(0, mac, point_b)
	v1_c := uuid.generate_v1(0, mac, point_c)
	v1_d := uuid.generate_v1(0, mac, point_d)
	v1_e := uuid.generate_v1(0, mac, point_e)

	sort_test := [5]u128be {
		transmute(u128be)v1_e,
		transmute(u128be)v1_a,
		transmute(u128be)v1_d,
		transmute(u128be)v1_b,
		transmute(u128be)v1_c,
	}

	log.debugf("Before: %x", sort_test)
	slice.sort(sort_test[:])
	log.debugf("After:  %x", sort_test)

	ERROR :: "v1 UUIDs are sorting by time, despite this not being possible."

	testing.expect(t, sort_test[0] != transmute(u128be)v1_a, ERROR)
	testing.expect(t, sort_test[1] != transmute(u128be)v1_b, ERROR)
	testing.expect(t, sort_test[2] != transmute(u128be)v1_c, ERROR)
	testing.expect(t, sort_test[3] != transmute(u128be)v1_d, ERROR)
	testing.expect(t, sort_test[4] != transmute(u128be)v1_e, ERROR)
}

@(test)
test_sorting_v6 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	point_a := time.unix(1, 0)
	point_b := time.unix(3, 0)
	point_c := time.unix(5, 0)
	point_d := time.unix(7, 0)
	point_e := time.unix(11, 0)

	mac: [6]byte
	v6_a := uuid.generate_v6(0, mac, point_a)
	v6_b := uuid.generate_v6(0, mac, point_b)
	v6_c := uuid.generate_v6(0, mac, point_c)
	v6_d := uuid.generate_v6(0, mac, point_d)
	v6_e := uuid.generate_v6(0, mac, point_e)

	sort_test := [5]u128be {
		transmute(u128be)v6_e,
		transmute(u128be)v6_a,
		transmute(u128be)v6_d,
		transmute(u128be)v6_b,
		transmute(u128be)v6_c,
	}

	log.debugf("Before: %x", sort_test)
	slice.sort(sort_test[:])
	log.debugf("After:  %x", sort_test)

	ERROR :: "v6 UUIDs are failing to sort properly."

	testing.expect(t, sort_test[0] < sort_test[1], ERROR)
	testing.expect(t, sort_test[1] < sort_test[2], ERROR)
	testing.expect(t, sort_test[2] < sort_test[3], ERROR)
	testing.expect(t, sort_test[3] < sort_test[4], ERROR)

	testing.expect(t, sort_test[0] == transmute(u128be)v6_a, ERROR)
	testing.expect(t, sort_test[1] == transmute(u128be)v6_b, ERROR)
	testing.expect(t, sort_test[2] == transmute(u128be)v6_c, ERROR)
	testing.expect(t, sort_test[3] == transmute(u128be)v6_d, ERROR)
	testing.expect(t, sort_test[4] == transmute(u128be)v6_e, ERROR)
}

@(test)
test_sorting_v7 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	point_a := time.unix(1, 0)
	point_b := time.unix(3, 0)
	point_c := time.unix(5, 0)
	point_d := time.unix(7, 0)
	point_e := time.unix(11, 0)

	v7_a := uuid.generate_v7(point_a)
	v7_b := uuid.generate_v7(point_b)
	v7_c := uuid.generate_v7(point_c)
	v7_d := uuid.generate_v7(point_d)
	v7_e := uuid.generate_v7(point_e)

	sort_test := [5]u128be {
		transmute(u128be)v7_e,
		transmute(u128be)v7_a,
		transmute(u128be)v7_d,
		transmute(u128be)v7_b,
		transmute(u128be)v7_c,
	}

	log.debugf("Before: %x", sort_test)
	slice.sort(sort_test[:])
	log.debugf("After:  %x", sort_test)

	ERROR :: "v7 UUIDs are failing to sort properly."

	testing.expect(t, sort_test[0] < sort_test[1], ERROR)
	testing.expect(t, sort_test[1] < sort_test[2], ERROR)
	testing.expect(t, sort_test[2] < sort_test[3], ERROR)
	testing.expect(t, sort_test[3] < sort_test[4], ERROR)

	testing.expect(t, sort_test[0] == transmute(u128be)v7_a, ERROR)
	testing.expect(t, sort_test[1] == transmute(u128be)v7_b, ERROR)
	testing.expect(t, sort_test[2] == transmute(u128be)v7_c, ERROR)
	testing.expect(t, sort_test[3] == transmute(u128be)v7_d, ERROR)
	testing.expect(t, sort_test[4] == transmute(u128be)v7_e, ERROR)
}

@(test)
test_writing :: proc(t: ^testing.T) {
	id: uuid.Identifier

	for &b, i in id {
		b = u8(i)
	}

	buf: [uuid.EXPECTED_LENGTH]u8

	s_alloc := uuid.to_string(id)
	defer delete(s_alloc)

	s_buf := uuid.to_string(id, buf[:])

	testing.expect_value(t, s_alloc, "00010203-0405-0607-0809-0a0b0c0d0e0f")
	testing.expect_value(t, s_buf, "00010203-0405-0607-0809-0a0b0c0d0e0f")
}

@(test)
test_reading :: proc(t: ^testing.T) {
	id, err := uuid.read("00010203-0405-0607-0809-0a0b0c0d0e0f")
	testing.expect_value(t, err, nil)

	for b, i in id {
		testing.expect_value(t, b, u8(i))
	}
}

@(test)
test_reading_errors :: proc(t: ^testing.T) {
	{
		BAD_STRING :: "|.......@....@....@....@............"
		_, err := uuid.read(BAD_STRING)
		testing.expect_value(t, err, uuid.Read_Error.Invalid_Separator)
	}

	{
		BAD_STRING :: "|.......-....-....-....-............"
		_, err := uuid.read(BAD_STRING)
		testing.expect_value(t, err, uuid.Read_Error.Invalid_Hexadecimal)
	}

	{
		BAD_STRING :: ".......-....-....-....-............"
		_, err := uuid.read(BAD_STRING)
		testing.expect_value(t, err, uuid.Read_Error.Invalid_Length)
	}

	{
		BAD_STRING :: "|.......-....-....-....-............|"
		_, err := uuid.read(BAD_STRING)
		testing.expect_value(t, err, uuid.Read_Error.Invalid_Length)
	}

	{
		BAD_STRING :: "00000000-0000-0000-0000-0000000000001"
		_, err := uuid.read(BAD_STRING)
		testing.expect_value(t, err, uuid.Read_Error.Invalid_Length)
	}

	{
		BAD_STRING :: "00000000000000000000000000000000"
		_, err := uuid.read(BAD_STRING)
		testing.expect_value(t, err, uuid.Read_Error.Invalid_Length)
	}

	{
		OK_STRING :: "00000000-0000-0000-0000-000000000000"
		_, err := uuid.read(OK_STRING)
		testing.expect_value(t, err, nil)
	}
}
