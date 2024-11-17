#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "base:intrinsics"

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// signal.h - signals

foreign lib {
	/*
	Raise a signal to the process/group specified by pid.

	If sig is 0, this function can be used to check if the pid is just checked for validity.

	If pid is -1, the signal is sent to all processes that the current process has permission to send.

	If pid is negative (not -1), the signal is sent to all processes in the group identifier by the
	absolute value.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/kill.html ]]
	*/
	kill :: proc(pid: pid_t, sig: Signal) -> result ---

	/*
	Shorthand for `kill(-pgrp, sig)` which will kill all processes in the given process group.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/killpg.html ]]
	*/
	killpg :: proc(pgrp: pid_t, sig: Signal) -> result ---

	/*
	Writes a language-dependent message to stderror.

	Example:
		posix.psignal(.SIGSEGV, "that didn't go well")

	Possible Output:
		that didn't go well: Segmentation fault

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/psignal.html ]]
	*/
	psignal :: proc(signum: Signal, message: cstring) ---

	/*
	Send a signal to a thread.
	
	As with kill, if sig is 0, only validation (of the pthread_t given) is done and no signal is sent.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_kill.html ]]
	*/
	pthread_kill :: proc(thread: pthread_t, sig: Signal) -> Errno ---

	/*
	Examine and change blocked signals.

	Equivalent to sigprocmask(), without the restriction that the call be made in a single-threaded process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_sigmask.html ]]
	*/
	pthread_sigmask :: proc(how: Sig, set: ^sigset_t, oset: ^sigset_t) -> Errno ---

	/*
	Examine and change blocked signals in a single-threaded process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_sigmask.html ]]
	*/
	@(link_name=LSIGPROCMASK)
	sigprocmask :: proc(how: Sig, set: ^sigset_t, oldset: ^sigset_t) -> result ---

	/*
	Examine and change a signal action.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigaction.html ]]
	*/
	@(link_name=LSIGACTION)
	sigaction :: proc(sig: Signal, act: ^sigaction_t, oact: ^sigaction_t) -> result ---

	@(link_name=LSIGADDSET)
	sigaddset :: proc(set: ^sigset_t, signo: Signal) -> result ---
	@(link_name=LSIGDELSET)
	sigdelset :: proc(^sigset_t, Signal) -> c.int ---
	@(link_name=LSIGEMPTYSET)
	sigemptyset :: proc(^sigset_t) -> c.int ---
	@(link_name=LSIGFILLSET)
	sigfillset :: proc(^sigset_t) -> c.int ---

	/*
	Set and get the signal alternate stack context.

	Example:
		sigstk := posix.stack_t {
			ss_sp    = make([^]byte, posix.SIGSTKSZ) or_else panic("allocation failure"),
			ss_size  = posix.SIGSTKSZ,
			ss_flags = {},
		}
		if posix.sigaltstack(&sigstk, nil) != .OK {
			fmt.panicf("sigaltstack failure: %v", posix.strerror(posix.errno()))
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigaltstack.html ]]
	*/
	@(link_name=LSIGALTSTACK)
	sigaltstack :: proc(ss: ^stack_t, oss: ^stack_t) -> result ---

	/*
	Adds sig to the signal mask of the calling process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sighold.html ]]
	*/
	sighold :: proc(sig: Signal) -> result ---

	/*
	Sets the disposition of sig to SIG_IGN.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sighold.html ]]
	*/
	sigignore :: proc(sig: Signal) -> result ---

	/*
	Removes sig from the signal mask of the calling process and suspend the calling process until 
	a signal is received.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sighold.html ]]
	*/
	sigpause :: proc(sig: Signal) -> result ---

	/*
	Removes sig from the signal mask of the calling process.

	Returns: always -1.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sighold.html ]]
	*/
	sigrelse :: proc(sig: Signal) -> result ---

	/*
	Changes the restart behavior when a function is interrupted by the specified signal.

	If flag is true, SA_RESTART is removed, added otherwise.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/siginterrupt.html ]]
	*/
	siginterrupt :: proc(sig: Signal, flag: b32) -> result ---

	/*
	Test for a signal in a signal set.

	Returns: 1 if it is a member, 0 if not, -1 (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigismember.html ]]
	*/
	@(link_name=LSIGISMEMBER)
	sigismember :: proc(set: ^sigset_t, signo: Signal) -> c.int ---

	/*
	Stores the set of signals that are blocked from delivery to the calling thread and that are pending
	on the process or the calling thread.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigpending.html ]]
	*/
	@(link_name=LSIGPENDING)
	sigpending :: proc(set: ^sigset_t) -> result --- 

	/*
	Wait for one of the given signals.

	Returns: always -1

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigsuspend.html ]]
	*/
	@(link_name=LSIGSUSPEND)
	sigsuspend :: proc(sigmask: ^sigset_t) -> result ---

	/*
	Wait for queued signals.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sigwait.html ]]
	*/
	sigwait :: proc(set: ^sigset_t, sig: ^Signal) -> Errno ---

	/* NOTE: unimplemented on darwin.

	void   psiginfo(const siginfo_t *, const char *);
	int    sigqueue(pid_t, int, union sigval);
	void (*sigset(int, void (*)(int)))(int);
	int    sigsuspend(const sigset_t *);
	int    sigtimedwait(const sigset_t *restrict, siginfo_t *restrict,
	           const struct timespec *restrict);
	int    sigwaitinfo(const sigset_t *restrict, siginfo_t *restrict);
	*/
}

sigval :: struct #raw_union {
	sigval_int: c.int,  /* [PSX] integer signal value */
	sigval_ptr: rawptr, /* [PSX] pointer signal value */
}

ILL_Code :: enum c.int {
	// Illegal opcode.
	ILLOPC = ILL_ILLOPC,
	// Illegal operand.
	ILLOPN = ILL_ILLOPN,
	// Illegal addressing mode.
	ILLADR = ILL_ILLADR,
	// Illegal trap.
	ILLTRP = ILL_ILLTRP,
	// Priviledged opcode.
	PRVOPC = ILL_PRVOPC,
	// Priviledged register.
	PRVREG = ILL_PRVREG,
	// Coprocessor error.
	COPROC = ILL_COPROC,
	// Internal stack error.
	BADSTK = ILL_BADSTK,
}

FPE_Code :: enum c.int {
	// Integer divide by zero.
	INTDIV = FPE_INTDIV,
	// Integer overflow.
	INTOVF = FPE_INTOVF,
	// Floating-point divide by zero.
	FLTDIV = FPE_FLTDIV,
	// Floating-point overflow.
	FLTOVF = FPE_FLTOVF,
	// Floating-point underflow.
	FLTUND = FPE_FLTUND,
	// Floating-point inexact result.
	FLTRES = FPE_FLTRES,
	// Invalid floating-point operation.
	FLTINV = FPE_FLTINV,
	// Subscript out of range.
	FLTSUB = FPE_FLTSUB,
}

SEGV_Code :: enum c.int {
	// Address not mapped to object.
	MAPERR = SEGV_MAPERR,
	// Invalid permissions for mapped object.
	ACCERR = SEGV_ACCERR,
}

BUS_Code :: enum c.int {
	// Invalid address alignment.
	ADRALN = BUS_ADRALN,
	// Nonexistent physical address.
	ADRERR = BUS_ADRERR,
	// Object-specific hardware error.
	OBJERR = BUS_OBJERR,
}

TRAP_Code :: enum c.int {
	// Process breakpoint.
	BRKPT = TRAP_BRKPT,
	// Process trace trap.
	TRACE = TRAP_TRACE,
}

CLD_Code :: enum c.int {
	// Child has exited..
	EXITED    = CLD_EXITED,
	// Child has terminated abnormally and did not create a core file.
	KILLED    = CLD_KILLED,
	// Child has terminated abnormally and created a core file.
	DUMPED    = CLD_DUMPED,
	// Traced child trapped.
	TRAPPED   = CLD_TRAPPED,
	// Child has stopped.
	STOPPED   = CLD_STOPPED,
	// Stopped child has continued.
	CONTINUED = CLD_CONTINUED,
}

POLL_Code :: enum c.int {
	// Data input is available.
	IN  = POLL_IN,
	// Output buffers available.
	OUT = POLL_OUT,
	// Input message available.
	MSG = POLL_MSG,
	// I/O error.
	ERR = POLL_ERR,
	// High priority input available.
	PRI = POLL_PRI,
	// Device disconnected.
	HUP = POLL_HUP,
}

Any_Code :: enum c.int {
	// Signal sent by kill().
	USER    = SI_USER,
	// Signal sent by sigqueue().
	QUEUE   = SI_QUEUE,
	// Signal generated by expiration of a timer set by timer_settime().
	TIMER   = SI_TIMER,
	// Signal generated by completion of an asynchronous I/O request.
	ASYNCIO = SI_ASYNCIO,
	// Signal generated by arrival of a message on an empty message queue.
	MESGQ   = SI_MESGQ,
}

SA_Flags_Bits :: enum c.int {
	// Do not generate SIGCHLD when children stop or stopped children continue.
	NOCLDSTOP  = log2(SA_NOCLDSTOP),
	// Cause signal delivery to occur on an alternate stack.
	ONSTACK    = log2(SA_ONSTACK),
	// Cause signal disposition to be set to SIG_DFL on entry to signal handlers.
	RESETHAND  = log2(SA_RESETHAND),
	// Cause certain functions to become restartable.
	RESTART    = log2(SA_RESTART),
	// Cause extra information to be passed to signal handlers at the time of receipt of a signal.
	SIGINFO    = log2(SA_SIGINFO),
	// Cause implementation not to create zombie processes or status information on child termination.
	NOCLDWAIT  = log2(SA_NOCLDWAIT),
	// Cause signal not to be automatically blocked on entry to signal handler.
	SA_NODEFER = log2(SA_NODEFER),
}
SA_Flags :: bit_set[SA_Flags_Bits; c.int]

SS_Flag_Bits :: enum c.int {
	// Process is executing on an alternate signal stack.
	ONSTACK = log2(SS_ONSTACK),
	// Alternate signal stack is disabled.
	DISABLE = log2(SS_DISABLE),
}
SS_Flags :: bit_set[SS_Flag_Bits; c.int]

Sig :: enum c.int {
	// Resulting set is the union of the current set and the signal set and the complement of 
	// the signal set pointed to by the argument.
	BLOCK   = SIG_BLOCK,
	// Resulting set is the intersection of the current set and the complement of the signal set
	// pointed to by the argument.
	UNBLOCK = SIG_UNBLOCK,
	// Resulting set is the signal set pointed to by the argument.
	SETMASK = SIG_SETMASK,
}

when ODIN_OS == .NetBSD {
	@(private) LSIGPROCMASK :: "__sigprocmask14"
	@(private) LSIGACTION   :: "__sigaction_siginfo"
	@(private) LSIGADDSET   :: "__sigaddset14"
	@(private) LSIGDELSET   :: "__sigdelset14"
	@(private) LSIGEMPTYSET :: "__sigemptyset14"
	@(private) LSIGFILLSET  :: "__sigfillset14"
	@(private) LSIGALTSTACK :: "__sigaltstack14"
	@(private) LSIGISMEMBER :: "__sigismember14"
	@(private) LSIGPENDING  :: "__sigpending14"
	@(private) LSIGSUSPEND  :: "__sigsuspend14"
} else {
	@(private) LSIGPROCMASK :: "sigprocmask"
	@(private) LSIGACTION   :: "sigaction"
	@(private) LSIGADDSET   :: "sigaddset"
	@(private) LSIGDELSET   :: "sigdelset"
	@(private) LSIGEMPTYSET :: "sigemptyset"
	@(private) LSIGFILLSET  :: "sigfillset"
	@(private) LSIGALTSTACK :: "sigaltstack"
	@(private) LSIGISMEMBER :: "sigismember"
	@(private) LSIGPENDING  :: "sigpending"
	@(private) LSIGSUSPEND  :: "sigsuspend"
}

when ODIN_OS == .Darwin {

	// Request that signal be held
	SIG_HOLD :: rawptr(uintptr(5))

	uid_t :: distinct c.uint32_t
	sigset_t :: distinct c.uint32_t

	SIGHUP    :: 1
	SIGQUIT   :: 3
	SIGTRAP   :: 5
	SIGPOLL   :: 7
	SIGKILL   :: 9
	SIGBUS    :: 10
	SIGSYS    :: 12
	SIGPIPE   :: 13
	SIGALRM   :: 14
	SIGURG    :: 16
	SIGCONT   :: 19
	SIGSTOP   :: 17
	SIGTSTP   :: 18
	SIGCHLD   :: 20
	SIGTTIN   :: 21
	SIGTTOU   :: 22
	SIGXCPU   :: 24
	SIGXFSZ   :: 25
	SIGVTALRM :: 26
	SIGPROF   :: 27
	SIGUSR1   :: 30
	SIGUSR2   :: 31

	// NOTE: this is actually defined as `sigaction`, but due to the function with the same name
	// `_t` has been added.

	sigaction_t :: struct {
		using _: struct #raw_union {
			sa_handler:   proc "c" (Signal),                     /* [PSX] signal-catching function or one of the SIG_IGN or SIG_DFL */
			sa_sigaction: proc "c" (Signal, ^siginfo_t, rawptr), /* [PSX] signal-catching function */
		},
		sa_mask:  sigset_t, /* [PSX] set of signals to be blocked during execution of the signal handling function */
		sa_flags: SA_Flags, /* [PSX] special flags */
	}

	SIG_BLOCK   :: 1
	SIG_UNBLOCK :: 2
	SIG_SETMASK :: 3

	SA_NOCLDSTOP :: 0x0008
	SA_ONSTACK   :: 0x0001
	SA_RESETHAND :: 0x0004
	SA_RESTART   :: 0x0002
	SA_SIGINFO   :: 0x0040
	SA_NOCLDWAIT :: 0x0020
	SA_NODEFER   :: 0x0010

	SS_ONSTACK :: 0x0001
	SS_DISABLE :: 0x0004

	MINSIGSTKSZ :: 32768
	SIGSTKSZ    :: 131072

	stack_t :: struct {
		ss_sp:    rawptr,   /* [PSX] stack base or pointer */
		ss_size:  c.size_t, /* [PSX] stack size */
		ss_flags: SS_Flags, /* [PSX] flags */
	}

	siginfo_t :: struct {
		si_signo:  Signal, /* [PSX] signal number */
		si_errno:  Errno,  /* [PSX] errno value associated with this signal */
		si_code: struct #raw_union { /* [PSX] specific more detailed codes per signal */
			ill:  ILL_Code,
			fpe:  FPE_Code,
			segv: SEGV_Code,
			bus:  BUS_Code,
			trap: TRAP_Code,
			chld: CLD_Code,
			poll: POLL_Code,
			any:  Any_Code,
		},
		si_pid:    pid_t,      /* [PSX] sending process ID */
		si_uid:    uid_t,      /* [PSX] real user ID of sending process */
		si_status: c.int,      /* [PSX] exit value or signal */
		si_addr:   rawptr,     /* [PSX] address of faulting instruction */
		si_value:  sigval,     /* [PSX] signal value */
		si_band:   c.long,     /* [PSX] band event for SIGPOLL */
		__pad:     [7]c.ulong,
	}

	ILL_ILLOPC :: 1
	ILL_ILLOPN :: 4
	ILL_ILLADR :: 5
	ILL_ILLTRP :: 2
	ILL_PRVOPC :: 3
	ILL_PRVREG :: 6
	ILL_COPROC :: 7
	ILL_BADSTK :: 8

	FPE_INTDIV :: 7
	FPE_INTOVF :: 8
	FPE_FLTDIV :: 1
	FPE_FLTOVF :: 2
	FPE_FLTUND :: 3
	FPE_FLTRES :: 4
	FPE_FLTINV :: 5
	FPE_FLTSUB :: 6

	SEGV_MAPERR :: 1
	SEGV_ACCERR :: 2

	BUS_ADRALN :: 1
	BUS_ADRERR :: 2
	BUS_OBJERR :: 3

	TRAP_BRKPT :: 1
	TRAP_TRACE :: 2

	CLD_EXITED    :: 1
	CLD_KILLED    :: 2
	CLD_DUMPED    :: 3
	CLD_TRAPPED   :: 4
	CLD_STOPPED   :: 5
	CLD_CONTINUED :: 6

	POLL_IN  :: 1
	POLL_OUT :: 2
	POLL_MSG :: 3
	POLL_ERR :: 4
	POLL_PRI :: 5
	POLL_HUP :: 6

	SI_USER    :: 0x10001
	SI_QUEUE   :: 0x10002
	SI_TIMER   :: 0x10003
	SI_ASYNCIO :: 0x10004
	SI_MESGQ   :: 0x10005

} else when ODIN_OS == .FreeBSD {

	// Request that signal be held
	SIG_HOLD :: rawptr(uintptr(3))

	uid_t :: distinct c.uint32_t

	sigset_t :: struct {
		__bits: [4]c.uint32_t,
	}

	SIGHUP    :: 1
	SIGQUIT   :: 3
	SIGTRAP   :: 5
	SIGPOLL   :: 7
	SIGKILL   :: 9
	SIGBUS    :: 10
	SIGSYS    :: 12
	SIGPIPE   :: 13
	SIGALRM   :: 14
	SIGURG    :: 16
	SIGCONT   :: 19
	SIGSTOP   :: 17
	SIGTSTP   :: 18
	SIGCHLD   :: 20
	SIGTTIN   :: 21
	SIGTTOU   :: 22
	SIGXCPU   :: 24
	SIGXFSZ   :: 25
	SIGVTALRM :: 26
	SIGPROF   :: 27
	SIGUSR1   :: 30
	SIGUSR2   :: 31

	// NOTE: this is actually defined as `sigaction`, but due to the function with the same name
	// `_t` has been added.

	sigaction_t :: struct {
		using _: struct #raw_union {
			sa_handler:   proc "c" (Signal),                     /* [PSX] signal-catching function or one of the SIG_IGN or SIG_DFL */
			sa_sigaction: proc "c" (Signal, ^siginfo_t, rawptr), /* [PSX] signal-catching function */
		},
		sa_flags: SA_Flags, /* [PSX] special flags */
		sa_mask:  sigset_t, /* [PSX] set of signals to be blocked during execution of the signal handling function */
	}

	SIG_BLOCK   :: 1
	SIG_UNBLOCK :: 2
	SIG_SETMASK :: 3

	SA_NOCLDSTOP :: 0x0008
	SA_ONSTACK   :: 0x0001
	SA_RESETHAND :: 0x0004
	SA_RESTART   :: 0x0002
	SA_SIGINFO   :: 0x0040
	SA_NOCLDWAIT :: 0x0020
	SA_NODEFER   :: 0x0010

	SS_ONSTACK :: 0x0001
	SS_DISABLE :: 0x0004

	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm32 {
		MINSIGSTKSZ :: 1024 * 4
	} else when ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 {
		MINSIGSTKSZ :: 512 * 4
	}

	SIGSTKSZ :: MINSIGSTKSZ + 32768

	stack_t :: struct {
		ss_sp:    rawptr,   /* [PSX] stack base or pointer */
		ss_size:  c.size_t, /* [PSX] stack size */
		ss_flags: SS_Flags, /* [PSX] flags */
	}

	siginfo_t :: struct {
		si_signo:  Signal, /* [PSX] signal number */
		si_errno:  Errno,  /* [PSX] errno value associated with this signal */
		si_code: struct #raw_union { /* [PSX] specific more detailed codes per signal */
			ill:  ILL_Code,
			fpe:  FPE_Code,
			segv: SEGV_Code,
			bus:  BUS_Code,
			trap: TRAP_Code,
			chld: CLD_Code,
			poll: POLL_Code,
			any:  Any_Code,
		},
		si_pid:    pid_t,      /* [PSX] sending process ID */
		si_uid:    uid_t,      /* [PSX] real user ID of sending process */
		si_status: c.int,      /* [PSX] exit value or signal */
		si_addr:   rawptr,     /* [PSX] address of faulting instruction */
		si_value:  sigval,     /* [PSX] signal value */
		using _reason: struct #raw_union {
			_fault: struct {
				_trapno: c.int, /* machine specific trap code */
			},
			_timer: struct {
				_timerid: c.int,
				_overrun: c.int,
			},
			_mesgq: struct {
				_mqd: c.int,
			},
			using _poll: struct {
				si_band: c.long, /* [PSX] band event for SIGPOLL */
			},
			_capsicum: struct {
				_syscall: c.int, /* syscall number for signals delivered as a result of system calls denied by capsicum */
			},
			__spare__: struct {
				__spare1__: c.long,
				__spare2__: [7]c.int,
			},
		},
	}

	ILL_ILLOPC :: 1
	ILL_ILLOPN :: 2
	ILL_ILLADR :: 3
	ILL_ILLTRP :: 4
	ILL_PRVOPC :: 5
	ILL_PRVREG :: 6
	ILL_COPROC :: 7
	ILL_BADSTK :: 8

	FPE_INTDIV :: 2
	FPE_INTOVF :: 1
	FPE_FLTDIV :: 3
	FPE_FLTOVF :: 4
	FPE_FLTUND :: 5
	FPE_FLTRES :: 6
	FPE_FLTINV :: 7
	FPE_FLTSUB :: 8

	SEGV_MAPERR :: 1
	SEGV_ACCERR :: 2

	BUS_ADRALN :: 1
	BUS_ADRERR :: 2
	BUS_OBJERR :: 3

	TRAP_BRKPT :: 1
	TRAP_TRACE :: 2

	CLD_EXITED    :: 1
	CLD_KILLED    :: 2
	CLD_DUMPED    :: 3
	CLD_TRAPPED   :: 4
	CLD_STOPPED   :: 5
	CLD_CONTINUED :: 6

	POLL_IN  :: 1
	POLL_OUT :: 2
	POLL_MSG :: 3
	POLL_ERR :: 4
	POLL_PRI :: 5
	POLL_HUP :: 6

	SI_USER    :: 0x10001
	SI_QUEUE   :: 0x10002
	SI_TIMER   :: 0x10003
	SI_ASYNCIO :: 0x10004
	SI_MESGQ   :: 0x10005

} else when ODIN_OS == .NetBSD {

	// Request that signal be held
	SIG_HOLD :: rawptr(uintptr(3))

	uid_t :: distinct c.uint32_t
	sigset_t :: struct {
		__bits: [4]c.uint32_t,
	}

	SIGHUP    :: 1
	SIGQUIT   :: 3
	SIGTRAP   :: 5
	SIGPOLL   :: 7
	SIGKILL   :: 9
	SIGBUS    :: 10
	SIGSYS    :: 12
	SIGPIPE   :: 13
	SIGALRM   :: 14
	SIGURG    :: 16
	SIGCONT   :: 19
	SIGSTOP   :: 17
	SIGTSTP   :: 18
	SIGCHLD   :: 20
	SIGTTIN   :: 21
	SIGTTOU   :: 22
	SIGXCPU   :: 24
	SIGXFSZ   :: 25
	SIGVTALRM :: 26
	SIGPROF   :: 27
	SIGUSR1   :: 30
	SIGUSR2   :: 31

	// NOTE: this is actually defined as `sigaction`, but due to the function with the same name
	// `_t` has been added.

	sigaction_t :: struct {
		using _: struct #raw_union {
			sa_handler:   proc "c" (Signal),                     /* [PSX] signal-catching function or one of the SIG_IGN or SIG_DFL */
			sa_sigaction: proc "c" (Signal, ^siginfo_t, rawptr), /* [PSX] signal-catching function */
		},
		sa_mask:  sigset_t, /* [PSX] set of signals to be blocked during execution of the signal handling function */
		sa_flags: SA_Flags, /* [PSX] special flags */
	}

	SIG_BLOCK   :: 1
	SIG_UNBLOCK :: 2
	SIG_SETMASK :: 3

	SA_NOCLDSTOP :: 0x0008
	SA_ONSTACK   :: 0x0001
	SA_RESETHAND :: 0x0004
	SA_RESTART   :: 0x0002
	SA_SIGINFO   :: 0x0040
	SA_NOCLDWAIT :: 0x0020
	SA_NODEFER   :: 0x0010

	SS_ONSTACK :: 0x0001
	SS_DISABLE :: 0x0004

	MINSIGSTKSZ :: 8192
	SIGSTKSZ    :: MINSIGSTKSZ + 32768

	stack_t :: struct {
		ss_sp:    rawptr,   /* [PSX] stack base or pointer */
		ss_size:  c.size_t, /* [PSX] stack size */
		ss_flags: SS_Flags, /* [PSX] flags */
	}

	@(private)
	lwpid_t :: c.int32_t

	siginfo_t :: struct #raw_union {
		si_pad: [128]byte,
		using _info: struct {
			si_signo: Signal, /* [PSX] signal number */
			si_code: struct #raw_union { /* [PSX] specific more detailed codes per signal */
				ill:  ILL_Code,
				fpe:  FPE_Code,
				segv: SEGV_Code,
				bus:  BUS_Code,
				trap: TRAP_Code,
				chld: CLD_Code,
				poll: POLL_Code,
				any:  Any_Code,
			},
			si_errno: Errno,  /* [PSX] errno value associated with this signal */
			// #ifdef _LP64
			/* In _LP64 the union starts on an 8-byte boundary. */
			_pad: c.int,
			// #endif
			using _reason: struct #raw_union {
				using _rt: struct {
					_pid:     pid_t,
					_uid:     uid_t,
					si_value: sigval,   /* [PSX] signal value */
				},
				using _child: struct {
					si_pid:    pid_t,   /* [PSX] sending process ID */
					si_uid:    uid_t,   /* [PSX] real user ID of sending process */
					si_status: c.int,   /* [PSX] exit value or signal */
					_utime:    clock_t,
					_stime:    clock_t,
				},
				using _fault: struct {
					si_addr: rawptr, /* [PSX] address of faulting instruction */
					_trap:   c.int,
					_trap2:  c.int,
					_trap3:  c.int,
				},
				using _poll: struct {
					si_band: c.long, /* [PSX] band event for SIGPOLL */
					_fd:     FD,
				},
				_syscall: struct {
					_sysnum:  c.int,
					_retval: [2]c.int,
					_error:   c.int,
					_args:   [8]c.uint64_t,
				},
				_ptrace_state: struct {
					_pe_report_event: c.int,
					_option: struct #raw_union {
						_pe_other_pid: pid_t,
						_pe_lwp:       lwpid_t,
					},
				},
			},
		},
	}

	ILL_ILLOPC :: 1
	ILL_ILLOPN :: 2
	ILL_ILLADR :: 3
	ILL_ILLTRP :: 4
	ILL_PRVOPC :: 5
	ILL_PRVREG :: 6
	ILL_COPROC :: 7
	ILL_BADSTK :: 8

	FPE_INTDIV :: 1
	FPE_INTOVF :: 2
	FPE_FLTDIV :: 3
	FPE_FLTOVF :: 4
	FPE_FLTUND :: 5
	FPE_FLTRES :: 6
	FPE_FLTINV :: 7
	FPE_FLTSUB :: 8

	SEGV_MAPERR :: 1
	SEGV_ACCERR :: 2

	BUS_ADRALN :: 1
	BUS_ADRERR :: 2
	BUS_OBJERR :: 3

	TRAP_BRKPT :: 1
	TRAP_TRACE :: 2

	CLD_EXITED    :: 1
	CLD_KILLED    :: 2
	CLD_DUMPED    :: 3
	CLD_TRAPPED   :: 4
	CLD_STOPPED   :: 5
	CLD_CONTINUED :: 6

	POLL_IN  :: 1
	POLL_OUT :: 2
	POLL_MSG :: 3
	POLL_ERR :: 4
	POLL_PRI :: 5
	POLL_HUP :: 6

	SI_USER    ::  0
	SI_QUEUE   :: -1
	SI_TIMER   :: -2
	SI_ASYNCIO :: -3
	SI_MESGQ   :: -4

} else when ODIN_OS == .OpenBSD {

	// Request that signal be held
	SIG_HOLD :: rawptr(uintptr(3))

	uid_t :: distinct c.uint32_t
	sigset_t :: distinct c.uint32_t

	SIGHUP    :: 1
	SIGQUIT   :: 3
	SIGTRAP   :: 5
	SIGPOLL   :: 7
	SIGKILL   :: 9
	SIGBUS    :: 10
	SIGSYS    :: 12
	SIGPIPE   :: 13
	SIGALRM   :: 14
	SIGURG    :: 16
	SIGCONT   :: 19
	SIGSTOP   :: 17
	SIGTSTP   :: 18
	SIGCHLD   :: 20
	SIGTTIN   :: 21
	SIGTTOU   :: 22
	SIGXCPU   :: 24
	SIGXFSZ   :: 25
	SIGVTALRM :: 26
	SIGPROF   :: 27
	SIGUSR1   :: 30
	SIGUSR2   :: 31

	// NOTE: this is actually defined as `sigaction`, but due to the function with the same name
	// `_t` has been added.

	sigaction_t :: struct {
		using _: struct #raw_union {
			sa_handler:   proc "c" (Signal),                     /* [PSX] signal-catching function or one of the SIG_IGN or SIG_DFL */
			sa_sigaction: proc "c" (Signal, ^siginfo_t, rawptr), /* [PSX] signal-catching function */
		},
		sa_mask:  sigset_t, /* [PSX] set of signals to be blocked during execution of the signal handling function */
		sa_flags: SA_Flags, /* [PSX] special flags */
	}

	SIG_BLOCK   :: 1
	SIG_UNBLOCK :: 2
	SIG_SETMASK :: 3

	SA_NOCLDSTOP :: 0x0008
	SA_ONSTACK   :: 0x0001
	SA_RESETHAND :: 0x0004
	SA_RESTART   :: 0x0002
	SA_SIGINFO   :: 0x0040
	SA_NOCLDWAIT :: 0x0020
	SA_NODEFER   :: 0x0010

	SS_ONSTACK :: 0x0001
	SS_DISABLE :: 0x0004

	MINSIGSTKSZ :: 3 << 12
	SIGSTKSZ    :: MINSIGSTKSZ + (1 << 12) * 4

	stack_t :: struct {
		ss_sp:    rawptr,   /* [PSX] stack base or pointer */
		ss_size:  c.size_t, /* [PSX] stack size */
		ss_flags: SS_Flags, /* [PSX] flags */
	}

	SI_MAXSZ :: 128
	SI_PAD   :: (SI_MAXSZ / size_of(c.int)) - 3

	siginfo_t :: struct {
		si_signo: Signal, /* [PSX] signal number */
		si_code: struct #raw_union { /* [PSX] specific more detailed codes per signal */
			ill:  ILL_Code,
			fpe:  FPE_Code,
			segv: SEGV_Code,
			bus:  BUS_Code,
			trap: TRAP_Code,
			chld: CLD_Code,
			poll: POLL_Code,
			any:  Any_Code,
		},
		si_errno: Errno,  /* [PSX] errno value associated with this signal */
		using _data: struct #raw_union {
			_pad: [SI_PAD]c.int,
			using _proc: struct {
				si_pid: pid_t,   /* [PSX] sending process ID */
				si_uid: uid_t,   /* [PSX] real user ID of sending process */
				using _pdata: struct #raw_union {
					using _kill: struct {
						si_value: sigval,
					},
					using _cld: struct {
						_utime:  clock_t,
						_stime:  clock_t,
						si_status: c.int,
					},
				},
			},
			using _fault: struct {
				si_addr: rawptr,
				_trapno: c.int,
			},
			using _file: struct {
				_fd: FD,
				si_band: c.long, /* [PSX] band event for SIGPOLL */
			},
		},
	}

	ILL_ILLOPC :: 1
	ILL_ILLOPN :: 2
	ILL_ILLADR :: 3
	ILL_ILLTRP :: 4
	ILL_PRVOPC :: 5
	ILL_PRVREG :: 6
	ILL_COPROC :: 7
	ILL_BADSTK :: 8

	FPE_INTDIV :: 1
	FPE_INTOVF :: 2
	FPE_FLTDIV :: 3
	FPE_FLTOVF :: 4
	FPE_FLTUND :: 5
	FPE_FLTRES :: 6
	FPE_FLTINV :: 7
	FPE_FLTSUB :: 8

	SEGV_MAPERR :: 1
	SEGV_ACCERR :: 2

	BUS_ADRALN :: 1
	BUS_ADRERR :: 2
	BUS_OBJERR :: 3

	TRAP_BRKPT :: 1
	TRAP_TRACE :: 2

	CLD_EXITED    :: 1
	CLD_KILLED    :: 2
	CLD_DUMPED    :: 3
	CLD_TRAPPED   :: 4
	CLD_STOPPED   :: 5
	CLD_CONTINUED :: 6

	POLL_IN  :: 1
	POLL_OUT :: 2
	POLL_MSG :: 3
	POLL_ERR :: 4
	POLL_PRI :: 5
	POLL_HUP :: 6

	SI_USER    ::  0
	SI_QUEUE   :: -2
	SI_TIMER   :: -3
	SI_ASYNCIO :: -4 // NOTE: not implemented
	SI_MESGQ   :: -5 // NOTE: not implemented

} else when ODIN_OS == .Linux {

	// Request that signal be held
	SIG_HOLD :: rawptr(uintptr(2))

	uid_t :: distinct c.uint32_t
	sigset_t :: struct {
		__val: [1024/(8 * size_of(c.ulong))]c.ulong,
	}

	SIGHUP    :: 1
	SIGQUIT   :: 3
	SIGTRAP   :: 5
	SIGBUS    :: 7
	SIGKILL   :: 9
	SIGUSR1   :: 10
	SIGUSR2   :: 12
	SIGPIPE   :: 13
	SIGALRM   :: 14
	SIGCHLD   :: 17
	SIGCONT   :: 18
	SIGSTOP   :: 19
	SIGTSTP   :: 20
	SIGTTIN   :: 21
	SIGTTOU   :: 22
	SIGURG    :: 23
	SIGXCPU   :: 24
	SIGXFSZ   :: 25
	SIGVTALRM :: 26
	SIGPROF   :: 27
	SIGPOLL   :: 29
	SIGSYS    :: 31

	// NOTE: this is actually defined as `sigaction`, but due to the function with the same name
	// `_t` has been added.

	sigaction_t :: struct {
		using _: struct #raw_union {
			sa_handler:   proc "c" (Signal),                     /* [PSX] signal-catching function or one of the SIG_IGN or SIG_DFL */
			sa_sigaction: proc "c" (Signal, ^siginfo_t, rawptr), /* [PSX] signal-catching function */
		},
		sa_mask:     sigset_t, /* [PSX] set of signals to be blocked during execution of the signal handling function */
		sa_flags:    SA_Flags, /* [PSX] special flags */
		sa_restorer: proc "c" (),
	}

	SIG_BLOCK   :: 0
	SIG_UNBLOCK :: 1
	SIG_SETMASK :: 2

	SA_NOCLDSTOP :: 1
	SA_NOCLDWAIT :: 2
	SA_SIGINFO   :: 4
	SA_ONSTACK   :: 0x08000000
	SA_RESTART   :: 0x10000000
	SA_NODEFER   :: 0x40000000
	SA_RESETHAND :: 0x80000000

	SS_ONSTACK :: 1
	SS_DISABLE :: 2

	when ODIN_ARCH == .arm64 {
		MINSIGSTKSZ :: 6144
		SIGSTKSZ    :: 12288
	} else {
		MINSIGSTKSZ :: 2048
		SIGSTKSZ    :: 8192
	}

	stack_t :: struct {
		ss_sp:    rawptr,   /* [PSX] stack base or pointer */
		ss_flags: SS_Flags, /* [PSX] flags */
		ss_size:  c.size_t, /* [PSX] stack size */
	}

	@(private)
	__SI_MAX_SIZE :: 128

	when size_of(int) == 8 { 
		@(private)
		_pad0 :: struct {
			_pad0: c.int,
		}
		@(private)
		__SI_PAD_SIZE :: (__SI_MAX_SIZE / size_of(c.int)) - 4

	} else {
		@(private)
		_pad0 :: struct {}
		@(private)
		__SI_PAD_SIZE :: (__SI_MAX_SIZE / size_of(c.int)) - 3
	}

	siginfo_t :: struct #align(8) {
		si_signo:  Signal, /* [PSX] signal number */
		si_errno:  Errno,  /* [PSX] errno value associated with this signal */
		si_code: struct #raw_union { /* [PSX] specific more detailed codes per signal */
			ill:  ILL_Code,
			fpe:  FPE_Code,
			segv: SEGV_Code,
			bus:  BUS_Code,
			trap: TRAP_Code,
			chld: CLD_Code,
			poll: POLL_Code,
			any:  Any_Code,
		},
		__pad0: _pad0,
		using _sifields: struct #raw_union {
			_pad: [__SI_PAD_SIZE]c.int,

			using _: struct {
				si_pid: pid_t, /* [PSX] sending process ID */
				si_uid: uid_t, /* [PSX] real user ID of sending process */
				using _: struct #raw_union {
					si_status: c.int,  /* [PSX] exit value or signal */
					si_value:  sigval, /* [PSX] signal value */
				},
			},
			using _: struct {
				si_addr: rawptr, /* [PSX] address of faulting instruction */
			},
			using _: struct {
				si_band: c.long, /* [PSX] band event for SIGPOLL */
			},
		},
	}

	ILL_ILLOPC :: 1
	ILL_ILLOPN :: 2
	ILL_ILLADR :: 3
	ILL_ILLTRP :: 4
	ILL_PRVOPC :: 5
	ILL_PRVREG :: 6
	ILL_COPROC :: 7
	ILL_BADSTK :: 8

	FPE_INTDIV :: 1
	FPE_INTOVF :: 2
	FPE_FLTDIV :: 3
	FPE_FLTOVF :: 4
	FPE_FLTUND :: 5
	FPE_FLTRES :: 6
	FPE_FLTINV :: 7
	FPE_FLTSUB :: 8

	SEGV_MAPERR :: 1
	SEGV_ACCERR :: 2

	BUS_ADRALN :: 1
	BUS_ADRERR :: 2
	BUS_OBJERR :: 3

	TRAP_BRKPT :: 1
	TRAP_TRACE :: 2

	CLD_EXITED    :: 1
	CLD_KILLED    :: 2
	CLD_DUMPED    :: 3
	CLD_TRAPPED   :: 4
	CLD_STOPPED   :: 5
	CLD_CONTINUED :: 6

	POLL_IN  :: 1
	POLL_OUT :: 2
	POLL_MSG :: 3
	POLL_ERR :: 4
	POLL_PRI :: 5
	POLL_HUP :: 6

	SI_USER    :: 0
	SI_QUEUE   :: -1
	SI_TIMER   :: -2
	SI_MESGQ   :: -3
	SI_ASYNCIO :: -4
}
