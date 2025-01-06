#+build amd64
package sys_valgrind

import "base:intrinsics"

Callgrind_Client_Request :: enum uintptr {
	Dump_Stats = 'C'<<24 | 'T'<<16,
	Zero_Stats,
	Toggle_Collect,
	Dump_Stats_At,
	Start_Instrumentation,
	Stop_Instrumentation,
}

@(require_results)
callgrind_client_request_expr :: #force_inline proc "c" (default: uintptr, request: Callgrind_Client_Request, a0, a1, a2, a3, a4: uintptr) -> uintptr {
	return intrinsics.valgrind_client_request(default, uintptr(request), a0, a1, a2, a3, a4)
}
callgrind_client_request_stmt :: #force_inline proc "c" (request: Callgrind_Client_Request, a0, a1, a2, a3, a4: uintptr) {
	_ = intrinsics.valgrind_client_request(0, uintptr(request), a0, a1, a2, a3, a4)
}

// Dump current state of cost centres, and zero them afterwards.
dump_stats :: proc "c" () {
	callgrind_client_request_stmt(.Dump_Stats, 0, 0, 0, 0, 0)
}

// Zero cost centres
zero_stats :: proc "c" () {
	callgrind_client_request_stmt(.Zero_Stats, 0, 0, 0, 0, 0)
}

// Toggles collection state.
// The collection state specifies whether the happening of events should be noted or
// if they are to be ignored. Events are noted by increment of counters in a cost centre.
toggle_collect :: proc "c" () {
	callgrind_client_request_stmt(.Toggle_Collect, 0, 0, 0, 0, 0)
}

// Dump current state of cost centres, and zero them afterwards.
// The argument is appended to a string stating the reason which triggered
// the dump. This string is written as a description field into the
// profile data dump.
dump_stats_at :: proc "c" (pos_str: rawptr) {
	callgrind_client_request_stmt(.Dump_Stats_At, uintptr(pos_str), 0, 0, 0, 0)
}

// Start full callgrind instrumentation if not already switched on.
// When cache simulation is done, it will flush the simulated cache;
// this will lead to an artificial cache warmup phase afterwards with
// cache misses which would not have happened in reality.
start_instrumentation :: proc "c" () {
	callgrind_client_request_stmt(.Start_Instrumentation, 0, 0, 0, 0, 0)
}

// Stop full callgrind instrumentation if not already switched off.
// This flushes Valgrinds translation cache, and does no additional instrumentation
// afterwards, which effectivly will run at the same speed as the "none" tool (ie. at minimal slowdown).
// Use this to bypass Callgrind aggregation for uninteresting code parts.
// To start Callgrind in this mode to ignore the setup phase, use the option "--instr-atstart=no".
stop_instrumentation :: proc "c" () {
	callgrind_client_request_stmt(.Stop_Instrumentation, 0, 0, 0, 0, 0)
}