package darwin

// IMPORTANT NOTE: direct syscall usage is not allowed by Apple's review process of apps and should
// be entirely avoided in the builtin Odin collections, these are here for users if they don't
// care about the Apple review process.

unix_offset_syscall :: proc "contextless" (number: System_Call_Number) -> uintptr {
	return uintptr(number) + uintptr(0x2000000)
}

System_Call_Number :: enum uintptr {
	/* 0 syscall */
	exit = 1,
	fork = 2,
	read = 3,
	write = 4,
	open = 5,
	close = 6,
	wait4 = 7,
	/* 8  old creat */
	link = 9,
	unlink = 10,
	/* 11  old execv */
	chdir = 12,
	fchdir = 13,
	mknod = 14,
	chmod = 15,
	chown = 16,
	/* 17  old break */
	getfsstat = 18,
	/* 19  old lseek */
	getpid = 20,
	/* 21  old mount */
	/* 22  old umount */
	setuid = 23,
	getuid = 24,
	geteuid = 25,
	ptrace = 26,
	recvmsg = 27,
	sendmsg = 28,
	recvfrom = 29,
	accept = 30,
	getpeername = 31,
	getsockname = 32,
	access = 33,
	chflags = 34,
	fchflags = 35,
	sync = 36,
	kill = 37,
	/* 38  old stat */
	getppid = 39,
	/* 40  old lstat */
	dup = 41,
	pipe = 42,
	getegid = 43,
	/* 44  old profil */
	/* 45  old ktrace */
	sigaction = 46,
	getgid = 47,
	sigprocmask = 48,
	getlogin = 49,
	setlogin = 50,
	acct = 51,
	sigpending = 52,
	sigaltstack = 53,
	ioctl = 54,
	reboot = 55,
	revoke = 56,
	symlink = 57,
	readlink = 58,
	execve = 59,
	umask = 60,
	chroot = 61,
	/* 62  old fstat */
	/* 63  used internally and reserved */
	/* getpagesize = 64, invalid */
	msync = 65,
	vfork = 66,
	/* 67  old vread */
	/* 68  old vwrite */
	/* 69  old sbrk */
	/* 70  old sstk */
	/* 71  old mmap */
	/* 72  old vadvise */
	munmap = 73,
	mprotect = 74,
	madvise = 75,
	/* 76  old vhangup */
	/* 77  old vlimit */
	mincore = 78,
	getgroups = 79,
	setgroups = 80,
	getpgrp = 81,
	setpgid = 82,
	setitimer = 83,
	/* 84  old wait */
	swapon = 85,
	getitimer = 86,
	/* 87  old gethostname */
	/* 88  old sethostname */
	getdtablesize = 89,
	dup2 = 90,
	/* 91  old getdopt */
	fcntl = 92,
	select = 93,
	/* 94  old setdopt */
	fsync = 95,
	setpriority = 96,
	socket = 97,
	connect = 98,
	/* 99  old accept */
	getpriority = 100,
	/* 101  old send */
	/* 102  old recv */
	/* 103  old sigreturn */
	bind = 104,
	setsockopt = 105,
	listen = 106,
	/* 107  old vtimes */
	/* 108  old sigvec */
	/* 109  old sigblock */
	/* 110  old sigsetmask */
	sigsuspend = 111,
	/* 112  old sigstack */
	/* 113  old recvmsg */
	/* 114  old sendmsg */
	/* 115  old vtrace */
	gettimeofday = 116,
	getrusage = 117,
	getsockopt = 118,
	/* 119  old resuba */
	readv = 120,
	writev = 121,
	settimeofday = 122,
	fchown = 123,
	fchmod = 124,
	/* 125  old recvfrom */
	setreuid = 126,
	setregid = 127,
	rename = 128,
	/* 129  old truncate */
	/* 130  old ftruncate */
	flock = 131,
	mkfifo = 132,
	sendto = 133,
	shutdown = 134,
	socketpair = 135,
	mkdir = 136,
	rmdir = 137,
	utimes = 138,
	futimes = 139,
	adjtime = 140,
	/* 141  old getpeername */
	gethostuuid = 142,
	/* 143  old sethostid */
	/* 144  old getrlimit */
	/* 145  old setrlimit */
	/* 146  old killpg */
	setsid = 147,
	/* 148  old setquota */
	/* 149  old qquota */
	/* 150  old getsockname */
	getpgid = 151,
	setprivexec = 152,
	pread = 153,
	pwrite = 154,
	nfssvc = 155,
	/* 156  old getdirentries */
	statfs = 157,
	fstatfs = 158,
	unmount = 159,
	/* 160  old async_daemon */
	getfh = 161,
	/* 162  old getdomainname */
	/* 163  old setdomainname */
	/* 164  */
	quotactl = 165,
	/* 166  old exportfs */
	mount = 167,
	/* 168  old ustat */
	csops = 169,
	csops_audittoken = 170,
	/* 171  old wait3 */
	/* 172  old rpause */
	waitid = 173,
	/* 174  old getdents */
	/* 175  old gc_control */
	/* 176  old add_profil */
	kdebug_typefilter = 177,
	kdebug_trace_string = 178,
	kdebug_trace64 = 179,
	kdebug_trace = 180,
	setgid = 181,
	setegid = 182,
	seteuid = 183,
	sigreturn = 184,
	/* 185  old chud */
	thread_selfcounts = 186,
	fdatasync = 187,
	stat = 188,
	fstat = 189,
	lstat = 190,
	pathconf = 191,
	fpathconf = 192,
	/* 193  old getfsstat */
	getrlimit = 194,
	setrlimit = 195,
	getdirentries = 196,
	mmap = 197,
	/* 198  old __syscall */
	lseek = 199,
	truncate = 200,
	ftruncate = 201,
	sysctl = 202,
	mlock = 203,
	munlock = 204,
	undelete = 205,
	/* 206  old ATsocket */
	/* 207  old ATgetmsg */
	/* 208  old ATputmsg */
	/* 209  old ATsndreq */
	/* 210  old ATsndrsp */
	/* 211  old ATgetreq */
	/* 212  old ATgetrsp */
	/* 213  Reserved for AppleTalk */
	/* 214  */
	/* 215  */
	open_dprotected_np = 216,
	fsgetpath_ext = 217,
	/* 218  old lstatv */
	/* 219  old fstatv */
	getattrlist = 220,
	setattrlist = 221,
	getdirentriesattr = 222,
	exchangedata = 223,
	/* 224  old checkuseraccess or fsgetpath */
	searchfs = 225,
	delete = 226,
	copyfile = 227,
	fgetattrlist = 228,
	fsetattrlist = 229,
	poll = 230,
	/* 231  old watchevent */
	/* 232  old waitevent */
	/* 233  old modwatch */
	getxattr = 234,
	fgetxattr = 235,
	setxattr = 236,
	fsetxattr = 237,
	removexattr = 238,
	fremovexattr = 239,
	listxattr = 240,
	flistxattr = 241,
	fsctl = 242,
	initgroups = 243,
	posix_spawn = 244,
	ffsctl = 245,
	/* 246  */
	nfsclnt = 247,
	fhopen = 248,
	/* 249  */
	minherit = 250,
	semsys = 251,
	msgsys = 252,
	shmsys = 253,
	semctl = 254,
	semget = 255,
	semop = 256,
	/* 257  old semconfig */
	msgctl = 258,
	msgget = 259,
	msgsnd = 260,
	msgrcv = 261,
	shmat = 262,
	shmctl = 263,
	shmdt = 264,
	shmget = 265,
	shm_open = 266,
	shm_unlink = 267,
	sem_open = 268,
	sem_close = 269,
	sem_unlink = 270,
	sem_wait = 271,
	sem_trywait = 272,
	sem_post = 273,
	sysctlbyname = 274,
	/* 275  old sem_init */
	/* 276  old sem_destroy */
	open_extended = 277,
	umask_extended = 278,
	stat_extended = 279,
	lstat_extended = 280,
	fstat_extended = 281,
	chmod_extended = 282,
	fchmod_extended = 283,
	access_extended = 284,
	settid = 285,
	gettid = 286,
	setsgroups = 287,
	getsgroups = 288,
	setwgroups = 289,
	getwgroups = 290,
	mkfifo_extended = 291,
	mkdir_extended = 292,
	identitysvc = 293,
	shared_region_check_np = 294,
	/* 295  old shared_region_map_np */
	vm_pressure_monitor = 296,
	psynch_rw_longrdlock = 297,
	psynch_rw_yieldwrlock = 298,
	psynch_rw_downgrade = 299,
	psynch_rw_upgrade = 300,
	psynch_mutexwait = 301,
	psynch_mutexdrop = 302,
	psynch_cvbroad = 303,
	psynch_cvsignal = 304,
	psynch_cvwait = 305,
	psynch_rw_rdlock = 306,
	psynch_rw_wrlock = 307,
	psynch_rw_unlock = 308,
	psynch_rw_unlock2 = 309,
	getsid = 310,
	settid_with_pid = 311,
	psynch_cvclrprepost = 312,
	aio_fsync = 313,
	aio_return = 314,
	aio_suspend = 315,
	aio_cancel = 316,
	aio_error = 317,
	aio_read = 318,
	aio_write = 319,
	lio_listio = 320,
	/* 321  old __pthread_cond_wait */
	iopolicysys = 322,
	process_policy = 323,
	mlockall = 324,
	munlockall = 325,
	/* 326  */
	issetugid = 327,
	__pthread_kill = 328,
	__pthread_sigmask = 329,
	__sigwait = 330,
	__disable_threadsignal = 331,
	__pthread_markcancel = 332,
	__pthread_canceled = 333,
	__semwait_signal = 334,
	/* 335  old utrace */
	proc_info = 336,
	sendfile = 337,
	stat64 = 338,
	fstat64 = 339,
	lstat64 = 340,
	stat64_extended = 341,
	lstat64_extended = 342,
	fstat64_extended = 343,
	getdirentries64 = 344,
	statfs64 = 345,
	fstatfs64 = 346,
	getfsstat64 = 347,
	__pthread_chdir = 348,
	__pthread_fchdir = 349,
	audit = 350,
	auditon = 351,
	/* 352  */
	getauid = 353,
	setauid = 354,
	/* 355  old getaudit */
	/* 356  old setaudit */
	getaudit_addr = 357,
	setaudit_addr = 358,
	auditctl = 359,
	bsdthread_create = 360,
	bsdthread_terminate = 361,
	kqueue = 362,
	kevent = 363,
	lchown = 364,
	/* 365  old stack_snapshot */
	bsdthread_register = 366,
	workq_open = 367,
	workq_kernreturn = 368,
	kevent64 = 369,
	__old_semwait_signal = 370,
	__old_semwait_signal_nocancel = 371,
	thread_selfid = 372,
	ledger = 373,
	kevent_qos = 374,
	kevent_id = 375,
	/* 376  */
	/* 377  */
	/* 378  */
	/* 379  */
	__mac_execve = 380,
	__mac_syscall = 381,
	__mac_get_file = 382,
	__mac_set_file = 383,
	__mac_get_link = 384,
	__mac_set_link = 385,
	__mac_get_proc = 386,
	__mac_set_proc = 387,
	__mac_get_fd = 388,
	__mac_set_fd = 389,
	__mac_get_pid = 390,
	/* 391  */
	/* 392  */
	/* 393  */
	pselect = 394,
	pselect_nocancel = 395,
	read_nocancel = 396,
	write_nocancel = 397,
	open_nocancel = 398,
	close_nocancel = 399,
	wait4_nocancel = 400,
	recvmsg_nocancel = 401,
	sendmsg_nocancel = 402,
	recvfrom_nocancel = 403,
	accept_nocancel = 404,
	msync_nocancel = 405,
	fcntl_nocancel = 406,
	select_nocancel = 407,
	fsync_nocancel = 408,
	connect_nocancel = 409,
	sigsuspend_nocancel = 410,
	readv_nocancel = 411,
	writev_nocancel = 412,
	sendto_nocancel = 413,
	pread_nocancel = 414,
	pwrite_nocancel = 415,
	waitid_nocancel = 416,
	poll_nocancel = 417,
	msgsnd_nocancel = 418,
	msgrcv_nocancel = 419,
	sem_wait_nocancel = 420,
	aio_suspend_nocancel = 421,
	__sigwait_nocancel = 422,
	__semwait_signal_nocancel = 423,
	__mac_mount = 424,
	__mac_get_mount = 425,
	__mac_getfsstat = 426,
	fsgetpath = 427,
	audit_session_self = 428,
	audit_session_join = 429,
	fileport_makeport = 430,
	fileport_makefd = 431,
	audit_session_port = 432,
	pid_suspend = 433,
	pid_resume = 434,
	pid_hibernate = 435,
	pid_shutdown_sockets = 436,
	/* 437  old shared_region_slide_np */
	shared_region_map_and_slide_np = 438,
	kas_info = 439,
	memorystatus_control = 440,
	guarded_open_np = 441,
	guarded_close_np = 442,
	guarded_kqueue_np = 443,
	change_fdguard_np = 444,
	usrctl = 445,
	proc_rlimit_control = 446,
	connectx = 447,
	disconnectx = 448,
	peeloff = 449,
	socket_delegate = 450,
	telemetry = 451,
	proc_uuid_policy = 452,
	memorystatus_get_level = 453,
	system_override = 454,
	vfs_purge = 455,
	sfi_ctl = 456,
	sfi_pidctl = 457,
	coalition = 458,
	coalition_info = 459,
	necp_match_policy = 460,
	getattrlistbulk = 461,
	clonefileat = 462,
	openat = 463,
	openat_nocancel = 464,
	renameat = 465,
	faccessat = 466,
	fchmodat = 467,
	fchownat = 468,
	fstatat = 469,
	fstatat64 = 470,
	linkat = 471,
	unlinkat = 472,
	readlinkat = 473,
	symlinkat = 474,
	mkdirat = 475,
	getattrlistat = 476,
	proc_trace_log = 477,
	bsdthread_ctl = 478,
	openbyid_np = 479,
	recvmsg_x = 480,
	sendmsg_x = 481,
	thread_selfusage = 482,
	csrctl = 483,
	guarded_open_dprotected_np = 484,
	guarded_write_np = 485,
	guarded_pwrite_np = 486,
	guarded_writev_np = 487,
	renameatx_np = 488,
	mremap_encrypted = 489,
	netagent_trigger = 490,
	stack_snapshot_with_config = 491,
	microstackshot = 492,
	grab_pgo_data = 493,
	persona = 494,
	/* 495  */
	mach_eventlink_signal = 496,
	mach_eventlink_wait_until = 497,
	mach_eventlink_signal_wait_until = 498,
	work_interval_ctl = 499,
	getentropy = 500,
	necp_open = 501,
	necp_client_action = 502,
	nexus_open = 503,       // for those who are intressted http://newosxbook.com/bonus/vol1ch16.html
	nexus_register = 504,
	nexus_deregister = 505,
	nexus_create = 506,
	nexus_destroy = 507,
	nexus_get_opt = 508,
	nexus_set_opt = 509,
	channel_open = 510,
	channel_get_info = 511,
	channel_sync = 512,
	channel_get_opt = 513,
	channel_set_opt = 514,
	ulock_wait = 515,
	ulock_wake = 516,
	fclonefileat = 517,
	fs_snapshot = 518,
	register_uexc_handler = 519,
	terminate_with_payload = 520,
	abort_with_payload = 521,
	necp_session_open = 522,
	necp_session_action = 523,
	setattrlistat = 524,
	net_qos_guideline = 525,
	fmount = 526,
	ntp_adjtime = 527,
	ntp_gettime = 528,
	os_fault_with_payload = 529,
	kqueue_workloop_ctl = 530,
	mach_bridge_remote_time = 531,
	coalition_ledger = 532,
	log_data = 533,
	memorystatus_available_memory = 534,
	objc_bp_assist_cfg_np = 535,
	shared_region_map_and_slide_2_np = 536,
	pivot_root = 537,
	task_inspect_for_pid = 538,
	task_read_for_pid = 539,
	preadv = 540,
	pwritev = 541,
	preadv_nocancel = 542,
	pwritev_nocancel = 543,
	ulock_wait2 = 544,
	proc_info_extended_id = 545,
	tracker_action = 546,
	debug_syscall_reject = 547,
	MAXSYSCALL = 548,
	/* invalid = 63, */
}
