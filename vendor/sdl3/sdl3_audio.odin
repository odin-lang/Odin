package sdl3

import "core:c"

AUDIO_MASK_BITSIZE    :: 0xFF
AUDIO_MASK_FLOAT      :: 1<<8
AUDIO_MASK_BIG_ENDIAN :: 1<<12
AUDIO_MASK_SIGNED     :: 1<<15

@(require_results)
DEFINE_AUDIO_FORMAT :: #force_inline proc "c" (signed, bigendian, flt, size: Uint16) -> Uint16 {
	return (((Uint16)(signed) << 15) | ((Uint16)(bigendian) << 12) | ((Uint16)(flt) << 8) | ((size) & AUDIO_MASK_BITSIZE))
}


AudioFormat :: enum c.int {
	UNKNOWN   = 0x0000,  /**< Unspecified audio format */
	U8        = 0x0008,  /**< Unsigned 8-bit samples */
	                     /* DEFINE_AUDIO_FORMAT(0, 0, 0, 8), */
	S8        = 0x8008,  /**< Signed 8-bit samples */
	                     /* DEFINE_AUDIO_FORMAT(1, 0, 0, 8), */
	S16LE     = 0x8010,  /**< Signed 16-bit samples */
	                     /* DEFINE_AUDIO_FORMAT(1, 0, 0, 16), */
	S16BE     = 0x9010,  /**< As above, but big-endian byte order */
	                     /* DEFINE_AUDIO_FORMAT(1, 1, 0, 16), */
	S32LE     = 0x8020,  /**< 32-bit integer samples */
	                     /* DEFINE_AUDIO_FORMAT(1, 0, 0, 32), */
	S32BE     = 0x9020,  /**< As above, but big-endian byte order */
	                     /* DEFINE_AUDIO_FORMAT(1, 1, 0, 32), */
	F32LE     = 0x8120,  /**< 32-bit floating point samples */
	                     /* DEFINE_AUDIO_FORMAT(1, 0, 1, 32), */
	F32BE     = 0x9120,  /**< As above, but big-endian byte order */
	                     /* DEFINE_AUDIO_FORMAT(1, 1, 1, 32), */

	/* These represent the current system's byteorder. */
	S16 = S16LE when BYTEORDER == LIL_ENDIAN else S16BE,
	S32 = S32LE when BYTEORDER == LIL_ENDIAN else S32BE,
	F32 = F32LE when BYTEORDER == LIL_ENDIAN else F32BE,
}

@(require_results) AUDIO_BITSIZE        :: proc "c" (x: AudioFormat) -> Uint16 { return (Uint16(x) & AUDIO_MASK_BITSIZE)       }
@(require_results) AUDIO_BYTESIZE       :: proc "c" (x: AudioFormat) -> Uint16 { return AUDIO_BITSIZE(x) / 8                   }
@(require_results) AUDIO_ISFLOAT        :: proc "c" (x: AudioFormat) -> bool { return (Uint16(x) & AUDIO_MASK_FLOAT) != 0      }
@(require_results) AUDIO_ISBIGENDIAN    :: proc "c" (x: AudioFormat) -> bool { return (Uint16(x) & AUDIO_MASK_BIG_ENDIAN) != 0 }
@(require_results) AUDIO_ISLITTLEENDIAN :: proc "c" (x: AudioFormat) -> bool { return !AUDIO_ISBIGENDIAN(x)                    }
@(require_results) AUDIO_ISSIGNED       :: proc "c" (x: AudioFormat) -> bool { return (Uint16(x) & AUDIO_MASK_SIGNED) != 0     }
@(require_results) AUDIO_ISINT          :: proc "c" (x: AudioFormat) -> bool { return !AUDIO_ISFLOAT(x)                        }
@(require_results) AUDIO_ISUNSIGNED     :: proc "c" (x: AudioFormat) -> bool { return !AUDIO_ISSIGNED(x)                       }


AudioDeviceID :: distinct Uint32

AUDIO_DEVICE_DEFAULT_PLAYBACK  :: AudioDeviceID(0xFFFFFFFF)
AUDIO_DEVICE_DEFAULT_RECORDING :: AudioDeviceID(0xFFFFFFFE)

AudioSpec :: struct {
	format:   AudioFormat, /**< Audio data format */
	channels: c.int,       /**< Number of channels: 1 mono, 2 stereo, etc */
	freq:     c.int,       /**< sample rate: sample frames per second */
}

@(require_results)
AUDIO_FRAMESIZE :: proc "c" (x: AudioSpec) -> c.int {
	return c.int(AUDIO_BYTESIZE(x.format)) * x.channels
}


AudioStream :: struct {}

AudioStreamCallback  :: #type proc "c" (userdata: rawptr, stream: ^AudioStream, additional_amount, total_amount: c.int)
AudioPostmixCallback :: #type proc "c" (userdata: rawptr, spec: ^AudioSpec, buffer: [^]f32, buflen: c.int)

@(default_calling_convention="c", link_prefix="SDL_")
foreign lib {
	GetNumAudioDrivers             :: proc() -> c.int ---
	GetAudioDriver                 :: proc(index: c.int) -> cstring ---
	GetCurrentAudioDriver          :: proc() -> cstring ---
	GetAudioPlaybackDevices        :: proc(count: ^c.int) -> [^]AudioDeviceID ---
	GetAudioRecordingDevices       :: proc(count: ^c.int) -> [^]AudioDeviceID ---
	GetAudioDeviceName             :: proc(devid: AudioDeviceID) -> cstring ---
	GetAudioDeviceFormat           :: proc(devid: AudioDeviceID, spec: ^AudioSpec, sample_frames: ^c.int) -> bool ---
	GetAudioDeviceChannelMap       :: proc(devid: AudioDeviceID, count: ^c.int) -> [^]c.int ---
	OpenAudioDevice                :: proc(devid: AudioDeviceID, spec: ^AudioSpec) -> AudioDeviceID ---
	IsAudioDevicePhysical          :: proc(devid: AudioDeviceID) -> bool ---
	IsAudioDevicePlayback          :: proc(devid: AudioDeviceID) -> bool ---
	PauseAudioDevice               :: proc(devid: AudioDeviceID) -> bool ---
	ResumeAudioDevice              :: proc(devid: AudioDeviceID) -> bool ---
	AudioDevicePaused              :: proc(devid: AudioDeviceID) -> bool ---
	GetAudioDeviceGain             :: proc(devid: AudioDeviceID) -> f32 ---
	SetAudioDeviceGain             :: proc(devid: AudioDeviceID, gain: f32) -> bool ---
	CloseAudioDevice               :: proc(devid: AudioDeviceID) ---
	BindAudioStreams               :: proc(devid: AudioDeviceID, streams: [^]^AudioStream, num_streams: c.int) -> bool ---
	BindAudioStream                :: proc(devid: AudioDeviceID, stream: ^AudioStream) -> bool ---
	UnbindAudioStreams             :: proc(streams: [^]^AudioStream, num_streams: c.int) ---
	UnbindAudioStream              :: proc(stream: ^AudioStream) ---
	GetAudioStreamDevice           :: proc(stream: ^AudioStream) -> AudioDeviceID ---
	CreateAudioStream              :: proc(src_spec, dst_spec: ^AudioSpec) -> ^AudioStream ---
	GetAudioStreamProperties       :: proc(stream: ^AudioStream) -> PropertiesID ---
	GetAudioStreamFormat           :: proc(stream: ^AudioStream, src_spec, dst_spec: ^AudioSpec) -> bool ---
	SetAudioStreamFormat           :: proc(stream: ^AudioStream, src_spec, dst_spec: ^AudioSpec) -> bool ---
	GetAudioStreamFrequencyRatio   :: proc(stream: ^AudioStream) -> f32 ---
	SetAudioStreamFrequencyRatio   :: proc(stream: ^AudioStream, ratio: f32) -> bool ---
	GetAudioStreamGain             :: proc(stream: ^AudioStream) -> f32 ---
	SetAudioStreamGain             :: proc(stream: ^AudioStream, gain: f32) -> bool ---
	GetAudioStreamInputChannelMap  :: proc(stream: ^AudioStream, count: ^c.int) -> [^]c.int ---
	GetAudioStreamOutputChannelMap :: proc(stream: ^AudioStream, count: ^c.int) -> [^]c.int ---
	SetAudioStreamInputChannelMap  :: proc(stream: ^AudioStream, chmap: [^]c.int, count: c.int) -> bool ---
	SetAudioStreamOutputChannelMap :: proc(stream: ^AudioStream, chmap: [^]c.int, count: c.int) -> bool ---
	PutAudioStreamData             :: proc(stream: ^AudioStream, buf: rawptr, len: c.int) -> bool ---
	GetAudioStreamData             :: proc(stream: ^AudioStream, buf: rawptr, len: c.int) -> c.int ---
	GetAudioStreamAvailable        :: proc(stream: ^AudioStream) -> c.int ---
	GetAudioStreamQueued           :: proc(stream: ^AudioStream) -> c.int ---
	FlushAudioStream               :: proc(stream: ^AudioStream) -> bool ---
	ClearAudioStream               :: proc(stream: ^AudioStream) -> bool ---
	PauseAudioStreamDevice         :: proc(stream: ^AudioStream) -> bool ---
	ResumeAudioStreamDevice        :: proc(stream: ^AudioStream) -> bool ---
	AudioStreamDevicePaused        :: proc(stream: ^AudioStream) -> bool ---
	LockAudioStream                :: proc(stream: ^AudioStream) -> bool ---
	UnlockAudioStream              :: proc(stream: ^AudioStream) -> bool ---
	SetAudioStreamGetCallback      :: proc(stream: ^AudioStream, callback: AudioStreamCallback, userdata: rawptr) -> bool ---
	SetAudioStreamPutCallback      :: proc(stream: ^AudioStream, callback: AudioStreamCallback, userdata: rawptr) -> bool ---
	DestroyAudioStream             :: proc(stream: ^AudioStream) ---
	OpenAudioDeviceStream          :: proc(devid: AudioDeviceID, spec: ^AudioSpec, callback: AudioStreamCallback, userdata: rawptr) -> ^AudioStream ---
	SetAudioPostmixCallback        :: proc(devid: AudioDeviceID, callback: AudioPostmixCallback, userdata: rawptr) -> bool ---
	LoadWAV_IO                     :: proc(src: ^IOStream, closeio: bool, spec: ^AudioSpec, audio_buf: ^[^]Uint8, audio_len: ^Uint32) -> bool ---
	LoadWAV                        :: proc(path: cstring, spec: ^AudioSpec, audio_buf: ^[^]Uint8, audio_len: ^Uint32) -> bool ---
	MixAudio                       :: proc(dst, src: [^]Uint8, format: AudioFormat, len: Uint32, volume: f32) -> bool ---
	ConvertAudioSamples            :: proc(src_spec: ^AudioSpec, src_data: [^]Uint8, src_len: c.int, dst_spec: ^AudioSpec, dst_data: ^[^]Uint8, dst_len: ^c.int) -> bool ---
	GetAudioFormatName             :: proc(format: AudioFormat) -> cstring ---
	GetSilenceValueForFormat       :: proc(format: AudioFormat) -> c.int ---
}