#+build linux, darwin, netbsd, openbsd, freebsd
package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// termios.h - define values for termios

foreign lib {
	/*
	Get the input baud rate.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/cfgetispeed.html ]]
	*/
	cfgetispeed :: proc(termios_p: ^termios) -> speed_t ---

	/*
	Set the input baud rate.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/cfsetispeed.html ]]
	*/
	cfsetispeed :: proc(termios_p: ^termios, rate: speed_t) -> result ---

	/*
	Get the output baud rate.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/cfgetospeed.html ]]
	*/
	cfgetospeed :: proc(termios_p: ^termios) -> speed_t ---

	/*
	Set the output baud rate.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/cfsetospeed.html ]]
	*/
	cfsetospeed :: proc(termios_p: ^termios, rate: speed_t) -> result ---

	/*
	Wait for transmission of output.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcdrain.html ]]
	*/
	tcdrain :: proc(fildes: FD) -> result ---

	/*
	Suspend or restart the transmission or reception of data.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcflow.html ]]
	*/
	tcflow :: proc(fildes: FD, action: TC_Action) -> result ---

	/*
	Flush non-transmitted output data, non-read input data, or both.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcflush.html ]]
	*/
	tcflush :: proc(fildes: FD, queue_selector: TC_Queue) -> result ---

	/*
	Get the parameters associated with the terminal.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcgetattr.html ]]
	*/
	tcgetattr :: proc(fildes: FD, termios_p: ^termios) -> result ---

	/*
	Get the process group ID for the session leader for the controlling terminal.

	Returns: -1 (setting errno) on failure, the pid otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcgetsid.html ]]
	*/
	tcgetsid :: proc(fildes: FD) -> pid_t ---

	/*
	Send a break for a specific duration.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcsendbreak.html ]]
	*/
	tcsendbreak :: proc(fildes: FD, duration: c.int) -> result ---

	/*
	Set the parameters associated with the terminal.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcsetattr.html ]]
	*/
	tcsetattr :: proc(fildes: FD, optional_actions: TC_Optional_Action, termios_p: ^termios) -> result ---
}

Control_Char :: enum c.int {
	VEOF   = VEOF,
	VEOL   = VEOL,
	VERASE = VERASE,
	VINTR  = VINTR,
	VKILL  = VKILL,
	VMIN   = VMIN,
	VQUIT  = VQUIT,
	VSTART = VSTART,
	VSTOP  = VSTOP,
	VSUSP  = VSUSP,
	VTIME  = VTIME,

	NCCS   = NCCS-1,
}
#assert(len(#sparse [Control_Char]cc_t) == NCCS)

CInput_Flag_Bits :: enum tcflag_t {
	IGNBRK = log2(IGNBRK), /* ignore BREAK condition */
	BRKINT = log2(BRKINT), /* map BREAK to SIGINTR */
	IGNPAR = log2(IGNPAR), /* ignore (discard) parity errors */
	PARMRK = log2(PARMRK), /* mark parity and framing errors */
	INPCK  = log2(INPCK),  /* enable checking of parity errors */
	ISTRIP = log2(ISTRIP), /* strip 8th bit off chars */
	INLCR  = log2(INLCR),  /* map NL into CR */
	IGNCR  = log2(IGNCR),  /* ignore CR */
	ICRNL  = log2(ICRNL),  /* map CR to NL (ala CRMOD) */
	IXON   = log2(IXON),   /* enable output flow control */
	IXOFF  = log2(IXOFF),  /* enable input flow control */
	IXANY  = log2(IXANY),  /* any char will restart after stop */
}
CInput_Flags :: bit_set[CInput_Flag_Bits; tcflag_t]

CLocal_Flag_Bits :: enum tcflag_t {
	ECHO   = log2(ECHO),   /* visual erase for line kill */
	ECHOE  = log2(ECHOE),  /* visually erase chars */
	ECHOK  = log2(ECHOK),  /* echo NL after line kill */
	ECHONL = log2(ECHONL), /* echo NL even if ECHO is off */
	ICANON = log2(ICANON), /* canonicalize input lines */
	IEXTEN = log2(IEXTEN), /* enable DISCARD and LNEXT */
	ISIG   = log2(ISIG),   /* enable signals INTR, QUIT, [D]SUSP */
	NOFLSH = log2(NOFLSH), /* don't flush after interrupt */
	TOSTOP = log2(TOSTOP), /* stop background jobs from output */
}
CLocal_Flags :: bit_set[CLocal_Flag_Bits; tcflag_t]

CControl_Flag_Bits :: enum tcflag_t {
	// CS5    = log2(CS5), /* 5 bits (pseudo) (default) */
	CS6    = log2(CS6),    /* 6 bits */
	CS7    = log2(CS7),    /* 7 bits */
	CS8    = log2(CS8),    /* 8 bits */
	CSTOPB = log2(CSTOPB), /* send 2 stop bits */
	CREAD  = log2(CREAD),  /* enable receiver */
	PARENB = log2(PARENB), /* parity enable */
	PARODD = log2(PARODD), /* odd parity, else even */
	HUPCL  = log2(HUPCL),  /* hang up on last close */
	CLOCAL = log2(CLOCAL), /* ignore modem status lines */
}
CControl_Flags :: bit_set[CControl_Flag_Bits; tcflag_t]

// character size mask
CSIZE :: transmute(CControl_Flags)tcflag_t(_CSIZE)

COutput_Flag_Bits :: enum tcflag_t {
	OPOST  = log2(OPOST),  /* enable following output processing */
	ONLCR  = log2(ONLCR),  /* map NL to CR-NL (ala CRMOD) */
	OCRNL  = log2(OCRNL),  /* map CR to NL on output */
	ONOCR  = log2(ONOCR),  /* no CR output at column 0 */
	ONLRET = log2(ONLRET), /* NL performs CR function */
	OFDEL  = log2(OFDEL),  /* fill is DEL, else NUL */
	OFILL  = log2(OFILL),  /* use fill characters for delay */
	// NL0    = log2(NL0), /* \n delay 0 (default) */
	NL1    = log2(NL1),    /* \n delay 1 */
	// CR0    = log2(CR0), /* \r delay 0 (default) */
	CR1    = log2(CR1),    /* \r delay 1 */
	CR2    = log2(CR2),    /* \r delay 2 */
	CR3    = log2(CR3),    /* \r delay 3 */
	// TAB0   = log2(TAB0),/* horizontal tab delay 0 (default) */
	TAB1   = log2(TAB1),   /* horizontal tab delay 1 */
	TAB3   = log2(TAB3),   /* horizontal tab delay 3 */
	// BS0    = log2(BS0), /* \b delay 0 (default) */
	BS1    = log2(BS1),    /* \b delay 1 */
	// VT0    = log2(VT0), /* vertical tab delay 0 (default) */
	VT1    = log2(VT1),    /* vertical tab delay 1 */
	// FF0    = log2(FF0), /* form feed delay 0 (default) */
	FF1    = log2(FF1),    /* form feed delay 1 */
}
COutput_Flags :: bit_set[COutput_Flag_Bits; tcflag_t]

// \n delay mask
NLDLY  :: transmute(COutput_Flags)tcflag_t(_NLDLY)
// \r delay mask
CRDLY  :: transmute(COutput_Flags)tcflag_t(_CRDLY)
// horizontal tab delay mask
TABDLY :: transmute(COutput_Flags)tcflag_t(_TABDLY)
// \b delay mask
BSDLY  :: transmute(COutput_Flags)tcflag_t(_BSDLY)
// vertical tab delay mask
VTDLY  :: transmute(COutput_Flags)tcflag_t(_VTDLY)
// form feed delay mask
FFDLY  :: transmute(COutput_Flags)tcflag_t(_FFDLY)

speed_t :: enum _speed_t {
	B0     = B0,
	B50    = B50,
	B75    = B75,
	B110   = B110,
	B134   = B134,
	B150   = B150,
	B200   = B200,
	B300   = B300,
	B600   = B600,
	B1200  = B1200,
	B1800  = B1800,
	B2400  = B2400,
	B4800  = B4800,
	B9600  = B9600,
	B19200 = B19200,
	B38400 = B38400,
}

TC_Action :: enum c.int {
	TCIOFF = TCIOFF,
	TCION  = TCION,
	TCOOFF = TCOOFF,
	TCOON  = TCOON,
}

TC_Optional_Action :: enum c.int {
	TCSANOW,
	TCSADRAIN,
	TCSAFLUSH,
}

TC_Queue :: enum c.int {
	TCIFLUSH  = TCIFLUSH,
	TCOFLUSH  = TCOFLUSH,
	TCIOFLUSH = TCIOFLUSH,
}

when ODIN_OS == .Darwin {

	cc_t      :: distinct c.uchar
	_speed_t  :: distinct c.ulong
	tcflag_t  :: distinct c.ulong

	termios :: struct {
		c_iflag:  CInput_Flags,               /* [XBD] input flags */
		c_oflag:  COutput_Flags,              /* [XBD] output flags */
		c_cflag:  CControl_Flags,             /* [XBD] control flags */
		c_lflag:  CLocal_Flags,               /* [XBD] local flag */
		c_cc:     #sparse [Control_Char]cc_t, /* [XBD] control chars */
		c_ispeed: speed_t,                    /* input speed */
		c_ospeed: speed_t,                    /* output speed */
	}

	NCCS :: 20

	VEOF   :: 0
	VEOL   :: 1
	VERASE :: 3
	VINTR  :: 8
	VKILL  :: 5
	VMIN   :: 16
	VQUIT  :: 9
	VSTART :: 12
	VSTOP  :: 13
	VSUSP  :: 10
	VTIME  :: 17

	IGNBRK :: 0x00000001
	BRKINT :: 0x00000002
	IGNPAR :: 0x00000004
	PARMRK :: 0x00000008
	INPCK  :: 0x00000010
	ISTRIP :: 0x00000020
	INLCR  :: 0x00000040
	IGNCR  :: 0x00000080
	ICRNL  :: 0x00000100
	IXON   :: 0x00000200
	IXOFF  :: 0x00000400
	IXANY  :: 0x00000800

	OPOST   :: 0x00000001
	ONLCR   :: 0x00000002
	OCRNL   :: 0x00000010
	ONOCR   :: 0x00000020
	ONLRET  :: 0x00000040
	OFDEL   :: 0x00020000
	OFILL   :: 0x00000080
	_NLDLY  :: 0x00000300
	NL0     :: 0x00000000
	NL1     :: 0x00000100
	_CRDLY  :: 0x00003000
	CR0     :: 0x00000000
	CR1     :: 0x00001000
	CR2     :: 0x00002000
	CR3     :: 0x00003000
	_TABDLY :: 0x00000c04
	TAB0    :: 0x00000000
	TAB1    :: 0x00000400
	TAB3    :: 0x00000800
	_BSDLY  :: 0x00008000
	BS0     :: 0x00000000
	BS1     :: 0x00008000
	_VTDLY  :: 0x00010000
	VT0     :: 0x00000000
	VT1     :: 0x00010000
	_FFDLY  :: 0x00004000
	FF0     :: 0x00000000
	FF1     :: 0x00004000

	B0     :: 0
	B50    :: 50
	B75    :: 75
	B110   :: 110
	B134   :: 134
	B150   :: 150
	B200   :: 200
	B300   :: 300
	B600   :: 600
	B1200  :: 1200
	B1800  :: 1800
	B2400  :: 2400
	B4800  :: 4800
	B9600  :: 9600
	B19200 :: 19200
	B38400 :: 38400

	_CSIZE :: 0x00000300
	CS5    :: 0x00000000
	CS6    :: 0x00000100
	CS7    :: 0x00000200
	CS8    :: 0x00000300
	CSTOPB :: 0x00000400
	CREAD  :: 0x00000800
	PARENB :: 0x00001000
	PARODD :: 0x00002000
	HUPCL  :: 0x00004000
	CLOCAL :: 0x00008000

	ECHO   :: 0x00000008
	ECHOE  :: 0x00000002
	ECHOK  :: 0x00000004
	ECHONL :: 0x00000010
	ICANON :: 0x00000100
	IEXTEN :: 0x00000400
	ISIG   :: 0x00000080
	NOFLSH :: 0x80000000
	TOSTOP :: 0x00400000

	TCIFLUSH  :: 1
	TCOFLUSH  :: 2
	TCIOFLUSH :: 3

	TCIOFF :: 3
	TCION  :: 4
	TCOOFF :: 1
	TCOON  :: 2

} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	cc_t      :: distinct c.uchar
	_speed_t  :: distinct c.uint
	tcflag_t  :: distinct c.uint

	termios :: struct {
		c_iflag:  CInput_Flags,               /* [XBD] input flags */
		c_oflag:  COutput_Flags,              /* [XBD] output flags */
		c_cflag:  CControl_Flags,             /* [XBD] control flags */
		c_lflag:  CLocal_Flags,               /* [XBD] local flag */
		c_cc:     #sparse [Control_Char]cc_t, /* [XBD] control chars */
		c_ispeed: speed_t,                    /* input speed */
		c_ospeed: speed_t,                    /* output speed */
	}

	NCCS :: 20

	VEOF   :: 0
	VEOL   :: 1
	VERASE :: 3
	VINTR  :: 8
	VKILL  :: 5
	VMIN   :: 16
	VQUIT  :: 9
	VSTART :: 12
	VSTOP  :: 13
	VSUSP  :: 10
	VTIME  :: 17

	IGNBRK :: 0x00000001
	BRKINT :: 0x00000002
	IGNPAR :: 0x00000004
	PARMRK :: 0x00000008
	INPCK  :: 0x00000010
	ISTRIP :: 0x00000020
	INLCR  :: 0x00000040
	IGNCR  :: 0x00000080
	ICRNL  :: 0x00000100
	IXON   :: 0x00000200
	IXOFF  :: 0x00000400
	IXANY  :: 0x00000800

	OPOST    :: 0x00000001
	ONLCR    :: 0x00000002
	OCRNL    :: 0x00000010
	when ODIN_OS == .OpenBSD {
		ONOCR  :: 0x00000040
		ONLRET :: 0x00000080
	} else {
		ONOCR  :: 0x00000020
		ONLRET :: 0x00000040
	}
	OFDEL   :: 0x00020000 // NOTE: not in headers
	OFILL   :: 0x00000080 // NOTE: not in headers
	_NLDLY  :: 0x00000300 // NOTE: not in headers
	NL0     :: 0x00000000 // NOTE: not in headers
	NL1     :: 0x00000100 // NOTE: not in headers
	_CRDLY  :: 0x00003000 // NOTE: not in headers
	CR0     :: 0x00000000 // NOTE: not in headers
	CR1     :: 0x00001000 // NOTE: not in headers
	CR2     :: 0x00002000 // NOTE: not in headers
	CR3     :: 0x00003000 // NOTE: not in headers
	_TABDLY :: 0x00000004 // NOTE: not in headers (netbsd)
	TAB0    :: 0x00000000 // NOTE: not in headers (netbsd)
	TAB1    :: 0x00000004 // NOTE: not in headers
	TAB3    :: 0x00000004 // NOTE: not in headers (netbsd)
	_BSDLY  :: 0x00008000 // NOTE: not in headers
	BS0     :: 0x00000000 // NOTE: not in headers
	BS1     :: 0x00008000 // NOTE: not in headers
	_VTDLY  :: 0x00010000 // NOTE: not in headers
	VT0     :: 0x00000000 // NOTE: not in headers
	VT1     :: 0x00010000 // NOTE: not in headers
	_FFDLY  :: 0x00004000 // NOTE: not in headers
	FF0     :: 0x00000000 // NOTE: not in headers
	FF1     :: 0x00004000 // NOTE: not in headers

	B0     :: 0
	B50    :: 50
	B75    :: 75
	B110   :: 110
	B134   :: 134
	B150   :: 150
	B200   :: 200
	B300   :: 300
	B600   :: 600
	B1200  :: 1200
	B1800  :: 1800
	B2400  :: 2400
	B4800  :: 4800
	B9600  :: 9600
	B19200 :: 19200
	B38400 :: 38400

	_CSIZE :: 0x00000300
	CS5    :: 0x00000000
	CS6    :: 0x00000100
	CS7    :: 0x00000200
	CS8    :: 0x00000300
	CSTOPB :: 0x00000400
	CREAD  :: 0x00000800
	PARENB :: 0x00001000
	PARODD :: 0x00002000
	HUPCL  :: 0x00004000
	CLOCAL :: 0x00008000

	ECHO   :: 0x00000008
	ECHOE  :: 0x00000002
	ECHOK  :: 0x00000004
	ECHONL :: 0x00000010
	ICANON :: 0x00000100
	IEXTEN :: 0x00000400
	ISIG   :: 0x00000080
	NOFLSH :: 0x80000000
	TOSTOP :: 0x00400000

	TCIFLUSH  :: 1
	TCOFLUSH  :: 2
	TCIOFLUSH :: 3

	TCIOFF :: 3
	TCION  :: 4
	TCOOFF :: 1
	TCOON  :: 2

} else when ODIN_OS == .Linux {
	cc_t      :: distinct c.uchar
	_speed_t  :: distinct c.uint
	tcflag_t  :: distinct c.uint

	termios :: struct {
		c_iflag:  CInput_Flags,               /* [XBD] input flags */
		c_oflag:  COutput_Flags,              /* [XBD] output flags */
		c_cflag:  CControl_Flags,             /* [XBD] control flags */
		c_lflag:  CLocal_Flags,               /* [XBD] local flag */
		c_line:   cc_t,                       /* control characters */
		c_cc:     #sparse [Control_Char]cc_t, /* [XBD] control chars */
		c_ispeed: speed_t,                    /* input speed */
		c_ospeed: speed_t,                    /* output speed */
	}

	NCCS :: 32

	VINTR  :: 0
	VQUIT  :: 1
	VERASE :: 2
	VKILL  :: 3
	VEOF   :: 4
	VTIME  :: 5
	VMIN   :: 6
	VSTART :: 8
	VSTOP  :: 9
	VSUSP  :: 10
	VEOL   :: 11

	IGNBRK :: 0x00000001
	BRKINT :: 0x00000002
	IGNPAR :: 0x00000004
	PARMRK :: 0x00000008
	INPCK  :: 0x00000010
	ISTRIP :: 0x00000020
	INLCR  :: 0x00000040
	IGNCR  :: 0x00000080
	ICRNL  :: 0x00000100
	IXON   :: 0x00000400
	IXOFF  :: 0x00001000
	IXANY  :: 0x00000800

	OPOST   :: 0x00000001
	ONLCR   :: 0x00000004
	OCRNL   :: 0x00000008
	ONOCR   :: 0x00000010
	ONLRET  :: 0x00000020
	OFDEL   :: 0x00000080
	OFILL   :: 0x00000040
	_NLDLY  :: 0x00000100
	NL0     :: 0x00000000
	NL1     :: 0x00000100
	_CRDLY  :: 0x00000600
	CR0     :: 0x00000000
	CR1     :: 0x00000200
	CR2     :: 0x00000400
	CR3     :: 0x00000600
	_TABDLY :: 0x00001800
	TAB0    :: 0x00000000
	TAB1    :: 0x00000800
	TAB3    :: 0x00001800
	_BSDLY  :: 0x00002000
	BS0     :: 0x00000000
	BS1     :: 0x00002000
	_VTDLY  :: 0x00004000
	VT0     :: 0x00000000
	VT1     :: 0x00004000
	_FFDLY  :: 0x00008000
	FF0     :: 0x00000000
	FF1     :: 0x00008000

	B0     :: 0x00000000
	B50    :: 0x00000001
	B75    :: 0x00000002
	B110   :: 0x00000003
	B134   :: 0x00000004
	B150   :: 0x00000005
	B200   :: 0x00000006
	B300   :: 0x00000007
	B600   :: 0x00000008
	B1200  :: 0x00000009
	B1800  :: 0x0000000a
	B2400  :: 0x0000000b
	B4800  :: 0x0000000c
	B9600  :: 0x0000000d
	B19200 :: 0x0000000e
	B38400 :: 0x0000000f

	_CSIZE :: 0x00000030
	CS5    :: 0x00000000
	CS6    :: 0x00000010
	CS7    :: 0x00000020
	CS8    :: 0x00000030
	CSTOPB :: 0x00000040
	CREAD  :: 0x00000080
	PARENB :: 0x00000100
	PARODD :: 0x00000200
	HUPCL  :: 0x00000400
	CLOCAL :: 0x00000800

	ECHO   :: 0x00000008
	ECHOE  :: 0x00000010
	ECHOK  :: 0x00000020
	ECHONL :: 0x00000040
	ICANON :: 0x00000002
	IEXTEN :: 0x00008000
	ISIG   :: 0x00000001
	NOFLSH :: 0x80000080
	TOSTOP :: 0x00000100

	TCIFLUSH  :: 0
	TCOFLUSH  :: 1
	TCIOFLUSH :: 2

	TCIOFF :: 2
	TCION  :: 3
	TCOOFF :: 0
	TCOON  :: 1

}
