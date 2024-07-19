/*
package uuid implements Universally Unique Identifiers according to the
standard originally outlined in RFC 4122 with additions from RFC 9562.

The UUIDs are textually represented and read in the following string format:
`00000000-0000-v000-V000-000000000000`

`v` is where the version bits reside, and `V` is where the variant bits reside.
The meaning of the other bits is version-dependent.

Outside of string representations, UUIDs are represented in memory by a 128-bit
structure organized as an array of 16 bytes.


Of the UUID versions which may make use of random number generation, a
requirement is placed upon them that the underlying generator be
cryptographically-secure, per RFC 9562's suggestion.

- Version 1 without a node argument.
- Version 4 in all cases.
- Version 6 without either a clock or node argument.
- Version 7 in all cases.

Here's an example of how to set up one:
	
	import "core:crypto"
	import "core:encoding/uuid"

	main :: proc() {
		my_uuid: uuid.Identifier

		{
			// This scope will have a CSPRNG.
			context.random_generator = crypto.random_generator()
			my_uuid = uuid.generate_v7()
		}

		// Back to the default random number generator.
	}


For more information on the specifications, see here:
- https://www.rfc-editor.org/rfc/rfc4122.html
- https://www.rfc-editor.org/rfc/rfc9562.html
*/
package uuid
