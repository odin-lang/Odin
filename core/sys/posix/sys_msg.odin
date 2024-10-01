package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/msg.h = XSI message queue structures

foreign lib {
	/*
	Provides various operation as specified by the given cmd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/msgctl.html ]]
	*/
	@(link_name=LMSGCTL)
	msgctl :: proc(msqid: FD, cmd: IPC_Cmd, buf: ^msqid_ds) -> result ---

	/*
	Returns the message queue identifier associated with the argument key.

	Returns: -1 (setting errno) on failure, the identifier otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/msgget.html ]]
	*/
	msgget :: proc(key: key_t, msgflg: IPC_Flags) -> FD ---

	/*
	Read a message from the queue.

	Returns: -1 (setting errno) on failure, the bytes received otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/msgrcv.html ]]
	*/
	msgrcv :: proc(
		msgid:  FD,
		msgp:   rawptr,
		msgsz:  c.size_t,
		msgtyp: c.long,
		msgflg: IPC_Flags,
	) -> c.ssize_t ---

	/*
	Send a message on the queue.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/msgsnd.html ]]
	*/
	msgsnd :: proc(msgid: FD, msgp: rawptr, msgsz: c.size_t, msgflg: IPC_Flags) -> result ---
}

when ODIN_OS == .NetBSD {
	@(private) LMSGCTL :: "__msgctl50"
} else {
	@(private) LMSGCTL :: "msgctl"
}

when ODIN_OS == .Darwin {

	msgqnum_t :: distinct c.ulong
	msglen_t  :: distinct c.ulong

	MSG_NOERROR :: 0o10000

	msqid_ds :: struct #max_field_align(4) {
		msg_perm:   ipc_perm,     /* [PSX] operation permission structure */
		msg_first:  c.int32_t,
		msg_last:   c.int32_t,
		msg_cbytes: msglen_t,
		msg_qnum:   msgqnum_t,    /* [PSX] number of messages currently on queue */
		msg_qbytes: msglen_t,     /* [PSX] maximum number of bytes allowed on queue */
		msg_lspid:  pid_t,        /* [PSX] process ID of last msgsnd() */
		msg_lrpid:  pid_t,        /* [PSX] process ID of last msgrcv() */
		msg_stime:  time_t,       /* [PSX] time of last msgsnd() */
		msg_pad1:   c.int32_t,
		msg_rtime:  time_t,       /* [PSX] time of last msgrcv() */
		msg_pad2:   c.int32_t,
		msg_ctime:  time_t,       /* [PSX] time of last change */
		msg_pad3:   c.int32_t,
		msg_pad4:   [4]c.int32_t,
	}

} else when ODIN_OS == .FreeBSD {

	msgqnum_t :: distinct c.ulong
	msglen_t  :: distinct c.ulong

	MSG_NOERROR :: 0o10000

	msqid_ds :: struct {
		msg_perm:    ipc_perm,  /* [PSX] operation permission structure */
		__msg_first: rawptr,
		__msg_last:  rawptr,
		msg_cbytes:  msglen_t,
		msg_qnum:    msgqnum_t, /* [PSX] number of messages currently on queue */
		msg_qbytes:  msglen_t,  /* [PSX] maximum number of bytes allowed on queue */
		msg_lspid:   pid_t,     /* [PSX] process ID of last msgsnd() */
		msg_lrpid:   pid_t,     /* [PSX] process ID of last msgrcv() */
		msg_stime:   time_t,    /* [PSX] time of last msgsnd() */
		msg_rtime:   time_t,    /* [PSX] time of last msgrcv() */
		msg_ctime:   time_t,    /* [PSX] time of last change */
	}

} else when ODIN_OS == .NetBSD {

	msgqnum_t :: distinct c.ulong
	msglen_t  :: distinct c.size_t

	MSG_NOERROR :: 0o10000

	msqid_ds :: struct {
		msg_perm:    ipc_perm,  /* [PSX] operation permission structure */
		msg_qnum:    msgqnum_t, /* [PSX] number of messages currently on queue */
		msg_qbytes:  msglen_t,  /* [PSX] maximum number of bytes allowed on queue */
		msg_lspid:   pid_t,     /* [PSX] process ID of last msgsnd() */
		msg_lrpid:   pid_t,     /* [PSX] process ID of last msgrcv() */
		msg_stime:   time_t,    /* [PSX] time of last msgsnd() */
		msg_rtime:   time_t,    /* [PSX] time of last msgrcv() */
		msg_ctime:   time_t,    /* [PSX] time of last change */

		_msg_first:  rawptr,
		_msg_last:   rawptr,
		_msg_cbytes: msglen_t,
	}

} else when ODIN_OS == .OpenBSD {

	msgqnum_t :: distinct c.ulong
	msglen_t  :: distinct c.ulong

	MSG_NOERROR :: 0o10000

	msqid_ds :: struct {
		msg_perm:    ipc_perm,  /* [PSX] operation permission structure */
		__msg_first: rawptr,
		__msg_last:  rawptr,
		msg_cbytes:  msglen_t,
		msg_qnum:    msgqnum_t, /* [PSX] number of messages currently on queue */
		msg_qbytes:  msglen_t,  /* [PSX] maximum number of bytes allowed on queue */
		msg_lspid:   pid_t,     /* [PSX] process ID of last msgsnd() */
		msg_lrpid:   pid_t,     /* [PSX] process ID of last msgrcv() */
		msg_stime:   time_t,    /* [PSX] time of last msgsnd() */
		msg_pad1:    c.long,
		msg_rtime:   time_t,    /* [PSX] time of last msgrcv() */
		msg_pad2:    c.long,
		msg_ctime:   time_t,    /* [PSX] time of last change */
		msg_pad3:    c.long,
		msg_pad4:    [4]c.long,
	}

} else {
	#panic("posix is unimplemented for the current target")
}
