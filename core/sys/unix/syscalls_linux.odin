package unix

import "base:intrinsics"

// Linux has inconsistent system call numbering across architectures,
// for largely historical reasons.  This attempts to provide a unified
// Odin-side interface for system calls that are required for the core
// library to work.

// For authorative system call numbers, the following files in the kernel
// source can be used:
//
//  amd64: arch/x86/entry/syscalls/syscall_64.tbl
//  arm64: include/uapi/asm-generic/unistd.h
//  386: arch/x86/entry/syscalls/sycall_32.tbl
//  arm: arch/arm/tools/syscall.tbl

when ODIN_ARCH == .amd64 {
	SYS_read : uintptr : 0
	SYS_write : uintptr : 1
	SYS_open : uintptr : 2
	SYS_close : uintptr : 3
	SYS_stat : uintptr : 4
	SYS_fstat : uintptr : 5
	SYS_lstat : uintptr : 6
	SYS_poll : uintptr : 7
	SYS_lseek : uintptr : 8
	SYS_mmap : uintptr : 9
	SYS_mprotect : uintptr : 10
	SYS_munmap : uintptr : 11
	SYS_brk : uintptr : 12
	SYS_rt_sigaction : uintptr : 13
	SYS_rt_sigprocmask : uintptr : 14
	SYS_rt_sigreturn : uintptr : 15
	SYS_ioctl : uintptr : 16
	SYS_pread64 : uintptr : 17
	SYS_pwrite64 : uintptr : 18
	SYS_readv : uintptr : 19
	SYS_writev : uintptr : 20
	SYS_access : uintptr : 21
	SYS_pipe : uintptr : 22
	SYS_select : uintptr : 23
	SYS_sched_yield : uintptr : 24
	SYS_mremap : uintptr : 25
	SYS_msync : uintptr : 26
	SYS_mincore : uintptr : 27
	SYS_madvise : uintptr : 28
	SYS_shmget : uintptr : 29
	SYS_shmat : uintptr : 30
	SYS_shmctl : uintptr : 31
	SYS_dup : uintptr : 32
	SYS_dup2 : uintptr : 33
	SYS_pause : uintptr : 34
	SYS_nanosleep : uintptr : 35
	SYS_getitimer : uintptr : 36
	SYS_alarm : uintptr : 37
	SYS_setitimer : uintptr : 38
	SYS_getpid : uintptr : 39
	SYS_sendfile : uintptr : 40
	SYS_socket : uintptr : 41
	SYS_connect : uintptr : 42
	SYS_accept : uintptr : 43
	SYS_sendto : uintptr : 44
	SYS_recvfrom : uintptr : 45
	SYS_sendmsg : uintptr : 46
	SYS_recvmsg : uintptr : 47
	SYS_shutdown : uintptr : 48
	SYS_bind : uintptr : 49
	SYS_listen : uintptr : 50
	SYS_getsockname : uintptr : 51
	SYS_getpeername : uintptr : 52
	SYS_socketpair : uintptr : 53
	SYS_setsockopt : uintptr : 54
	SYS_getsockopt : uintptr : 55
	SYS_clone : uintptr : 56
	SYS_fork : uintptr : 57
	SYS_vfork : uintptr : 58
	SYS_execve : uintptr : 59
	SYS_exit : uintptr : 60
	SYS_wait4 : uintptr : 61
	SYS_kill : uintptr : 62
	SYS_uname : uintptr : 63
	SYS_semget : uintptr : 64
	SYS_semop : uintptr : 65
	SYS_semctl : uintptr : 66
	SYS_shmdt : uintptr : 67
	SYS_msgget : uintptr : 68
	SYS_msgsnd : uintptr : 69
	SYS_msgrcv : uintptr : 70
	SYS_msgctl : uintptr : 71
	SYS_fcntl : uintptr : 72
	SYS_flock : uintptr : 73
	SYS_fsync : uintptr : 74
	SYS_fdatasync : uintptr : 75
	SYS_truncate : uintptr : 76
	SYS_ftruncate : uintptr : 77
	SYS_getdents : uintptr : 78
	SYS_getcwd : uintptr : 79
	SYS_chdir : uintptr : 80
	SYS_fchdir : uintptr : 81
	SYS_rename : uintptr : 82
	SYS_mkdir : uintptr : 83
	SYS_rmdir : uintptr : 84
	SYS_creat : uintptr : 85
	SYS_link : uintptr : 86
	SYS_unlink : uintptr : 87
	SYS_symlink : uintptr : 88
	SYS_readlink : uintptr : 89
	SYS_chmod : uintptr : 90
	SYS_fchmod : uintptr : 91
	SYS_chown : uintptr : 92
	SYS_fchown : uintptr : 93
	SYS_lchown : uintptr : 94
	SYS_umask : uintptr : 95
	SYS_gettimeofday : uintptr : 96
	SYS_getrlimit : uintptr : 97
	SYS_getrusage : uintptr : 98
	SYS_sysinfo : uintptr : 99
	SYS_times : uintptr : 100
	SYS_ptrace : uintptr : 101
	SYS_getuid : uintptr : 102
	SYS_syslog : uintptr : 103
	SYS_getgid : uintptr : 104
	SYS_setuid : uintptr : 105
	SYS_setgid : uintptr : 106
	SYS_geteuid : uintptr : 107
	SYS_getegid : uintptr : 108
	SYS_setpgid : uintptr : 109
	SYS_getppid : uintptr : 110
	SYS_getpgrp : uintptr : 111
	SYS_setsid : uintptr : 112
	SYS_setreuid : uintptr : 113
	SYS_setregid : uintptr : 114
	SYS_getgroups : uintptr : 115
	SYS_setgroups : uintptr : 116
	SYS_setresuid : uintptr : 117
	SYS_getresuid : uintptr : 118
	SYS_setresgid : uintptr : 119
	SYS_getresgid : uintptr : 120
	SYS_getpgid : uintptr : 121
	SYS_setfsuid : uintptr : 122
	SYS_setfsgid : uintptr : 123
	SYS_getsid : uintptr : 124
	SYS_capget : uintptr : 125
	SYS_capset : uintptr : 126
	SYS_rt_sigpending : uintptr : 127
	SYS_rt_sigtimedwait : uintptr : 128
	SYS_rt_sigqueueinfo : uintptr : 129
	SYS_rt_sigsuspend : uintptr : 130
	SYS_sigaltstack : uintptr : 131
	SYS_utime : uintptr : 132
	SYS_mknod : uintptr : 133
	SYS_uselib : uintptr : 134
	SYS_personality : uintptr : 135
	SYS_ustat : uintptr : 136
	SYS_statfs : uintptr : 137
	SYS_fstatfs : uintptr : 138
	SYS_sysfs : uintptr : 139
	SYS_getpriority : uintptr : 140
	SYS_setpriority : uintptr : 141
	SYS_sched_setparam : uintptr : 142
	SYS_sched_getparam : uintptr : 143
	SYS_sched_setscheduler : uintptr : 144
	SYS_sched_getscheduler : uintptr : 145
	SYS_sched_get_priority_max : uintptr : 146
	SYS_sched_get_priority_min : uintptr : 147
	SYS_sched_rr_get_interval : uintptr : 148
	SYS_mlock : uintptr : 149
	SYS_munlock : uintptr : 150
	SYS_mlockall : uintptr : 151
	SYS_munlockall : uintptr : 152
	SYS_vhangup : uintptr : 153
	SYS_modify_ldt : uintptr : 154
	SYS_pivot_root : uintptr : 155
	SYS__sysctl : uintptr : 156
	SYS_prctl : uintptr : 157
	SYS_arch_prctl : uintptr : 158
	SYS_adjtimex : uintptr : 159
	SYS_setrlimit : uintptr : 160
	SYS_chroot : uintptr : 161
	SYS_sync : uintptr : 162
	SYS_acct : uintptr : 163
	SYS_settimeofday : uintptr : 164
	SYS_mount : uintptr : 165
	SYS_umount2 : uintptr : 166
	SYS_swapon : uintptr : 167
	SYS_swapoff : uintptr : 168
	SYS_reboot : uintptr : 169
	SYS_sethostname : uintptr : 170
	SYS_setdomainname : uintptr : 171
	SYS_iopl : uintptr : 172
	SYS_ioperm : uintptr : 173
	SYS_create_module : uintptr : 174
	SYS_init_module : uintptr : 175
	SYS_delete_module : uintptr : 176
	SYS_get_kernel_syms : uintptr : 177
	SYS_query_module : uintptr : 178
	SYS_quotactl : uintptr : 179
	SYS_nfsservctl : uintptr : 180
	SYS_getpmsg : uintptr : 181
	SYS_putpmsg : uintptr : 182
	SYS_afs_syscall : uintptr : 183
	SYS_tuxcall : uintptr : 184
	SYS_security : uintptr : 185
	SYS_gettid : uintptr : 186
	SYS_readahead : uintptr : 187
	SYS_setxattr : uintptr : 188
	SYS_lsetxattr : uintptr : 189
	SYS_fsetxattr : uintptr : 190
	SYS_getxattr : uintptr : 191
	SYS_lgetxattr : uintptr : 192
	SYS_fgetxattr : uintptr : 193
	SYS_listxattr : uintptr : 194
	SYS_llistxattr : uintptr : 195
	SYS_flistxattr : uintptr : 196
	SYS_removexattr : uintptr : 197
	SYS_lremovexattr : uintptr : 198
	SYS_fremovexattr : uintptr : 199
	SYS_tkill : uintptr : 200
	SYS_time : uintptr : 201
	SYS_futex : uintptr : 202
	SYS_sched_setaffinity : uintptr : 203
	SYS_sched_getaffinity : uintptr : 204
	SYS_set_thread_area : uintptr : 205
	SYS_io_setup : uintptr : 206
	SYS_io_destroy : uintptr : 207
	SYS_io_getevents : uintptr : 208
	SYS_io_submit : uintptr : 209
	SYS_io_cancel : uintptr : 210
	SYS_get_thread_area : uintptr : 211
	SYS_lookup_dcookie : uintptr : 212
	SYS_epoll_create : uintptr : 213
	SYS_epoll_ctl_old : uintptr : 214
	SYS_epoll_wait_old : uintptr : 215
	SYS_remap_file_pages : uintptr : 216
	SYS_getdents64 : uintptr : 217
	SYS_set_tid_address : uintptr : 218
	SYS_restart_syscall : uintptr : 219
	SYS_semtimedop : uintptr : 220
	SYS_fadvise64 : uintptr : 221
	SYS_timer_create : uintptr : 222
	SYS_timer_settime : uintptr : 223
	SYS_timer_gettime : uintptr : 224
	SYS_timer_getoverrun : uintptr : 225
	SYS_timer_delete : uintptr : 226
	SYS_clock_settime : uintptr : 227
	SYS_clock_gettime : uintptr : 228
	SYS_clock_getres : uintptr : 229
	SYS_clock_nanosleep : uintptr : 230
	SYS_exit_group : uintptr : 231
	SYS_epoll_wait : uintptr : 232
	SYS_epoll_ctl : uintptr : 233
	SYS_tgkill : uintptr : 234
	SYS_utimes : uintptr : 235
	SYS_vserver : uintptr : 236
	SYS_mbind : uintptr : 237
	SYS_set_mempolicy : uintptr : 238
	SYS_get_mempolicy : uintptr : 239
	SYS_mq_open : uintptr : 240
	SYS_mq_unlink : uintptr : 241
	SYS_mq_timedsend : uintptr : 242
	SYS_mq_timedreceive : uintptr : 243
	SYS_mq_notify : uintptr : 244
	SYS_mq_getsetattr : uintptr : 245
	SYS_kexec_load : uintptr : 246
	SYS_waitid : uintptr : 247
	SYS_add_key : uintptr : 248
	SYS_request_key : uintptr : 249
	SYS_keyctl : uintptr : 250
	SYS_ioprio_set : uintptr : 251
	SYS_ioprio_get : uintptr : 252
	SYS_inotify_init : uintptr : 253
	SYS_inotify_add_watch : uintptr : 254
	SYS_inotify_rm_watch : uintptr : 255
	SYS_migrate_pages : uintptr : 256
	SYS_openat : uintptr : 257
	SYS_mkdirat : uintptr : 258
	SYS_mknodat : uintptr : 259
	SYS_fchownat : uintptr : 260
	SYS_futimesat : uintptr : 261
	SYS_fstatat : uintptr : 262
	SYS_unlinkat : uintptr : 263
	SYS_renameat : uintptr : 264
	SYS_linkat : uintptr : 265
	SYS_symlinkat : uintptr : 266
	SYS_readlinkat : uintptr : 267
	SYS_fchmodat : uintptr : 268
	SYS_faccessat : uintptr : 269
	SYS_pselect6 : uintptr : 270
	SYS_ppoll : uintptr : 271
	SYS_unshare : uintptr : 272
	SYS_set_robust_list : uintptr : 273
	SYS_get_robust_list : uintptr : 274
	SYS_splice : uintptr : 275
	SYS_tee : uintptr : 276
	SYS_sync_file_range : uintptr : 277
	SYS_vmsplice : uintptr : 278
	SYS_move_pages : uintptr : 279
	SYS_utimensat : uintptr : 280
	SYS_epoll_pwait : uintptr : 281
	SYS_signalfd : uintptr : 282
	SYS_timerfd_create : uintptr : 283
	SYS_eventfd : uintptr : 284
	SYS_fallocate : uintptr : 285
	SYS_timerfd_settime : uintptr : 286
	SYS_timerfd_gettime : uintptr : 287
	SYS_accept4 : uintptr : 288
	SYS_signalfd4 : uintptr : 289
	SYS_eventfd2 : uintptr : 290
	SYS_epoll_create1 : uintptr : 291
	SYS_dup3 : uintptr : 292
	SYS_pipe2 : uintptr : 293
	SYS_inotify_init1 : uintptr : 294
	SYS_preadv : uintptr : 295
	SYS_pwritev : uintptr : 296
	SYS_rt_tgsigqueueinfo : uintptr : 297
	SYS_perf_event_open : uintptr : 298
	SYS_recvmmsg : uintptr : 299
	SYS_fanotify_init : uintptr : 300
	SYS_fanotify_mark : uintptr : 301
	SYS_prlimit64 : uintptr : 302
	SYS_name_to_handle_at : uintptr : 303
	SYS_open_by_handle_at : uintptr : 304
	SYS_clock_adjtime : uintptr : 305
	SYS_syncfs : uintptr : 306
	SYS_sendmmsg : uintptr : 307
	SYS_setns : uintptr : 308
	SYS_getcpu : uintptr : 309
	SYS_process_vm_readv : uintptr : 310
	SYS_process_vm_writev : uintptr : 311
	SYS_kcmp : uintptr : 312
	SYS_finit_module : uintptr : 313
	SYS_sched_setattr : uintptr : 314
	SYS_sched_getattr : uintptr : 315
	SYS_renameat2 : uintptr : 316
	SYS_seccomp : uintptr : 317
	SYS_getrandom : uintptr : 318
	SYS_memfd_create : uintptr : 319
	SYS_kexec_file_load : uintptr : 320
	SYS_bpf : uintptr : 321
	SYS_execveat : uintptr : 322
	SYS_userfaultfd : uintptr : 323
	SYS_membarrier : uintptr : 324
	SYS_mlock2 : uintptr : 325
	SYS_copy_file_range : uintptr : 326
	SYS_preadv2 : uintptr : 327
	SYS_pwritev2 : uintptr : 328
	SYS_pkey_mprotect : uintptr : 329
	SYS_pkey_alloc : uintptr : 330
	SYS_pkey_free : uintptr : 331
	SYS_statx : uintptr : 332
	SYS_io_pgetevents : uintptr : 333
	SYS_rseq : uintptr : 334
	SYS_pidfd_send_signal : uintptr : 424
	SYS_io_uring_setup : uintptr : 425
	SYS_io_uring_enter : uintptr : 426
	SYS_io_uring_register : uintptr : 427
	SYS_open_tree : uintptr : 428
	SYS_move_mount : uintptr : 429
	SYS_fsopen : uintptr : 430
	SYS_fsconfig : uintptr : 431
	SYS_fsmount : uintptr : 432
	SYS_fspick : uintptr : 433
	SYS_pidfd_open : uintptr : 434
	SYS_clone3 : uintptr : 435
	SYS_close_range : uintptr : 436
	SYS_openat2 : uintptr : 437
	SYS_pidfd_getfd : uintptr : 438
	SYS_faccessat2 : uintptr : 439
	SYS_process_madvise : uintptr : 440
	SYS_epoll_pwait2 : uintptr : 441
	SYS_mount_setattr : uintptr : 442
	SYS_landlock_create_ruleset : uintptr : 444
	SYS_landlock_add_rule : uintptr : 445
	SYS_landlock_restrict_self : uintptr : 446
	SYS_memfd_secret : uintptr : 447
} else when ODIN_ARCH == .arm64 {
	SYS_io_setup : uintptr : 0
	SYS_io_destroy : uintptr : 1
	SYS_io_submit : uintptr : 2
	SYS_io_cancel : uintptr : 3
	SYS_io_getevents : uintptr : 4
	SYS_setxattr : uintptr : 5
	SYS_lsetxattr : uintptr : 6
	SYS_fsetxattr : uintptr : 7
	SYS_getxattr : uintptr : 8
	SYS_lgetxattr : uintptr : 9
	SYS_fgetxattr : uintptr : 10
	SYS_listxattr : uintptr : 11
	SYS_llistxattr : uintptr : 12
	SYS_flistxattr : uintptr : 13
	SYS_removexattr : uintptr : 14
	SYS_lremovexattr : uintptr : 15
	SYS_fremovexattr : uintptr : 16
	SYS_getcwd : uintptr : 17
	SYS_lookup_dcookie : uintptr : 18
	SYS_eventfd2 : uintptr : 19
	SYS_epoll_create1 : uintptr : 20
	SYS_epoll_ctl : uintptr : 21
	SYS_epoll_pwait : uintptr : 22
	SYS_dup : uintptr : 23
	SYS_dup3 : uintptr : 24
	SYS_fcntl : uintptr : 25
	SYS_inotify_init1 : uintptr : 26
	SYS_inotify_add_watch : uintptr : 27
	SYS_inotify_rm_watch : uintptr : 28
	SYS_ioctl : uintptr : 29
	SYS_ioprio_set : uintptr : 30
	SYS_ioprio_get : uintptr : 31
	SYS_flock : uintptr : 32
	SYS_mknodat : uintptr : 33
	SYS_mkdirat : uintptr : 34
	SYS_unlinkat : uintptr : 35
	SYS_symlinkat : uintptr : 36
	SYS_linkat : uintptr : 37
	SYS_renameat : uintptr : 38
	SYS_umount2 : uintptr : 39
	SYS_mount : uintptr : 40
	SYS_pivot_root : uintptr : 41
	SYS_nfsservctl : uintptr : 42
	SYS_statfs : uintptr : 43
	SYS_fstatfs : uintptr : 44
	SYS_truncate : uintptr : 45
	SYS_ftruncate : uintptr : 46
	SYS_fallocate : uintptr : 47
	SYS_faccessat : uintptr : 48
	SYS_chdir : uintptr : 49
	SYS_fchdir : uintptr : 50
	SYS_chroot : uintptr : 51
	SYS_fchmod : uintptr : 52
	SYS_fchmodat : uintptr : 53
	SYS_fchownat : uintptr : 54
	SYS_fchown : uintptr : 55
	SYS_openat : uintptr : 56
	SYS_close : uintptr : 57
	SYS_vhangup : uintptr : 58
	SYS_pipe2 : uintptr : 59
	SYS_quotactl : uintptr : 60
	SYS_getdents64 : uintptr : 61
	SYS_lseek : uintptr : 62
	SYS_read : uintptr : 63
	SYS_write : uintptr : 64
	SYS_readv : uintptr : 65
	SYS_writev : uintptr : 66
	SYS_pread64 : uintptr : 67
	SYS_pwrite64 : uintptr : 68
	SYS_preadv : uintptr : 69
	SYS_pwritev : uintptr : 70
	SYS_sendfile : uintptr : 71
	SYS_pselect6 : uintptr : 72
	SYS_ppoll : uintptr : 73
	SYS_signalfd4 : uintptr : 74
	SYS_vmsplice : uintptr : 75
	SYS_splice : uintptr : 76
	SYS_tee : uintptr : 77
	SYS_readlinkat : uintptr : 78
	SYS_fstatat : uintptr : 79
	SYS_fstat : uintptr : 80
	SYS_sync : uintptr : 81
	SYS_fsync : uintptr : 82
	SYS_fdatasync : uintptr : 83
	SYS_sync_file_range : uintptr : 84
	SYS_timerfd_create : uintptr : 85
	SYS_timerfd_settime : uintptr : 86
	SYS_timerfd_gettime : uintptr : 87
	SYS_utimensat : uintptr : 88
	SYS_acct : uintptr : 89
	SYS_capget : uintptr : 90
	SYS_capset : uintptr : 91
	SYS_personality : uintptr : 92
	SYS_exit : uintptr : 93
	SYS_exit_group : uintptr : 94
	SYS_waitid : uintptr : 95
	SYS_set_tid_address : uintptr : 96
	SYS_unshare : uintptr : 97
	SYS_futex : uintptr : 98
	SYS_set_robust_list : uintptr : 99
	SYS_get_robust_list : uintptr : 100
	SYS_nanosleep : uintptr : 101
	SYS_getitimer : uintptr : 102
	SYS_setitimer : uintptr : 103
	SYS_kexec_load : uintptr : 104
	SYS_init_module : uintptr : 105
	SYS_delete_module : uintptr : 106
	SYS_timer_create : uintptr : 107
	SYS_timer_gettime : uintptr : 108
	SYS_timer_getoverrun : uintptr : 109
	SYS_timer_settime : uintptr : 110
	SYS_timer_delete : uintptr : 111
	SYS_clock_settime : uintptr : 112
	SYS_clock_gettime : uintptr : 113
	SYS_clock_getres : uintptr : 114
	SYS_clock_nanosleep : uintptr : 115
	SYS_syslog : uintptr : 116
	SYS_ptrace : uintptr : 117
	SYS_sched_setparam : uintptr : 118
	SYS_sched_setscheduler : uintptr : 119
	SYS_sched_getscheduler : uintptr : 120
	SYS_sched_getparam : uintptr : 121
	SYS_sched_setaffinity : uintptr : 122
	SYS_sched_getaffinity : uintptr : 123
	SYS_sched_yield : uintptr : 124
	SYS_sched_get_priority_max : uintptr : 125
	SYS_sched_get_priority_min : uintptr : 126
	SYS_sched_rr_get_interval : uintptr : 127
	SYS_restart_syscall : uintptr : 128
	SYS_kill : uintptr : 129
	SYS_tkill : uintptr : 130
	SYS_tgkill : uintptr : 131
	SYS_sigaltstack : uintptr : 132
	SYS_rt_sigsuspend : uintptr : 133
	SYS_rt_sigaction : uintptr : 134
	SYS_rt_sigprocmask : uintptr : 135
	SYS_rt_sigpending : uintptr : 136
	SYS_rt_sigtimedwait : uintptr : 137
	SYS_rt_sigqueueinfo : uintptr : 138
	SYS_rt_sigreturn : uintptr : 139
	SYS_setpriority : uintptr : 140
	SYS_getpriority : uintptr : 141
	SYS_reboot : uintptr : 142
	SYS_setregid : uintptr : 143
	SYS_setgid : uintptr : 144
	SYS_setreuid : uintptr : 145
	SYS_setuid : uintptr : 146
	SYS_setresuid : uintptr : 147
	SYS_getresuid : uintptr : 148
	SYS_setresgid : uintptr : 149
	SYS_getresgid : uintptr : 150
	SYS_setfsuid : uintptr : 151
	SYS_setfsgid : uintptr : 152
	SYS_times : uintptr : 153
	SYS_setpgid : uintptr : 154
	SYS_getpgid : uintptr : 155
	SYS_getsid : uintptr : 156
	SYS_setsid : uintptr : 157
	SYS_getgroups : uintptr : 158
	SYS_setgroups : uintptr : 159
	SYS_uname : uintptr : 160
	SYS_sethostname : uintptr : 161
	SYS_setdomainname : uintptr : 162
	SYS_getrlimit : uintptr : 163
	SYS_setrlimit : uintptr : 164
	SYS_getrusage : uintptr : 165
	SYS_umask : uintptr : 166
	SYS_prctl : uintptr : 167
	SYS_getcpu : uintptr : 168
	SYS_gettimeofday : uintptr : 169
	SYS_settimeofday : uintptr : 170
	SYS_adjtimex : uintptr : 171
	SYS_getpid : uintptr : 172
	SYS_getppid : uintptr : 173
	SYS_getuid : uintptr : 174
	SYS_geteuid : uintptr : 175
	SYS_getgid : uintptr : 176
	SYS_getegid : uintptr : 177
	SYS_gettid : uintptr : 178
	SYS_sysinfo : uintptr : 179
	SYS_mq_open : uintptr : 180
	SYS_mq_unlink : uintptr : 181
	SYS_mq_timedsend : uintptr : 182
	SYS_mq_timedreceive : uintptr : 183
	SYS_mq_notify : uintptr : 184
	SYS_mq_getsetattr : uintptr : 185
	SYS_msgget : uintptr : 186
	SYS_msgctl : uintptr : 187
	SYS_msgrcv : uintptr : 188
	SYS_msgsnd : uintptr : 189
	SYS_semget : uintptr : 190
	SYS_semctl : uintptr : 191
	SYS_semtimedop : uintptr : 192
	SYS_semop : uintptr : 193
	SYS_shmget : uintptr : 194
	SYS_shmctl : uintptr : 195
	SYS_shmat : uintptr : 196
	SYS_shmdt : uintptr : 197
	SYS_socket : uintptr : 198
	SYS_socketpair : uintptr : 199
	SYS_bind : uintptr : 200
	SYS_listen : uintptr : 201
	SYS_accept : uintptr : 202
	SYS_connect : uintptr : 203
	SYS_getsockname : uintptr : 204
	SYS_getpeername : uintptr : 205
	SYS_sendto : uintptr : 206
	SYS_recvfrom : uintptr : 207
	SYS_setsockopt : uintptr : 208
	SYS_getsockopt : uintptr : 209
	SYS_shutdown : uintptr : 210
	SYS_sendmsg : uintptr : 211
	SYS_recvmsg : uintptr : 212
	SYS_readahead : uintptr : 213
	SYS_brk : uintptr : 214
	SYS_munmap : uintptr : 215
	SYS_mremap : uintptr : 216
	SYS_add_key : uintptr : 217
	SYS_request_key : uintptr : 218
	SYS_keyctl : uintptr : 219
	SYS_clone : uintptr : 220
	SYS_execve : uintptr : 221
	SYS_mmap : uintptr : 222
	SYS_fadvise64 : uintptr : 223
	SYS_swapon : uintptr : 224
	SYS_swapoff : uintptr : 225
	SYS_mprotect : uintptr : 226
	SYS_msync : uintptr : 227
	SYS_mlock : uintptr : 228
	SYS_munlock : uintptr : 229
	SYS_mlockall : uintptr : 230
	SYS_munlockall : uintptr : 231
	SYS_mincore : uintptr : 232
	SYS_madvise : uintptr : 233
	SYS_remap_file_pages : uintptr : 234
	SYS_mbind : uintptr : 235
	SYS_get_mempolicy : uintptr : 236
	SYS_set_mempolicy : uintptr : 237
	SYS_migrate_pages : uintptr : 238
	SYS_move_pages : uintptr : 239
	SYS_rt_tgsigqueueinfo : uintptr : 240
	SYS_perf_event_open : uintptr : 241
	SYS_accept4 : uintptr : 242
	SYS_recvmmsg : uintptr : 243
	SYS_arch_specific_syscall : uintptr : 244
	SYS_wait4 : uintptr : 260
	SYS_prlimit64 : uintptr : 261
	SYS_fanotify_init : uintptr : 262
	SYS_fanotify_mark : uintptr : 263
	SYS_clock_adjtime : uintptr : 266
	SYS_syncfs : uintptr : 267
	SYS_setns : uintptr : 268
	SYS_sendmmsg : uintptr : 269
	SYS_process_vm_readv : uintptr : 270
	SYS_process_vm_writev : uintptr : 271
	SYS_kcmp : uintptr : 272
	SYS_finit_module : uintptr : 273
	SYS_sched_setattr : uintptr : 274
	SYS_sched_getattr : uintptr : 275
	SYS_renameat2 : uintptr : 276
	SYS_seccomp : uintptr : 277
	SYS_getrandom : uintptr : 278
	SYS_memfd_create : uintptr : 279
	SYS_bpf : uintptr : 280
	SYS_execveat : uintptr : 281
	SYS_userfaultfd : uintptr : 282
	SYS_membarrier : uintptr : 283
	SYS_mlock2 : uintptr : 284
	SYS_copy_file_range : uintptr : 285
	SYS_preadv2 : uintptr : 286
	SYS_pwritev2 : uintptr : 287
	SYS_pkey_mprotect : uintptr : 288
	SYS_pkey_alloc : uintptr : 289
	SYS_pkey_free : uintptr : 290
	SYS_statx : uintptr : 291
	SYS_io_pgetevents : uintptr : 292
	SYS_rseq : uintptr : 293
	SYS_kexec_file_load : uintptr : 294
	SYS_pidfd_send_signal : uintptr : 424
	SYS_io_uring_setup : uintptr : 425
	SYS_io_uring_enter : uintptr : 426
	SYS_io_uring_register : uintptr : 427
	SYS_open_tree : uintptr : 428
	SYS_move_mount : uintptr : 429
	SYS_fsopen : uintptr : 430
	SYS_fsconfig : uintptr : 431
	SYS_fsmount : uintptr : 432
	SYS_fspick : uintptr : 433
	SYS_pidfd_open : uintptr : 434
	SYS_clone3 : uintptr : 435
	SYS_close_range : uintptr : 436
	SYS_openat2 : uintptr : 437
	SYS_pidfd_getfd : uintptr : 438
	SYS_faccessat2 : uintptr : 439
	SYS_process_madvise : uintptr : 440
	SYS_epoll_pwait2 : uintptr : 441
	SYS_mount_setattr : uintptr : 442
	SYS_landlock_create_ruleset : uintptr : 444
	SYS_landlock_add_rule : uintptr : 445
	SYS_landlock_restrict_self : uintptr : 446
	
	SIGCHLD :: 17
} else when ODIN_ARCH == .i386 {
	SYS_restart_syscall : uintptr : 0
	SYS_exit : uintptr : 1
	SYS_fork : uintptr : 2
	SYS_read : uintptr : 3
	SYS_write : uintptr : 4
	SYS_open : uintptr : 5
	SYS_close : uintptr : 6
	SYS_waitpid : uintptr : 7
	SYS_creat : uintptr : 8
	SYS_link : uintptr : 9
	SYS_unlink : uintptr : 10
	SYS_execve : uintptr : 11
	SYS_chdir : uintptr : 12
	SYS_time : uintptr : 13
	SYS_mknod : uintptr : 14
	SYS_chmod : uintptr : 15
	SYS_lchown : uintptr : 16
	SYS_break : uintptr : 17
	SYS_oldstat : uintptr : 18
	SYS_lseek : uintptr : 19
	SYS_getpid : uintptr : 20
	SYS_mount : uintptr : 21
	SYS_umount : uintptr : 22
	SYS_setuid : uintptr : 23
	SYS_getuid : uintptr : 24
	SYS_stime : uintptr : 25
	SYS_ptrace : uintptr : 26
	SYS_alarm : uintptr : 27
	SYS_oldfstat : uintptr : 28
	SYS_pause : uintptr : 29
	SYS_utime : uintptr : 30
	SYS_stty : uintptr : 31
	SYS_gtty : uintptr : 32
	SYS_access : uintptr : 33
	SYS_nice : uintptr : 34
	SYS_ftime : uintptr : 35
	SYS_sync : uintptr : 36
	SYS_kill : uintptr : 37
	SYS_rename : uintptr : 38
	SYS_mkdir : uintptr : 39
	SYS_rmdir : uintptr : 40
	SYS_dup : uintptr : 41
	SYS_pipe : uintptr : 42
	SYS_times : uintptr : 43
	SYS_prof : uintptr : 44
	SYS_brk : uintptr : 45
	SYS_setgid : uintptr : 46
	SYS_getgid : uintptr : 47
	SYS_signal : uintptr : 48
	SYS_geteuid : uintptr : 49
	SYS_getegid : uintptr : 50
	SYS_acct : uintptr : 51
	SYS_umount2 : uintptr : 52
	SYS_lock : uintptr : 53
	SYS_ioctl : uintptr : 54
	SYS_fcntl : uintptr : 55
	SYS_mpx : uintptr : 56
	SYS_setpgid : uintptr : 57
	SYS_ulimit : uintptr : 58
	SYS_oldolduname : uintptr : 59
	SYS_umask : uintptr : 60
	SYS_chroot : uintptr : 61
	SYS_ustat : uintptr : 62
	SYS_dup2 : uintptr : 63
	SYS_getppid : uintptr : 64
	SYS_getpgrp : uintptr : 65
	SYS_setsid : uintptr : 66
	SYS_sigaction : uintptr : 67
	SYS_sgetmask : uintptr : 68
	SYS_ssetmask : uintptr : 69
	SYS_setreuid : uintptr : 70
	SYS_setregid : uintptr : 71
	SYS_sigsuspend : uintptr : 72
	SYS_sigpending : uintptr : 73
	SYS_sethostname : uintptr : 74
	SYS_setrlimit : uintptr : 75
	SYS_getrlimit : uintptr : 76
	SYS_getrusage : uintptr : 77
	SYS_gettimeofday : uintptr : 78
	SYS_settimeofday : uintptr : 79
	SYS_getgroups : uintptr : 80
	SYS_setgroups : uintptr : 81
	SYS_select : uintptr : 82
	SYS_symlink : uintptr : 83
	SYS_oldlstat : uintptr : 84
	SYS_readlink : uintptr : 85
	SYS_uselib : uintptr : 86
	SYS_swapon : uintptr : 87
	SYS_reboot : uintptr : 88
	SYS_readdir : uintptr : 89
	SYS_old_mmap : uintptr : 90  // 90 is "sys_old_mmap", we want mmap2
	SYS_munmap : uintptr : 91
	SYS_truncate : uintptr : 92
	SYS_ftruncate : uintptr : 93
	SYS_fchmod : uintptr : 94
	SYS_fchown : uintptr : 95
	SYS_getpriority : uintptr : 96
	SYS_setpriority : uintptr : 97
	SYS_profil : uintptr : 98
	SYS_statfs : uintptr : 99
	SYS_fstatfs : uintptr : 100
	SYS_ioperm : uintptr : 101
	SYS_socketcall : uintptr : 102
	SYS_syslog : uintptr : 103
	SYS_setitimer : uintptr : 104
	SYS_getitimer : uintptr : 105
	SYS_stat : uintptr : 106
	SYS_lstat : uintptr : 107
	SYS_fstat : uintptr : 108
	SYS_olduname : uintptr : 109
	SYS_iopl : uintptr : 110
	SYS_vhangup : uintptr : 111
	SYS_idle : uintptr : 112
	SYS_vm86old : uintptr : 113
	SYS_wait4 : uintptr : 114
	SYS_swapoff : uintptr : 115
	SYS_sysinfo : uintptr : 116
	SYS_ipc : uintptr : 117
	SYS_fsync : uintptr : 118
	SYS_sigreturn : uintptr : 119
	SYS_clone : uintptr : 120
	SYS_setdomainname : uintptr : 121
	SYS_uname : uintptr : 122
	SYS_modify_ldt : uintptr : 123
	SYS_adjtimex : uintptr : 124
	SYS_mprotect : uintptr : 125
	SYS_sigprocmask : uintptr : 126
	SYS_create_module : uintptr : 127
	SYS_init_module : uintptr : 128
	SYS_delete_module : uintptr : 129
	SYS_get_kernel_syms : uintptr : 130
	SYS_quotactl : uintptr : 131
	SYS_getpgid : uintptr : 132
	SYS_fchdir : uintptr : 133
	SYS_bdflush : uintptr : 134
	SYS_sysfs : uintptr : 135
	SYS_personality : uintptr : 136
	SYS_afs_syscall : uintptr : 137
	SYS_setfsuid : uintptr : 138
	SYS_setfsgid : uintptr : 139
	SYS__llseek : uintptr : 140
	SYS_getdents : uintptr : 141
	SYS__newselect : uintptr : 142
	SYS_flock : uintptr : 143
	SYS_msync : uintptr : 144
	SYS_readv : uintptr : 145
	SYS_writev : uintptr : 146
	SYS_getsid : uintptr : 147
	SYS_fdatasync : uintptr : 148
	SYS__sysctl : uintptr : 149
	SYS_mlock : uintptr : 150
	SYS_munlock : uintptr : 151
	SYS_mlockall : uintptr : 152
	SYS_munlockall : uintptr : 153
	SYS_sched_setparam : uintptr : 154
	SYS_sched_getparam : uintptr : 155
	SYS_sched_setscheduler : uintptr : 156
	SYS_sched_getscheduler : uintptr : 157
	SYS_sched_yield : uintptr : 158
	SYS_sched_get_priority_max : uintptr : 159
	SYS_sched_get_priority_min : uintptr : 160
	SYS_sched_rr_get_interval : uintptr : 161
	SYS_nanosleep : uintptr : 162
	SYS_mremap : uintptr : 163
	SYS_setresuid : uintptr : 164
	SYS_getresuid : uintptr : 165
	SYS_vm86 : uintptr : 166
	SYS_query_module : uintptr : 167
	SYS_poll : uintptr : 168
	SYS_nfsservctl : uintptr : 169
	SYS_setresgid : uintptr : 170
	SYS_getresgid : uintptr : 171
	SYS_prctl : uintptr : 172
	SYS_rt_sigreturn : uintptr : 173
	SYS_rt_sigaction : uintptr : 174
	SYS_rt_sigprocmask : uintptr : 175
	SYS_rt_sigpending : uintptr : 176
	SYS_rt_sigtimedwait : uintptr : 177
	SYS_rt_sigqueueinfo : uintptr : 178
	SYS_rt_sigsuspend : uintptr : 179
	SYS_pread64 : uintptr : 180
	SYS_pwrite64 : uintptr : 181
	SYS_chown : uintptr : 182
	SYS_getcwd : uintptr : 183
	SYS_capget : uintptr : 184
	SYS_capset : uintptr : 185
	SYS_sigaltstack : uintptr : 186
	SYS_sendfile : uintptr : 187
	SYS_getpmsg : uintptr : 188
	SYS_putpmsg : uintptr : 189
	SYS_vfork : uintptr : 190
	SYS_ugetrlimit : uintptr : 191
	SYS_mmap : uintptr : 192  // actually mmap2
	SYS_truncate64 : uintptr : 193
	SYS_ftruncate64 : uintptr : 194
	SYS_stat64 : uintptr : 195
	SYS_lstat64 : uintptr : 196
	SYS_fstat64 : uintptr : 197
	SYS_lchown32 : uintptr : 198
	SYS_getuid32 : uintptr : 199
	SYS_getgid32 : uintptr : 200
	SYS_geteuid32 : uintptr : 201
	SYS_getegid32 : uintptr : 202
	SYS_setreuid32 : uintptr : 203
	SYS_setregid32 : uintptr : 204
	SYS_getgroups32 : uintptr : 205
	SYS_setgroups32 : uintptr : 206
	SYS_fchown32 : uintptr : 207
	SYS_setresuid32 : uintptr : 208
	SYS_getresuid32 : uintptr : 209
	SYS_setresgid32 : uintptr : 210
	SYS_getresgid32 : uintptr : 211
	SYS_chown32 : uintptr : 212
	SYS_setuid32 : uintptr : 213
	SYS_setgid32 : uintptr : 214
	SYS_setfsuid32 : uintptr : 215
	SYS_setfsgid32 : uintptr : 216
	SYS_pivot_root : uintptr : 217
	SYS_mincore : uintptr : 218
	SYS_madvise : uintptr : 219
	SYS_getdents64 : uintptr : 220
	SYS_fcntl64 : uintptr : 221
	SYS_gettid : uintptr : 224
	SYS_readahead : uintptr : 225
	SYS_setxattr : uintptr : 226
	SYS_lsetxattr : uintptr : 227
	SYS_fsetxattr : uintptr : 228
	SYS_getxattr : uintptr : 229
	SYS_lgetxattr : uintptr : 230
	SYS_fgetxattr : uintptr : 231
	SYS_listxattr : uintptr : 232
	SYS_llistxattr : uintptr : 233
	SYS_flistxattr : uintptr : 234
	SYS_removexattr : uintptr : 235
	SYS_lremovexattr : uintptr : 236
	SYS_fremovexattr : uintptr : 237
	SYS_tkill : uintptr : 238
	SYS_sendfile64 : uintptr : 239
	SYS_futex : uintptr : 240
	SYS_sched_setaffinity : uintptr : 241
	SYS_sched_getaffinity : uintptr : 242
	SYS_set_thread_area : uintptr : 243
	SYS_get_thread_area : uintptr : 244
	SYS_io_setup : uintptr : 245
	SYS_io_destroy : uintptr : 246
	SYS_io_getevents : uintptr : 247
	SYS_io_submit : uintptr : 248
	SYS_io_cancel : uintptr : 249
	SYS_fadvise64 : uintptr : 250
	SYS_exit_group : uintptr : 252
	SYS_lookup_dcookie : uintptr : 253
	SYS_epoll_create : uintptr : 254
	SYS_epoll_ctl : uintptr : 255
	SYS_epoll_wait : uintptr : 256
	SYS_remap_file_pages : uintptr : 257
	SYS_set_tid_address : uintptr : 258
	SYS_timer_create : uintptr : 259
	SYS_timer_settime : uintptr : 260
	SYS_timer_gettime : uintptr : 261
	SYS_timer_getoverrun : uintptr : 262
	SYS_timer_delete : uintptr : 263
	SYS_clock_settime : uintptr : 264
	SYS_clock_gettime : uintptr : 265
	SYS_clock_getres : uintptr : 266
	SYS_clock_nanosleep : uintptr : 267
	SYS_statfs64 : uintptr : 268
	SYS_fstatfs64 : uintptr : 269
	SYS_tgkill : uintptr : 270
	SYS_utimes : uintptr : 271
	SYS_fadvise64_64 : uintptr : 272
	SYS_vserver : uintptr : 273
	SYS_mbind : uintptr : 274
	SYS_get_mempolicy : uintptr : 275
	SYS_set_mempolicy : uintptr : 276
	SYS_mq_open : uintptr : 277
	SYS_mq_unlink : uintptr : 278
	SYS_mq_timedsend : uintptr : 279
	SYS_mq_timedreceive : uintptr : 280
	SYS_mq_notify : uintptr : 281
	SYS_mq_getsetattr : uintptr : 282
	SYS_kexec_load : uintptr : 283
	SYS_waitid : uintptr : 284
	SYS_add_key : uintptr : 286
	SYS_request_key : uintptr : 287
	SYS_keyctl : uintptr : 288
	SYS_ioprio_set : uintptr : 289
	SYS_ioprio_get : uintptr : 290
	SYS_inotify_init : uintptr : 291
	SYS_inotify_add_watch : uintptr : 292
	SYS_inotify_rm_watch : uintptr : 293
	SYS_migrate_pages : uintptr : 294
	SYS_openat : uintptr : 295
	SYS_mkdirat : uintptr : 296
	SYS_mknodat : uintptr : 297
	SYS_fchownat : uintptr : 298
	SYS_futimesat : uintptr : 299
	SYS_fstatat64 : uintptr : 300
	SYS_unlinkat : uintptr : 301
	SYS_renameat : uintptr : 302
	SYS_linkat : uintptr : 303
	SYS_symlinkat : uintptr : 304
	SYS_readlinkat : uintptr : 305
	SYS_fchmodat : uintptr : 306
	SYS_faccessat : uintptr : 307
	SYS_pselect6 : uintptr : 308
	SYS_ppoll : uintptr : 309
	SYS_unshare : uintptr : 310
	SYS_set_robust_list : uintptr : 311
	SYS_get_robust_list : uintptr : 312
	SYS_splice : uintptr : 313
	SYS_sync_file_range : uintptr : 314
	SYS_tee : uintptr : 315
	SYS_vmsplice : uintptr : 316
	SYS_move_pages : uintptr : 317
	SYS_getcpu : uintptr : 318
	SYS_epoll_pwait : uintptr : 319
	SYS_utimensat : uintptr : 320
	SYS_signalfd : uintptr : 321
	SYS_timerfd_create : uintptr : 322
	SYS_eventfd : uintptr : 323
	SYS_fallocate : uintptr : 324
	SYS_timerfd_settime : uintptr : 325
	SYS_timerfd_gettime : uintptr : 326
	SYS_signalfd4 : uintptr : 327
	SYS_eventfd2 : uintptr : 328
	SYS_epoll_create1 : uintptr : 329
	SYS_dup3 : uintptr : 330
	SYS_pipe2 : uintptr : 331
	SYS_inotify_init1 : uintptr : 332
	SYS_preadv : uintptr : 333
	SYS_pwritev : uintptr : 334
	SYS_rt_tgsigqueueinfo : uintptr : 335
	SYS_perf_event_open : uintptr : 336
	SYS_recvmmsg : uintptr : 337
	SYS_fanotify_init : uintptr : 338
	SYS_fanotify_mark : uintptr : 339
	SYS_prlimit64 : uintptr : 340
	SYS_name_to_handle_at : uintptr : 341
	SYS_open_by_handle_at : uintptr : 342
	SYS_clock_adjtime : uintptr : 343
	SYS_syncfs : uintptr : 344
	SYS_sendmmsg : uintptr : 345
	SYS_setns : uintptr : 346
	SYS_process_vm_readv : uintptr : 347
	SYS_process_vm_writev : uintptr : 348
	SYS_kcmp : uintptr : 349
	SYS_finit_module : uintptr : 350
	SYS_sched_setattr : uintptr : 351
	SYS_sched_getattr : uintptr : 352
	SYS_renameat2 : uintptr : 353
	SYS_seccomp : uintptr : 354
	SYS_getrandom : uintptr : 355
	SYS_memfd_create : uintptr : 356
	SYS_bpf : uintptr : 357
	SYS_execveat : uintptr : 358
	SYS_socket : uintptr : 359
	SYS_socketpair : uintptr : 360
	SYS_bind : uintptr : 361
	SYS_connect : uintptr : 362
	SYS_listen : uintptr : 363
	SYS_accept4 : uintptr : 364
	SYS_getsockopt : uintptr : 365
	SYS_setsockopt : uintptr : 366
	SYS_getsockname : uintptr : 367
	SYS_getpeername : uintptr : 368
	SYS_sendto : uintptr : 369
	SYS_sendmsg : uintptr : 370
	SYS_recvfrom : uintptr : 371
	SYS_recvmsg : uintptr : 372
	SYS_shutdown : uintptr : 373
	SYS_userfaultfd : uintptr : 374
	SYS_membarrier : uintptr : 375
	SYS_mlock2 : uintptr : 376
	SYS_copy_file_range : uintptr : 377
	SYS_preadv2 : uintptr : 378
	SYS_pwritev2 : uintptr : 379
	SYS_pkey_mprotect : uintptr : 380
	SYS_pkey_alloc : uintptr : 381
	SYS_pkey_free : uintptr : 382
	SYS_statx : uintptr : 383
	SYS_arch_prctl : uintptr : 384
	SYS_io_pgetevents : uintptr : 385
	SYS_rseq : uintptr : 386
	SYS_semget : uintptr : 393
	SYS_semctl : uintptr : 394
	SYS_shmget : uintptr : 395
	SYS_shmctl : uintptr : 396
	SYS_shmat : uintptr : 397
	SYS_shmdt : uintptr : 398
	SYS_msgget : uintptr : 399
	SYS_msgsnd : uintptr : 400
	SYS_msgrcv : uintptr : 401
	SYS_msgctl : uintptr : 402
	SYS_clock_gettime64 : uintptr : 403
	SYS_clock_settime64 : uintptr : 404
	SYS_clock_adjtime64 : uintptr : 405
	SYS_clock_getres_time64 : uintptr : 406
	SYS_clock_nanosleep_time64 : uintptr : 407
	SYS_timer_gettime64 : uintptr : 408
	SYS_timer_settime64 : uintptr : 409
	SYS_timerfd_gettime64 : uintptr : 410
	SYS_timerfd_settime64 : uintptr : 411
	SYS_utimensat_time64 : uintptr : 412
	SYS_pselect6_time64 : uintptr : 413
	SYS_ppoll_time64 : uintptr : 414
	SYS_io_pgetevents_time64 : uintptr : 416
	SYS_recvmmsg_time64 : uintptr : 417
	SYS_mq_timedsend_time64 : uintptr : 418
	SYS_mq_timedreceive_time64 : uintptr : 419
	SYS_semtimedop_time64 : uintptr : 420
	SYS_rt_sigtimedwait_time64 : uintptr : 421
	SYS_futex_time64 : uintptr : 422
	SYS_sched_rr_get_interval_time64 : uintptr : 423
	SYS_pidfd_send_signal : uintptr : 424
	SYS_io_uring_setup : uintptr : 425
	SYS_io_uring_enter : uintptr : 426
	SYS_io_uring_register : uintptr : 427
	SYS_open_tree : uintptr : 428
	SYS_move_mount : uintptr : 429
	SYS_fsopen : uintptr : 430
	SYS_fsconfig : uintptr : 431
	SYS_fsmount : uintptr : 432
	SYS_fspick : uintptr : 433
	SYS_pidfd_open : uintptr : 434
	SYS_clone3 : uintptr : 435
	SYS_close_range : uintptr : 436
	SYS_openat2 : uintptr : 437
	SYS_pidfd_getfd : uintptr : 438
	SYS_faccessat2 : uintptr : 439
	SYS_process_madvise : uintptr : 440
	SYS_epoll_pwait2 : uintptr : 441
	SYS_mount_setattr : uintptr : 442
	SYS_landlock_create_ruleset : uintptr : 444
	SYS_landlock_add_rule : uintptr : 445
	SYS_landlock_restrict_self : uintptr : 446
	SYS_memfd_secret : uintptr : 447
} else when ODIN_ARCH == .arm32 { // TODO
	SYS_restart_syscall : uintptr : 0
	SYS_exit : uintptr : 1
	SYS_fork : uintptr : 2
	SYS_read : uintptr : 3
	SYS_write : uintptr : 4
	SYS_open : uintptr : 5
	SYS_close : uintptr : 6
	SYS_creat : uintptr : 8
	SYS_link : uintptr : 9
	SYS_unlink : uintptr : 10
	SYS_execve : uintptr : 11
	SYS_chdir : uintptr : 12
	SYS_mknod : uintptr : 14
	SYS_chmod : uintptr : 15
	SYS_lchown : uintptr : 16
	SYS_lseek : uintptr : 19
	SYS_getpid : uintptr : 20
	SYS_mount : uintptr : 21
	SYS_setuid : uintptr : 23
	SYS_getuid : uintptr : 24
	SYS_ptrace : uintptr : 26
	SYS_pause : uintptr : 29
	SYS_access : uintptr : 33
	SYS_nice : uintptr : 34
	SYS_sync : uintptr : 36
	SYS_kill : uintptr : 37
	SYS_rename : uintptr : 38
	SYS_mkdir : uintptr : 39
	SYS_rmdir : uintptr : 40
	SYS_dup : uintptr : 41
	SYS_pipe : uintptr : 42
	SYS_times : uintptr : 43
	SYS_brk : uintptr : 45
	SYS_setgid : uintptr : 46
	SYS_getgid : uintptr : 47
	SYS_geteuid : uintptr : 49
	SYS_getegid : uintptr : 50
	SYS_acct : uintptr : 51
	SYS_umount2 : uintptr : 52
	SYS_ioctl : uintptr : 54
	SYS_fcntl : uintptr : 55
	SYS_setpgid : uintptr : 57
	SYS_umask : uintptr : 60
	SYS_chroot : uintptr : 61
	SYS_ustat : uintptr : 62
	SYS_dup2 : uintptr : 63
	SYS_getppid : uintptr : 64
	SYS_getpgrp : uintptr : 65
	SYS_setsid : uintptr : 66
	SYS_sigaction : uintptr : 67
	SYS_setreuid : uintptr : 70
	SYS_setregid : uintptr : 71
	SYS_sigsuspend : uintptr : 72
	SYS_sigpending : uintptr : 73
	SYS_sethostname : uintptr : 74
	SYS_setrlimit : uintptr : 75
	SYS_getrusage : uintptr : 77
	SYS_gettimeofday : uintptr : 78
	SYS_settimeofday : uintptr : 79
	SYS_getgroups : uintptr : 80
	SYS_setgroups : uintptr : 81
	SYS_symlink : uintptr : 83
	SYS_readlink : uintptr : 85
	SYS_uselib : uintptr : 86
	SYS_swapon : uintptr : 87
	SYS_reboot : uintptr : 88
	SYS_munmap : uintptr : 91
	SYS_truncate : uintptr : 92
	SYS_ftruncate : uintptr : 93
	SYS_fchmod : uintptr : 94
	SYS_fchown : uintptr : 95
	SYS_getpriority : uintptr : 96
	SYS_setpriority : uintptr : 97
	SYS_statfs : uintptr : 99
	SYS_fstatfs : uintptr : 100
	SYS_syslog : uintptr : 103
	SYS_setitimer : uintptr : 104
	SYS_getitimer : uintptr : 105
	SYS_stat : uintptr : 106
	SYS_lstat : uintptr : 107
	SYS_fstat : uintptr : 108
	SYS_vhangup : uintptr : 111
	SYS_wait4 : uintptr : 114
	SYS_swapoff : uintptr : 115
	SYS_sysinfo : uintptr : 116
	SYS_fsync : uintptr : 118
	SYS_sigreturn : uintptr : 119
	SYS_clone : uintptr : 120
	SYS_setdomainname : uintptr : 121
	SYS_uname : uintptr : 122
	SYS_adjtimex : uintptr : 124
	SYS_mprotect : uintptr : 125
	SYS_sigprocmask : uintptr : 126
	SYS_init_module : uintptr : 128
	SYS_delete_module : uintptr : 129
	SYS_quotactl : uintptr : 131
	SYS_getpgid : uintptr : 132
	SYS_fchdir : uintptr : 133
	SYS_bdflush : uintptr : 134
	SYS_sysfs : uintptr : 135
	SYS_personality : uintptr : 136
	SYS_setfsuid : uintptr : 138
	SYS_setfsgid : uintptr : 139
	SYS__llseek : uintptr : 140
	SYS_getdents : uintptr : 141
	SYS__newselect : uintptr : 142
	SYS_flock : uintptr : 143
	SYS_msync : uintptr : 144
	SYS_readv : uintptr : 145
	SYS_writev : uintptr : 146
	SYS_getsid : uintptr : 147
	SYS_fdatasync : uintptr : 148
	SYS__sysctl : uintptr : 149
	SYS_mlock : uintptr : 150
	SYS_munlock : uintptr : 151
	SYS_mlockall : uintptr : 152
	SYS_munlockall : uintptr : 153
	SYS_sched_setparam : uintptr : 154
	SYS_sched_getparam : uintptr : 155
	SYS_sched_setscheduler : uintptr : 156
	SYS_sched_getscheduler : uintptr : 157
	SYS_sched_yield : uintptr : 158
	SYS_sched_get_priority_max : uintptr : 159
	SYS_sched_get_priority_min : uintptr : 160
	SYS_sched_rr_get_interval : uintptr : 161
	SYS_nanosleep : uintptr : 162
	SYS_mremap : uintptr : 163
	SYS_setresuid : uintptr : 164
	SYS_getresuid : uintptr : 165
	SYS_poll : uintptr : 168
	SYS_nfsservctl : uintptr : 169
	SYS_setresgid : uintptr : 170
	SYS_getresgid : uintptr : 171
	SYS_prctl : uintptr : 172
	SYS_rt_sigreturn : uintptr : 173
	SYS_rt_sigaction : uintptr : 174
	SYS_rt_sigprocmask : uintptr : 175
	SYS_rt_sigpending : uintptr : 176
	SYS_rt_sigtimedwait : uintptr : 177
	SYS_rt_sigqueueinfo : uintptr : 178
	SYS_rt_sigsuspend : uintptr : 179
	SYS_pread64 : uintptr : 180
	SYS_pwrite64 : uintptr : 181
	SYS_chown : uintptr : 182
	SYS_getcwd : uintptr : 183
	SYS_capget : uintptr : 184
	SYS_capset : uintptr : 185
	SYS_sigaltstack : uintptr : 186
	SYS_sendfile : uintptr : 187
	SYS_vfork : uintptr : 190
	SYS_ugetrlimit : uintptr : 191
	SYS_mmap : uintptr : 192  // actually mmap2
	SYS_truncate64 : uintptr : 193
	SYS_ftruncate64 : uintptr : 194
	SYS_stat64 : uintptr : 195
	SYS_lstat64 : uintptr : 196
	SYS_fstat64 : uintptr : 197
	SYS_lchown32 : uintptr : 198
	SYS_getuid32 : uintptr : 199
	SYS_getgid32 : uintptr : 200
	SYS_geteuid32 : uintptr : 201
	SYS_getegid32 : uintptr : 202
	SYS_setreuid32 : uintptr : 203
	SYS_setregid32 : uintptr : 204
	SYS_getgroups32 : uintptr : 205
	SYS_setgroups32 : uintptr : 206
	SYS_fchown32 : uintptr : 207
	SYS_setresuid32 : uintptr : 208
	SYS_getresuid32 : uintptr : 209
	SYS_setresgid32 : uintptr : 210
	SYS_getresgid32 : uintptr : 211
	SYS_chown32 : uintptr : 212
	SYS_setuid32 : uintptr : 213
	SYS_setgid32 : uintptr : 214
	SYS_setfsuid32 : uintptr : 215
	SYS_setfsgid32 : uintptr : 216
	SYS_getdents64 : uintptr : 217
	SYS_pivot_root : uintptr : 218
	SYS_mincore : uintptr : 219
	SYS_madvise : uintptr : 220
	SYS_fcntl64 : uintptr : 221
	SYS_gettid : uintptr : 224
	SYS_readahead : uintptr : 225
	SYS_setxattr : uintptr : 226
	SYS_lsetxattr : uintptr : 227
	SYS_fsetxattr : uintptr : 228
	SYS_getxattr : uintptr : 229
	SYS_lgetxattr : uintptr : 230
	SYS_fgetxattr : uintptr : 231
	SYS_listxattr : uintptr : 232
	SYS_llistxattr : uintptr : 233
	SYS_flistxattr : uintptr : 234
	SYS_removexattr : uintptr : 235
	SYS_lremovexattr : uintptr : 236
	SYS_fremovexattr : uintptr : 237
	SYS_tkill : uintptr : 238
	SYS_sendfile64 : uintptr : 239
	SYS_futex : uintptr : 240
	SYS_sched_setaffinity : uintptr : 241
	SYS_sched_getaffinity : uintptr : 242
	SYS_io_setup : uintptr : 243
	SYS_io_destroy : uintptr : 244
	SYS_io_getevents : uintptr : 245
	SYS_io_submit : uintptr : 246
	SYS_io_cancel : uintptr : 247
	SYS_exit_group : uintptr : 248
	SYS_lookup_dcookie : uintptr : 249
	SYS_epoll_create : uintptr : 250
	SYS_epoll_ctl : uintptr : 251
	SYS_epoll_wait : uintptr : 252
	SYS_remap_file_pages : uintptr : 253
	SYS_set_tid_address : uintptr : 256
	SYS_timer_create : uintptr : 257
	SYS_timer_settime : uintptr : 258
	SYS_timer_gettime : uintptr : 259
	SYS_timer_getoverrun : uintptr : 260
	SYS_timer_delete : uintptr : 261
	SYS_clock_settime : uintptr : 262
	SYS_clock_gettime : uintptr : 263
	SYS_clock_getres : uintptr : 264
	SYS_clock_nanosleep : uintptr : 265
	SYS_statfs64 : uintptr : 266
	SYS_fstatfs64 : uintptr : 267
	SYS_tgkill : uintptr : 268
	SYS_utimes : uintptr : 269
	SYS_fadvise64_64 : uintptr : 270
	SYS_pciconfig_iobase : uintptr : 271
	SYS_pciconfig_read : uintptr : 272
	SYS_pciconfig_write : uintptr : 273
	SYS_mq_open : uintptr : 274
	SYS_mq_unlink : uintptr : 275
	SYS_mq_timedsend : uintptr : 276
	SYS_mq_timedreceive : uintptr : 277
	SYS_mq_notify : uintptr : 278
	SYS_mq_getsetattr : uintptr : 279
	SYS_waitid : uintptr : 280
	SYS_socket : uintptr : 281
	SYS_bind : uintptr : 282
	SYS_connect : uintptr : 283
	SYS_listen : uintptr : 284
	SYS_accept : uintptr : 285
	SYS_getsockname : uintptr : 286
	SYS_getpeername : uintptr : 287
	SYS_socketpair : uintptr : 288
	SYS_send : uintptr : 289
	SYS_sendto : uintptr : 290
	SYS_recv : uintptr : 291
	SYS_recvfrom : uintptr : 292
	SYS_shutdown : uintptr : 293
	SYS_setsockopt : uintptr : 294
	SYS_getsockopt : uintptr : 295
	SYS_sendmsg : uintptr : 296
	SYS_recvmsg : uintptr : 297
	SYS_semop : uintptr : 298
	SYS_semget : uintptr : 299
	SYS_semctl : uintptr : 300
	SYS_msgsnd : uintptr : 301
	SYS_msgrcv : uintptr : 302
	SYS_msgget : uintptr : 303
	SYS_msgctl : uintptr : 304
	SYS_shmat : uintptr : 305
	SYS_shmdt : uintptr : 306
	SYS_shmget : uintptr : 307
	SYS_shmctl : uintptr : 308
	SYS_add_key : uintptr : 309
	SYS_request_key : uintptr : 310
	SYS_keyctl : uintptr : 311
	SYS_semtimedop : uintptr : 312
	SYS_vserver : uintptr : 313
	SYS_ioprio_set : uintptr : 314
	SYS_ioprio_get : uintptr : 315
	SYS_inotify_init : uintptr : 316
	SYS_inotify_add_watch : uintptr : 317
	SYS_inotify_rm_watch : uintptr : 318
	SYS_mbind : uintptr : 319
	SYS_get_mempolicy : uintptr : 320
	SYS_set_mempolicy : uintptr : 321
	SYS_openat : uintptr : 322
	SYS_mkdirat : uintptr : 323
	SYS_mknodat : uintptr : 324
	SYS_fchownat : uintptr : 325
	SYS_futimesat : uintptr : 326
	SYS_fstatat64 : uintptr : 327
	SYS_unlinkat : uintptr : 328
	SYS_renameat : uintptr : 329
	SYS_linkat : uintptr : 330
	SYS_symlinkat : uintptr : 331
	SYS_readlinkat : uintptr : 332
	SYS_fchmodat : uintptr : 333
	SYS_faccessat : uintptr : 334
	SYS_pselect6 : uintptr : 335
	SYS_ppoll : uintptr : 336
	SYS_unshare : uintptr : 337
	SYS_set_robust_list : uintptr : 338
	SYS_get_robust_list : uintptr : 339
	SYS_splice : uintptr : 340
	SYS_sync_file_range : uintptr : 341
	SYS_tee : uintptr : 342
	SYS_vmsplice : uintptr : 343
	SYS_move_pages : uintptr : 344
	SYS_getcpu : uintptr : 345
	SYS_epoll_pwait : uintptr : 346
	SYS_kexec_load : uintptr : 347
	SYS_utimensat : uintptr : 348
	SYS_signalfd : uintptr : 349
	SYS_timerfd_create : uintptr : 350
	SYS_eventfd : uintptr : 351
	SYS_fallocate : uintptr : 352
	SYS_timerfd_settime : uintptr : 353
	SYS_timerfd_gettime : uintptr : 354
	SYS_signalfd4 : uintptr : 355
	SYS_eventfd2 : uintptr : 356
	SYS_epoll_create1 : uintptr : 357
	SYS_dup3 : uintptr : 358
	SYS_pipe2 : uintptr : 359
	SYS_inotify_init1 : uintptr : 360
	SYS_preadv : uintptr : 361
	SYS_pwritev : uintptr : 362
	SYS_rt_tgsigqueueinfo : uintptr : 363
	SYS_perf_event_open : uintptr : 364
	SYS_recvmmsg : uintptr : 365
	SYS_accept4 : uintptr : 366
	SYS_fanotify_init : uintptr : 367
	SYS_fanotify_mark : uintptr : 368
	SYS_prlimit64 : uintptr : 369
	SYS_name_to_handle_at : uintptr : 370
	SYS_open_by_handle_at : uintptr : 371
	SYS_clock_adjtime : uintptr : 372
	SYS_syncfs : uintptr : 373
	SYS_sendmmsg : uintptr : 374
	SYS_setns : uintptr : 375
	SYS_process_vm_readv : uintptr : 376
	SYS_process_vm_writev : uintptr : 377
	SYS_kcmp : uintptr : 378
	SYS_finit_module : uintptr : 379
	SYS_sched_setattr : uintptr : 380
	SYS_sched_getattr : uintptr : 381
	SYS_renameat2 : uintptr : 382
	SYS_seccomp : uintptr : 383
	SYS_getrandom : uintptr : 384
	SYS_memfd_create : uintptr : 385
	SYS_bpf : uintptr : 386
	SYS_execveat : uintptr : 387
	SYS_userfaultfd : uintptr : 388
	SYS_membarrier : uintptr : 389
	SYS_mlock2 : uintptr : 390
	SYS_copy_file_range : uintptr : 391
	SYS_preadv2 : uintptr : 392
	SYS_pwritev2 : uintptr : 393
	SYS_pkey_mprotect : uintptr : 394
	SYS_pkey_alloc : uintptr : 395
	SYS_pkey_free : uintptr : 396
	SYS_statx : uintptr : 397
	SYS_rseq : uintptr : 398
	SYS_io_pgetevents : uintptr : 399
	SYS_migrate_pages : uintptr : 400
	SYS_kexec_file_load : uintptr : 401
	SYS_clock_gettime64 : uintptr : 403
	SYS_clock_settime64 : uintptr : 404
	SYS_clock_adjtime64 : uintptr : 405
	SYS_clock_getres_time64 : uintptr : 406
	SYS_clock_nanosleep_time64 : uintptr : 407
	SYS_timer_gettime64 : uintptr : 408
	SYS_timer_settime64 : uintptr : 409
	SYS_timerfd_gettime64 : uintptr : 410
	SYS_timerfd_settime64 : uintptr : 411
	SYS_utimensat_time64 : uintptr : 412
	SYS_pselect6_time64 : uintptr : 413
	SYS_ppoll_time64 : uintptr : 414
	SYS_io_pgetevents_time64 : uintptr : 416
	SYS_recvmmsg_time64 : uintptr : 417
	SYS_mq_timedsend_time64 : uintptr : 418
	SYS_mq_timedreceive_time64 : uintptr : 419
	SYS_semtimedop_time64 : uintptr : 420
	SYS_rt_sigtimedwait_time64 : uintptr : 421
	SYS_futex_time64 : uintptr : 422
	SYS_sched_rr_get_interval_time64 : uintptr : 423
	SYS_pidfd_send_signal : uintptr : 424
	SYS_io_uring_setup : uintptr : 425
	SYS_io_uring_enter : uintptr : 426
	SYS_io_uring_register : uintptr : 427
	SYS_open_tree : uintptr : 428
	SYS_move_mount : uintptr : 429
	SYS_fsopen : uintptr : 430
	SYS_fsconfig : uintptr : 431
	SYS_fsmount : uintptr : 432
	SYS_fspick : uintptr : 433
	SYS_pidfd_open : uintptr : 434
	SYS_clone3 : uintptr : 435
	SYS_close_range : uintptr : 436
	SYS_openat2 : uintptr : 437
	SYS_pidfd_getfd : uintptr : 438
	SYS_faccessat2 : uintptr : 439
	SYS_process_madvise : uintptr : 440
	SYS_epoll_pwait2 : uintptr : 441
	SYS_mount_setattr : uintptr : 442
	SYS_landlock_create_ruleset : uintptr : 444
	SYS_landlock_add_rule : uintptr : 445
	SYS_landlock_restrict_self : uintptr : 446
} else when ODIN_ARCH == .riscv64 {
	SYS_io_setup                     :: uintptr(0)
	SYS_io_destroy                   :: uintptr(1)
	SYS_io_submit                    :: uintptr(2)
	SYS_io_cancel                    :: uintptr(3)
	SYS_io_getevents                 :: uintptr(4)
	SYS_setxattr                     :: uintptr(5)
	SYS_lsetxattr                    :: uintptr(6)
	SYS_fsetxattr                    :: uintptr(7)
	SYS_getxattr                     :: uintptr(8)
	SYS_lgetxattr                    :: uintptr(9)
	SYS_fgetxattr                    :: uintptr(10)
	SYS_listxattr                    :: uintptr(11)
	SYS_llistxattr                   :: uintptr(12)
	SYS_flistxattr                   :: uintptr(13)
	SYS_removexattr                  :: uintptr(14)
	SYS_lremovexattr                 :: uintptr(15)
	SYS_fremovexattr                 :: uintptr(16)
	SYS_getcwd                       :: uintptr(17)
	SYS_lookup_dcookie               :: uintptr(18)
	SYS_eventfd2                     :: uintptr(19)
	SYS_epoll_create1                :: uintptr(20)
	SYS_epoll_ctl                    :: uintptr(21)
	SYS_epoll_pwait                  :: uintptr(22)
	SYS_dup                          :: uintptr(23)
	SYS_dup3                         :: uintptr(24)
	SYS_fcntl                        :: uintptr(25)
	SYS_inotify_init1                :: uintptr(26)
	SYS_inotify_add_watch            :: uintptr(27)
	SYS_inotify_rm_watch             :: uintptr(28)
	SYS_ioctl                        :: uintptr(29)
	SYS_ioprio_set                   :: uintptr(30)
	SYS_ioprio_get                   :: uintptr(31)
	SYS_flock                        :: uintptr(32)
	SYS_mknodat                      :: uintptr(33)
	SYS_mkdirat                      :: uintptr(34)
	SYS_unlinkat                     :: uintptr(35)
	SYS_symlinkat                    :: uintptr(36)
	SYS_linkat                       :: uintptr(37)
	SYS_renameat                     :: uintptr(38)
	SYS_umount2                      :: uintptr(39)
	SYS_mount                        :: uintptr(40)
	SYS_pivot_root                   :: uintptr(41)
	SYS_nfsservctl                   :: uintptr(42)
	SYS_statfs                       :: uintptr(43)
	SYS_fstatfs                      :: uintptr(44)
	SYS_truncate                     :: uintptr(45)
	SYS_ftruncate                    :: uintptr(46)
	SYS_fallocate                    :: uintptr(47)
	SYS_faccessat                    :: uintptr(48)
	SYS_chdir                        :: uintptr(49)
	SYS_fchdir                       :: uintptr(50)
	SYS_chroot                       :: uintptr(51)
	SYS_fchmod                       :: uintptr(52)
	SYS_fchmodat                     :: uintptr(53)
	SYS_fchownat                     :: uintptr(54)
	SYS_fchown                       :: uintptr(55)
	SYS_openat                       :: uintptr(56)
	SYS_close                        :: uintptr(57)
	SYS_vhangup                      :: uintptr(58)
	SYS_pipe2                        :: uintptr(59)
	SYS_quotactl                     :: uintptr(60)
	SYS_getdents64                   :: uintptr(61)
	SYS_lseek                        :: uintptr(62)
	SYS_read                         :: uintptr(63)
	SYS_write                        :: uintptr(64)
	SYS_readv                        :: uintptr(65)
	SYS_writev                       :: uintptr(66)
	SYS_pread64                      :: uintptr(67)
	SYS_pwrite64                     :: uintptr(68)
	SYS_preadv                       :: uintptr(69)
	SYS_pwritev                      :: uintptr(70)
	SYS_sendfile                     :: uintptr(71)
	SYS_pselect6                     :: uintptr(72)
	SYS_ppoll                        :: uintptr(73)
	SYS_signalfd4                    :: uintptr(74)
	SYS_vmsplice                     :: uintptr(75)
	SYS_splice                       :: uintptr(76)
	SYS_tee                          :: uintptr(77)
	SYS_readlinkat                   :: uintptr(78)
	SYS_fstatat                      :: uintptr(79)
	SYS_fstat                        :: uintptr(80)
	SYS_sync                         :: uintptr(81)
	SYS_fsync                        :: uintptr(82)
	SYS_fdatasync                    :: uintptr(83)
	SYS_sync_file_range2             :: uintptr(84)
	SYS_sync_file_range              :: uintptr(84)
	SYS_timerfd_create               :: uintptr(85)
	SYS_timerfd_settime              :: uintptr(86)
	SYS_timerfd_gettime              :: uintptr(87)
	SYS_utimensat                    :: uintptr(88)
	SYS_acct                         :: uintptr(89)
	SYS_capget                       :: uintptr(90)
	SYS_capset                       :: uintptr(91)
	SYS_personality                  :: uintptr(92)
	SYS_exit                         :: uintptr(93)
	SYS_exit_group                   :: uintptr(94)
	SYS_waitid                       :: uintptr(95)
	SYS_set_tid_address              :: uintptr(96)
	SYS_unshare                      :: uintptr(97)
	SYS_futex                        :: uintptr(98)
	SYS_set_robust_list              :: uintptr(99)
	SYS_get_robust_list              :: uintptr(100)
	SYS_nanosleep                    :: uintptr(101)
	SYS_getitimer                    :: uintptr(102)
	SYS_setitimer                    :: uintptr(103)
	SYS_kexec_load                   :: uintptr(104)
	SYS_init_module                  :: uintptr(105)
	SYS_delete_module                :: uintptr(106)
	SYS_timer_create                 :: uintptr(107)
	SYS_timer_gettime                :: uintptr(108)
	SYS_timer_getoverrun             :: uintptr(109)
	SYS_timer_settime                :: uintptr(110)
	SYS_timer_delete                 :: uintptr(111)
	SYS_clock_settime                :: uintptr(112)
	SYS_clock_gettime                :: uintptr(113)
	SYS_clock_getres                 :: uintptr(114)
	SYS_clock_nanosleep              :: uintptr(115)
	SYS_syslog                       :: uintptr(116)
	SYS_ptrace                       :: uintptr(117)
	SYS_sched_setparam               :: uintptr(118)
	SYS_sched_setscheduler           :: uintptr(119)
	SYS_sched_getscheduler           :: uintptr(120)
	SYS_sched_getparam               :: uintptr(121)
	SYS_sched_setaffinity            :: uintptr(122)
	SYS_sched_getaffinity            :: uintptr(123)
	SYS_sched_yield                  :: uintptr(124)
	SYS_sched_get_priority_max       :: uintptr(125)
	SYS_sched_get_priority_min       :: uintptr(126)
	SYS_sched_rr_get_interval        :: uintptr(127)
	SYS_restart_syscall              :: uintptr(128)
	SYS_kill                         :: uintptr(129)
	SYS_tkill                        :: uintptr(130)
	SYS_tgkill                       :: uintptr(131)
	SYS_sigaltstack                  :: uintptr(132)
	SYS_rt_sigsuspend                :: uintptr(133)
	SYS_rt_sigaction                 :: uintptr(134)
	SYS_rt_sigprocmask               :: uintptr(135)
	SYS_rt_sigpending                :: uintptr(136)
	SYS_rt_sigtimedwait              :: uintptr(137)
	SYS_rt_sigqueueinfo              :: uintptr(138)
	SYS_rt_sigreturn                 :: uintptr(139)
	SYS_setpriority                  :: uintptr(140)
	SYS_getpriority                  :: uintptr(141)
	SYS_reboot                       :: uintptr(142)
	SYS_setregid                     :: uintptr(143)
	SYS_setgid                       :: uintptr(144)
	SYS_setreuid                     :: uintptr(145)
	SYS_setuid                       :: uintptr(146)
	SYS_setresuid                    :: uintptr(147)
	SYS_getresuid                    :: uintptr(148)
	SYS_setresgid                    :: uintptr(149)
	SYS_getresgid                    :: uintptr(150)
	SYS_setfsuid                     :: uintptr(151)
	SYS_setfsgid                     :: uintptr(152)
	SYS_times                        :: uintptr(153)
	SYS_setpgid                      :: uintptr(154)
	SYS_getpgid                      :: uintptr(155)
	SYS_getsid                       :: uintptr(156)
	SYS_setsid                       :: uintptr(157)
	SYS_getgroups                    :: uintptr(158)
	SYS_setgroups                    :: uintptr(159)
	SYS_uname                        :: uintptr(160)
	SYS_sethostname                  :: uintptr(161)
	SYS_setdomainname                :: uintptr(162)
	SYS_getrlimit                    :: uintptr(163)
	SYS_setrlimit                    :: uintptr(164)
	SYS_getrusage                    :: uintptr(165)
	SYS_umask                        :: uintptr(166)
	SYS_prctl                        :: uintptr(167)
	SYS_getcpu                       :: uintptr(168)
	SYS_gettimeofday                 :: uintptr(169)
	SYS_settimeofday                 :: uintptr(170)
	SYS_adjtimex                     :: uintptr(171)
	SYS_getpid                       :: uintptr(172)
	SYS_getppid                      :: uintptr(173)
	SYS_getuid                       :: uintptr(174)
	SYS_geteuid                      :: uintptr(175)
	SYS_getgid                       :: uintptr(176)
	SYS_getegid                      :: uintptr(177)
	SYS_gettid                       :: uintptr(178)
	SYS_sysinfo                      :: uintptr(179)
	SYS_mq_open                      :: uintptr(180)
	SYS_mq_unlink                    :: uintptr(181)
	SYS_mq_timedsend                 :: uintptr(182)
	SYS_mq_timedreceive              :: uintptr(183)
	SYS_mq_notify                    :: uintptr(184)
	SYS_mq_getsetattr                :: uintptr(185)
	SYS_msgget                       :: uintptr(186)
	SYS_msgctl                       :: uintptr(187)
	SYS_msgrcv                       :: uintptr(188)
	SYS_msgsnd                       :: uintptr(189)
	SYS_semget                       :: uintptr(190)
	SYS_semctl                       :: uintptr(191)
	SYS_semtimedop                   :: uintptr(192)
	SYS_semop                        :: uintptr(193)
	SYS_shmget                       :: uintptr(194)
	SYS_shmctl                       :: uintptr(195)
	SYS_shmat                        :: uintptr(196)
	SYS_shmdt                        :: uintptr(197)
	SYS_socket                       :: uintptr(198)
	SYS_socketpair                   :: uintptr(199)
	SYS_bind                         :: uintptr(200)
	SYS_listen                       :: uintptr(201)
	SYS_accept                       :: uintptr(202)
	SYS_connect                      :: uintptr(203)
	SYS_getsockname                  :: uintptr(204)
	SYS_getpeername                  :: uintptr(205)
	SYS_sendto                       :: uintptr(206)
	SYS_recvfrom                     :: uintptr(207)
	SYS_setsockopt                   :: uintptr(208)
	SYS_getsockopt                   :: uintptr(209)
	SYS_shutdown                     :: uintptr(210)
	SYS_sendmsg                      :: uintptr(211)
	SYS_recvmsg                      :: uintptr(212)
	SYS_readahead                    :: uintptr(213)
	SYS_brk                          :: uintptr(214)
	SYS_munmap                       :: uintptr(215)
	SYS_mremap                       :: uintptr(216)
	SYS_add_key                      :: uintptr(217)
	SYS_request_key                  :: uintptr(218)
	SYS_keyctl                       :: uintptr(219)
	SYS_clone                        :: uintptr(220)
	SYS_execve                       :: uintptr(221)
	SYS_mmap                         :: uintptr(222)
	SYS_fadvise64                    :: uintptr(223)
	SYS_swapon                       :: uintptr(224)
	SYS_swapoff                      :: uintptr(225)
	SYS_mprotect                     :: uintptr(226)
	SYS_msync                        :: uintptr(227)
	SYS_mlock                        :: uintptr(228)
	SYS_munlock                      :: uintptr(229)
	SYS_mlockall                     :: uintptr(230)
	SYS_munlockall                   :: uintptr(231)
	SYS_mincore                      :: uintptr(232)
	SYS_madvise                      :: uintptr(233)
	SYS_remap_file_pages             :: uintptr(234)
	SYS_mbind                        :: uintptr(235)
	SYS_get_mempolicy                :: uintptr(236)
	SYS_set_mempolicy                :: uintptr(237)
	SYS_migrate_pages                :: uintptr(238)
	SYS_move_pages                   :: uintptr(239)
	SYS_rt_tgsigqueueinfo            :: uintptr(240)
	SYS_perf_event_open              :: uintptr(241)
	SYS_accept4                      :: uintptr(242)
	SYS_recvmmsg                     :: uintptr(243)
	SYS_wait4                        :: uintptr(260)
	SYS_prlimit64                    :: uintptr(261)
	SYS_fanotify_init                :: uintptr(262)
	SYS_fanotify_mark                :: uintptr(263)
	SYS_name_to_handle_at            :: uintptr(264)
	SYS_open_by_handle_at            :: uintptr(265)
	SYS_clock_adjtime                :: uintptr(266)
	SYS_syncfs                       :: uintptr(267)
	SYS_setns                        :: uintptr(268)
	SYS_sendmmsg                     :: uintptr(269)
	SYS_process_vm_readv             :: uintptr(270)
	SYS_process_vm_writev            :: uintptr(271)
	SYS_kcmp                         :: uintptr(272)
	SYS_finit_module                 :: uintptr(273)
	SYS_sched_setattr                :: uintptr(274)
	SYS_sched_getattr                :: uintptr(275)
	SYS_renameat2                    :: uintptr(276)
	SYS_seccomp                      :: uintptr(277)
	SYS_getrandom                    :: uintptr(278)
	SYS_memfd_create                 :: uintptr(279)
	SYS_bpf                          :: uintptr(280)
	SYS_execveat                     :: uintptr(281)
	SYS_userfaultfd                  :: uintptr(282)
	SYS_membarrier                   :: uintptr(283)
	SYS_mlock2                       :: uintptr(284)
	SYS_copy_file_range              :: uintptr(285)
	SYS_preadv2                      :: uintptr(286)
	SYS_pwritev2                     :: uintptr(287)
	SYS_pkey_mprotect                :: uintptr(288)
	SYS_pkey_alloc                   :: uintptr(289)
	SYS_pkey_free                    :: uintptr(290)
	SYS_statx                        :: uintptr(291)
	SYS_io_pgetevents                :: uintptr(292)
	SYS_rseq                         :: uintptr(293)
	SYS_kexec_file_load              :: uintptr(294)
	SYS_clock_gettime64              :: uintptr(403)
	SYS_clock_settime64              :: uintptr(404)
	SYS_clock_adjtime64              :: uintptr(405)
	SYS_clock_getres_time64          :: uintptr(406)
	SYS_clock_nanosleep_time64       :: uintptr(407)
	SYS_timer_gettime64              :: uintptr(408)
	SYS_timer_settime64              :: uintptr(409)
	SYS_timerfd_gettime64            :: uintptr(410)
	SYS_timerfd_settime64            :: uintptr(411)
	SYS_utimensat_time64             :: uintptr(412)
	SYS_pselect6_time64              :: uintptr(413)
	SYS_ppoll_time64                 :: uintptr(414)
	SYS_io_pgetevents_time64         :: uintptr(416)
	SYS_recvmmsg_time64              :: uintptr(417)
	SYS_mq_timedsend_time64          :: uintptr(418)
	SYS_mq_timedreceive_time64       :: uintptr(419)
	SYS_semtimedop_time64            :: uintptr(420)
	SYS_rt_sigtimedwait_time64       :: uintptr(421)
	SYS_futex_time64                 :: uintptr(422)
	SYS_sched_rr_get_interval_time64 :: uintptr(423)
	SYS_pidfd_send_signal            :: uintptr(424)
	SYS_io_uring_setup               :: uintptr(425)
	SYS_io_uring_enter               :: uintptr(426)
	SYS_io_uring_register            :: uintptr(427)
	SYS_open_tree                    :: uintptr(428)
	SYS_move_mount                   :: uintptr(429)
	SYS_fsopen                       :: uintptr(430)
	SYS_fsconfig                     :: uintptr(431)
	SYS_fsmount                      :: uintptr(432)
	SYS_fspick                       :: uintptr(433)
	SYS_pidfd_open                   :: uintptr(434)
	SYS_clone3                       :: uintptr(435)
	SYS_close_range                  :: uintptr(436)
	SYS_openat2                      :: uintptr(437)
	SYS_pidfd_getfd                  :: uintptr(438)
	SYS_faccessat2                   :: uintptr(439)
	SYS_process_madvise              :: uintptr(440)
	SYS_epoll_pwait2                 :: uintptr(441)
	SYS_mount_setattr                :: uintptr(442)
	SYS_quotactl_fd                  :: uintptr(443)
	SYS_landlock_create_ruleset      :: uintptr(444)
	SYS_landlock_add_rule            :: uintptr(445)
	SYS_landlock_restrict_self       :: uintptr(446)
	SYS_memfd_secret                 :: uintptr(447)
	SYS_process_mrelease             :: uintptr(448)
	SYS_futex_waitv                  :: uintptr(449)
	SYS_set_mempolicy_home_node      :: uintptr(450)
	SYS_cachestat                    :: uintptr(451)
	SYS_fchmodat2                    :: uintptr(452)

	SIGCHLD :: 17
} else {
	#panic("Unsupported architecture")
}


// syscall related constants
AT_FDCWD            :: ~uintptr(99)
AT_REMOVEDIR        :: uintptr(0x200)
AT_SYMLINK_FOLLOW   :: uintptr(0x400)
AT_SYMLINK_NOFOLLOW :: uintptr(0x100)

// mmap flags
PROT_NONE      :: 0x0
PROT_READ      :: 0x1
PROT_WRITE     :: 0x2
PROT_EXEC      :: 0x4
PROT_GROWSDOWN :: 0x01000000
PROT_GROWSUP   :: 0x02000000

MAP_FIXED           :: 0x10
MAP_SHARED          :: 0x1
MAP_PRIVATE         :: 0x2
MAP_SHARED_VALIDATE :: 0x3
MAP_ANONYMOUS       :: 0x20

// mremap flags
MREMAP_MAYMOVE   :: 1
MREMAP_FIXED     :: 2
MREMAP_DONTUNMAP :: 4

// madvise flags
MADV_NORMAL      :: 0
MADV_RANDOM      :: 1
MADV_SEQUENTIAL  :: 2
MADV_WILLNEED    :: 3
MADV_DONTNEED    :: 4
MADV_FREE        :: 8
MADV_REMOVE      :: 9
MADV_DONTFORK    :: 10
MADV_DOFORK      :: 11
MADV_MERGEABLE   :: 12
MADV_UNMERGEABLE :: 13
MADV_HUGEPAGE    :: 14
MADV_NOHUGEPAGE  :: 15
MADV_DONTDUMP    :: 16
MADV_DODUMP      :: 17
MADV_WIPEONFORK  :: 18
MADV_KEEPONFORK  :: 19
MADV_HWPOISON    :: 100

// pipe2 flags
O_CLOEXEC :: 0o2000000

// poll events
POLLIN         :: 0x0001
POLLPRI        :: 0x0002
POLLOUT        :: 0x0004
POLLERR        :: 0x0008
POLLHUP        :: 0x0010
POLLNVAL       :: 0x0020
POLLRDNORM     :: 0x0040
POLLRDBAND     :: 0x0080
POLLWRNORM     :: 0x0100
POLLWRBAND     :: 0x0200
POLLMSG        :: 0x0400
POLLREMOVE     :: 0x1000
POLLRDHUP      :: 0x2000
POLLFREE       :: 0x4000
POLL_BUSY_LOOP :: 0x8000

// perf event data
Perf_Sample :: struct #raw_union {
	period:    u64,
	frequency: u64,
}
Perf_Wakeup :: struct #raw_union {
	events:    u32,
	watermark: u32,
}
Perf_Field1 :: struct #raw_union {
	breakpoint_addr: u64,
	kprobe_func:     u64,
	uprobe_path:     u64,
	config1:         u64,
}
Perf_Field2 :: struct #raw_union {
	breakpoint_len: u64,
	kprobe_addr:    u64,
	uprobe_offset:  u64,
	config2:        u64,
}
Perf_Event_Attr :: struct #packed {
	type:   u32,
	size:   u32,
	config: u64,
	sample: Perf_Sample,
	sample_type: u64,
	read_format: u64,
	flags:       Perf_Flags,
	wakeup: Perf_Wakeup,
	breakpoint_type: u32,
	field1: Perf_Field1,
	field2: Perf_Field2,
	branch_sample_type: u64,
	sample_regs_user:   u64,
	sample_stack_user:  u32,
	clock_id:           i32,
	sample_regs_intr:   u64,
	aux_watermark:      u32,
	sample_max_stack:   u16,
	_padding:           u16,
}

Perf_Event_Flags :: distinct bit_set[Perf_Event_Flag; u64]
Perf_Event_Flag :: enum u64 {
	Bit0               = 0,
	Bit0_Is_Deprecated = 1,
	User_Rdpmc         = 2,
	User_Time          = 3,
	User_Time_Zero     = 4,
	User_Time_Short    = 5,
}
Perf_Capabilities :: struct #raw_union {
	capabilities: u64,
	flags: Perf_Event_Flags,
}
Perf_Event_mmap_Page :: struct #packed {
	version:        u32,
	compat_version: u32,
	lock:           u32,
	index:          u32,
	offset:         i64,
	time_enabled:   u64,
	time_running:   u64,
	cap: Perf_Capabilities,
	pmc_width:      u16,
	time_shift:     u16,
	time_mult:      u32,
	time_offset:    u64,
	time_zero:      u64,
	size:           u32,
	reserved1:      u32,
	time_cycles:    u64,
	time_mask:      u64,
	reserved2:      [116*8]u8,
	data_head:      u64,
	data_tail:      u64,
	data_offset:    u64,
	data_size:      u64,
	aux_head:       u64,
	aux_tail:       u64,
	aux_offset:     u64,
	aux_size:       u64,
}

Perf_Type_Id :: enum u32 {
	Hardware   = 0,
	Software   = 1,
	Tracepoint = 2,
	HW_Cache   = 3,
	Raw        = 4,
	Breakpoint = 5,
}

Perf_Hardware_Id :: enum u64 {
	CPU_Cycles              = 0,
	Instructions            = 1,
	Cache_References        = 2,
	Cache_Misses            = 3,
	Branch_Instructions     = 4,
	Branch_Misses           = 5,
	Bus_Cycles              = 6,
	Stalled_Cycles_Frontend = 7,
	Stalled_Cycles_Backend  = 8,
	Ref_CPU_Cycles          = 9,
}

Perf_Flags :: distinct bit_set[Perf_Flag; u64]
Perf_Flag :: enum u64 {
	Disabled       = 0,
	Inherit        = 1,
	Pinned         = 2,
	Exclusive      = 3,
	Exclude_User   = 4,
	Exclude_Kernel = 5,
	Exclude_HV     = 6,
	Exclude_Idle   = 7,
	mmap           = 8,
	Comm           = 9,
	Freq           = 10,
	Inherit_Stat   = 11,
	Enable_On_Exec = 12,
	Task           = 13,
	Watermark      = 14,
	Precise_IP_0   = 15,
	Precise_IP_1   = 16,
	mmap_Data      = 17,
	Sample_Id_All  = 18,
	Exclude_Host   = 19,
	Exclude_Guest  = 20,
	Exclude_Callchain_Kernel = 21,
	Exclude_Callchain_User   = 22,
	mmap2          = 23,
	Comm_Exec      = 24,
	Use_Clockid    = 25,
	Context_Switch = 26,
	Write_Backward = 27,
	Namespaces     = 28,
	KSymbol        = 29,
	BPF_Event      = 30,
	Aux_Output     = 31,
	CGroup         = 32,
	Text_Poke      = 33,
	Build_Id       = 34,
	Inherit_Thread = 35,
	Remove_On_Exec = 36,
	Sigtrap        = 37,
}

sys_gettid :: proc "contextless" () -> int {
	return int(intrinsics.syscall(SYS_gettid))
}

sys_getrandom :: proc "contextless" (buf: [^]byte, buflen: uint, flags: int) -> int {
	return int(intrinsics.syscall(SYS_getrandom, uintptr(buf), uintptr(buflen), uintptr(flags)))
}

sys_open :: proc "contextless" (path: cstring, flags: int, mode: uint = 0o000) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_open, uintptr(rawptr(path)), uintptr(flags), uintptr(mode)))
	} else { // NOTE: arm64 does not have open
		return int(intrinsics.syscall(SYS_openat, AT_FDCWD, uintptr(rawptr(path)), uintptr(flags), uintptr(mode)))
	}
}

sys_openat :: proc "contextless" (dfd: int, path: cstring, flags: int, mode: uint = 0o000) -> int {
	return int(intrinsics.syscall(SYS_openat, uintptr(dfd), uintptr(rawptr(path)), uintptr(flags), uintptr(mode)))
}

sys_close :: proc "contextless" (fd: int) -> int {
	return int(intrinsics.syscall(SYS_close, uintptr(fd)))
}

sys_read :: proc "contextless" (fd: int, buf: rawptr, size: uint) -> int {
	return int(intrinsics.syscall(SYS_read, uintptr(fd), uintptr(buf), uintptr(size)))
}

sys_pread :: proc "contextless" (fd: int, buf: rawptr, size: uint, offset: i64) -> int {
	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return int(intrinsics.syscall(SYS_pread64, uintptr(fd), uintptr(buf), uintptr(size), uintptr(offset)))
	} else {
		low := uintptr(offset & 0xFFFFFFFF)
		high := uintptr(offset >> 32)
		return int(intrinsics.syscall(SYS_pread64, uintptr(fd), uintptr(buf), uintptr(size), high, low))
	}
}

sys_write :: proc "contextless" (fd: int, buf: rawptr, size: uint) -> int {
	return int(intrinsics.syscall(SYS_write, uintptr(fd), uintptr(buf), uintptr(size)))
}

sys_pwrite :: proc "contextless" (fd: int, buf: rawptr, size: uint, offset: i64) -> int {
	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return int(intrinsics.syscall(SYS_pwrite64, uintptr(fd), uintptr(buf), uintptr(size), uintptr(offset)))
	} else {
		low := uintptr(offset & 0xFFFFFFFF)
		high := uintptr(offset >> 32)
		return int(intrinsics.syscall(SYS_pwrite64, uintptr(fd), uintptr(buf), uintptr(size), high, low))
	}
}

sys_lseek :: proc "contextless" (fd: int, offset: i64, whence: int) -> i64 {
	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return i64(intrinsics.syscall(SYS_lseek, uintptr(fd), uintptr(offset), uintptr(whence)))
	} else {
		low := uintptr(offset & 0xFFFFFFFF)
		high := uintptr(offset >> 32)
		result: i64
		res := i64(intrinsics.syscall(SYS__llseek, uintptr(fd), high, low, uintptr(&result), uintptr(whence)))
		return res if res < 0 else result
	}
}

sys_stat :: proc "contextless" (path: cstring, stat: rawptr) -> int {
	when ODIN_ARCH == .amd64 {
		return int(intrinsics.syscall(SYS_stat, uintptr(rawptr(path)), uintptr(stat)))
	} else when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_stat64, uintptr(rawptr(path)), uintptr(stat)))
	} else { // NOTE: arm64 does not have stat
		return int(intrinsics.syscall(SYS_fstatat, AT_FDCWD, uintptr(rawptr(path)), uintptr(stat), 0))
	}
}

sys_fstat :: proc "contextless" (fd: int, stat: rawptr) -> int {
	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return int(intrinsics.syscall(SYS_fstat, uintptr(fd), uintptr(stat)))
	} else {
		return int(intrinsics.syscall(SYS_fstat64, uintptr(fd), uintptr(stat)))
	}
}

sys_lstat :: proc "contextless" (path: cstring, stat: rawptr) -> int {
	when ODIN_ARCH == .amd64 {
		return int(intrinsics.syscall(SYS_lstat, uintptr(rawptr(path)), uintptr(stat)))
	} else when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_lstat64, uintptr(rawptr(path)), uintptr(stat)))
	} else { // NOTE: arm64 does not have any lstat
		return int(intrinsics.syscall(SYS_fstatat, AT_FDCWD, uintptr(rawptr(path)), uintptr(stat), AT_SYMLINK_NOFOLLOW))
	}
}

sys_readlink :: proc "contextless" (path: cstring, buf: rawptr, bufsiz: uint) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_readlink, uintptr(rawptr(path)), uintptr(buf), uintptr(bufsiz)))
	} else { // NOTE: arm64 does not have readlink
		return int(intrinsics.syscall(SYS_readlinkat, AT_FDCWD, uintptr(rawptr(path)), uintptr(buf), uintptr(bufsiz)))
	}
}

sys_symlink :: proc "contextless" (old_name: cstring, new_name: cstring) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_symlink, uintptr(rawptr(old_name)), uintptr(rawptr(new_name))))
	} else { // NOTE: arm64 does not have symlink
		return int(intrinsics.syscall(SYS_symlinkat, uintptr(rawptr(old_name)), AT_FDCWD, uintptr(rawptr(new_name))))
	}
}

sys_access :: proc "contextless" (path: cstring, mask: int) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_access, uintptr(rawptr(path)), uintptr(mask)))
	} else { // NOTE: arm64 does not have access
		return int(intrinsics.syscall(SYS_faccessat, AT_FDCWD, uintptr(rawptr(path)), uintptr(mask)))
	}
}

sys_getcwd :: proc "contextless" (buf: rawptr, size: uint) -> int {
	return int(intrinsics.syscall(SYS_getcwd, uintptr(buf), uintptr(size)))
}

sys_chdir :: proc "contextless" (path: cstring) -> int {
	return int(intrinsics.syscall(SYS_chdir, uintptr(rawptr(path))))
}

sys_fchdir :: proc "contextless" (fd: int) -> int {
	return int(intrinsics.syscall(SYS_fchdir, uintptr(fd)))
}

sys_chmod :: proc "contextless" (path: cstring, mode: uint) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_chmod, uintptr(rawptr(path)), uintptr(mode)))
	} else { // NOTE: arm64 does not have chmod
		return int(intrinsics.syscall(SYS_fchmodat, AT_FDCWD, uintptr(rawptr(path)), uintptr(mode)))
	}
}

sys_fchmod :: proc "contextless" (fd: int, mode: uint) -> int {
	return int(intrinsics.syscall(SYS_fchmod, uintptr(fd), uintptr(mode)))
}

sys_chown :: proc "contextless" (path: cstring, user: int, group: int) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH !=. riscv64 {
		return int(intrinsics.syscall(SYS_chown, uintptr(rawptr(path)), uintptr(user), uintptr(group)))
	} else { // NOTE: arm64 does not have chown
		return int(intrinsics.syscall(SYS_fchownat, AT_FDCWD, uintptr(rawptr(path)), uintptr(user), uintptr(group), 0))
	}
}

sys_fchown :: proc "contextless" (fd: int, user: int, group: int) -> int {
	return int(intrinsics.syscall(SYS_fchown, uintptr(fd), uintptr(user), uintptr(group)))
}

sys_lchown :: proc "contextless" (path: cstring, user: int, group: int) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_lchown, uintptr(rawptr(path)), uintptr(user), uintptr(group)))
	} else { // NOTE: arm64 does not have lchown
		return int(intrinsics.syscall(SYS_fchownat, AT_FDCWD, uintptr(rawptr(path)), uintptr(user), uintptr(group), AT_SYMLINK_NOFOLLOW))
	}
}

sys_rename :: proc "contextless" (old, new: cstring) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_rename, uintptr(rawptr(old)), uintptr(rawptr(new))))
	} else { // NOTE: arm64 does not have rename
		return int(intrinsics.syscall(SYS_renameat, AT_FDCWD, uintptr(rawptr(old)), uintptr(rawptr(new))))
	}
}

sys_link :: proc "contextless" (old_name: cstring, new_name: cstring) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_link, uintptr(rawptr(old_name)), uintptr(rawptr(new_name))))
	} else { // NOTE: arm64 does not have link
		return int(intrinsics.syscall(SYS_linkat, AT_FDCWD, uintptr(rawptr(old_name)), AT_FDCWD, uintptr(rawptr(new_name)), AT_SYMLINK_FOLLOW))
	}
}

sys_unlink :: proc "contextless" (path: cstring) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_unlink, uintptr(rawptr(path))))
	} else { // NOTE: arm64 does not have unlink
		return int(intrinsics.syscall(SYS_unlinkat, AT_FDCWD, uintptr(rawptr(path)), 0))
	}
}

sys_unlinkat :: proc "contextless" (dfd: int, path: cstring, flag: int = 0) -> int {
	return int(intrinsics.syscall(SYS_unlinkat, uintptr(dfd), uintptr(rawptr(path)), uintptr(flag)))
}

sys_rmdir :: proc "contextless" (path: cstring) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_rmdir, uintptr(rawptr(path))))
	} else { // NOTE: arm64 does not have rmdir
		return int(intrinsics.syscall(SYS_unlinkat, AT_FDCWD, uintptr(rawptr(path)), AT_REMOVEDIR))
	}
}

sys_mkdir :: proc "contextless" (path: cstring, mode: uint) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_mkdir, uintptr(rawptr(path)), uintptr(mode)))
	} else { // NOTE: arm64 does not have mkdir
		return int(intrinsics.syscall(SYS_mkdirat, AT_FDCWD, uintptr(rawptr(path)), uintptr(mode)))
	}
}

sys_mkdirat :: proc "contextless" (dfd: int, path: cstring, mode: uint) -> int {
	return int(intrinsics.syscall(SYS_mkdirat, uintptr(dfd), uintptr(rawptr(path)), uintptr(mode)))
}

sys_mknod :: proc "contextless" (path: cstring, mode: uint, dev: int) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_mknod, uintptr(rawptr(path)), uintptr(mode), uintptr(dev)))
	} else { // NOTE: arm64 does not have mknod
		return int(intrinsics.syscall(SYS_mknodat, AT_FDCWD, uintptr(rawptr(path)), uintptr(mode), uintptr(dev)))
	}
}

sys_mknodat :: proc "contextless" (dfd: int, path: cstring, mode: uint, dev: int) -> int {
	return int(intrinsics.syscall(SYS_mknodat, uintptr(dfd), uintptr(rawptr(path)), uintptr(mode), uintptr(dev)))
}

sys_truncate :: proc "contextless" (path: cstring, length: i64) -> int {
	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return int(intrinsics.syscall(SYS_truncate, uintptr(rawptr(path)), uintptr(length)))
	} else {
		low := uintptr(length & 0xFFFFFFFF)
		high := uintptr(length >> 32)
		return int(intrinsics.syscall(SYS_truncate64, uintptr(rawptr(path)), high, low))
	}
}

sys_ftruncate :: proc "contextless" (fd: int, length: i64) -> int {
	when ODIN_ARCH == .amd64 || ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		return int(intrinsics.syscall(SYS_ftruncate, uintptr(fd), uintptr(length)))
	} else {
		low := uintptr(length & 0xFFFFFFFF)
		high := uintptr(length >> 32)
		return int(intrinsics.syscall(SYS_ftruncate64, uintptr(fd), high, low))
	}
}

sys_fsync :: proc "contextless" (fd: int) -> int {
	return int(intrinsics.syscall(SYS_fsync, uintptr(fd)))
}

sys_getdents64 :: proc "contextless" (fd: int, dirent: rawptr, count: int) -> int {
	return int(intrinsics.syscall(SYS_getdents64, uintptr(fd), uintptr(dirent), uintptr(count)))
}

sys_fork :: proc "contextless" () -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_fork))
	} else {
		return int(intrinsics.syscall(SYS_clone, SIGCHLD))
	}
}
sys_pipe2 :: proc "contextless" (fds: rawptr, flags: int) -> int {
	return int(intrinsics.syscall(SYS_pipe2, uintptr(fds), uintptr(flags)))
}
sys_dup2 :: proc "contextless" (oldfd: int, newfd: int) -> int {
	when ODIN_ARCH != .arm64 && ODIN_ARCH != .riscv64 {
		return int(intrinsics.syscall(SYS_dup2, uintptr(oldfd), uintptr(newfd)))
	} else {
		return int(intrinsics.syscall(SYS_dup3, uintptr(oldfd), uintptr(newfd), 0))
	}
}

sys_mmap :: proc "contextless" (addr: rawptr, length: uint, prot, flags, fd: int, offset: uintptr) -> int {
	return int(intrinsics.syscall(SYS_mmap, uintptr(addr), uintptr(length), uintptr(prot), uintptr(flags), uintptr(fd), offset))
}

sys_mremap :: proc "contextless" (addr: rawptr, old_length, new_length: uint, flags: int, new_addr: rawptr = nil) -> int {
	return int(intrinsics.syscall(SYS_mremap, uintptr(addr), uintptr(old_length), uintptr(new_length), uintptr(flags), uintptr(new_addr)))
}

sys_munmap :: proc "contextless" (addr: rawptr, length: uint) -> int {
	return int(intrinsics.syscall(SYS_munmap, uintptr(addr), uintptr(length)))
}

sys_mprotect :: proc "contextless" (addr: rawptr, length: uint, prot: int) -> int {
	return int(intrinsics.syscall(SYS_mprotect, uintptr(addr), uintptr(length), uintptr(prot)))
}

sys_madvise :: proc "contextless" (addr: rawptr, length: uint, advice: int) -> int {
	return int(intrinsics.syscall(SYS_madvise, uintptr(addr), uintptr(length), uintptr(advice)))
}


// NOTE: Unsure about if this works directly on 32 bit archs. It may need 32 bit version of the time struct.
//       As of Linux 5.1, there is a utimensat_time64 function.  Maybe use this in the future?
sys_utimensat :: proc "contextless" (dfd: int, path: cstring, times: rawptr, flags: int) -> int {
	return int(intrinsics.syscall(SYS_utimensat, uintptr(dfd), uintptr(rawptr(path)), uintptr(times), uintptr(flags)))
}

sys_socket :: proc "contextless" (domain: int, type: int, protocol: int) -> int {
	return int(intrinsics.syscall(SYS_socket, uintptr(domain), uintptr(type), uintptr(protocol)))
}

sys_connect :: proc "contextless" (sd: int, addr: rawptr, len: i32) -> int {
	return int(intrinsics.syscall(SYS_connect, uintptr(sd), uintptr(addr), uintptr(len)))
}

sys_accept :: proc "contextless" (sd: int, addr: rawptr, len: rawptr) -> int {
	return int(intrinsics.syscall(SYS_accept4, uintptr(sd), uintptr(addr), uintptr(len), uintptr(0)))
}

sys_listen :: proc "contextless" (sd: int, backlog: int) -> int {
	return int(intrinsics.syscall(SYS_listen, uintptr(sd), uintptr(backlog)))
}

sys_bind :: proc "contextless" (sd: int, addr: rawptr, len: i32) -> int {
	return int(intrinsics.syscall(SYS_bind, uintptr(sd), uintptr(addr), uintptr(len)))
}

sys_setsockopt :: proc "contextless" (sd: int, level: int, optname: int, optval: rawptr, optlen: i32) -> int {
	return int(intrinsics.syscall(SYS_setsockopt, uintptr(sd), uintptr(level), uintptr(optname), uintptr(optval), uintptr(optlen)))
}

sys_recvfrom :: proc "contextless" (sd: int, buf: rawptr, len: uint, flags: int, addr: rawptr, alen: uintptr) -> i64 {
	return i64(intrinsics.syscall(SYS_recvfrom, uintptr(sd), uintptr(buf), uintptr(len), uintptr(flags), uintptr(addr), uintptr(alen)))
}

sys_sendto :: proc "contextless" (sd: int, buf: rawptr, len: uint, flags: int, addr: rawptr, alen: i32) -> i64 {
	return i64(intrinsics.syscall(SYS_sendto, uintptr(sd), uintptr(buf), uintptr(len), uintptr(flags), uintptr(addr), uintptr(alen)))
}

sys_shutdown :: proc "contextless" (sd: int, how: int) -> int {
	return int(intrinsics.syscall(SYS_shutdown, uintptr(sd), uintptr(how)))
}

sys_perf_event_open :: proc "contextless" (event_attr: rawptr, pid: i32, cpu: i32, group_fd: i32, flags: u32) -> int {
	return int(intrinsics.syscall(SYS_perf_event_open, uintptr(event_attr), uintptr(pid), uintptr(cpu), uintptr(group_fd), uintptr(flags)))
}

sys_personality :: proc(persona: u64) -> int {
	return int(intrinsics.syscall(SYS_personality, uintptr(persona)))
}

sys_fcntl :: proc "contextless" (fd: int, cmd: int, arg: int) -> int {
	return int(intrinsics.syscall(SYS_fcntl, uintptr(fd), uintptr(cmd), uintptr(arg)))
}

sys_poll :: proc "contextless" (fds: rawptr, nfds: uint, timeout: int) -> int {
	// NOTE: specialcased here because `arm64` does not have `poll`
	when ODIN_ARCH == .arm64 || ODIN_ARCH == .riscv64 {
		seconds := i64(timeout / 1_000)
		nanoseconds := i64((timeout % 1000) * 1_000_000)
		timeout_spec := timespec{seconds, nanoseconds}
		
		return int(intrinsics.syscall(SYS_ppoll, uintptr(fds), uintptr(nfds), uintptr(&timeout_spec), uintptr(0), uintptr(8)))
	} else {
		return int(intrinsics.syscall(SYS_poll, uintptr(fds), uintptr(nfds), uintptr(timeout)))
	}
}

sys_ppoll :: proc "contextless" (fds: rawptr, nfds: uint, timeout: rawptr, sigmask: rawptr, sigsetsize: uint) -> int {
	return int(intrinsics.syscall(SYS_ppoll, uintptr(fds), uintptr(nfds), uintptr(timeout), uintptr(sigmask), uintptr(sigsetsize)))
}

get_errno :: proc "contextless" (res: int) -> i32 {
	if res < 0 && res > -4096 {
		return i32(-res)
	}
	return 0
}
