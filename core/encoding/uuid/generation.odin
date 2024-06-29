package uuid

import "base:runtime"
import "core:crypto/hash"
import "core:math/rand"
import "core:time"

/*
Generate a version 1 UUID.

Inputs:
- clock_seq: The clock sequence, a number which must be initialized to a random number once in the lifetime of a system.
- node: An optional 48-bit spatially unique identifier, specified to be the IEEE 802 address of the system.
  If one is not provided or available, 48 bits of random state will take its place.
- timestamp: A timestamp from the `core:time` package, or `nil` to use the current time.

Returns:
- result: The generated UUID.
*/
generate_v1 :: proc(clock_seq: u16, node: Maybe([6]u8) = nil, timestamp: Maybe(time.Time) = nil) -> (result: Identifier) {
	assert(clock_seq <= 0x3FFF, BIG_CLOCK_ERROR)
	unix_time_in_hns_intervals := time.to_unix_nanoseconds(timestamp.? or_else time.now()) / 100

	uuid_timestamp := cast(u64le)(HNS_INTERVALS_BETWEEN_GREG_AND_UNIX + unix_time_in_hns_intervals)
	uuid_timestamp_octets := transmute([8]u8)uuid_timestamp

	result[0] = uuid_timestamp_octets[0]
	result[1] = uuid_timestamp_octets[1]
	result[2] = uuid_timestamp_octets[2]
	result[3] = uuid_timestamp_octets[3]
	result[4] = uuid_timestamp_octets[4]
	result[5] = uuid_timestamp_octets[5]

	result[6] = uuid_timestamp_octets[6] >> 4
	result[7] = uuid_timestamp_octets[6] << 4 | uuid_timestamp_octets[7]

	if realized_node, ok := node.?; ok {
		mutable_node := realized_node
		runtime.mem_copy_non_overlapping(&result[10], &mutable_node[0], 6)
	} else {
		assert(.Cryptographic in runtime.random_generator_query_info(context.random_generator), NO_CSPRNG_ERROR)
		bytes_generated := rand.read(result[10:])
		assert(bytes_generated == 6, "RNG failed to generate 6 bytes for UUID v1.")
	}

	result[VERSION_BYTE_INDEX] |= 0x10
	result[VARIANT_BYTE_INDEX] |= 0x80

	result[8] |= cast(u8)(clock_seq & 0x3F00 >> 8)
	result[9]  = cast(u8)clock_seq

	return
}

/*
Generate a version 4 UUID.

This UUID will be pseudorandom, save for 6 pre-determined version and variant bits.

Returns:
- result: The generated UUID.
*/
generate_v4 :: proc() -> (result: Identifier) {
	assert(.Cryptographic in runtime.random_generator_query_info(context.random_generator), NO_CSPRNG_ERROR)
	bytes_generated := rand.read(result[:])
	assert(bytes_generated == 16, "RNG failed to generate 16 bytes for UUID v4.")

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x40

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 6 UUID.

Inputs:
- clock_seq: The clock sequence from version 1, now made optional.
  If unspecified, it will be replaced with random bits.
- node: An optional 48-bit spatially unique identifier, specified to be the IEEE 802 address of the system.
  If one is not provided or available, 48 bits of random state will take its place.
- timestamp: A timestamp from the `core:time` package, or `nil` to use the current time.

Returns:
- result: The generated UUID.
*/
generate_v6 :: proc(clock_seq: Maybe(u16) = nil, node: Maybe([6]u8) = nil, timestamp: Maybe(time.Time) = nil) -> (result: Identifier) {
	unix_time_in_hns_intervals := time.to_unix_nanoseconds(timestamp.? or_else time.now()) / 100

	uuid_timestamp := cast(u128be)(HNS_INTERVALS_BETWEEN_GREG_AND_UNIX + unix_time_in_hns_intervals)

	result = transmute(Identifier)(
		uuid_timestamp & 0x0FFFFFFF_FFFFF000 << 68 |
		uuid_timestamp & 0x00000000_00000FFF << 64
	)

	if realized_clock_seq, ok := clock_seq.?; ok {
		assert(realized_clock_seq <= 0x3FFF, BIG_CLOCK_ERROR)
		result[8] |= cast(u8)(realized_clock_seq & 0x3F00 >> 8)
		result[9]  = cast(u8)realized_clock_seq
	} else {
		assert(.Cryptographic in runtime.random_generator_query_info(context.random_generator), NO_CSPRNG_ERROR)
		temporary: [2]u8
		bytes_generated := rand.read(temporary[:])
		assert(bytes_generated == 2, "RNG failed to generate 2 bytes for UUID v1.")
		result[8] |= temporary[0] & 0x3F
		result[9]  = temporary[1]
	}

	if realized_node, ok := node.?; ok {
		mutable_node := realized_node
		runtime.mem_copy_non_overlapping(&result[10], &mutable_node[0], 6)
	} else {
		assert(.Cryptographic in runtime.random_generator_query_info(context.random_generator), NO_CSPRNG_ERROR)
		bytes_generated := rand.read(result[10:])
		assert(bytes_generated == 6, "RNG failed to generate 6 bytes for UUID v1.")
	}

	result[VERSION_BYTE_INDEX] |= 0x60
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 7 UUID.

This UUID will be pseudorandom, save for 6 pre-determined version and variant
bits and a 48-bit timestamp.

It is designed with time-based sorting in mind, such as for database usage, as
the highest bits are allocated from the timestamp of when it is created.

Inputs:
- timestamp: A timestamp from the `core:time` package, or `nil` to use the current time.

Returns:
- result: The generated UUID.
*/
generate_v7_basic :: proc(timestamp: Maybe(time.Time) = nil) -> (result: Identifier) {
	assert(.Cryptographic in runtime.random_generator_query_info(context.random_generator), NO_CSPRNG_ERROR)
	unix_time_in_milliseconds := time.to_unix_nanoseconds(timestamp.? or_else time.now()) / 1e6

	result = transmute(Identifier)(cast(u128be)unix_time_in_milliseconds << VERSION_7_TIME_SHIFT)

	bytes_generated := rand.read(result[6:])
	assert(bytes_generated == 10, "RNG failed to generate 10 bytes for UUID v7.")

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x70

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 7 UUID that has an incremented counter.

This UUID will be pseudorandom, save for 6 pre-determined version and variant
bits, a 48-bit timestamp, and 12 bits of counter state.

It is designed with time-based sorting in mind, such as for database usage, as
the highest bits are allocated from the timestamp of when it is created.

This procedure is preferable if you are generating hundreds or thousands of
UUIDs as a batch within the span of a millisecond. Do note that the counter
only has 12 bits of state, thus `counter` cannot exceed the number 4,095.

Example:

	import "core:uuid"

	// Create a batch of UUIDs all at once.
	batch: [dynamic]uuid.Identifier

	for i: u16 = 0; i < 1000; i += 1 {
		my_uuid := uuid.generate_v7_counter(i)
		append(&batch, my_uuid)
	}

Inputs:
- counter: A 12-bit value which should be incremented each time a UUID is generated in a batch.
- timestamp: A timestamp from the `core:time` package, or `nil` to use the current time.

Returns:
- result: The generated UUID.
*/
generate_v7_with_counter :: proc(counter: u16, timestamp: Maybe(time.Time) = nil) -> (result: Identifier) {
	assert(.Cryptographic in runtime.random_generator_query_info(context.random_generator), NO_CSPRNG_ERROR)
	assert(counter <= 0x0fff, VERSION_7_BIG_COUNTER_ERROR)
	unix_time_in_milliseconds := time.to_unix_nanoseconds(timestamp.? or_else time.now()) / 1e6

	result = transmute(Identifier)(
		cast(u128be)unix_time_in_milliseconds << VERSION_7_TIME_SHIFT |
		cast(u128be)counter << VERSION_7_COUNTER_SHIFT
	)

	bytes_generated := rand.read(result[8:])
	assert(bytes_generated == 8, "RNG failed to generate 8 bytes for UUID v7.")

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x70

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

generate_v7 :: proc {
	generate_v7_basic,
	generate_v7_with_counter,
}

/*
Generate a version 8 UUID using a specific hashing algorithm.

This UUID is generated by hashing a name with a namespace.

Note that all version 8 UUIDs are for experimental or vendor-specific use
cases, per the specification. This use case in particular is for offering a
non-legacy alternative to UUID versions 3 and 5.

Inputs:
- namespace: An `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in this package.
- name: The byte slice which will be hashed with the namespace.
- algorithm: A hashing algorithm from `core:crypto/hash`.

Returns:
- result: The generated UUID.

Example:
	import "core:crypto/hash"
	import "core:encoding/uuid"
	import "core:fmt"

	main :: proc() {
		my_uuid := uuid.generate_v8_hash(uuid.Namespace_DNS, "www.odin-lang.org", .SHA256)
		my_uuid_string := uuid.to_string(my_uuid, context.temp_allocator)
		fmt.println(my_uuid_string)
	}

Output:

	3730f688-4bff-8dce-9cbf-74a3960c5703

*/
generate_v8_hash_bytes :: proc(
	namespace: Identifier,
	name: []byte,
	algorithm: hash.Algorithm,
) -> (
	result: Identifier,
) {
	// 128 bytes should be enough for the foreseeable future.
	digest: [128]byte

	assert(hash.DIGEST_SIZES[algorithm] >= 16, "Per RFC 9562, the hashing algorithm used must generate a digest of 128 bits or larger.")
	assert(hash.DIGEST_SIZES[algorithm] < len(digest), "Digest size is too small for this algorithm. The buffer must be increased.")

	hash_context: hash.Context
	hash.init(&hash_context, algorithm)

	mutable_namespace := namespace
	hash.update(&hash_context, mutable_namespace[:])
	hash.update(&hash_context, name[:])
	hash.final(&hash_context, digest[:])

	runtime.mem_copy_non_overlapping(&result, &digest, 16)

	result[VERSION_BYTE_INDEX] &= 0x0F
	result[VERSION_BYTE_INDEX] |= 0x80

	result[VARIANT_BYTE_INDEX] &= 0x3F
	result[VARIANT_BYTE_INDEX] |= 0x80

	return
}

/*
Generate a version 8 UUID using a specific hashing algorithm.

This UUID is generated by hashing a name with a namespace.

Note that all version 8 UUIDs are for experimental or vendor-specific use
cases, per the specification. This use case in particular is for offering a
non-legacy alternative to UUID versions 3 and 5.

Inputs:
- namespace: An `Identifier` that is used to represent the underlying namespace.
  This can be any one of the `Namespace_*` values provided in this package.
- name: The string which will be hashed with the namespace.
- algorithm: A hashing algorithm from `core:crypto/hash`.

Returns:
- result: The generated UUID.

Example:
	import "core:crypto/hash"
	import "core:encoding/uuid"
	import "core:fmt"

	main :: proc() {
		my_uuid := uuid.generate_v8_hash(uuid.Namespace_DNS, "www.odin-lang.org", .SHA256)
		my_uuid_string := uuid.to_string(my_uuid, context.temp_allocator)
		fmt.println(my_uuid_string)
	}

Output:

	3730f688-4bff-8dce-9cbf-74a3960c5703

*/
generate_v8_hash_string :: proc(
	namespace: Identifier,
	name: string,
	algorithm: hash.Algorithm,
) -> (
	result: Identifier,
) {
	return generate_v8_hash_bytes(namespace, transmute([]byte)name, algorithm)
}

generate_v8_hash :: proc {
	generate_v8_hash_bytes,
	generate_v8_hash_string,
}
