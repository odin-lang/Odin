package odin_libc

import "core:time"
import "core:thread"

Clock :: enum i32 {
	Monotonic = 1,
}

Time_Spec :: struct {
	tv_sec:  i64,
	tv_nsec: i64,
}

@(require, linkage="strong", link_name="clock_gettime")
clock_gettine :: proc "c" (clockid: Clock, tp: ^Time_Spec) -> i32 {
	switch clockid {
	case .Monotonic:
		tick := time.tick_now()
		tp.tv_sec = tick._nsec/1e9
		tp.tv_nsec = tick._nsec%1e9/1000
		return 0

	case: return -1
	}
}

@(require, linkage="strong", link_name="sched_yield")
sched_yield :: proc "c" () -> i32 {
	when thread.IS_SUPPORTED {
		context = g_ctx
		thread.yield()
	}
	return 0
}
