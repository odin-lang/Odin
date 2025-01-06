package uuid

import "base:runtime"
import "core:time"

/*
Convert a string to a UUID.

Inputs:
- str: A string in the 8-4-4-4-12 format.

Returns:
- id: The converted identifier, or `nil` if there is an error.
- error: A description of the error, or `nil` if successful.
*/
read :: proc "contextless" (str: string) -> (id: Identifier, error: Read_Error) #no_bounds_check {
	// Only exact-length strings are acceptable.
	if len(str) != EXPECTED_LENGTH {
		return {}, .Invalid_Length
	}

	// Check ahead to see if the separators are in the right places.
	if str[8] != '-' || str[13] != '-' || str[18] != '-' || str[23] != '-' {
		return {}, .Invalid_Separator
	}

	read_nibble :: proc "contextless" (nibble: u8) -> u8 {
		switch nibble {
		case '0' ..= '9':
			return nibble - '0'
		case 'A' ..= 'F':
			return nibble - 'A' + 10
		case 'a' ..= 'f':
			return nibble - 'a' + 10
		case:
			// Return an error value.
			return 0xFF
		}
	}

	index := 0
	octet_index := 0

	CHUNKS :: [5]int{8, 4, 4, 4, 12}

	for chunk in CHUNKS {
		for i := index; i < index + chunk; i += 2 {
			high := read_nibble(str[i])
			low := read_nibble(str[i + 1])

			if high | low > 0xF {
				return {}, .Invalid_Hexadecimal
			}

			id[octet_index] = low | high << 4
			octet_index += 1
		}

		index += chunk + 1
	}

	return
}

/*
Get the version of a UUID.

Inputs:
- id: The identifier.

Returns:
- number: The version number.
*/
version :: proc "contextless" (id: Identifier) -> (number: int) #no_bounds_check {
	return cast(int)(id[VERSION_BYTE_INDEX] & 0xF0 >> 4)
}

/*
Get the variant of a UUID.

Inputs:
- id: The identifier.

Returns:
- variant: The variant type.
*/
variant :: proc "contextless" (id: Identifier) -> (variant: Variant_Type) #no_bounds_check {
	switch {
	case id[VARIANT_BYTE_INDEX] & 0x80 == 0:
		return .Reserved_Apollo_NCS
	case id[VARIANT_BYTE_INDEX] & 0xC0 == 0x80:
		return .RFC_4122
	case id[VARIANT_BYTE_INDEX] & 0xE0 == 0xC0:
		return .Reserved_Microsoft_COM
	case id[VARIANT_BYTE_INDEX] & 0xF0 == 0xE0:
		return .Reserved_Future
	case:
		return .Unknown
	}
}

/*
Get the clock sequence of a version 1 or version 6 UUID.

Inputs:
- id: The identifier.

Returns:
- clock_seq: The 14-bit clock sequence field.
*/
clock_seq :: proc "contextless" (id: Identifier) -> (clock_seq: u16) {
	return cast(u16)id[9] | cast(u16)id[8] & 0x3F << 8
}

/*
Get the node of a version 1 or version 6 UUID.

Inputs:
- id: The identifier.

Returns:
- node: The 48-bit spatially unique identifier.
*/
node :: proc "contextless" (id: Identifier) -> (node: [6]u8) {
	mutable_id := id
	runtime.mem_copy_non_overlapping(&node, &mutable_id[10], 6)
	return
}

/*
Get the raw timestamp of a version 1 UUID.

Inputs:
- id: The identifier.

Returns:
- timestamp: The timestamp, in 100-nanosecond intervals since 1582-10-15.
*/
raw_time_v1 :: proc "contextless" (id: Identifier) -> (timestamp: u64) {
	timestamp_octets: [8]u8

	timestamp_octets[0] = id[0]
	timestamp_octets[1] = id[1]
	timestamp_octets[2] = id[2]
	timestamp_octets[3] = id[3]
	timestamp_octets[4] = id[4]
	timestamp_octets[5] = id[5]

	timestamp_octets[6] = id[6] << 4 | id[7] >> 4
	timestamp_octets[7] = id[7] & 0xF

	return cast(u64)transmute(u64le)timestamp_octets
}


/*
Get the timestamp of a version 1 UUID.

Inputs:
- id: The identifier.

Returns:
- timestamp: The timestamp of the UUID.
*/
time_v1 :: proc "contextless" (id: Identifier) -> (timestamp: time.Time) {
	return time.from_nanoseconds(cast(i64)(raw_time_v1(id) - HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100)
}

/*
Get the raw timestamp of a version 6 UUID.

Inputs:
- id: The identifier.

Returns:
- timestamp: The timestamp, in 100-nanosecond intervals since 1582-10-15.
*/
raw_time_v6 :: proc "contextless" (id: Identifier) -> (timestamp: u64) {
	temporary := transmute(u128be)id

	timestamp |= cast(u64)(temporary & 0xFFFFFFFF_FFFF0000_00000000_00000000 >> 68)
	timestamp |= cast(u64)(temporary & 0x00000000_00000FFF_00000000_00000000 >> 64)

	return timestamp
}

/*
Get the timestamp of a version 6 UUID.

Inputs:
- id: The identifier.

Returns:
- timestamp: The timestamp, in 100-nanosecond intervals since 1582-10-15.
*/
time_v6 :: proc "contextless" (id: Identifier) -> (timestamp: time.Time) {
	return time.from_nanoseconds(cast(i64)(raw_time_v6(id) - HNS_INTERVALS_BETWEEN_GREG_AND_UNIX) * 100)
}

/*
Get the raw timestamp of a version 7 UUID.

Inputs:
- id: The identifier.

Returns:
- timestamp: The timestamp, in milliseconds since the UNIX epoch.
*/
raw_time_v7 :: proc "contextless" (id: Identifier) -> (timestamp: u64) {
	time_bits := transmute(u128be)id & VERSION_7_TIME_MASK
	return cast(u64)(time_bits >> VERSION_7_TIME_SHIFT)
}

/*
Get the timestamp of a version 7 UUID.

Inputs:
- id: The identifier.

Returns:
- timestamp: The timestamp, in milliseconds since the UNIX epoch.
*/
time_v7 :: proc "contextless" (id: Identifier) -> (timestamp: time.Time) {
	return time.from_nanoseconds(cast(i64)raw_time_v7(id) * 1e6)
}

/*
Get the 12-bit counter value of a version 7 UUID.

The UUID must have been generated with a counter, otherwise this procedure will
return random bits.

Inputs:
- id: The identifier.

Returns:
- counter: The 12-bit counter value.
*/
counter_v7 :: proc "contextless" (id: Identifier) -> (counter: u16) {
	counter_bits := transmute(u128be)id & VERSION_7_COUNTER_MASK
	return cast(u16)(counter_bits >> VERSION_7_COUNTER_SHIFT)
}
