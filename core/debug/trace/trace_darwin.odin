#+vet explicit-allocators
#+private file
package debug_trace

@require import "base:runtime"

@require import "core:strings"
@require import "core:sys/posix"

when !INSTRUMENTATION_MODE {

foreign import system "system:System.framework"

// NOTE: CoreSymbolication is a private framework, Apple is allowed to break it and doesn't provide
// headers, although the API has as of my knowledge been the same in the past 10 years at least.
@(extra_linker_flags="-iframework /System/Library/PrivateFrameworks")
foreign import symbolication "system:CoreSymbolication.framework"

@(private="package")
_Capture_Entry :: rawptr

@(private="package")
_capture :: #force_no_inline proc(buf: Capture, skip: int) -> (n: int) {
	ctx:    unw_context_t
	cursor: unw_cursor_t

	ret: i32
	if ret = unw_getcontext(&ctx);          ret != 0 { return }
	if ret = unw_init_local(&cursor, &ctx); ret != 0 { return }

	// Skip this function's frame and the caller, in addition to `skip`.
	for _ in 0..<skip+1 {
		if unw_step(&cursor) <= 0 { return }
	}

	pc: uintptr
	for ; unw_step(&cursor) > 0 && n < len(buf); n += 1 {
		if ret = unw_get_reg(&cursor, .IP, &pc); ret != 0 { return }
		buf[n] = Capture_Entry(pc)
	}

	return
}

@(private="package")
_locations_destroy :: proc(locations: []Location, allocator: runtime.Allocator) {
	for location in locations {
		delete(location.file_path, allocator)
		delete(location.procedure, allocator)
	}
	delete(locations, allocator)
}

@(private="package")
_resolve :: proc(bt: Capture, allocator, _: runtime.Allocator) -> (out: []Location, err: Resolve_Error) {
	out = make([]Location, len(bt), allocator)
	defer if err != nil { _locations_destroy(out, allocator) }

	symbolicator := CSSymbolicatorCreateWithPid(posix.getpid())
	defer CSRelease(symbolicator)

	for &location, i in out {
		symbol := CSSymbolicatorGetSymbolWithAddressAtTime(symbolicator, uintptr(bt[i]), CSNow)
		info   := CSSymbolicatorGetSourceInfoWithAddressAtTime(symbolicator, uintptr(bt[i]), CSNow)

		location.procedure = clone_or_oom_marker(CSSymbolGetName(symbol), allocator)

		// No debug info.
		if CSIsNull(info) {
			owner := CSSymbolGetSymbolOwner(symbol)
			location.file_path = clone_or_oom_marker(CSSymbolOwnerGetPath(owner), allocator)
		} else {
			location.file_path = clone_or_oom_marker(CSSourceInfoGetPath(info), allocator)
			location.line      = CSSourceInfoGetLineNumber(info)
		}
	}

	return

	clone_or_oom_marker :: proc(s: cstring, allocator: runtime.Allocator) -> string {
		clone, err := strings.clone_from(s, allocator)
		if err != nil {
			return OOM_MARKER
		}

		return clone
	}

}

CSTypeRef :: struct {
	csCppData: rawptr,
	csCppObj:  rawptr,
}

CSSymbolicatorRef :: distinct CSTypeRef
CSSymbolRef       :: distinct CSTypeRef
CSSourceInfoRef   :: distinct CSTypeRef
CSSymbolOwnerRef  :: distinct CSTypeRef

CSNow :: 0x80000000

foreign symbolication {
	@(link_name="CSIsNull")
	_CSIsNull :: proc(ref: CSTypeRef) -> bool ---
	@(link_name="CSRelease")
	_CSRelease :: proc(ref: CSTypeRef) ---

	CSSymbolicatorCreateWithPid :: proc(pid: posix.pid_t) -> CSSymbolicatorRef ---

	CSSymbolicatorGetSymbolWithAddressAtTime     :: proc(symbolicator: CSSymbolicatorRef, addr: uintptr, time: u64) -> CSSymbolRef ---
	CSSymbolicatorGetSourceInfoWithAddressAtTime :: proc(symbolicator: CSSymbolicatorRef, adrr: uintptr, time: u64) -> CSSourceInfoRef ---

	CSSymbolGetName        :: proc(symbol: CSSymbolRef) -> cstring ---
	CSSymbolGetSymbolOwner :: proc(symbol: CSSymbolRef) -> CSSymbolOwnerRef ---

	CSSourceInfoGetPath       :: proc(info: CSSourceInfoRef) -> cstring ---
	CSSourceInfoGetLineNumber :: proc(info: CSSourceInfoRef) -> i32 ---
	CSSourceInfoGetSymbol     :: proc(info: CSSourceInfoRef) -> CSSymbolRef ---

	CSSymbolOwnerGetPath :: proc(owner: CSSymbolOwnerRef) -> cstring ---
}

CSRelease :: #force_inline proc(ref: $T) {
	_CSRelease(CSTypeRef(ref))
}

CSIsNull :: #force_inline proc(ref: $T) -> bool {
	return _CSIsNull(CSTypeRef(ref))
}

// These could actually be smaller, but then we would have to define and check the size on each
// architecture, the sizes here are the largest they can be.
_LIBUNWIND_CONTEXT_SIZE :: 167
_LIBUNWIND_CURSOR_SIZE :: 204

unw_context_t :: struct {
	data: [_LIBUNWIND_CONTEXT_SIZE]u64,
}

unw_cursor_t :: struct {
	data: [_LIBUNWIND_CURSOR_SIZE]u64,
}

// Cross-platform registers, each architecture has additional registers but these are enough for us.
Register :: enum i32 {
	SP = -2,
	IP = -1,
}

foreign system {
	unw_getcontext :: proc(ctx: ^unw_context_t) -> i32 ---
	unw_init_local :: proc(cursor: ^unw_cursor_t, ctx: ^unw_context_t) -> i32 ---
	unw_get_reg    :: proc(cursor: ^unw_cursor_t, name: Register, reg: ^uintptr) -> i32 ---
	unw_step       :: proc(cursor: ^unw_cursor_t) -> i32 ---
}
} // INSTRUMENTATION_MODE
