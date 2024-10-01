package darwin

import "base:intrinsics"

import "core:sys/posix"

foreign import lib "system:System.framework"

// Incomplete bindings to the proc API on MacOS, add to when needed.

foreign lib {
	proc_pidinfo     :: proc(pid: posix.pid_t, flavor: PID_Info_Flavor, arg: i64, buffer: rawptr, buffersize: i32) -> i32 ---
	proc_pidpath     :: proc(pid: posix.pid_t, buffer: [^]byte, buffersize: u32) -> i32 ---
	proc_listallpids :: proc(buffer: [^]i32, buffersize: i32) -> i32 ---
	proc_pid_rusage  :: proc(pid: posix.pid_t, flavor: Pid_Rusage_Flavor, buffer: rawptr) -> i32 ---
}

MAXCOMLEN :: 16

proc_bsdinfo :: struct {
	pbi_flags:        PBI_Flags,
	pbi_status:       u32,
	pbi_xstatus:      u32,
	pbi_pid:          u32,
	pbi_ppid:         u32,
	pbi_uid:          posix.uid_t,
	pbi_gid:          posix.gid_t,
	pbi_ruid:         posix.uid_t,
	pbi_rgid:         posix.gid_t,
	pbi_svuid:        posix.uid_t,
	pbi_svgid:        posix.gid_t,
	rfu_1:            u32,
	pbi_comm:         [MAXCOMLEN]byte `fmt:"s,0"`,
	pbi_name:         [2 * MAXCOMLEN]byte `fmt:"s,0"`,
	pbi_nfiles:       u32,
	pbi_pgid:         u32,
	pbi_pjobc:        u32,
	e_tdev:           u32,
	e_tpgid:          u32,
	pbi_nice:         i32,
	pbi_start_tvsec:  u64,
	pbi_start_tvusec: u64,
}

proc_bsdshortinfo :: struct {
	pbsi_pid:    u32,
	pbsi_ppid:   u32,
	pbsi_pgid:   u32,
	pbsi_status: u32,
	pbsi_comm:   [MAXCOMLEN]byte `fmt:"s,0"`,
	pbsi_flags:  PBI_Flags,
	pbsi_uid:    posix.uid_t,
	pbsi_gid:    posix.gid_t,
	pbsi_ruid:   posix.uid_t,
	pbsi_rgid:   posix.gid_t,
	pbsi_svuid:  posix.uid_t,
	pbsi_svgid:  posix.gid_t,
	pbsi_rfu:    u32,
}

proc_vnodepathinfo :: struct {
	pvi_cdir: vnode_info_path,
	pvi_rdir: vnode_info_path,
}

vnode_info_path :: struct {
	vip_vi:   vnode_info,
	vip_path: [posix.PATH_MAX]byte,
}

vnode_info :: struct {
	vi_stat: vinfo_stat,
	vi_type: i32,
	vi_pad:  i32,
	vi_fsid: fsid_t,
}

vinfo_stat :: struct {
	vst_dev:           u32,
	vst_mode:          u16,
	vst_nlink:         u16,
	vst_ino:           u64,
	vst_uid:           posix.uid_t,
	vst_gid:           posix.gid_t,
	vst_atime:         i64,
	vst_atimensec:     i64,
	vst_mtime:         i64,
	vst_mtimensec:     i64,
	vst_ctime:         i64,
	vst_ctimensec:     i64,
	vst_birthtime:     i64,
	vst_birthtimensec: i64,
	vst_size:          posix.off_t,
	vst_blocks:        i64,
	vst_blksize:       i32,
	vst_flags:         u32,
	vst_gen:           u32,
	vst_rdev:          u32,
	vst_qspare:        [2]i64,
}

proc_taskinfo :: struct {
	pti_virtual_size:      u64 `fmt:"M"`,
	pti_resident_size:     u64 `fmt:"M"`,
	pti_total_user:        u64,
	pti_total_system:      u64,
	pti_threads_user:      u64,
	pti_threads_system:    u64,
	pti_policy:            i32,
	pti_faults:            i32,
	pti_pageins:           i32,
	pti_cow_faults:        i32,
	pti_messages_sent:     i32,
	pti_messages_received: i32,
	pti_syscalls_mach:     i32,
	pti_syscalls_unix:     i32,
	pti_csw:               i32,
	pti_threadnum:         i32,
	pti_numrunning:        i32,
	pti_priority:          i32,
}

proc_taskallinfo :: struct {
	pbsd:   proc_bsdinfo,
	ptinfo: proc_taskinfo,
}

fsid_t :: distinct [2]i32

PBI_Flag_Bits :: enum u32 {
	SYSTEM      = intrinsics.constant_log2(0x0001),
	TRACED      = intrinsics.constant_log2(0x0002),
	INEXIT      = intrinsics.constant_log2(0x0004),
	PWAIT       = intrinsics.constant_log2(0x0008),
	LP64        = intrinsics.constant_log2(0x0010),
	SLEADER     = intrinsics.constant_log2(0x0020),
	CTTY        = intrinsics.constant_log2(0x0040),
	CONTROLT    = intrinsics.constant_log2(0x0080),
	THCWD       = intrinsics.constant_log2(0x0100),
	PC_THROTTLE = intrinsics.constant_log2(0x0200),
	PC_SUSP     = intrinsics.constant_log2(0x0400),
	PC_KILL     = intrinsics.constant_log2(0x0600),
	PA_THROTTLE = intrinsics.constant_log2(0x0800),
	PA_SUSP     = intrinsics.constant_log2(0x1000),
	PA_PSUGID   = intrinsics.constant_log2(0x2000),
	EXEC        = intrinsics.constant_log2(0x4000),
}
PBI_Flags :: bit_set[PBI_Flag_Bits; u32]

PID_Info_Flavor :: enum i32 {
	LISTFDS = 1,
	TASKALLINFO,
	BSDINFO,
	TASKINFO,
	THREADINFO,
	LISTTHREADS,
	REGIONINFO,
	REGIONPATHINFO,
	VNODEPATHINFO,
	THREADPATHINFO,
	PATHINFO,
	WORKQUEUEINFO,
	SHORTBSDINFO,
	LISTFILEPORTS,
	THREADID64INFO,
	RUSAGE,
}

PIDPATHINFO_MAXSIZE :: 4*posix.PATH_MAX

Pid_Rusage_Flavor :: enum i32 {
	V0,
	V1,
	V2,
	V3,
	V4,
	V5,
}

rusage_info_v0 :: struct {
	ri_uuid:               [16]u8,
	ri_user_time:          u64,
	ri_system_time:        u64,
	ri_pkg_idle_wkups:     u64,
	ri_interrupt_wkups:    u64,
	ri_pageins:            u64,
	ri_wired_size:         u64,
	ri_resident_size:      u64,
	ri_phys_footprint:     u64,
	ri_proc_start_abstime: u64,
	ri_proc_exit_abstime:  u64,
}
