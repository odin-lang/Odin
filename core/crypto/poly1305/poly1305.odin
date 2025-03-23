/*
package poly1305 implements the Poly1305 one-time MAC algorithm.

See:
- [[ https://datatracker.ietf.org/doc/html/rfc8439 ]]
*/
package poly1305

import "core:crypto"
import field "core:crypto/_fiat/field_poly1305"
import "core:encoding/endian"
import "core:math/bits"
import "core:mem"

// KEY_SIZE is the Poly1305 key size in bytes.
KEY_SIZE :: 32
// TAG_SIZE is the Poly1305 tag size in bytes.
TAG_SIZE :: 16

@(private)
_BLOCK_SIZE :: 16

// sum will compute the Poly1305 MAC with the key over msg, and write
// the computed tag to dst.  It requires that the dst buffer is the tag
// size.
//
// The key SHOULD be unique and MUST be unpredictable for each invocation.
sum :: proc(dst, msg, key: []byte) {
	ctx: Context = ---

	init(&ctx, key)
	update(&ctx, msg)
	final(&ctx, dst)
}

// verify will verify the Poly1305 tag computed with the key over msg and
// return true iff the tag is valid.  It requires that the tag is correctly
// sized.
verify :: proc(tag, msg, key: []byte) -> bool {
	ctx: Context = ---
	derived_tag: [TAG_SIZE]byte = ---

	init(&ctx, key)
	update(&ctx, msg)
	final(&ctx, derived_tag[:])

	return crypto.compare_constant_time(derived_tag[:], tag) == 1
}

// Context is a Poly1305 instance.
Context :: struct {
	_r:              field.Tight_Field_Element,
	_a:              field.Tight_Field_Element,
	_s:              [2]u64,
	_buffer:         [_BLOCK_SIZE]byte,
	_leftover:       int,
	_is_initialized: bool,
}

// init initializes a Context with the specified key.  The key SHOULD be
// unique and MUST be unpredictable for each invocation.
init :: proc(ctx: ^Context, key: []byte) {
	ensure(len(key) == KEY_SIZE, "crypto/poly1305: invalid key size")

	// r = le_bytes_to_num(key[0..15])
	// r = clamp(r) (r &= 0xffffffc0ffffffc0ffffffc0fffffff)
	tmp_lo := endian.unchecked_get_u64le(key[0:]) & 0x0ffffffc0fffffff
	tmp_hi := endian.unchecked_get_u64le(key[8:]) & 0x0ffffffc0ffffffc
	field.fe_from_u64s(&ctx._r, tmp_lo, tmp_hi)

	// s = le_bytes_to_num(key[16..31])
	ctx._s[0] = endian.unchecked_get_u64le(key[16:])
	ctx._s[1] = endian.unchecked_get_u64le(key[24:])

	// a = 0
	field.fe_zero(&ctx._a)

	// No leftover in buffer
	ctx._leftover = 0

	ctx._is_initialized = true
}

// update adds more data to the Context.
update :: proc(ctx: ^Context, data: []byte) {
	ensure(ctx._is_initialized)

	msg := data
	msg_len := len(data)

	// Handle leftover
	if ctx._leftover > 0 {
		want := min(_BLOCK_SIZE - ctx._leftover, msg_len)
		copy_slice(ctx._buffer[ctx._leftover:], msg[:want])
		msg_len = msg_len - want
		msg = msg[want:]
		ctx._leftover = ctx._leftover + want
		if ctx._leftover < _BLOCK_SIZE {
			return
		}
		_blocks(ctx, ctx._buffer[:])
		ctx._leftover = 0
	}

	// Process full blocks
	if msg_len >= _BLOCK_SIZE {
		want := msg_len & (~int(_BLOCK_SIZE - 1))
		_blocks(ctx, msg[:want])
		msg = msg[want:]
		msg_len = msg_len - want
	}

	// Store leftover
	if msg_len > 0 {
		// TODO: While -donna does it this way, I'm fairly sure that
		// `ctx._leftover == 0` is an invariant at this point.
		copy(ctx._buffer[ctx._leftover:], msg)
		ctx._leftover = ctx._leftover + msg_len
	}
}

// final finalizes the Context, writes the tag to dst, and calls
// reset on the Context.
final :: proc(ctx: ^Context, dst: []byte) {
	defer reset(ctx)

	ensure(ctx._is_initialized)
	ensure(len(dst) == TAG_SIZE, "poly1305: invalid destination tag size")

	// Process remaining block
	if ctx._leftover > 0 {
		ctx._buffer[ctx._leftover] = 1
		for i := ctx._leftover + 1; i < _BLOCK_SIZE; i = i + 1 {
			ctx._buffer[i] = 0
		}
		_blocks(ctx, ctx._buffer[:], true)
	}

	// a += s (NOT mod p)
	tmp: [32]byte = ---
	field.fe_to_bytes(&tmp, &ctx._a)

	c: u64
	lo := endian.unchecked_get_u64le(tmp[0:])
	hi := endian.unchecked_get_u64le(tmp[8:])

	lo, c = bits.add_u64(lo, ctx._s[0], 0)
	hi, _ = bits.add_u64(hi, ctx._s[1], c)

	// return num_to_16_le_bytes(a)
	endian.unchecked_put_u64le(dst[0:], lo)
	endian.unchecked_put_u64le(dst[8:], hi)
}

// reset sanitizes the Context.  The Context must be re-initialized to
// be used again.
reset :: proc(ctx: ^Context) {
	mem.zero_explicit(&ctx._r, size_of(ctx._r))
	mem.zero_explicit(&ctx._a, size_of(ctx._a))
	mem.zero_explicit(&ctx._s, size_of(ctx._s))
	mem.zero_explicit(&ctx._buffer, size_of(ctx._buffer))

	ctx._is_initialized = false
}

@(private)
_blocks :: proc "contextless" (ctx: ^Context, msg: []byte, final := false) {
	n: field.Tight_Field_Element = ---
	final_byte := byte(!final)

	data := msg
	data_len := len(data)
	for data_len >= _BLOCK_SIZE {
		// n = le_bytes_to_num(msg[((i-1)*16)..*i*16] | [0x01])
		field.fe_from_bytes(&n, data[:_BLOCK_SIZE], final_byte)

		// a += n
		field.fe_add(field.fe_relax_cast(&ctx._a), &ctx._a, &n) // _a unreduced

		// a = (r * a) % p
		field.fe_carry_mul(&ctx._a, field.fe_relax_cast(&ctx._a), field.fe_relax_cast(&ctx._r)) // _a reduced

		data = data[_BLOCK_SIZE:]
		data_len = data_len - _BLOCK_SIZE
	}
}
