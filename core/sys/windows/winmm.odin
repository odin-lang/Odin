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

	waveOutGetNumDevs :: proc() -> UINT ---
	waveOutGetDevCapsW :: proc(uDeviceID: UINT_PTR, pwoc: LPWAVEOUTCAPSW, cbwoc: UINT) -> MMRESULT ---
	waveOutGetVolume :: proc(hwo: HWAVEOUT, pdwVolume: LPDWORD) -> MMRESULT ---
	waveOutSetVolume :: proc(hwo: HWAVEOUT, dwVolume: DWORD) -> MMRESULT ---
	waveOutGetErrorTextW :: proc(mmrError: MMRESULT, pszText: LPWSTR, cchText: UINT) -> MMRESULT ---
	waveOutOpen :: proc(phwo: LPHWAVEOUT, uDeviceID: UINT, pwfx: LPCWAVEFORMATEX, dwCallback: DWORD_PTR, dwInstance: DWORD_PTR, fdwOpen: DWORD) -> MMRESULT ---
	waveOutClose :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutPrepareHeader :: proc(hwo: HWAVEOUT, pwh: LPWAVEHDR, cbwh: UINT) -> MMRESULT ---
	waveOutUnprepareHeader :: proc(hwo: HWAVEOUT, pwh: LPWAVEHDR, cbwh: UINT) -> MMRESULT ---
	waveOutWrite :: proc(hwo: HWAVEOUT, pwh: LPWAVEHDR, cbwh: UINT) -> MMRESULT ---
	waveOutPause :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutRestart :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutReset :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutBreakLoop :: proc(hwo: HWAVEOUT) -> MMRESULT ---
	waveOutGetPosition :: proc(hwo: HWAVEOUT, pmmt: LPMMTIME, cbmmt: UINT) -> MMRESULT ---
	waveOutGetPitch :: proc(hwo: HWAVEOUT, pdwPitch: LPDWORD) -> MMRESULT ---
	waveOutSetPitch :: proc(hwo: HWAVEOUT, pdwPitch: DWORD) -> MMRESULT ---
	waveOutGetPlaybackRate :: proc(hwo: HWAVEOUT, pdwRate: LPDWORD) -> MMRESULT ---
	waveOutSetPlaybackRate :: proc(hwo: HWAVEOUT, pdwRate: DWORD) -> MMRESULT ---
	waveOutGetID :: proc(hwo: HWAVEOUT, puDeviceID: LPUINT) -> MMRESULT ---

	waveInGetNumDevs :: proc() -> UINT ---
	waveInGetDevCapsW :: proc(uDeviceID: UINT_PTR, pwic: LPWAVEINCAPSW, cbwic: UINT) -> MMRESULT ---

	PlaySoundW :: proc(pszSound: LPCWSTR, hmod: HMODULE, fdwSound: DWORD) -> BOOL ---
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

/* waveform output */
MM_WOM_OPEN  :: 0x3BB
MM_WOM_CLOSE :: 0x3BC
MM_WOM_DONE  :: 0x3BD
/* waveform input */
MM_WIM_OPEN  :: 0x3BE
MM_WIM_CLOSE :: 0x3BF
MM_WIM_DATA  :: 0x3C0

WOM_OPEN  :: MM_WOM_OPEN
WOM_CLOSE :: MM_WOM_CLOSE
WOM_DONE  :: MM_WOM_DONE
WIM_OPEN  :: MM_WIM_OPEN
WIM_CLOSE :: MM_WIM_CLOSE
WIM_DATA  :: MM_WIM_DATA

WAVE_MAPPER : UINT : 0xFFFFFFFF // -1

WAVE_FORMAT_QUERY                        :: 0x0001
WAVE_ALLOWSYNC                           :: 0x0002
WAVE_MAPPED                              :: 0x0004
WAVE_FORMAT_DIRECT                       :: 0x0008
WAVE_FORMAT_DIRECT_QUERY                 :: (WAVE_FORMAT_QUERY | WAVE_FORMAT_DIRECT)
WAVE_MAPPED_DEFAULT_COMMUNICATION_DEVICE :: 0x0010

WHDR_DONE      :: 0x00000001 /* done bit */
WHDR_PREPARED  :: 0x00000002 /* set if this header has been prepared */
WHDR_BEGINLOOP :: 0x00000004 /* loop start block */
WHDR_ENDLOOP   :: 0x00000008 /* loop end block */
WHDR_INQUEUE   :: 0x00000010 /* reserved for driver */

WAVECAPS_PITCH          :: 0x0001 /* supports pitch control */
WAVECAPS_PLAYBACKRATE   :: 0x0002 /* supports playback rate control */
WAVECAPS_VOLUME         :: 0x0004 /* supports volume control */
WAVECAPS_LRVOLUME       :: 0x0008 /* separate left-right volume control */
WAVECAPS_SYNC           :: 0x0010
WAVECAPS_SAMPLEACCURATE :: 0x0020

WAVE_INVALIDFORMAT :: 0x00000000 /* invalid format */
WAVE_FORMAT_1M08   :: 0x00000001 /* 11.025 kHz, Mono,   8-bit  */
WAVE_FORMAT_1S08   :: 0x00000002 /* 11.025 kHz, Stereo, 8-bit  */
WAVE_FORMAT_1M16   :: 0x00000004 /* 11.025 kHz, Mono,   16-bit */
WAVE_FORMAT_1S16   :: 0x00000008 /* 11.025 kHz, Stereo, 16-bit */
WAVE_FORMAT_2M08   :: 0x00000010 /* 22.05  kHz, Mono,   8-bit  */
WAVE_FORMAT_2S08   :: 0x00000020 /* 22.05  kHz, Stereo, 8-bit  */
WAVE_FORMAT_2M16   :: 0x00000040 /* 22.05  kHz, Mono,   16-bit */
WAVE_FORMAT_2S16   :: 0x00000080 /* 22.05  kHz, Stereo, 16-bit */
WAVE_FORMAT_4M08   :: 0x00000100 /* 44.1   kHz, Mono,   8-bit  */
WAVE_FORMAT_4S08   :: 0x00000200 /* 44.1   kHz, Stereo, 8-bit  */
WAVE_FORMAT_4M16   :: 0x00000400 /* 44.1   kHz, Mono,   16-bit */
WAVE_FORMAT_4S16   :: 0x00000800 /* 44.1   kHz, Stereo, 16-bit */
WAVE_FORMAT_44M08  :: 0x00000100 /* 44.1   kHz, Mono,   8-bit  */
WAVE_FORMAT_44S08  :: 0x00000200 /* 44.1   kHz, Stereo, 8-bit  */
WAVE_FORMAT_44M16  :: 0x00000400 /* 44.1   kHz, Mono,   16-bit */
WAVE_FORMAT_44S16  :: 0x00000800 /* 44.1   kHz, Stereo, 16-bit */
WAVE_FORMAT_48M08  :: 0x00001000 /* 48     kHz, Mono,   8-bit  */
WAVE_FORMAT_48S08  :: 0x00002000 /* 48     kHz, Stereo, 8-bit  */
WAVE_FORMAT_48M16  :: 0x00004000 /* 48     kHz, Mono,   16-bit */
WAVE_FORMAT_48S16  :: 0x00008000 /* 48     kHz, Stereo, 16-bit */
WAVE_FORMAT_96M08  :: 0x00010000 /* 96     kHz, Mono,   8-bit  */
WAVE_FORMAT_96S08  :: 0x00020000 /* 96     kHz, Stereo, 8-bit  */
WAVE_FORMAT_96M16  :: 0x00040000 /* 96     kHz, Mono,   16-bit */
WAVE_FORMAT_96S16  :: 0x00080000 /* 96     kHz, Stereo, 16-bit */

HWAVE    :: distinct HANDLE
HWAVEIN  :: distinct HANDLE
HWAVEOUT :: distinct HANDLE

LPHWAVEIN :: ^HWAVEIN
LPHWAVEOUT :: ^HWAVEOUT

// https://learn.microsoft.com/en-us/windows/win32/multimedia/multimedia-timer-structures
MMTIME :: struct {
	wType: MMTIME_TYPE,
	u: struct #raw_union {
		ms: DWORD,
		sample: DWORD,
		cb: DWORD,
		ticks: DWORD,
		smpte: struct {
			hour: BYTE,
			min: BYTE,
			sec: BYTE,
			frame: BYTE,
			fps: BYTE,
			dummy: BYTE,
			pad: [2]BYTE,
		},
		midi: struct {
			songptrpos: DWORD,
		},
	},
}
LPMMTIME :: ^MMTIME

MMTIME_TYPE :: enum UINT {
	/* time in milliseconds */
	TIME_MS      = 0x0001,
	/* number of wave samples */
	TIME_SAMPLES = 0x0002,
	/* current byte offset */
	TIME_BYTES   = 0x0004,
	/* SMPTE time */
	TIME_SMPTE   = 0x0008,
	/* MIDI time */
	TIME_MIDI    = 0x0010,
	/* Ticks within MIDI stream */
	TIME_TICKS   = 0x0020,
}

MAXPNAMELEN :: 32
MAXERRORLENGTH :: 256
MMVERSION :: UINT

/* flags for wFormatTag field of WAVEFORMAT */
WAVE_FORMAT_PCM :: 1

WAVEFORMATEX :: struct {
	wFormatTag:      WORD,
	nChannels:       WORD,
	nSamplesPerSec:  DWORD,
	nAvgBytesPerSec: DWORD,
	nBlockAlign:     WORD,
	wBitsPerSample:  WORD,
	cbSize:          WORD,
}
LPCWAVEFORMATEX :: ^WAVEFORMATEX

WAVEHDR :: struct {
	lpData:          LPSTR, /* pointer to locked data buffer */
	dwBufferLength:  DWORD, /* length of data buffer */
	dwBytesRecorded: DWORD, /* used for input only */
	dwUser:          DWORD_PTR, /* for client's use */
	dwFlags:         DWORD, /* assorted flags (see defines) */
	dwLoops:         DWORD, /* loop control counter */
	lpNext:          LPWAVEHDR, /* reserved for driver */
	reserved:        DWORD_PTR, /* reserved for driver */
}
LPWAVEHDR :: ^WAVEHDR

WAVEINCAPSW :: struct {
	wMid:           WORD, /* manufacturer ID */
	wPid:           WORD, /* product ID */
	vDriverVersion: MMVERSION, /* version of the driver */
	szPname:        [MAXPNAMELEN]WCHAR, /* product name (NULL terminated string) */
	dwFormats:      DWORD, /* formats supported */
	wChannels:      WORD, /* number of channels supported */
	wReserved1:     WORD, /* structure packing */
}
LPWAVEINCAPSW :: ^WAVEINCAPSW

WAVEOUTCAPSW :: struct {
	wMid:           WORD, /* manufacturer ID */
	wPid:           WORD, /* product ID */
	vDriverVersion: MMVERSION, /* version of the driver */
	szPname:        [MAXPNAMELEN]WCHAR, /* product name (NULL terminated string) */
	dwFormats:      DWORD, /* formats supported */
	wChannels:      WORD, /* number of sources supported */
	wReserved1:     WORD, /* packing */
	dwSupport:      DWORD, /* functionality supported by driver */
}
LPWAVEOUTCAPSW :: ^WAVEOUTCAPSW

// flag values for PlaySound
SND_SYNC		:: 0x0000  /* play synchronously (default) */
SND_ASYNC		:: 0x0001  /* play asynchronously */
SND_NODEFAULT	:: 0x0002  /* silence (!default) if sound not found */
SND_MEMORY		:: 0x0004  /* pszSound points to a memory file */
SND_LOOP		:: 0x0008  /* loop the sound until next sndPlaySound */
SND_NOSTOP		:: 0x0010  /* don't stop any currently playing sound */

SND_NOWAIT		:: 0x00002000 /* don't wait if the driver is busy */
SND_ALIAS		:: 0x00010000 /* name is a registry alias */
SND_ALIAS_ID	:: 0x00110000 /* alias is a predefined ID */
SND_FILENAME	:: 0x00020000 /* name is file name */
SND_RESOURCE	:: 0x00040004 /* name is resource name or atom */

SND_PURGE		:: 0x0040  /* purge non-static events for task */
SND_APPLICATION	:: 0x0080  /* look for application specific association */

SND_SENTRY		:: 0x00080000 /* Generate a SoundSentry event with this sound */
SND_RING		:: 0x00100000 /* Treat this as a "ring" from a communications app - don't duck me */
SND_SYSTEM		:: 0x00200000 /* Treat this as a system sound */


CALLBACK_TYPEMASK :: 0x00070000    /* callback type mask */
CALLBACK_NULL     :: 0x00000000    /* no callback */
CALLBACK_WINDOW   :: 0x00010000    /* dwCallback is a HWND */
CALLBACK_TASK     :: 0x00020000    /* dwCallback is a HTASK */
CALLBACK_FUNCTION :: 0x00030000    /* dwCallback is a FARPROC */
CALLBACK_THREAD   :: CALLBACK_TASK /* thread ID replaces 16 bit task */
CALLBACK_EVENT    :: 0x00050000    /* dwCallback is an EVENT Handle */
