package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/shm.h = XSI shared memory facility

foreign lib {
	/*
	Attaches the shared memory segment associated with the identifier
	into the address space of the calling process.

	Returns: nil (setting errno) on failure, the address otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shmat.html ]]
	*/
	shmat :: proc(shmid: FD, shmaddr: rawptr, shmflag: SHM_Flags) -> rawptr ---

	/*
	Provides various shared memory operation as specified by the given cmd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shmctl.html ]]
	*/
	@(link_name=LSHMCTL)
	shmctl :: proc(shmid: FD, cmd: IPC_Cmd, buf: ^shmid_ds) -> result ---

	/*
	Detaches the shared memory segment located at the address specified.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shmdt.html ]] 
	*/
	shmdt :: proc(shmaddr: rawptr) -> result ---

	/*
	Returns the shared memory identifier associated with key.

	Returns: -1 (setting errno) on failure, the shared memory ID otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/shmget.html ]]
	*/
	shmget :: proc(key: key_t, size: c.size_t, shmflag: SHM_Flags) -> FD ---
}

SHM_Flag_Bits :: enum c.int {
	RDONLY = log2(SHM_RDONLY),
	RND    = log2(SHM_RND),
}
SHM_Flags :: bit_set[SHM_Flag_Bits; c.int]

when ODIN_OS == .NetBSD {
	@(private) LSHMCTL :: "__shmctl50"
} else {
	@(private) LSHMCTL :: "shmctl"
}

when ODIN_OS == .Darwin {

	SHM_RDONLY :: 0o10000
	SHM_RND    :: 0o20000

	SHMLBA     :: 16 * 1024 when ODIN_ARCH == .arm64 else 4096

	shmatt_t :: distinct c.ushort

	shmid_ds :: struct #max_field_align(4) {
		shm_perm:     ipc_perm, /* [PSX] operation permission structure */
		shm_segsz:    c.size_t, /* [PSX] size of segment in bytes */
		shm_lpid:     pid_t,    /* [PSX] process ID of last shared memory operation */
		shm_cpid:     pid_t,    /* [PSX] process ID of creator */
		shm_nattch:   shmatt_t, /* [PSX] number of current attaches */
		shm_atime:    time_t,   /* [PSX] time of last shmat() */
		shm_dtime:    time_t,   /* [PSX] time of last shmdt() */
		shm_ctime:    time_t,   /* [PSX] time of last change by shmctl() */
		shm_internal: rawptr,
	}

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD {

	SHM_RDONLY :: 0o10000
	SHM_RND    :: 0o20000

	SHMLBA     :: PAGESIZE

	shmatt_t :: distinct c.uint

	when ODIN_OS == .FreeBSD {
		shmid_ds :: struct {
			shm_perm:     ipc_perm, /* [PSX] operation permission structure */
			shm_segsz:    c.size_t, /* [PSX] size of segment in bytes */
			shm_lpid:     pid_t,    /* [PSX] process ID of last shared memory operation */
			shm_cpid:     pid_t,    /* [PSX] process ID of creator */
			shm_nattch:   shmatt_t, /* [PSX] number of current attaches */
			shm_atime:    time_t,   /* [PSX] time of last shmat() */
			shm_dtime:    time_t,   /* [PSX] time of last shmdt() */
			shm_ctime:    time_t,   /* [PSX] time of last change by shmctl() */
		}
	} else {
		shmid_ds :: struct {
			shm_perm:      ipc_perm, /* [PSX] operation permission structure */
			shm_segsz:     c.size_t, /* [PSX] size of segment in bytes */
			shm_lpid:      pid_t,    /* [PSX] process ID of last shared memory operation */
			shm_cpid:      pid_t,    /* [PSX] process ID of creator */
			shm_nattch:    shmatt_t, /* [PSX] number of current attaches */
			shm_atime:     time_t,   /* [PSX] time of last shmat() */
			shm_dtime:     time_t,   /* [PSX] time of last shmdt() */
			shm_ctime:     time_t,   /* [PSX] time of last change by shmctl() */
			_shm_internal: rawptr,
		}
	}

} else when ODIN_OS == .OpenBSD {

	SHM_RDONLY :: 0o10000
	SHM_RND    :: 0o20000

	SHMLBA     :: 1 << 12

	shmatt_t :: distinct c.short

	shmid_ds :: struct {
		shm_perm:        ipc_perm, /* [PSX] operation permission structure */
		shm_segsz:       c.int,    /* [PSX] size of segment in bytes */
		shm_lpid:        pid_t,    /* [PSX] process ID of last shared memory operation */
		shm_cpid:        pid_t,    /* [PSX] process ID of creator */
		shm_nattch:      shmatt_t, /* [PSX] number of current attaches */
		shm_atime:       time_t,   /* [PSX] time of last shmat() */
		__shm_atimensec: c.long,
		shm_dtime:       time_t,   /* [PSX] time of last shmdt() */
		__shm_dtimensec: c.long,
		shm_ctime:       time_t,   /* [PSX] time of last change by shmctl() */
		__shm_ctimensec: c.long,
		_shm_internal:   rawptr,
	}

} else {
	#panic("posix is unimplemented for the current target")
}
