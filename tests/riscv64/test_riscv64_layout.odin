#+build riscv64
#+build linux
package test_riscv64

import "core:fmt"
import "core:os"
import "core:strings"
import "core:sys/linux"
import "core:testing"

SYSCALL_SOURCE :: #load("../../core/sys/linux/syscall_riscv64.odin", string)

@(test)
layout_matches_uapi_headers :: proc(t: ^testing.T) {
	dir, dir_err := os.make_directory_temp("", "odin-riscv64-layout-*", context.allocator)
	if !testing.expectf(t, dir_err == nil, "make_directory_temp: %v", dir_err) {
		return
	}
	defer delete(dir)
	defer os.remove_all(dir)

	header, want: strings.Builder
	strings.builder_init(&header)
	defer strings.builder_destroy(&header)
	strings.builder_init(&want)
	defer strings.builder_destroy(&want)

	syscall_count := 0
	source := SYSCALL_SOURCE
	for raw_line in strings.split_lines_iterator(&source) {
		line := strings.trim_space(raw_line)
		name_end := strings.index(line, " ")
		number_start := strings.index(line, ":: uintptr(")
		if !strings.has_prefix(line, "SYS_") || name_end < 0 || number_start < 0 {
			continue
		}
		name := line[4:name_end]
		number := line[number_start + len(":: uintptr("):]
		number = number[:strings.index(number, ")")]
		fmt.sbprintf(&header, "#ifdef __NR_%s\n\tK(\"SYS_%s\", __NR_%s);\n#else\n\tM(\"SYS_%s\");\n#endif\n", name, name, name, name)
		fmt.sbprintf(&want, "SYS_%s %s\n", name, number)
		syscall_count += 1
	}
	testing.expectf(t, syscall_count > 250, "only %v syscalls parsed", syscall_count)

	layout_odin(&want)

	header_path := strings.concatenate({dir, "/syscalls.h"})
	defer delete(header_path)
	exe_path := strings.concatenate({dir, "/layout"})
	defer delete(exe_path)
	include := strings.concatenate({"-I", dir})
	defer delete(include)
	if write_err := os.write_entire_file(header_path, header.buf[:]); !testing.expectf(t, write_err == nil, "write %v: %v", header_path, write_err) {
		return
	}

	compile := []string{
		"clang", "--target=riscv64-linux-gnu", "-static", "-O0", include,
		#directory + "/layout/uapi.c", #directory + "/layout/libc.c", "-o", exe_path,
	}
	if _, ok := layout_run(t, compile); !ok {
		return
	}
	got, ok := layout_run(t, {exe_path})
	if !ok {
		return
	}
	defer delete(got)

	c_values: map[string]string
	defer delete(c_values)
	got_lines := string(got)
	for line in strings.split_lines_iterator(&got_lines) {
		space := strings.index(line, " ")
		if space > 0 {
			c_values[line[:space]] = line[space + 1:]
		}
	}

	verified := 0
	want_lines := strings.to_string(want)
	for line in strings.split_lines_iterator(&want_lines) {
		space := strings.index(line, " ")
		key, value := line[:space], line[space + 1:]
		c_value, found := c_values[key]
		switch {
		case !found:
			testing.expectf(t, false, "%s: not printed by the C side", key)
		case c_value == "missing" && strings.has_prefix(key, "SYS_"):
		case:
			testing.expectf(t, c_value == value, "%s: C %s, Odin %s", key, c_value, value)
			verified += 1
		}
	}
	testing.expectf(t, verified > 450, "only %v entries verified", verified)
}

@(private = "file")
layout_run :: proc(t: ^testing.T, command: []string) -> (stdout: []byte, ok: bool) {
	state, out, errs, err := os.process_exec({command = command}, context.allocator)
	defer delete(errs)
	if !testing.expectf(t, err == nil && state.exited && state.exit_code == 0, "%v: %v, %v\n%s", command, err, state, errs) {
		delete(out)
		return nil, false
	}
	return out, true
}

@(private = "file")
layout_odin :: proc(b: ^strings.Builder) {
	S :: proc(b: ^strings.Builder, name: string, $T: typeid) {
		fmt.sbprintf(b, "%s %d %d\n", name, size_of(T), align_of(T))
	}
	Z :: proc(b: ^strings.Builder, name: string, $T: typeid) {
		fmt.sbprintf(b, "%s %d\n", name, size_of(T))
	}
	F :: proc(b: ^strings.Builder, name: string, offset: uintptr) {
		fmt.sbprintf(b, "%s %d\n", name, offset)
	}
	K :: proc(b: ^strings.Builder, name: string, value: i64) {
		fmt.sbprintf(b, "%s %d\n", name, value)
	}

	S(b, "timespec", linux.Time_Spec)
	F(b, "timespec.tv_nsec", offset_of(linux.Time_Spec, time_nsec))
	S(b, "timeval", linux.Time_Val)
	F(b, "timeval.tv_usec", offset_of(linux.Time_Val, microseconds))
	S(b, "itimerval", linux.ITimer_Val)
	F(b, "itimerval.it_value", offset_of(linux.ITimer_Val, value))
	S(b, "itimerspec", linux.ITimer_Spec)
	F(b, "itimerspec.it_value", offset_of(linux.ITimer_Spec, value))

	S(b, "stat", linux.Stat)
	F(b, "stat.st_dev", offset_of(linux.Stat, dev))
	F(b, "stat.st_ino", offset_of(linux.Stat, ino))
	F(b, "stat.st_mode", offset_of(linux.Stat, mode))
	F(b, "stat.st_nlink", offset_of(linux.Stat, nlink))
	F(b, "stat.st_uid", offset_of(linux.Stat, uid))
	F(b, "stat.st_gid", offset_of(linux.Stat, gid))
	F(b, "stat.st_rdev", offset_of(linux.Stat, rdev))
	F(b, "stat.st_size", offset_of(linux.Stat, size))
	F(b, "stat.st_blksize", offset_of(linux.Stat, blksize))
	F(b, "stat.st_blocks", offset_of(linux.Stat, blocks))
	F(b, "stat.st_atime", offset_of(linux.Stat, atime))
	F(b, "stat.st_mtime", offset_of(linux.Stat, mtime))
	F(b, "stat.st_ctime", offset_of(linux.Stat, ctime))

	S(b, "statx", linux.Statx)
	F(b, "statx.stx_blksize", offset_of(linux.Statx, blksize))
	F(b, "statx.stx_attributes", offset_of(linux.Statx, attributes))
	F(b, "statx.stx_nlink", offset_of(linux.Statx, nlink))
	F(b, "statx.stx_uid", offset_of(linux.Statx, uid))
	F(b, "statx.stx_gid", offset_of(linux.Statx, gid))
	F(b, "statx.stx_mode", offset_of(linux.Statx, mode))
	F(b, "statx.stx_ino", offset_of(linux.Statx, ino))
	F(b, "statx.stx_size", offset_of(linux.Statx, size))
	F(b, "statx.stx_blocks", offset_of(linux.Statx, blocks))
	F(b, "statx.stx_attributes_mask", offset_of(linux.Statx, attributes_mask))
	F(b, "statx.stx_atime", offset_of(linux.Statx, atime))
	F(b, "statx.stx_btime", offset_of(linux.Statx, btime))
	F(b, "statx.stx_ctime", offset_of(linux.Statx, ctime))
	F(b, "statx.stx_mtime", offset_of(linux.Statx, mtime))
	F(b, "statx.stx_rdev_major", offset_of(linux.Statx, rdev_major))
	F(b, "statx.stx_dev_major", offset_of(linux.Statx, dev_major))
	F(b, "statx.stx_mnt_id", offset_of(linux.Statx, mnt_id))
	F(b, "statx.stx_dio_mem_align", offset_of(linux.Statx, dio_mem_align))
	F(b, "statx.stx_dio_offset_align", offset_of(linux.Statx, dio_offset_align))
	S(b, "statx_timestamp", linux.Statx_Timestamp)
	F(b, "statx_timestamp.tv_nsec", offset_of(linux.Statx_Timestamp, nsec))

	S(b, "statfs", linux.Stat_FS)
	F(b, "statfs.f_bsize", offset_of(linux.Stat_FS, bsize))
	F(b, "statfs.f_blocks", offset_of(linux.Stat_FS, blocks))
	F(b, "statfs.f_ffree", offset_of(linux.Stat_FS, ffree))
	F(b, "statfs.f_fsid", offset_of(linux.Stat_FS, fsid))
	F(b, "statfs.f_namelen", offset_of(linux.Stat_FS, namelen))
	F(b, "statfs.f_frsize", offset_of(linux.Stat_FS, frsize))
	F(b, "statfs.f_flags", offset_of(linux.Stat_FS, flags))
	F(b, "statfs.f_spare", offset_of(linux.Stat_FS, spare))

	S(b, "flock", linux.FLock)
	F(b, "flock.l_whence", offset_of(linux.FLock, whence))
	F(b, "flock.l_start", offset_of(linux.FLock, start))
	F(b, "flock.l_len", offset_of(linux.FLock, len))
	F(b, "flock.l_pid", offset_of(linux.FLock, pid))
	S(b, "f_owner_ex", linux.F_Owner)
	F(b, "f_owner_ex.pid", offset_of(linux.F_Owner, pid))
	S(b, "pollfd", linux.Poll_Fd)
	F(b, "pollfd.events", offset_of(linux.Poll_Fd, events))
	F(b, "pollfd.revents", offset_of(linux.Poll_Fd, revents))
	S(b, "inotify_event", linux.Inotify_Event)
	F(b, "inotify_event.mask", offset_of(linux.Inotify_Event, mask))
	F(b, "inotify_event.cookie", offset_of(linux.Inotify_Event, cookie))
	F(b, "inotify_event.len", offset_of(linux.Inotify_Event, len))
	F(b, "inotify_event.name", offset_of(linux.Inotify_Event, name))

	S(b, "sigset_t", linux.Sig_Set)
	S(b, "sigaction", linux.Sig_Action)
	F(b, "sigaction.sa_flags", offset_of(linux.Sig_Action, flags))
	F(b, "sigaction.sa_mask", offset_of(linux.Sig_Action, mask))
	S(b, "stack_t", linux.Sig_Stack)
	F(b, "stack_t.ss_flags", offset_of(linux.Sig_Stack, flags))
	F(b, "stack_t.ss_size", offset_of(linux.Sig_Stack, size))
	S(b, "sigevent", linux.Sig_Event)
	F(b, "sigevent.sigev_signo", offset_of(linux.Sig_Event, signo))
	F(b, "sigevent.sigev_notify", offset_of(linux.Sig_Event, notify))
	F(b, "sigevent.sigev_notify_thread_id", offset_of(linux.Sig_Event, thread_id))
	F(b, "sigevent.sigev_notify_function", offset_of(linux.Sig_Event, notify_function))
	F(b, "sigevent.sigev_notify_attributes", offset_of(linux.Sig_Event, notify_attribute))
	S(b, "siginfo_t", linux.Sig_Info)
	F(b, "siginfo_t.si_errno", offset_of(linux.Sig_Info, errno))
	F(b, "siginfo_t.si_code", offset_of(linux.Sig_Info, code))
	F(b, "siginfo_t.si_pid", offset_of(linux.Sig_Info, pid))
	F(b, "siginfo_t.si_uid", offset_of(linux.Sig_Info, uid))
	F(b, "siginfo_t.si_timerid", offset_of(linux.Sig_Info, timerid))
	F(b, "siginfo_t.si_overrun", offset_of(linux.Sig_Info, overrun))
	F(b, "siginfo_t.si_value", offset_of(linux.Sig_Info, value))
	F(b, "siginfo_t.si_status", offset_of(linux.Sig_Info, status))
	F(b, "siginfo_t.si_utime", offset_of(linux.Sig_Info, utime))
	F(b, "siginfo_t.si_stime", offset_of(linux.Sig_Info, stime))
	F(b, "siginfo_t.si_addr", offset_of(linux.Sig_Info, addr))
	F(b, "siginfo_t.si_addr_lsb", offset_of(linux.Sig_Info, addr_lsb))
	F(b, "siginfo_t.si_lower", offset_of(linux.Sig_Info, lower))
	F(b, "siginfo_t.si_upper", offset_of(linux.Sig_Info, upper))
	F(b, "siginfo_t.si_pkey", offset_of(linux.Sig_Info, pkey))
	F(b, "siginfo_t.si_band", offset_of(linux.Sig_Info, band))
	F(b, "siginfo_t.si_fd", offset_of(linux.Sig_Info, fd))
	F(b, "siginfo_t.si_call_addr", offset_of(linux.Sig_Info, call_addr))
	F(b, "siginfo_t.si_syscall", offset_of(linux.Sig_Info, syscall))
	F(b, "siginfo_t.si_arch", offset_of(linux.Sig_Info, arch))

	Z(b, "sockaddr_in", linux.Sock_Addr_In)
	F(b, "sockaddr_in.sin_port", offset_of(linux.Sock_Addr_In, sin_port))
	F(b, "sockaddr_in.sin_addr", offset_of(linux.Sock_Addr_In, sin_addr))
	Z(b, "sockaddr_in6", linux.Sock_Addr_In6)
	F(b, "sockaddr_in6.sin6_port", offset_of(linux.Sock_Addr_In6, sin6_port))
	F(b, "sockaddr_in6.sin6_flowinfo", offset_of(linux.Sock_Addr_In6, sin6_flowinfo))
	F(b, "sockaddr_in6.sin6_addr", offset_of(linux.Sock_Addr_In6, sin6_addr))
	F(b, "sockaddr_in6.sin6_scope_id", offset_of(linux.Sock_Addr_In6, sin6_scope_id))
	Z(b, "sockaddr_un", linux.Sock_Addr_Un)
	F(b, "sockaddr_un.sun_path", offset_of(linux.Sock_Addr_Un, sun_path))

	S(b, "tms", linux.Tms)
	F(b, "tms.tms_cstime", offset_of(linux.Tms, tms_cstime))
	S(b, "new_utsname", linux.UTS_Name)
	F(b, "new_utsname.machine", offset_of(linux.UTS_Name, machine))
	F(b, "new_utsname.domainname", offset_of(linux.UTS_Name, domainname))
	S(b, "sysinfo", linux.Sys_Info)
	F(b, "sysinfo.loads", offset_of(linux.Sys_Info, loads))
	F(b, "sysinfo.totalram", offset_of(linux.Sys_Info, totalram))
	F(b, "sysinfo.freeswap", offset_of(linux.Sys_Info, freeswap))
	F(b, "sysinfo.procs", offset_of(linux.Sys_Info, procs))
	F(b, "sysinfo.totalhigh", offset_of(linux.Sys_Info, totalhigh))
	F(b, "sysinfo.freehigh", offset_of(linux.Sys_Info, freehigh))
	F(b, "sysinfo.mem_unit", offset_of(linux.Sys_Info, mem_unit))
	S(b, "rlimit", linux.RLimit)
	F(b, "rlimit.rlim_max", offset_of(linux.RLimit, max))
	S(b, "rusage", linux.RUsage)
	F(b, "rusage.ru_stime", offset_of(linux.RUsage, stime))
	F(b, "rusage.ru_maxrss", offset_of(linux.RUsage, maxrss_word))
	F(b, "rusage.ru_nivcsw", offset_of(linux.RUsage, nivcsw_word))
	S(b, "iovec", linux.IO_Vec)
	F(b, "iovec.iov_len", offset_of(linux.IO_Vec, len))

	S(b, "ipc64_perm", linux.IPC_Perm)
	F(b, "ipc64_perm.uid", offset_of(linux.IPC_Perm, uid))
	F(b, "ipc64_perm.cgid", offset_of(linux.IPC_Perm, cgid))
	F(b, "ipc64_perm.mode", offset_of(linux.IPC_Perm, mode))
	F(b, "ipc64_perm.seq", offset_of(linux.IPC_Perm, seq))
	S(b, "shmid64_ds", linux.Shmid_DS)
	F(b, "shmid64_ds.shm_segsz", offset_of(linux.Shmid_DS, segsz))
	F(b, "shmid64_ds.shm_atime", offset_of(linux.Shmid_DS, atime))
	F(b, "shmid64_ds.shm_ctime", offset_of(linux.Shmid_DS, ctime))
	F(b, "shmid64_ds.shm_cpid", offset_of(linux.Shmid_DS, cpid))
	F(b, "shmid64_ds.shm_lpid", offset_of(linux.Shmid_DS, lpid))
	F(b, "shmid64_ds.shm_nattch", offset_of(linux.Shmid_DS, nattch))
	S(b, "semid64_ds", linux.Semid_DS)
	F(b, "semid64_ds.sem_otime", offset_of(linux.Semid_DS, otime))
	F(b, "semid64_ds.sem_ctime", offset_of(linux.Semid_DS, ctime))
	F(b, "semid64_ds.sem_nsems", offset_of(linux.Semid_DS, sem_nsems))
	S(b, "msqid64_ds", linux.Msqid_DS)
	F(b, "msqid64_ds.msg_stime", offset_of(linux.Msqid_DS, stime))
	F(b, "msqid64_ds.msg_rtime", offset_of(linux.Msqid_DS, rtime))
	F(b, "msqid64_ds.msg_ctime", offset_of(linux.Msqid_DS, ctime))
	F(b, "msqid64_ds.msg_cbytes", offset_of(linux.Msqid_DS, cbytes))
	F(b, "msqid64_ds.msg_qnum", offset_of(linux.Msqid_DS, qnum))
	F(b, "msqid64_ds.msg_qbytes", offset_of(linux.Msqid_DS, qbytes))
	F(b, "msqid64_ds.msg_lspid", offset_of(linux.Msqid_DS, lspid))
	F(b, "msqid64_ds.msg_lrpid", offset_of(linux.Msqid_DS, lrpid))

	S(b, "epoll_event", linux.EPoll_Event)
	F(b, "epoll_event.data", offset_of(linux.EPoll_Event, data))
	S(b, "riscv_hwprobe", linux.RISCV_HWProbe)
	F(b, "riscv_hwprobe.value", offset_of(linux.RISCV_HWProbe, value))

	S(b, "io_uring_params", linux.IO_Uring_Params)
	F(b, "io_uring_params.flags", offset_of(linux.IO_Uring_Params, flags))
	F(b, "io_uring_params.features", offset_of(linux.IO_Uring_Params, features))
	F(b, "io_uring_params.wq_fd", offset_of(linux.IO_Uring_Params, wq_fd))
	F(b, "io_uring_params.sq_off", offset_of(linux.IO_Uring_Params, sq_off))
	F(b, "io_uring_params.cq_off", offset_of(linux.IO_Uring_Params, cq_off))
	S(b, "io_sqring_offsets", linux.IO_SQ_Ring_Offsets)
	F(b, "io_sqring_offsets.array", offset_of(linux.IO_SQ_Ring_Offsets, array))
	F(b, "io_sqring_offsets.user_addr", offset_of(linux.IO_SQ_Ring_Offsets, user_addr))
	S(b, "io_cqring_offsets", linux.IO_CQ_Ring_Offsets)
	F(b, "io_cqring_offsets.cqes", offset_of(linux.IO_CQ_Ring_Offsets, cqes))
	F(b, "io_cqring_offsets.user_addr", offset_of(linux.IO_CQ_Ring_Offsets, user_addr))
	S(b, "io_uring_cqe", linux.IO_Uring_CQE)
	F(b, "io_uring_cqe.res", offset_of(linux.IO_Uring_CQE, res))
	F(b, "io_uring_cqe.flags", offset_of(linux.IO_Uring_CQE, flags))
	S(b, "io_uring_sqe", linux.IO_Uring_SQE)
	F(b, "io_uring_sqe.ioprio", offset_of(linux.IO_Uring_SQE, ioprio))
	F(b, "io_uring_sqe.fd", offset_of(linux.IO_Uring_SQE, fd))
	F(b, "io_uring_sqe.off", offset_of(linux.IO_Uring_SQE, off))
	F(b, "io_uring_sqe.addr", offset_of(linux.IO_Uring_SQE, addr))
	F(b, "io_uring_sqe.len", offset_of(linux.IO_Uring_SQE, len))
	F(b, "io_uring_sqe.rw_flags", offset_of(linux.IO_Uring_SQE, rw_flags))
	F(b, "io_uring_sqe.user_data", offset_of(linux.IO_Uring_SQE, user_data))
	F(b, "io_uring_sqe.buf_index", offset_of(linux.IO_Uring_SQE, buf_index))
	F(b, "io_uring_sqe.personality", offset_of(linux.IO_Uring_SQE, personality))
	F(b, "io_uring_sqe.splice_fd_in", offset_of(linux.IO_Uring_SQE, splice_fd_in))
	F(b, "io_uring_sqe.addr3", offset_of(linux.IO_Uring_SQE, addr3))
	S(b, "io_uring_getevents_arg", linux.IO_Uring_Getevents_Arg)
	F(b, "io_uring_getevents_arg.sigmask_sz", offset_of(linux.IO_Uring_Getevents_Arg, sigmask_sz))
	F(b, "io_uring_getevents_arg.ts", offset_of(linux.IO_Uring_Getevents_Arg, ts))

	S(b, "timex", linux.Timex)
	F(b, "timex.offset", offset_of(linux.Timex, offset))
	F(b, "timex.status", offset_of(linux.Timex, status))
	F(b, "timex.constant", offset_of(linux.Timex, constant))
	F(b, "timex.time", offset_of(linux.Timex, time))
	F(b, "timex.tick", offset_of(linux.Timex, tick))
	F(b, "timex.shift", offset_of(linux.Timex, shift))
	F(b, "timex.stabil", offset_of(linux.Timex, stabil))
	F(b, "timex.stbcnt", offset_of(linux.Timex, stbcnt))
	F(b, "timex.tai", offset_of(linux.Timex, tai))

	S(b, "sched_attr", linux.Sched_Attr)
	F(b, "sched_attr.sched_nice", offset_of(linux.Sched_Attr, sched_nice))
	F(b, "sched_attr.sched_runtime", offset_of(linux.Sched_Attr, sched_runtime))
	F(b, "sched_attr.sched_util_max", offset_of(linux.Sched_Attr, sched_util_max))

	S(b, "nlmsghdr", linux.Netlink_Message_Header)
	F(b, "nlmsghdr.nlmsg_flags", offset_of(linux.Netlink_Message_Header, flags))
	F(b, "nlmsghdr.nlmsg_pid", offset_of(linux.Netlink_Message_Header, pid))
	S(b, "nlmsgerr", linux.Netlink_Message_Error)
	F(b, "nlmsgerr.msg", offset_of(linux.Netlink_Message_Error, msg))
	S(b, "rtattr", linux.Rtnetlink_Attribute)
	S(b, "rtgenmsg", linux.Rtnetlink_Generic_Message)
	S(b, "ifinfomsg", linux.Interface_Info_Message)
	F(b, "ifinfomsg.ifi_index", offset_of(linux.Interface_Info_Message, index))
	F(b, "ifinfomsg.ifi_change", offset_of(linux.Interface_Info_Message, change))
	S(b, "ifaddrmsg", linux.Interface_Address_Message)
	F(b, "ifaddrmsg.ifa_index", offset_of(linux.Interface_Address_Message, index))
	S(b, "rtmsg", linux.Route_Message)
	F(b, "rtmsg.rtm_type", offset_of(linux.Route_Message, type))
	F(b, "rtmsg.rtm_flags", offset_of(linux.Route_Message, flags))
	S(b, "rtnexthop", linux.Route_Next_Hop)
	F(b, "rtnexthop.rtnh_ifindex", offset_of(linux.Route_Next_Hop, ifindex))

	info: linux.PTrace_Syscall_Info
	S(b, "ptrace_peeksiginfo_args", linux.PTrace_Peek_Sig_Info_Args)
	F(b, "ptrace_peeksiginfo_args.nr", offset_of(linux.PTrace_Peek_Sig_Info_Args, nr))
	S(b, "seccomp_metadata", linux.PTrace_Seccomp_Metadata)
	S(b, "ptrace_syscall_info", linux.PTrace_Syscall_Info)
	F(b, "ptrace_syscall_info.arch", offset_of(linux.PTrace_Syscall_Info, arch))
	F(b, "ptrace_syscall_info.instruction_pointer", offset_of(linux.PTrace_Syscall_Info, instruction_pointer))
	F(b, "ptrace_syscall_info.stack_pointer", offset_of(linux.PTrace_Syscall_Info, stack_pointer))
	F(b, "ptrace_syscall_info.entry.args", offset_of(linux.PTrace_Syscall_Info, entry) + offset_of(type_of(info.entry), args))
	F(b, "ptrace_syscall_info.exit.is_error", offset_of(linux.PTrace_Syscall_Info, exit) + offset_of(type_of(info.exit), is_error))
	F(b, "ptrace_syscall_info.seccomp.ret_data", offset_of(linux.PTrace_Syscall_Info, seccomp) + offset_of(type_of(info.seccomp), ret_data))
	S(b, "ptrace_rseq_configuration", linux.PTrace_RSeq_Configuration)
	F(b, "ptrace_rseq_configuration.flags", offset_of(linux.PTrace_RSeq_Configuration, flags))

	F(b, "perf_event_attr.config", offset_of(linux.Perf_Event_Attr, config))
	F(b, "perf_event_attr.sample_type", offset_of(linux.Perf_Event_Attr, sample_type))
	F(b, "perf_event_attr.read_format", offset_of(linux.Perf_Event_Attr, read_format))
	F(b, "perf_event_attr.wakeup_events", offset_of(linux.Perf_Event_Attr, wakeup))
	F(b, "perf_event_attr.bp_type", offset_of(linux.Perf_Event_Attr, breakpoint_type))
	F(b, "perf_event_attr.config1", offset_of(linux.Perf_Event_Attr, config1))
	F(b, "perf_event_attr.config2", offset_of(linux.Perf_Event_Attr, config2))
	F(b, "perf_event_attr.branch_sample_type", offset_of(linux.Perf_Event_Attr, branch_sample_type))
	F(b, "perf_event_attr.sample_stack_user", offset_of(linux.Perf_Event_Attr, sample_stack_user))
	F(b, "perf_event_attr.clockid", offset_of(linux.Perf_Event_Attr, clock_id))
	F(b, "perf_event_attr.aux_watermark", offset_of(linux.Perf_Event_Attr, aux_watermark))
	F(b, "perf_event_attr.sample_max_stack", offset_of(linux.Perf_Event_Attr, sample_max_stack))
	K(b, "PERF_ATTR_SIZE_VER5", size_of(linux.Perf_Event_Attr))
	F(b, "perf_event_mmap_page.capabilities", offset_of(linux.Perf_Event_Mmap_Page, cap))
	F(b, "perf_event_mmap_page.pmc_width", offset_of(linux.Perf_Event_Mmap_Page, pmc_width))
	F(b, "perf_event_mmap_page.time_zero", offset_of(linux.Perf_Event_Mmap_Page, time_zero))
	F(b, "perf_event_mmap_page.time_mask", offset_of(linux.Perf_Event_Mmap_Page, time_mask))
	F(b, "perf_event_mmap_page.data_head", offset_of(linux.Perf_Event_Mmap_Page, data_head))
	F(b, "perf_event_mmap_page.aux_size", offset_of(linux.Perf_Event_Mmap_Page, aux_size))

	fp: linux.User_FP_Regs
	S(b, "user_regs_struct", linux.User_Regs)
	F(b, "user_regs_struct.sp", offset_of(linux.User_Regs, sp))
	F(b, "user_regs_struct.a0", offset_of(linux.User_Regs, a0))
	F(b, "user_regs_struct.s2", offset_of(linux.User_Regs, s2))
	F(b, "user_regs_struct.t6", offset_of(linux.User_Regs, t6))
	S(b, "__riscv_fp_state", linux.User_FP_Regs)
	F(b, "__riscv_fp_state.f.fcsr", offset_of(type_of(fp.f_ext), fcsr))
	F(b, "__riscv_fp_state.d.fcsr", offset_of(type_of(fp.d_ext), fcsr))
	F(b, "__riscv_fp_state.q.fcsr", offset_of(type_of(fp.q_ext), fcsr))

	K(b, "O_DIRECT", i64(transmute(u32)linux.Open_Flags{.DIRECT}))
	K(b, "O_LARGEFILE", i64(transmute(u32)linux.Open_Flags{.LARGEFILE}))
	K(b, "O_DIRECTORY", i64(transmute(u32)linux.Open_Flags{.DIRECTORY}))
	K(b, "O_NOFOLLOW", i64(transmute(u32)linux.Open_Flags{.NOFOLLOW}))
	K(b, "O_PATH", i64(transmute(u32)linux.Open_Flags{.PATH}))

	K(b, "SA_NOCLDSTOP", i64(transmute(uint)linux.Sig_Action_Flags{.NOCLDSTOP}))
	K(b, "SA_NOCLDWAIT", i64(transmute(uint)linux.Sig_Action_Flags{.NOCLDWAIT}))
	K(b, "SA_SIGINFO", i64(transmute(uint)linux.Sig_Action_Flags{.SIGINFO}))
	K(b, "SA_ONSTACK", i64(transmute(uint)linux.Sig_Action_Flags{.ONSTACK}))
	K(b, "SA_RESTART", i64(transmute(uint)linux.Sig_Action_Flags{.RESTART}))
	K(b, "SA_NODEFER", i64(transmute(uint)linux.Sig_Action_Flags{.NODEFER}))
	K(b, "SA_RESETHAND", i64(transmute(uint)linux.Sig_Action_Flags{.RESETHAND}))

	K(b, "SIGBUS", i64(linux.Signal.SIGBUS))
	K(b, "SIGUSR1", i64(linux.Signal.SIGUSR1))
	K(b, "SIGUSR2", i64(linux.Signal.SIGUSR2))
	K(b, "SIGSTKFLT", i64(linux.Signal.SIGSTKFLT))
	K(b, "SIGCHLD", i64(linux.Signal.SIGCHLD))
	K(b, "SIGCONT", i64(linux.Signal.SIGCONT))
	K(b, "SIGSTOP", i64(linux.Signal.SIGSTOP))
	K(b, "SIGURG", i64(linux.Signal.SIGURG))
	K(b, "SIGPOLL", i64(linux.Signal.SIGPOLL))
	K(b, "SIGPWR", i64(linux.Signal.SIGPWR))
	K(b, "SIGSYS", i64(linux.Signal.SIGSYS))

	F(b, "dirent64.d_off", offset_of(linux.Dirent, off))
	F(b, "dirent64.d_reclen", offset_of(linux.Dirent, reclen))
	F(b, "dirent64.d_type", offset_of(linux.Dirent, type))
	F(b, "dirent64.d_name", offset_of(linux.Dirent, name))

	Z(b, "sockaddr", linux.Sock_Addr)
	F(b, "sockaddr.sa_data", offset_of(linux.Sock_Addr, sa_data))
	S(b, "linger", linux.Linger)
	F(b, "linger.l_linger", offset_of(linux.Linger, l_linger))
	S(b, "msghdr", linux.Msg_Hdr)
	F(b, "msghdr.msg_namelen", offset_of(linux.Msg_Hdr, namelen))
	F(b, "msghdr.msg_iov", offset_of(linux.Msg_Hdr, iov))
	F(b, "msghdr.msg_iovlen", offset_of(linux.Msg_Hdr, iov) + size_of(rawptr))
	F(b, "msghdr.msg_control", offset_of(linux.Msg_Hdr, control))
	F(b, "msghdr.msg_controllen", offset_of(linux.Msg_Hdr, control) + size_of(rawptr))
	F(b, "msghdr.msg_flags", offset_of(linux.Msg_Hdr, flags))
	S(b, "mmsghdr", linux.MMsg_Hdr)
	F(b, "mmsghdr.msg_len", offset_of(linux.MMsg_Hdr, len))
}
