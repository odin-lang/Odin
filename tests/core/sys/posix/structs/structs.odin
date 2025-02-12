package main

import "core:fmt"
import "core:sys/posix"

main :: proc() {
	fmt.println("dirent", size_of(posix.dirent), align_of(posix.dirent))
	fmt.println("flock", size_of(posix.flock), align_of(posix.flock))
	fmt.println("glob_t", size_of(posix.glob_t), align_of(posix.glob_t))
	fmt.println("group", size_of(posix.group), align_of(posix.group))
	fmt.println("lconv", size_of(posix.lconv), align_of(posix.lconv))

	fmt.println("pthread_t", size_of(posix.pthread_t), align_of(posix.pthread_t))
	fmt.println("pthread_attr_t", size_of(posix.pthread_attr_t), align_of(posix.pthread_attr_t))
	fmt.println("pthread_key_t", size_of(posix.pthread_key_t), align_of(posix.pthread_key_t))

	// NOTE: On Linux, differences between libc may mean the Odin side is larger than the other side,
	// this is fine in practice.
	when ODIN_OS != .Linux {
		fmt.println("sched_param", size_of(posix.sched_param), align_of(posix.sched_param))
	}

	fmt.println("termios", size_of(posix.termios), align_of(posix.termios))
	
	fmt.println("in_addr", size_of(posix.in_addr), align_of(posix.in_addr))
	fmt.println("in6_addr", size_of(posix.in6_addr), align_of(posix.in6_addr))
	fmt.println("sockaddr_in", size_of(posix.sockaddr_in), align_of(posix.sockaddr_in))
	fmt.println("sockaddr_in6", size_of(posix.sockaddr_in6), align_of(posix.sockaddr_in6))
	fmt.println("ipv6_mreq", size_of(posix.ipv6_mreq), align_of(posix.ipv6_mreq))

	fmt.println("sockaddr_storage", size_of(posix.sockaddr_storage), align_of(posix.sockaddr_storage))
	fmt.println("msghdr", size_of(posix.msghdr), align_of(posix.msghdr))
	fmt.println("cmsghdr", size_of(posix.cmsghdr), align_of(posix.cmsghdr))
	fmt.println("linger", size_of(posix.linger), align_of(posix.linger))

	fmt.println("hostent", size_of(posix.hostent), align_of(posix.hostent))
	fmt.println("netent", size_of(posix.netent), align_of(posix.netent))
	fmt.println("protoent", size_of(posix.protoent), align_of(posix.protoent))
	fmt.println("servent", size_of(posix.servent), align_of(posix.servent))
	fmt.println("addrinfo", size_of(posix.addrinfo), align_of(posix.addrinfo))
	fmt.println("ai_canonname", offset_of(posix.addrinfo, ai_canonname))

	fmt.println("pollfd", size_of(posix.pollfd), align_of(posix.pollfd))
	fmt.println("passwd", size_of(posix.passwd), align_of(posix.passwd))

	when ODIN_OS != .Haiku {
		fmt.println("shmid_ds", size_of(posix.shmid_ds), align_of(posix.shmid_ds))
	}
	
	fmt.println("ipc_perm", size_of(posix.ipc_perm), align_of(posix.ipc_perm))
	fmt.println("msqid_ds", size_of(posix.msqid_ds), align_of(posix.msqid_ds))

	fmt.println("rlimit", size_of(posix.rlimit), align_of(posix.rlimit))
	fmt.println("rusage", size_of(posix.rusage), align_of(posix.rusage))

	fmt.println("sockaddr_un", size_of(posix.sockaddr_un), align_of(posix.sockaddr_un))

	fmt.println("utsname", size_of(posix.utsname), align_of(posix.utsname))

	fmt.println("tms", size_of(posix.tms), align_of(posix.tms))

	fmt.println("sigaction", size_of(posix.sigaction_t), align_of(posix.sigaction_t))
	fmt.println("stack_t", size_of(posix.stack_t), align_of(posix.stack_t))
	fmt.println("siginfo_t", size_of(posix.siginfo_t), align_of(posix.siginfo_t))

	fmt.println("fd_set", size_of(posix.fd_set), align_of(posix.fd_set))

	fmt.println("iovec", size_of(posix.iovec), align_of(posix.iovec))

	fmt.println("semid_ds", size_of(posix.semid_ds), align_of(posix.semid_ds))
	fmt.println("sembuf", size_of(posix.sembuf), align_of(posix.sembuf))

	fmt.println("itimerval", size_of(posix.itimerval), align_of(posix.itimerval))

	fmt.println("utimbuf", size_of(posix.utimbuf), align_of(posix.utimbuf))

	when ODIN_OS != .Haiku {
		fmt.println("wordexp_t", size_of(posix.wordexp_t), align_of(posix.wordexp_t))
	}
	
	fmt.println("time_t", size_of(posix.time_t), align_of(posix.time_t))
	fmt.println("timespec", size_of(posix.timespec), align_of(posix.timespec))
	fmt.println("clock_t", size_of(posix.clock_t), align_of(posix.clock_t))

	fmt.println("PTHREAD_CANCEL_ASYNCHRONOUS", posix.PTHREAD_CANCEL_ASYNCHRONOUS)
	fmt.println("PTHREAD_CANCEL_DEFERRED",     posix.PTHREAD_CANCEL_DEFERRED)

	fmt.println("PTHREAD_CANCEL_DISABLE",      posix.PTHREAD_CANCEL_DISABLE)
	fmt.println("PTHREAD_CANCEL_ENABLE",       posix.PTHREAD_CANCEL_ENABLE)

	fmt.printfln("PTHREAD_CANCELED %#x",       posix.PTHREAD_CANCELED)

	fmt.println("PTHREAD_CREATE_JOINABLE",     posix.PTHREAD_CREATE_JOINABLE)
	fmt.println("PTHREAD_CREATE_DETACHED",     posix.PTHREAD_CREATE_DETACHED)

	fmt.println("PTHREAD_EXPLICIT_SCHED",      posix.PTHREAD_EXPLICIT_SCHED)
	fmt.println("PTHREAD_INHERIT_SCHED",       posix.PTHREAD_INHERIT_SCHED)

	fmt.println("PTHREAD_PRIO_INHERIT",        posix.PTHREAD_PRIO_INHERIT)
	fmt.println("PTHREAD_PRIO_NONE",           posix.PTHREAD_PRIO_NONE)
	fmt.println("PTHREAD_PRIO_PROTECT",        posix.PTHREAD_PRIO_PROTECT)

	fmt.println("PTHREAD_PROCESS_SHARED",      posix.PTHREAD_PROCESS_SHARED)
	fmt.println("PTHREAD_PROCESS_PRIVATE",     posix.PTHREAD_PROCESS_PRIVATE)

	fmt.println("PTHREAD_SCOPE_PROCESS",       posix.PTHREAD_SCOPE_PROCESS)
	fmt.println("PTHREAD_SCOPE_SYSTEM",        posix.PTHREAD_SCOPE_SYSTEM)
}
