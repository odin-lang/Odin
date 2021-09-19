package lz4

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.

	Thanks to Yann Collet for creating the LZ4 compression format.
	This implementation is written in accordance with the 
		(LZ4 block and frame specifications)[https://github.com/lz4/lz4/tree/dev/doc]
*/

import "core:hash/xxhash"

Magic :: enum u32le {
	Frame_Magic_Number          = 0x184D2204,
	Frame_Magic_Skippable_Start = 0x184D2A50,
	Frame_Magic_Skippable_Max   = 0x184D2A5F,
	Frame_Magic_Skippable_Mask  = 0xFFFFFFF0,
	Block_Uncompressed_Flag     = 0x80000000,
}
Block_Size_ID_Default   :: Frame_Block_Size_ID.max_64_kiB

/*
	LZ4_Error :: enum {
		Generic,
		Max_Block_Size_Invalid,
		Block_Mode_Invalid,
		Content_Checksum_Invalid,
		Compression_Level_Invalid,
		Header_Version_Wrong,
		Block_Checksum_Invalid,
		Reserved_Flag_Set,
		Allocation_Failed,
		Source_Size_Too_Large,
		Output_Buffer_Too_Small,
		Frame_Header_Incomplete,
		Frame_Type_Unknown,
		Frame_Type_Wrong,
		Frame_Size_Wrong,
		Source_Input_Wrong,
		Decompression_Failed,
		Header_Checksum_Invalid,
		Frame_Decoding_Already_Started,
	}
*/

/*-************************************
*  Structures and local types
**************************************/

MEMORY_USAGE       :: 14
HASH_TABLE_SIZE    :: 1 << MEMORY_USAGE
STREAM_SIZE        :: (1 << MEMORY_USAGE) + 32 /* static size, for inter-version compatibility */
STREAM_SIZE_RAWPTR :: STREAM_SIZE / size_of(rawptr)
HASH_LOG           :: MEMORY_USAGE - 2
HASH_SIZE_U32      :: 1 << HASH_LOG

HC_DICTIONARY_LOG_SIZE :: 16
HC_MAX_D               :: 1 << HC_DICTIONARY_LOG_SIZE
HC_MAX_D_MASK          :: HC_MAX_D - 1
HC_HASH_LOG            :: 15
HC_HASH_TABLE_SIZE     :: 1 << HC_HASH_LOG
HC_HASH_MASK           :: HC_HASH_TABLE_SIZE - 1

LZ4_stream_t_internal :: struct {
	hash_table:     [HASH_SIZE_U32]u32,
	current_offset: u32,
	table_type: u32,
	dictionary: []u8, // const LZ4_byte* dictionary;
	dictionary_context: ^LZ4_stream_t_internal,
	dictionary_size: u32,
}

LZ4_streamDecode_t_internal :: struct {
	external_dict: []u8,
	external_dict_size: uint,
	prefix_end: []u8,
	prefix_size: uint,
}

/*
	LZ4_stream_t :
 *  Do not use below internal definitions directly !
 *  Declare or allocate an LZ4_stream_t instead.
 *  LZ4_stream_t can also be created using LZ4_createStream(), which is recommended.
 *  The structure definition can be convenient for static allocation
 *  (on stack, or as part of larger structure).
 *  Init this structure with LZ4_initStream() before first use.
 *  note : only use this definition in association with static linking !
 *  this definition is not API/ABI safe, and may change in future versions.
 */
LZ4_Stream :: struct #raw_union {
	table: [STREAM_SIZE_RAWPTR]rawptr,
	internal_donotuse: LZ4_stream_t_internal,
}

/*
	LZ4_streamDecode_t: information structure to track an LZ4 stream during decompression.
  	init this structure  using LZ4_setStreamDecode() before first use.
  	note : only use in association with static linking !
         this definition is not API/ABI safe,
         and may change in a future version !
*/
when size_of(rawptr) == 16 {
	LZ4_STREAM_DECODE_SIZE_U64 :: 4 + 2  // AS-400
} else {
	LZ4_STREAM_DECODE_SIZE_U64 :: 4 + 0
}

LZ4_STREAM_DECODE_SIZE     :: (LZ4_STREAM_DECODE_SIZE_U64 * size_of(u64))

LZ4_stream_decode :: struct #raw_union {
	table: [LZ4_STREAM_DECODE_SIZE_U64]u64,
	internal_donotuse: LZ4_streamDecode_t_internal,
} /* previously typedef'd to LZ4_streamDecode_t */


HC_CCtx_internal :: struct {
    hash_table:               [HC_HASH_TABLE_SIZE]u32,
    chain_table:              [HC_MAX_D]u16,
    end:                      []u8,    /* next block here to continue on current prefix */
    base:                     []u8,    /* All index relative to this position */
    dict_base:                []u8,    /* alternate base for extDict */
    dict_limit:                u32,    /* below that point, need extDict */
    low_limit:                 u32,    /* below that point, no more dict */
    next_to_update:            u32,    /* index from which to continue dictionary update */
    compression_level:         u16,
    favor_decompression_speed: i8,     /* favor decompression speed if this flag set, otherwise, favor compression ratio */
    dirty:                     i8,     /* stream has to be fully reset if this flag is set */
    dict_context:              ^HC_CCtx_internal,
}

/*
	Do not use these definitions directly !
	Declare or allocate an LZ4_streamHC_t instead.
*/
STREAM_HC_SIZE        :: 262200  /* static size, for inter-version compatibility */
STREAM_HC_SIZE_RAWPTR :: STREAM_HC_SIZE / size_of(rawptr)


LZ4_Stream_HC :: struct #raw_union {
    table: [STREAM_HC_SIZE_RAWPTR]rawptr,
    internal_donotuse: HC_CCtx_internal,
} /* previously typedef'd to LZ4_streamHC_t */

LZ4_Compression_Dictionary :: struct {
	dictionary_content: []u8,
	fast_context: ^LZ4_Stream,
	high_compression_context: ^LZ4_Stream_HC,
}

LZ4_Compression_Context :: struct {
	prefs: Preferences,
	version: u32,
	c_stage: u32,
	c_dict:  ^LZ4_Compression_Dictionary,
	max_block_size:  uint,
	max_buffer_size: uint,
	temp_buffer: []u8, /* internal buffer, for streaming */
	temp_in:     []u8, /* starting position of data compress within internal buffer (>= tmpBuff) */
	// size_t tmpInSize;  /* amount of data to compress after tmpIn */
	total_in_size: u64,
	xxh: xxhash.XXH32_state,
	lz4_ctx_ptr: rawptr,
	lz4_context_alloc: u16, /* sized for: 0 = none, 1 = lz4 ctx, 2 = lz4hc ctx */
	lz4_context_state: u16, /* in use as: 0 = none, 1 = lz4 ctx, 2 = lz4hc ctx */
}

Last_Block_Status :: enum {
	not_done,
	from_temp_buffer,
	from_source_buffer,
}

/*-***************************************************
*   Frame Decompression
*****************************************************/

Decompression_Stage :: enum {
	get_frame_header = 0,
	store_frame_header,
	init,
	get_block_header,
	store_block_header,
	copy_direct,
	get_block_checksum,
	get_C_block,
	store_C_block,
	flush_out,
	get_suffix,
	store_suffix,
	get_S_frame_size,
	store_S_frame_size,
	skip_skippable,
}

/*
struct LZ4F_dctx_s {
	LZ4F_frameInfo_t frameInfo;
	U32    version;
	dStage_t dStage;
	U64    frameRemainingSize;
	size_t maxBlockSize;
	size_t maxBufferSize;
	BYTE*  tmpIn;
	size_t tmpInSize;
	size_t tmpInTarget;
	BYTE*  tmpOutBuffer;
	const BYTE* dict;
	size_t dictSize;
	BYTE*  tmpOut;
	size_t tmpOutSize;
	size_t tmpOutStart;
	XXH32_state_t xxh;
	XXH32_state_t blockChecksum;
	BYTE   header[LZ4F_HEADER_SIZE_MAX];
};  /* typedef'd to LZ4F_dctx in lz4frame.h */

typedef int (*compressFunc_t)(void* ctx, const char* src, char* dst, int srcSize, int dstSize, int level, const LZ4F_CDict* cdict);

*/

/*
	The larger the block size, the (slightly) better the compression ratio, though there are diminishing returns.
	Larger blocks also increase memory usage on both compression and decompression sides.
*/
Frame_Block_Size_ID :: enum u32 {
	default                            = 0,
	max_64_kiB                         = 4,
	max_256_kiB                        = 5,
	max_1_MiB                          = 6,
	max_4_MiB                          = 7,
	obsolete_max_64_kiB,
	obsolete_max_256_kiB,
	obsolete_max_1_MiB,
	obsolete_max_4_MiB,
}

/*
	Linked blocks sharply reduce inefficiencies when using small blocks, they compress better.
	However, some LZ4 decoders are only compatible with independent blocks.
*/
Block_Mode :: enum u32 {
	block_linked                       = 0,
	block_independent,
	obsolete_block_linked,
	obsolete_block_independent,
}

Content_Checksum :: enum u32 {
	no_content_checksum                = 0,
	content_checksum_enabled,
	obsolete_no_content_checksum,
	obsolete_content_checksum_enabled,
}

Frame_Type :: enum u32 {
	frame                              = 0,
	skippable_frame,
	obsolete_skippable_frame,
}

Block_Checksum :: enum u32 {
	no_block_checksum                  = 0,
	block_checksum_enabled,
}

/*
	LZ4F_frameInfo_t : makes it possible to set or read frame parameters.
	Structure must be first init to 0, using memset() or LZ4F_INIT_FRAMEINFO, setting all parameters to default.
	It's then possible to update selectively some parameters.
*/
Frame_Info :: struct {
	block_size:          Frame_Block_Size_ID,    /* max64KB, max256KB, max1MB, max4MB; 0 == default */
	block_mode:          Block_Mode,             /* LZ4F_blockLinked, LZ4F_blockIndependent; 0 == default */
	content_checksum:    Content_Checksum,       /* 1: frame terminated with 32-bit checksum of decompressed data; 0: disabled (default) */
	frame_type:          Frame_Type,             /* read-only field : LZ4F_frame or LZ4F_skippableFrame */
	content_size:        u64,                    /* Size of uncompressed content ; 0 == unknown */
	dict_id:             u32,                    /* Dictionary ID, sent by compressor to help decoder select correct dictionary; 0 == no dictID provided */
	block_checksum_flag: Block_Checksum,         /* 1: each block followed by a checksum of block's compressed data; 0: disabled (default) */
}
#assert(size_of(Frame_Info) == 32)

INIT_FRAMEINFO :: Frame_Info{
	.default, .block_linked, .no_content_checksum, .frame, 0, 0, .no_block_checksum,
} /* v1.8.3+ */

/*
	LZ4F_preferences_t: makes it possible to supply advanced compression instructions to streaming interface.
	Structure must be first init to 0, using memset() or LZ4F_INIT_PREFERENCES, setting all parameters to default.
	All reserved fields must be set to zero.
*/
Preferences :: struct {
	frame_info: Frame_Info,
	compression_level:                    i32,   /* 0: default (fast mode); values > LZ4HC_CLEVEL_MAX count as LZ4HC_CLEVEL_MAX; values < 0 trigger "fast acceleration" */
	auto_flush:                           i32,   /* 1: always flush; reduces usage of internal buffers */
	favor_decompression_speed:            i32,   /* 1: parser favors decompression speed vs compression ratio. Only works for high compression modes (>= LZ4HC_CLEVEL_OPT_MIN) */  /* v1.8.2+ */
	reserved:                          [3]u32,   /* must be zero for forward compatibility */
}
#assert(size_of(Preferences) == 56)

INIT_PREFERENCES :: Preferences{
	INIT_FRAMEINFO, 0, 0, 0, { 0, 0, 0 },
}    /* v1.8.3+ */


/*-***********************************
*  Advanced compression options
*************************************/
Compress_Options :: struct {
	stable_source:    b32, /* 1 == src content will remain present on future calls to LZ4F_compress(); skip copying src content within tmp buffer */
	reserved:      [3]u32,
}

/*---   Resource Management   ---*/
Frame_Version :: 100    /* This number can be used to check for an incompatible API breaking change */

/*----    Compression    ----*/

Frame_Header_Size_Min ::  7     /* LZ4 Frame header size can vary, depending on selected paramaters */
Frame_Header_Size_Max :: 19

/* Size in bytes of a block header in little-endian format. Highest bit indicates if block data is uncompressed */
Block_Header_Size     :: 4

/* Size in bytes of a block checksum footer in little-endian format. */
Block_Checksum_Size   :: 4

/* Size in bytes of the content checksum. */
Content_Checksum_Size :: 4

/*-*********************************
*  Decompression options
***********************************/
Uncompress_Options :: struct {
	stable_output:    b32, /* pledges that last 64KB decompressed data will remain available unmodified. This optimization skips storage operations in tmp buffers. */
	reserved:      [3]u32, /* must be set to zero for forward compatibility */
}

/*-***********************************
*  Streaming decompression options
*************************************/
MIN_SIZE_TO_KNOW_HEADER_LENGTH :: 5