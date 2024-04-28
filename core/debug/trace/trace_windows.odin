//+private
//+build windows
package debug_trace

import "base:intrinsics"
import "base:runtime"

import win32 "core:sys/windows"
import "core:fmt"

_Context :: struct {
	hProcess: win32.HANDLE,
	lock:     win32.SRWLOCK,
}

_init :: proc "contextless" (ctx: ^Context) -> (ok: bool) {
	defer if !ok { _destroy(ctx) }
	ctx.impl.hProcess = win32.GetCurrentProcess()
	win32.SymInitialize(ctx.impl.hProcess, nil, true) or_return
	win32.SymSetOptions(win32.SYMOPT_LOAD_LINES)
	return true
}

_destroy :: proc "contextless" (ctx: ^Context) -> bool {
	if ctx != nil {
		win32.SymCleanup(ctx.impl.hProcess)
	}
	return true
}

_frames :: proc(ctx: ^Context, skip: uint, allocator: runtime.Allocator) -> []Frame {
	buffer: [MAX_FRAMES]rawptr
	frame_count := win32.RtlCaptureStackBackTrace(u32(skip) + 2, len(buffer), &buffer[0], nil)
	frames := make([]Frame, frame_count, allocator)
	for &f, i in frames {
		// NOTE: Return address is one after the call instruction so subtract a byte to
		// end up back inside the call instruction which is needed for SymFromAddr.
		f = Frame(buffer[i]) - 1
	}
	return frames
}


_resolve :: proc(ctx: ^Context, frame: Frame, allocator: runtime.Allocator) -> (result: runtime.Source_Code_Location) {
	intrinsics.atomic_store(&ctx.in_resolve, true)
	defer intrinsics.atomic_store(&ctx.in_resolve, false)

	// NOTE(bill): Dbghelp is not thread-safe
	win32.AcquireSRWLockExclusive(&ctx.impl.lock)
	defer win32.ReleaseSRWLockExclusive(&ctx.impl.lock)

	data: [size_of(win32.SYMBOL_INFOW) + size_of([256]win32.WCHAR)]byte
	symbol := (^win32.SYMBOL_INFOW)(&data[0])
	symbol.SizeOfStruct = size_of(symbol)
	symbol.MaxNameLen = 255
	if win32.SymFromAddrW(ctx.impl.hProcess, win32.DWORD64(frame), &{}, symbol) {
		result.procedure, _ = win32.wstring_to_utf8(&symbol.Name[0], -1, allocator)
	} else {
		result.procedure = fmt.aprintf("(procedure: 0x%x)", frame, allocator=allocator)
	}

	line: win32.IMAGEHLP_LINE64
	line.SizeOfStruct = size_of(line)
	if win32.SymGetLineFromAddrW64(ctx.impl.hProcess, win32.DWORD64(frame), &{}, &line) {
		result.file_path, _ = win32.wstring_to_utf8(line.FileName, -1, allocator)
		result.line = i32(line.LineNumber)
	}

	return result
}