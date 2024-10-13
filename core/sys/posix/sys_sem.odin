package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/sem.h - XSI semaphore facility

foreign lib {
	/*
	Provides various semaphore control operation as specified by cmd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/semctl.html ]]
	*/
	@(link_name=LSEMCTL)
	semctl :: proc(semid: FD, semnum: c.int, cmd: Sem_Cmd, arg: ^semun = nil) -> c.int ---

	/*
	Returns the semaphore identifier associated with key.

	Returns: -1 (setting errno) on failure, a semaphore file descriptor otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/semget.html ]]
	*/
	semget :: proc(key: key_t, nsems: c.int, semflg: IPC_Flags) -> FD ---

	/*
	Perform atomically a user-defined array of semaphore operations in array order on the set of
	semaphores associated with the semaphore identifier specified by the argument semid.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/semop.html ]]
	*/
	semop :: proc(semid: FD, sops: [^]sembuf, nsops: c.size_t) -> result ---
}

Sem_Cmd :: enum c.int {
	// Returns the value of semncnt.
	GETNCNT = GETNCNT,
	// Returns the value of sempid.
	GETPID  = GETPID,
	// Return the value of semval.
	GETVAL  = GETVAL,
	// Returns the value of semval for each semaphore in the semaphore set.
	GETALL  = GETALL,
	// Returns the value of semzcnt.
	GETZCNT = GETZCNT,
	// Sets the value of semval to arg.val.
	SETVAL  = SETVAL,
	// Sets the value of semval for each semaphore in the set.
	SETALL  = SETALL,
}

semun :: struct #raw_union {
	val:   c.int,
	buf:   ^semid_ds,
	array: [^]c.ushort,
}

when ODIN_OS == .NetBSD {
	@(private) LSEMCTL :: "__semctl50"
} else {
	@(private) LSEMCTL :: "semctl"
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	SEM_UNDO :: 0o10000

	GETNCNT :: 3
	GETPID  :: 4
	GETVAL  :: 5
	GETALL  :: 6
	GETZCNT :: 7
	SETVAL  :: 8
	SETALL  :: 9

	when ODIN_OS == .Darwin {
		semid_ds :: struct #max_field_align(4) {
			sem_perm:  ipc_perm,     /* [PSX] operation permission structure */
			sem_base:  c.int32_t,    /* 32 bit base ptr for semaphore set */
			sem_nsems: c.ushort,     /* [PSX] number of semaphores in set */
			sem_otime: time_t,       /* [PSX] last semop() */
			sem_pad1:  c.int32_t,
			sem_ctime: time_t,       /* [PSX] last time changed by semctl() */
			sem_pad2:  c.int32_t,
			sem_pad3:  [4]c.int32_t,
		}
	} else when ODIN_OS == .FreeBSD {
		semid_ds :: struct {
			sem_perm:  ipc_perm, /* [PSX] operation permission structure */
			sem_base:  rawptr,   /* 32 bit base ptr for semaphore set */
			sem_nsems: c.ushort, /* [PSX] number of semaphores in set */
			sem_otime: time_t,   /* [PSX] last semop() */
			sem_ctime: time_t,   /* [PSX] last time changed by semctl() */
		}
	} else when ODIN_OS == .NetBSD {
		semid_ds :: struct {
			sem_perm:  ipc_perm, /* [PSX] operation permission structure */
			sem_nsems: c.ushort, /* [PSX] number of semaphores in set */
			sem_otime: time_t,   /* [PSX] last semop() */
			sem_ctime: time_t,   /* [PSX] last time changed by semctl() */
			_sem_base: rawptr,   /* 32 bit base ptr for semaphore set */
		}
	} else when ODIN_OS == .OpenBSD {
		semid_ds :: struct {
			sem_perm:  ipc_perm, /* [PSX] operation permission structure */
			sem_nsems: c.ushort, /* [PSX] number of semaphores in set */
			sem_otime: time_t,   /* [PSX] last semop() */
			sem_pad1:  c.long,
			sem_ctime: time_t,   /* [PSX] last time changed by semctl() */
			sem_pad2:  c.long,
			sem_pad3:  [4]c.long,
		}
	}

	sembuf :: struct {
		sem_num: c.ushort, /* [PSX] semaphore number */
		sem_op:  c.short,  /* [PSX] semaphore operation */
		sem_flg: c.short,  /* [PSX] operation flags */
	}

} else when ODIN_OS == .Linux {

	SEM_UNDO :: 0x1000 // undo the operation on exit

	// Commands for `semctl'.
	GETPID  :: 11
	GETVAL  :: 12
	GETALL  :: 13
	GETNCNT :: 14
	GETZCNT :: 15
	SETVAL  :: 16
	SETALL  :: 17

	semid_ds :: struct {
		sem_perm:  ipc_perm,  // [PSX] operation permission structure
		sem_otime: time_t,    // [PSX] last semop()
		__sem_otime_high: c.ulong,
		sem_ctime: time_t,    // [PSX] last time changed by semctl()
		__sem_ctime_high: c.ulong,
		sem_nsems: c.ulong, // [PSX] number of semaphores in set
		__glibc_reserved3: c.ulong,
		__glibc_reserved4: c.ulong,
	}

	sembuf :: struct {
		sem_num: c.ushort, /* [PSX] semaphore number */
		sem_op:  c.short,  /* [PSX] semaphore operation */
		sem_flg: c.short,  /* [PSX] operation flags */
	}

} else {
	#panic("posix is unimplemented for the current target")
}
