#include <linux/types.h>
#include <linux/time.h>
#include <linux/time_types.h>
#include <asm/stat.h>
#include <linux/stat.h>
#include <asm/statfs.h>
#include <linux/fcntl.h>
#include <linux/poll.h>
#include <linux/inotify.h>
#include <linux/signal.h>
#include <linux/in.h>
#include <linux/in6.h>
#include <linux/un.h>
#include <linux/times.h>
#include <linux/utsname.h>
#include <linux/sysinfo.h>
#include <linux/resource.h>
#include <linux/uio.h>
#include <asm/ipcbuf.h>
#include <asm/shmbuf.h>
#include <asm/sembuf.h>
#include <asm/msgbuf.h>
#include <linux/eventpoll.h>
#include <linux/io_uring.h>
#include <linux/timex.h>
#include <linux/sched/types.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <linux/ptrace.h>
#include <linux/perf_event.h>
#include <asm/ptrace.h>
#include <asm/hwprobe.h>
#include <asm/unistd.h>

int printf(const char *, ...);
void libc_layouts(void);

#define S(n, t)    printf("%s %d %d\n", n, (int)sizeof(t), (int)_Alignof(t))
#define Z(n, t)    printf("%s %d\n", n, (int)sizeof(t))
#define F(n, t, f) printf("%s %d\n", n, (int)__builtin_offsetof(t, f))
#define K(n, v)    printf("%s %lld\n", n, (long long)(v))
#define M(n)       printf("%s missing\n", n)

int main(void)
{
	S("timespec", struct __kernel_timespec);
	F("timespec.tv_nsec", struct __kernel_timespec, tv_nsec);
	S("timeval", struct __kernel_old_timeval);
	F("timeval.tv_usec", struct __kernel_old_timeval, tv_usec);
	S("itimerval", struct __kernel_old_itimerval);
	F("itimerval.it_value", struct __kernel_old_itimerval, it_value);
	S("itimerspec", struct __kernel_itimerspec);
	F("itimerspec.it_value", struct __kernel_itimerspec, it_value);

	S("stat", struct stat);
	F("stat.st_dev", struct stat, st_dev);
	F("stat.st_ino", struct stat, st_ino);
	F("stat.st_mode", struct stat, st_mode);
	F("stat.st_nlink", struct stat, st_nlink);
	F("stat.st_uid", struct stat, st_uid);
	F("stat.st_gid", struct stat, st_gid);
	F("stat.st_rdev", struct stat, st_rdev);
	F("stat.st_size", struct stat, st_size);
	F("stat.st_blksize", struct stat, st_blksize);
	F("stat.st_blocks", struct stat, st_blocks);
	F("stat.st_atime", struct stat, st_atime);
	F("stat.st_mtime", struct stat, st_mtime);
	F("stat.st_ctime", struct stat, st_ctime);

	S("statx", struct statx);
	F("statx.stx_blksize", struct statx, stx_blksize);
	F("statx.stx_attributes", struct statx, stx_attributes);
	F("statx.stx_nlink", struct statx, stx_nlink);
	F("statx.stx_uid", struct statx, stx_uid);
	F("statx.stx_gid", struct statx, stx_gid);
	F("statx.stx_mode", struct statx, stx_mode);
	F("statx.stx_ino", struct statx, stx_ino);
	F("statx.stx_size", struct statx, stx_size);
	F("statx.stx_blocks", struct statx, stx_blocks);
	F("statx.stx_attributes_mask", struct statx, stx_attributes_mask);
	F("statx.stx_atime", struct statx, stx_atime);
	F("statx.stx_btime", struct statx, stx_btime);
	F("statx.stx_ctime", struct statx, stx_ctime);
	F("statx.stx_mtime", struct statx, stx_mtime);
	F("statx.stx_rdev_major", struct statx, stx_rdev_major);
	F("statx.stx_dev_major", struct statx, stx_dev_major);
	F("statx.stx_mnt_id", struct statx, stx_mnt_id);
	F("statx.stx_dio_mem_align", struct statx, stx_dio_mem_align);
	F("statx.stx_dio_offset_align", struct statx, stx_dio_offset_align);
	S("statx_timestamp", struct statx_timestamp);
	F("statx_timestamp.tv_nsec", struct statx_timestamp, tv_nsec);

	S("statfs", struct statfs);
	F("statfs.f_bsize", struct statfs, f_bsize);
	F("statfs.f_blocks", struct statfs, f_blocks);
	F("statfs.f_ffree", struct statfs, f_ffree);
	F("statfs.f_fsid", struct statfs, f_fsid);
	F("statfs.f_namelen", struct statfs, f_namelen);
	F("statfs.f_frsize", struct statfs, f_frsize);
	F("statfs.f_flags", struct statfs, f_flags);
	F("statfs.f_spare", struct statfs, f_spare);

	S("flock", struct flock);
	F("flock.l_whence", struct flock, l_whence);
	F("flock.l_start", struct flock, l_start);
	F("flock.l_len", struct flock, l_len);
	F("flock.l_pid", struct flock, l_pid);
	S("f_owner_ex", struct f_owner_ex);
	F("f_owner_ex.pid", struct f_owner_ex, pid);
	S("pollfd", struct pollfd);
	F("pollfd.events", struct pollfd, events);
	F("pollfd.revents", struct pollfd, revents);
	S("inotify_event", struct inotify_event);
	F("inotify_event.mask", struct inotify_event, mask);
	F("inotify_event.cookie", struct inotify_event, cookie);
	F("inotify_event.len", struct inotify_event, len);
	F("inotify_event.name", struct inotify_event, name);

	S("sigset_t", sigset_t);
	S("sigaction", struct sigaction);
	F("sigaction.sa_flags", struct sigaction, sa_flags);
	F("sigaction.sa_mask", struct sigaction, sa_mask);
	S("stack_t", stack_t);
	F("stack_t.ss_flags", stack_t, ss_flags);
	F("stack_t.ss_size", stack_t, ss_size);
	S("sigevent", struct sigevent);
	F("sigevent.sigev_signo", struct sigevent, sigev_signo);
	F("sigevent.sigev_notify", struct sigevent, sigev_notify);
	F("sigevent.sigev_notify_thread_id", struct sigevent, sigev_notify_thread_id);
	F("sigevent.sigev_notify_function", struct sigevent, sigev_notify_function);
	F("sigevent.sigev_notify_attributes", struct sigevent, sigev_notify_attributes);
	S("siginfo_t", siginfo_t);
	F("siginfo_t.si_errno", siginfo_t, si_errno);
	F("siginfo_t.si_code", siginfo_t, si_code);
	F("siginfo_t.si_pid", siginfo_t, si_pid);
	F("siginfo_t.si_uid", siginfo_t, si_uid);
	F("siginfo_t.si_timerid", siginfo_t, si_tid);
	F("siginfo_t.si_overrun", siginfo_t, si_overrun);
	F("siginfo_t.si_value", siginfo_t, si_value);
	F("siginfo_t.si_status", siginfo_t, si_status);
	F("siginfo_t.si_utime", siginfo_t, si_utime);
	F("siginfo_t.si_stime", siginfo_t, si_stime);
	F("siginfo_t.si_addr", siginfo_t, si_addr);
	F("siginfo_t.si_addr_lsb", siginfo_t, si_addr_lsb);
	F("siginfo_t.si_lower", siginfo_t, si_lower);
	F("siginfo_t.si_upper", siginfo_t, si_upper);
	F("siginfo_t.si_pkey", siginfo_t, si_pkey);
	F("siginfo_t.si_band", siginfo_t, si_band);
	F("siginfo_t.si_fd", siginfo_t, si_fd);
	F("siginfo_t.si_call_addr", siginfo_t, si_call_addr);
	F("siginfo_t.si_syscall", siginfo_t, si_syscall);
	F("siginfo_t.si_arch", siginfo_t, si_arch);

	Z("sockaddr_in", struct sockaddr_in);
	F("sockaddr_in.sin_port", struct sockaddr_in, sin_port);
	F("sockaddr_in.sin_addr", struct sockaddr_in, sin_addr);
	Z("sockaddr_in6", struct sockaddr_in6);
	F("sockaddr_in6.sin6_port", struct sockaddr_in6, sin6_port);
	F("sockaddr_in6.sin6_flowinfo", struct sockaddr_in6, sin6_flowinfo);
	F("sockaddr_in6.sin6_addr", struct sockaddr_in6, sin6_addr);
	F("sockaddr_in6.sin6_scope_id", struct sockaddr_in6, sin6_scope_id);
	Z("sockaddr_un", struct sockaddr_un);
	F("sockaddr_un.sun_path", struct sockaddr_un, sun_path);

	S("tms", struct tms);
	F("tms.tms_cstime", struct tms, tms_cstime);
	S("new_utsname", struct new_utsname);
	F("new_utsname.machine", struct new_utsname, machine);
	F("new_utsname.domainname", struct new_utsname, domainname);
	S("sysinfo", struct sysinfo);
	F("sysinfo.loads", struct sysinfo, loads);
	F("sysinfo.totalram", struct sysinfo, totalram);
	F("sysinfo.freeswap", struct sysinfo, freeswap);
	F("sysinfo.procs", struct sysinfo, procs);
	F("sysinfo.totalhigh", struct sysinfo, totalhigh);
	F("sysinfo.freehigh", struct sysinfo, freehigh);
	F("sysinfo.mem_unit", struct sysinfo, mem_unit);
	S("rlimit", struct rlimit);
	F("rlimit.rlim_max", struct rlimit, rlim_max);
	S("rusage", struct rusage);
	F("rusage.ru_stime", struct rusage, ru_stime);
	F("rusage.ru_maxrss", struct rusage, ru_maxrss);
	F("rusage.ru_nivcsw", struct rusage, ru_nivcsw);
	S("iovec", struct iovec);
	F("iovec.iov_len", struct iovec, iov_len);

	S("ipc64_perm", struct ipc64_perm);
	F("ipc64_perm.uid", struct ipc64_perm, uid);
	F("ipc64_perm.cgid", struct ipc64_perm, cgid);
	F("ipc64_perm.mode", struct ipc64_perm, mode);
	F("ipc64_perm.seq", struct ipc64_perm, seq);
	S("shmid64_ds", struct shmid64_ds);
	F("shmid64_ds.shm_segsz", struct shmid64_ds, shm_segsz);
	F("shmid64_ds.shm_atime", struct shmid64_ds, shm_atime);
	F("shmid64_ds.shm_ctime", struct shmid64_ds, shm_ctime);
	F("shmid64_ds.shm_cpid", struct shmid64_ds, shm_cpid);
	F("shmid64_ds.shm_lpid", struct shmid64_ds, shm_lpid);
	F("shmid64_ds.shm_nattch", struct shmid64_ds, shm_nattch);
	S("semid64_ds", struct semid64_ds);
	F("semid64_ds.sem_otime", struct semid64_ds, sem_otime);
	F("semid64_ds.sem_ctime", struct semid64_ds, sem_ctime);
	F("semid64_ds.sem_nsems", struct semid64_ds, sem_nsems);
	S("msqid64_ds", struct msqid64_ds);
	F("msqid64_ds.msg_stime", struct msqid64_ds, msg_stime);
	F("msqid64_ds.msg_rtime", struct msqid64_ds, msg_rtime);
	F("msqid64_ds.msg_ctime", struct msqid64_ds, msg_ctime);
	F("msqid64_ds.msg_cbytes", struct msqid64_ds, msg_cbytes);
	F("msqid64_ds.msg_qnum", struct msqid64_ds, msg_qnum);
	F("msqid64_ds.msg_qbytes", struct msqid64_ds, msg_qbytes);
	F("msqid64_ds.msg_lspid", struct msqid64_ds, msg_lspid);
	F("msqid64_ds.msg_lrpid", struct msqid64_ds, msg_lrpid);

	S("epoll_event", struct epoll_event);
	F("epoll_event.data", struct epoll_event, data);
	S("riscv_hwprobe", struct riscv_hwprobe);
	F("riscv_hwprobe.value", struct riscv_hwprobe, value);

	S("io_uring_params", struct io_uring_params);
	F("io_uring_params.flags", struct io_uring_params, flags);
	F("io_uring_params.features", struct io_uring_params, features);
	F("io_uring_params.wq_fd", struct io_uring_params, wq_fd);
	F("io_uring_params.sq_off", struct io_uring_params, sq_off);
	F("io_uring_params.cq_off", struct io_uring_params, cq_off);
	S("io_sqring_offsets", struct io_sqring_offsets);
	F("io_sqring_offsets.array", struct io_sqring_offsets, array);
	F("io_sqring_offsets.user_addr", struct io_sqring_offsets, user_addr);
	S("io_cqring_offsets", struct io_cqring_offsets);
	F("io_cqring_offsets.cqes", struct io_cqring_offsets, cqes);
	F("io_cqring_offsets.user_addr", struct io_cqring_offsets, user_addr);
	S("io_uring_cqe", struct io_uring_cqe);
	F("io_uring_cqe.res", struct io_uring_cqe, res);
	F("io_uring_cqe.flags", struct io_uring_cqe, flags);
	S("io_uring_sqe", struct io_uring_sqe);
	F("io_uring_sqe.ioprio", struct io_uring_sqe, ioprio);
	F("io_uring_sqe.fd", struct io_uring_sqe, fd);
	F("io_uring_sqe.off", struct io_uring_sqe, off);
	F("io_uring_sqe.addr", struct io_uring_sqe, addr);
	F("io_uring_sqe.len", struct io_uring_sqe, len);
	F("io_uring_sqe.rw_flags", struct io_uring_sqe, rw_flags);
	F("io_uring_sqe.user_data", struct io_uring_sqe, user_data);
	F("io_uring_sqe.buf_index", struct io_uring_sqe, buf_index);
	F("io_uring_sqe.personality", struct io_uring_sqe, personality);
	F("io_uring_sqe.splice_fd_in", struct io_uring_sqe, splice_fd_in);
	F("io_uring_sqe.addr3", struct io_uring_sqe, addr3);
	S("io_uring_getevents_arg", struct io_uring_getevents_arg);
	F("io_uring_getevents_arg.sigmask_sz", struct io_uring_getevents_arg, sigmask_sz);
	F("io_uring_getevents_arg.ts", struct io_uring_getevents_arg, ts);

	S("timex", struct timex);
	F("timex.offset", struct timex, offset);
	F("timex.status", struct timex, status);
	F("timex.constant", struct timex, constant);
	F("timex.time", struct timex, time);
	F("timex.tick", struct timex, tick);
	F("timex.shift", struct timex, shift);
	F("timex.stabil", struct timex, stabil);
	F("timex.stbcnt", struct timex, stbcnt);
	F("timex.tai", struct timex, tai);

	S("sched_attr", struct sched_attr);
	F("sched_attr.sched_nice", struct sched_attr, sched_nice);
	F("sched_attr.sched_runtime", struct sched_attr, sched_runtime);
	F("sched_attr.sched_util_max", struct sched_attr, sched_util_max);

	S("nlmsghdr", struct nlmsghdr);
	F("nlmsghdr.nlmsg_flags", struct nlmsghdr, nlmsg_flags);
	F("nlmsghdr.nlmsg_pid", struct nlmsghdr, nlmsg_pid);
	S("nlmsgerr", struct nlmsgerr);
	F("nlmsgerr.msg", struct nlmsgerr, msg);
	S("rtattr", struct rtattr);
	S("rtgenmsg", struct rtgenmsg);
	S("ifinfomsg", struct ifinfomsg);
	F("ifinfomsg.ifi_index", struct ifinfomsg, ifi_index);
	F("ifinfomsg.ifi_change", struct ifinfomsg, ifi_change);
	S("ifaddrmsg", struct ifaddrmsg);
	F("ifaddrmsg.ifa_index", struct ifaddrmsg, ifa_index);
	S("rtmsg", struct rtmsg);
	F("rtmsg.rtm_type", struct rtmsg, rtm_type);
	F("rtmsg.rtm_flags", struct rtmsg, rtm_flags);
	S("rtnexthop", struct rtnexthop);
	F("rtnexthop.rtnh_ifindex", struct rtnexthop, rtnh_ifindex);

	S("ptrace_peeksiginfo_args", struct ptrace_peeksiginfo_args);
	F("ptrace_peeksiginfo_args.nr", struct ptrace_peeksiginfo_args, nr);
	S("seccomp_metadata", struct seccomp_metadata);
	S("ptrace_syscall_info", struct ptrace_syscall_info);
	F("ptrace_syscall_info.arch", struct ptrace_syscall_info, arch);
	F("ptrace_syscall_info.instruction_pointer", struct ptrace_syscall_info, instruction_pointer);
	F("ptrace_syscall_info.stack_pointer", struct ptrace_syscall_info, stack_pointer);
	F("ptrace_syscall_info.entry.args", struct ptrace_syscall_info, entry.args);
	F("ptrace_syscall_info.exit.is_error", struct ptrace_syscall_info, exit.is_error);
	F("ptrace_syscall_info.seccomp.ret_data", struct ptrace_syscall_info, seccomp.ret_data);
	S("ptrace_rseq_configuration", struct ptrace_rseq_configuration);
	F("ptrace_rseq_configuration.flags", struct ptrace_rseq_configuration, flags);

	F("perf_event_attr.config", struct perf_event_attr, config);
	F("perf_event_attr.sample_type", struct perf_event_attr, sample_type);
	F("perf_event_attr.read_format", struct perf_event_attr, read_format);
	F("perf_event_attr.wakeup_events", struct perf_event_attr, wakeup_events);
	F("perf_event_attr.bp_type", struct perf_event_attr, bp_type);
	F("perf_event_attr.config1", struct perf_event_attr, config1);
	F("perf_event_attr.config2", struct perf_event_attr, config2);
	F("perf_event_attr.branch_sample_type", struct perf_event_attr, branch_sample_type);
	F("perf_event_attr.sample_stack_user", struct perf_event_attr, sample_stack_user);
	F("perf_event_attr.clockid", struct perf_event_attr, clockid);
	F("perf_event_attr.aux_watermark", struct perf_event_attr, aux_watermark);
	F("perf_event_attr.sample_max_stack", struct perf_event_attr, sample_max_stack);
	K("PERF_ATTR_SIZE_VER5", PERF_ATTR_SIZE_VER5);
	F("perf_event_mmap_page.capabilities", struct perf_event_mmap_page, capabilities);
	F("perf_event_mmap_page.pmc_width", struct perf_event_mmap_page, pmc_width);
	F("perf_event_mmap_page.time_zero", struct perf_event_mmap_page, time_zero);
	F("perf_event_mmap_page.time_mask", struct perf_event_mmap_page, time_mask);
	F("perf_event_mmap_page.data_head", struct perf_event_mmap_page, data_head);
	F("perf_event_mmap_page.aux_size", struct perf_event_mmap_page, aux_size);

	S("user_regs_struct", struct user_regs_struct);
	F("user_regs_struct.sp", struct user_regs_struct, sp);
	F("user_regs_struct.a0", struct user_regs_struct, a0);
	F("user_regs_struct.s2", struct user_regs_struct, s2);
	F("user_regs_struct.t6", struct user_regs_struct, t6);
	S("__riscv_fp_state", union __riscv_fp_state);
	F("__riscv_fp_state.f.fcsr", union __riscv_fp_state, f.fcsr);
	F("__riscv_fp_state.d.fcsr", union __riscv_fp_state, d.fcsr);
	F("__riscv_fp_state.q.fcsr", union __riscv_fp_state, q.fcsr);

	K("O_DIRECT", O_DIRECT);
	K("O_LARGEFILE", O_LARGEFILE);
	K("O_DIRECTORY", O_DIRECTORY);
	K("O_NOFOLLOW", O_NOFOLLOW);
	K("O_PATH", O_PATH);

	K("SA_NOCLDSTOP", SA_NOCLDSTOP);
	K("SA_NOCLDWAIT", SA_NOCLDWAIT);
	K("SA_SIGINFO", SA_SIGINFO);
	K("SA_ONSTACK", SA_ONSTACK);
	K("SA_RESTART", SA_RESTART);
	K("SA_NODEFER", SA_NODEFER);
	K("SA_RESETHAND", SA_RESETHAND);
#ifdef SA_RESTORER
	K("SA_RESTORER", SA_RESTORER);
#else
	M("SA_RESTORER");
#endif

	K("SIGBUS", SIGBUS);
	K("SIGUSR1", SIGUSR1);
	K("SIGUSR2", SIGUSR2);
	K("SIGSTKFLT", SIGSTKFLT);
	K("SIGCHLD", SIGCHLD);
	K("SIGCONT", SIGCONT);
	K("SIGSTOP", SIGSTOP);
	K("SIGURG", SIGURG);
	K("SIGPOLL", SIGPOLL);
	K("SIGPWR", SIGPWR);
	K("SIGSYS", SIGSYS);

#include "syscalls.h"

	libc_layouts();
	return 0;
}
