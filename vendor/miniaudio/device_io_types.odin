package miniaudio

import "core:c"

SUPPORT_WASAPI     :: ODIN_OS == .Windows
SUPPORT_DSOUND     :: ODIN_OS == .Windows
SUPPORT_WINMM      :: ODIN_OS == .Windows
SUPPORT_COREAUDIO  :: ODIN_OS == .Darwin
SUPPORT_SNDIO      :: ODIN_OS == .OpenBSD
SUPPORT_AUDIO4     :: false // ODIN_OS == .OpenBSD || ODIN_OS == .NetBSD
SUPPORT_OSS        :: ODIN_OS == .FreeBSD
SUPPORT_PULSEAUDIO :: ODIN_OS == .Linux
SUPPORT_ALSA       :: ODIN_OS == .Linux
SUPPORT_JACK       :: ODIN_OS == .Windows
SUPPORT_AAUDIO     :: false // ODIN_OS == .Android
SUPPORT_OPENSL     :: false // ODIN_OS == .Android
SUPPORT_WEBAUDIO   :: false // ODIN_OS == .Emscripten
SUPPORT_CUSTOM     :: true
SUPPORT_NULL       :: true // ODIN_OS != .Emscripten

STATE_UNINITIALIZED :: 0
STATE_STOPPED       :: 1   /* The device's default state after initialization. */
STATE_STARTED       :: 2   /* The device is started and is requesting and/or delivering audio data. */
STATE_STARTING      :: 3   /* Transitioning from a stopped state to started. */
STATE_STOPPING      :: 4   /* Transitioning from a started state to stopped. */



when SUPPORT_WASAPI {
	IMMNotificationClient :: struct {
		lpVtbl:  rawptr,
		counter: u32,
		pDevice: ^device,
	}
}

/* Backend enums must be in priority order. */
backend :: enum c.int {
	wasapi,
	dsound,
	winmm,
	coreaudio,
	sndio,
	audio4,
	oss,
	pulseaudio,
	alsa,
	jack,
	aaudio,
	opensl,
	webaudio,
	custom,  /* <-- Custom backend, with callbacks defined by the context config. */
	null,    /* <-- Must always be the last item. Lowest priority, and used as the terminator for backend enumeration. */
}

BACKEND_COUNT :: len(backend)


/*
The callback for processing audio data from the device.

The data callback is fired by miniaudio whenever the device needs to have more data delivered to a playback device, or when a capture device has some data
available. This is called as soon as the backend asks for more data which means it may be called with inconsistent frame counts. You cannot assume the
callback will be fired with a consistent frame count.


Parameters
----------
pDevice (in)
	A pointer to the relevant device.

pOutput (out)
	A pointer to the output buffer that will receive audio data that will later be played back through the speakers. This will be non-null for a playback or
	full-duplex device and null for a capture and loopback device.

pInput (in)
	A pointer to the buffer containing input data from a recording device. This will be non-null for a capture, full-duplex or loopback device and null for a
	playback device.

frameCount (in)
	The number of PCM frames to process. Note that this will not necessarily be equal to what you requested when you initialized the device. The
	`periodSizeInFrames` and `periodSizeInMilliseconds` members of the device config are just hints, and are not necessarily exactly what you'll get. You must
	not assume this will always be the same value each time the callback is fired.


Remarks
-------
You cannot stop and start the device from inside the callback or else you'll get a deadlock. You must also not uninitialize the device from inside the
callback. The following APIs cannot be called from inside the callback:

	ma_device_init()
	ma_device_init_ex()
	ma_device_uninit()
	ma_device_start()
	ma_device_stop()

The proper way to stop the device is to call `ma_device_stop()` from a different thread, normally the main application thread.
*/
device_callback_proc :: proc "c" (pDevice: ^device, pOutput: rawptr, pInput: rawptr, frameCount: u32)

/*
The callback for when the device has been stopped.

This will be called when the device is stopped explicitly with `ma_device_stop()` and also called implicitly when the device is stopped through external forces
such as being unplugged or an internal error occuring.


Parameters
----------
pDevice (in)
	A pointer to the device that has just stopped.


Remarks
-------
Do not restart or uninitialize the device from the callback.
*/
stop_proc :: proc "c" (pDevice: ^device)

/*
The callback for handling log messages.


Parameters
----------
pContext (in)
	A pointer to the context the log message originated from.

pDevice (in)
	A pointer to the device the log message originate from, if any. This can be null, in which case the message came from the context.

logLevel (in)
	The log level. This can be one of the following:

	+----------------------+
	| Log Level            |
	+----------------------+
	| MA_LOG_LEVEL_DEBUG   |
	| MA_LOG_LEVEL_INFO    |
	| MA_LOG_LEVEL_WARNING |
	| MA_LOG_LEVEL_ERROR   |
	+----------------------+

message (in)
	The log message.


Remarks
-------
Do not modify the state of the device from inside the callback.
*/
log_proc :: proc "c" (pContext: context_type, pDevice: ^device, logLevel: u32, message: cstring)

device_type :: enum c.int {
	playback = 1,
	capture  = 2,
	duplex   = 3, // playback | capture
	loopback = 4,
}

share_mode :: enum c.int {
	shared = 0,
	exclusive,
}

/* iOS/tvOS/watchOS session categories. */
ios_session_category :: enum c.int {
	default = 0,        /* AVAudioSessionCategoryPlayAndRecord with AVAudioSessionCategoryOptionDefaultToSpeaker. */
	none,               /* Leave the session category unchanged. */
	ambient,            /* AVAudioSessionCategoryAmbient */
	solo_ambient,       /* AVAudioSessionCategorySoloAmbient */
	playback,           /* AVAudioSessionCategoryPlayback */
	record,             /* AVAudioSessionCategoryRecord */
	play_and_record,    /* AVAudioSessionCategoryPlayAndRecord */
	multi_route,        /* AVAudioSessionCategoryMultiRoute */
}

/* iOS/tvOS/watchOS session category options */
ios_session_category_option:: enum c.int {
	mix_with_others                            = 0x01,   /* AVAudioSessionCategoryOptionMixWithOthers */
	duck_others                                = 0x02,   /* AVAudioSessionCategoryOptionDuckOthers */
	allow_bluetooth                            = 0x04,   /* AVAudioSessionCategoryOptionAllowBluetooth */
	default_to_speaker                         = 0x08,   /* AVAudioSessionCategoryOptionDefaultToSpeaker */
	interrupt_spoken_audio_and_mix_with_others = 0x11,   /* AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers */
	allow_bluetooth_a2dp                       = 0x20,   /* AVAudioSessionCategoryOptionAllowBluetoothA2DP */
	allow_air_play                             = 0x40,   /* AVAudioSessionCategoryOptionAllowAirPlay */
}

/* OpenSL stream types. */
opensl_stream_type :: enum c.int {
	default = 0,              /* Leaves the stream type unset. */
	voice,                    /* SL_ANDROID_STREAM_VOICE */
	system,                   /* SL_ANDROID_STREAM_SYSTEM */
	ring,                     /* SL_ANDROID_STREAM_RING */
	media,                    /* SL_ANDROID_STREAM_MEDIA */
	alarm,                    /* SL_ANDROID_STREAM_ALARM */
	notification,             /* SL_ANDROID_STREAM_NOTIFICATION */
}

/* OpenSL recording presets. */
opensl_recording_preset :: enum c.int {
	default = 0,         /* Leaves the input preset unset. */
	generic,             /* SL_ANDROID_RECORDING_PRESET_GENERIC */
	camcorder,           /* SL_ANDROID_RECORDING_PRESET_CAMCORDER */
	voice_recognition,   /* SL_ANDROID_RECORDING_PRESET_VOICE_RECOGNITION */
	voice_communication, /* SL_ANDROID_RECORDING_PRESET_VOICE_COMMUNICATION */
	voice_unprocessed,   /* SL_ANDROID_RECORDING_PRESET_UNPROCESSED */
}

/* AAudio usage types. */
aaudio_usage :: enum c.int {
	default = 0,                    /* Leaves the usage type unset. */
	announcement,                   /* AAUDIO_SYSTEM_USAGE_ANNOUNCEMENT */
	emergency,                      /* AAUDIO_SYSTEM_USAGE_EMERGENCY */
	safety,                         /* AAUDIO_SYSTEM_USAGE_SAFETY */
	vehicle_status,                 /* AAUDIO_SYSTEM_USAGE_VEHICLE_STATUS */
	alarm,                          /* AAUDIO_USAGE_ALARM */
	assistance_accessibility,       /* AAUDIO_USAGE_ASSISTANCE_ACCESSIBILITY */
	assistance_navigation_guidance, /* AAUDIO_USAGE_ASSISTANCE_NAVIGATION_GUIDANCE */
	assistance_sonification,        /* AAUDIO_USAGE_ASSISTANCE_SONIFICATION */
	assitant,                       /* AAUDIO_USAGE_ASSISTANT */
	game,                           /* AAUDIO_USAGE_GAME */
	media,                          /* AAUDIO_USAGE_MEDIA */
	notification,                   /* AAUDIO_USAGE_NOTIFICATION */
	notification_event,             /* AAUDIO_USAGE_NOTIFICATION_EVENT */
	notification_ringtone,          /* AAUDIO_USAGE_NOTIFICATION_RINGTONE */
	voice_communication,            /* AAUDIO_USAGE_VOICE_COMMUNICATION */
	voice_communication_signalling, /* AAUDIO_USAGE_VOICE_COMMUNICATION_SIGNALLING */
}

/* AAudio content types. */
aaudio_content_type :: enum c.int {
	default = 0,             /* Leaves the content type unset. */
	movie,                   /* AAUDIO_CONTENT_TYPE_MOVIE */
	music,                   /* AAUDIO_CONTENT_TYPE_MUSIC */
	sonification,            /* AAUDIO_CONTENT_TYPE_SONIFICATION */
	speech,                  /* AAUDIO_CONTENT_TYPE_SPEECH */
}

/* AAudio input presets. */
aaudio_input_preset :: enum c.int {
	default = 0,             /* Leaves the input preset unset. */
	generic,                 /* AAUDIO_INPUT_PRESET_GENERIC */
	camcorder,               /* AAUDIO_INPUT_PRESET_CAMCORDER */
	unprocessed,             /* AAUDIO_INPUT_PRESET_UNPROCESSED */
	voice_recognition,       /* AAUDIO_INPUT_PRESET_VOICE_RECOGNITION */
	voice_communication,     /* AAUDIO_INPUT_PRESET_VOICE_COMMUNICATION */
	voice_performance,       /* AAUDIO_INPUT_PRESET_VOICE_PERFORMANCE */
}


timer :: struct #raw_union {
	counter:  i64,
	counterD: f64,
}

device_id :: struct #raw_union {
	wasapi:             [64]c.wchar_t,  /* WASAPI uses a wchar_t string for identification. */
	dsound:             [16]u8,         /* DirectSound uses a GUID for identification. */
	/*UINT_PTR*/ winmm: u32,            /* When creating a device, WinMM expects a Win32 UINT_PTR for device identification. In practice it's actually just a UINT. */
	alsa:               [256]c.char,    /* ALSA uses a name string for identification. */
	pulse:              [256]c.char,    /* PulseAudio uses a name string for identification. */
	jack:               c.int,          /* JACK always uses default devices. */
	coreaudio:          [256]c.char,    /* Core Audio uses a string for identification. */
	sndio:              [256]c.char,    /* "snd/0", etc. */
	audio4:             [256]c.char,    /* "/dev/audio", etc. */
	oss:                [64]c.char,     /* "dev/dsp0", etc. "dev/dsp" for the default device. */
	aaudio:             i32,            /* AAudio uses a 32-bit integer for identification. */
	opensl:             u32,            /* OpenSL|ES uses a 32-bit unsigned integer for identification. */
	webaudio:           [32]c.char,     /* Web Audio always uses default devices for now, but if this changes it'll be a GUID. */
	custom: struct #raw_union {
		i: c.int,
		s: [256]c.char,
		p: rawptr,
	},                                  /* The custom backend could be anything. Give them a few options. */
	nullbackend: c.int,                 /* The null backend uses an integer for device IDs. */
}


DATA_FORMAT_FLAG_EXCLUSIVE_MODE :: 1 << 1    /* If set, this is supported in exclusive mode. Otherwise not natively supported by exclusive mode. */

device_info :: struct {
	/* Basic info. This is the only information guaranteed to be filled in during device enumeration. */
	id:        device_id,
	name:      [256]byte,
	isDefault: b32,

	/*
	Detailed info. As much of this is filled as possible with ma_context_get_device_info(). Note that you are allowed to initialize
	a device with settings outside of this range, but it just means the data will be converted using miniaudio's data conversion
	pipeline before sending the data to/from the device. Most programs will need to not worry about these values, but it's provided
	here mainly for informational purposes or in the rare case that someone might find it useful.

	These will be set to 0 when returned by ma_context_enumerate_devices() or ma_context_get_devices().
	*/
	formatCount:   u32,
	formats:       [format]format,
	minChannels:   u32,
	maxChannels:   u32,
	minSampleRate: u32,
	maxSampleRate: u32,


	/* Experimental. Don't use these right now. */
	nativeDataFormatCount: u32,
	nativeDataFormats: [/*len(format_count) * standard_sample_rate.rate_count * MAX_CHANNELS*/ 64]struct { /* Not sure how big to make this. There can be *many* permutations for virtual devices which can support anything. */
		format:     format, /* Sample format. If set to ma_format_unknown, all sample formats are supported. */
		channels:   u32,    /* If set to 0, all channels are supported. */
		sampleRate: u32,    /* If set to 0, all sample rates are supported. */
		flags:      u32,    /* A combination of MA_DATA_FORMAT_FLAG_* flags. */
	},  
}

device_config :: struct {
	deviceType:               device_type,
	sampleRate:               u32,
	periodSizeInFrames:       u32,
	periodSizeInMilliseconds: u32,
	periods:                  u32,
	performanceProfile:       performance_profile,
	noPreZeroedOutputBuffer:  b8,   /* When set to true, the contents of the output buffer passed into the data callback will be left undefined rather than initialized to zero. */
	noClip:                   b8,                    /* When set to true, the contents of the output buffer passed into the data callback will be clipped after returning. Only applies when the playback sample format is f32. */
	dataCallback:             device_callback_proc,
	stopCallback:             stop_proc,
	pUserData: rawptr,
	resampling: struct {
		algorithm: resample_algorithm,
		linear: struct {
			lpfOrder: u32,
		},
		speex: struct {
			quality: c.int,
		},
	},
	playback: struct {
		pDeviceID:      ^device_id,
		format:         format,
		channels:       u32,
		channelMap:     [MAX_CHANNELS]channel,
		channelMixMode: channel_mix_mode,
		shareMode:      share_mode,
	},
	capture: struct {
		pDeviceID:      ^device_id,
		format:         format,
		channels:       u32,
		channelMap:     [MAX_CHANNELS]channel,
		channelMixMode: channel_mix_mode,
		shareMode:      share_mode,
	},

	wasapi: struct {
		noAutoConvertSRC:     b8, /* When set to true, disables the use of AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM. */
		noDefaultQualitySRC:  b8, /* When set to true, disables the use of AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY. */
		noAutoStreamRouting:  b8, /* Disables automatic stream routing. */
		noHardwareOffloading: b8, /* Disables WASAPI's hardware offloading feature. */
	},
	alsa: struct {
		noMMap:         b32, /* Disables MMap mode. */
		noAutoFormat:   b32, /* Opens the ALSA device with SND_PCM_NO_AUTO_FORMAT. */
		noAutoChannels: b32, /* Opens the ALSA device with SND_PCM_NO_AUTO_CHANNELS. */
		noAutoResample: b32, /* Opens the ALSA device with SND_PCM_NO_AUTO_RESAMPLE. */
	},
	pulse: struct {
		pStreamNamePlayback: cstring,
		pStreamNameCapture:  cstring,
	},
	coreaudio: struct {
		allowNominalSampleRateChange: b32, /* Desktop only. When enabled, allows changing of the sample rate at the operating system level. */
	},
	opensl: struct {
		streamType:      opensl_stream_type,
		recordingPreset: opensl_recording_preset,
	},
	aaudio: struct {
		usage:       aaudio_usage,
		contentType: aaudio_content_type,
		inputPreset: aaudio_input_preset,
	},
}


/*
The callback for handling device enumeration. This is fired from `ma_context_enumerated_devices()`.


Parameters
----------
pContext (in)
	A pointer to the context performing the enumeration.

deviceType (in)
	The type of the device being enumerated. This will always be either `ma_device_type_playback` or `ma_device_type_capture`.

pInfo (in)
	A pointer to a `ma_device_info` containing the ID and name of the enumerated device. Note that this will not include detailed information about the device,
	only basic information (ID and name). The reason for this is that it would otherwise require opening the backend device to probe for the information which
	is too inefficient.

pUserData (in)
	The user data pointer passed into `ma_context_enumerate_devices()`.
*/
enum_devices_callback_proc :: proc "c" (pContext: ^context_type, deviceType: device_type, pInfo: ^device_info, pUserData: rawptr) -> b32


/*
Describes some basic details about a playback or capture device.
*/
device_descriptor :: struct {
	pDeviceID:                ^device_id,
	shareMode:                share_mode,
	format:                   format,
	channels:                 u32,
	sampleRate:               u32,
	channelMap:               [MAX_CHANNELS]channel,
	periodSizeInFrames:       u32,
	periodSizeInMilliseconds: u32,
	periodCount:              u32,
}

/*
These are the callbacks required to be implemented for a backend. These callbacks are grouped into two parts: context and device. There is one context
to many devices. A device is created from a context.

The general flow goes like this:

  1) A context is created with `onContextInit()`
	 1a) Available devices can be enumerated with `onContextEnumerateDevices()` if required.
	 1b) Detailed information about a device can be queried with `onContextGetDeviceInfo()` if required.
  2) A device is created from the context that was created in the first step using `onDeviceInit()`, and optionally a device ID that was
	 selected from device enumeration via `onContextEnumerateDevices()`.
  3) A device is started or stopped with `onDeviceStart()` / `onDeviceStop()`
  4) Data is delivered to and from the device by the backend. This is always done based on the native format returned by the prior call
	 to `onDeviceInit()`. Conversion between the device's native format and the format requested by the application will be handled by
	 miniaudio internally.

Initialization of the context is quite simple. You need to do any necessary initialization of internal objects and then output the
callbacks defined in this structure.

Once the context has been initialized you can initialize a device. Before doing so, however, the application may want to know which
physical devices are available. This is where `onContextEnumerateDevices()` comes in. This is fairly simple. For each device, fire the
given callback with, at a minimum, the basic information filled out in `ma_device_info`. When the callback returns `MA_FALSE`, enumeration
needs to stop and the `onContextEnumerateDevices()` function return with a success code.

Detailed device information can be retrieved from a device ID using `onContextGetDeviceInfo()`. This takes as input the device type and ID,
and on output returns detailed information about the device in `ma_device_info`. The `onContextGetDeviceInfo()` callback must handle the
case when the device ID is NULL, in which case information about the default device needs to be retrieved.

Once the context has been created and the device ID retrieved (if using anything other than the default device), the device can be created.
This is a little bit more complicated than initialization of the context due to it's more complicated configuration. When initializing a
device, a duplex device may be requested. This means a separate data format needs to be specified for both playback and capture. On input,
the data format is set to what the application wants. On output it's set to the native format which should match as closely as possible to
the requested format. The conversion between the format requested by the application and the device's native format will be handled
internally by miniaudio.

On input, if the sample format is set to `ma_format_unknown`, the backend is free to use whatever sample format it desires, so long as it's
supported by miniaudio. When the channel count is set to 0, the backend should use the device's native channel count. The same applies for
sample rate. For the channel map, the default should be used when `ma_channel_map_blank()` returns true (all channels set to
`MA_CHANNEL_NONE`). On input, the `periodSizeInFrames` or `periodSizeInMilliseconds` option should always be set. The backend should
inspect both of these variables. If `periodSizeInFrames` is set, it should take priority, otherwise it needs to be derived from the period
size in milliseconds (`periodSizeInMilliseconds`) and the sample rate, keeping in mind that the sample rate may be 0, in which case the
sample rate will need to be determined before calculating the period size in frames. On output, all members of the `ma_device_data_format`
object should be set to a valid value, except for `periodSizeInMilliseconds` which is optional (`periodSizeInFrames` *must* be set).

Starting and stopping of the device is done with `onDeviceStart()` and `onDeviceStop()` and should be self-explanatory. If the backend uses
asynchronous reading and writing, `onDeviceStart()` and `onDeviceStop()` should always be implemented.

The handling of data delivery between the application and the device is the most complicated part of the process. To make this a bit
easier, some helper callbacks are available. If the backend uses a blocking read/write style of API, the `onDeviceRead()` and
`onDeviceWrite()` callbacks can optionally be implemented. These are blocking and work just like reading and writing from a file. If the
backend uses a callback for data delivery, that callback must call `ma_device_handle_backend_data_callback()` from within it's callback.
This allows miniaudio to then process any necessary data conversion and then pass it to the miniaudio data callback.

If the backend requires absolute flexibility with it's data delivery, it can optionally implement the `onDeviceDataLoop()` callback
which will allow it to implement the logic that will run on the audio thread. This is much more advanced and is completely optional.

The audio thread should run data delivery logic in a loop while `ma_device_get_state() == MA_STATE_STARTED` and no errors have been
encounted. Do not start or stop the device here. That will be handled from outside the `onDeviceDataLoop()` callback.

The invocation of the `onDeviceDataLoop()` callback will be handled by miniaudio. When you start the device, miniaudio will fire this
callback. When the device is stopped, the `ma_device_get_state() == MA_STATE_STARTED` condition will fail and the loop will be terminated
which will then fall through to the part that stops the device. For an example on how to implement the `onDeviceDataLoop()` callback,
look at `ma_device_audio_thread__default_read_write()`. Implement the `onDeviceDataLoopWakeup()` callback if you need a mechanism to
wake up the audio thread.
*/
backend_callbacks :: struct {
	onContextInit:              proc "c" (pContext: ^context_type, pConfig: ^context_config, pCallbacks: ^backend_callbacks) -> result,
	onContextUninit:            proc "c" (pContext: ^context_type) -> result,
	onContextEnumerateDevices:  proc "c" (pContext: ^context_type, callback: enum_devices_callback_proc, pUserData: rawptr) -> result,
	onContextGetDeviceInfo:     proc "c" (pContext: ^context_type, deviceType: device_type, pDeviceID: ^device_id, pDeviceInfo: ^device_info) -> result,
	onDeviceInit:               proc "c" (pDevice: ^device, pConfig: ^device_config, pDescriptorPlayback, pDescriptorCapture: ^device_descriptor) -> result,
	onDeviceUninit:             proc "c" (pDevice: ^device) -> result,
	onDeviceStart:              proc "c" (pDevice: ^device) -> result,
	onDeviceStop:               proc "c" (pDevice: ^device) -> result,
	onDeviceRead:               proc "c" (pDevice: ^device, pFrames: rawptr, frameCount: u32, pFramesRead: ^u32) -> result,
	onDeviceWrite:              proc "c" (pDevice: ^device, pFrames: rawptr, frameCount: u32, pFramesWritten: ^u32) -> result,
	onDeviceDataLoop:           proc "c" (pDevice: ^device) -> result,
	onDeviceDataLoopWakeup:     proc "c" (pDevice: ^device) -> result,
}

context_config :: struct {
	logCallback: log_proc, /* Legacy logging callback. Will be removed in version 0.11. */
	pLog: ^log,
	threadPriority: thread_priority,
	threadStackSize: c.size_t,
	pUserData: rawptr,
	allocationCallbacks: allocation_callbacks,
	alsa: struct {
		useVerboseDeviceEnumeration: b32,
	},
	pulse: struct {
		pApplicationName: cstring,
		pServerName:      cstring,
		tryAutoSpawn:     b32,     /* Enables autospawning of the PulseAudio daemon if necessary. */
	},
	coreaudio: struct {
		sessionCategory:          ios_session_category,
		sessionCategoryOptions:   u32,
		noAudioSessionActivate:   b32, /* iOS only. When set to true, does not perform an explicit [[AVAudioSession sharedInstace] setActive:true] on initialization. */
		noAudioSessionDeactivate: b32, /* iOS only. When set to true, does not perform an explicit [[AVAudioSession sharedInstace] setActive:false] on uninitialization. */
	},
	jack: struct {
		pClientName:    cstring,
		tryStartServer: b32,
	},
	custom: backend_callbacks,
}

/* WASAPI specific structure for some commands which must run on a common thread due to bugs in WASAPI. */
context_command__wasapi :: struct {
	code:   c.int,
	pEvent: ^event,   /* This will be signalled when the event is complete. */
	data:   struct #raw_union {
		quit: struct {
			_unused: c.int,
		},
		createAudioClient: struct {
			deviceType:           device_type,
			pAudioClient:         rawptr,
			ppAudioClientService: ^rawptr,
			pResult:              ^rawptr, /* The result from creating the audio client service. */
		},
		releaseAudioClient: struct {
			pDevice:    ^device,
			deviceType: device_type,
		},
	},
}

context_type :: struct {
	callbacks: backend_callbacks,
	backend: backend,                 /* DirectSound, ALSA, etc. */
	pLog: ^log,
	log: log,                         /* Only used if the log is owned by the context. The pLog member will be set to &log in this case. */
	logCallback: log_proc,            /* Legacy callback. Will be removed in version 0.11. */
	threadPriority: thread_priority,
	threadStackSize: c.size_t,
	pUserData: rawptr,
	allocationCallbacks: allocation_callbacks,
	deviceEnumLock: mutex,            /* Used to make ma_context_get_devices() thread safe. */
	deviceInfoLock: mutex,            /* Used to make ma_context_get_device_info() thread safe. */
	deviceInfoCapacity: u32,          /* Total capacity of pDeviceInfos. */
	playbackDeviceInfoCount: u32,
	captureDeviceInfoCount: u32,
	pDeviceInfos: [^]device_info,     /* Playback devices first, then capture. */

	using _: struct #raw_union {
		wasapi: (struct {
			commandThread: thread,
			commandLock:   mutex,
			commandSem:    semaphore,
			commandIndex:  u32,
			commandCount:  u32,
			commands:      [4]context_command__wasapi,
		} when SUPPORT_WASAPI else struct {}),
		
		dsound: (struct {
			DSoundDLL:                    handle,
			DirectSoundCreate:            proc "system" (),
			DirectSoundEnumerateA:        proc "system" (),
			DirectSoundCaptureCreate:     proc "system" (),
			DirectSoundCaptureEnumerateA: proc "system" (),
		} when SUPPORT_DSOUND else struct {}),
		
		winmm: (struct {
			hWinMM:                 handle,
			waveOutGetNumDevs:      proc "system" (),
			waveOutGetDevCapsA:     proc "system" (),
			waveOutOpen:            proc "system" (),
			waveOutClose:           proc "system" (),
			waveOutPrepareHeader:   proc "system" (),
			waveOutUnprepareHeader: proc "system" (),
			waveOutWrite:           proc "system" (),
			waveOutReset:           proc "system" (),
			waveInGetNumDevs:       proc "system" (),
			waveInGetDevCapsA:      proc "system" (),
			waveInOpen:             proc "system" (),
			waveInClose:            proc "system" (),
			waveInPrepareHeader:    proc "system" (),
			waveInUnprepareHeader:  proc "system" (),
			waveInAddBuffer:        proc "system" (),
			waveInStart:            proc "system" (),
			waveInReset:            proc "system" (),
		} when SUPPORT_WINMM else struct {}),

		alsa: (struct {
			asoundSO:                               handle,
			snd_pcm_open:                           proc "system" (),
			snd_pcm_close:                          proc "system" (),
			snd_pcm_hw_params_sizeof:               proc "system" (),
			snd_pcm_hw_params_any:                  proc "system" (),
			snd_pcm_hw_params_set_format:           proc "system" (),
			snd_pcm_hw_params_set_format_first:     proc "system" (),
			snd_pcm_hw_params_get_format_mask:      proc "system" (),
			snd_pcm_hw_params_set_channels:         proc "system" (),
			snd_pcm_hw_params_set_channels_near:    proc "system" (),
			snd_pcm_hw_params_set_channels_minmax:  proc "system" (),
			snd_pcm_hw_params_set_rate_resample:    proc "system" (),
			snd_pcm_hw_params_set_rate:             proc "system" (),
			snd_pcm_hw_params_set_rate_near:        proc "system" (),
			snd_pcm_hw_params_set_buffer_size_near: proc "system" (),
			snd_pcm_hw_params_set_periods_near:     proc "system" (),
			snd_pcm_hw_params_set_access:           proc "system" (),
			snd_pcm_hw_params_get_format:           proc "system" (),
			snd_pcm_hw_params_get_channels:         proc "system" (),
			snd_pcm_hw_params_get_channels_min:     proc "system" (),
			snd_pcm_hw_params_get_channels_max:     proc "system" (),
			snd_pcm_hw_params_get_rate:             proc "system" (),
			snd_pcm_hw_params_get_rate_min:         proc "system" (),
			snd_pcm_hw_params_get_rate_max:         proc "system" (),
			snd_pcm_hw_params_get_buffer_size:      proc "system" (),
			snd_pcm_hw_params_get_periods:          proc "system" (),
			snd_pcm_hw_params_get_access:           proc "system" (),
			snd_pcm_hw_params_test_format:          proc "system" (),
			snd_pcm_hw_params_test_channels:        proc "system" (),
			snd_pcm_hw_params_test_rate:            proc "system" (),
			snd_pcm_hw_params:                      proc "system" (),
			snd_pcm_sw_params_sizeof:               proc "system" (),
			snd_pcm_sw_params_current:              proc "system" (),
			snd_pcm_sw_params_get_boundary:         proc "system" (),
			snd_pcm_sw_params_set_avail_min:        proc "system" (),
			snd_pcm_sw_params_set_start_threshold:  proc "system" (),
			snd_pcm_sw_params_set_stop_threshold:   proc "system" (),
			snd_pcm_sw_params:                      proc "system" (),
			snd_pcm_format_mask_sizeof:             proc "system" (),
			snd_pcm_format_mask_test:               proc "system" (),
			snd_pcm_get_chmap:                      proc "system" (),
			snd_pcm_state:                          proc "system" (),
			snd_pcm_prepare:                        proc "system" (),
			snd_pcm_start:                          proc "system" (),
			snd_pcm_drop:                           proc "system" (),
			snd_pcm_drain:                          proc "system" (),
			snd_pcm_reset:                          proc "system" (),
			snd_device_name_hint:                   proc "system" (),
			snd_device_name_get_hint:               proc "system" (),
			snd_card_get_index:                     proc "system" (),
			snd_device_name_free_hint:              proc "system" (),
			snd_pcm_mmap_begin:                     proc "system" (),
			snd_pcm_mmap_commit:                    proc "system" (),
			snd_pcm_recover:                        proc "system" (),
			snd_pcm_readi:                          proc "system" (),
			snd_pcm_writei:                         proc "system" (),
			snd_pcm_avail:                          proc "system" (),
			snd_pcm_avail_update:                   proc "system" (),
			snd_pcm_wait:                           proc "system" (),
			snd_pcm_nonblock:                       proc "system" (),
			snd_pcm_info:                           proc "system" (),
			snd_pcm_info_sizeof:                    proc "system" (),
			snd_pcm_info_get_name:                  proc "system" (),
			snd_pcm_poll_descriptors:               proc "system" (),
			snd_pcm_poll_descriptors_count:         proc "system" (),
			snd_pcm_poll_descriptors_revents:       proc "system" (),
			snd_config_update_free_global:          proc "system" (),

			internalDeviceEnumLock:      mutex,
			useVerboseDeviceEnumeration: b32,
		} when SUPPORT_ALSA else struct {}),

		pulse: (struct {
			pulseSO:                            handle,
			pa_mainloop_new:                    proc "system" (),
			pa_mainloop_free:                   proc "system" (),
			pa_mainloop_quit:                   proc "system" (),
			pa_mainloop_get_api:                proc "system" (),
			pa_mainloop_iterate:                proc "system" (),
			pa_mainloop_wakeup:                 proc "system" (),
			pa_threaded_mainloop_new:           proc "system" (),
			pa_threaded_mainloop_free:          proc "system" (),
			pa_threaded_mainloop_start:         proc "system" (),
			pa_threaded_mainloop_stop:          proc "system" (),
			pa_threaded_mainloop_lock:          proc "system" (),
			pa_threaded_mainloop_unlock:        proc "system" (),
			pa_threaded_mainloop_wait:          proc "system" (),
			pa_threaded_mainloop_signal:        proc "system" (),
			pa_threaded_mainloop_accept:        proc "system" (),
			pa_threaded_mainloop_get_retval:    proc "system" (),
			pa_threaded_mainloop_get_api:       proc "system" (),
			pa_threaded_mainloop_in_thread:     proc "system" (),
			pa_threaded_mainloop_set_name:      proc "system" (),
			pa_context_new:                     proc "system" (),
			pa_context_unref:                   proc "system" (),
			pa_context_connect:                 proc "system" (),
			pa_context_disconnect:              proc "system" (),
			pa_context_set_state_callback:      proc "system" (),
			pa_context_get_state:               proc "system" (),
			pa_context_get_sink_info_list:      proc "system" (),
			pa_context_get_source_info_list:    proc "system" (),
			pa_context_get_sink_info_by_name:   proc "system" (),
			pa_context_get_source_info_by_name: proc "system" (),
			pa_operation_unref:                 proc "system" (),
			pa_operation_get_state:             proc "system" (),
			pa_channel_map_init_extend:         proc "system" (),
			pa_channel_map_valid:               proc "system" (),
			pa_channel_map_compatible:          proc "system" (),
			pa_stream_new:                      proc "system" (),
			pa_stream_unref:                    proc "system" (),
			pa_stream_connect_playback:         proc "system" (),
			pa_stream_connect_record:           proc "system" (),
			pa_stream_disconnect:               proc "system" (),
			pa_stream_get_state:                proc "system" (),
			pa_stream_get_sample_spec:          proc "system" (),
			pa_stream_get_channel_map:          proc "system" (),
			pa_stream_get_buffer_attr:          proc "system" (),
			pa_stream_set_buffer_attr:          proc "system" (),
			pa_stream_get_device_name:          proc "system" (),
			pa_stream_set_write_callback:       proc "system" (),
			pa_stream_set_read_callback:        proc "system" (),
			pa_stream_set_suspended_callback:   proc "system" (),
			pa_stream_is_suspended:             proc "system" (),
			pa_stream_flush:                    proc "system" (),
			pa_stream_drain:                    proc "system" (),
			pa_stream_is_corked:                proc "system" (),
			pa_stream_cork:                     proc "system" (),
			pa_stream_trigger:                  proc "system" (),
			pa_stream_begin_write:              proc "system" (),
			pa_stream_write:                    proc "system" (),
			pa_stream_peek:                     proc "system" (),
			pa_stream_drop:                     proc "system" (),
			pa_stream_writable_size:            proc "system" (),
			pa_stream_readable_size:            proc "system" (),

			/*pa_mainloop**/ pMainLoop:     rawptr,
			/*pa_context**/  pPulseContext: rawptr,
		} when SUPPORT_PULSEAUDIO else struct {}),
		
		jack: (struct {
			jackSO:                        handle,
			jack_client_open:              proc "system" (),
			jack_client_close:             proc "system" (),
			jack_client_name_size:         proc "system" (),
			jack_set_process_callback:     proc "system" (),
			jack_set_buffer_size_callback: proc "system" (),
			jack_on_shutdown:              proc "system" (),
			jack_get_sample_rate:          proc "system" (),
			jack_get_buffer_size:          proc "system" (),
			jack_get_ports:                proc "system" (),
			jack_activate:                 proc "system" (),
			jack_deactivate:               proc "system" (),
			jack_connect:                  proc "system" (),
			jack_port_register:            proc "system" (),
			jack_port_name:                proc "system" (),
			jack_port_get_buffer:          proc "system" (),
			jack_free:                     proc "system" (),

			pClientName:    [^]c.char,
			tryStartServer: b32,
		} when SUPPORT_JACK else struct {}),

		coreaudio: (struct {
			hCoreFoundation:    handle,
			CFStringGetCString: proc "system" (),
			CFRelease:          proc "system" (),

			hCoreAudio:                        handle,
			AudioObjectGetPropertyData:        proc "system" (),
			AudioObjectGetPropertyDataSize:    proc "system" (),
			AudioObjectSetPropertyData:        proc "system" (),
			AudioObjectAddPropertyListener:    proc "system" (),
			AudioObjectRemovePropertyListener: proc "system" (),

			hAudioUnit:                    handle,  /* Could possibly be set to AudioToolbox on later versions of macOS. */
			AudioComponentFindNext:        proc "system" (),
			AudioComponentInstanceDispose: proc "system" (),
			AudioComponentInstanceNew:     proc "system" (),
			AudioOutputUnitStart:          proc "system" (),
			AudioOutputUnitStop:           proc "system" (),
			AudioUnitAddPropertyListener:  proc "system" (),
			AudioUnitGetPropertyInfo:      proc "system" (),
			AudioUnitGetProperty:          proc "system" (),
			AudioUnitSetProperty:          proc "system" (),
			AudioUnitInitialize:           proc "system" (),
			AudioUnitRender:               proc "system" (),

			/*AudioComponent*/ component: rawptr,
			noAudioSessionDeactivate:     b32, /* For tracking whether or not the iOS audio session should be explicitly deactivated. Set from the config in ma_context_init__coreaudio(). */
		} when SUPPORT_COREAUDIO else struct {}),
		
		sndio: (struct {
			sndioSO:     handle,
			sio_open:    proc "system" (),
			sio_close:   proc "system" (),
			sio_setpar:  proc "system" (),
			sio_getpar:  proc "system" (),
			sio_getcap:  proc "system" (),
			sio_start:   proc "system" (),
			sio_stop:    proc "system" (),
			sio_read:    proc "system" (),
			sio_write:   proc "system" (),
			sio_onmove:  proc "system" (),
			sio_nfds:    proc "system" (),
			sio_pollfd:  proc "system" (),
			sio_revents: proc "system" (),
			sio_eof:     proc "system" (),
			sio_setvol:  proc "system" (),
			sio_onvol:   proc "system" (),
			sio_initpar: proc "system" (),
		} when SUPPORT_SNDIO else struct {}),

		audio4: (struct {
			_unused: cint,
		} when SUPPORT_AUDIO4 else struct {}),

		oss: (struct {
			versionMajor: c.int,
			versionMinor: c.int,
		} when SUPPORT_OSS else struct {}),

		aaudio: (struct {
			hAAudio:                                       handle, /* libaaudio.so */
			AAudio_createStreamBuilder:                    proc "system" (),
			AAudioStreamBuilder_delete:                    proc "system" (),
			AAudioStreamBuilder_setDeviceId:               proc "system" (),
			AAudioStreamBuilder_setDirection:              proc "system" (),
			AAudioStreamBuilder_setSharingMode:            proc "system" (),
			AAudioStreamBuilder_setFormat:                 proc "system" (),
			AAudioStreamBuilder_setChannelCount:           proc "system" (),
			AAudioStreamBuilder_setSampleRate:             proc "system" (),
			AAudioStreamBuilder_setBufferCapacityInFrames: proc "system" (),
			AAudioStreamBuilder_setFramesPerDataCallback:  proc "system" (),
			AAudioStreamBuilder_setDataCallback:           proc "system" (),
			AAudioStreamBuilder_setErrorCallback:          proc "system" (),
			AAudioStreamBuilder_setPerformanceMode:        proc "system" (),
			AAudioStreamBuilder_setUsage:                  proc "system" (),
			AAudioStreamBuilder_setContentType:            proc "system" (),
			AAudioStreamBuilder_setInputPreset:            proc "system" (),
			AAudioStreamBuilder_openStream:                proc "system" (),
			AAudioStream_close:                            proc "system" (),
			AAudioStream_getState:                         proc "system" (),
			AAudioStream_waitForStateChange:               proc "system" (),
			AAudioStream_getFormat:                        proc "system" (),
			AAudioStream_getChannelCount:                  proc "system" (),
			AAudioStream_getSampleRate:                    proc "system" (),
			AAudioStream_getBufferCapacityInFrames:        proc "system" (),
			AAudioStream_getFramesPerDataCallback:         proc "system" (),
			AAudioStream_getFramesPerBurst:                proc "system" (),
			AAudioStream_requestStart:                     proc "system" (),
			AAudioStream_requestStop:                      proc "system" (),
		} when SUPPORT_AAUDIO else struct {}),

		opensl: (struct {
			libOpenSLES:                      handle,
			SL_IID_ENGINE:                    handle,
			SL_IID_AUDIOIODEVICECAPABILITIES: handle,
			SL_IID_ANDROIDSIMPLEBUFFERQUEUE:  handle,
			SL_IID_RECORD:                    handle,
			SL_IID_PLAY:                      handle,
			SL_IID_OUTPUTMIX:                 handle,
			SL_IID_ANDROIDCONFIGURATION:      handle,
			slCreateEngine:                   proc "system" (),
		} when SUPPORT_OPENSL else struct {}),
		
		webaudio: (struct {
			_unused: c.int,
		} when SUPPORT_WEBAUDIO else struct {}),
		
		null_backend: (struct {
			_unused: c.int,
		} when SUPPORT_NULL else struct {}),
	},
	using _: struct #raw_union {
		win32: (struct {
			/*HMODULE*/ hOle32DLL:       handle,
			CoInitializeEx:              proc "system" (),
			CoUninitialize:              proc "system" (),
			CoCreateInstance:            proc "system" (),
			CoTaskMemFree:               proc "system" (),
			PropVariantClear:            proc "system" (),
			StringFromGUID2:             proc "system" (),

			/*HMODULE*/ hUser32DLL:      handle,
			GetForegroundWindow:         proc "system" (),
			GetDesktopWindow:            proc "system" (),

			/*HMODULE*/ hAdvapi32DLL:    handle,
			RegOpenKeyExA:               proc "system" (),
			RegCloseKey:                 proc "system" (),
			RegQueryValueExA:            proc "system" (),
		} when ODIN_OS == .Windows else struct {}),
		
		posix: (struct {
			pthreadSO:                   handle,
			pthread_create:              proc "system" (),
			pthread_join:                proc "system" (),
			pthread_mutex_init:          proc "system" (),
			pthread_mutex_destroy:       proc "system" (),
			pthread_mutex_lock:          proc "system" (),
			pthread_mutex_unlock:        proc "system" (),
			pthread_cond_init:           proc "system" (),
			pthread_cond_destroy:        proc "system" (),
			pthread_cond_wait:           proc "system" (),
			pthread_cond_signal:         proc "system" (),
			pthread_attr_init:           proc "system" (),
			pthread_attr_destroy:        proc "system" (),
			pthread_attr_setschedpolicy: proc "system" (),
			pthread_attr_getschedparam:  proc "system" (),
			pthread_attr_setschedparam:  proc "system" (),
		} when ODIN_OS != .Windows else struct {}),
		
		_unused: c.int,
	},
}

device :: struct {
	pContext:                ^context_type,
	type:                    device_type,
	sampleRate:              u32,
	state:                   u32, /*atomic*/        /* The state of the device is variable and can change at any time on any thread. Must be used atomically. */
	onData:                  device_callback_proc,  /* Set once at initialization time and should not be changed after. */
	onStop:                  stop_proc,             /* Set once at initialization time and should not be changed after. */
	pUserData:               rawptr,                /* Application defined data. */
	startStopLock:           mutex,
	wakeupEvent:             event,
	startEvent:              event,
	stopEvent:               event,
	device_thread:           thread,
	workResult:              result,                /* This is set by the worker thread after it's finished doing a job. */
	isOwnerOfContext:        b8,                    /* When set to true, uninitializing the device will also uninitialize the context. Set to true when NULL is passed into ma_device_init(). */
	noPreZeroedOutputBuffer: b8,
	noClip:                  b8,
	masterVolumeFactor:      f32, /*atomic*/        /* Linear 0..1. Can be read and written simultaneously by different threads. Must be used atomically. */
	duplexRB:                duplex_rb,             /* Intermediary buffer for duplex device on asynchronous backends. */
	resampling: struct {
		algorithm: resample_algorithm,
		linear: struct {
			lpfOrder: u32,
		},
		speex: struct {
			quality: c.int,
		},
	},
	playback: struct {
		id:                         device_id,             /* If using an explicit device, will be set to a copy of the ID used for initialization. Otherwise cleared to 0. */
		name:                       [256]byte,             /* Maybe temporary. Likely to be replaced with a query API. */
		shareMode:                  share_mode,            /* Set to whatever was passed in when the device was initialized. */
		playback_format:            format,
		channels:                   u32,
		channelMap:                 [MAX_CHANNELS]channel,
		internalFormat:             format,
		internalChannels:           u32,
		internalSampleRate:         u32,
		internalChannelMap:         [MAX_CHANNELS]channel,
		internalPeriodSizeInFrames: u32,
		internalPeriods:            u32,
		channelMixMode:             channel_mix_mode,
		converter:                  data_converter,
	},
	capture: struct {
		id:                         device_id,             /* If using an explicit device, will be set to a copy of the ID used for initialization. Otherwise cleared to 0. */
		name:                       [256]byte,             /* Maybe temporary. Likely to be replaced with a query API. */
		shareMode:                  share_mode,            /* Set to whatever was passed in when the device was initialized. */
		capture_format:             format,
		channels:                   u32,
		channelMap:                 [MAX_CHANNELS]channel,
		internalFormat:             format,
		internalChannels:           u32,
		internalSampleRate:         u32,
		internalChannelMap:         [MAX_CHANNELS]channel,
		internalPeriodSizeInFrames: u32,
		internalPeriods:            u32,
		channelMixMode:             channel_mix_mode,
		converter:                  data_converter,
	},

	using _: struct #raw_union {
		wasapi: (struct {
			/*IAudioClient**/ pAudioClientPlayback: rawptr,
			/*IAudioClient**/ pAudioClientCapture: rawptr,
			/*IAudioRenderClient**/ pRenderClient: rawptr,
			/*IAudioCaptureClient**/ pCaptureClient: rawptr,
			/*IMMDeviceEnumerator**/ pDeviceEnumerator: rawptr,      /* Used for IMMNotificationClient notifications. Required for detecting default device changes. */
			notificationClient: IMMNotificationClient,
			/*HANDLE*/ hEventPlayback: handle,                    /* Auto reset. Initialized to signaled. */
			/*HANDLE*/ hEventCapture: handle,                     /* Auto reset. Initialized to unsignaled. */
			actualPeriodSizeInFramesPlayback: u32,             /* Value from GetBufferSize(). internalPeriodSizeInFrames is not set to the _actual_ buffer size when low-latency shared mode is being used due to the way the IAudioClient3 API works. */
			actualPeriodSizeInFramesCapture: u32,
			originalPeriodSizeInFrames: u32,
			originalPeriodSizeInMilliseconds: u32,
			originalPeriods: u32,
			originalPerformanceProfile: performance_profile,
			periodSizeInFramesPlayback: u32,
			periodSizeInFramesCapture: u32,
			isStartedCapture: b32, /*atomic*/                   /* Can be read and written simultaneously across different threads. Must be used atomically, and must be 32-bit. */
			isStartedPlayback: b32, /*atomic*/                  /* Can be read and written simultaneously across different threads. Must be used atomically, and must be 32-bit. */
			noAutoConvertSRC: b8,                              /* When set to true, disables the use of AUDCLNT_STREAMFLAGS_AUTOCONVERTPCM. */
			noDefaultQualitySRC: b8,                           /* When set to true, disables the use of AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY. */
			noHardwareOffloading: b8,
			allowCaptureAutoStreamRouting: b8,
			allowPlaybackAutoStreamRouting: b8,
			isDetachedPlayback: b8,
			isDetachedCapture: b8,
		} when SUPPORT_WASAPI else struct {}),
		
		dsound: (struct {
			/*LPDIRECTSOUND*/ pPlayback: rawptr,
			/*LPDIRECTSOUNDBUFFER*/ pPlaybackPrimaryBuffer: rawptr,
			/*LPDIRECTSOUNDBUFFER*/ pPlaybackBuffer: rawptr,
			/*LPDIRECTSOUNDCAPTURE*/ pCapture: rawptr,
			/*LPDIRECTSOUNDCAPTUREBUFFER*/ pCaptureBuffer: rawptr,
		} when SUPPORT_DSOUND else struct {}),
		
		winmm: (struct {
			/*HWAVEOUT*/ hDevicePlayback: handle,
			/*HWAVEIN*/ hDeviceCapture: handle,
			/*HANDLE*/ hEventPlayback: handle,
			/*HANDLE*/ hEventCapture: handle,
			fragmentSizeInFrames: u32,
			iNextHeaderPlayback: u32,             /* [0,periods). Used as an index into pWAVEHDRPlayback. */
			iNextHeaderCapture: u32,              /* [0,periods). Used as an index into pWAVEHDRCapture. */
			headerFramesConsumedPlayback: u32,    /* The number of PCM frames consumed in the buffer in pWAVEHEADER[iNextHeader]. */
			headerFramesConsumedCapture: u32,     /* ^^^ */
			/*WAVEHDR**/ pWAVEHDRPlayback: [^]u8,   /* One instantiation for each period. */
			/*WAVEHDR**/ pWAVEHDRCapture:  [^]u8,    /* One instantiation for each period. */
			pIntermediaryBufferPlayback: [^]u8,
			pIntermediaryBufferCapture: [^]u8,
			_pHeapData: [^]u8,                      /* Used internally and is used for the heap allocated data for the intermediary buffer and the WAVEHDR structures. */
		} when SUPPORT_WINMM else struct {}),
		
		alsa: (struct {
			/*snd_pcm_t**/ pPCMPlayback: rawptr,
			/*snd_pcm_t**/ pPCMCapture: rawptr,
			/*struct pollfd**/ pPollDescriptorsPlayback: rawptr,
			/*struct pollfd**/ pPollDescriptorsCapture: rawptr,
			pollDescriptorCountPlayback: c.int,
			pollDescriptorCountCapture: c.int,
			wakeupfdPlayback: c.int,   /* eventfd for waking up from poll() when the playback device is stopped. */
			wakeupfdCapture: c.int,    /* eventfd for waking up from poll() when the capture device is stopped. */
			isUsingMMapPlayback: b8,
			isUsingMMapCapture: b8,
		} when SUPPORT_ALSA else struct {}),

		pulse: (struct {
			/*pa_stream**/ pStreamPlayback: rawptr,
			/*pa_stream**/ pStreamCapture: rawptr,
		} when SUPPORT_PULSEAUDIO else struct {}),
		
		jack: (struct {
			/*jack_client_t**/ pClient: rawptr,
			/*jack_port_t**/ pPortsPlayback: [MAX_CHANNELS]rawptr,
			/*jack_port_t**/ pPortsCapture:  [MAX_CHANNELS]rawptr,
			pIntermediaryBufferPlayback: [^]f32, /* Typed as a float because JACK is always floating point. */
			pIntermediaryBufferCapture: [^]f32,
		} when SUPPORT_JACK else struct {}),

		coreaudio: (struct {
			deviceObjectIDPlayback: u32,
			deviceObjectIDCapture: u32,
			/*AudioUnit*/ audioUnitPlayback: rawptr,
			/*AudioUnit*/ audioUnitCapture: rawptr,
			/*AudioBufferList**/ pAudioBufferList: rawptr,   /* Only used for input devices. */
			audioBufferCapInFrames: u32,               /* Only used for input devices. The capacity in frames of each buffer in pAudioBufferList. */
			stopEvent: event,
			originalPeriodSizeInFrames: u32,
			originalPeriodSizeInMilliseconds: u32,
			originalPeriods: u32,
			originalPerformanceProfile: performance_profile,
			isDefaultPlaybackDevice: b32,
			isDefaultCaptureDevice: b32,
			isSwitchingPlaybackDevice: b32,   /* <-- Set to true when the default device has changed and miniaudio is in the process of switching. */
			isSwitchingCaptureDevice: b32,    /* <-- Set to true when the default device has changed and miniaudio is in the process of switching. */
			pRouteChangeHandler: rawptr,             /* Only used on mobile platforms. Obj-C object for handling route changes. */
		} when SUPPORT_COREAUDIO else struct {}),
		sndio: (struct {
			handlePlayback: rawptr,
			handleCapture: rawptr,
			isStartedPlayback: b32,
			isStartedCapture: b32,
		} when SUPPORT_SNDIO else struct {}),

		audio4: (struct {
			fdPlayback: c.int,
			fdCapture: c.int,
		} when SUPPORT_AUDIO4 else struct {}),

		oss: (struct {
			fdPlayback: c.int,
			fdCapture: c.int,
		} when SUPPORT_OSS else struct {}),
		
		aaudio: (struct {
			/*AAudioStream**/ pStreamPlayback: rawptr,
			/*AAudioStream**/ pStreamCapture: rawptr,
		} when SUPPORT_AAUDIO else struct {}),

		opensl: (struct {
			/*SLObjectItf*/ pOutputMixObj: rawptr,
			/*SLOutputMixItf*/ pOutputMix: rawptr,
			/*SLObjectItf*/ pAudioPlayerObj: rawptr,
			/*SLPlayItf*/ pAudioPlayer: rawptr,
			/*SLObjectItf*/ pAudioRecorderObj: rawptr,
			/*SLRecordItf*/ pAudioRecorder: rawptr,
			/*SLAndroidSimpleBufferQueueItf*/ pBufferQueuePlayback: rawptr,
			/*SLAndroidSimpleBufferQueueItf*/ pBufferQueueCapture: rawptr,
			isDrainingCapture: b32,
			isDrainingPlayback: b32,
			currentBufferIndexPlayback: u32,
			currentBufferIndexCapture: u32,
			pBufferPlayback: [^]u8,      /* This is malloc()'d and is used for storing audio data. Typed as ma_uint8 for easy offsetting. */
			pBufferCapture: [^]u8,
		} when SUPPORT_OPENSL else struct {}),

		webaudio: (struct {
			indexPlayback: c.int,              /* We use a factory on the JavaScript side to manage devices and use an index for JS/C interop. */
			indexCapture: c.int,
		} when SUPPORT_WEBAUDIO else struct {}),

		null_device: (struct {
			deviceThread: thread,
			operationEvent: event,
			operationCompletionEvent: event,
			operationSemaphore: semaphore,
			operation: u32,
			operationResult: result,
			timer: timer,
			priorRunTime: f64,
			currentPeriodFramesRemainingPlayback: u32,
			currentPeriodFramesRemainingCapture: u32,
			lastProcessedFramePlayback: u64,
			lastProcessedFrameCapture: u64,
			sStarted: b32, /*atomic*/   /* Read and written by multiple threads. Must be used atomically, and must be 32-bit for compiler compatibility. */
		} when SUPPORT_NULL else struct {}),
	},
}


