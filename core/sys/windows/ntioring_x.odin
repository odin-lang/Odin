#+build windows
package sys_windows


IORING_SUBMIT_WAIT_ALL :: max(u32)

IORING_VERSION :: enum i32 {
	INVALID,
	_1,
	_2,
	_3 = 300,
	_4 = 400,
}

IORING_FEATURE_FLAG :: enum u32 {
	UM_EMULATION         = 0, // 0x00000001
	SET_COMPLETION_EVENT = 1, // 0x00000002
}

IORING_FEATURE_FLAGS :: bit_set[IORING_FEATURE_FLAG; u32]

IORING_OP_CODE :: enum i32 {
	NOP,
	READ,
	REGISTER_FILES,
	REGISTER_BUFFERS,
	CANCEL,
	WRITE,
	FLUSH,
	READ_SCATTER,
	WRITE_GATHER,
}

IORING_BUFFER_INFO :: struct {
	Address: rawptr,
	Length: u32,
}

IORING_REGISTERED_BUFFER :: struct {
	BufferIndex: u32,
	Offset: u32,
}
