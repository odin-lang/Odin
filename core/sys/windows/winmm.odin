// +build windows
package sys_windows

foreign import winmm "system:Winmm.lib"

MMRESULT :: UINT

@(default_calling_convention="system")
foreign winmm {
	timeGetDevCaps  :: proc(ptc: LPTIMECAPS, cbtc: UINT) -> MMRESULT ---
	timeBeginPeriod :: proc(uPeriod: UINT) -> MMRESULT ---
	timeEndPeriod   :: proc(uPeriod: UINT) -> MMRESULT ---
	timeGetTime     :: proc() -> DWORD ---
}

LPTIMECAPS :: ^TIMECAPS
TIMECAPS :: struct {
	wPeriodMin: UINT,
	wPeriodMax: UINT,
}

// String resource number bases (internal use)
MMSYSERR_BASE :: 0
WAVERR_BASE   :: 32
MIDIERR_BASE  :: 64
TIMERR_BASE   :: 96
JOYERR_BASE   :: 160
MCIERR_BASE   :: 256
MIXERR_BASE   :: 1024

MCI_STRING_OFFSET :: 512
MCI_VD_OFFSET     :: 1024
MCI_CD_OFFSET     :: 1088
MCI_WAVE_OFFSET   :: 1152
MCI_SEQ_OFFSET    :: 1216

/* general error return values */
MMSYSERR_NOERROR      :: 0                  /* no error */
MMSYSERR_ERROR        :: MMSYSERR_BASE + 1  /* unspecified error */
MMSYSERR_BADDEVICEID  :: MMSYSERR_BASE + 2  /* device ID out of range */
MMSYSERR_NOTENABLED   :: MMSYSERR_BASE + 3  /* driver failed enable */
MMSYSERR_ALLOCATED    :: MMSYSERR_BASE + 4  /* device already allocated */
MMSYSERR_INVALHANDLE  :: MMSYSERR_BASE + 5  /* device handle is invalid */
MMSYSERR_NODRIVER     :: MMSYSERR_BASE + 6  /* no device driver present */
MMSYSERR_NOMEM        :: MMSYSERR_BASE + 7  /* memory allocation error */
MMSYSERR_NOTSUPPORTED :: MMSYSERR_BASE + 8  /* function isn't supported */
MMSYSERR_BADERRNUM    :: MMSYSERR_BASE + 9  /* error value out of range */
MMSYSERR_INVALFLAG    :: MMSYSERR_BASE + 10 /* invalid flag passed */
MMSYSERR_INVALPARAM   :: MMSYSERR_BASE + 11 /* invalid parameter passed */
MMSYSERR_HANDLEBUSY   :: MMSYSERR_BASE + 12 /* handle being used simultaneously on another thread (eg callback) */
MMSYSERR_INVALIDALIAS :: MMSYSERR_BASE + 13 /* specified alias not found */
MMSYSERR_BADDB        :: MMSYSERR_BASE + 14 /* bad registry database */
MMSYSERR_KEYNOTFOUND  :: MMSYSERR_BASE + 15 /* registry key not found */
MMSYSERR_READERROR    :: MMSYSERR_BASE + 16 /* registry read error */
MMSYSERR_WRITEERROR   :: MMSYSERR_BASE + 17 /* registry write error */
MMSYSERR_DELETEERROR  :: MMSYSERR_BASE + 18 /* registry delete error */
MMSYSERR_VALNOTFOUND  :: MMSYSERR_BASE + 19 /* registry value not found */
MMSYSERR_NODRIVERCB   :: MMSYSERR_BASE + 20 /* driver does not call DriverCallback */
MMSYSERR_MOREDATA     :: MMSYSERR_BASE + 21 /* more data to be returned */
MMSYSERR_LASTERROR    :: MMSYSERR_BASE + 21 /* last error in range */

/* waveform audio error return values */
WAVERR_BADFORMAT    :: WAVERR_BASE + 0 /* unsupported wave format */
WAVERR_STILLPLAYING :: WAVERR_BASE + 1 /* still something playing */
WAVERR_UNPREPARED   :: WAVERR_BASE + 2 /* header not prepared */
WAVERR_SYNC         :: WAVERR_BASE + 3 /* device is synchronous */
WAVERR_LASTERROR    :: WAVERR_BASE + 3 /* last error in range */

/* MIDI error return values */
MIDIERR_UNPREPARED    :: MIDIERR_BASE + 0 /* header not prepared */
MIDIERR_STILLPLAYING  :: MIDIERR_BASE + 1 /* still something playing */
MIDIERR_NOMAP         :: MIDIERR_BASE + 2 /* no configured instruments */
MIDIERR_NOTREADY      :: MIDIERR_BASE + 3 /* hardware is still busy */
MIDIERR_NODEVICE      :: MIDIERR_BASE + 4 /* port no longer connected */
MIDIERR_INVALIDSETUP  :: MIDIERR_BASE + 5 /* invalid MIF */
MIDIERR_BADOPENMODE   :: MIDIERR_BASE + 6 /* operation unsupported w/ open mode */
MIDIERR_DONT_CONTINUE :: MIDIERR_BASE + 7 /* thru device 'eating' a message */
MIDIERR_LASTERROR     :: MIDIERR_BASE + 7 /* last error in range */

/* timer error return values */
TIMERR_NOERROR :: 0                /* no error */
TIMERR_NOCANDO :: TIMERR_BASE + 1  /* request not completed */
TIMERR_STRUCT  :: TIMERR_BASE + 33 /* time struct size */

/* joystick error return values */
JOYERR_NOERROR   :: 0               /* no error */
JOYERR_PARMS     :: JOYERR_BASE + 5 /* bad parameters */
JOYERR_NOCANDO   :: JOYERR_BASE + 6 /* request not completed */
JOYERR_UNPLUGGED :: JOYERR_BASE + 7 /* joystick is unplugged */

/* MCI error return values */
MCIERR_INVALID_DEVICE_ID        :: MCIERR_BASE + 1
MCIERR_UNRECOGNIZED_KEYWORD     :: MCIERR_BASE + 3
MCIERR_UNRECOGNIZED_COMMAND     :: MCIERR_BASE + 5
MCIERR_HARDWARE                 :: MCIERR_BASE + 6
MCIERR_INVALID_DEVICE_NAME      :: MCIERR_BASE + 7
MCIERR_OUT_OF_MEMORY            :: MCIERR_BASE + 8
MCIERR_DEVICE_OPEN              :: MCIERR_BASE + 9
MCIERR_CANNOT_LOAD_DRIVER       :: MCIERR_BASE + 10
MCIERR_MISSING_COMMAND_STRING   :: MCIERR_BASE + 11
MCIERR_PARAM_OVERFLOW           :: MCIERR_BASE + 12
MCIERR_MISSING_STRING_ARGUMENT  :: MCIERR_BASE + 13
MCIERR_BAD_INTEGER              :: MCIERR_BASE + 14
MCIERR_PARSER_INTERNAL          :: MCIERR_BASE + 15
MCIERR_DRIVER_INTERNAL          :: MCIERR_BASE + 16
MCIERR_MISSING_PARAMETER        :: MCIERR_BASE + 17
MCIERR_UNSUPPORTED_FUNCTION     :: MCIERR_BASE + 18
MCIERR_FILE_NOT_FOUND           :: MCIERR_BASE + 19
MCIERR_DEVICE_NOT_READY         :: MCIERR_BASE + 20
MCIERR_INTERNAL                 :: MCIERR_BASE + 21
MCIERR_DRIVER                   :: MCIERR_BASE + 22
MCIERR_CANNOT_USE_ALL           :: MCIERR_BASE + 23
MCIERR_MULTIPLE                 :: MCIERR_BASE + 24
MCIERR_EXTENSION_NOT_FOUND      :: MCIERR_BASE + 25
MCIERR_OUTOFRANGE               :: MCIERR_BASE + 26
MCIERR_FLAGS_NOT_COMPATIBLE     :: MCIERR_BASE + 28
MCIERR_FILE_NOT_SAVED           :: MCIERR_BASE + 30
MCIERR_DEVICE_TYPE_REQUIRED     :: MCIERR_BASE + 31
MCIERR_DEVICE_LOCKED            :: MCIERR_BASE + 32
MCIERR_DUPLICATE_ALIAS          :: MCIERR_BASE + 33
MCIERR_BAD_CONSTANT             :: MCIERR_BASE + 34
MCIERR_MUST_USE_SHAREABLE       :: MCIERR_BASE + 35
MCIERR_MISSING_DEVICE_NAME      :: MCIERR_BASE + 36
MCIERR_BAD_TIME_FORMAT          :: MCIERR_BASE + 37
MCIERR_NO_CLOSING_QUOTE         :: MCIERR_BASE + 38
MCIERR_DUPLICATE_FLAGS          :: MCIERR_BASE + 39
MCIERR_INVALID_FILE             :: MCIERR_BASE + 40
MCIERR_NULL_PARAMETER_BLOCK     :: MCIERR_BASE + 41
MCIERR_UNNAMED_RESOURCE         :: MCIERR_BASE + 42
MCIERR_NEW_REQUIRES_ALIAS       :: MCIERR_BASE + 43
MCIERR_NOTIFY_ON_AUTO_OPEN      :: MCIERR_BASE + 44
MCIERR_NO_ELEMENT_ALLOWED       :: MCIERR_BASE + 45
MCIERR_NONAPPLICABLE_FUNCTION   :: MCIERR_BASE + 46
MCIERR_ILLEGAL_FOR_AUTO_OPEN    :: MCIERR_BASE + 47
MCIERR_FILENAME_REQUIRED        :: MCIERR_BASE + 48
MCIERR_EXTRA_CHARACTERS         :: MCIERR_BASE + 49
MCIERR_DEVICE_NOT_INSTALLED     :: MCIERR_BASE + 50
MCIERR_GET_CD                   :: MCIERR_BASE + 51
MCIERR_SET_CD                   :: MCIERR_BASE + 52
MCIERR_SET_DRIVE                :: MCIERR_BASE + 53
MCIERR_DEVICE_LENGTH            :: MCIERR_BASE + 54
MCIERR_DEVICE_ORD_LENGTH        :: MCIERR_BASE + 55
MCIERR_NO_INTEGER               :: MCIERR_BASE + 56
MCIERR_WAVE_OUTPUTSINUSE        :: MCIERR_BASE + 64
MCIERR_WAVE_SETOUTPUTINUSE      :: MCIERR_BASE + 65
MCIERR_WAVE_INPUTSINUSE         :: MCIERR_BASE + 66
MCIERR_WAVE_SETINPUTINUSE       :: MCIERR_BASE + 67
MCIERR_WAVE_OUTPUTUNSPECIFIED   :: MCIERR_BASE + 68
MCIERR_WAVE_INPUTUNSPECIFIED    :: MCIERR_BASE + 69
MCIERR_WAVE_OUTPUTSUNSUITABLE   :: MCIERR_BASE + 70
MCIERR_WAVE_SETOUTPUTUNSUITABLE :: MCIERR_BASE + 71
MCIERR_WAVE_INPUTSUNSUITABLE    :: MCIERR_BASE + 72
MCIERR_WAVE_SETINPUTUNSUITABLE  :: MCIERR_BASE + 73
MCIERR_SEQ_DIV_INCOMPATIBLE     :: MCIERR_BASE + 80
MCIERR_SEQ_PORT_INUSE           :: MCIERR_BASE + 81
MCIERR_SEQ_PORT_NONEXISTENT     :: MCIERR_BASE + 82
MCIERR_SEQ_PORT_MAPNODEVICE     :: MCIERR_BASE + 83
MCIERR_SEQ_PORT_MISCERROR       :: MCIERR_BASE + 84
MCIERR_SEQ_TIMER                :: MCIERR_BASE + 85
MCIERR_SEQ_PORTUNSPECIFIED      :: MCIERR_BASE + 86
MCIERR_SEQ_NOMIDIPRESENT        :: MCIERR_BASE + 87
MCIERR_NO_WINDOW                :: MCIERR_BASE + 90
MCIERR_CREATEWINDOW             :: MCIERR_BASE + 91
MCIERR_FILE_READ                :: MCIERR_BASE + 92
MCIERR_FILE_WRITE               :: MCIERR_BASE + 93
MCIERR_NO_IDENTITY              :: MCIERR_BASE + 94

/*  MMRESULT error return values specific to the mixer API */
MIXERR_INVALLINE    :: (MIXERR_BASE + 0)
MIXERR_INVALCONTROL :: (MIXERR_BASE + 1)
MIXERR_INVALVALUE   :: (MIXERR_BASE + 2)
MIXERR_LASTERROR    :: (MIXERR_BASE + 2)