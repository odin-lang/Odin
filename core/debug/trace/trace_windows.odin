#+vet explicit-allocators
#+private file
package debug_trace

@require import     "base:runtime"

@require import     "core:strings"
@require import     "core:sync"
@require import win "core:sys/windows"

when !INSTRUMENTATION_MODE {

@(private="package")
_Capture_Entry :: uintptr

@(private="package")
_capture :: #force_no_inline proc(buf: Capture, skip: int) -> (n: int) {
	frame_count := win.RtlCaptureStackBackTrace(u32(skip)+2, u32(len(buf)), ([^]rawptr)(raw_data(buf)), nil)

	for &frame in buf[:frame_count] {
		// NOTE: Return address is one after the call instruction so subtract a byte to
		// end up back inside the call instruction which is needed for SymFromAddr.
		frame -= 1
	}

	return int(frame_count)
}

@(private="package")
_locations_destroy :: proc(locations: []Resolved_Location, allocator: runtime.Allocator) {
	for entry in locations {
		if entry.location.file_path != "??" && entry.location.file_path != OOM_MARKER {
			delete(entry.location.file_path, allocator)
		}
		if entry.location.procedure != "??" && entry.location.procedure != OOM_MARKER {
			delete(entry.location.procedure, allocator)
		}
	}
	delete(locations, allocator)
}

@(private="package")
_resolve :: proc(bt: Capture, allocator, temp_allocator: runtime.Allocator) -> (out: []Resolved_Location, err: runtime.Allocator_Error) {
	out = make([]Resolved_Location, len(bt), allocator) or_return

	// Debug info is needed, if we call with out-of-date debug symbols it will return out-of-date info, so better to short-circuit right away.
	when !ODIN_DEBUG {
		for &entry, i in out {
			entry.location.file_path = "??"

			builder := strings.builder_make(allocator)
			strings.write_string(&builder, "0x")
			strings.write_i64   (&builder, i64(bt[i]), 16)
			entry.location.procedure = strings.to_string(builder)
		}
		return
	}

	process := win.GetCurrentProcess()

	sync.guard(&_win32_dbghelp_mutex)

	if !win.SymInitialize(process, nil, true) {
		for &entry in out {
			entry.location.procedure = "??"
			entry.location.file_path = "??"
			entry.error = .Resolve_Aborted
		}
		return
	}
	defer win.SymCleanup(process)

	win.SymSetOptions(win.SYMOPT_LOAD_LINES|win.SYMOPT_DEFERRED_LOADS)

	data: [size_of(win.SYMBOL_INFOW) + size_of([256]win.WCHAR)]byte
	symbol := (^win.SYMBOL_INFOW)(&data[0])
	// The value of SizeOfStruct must be the size of the whole struct,
	// not just the size of the pointer
	symbol.SizeOfStruct = size_of(symbol^)
	symbol.MaxNameLen = 255

	for &entry, i in out {
		if win.SymFromAddrW(process, win.DWORD64(bt[i]), nil, symbol) {
			symbol, mem_err := win.wstring_to_utf8(cstring16(&symbol.Name[0]), int(symbol.NameLen), allocator)
			if mem_err != nil {
				entry.location.procedure = OOM_MARKER
			} else if symbol == "??" {
				delete(symbol, allocator)
				entry.location.procedure = "??"
			} else {
				entry.location.procedure = symbol
			}
		} else {
			entry.location.procedure = "??"
		}

		lineInfo: win.IMAGEHLP_LINEW64
		lineInfo.SizeOfStruct = size_of(lineInfo)
		if win.SymGetLineFromAddrW64(process, win.DWORD64(bt[i]), &{}, &lineInfo) {
			file_name, mem_err := win.wstring_to_utf8(lineInfo.FileName, len(lineInfo.FileName), allocator)
			if mem_err != nil {
				entry.location.file_path = OOM_MARKER
			} else if file_name == "??" {
				delete(file_name, allocator)
				entry.location.file_path = "??"
			} else {
				entry.location.file_path = file_name
			}
			entry.location.line = i32(lineInfo.LineNumber)
		} else {
			location := strings.builder_make(allocator)
			strings.write_string(&location, "0x")
			strings.write_i64   (&location, i64(bt[i]), 16)
			entry.location.file_path = strings.to_string(location)
		}
	}

	return
}

} // INSTRUMENTATION_MODE
