package sys_freebsd

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Feoramund: Initial implementation.
*/

import "core:c"

// These definitions have been extracted from a system running FreeBSD 14.0-RELEASE.
// Most comments come from system header files.
//
// Where applicable, original C struct and define names are indicated in line
// comments above Odin declarations.
//
// This data is separated into blocks by original header file. If you happen to
// add or change something in this file, mind the organizational structure.

Fd :: distinct c.int

//
// #include <x86/_types.h>
//         &
// #include <arm/_types.h>
//

time_t :: distinct i64

//
// #include <sys/_types.h>
//

off_t       :: distinct i64
pid_t       :: distinct i32
sa_family_t :: distinct u8
socklen_t   :: distinct u32
suseconds_t :: distinct c.long /* microseconds (signed) */

//
// #include <sys/types.h>
//

in_port_t :: distinct u16be

//
// #include <sys/_timespec.h>
//

timespec :: struct {
	sec: time_t,  /* seconds */
	nsec: c.long, /* and nanoseconds */
}

//
// #include <sys/_timeval.h>
//

timeval :: struct {
	sec:  time_t,      /* seconds */
	usec: suseconds_t, /* and microseconds */
}

//
// #include <sys/errno.h>
//

Errno :: enum c.int {
	NONE            = 0,
	EPERM           = 1,
	ENOENT          = 2,
	ESRCH           = 3,
	EINTR           = 4,
	EIO             = 5,
	ENXIO           = 6,
	E2BIG           = 7,
	ENOEXEC         = 8,
	EBADF           = 9,
	ECHILD          = 10,
	EDEADLK         = 11,
	ENOMEM          = 12,
	EACCES          = 13,
	EFAULT          = 14,
	ENOTBLK         = 15,
	EBUSY           = 16,
	EEXIST          = 17,
	EXDEV           = 18,
	ENODEV          = 19,
	ENOTDIR         = 20,
	EISDIR          = 21,
	EINVAL          = 22,
	ENFILE          = 23,
	EMFILE          = 24,
	ENOTTY          = 25,
	ETXTBSY         = 26,
	EFBIG           = 27,
	ENOSPC          = 28,
	ESPIPE          = 29,
	EROFS           = 30,
	EMLINK          = 31,
	EPIPE           = 32,
	EDOM            = 33,
	ERANGE          = 34,
	EAGAIN          = 35,
	EWOULDBLOCK     = EAGAIN,
	EINPROGRESS     = 36,
	EALREADY        = 37,
	ENOTSOCK        = 38,
	EDESTADDRREQ    = 39,
	EMSGSIZE        = 40,
	EPROTOTYPE      = 41,
	ENOPROTOOPT     = 42,
	EPROTONOSUPPORT = 43,
	ESOCKTNOSUPPORT = 44,
	EOPNOTSUPP      = 45,
	ENOTSUP         = EOPNOTSUPP,
	EPFNOSUPPORT    = 46,
	EAFNOSUPPORT    = 47,
	EADDRINUSE      = 48,
	EADDRNOTAVAIL   = 49,
	ENETDOWN        = 50,
	ENETUNREACH     = 51,
	ENETRESET       = 52,
	ECONNABORTED    = 53,
	ECONNRESET      = 54,
	ENOBUFS         = 55,
	EISCONN         = 56,
	ENOTCONN        = 57,
	ESHUTDOWN       = 58,
	ETOOMANYREFS    = 59,
	ETIMEDOUT       = 60,
	ECONNREFUSED    = 61,
	ELOOP           = 62,
	ENAMETOOLONG    = 63,
	EHOSTDOWN       = 64,
	EHOSTUNREACH    = 65,
	ENOTEMPTY       = 66,
	EPROCLIM        = 67,
	EUSERS          = 68,
	EDQUOT          = 69,
	ESTALE          = 70,
	EREMOTE         = 71,
	EBADRPC         = 72,
	ERPCMISMATCH    = 73,
	EPROGUNAVAIL    = 74,
	EPROGMISMATCH   = 75,
	EPROCUNAVAIL    = 76,
	ENOLCK          = 77,
	ENOSYS          = 78,
	EFTYPE          = 79,
	EAUTH           = 80,
	ENEEDAUTH       = 81,
	EIDRM           = 82,
	ENOMSG          = 83,
	EOVERFLOW       = 84,
	ECANCELED       = 85,
	EILSEQ          = 86,
	ENOATTR         = 87,
	EDOOFUS         = 88,
	EBADMSG         = 89,
	EMULTIHOP       = 90,
	ENOLINK         = 91,
	EPROTO          = 92,
	ENOTCAPABLE     = 93,
	ECAPMODE        = 94,
	ENOTRECOVERABLE = 95,
	EOWNERDEAD      = 96,
	EINTEGRITY      = 97,
}

//
// #include <sys/socket.h>
//

/*
 * Types
 */
// #define SOCK_*
Socket_Type :: enum c.int {
	STREAM    = 1, /* stream socket */
	DGRAM     = 2, /* datagram socket */
	RAW       = 3, /* raw-protocol interface */
	RDM       = 4, /* reliably-delivered message */
	SEQPACKET = 5, /* sequenced packet stream */

	/*
	 * Creation flags, OR'ed into socket() and socketpair() type argument.
	 */
	CLOEXEC   = 0x10000000,
	NONBLOCK  = 0x20000000,
}

Socket_Flag_Index :: enum c.int {
	CLOEXEC  = 28, // 0x10000000
	NONBLOCK = 29, // 0x20000000
}

Socket_Flags :: bit_set[Socket_Flag_Index; c.int]

/*
 * Option flags per-socket.
 */
// #define SO_*
Socket_Option :: enum c.int {
	DEBUG             = 0x00000001, /* turn on debugging info recording */
	ACCEPTCONN        = 0x00000002, /* socket has had listen() */
	REUSEADDR         = 0x00000004, /* allow local address reuse */
	KEEPALIVE         = 0x00000008, /* keep connections alive */
	DONTROUTE         = 0x00000010, /* just use interface addresses */
	BROADCAST         = 0x00000020, /* permit sending of broadcast msgs */
	USELOOPBACK       = 0x00000040, /* bypass hardware when possible */
	LINGER            = 0x00000080, /* linger on close if data present */
	OOBINLINE         = 0x00000100, /* leave received OOB data in line */
	REUSEPORT         = 0x00000200, /* allow local address & port reuse */
	TIMESTAMP         = 0x00000400, /* timestamp received dgram traffic */
	NOSIGPIPE         = 0x00000800, /* no SIGPIPE from EPIPE */
	ACCEPTFILTER      = 0x00001000, /* there is an accept filter */
	BINTIME           = 0x00002000, /* timestamp received dgram traffic */
	NO_OFFLOAD        = 0x00004000, /* socket cannot be offloaded */
	NO_DDP            = 0x00008000, /* disable direct data placement */
	REUSEPORT_LB      = 0x00010000, /* reuse with load balancing */
	RERROR            = 0x00020000, /* keep track of receive errors */

	/*
	 * Additional options, not kept in so_options.
	 */
	SNDBUF            = 0x1001,      /* send buffer size */
	RCVBUF            = 0x1002,      /* receive buffer size */
	SNDLOWAT          = 0x1003,      /* send low-water mark */
	RCVLOWAT          = 0x1004,      /* receive low-water mark */
	SNDTIMEO          = 0x1005,      /* send timeout */
	RCVTIMEO          = 0x1006,      /* receive timeout */
	ERROR             = 0x1007,      /* get error status and clear */
	TYPE              = 0x1008,      /* get socket type */
	LABEL             = 0x1009,      /* socket's MAC label */
	PEERLABEL         = 0x1010,      /* socket's peer's MAC label */
	LISTENQLIMIT      = 0x1011,      /* socket's backlog limit */
	LISTENQLEN        = 0x1012,      /* socket's complete queue length */
	LISTENINCQLEN     = 0x1013,      /* socket's incomplete queue length */
	SETFIB            = 0x1014,      /* use this FIB to route */
	USER_COOKIE       = 0x1015,      /* user cookie (dummynet etc.) */
	PROTOCOL          = 0x1016,      /* get socket protocol (Linux name) */
	PROTOTYPE         = PROTOCOL,    /* alias for SO_PROTOCOL (SunOS name) */
	TS_CLOCK          = 0x1017,      /* clock type used for SO_TIMESTAMP */
	MAX_PACING_RATE   = 0x1018,      /* socket's max TX pacing rate (Linux name) */
	DOMAIN            = 0x1019,      /* get socket domain */

	TS_REALTIME_MICRO = 0,           /* microsecond resolution, realtime */
	TS_BINTIME        = 1,           /* sub-nanosecond resolution, realtime */
	TS_REALTIME       = 2,           /* nanosecond resolution, realtime */
	TS_MONOTONIC      = 3,           /* nanosecond resolution, monotonic */
	TS_DEFAULT        = TS_REALTIME_MICRO,
	TS_CLOCK_MAX      = TS_MONOTONIC,
}

Valid_Socket_Option_Level :: union #no_nil {
	Protocol_Family,
	Socket_Option_Level,
}

/*
 * Level number for (get/set)sockopt() to apply to socket itself.
 */
// #define SOL_*
Socket_Option_Level :: enum c.int {
	SOCKET = 0xffff, /* options for socket level */
}

// #define MSG_*
Message_Flag :: enum c.int {
	OOB          = 0x00000001, /* process out-of-band data */
	PEEK         = 0x00000002, /* peek at incoming message */
	DONTROUTE    = 0x00000004, /* send without using routing tables */
	EOR          = 0x00000008, /* data completes record */
	TRUNC        = 0x00000010, /* data discarded before delivery */
	CTRUNC       = 0x00000020, /* control data lost before delivery */
	WAITALL      = 0x00000040, /* wait for full request or error */
	DONTWAIT     = 0x00000080, /* this message should be nonblocking */
	EOF          = 0x00000100, /* data completes connection */
	/*             0x00000200     unused */
	/*             0x00000400     unused */
	/*             0x00000800     unused */
	/*             0x00001000     unused */
	NOTIFICATION = 0x00002000, /* SCTP notification */
	NBIO         = 0x00004000, /* FIONBIO mode, used by fifofs */
	COMPAT       = 0x00008000, /* used in sendit() */
	SOCALLBCK    = 0x00010000, /* for use by socket callbacks - soreceive (TCP) */
	NOSIGNAL     = 0x00020000, /* do not generate SIGPIPE on EOF */
	CMSG_CLOEXEC = 0x00040000, /* make received fds close-on-exec */
	WAITFORONE   = 0x00080000, /* for recvmmsg() */
}

// Specific subset of `MSG_*` defines that are only for `recv*`.
Recv_Flags :: enum c.int {
	NONE         = 0,
	OOB          = cast(c.int)Message_Flag.OOB,          /* process out-of-band data */
	PEEK         = cast(c.int)Message_Flag.PEEK,         /* peek at incoming message */
	TRUNC        = cast(c.int)Message_Flag.TRUNC,        /* return real packet or datagram length */
	WAITALL      = cast(c.int)Message_Flag.WAITALL,      /* wait for full request or error */
	DONTWAIT     = cast(c.int)Message_Flag.DONTWAIT,     /* do not block */
	CMSG_CLOEXEC = cast(c.int)Message_Flag.CMSG_CLOEXEC, /* set received fds close-on-exec */
	WAITFORONE   = cast(c.int)Message_Flag.WAITFORONE,   /* do not block after receiving the first message */
}

// Specific subset of `MSG_*` defines that are only for `send*`.
Send_Flags :: enum c.int {
	NONE      = 0,
	OOB       = cast(c.int)Message_Flag.OOB,       /* process out-of-band data */
	DONTROUTE = cast(c.int)Message_Flag.DONTROUTE, /* bypass routing, use direct interface */
	EOR       = cast(c.int)Message_Flag.EOR,       /* data completes record */
	DONTWAIT  = cast(c.int)Message_Flag.DONTWAIT,  /* do not block */
	EOF       = cast(c.int)Message_Flag.EOF,       /* data completes transaction */
	NOSIGNAL  = cast(c.int)Message_Flag.NOSIGNAL,  /* do not generate SIGPIPE on EOF */
}

// Socket address struct header without protocol-specific data.
//
// Inherit from this if you want a custom socket address datatype for use with
// bind(), listen(), et cetera.
Socket_Address_Header :: struct #packed {
	len: c.uchar,           /* address length */
	family: Address_Family, /* address family */
}

// struct sockaddr
Socket_Address_Basic :: struct #packed {
	using _: Socket_Address_Header,
	data: [14]c.char,
}

/*
 * howto arguments for shutdown(2), specified by Posix.1g.
 */
// #define SHUT_*
Shutdown_Method :: enum c.int {
	RD   = 0, /* shut down the reading side */
	WR   = 1, /* shut down the writing side */
	RDWR = 2, /* shut down both sides */
}

// #define AF_*
Address_Family :: enum sa_family_t {
	UNSPEC      = 0,
	LOCAL       = 1,
	UNIX        = LOCAL,
	INET        = 2,
	IMPLINK     = 3,
	PUP         = 4,
	CHAOS       = 5,
	NETBIOS     = 6,
	ISO         = 7,
	OSI         = ISO,
	ECMA        = 8,
	DATAKIT     = 9,
	CCITT       = 10,
	SNA         = 11,
	DECnet      = 12,
	DLI         = 13,
	LAT         = 14,
	HYLINK      = 15,
	APPLETALK   = 16,
	ROUTE       = 17,
	LINK        = 18,
	PSEUDO_XTP  = 19,
	COIP        = 20,
	CNT         = 21,
	PSEUDO_RTIP = 22,
	IPX         = 23,
	SIP         = 24,
	PSEUDO_PIP  = 25,
	ISDN        = 26,
	E164        = ISDN,
	PSEUDO_KEY  = 27,
	INET6       = 28,
	NATM        = 29,
	ATM         = 30,
	NETGRAPH    = 32,
	SLOW        = 33,
	SCLUSTER    = 34,
	ARP         = 35,
	BLUETOOTH   = 36,
	IEEE80211   = 37,
	NETLINK     = 38,
	INET_SDP    = 40,
	INET6_SDP   = 42,
	HYPERV      = 43,
	DIVERT      = 44,
	MAX         = 44,
	VENDOR00    = 39,
	VENDOR01    = 41,
	VENDOR03    = 45,
	VENDOR04    = 47,
	VENDOR05    = 49,
	VENDOR06    = 51,
	VENDOR07    = 53,
	VENDOR08    = 55,
	VENDOR09    = 57,
	VENDOR10    = 59,
	VENDOR11    = 61,
	VENDOR12    = 63,
	VENDOR13    = 65,
	VENDOR14    = 67,
	VENDOR15    = 69,
	VENDOR16    = 71,
	VENDOR17    = 73,
	VENDOR18    = 75,
	VENDOR19    = 77,
	VENDOR20    = 79,
	VENDOR21    = 81,
	VENDOR22    = 83,
	VENDOR23    = 85,
	VENDOR24    = 87,
	VENDOR25    = 89,
	VENDOR26    = 91,
	VENDOR27    = 93,
	VENDOR28    = 95,
	VENDOR29    = 97,
	VENDOR30    = 99,
	VENDOR31    = 101,
	VENDOR32    = 103,
	VENDOR33    = 105,
	VENDOR34    = 107,
	VENDOR35    = 109,
	VENDOR36    = 111,
	VENDOR37    = 113,
	VENDOR38    = 115,
	VENDOR39    = 117,
	VENDOR40    = 119,
	VENDOR41    = 121,
	VENDOR42    = 123,
	VENDOR43    = 125,
	VENDOR44    = 127,
	VENDOR45    = 129,
	VENDOR46    = 131,
	VENDOR47    = 133,
}

// #define PF_*
Protocol_Family :: enum sa_family_t {
	UNSPEC    = cast(sa_family_t)Address_Family.UNSPEC,
	LOCAL     = cast(sa_family_t)Address_Family.LOCAL,
	UNIX      = LOCAL,
	INET      = cast(sa_family_t)Address_Family.INET,
	IMPLINK   = cast(sa_family_t)Address_Family.IMPLINK,
	PUP       = cast(sa_family_t)Address_Family.PUP,
	CHAOS     = cast(sa_family_t)Address_Family.CHAOS,
	NETBIOS   = cast(sa_family_t)Address_Family.NETBIOS,
	ISO       = cast(sa_family_t)Address_Family.ISO,
	OSI       = cast(sa_family_t)Address_Family.ISO,
	ECMA      = cast(sa_family_t)Address_Family.ECMA,
	DATAKIT   = cast(sa_family_t)Address_Family.DATAKIT,
	CCITT     = cast(sa_family_t)Address_Family.CCITT,
	SNA       = cast(sa_family_t)Address_Family.SNA,
	DECnet    = cast(sa_family_t)Address_Family.DECnet,
	DLI       = cast(sa_family_t)Address_Family.DLI,
	LAT       = cast(sa_family_t)Address_Family.LAT,
	HYLINK    = cast(sa_family_t)Address_Family.HYLINK,
	APPLETALK = cast(sa_family_t)Address_Family.APPLETALK,
	ROUTE     = cast(sa_family_t)Address_Family.ROUTE,
	LINK      = cast(sa_family_t)Address_Family.LINK,
	XTP       = cast(sa_family_t)Address_Family.PSEUDO_XTP,
	COIP      = cast(sa_family_t)Address_Family.COIP,
	CNT       = cast(sa_family_t)Address_Family.CNT,
	SIP       = cast(sa_family_t)Address_Family.SIP,
	IPX       = cast(sa_family_t)Address_Family.IPX,
	RTIP      = cast(sa_family_t)Address_Family.PSEUDO_RTIP,
	PIP       = cast(sa_family_t)Address_Family.PSEUDO_PIP,
	ISDN      = cast(sa_family_t)Address_Family.ISDN,
	KEY       = cast(sa_family_t)Address_Family.PSEUDO_KEY,
	INET6     = cast(sa_family_t)Address_Family.INET6,
	NATM      = cast(sa_family_t)Address_Family.NATM,
	ATM       = cast(sa_family_t)Address_Family.ATM,
	NETGRAPH  = cast(sa_family_t)Address_Family.NETGRAPH,
	SLOW      = cast(sa_family_t)Address_Family.SLOW,
	SCLUSTER  = cast(sa_family_t)Address_Family.SCLUSTER,
	ARP       = cast(sa_family_t)Address_Family.ARP,
	BLUETOOTH = cast(sa_family_t)Address_Family.BLUETOOTH,
	IEEE80211 = cast(sa_family_t)Address_Family.IEEE80211,
	NETLINK   = cast(sa_family_t)Address_Family.NETLINK,
	INET_SDP  = cast(sa_family_t)Address_Family.INET_SDP,
	INET6_SDP = cast(sa_family_t)Address_Family.INET6_SDP,
	DIVERT    = cast(sa_family_t)Address_Family.DIVERT,
	MAX       = cast(sa_family_t)Address_Family.MAX,
}

//
// /etc/protocols
//

Protocol :: enum c.int {
	IP              = 0,
	ICMP            = 1,
	IGMP            = 2,
	GGP             = 3,
	IP_ENCAP        = 4,
	ST2             = 5,
	TCP             = 6,
	CBT             = 7,
	EGP             = 8,
	IGP             = 9,
	BBN_RCC_MON     = 10,
	NVP_II          = 11,
	PUP             = 12,
	ARGUS           = 13,
	EMCON           = 14,
	XNET            = 15,
	CHAOS           = 16,
	UDP             = 17,
	MUX             = 18,
	DCN_MEAS        = 19,
	HMP             = 20,
	PRM             = 21,
	XNS_IDP         = 22,
	TRUNK_1         = 23,
	TRUNK_2         = 24,
	LEAF_1          = 25,
	LEAF_2          = 26,
	RDP             = 27,
	IRTP            = 28,
	ISO_TP4         = 29,
	NETBLT          = 30,
	MFE_NSP         = 31,
	MERIT_INP       = 32,
	DCCP            = 33,
	THREE_PC        = 34,
	IDPR            = 35,
	XTP             = 36,
	DDP             = 37,
	IDPR_CMTP       = 38,
	TP_PlusPlus     = 39,
	IL              = 40,
	IPV6            = 41,
	SDRP            = 42,
	IPV6_ROUTE      = 43,
	IPV6_FRAG       = 44,
	IDRP            = 45,
	RSVP            = 46,
	GRE             = 47,
	DSR             = 48,
	BNA             = 49,
	ESP             = 50,
	AH              = 51,
	I_NLSP          = 52,
	SWIPE           = 53,
	NARP            = 54,
	MOBILE          = 55,
	TLSP            = 56,
	SKIP            = 57,
	IPV6_ICMP       = 58,
	IPV6_NONXT      = 59,
	IPV6_OPTS       = 60,
	CFTP            = 62,
	SAT_EXPAK       = 64,
	KRYPTOLAN       = 65,
	RVD             = 66,
	IPPC            = 67,
	SAT_MON         = 69,
	VISA            = 70,
	IPCV            = 71,
	CPNX            = 72,
	CPHB            = 73,
	WSN             = 74,
	PVP             = 75,
	BR_SAT_MON      = 76,
	SUN_ND          = 77,
	WB_MON          = 78,
	WB_EXPAK        = 79,
	ISO_IP          = 80,
	VMTP            = 81,
	SECURE_VMTP     = 82,
	VINES           = 83,
	TTP             = 84,
	IPTM            = 84,
	NSFNET_IGP      = 85,
	DGP             = 86,
	TCF             = 87,
	EIGRP           = 88,
	OSPFIGP         = 89,
	Sprite_RPC      = 90,
	LARP            = 91,
	MTP             = 92,
	AX_25           = 93,
	IPIP            = 94,
	MICP            = 95,
	SCC_SP          = 96,
	ETHERIP         = 97,
	ENCAP           = 98,
	GMTP            = 100,
	IFMP            = 101,
	PNNI            = 102,
	PIM             = 103,
	ARIS            = 104,
	SCPS            = 105,
	QNX             = 106,
	A_N             = 107,
	IPComp          = 108,
	SNP             = 109,
	Compaq_Peer     = 110,
	IPX_in_IP       = 111,
	CARP            = 112,
	PGM             = 113,
	L2TP            = 115,
	DDX             = 116,
	IATP            = 117,
	STP             = 118,
	SRP             = 119,
	UTI             = 120,
	SMP             = 121,
	SM              = 122,
	PTP             = 123,
	ISIS            = 124,
	FIRE            = 125,
	CRTP            = 126,
	CRUDP           = 127,
	SSCOPMCE        = 128,
	IPLT            = 129,
	SPS             = 130,
	PIPE            = 131,
	SCTP            = 132,
	FC              = 133,
	RSVP_E2E_IGNORE = 134,
	Mobility_Header = 135,
	UDPLite         = 136,
	MPLS_IN_IP      = 137,
	MANET           = 138,
	HIP             = 139,
	SHIM6           = 140,
	WESP            = 141,
	ROHC            = 142,
	PFSYNC          = 240,
	DIVERT          = 258,
}

//
// #include <sys/fcntl.h>
//

/*
 * Constants used for fcntl(2)
 */

/* command values */
// #define F_*
File_Control_Command :: enum c.int {
	DUPFD          = 0,  /* duplicate file descriptor */
	GETFD          = 1,  /* get file descriptor flags */
	SETFD          = 2,  /* set file descriptor flags */
	GETFL          = 3,  /* get file status flags */
	SETFL          = 4,  /* set file status flags */
	GETOWN         = 5,  /* get SIGIO/SIGURG proc/pgrp */
	SETOWN         = 6,  /* set SIGIO/SIGURG proc/pgrp */
	OGETLK         = 7,  /* get record locking information */
	OSETLK         = 8,  /* set record locking information */
	OSETLKW        = 9,  /* F_SETLK; wait if blocked */
	DUP2FD         = 10, /* duplicate file descriptor to arg */
	GETLK          = 11, /* get record locking information */
	SETLK          = 12, /* set record locking information */
	SETLKW         = 13, /* F_SETLK; wait if blocked */
	SETLK_REMOTE   = 14, /* debugging support for remote locks */
	READAHEAD      = 15, /* read ahead */
	RDAHEAD        = 16, /* Darwin compatible read ahead */
	DUPFD_CLOEXEC  = 17, /* Like F_DUPFD, but FD_CLOEXEC is set */
	DUP2FD_CLOEXEC = 18, /* Like F_DUP2FD, but FD_CLOEXEC is set */
	ADD_SEALS      = 19,
	GET_SEALS      = 20,
	ISUNIONSTACK   = 21, /* Kludge for libc, don't use it. */
	KINFO          = 22, /* Return kinfo_file for this fd */
}

/* Seals (F_ADD_SEALS, F_GET_SEALS). */
// #define F_SEAL_*
File_Seal_Index :: enum c.int {
	SEAL   = 0, // 0x0001, /* Prevent adding sealings */
	SHRINK = 1, // 0x0002, /* May not shrink */
	GROW   = 2, // 0x0004, /* May not grow */
	WRITE  = 3, // 0x0008, /* May not write */
}

File_Seals :: bit_set[File_Seal_Index; c.int]

/* file descriptor flags (F_GETFD, F_SETFD) */
FD_CLOEXEC :: 1 /* close-on-exec flag */

/* record locking flags (F_GETLK, F_SETLK, F_SETLKW) */
// #define F_*
Record_Lock_Flag :: enum c.int {
	RDLCK       = 1, /* shared or read lock */
	UNLCK       = 2, /* unlock */
	WRLCK       = 3, /* exclusive or write lock */
	UNLCKSYS    = 4, /* purge locks for a given system ID */
	CANCEL      = 5, /* cancel an async lock request */
}

// struct flock
File_Lock :: struct {
	start:  off_t,            /* starting offset */
	len:    off_t,            /* len = 0 means until end of file */
	pid:    pid_t,            /* lock owner */
	type:   Record_Lock_Flag, /* lock type: read/write, etc. */
	whence: c.short,          /* type of l_start */
	sysid:  c.int,            /* remote system id or zero for local */
}

/*
 * File status flags: these are used by open(2), fcntl(2).
 * They are also used (indirectly) in the kernel file structure f_flags,
 * which is a superset of the open/fcntl flags.  Open flags and f_flags
 * are inter-convertible using OFLAGS(fflags) and FFLAGS(oflags).
 * Open/fcntl flags begin with O_; kernel-internal flags begin with F.
 */
File_Status_Flag :: enum c.int {
	/* open-only flags */
	RDONLY          = 0x0000,     /* open for reading only */
	WRONLY          = 0x0001,     /* open for writing only */
	RDWR            = 0x0002,     /* open for reading and writing */
	ACCMODE         = 0x0003,     /* mask for above modes */

	/**/
	NONBLOCK        = 0x0004,     /* no delay */
	APPEND          = 0x0008,     /* set append mode */
	SHLOCK          = 0x0010,     /* open with shared file lock */
	EXLOCK          = 0x0020,     /* open with exclusive file lock */
	ASYNC           = 0x0040,     /* signal pgrp when data ready */
	FSYNC           = 0x0080,     /* synchronous writes */
	SYNC            = 0x0080,     /* POSIX synonym for O_FSYNC */
	NOFOLLOW        = 0x0100,     /* don't follow symlinks */
	CREAT           = 0x0200,     /* create if nonexistent */
	TRUNC           = 0x0400,     /* truncate to zero length */
	EXCL            = 0x0800,     /* error if already exists */

	/* Defined by POSIX 1003.1; BSD default, but must be distinct from O_RDONLY. */
	NOCTTY          = 0x8000,     /* don't assign controlling terminal */

	/* Attempt to bypass buffer cache */
	DIRECT          = 0x00010000,

	DIRECTORY       = 0x00020000, /* Fail if not directory */
	EXEC            = 0x00040000, /* Open for execute only */
	SEARCH          = EXEC,

	/* Defined by POSIX 1003.1-2008; BSD default, but reserve for future use. */
	TTY_INIT        = 0x00080000, /* Restore default termios attributes */

	CLOEXEC         = 0x00100000,
	VERIFY          = 0x00200000, /* open only after verification */
	PATH            = 0x00400000, /* fd is only a path */
	RESOLVE_BENEATH = 0x00800000, /* Do not allow name resolution to walk out of cwd */
	DSYNC           = 0x01000000, /* POSIX data sync */
	EMPTY_PATH      = 0x02000000,
}

File_Status_Index :: enum c.int {
	// No RDONLY (0x00), as that is implied and also impossible to express in a bit_set.

	// The comments below come from the documentation for `fcntl`.
	WRONLY          = 0,
	RDWR            = 1,

	/* Non-blocking I/O; if no data is available to a read(2)
	   system call, or if a write(2) operation would block, the
	   read or write call returns -1 with the error EAGAIN. */
	NONBLOCK        = 2,

	/* Force each write to append at the end of file; corresponds
	   to the O_APPEND flag of open(2). */
	APPEND          = 3,

	SHLOCK          = 4,
	EXLOCK          = 5,

	/* Enable the SIGIO signal to be sent to the process group when
	   I/O is possible, e.g., upon availability of data to be read. */
	ASYNC           = 6,

	/* Enable synchronous writes.  Corresponds to the O_SYNC flag
	   of open(2).  O_FSYNC is an historical synonym for O_SYNC. */
	SYNC            = 7,

	FSYNC           = 7,
	NOFOLLOW        = 8,
	CREAT           = 9,
	TRUNC           = 10,
	EXCL            = 11,

	NOCTTY          = 15,

	/* Minimize or eliminate the cache effects of reading and
	   writing.  The system will attempt to avoid caching the data
	   you read or write.  If it cannot avoid caching the data, it
	   will minimize the impact the data has on the cache.  Use of
	   this flag can drastically reduce performance if not used
	   with care. */
	DIRECT          = 16,

	DIRECTORY       = 17,
	EXEC            = 18,
	TTY_INIT        = 19,
	CLOEXEC         = 20,
	VERIFY          = 21,
	PATH            = 22,
	RESOLVE_BENEATH = 23,

	/* Enable synchronous data writes.  Corresponds to the O_DSYNC
	   flag of open(2). */
	DSYNC           = 24,

	EMPTY_PATH      = 25,
}

File_Status_Flags :: bit_set[File_Status_Index; c.int]

//
// #include <sys/_sockaddr_storage.h>
//

@private _SS_MAXSIZE   :: 128
@private _SS_ALIGNSIZE :: size_of(i64)
@private _SS_PAD1SIZE  :: _SS_ALIGNSIZE - size_of(c.uchar) - size_of(Address_Family)
@private _SS_PAD2SIZE  :: _SS_MAXSIZE - size_of(c.uchar) - size_of(Address_Family) - _SS_PAD1SIZE - _SS_ALIGNSIZE

/*
 * RFC 2553: protocol-independent placeholder for socket addresses
 */
// struct sockaddr_storage
Socket_Address_Storage :: struct {
	using _: Socket_Address_Header,
	_pad1:  [_SS_PAD1SIZE]c.char,
	_align: i64,                  /* force desired struct alignment */
	_pad2:  [_SS_PAD2SIZE]c.char,
}

//
// #include <sys/sysctl.h>
//

// MIB, or Management Information Base. Used in sysctl().
MIB_Identifier :: enum c.int {
	/*
	* Top-level identifiers
	*/
	CTL_SYSCTL = 0,                          /* "magic" numbers */
	CTL_KERN = 1,                            /* "high kernel": proc, limits */
	CTL_VM = 2,                              /* virtual memory */
	CTL_VFS = 3,                             /* filesystem, mount type is next */
	CTL_NET = 4,                             /* network, see socket.h */
	CTL_DEBUG = 5,                           /* debugging parameters */
	CTL_HW = 6,                              /* generic cpu/io */
	CTL_MACHDEP = 7,                         /* machine dependent */
	CTL_USER = 8,                            /* user-level */
	CTL_P1003_1B = 9,                        /* POSIX 1003.1B */

	/*
	* CTL_SYSCTL identifiers
	*/
	CTL_SYSCTL_DEBUG = 0,                    /* printf all nodes */
	CTL_SYSCTL_NAME = 1,                     /* string name of OID */
	CTL_SYSCTL_NEXT = 2,                     /* next OID, honoring CTLFLAG_SKIP */
	CTL_SYSCTL_NAME2OID = 3,                 /* int array of name */
	CTL_SYSCTL_OIDFMT = 4,                   /* OID's kind and format */
	CTL_SYSCTL_OIDDESCR = 5,                 /* OID's description */
	CTL_SYSCTL_OIDLABEL = 6,                 /* aggregation label */
	CTL_SYSCTL_NEXTNOSKIP = 7,               /* next OID, ignoring CTLFLAG_SKIP */

	/*
	* CTL_KERN identifiers
	*/
	KERN_OSTYPE = 1,                         /* string: system version */
	KERN_OSRELEASE = 2,                      /* string: system release */
	KERN_OSREV = 3,                          /* int: system revision */
	KERN_VERSION = 4,                        /* string: compile time info */
	KERN_MAXVNODES = 5,                      /* int: max vnodes */
	KERN_MAXPROC = 6,                        /* int: max processes */
	KERN_MAXFILES = 7,                       /* int: max open files */
	KERN_ARGMAX = 8,                         /* int: max arguments to exec */
	KERN_SECURELVL = 9,                      /* int: system security level */
	KERN_HOSTNAME = 10,                      /* string: hostname */
	KERN_HOSTID = 11,                        /* int: host identifier */
	KERN_CLOCKRATE = 12,                     /* struct: struct clockrate */
	/* was: #define KERN_VNODE13; disabled in 2003 and removed in 2023 */
	KERN_PROC = 14,                          /* struct: process entries */
	KERN_FILE = 15,                          /* struct: file entries */
	KERN_PROF = 16,                          /* node: kernel profiling info */
	KERN_POSIX1 = 17,                        /* int: POSIX.1 version */
	KERN_NGROUPS = 18,                       /* int: # of supplemental group ids */
	KERN_JOB_CONTROL = 19,                   /* int: is job control available */
	KERN_SAVED_IDS = 20,                     /* int: saved set-user/group-ID */
	KERN_BOOTTIME = 21,                      /* struct: time kernel was booted */
	KERN_NISDOMAINNAME = 22,                 /* string: YP domain name */
	KERN_UPDATEINTERVAL = 23,                /* int: update process sleep time */
	KERN_OSRELDATE = 24,                     /* int: kernel release date */
	KERN_NTP_PLL = 25,                       /* node: NTP PLL control */
	KERN_BOOTFILE = 26,                      /* string: name of booted kernel */
	KERN_MAXFILESPERPROC = 27,               /* int: max open files per proc */
	KERN_MAXPROCPERUID = 28,                 /* int: max processes per uid */
	KERN_DUMPDEV = 29,                       /* struct cdev *: device to dump on */
	KERN_IPC = 30,                           /* node: anything related to IPC */
	KERN_DUMMY = 31,                         /* unused */
	KERN_PS_STRINGS = 32,                    /* int: address of PS_STRINGS */
	KERN_USRSTACK = 33,                      /* int: address of USRSTACK */
	KERN_LOGSIGEXIT = 34,                    /* int: do we log sigexit procs? */
	KERN_IOV_MAX = 35,                       /* int: value of UIO_MAXIOV */
	KERN_HOSTUUID = 36,                      /* string: host UUID identifier */
	KERN_ARND = 37,                          /* int: from arc4rand() */
	KERN_MAXPHYS = 38,                       /* int: MAXPHYS value */
	KERN_LOCKF = 39,                         /* struct: lockf reports */
	/*
	* KERN_PROC subtypes
	*/
	KERN_PROC_ALL = 0,                       /* everything */
	KERN_PROC_PID = 1,                       /* by process id */
	KERN_PROC_PGRP = 2,                      /* by process group id */
	KERN_PROC_SESSION = 3,                   /* by session of pid */
	KERN_PROC_TTY = 4,                       /* by controlling tty */
	KERN_PROC_UID = 5,                       /* by effective uid */
	KERN_PROC_RUID = 6,                      /* by real uid */
	KERN_PROC_ARGS = 7,                      /* get/set arguments/proctitle */
	KERN_PROC_PROC = 8,                      /* only return procs */
	KERN_PROC_SV_NAME = 9,                   /* get syscall vector name */
	KERN_PROC_RGID = 10,                     /* by real group id */
	KERN_PROC_GID = 11,                      /* by effective group id */
	KERN_PROC_PATHNAME = 12,                 /* path to executable */
	KERN_PROC_OVMMAP = 13,                   /* Old VM map entries for process */
	KERN_PROC_OFILEDESC = 14,                /* Old file descriptors for process */
	KERN_PROC_KSTACK = 15,                   /* Kernel stacks for process */
	KERN_PROC_INC_THREAD = 0x10,             /* modifier for pid, pgrp, tty, uid, ruid, gid, rgid and proc. This effectively uses 16-31 */
	KERN_PROC_VMMAP = 32,                    /* VM map entries for process */
	KERN_PROC_FILEDESC = 33,                 /* File descriptors for process */
	KERN_PROC_GROUPS = 34,                   /* process groups */
	KERN_PROC_ENV = 35,                      /* get environment */
	KERN_PROC_AUXV = 36,                     /* get ELF auxiliary vector */
	KERN_PROC_RLIMIT = 37,                   /* process resource limits */
	KERN_PROC_PS_STRINGS = 38,               /* get ps_strings location */
	KERN_PROC_UMASK = 39,                    /* process umask */
	KERN_PROC_OSREL = 40,                    /* osreldate for process binary */
	KERN_PROC_SIGTRAMP = 41,                 /* signal trampoline location */
	KERN_PROC_CWD = 42,                      /* process current working directory */
	KERN_PROC_NFDS = 43,                     /* number of open file descriptors */
	KERN_PROC_SIGFASTBLK = 44,               /* address of fastsigblk magic word */
	KERN_PROC_VM_LAYOUT = 45,                /* virtual address space layout info */

	/*
	* KERN_IPC identifiers
	*/
	KIPC_MAXSOCKBUF = 1,                     /* int: max size of a socket buffer */
	KIPC_SOCKBUF_WASTE = 2,                  /* int: wastage factor in sockbuf */
	KIPC_SOMAXCONN = 3,                      /* int: max length of connection q */
	KIPC_MAX_LINKHDR = 4,                    /* int: max length of link header */
	KIPC_MAX_PROTOHDR = 5,                   /* int: max length of network header */
	KIPC_MAX_HDR = 6,                        /* int: max total length of headers */
	KIPC_MAX_DATALEN = 7,                    /* int: max length of data? */

	/*
	 * Definitions for network related sysctl, CTL_NET.
	 *
	 * Second level is protocol family.
	 * Third level is protocol number.
	 *
	 * Further levels are defined by the individual families.
	 */

	/*
	 * PF_ROUTE - Routing table
	 *
	 * Three additional levels are defined:
	 *      Fourth: address family, 0 is wildcard
	 *      Fifth: type of info, defined below
	 *      Sixth: flag(s) to mask with for NET_RT_FLAGS
	 */
	NET_RT_DUMP = 1,                         /* dump; may limit to a.f. */
	NET_RT_FLAGS = 2,                        /* by flags, e.g. RESOLVING */
	NET_RT_IFLIST = 3,                       /* survey interface list */
	NET_RT_IFMALIST = 4,                     /* return multicast address list */
	NET_RT_IFLISTL = 5,                      /* Survey interface list, using 'l'en versions of msghdr structs. */
	NET_RT_NHOP = 6,                         /* dump routing nexthops */
	NET_RT_NHGRP = 7,                        /* dump routing nexthop groups */

	/*
	* CTL_HW identifiers
	*/
	HW_MACHINE = 1,                          /* string: machine class */
	HW_MODEL = 2,                            /* string: specific machine model */
	HW_NCPU = 3,                             /* int: number of cpus */
	HW_BYTEORDER = 4,                        /* int: machine byte order */
	HW_PHYSMEM = 5,                          /* int: total memory */
	HW_USERMEM = 6,                          /* int: non-kernel memory */
	HW_PAGESIZE = 7,                         /* int: software page size */
	HW_DISKNAMES = 8,                        /* strings: disk drive names */
	HW_DISKSTATS = 9,                        /* struct: diskstats[] */
	HW_FLOATINGPT = 10,                      /* int: has HW floating point? */
	HW_MACHINE_ARCH = 11,                    /* string: machine architecture */
	HW_REALMEM = 12,                         /* int: 'real' memory */

	/*
	* CTL_USER definitions
	*/
	USER_CS_PATH = 1,                        /* string: _CS_PATH */
	USER_BC_BASE_MAX = 2,                    /* int: BC_BASE_MAX */
	USER_BC_DIM_MAX = 3,                     /* int: BC_DIM_MAX */
	USER_BC_SCALE_MAX = 4,                   /* int: BC_SCALE_MAX */
	USER_BC_STRING_MAX = 5,                  /* int: BC_STRING_MAX */
	USER_COLL_WEIGHTS_MAX = 6,               /* int: COLL_WEIGHTS_MAX */
	USER_EXPR_NEST_MAX = 7,                  /* int: EXPR_NEST_MAX */
	USER_LINE_MAX = 8,                       /* int: LINE_MAX */
	USER_RE_DUP_MAX = 9,                     /* int: RE_DUP_MAX */
	USER_POSIX2_VERSION = 10,                /* int: POSIX2_VERSION */
	USER_POSIX2_C_BIND = 11,                 /* int: POSIX2_C_BIND */
	USER_POSIX2_C_DEV = 12,                  /* int: POSIX2_C_DEV */
	USER_POSIX2_CHAR_TERM = 13,              /* int: POSIX2_CHAR_TERM */
	USER_POSIX2_FORT_DEV = 14,               /* int: POSIX2_FORT_DEV */
	USER_POSIX2_FORT_RUN = 15,               /* int: POSIX2_FORT_RUN */
	USER_POSIX2_LOCALEDEF = 16,              /* int: POSIX2_LOCALEDEF */
	USER_POSIX2_SW_DEV = 17,                 /* int: POSIX2_SW_DEV */
	USER_POSIX2_UPE = 18,                    /* int: POSIX2_UPE */
	USER_STREAM_MAX = 19,                    /* int: POSIX2_STREAM_MAX */
	USER_TZNAME_MAX = 20,                    /* int: POSIX2_TZNAME_MAX */
	USER_LOCALBASE = 21,                     /* string: _PATH_LOCALBASE */

	CTL_P1003_1B_ASYNCHRONOUS_IO = 1,        /* boolean */
	CTL_P1003_1B_MAPPED_FILES = 2,           /* boolean */
	CTL_P1003_1B_MEMLOCK = 3,                /* boolean */
	CTL_P1003_1B_MEMLOCK_RANGE = 4,          /* boolean */
	CTL_P1003_1B_MEMORY_PROTECTION = 5,      /* boolean */
	CTL_P1003_1B_MESSAGE_PASSING = 6,        /* boolean */
	CTL_P1003_1B_PRIORITIZED_IO = 7,         /* boolean */
	CTL_P1003_1B_PRIORITY_SCHEDULING = 8,    /* boolean */
	CTL_P1003_1B_REALTIME_SIGNALS = 9,       /* boolean */
	CTL_P1003_1B_SEMAPHORES = 10,            /* boolean */
	CTL_P1003_1B_FSYNC = 11,                 /* boolean */
	CTL_P1003_1B_SHARED_MEMORY_OBJECTS = 12, /* boolean */
	CTL_P1003_1B_SYNCHRONIZED_IO = 13,       /* boolean */
	CTL_P1003_1B_TIMERS = 14,                /* boolean */
	CTL_P1003_1B_AIO_LISTIO_MAX = 15,        /* int */
	CTL_P1003_1B_AIO_MAX = 16,               /* int */
	CTL_P1003_1B_AIO_PRIO_DELTA_MAX = 17,    /* int */
	CTL_P1003_1B_DELAYTIMER_MAX = 18,        /* int */
	CTL_P1003_1B_MQ_OPEN_MAX = 19,           /* int */
	CTL_P1003_1B_PAGESIZE = 20,              /* int */
	CTL_P1003_1B_RTSIG_MAX = 21,             /* int */
	CTL_P1003_1B_SEM_NSEMS_MAX = 22,         /* int */
	CTL_P1003_1B_SEM_VALUE_MAX = 23,         /* int */
	CTL_P1003_1B_SIGQUEUE_MAX = 24,          /* int */
	CTL_P1003_1B_TIMER_MAX = 25,             /* int */
}

//
// #include <net/route.h>
//

// struct rt_metrics
Route_Metrics :: struct {
	locks:    c.ulong,    /* Kernel must leave these values alone */
	mtu:      c.ulong,    /* MTU for this path */
	hopcount: c.ulong,    /* max hops expected */
	expire:   c.ulong,    /* lifetime for route, e.g. redirect */
	recvpipe: c.ulong,    /* inbound delay-bandwidth product */
	sendpipe: c.ulong,    /* outbound delay-bandwidth product */
	ssthresh: c.ulong,    /* outbound gateway buffer limit */
	rtt:      c.ulong,    /* estimated round trip time */
	rttvar:   c.ulong,    /* estimated rtt variance */
	pksent:   c.ulong,    /* packets sent using this route */
	weight:   c.ulong,    /* route weight */
	nhidx:    c.ulong,    /* route nexhop index */
	filler:   [2]c.ulong, /* will be used for T/TCP later */
}

// struct rt_msghdr
Route_Message_Header :: struct {
	msglen:  c.ushort,           /* to skip over non-understood messages */
	version: c.uchar,            /* future binary compatibility */
	type:    Route_Message_Type, /* message type */
	index:   c.ushort,           /* index for associated ifp */
	_spare1: c.ushort,
	flags:   c.int,              /* flags, incl. kern & message, e.g. DONE */
	addrs:   c.int,              /* bitmask identifying sockaddrs in msg */
	pid:     pid_t,              /* identify sender */
	seq:     c.int,              /* for sender to identify action */
	errno:   c.int,              /* why failed */
	fmask:   c.int,              /* bitmask used in RTM_CHANGE message */
	inits:   c.ulong,            /* which metrics we are initializing */
	rmx:     Route_Metrics,      /* metrics themselves */
}

RTM_VERSION :: 5 /* Up the ante and ignore older versions */

/*
 * Message types.
 *
 * The format for each message is annotated below using the following
 * identifiers:
 *
 * (1) struct rt_msghdr
 * (2) struct ifa_msghdr
 * (3) struct if_msghdr
 * (4) struct ifma_msghdr
 * (5) struct if_announcemsghdr
 *
 */
// #define RTM_*
Route_Message_Type :: enum c.uchar {
	ADD        = 0x1,  /* (1) Add Route */
	DELETE     = 0x2,  /* (1) Delete Route */
	CHANGE     = 0x3,  /* (1) Change Metrics or flags */
	GET        = 0x4,  /* (1) Report Metrics */
	LOSING     = 0x5,  /* (1) Kernel Suspects Partitioning */
	REDIRECT   = 0x6,  /* (1) Told to use different route */
	MISS       = 0x7,  /* (1) Lookup failed on this address */
	LOCK       = 0x8,  /* (1) fix specified metrics */
	        /* = 0x9  */
	        /* = 0xa  */
	RESOLVE    = 0xb,  /* (1) req to resolve dst to LL addr */
	NEWADDR    = 0xc,  /* (2) address being added to iface */
	DELADDR    = 0xd,  /* (2) address being removed from iface */
	IFINFO     = 0xe,  /* (3) iface going up/down etc. */
	NEWMADDR   = 0xf,  /* (4) mcast group membership being added to if */
	DELMADDR   = 0x10, /* (4) mcast group membership being deleted */
	IFANNOUNCE = 0x11, /* (5) iface arrival/departure */
	IEEE80211  = 0x12, /* (5) IEEE80211 wireless event */
}

/*
 * Bitmask values for rtm_addrs.
 */
// #define RTA_*
Route_Address_Flag :: enum c.int {
	DST     = 0x1,  /* destination sockaddr present */
	GATEWAY = 0x2,  /* gateway sockaddr present */
	NETMASK = 0x4,  /* netmask sockaddr present */
	GENMASK = 0x8,  /* cloning mask sockaddr present */
	IFP     = 0x10, /* interface name sockaddr present */
	IFA     = 0x20, /* interface addr sockaddr present */
	AUTHOR  = 0x40, /* sockaddr for author of redirect */
	BRD     = 0x80, /* for NEWADDR, broadcast or p-p dest addr */
}

/*
 * Index offsets for sockaddr array for alternate internal encoding.
 */
// #define RTAX_*
Route_Address_Index :: enum c.int {
	DST     = 0, /* destination sockaddr present */
	GATEWAY = 1, /* gateway sockaddr present */
	NETMASK = 2, /* netmask sockaddr present */
	GENMASK = 3, /* cloning mask sockaddr present */
	IFP     = 4, /* interface name sockaddr present */
	IFA     = 5, /* interface addr sockaddr present */
	AUTHOR  = 6, /* sockaddr for author of redirect */
	BRD     = 7, /* for NEWADDR, broadcast or p-p dest addr */
	MAX     = 8, /* size of array to allocate */
}

// The value stored in rtm_addrs and similar (ifm_addrs, etc.)
Route_Address_Flags :: bit_set[Route_Address_Index; c.int]

//
// #include <net/if.h>
//

/*
 * Values for if_link_state.
 */
// #define LINK_STATE_*
Link_State :: enum u8 {
	UNKNOWN = 0, /* link invalid/unknown */
	DOWN    = 1, /* link is down */
	UP      = 2, /* link is up */
}

/*
 * Structure describing information about an interface
 * which may be of interest to management entities.
 */
// struct if_data
Interface_Data :: struct {
	/* generic interface information */
	type:       u8,         /* ethernet, tokenring, etc */
	physical:   u8,         /* e.g., AUI, Thinnet, 10base-T, etc */
	addrlen:    u8,         /* media address length */
	hdrlen:     u8,         /* media header length */
	link_state: Link_State, /* current link state */
	vhid:       u8,         /* carp vhid */
	datalen:    u16,        /* length of this data struct */
	mtu:        u32,        /* maximum transmission unit */
	metric:     u32,        /* routing metric (external only) */
	baudrate:   u64,        /* linespeed */
	/* volatile statistics */
	ipackets:   u64,        /* packets received on interface */
	ierrors:    u64,        /* input errors on interface */
	opackets:   u64,        /* packets sent on interface */
	oerrors:    u64,        /* output errors on interface */
	collisions: u64,        /* collisions on csma interfaces */
	ibytes:     u64,        /* total number of octets received */
	obytes:     u64,        /* total number of octets sent */
	imcasts:    u64,        /* packets received via multicast */
	omcasts:    u64,        /* packets sent via multicast */
	iqdrops:    u64,        /* dropped on input */
	oqdrops:    u64,        /* dropped on output */
	noproto:    u64,        /* destined for unsupported protocol */
	hwassist:   u64,        /* HW offload capabilities, see IFCAP */

	/* Unions are here to make sizes MI. */
	_epoch: struct #raw_union { /* uptime at attach or stat reset */
		tt: time_t,
		ph: u64,
	},

	_lastchange: struct #raw_union { /* time of last administrative change */
		tv: timeval,
		ph: struct {
			ph1: u64,
			ph2: u64,
		},
	},
}

/*
 * The 'l' version shall be used by new interfaces, like NET_RT_IFLISTL.  It is
 * extensible after ifm_data_off or within ifm_data.  Both the if_msghdr and
 * if_data now have a member field detailing the struct length in addition to
 * the routing message length.  Macros are provided to find the start of
 * ifm_data and the start of the socket address strucutres immediately following
 * struct if_msghdrl given a pointer to struct if_msghdrl.
 */
// struct if_msghdrl
Interface_Message_Header_Len :: struct {
	msglen:   c.ushort,            /* to skip over non-understood messages */
	version:  c.uchar,             /* future binary compatibility */
	type:     c.uchar,             /* message type */
	addrs:    Route_Address_Flags, /* like rtm_addrs */
	flags:    c.int,               /* value of if_flags */
	index:    c.ushort,            /* index for associated ifp */
	_spare1:  c.ushort,            /* spare space to grow if_index, see if_var.h */
	len:      c.ushort,            /* length of if_msghdrl incl. if_data */
	data_off: c.ushort,            /* offset of if_data from beginning */
	_spare2:  c.int,
	data:     Interface_Data,      /* statistics and other data about if */
}

/*
 * The 'l' version shall be used by new interfaces, like NET_RT_IFLISTL.  It is
 * extensible after ifam_metric or within ifam_data.  Both the ifa_msghdrl and
 * if_data now have a member field detailing the struct length in addition to
 * the routing message length.  Macros are provided to find the start of
 * ifm_data and the start of the socket address strucutres immediately following
 * struct ifa_msghdrl given a pointer to struct ifa_msghdrl.
 */
// struct ifa_msghdrl
Interface_Address_Message_Header_Len :: struct {
	msglen:   c.ushort,            /* to skip over non-understood messages */
	version:  c.uchar,             /* future binary compatibility */
	type:     c.uchar,             /* message type */
	addrs:    Route_Address_Flags, /* like rtm_addrs */
	flags:    c.int,               /* value of ifa_flags */
	index:    c.ushort,            /* index for associated ifp */
	_spare1:  c.ushort,            /* spare space to grow if_index, see if_var.h */
	len:      c.ushort,            /* length of ifa_msghdrl incl. if_data */
	data_off: c.ushort,            /* offset of if_data from beginning */
	metric:   c.int,               /* value of ifa_ifp->if_metric */
	data:     Interface_Data,      /* statistics and other data about if or address */
}

//
// #include <net/if_types.h>
//

// enum ifType
Interface_Type :: enum c.uchar {
	OTHER                         = 0x1,  /* none of the following */
	ARPA_1822                     = 0x2,  /* old-style arpanet imp */
	HDH1822                       = 0x3,  /* HDH arpanet imp */
	X25DDN                        = 0x4,  /* x25 to imp */
	X25                           = 0x5,  /* PDN X25 interface (RFC877) */
	ETHER                         = 0x6,  /* Ethernet CSMA/CD */
	ISO88023                      = 0x7,  /* CMSA/CD */
	ISO88024                      = 0x8,  /* Token Bus */
	ISO88025                      = 0x9,  /* Token Ring */
	ISO88026                      = 0xa,  /* MAN */
	STARLAN                       = 0xb,
	P10                           = 0xc,  /* Proteon 10MBit ring */
	P80                           = 0xd,  /* Proteon 80MBit ring */
	HY                            = 0xe,  /* Hyperchannel */
	FDDI                          = 0xf,
	LAPB                          = 0x10,
	SDLC                          = 0x11,
	T1                            = 0x12,
	CEPT                          = 0x13, /* E1 - european T1 */
	ISDNBASIC                     = 0x14,
	ISDNPRIMARY                   = 0x15,
	PTPSERIAL                     = 0x16, /* Proprietary PTP serial */
	PPP                           = 0x17, /* RFC 1331 */
	LOOP                          = 0x18, /* loopback */
	EON                           = 0x19, /* ISO over IP */
	XETHER                        = 0x1a, /* obsolete 3MB experimental ethernet */
	NSIP                          = 0x1b, /* XNS over IP */
	SLIP                          = 0x1c, /* IP over generic TTY */
	ULTRA                         = 0x1d, /* Ultra Technologies */
	DS3                           = 0x1e, /* Generic T3 */
	SIP                           = 0x1f, /* SMDS */
	FRELAY                        = 0x20, /* Frame Relay DTE only */
	RS232                         = 0x21,
	PARA                          = 0x22, /* parallel-port */
	ARCNET                        = 0x23,
	ARCNETPLUS                    = 0x24,
	ATM                           = 0x25, /* ATM cells */
	MIOX25                        = 0x26,
	SONET                         = 0x27, /* SONET or SDH */
	X25PLE                        = 0x28,
	ISO88022LLC                   = 0x29,
	LOCALTALK                     = 0x2a,
	SMDSDXI                       = 0x2b,
	FRELAYDCE                     = 0x2c, /* Frame Relay DCE */
	V35                           = 0x2d,
	HSSI                          = 0x2e,
	HIPPI                         = 0x2f,
	MODEM                         = 0x30, /* Generic Modem */
	AAL5                          = 0x31, /* AAL5 over ATM */
	SONETPATH                     = 0x32,
	SONETVT                       = 0x33,
	SMDSICIP                      = 0x34, /* SMDS InterCarrier Interface */
	PROPVIRTUAL                   = 0x35, /* Proprietary Virtual/internal */
	PROPMUX                       = 0x36, /* Proprietary Multiplexing */
	IEEE80212                     = 0x37, /* 100BaseVG */
	FIBRECHANNEL                  = 0x38, /* Fibre Channel */
	HIPPIINTERFACE                = 0x39, /* HIPPI interfaces	 */
	FRAMERELAYINTERCONNECT        = 0x3a, /* Obsolete, use 0x20 either 0x2c */
	AFLANE8023                    = 0x3b, /* ATM Emulated LAN for 802.3 */
	AFLANE8025                    = 0x3c, /* ATM Emulated LAN for 802.5 */
	CCTEMUL                       = 0x3d, /* ATM Emulated circuit		  */
	FASTETHER                     = 0x3e, /* Fast Ethernet (100BaseT) */
	ISDN                          = 0x3f, /* ISDN and X.25	    */
	V11                           = 0x40, /* CCITT V.11/X.21		*/
	V36                           = 0x41, /* CCITT V.36			*/
	G703AT64K                     = 0x42, /* CCITT G703 at 64Kbps */
	G703AT2MB                     = 0x43, /* Obsolete see DS1-MIB */
	QLLC                          = 0x44, /* SNA QLLC			*/
	FASTETHERFX                   = 0x45, /* Fast Ethernet (100BaseFX)	*/
	CHANNEL                       = 0x46, /* channel			*/
	IEEE80211                     = 0x47, /* radio spread spectrum (unused) */
	IBM370PARCHAN                 = 0x48, /* IBM System 360/370 OEMI Channel */
	ESCON                         = 0x49, /* IBM Enterprise Systems Connection */
	DLSW                          = 0x4a, /* Data Link Switching */
	ISDNS                         = 0x4b, /* ISDN S/T interface */
	ISDNU                         = 0x4c, /* ISDN U interface */
	LAPD                          = 0x4d, /* Link Access Protocol D */
	IPSWITCH                      = 0x4e, /* IP Switching Objects */
	RSRB                          = 0x4f, /* Remote Source Route Bridging */
	ATMLOGICAL                    = 0x50, /* ATM Logical Port */
	DS0                           = 0x51, /* Digital Signal Level 0 */
	DS0BUNDLE                     = 0x52, /* group of ds0s on the same ds1 */
	BSC                           = 0x53, /* Bisynchronous Protocol */
	ASYNC                         = 0x54, /* Asynchronous Protocol */
	CNR                           = 0x55, /* Combat Net Radio */
	ISO88025DTR                   = 0x56, /* ISO 802.5r DTR */
	EPLRS                         = 0x57, /* Ext Pos Loc Report Sys */
	ARAP                          = 0x58, /* Appletalk Remote Access Protocol */
	PROPCNLS                      = 0x59, /* Proprietary Connectionless Protocol*/
	HOSTPAD                       = 0x5a, /* CCITT-ITU X.29 PAD Protocol */
	TERMPAD                       = 0x5b, /* CCITT-ITU X.3 PAD Facility */
	FRAMERELAYMPI                 = 0x5c, /* Multiproto Interconnect over FR */
	X213                          = 0x5d, /* CCITT-ITU X213 */
	ADSL                          = 0x5e, /* Asymmetric Digital Subscriber Loop */
	RADSL                         = 0x5f, /* Rate-Adapt. Digital Subscriber Loop*/
	SDSL                          = 0x60, /* Symmetric Digital Subscriber Loop */
	VDSL                          = 0x61, /* Very H-Speed Digital Subscrib. Loop*/
	ISO88025CRFPINT               = 0x62, /* ISO 802.5 CRFP */
	MYRINET                       = 0x63, /* Myricom Myrinet */
	VOICEEM                       = 0x64, /* voice recEive and transMit */
	VOICEFXO                      = 0x65, /* voice Foreign Exchange Office */
	VOICEFXS                      = 0x66, /* voice Foreign Exchange Station */
	VOICEENCAP                    = 0x67, /* voice encapsulation */
	VOICEOVERIP                   = 0x68, /* voice over IP encapsulation */
	ATMDXI                        = 0x69, /* ATM DXI */
	ATMFUNI                       = 0x6a, /* ATM FUNI */
	ATMIMA                        = 0x6b, /* ATM IMA		      */
	PPPMULTILINKBUNDLE            = 0x6c, /* PPP Multilink Bundle */
	IPOVERCDLC                    = 0x6d, /* IBM ipOverCdlc */
	IPOVERCLAW                    = 0x6e, /* IBM Common Link Access to Workstn */
	STACKTOSTACK                  = 0x6f, /* IBM stackToStack */
	VIRTUALIPADDRESS              = 0x70, /* IBM VIPA */
	MPC                           = 0x71, /* IBM multi-protocol channel support */
	IPOVERATM                     = 0x72, /* IBM ipOverAtm */
	ISO88025FIBER                 = 0x73, /* ISO 802.5j Fiber Token Ring */
	TDLC                          = 0x74, /* IBM twinaxial data link control */
	GIGABITETHERNET               = 0x75, /* Gigabit Ethernet */
	HDLC                          = 0x76, /* HDLC */
	LAPF                          = 0x77, /* LAP F */
	V37                           = 0x78, /* V.37 */
	X25MLP                        = 0x79, /* Multi-Link Protocol */
	X25HUNTGROUP                  = 0x7a, /* X25 Hunt Group */
	TRANSPHDLC                    = 0x7b, /* Transp HDLC */
	INTERLEAVE                    = 0x7c, /* Interleave channel */
	FAST                          = 0x7d, /* Fast channel */
	IP                            = 0x7e, /* IP (for APPN HPR in IP networks) */
	DOCSCABLEMACLAYER             = 0x7f, /* CATV Mac Layer */
	DOCSCABLEDOWNSTREAM           = 0x80, /* CATV Downstream interface */
	DOCSCABLEUPSTREAM             = 0x81, /* CATV Upstream interface */
	A12MPPSWITCH                  = 0x82, /* Avalon Parallel Processor */
	TUNNEL                        = 0x83, /* Encapsulation interface */
	COFFEE                        = 0x84, /* coffee pot */
	CES                           = 0x85, /* Circiut Emulation Service */
	ATMSUBINTERFACE               = 0x86, /* (x)  ATM Sub Interface */
	L2VLAN                        = 0x87, /* Layer 2 Virtual LAN using 802.1Q */
	L3IPVLAN                      = 0x88, /* Layer 3 Virtual LAN - IP Protocol */
	L3IPXVLAN                     = 0x89, /* Layer 3 Virtual LAN - IPX Prot. */
	DIGITALPOWERLINE              = 0x8a, /* IP over Power Lines */
	MEDIAMAILOVERIP               = 0x8b, /* (xxx)  Multimedia Mail over IP */
	DTM                           = 0x8c, /* Dynamic synchronous Transfer Mode */
	DCN                           = 0x8d, /* Data Communications Network */
	IPFORWARD                     = 0x8e, /* IP Forwarding Interface */
	MSDSL                         = 0x8f, /* Multi-rate Symmetric DSL */
	IEEE1394                      = 0x90, /* IEEE1394 High Performance SerialBus*/
	IFGSN                         = 0x91, /* HIPPI-6400 */
	DVBRCCMACLAYER                = 0x92, /* DVB-RCC MAC Layer */
	DVBRCCDOWNSTREAM              = 0x93, /* DVB-RCC Downstream Channel */
	DVBRCCUPSTREAM                = 0x94, /* DVB-RCC Upstream Channel */
	ATMVIRTUAL                    = 0x95, /* ATM Virtual Interface */
	MPLSTUNNEL                    = 0x96, /* MPLS Tunnel Virtual Interface */
	SRP                           = 0x97, /* Spatial Reuse Protocol */
	VOICEOVERATM                  = 0x98, /* Voice over ATM */
	VOICEOVERFRAMERELAY           = 0x99, /* Voice Over Frame Relay */
	IDSL                          = 0x9a, /* Digital Subscriber Loop over ISDN */
	COMPOSITELINK                 = 0x9b, /* Avici Composite Link Interface */
	SS7SIGLINK                    = 0x9c, /* SS7 Signaling Link */
	PROPWIRELESSP2P               = 0x9d, /* Prop. P2P wireless interface */
	FRFORWARD                     = 0x9e, /* Frame forward Interface */
	RFC1483                       = 0x9f, /* Multiprotocol over ATM AAL5 */
	USB                           = 0xa0, /* USB Interface */
	IEEE8023ADLAG                 = 0xa1, /* IEEE 802.3ad Link Aggregate*/
	BGPPOLICYACCOUNTING           = 0xa2, /* BGP Policy Accounting */
	FRF16MFRBUNDLE                = 0xa3, /* FRF.16 Multilink Frame Relay*/
	H323GATEKEEPER                = 0xa4, /* H323 Gatekeeper */
	H323PROXY                     = 0xa5, /* H323 Voice and Video Proxy */
	MPLS                          = 0xa6, /* MPLS */
	MFSIGLINK                     = 0xa7, /* Multi-frequency signaling link */
	HDSL2                         = 0xa8, /* High Bit-Rate DSL, 2nd gen. */
	SHDSL                         = 0xa9, /* Multirate HDSL2 */
	DS1FDL                        = 0xaa, /* Facility Data Link (4Kbps) on a DS1*/
	POS                           = 0xab, /* Packet over SONET/SDH Interface */
	DVBASILN                      = 0xac, /* DVB-ASI Input */
	DVBASIOUT                     = 0xad, /* DVB-ASI Output */
	PLC                           = 0xae, /* Power Line Communications */
	NFAS                          = 0xaf, /* Non-Facility Associated Signaling */
	TR008                         = 0xb0, /* TROO8 */
	GR303RDT                      = 0xb1, /* Remote Digital Terminal */
	GR303IDT                      = 0xb2, /* Integrated Digital Terminal */
	ISUP                          = 0xb3, /* ISUP */
	PROPDOCSWIRELESSMACLAYER      = 0xb4, /* prop/Wireless MAC Layer */
	PROPDOCSWIRELESSDOWNSTREAM    = 0xb5, /* prop/Wireless Downstream */
	PROPDOCSWIRELESSUPSTREAM      = 0xb6, /* prop/Wireless Upstream */
	HIPERLAN2                     = 0xb7, /* HIPERLAN Type 2 Radio Interface */
	PROPBWAP2MP                   = 0xb8, /* PropBroadbandWirelessAccess P2MP*/
	SONETOVERHEADCHANNEL          = 0xb9, /* SONET Overhead Channel */
	DIGITALWRAPPEROVERHEADCHANNEL = 0xba, /* Digital Wrapper Overhead */
	AAL2                          = 0xbb, /* ATM adaptation layer 2 */
	RADIOMAC                      = 0xbc, /* MAC layer over radio links */
	ATMRADIO                      = 0xbd, /* ATM over radio links */
	IMT                           = 0xbe, /* Inter-Machine Trunks */
	MVL                           = 0xbf, /* Multiple Virtual Lines DSL */
	REACHDSL                      = 0xc0, /* Long Reach DSL */
	FRDLCIENDPT                   = 0xc1, /* Frame Relay DLCI End Point */
	ATMVCIENDPT                   = 0xc2, /* ATM VCI End Point */
	OPTICALCHANNEL                = 0xc3, /* Optical Channel */
	OPTICALTRANSPORT              = 0xc4, /* Optical Transport */
	INFINIBAND                    = 0xc7, /* Infiniband */
	INFINIBANDLAG                 = 0xc8, /* Infiniband Link Aggregate */
	BRIDGE                        = 0xd1, /* Transparent bridge interface */
	STF                           = 0xd7, /* 6to4 interface */

	/*
	 * Not based on IANA assignments.  Conflicting with IANA assignments.
	 * We should make them negative probably.
	 * This requires changes to struct if_data.
	 */
	GIF                           = 0xf0, /* Generic tunnel interface */
	PVC                           = 0xf1, /* Unused */
	ENC                           = 0xf4, /* Encapsulating interface */
	PFLOG                         = 0xf6, /* PF packet filter logging */
	PFSYNC                        = 0xf7, /* PF packet filter synchronization */
	WIREGUARD                     = 0xf8, /* WireGuard tunnel */
}

//
// #include <net/if_dl.h>
//

/*
 * Structure of a Link-Level sockaddr:
 */
// struct sockaddr_dl
Socket_Address_Data_Link :: struct {
	using _: Socket_Address_Header,
	index:  c.ushort,       /* if != 0, system given index for interface */
	type:   Interface_Type, /* interface type */
	nlen:   c.uchar,        /* interface name length, no trailing 0 reqd. */
	alen:   c.uchar,        /* link level address length */
	slen:   c.uchar,        /* link layer selector length */
	data:   [46]c.char,     /* minimum work area, can be larger; contains both if name and ll address */
}

//
// #include <netinet/in.h>
//

in_addr_t :: distinct u32be

/* Internet address (a structure for historical reasons). */
// struct in_addr
IP4_Address :: struct #raw_union {
	// NOTE(Feoramund): I have modified this struct from its C definition by
	// introducing the byte variant to make it easier to work with.
	addr8: [4]u8,
	addr32: in_addr_t,
}

/* Socket address, internet style. */
// struct sockaddr_in
Socket_Address_Internet :: struct #packed {
	using _: Socket_Address_Header,
	port:    in_port_t,
	addr:    IP4_Address,
	zero:    [8]c.char,
}

//
// #include <netinet6/in6.h>
//

/*
 * IPv6 address
 */
// struct in6_addr
IP6_Address :: struct #raw_union {
	addr8:  [16]u8,
	addr16: [8]u16be,
	addr32: [4]u32be,
}

/*
 * Socket address for IPv6
 */
// struct sockaddr_in6
Socket_Address_Internet6 :: struct #packed {
	using _:  Socket_Address_Header,
	port:     in_port_t,           /* Transport layer port # */
	flowinfo: u32,                 /* IP6 flow information */
	addr:     IP6_Address,         /* IP6 address */
	scope_id: u32,                 /* scope zone index */
}

//
// #include <sys/umtx.h>
//

/* op code for _umtx_op */
// #define UMTX_OP_*
Userland_Mutex_Operation :: enum c.int {
	LOCK              = 0,  /* COMPAT10 */
	UNLOCK            = 1,  /* COMPAT10 */
	WAIT              = 2,
	WAKE              = 3,
	MUTEX_TRYLOCK     = 4,
	MUTEX_LOCK        = 5,
	MUTEX_UNLOCK      = 6,
	SET_CEILING       = 7,
	CV_WAIT           = 8,
	CV_SIGNAL         = 9,
	CV_BROADCAST      = 10,
	WAIT_UINT         = 11,
	RW_RDLOCK         = 12,
	RW_WRLOCK         = 13,
	RW_UNLOCK         = 14,
	WAIT_UINT_PRIVATE = 15,
	WAKE_PRIVATE      = 16,
	MUTEX_WAIT        = 17,
	MUTEX_WAKE        = 18, /* deprecated */
	SEM_WAIT          = 19, /* deprecated */
	SEM_WAKE          = 20, /* deprecated */
	NWAKE_PRIVATE     = 21,
	MUTEX_WAKE2       = 22,
	SEM2_WAIT         = 23,
	SEM2_WAKE         = 24,
	SHM               = 25,
	ROBUST_LISTS      = 26,
	GET_MIN_TIMEOUT   = 27,
	SET_MIN_TIMEOUT   = 28,
}
