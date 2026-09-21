//  Bindings for [[LZ4 ; https://github.com/lz4/lz4]].
package vendor_compress_lz4

when ODIN_OS == .Windows {
	@(extra_linker_flags="/NODEFAULTLIB:libcmt")
	foreign import lib { "lib/liblz4_static.lib", "system:ucrt.lib" }
} else {
	foreign import lib "system:lz4"
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


///////////////////
// lz4frame

F_errorCode_t :: c.size_t

@(default_calling_convention="c", link_prefix="LZ4")
foreign lib {
	/* tells when a function result is an error code */
	F_isError :: proc(code: F_errorCode_t) -> b32 ---
	/* return error code string; for debugging */
	F_getErrorName :: proc(code: F_errorCode_t) -> cstring ---

	/*! LZ4F_compressFrame() :
	 *  Compress srcBuffer content into an LZ4-compressed frame.
	 *  It's a one shot operation, all input content is consumed, and all output is generated.
	 *
	 *  Note : it's a stateless operation (no LZ4F_cctx state needed).
	 *  In order to reduce load on the allocator, LZ4F_compressFrame(), by default,
	 *  uses the stack to allocate space for the compression state and some table.
	 *  If this usage of the stack is too much for your application,
	 *  consider compiling `lz4frame.c` with compile-time macro LZ4F_HEAPMODE set to 1 instead.
	 *  All state allocations will use the Heap.
	 *  It also means each invocation of LZ4F_compressFrame() will trigger several internal alloc/free invocations.
	 *
	 * @dstCapacity MUST be >= LZ4F_compressFrameBound(srcSize, preferencesPtr).
	 * @preferencesPtr is optional : one can provide NULL, in which case all preferences are set to default.
	 * @return : number of bytes written into dstBuffer.
	 *           or an error code if it fails (can be tested using LZ4F_isError())
	 */
	F_compressFrame :: proc(dstBuffer: rawptr, dstCapacity: c.size_t, srcBuffer: rawptr, srcSize: c.size_t, preferencesPtr: Maybe(^F_preferences_t)) -> c.size_t ---

	/*! LZ4F_compressFrameBound() :
	 *  Returns the maximum possible compressed size with LZ4F_compressFrame() given srcSize and preferences.
	 * `preferencesPtr` is optional. It can be replaced by NULL, in which case, the function will assume default preferences.
	 *  Note : this result is only usable with LZ4F_compressFrame().
	 *         It may also be relevant to LZ4F_compressUpdate() _only if_ no flush() operation is ever performed.
	 */
	F_compressFrameBound :: proc(srcSize: c.size_t, preferencesPtr: Maybe(^F_preferences_t)) -> c.size_t ---

	/*! LZ4F_compressionLevel_max() :
	 * @return maximum allowed compression level (currently: 12)
	 */
	F_compressionLevel_max :: proc() -> c.int --- /* v1.8.0+ */

	F_getVersion :: proc() -> c.uint ---

	F_createCompressionContext :: proc(cctxPtr: ^F_cctx, version: c.uint) -> F_errorCode_t ---
	F_freeCompressionContext :: proc(cctx: F_cctx) -> F_errorCode_t ---

	/*! LZ4F_compressBegin() :
	 *  will write the frame header into dstBuffer.
	 *  dstCapacity must be >= LZ4F_HEADER_SIZE_MAX bytes.
	 * `prefsPtr` is optional : NULL can be provided to set all preferences to default.
	 * @return : number of bytes written into dstBuffer for the header
	 *           or an error code (which can be tested using LZ4F_isError())
	 */
	F_compressBegin :: proc(cctx: F_cctx, dstBuffer: rawptr, dstCapacity: c.size_t, prefsPtr: Maybe(^F_preferences_t)) -> c.size_t ---

	/*! LZ4F_compressBound() :
	 *  Provides minimum dstCapacity required to guarantee success of
	 *  LZ4F_compressUpdate(), given a srcSize and preferences, for a worst case scenario.
	 *  When srcSize==0, LZ4F_compressBound() provides an upper bound for LZ4F_flush() and LZ4F_compressEnd() instead.
	 *  Note that the result is only valid for a single invocation of LZ4F_compressUpdate().
	 *  When invoking LZ4F_compressUpdate() multiple times,
	 *  if the output buffer is gradually filled up instead of emptied and re-used from its start,
	 *  one must check if there is enough remaining capacity before each invocation, using LZ4F_compressBound().
	 * @return is always the same for a srcSize and prefsPtr.
	 *  prefsPtr is optional : when NULL is provided, preferences will be set to cover worst case scenario.
	 *  tech details :
	 * @return if automatic flushing is not enabled, includes the possibility that internal buffer might already be filled by up to (blockSize-1) bytes.
	 *  It also includes frame footer (ending + checksum), since it might be generated by LZ4F_compressEnd().
	 * @return doesn't include frame header, as it was already generated by LZ4F_compressBegin().
	 */
	F_compressBound :: proc(srcSize: c.size_t, prefsPtr: Maybe(^F_preferences_t)) -> c.size_t ---

	/*! LZ4F_compressUpdate() :
	 *  LZ4F_compressUpdate() can be called repetitively to compress as much data as necessary.
	 *  Important rule: dstCapacity MUST be large enough to ensure operation success even in worst case situations.
	 *  This value is provided by LZ4F_compressBound().
	 *  If this condition is not respected, LZ4F_compress() will fail (result is an errorCode).
	 *  After an error, the state is left in a UB state, and must be re-initialized or freed.
	 *  If previously an uncompressed block was written, buffered data is flushed
	 *  before appending compressed data is continued.
	 * `cOptPtr` is optional : NULL can be provided, in which case all options are set to default.
	 * @return : number of bytes written into `dstBuffer` (it can be zero, meaning input data was just buffered).
	 *           or an error code if it fails (which can be tested using LZ4F_isError())
	 */
	F_compressUpdate :: proc(cctx: F_cctx, dstBuffer: rawptr, dstCapacity: c.size_t, srcBuffer: rawptr, srcSize: c.size_t, cOptPtr: Maybe(^F_compressOptions_t)) -> c.size_t ---

	/*! LZ4F_flush() :
	 *  When data must be generated and sent immediately, without waiting for a block to be completely filled,
	 *  it's possible to call LZ4_flush(). It will immediately compress any data buffered within cctx.
	 * `dstCapacity` must be large enough to ensure the operation will be successful.
	 * `cOptPtr` is optional : it's possible to provide NULL, all options will be set to default.
	 * @return : nb of bytes written into dstBuffer (can be zero, when there is no data stored within cctx)
	 *           or an error code if it fails (which can be tested using LZ4F_isError())
	 *  Note : LZ4F_flush() is guaranteed to be successful when dstCapacity >= LZ4F_compressBound(0, prefsPtr).
	 */
	F_flush :: proc(cctx: F_cctx, dstBuffer: rawptr, dstCapacity: c.size_t, cOptPtr: Maybe(^F_compressOptions_t)) -> c.size_t ---

	/*! LZ4F_compressEnd() :
	 *  To properly finish an LZ4 frame, invoke LZ4F_compressEnd().
	 *  It will flush whatever data remained within `cctx` (like LZ4_flush())
	 *  and properly finalize the frame, with an endMark and a checksum.
	 * `cOptPtr` is optional : NULL can be provided, in which case all options will be set to default.
	 * @return : nb of bytes written into dstBuffer, necessarily >= 4 (endMark),
	 *           or an error code if it fails (which can be tested using LZ4F_isError())
	 *  Note : LZ4F_compressEnd() is guaranteed to be successful when dstCapacity >= LZ4F_compressBound(0, prefsPtr).
	 *  A successful call to LZ4F_compressEnd() makes `cctx` available again for another compression task.
	 */
	F_compressEnd :: proc(cctx: F_cctx, dstBuffer: rawptr, dstCapacity: c.size_t, cOptPtr: Maybe(^F_compressOptions_t)) -> c.size_t ---

	/*! LZ4F_createDecompressionContext() :
	 *  Create an LZ4F_dctx object, to track all decompression operations.
	 *  @version provided MUST be LZ4F_VERSION.
	 *  @dctxPtr MUST be valid.
	 *  The function fills @dctxPtr with the value of a pointer to an allocated and initialized LZ4F_dctx object.
	 *  The @return is an errorCode, which can be tested using LZ4F_isError().
	 *  dctx memory can be released using LZ4F_freeDecompressionContext();
	 *  Result of LZ4F_freeDecompressionContext() indicates current state of decompressionContext when being released.
	 *  That is, it should be == 0 if decompression has been completed fully and correctly.
	 */
	F_createDecompressionContext :: proc(dctxPtr: F_dctx, version: c.uint) -> F_errorCode_t ---
	F_freeDecompressionContext :: proc(dctx: F_dctx) -> F_errorCode_t ---

	/*! LZ4F_headerSize() : v1.9.0+
	 *  Provide the header size of a frame starting at `src`.
	 * `srcSize` must be >= LZ4F_MIN_SIZE_TO_KNOW_HEADER_LENGTH,
	 *  which is enough to decode the header length.
	 * @return : size of frame header
	 *           or an error code, which can be tested using LZ4F_isError()
	 *  note : Frame header size is variable, but is guaranteed to be
	 *         >= LZ4F_HEADER_SIZE_MIN bytes, and <= LZ4F_HEADER_SIZE_MAX bytes.
	 */
	F_headerSize :: proc(src: rawptr, srcSize: c.size_t) -> c.size_t ---

	/*! LZ4F_getFrameInfo() :
	 *  This function extracts frame parameters (max blockSize, dictID, etc.).
	 *  Its usage is optional: user can also invoke LZ4F_decompress() directly.
	 *
	 *  Extracted information will fill an existing LZ4F_frameInfo_t structure.
	 *  This can be useful for allocation and dictionary identification purposes.
	 *
	 *  LZ4F_getFrameInfo() can work in the following situations :
	 *
	 *  1) At the beginning of a new frame, before any invocation of LZ4F_decompress().
	 *     It will decode header from `srcBuffer`,
	 *     consuming the header and starting the decoding process.
	 *
	 *     Input size must be large enough to contain the full frame header.
	 *     Frame header size can be known beforehand by LZ4F_headerSize().
	 *     Frame header size is variable, but is guaranteed to be >= LZ4F_HEADER_SIZE_MIN bytes,
	 *     and not more than <= LZ4F_HEADER_SIZE_MAX bytes.
	 *     Hence, blindly providing LZ4F_HEADER_SIZE_MAX bytes or more will always work.
	 *     It's allowed to provide more input data than the header size,
	 *     LZ4F_getFrameInfo() will only consume the header.
	 *
	 *     If input size is not large enough,
	 *     aka if it's smaller than header size,
	 *     function will fail and return an error code.
	 *
	 *  2) After decoding has been started,
	 *     it's possible to invoke LZ4F_getFrameInfo() anytime
	 *     to extract already decoded frame parameters stored within dctx.
	 *
	 *     Note that, if decoding has barely started,
	 *     and not yet read enough information to decode the header,
	 *     LZ4F_getFrameInfo() will fail.
	 *
	 *  The number of bytes consumed from srcBuffer will be updated in *srcSizePtr (necessarily <= original value).
	 *  LZ4F_getFrameInfo() only consumes bytes when decoding has not yet started,
	 *  and when decoding the header has been successful.
	 *  Decompression must then resume from (srcBuffer + *srcSizePtr).
	 *
	 * @return : a hint about how many srcSize bytes LZ4F_decompress() expects for next call,
	 *           or an error code which can be tested using LZ4F_isError().
	 *  note 1 : in case of error, dctx is not modified. Decoding operation can resume from beginning safely.
	 *  note 2 : frame parameters are *copied into* an already allocated LZ4F_frameInfo_t structure.
	 */
	F_getFrameInfo :: proc(dctx: F_dctx, frameInfoPtr: ^F_frameInfo_t, srcBuffer: rawptr, srcSizePtr: ^c.size_t) -> c.size_t ---

	/*! LZ4F_decompress() :
	 *  Call this function repetitively to regenerate data compressed in `srcBuffer`.
	 *
	 *  The function requires a valid dctx state.
	 *  It will read up to *srcSizePtr bytes from srcBuffer,
	 *  and decompress data into dstBuffer, of capacity *dstSizePtr.
	 *
	 *  The nb of bytes consumed from srcBuffer will be written into *srcSizePtr (necessarily <= original value).
	 *  The nb of bytes decompressed into dstBuffer will be written into *dstSizePtr (necessarily <= original value).
	 *
	 *  The function does not necessarily read all input bytes, so always check value in *srcSizePtr.
	 *  Unconsumed source data must be presented again in subsequent invocations.
	 *
	 * `dstBuffer` can freely change between each consecutive function invocation.
	 * `dstBuffer` content will be overwritten.
	 *
	 *  Note: if `LZ4F_getFrameInfo()` is called before `LZ4F_decompress()`, srcBuffer must be updated to reflect
	 *  the number of bytes consumed after reading the frame header. Failure to update srcBuffer before calling
	 *  `LZ4F_decompress()` will cause decompression failure or, even worse, successful but incorrect decompression.
	 *  See the `LZ4F_getFrameInfo()` docs for details.
	 *
	 * @return : an hint of how many `srcSize` bytes LZ4F_decompress() expects for next call.
	 *  Schematically, it's the size of the current (or remaining) compressed block + header of next block.
	 *  Respecting the hint provides some small speed benefit, because it skips intermediate buffers.
	 *  This is just a hint though, it's always possible to provide any srcSize.
	 *
	 *  When a frame is fully decoded, @return will be 0 (no more data expected).
	 *  When provided with more bytes than necessary to decode a frame,
	 *  LZ4F_decompress() will stop reading exactly at end of current frame, and @return 0.
	 *
	 *  If decompression failed, @return is an error code, which can be tested using LZ4F_isError().
	 *  After a decompression error, the `dctx` context is not resumable.
	 *  Use LZ4F_resetDecompressionContext() to return to clean state.
	 *
	 *  After a frame is fully decoded, dctx can be used again to decompress another frame.
	 */
	F_decompress :: proc(dctx: F_dctx, dstBuffer: rawptr, dstSizePtr: ^c.size_t, srcBuffer: rawptr, srcSizePtr: ^c.size_t, dOptPtr: Maybe(^F_decompressOptions_t)) -> c.size_t ---

	/*! LZ4F_resetDecompressionContext() : added in v1.8.0
	 *  In case of an error, the context is left in "undefined" state.
	 *  In which case, it's necessary to reset it, before re-using it.
	 *  This method can also be used to abruptly stop any unfinished decompression,
	 *  and start a new one using same context resources. */
	F_resetDecompressionContext :: proc(dctx: F_dctx) --- /* always successful */

	/*! LZ4F_compressBegin_usingDict() : stable since v1.10
	 *  Inits dictionary compression streaming, and writes the frame header into dstBuffer.
	 * @dstCapacity must be >= LZ4F_HEADER_SIZE_MAX bytes.
	 * @prefsPtr is optional : one may provide NULL as argument,
	 *  however, it's the only way to provide dictID in the frame header.
	 * @dictBuffer must outlive the compression session.
	 * @return : number of bytes written into dstBuffer for the header,
	 *           or an error code (which can be tested using LZ4F_isError())
	 *  NOTE: The LZ4Frame spec allows each independent block to be compressed with the dictionary,
	 *        but this entry supports a more limited scenario, where only the first block uses the dictionary.
	 *        This is still useful for small data, which only need one block anyway.
	 *        For larger inputs, one may be more interested in LZ4F_compressFrame_usingCDict() below.
	 */
	F_compressBegin_usingDict :: proc(cctx: F_cctx, dstBuffer: rawptr, dstCapacity: c.size_t, dictBuffer: rawptr, dictSize: c.size_t, prefsPtr: Maybe(^F_preferences_t)) -> c.size_t ---

	/*! LZ4F_decompress_usingDict() : stable since v1.10
	 *  Same as LZ4F_decompress(), using a predefined dictionary.
	 *  Dictionary is used "in place", without any preprocessing.
	**  It must remain accessible throughout the entire frame decoding. */
	F_decompress_usingDict :: proc(dctxPtr: F_dctx, dstBuffer: rawptr, dstSizePtr: ^c.size_t, srcBuffer: rawptr, srcSizePtr: ^c.size_t, dict: rawptr, dictSize: c.size_t, decompressOptionsPtr: Maybe(^F_decompressOptions_t)) -> c.size_t ---

	/*! LZ4_createCDict() : stable since v1.10
	 *  When compressing multiple messages / blocks using the same dictionary, it's recommended to initialize it just once.
	 *  LZ4_createCDict() will create a digested dictionary, ready to start future compression operations without startup delay.
	 *  LZ4_CDict can be created once and shared by multiple threads concurrently, since its usage is read-only.
	 * @dictBuffer can be released after LZ4_CDict creation, since its content is copied within CDict. */
	F_createCDict :: proc(dictBuffer: rawptr, dictSize: c.size_t) -> F_CDict ---
	F_freeCDict :: proc(CDict: F_CDict) ---

	/*! LZ4_compressFrame_usingCDict() : stable since v1.10
	 *  Compress an entire srcBuffer into a valid LZ4 frame using a digested Dictionary.
	 * @cctx must point to a context created by LZ4F_createCompressionContext().
	 *  If @cdict==NULL, compress without a dictionary.
	 * @dstBuffer MUST be >= LZ4F_compressFrameBound(srcSize, preferencesPtr).
	 *  If this condition is not respected, function will fail (@return an errorCode).
	 *  The LZ4F_preferences_t structure is optional : one may provide NULL as argument,
	 *  but it's not recommended, as it's the only way to provide @dictID in the frame header.
	 * @return : number of bytes written into dstBuffer.
	 *           or an error code if it fails (can be tested using LZ4F_isError())
	 *  Note: for larger inputs generating multiple independent blocks,
	 *        this entry point uses the dictionary for each block. */
	F_compressFrame_usingCDict :: proc(cctx: F_cctx, dst: rawptr, dstCapacity: c.size_t, src: rawptr, srcSize: c.size_t, cdict: F_CDict, preferencesPtr: Maybe(^F_preferences_t)) -> c.size_t ---

	/*! LZ4F_compressBegin_usingCDict() : stable since v1.10
	 *  Inits streaming dictionary compression, and writes the frame header into dstBuffer.
	 * @dstCapacity must be >= LZ4F_HEADER_SIZE_MAX bytes.
	 * @prefsPtr is optional : one may provide NULL as argument,
	 *  note however that it's the only way to insert a @dictID in the frame header.
	 * @cdict must outlive the compression session.
	 * @return : number of bytes written into dstBuffer for the header,
	 *           or an error code, which can be tested using LZ4F_isError(). */
	F_compressBegin_usingCDict :: proc(cctx: F_cctx, dstBuffer: rawptr, dstCapacity: c.size_t, cdict: F_CDict, prefsPtr: Maybe(^F_preferences_t)) -> c.size_t ---
}

/* The larger the block size, the (slightly) better the compression ratio,
 * though there are diminishing returns.
 * Larger blocks also increase memory usage on both compression and decompression sides.
 */
F_blockSizeID_t :: enum c.int {
	default = 0,
	max64KB = 4,
	max256KB = 5,
	max1MB = 6,
	max4MB = 7,
}

/* Linked blocks sharply reduce inefficiencies when using small blocks,
 * they compress better.
 * However, some LZ4 decoders are only compatible with independent blocks */
F_blockMode_t :: enum c.int {
	blockLinked = 0,
	blockIndependent,
}

F_contentChecksum_t :: enum c.int {
	noContentChecksum = 0,
	contentChecksumEnabled,
}

F_blockChecksum_t :: enum c.int {
	noBlockChecksum = 0,
	blockChecksumEnabled,
}

F_frameType_t :: enum c.int {
	frame = 0,
	skippableFrame,
}

/*! LZ4F_frameInfo_t :
 *  makes it possible to set or read frame parameters.
 *  Structure must be first init to 0, using memset() or LZ4F_INIT_FRAMEINFO,
 *  setting all parameters to default.
 *  It's then possible to update selectively some parameters */
F_frameInfo_t :: struct {
	blockSizeID:         F_blockSizeID_t,     /* max64KB, max256KB, max1MB, max4MB; 0 == default (LZ4F_max64KB) */
	blockMode:           F_blockMode_t,       /* LZ4F_blockLinked, LZ4F_blockIndependent; 0 == default (LZ4F_blockLinked) */
	contentChecksumFlag: F_contentChecksum_t, /* 1: add a 32-bit checksum of frame's decompressed data; 0 == default (disabled) */
	frameType:           F_frameType_t,       /* read-only field : LZ4F_frame or LZ4F_skippableFrame */
	contentSize:         c.ulonglong,         /* Size of uncompressed content ; 0 == unknown */
	dictID:              c.uint,              /* Dictionary ID, sent by compressor to help decoder select correct dictionary; 0 == no dictID provided */
	blockChecksumFlag:   F_blockChecksum_t,   /* 1: each block followed by a checksum of block's compressed data; 0 == default (disabled) */
}

/* v1.8.3+ */
F_INIT_FRAMEINFO :: F_frameInfo_t{
	blockSizeID = .max64KB,
	blockMode = .blockLinked,
	contentChecksumFlag = .noContentChecksum,
	frameType = .frame,
	contentSize = 0,
	dictID = 0,
	blockChecksumFlag = .noBlockChecksum,
}

/*! LZ4F_preferences_t :
 *  makes it possible to supply advanced compression instructions to streaming interface.
 *  Structure must be first init to 0, using memset() or LZ4F_INIT_PREFERENCES,
 *  setting all parameters to default.
 *  All reserved fields must be set to zero. */
F_preferences_t :: struct{
	frameInfo:        F_frameInfo_t,
	compressionLevel: c.int, /* 0: default (fast mode); values > LZ4HC_CLEVEL_MAX count as LZ4HC_CLEVEL_MAX; values < 0 trigger "fast acceleration" */
	autoFlush:        c.uint, /* 1: always flush; reduces usage of internal buffers */
	favorDecSpeed:    c.uint, /* 1: parser favors decompression speed vs compression ratio. Only works for high compression modes (>= LZ4HC_CLEVEL_OPT_MIN) */  /* v1.8.2+ */
	reserved:         [3]c.uint, /* must be zero for forward compatibility */
}

F_INIT_PREFERENCES :: F_preferences_t{
	frameInfo = F_INIT_FRAMEINFO,
	compressionLevel = 0,
	autoFlush = 0,
	favorDecSpeed = 0,
	reserved = {0, 0, 0}
}

F_cctx :: distinct rawptr /* incomplete type */
F_compressionContext_t :: F_cctx /* for compatibility with older APIs, prefer using LZ4F_cctx */

F_compressOptions_t :: struct {
	stableSrc: c.uint, /* 1 == src content will remain present on future calls to LZ4F_compress(); skip copying src content within tmp buffer */
	reserved:  [3]c.uint,
}

F_VERSION :: 100 /* This number can be used to check for an incompatible API breaking change */

F_HEADER_SIZE_MIN :: 7 /* LZ4 Frame header size can vary, depending on selected parameters */
F_HEADER_SIZE_MAX :: 19

/* Size in bytes of a block header in little-endian format. Highest bit indicates if block data is uncompressed */
F_BLOCK_HEADER_SIZE :: 4

/* Size in bytes of a block checksum footer in little-endian format. */
F_BLOCK_CHECKSUM_SIZE :: 4

/* Size in bytes of the content checksum. */
F_CONTENT_CHECKSUM_SIZE :: 4

F_dctx :: distinct rawptr /* incomplete type */
F_decompressionContext_t :: F_dctx

F_decompressOptions_t :: struct {
	/* pledges that last 64KB decompressed data is present right before @dstBuffer pointer.
         * This optimization skips internal storage operations.
         * Once set, this pledge must remain valid up to the end of current frame. */
	stableDst:     c.uint,
	/* disable checksum calculation and verification, even when one is present in frame, to save CPU time.
         * Setting this option to 1 once disables all checksums for the rest of the frame. */
        skipChecksums: c.uint,
        reserved1:     c.uint, /* must be set to zero for forward compatibility */
        reserved0:     c.uint, /* idem */
}

F_MAGICNUMBER                    :: 0x184D2204
F_MAGIC_SKIPPABLE_START          :: 0x184D2A50
F_MIN_SIZE_TO_KNOW_HEADER_LENGTH :: 5

/* Loading a dictionary has a cost, since it involves construction of tables.
 * The Bulk processing dictionary API makes it possible to share this cost
 * over an arbitrary number of compression jobs, even concurrently,
 * markedly improving compression latency for these cases.
 *
 * Note that there is no corresponding bulk API for the decompression side,
 * because dictionary does not carry any initialization cost for decompression.
 * Use the regular LZ4F_decompress_usingDict() there.
 */
F_CDict :: distinct rawptr
