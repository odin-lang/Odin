package sdl3

import "core:c"

Thread :: struct {}
ThreadID :: distinct Uint64

TLSID :: AtomicInt

ThreadPriority :: enum c.int {
	LOW,
	NORMAL,
	HIGH,
	TIME_CRITICAL,
}

ThreadState :: enum c.int {
	UNKNOWN,     /**< The thread is not valid */
	ALIVE,       /**< The thread is currently running */
	DETACHED,    /**< The thread is detached and can't be waited on */
	COMPLETE,    /**< The thread has finished and should be cleaned up with SDL_WaitThread() */
}

ThreadFunction :: #type proc "c" (data: rawptr) -> c.int

TLSDestructorCallback :: #type proc "c" (value: rawptr)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	CreateThreadRuntime :: proc(fn: ThreadFunction, name: cstring, data: rawptr, pfnBeginThread: FunctionPointer, pfnEndThread: FunctionPointer) -> ^Thread ---
	CreateThreadWithPropertiesRuntime :: proc(props: PropertiesID, pfnBeginThread: FunctionPointer, pfnEndThread: FunctionPointer) -> ^Thread ---
}

@(require_results)
CreateThread :: proc "c" (fn: ThreadFunction, name: cstring, data: rawptr) -> ^Thread {
	return CreateThreadRuntime(fn, name, data, BeginThreadFunction(), EndThreadFunction())
}
@(require_results)
CreateThreadWithProperties :: proc "c" (props: PropertiesID) -> ^Thread {
	return CreateThreadWithPropertiesRuntime(props, BeginThreadFunction(), EndThreadFunction())
}

PROP_THREAD_CREATE_ENTRY_FUNCTION_POINTER :: "SDL.thread.create.entry_function"
PROP_THREAD_CREATE_NAME_STRING            :: "SDL.thread.create.name"
PROP_THREAD_CREATE_USERDATA_POINTER       :: "SDL.thread.create.userdata"
PROP_THREAD_CREATE_STACKSIZE_NUMBER       :: "SDL.thread.create.stacksize"


BeginThreadFunction :: proc "c" () -> FunctionPointer {
	when ODIN_OS == .Windows {
		foreign {
			_beginthreadx :: proc "c" (
			        security: rawptr,
			        stack_size: c.uint,
				start_address: proc "c" (rawptr),
				arglist: rawptr,
				initflag: c.uint,
				thraddr: ^c.uint,
			) -> uintptr ---
		}
		return FunctionPointer(_beginthreadx)
	} else {
		return nil
	}
}

EndThreadFunction :: proc "c" () -> FunctionPointer {
	when ODIN_OS == .Windows {
		foreign {
			_endthreadex :: proc "c" (retval: c.uint) ---
		}
		return FunctionPointer(_endthreadex)
	} else {
		return nil
	}
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetThreadName            :: proc(thread: ^Thread) -> cstring ---
	GetCurrentThreadID       :: proc() -> ThreadID ---
	GetThreadID              :: proc(thread: ^Thread) -> ThreadID ---
	GetThreadState           :: proc(thread: ^Thread) -> ThreadState ---
	GetTLS                   :: proc(id: ^TLSID) -> rawptr ---
	SetTLS                   :: proc(id: ^TLSID, value: rawptr, destructor: TLSDestructorCallback) -> bool ---
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	SetCurrentThreadPriority :: proc(priority: ThreadPriority) -> bool ---
	WaitThread               :: proc(thread: ^Thread, status: ^c.int) ---
	DetachThread             :: proc(thread: ^Thread) ---
	CleanupTLS               :: proc() ---
}