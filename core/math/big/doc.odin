/*
A BigInt implementation in Odin.
For the theoretical underpinnings, see Knuth's The Art of Computer Programming, Volume 2, section 4.3.
The code started out as an idiomatic source port of libTomMath, which is in the public domain, with thanks.

==========================    Low-level routines    ==========================

IMPORTANT: `internal_*` procedures make certain assumptions about their input.

The public functions that call them are expected to satisfy their sanity check requirements.
This allows `internal_*` call `internal_*` without paying this overhead multiple times.

Where errors can occur, they are of course still checked and returned as appropriate.

When importing `math:core/big` to implement an involved algorithm of your own, you are welcome
to use these procedures instead of their public counterparts.

Most inputs and outputs are expected to be passed an initialized `Int`, for example.
Exceptions include `quotient` and `remainder`, which are allowed to be `nil` when the calling code doesn't need them.

Check the comments above each `internal_*` implementation to see what constraints it expects to have met.

We pass the custom allocator to procedures by default using the pattern `context.allocator = allocator`.
This way we don't have to add `, allocator` at the end of each call.

TODO: Handle +/- Infinity and NaN.
*/
package math_big
