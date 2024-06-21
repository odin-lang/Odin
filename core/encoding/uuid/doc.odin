/*
package uuid implements Universally Unique Identifiers according to the
standard outlined in RFC 4122.

See here for more information: https://www.rfc-editor.org/rfc/rfc4122.html

Generation of versions 1 and 2 (the MAC address-based versions) are not yet
implemented.

The UUIDs are textually represented and read in the following string format:
`00000000-0000-4000-8000-000000000000`

Outside of string representations, they are represented in memory by a 128-bit structure.
*/
package uuid
