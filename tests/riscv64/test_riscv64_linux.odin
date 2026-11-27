#+build riscv64
#+build linux
package test_riscv64

import "base:intrinsics"
import chacha_simd128 "core:crypto/_chacha20/simd128"
import "core:sys/info"
import "core:sys/linux"
import "core:testing"

@(test)
linux_cpu_features :: proc(t: ^testing.T) {
	features := info.cpu_features()
	testing.expectf(t, features >= {.I, .M, .A, .F, .D, .C}, "cpu_features() = %v", features)
	when intrinsics.has_target_feature("v") {
		testing.expectf(t, .V in features, "built with V, but cpu_features() = %v", features)
	}
	testing.expect_value(t, chacha_simd128.is_performant(), .V in features)

	pairs := [?]linux.RISCV_HWProbe{{key = .IMA_EXT_0}, {key = .BASE_BEHAVIOR}, {key = linux.RISCV_HWProbe_Key(1 << 40)}}
	err := linux.riscv_hwprobe(&pairs[0], len(pairs), 0, nil, {})
	if err == .ENOSYS {
		return
	}
	if !testing.expect_value(t, err, linux.Errno.NONE) {
		return
	}
	testing.expect_value(t, pairs[0].key, linux.RISCV_HWProbe_Key.IMA_EXT_0)
	testing.expect_value(t, pairs[1].key, linux.RISCV_HWProbe_Key.BASE_BEHAVIOR)
	testing.expect_value(t, pairs[2].key, linux.RISCV_HWProbe_Key.UNSUPPORTED)
	testing.expect_value(t, pairs[2].value.raw, 0)
	testing.expectf(t, .IMA in pairs[1].value.base_behavior, "base behavior %v", pairs[1].value.base_behavior)
	exts := pairs[0].value.ima_ext_0
	testing.expectf(t, (.FD in exts) == (features >= {.F, .D}), "hwprobe %v, auxv %v", exts, features)
	testing.expectf(t, (.C in exts) == (.C in features), "hwprobe %v, auxv %v", exts, features)
	testing.expectf(t, (.V in exts) == (.V in features), "hwprobe %v, auxv %v", exts, features)
}

@(test)
linux_basic_syscalls :: proc(t: ^testing.T) {
	name: linux.UTS_Name
	testing.expect_value(t, linux.uname(&name), linux.Errno.NONE)
	testing.expect_value(t, string(cstring(&name.machine[0])), "riscv64")

	a, a_err := linux.clock_gettime(.MONOTONIC)
	b, b_err := linux.clock_gettime(.MONOTONIC)
	testing.expect_value(t, a_err, linux.Errno.NONE)
	testing.expect_value(t, b_err, linux.Errno.NONE)
	testing.expectf(t, a.time_nsec < 1e9 && (b.time_sec > a.time_sec || b.time_sec == a.time_sec && b.time_nsec >= a.time_nsec), "%v then %v", a, b)

	buf: [64]u8
	n, r_err := linux.getrandom(buf[:], {})
	testing.expect_value(t, r_err, linux.Errno.NONE)
	testing.expect_value(t, n, len(buf))
}

@(private = "file")
Handler_Result :: struct {
	signo:   linux.Signal,
	code:    i32,
	pid:     linux.Pid,
	blocked: linux.Sig_Set,
	calls:   int,
}

@(private = "file")
handler_result: Handler_Result

@(private = "file")
sig_bit :: proc "contextless" (sig: linux.Signal) -> uint {
	return 1 << (uint(sig) - 1)
}

@(test)
linux_sigaction_mask_and_delivery :: proc(t: ^testing.T) {
	handler :: proc "c" (sig: linux.Signal, si: ^linux.Sig_Info, ctx: rawptr) {
		handler_result.signo = si.signo
		handler_result.code = si.code
		handler_result.pid = si.pid
		handler_result.calls += 1
		linux.rt_sigprocmask(.SIG_BLOCK, nil, &handler_result.blocked)
	}

	act: linux.Sig_Action
	act.sigaction = handler
	act.flags = {.SIGINFO, .RESTART}
	act.mask[0] = sig_bit(.SIGUSR2) | sig_bit(.SIGWINCH)
	old: linux.Sig_Action
	if !testing.expect_value(t, linux.rt_sigaction(.SIGUSR1, &act, &old), linux.Errno.NONE) {
		return
	}
	defer linux.rt_sigaction(.SIGUSR1, &old, nil)

	query: linux.Sig_Action
	testing.expect_value(t, linux.rt_sigaction(.SIGUSR1, nil, &query), linux.Errno.NONE)
	testing.expect_value(t, rawptr(query.sigaction), rawptr(act.sigaction))
	testing.expectf(t, query.flags >= {.SIGINFO, .RESTART}, "flags %v", query.flags)
	testing.expect_value(t, query.mask, act.mask)

	before: linux.Sig_Set
	linux.rt_sigprocmask(.SIG_BLOCK, nil, &before)
	handler_result = {}
	testing.expect_value(t, linux.tgkill(linux.getpid(), linux.gettid(), .SIGUSR1), linux.Errno.NONE)

	testing.expect_value(t, handler_result.calls, 1)
	testing.expect_value(t, handler_result.signo, linux.Signal.SIGUSR1)
	testing.expect_value(t, handler_result.code, -6)
	testing.expect_value(t, handler_result.pid, linux.getpid())
	added := sig_bit(.SIGUSR1) | sig_bit(.SIGUSR2) | sig_bit(.SIGWINCH)
	testing.expectf(t, handler_result.blocked[0] == before[0] | added, "blocked in handler %x, before %x", handler_result.blocked[0], before[0])
	after: linux.Sig_Set
	linux.rt_sigprocmask(.SIG_BLOCK, nil, &after)
	testing.expect_value(t, after, before)
}
