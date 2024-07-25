package vendor_compress_lz4

when ODIN_OS == .Windows {
	@(extra_linker_flags="/NODEFAULTLIB:libcmt")
	foreign import lib "lib/liblz4_static.lib"
}

import "core:c"

VERSION_MAJOR   ::  1    /* for breaking interface changes  */
VERSION_MINOR   :: 10    /* for new (non-breaking) interface capabilities */
VERSION_RELEASE ::  0    /* for tweaks, bug-fixes, or development */

VERSION_NUMBER  :: VERSION_MAJOR *100*100 + VERSION_MINOR *100 + VERSION_RELEASE

MEMORY_USAGE_MIN     :: 10
MEMORY_USAGE_DEFAULT :: 14
MEMORY_USAGE_MAX     :: 20

MEMORY_USAGE :: MEMORY_USAGE_DEFAULT

MAX_INPUT_SIZE :: 0x7E000000   /* 2_113_929_216 bytes */


COMPRESSBOUND :: #force_inline proc "c" (isize: c.int) -> c.int {
	return u32(isize) > MAX_INPUT_SIZE ? 0 : isize + (isize/255) + 16
}


DECODER_RING_BUFFER_SIZE :: #force_inline proc "c" (maxBlockSize: c.int) -> c.int {
	return 65536 + 14 + maxBlockSize  /* for static allocation; maxBlockSize presumed valid */
}

@(default_calling_convention="c", link_prefix="LZ4_")
foreign lib {
	versionNumber :: proc() -> c.int ---   /**< library version number; useful to check dll version; requires v1.3.0+ */
	versionString :: proc() -> cstring --- /**< library version string; useful to check dll version; requires v1.7.5+ */

	/*! LZ4_compress_default() :
	 *  Compresses 'srcSize' bytes from buffer 'src'
	 *  into already allocated 'dst' buffer of size 'dstCapacity'.
	 *  Compression is guaranteed to succeed if 'dstCapacity' >= LZ4_compressBound(srcSize).
	 *  It also runs faster, so it's a recommended setting.
	 *  If the function cannot compress 'src' into a more limited 'dst' budget,
	 *  compression stops *immediately*, and the function result is zero.
	 *  In which case, 'dst' content is undefined (invalid).
	 *      srcSize : max supported value is LZ4_MAX_INPUT_SIZE.
	 *      dstCapacity : size of buffer 'dst' (which must be already allocated)
	 *     @return  : the number of bytes written into buffer 'dst' (necessarily <= dstCapacity)
	 *                or 0 if compression fails
	 * Note : This function is protected against buffer overflow scenarios (never writes outside 'dst' buffer, nor read outside 'source' buffer).
	 */
	compress_default :: proc(src, dst: [^]byte, srcSize, dstCapacity: c.int) -> c.int ---

	/*! LZ4_decompress_safe() :
	 * @compressedSize : is the exact complete size of the compressed block.
	 * @dstCapacity : is the size of destination buffer (which must be already allocated),
	 *                presumed an upper bound of decompressed size.
	 * @return : the number of bytes decompressed into destination buffer (necessarily <= dstCapacity)
	 *           If destination buffer is not large enough, decoding will stop and output an error code (negative value).
	 *           If the source stream is detected malformed, the function will stop decoding and return a negative result.
	 * Note 1 : This function is protected against malicious data packets :
	 *          it will never writes outside 'dst' buffer, nor read outside 'source' buffer,
	 *          even if the compressed block is maliciously modified to order the decoder to do these actions.
	 *          In such case, the decoder stops immediately, and considers the compressed block malformed.
	 * Note 2 : compressedSize and dstCapacity must be provided to the function, the compressed block does not contain them.
	 *          The implementation is free to send / store / derive this information in whichever way is most beneficial.
	 *          If there is a need for a different format which bundles together both compressed data and its metadata, consider looking at lz4frame.h instead.
	 */
	decompress_safe :: proc(src, dst: [^]byte, compressedSize, dstCapacity: c.int) -> c.int ---


	/*! LZ4_compressBound() :
	    Provides the maximum size that LZ4 compression may output in a "worst case" scenario (input data not compressible)
	    This function is primarily useful for memory allocation purposes (destination buffer size).
	    Macro LZ4_COMPRESSBOUND() is also provided for compilation-time evaluation (stack memory allocation for example).
	    Note that LZ4_compress_default() compresses faster when dstCapacity is >= LZ4_compressBound(srcSize)
	        inputSize  : max supported value is LZ4_MAX_INPUT_SIZE
	        return : maximum output size in a "worst case" scenario
	              or 0, if input size is incorrect (too large or negative)
	*/
	compressBound :: proc(inputSize: c.int) -> c.int ---

	/*! LZ4_compress_fast() :
	    Same as LZ4_compress_default(), but allows selection of "acceleration" factor.
	    The larger the acceleration value, the faster the algorithm, but also the lesser the compression.
	    It's a trade-off. It can be fine tuned, with each successive value providing roughly +~3% to speed.
	    An acceleration value of "1" is the same as regular LZ4_compress_default()
	    Values <= 0 will be replaced by LZ4_ACCELERATION_DEFAULT (currently == 1, see lz4.c).
	    Values > LZ4_ACCELERATION_MAX will be replaced by LZ4_ACCELERATION_MAX (currently == 65537, see lz4.c).
	*/
	compress_fast :: proc(src, dst: [^]byte, srcSize, dstCapacity: c.int, acceleration: c.int) -> c.int ---


	/*! LZ4_compress_fast_extState() :
	 *  Same as LZ4_compress_fast(), using an externally allocated memory space for its state.
	 *  Use LZ4_sizeofState() to know how much memory must be allocated,
	 *  and allocate it on 8-bytes boundaries (using `malloc()` typically).
	 *  Then, provide this buffer as `void* state` to compression function.
	 */
	sizeofState :: proc() -> c.int ---
	compress_fast_extState :: proc (state: rawptr, src, dst: [^]byte, srcSize, dstCapacity: c.int, acceleration: c.int) -> c.int ---


	/*! LZ4_compress_destSize() :
	 *  Reverse the logic : compresses as much data as possible from 'src' buffer
	 *  into already allocated buffer 'dst', of size >= 'dstCapacity'.
	 *  This function either compresses the entire 'src' content into 'dst' if it's large enough,
	 *  or fill 'dst' buffer completely with as much data as possible from 'src'.
	 *  note: acceleration parameter is fixed to "default".
	 *
	 * *srcSizePtr : in+out parameter. Initially contains size of input.
	 *               Will be modified to indicate how many bytes where read from 'src' to fill 'dst'.
	 *               New value is necessarily <= input value.
	 * @return : Nb bytes written into 'dst' (necessarily <= dstCapacity)
	 *           or 0 if compression fails.
	 *
	 * Note : from v1.8.2 to v1.9.1, this function had a bug (fixed in v1.9.2+):
	 *        the produced compressed content could, in specific circumstances,
	 *        require to be decompressed into a destination buffer larger
	 *        by at least 1 byte than the content to decompress.
	 *        If an application uses `LZ4_compress_destSize()`,
	 *        it's highly recommended to update liblz4 to v1.9.2 or better.
	 *        If this can't be done or ensured,
	 *        the receiving decompression function should provide
	 *        a dstCapacity which is > decompressedSize, by at least 1 byte.
	 *        See https://github.com/lz4/lz4/issues/859 for details
	 */
	compress_destSize :: proc(src, dst: [^]byte, srcSizePtr: ^c.int, targetDstSize: c.int) -> c.int ---


	/*! LZ4_decompress_safe_partial() :
	 *  Decompress an LZ4 compressed block, of size 'srcSize' at position 'src',
	 *  into destination buffer 'dst' of size 'dstCapacity'.
	 *  Up to 'targetOutputSize' bytes will be decoded.
	 *  The function stops decoding on reaching this objective.
	 *  This can be useful to boost performance
	 *  whenever only the beginning of a block is required.
	 *
	 * @return : the number of bytes decoded in `dst` (necessarily <= targetOutputSize)
	 *           If source stream is detected malformed, function returns a negative result.
	 *
	 *  Note 1 : @return can be < targetOutputSize, if compressed block contains less data.
	 *
	 *  Note 2 : targetOutputSize must be <= dstCapacity
	 *
	 *  Note 3 : this function effectively stops decoding on reaching targetOutputSize,
	 *           so dstCapacity is kind of redundant.
	 *           This is because in older versions of this function,
	 *           decoding operation would still write complete sequences.
	 *           Therefore, there was no guarantee that it would stop writing at exactly targetOutputSize,
	 *           it could write more bytes, though only up to dstCapacity.
	 *           Some "margin" used to be required for this operation to work properly.
	 *           Thankfully, this is no longer necessary.
	 *           The function nonetheless keeps the same signature, in an effort to preserve API compatibility.
	 *
	 *  Note 4 : If srcSize is the exact size of the block,
	 *           then targetOutputSize can be any value,
	 *           including larger than the block's decompressed size.
	 *           The function will, at most, generate block's decompressed size.
	 *
	 *  Note 5 : If srcSize is _larger_ than block's compressed size,
	 *           then targetOutputSize **MUST** be <= block's decompressed size.
	 *           Otherwise, *silent corruption will occur*.
	 */
	decompress_safe_partial :: proc (src, dst: [^]byte, srcSize, targetOutputSize, dstCapacity: c.int) -> c.int ---


	createStream :: proc() -> ^stream_t ---
	freeStream   :: proc(streamPtr: ^stream_t) -> c.int ---

	/*! LZ4_resetStream_fast() : v1.9.0+
	 *  Use this to prepare an LZ4_stream_t for a new chain of dependent blocks
	 *  (e.g., LZ4_compress_fast_continue()).
	 *
	 *  An LZ4_stream_t must be initialized once before usage.
	 *  This is automatically done when created by LZ4_createStream().
	 *  However, should the LZ4_stream_t be simply declared on stack (for example),
	 *  it's necessary to initialize it first, using LZ4_initStream().
	 *
	 *  After init, start any new stream with LZ4_resetStream_fast().
	 *  A same LZ4_stream_t can be re-used multiple times consecutively
	 *  and compress multiple streams,
	 *  provided that it starts each new stream with LZ4_resetStream_fast().
	 *
	 *  LZ4_resetStream_fast() is much faster than LZ4_initStream(),
	 *  but is not compatible with memory regions containing garbage data.
	 *
	 *  Note: it's only useful to call LZ4_resetStream_fast()
	 *        in the context of streaming compression.
	 *        The *extState* functions perform their own resets.
	 *        Invoking LZ4_resetStream_fast() before is redundant, and even counterproductive.
	 */
	resetStream_fast :: proc(streamPtr: ^stream_t) ---


	/*! LZ4_loadDict() :
	 *  Use this function to reference a static dictionary into LZ4_stream_t.
	 *  The dictionary must remain available during compression.
	 *  LZ4_loadDict() triggers a reset, so any previous data will be forgotten.
	 *  The same dictionary will have to be loaded on decompression side for successful decoding.
	 *  Dictionary are useful for better compression of small data (KB range).
	 *  While LZ4 itself accepts any input as dictionary, dictionary efficiency is also a topic.
	 *  When in doubt, employ the Zstandard's Dictionary Builder.
	 *  Loading a size of 0 is allowed, and is the same as reset.
	 * @return : loaded dictionary size, in bytes (note: only the last 64 KB are loaded)
	 */
	loadDict :: proc(streamPtr: ^stream_t, dictionary: [^]byte, dictSize: c.int) -> c.int ---

	/*! LZ4_loadDictSlow() : v1.10.0+
	 *  Same as LZ4_loadDict(),
	 *  but uses a bit more cpu to reference the dictionary content more thoroughly.
	 *  This is expected to slightly improve compression ratio.
	 *  The extra-cpu cost is likely worth it if the dictionary is re-used across multiple sessions.
	 * @return : loaded dictionary size, in bytes (note: only the last 64 KB are loaded)
	 */
	loadDictSlow :: proc(streamPtr: ^stream_t, dictionary: [^]byte, dictSize: c.int) -> c.int ---

	/*! LZ4_attach_dictionary() : stable since v1.10.0
	 *
	 *  This allows efficient re-use of a static dictionary multiple times.
	 *
	 *  Rather than re-loading the dictionary buffer into a working context before
	 *  each compression, or copying a pre-loaded dictionary's LZ4_stream_t into a
	 *  working LZ4_stream_t, this function introduces a no-copy setup mechanism,
	 *  in which the working stream references @dictionaryStream in-place.
	 *
	 *  Several assumptions are made about the state of @dictionaryStream.
	 *  Currently, only states which have been prepared by LZ4_loadDict() or
	 *  LZ4_loadDictSlow() should be expected to work.
	 *
	 *  Alternatively, the provided @dictionaryStream may be NULL,
	 *  in which case any existing dictionary stream is unset.
	 *
	 *  If a dictionary is provided, it replaces any pre-existing stream history.
	 *  The dictionary contents are the only history that can be referenced and
	 *  logically immediately precede the data compressed in the first subsequent
	 *  compression call.
	 *
	 *  The dictionary will only remain attached to the working stream through the
	 *  first compression call, at the end of which it is cleared.
	 * @dictionaryStream stream (and source buffer) must remain in-place / accessible / unchanged
	 *  through the completion of the compression session.
	 *
	 *  Note: there is no equivalent LZ4_attach_*() method on the decompression side
	 *  because there is no initialization cost, hence no need to share the cost across multiple sessions.
	 *  To decompress LZ4 blocks using dictionary, attached or not,
	 *  just employ the regular LZ4_setStreamDecode() for streaming,
	 *  or the stateless LZ4_decompress_safe_usingDict() for one-shot decompression.
	 */
	attach_dictionary :: proc(workingStream, dictionaryStream: ^stream_t) ---

	/*! LZ4_compress_fast_continue() :
	 *  Compress 'src' content using data from previously compressed blocks, for better compression ratio.
	 * 'dst' buffer must be already allocated.
	 *  If dstCapacity >= LZ4_compressBound(srcSize), compression is guaranteed to succeed, and runs faster.
	 *
	 * @return : size of compressed block
	 *           or 0 if there is an error (typically, cannot fit into 'dst').
	 *
	 *  Note 1 : Each invocation to LZ4_compress_fast_continue() generates a new block.
	 *           Each block has precise boundaries.
	 *           Each block must be decompressed separately, calling LZ4_decompress_*() with relevant metadata.
	 *           It's not possible to append blocks together and expect a single invocation of LZ4_decompress_*() to decompress them together.
	 *
	 *  Note 2 : The previous 64KB of source data is __assumed__ to remain present, unmodified, at same address in memory !
	 *
	 *  Note 3 : When input is structured as a double-buffer, each buffer can have any size, including < 64 KB.
	 *           Make sure that buffers are separated, by at least one byte.
	 *           This construction ensures that each block only depends on previous block.
	 *
	 *  Note 4 : If input buffer is a ring-buffer, it can have any size, including < 64 KB.
	 *
	 *  Note 5 : After an error, the stream status is undefined (invalid), it can only be reset or freed.
	 */
	compress_fast_continue :: proc(streamPtr: ^stream_t, src, dst: [^]byte, srcSize, dstCapacity: c.int, acceleration: c.int) -> c.int ---

	/*! LZ4_saveDict() :
	 *  If last 64KB data cannot be guaranteed to remain available at its current memory location,
	 *  save it into a safer place (char* safeBuffer).
	 *  This is schematically equivalent to a memcpy() followed by LZ4_loadDict(),
	 *  but is much faster, because LZ4_saveDict() doesn't need to rebuild tables.
	 * @return : saved dictionary size in bytes (necessarily <= maxDictSize), or 0 if error.
	 */
	saveDict :: proc(streamPtr: ^stream_t, safeBuffer: [^]byte, maxDictSize: c.int) -> c.int ---


	createStreamDecode :: proc() -> ^streamDecode_t ---
	freeStreamDecode   :: proc(LZ4_stream: ^streamDecode_t) -> c.int ---

	/*! LZ4_setStreamDecode() :
	 *  An LZ4_streamDecode_t context can be allocated once and re-used multiple times.
	 *  Use this function to start decompression of a new stream of blocks.
	 *  A dictionary can optionally be set. Use NULL or size 0 for a reset order.
	 *  Dictionary is presumed stable : it must remain accessible and unmodified during next decompression.
	 * @return : 1 if OK, 0 if error
	 */
	setStreamDecode :: proc(LZ4_streamDecode: ^streamDecode_t, dictionary: [^]byte, dictSize: c.int) -> c.int ---

	/*! LZ4_decoderRingBufferSize() : v1.8.2+
	 *  Note : in a ring buffer scenario (optional),
	 *  blocks are presumed decompressed next to each other
	 *  up to the moment there is not enough remaining space for next block (remainingSize < maxBlockSize),
	 *  at which stage it resumes from beginning of ring buffer.
	 *  When setting such a ring buffer for streaming decompression,
	 *  provides the minimum size of this ring buffer
	 *  to be compatible with any source respecting maxBlockSize condition.
	 * @return : minimum ring buffer size,
	 *           or 0 if there is an error (invalid maxBlockSize).
	 */
	decoderRingBufferSize :: proc(maxBlockSize: c.int) -> c.int ---

	/*! LZ4_decompress_safe_continue() :
	 *  This decoding function allows decompression of consecutive blocks in "streaming" mode.
	 *  The difference with the usual independent blocks is that
	 *  new blocks are allowed to find references into former blocks.
	 *  A block is an unsplittable entity, and must be presented entirely to the decompression function.
	 *  LZ4_decompress_safe_continue() only accepts one block at a time.
	 *  It's modeled after `LZ4_decompress_safe()` and behaves similarly.
	 *
	 * @LZ4_streamDecode : decompression state, tracking the position in memory of past data
	 * @compressedSize : exact complete size of one compressed block.
	 * @dstCapacity : size of destination buffer (which must be already allocated),
	 *                must be an upper bound of decompressed size.
	 * @return : number of bytes decompressed into destination buffer (necessarily <= dstCapacity)
	 *           If destination buffer is not large enough, decoding will stop and output an error code (negative value).
	 *           If the source stream is detected malformed, the function will stop decoding and return a negative result.
	 *
	 *  The last 64KB of previously decoded data *must* remain available and unmodified
	 *  at the memory position where they were previously decoded.
	 *  If less than 64KB of data has been decoded, all the data must be present.
	 *
	 *  Special : if decompression side sets a ring buffer, it must respect one of the following conditions :
	 *  - Decompression buffer size is _at least_ LZ4_decoderRingBufferSize(maxBlockSize).
	 *    maxBlockSize is the maximum size of any single block. It can have any value > 16 bytes.
	 *    In which case, encoding and decoding buffers do not need to be synchronized.
	 *    Actually, data can be produced by any source compliant with LZ4 format specification, and respecting maxBlockSize.
	 *  - Synchronized mode :
	 *    Decompression buffer size is _exactly_ the same as compression buffer size,
	 *    and follows exactly same update rule (block boundaries at same positions),
	 *    and decoding function is provided with exact decompressed size of each block (exception for last block of the stream),
	 *    _then_ decoding & encoding ring buffer can have any size, including small ones ( < 64 KB).
	 *  - Decompression buffer is larger than encoding buffer, by a minimum of maxBlockSize more bytes.
	 *    In which case, encoding and decoding buffers do not need to be synchronized,
	 *    and encoding ring buffer can have any size, including small ones ( < 64 KB).
	 *
	 *  Whenever these conditions are not possible,
	 *  save the last 64KB of decoded data into a safe buffer where it can't be modified during decompression,
	 *  then indicate where this data is saved using LZ4_setStreamDecode(), before decompressing next block.
	*/
	decompress_safe_continue :: proc(LZ4_streamDecode: ^streamDecode_t, src, dst: [^]byte, srcSize, dstCapacity: c.int) -> c.int ---


	/*! LZ4_decompress_safe_usingDict() :
	 *  Works the same as
	 *  a combination of LZ4_setStreamDecode() followed by LZ4_decompress_safe_continue()
	 *  However, it's stateless: it doesn't need any LZ4_streamDecode_t state.
	 *  Dictionary is presumed stable : it must remain accessible and unmodified during decompression.
	 *  Performance tip : Decompression speed can be substantially increased
	 *                    when dst == dictStart + dictSize.
	 */
	decompress_safe_usingDict :: proc(src, dst: [^]byte, srcSize, dstCapacity: c.int, dictStart: [^]byte, dictSize: c.int) -> c.int ---

	/*! LZ4_decompress_safe_partial_usingDict() :
	 *  Behaves the same as LZ4_decompress_safe_partial()
	 *  with the added ability to specify a memory segment for past data.
	 *  Performance tip : Decompression speed can be substantially increased
	 *                    when dst == dictStart + dictSize.
	 */
	decompress_safe_partial_usingDict :: proc(src, dst: [^]byte, compressedSize, targetOutputSize, maxOutputSize: c.int, dictStart: [^]byte, dictSize: c.int) -> c.int ---

}


STREAM_MINSIZE :: (1 << MEMORY_USAGE) + 32  /* static size, for inter-version compatibility */

stream_t :: struct #raw_union {
	minStateSize:      [STREAM_MINSIZE]byte,
	internal_donotuse: stream_t_internal,
}


HASHLOG       :: MEMORY_USAGE-2
HASHTABLESIZE :: 1 << MEMORY_USAGE
HASH_SIZE_U32 :: 1 << HASHLOG      /* required as macro for static allocation */

stream_t_internal :: struct {
	hashTable:     [HASH_SIZE_U32]u32,
	dictionary:    [^]byte,
	dictCtx:       ^stream_t_internal,
	currentOffset: u32,
	tableType:     u32,
	dictSize:      u32,
	/* Implicit padding to ensure structure is aligned */
}


STREAMDECODE_MINSIZE :: 32
streamDecode_t :: struct #raw_union {
	minStateSize:      [STREAMDECODE_MINSIZE]byte,
	internal_donotuse: streamDecode_t_internal,
}

streamDecode_t_internal :: struct {
	externalDict: [^]byte,
	prefixEnd:    [^]byte,
	extDictSize:  c.size_t,
	prefixSize:   c.size_t,
}



///////////////////
// lz4hc

CLEVEL_MIN     ::  2
CLEVEL_DEFAULT ::  9
CLEVEL_OPT_MIN :: 10
CLEVEL_MAX     :: 12


@(default_calling_convention="c", link_prefix="LZ4_")
foreign lib {
	/*! LZ4_compress_HC() :
	 *  Compress data from `src` into `dst`, using the powerful but slower "HC" algorithm.
	 * `dst` must be already allocated.
	 *  Compression is guaranteed to succeed if `dstCapacity >= LZ4_compressBound(srcSize)` (see "lz4.h")
	 *  Max supported `srcSize` value is LZ4_MAX_INPUT_SIZE (see "lz4.h")
	 * `compressionLevel` : any value between 1 and LZ4HC_CLEVEL_MAX will work.
	 *                      Values > LZ4HC_CLEVEL_MAX behave the same as LZ4HC_CLEVEL_MAX.
	 * @return : the number of bytes written into 'dst'
	 *           or 0 if compression fails.
	 */
	compress_HC :: proc(src, dst: [^]byte, srcSize, dstCapacity, compressionLevel: c.int) -> c.int ---


	/*! LZ4_compress_HC_extStateHC() :
	 *  Same as LZ4_compress_HC(), but using an externally allocated memory segment for `state`.
	 * `state` size is provided by LZ4_sizeofStateHC().
	 *  Memory segment must be aligned on 8-bytes boundaries (which a normal malloc() should do properly).
	 */
	sizeofStateHC :: proc() -> c.int ---
	compress_HC_extStateHC :: proc(stateHC: rawptr, src, dst: [^]byte, srcSize, maxDstSize: c.int, compressionLevel: c.int) -> c.int ---


	/*! LZ4_compress_HC_destSize() : v1.9.0+
	 *  Will compress as much data as possible from `src`
	 *  to fit into `targetDstSize` budget.
	 *  Result is provided in 2 parts :
	 * @return : the number of bytes written into 'dst' (necessarily <= targetDstSize)
	 *           or 0 if compression fails.
	 * `srcSizePtr` : on success, *srcSizePtr is updated to indicate how much bytes were read from `src`
	 */
	compress_HC_destSize :: proc(stateHC: rawptr, src, dst: [^]byte, srcSizePtr: ^c.int, targetDstSize: c.int, compressionLevel: c.int) -> c.int ---

	/*! LZ4_createStreamHC() and LZ4_freeStreamHC() :
	 *  These functions create and release memory for LZ4 HC streaming state.
	 *  Newly created states are automatically initialized.
	 *  A same state can be used multiple times consecutively,
	 *  starting with LZ4_resetStreamHC_fast() to start a new stream of blocks.
	 */
	createStreamHC :: proc() -> ^streamHC_t ---
	freeStreamHC :: proc(streamHCPtr: ^streamHC_t) -> c.int ---

	resetStreamHC_fast :: proc(streamHCPtr: ^streamHC_t, compressionLevel: c.int) ---   /* v1.9.0+ */
	loadDictHC         :: proc(streamHCPtr: ^streamHC_t, dictionary: [^]byte, dictSize: c.int) -> c.int ---

	compress_HC_continue :: proc(streamHCPtr: ^streamHC_t, src, dst: [^]byte, srcSize, maxDstSize: c.int) -> c.int ---

	/*! LZ4_compress_HC_continue_destSize() : v1.9.0+
	 *  Similar to LZ4_compress_HC_continue(),
	 *  but will read as much data as possible from `src`
	 *  to fit into `targetDstSize` budget.
	 *  Result is provided into 2 parts :
	 * @return : the number of bytes written into 'dst' (necessarily <= targetDstSize)
	 *           or 0 if compression fails.
	 * `srcSizePtr` : on success, *srcSizePtr will be updated to indicate how much bytes were read from `src`.
	 *           Note that this function may not consume the entire input.
	 */
	compress_HC_continue_destSize:: proc(LZ4_streamHCPtr: ^streamHC_t, src, dst: [^]byte, srcSizePtr: ^c.int, targetDstSize: c.int) -> c.int ---

	saveDictHC :: proc(streamHCPtr: ^streamHC_t, safeBuffer: [^]byte, maxDictSize: c.int) -> c.int ---

	/*! LZ4_attach_HC_dictionary() : stable since v1.10.0
	 *  This API allows for the efficient re-use of a static dictionary many times.
	 *
	 *  Rather than re-loading the dictionary buffer into a working context before
	 *  each compression, or copying a pre-loaded dictionary's LZ4_streamHC_t into a
	 *  working LZ4_streamHC_t, this function introduces a no-copy setup mechanism,
	 *  in which the working stream references the dictionary stream in-place.
	 *
	 *  Several assumptions are made about the state of the dictionary stream.
	 *  Currently, only streams which have been prepared by LZ4_loadDictHC() should
	 *  be expected to work.
	 *
	 *  Alternatively, the provided dictionary stream pointer may be NULL, in which
	 *  case any existing dictionary stream is unset.
	 *
	 *  A dictionary should only be attached to a stream without any history (i.e.,
	 *  a stream that has just been reset).
	 *
	 *  The dictionary will remain attached to the working stream only for the
	 *  current stream session. Calls to LZ4_resetStreamHC(_fast) will remove the
	 *  dictionary context association from the working stream. The dictionary
	 *  stream (and source buffer) must remain in-place / accessible / unchanged
	 *  through the lifetime of the stream session.
	 */
	attach_HC_dictionary :: proc(working_stream, dictionary_stream: ^streamHC_t) ---
}


HC_DICTIONARY_LOGSIZE :: 16
HC_MAXD               :: 1<<HC_DICTIONARY_LOGSIZE
HC_MAXD_MASK          :: HC_MAXD - 1

HC_HASH_LOG           :: 15
HC_HASHTABLESIZE      :: 1 << HC_HASH_LOG
HC_HASH_MASK          :: HC_HASHTABLESIZE - 1


streamHC_internal_t :: struct {
	hashTable:        [HC_HASHTABLESIZE]u32,
	chainTable:       [HC_MAXD]u16,
	end:              [^]byte,  /* next block here to continue on current prefix */
	prefixStart:      [^]byte,  /* Indexes relative to this position */
	dictStart:        [^]byte,  /* alternate reference for extDict */
	dictLimit:        u32,      /* below that point, need extDict */
	lowLimit:         u32,      /* below that point, no more history */
	nextToUpdate:     u32,      /* index from which to continue dictionary update */
	compressionLevel: c.short,
	favorDecSpeed:    i8,       /* favor decompression speed if this flag set,
	                               otherwise, favor compression ratio */
	dirty:            i8,       /* stream has to be fully reset if this flag is set */
	dictCtx:          ^streamHC_internal_t,
}

STREAMHC_MINSIZE :: 262200

streamHC_t :: struct #raw_union {
	minStateSize:      [STREAMHC_MINSIZE]byte,
	internal_donotuse: streamHC_internal_t,
}