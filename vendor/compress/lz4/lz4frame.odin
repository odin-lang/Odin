package vendor_compress_lz4

when ODIN_OS == .Windows {
	foreign import lib "lib/liblz4_static.lib"
} else {
	foreign import lib "system:lz4"
}

import "core:c"

FRAME_VERSION :: 100

HEADER_SIZE_MIN           :: 7
HEADER_SIZE_MAX           :: 19
BLOCK_HEADER_SIZE         :: 4
BLOCK_CHECKSUM_SIZE       :: 4
CONTENT_CHECKSUM_SIZE     :: 4
ENDMARK_SIZE              :: 4

MAGICNUMBER                     :: 0x184D2204
MAGIC_SKIPPABLE_START           :: 0x184D2A50
MIN_SIZE_TO_KNOW_HEADER_LENGTH  :: 5

errorCode_t :: c.size_t

blockSizeID_t :: enum c.int {
	default = 0,
	max64KB = 4,
	max256KB = 5,
	max1MB = 6,
	max4MB = 7,
}

blockMode_t :: enum c.int {
	blockLinked = 0,
	blockIndependent,
}

contentChecksum_t :: enum c.int {
	noContentChecksum = 0,
	contentChecksumEnabled,
}

blockChecksum_t :: enum c.int {
	noBlockChecksum = 0,
	blockChecksumEnabled,
}

frameType_t :: enum c.int {
	frame = 0,
	skippableFrame,
}

stableSrc_t :: enum c.uint {
	srcUnstable = 0,
	srcStable = 1,
	srcStableUntilFlush = 2,
}

errorCodes :: enum c.int {
	OK_NoError,
	ERROR_GENERIC,
	ERROR_maxBlockSize_invalid,
	ERROR_blockMode_invalid,
	ERROR_parameter_invalid,
	ERROR_compressionLevel_invalid,
	ERROR_headerVersion_wrong,
	ERROR_blockChecksum_invalid,
	ERROR_reservedFlag_set,
	ERROR_allocation_failed,
	ERROR_srcSize_tooLarge,
	ERROR_dstCapacity_tooSmall,
	ERROR_frameHeader_incomplete,
	ERROR_frameType_unknown,
	ERROR_frameSize_wrong,
	ERROR_srcPtr_wrong,
	ERROR_decompressionFailed,
	ERROR_headerChecksum_invalid,
	ERROR_contentChecksum_invalid,
	ERROR_frameDecoding_alreadyStarted,
	ERROR_compressionState_uninitialized,
	ERROR_parameter_null,
	ERROR_io_write,
	ERROR_io_read,
	ERROR_maxCode,
}

frameInfo_t :: struct {
	blockSizeID:         blockSizeID_t,
	blockMode:           blockMode_t,
	contentChecksumFlag: contentChecksum_t,
	frameType:           frameType_t,
	contentSize:         c.ulonglong,
	dictID:              c.uint,
	blockChecksumFlag:   blockChecksum_t,
}

preferences_t :: struct {
	frameInfo:        frameInfo_t,
	compressionLevel: c.int,
	autoFlush:        c.uint,
	favorDecSpeed:    c.uint,
	nbWorkers:        c.uint,
	reserved1:        c.uint,
	reserved0:        c.uint,
}

compressOptions_t :: struct {
	stableSrc:    stableSrc_t,
	uncompressed: c.uint,
	reserved1:    c.uint,
	reserved0:    c.uint,
}

decompressOptions_t :: struct {
	stableDst:     c.uint,
	skipChecksums: c.uint,
	reserved1:     c.uint,
	reserved0:     c.uint,
}

cctx  :: struct {}
dctx  :: struct {}
CDict :: struct {}

@(default_calling_convention="c", link_prefix="LZ4F_")
foreign lib {
	isError      :: proc(code: errorCode_t) -> c.uint ---
	getErrorName :: proc(code: errorCode_t) -> cstring ---
	getVersion   :: proc() -> c.uint ---

	compressFrame            :: proc(dstBuffer: [^]byte, dstCapacity: c.size_t, srcBuffer: [^]byte, srcSize: c.size_t, preferencesPtr: ^preferences_t) -> c.size_t ---
	compressFrameBound       :: proc(srcSize: c.size_t, preferencesPtr: ^preferences_t) -> c.size_t ---
	compressionLevel_max     :: proc() -> c.int ---

	createCompressionContext :: proc(cctxPtr: ^^cctx, version: c.uint) -> errorCode_t ---
	freeCompressionContext   :: proc(cctx: ^cctx) -> errorCode_t ---

	compressBegin :: proc(cctx: ^cctx, dstBuffer: [^]byte, dstCapacity: c.size_t, prefsPtr: ^preferences_t) -> c.size_t ---

	@(link_name="LZ4F_compressBound")
	frame_compressBound :: proc(srcSize: c.size_t, prefsPtr: ^preferences_t) -> c.size_t ---

	compressUpdate :: proc(cctx: ^cctx, dstBuffer: [^]byte, dstCapacity: c.size_t, srcBuffer: [^]byte, srcSize: c.size_t, cOptPtr: ^compressOptions_t) -> c.size_t ---
	flush          :: proc(cctx: ^cctx, dstBuffer: [^]byte, dstCapacity: c.size_t, cOptPtr: ^compressOptions_t) -> c.size_t ---
	compressEnd    :: proc(cctx: ^cctx, dstBuffer: [^]byte, dstCapacity: c.size_t, cOptPtr: ^compressOptions_t) -> c.size_t ---

	createDecompressionContext :: proc(dctxPtr: ^^dctx, version: c.uint) -> errorCode_t ---
	freeDecompressionContext   :: proc(dctx: ^dctx) -> errorCode_t ---
	resetDecompressionContext  :: proc(dctx: ^dctx) ---

	headerSize   :: proc(src: rawptr, srcSize: c.size_t) -> c.size_t ---
	getFrameInfo :: proc(dctx: ^dctx, frameInfoPtr: ^frameInfo_t, srcBuffer: [^]byte, srcSizePtr: ^c.size_t) -> c.size_t ---
	decompress   :: proc(dctx: ^dctx, dstBuffer: [^]byte, dstSizePtr: ^c.size_t, srcBuffer: [^]byte, srcSizePtr: ^c.size_t, dOptPtr: ^decompressOptions_t) -> c.size_t ---

	compressBegin_usingDict   :: proc(cctx: ^cctx, dstBuffer: [^]byte, dstCapacity: c.size_t, dictBuffer: [^]byte, dictSize: c.size_t, prefsPtr: ^preferences_t) -> c.size_t ---
	decompress_usingDict      :: proc(dctx: ^dctx, dstBuffer: [^]byte, dstSizePtr: ^c.size_t, srcBuffer: [^]byte, srcSizePtr: ^c.size_t, dict: [^]byte, dictSize: c.size_t, decompressOptionsPtr: ^decompressOptions_t) -> c.size_t ---

	createCDict                    :: proc(dictBuffer: [^]byte, dictSize: c.size_t) -> ^CDict ---
	freeCDict                      :: proc(CDict: ^CDict) ---
	compressFrame_usingCDict       :: proc(cctx: ^cctx, dst: [^]byte, dstCapacity: c.size_t, src: [^]byte, srcSize: c.size_t, cdict: ^CDict, preferencesPtr: ^preferences_t) -> c.size_t ---
	compressBegin_usingCDict       :: proc(cctx: ^cctx, dstBuffer: [^]byte, dstCapacity: c.size_t, cdict: ^CDict, prefsPtr: ^preferences_t) -> c.size_t ---

	getErrorCode   :: proc(functionResult: c.size_t) -> errorCodes ---
	getBlockSize   :: proc(blockSizeID: blockSizeID_t) -> c.size_t ---
	getMaxNbWorkers :: proc() -> c.uint ---
	resumeFrame    :: proc(dctx: ^dctx, frameInfo: ^frameInfo_t, decodedPos: c.ulonglong, dict: [^]byte, dictSize: c.size_t) -> c.size_t ---
	cctx_size      :: proc(cctx: ^cctx) -> c.size_t ---
	dctx_size      :: proc(dctx: ^dctx) -> c.size_t ---
}
