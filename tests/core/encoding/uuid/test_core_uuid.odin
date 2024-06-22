package test_core_uuid

import "core:crypto"
import "core:encoding/uuid"
import uuid_legacy "core:encoding/uuid/legacy"
import "core:log"
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

	CLOCK :: 0x3A1A
	v1_a := uuid.generate_v1(CLOCK)
	time.sleep(10 * time.Millisecond)
	v1_b := uuid.generate_v1(CLOCK)
	time.sleep(10 * time.Millisecond)
	v1_c := uuid.generate_v1(CLOCK)

	testing.expect_value(t, uuid.clock_seq(v1_a), CLOCK)

	time_bits_a := uuid.time_v1(v1_a)
	time_bits_b := uuid.time_v1(v1_b)
	time_bits_c := uuid.time_v1(v1_c)

	time_a := time.Time { _nsec = cast(i64)((time_bits_a - uuid.HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100) }
	time_b := time.Time { _nsec = cast(i64)((time_bits_b - uuid.HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100) }
	time_c := time.Time { _nsec = cast(i64)((time_bits_c - uuid.HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100) }

	log.debugf("A: %02x, %i, %v", v1_a, time_bits_a, time_a)
	log.debugf("B: %02x, %i, %v", v1_b, time_bits_b, time_b)
	log.debugf("C: %02x, %i, %v", v1_c, time_bits_c, time_c)

	testing.expect(t, time_bits_b > time_bits_a, "The time bits on the later-generated v1 UUID are lesser than the earlier UUID.")
	testing.expect(t, time_bits_c > time_bits_b, "The time bits on the later-generated v1 UUID are lesser than the earlier UUID.")
	testing.expect(t, time_bits_c > time_bits_a, "The time bits on the later-generated v1 UUID are lesser than the earlier UUID.")
}

@(test)
test_v6 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	CLOCK :: 0x3A1A
	v6_a := uuid.generate_v6(CLOCK)
	time.sleep(10 * time.Millisecond)
	v6_b := uuid.generate_v6(CLOCK)
	time.sleep(10 * time.Millisecond)
	v6_c := uuid.generate_v6(CLOCK)

	testing.expect_value(t, uuid.clock_seq(v6_a), CLOCK)

	time_bits_a := uuid.time_v6(v6_a)
	time_bits_b := uuid.time_v6(v6_b)
	time_bits_c := uuid.time_v6(v6_c)

	time_a := time.Time { _nsec = cast(i64)((time_bits_a - uuid.HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100) }
	time_b := time.Time { _nsec = cast(i64)((time_bits_b - uuid.HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100) }
	time_c := time.Time { _nsec = cast(i64)((time_bits_c - uuid.HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100) }

	log.debugf("A: %02x, %i, %v", v6_a, time_bits_a, time_a)
	log.debugf("B: %02x, %i, %v", v6_b, time_bits_b, time_b)
	log.debugf("C: %02x, %i, %v", v6_c, time_bits_c, time_c)

	testing.expect(t, time_bits_b > time_bits_a, "The time bits on the later-generated v6 UUID are lesser than the earlier UUID.")
	testing.expect(t, time_bits_c > time_bits_b, "The time bits on the later-generated v6 UUID are lesser than the earlier UUID.")
	testing.expect(t, time_bits_c > time_bits_a, "The time bits on the later-generated v6 UUID are lesser than the earlier UUID.")
}

@(test)
test_v7 :: proc(t: ^testing.T) {
	context.random_generator = crypto.random_generator()

	v7_a := uuid.generate_v7()
	time.sleep(10 * time.Millisecond)
	v7_b := uuid.generate_v7()
	time.sleep(10 * time.Millisecond)
	v7_c := uuid.generate_v7()

	time_bits_a := uuid.time_v7(v7_a)
	time_bits_b := uuid.time_v7(v7_b)
	time_bits_c := uuid.time_v7(v7_c)

	log.debugf("A: %02x, %i", v7_a, time_bits_a)
	log.debugf("B: %02x, %i", v7_b, time_bits_b)
	log.debugf("C: %02x, %i", v7_c, time_bits_c)

	testing.expect(t, time_bits_b > time_bits_a, "The time bits on the later-generated v7 UUID are lesser than the earlier UUID.")
	testing.expect(t, time_bits_c > time_bits_b, "The time bits on the later-generated v7 UUID are lesser than the earlier UUID.")
	testing.expect(t, time_bits_c > time_bits_a, "The time bits on the later-generated v7 UUID are lesser than the earlier UUID.")

	v7_with_counter := uuid.generate_v7_counter(0x555)
	log.debugf("D: %02x", v7_with_counter)
	testing.expect_value(t, uuid.counter_v7(v7_with_counter), 0x555)
}

@(test)
test_writing :: proc(t: ^testing.T) {
    id: uuid.Identifier

    for &b, i in id {
        b = u8(i)
    }

    s := uuid.to_string(id)
    defer delete(s)

    testing.expect_value(t, s, "00010203-0405-0607-0809-0a0b0c0d0e0f")
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
