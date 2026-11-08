// An implementation of the LZMA and LZMA2 compression methods
//
// Reads and writes `.lzma` files, raw LZMA streams as stored in 7z and zip (method 14),
// and raw LZMA2 streams as used by xz and 7z.
// It is a port of Igor Pavlov's public domain LZMA SDK, and the encoder's output is byte-identical to the SDK's.
package compress_lzma

/*
	Copyright 2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	Ported from the LZMA SDK 26.05 (2026-10-21), written by Igor Pavlov and placed in the public domain:
		https://www.7-zip.org/sdk.html

		C/LzmaDec.c, C/Lzma2Dec.c:    decoder
		C/LzmaEnc.c, C/Lzma2Enc.c:    encoder
		C/LzFind.c, C/LzHash.h:       match finders
		DOC/lzma-specification.txt:   format

	Many thanks to Igor Pavlov for LZMA, and for placing the SDK in the public domain.

	The level presets and the `.lzma` dictionary size rounding follow xz by Lasse Collin:
		https://tukaani.org/xz/
*/

import "core:compress"

Error         :: compress.Error
General_Error :: compress.General_Error
LZMA_Error    :: compress.LZMA_Error

Properties :: struct {
	lc:        u8,
	lp:        u8,
	pb:        u8,
	dict_size: u32,
}

DEFAULT_PROPERTIES :: Properties{lc = 3, lp = 0, pb = 2, dict_size = 8 << 20}

PROPERTIES_SIZE     :: 5
HEADER_SIZE         :: PROPERTIES_SIZE + 8
UNKNOWN_SIZE        :: max(u64)
DICT_SIZE_MIN       :: 1 << 12
LC_MAX              :: 8
LP_MAX              :: 4
PB_MAX              :: 4
LZMA2_LCLP_MAX      :: 4
LZMA2_DICT_PROP_MAX :: 40

Match_Finder_Kind :: enum u8 {
	HC4,
	HC5,
	BT2,
	BT3,
	BT4,
	BT5,
}

Options :: struct {
	lc:           u8,
	lp:           u8,
	pb:           u8,
	dict_size:    u32,
	fast:         bool,
	nice_len:     u32,
	depth:        u32,
	match_finder: Match_Finder_Kind,
	end_marker:   bool,
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
	Default = Level_6,
	Best    = Level_9,
}

@(rodata, private)
LEVEL_DICT_POW2 := [10]u8{18, 20, 21, 22, 22, 23, 23, 24, 25, 26}
@(rodata, private)
LEVEL_NICE_LEN  := [10]u32{128, 128, 273, 273, 16, 32, 64, 64, 64, 64}
@(rodata, private)
LEVEL_DEPTH     := [10]u32{4, 8, 24, 48, 0, 0, 0, 0, 0, 0}

@(rodata, private)
MF_HASH_BYTES := [Match_Finder_Kind]u32{.HC4 = 4, .HC5 = 5, .BT2 = 2, .BT3 = 3, .BT4 = 4, .BT5 = 5}

@(rodata, private)
LITERAL_NEXT_STATES   := [NUM_STATES]u8{0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 4, 5}
@(rodata, private)
MATCH_NEXT_STATES     := [NUM_STATES]u8{7, 7, 7, 7, 7, 7, 7, 10, 10, 10, 10, 10}
@(rodata, private)
REP_NEXT_STATES       := [NUM_STATES]u8{8, 8, 8, 8, 8, 8, 8, 11, 11, 11, 11, 11}
@(rodata, private)
SHORT_REP_NEXT_STATES := [NUM_STATES]u8{9, 9, 9, 9, 9, 9, 9, 11, 11, 11, 11, 11}

@(private)
Match_Finder :: struct {
	buffer:          [^]u8,
	pos:             u32,
	pos_limit:       u32,
	stream_pos:      u32,
	len_limit:       u32,
	cyclic_pos:      u32,
	cyclic_size:     u32,
	kind:            Match_Finder_Kind,
	stream_end:      bool,
	bt_mode:         bool,
	num_hash_bytes:  u32,
	direct_rem:      int,
	match_max_len:   u32,
	hash:            [^]u32,
	son:             [^]u32,
	refs:            []u32,
	hash_mask:       u32,
	cut_value:       u32,
	keep_size_after: u32,
	history_size:    u32,
	fixed_hash_size: u32,
	crc:             [256]u32,
}

@(private)
Optimal :: struct {
	price: u32,
	state: u16,
	extra: u16,
	len:   u32,
	dist:  u32,
	reps:  [NUM_REPS]u32,
}

@(private)
Len_Enc :: struct {
	low:  [NUM_POS_STATES_MAX << (LEN_NUM_LOW_BITS + 1)]u16,
	high: [LEN_NUM_HIGH_SYMBOLS]u16,
}

@(private)
Len_Price_Enc :: struct {
	table_size: u32,
	prices:     [NUM_POS_STATES_MAX][LEN_NUM_SYMBOLS_TOTAL]u32,
}

@(private)
Range_Encoder :: struct {
	range_:     u32,
	cache:      u32,
	low:        u64,
	cache_size: u64,
	start:      int,
	pos:        int,
	buf:        [^]u8,
	cap:        int,
	grow:       ^[dynamic]u8,
	limit:      int,
	grow_err:   Error,
}

@(private)
Encoder_State :: struct {
	state:             u32,
	reps:              [NUM_REPS]u32,
	pos_align_encoder: [ALIGN_TABLE_SIZE]u16,
	is_rep:            [NUM_STATES]u16,
	is_rep_g0:         [NUM_STATES]u16,
	is_rep_g1:         [NUM_STATES]u16,
	is_rep_g2:         [NUM_STATES]u16,
	is_match:          [NUM_STATES][NUM_POS_STATES_MAX]u16,
	is_rep0_long:      [NUM_STATES][NUM_POS_STATES_MAX]u16,
	pos_slot_encoder:  [NUM_LEN_TO_POS_STATES][1 << NUM_POS_SLOT_BITS]u16,
	pos_encoders:      [NUM_FULL_DISTANCES]u16,
	len_probs:         Len_Enc,
	rep_len_probs:     Len_Enc,
}

@(private)
Encoder :: struct {
	using probs:         Encoder_State,
	mf:                  Match_Finder,
	opt_cur:             u32,
	opt_end:             u32,
	longest_match_len:   u32,
	num_pairs:           u32,
	num_avail:           u32,
	num_fast_bytes:      u32,
	additional_offset:   u32,
	lp_mask:             u32,
	pb_mask:             u32,
	lit_probs:           []u16,
	saved_lit_probs:     []u16,
	saved:               Encoder_State,
	rc:                  Range_Encoder,
	back_res:            u32,
	lc:                  u32,
	lp:                  u32,
	pb:                  u32,
	fast_mode:           bool,
	write_end_mark:      bool,
	finished:            bool,
	need_init:           bool,
	now_pos64:           u64,
	match_price_count:   u32,
	rep_len_enc_counter: i32,
	dist_table_size:     u32,
	dict_size:           u32,
	input:               []u8,
	prob_prices:         [BIT_MODEL_TOTAL >> NUM_MOVE_REDUCING_BITS]u32,
	matches:             [MATCH_MAX_LEN * 2 + 2]u32,
	align_prices:        [ALIGN_TABLE_SIZE]u32,
	pos_slot_prices:     [NUM_LEN_TO_POS_STATES][DIST_TABLE_SIZE_MAX]u32,
	distances_prices:    [NUM_LEN_TO_POS_STATES][NUM_FULL_DISTANCES]u32,
	len_enc:             Len_Price_Enc,
	rep_len_enc:         Len_Price_Enc,
	opt:                 [NUM_OPTS]Optimal,
}

@(private)
NUM_BIT_MODEL_TOTAL_BITS :: 11
@(private)
BIT_MODEL_TOTAL          :: u32(1) << NUM_BIT_MODEL_TOTAL_BITS
@(private)
NUM_MOVE_BITS            :: 5
@(private)
TOP_VALUE                :: u32(1) << 24
@(private)
PROB_INIT                :: u16(BIT_MODEL_TOTAL >> 1)
@(private)
RC_INIT_SIZE             :: 5
@(private)
REQUIRED_INPUT_MAX       :: 20

@(private)
NUM_POS_BITS_MAX         :: 4
@(private)
NUM_POS_STATES_MAX       :: 1 << NUM_POS_BITS_MAX
@(private)
LEN_NUM_LOW_BITS         :: 3
@(private)
LEN_NUM_LOW_SYMBOLS      :: 1 << LEN_NUM_LOW_BITS
@(private)
LEN_NUM_HIGH_BITS        :: 8
@(private)
LEN_NUM_HIGH_SYMBOLS     :: 1 << LEN_NUM_HIGH_BITS
@(private)
LEN_LOW                  :: 0
@(private)
LEN_HIGH                 :: LEN_LOW + 2 * (NUM_POS_STATES_MAX << LEN_NUM_LOW_BITS)
@(private)
NUM_LEN_PROBS            :: LEN_HIGH + LEN_NUM_HIGH_SYMBOLS
@(private)
LEN_CHOICE               :: LEN_LOW
@(private)
LEN_CHOICE2              :: LEN_LOW + LEN_NUM_LOW_SYMBOLS

@(private)
NUM_STATES               :: 12
@(private)
NUM_STATES2              :: 16
@(private)
NUM_LIT_STATES           :: 7

@(private)
START_POS_MODEL_INDEX    :: 4
@(private)
END_POS_MODEL_INDEX      :: 14
@(private)
NUM_FULL_DISTANCES       :: 1 << (END_POS_MODEL_INDEX >> 1)
@(private)
NUM_POS_SLOT_BITS        :: 6
@(private)
NUM_LEN_TO_POS_STATES    :: 4
@(private)
NUM_ALIGN_BITS           :: 4
@(private)
ALIGN_TABLE_SIZE         :: 1 << NUM_ALIGN_BITS

@(private)
MATCH_MIN_LEN            :: 2
@(private)
MATCH_MAX_LEN            :: MATCH_MIN_LEN + LEN_NUM_LOW_SYMBOLS * 2 + LEN_NUM_HIGH_SYMBOLS - 1
@(private)
SPEC_LEN_START           :: MATCH_MIN_LEN + LEN_NUM_LOW_SYMBOLS * 2 + LEN_NUM_HIGH_SYMBOLS

@(private)
SPEC_POS                 :: 0
@(private)
IS_REP0_LONG             :: SPEC_POS + NUM_FULL_DISTANCES
@(private)
REP_LEN_CODER            :: IS_REP0_LONG + (NUM_STATES2 << NUM_POS_BITS_MAX)
@(private)
LEN_CODER                :: REP_LEN_CODER + NUM_LEN_PROBS
@(private)
IS_MATCH                 :: LEN_CODER + NUM_LEN_PROBS
@(private)
ALIGN                    :: IS_MATCH + (NUM_STATES2 << NUM_POS_BITS_MAX)
@(private)
IS_REP                   :: ALIGN + ALIGN_TABLE_SIZE
@(private)
IS_REP_G0                :: IS_REP + NUM_STATES
@(private)
IS_REP_G1                :: IS_REP_G0 + NUM_STATES
@(private)
IS_REP_G2                :: IS_REP_G1 + NUM_STATES
@(private)
POS_SLOT                 :: IS_REP_G2 + NUM_STATES
@(private)
LITERAL                  :: POS_SLOT + (NUM_LEN_TO_POS_STATES << NUM_POS_SLOT_BITS)
@(private)
NUM_BASE_PROBS           :: LITERAL
@(private)
LITERAL_CODER_SIZE       :: 0x300
#assert(NUM_BASE_PROBS == 1984)

@(private)
NUM_REPS                 :: 4
@(private)
LEN_NUM_SYMBOLS_TOTAL    :: LEN_NUM_LOW_SYMBOLS * 2 + LEN_NUM_HIGH_SYMBOLS
@(private)
NUM_MOVE_REDUCING_BITS   :: 4
@(private)
NUM_BIT_PRICE_SHIFT_BITS :: 4
@(private)
REP_LEN_COUNT            :: 64
@(private)
NUM_OPTS                 :: 1 << 11
@(private)
PACK_RESERVE             :: NUM_OPTS * 8
@(private)
DIC_LOG_SIZE_MAX         :: 32
@(private)
DIST_TABLE_SIZE_MAX      :: DIC_LOG_SIZE_MAX * 2
@(private)
ALIGN_MASK               :: ALIGN_TABLE_SIZE - 1
@(private)
INFINITY_PRICE           :: u32(1) << 30
@(private)
MARK_LIT                 :: u32(0xFFFF_FFFF)
@(private)
MAX_HISTORY_SIZE         :: u32(15) << 28
@(private)
STATE_LIT_AFTER_MATCH    :: 4
@(private)
STATE_LIT_AFTER_REP      :: 5
@(private)
STATE_MATCH_AFTER_LIT    :: 7
@(private)
STATE_REP_AFTER_LIT      :: 8
@(private)
NICE_LEN_MIN             :: 5
@(private)
COMPRESS_BOUND_SLACK     :: 1024
@(private)
LZMA2_KEEP_WINDOW_SIZE   :: LZMA2_UNPACK_CHUNK_MAX

@(private)
MF_HASH2_SIZE            :: u32(1) << 10
@(private)
MF_HASH3_SIZE            :: u32(1) << 16
@(private)
MF_FIX3_HASH_SIZE        :: MF_HASH2_SIZE
@(private)
MF_FIX4_HASH_SIZE        :: MF_HASH2_SIZE + MF_HASH3_SIZE
@(private)
MF_CRC_SHIFT_1           :: 5
@(private)
MF_CRC_SHIFT_2           :: 10
@(private)
MF_CRC_POLY              :: u32(0xEDB8_8320)
@(private)
MF_EMPTY_HASH            :: u32(0)
@(private)
MF_MAX_VAL_FOR_NORMALIZE :: u32(#config(LZMA_NORMALIZE_AT, 0))

@(private)
BAD_REP_CODE             :: u32(0xC000_0000 - 0x400)

@(private)
LZMA2_CONTROL_COPY_RESET_DICT :: 1
@(private)
LZMA2_CONTROL_COPY            :: 2
@(private)
LZMA2_CONTROL_LZMA            :: 0x80
@(private)
LZMA2_CONTROL_RESET_STATE     :: 0xA0
@(private)
LZMA2_CONTROL_SET_PROPS       :: 0xC0
@(private)
LZMA2_CONTROL_RESET_DICT      :: 0xE0
@(private)
LZMA2_UNPACK_CHUNK_MAX        :: 1 << 21
@(private)
LZMA2_PACK_CHUNK_MAX          :: 1 << 16
@(private)
LZMA2_COPY_CHUNK_MAX          :: 1 << 16

decode_properties :: proc "contextless" (data: []u8) -> (props: Properties, err: Error) {
	if len(data) < PROPERTIES_SIZE {
		return {}, General_Error.Stream_Too_Short
	}
	d := data[0]
	if d >= 9 * 5 * 5 {
		return {}, LZMA_Error.Invalid_Properties
	}
	props.lc        = d % 9
	d              /= 9
	props.pb        = d / 5
	props.lp        = d % 5
	props.dict_size = u32(data[1]) | u32(data[2]) << 8 | u32(data[3]) << 16 | u32(data[4]) << 24
	return
}

encode_properties :: proc "contextless" (props: Properties) -> (data: [PROPERTIES_SIZE]u8) {
	data[0] = (props.pb * 5 + props.lp) * 9 + props.lc
	data[1] = u8(props.dict_size)
	data[2] = u8(props.dict_size >> 8)
	data[3] = u8(props.dict_size >> 16)
	data[4] = u8(props.dict_size >> 24)
	return
}

lzma2_dict_size :: proc "contextless" (prop: u8) -> (dict_size: u32, err: Error) {
	if prop > LZMA2_DICT_PROP_MAX {
		return 0, LZMA_Error.Invalid_Properties
	}
	if prop == LZMA2_DICT_PROP_MAX {
		return max(u32), nil
	}
	return (2 | u32(prop & 1)) << (prop / 2 + 11), nil
}

lzma2_dict_prop :: proc "contextless" (dict_size: u32) -> (prop: u8) {
	for prop = 0; prop < LZMA2_DICT_PROP_MAX; prop += 1 {
		if size, _ := lzma2_dict_size(prop); size >= dict_size {
			return
		}
	}
	return
}

@(private)
num_probs :: #force_inline proc "contextless" (lc, lp: u8) -> int {
	return NUM_BASE_PROBS + LITERAL_CODER_SIZE << uint(lc + lp)
}

@(private)
valid_properties :: proc "contextless" (props: Properties) -> bool {
	return props.lc <= LC_MAX && props.lp <= LP_MAX && props.pb <= PB_MAX
}
