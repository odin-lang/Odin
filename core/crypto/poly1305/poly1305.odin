package poly1305

import "core:crypto"
import "core:crypto/util"
import field "core:crypto/_fiat/field_poly1305"
import "core:mem"

KEY_SIZE :: 32
TAG_SIZE :: 16

_BLOCK_SIZE :: 16

sum :: proc (dst, msg, key: []byte) {
	ctx: Context = ---

	init(&ctx, key)
	update(&ctx, msg)
	final(&ctx, dst)
}

verify :: proc (tag, msg, key: []byte) -> bool {
	ctx: Context = ---
	derived_tag: [16]byte = ---

	if len(tag) != TAG_SIZE {
		panic("crypto/poly1305: invalid tag size")
	}

	init(&ctx, key)
	update(&ctx, msg)
	final(&ctx, derived_tag[:])

	return crypto.compare_constant_time(derived_tag[:], tag) == 1
}

Context :: struct {
	_r: field.Tight_Field_Element,
	_a: field.Tight_Field_Element,
	_s: field.Tight_Field_Element,

	_buffer: [_BLOCK_SIZE]byte,
	_leftover: int,

	_is_initialized: bool,
}

init :: proc (ctx: ^Context, key: []byte) {
	if len(key) != KEY_SIZE {
		panic("crypto/poly1305: invalid key size")
	}

	// r = le_bytes_to_num(key[0..15])
	// r = clamp(r) (r &= 0xffffffc0ffffffc0ffffffc0fffffff)
	tmp_lo := util.U64_LE(key[0:8]) & 0x0ffffffc0fffffff
	tmp_hi := util.U64_LE(key[8:16]) & 0xffffffc0ffffffc
	field.fe_from_u64s(&ctx._r, tmp_lo, tmp_hi)

	// s = le_bytes_to_num(key[16..31])
	field.fe_from_bytes(&ctx._s, key[16:32], 0)

	// a = 0
	field.fe_zero(&ctx._a)

	// No leftover in buffer
	ctx._leftover = 0

	ctx._is_initialized = true
}

update :: proc (ctx: ^Context, data: []byte) {
	assert(ctx._is_initialized)

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

final :: proc (ctx: ^Context, dst: []byte) {
	assert(ctx._is_initialized)

	if len(dst) != TAG_SIZE {
		panic("poly1305: invalid destination tag size")
	}

	// Process remaining block
	if ctx._leftover > 0 {
		ctx._buffer[ctx._leftover] = 1
		for i := ctx._leftover + 1; i < _BLOCK_SIZE; i = i + 1 {
			ctx._buffer[i] = 0
		}
		_blocks(ctx, ctx._buffer[:], true)
	}

	// a += s
	field.fe_add(field.fe_relax_cast(&ctx._a), &ctx._a, &ctx._s) // _a unreduced
	field.fe_carry(&ctx._a, field.fe_relax_cast(&ctx._a)) // _a reduced

	// return num_to_16_le_bytes(a)
	tmp: [32]byte = ---
	field.fe_to_bytes(&tmp, &ctx._a)
	copy_slice(dst, tmp[0:16])

	reset(ctx)
}

reset :: proc (ctx: ^Context) {
	mem.zero_explicit(&ctx._r, size_of(ctx._r))
	mem.zero_explicit(&ctx._a, size_of(ctx._a))
	mem.zero_explicit(&ctx._s, size_of(ctx._s))
	mem.zero_explicit(&ctx._buffer, size_of(ctx._buffer))

	ctx._is_initialized = false
}

_blocks :: proc (ctx: ^Context, msg: []byte, final := false) {
	n: field.Tight_Field_Element = ---
	final_byte := byte(!final)

	data := msg
	data_len := len(data)
	for data_len >= _BLOCK_SIZE {
		// n = le_bytes_to_num(msg[((i-1)*16)..*i*16] | [0x01])
		field.fe_from_bytes(&n, data[:_BLOCK_SIZE], final_byte, false)

		// a += n
		field.fe_add(field.fe_relax_cast(&ctx._a), &ctx._a, &n) // _a unreduced

		// a = (r * a) % p
		field.fe_carry_mul(&ctx._a, field.fe_relax_cast(&ctx._a), field.fe_relax_cast(&ctx._r)) // _a reduced

		data = data[_BLOCK_SIZE:]
		data_len = data_len - _BLOCK_SIZE
	}
}
