package uuid

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

			id.bytes[octet_index] = low | high << 4
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
	return cast(int)(id.bytes[VERSION_BYTE_INDEX] & 0xF0 >> 4)
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
	case id.bytes[VARIANT_BYTE_INDEX] & 0x80 == 0:
		return .Reserved_Apollo_NCS
	case id.bytes[VARIANT_BYTE_INDEX] & 0xC0 == 0x80:
		return .RFC_4122
	case id.bytes[VARIANT_BYTE_INDEX] & 0xE0 == 0xC0:
		return .Reserved_Microsoft_COM
	case id.bytes[VARIANT_BYTE_INDEX] & 0xF0 == 0xE0:
		return .Reserved_Future
	case:
		return .Unknown
	}
}
