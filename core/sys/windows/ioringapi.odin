#+build windows
package sys_windows

foreign import ioringapi "system:kernel32.lib"

HIORING :: distinct rawptr

IORING_SQE_FLAG :: enum u32 {
	DRAIN_PRECEDING_OPS = 0, // 0x00000001
}
IORING_SQE_FLAGS :: bit_set[IORING_SQE_FLAG; u32]

// Reserved for future use; currently no flags defined
IORING_CREATE_REQUIRED_FLAG :: enum u32 {}
IORING_CREATE_REQUIRED_FLAGS :: bit_set[IORING_CREATE_REQUIRED_FLAG; u32]

IORING_CREATE_ADVISORY_FLAG :: enum u32 {
	SKIP_BUILDER_PARAM_CHECKS = 0, // 0x00000001
}
IORING_CREATE_ADVISORY_FLAGS :: bit_set[IORING_CREATE_ADVISORY_FLAG; u32]

IORING_CREATE_FLAGS :: struct {
	Required: IORING_CREATE_REQUIRED_FLAGS,
	Advisory: IORING_CREATE_ADVISORY_FLAGS,
}

IORING_INFO :: struct {
	Version: IORING_VERSION,
	Flags: IORING_CREATE_FLAGS,
	SubmissionQueueSize: UINT32,
	CompletionQueueSize: UINT32,
}

IORING_CAPABILITIES :: struct {
	MaxVersion: IORING_VERSION,
	MaxSubmissionQueueSize: UINT32,
	MaxCompletionQueueSize: UINT32,
	FeatureFlags: IORING_FEATURE_FLAGS,
}

IORING_REF_KIND :: enum i32 {
	RAW,
	REGISTERED,
}

IORING_HANDLE_REF :: struct {
	Kind: IORING_REF_KIND,
	HandleUnion: struct #raw_union {
		Handle: HANDLE,
		Index: UINT32,
	},
}

IORING_BUFFER_REF :: struct {
	Kind:  IORING_REF_KIND,
	BufferUnion: struct #raw_union {
		Address: rawptr,
		IndexAndOffset: IORING_REGISTERED_BUFFER,
	},
}

IORING_CQE :: struct {
	UserData: UINT_PTR,
	ResultCode: HRESULT,
	Information: ULONG_PTR,
}

// Types below are from winbase.h and winnt.h
FILE_WRITE_FLAG :: enum u32 {
	WRITE_THROUGH = 0, // 0x000000001
}
FILE_WRITE_FLAGS :: bit_set[FILE_WRITE_FLAG ;u32]

FILE_FLUSH_MODE :: enum i32 {
	DEFAULT,
	DATA,
	MIN_METADATA,
	NO_SYNC,
}

FILE_SEGMENT_ELEMENT :: struct #raw_union {
	Buffer: PVOID64,
	Alignment: ULONGLONG,
}


@(default_calling_convention="system")
foreign ioringapi {
	QueryIoRingCapabilities :: proc(capabilities: ^IORING_CAPABILITIES) -> HRESULT ---
	IsIoRingOpSupported :: proc(ioRing: HIORING, op: IORING_OP_CODE) -> BOOL ---
	CreateIoRing :: proc(ioringVersion: IORING_VERSION, flags: IORING_CREATE_FLAGS, submissionQueueSize: UINT32, completionQueueSize: UINT32, h: ^HIORING) -> HRESULT ---
	GetIoRingInfo :: proc(ioRing: HIORING, info: ^IORING_INFO) -> HRESULT ---
	SubmitIoRing :: proc(ioRing: HIORING, waitOperations: UINT32, milliseconds: UINT32, submittedEntries: ^UINT32) -> HRESULT ---
	CloseIoRing :: proc(ioRing: HIORING) -> HRESULT ---
	PopIoRingCompletion :: proc(ioRing: HIORING, cqe: ^IORING_CQE) -> HRESULT ---
	SetIoRingCompletionEvent :: proc(ioRing: HIORING, hEvent: HANDLE) -> HRESULT ---

	BuildIoRingCancelRequest :: proc(ioRing: HIORING, file: IORING_HANDLE_REF, opToCancel: UINT_PTR, userData: UINT_PTR) -> HRESULT ---
	BuildIoRingReadFile :: proc(ioRing: HIORING, fileRef: IORING_HANDLE_REF, dataRef: IORING_BUFFER_REF, numberOfBytesToRead: UINT32, fileOffset: UINT64, userData: UINT_PTR, sqeFlags: IORING_SQE_FLAGS) -> HRESULT ---
	BuildIoRingRegisterFileHandles :: proc(ioRing: HIORING, count: UINT32, handles: [^]HANDLE, userData: UINT_PTR) -> HRESULT ---
	BuildIoRingRegisterBuffers :: proc(ioRing: HIORING, count: UINT32, buffers: [^]IORING_BUFFER_INFO, userData: UINT_PTR) -> HRESULT ---
	BuildIoRingWriteFile :: proc(ioRing: HIORING, fileRef: IORING_HANDLE_REF, bufferRef: IORING_BUFFER_REF, numberOfBytesToWrite: UINT32, fileOffset: UINT64, writeFlags: FILE_WRITE_FLAGS, userData: UINT_PTR, sqeFlags: IORING_SQE_FLAGS) -> HRESULT ---
	BuildIoRingFlushFile :: proc(ioRing: HIORING, fileRef: IORING_HANDLE_REF, flushMode: FILE_FLUSH_MODE, userData: UINT_PTR, sqeFlags: IORING_SQE_FLAGS) -> HRESULT ---
	BuildIoRingReadFileScatter :: proc(ioRing: HIORING, fileRef: IORING_HANDLE_REF, segmentCount: UINT32, segmentArray: [^]FILE_SEGMENT_ELEMENT, numberOfBytesToRead: UINT32, fileOffset: UINT64, userData: UINT_PTR, sqeFlags: IORING_SQE_FLAGS) -> HRESULT ---
    BuildIoRingWriteFileGather :: proc(ioRing: HIORING, fileRef: IORING_HANDLE_REF, segmentCount: UINT32, segmentArray: [^]FILE_SEGMENT_ELEMENT, numberOfBytesToWrite: UINT32, fileOffset: UINT64, writeFlags: FILE_WRITE_FLAGS, userData: UINT_PTR, sqeFlags: IORING_SQE_FLAGS) -> HRESULT ---
}
