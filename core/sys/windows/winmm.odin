#+build windows
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

LPHWAVEIN  :: ^HWAVEIN
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

// Input is four characters string
// Output is little-endian u32 representation
MAKEFOURCC :: #force_inline proc "contextless" (s: [4]byte) -> DWORD {
	return (DWORD(s[0])) | (DWORD(s[1]) << 8) | (DWORD(s[2]) << 16) | (DWORD(s[3]) << 24 )
}

/* flags for wFormatTag field of WAVEFORMAT */
WAVE_FORMAT_PCM :: 1

WAVE_FORMAT_UNKNOWN                    :: 0x0000 /* Microsoft Corporation */
WAVE_FORMAT_ADPCM                      :: 0x0002 /* Microsoft Corporation */
WAVE_FORMAT_IEEE_FLOAT                 :: 0x0003 /* Microsoft Corporation */
WAVE_FORMAT_VSELP                      :: 0x0004 /* Compaq Computer Corp. */
WAVE_FORMAT_IBM_CVSD                   :: 0x0005 /* IBM Corporation */
WAVE_FORMAT_ALAW                       :: 0x0006 /* Microsoft Corporation */
WAVE_FORMAT_MULAW                      :: 0x0007 /* Microsoft Corporation */
WAVE_FORMAT_DTS                        :: 0x0008 /* Microsoft Corporation */
WAVE_FORMAT_DRM                        :: 0x0009 /* Microsoft Corporation */
WAVE_FORMAT_WMAVOICE9                  :: 0x000A /* Microsoft Corporation */
WAVE_FORMAT_WMAVOICE10                 :: 0x000B /* Microsoft Corporation */
WAVE_FORMAT_OKI_ADPCM                  :: 0x0010 /* OKI */
WAVE_FORMAT_DVI_ADPCM                  :: 0x0011 /* Intel Corporation */
WAVE_FORMAT_IMA_ADPCM                  :: WAVE_FORMAT_DVI_ADPCM /*  Intel Corporation */
WAVE_FORMAT_MEDIASPACE_ADPCM           :: 0x0012 /* Videologic */
WAVE_FORMAT_SIERRA_ADPCM               :: 0x0013 /* Sierra Semiconductor Corp */
WAVE_FORMAT_G723_ADPCM                 :: 0x0014 /* Antex Electronics Corporation */
WAVE_FORMAT_DIGISTD                    :: 0x0015 /* DSP Solutions, Inc. */
WAVE_FORMAT_DIGIFIX                    :: 0x0016 /* DSP Solutions, Inc. */
WAVE_FORMAT_DIALOGIC_OKI_ADPCM         :: 0x0017 /* Dialogic Corporation */
WAVE_FORMAT_MEDIAVISION_ADPCM          :: 0x0018 /* Media Vision, Inc. */
WAVE_FORMAT_CU_CODEC                   :: 0x0019 /* Hewlett-Packard Company */
WAVE_FORMAT_HP_DYN_VOICE               :: 0x001A /* Hewlett-Packard Company */
WAVE_FORMAT_YAMAHA_ADPCM               :: 0x0020 /* Yamaha Corporation of America */
WAVE_FORMAT_SONARC                     :: 0x0021 /* Speech Compression */
WAVE_FORMAT_DSPGROUP_TRUESPEECH        :: 0x0022 /* DSP Group, Inc */
WAVE_FORMAT_ECHOSC1                    :: 0x0023 /* Echo Speech Corporation */
WAVE_FORMAT_AUDIOFILE_AF36             :: 0x0024 /* Virtual Music, Inc. */
WAVE_FORMAT_APTX                       :: 0x0025 /* Audio Processing Technology */
WAVE_FORMAT_AUDIOFILE_AF10             :: 0x0026 /* Virtual Music, Inc. */
WAVE_FORMAT_PROSODY_1612               :: 0x0027 /* Aculab plc */
WAVE_FORMAT_LRC                        :: 0x0028 /* Merging Technologies S.A. */
WAVE_FORMAT_DOLBY_AC2                  :: 0x0030 /* Dolby Laboratories */
WAVE_FORMAT_GSM610                     :: 0x0031 /* Microsoft Corporation */
WAVE_FORMAT_MSNAUDIO                   :: 0x0032 /* Microsoft Corporation */
WAVE_FORMAT_ANTEX_ADPCME               :: 0x0033 /* Antex Electronics Corporation */
WAVE_FORMAT_CONTROL_RES_VQLPC          :: 0x0034 /* Control Resources Limited */
WAVE_FORMAT_DIGIREAL                   :: 0x0035 /* DSP Solutions, Inc. */
WAVE_FORMAT_DIGIADPCM                  :: 0x0036 /* DSP Solutions, Inc. */
WAVE_FORMAT_CONTROL_RES_CR10           :: 0x0037 /* Control Resources Limited */
WAVE_FORMAT_NMS_VBXADPCM               :: 0x0038 /* Natural MicroSystems */
WAVE_FORMAT_CS_IMAADPCM                :: 0x0039 /* Crystal Semiconductor IMA ADPCM */
WAVE_FORMAT_ECHOSC3                    :: 0x003A /* Echo Speech Corporation */
WAVE_FORMAT_ROCKWELL_ADPCM             :: 0x003B /* Rockwell International */
WAVE_FORMAT_ROCKWELL_DIGITALK          :: 0x003C /* Rockwell International */
WAVE_FORMAT_XEBEC                      :: 0x003D /* Xebec Multimedia Solutions Limited */
WAVE_FORMAT_G721_ADPCM                 :: 0x0040 /* Antex Electronics Corporation */
WAVE_FORMAT_G728_CELP                  :: 0x0041 /* Antex Electronics Corporation */
WAVE_FORMAT_MSG723                     :: 0x0042 /* Microsoft Corporation */
WAVE_FORMAT_INTEL_G723_1               :: 0x0043 /* Intel Corp. */
WAVE_FORMAT_INTEL_G729                 :: 0x0044 /* Intel Corp. */
WAVE_FORMAT_SHARP_G726                 :: 0x0045 /* Sharp */
WAVE_FORMAT_MPEG                       :: 0x0050 /* Microsoft Corporation */
WAVE_FORMAT_RT24                       :: 0x0052 /* InSoft, Inc. */
WAVE_FORMAT_PAC                        :: 0x0053 /* InSoft, Inc. */
WAVE_FORMAT_MPEGLAYER3                 :: 0x0055 /* ISO/MPEG Layer3 Format Tag */
WAVE_FORMAT_LUCENT_G723                :: 0x0059 /* Lucent Technologies */
WAVE_FORMAT_CIRRUS                     :: 0x0060 /* Cirrus Logic */
WAVE_FORMAT_ESPCM                      :: 0x0061 /* ESS Technology */
WAVE_FORMAT_VOXWARE                    :: 0x0062 /* Voxware Inc */
WAVE_FORMAT_CANOPUS_ATRAC              :: 0x0063 /* Canopus, co., Ltd. */
WAVE_FORMAT_G726_ADPCM                 :: 0x0064 /* APICOM */
WAVE_FORMAT_G722_ADPCM                 :: 0x0065 /* APICOM */
WAVE_FORMAT_DSAT                       :: 0x0066 /* Microsoft Corporation */
WAVE_FORMAT_DSAT_DISPLAY               :: 0x0067 /* Microsoft Corporation */
WAVE_FORMAT_VOXWARE_BYTE_ALIGNED       :: 0x0069 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC8                :: 0x0070 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC10               :: 0x0071 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC16               :: 0x0072 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC20               :: 0x0073 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_RT24               :: 0x0074 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_RT29               :: 0x0075 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_RT29HW             :: 0x0076 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_VR12               :: 0x0077 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_VR18               :: 0x0078 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_TQ40               :: 0x0079 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_SC3                :: 0x007A /* Voxware Inc */
WAVE_FORMAT_VOXWARE_SC3_1              :: 0x007B /* Voxware Inc */
WAVE_FORMAT_SOFTSOUND                  :: 0x0080 /* Softsound, Ltd. */
WAVE_FORMAT_VOXWARE_TQ60               :: 0x0081 /* Voxware Inc */
WAVE_FORMAT_MSRT24                     :: 0x0082 /* Microsoft Corporation */
WAVE_FORMAT_G729A                      :: 0x0083 /* AT&T Labs, Inc. */
WAVE_FORMAT_MVI_MVI2                   :: 0x0084 /* Motion Pixels */
WAVE_FORMAT_DF_G726                    :: 0x0085 /* DataFusion Systems (Pty) (Ltd) */
WAVE_FORMAT_DF_GSM610                  :: 0x0086 /* DataFusion Systems (Pty) (Ltd) */
WAVE_FORMAT_ISIAUDIO                   :: 0x0088 /* Iterated Systems, Inc. */
WAVE_FORMAT_ONLIVE                     :: 0x0089 /* OnLive! Technologies, Inc. */
WAVE_FORMAT_MULTITUDE_FT_SX20          :: 0x008A /* Multitude Inc. */
WAVE_FORMAT_INFOCOM_ITS_G721_ADPCM     :: 0x008B /* Infocom */
WAVE_FORMAT_CONVEDIA_G729              :: 0x008C /* Convedia Corp. */
WAVE_FORMAT_CONGRUENCY                 :: 0x008D /* Congruency Inc. */
WAVE_FORMAT_SBC24                      :: 0x0091 /* Siemens Business Communications Sys */
WAVE_FORMAT_DOLBY_AC3_SPDIF            :: 0x0092 /* Sonic Foundry */
WAVE_FORMAT_MEDIASONIC_G723            :: 0x0093 /* MediaSonic */
WAVE_FORMAT_PROSODY_8KBPS              :: 0x0094 /* Aculab plc */
WAVE_FORMAT_ZYXEL_ADPCM                :: 0x0097 /* ZyXEL Communications, Inc. */
WAVE_FORMAT_PHILIPS_LPCBB              :: 0x0098 /* Philips Speech Processing */
WAVE_FORMAT_PACKED                     :: 0x0099 /* Studer Professional Audio AG */
WAVE_FORMAT_MALDEN_PHONYTALK           :: 0x00A0 /* Malden Electronics Ltd. */
WAVE_FORMAT_RACAL_RECORDER_GSM         :: 0x00A1 /* Racal recorders */
WAVE_FORMAT_RACAL_RECORDER_G720_A      :: 0x00A2 /* Racal recorders */
WAVE_FORMAT_RACAL_RECORDER_G723_1      :: 0x00A3 /* Racal recorders */
WAVE_FORMAT_RACAL_RECORDER_TETRA_ACELP :: 0x00A4 /* Racal recorders */
WAVE_FORMAT_NEC_AAC                    :: 0x00B0 /* NEC Corp. */
WAVE_FORMAT_RAW_AAC1                   :: 0x00FF /* For Raw AAC, with format block AudioSpecificConfig() (as defined by MPEG-4), that follows WAVEFORMATEX */
WAVE_FORMAT_RHETOREX_ADPCM             :: 0x0100 /* Rhetorex Inc. */
WAVE_FORMAT_IRAT                       :: 0x0101 /* BeCubed Software Inc. */
WAVE_FORMAT_VIVO_G723                  :: 0x0111 /* Vivo Software */
WAVE_FORMAT_VIVO_SIREN                 :: 0x0112 /* Vivo Software */
WAVE_FORMAT_PHILIPS_CELP               :: 0x0120 /* Philips Speech Processing */
WAVE_FORMAT_PHILIPS_GRUNDIG            :: 0x0121 /* Philips Speech Processing */
WAVE_FORMAT_DIGITAL_G723               :: 0x0123 /* Digital Equipment Corporation */
WAVE_FORMAT_SANYO_LD_ADPCM             :: 0x0125 /* Sanyo Electric Co., Ltd. */
WAVE_FORMAT_SIPROLAB_ACEPLNET          :: 0x0130 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_ACELP4800         :: 0x0131 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_ACELP8V3          :: 0x0132 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_G729              :: 0x0133 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_G729A             :: 0x0134 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_KELVIN            :: 0x0135 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_VOICEAGE_AMR               :: 0x0136 /* VoiceAge Corp. */
WAVE_FORMAT_G726ADPCM                  :: 0x0140 /* Dictaphone Corporation */
WAVE_FORMAT_DICTAPHONE_CELP68          :: 0x0141 /* Dictaphone Corporation */
WAVE_FORMAT_DICTAPHONE_CELP54          :: 0x0142 /* Dictaphone Corporation */
WAVE_FORMAT_QUALCOMM_PUREVOICE         :: 0x0150 /* Qualcomm, Inc. */
WAVE_FORMAT_QUALCOMM_HALFRATE          :: 0x0151 /* Qualcomm, Inc. */
WAVE_FORMAT_TUBGSM                     :: 0x0155 /* Ring Zero Systems, Inc. */
WAVE_FORMAT_MSAUDIO1                   :: 0x0160 /* Microsoft Corporation */
WAVE_FORMAT_WMAUDIO2                   :: 0x0161 /* Microsoft Corporation */
WAVE_FORMAT_WMAUDIO3                   :: 0x0162 /* Microsoft Corporation */
WAVE_FORMAT_WMAUDIO_LOSSLESS           :: 0x0163 /* Microsoft Corporation */
WAVE_FORMAT_WMASPDIF                   :: 0x0164 /* Microsoft Corporation */
WAVE_FORMAT_UNISYS_NAP_ADPCM           :: 0x0170 /* Unisys Corp. */
WAVE_FORMAT_UNISYS_NAP_ULAW            :: 0x0171 /* Unisys Corp. */
WAVE_FORMAT_UNISYS_NAP_ALAW            :: 0x0172 /* Unisys Corp. */
WAVE_FORMAT_UNISYS_NAP_16K             :: 0x0173 /* Unisys Corp. */
WAVE_FORMAT_SYCOM_ACM_SYC008           :: 0x0174 /* SyCom Technologies */
WAVE_FORMAT_SYCOM_ACM_SYC701_G726L     :: 0x0175 /* SyCom Technologies */
WAVE_FORMAT_SYCOM_ACM_SYC701_CELP54    :: 0x0176 /* SyCom Technologies */
WAVE_FORMAT_SYCOM_ACM_SYC701_CELP68    :: 0x0177 /* SyCom Technologies */
WAVE_FORMAT_KNOWLEDGE_ADVENTURE_ADPCM  :: 0x0178 /* Knowledge Adventure, Inc. */
WAVE_FORMAT_FRAUNHOFER_IIS_MPEG2_AAC   :: 0x0180 /* Fraunhofer IIS */
WAVE_FORMAT_DTS_DS                     :: 0x0190 /* Digital Theatre Systems, Inc. */
WAVE_FORMAT_CREATIVE_ADPCM             :: 0x0200 /* Creative Labs, Inc */
WAVE_FORMAT_CREATIVE_FASTSPEECH8       :: 0x0202 /* Creative Labs, Inc */
WAVE_FORMAT_CREATIVE_FASTSPEECH10      :: 0x0203 /* Creative Labs, Inc */
WAVE_FORMAT_UHER_ADPCM                 :: 0x0210 /* UHER informatic GmbH */
WAVE_FORMAT_ULEAD_DV_AUDIO             :: 0x0215 /* Ulead Systems, Inc. */
WAVE_FORMAT_ULEAD_DV_AUDIO_1           :: 0x0216 /* Ulead Systems, Inc. */
WAVE_FORMAT_QUARTERDECK                :: 0x0220 /* Quarterdeck Corporation */
WAVE_FORMAT_ILINK_VC                   :: 0x0230 /* I-link Worldwide */
WAVE_FORMAT_RAW_SPORT                  :: 0x0240 /* Aureal Semiconductor */
WAVE_FORMAT_ESST_AC3                   :: 0x0241 /* ESS Technology, Inc. */
WAVE_FORMAT_GENERIC_PASSTHRU           :: 0x0249
WAVE_FORMAT_IPI_HSX                    :: 0x0250 /* Interactive Products, Inc. */
WAVE_FORMAT_IPI_RPELP                  :: 0x0251 /* Interactive Products, Inc. */
WAVE_FORMAT_CS2                        :: 0x0260 /* Consistent Software */
WAVE_FORMAT_SONY_SCX                   :: 0x0270 /* Sony Corp. */
WAVE_FORMAT_SONY_SCY                   :: 0x0271 /* Sony Corp. */
WAVE_FORMAT_SONY_ATRAC3                :: 0x0272 /* Sony Corp. */
WAVE_FORMAT_SONY_SPC                   :: 0x0273 /* Sony Corp. */
WAVE_FORMAT_TELUM_AUDIO                :: 0x0280 /* Telum Inc. */
WAVE_FORMAT_TELUM_IA_AUDIO             :: 0x0281 /* Telum Inc. */
WAVE_FORMAT_NORCOM_VOICE_SYSTEMS_ADPCM :: 0x0285 /* Norcom Electronics Corp. */
WAVE_FORMAT_FM_TOWNS_SND               :: 0x0300 /* Fujitsu Corp. */
WAVE_FORMAT_MICRONAS                   :: 0x0350 /* Micronas Semiconductors, Inc. */
WAVE_FORMAT_MICRONAS_CELP833           :: 0x0351 /* Micronas Semiconductors, Inc. */
WAVE_FORMAT_BTV_DIGITAL                :: 0x0400 /* Brooktree Corporation */
WAVE_FORMAT_INTEL_MUSIC_CODER          :: 0x0401 /* Intel Corp. */
WAVE_FORMAT_INDEO_AUDIO                :: 0x0402 /* Ligos */
WAVE_FORMAT_QDESIGN_MUSIC              :: 0x0450 /* QDesign Corporation */
WAVE_FORMAT_ON2_VP7_AUDIO              :: 0x0500 /* On2 Technologies */
WAVE_FORMAT_ON2_VP6_AUDIO              :: 0x0501 /* On2 Technologies */
WAVE_FORMAT_VME_VMPCM                  :: 0x0680 /* AT&T Labs, Inc. */
WAVE_FORMAT_TPC                        :: 0x0681 /* AT&T Labs, Inc. */
WAVE_FORMAT_LIGHTWAVE_LOSSLESS         :: 0x08AE /* Clearjump */
WAVE_FORMAT_OLIGSM                     :: 0x1000 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLIADPCM                   :: 0x1001 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLICELP                    :: 0x1002 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLISBC                     :: 0x1003 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLIOPR                     :: 0x1004 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_LH_CODEC                   :: 0x1100 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_CELP              :: 0x1101 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_SBC8              :: 0x1102 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_SBC12             :: 0x1103 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_SBC16             :: 0x1104 /* Lernout & Hauspie */
WAVE_FORMAT_NORRIS                     :: 0x1400 /* Norris Communications, Inc. */
WAVE_FORMAT_ISIAUDIO_2                 :: 0x1401 /* ISIAudio */
WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS    :: 0x1500 /* AT&T Labs, Inc. */
WAVE_FORMAT_MPEG_ADTS_AAC              :: 0x1600 /* Microsoft Corporation */
WAVE_FORMAT_MPEG_RAW_AAC               :: 0x1601 /* Microsoft Corporation */
WAVE_FORMAT_MPEG_LOAS                  :: 0x1602 /* Microsoft Corporation (MPEG-4 Audio Transport Streams (LOAS/LATM) */
WAVE_FORMAT_NOKIA_MPEG_ADTS_AAC        :: 0x1608 /* Microsoft Corporation */
WAVE_FORMAT_NOKIA_MPEG_RAW_AAC         :: 0x1609 /* Microsoft Corporation */
WAVE_FORMAT_VODAFONE_MPEG_ADTS_AAC     :: 0x160A /* Microsoft Corporation */
WAVE_FORMAT_VODAFONE_MPEG_RAW_AAC      :: 0x160B /* Microsoft Corporation */
WAVE_FORMAT_MPEG_HEAAC                 :: 0x1610 /* Microsoft Corporation (MPEG-2 AAC or MPEG-4 HE-AAC v1/v2 streams with any payload (ADTS, ADIF, LOAS/LATM, RAW). Format block includes MP4 AudioSpecificConfig() -- see HEAACWAVEFORMAT below */
WAVE_FORMAT_VOXWARE_RT24_SPEECH        :: 0x181C /* Voxware Inc. */
WAVE_FORMAT_SONICFOUNDRY_LOSSLESS      :: 0x1971 /* Sonic Foundry */
WAVE_FORMAT_INNINGS_TELECOM_ADPCM      :: 0x1979 /* Innings Telecom Inc. */
WAVE_FORMAT_LUCENT_SX8300P             :: 0x1C07 /* Lucent Technologies */
WAVE_FORMAT_LUCENT_SX5363S             :: 0x1C0C /* Lucent Technologies */
WAVE_FORMAT_CUSEEME                    :: 0x1F03 /* CUSeeMe */
WAVE_FORMAT_NTCSOFT_ALF2CM_ACM         :: 0x1FC4 /* NTCSoft */
WAVE_FORMAT_DVM                        :: 0x2000 /* FAST Multimedia AG */
WAVE_FORMAT_DTS2                       :: 0x2001
WAVE_FORMAT_MAKEAVIS                   :: 0x3313
WAVE_FORMAT_DIVIO_MPEG4_AAC            :: 0x4143 /* Divio, Inc. */
WAVE_FORMAT_NOKIA_ADAPTIVE_MULTIRATE   :: 0x4201 /* Nokia */
WAVE_FORMAT_DIVIO_G726                 :: 0x4243 /* Divio, Inc. */
WAVE_FORMAT_LEAD_SPEECH                :: 0x434C /* LEAD Technologies */
WAVE_FORMAT_LEAD_VORBIS                :: 0x564C /* LEAD Technologies */
WAVE_FORMAT_WAVPACK_AUDIO              :: 0x5756 /* xiph.org */
WAVE_FORMAT_ALAC                       :: 0x6C61 /* Apple Lossless */
WAVE_FORMAT_OGG_VORBIS_MODE_1          :: 0x674F /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_2          :: 0x6750 /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_3          :: 0x6751 /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_1_PLUS     :: 0x676F /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_2_PLUS     :: 0x6770 /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_3_PLUS     :: 0x6771 /* Ogg Vorbis */
WAVE_FORMAT_3COM_NBX                   :: 0x7000 /* 3COM Corp. */
WAVE_FORMAT_OPUS                       :: 0x704F /* Opus */
WAVE_FORMAT_FAAD_AAC                   :: 0x706D
WAVE_FORMAT_AMR_NB                     :: 0x7361 /* AMR Narrowband */
WAVE_FORMAT_AMR_WB                     :: 0x7362 /* AMR Wideband */
WAVE_FORMAT_AMR_WP                     :: 0x7363 /* AMR Wideband Plus */
WAVE_FORMAT_GSM_AMR_CBR                :: 0x7A21 /* GSMA/3GPP */
WAVE_FORMAT_GSM_AMR_VBR_SID            :: 0x7A22 /* GSMA/3GPP */
WAVE_FORMAT_COMVERSE_INFOSYS_G723_1    :: 0xA100 /* Comverse Infosys */
WAVE_FORMAT_COMVERSE_INFOSYS_AVQSBC    :: 0xA101 /* Comverse Infosys */
WAVE_FORMAT_COMVERSE_INFOSYS_SBC       :: 0xA102 /* Comverse Infosys */
WAVE_FORMAT_SYMBOL_G729_A              :: 0xA103 /* Symbol Technologies */
WAVE_FORMAT_VOICEAGE_AMR_WB            :: 0xA104 /* VoiceAge Corp. */
WAVE_FORMAT_INGENIENT_G726             :: 0xA105 /* Ingenient Technologies, Inc. */
WAVE_FORMAT_MPEG4_AAC                  :: 0xA106 /* ISO/MPEG-4 */
WAVE_FORMAT_ENCORE_G726                :: 0xA107 /* Encore Software */
WAVE_FORMAT_ZOLL_ASAO                  :: 0xA108 /* ZOLL Medical Corp. */
WAVE_FORMAT_SPEEX_VOICE                :: 0xA109 /* xiph.org */
WAVE_FORMAT_VIANIX_MASC                :: 0xA10A /* Vianix LLC */
WAVE_FORMAT_WM9_SPECTRUM_ANALYZER      :: 0xA10B /* Microsoft */
WAVE_FORMAT_WMF_SPECTRUM_ANAYZER       :: 0xA10C /* Microsoft */
WAVE_FORMAT_GSM_610                    :: 0xA10D
WAVE_FORMAT_GSM_620                    :: 0xA10E
WAVE_FORMAT_GSM_660                    :: 0xA10F
WAVE_FORMAT_GSM_690                    :: 0xA110
WAVE_FORMAT_GSM_ADAPTIVE_MULTIRATE_WB  :: 0xA111
WAVE_FORMAT_POLYCOM_G722               :: 0xA112 /* Polycom */
WAVE_FORMAT_POLYCOM_G728               :: 0xA113 /* Polycom */
WAVE_FORMAT_POLYCOM_G729_A             :: 0xA114 /* Polycom */
WAVE_FORMAT_POLYCOM_SIREN              :: 0xA115 /* Polycom */
WAVE_FORMAT_GLOBAL_IP_ILBC             :: 0xA116 /* Global IP */
WAVE_FORMAT_RADIOTIME_TIME_SHIFT_RADIO :: 0xA117 /* RadioTime */
WAVE_FORMAT_NICE_ACA                   :: 0xA118 /* Nice Systems */
WAVE_FORMAT_NICE_ADPCM                 :: 0xA119 /* Nice Systems */
WAVE_FORMAT_VOCORD_G721                :: 0xA11A /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G726                :: 0xA11B /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G722_1              :: 0xA11C /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G728                :: 0xA11D /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G729                :: 0xA11E /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G729_A              :: 0xA11F /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G723_1              :: 0xA120 /* Vocord Telecom */
WAVE_FORMAT_VOCORD_LBC                 :: 0xA121 /* Vocord Telecom */
WAVE_FORMAT_NICE_G728                  :: 0xA122 /* Nice Systems */
WAVE_FORMAT_FRACE_TELECOM_G729         :: 0xA123 /* France Telecom */
WAVE_FORMAT_CODIAN                     :: 0xA124 /* CODIAN */
WAVE_FORMAT_DOLBY_AC4                  :: 0xAC40 /* Dolby AC-4 */
WAVE_FORMAT_FLAC                       :: 0xF1AC /* flac.sourceforge.net */
WAVE_FORMAT_EXTENSIBLE                 :: 0xFFFE /* Microsoft */


WAVEFORMATEX :: struct #packed {
	wFormatTag:      WORD,
	nChannels:       WORD,
	nSamplesPerSec:  DWORD,
	nAvgBytesPerSec: DWORD,
	nBlockAlign:     WORD,
	wBitsPerSample:  WORD,
	cbSize:          WORD,
}
LPCWAVEFORMATEX :: ^WAVEFORMATEX

//  New wave format development should be based on the WAVEFORMATEXTENSIBLE structure.
//  WAVEFORMATEXTENSIBLE allows you to avoid having to register a new format tag with Microsoft.
//  Simply define a new GUID value for the WAVEFORMATEXTENSIBLE.SubFormat field and use WAVE_FORMAT_EXTENSIBLE in the WAVEFORMATEXTENSIBLE.Format.wFormatTag field.
WAVEFORMATEXTENSIBLE :: struct #packed {
	using Format: WAVEFORMATEX,
	Samples: struct #raw_union {
		wValidBitsPerSample: WORD,      /* bits of precision  */
		wSamplesPerBlock:    WORD,      /* valid if wBitsPerSample==0 */
		wReserved:           WORD,      /* If neither applies, set to zero. */
	},
	dwChannelMask: SPEAKER_FLAGS,       /* which channels are present in stream  */
	SubFormat:     GUID,
}

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

SPEAKER_FLAGS :: distinct bit_set[SPEAKER_FLAG; DWORD]
SPEAKER_FLAG :: enum DWORD {
	FRONT_LEFT            = 0,
	FRONT_RIGHT           = 1,
	FRONT_CENTER          = 2,
	LOW_FREQUENCY         = 3,
	BACK_LEFT             = 4,
	BACK_RIGHT            = 5,
	FRONT_LEFT_OF_CENTER  = 6,
	FRONT_RIGHT_OF_CENTER = 7,
	BACK_CENTER           = 8,
	SIDE_LEFT             = 9,
	SIDE_RIGHT            = 10,
	TOP_CENTER            = 11,
	TOP_FRONT_LEFT        = 12,
	TOP_FRONT_CENTER      = 13,
	TOP_FRONT_RIGHT       = 14,
	TOP_BACK_LEFT         = 15,
	TOP_BACK_CENTER       = 16,
	TOP_BACK_RIGHT        = 17,
	//RESERVED            = 0x7FFC0000, // bit mask locations reserved for future use
	ALL                   = 31,         // used to specify that any possible permutation of speaker configurations
}

// flag values for PlaySound
SND_SYNC        :: 0x0000  /* play synchronously (default) */
SND_ASYNC       :: 0x0001  /* play asynchronously */
SND_NODEFAULT   :: 0x0002  /* silence (!default) if sound not found */
SND_MEMORY      :: 0x0004  /* pszSound points to a memory file */
SND_LOOP        :: 0x0008  /* loop the sound until next sndPlaySound */
SND_NOSTOP      :: 0x0010  /* don't stop any currently playing sound */

SND_NOWAIT      :: 0x00002000 /* don't wait if the driver is busy */
SND_ALIAS       :: 0x00010000 /* name is a registry alias */
SND_ALIAS_ID    :: 0x00110000 /* alias is a predefined ID */
SND_FILENAME    :: 0x00020000 /* name is file name */
SND_RESOURCE    :: 0x00040004 /* name is resource name or atom */

SND_PURGE       :: 0x0040  /* purge non-static events for task */
SND_APPLICATION :: 0x0080  /* look for application specific association */

SND_SENTRY      :: 0x00080000 /* Generate a SoundSentry event with this sound */
SND_RING        :: 0x00100000 /* Treat this as a "ring" from a communications app - don't duck me */
SND_SYSTEM      :: 0x00200000 /* Treat this as a system sound */


CALLBACK_TYPEMASK :: 0x00070000    /* callback type mask */
CALLBACK_NULL     :: 0x00000000    /* no callback */
CALLBACK_WINDOW   :: 0x00010000    /* dwCallback is a HWND */
CALLBACK_TASK     :: 0x00020000    /* dwCallback is a HTASK */
CALLBACK_FUNCTION :: 0x00030000    /* dwCallback is a FARPROC */
CALLBACK_THREAD   :: CALLBACK_TASK /* thread ID replaces 16 bit task */
CALLBACK_EVENT    :: 0x00050000    /* dwCallback is an EVENT Handle */
