package sdl2

import "core:c"

when ODIN_OS == .Windows {
	@(ignore_duplicates)
	foreign import lib "SDL2.lib"
} else {
	@(ignore_duplicates)
	foreign import lib "system:SDL2"
}

/**
 *  \brief Audio format flags.
 *
 *  These are what the 16 bits in SDL_AudioFormat currently mean...
 *  (Unspecified bits are always zero).
 *
 *  \verbatim
    ++-----------------------sample is signed if set
    ||
    ||       ++-----------sample is bigendian if set
    ||       ||
    ||       ||          ++---sample is float if set
    ||       ||          ||
    ||       ||          || +---sample bit size---+
    ||       ||          || |                     |
    15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
    \endverbatim
 *
 *  There are macros in SDL 2.0 and later to query these bits.
 */
AudioFormat :: distinct u16


AUDIO_MASK_BITSIZE       :: 0xFF
AUDIO_MASK_DATATYPE      :: 1<<8
AUDIO_MASK_ENDIAN        :: 1<<12
AUDIO_MASK_SIGNED        :: 1<<15
AUDIO_BITSIZE        :: #force_inline proc "c" (x: AudioFormat) -> u8   { return u8(x & AUDIO_MASK_BITSIZE)                       }
AUDIO_ISFLOAT        :: #force_inline proc "c" (x: AudioFormat) -> bool { return (x & AUDIO_MASK_DATATYPE) == AUDIO_MASK_DATATYPE }
AUDIO_ISBIGENDIAN    :: #force_inline proc "c" (x: AudioFormat) -> bool { return (x & AUDIO_MASK_ENDIAN) == AUDIO_MASK_ENDIAN     }
AUDIO_ISSIGNED       :: #force_inline proc "c" (x: AudioFormat) -> bool { return (x & AUDIO_MASK_SIGNED) == AUDIO_MASK_SIGNED     }
AUDIO_ISINT          :: #force_inline proc "c" (x: AudioFormat) -> bool { return !AUDIO_ISFLOAT(x)                                }
AUDIO_ISLITTLEENDIAN :: #force_inline proc "c" (x: AudioFormat) -> bool { return !AUDIO_ISBIGENDIAN(x)                            }
AUDIO_ISUNSIGNED     :: #force_inline proc "c" (x: AudioFormat) -> bool { return !AUDIO_ISSIGNED(x)                               }

AUDIO_U8        :: 0x0008  /**< Unsigned 8-bit samples */
AUDIO_S8        :: 0x8008  /**< Signed 8-bit samples */
AUDIO_U16LSB    :: 0x0010  /**< Unsigned 16-bit samples */
AUDIO_S16LSB    :: 0x8010  /**< Signed 16-bit samples */
AUDIO_U16MSB    :: 0x1010  /**< As above, but big-endian byte order */
AUDIO_S16MSB    :: 0x9010  /**< As above, but big-endian byte order */
AUDIO_U16       :: AUDIO_U16LSB
AUDIO_S16       :: AUDIO_S16LSB

AUDIO_S32LSB    :: 0x8020  /**< 32-bit integer samples */
AUDIO_S32MSB    :: 0x9020  /**< As above, but big-endian byte order */
AUDIO_S32       :: AUDIO_S32LSB

AUDIO_F32LSB    :: 0x8120  /**< 32-bit floating point samples */
AUDIO_F32MSB    :: 0x9120  /**< As above, but big-endian byte order */
AUDIO_F32       :: AUDIO_F32LSB

when ODIN_ENDIAN == .Little {
	AUDIO_U16SYS :: AUDIO_U16LSB
	AUDIO_S16SYS :: AUDIO_S16LSB
	AUDIO_S32SYS :: AUDIO_S32LSB
	AUDIO_F32SYS :: AUDIO_F32LSB
} else {
	AUDIO_U16SYS :: AUDIO_U16MSB
	AUDIO_S16SYS :: AUDIO_S16MSB
	AUDIO_S32SYS :: AUDIO_S32MSB
	AUDIO_F32SYS :: AUDIO_F32MSB
}


AUDIO_ALLOW_FREQUENCY_CHANGE    :: 0x00000001
AUDIO_ALLOW_FORMAT_CHANGE       :: 0x00000002
AUDIO_ALLOW_CHANNELS_CHANGE     :: 0x00000004
AUDIO_ALLOW_SAMPLES_CHANGE      :: 0x00000008
AUDIO_ALLOW_ANY_CHANGE          :: AUDIO_ALLOW_FREQUENCY_CHANGE|AUDIO_ALLOW_FORMAT_CHANGE|AUDIO_ALLOW_CHANNELS_CHANGE|AUDIO_ALLOW_SAMPLES_CHANGE

AudioCallback :: proc "c" (userdata: rawptr, stream: [^]u8, len: c.int)

/**
 *  The calculated values in this structure are calculated by SDL_OpenAudio().
 *
 *  For multi-channel audio, the default SDL channel mapping is:
 *  2:  FL FR                       (stereo)
 *  3:  FL FR LFE                   (2.1 surround)
 *  4:  FL FR BL BR                 (quad)
 *  5:  FL FR FC BL BR              (quad + center)
 *  6:  FL FR FC LFE SL SR          (5.1 surround - last two can also be BL BR)
 *  7:  FL FR FC LFE BC SL SR       (6.1 surround)
 *  8:  FL FR FC LFE BL BR SL SR    (7.1 surround)
 */
AudioSpec :: struct {
	freq:     c.int,         /**< DSP frequency -- samples per second */
	format:   AudioFormat,   /**< Audio data format */
	channels: u8,            /**< Number of channels: 1 mono, 2 stereo */
	silence:  u8,            /**< Audio buffer silence value (calculated) */
	samples:  u16,           /**< Audio buffer size in sample FRAMES (total samples divided by channel count) */
	padding:  u16,           /**< Necessary for some compile environments */
	size:     u32,           /**< Audio buffer size in bytes (calculated) */
	callback: AudioCallback, /**< Callback that feeds the audio device (NULL to use SDL_QueueAudio()). */
	userdata: rawptr,        /**< Userdata passed to callback (ignored for NULL callbacks). */
}


AudioFilter :: proc "c" (cvt: ^AudioCVT, format: AudioFormat)

AUDIOCVT_MAX_FILTERS :: 9

AudioCVT :: struct #packed {
	needed:       c.int,       /**< Set to 1 if conversion possible */
	src_format:   AudioFormat, /**< Source audio format */
	dst_format:   AudioFormat, /**< Target audio format */
	rate_incr:    f64,         /**< Rate conversion increment */
	buf:          [^]u8,       /**< Buffer to hold entire audio data */
	len:          c.int,       /**< Length of original audio buffer */
	len_cvt:      c.int,       /**< Length of converted audio buffer */
	len_mult:     c.int,       /**< buffer must be len*len_mult big */
	len_ratio:    f64,         /**< Given len, final size is len*len_ratio */
	filters:      [AUDIOCVT_MAX_FILTERS + 1]AudioFilter, /**< NULL-terminated list of filter functions */
	filter_index: c.int,       /**< Current audio conversion function */
}



AudioDeviceID :: distinct u32

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumAudioDrivers :: proc() -> c.int ---
	GetAudioDriver     :: proc(index: c.int) -> cstring ---

	AudioInit :: proc(driver_name: cstring) -> c.int ---
	AudioQuit :: proc() ---

	GetCurrentAudioDriver :: proc() -> cstring ---

	OpenAudio :: proc(desired, obtained: ^AudioSpec) -> c.int ---

	GetNumAudioDevices :: proc(iscapture: bool) -> c.int ---

	GetAudioDeviceName :: proc(index: c.int, iscapture: bool) -> cstring ---
	GetAudioDeviceSpec :: proc(index: c.int, iscapture: bool, spec: ^AudioSpec) -> c.int ---

	OpenAudioDevice :: proc(device: cstring,
	                        iscapture: bool,
	                        desired: ^AudioSpec,
	                        obtained: ^AudioSpec,
	                        allowed_changes: bool) -> AudioDeviceID ---
}



AudioStatus :: enum c.int {
	STOPPED = 0,
	PLAYING,
	PAUSED,
}
@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetAudioStatus :: proc() -> AudioStatus ---
	GetAudioDeviceStatus :: proc(dev: AudioDeviceID) -> AudioStatus --- /* Audio State */
}


/* this is opaque to the outside world. */
AudioStream :: struct {}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	PauseAudio       :: proc(pause_on: bool) ---
	PauseAudioDevice :: proc(dev: AudioDeviceID, pause_on: bool) --- /* Pause audio functions */
}


/**
 *  Loads a WAV from a file.
 *  Compatibility convenience function.
 */
LoadWAV :: #force_inline proc "c" (file: cstring, spec: ^AudioSpec, audio_buf: ^[^]u8, audio_len: ^u32) -> ^AudioSpec {
	return LoadWAV_RW(RWFromFile(file, "rb"), true, spec, audio_buf, audio_len)
}

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	LoadWAV_RW :: proc(src: ^RWops, freesrc: bool, spec: ^AudioSpec, audio_buf: ^[^]u8, audio_len: ^u32) -> ^AudioSpec ---
	FreeWAV    :: proc(audio_buf: [^]u8) ---
}



@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	BuildAudioCVT :: proc(cvt:          ^AudioCVT,
	                      src_format:   AudioFormat,
	                      src_channels: u8,
	                      src_rate:     c.int,
	                      dst_format:   AudioFormat,
	                      dst_channels: u8,
	                      dst_rate:     c.int) -> c.int ---

	ConvertAudio :: proc(cvt: ^AudioCVT) -> c.int ---

	NewAudioStream :: proc(src_format:   AudioFormat,
	                       src_channels: u8,
	                       src_rate:     c.int,
	                       dst_format:   AudioFormat,
	                       dst_channels: u8,
	                       dst_rate:     c.int) -> ^AudioStream ---

	AudioStreamPut :: proc(stream: ^AudioStream, buf: rawptr, len: c.int) -> c.int ---
	AudioStreamGet :: proc(stream: ^AudioStream, buf: rawptr, len: c.int) -> c.int ---

	AudioStreamAvailable :: proc(stream: ^AudioStream) -> c.int ---
	AudioStreamFlush     :: proc(stream: ^AudioStream) -> c.int ---
	AudioStreamClear     :: proc(stream: ^AudioStream) ---
	FreeAudioStream      :: proc(stream: ^AudioStream) ---

}


MIX_MAXVOLUME :: 128

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	MixAudio           :: proc(dst: [^]u8, src: [^]u8, len: u32, volume: c.int)                      ---
	MixAudioFormat     :: proc(dst: [^]u8, src: [^]u8, format: AudioFormat, len: u32, volume: c.int) ---
	QueueAudio         :: proc(dev: AudioDeviceID, data: rawptr, len: u32) -> c.int              ---
	DequeueAudio       :: proc(dev: AudioDeviceID, data: rawptr, len: u32) -> u32                ---
	GetQueuedAudioSize :: proc(dev: AudioDeviceID) -> u32                                        ---
	ClearQueuedAudio   :: proc(dev: AudioDeviceID)                                               ---

	LockAudio         :: proc()                   ---
	LockAudioDevice   :: proc(dev: AudioDeviceID) ---
	UnlockAudio       :: proc()                   ---
	UnlockAudioDevice :: proc(dev: AudioDeviceID) --- /* Audio lock functions */

	CloseAudio       :: proc() ---
	CloseAudioDevice :: proc(dev: AudioDeviceID) ---
}
