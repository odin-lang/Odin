// An implementation of the PPMd compression methods
//
// Reads and writes raw PPMd var.H streams as stored in 7z (method 03 04 01),
// and raw PPMd var.I rev.1 streams as stored in zip (method 98).
// It is a port of Igor Pavlov's public domain code from the LZMA SDK and 7-Zip, and the encoder's output is byte-identical to 7-Zip's.
package compress_ppmd

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	PPMd var.H, ported from the LZMA SDK 26.05 (2026-10-21), written by Igor Pavlov and placed in the public domain:
		https://www.7-zip.org/sdk.html

		C/Ppmd7.c, C/Ppmd.h:          model and sub-allocator
		C/Ppmd7Dec.c:                 decoder, with 7z's range coder
		C/Ppmd7Enc.c:                 encoder

	PPMd var.I rev.1, ported from 7-Zip 26.02, written by Igor Pavlov and placed in the public domain:
		https://www.7-zip.org/

		C/Ppmd8.c:                    model, sub-allocator and restore methods
		C/Ppmd8Dec.c, C/Ppmd8Enc.c:   decoder and encoder

	Both are based on Dmitry Shkarin's public domain PPMd var.H (2001) and var.I (2002).
	var.I's range coder is Dmitry Subbotin's public domain carryless range coder (1999).

	Many thanks to Igor Pavlov, and to Dmitry Shkarin for PPMd.
*/

import "base:intrinsics"
import "base:runtime"
import "core:compress"

Error         :: compress.Error
General_Error :: compress.General_Error
PPMd_Error    :: compress.PPMd_Error

Variant :: enum u8 {
	H,
	I,
}

Restore_Method :: enum u8 {
	Restart = 0,
	Cut_Off = 1,
	Freeze  = 2,
}

Properties :: struct {
	variant:  Variant,
	order:    u8,
	mem_size: u32,
	restore:  Restore_Method,
}

Level :: enum i32 {
	Level_0 = 0,
	Level_1 = 1,
	Level_2 = 2,
	Level_3 = 3,
	Level_4 = 4,
	Level_5 = 5,
	Level_6 = 6,
	Level_7 = 7,
	Level_8 = 8,
	Level_9 = 9,
	Fastest = Level_0,
	Default = Level_5,
	Best    = Level_9,
}

ORDER_MIN      :: 2
H_ORDER_MAX    :: 64
I_ORDER_MAX    :: 16
MEM_SIZE_MIN   :: 1 << 11
MEM_SIZE_MAX   :: 0xFFFF_FFFF - 12 * 3
CUT_OFF_MEM_SIZE_MIN :: (1 + 256 / 2) * 12 * 4 / 3
PROPERTIES_7Z_SIZE  :: 5
PROPERTIES_ZIP_SIZE :: 2
ZIP_MEM_SIZE_MAX    :: 256 << 20

when size_of(uintptr) == 8 {
	MEMORY_MAX :: int(#config(PPMD_MEMORY_MAX, MEM_SIZE_MAX))
} else {
	MEMORY_MAX :: int(#config(PPMD_MEMORY_MAX, 1 << 29))
}
#assert(MEMORY_MAX <= max(int) - 3)

level_properties :: proc "contextless" (variant: Variant, level := Level.Default, input_size := -1) -> (props: Properties) {
	l := clamp(int(level), 0, 9)
	props.variant  = variant
	props.mem_size = u32(1) << uint(19 + l)
	if variant == .H {
		props.order = LEVEL_ORDER_H[l]
	} else {
		props.order    = u8(3 + l)
		props.restore  = .Cut_Off if l >= 7 else .Restart
		props.mem_size = max(props.mem_size, 1 << 20)
	}
	if input_size >= 0 {
		reduced := u64(1) << 16
		for reduced < 16 * u64(input_size) && reduced < u64(props.mem_size) {
			reduced <<= 1
		}
		if variant == .I {
			reduced = max(reduced, 1 << 20)
		}
		props.mem_size = u32(min(u64(props.mem_size), reduced))
	}
	return
}

decode_properties_7z :: proc "contextless" (data: []u8) -> (props: Properties, err: Error) {
	if len(data) < PROPERTIES_7Z_SIZE {
		return {}, PPMd_Error.Invalid_Properties
	}
	props.variant  = .H
	props.order    = data[0]
	props.mem_size = u32(data[1]) | u32(data[2]) << 8 | u32(data[3]) << 16 | u32(data[4]) << 24
	if !valid_properties(props) {
		return {}, PPMd_Error.Invalid_Properties
	}
	return props, nil
}

encode_properties_7z :: proc "contextless" (props: Properties) -> (data: [PROPERTIES_7Z_SIZE]u8, err: Error) {
	if props.variant != .H || !valid_properties(props) {
		return {}, PPMd_Error.Invalid_Properties
	}
	data[0] = props.order
	for i in 0..<4 {
		data[1 + i] = u8(props.mem_size >> (8 * uint(i)))
	}
	return data, nil
}

decode_properties_zip :: proc "contextless" (data: []u8) -> (props: Properties, err: Error) {
	if len(data) < PROPERTIES_ZIP_SIZE {
		return {}, PPMd_Error.Invalid_Properties
	}
	w := u32(data[0]) | u32(data[1]) << 8
	props.variant  = .I
	props.order    = u8(w & 0xF) + 1
	props.mem_size = (((w >> 4) & 0xFF) + 1) << 20
	if w >> 12 > u32(Restore_Method.Freeze) {
		return {}, PPMd_Error.Invalid_Properties
	}
	props.restore = Restore_Method(w >> 12)
	if !valid_properties(props) {
		return {}, PPMd_Error.Invalid_Properties
	}
	return props, nil
}

encode_properties_zip :: proc "contextless" (props: Properties) -> (data: [PROPERTIES_ZIP_SIZE]u8, err: Error) {
	if props.variant != .I || !valid_properties(props) || props.mem_size & (1 << 20 - 1) != 0 || props.mem_size > ZIP_MEM_SIZE_MAX {
		return {}, PPMd_Error.Invalid_Properties
	}
	w := u32(props.order - 1) | ((props.mem_size >> 20) - 1) << 4 | u32(props.restore) << 12
	data[0] = u8(w)
	data[1] = u8(w >> 8)
	return data, nil
}

@(private)
valid_properties :: proc "contextless" (props: Properties) -> bool {
	order_max := u8(H_ORDER_MAX) if props.variant == .H else u8(I_ORDER_MAX)
	if props.order < ORDER_MIN || props.order > order_max {
		return false
	}
	if props.mem_size < MEM_SIZE_MIN || props.mem_size > MEM_SIZE_MAX {
		return false
	}
	if props.variant == .H {
		return props.restore == .Restart
	}
	if props.restore == .Cut_Off && props.mem_size < CUT_OFF_MEM_SIZE_MIN {
		return false
	}
	return props.restore <= .Freeze
}

@(private)
LEVEL_ORDER_H := [10]u8{3, 4, 4, 5, 5, 6, 8, 16, 24, 32}

@(private)
EXP_ESCAPE := [16]u8{25, 14, 9, 7, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2}

@(private)
INIT_BIN_ESC := [8]u16{0x3CDD, 0x1F3F, 0x59BF, 0x48F3, 0x64A1, 0x5ABC, 0x6632, 0x6051}

@(private) INT_BITS     :: 7
@(private) PERIOD_BITS  :: 7
@(private) BIN_SCALE    :: 1 << (INT_BITS + PERIOD_BITS)
@(private) N1           :: 4
@(private) N2           :: 4
@(private) N3           :: 4
@(private) N4           :: (128 + 3 - 1 * N1 - 2 * N2 - 3 * N3) / 4
@(private) NUM_INDEXES  :: N1 + N2 + N3 + N4
@(private) MAX_FREQ     :: 124
@(private) UNIT_SIZE    :: 12
@(private) SYM_END      :: -1
@(private) SYM_ERROR    :: -2
@(private) TOP_7Z       :: u32(1) << 24
@(private) TOP_I        :: u32(1) << 24
@(private) BOT_I        :: u32(1) << 15
@(private) FLAG_RESCALED  :: 1 << 2
@(private) FLAG_PREV_HIGH :: 1 << 4
@(private) EMPTY_NODE_H :: u16(0)
@(private) EMPTY_NODE_I :: u32(0xFFFF_FFFF)
@(private) RESTORE_FREEZE :: u32(Restore_Method.Freeze)

@(private)
State :: struct {
	symbol:      u8,
	freq:        u8,
	successor_0: u16,
	successor_1: u16,
}
#assert(size_of(State) == 6)

@(private)
See :: struct {
	summ:  u16,
	shift: u8,
	count: u8,
}

@(private)
Context_H :: struct {
	num_stats: u16,
	summ_freq: u16,
	stats:     u32,
	suffix:    u32,
}
#assert(size_of(Context_H) == UNIT_SIZE)

@(private)
Context_I :: struct {
	num_stats: u8,
	flags:     u8,
	summ_freq: u16,
	stats:     u32,
	suffix:    u32,
}
#assert(size_of(Context_I) == UNIT_SIZE)

@(private)
Node_H :: struct {
	stamp: u16,
	nu:    u16,
	next:  u32,
	prev:  u32,
}
#assert(size_of(Node_H) == UNIT_SIZE)

@(private)
Node_I :: struct {
	stamp: u32,
	next:  u32,
	nu:    u32,
}
#assert(size_of(Node_I) == UNIT_SIZE)

@(private)
Sub_Allocator :: struct {
	base:         [^]u8,
	lo_unit:      [^]u8,
	hi_unit:      [^]u8,
	text:         [^]u8,
	units_start:  [^]u8,
	size:         u32,
	align_offset: u32,
	glue_count:   u32,
	indx2units:   [NUM_INDEXES + 2]u8,
	units2indx:   [128]u8,
	free_list:    [NUM_INDEXES]u32,
}

@(private)
Model_H :: struct {
	sub_alloc:    Sub_Allocator,
	min_context:  ^Context_H,
	max_context:  ^Context_H,
	found_state:  ^State,
	order_fall:   u32,
	init_esc:     u32,
	prev_success: u32,
	max_order:    u32,
	hi_bits_flag: u32,
	run_length:   i32,
	init_rl:      i32,
	ns2bs_indx:   [256]u8,
	ns2indx:      [256]u8,
	dummy_see:    See,
	see:          [25][16]See,
	bin_summ:     [128][64]u16,
}

@(private)
Model_I :: struct {
	sub_alloc:      Sub_Allocator,
	min_context:    ^Context_I,
	max_context:    ^Context_I,
	found_state:    ^State,
	order_fall:     u32,
	init_esc:       u32,
	prev_success:   u32,
	max_order:      u32,
	restore_method: u32,
	run_length:     i32,
	init_rl:        i32,
	stamps:         [NUM_INDEXES]u32,
	ns2bs_indx:     [256]u8,
	ns2indx:        [260]u8,
	dummy_see:      See,
	see:            [24][32]See,
	bin_summ:       [25][64]u16,
}

@(private)
Reader :: struct {
	buf:     []u8,
	pos:     int,
	z:       ^compress.Context,
	overrun: bool,
}

@(private)
Writer :: struct {
	buf:   [^]u8,
	pos:   int,
	cap:   int,
	grow:  ^[dynamic]u8,
	limit: int,
	full:  bool,
	err:   Error,
}

@(private)
Decoder_H :: struct {
	range_: u32,
	code:   u32,
}

@(private)
Encoder_H :: struct {
	low:        u64,
	range_:     u32,
	cache:      u8,
	cache_size: u64,
}

@(private)
Coder_I :: struct {
	low:    u32,
	range_: u32,
	code:   u32,
}

@(private)
sub_allocator_init :: proc(sa: ^Sub_Allocator, size: u32, allocator: runtime.Allocator) -> (err: Error) {
	k := 0
	for i in 0..<NUM_INDEXES {
		step := 4 if i >= 12 else (i >> 2) + 1
		for _ in 0..<step {
			sa.units2indx[k] = u8(i)
			k += 1
		}
		sa.indx2units[i] = u8(k)
	}
	if uint(size) > uint(MEMORY_MAX) {
		return PPMd_Error.Memory_Limit_Exceeded
	}
	sa.align_offset = (4 - size) & 3
	data := runtime.mem_alloc_non_zeroed(int(sa.align_offset) + int(size), 16, allocator) or_return
	sa.base = raw_data(data)
	sa.size = size
	return nil
}

@(private)
sub_allocator_destroy :: proc(sa: ^Sub_Allocator, allocator: runtime.Allocator) {
	if sa.base != nil {
		runtime.mem_free_with_size(sa.base, int(sa.align_offset) + int(sa.size), allocator)
		sa.base = nil
	}
}

@(private)
ns2bs_init :: proc "contextless" (ns2bs: ^[256]u8) {
	ns2bs[0] = 0 << 1
	ns2bs[1] = 1 << 1
	for i in 2..<11 {
		ns2bs[i] = 2 << 1
	}
	for i in 11..<256 {
		ns2bs[i] = 3 << 1
	}
}

@(private)
ref_of :: #force_inline proc "contextless" (sa: ^Sub_Allocator, p: rawptr) -> u32 {
	return u32(uintptr(p) - uintptr(sa.base))
}

@(private)
ptr_at :: #force_inline proc "contextless" (sa: ^Sub_Allocator, r: u32) -> rawptr {
	return rawptr(uintptr(sa.base) + uintptr(r))
}

@(private)
forward :: #force_inline proc "contextless" (p: rawptr, n: u32) -> [^]u8 {
	return ([^]u8)(uintptr(p) + uintptr(n))
}

@(private)
backward :: #force_inline proc "contextless" (p: rawptr, n: u32) -> [^]u8 {
	return ([^]u8)(uintptr(p) - uintptr(n))
}

@(private)
distance :: #force_inline proc "contextless" (hi, lo: rawptr) -> u32 {
	return u32(uintptr(hi) - uintptr(lo))
}

@(private)
u2b :: #force_inline proc "contextless" (nu: u32) -> u32 {
	return nu * UNIT_SIZE
}

@(private)
u2i :: #force_inline proc "contextless" (sa: ^Sub_Allocator, nu: u32) -> u32 #no_bounds_check {
	return u32(sa.units2indx[nu - 1])
}

@(private)
i2u :: #force_inline proc "contextless" (sa: ^Sub_Allocator, indx: u32) -> u32 #no_bounds_check {
	return u32(sa.indx2units[indx])
}

@(private)
copy_units :: #force_inline proc "contextless" (dst, src: rawptr, nu: u32) {
	intrinsics.mem_copy_non_overlapping(dst, src, int(nu) * UNIT_SIZE)
}

@(private)
get_successor :: #force_inline proc "contextless" (s: ^State) -> u32 {
	return u32(s.successor_0) | u32(s.successor_1) << 16
}

@(private)
set_successor :: #force_inline proc "contextless" (s: ^State, v: u32) {
	s.successor_0 = u16(v)
	s.successor_1 = u16(v >> 16)
}

@(private)
state_at :: #force_inline proc "contextless" (s: ^State, i: int) -> ^State {
	return (^State)(uintptr(s) + uintptr(i * size_of(State)))
}

@(private)
state_index :: #force_inline proc "contextless" (s, base: ^State) -> int {
	return int(uintptr(s) - uintptr(base)) / size_of(State)
}

@(private)
swap_states :: #force_inline proc "contextless" (a, b: ^State) {
	a^, b^ = b^, a^
}

@(private)
hi_bits_prepare :: #force_inline proc "contextless" (sym: u8) -> u32 {
	return u32(sym) + 0xC0
}

@(private)
hi_bits_flag_3 :: #force_inline proc "contextless" (sym: u8) -> u32 {
	return ((u32(sym) + 0xC0) >> (8 - 3)) & (1 << 3)
}

@(private)
hi_bits_flag_4 :: #force_inline proc "contextless" (sym: u8) -> u32 {
	return ((u32(sym) + 0xC0) >> (8 - 4)) & (1 << 4)
}

@(private)
get_mean :: #force_inline proc "contextless" (summ: u32) -> u32 {
	return (summ + (1 << (PERIOD_BITS - 2))) >> PERIOD_BITS
}

@(private)
see_update :: #force_inline proc "contextless" (s: ^See) {
	if s.shift < PERIOD_BITS {
		s.count -= 1
		if s.count == 0 {
			s.summ <<= 1
			s.count = u8(3 << s.shift)
			s.shift += 1
		}
	}
}

@(private)
see_escape :: #force_inline proc "contextless" (see: ^See) -> (esc_freq: u32) {
	summ := u32(see.summ)
	r    := summ >> see.shift
	see.summ = u16(summ - r)
	return r + u32(r == 0)
}
