package libc

// 7.26 Threads

thrd_start_t :: proc "c" (rawptr) -> int
tss_dtor_t   :: proc "c" (rawptr)

when ODIN_OS == .Windows {
	foreign import libc {
		"system:libucrt.lib", 
		"system:msvcprt.lib",
	}

	thrd_success        :: 0                             // _Thrd_success
	thrd_nomem          :: 1                             // _Thrd_nomem
	thrd_timedout       :: 2                             // _Thrd_timedout
	thrd_busy           :: 3                             // _Thrd_busy
	thrd_error          :: 4                             // _Thrd_error

	mtx_plain           :: 1                             // _Mtx_plain
	mtx_recursive       :: 0x100                         // _Mtx_recursive
	mtx_timed           :: 4                             // _Mtx_timed

	TSS_DTOR_ITERATIONS :: 4                             // _TSS_DTOR_ITERATIONS_IMP

	once_flag           :: distinct i8                   // _Once_flag_imp_t
	thrd_t              :: struct { _: rawptr, _: uint, } // _Thrd_t
	tss_t               :: distinct int                  // _Tss_imp_t
	cnd_t               :: distinct rawptr               // _Cnd_imp_t
	mtx_t               :: distinct rawptr               // _Mtx_imp_t

	// MSVCRT does not expose the C11 symbol names as what they are in C11
	// because they held off implementing <threads.h> and C11 support for so
	// long that people started implementing their own. To prevent symbol
	// conflict with existing customers code they had to namespace them
	// differently. Thus we need to alias the correct symbol names with Odin's
	// link_name attribute.
	@(default_calling_convention="c")
	foreign libc {
		// 7.26.2 Initialization functions
		@(link_name="_Call_once")     call_once     :: proc(flag: ^once_flag, func: proc "c" ()) ---
		// 7.26.3 Condition variable functions
		@(link_name="_Cnd_broadcast") cnd_broadcast :: proc(cond: ^cnd_t) -> int ---
		@(link_name="_Cnd_destroy")   cnd_destroy   :: proc(cond: ^cnd_t) ---
		@(link_name="_Cnd_init")      cnd_init      :: proc(cond: ^cnd_t) -> int ---
		@(link_name="_Cnd_signal")    cnd_signal    :: proc(cond: ^cnd_t) -> int ---
		@(link_name="_Cnd_timedwait") cnd_timedwait :: proc(cond: ^cnd_t, mtx: ^mtx_t, ts: ^timespec) -> int ---
		@(link_name="_Cnd_wait")      cnd_wait      :: proc(cond: ^cnd_t, mtx: ^mtx_t) -> int ---
		
		// 7.26.4 Mutex functions
		@(link_name="_Mtx_destroy")   mtx_destroy   :: proc(mtx: ^mtx_t) ---
		@(link_name="_Mtx_init")      mtx_init      :: proc(mtx: ^mtx_t, type: int) -> int ---
		@(link_name="_Mtx_lock")      mtx_lock      :: proc(mtx: ^mtx_t) -> int ---
		@(link_name="_Mtx_timedlock") mtx_timedlock :: proc(mtx: ^mtx_t, ts: ^timespec) -> int ---
		@(link_name="_Mtx_trylock")   mtx_trylock   :: proc(mtx: ^mtx_t) -> int ---
		@(link_name="_Mtx_unlock")    mtx_unlock    :: proc(mtx: ^mtx_t) -> int ---

		// 7.26.5 Thread functions
		@(link_name="_Thrd_create")   thrd_create   :: proc(thr: ^thrd_t, func: thrd_start_t, arg: rawptr) -> int ---
		@(link_name="_Thrd_current")  thrd_current  :: proc() -> thrd_t ---
		@(link_name="_Thrd_detach")   thrd_detach   :: proc(thr: thrd_t) -> int ---
		@(link_name="_Thrd_equal")    thrd_equal    :: proc(lhs, rhs: thrd_t) -> int ---
		@(link_name="_Thrd_exit")     thrd_exit     :: proc(res: int) -> ! ---
		@(link_name="_Thrd_join")     thrd_join     :: proc(thr: thrd_t, res: ^int) -> int ---
		@(link_name="_Thrd_sleep")    thrd_sleep    :: proc(duration, remaining: ^timespec) -> int ---
		@(link_name="_Thrd_yield")    thrd_yield    :: proc() ---

		// 7.26.6 Thread-specific storage functions
		@(link_name="_Tss_create")    tss_create    :: proc(key: ^tss_t, dtor: tss_dtor_t) -> int ---
		@(link_name="_Tss_delete")    tss_delete    :: proc(key: tss_t) ---
		@(link_name="_Tss_get")       tss_get       :: proc(key: tss_t) -> rawptr ---
		@(link_name="_Tss_set")       tss_set       :: proc(key: tss_t, val: rawptr) -> int ---
	}
}

// GLIBC and MUSL compatible constants and types.
when ODIN_OS == .Linux {
	foreign import libc {
		"system:c",
		"system:pthread",
	}

	thrd_success        :: 0
	thrd_busy           :: 1
	thrd_error          :: 2
	thrd_nomem          :: 3
	thrd_timedout       :: 4

	mtx_plain           :: 0
	mtx_recursive       :: 1
	mtx_timed           :: 2

	TSS_DTOR_ITERATIONS :: 4

	once_flag           :: distinct int
	thrd_t              :: distinct ulong
	tss_t               :: distinct uint
	cnd_t               :: struct #raw_union { _: [12]int, _: [12 * size_of(int) / size_of(rawptr)]rawptr, }
	mtx_t               :: struct #raw_union { _: [10 when size_of(long) == 8 else 6]int, _: [5 when size_of(long) == 8 else 6]rawptr, }

	@(default_calling_convention="c")
	foreign libc {
		// 7.26.2 Initialization functions
		call_once     :: proc(flag: ^once_flag, func: proc "c" ()) ---

		// 7.26.3 Condition variable functions
		cnd_broadcast :: proc(cond: ^cnd_t) -> int ---
		cnd_destroy   :: proc(cond: ^cnd_t) ---
		cnd_init      :: proc(cond: ^cnd_t) -> int ---
		cnd_signal    :: proc(cond: ^cnd_t) -> int ---
		cnd_timedwait :: proc(cond: ^cnd_t, mtx: ^mtx_t, ts: ^timespec) -> int ---
		cnd_wait      :: proc(cond: ^cnd_t, mtx: ^mtx_t) -> int ---
		
		// 7.26.4 Mutex functions
		mtx_destroy   :: proc(mtx: ^mtx_t) ---
		mtx_init      :: proc(mtx: ^mtx_t, type: int) -> int ---
		mtx_lock      :: proc(mtx: ^mtx_t) -> int ---
		mtx_timedlock :: proc(mtx: ^mtx_t, ts: ^timespec) -> int ---
		mtx_trylock   :: proc(mtx: ^mtx_t) -> int ---
		mtx_unlock    :: proc(mtx: ^mtx_t) -> int ---

		// 7.26.5 Thread functions
		thrd_create   :: proc(thr: ^thrd_t, func: thrd_start_t, arg: rawptr) -> int ---
		thrd_current  :: proc() -> thrd_t ---
		thrd_detach   :: proc(thr: thrd_t) -> int ---
		thrd_equal    :: proc(lhs, rhs: thrd_t) -> int ---
		thrd_exit     :: proc(res: int) -> ! ---
		thrd_join     :: proc(thr: thrd_t, res: ^int) -> int ---
		thrd_sleep    :: proc(duration, remaining: ^timespec) -> int ---
		thrd_yield    :: proc() ---

		// 7.26.6 Thread-specific storage functions
		tss_create    :: proc(key: ^tss_t, dtor: tss_dtor_t) -> int ---
		tss_delete    :: proc(key: tss_t) ---
		tss_get       :: proc(key: tss_t) -> rawptr ---
		tss_set       :: proc(key: tss_t, val: rawptr) -> int ---
	}
}


when ODIN_OS == .Darwin {
	// TODO: find out what this is meant to be!
}
