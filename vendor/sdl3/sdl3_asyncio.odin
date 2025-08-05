package sdl3

import "core:c"

AsyncIO :: struct {}

AsyncIOTaskType :: enum c.int {
	READ,  /**< A read operation. */
	WRITE, /**< A write operation. */
	CLOSE, /**< A close operation. */
}

AsyncIOResult :: enum c.int {
	COMPLETE, /**< request was completed without error */
	FAILURE,  /**< request failed for some reason; check SDL_GetError()! */
	CANCELED, /**< request was canceled before completing. */
}

AsyncIOOutcome :: struct {
	asyncio:           ^AsyncIO,        /**< what generated this task. This pointer will be invalid if it was closed! */
	type:              AsyncIOTaskType, /**< What sort of task was this? Read, write, etc? */
	result:            AsyncIOResult,   /**< the result of the work (success, failure, cancellation). */
	buffer:            rawptr,          /**< buffer where data was read/written. */
	offset:            Uint64,          /**< offset in the SDL_AsyncIO where data was read/written. */
	bytes_requested:   Uint64,          /**< number of bytes the task was to read/write. */
	bytes_transferred: Uint64,          /**< actual number of bytes that were read/written. */
	userdata:          rawptr,          /**< pointer provided by the app when starting the task */
}

AsyncIOQueue :: struct {}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	AsyncIOFromFile     :: proc(file: cstring, mode: cstring) -> ^AsyncIO ---
	GetAsyncIOSize      :: proc(asyncio: ^AsyncIO) -> Sint64 ---
	ReadAsyncIO         :: proc(asyncio: ^AsyncIO, ptr: rawptr, offset, size: Uint64, queue: ^AsyncIOQueue, userdata: rawptr) -> bool ---
	WriteAsyncIO        :: proc(asyncio: ^AsyncIO, ptr: rawptr, offset, size: Uint64, queue: ^AsyncIOQueue, userdata: rawptr) -> bool ---
	CloseAsyncIO        :: proc(asyncio: ^AsyncIO, flush: bool, queue: ^AsyncIOQueue, userdata: rawptr) -> bool ---
	CreateAsyncIOQueue  :: proc() -> ^AsyncIOQueue ---
	DestroyAsyncIOQueue :: proc(queue: ^AsyncIOQueue) ---
	GetAsyncIOResult    :: proc(queue: ^AsyncIOQueue, outcome: ^AsyncIOOutcome) -> bool ---
	WaitAsyncIOResult   :: proc(queue: ^AsyncIOQueue, outcome: ^AsyncIOOutcome, timeoutMS: Sint32) -> bool ---
	SignalAsyncIOQueue  :: proc(queue: ^AsyncIOQueue) ---
	LoadFileAsync       :: proc(file: cstring, queue: ^AsyncIOQueue, userdata: rawptr) -> bool ---
}