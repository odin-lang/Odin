package miniaudio

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else {
	foreign import lib "lib/miniaudio.a"
}

import "core:c"

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	device_job_thread_config_init :: proc() -> device_job_thread_config ---

	device_job_thread_init   :: proc(pConfig: ^device_job_thread_config, pAllocationCallbacks: ^allocation_callbacks, pJobThread: ^device_job_thread) -> result ---
	device_job_thread_uninit :: proc(pJobThread: ^device_job_thread, pAllocationCallbacks: ^allocation_callbacks) ---
	device_job_thread_post   :: proc(pJobThread: ^device_job_thread, pJob: ^job) -> result ---
	device_job_thread_next   :: proc(pJobThread: ^device_job_thread, pJob: ^job) -> result ---
	
	/*
	Initializes a `ma_context_config` object.


	Return Value
	------------
	A `ma_context_config` initialized to defaults.


	Remarks
	-------
	You must always use this to initialize the default state of the `ma_context_config` object. Not using this will result in your program breaking when miniaudio
	is updated and new members are added to `ma_context_config`. It also sets logical defaults.

	You can override members of the returned object by changing it's members directly.


	See Also
	--------
	ma_context_init()
	*/
	context_config_init :: proc() -> context_config ---

	/*
	Initializes a context.

	The context is used for selecting and initializing an appropriate backend and to represent the backend at a more global level than that of an individual
	device. There is one context to many devices, and a device is created from a context. A context is required to enumerate devices.


	Parameters
	----------
	backends (in, optional)
			A list of backends to try initializing, in priority order. Can be NULL, in which case it uses default priority order.

	backendCount (in, optional)
			The number of items in `backend`. Ignored if `backend` is NULL.

	pConfig (in, optional)
			The context configuration.

	pContext (in)
			A pointer to the context object being initialized.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. Do not call this function across multiple threads as some backends read and write to global state.


	Remarks
	-------
	When `backends` is NULL, the default priority order will be used. Below is a list of backends in priority order:

			|-------------|-----------------------|--------------------------------------------------------|
			| Name        | Enum Name             | Supported Operating Systems                            |
			|-------------|-----------------------|--------------------------------------------------------|
			| WASAPI      | ma_backend_wasapi     | Windows Vista+                                         |
			| DirectSound | ma_backend_dsound     | Windows XP+                                            |
			| WinMM       | ma_backend_winmm      | Windows XP+ (may work on older versions, but untested) |
			| Core Audio  | ma_backend_coreaudio  | macOS, iOS                                             |
			| ALSA        | ma_backend_alsa       | Linux                                                  |
			| PulseAudio  | ma_backend_pulseaudio | Cross Platform (disabled on Windows, BSD and Android)  |
			| JACK        | ma_backend_jack       | Cross Platform (disabled on BSD and Android)           |
			| sndio       | ma_backend_sndio      | OpenBSD                                                |
			| audio(4)    | ma_backend_audio4     | NetBSD, OpenBSD                                        |
			| OSS         | ma_backend_oss        | FreeBSD                                                |
			| AAudio      | ma_backend_aaudio     | Android 8+                                             |
			| OpenSL|ES   | ma_backend_opensl     | Android (API level 16+)                                |
			| Web Audio   | ma_backend_webaudio   | Web (via Emscripten)                                   |
			| Null        | ma_backend_null       | Cross Platform (not used on Web)                       |
			|-------------|-----------------------|--------------------------------------------------------|

	The context can be configured via the `pConfig` argument. The config object is initialized with `ma_context_config_init()`. Individual configuration settings
	can then be set directly on the structure. Below are the members of the `ma_context_config` object.

			pLog
					A pointer to the `ma_log` to post log messages to. Can be NULL if the application does not
					require logging. See the `ma_log` API for details on how to use the logging system.

			threadPriority
					The desired priority to use for the audio thread. Allowable values include the following:

					|--------------------------------------|
					| Thread Priority                      |
					|--------------------------------------|
					| ma_thread_priority_idle              |
					| ma_thread_priority_lowest            |
					| ma_thread_priority_low               |
					| ma_thread_priority_normal            |
					| ma_thread_priority_high              |
					| ma_thread_priority_highest (default) |
					| ma_thread_priority_realtime          |
					| ma_thread_priority_default           |
					|--------------------------------------|

			threadStackSize
					The desired size of the stack for the audio thread. Defaults to the operating system's default.

			pUserData
					A pointer to application-defined data. This can be accessed from the context object directly such as `context.pUserData`.

			allocationCallbacks
					Structure containing custom allocation callbacks. Leaving this at defaults will cause it to use MA_MALLOC, MA_REALLOC and MA_FREE. These allocation
					callbacks will be used for anything tied to the context, including devices.

			alsa.useVerboseDeviceEnumeration
					ALSA will typically enumerate many different devices which can be intrusive and not user-friendly. To combat this, miniaudio will enumerate only unique
					card/device pairs by default. The problem with this is that you lose a bit of flexibility and control. Setting alsa.useVerboseDeviceEnumeration makes
					it so the ALSA backend includes all devices. Defaults to false.

			pulse.pApplicationName
					PulseAudio only. The application name to use when initializing the PulseAudio context with `pa_context_new()`.

			pulse.pServerName
					PulseAudio only. The name of the server to connect to with `pa_context_connect()`.

			pulse.tryAutoSpawn
					PulseAudio only. Whether or not to try automatically starting the PulseAudio daemon. Defaults to false. If you set this to true, keep in mind that
					miniaudio uses a trial and error method to find the most appropriate backend, and this will result in the PulseAudio daemon starting which may be
					intrusive for the end user.

			coreaudio.sessionCategory
					iOS only. The session category to use for the shared AudioSession instance. Below is a list of allowable values and their Core Audio equivalents.

					|-----------------------------------------|-------------------------------------|
					| miniaudio Token                         | Core Audio Token                    |
					|-----------------------------------------|-------------------------------------|
					| ma_ios_session_category_ambient         | AVAudioSessionCategoryAmbient       |
					| ma_ios_session_category_solo_ambient    | AVAudioSessionCategorySoloAmbient   |
					| ma_ios_session_category_playback        | AVAudioSessionCategoryPlayback      |
					| ma_ios_session_category_record          | AVAudioSessionCategoryRecord        |
					| ma_ios_session_category_play_and_record | AVAudioSessionCategoryPlayAndRecord |
					| ma_ios_session_category_multi_route     | AVAudioSessionCategoryMultiRoute    |
					| ma_ios_session_category_none            | AVAudioSessionCategoryAmbient       |
					| ma_ios_session_category_default         | AVAudioSessionCategoryAmbient       |
					|-----------------------------------------|-------------------------------------|

			coreaudio.sessionCategoryOptions
					iOS only. Session category options to use with the shared AudioSession instance. Below is a list of allowable values and their Core Audio equivalents.

					|---------------------------------------------------------------------------|------------------------------------------------------------------|
					| miniaudio Token                                                           | Core Audio Token                                                 |
					|---------------------------------------------------------------------------|------------------------------------------------------------------|
					| ma_ios_session_category_option_mix_with_others                            | AVAudioSessionCategoryOptionMixWithOthers                        |
					| ma_ios_session_category_option_duck_others                                | AVAudioSessionCategoryOptionDuckOthers                           |
					| ma_ios_session_category_option_allow_bluetooth                            | AVAudioSessionCategoryOptionAllowBluetooth                       |
					| ma_ios_session_category_option_default_to_speaker                         | AVAudioSessionCategoryOptionDefaultToSpeaker                     |
					| ma_ios_session_category_option_interrupt_spoken_audio_and_mix_with_others | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers |
					| ma_ios_session_category_option_allow_bluetooth_a2dp                       | AVAudioSessionCategoryOptionAllowBluetoothA2DP                   |
					| ma_ios_session_category_option_allow_air_play                             | AVAudioSessionCategoryOptionAllowAirPlay                         |
					|---------------------------------------------------------------------------|------------------------------------------------------------------|

			coreaudio.noAudioSessionActivate
					iOS only. When set to true, does not perform an explicit [[AVAudioSession sharedInstace] setActive:true] on initialization.

			coreaudio.noAudioSessionDeactivate
					iOS only. When set to true, does not perform an explicit [[AVAudioSession sharedInstace] setActive:false] on uninitialization.

			jack.pClientName
					The name of the client to pass to `jack_client_open()`.

			jack.tryStartServer
					Whether or not to try auto-starting the JACK server. Defaults to false.


	It is recommended that only a single context is active at any given time because it's a bulky data structure which performs run-time linking for the
	relevant backends every time it's initialized.

	The location of the context cannot change throughout it's lifetime. Consider allocating the `ma_context` object with `malloc()` if this is an issue. The
	reason for this is that a pointer to the context is stored in the `ma_device` structure.


	Example 1 - Default Initialization
	----------------------------------
	The example below shows how to initialize the context using the default configuration.

	```c
	ma_context context;
	ma_result result = ma_context_init(NULL, 0, NULL, &context);
	if (result != MA_SUCCESS) {
			// Error.
	}
	```


	Example 2 - Custom Configuration
	--------------------------------
	The example below shows how to initialize the context using custom backend priorities and a custom configuration. In this hypothetical example, the program
	wants to prioritize ALSA over PulseAudio on Linux. They also want to avoid using the WinMM backend on Windows because it's latency is too high. They also
	want an error to be returned if no valid backend is available which they achieve by excluding the Null backend.

	For the configuration, the program wants to capture any log messages so they can, for example, route it to a log file and user interface.

	```c
	ma_backend backends[] = {
			ma_backend_alsa,
			ma_backend_pulseaudio,
			ma_backend_wasapi,
			ma_backend_dsound
	};

	ma_log log;
	ma_log_init(&log);
	ma_log_register_callback(&log, ma_log_callback_init(my_log_callbac, pMyLogUserData));

	ma_context_config config = ma_context_config_init();
	config.pLog = &log; // Specify a custom log object in the config so any logs that are posted from ma_context_init() are captured.

	ma_context context;
	ma_result result = ma_context_init(backends, sizeof(backends)/sizeof(backends[0]), &config, &context);
	if (result != MA_SUCCESS) {
			// Error.
			if (result == MA_NO_BACKEND) {
					// Couldn't find an appropriate backend.
			}
	}

	// You could also attach a log callback post-initialization:
	ma_log_register_callback(ma_context_get_log(&context), ma_log_callback_init(my_log_callback, pMyLogUserData));
	```


	See Also
	--------
	ma_context_config_init()
	ma_context_uninit()
	*/
	context_init :: proc(backends: [^]backend, backendCount: u32, pConfig: ^context_config, pContext: ^context_type) -> result ---

	/*
	Uninitializes a context.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. Do not call this function across multiple threads as some backends read and write to global state.


	Remarks
	-------
	Results are undefined if you call this while any device created by this context is still active.


	See Also
	--------
	ma_context_init()
	*/
	context_uninit :: proc(pContext: ^context_type) -> result ---

	/*
	Retrieves the size of the ma_context object.

	This is mainly for the purpose of bindings to know how much memory to allocate.
	*/
	context_sizeof :: proc() -> c.size_t ---

	/*
	Retrieves a pointer to the log object associated with this context.


	Remarks
	-------
	Pass the returned pointer to `ma_log_post()`, `ma_log_postv()` or `ma_log_postf()` to post a log
	message.


	Return Value
	------------
	A pointer to the `ma_log` object that the context uses to post log messages. If some error occurs,
	NULL will be returned.
	*/
	context_get_log :: proc(pContext: ^context_type) -> log ---

	/*
	Enumerates over every device (both playback and capture).

	This is a lower-level enumeration function to the easier to use `ma_context_get_devices()`. Use `ma_context_enumerate_devices()` if you would rather not incur
	an internal heap allocation, or it simply suits your code better.

	Note that this only retrieves the ID and name/description of the device. The reason for only retrieving basic information is that it would otherwise require
	opening the backend device in order to probe it for more detailed information which can be inefficient. Consider using `ma_context_get_device_info()` for this,
	but don't call it from within the enumeration callback.

	Returning false from the callback will stop enumeration. Returning true will continue enumeration.


	Parameters
	----------
	pContext (in)
			A pointer to the context performing the enumeration.

	callback (in)
			The callback to fire for each enumerated device.

	pUserData (in)
			A pointer to application-defined data passed to the callback.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Safe. This is guarded using a simple mutex lock.


	Remarks
	-------
	Do _not_ assume the first enumerated device of a given type is the default device.

	Some backends and platforms may only support default playback and capture devices.

	In general, you should not do anything complicated from within the callback. In particular, do not try initializing a device from within the callback. Also,
	do not try to call `ma_context_get_device_info()` from within the callback.

	Consider using `ma_context_get_devices()` for a simpler and safer API, albeit at the expense of an internal heap allocation.


	Example 1 - Simple Enumeration
	------------------------------
	ma_bool32 ma_device_enum_callback(ma_context* pContext, ma_device_type deviceType, const ma_device_info* pInfo, void* pUserData)
	{
			printf("Device Name: %s\n", pInfo->name);
			return MA_TRUE;
	}

	ma_result result = ma_context_enumerate_devices(&context, my_device_enum_callback, pMyUserData);
	if (result != MA_SUCCESS) {
			// Error.
	}


	See Also
	--------
	ma_context_get_devices()
	*/
	context_enumerate_devices :: proc(pContext: ^context_type, callback: enum_devices_callback_proc, pUserData: rawptr) -> result ---

	/*
	Retrieves basic information about every active playback and/or capture device.

	This function will allocate memory internally for the device lists and return a pointer to them through the `ppPlaybackDeviceInfos` and `ppCaptureDeviceInfos`
	parameters. If you do not want to incur the overhead of these allocations consider using `ma_context_enumerate_devices()` which will instead use a callback.


	Parameters
	----------
	pContext (in)
			A pointer to the context performing the enumeration.

	ppPlaybackDeviceInfos (out)
			A pointer to a pointer that will receive the address of a buffer containing the list of `ma_device_info` structures for playback devices.

	pPlaybackDeviceCount (out)
			A pointer to an unsigned integer that will receive the number of playback devices.

	ppCaptureDeviceInfos (out)
			A pointer to a pointer that will receive the address of a buffer containing the list of `ma_device_info` structures for capture devices.

	pCaptureDeviceCount (out)
			A pointer to an unsigned integer that will receive the number of capture devices.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. Since each call to this function invalidates the pointers from the previous call, you should not be calling this simultaneously across multiple
	threads. Instead, you need to make a copy of the returned data with your own higher level synchronization.


	Remarks
	-------
	It is _not_ safe to assume the first device in the list is the default device.

	You can pass in NULL for the playback or capture lists in which case they'll be ignored.

	The returned pointers will become invalid upon the next call this this function, or when the context is uninitialized. Do not free the returned pointers.


	See Also
	--------
	ma_context_get_devices()
	*/
	context_get_devices :: proc(pContext: ^context_type, ppPlaybackDeviceInfos: ^[^]device_info, pPlaybackDeviceCount: ^u32, ppCaptureDeviceInfos: ^[^]device_info, pCaptureDeviceCount: ^u32) -> result ---

	/*
	Retrieves information about a device of the given type, with the specified ID and share mode.


	Parameters
	----------
	pContext (in)
			A pointer to the context performing the query.

	deviceType (in)
			The type of the device being queried. Must be either `ma_device_type_playback` or `ma_device_type_capture`.

	pDeviceID (in)
			The ID of the device being queried.

	pDeviceInfo (out)
			A pointer to the `ma_device_info` structure that will receive the device information.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Safe. This is guarded using a simple mutex lock.


	Remarks
	-------
	Do _not_ call this from within the `ma_context_enumerate_devices()` callback.

	It's possible for a device to have different information and capabilities depending on whether or not it's opened in shared or exclusive mode. For example, in
	shared mode, WASAPI always uses floating point samples for mixing, but in exclusive mode it can be anything. Therefore, this function allows you to specify
	which share mode you want information for. Note that not all backends and devices support shared or exclusive mode, in which case this function will fail if
	the requested share mode is unsupported.

	This leaves pDeviceInfo unmodified in the result of an error.
	*/
	context_get_device_info :: proc(pContext: ^context_type, deviceType: device_type, pDeviceID: ^device_id, pDeviceInfo: ^device_info) -> result ---

	/*
	Determines if the given context supports loopback mode.


	Parameters
	----------
	pContext (in)
	    A pointer to the context getting queried.


	Return Value
	------------
	MA_TRUE if the context supports loopback mode; MA_FALSE otherwise.
	*/
	context_is_loopback_supported :: proc(pContext: ^context_type) -> b32 ---



	/*
	Initializes a device config with default settings.


	Parameters
	----------
	deviceType (in)
			The type of the device this config is being initialized for. This must set to one of the following:

			|-------------------------|
			| Device Type             |
			|-------------------------|
			| ma_device_type_playback |
			| ma_device_type_capture  |
			| ma_device_type_duplex   |
			| ma_device_type_loopback |
			|-------------------------|


	Return Value
	------------
	A new device config object with default settings. You will typically want to adjust the config after this function returns. See remarks.


	Thread Safety
	-------------
	Safe.


	Callback Safety
	---------------
	Safe, but don't try initializing a device in a callback.


	Remarks
	-------
	The returned config will be initialized to defaults. You will normally want to customize a few variables before initializing the device. See Example 1 for a
	typical configuration which sets the sample format, channel count, sample rate, data callback and user data. These are usually things you will want to change
	before initializing the device.

	See `ma_device_init()` for details on specific configuration options.


	Example 1 - Simple Configuration
	--------------------------------
	The example below is what a program will typically want to configure for each device at a minimum. Notice how `ma_device_config_init()` is called first, and
	then the returned object is modified directly. This is important because it ensures that your program continues to work as new configuration options are added
	to the `ma_device_config` structure.

	```c
	ma_device_config config = ma_device_config_init(ma_device_type_playback);
	config.playback.format   = ma_format_f32;
	config.playback.channels = 2;
	config.sampleRate        = 48000;
	config.dataCallback      = ma_data_callback;
	config.pUserData         = pMyUserData;
	```


	See Also
	--------
	ma_device_init()
	ma_device_init_ex()
	*/
	device_config_init :: proc(deviceType: device_type) -> device_config ---


	/*
	Initializes a device.

	A device represents a physical audio device. The idea is you send or receive audio data from the device to either play it back through a speaker, or capture it
	from a microphone. Whether or not you should send or receive data from the device (or both) depends on the type of device you are initializing which can be
	playback, capture, full-duplex or loopback. (Note that loopback mode is only supported on select backends.) Sending and receiving audio data to and from the
	device is done via a callback which is fired by miniaudio at periodic time intervals.

	The frequency at which data is delivered to and from a device depends on the size of it's period. The size of the period can be defined in terms of PCM frames
	or milliseconds, whichever is more convenient. Generally speaking, the smaller the period, the lower the latency at the expense of higher CPU usage and
	increased risk of glitching due to the more frequent and granular data deliver intervals. The size of a period will depend on your requirements, but
	miniaudio's defaults should work fine for most scenarios. If you're building a game you should leave this fairly small, whereas if you're building a simple
	media player you can make it larger. Note that the period size you request is actually just a hint - miniaudio will tell the backend what you want, but the
	backend is ultimately responsible for what it gives you. You cannot assume you will get exactly what you ask for.

	When delivering data to and from a device you need to make sure it's in the correct format which you can set through the device configuration. You just set the
	format that you want to use and miniaudio will perform all of the necessary conversion for you internally. When delivering data to and from the callback you
	can assume the format is the same as what you requested when you initialized the device. See Remarks for more details on miniaudio's data conversion pipeline.


	Parameters
	----------
	pContext (in, optional)
			A pointer to the context that owns the device. This can be null, in which case it creates a default context internally.

	pConfig (in)
			A pointer to the device configuration. Cannot be null. See remarks for details.

	pDevice (out)
			A pointer to the device object being initialized.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. It is not safe to call this function simultaneously for different devices because some backends depend on and mutate global state. The same applies to
	calling this at the same time as `ma_device_uninit()`.


	Callback Safety
	---------------
	Unsafe. It is not safe to call this inside any callback.


	Remarks
	-------
	Setting `pContext` to NULL will result in miniaudio creating a default context internally and is equivalent to passing in a context initialized like so:

			```c
			ma_context_init(NULL, 0, NULL, &context);
			```

	Do not set `pContext` to NULL if you are needing to open multiple devices. You can, however, use NULL when initializing the first device, and then use
	device.pContext for the initialization of other devices.

	The device can be configured via the `pConfig` argument. The config object is initialized with `ma_device_config_init()`. Individual configuration settings can
	then be set directly on the structure. Below are the members of the `ma_device_config` object.

			deviceType
					Must be `ma_device_type_playback`, `ma_device_type_capture`, `ma_device_type_duplex` of `ma_device_type_loopback`.

			sampleRate
					The sample rate, in hertz. The most common sample rates are 48000 and 44100. Setting this to 0 will use the device's native sample rate.

			periodSizeInFrames
					The desired size of a period in PCM frames. If this is 0, `periodSizeInMilliseconds` will be used instead. If both are 0 the default buffer size will
					be used depending on the selected performance profile. This value affects latency. See below for details.

			periodSizeInMilliseconds
					The desired size of a period in milliseconds. If this is 0, `periodSizeInFrames` will be used instead. If both are 0 the default buffer size will be
					used depending on the selected performance profile. The value affects latency. See below for details.

			periods
					The number of periods making up the device's entire buffer. The total buffer size is `periodSizeInFrames` or `periodSizeInMilliseconds` multiplied by
					this value. This is just a hint as backends will be the ones who ultimately decide how your periods will be configured.

			performanceProfile
					A hint to miniaudio as to the performance requirements of your program. Can be either `ma_performance_profile_low_latency` (default) or
					`ma_performance_profile_conservative`. This mainly affects the size of default buffers and can usually be left at it's default value.

			noPreSilencedOutputBuffer
					When set to true, the contents of the output buffer passed into the data callback will be left undefined. When set to false (default), the contents of
					the output buffer will be cleared the zero. You can use this to avoid the overhead of zeroing out the buffer if you can guarantee that your data
					callback will write to every sample in the output buffer, or if you are doing your own clearing.

			noClip
        			When set to true, the contents of the output buffer are left alone after returning and it will be left up to the backend itself to decide whether or
        			not to clip. When set to false (default), the contents of the output buffer passed into the data callback will be clipped after returning. This only
					applies when the playback sample format is f32.

			noDisableDenormals
					By default, miniaudio will disable denormals when the data callback is called. Setting this to true will prevent the disabling of denormals.

			noFixedSizedCallback
        			Allows miniaudio to fire the data callback with any frame count. When this is set to false (the default), the data callback will be fired with a
        			consistent frame count as specified by `periodSizeInFrames` or `periodSizeInMilliseconds`. When set to true, miniaudio will fire the callback with
        			whatever the backend requests, which could be anything.

			dataCallback
					The callback to fire whenever data is ready to be delivered to or from the device.

			notificationCallback
					The callback to fire when something has changed with the device, such as whether or not it has been started or stopped.

			pUserData
					The user data pointer to use with the device. You can access this directly from the device object like `device.pUserData`.

			resampling.algorithm
					The resampling algorithm to use when miniaudio needs to perform resampling between the rate specified by `sampleRate` and the device's native rate. The
					default value is `ma_resample_algorithm_linear`, and the quality can be configured with `resampling.linear.lpfOrder`.

			resampling.pBackendVTable
					A pointer to an optional vtable that can be used for plugging in a custom resampler.

			resampling.pBackendUserData
					A pointer that will passed to callbacks in pBackendVTable.

			resampling.linear.lpfOrder
					The linear resampler applies a low-pass filter as part of it's processing for anti-aliasing. This setting controls the order of the filter. The higher
					the value, the better the quality, in general. Setting this to 0 will disable low-pass filtering altogether. The maximum value is
					`MA_MAX_FILTER_ORDER`. The default value is `min(4, MA_MAX_FILTER_ORDER)`.

			playback.pDeviceID
					A pointer to a `ma_device_id` structure containing the ID of the playback device to initialize. Setting this NULL (default) will use the system's
					default playback device. Retrieve the device ID from the `ma_device_info` structure, which can be retrieved using device enumeration.

			playback.format
					The sample format to use for playback. When set to `ma_format_unknown` the device's native format will be used. This can be retrieved after
					initialization from the device object directly with `device.playback.format`.

			playback.channels
					The number of channels to use for playback. When set to 0 the device's native channel count will be used. This can be retrieved after initialization
					from the device object directly with `device.playback.channels`.

			playback.pChannelMap
					The channel map to use for playback. When left empty, the device's native channel map will be used. This can be retrieved after initialization from the
					device object direct with `device.playback.pChannelMap`. When set, the buffer should contain `channels` items.

			playback.shareMode
					The preferred share mode to use for playback. Can be either `ma_share_mode_shared` (default) or `ma_share_mode_exclusive`. Note that if you specify
					exclusive mode, but it's not supported by the backend, initialization will fail. You can then fall back to shared mode if desired by changing this to
					ma_share_mode_shared and reinitializing.

			capture.pDeviceID
					A pointer to a `ma_device_id` structure containing the ID of the capture device to initialize. Setting this NULL (default) will use the system's
					default capture device. Retrieve the device ID from the `ma_device_info` structure, which can be retrieved using device enumeration.

			capture.format
					The sample format to use for capture. When set to `ma_format_unknown` the device's native format will be used. This can be retrieved after
					initialization from the device object directly with `device.capture.format`.

			capture.channels
					The number of channels to use for capture. When set to 0 the device's native channel count will be used. This can be retrieved after initialization
					from the device object directly with `device.capture.channels`.

			capture.pChannelMap
					The channel map to use for capture. When left empty, the device's native channel map will be used. This can be retrieved after initialization from the
					device object direct with `device.capture.pChannelMap`. When set, the buffer should contain `channels` items.

			capture.shareMode
					The preferred share mode to use for capture. Can be either `ma_share_mode_shared` (default) or `ma_share_mode_exclusive`. Note that if you specify
					exclusive mode, but it's not supported by the backend, initialization will fail. You can then fall back to shared mode if desired by changing this to
					ma_share_mode_shared and reinitializing.

			wasapi.noAutoConvertSRC
					WASAPI only. When set to true, disables WASAPI's automatic resampling and forces the use of miniaudio's resampler. Defaults to false.

			wasapi.noDefaultQualitySRC
					WASAPI only. Only used when `wasapi.noAutoConvertSRC` is set to false. When set to true, disables the use of `AUDCLNT_STREAMFLAGS_SRC_DEFAULT_QUALITY`.
					You should usually leave this set to false, which is the default.

			wasapi.noAutoStreamRouting
					WASAPI only. When set to true, disables automatic stream routing on the WASAPI backend. Defaults to false.

			wasapi.noHardwareOffloading
					WASAPI only. When set to true, disables the use of WASAPI's hardware offloading feature. Defaults to false.

			alsa.noMMap
					ALSA only. When set to true, disables MMap mode. Defaults to false.

			alsa.noAutoFormat
					ALSA only. When set to true, disables ALSA's automatic format conversion by including the SND_PCM_NO_AUTO_FORMAT flag. Defaults to false.

			alsa.noAutoChannels
					ALSA only. When set to true, disables ALSA's automatic channel conversion by including the SND_PCM_NO_AUTO_CHANNELS flag. Defaults to false.

			alsa.noAutoResample
					ALSA only. When set to true, disables ALSA's automatic resampling by including the SND_PCM_NO_AUTO_RESAMPLE flag. Defaults to false.

			pulse.pStreamNamePlayback
					PulseAudio only. Sets the stream name for playback.

			pulse.pStreamNameCapture
					PulseAudio only. Sets the stream name for capture.

			coreaudio.allowNominalSampleRateChange
					Core Audio only. Desktop only. When enabled, allows the sample rate of the device to be changed at the operating system level. This
					is disabled by default in order to prevent intrusive changes to the user's system. This is useful if you want to use a sample rate
					that is known to be natively supported by the hardware thereby avoiding the cost of resampling. When set to true, miniaudio will
					find the closest match between the sample rate requested in the device config and the sample rates natively supported by the
					hardware. When set to false, the sample rate currently set by the operating system will always be used.

			opensl.streamType
					OpenSL only. Explicitly sets the stream type. If left unset (`ma_opensl_stream_type_default`), the
					stream type will be left unset. Think of this as the type of audio you're playing.

			opensl.recordingPreset
					OpenSL only. Explicitly sets the type of recording your program will be doing. When left
					unset, the recording preset will be left unchanged.

			aaudio.usage
					AAudio only. Explicitly sets the nature of the audio the program will be consuming. When
					left unset, the usage will be left unchanged.

			aaudio.contentType
					AAudio only. Sets the content type. When left unset, the content type will be left unchanged.

			aaudio.inputPreset
					AAudio only. Explicitly sets the type of recording your program will be doing. When left
					unset, the input preset will be left unchanged.

			aaudio.noAutoStartAfterReroute
					AAudio only. Controls whether or not the device should be automatically restarted after a
					stream reroute. When set to false (default) the device will be restarted automatically;
					otherwise the device will be stopped.


	Once initialized, the device's config is immutable. If you need to change the config you will need to initialize a new device.

	After initializing the device it will be in a stopped state. To start it, use `ma_device_start()`.

	If both `periodSizeInFrames` and `periodSizeInMilliseconds` are set to zero, it will default to `MA_DEFAULT_PERIOD_SIZE_IN_MILLISECONDS_LOW_LATENCY` or
	`MA_DEFAULT_PERIOD_SIZE_IN_MILLISECONDS_CONSERVATIVE`, depending on whether or not `performanceProfile` is set to `ma_performance_profile_low_latency` or
	`ma_performance_profile_conservative`.

	If you request exclusive mode and the backend does not support it an error will be returned. For robustness, you may want to first try initializing the device
	in exclusive mode, and then fall back to shared mode if required. Alternatively you can just request shared mode (the default if you leave it unset in the
	config) which is the most reliable option. Some backends do not have a practical way of choosing whether or not the device should be exclusive or not (ALSA,
	for example) in which case it just acts as a hint. Unless you have special requirements you should try avoiding exclusive mode as it's intrusive to the user.
	Starting with Windows 10, miniaudio will use low-latency shared mode where possible which may make exclusive mode unnecessary.

	When sending or receiving data to/from a device, miniaudio will internally perform a format conversion to convert between the format specified by the config
	and the format used internally by the backend. If you pass in 0 for the sample format, channel count, sample rate _and_ channel map, data transmission will run
	on an optimized pass-through fast path. You can retrieve the format, channel count and sample rate by inspecting the `playback/capture.format`,
	`playback/capture.channels` and `sampleRate` members of the device object.

	When compiling for UWP you must ensure you call this function on the main UI thread because the operating system may need to present the user with a message
	asking for permissions. Please refer to the official documentation for ActivateAudioInterfaceAsync() for more information.

	ALSA Specific: When initializing the default device, requesting shared mode will try using the "dmix" device for playback and the "dsnoop" device for capture.
	If these fail it will try falling back to the "hw" device.


	Example 1 - Simple Initialization
	---------------------------------
	This example shows how to initialize a simple playback device using a standard configuration. If you are just needing to do simple playback from the default
	playback device this is usually all you need.

	```c
	ma_device_config config = ma_device_config_init(ma_device_type_playback);
	config.playback.format   = ma_format_f32;
	config.playback.channels = 2;
	config.sampleRate        = 48000;
	config.dataCallback      = ma_data_callback;
	config.pMyUserData       = pMyUserData;

	ma_device device;
	ma_result result = ma_device_init(NULL, &config, &device);
	if (result != MA_SUCCESS) {
			// Error
	}
	```


	Example 2 - Advanced Initialization
	-----------------------------------
	This example shows how you might do some more advanced initialization. In this hypothetical example we want to control the latency by setting the buffer size
	and period count. We also want to allow the user to be able to choose which device to output from which means we need a context so we can perform device
	enumeration.

	```c
	ma_context context;
	ma_result result = ma_context_init(NULL, 0, NULL, &context);
	if (result != MA_SUCCESS) {
			// Error
	}

	ma_device_info* pPlaybackDeviceInfos;
	ma_uint32 playbackDeviceCount;
	result = ma_context_get_devices(&context, &pPlaybackDeviceInfos, &playbackDeviceCount, NULL, NULL);
	if (result != MA_SUCCESS) {
			// Error
	}

	// ... choose a device from pPlaybackDeviceInfos ...

	ma_device_config config = ma_device_config_init(ma_device_type_playback);
	config.playback.pDeviceID       = pMyChosenDeviceID;    // <-- Get this from the `id` member of one of the `ma_device_info` objects returned by ma_context_get_devices().
	config.playback.format          = ma_format_f32;
	config.playback.channels        = 2;
	config.sampleRate               = 48000;
	config.dataCallback             = ma_data_callback;
	config.pUserData                = pMyUserData;
	config.periodSizeInMilliseconds = 10;
	config.periods                  = 3;

	ma_device device;
	result = ma_device_init(&context, &config, &device);
	if (result != MA_SUCCESS) {
			// Error
	}
	```


	See Also
	--------
	ma_device_config_init()
	ma_device_uninit()
	ma_device_start()
	ma_context_init()
	ma_context_get_devices()
	ma_context_enumerate_devices()
	*/
	device_init :: proc(pContext: ^context_type, pConfig: ^device_config, pDevice: ^device) -> result ---

	/*
	Initializes a device without a context, with extra parameters for controlling the configuration of the internal self-managed context.

	This is the same as `ma_device_init()`, only instead of a context being passed in, the parameters from `ma_context_init()` are passed in instead. This function
	allows you to configure the internally created context.


	Parameters
	----------
	backends (in, optional)
			A list of backends to try initializing, in priority order. Can be NULL, in which case it uses default priority order.

	backendCount (in, optional)
			The number of items in `backend`. Ignored if `backend` is NULL.

	pContextConfig (in, optional)
			The context configuration.

	pConfig (in)
			A pointer to the device configuration. Cannot be null. See remarks for details.

	pDevice (out)
			A pointer to the device object being initialized.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. It is not safe to call this function simultaneously for different devices because some backends depend on and mutate global state. The same applies to
	calling this at the same time as `ma_device_uninit()`.


	Callback Safety
	---------------
	Unsafe. It is not safe to call this inside any callback.


	Remarks
	-------
	You only need to use this function if you want to configure the context differently to it's defaults. You should never use this function if you want to manage
	your own context.

	See the documentation for `ma_context_init()` for information on the different context configuration options.


	See Also
	--------
	ma_device_init()
	ma_device_uninit()
	ma_device_config_init()
	ma_context_init()
	*/
	device_init_ex :: proc(backends: [^]backend, backendCount: u32, pContextConfig: ^context_config, pConfig: ^device_config, pDevice: ^device) -> result ---

	/*
	Uninitializes a device.

	This will explicitly stop the device. You do not need to call `ma_device_stop()` beforehand, but it's harmless if you do.


	Parameters
	----------
	pDevice (in)
			A pointer to the device to stop.


	Return Value
	------------
	Nothing


	Thread Safety
	-------------
	Unsafe. As soon as this API is called the device should be considered undefined.


	Callback Safety
	---------------
	Unsafe. It is not safe to call this inside any callback. Doing this will result in a deadlock.


	See Also
	--------
	ma_device_init()
	ma_device_stop()
	*/
	device_uninit :: proc(pDevice: ^device) ---


	/*
	Retrieves a pointer to the context that owns the given device.
	*/
	device_get_context :: proc(pDevice: ^device) -> ^context_type ---

	/*
	Helper function for retrieving the log object associated with the context that owns this device.
	*/
	device_get_log :: proc(pDevice: ^device) -> ^log ---


	/*
	Retrieves information about the device.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose information is being retrieved.

	type (in)
			The device type. This parameter is required for duplex devices. When retrieving device
			information, you are doing so for an individual playback or capture device.

	pDeviceInfo (out)
			A pointer to the `ma_device_info` that will receive the device information.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. This should be considered unsafe because it may be calling into the backend which may or
	may not be safe.


	Callback Safety
	---------------
	Unsafe. You should avoid calling this in the data callback because it may call into the backend
	which may or may not be safe.
	*/
	device_get_info :: proc(pDevice: ^device, type: device_type, pDeviceInfo: ^device_info) -> result ---


	/*
	Retrieves the name of the device.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose information is being retrieved.

	type (in)
			The device type. This parameter is required for duplex devices. When retrieving device
			information, you are doing so for an individual playback or capture device.

	pName (out)
			A pointer to the buffer that will receive the name.

	nameCap (in)
			The capacity of the output buffer, including space for the null terminator.

	pLengthNotIncludingNullTerminator (out, optional)
			A pointer to the variable that will receive the length of the name, not including the null
			terminator.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Unsafe. This should be considered unsafe because it may be calling into the backend which may or
	may not be safe.


	Callback Safety
	---------------
	Unsafe. You should avoid calling this in the data callback because it may call into the backend
	which may or may not be safe.


	Remarks
	-------
	If the name does not fully fit into the output buffer, it'll be truncated. You can pass in NULL to
	`pName` if you want to first get the length of the name for the purpose of memory allocation of the
	output buffer. Allocating a buffer of size `MA_MAX_DEVICE_NAME_LENGTH + 1` should be enough for
	most cases and will avoid the need for the inefficiency of calling this function twice.

	This is implemented in terms of `ma_device_get_info()`.
	*/
	device_get_name :: proc(pDevice: ^device, type: device_type, pName: [^]c.char, nameCap: c.size_t, pLengthNotIncludingNullTerminator: ^c.size_t) -> result ---


	/*
	Starts the device. For playback devices this begins playback. For capture devices it begins recording.

	Use `ma_device_stop()` to stop the device.


	Parameters
	----------
	pDevice (in)
			A pointer to the device to start.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Safe. It's safe to call this from any thread with the exception of the callback thread.


	Callback Safety
	---------------
	Unsafe. It is not safe to call this inside any callback.


	Remarks
	-------
	For a playback device, this will retrieve an initial chunk of audio data from the client before returning. The reason for this is to ensure there is valid
	audio data in the buffer, which needs to be done before the device begins playback.

	This API waits until the backend device has been started for real by the worker thread. It also waits on a mutex for thread-safety.

	Do not call this in any callback.


	See Also
	--------
	ma_device_stop()
	*/
	device_start :: proc(pDevice: ^device) -> result ---

	/*
	Stops the device. For playback devices this stops playback. For capture devices it stops recording.

	Use `ma_device_start()` to start the device again.


	Parameters
	----------
	pDevice (in)
			A pointer to the device to stop.


	Return Value
	------------
	MA_SUCCESS if successful; any other error code otherwise.


	Thread Safety
	-------------
	Safe. It's safe to call this from any thread with the exception of the callback thread.


	Callback Safety
	---------------
	Unsafe. It is not safe to call this inside any callback. Doing this will result in a deadlock.


	Remarks
	-------
	This API needs to wait on the worker thread to stop the backend device properly before returning. It also waits on a mutex for thread-safety. In addition, some
	backends need to wait for the device to finish playback/recording of the current fragment which can take some time (usually proportionate to the buffer size
	that was specified at initialization time).

	Backends are required to either pause the stream in-place or drain the buffer if pausing is not possible. The reason for this is that stopping the device and
	the resuming it with ma_device_start() (which you might do when your program loses focus) may result in a situation where those samples are never output to the
	speakers or received from the microphone which can in turn result in de-syncs.

	Do not call this in any callback.


	See Also
	--------
	ma_device_start()
	*/
	device_stop :: proc(pDevice: ^device) -> result ---

	/*
	Determines whether or not the device is started.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose start state is being retrieved.


	Return Value
	------------
	True if the device is started, false otherwise.


	Thread Safety
	-------------
	Safe. If another thread calls `ma_device_start()` or `ma_device_stop()` at this same time as this function is called, there's a very small chance the return
	value will be out of sync.


	Callback Safety
	---------------
	Safe. This is implemented as a simple accessor.


	See Also
	--------
	ma_device_start()
	ma_device_stop()
	*/
	device_is_started :: proc(pDevice: ^device) -> b32 ---


	/*
	Retrieves the state of the device.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose state is being retrieved.


	Return Value
	------------
	The current state of the device. The return value will be one of the following:

			+-------------------------------+------------------------------------------------------------------------------+
			| ma_device_state_uninitialized | Will only be returned if the device is in the middle of initialization.      |
			+-------------------------------+------------------------------------------------------------------------------+
			| ma_device_state_stopped       | The device is stopped. The initial state of the device after initialization. |
			+-------------------------------+------------------------------------------------------------------------------+
			| ma_device_state_started       | The device started and requesting and/or delivering audio data.              |
			+-------------------------------+------------------------------------------------------------------------------+
			| ma_device_state_starting      | The device is in the process of starting.                                    |
			+-------------------------------+------------------------------------------------------------------------------+
			| ma_device_state_stopping      | The device is in the process of stopping.                                    |
			+-------------------------------+------------------------------------------------------------------------------+


	Thread Safety
	-------------
	Safe. This is implemented as a simple accessor. Note that if the device is started or stopped at the same time as this function is called,
	there's a possibility the return value could be out of sync. See remarks.


	Callback Safety
	---------------
	Safe. This is implemented as a simple accessor.


	Remarks
	-------
	The general flow of a devices state goes like this:

			```
			ma_device_init()  -> ma_device_state_uninitialized -> ma_device_state_stopped
			ma_device_start() -> ma_device_state_starting      -> ma_device_state_started
			ma_device_stop()  -> ma_device_state_stopping      -> ma_device_state_stopped
			```

	When the state of the device is changed with `ma_device_start()` or `ma_device_stop()` at this same time as this function is called, the
	value returned by this function could potentially be out of sync. If this is significant to your program you need to implement your own
	synchronization.
	*/
	device_get_state :: proc(pDevice: ^device) -> device_state ---


	/*
	Performs post backend initialization routines for setting up internal data conversion.

	This should be called whenever the backend is initialized. The only time this should be called from
	outside of miniaudio is if you're implementing a custom backend, and you would only do it if you
	are reinitializing the backend due to rerouting or reinitializing for some reason.


	Parameters
	----------
	pDevice [in]
			A pointer to the device.

	deviceType [in]
			The type of the device that was just reinitialized.

	pPlaybackDescriptor [in]
			The descriptor of the playback device containing the internal data format and buffer sizes.

	pPlaybackDescriptor [in]
			The descriptor of the capture device containing the internal data format and buffer sizes.


	Return Value
	------------
	MA_SUCCESS if successful; any other error otherwise.


	Thread Safety
	-------------
	Unsafe. This will be reinitializing internal data converters which may be in use by another thread.


	Callback Safety
	---------------
	Unsafe. This will be reinitializing internal data converters which may be in use by the callback.


	Remarks
	-------
	For a duplex device, you can call this for only one side of the system. This is why the deviceType
	is specified as a parameter rather than deriving it from the device.

	You do not need to call this manually unless you are doing a custom backend, in which case you need
	only do it if you're manually performing rerouting or reinitialization.
	*/
	device_post_init :: proc(pDevice: ^device, deviceType: device_type, pPlaybackDescriptor, pCaptureDescriptor: ^device_descriptor) -> result ---


	/*
	Sets the master volume factor for the device.

	The volume factor must be between 0 (silence) and 1 (full volume). Use `ma_device_set_master_volume_db()` to use decibel notation, where 0 is full volume and
	values less than 0 decreases the volume.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose volume is being set.

	volume (in)
			The new volume factor. Must be >= 0.


	Return Value
	------------
	MA_SUCCESS if the volume was set successfully.
	MA_INVALID_ARGS if pDevice is NULL.
	MA_INVALID_ARGS if volume is negative.


	Thread Safety
	-------------
	Safe. This just sets a local member of the device object.


	Callback Safety
	---------------
	Safe. If you set the volume in the data callback, that data written to the output buffer will have the new volume applied.


	Remarks
	-------
	This applies the volume factor across all channels.

	This does not change the operating system's volume. It only affects the volume for the given `ma_device` object's audio stream.


	See Also
	--------
	ma_device_get_master_volume()
	ma_device_set_master_volume_db()
	ma_device_get_master_volume_db()
	*/
	device_set_master_volume :: proc(pDevice: ^device, volume: f32) -> result ---

	/*
	Retrieves the master volume factor for the device.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose volume factor is being retrieved.

	pVolume (in)
			A pointer to the variable that will receive the volume factor. The returned value will be in the range of [0, 1].


	Return Value
	------------
	MA_SUCCESS if successful.
	MA_INVALID_ARGS if pDevice is NULL.
	MA_INVALID_ARGS if pVolume is NULL.


	Thread Safety
	-------------
	Safe. This just a simple member retrieval.


	Callback Safety
	---------------
	Safe.


	Remarks
	-------
	If an error occurs, `*pVolume` will be set to 0.


	See Also
	--------
	ma_device_set_master_volume()
	ma_device_set_master_volume_gain_db()
	ma_device_get_master_volume_gain_db()
	*/
	device_get_master_volume :: proc(pDevice: ^device, pVolume: ^f32) -> result ---

	/*
	Sets the master volume for the device as gain in decibels.

	A gain of 0 is full volume, whereas a gain of < 0 will decrease the volume.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose gain is being set.

	gainDB (in)
			The new volume as gain in decibels. Must be less than or equal to 0, where 0 is full volume and anything less than 0 decreases the volume.


	Return Value
	------------
	MA_SUCCESS if the volume was set successfully.
	MA_INVALID_ARGS if pDevice is NULL.
	MA_INVALID_ARGS if the gain is > 0.


	Thread Safety
	-------------
	Safe. This just sets a local member of the device object.


	Callback Safety
	---------------
	Safe. If you set the volume in the data callback, that data written to the output buffer will have the new volume applied.


	Remarks
	-------
	This applies the gain across all channels.

	This does not change the operating system's volume. It only affects the volume for the given `ma_device` object's audio stream.


	See Also
	--------
	ma_device_get_master_volume_gain_db()
	ma_device_set_master_volume()
	ma_device_get_master_volume()
	*/
	device_set_master_volume_db :: proc(pDevice: ^device, gainDB: f32) -> result ---

	/*
	Retrieves the master gain in decibels.


	Parameters
	----------
	pDevice (in)
			A pointer to the device whose gain is being retrieved.

	pGainDB (in)
			A pointer to the variable that will receive the gain in decibels. The returned value will be <= 0.


	Return Value
	------------
	MA_SUCCESS if successful.
	MA_INVALID_ARGS if pDevice is NULL.
	MA_INVALID_ARGS if pGainDB is NULL.


	Thread Safety
	-------------
	Safe. This just a simple member retrieval.


	Callback Safety
	---------------
	Safe.


	Remarks
	-------
	If an error occurs, `*pGainDB` will be set to 0.


	See Also
	--------
	ma_device_set_master_volume_db()
	ma_device_set_master_volume()
	ma_device_get_master_volume()
	*/
	device_get_master_volume_db :: proc(pDevice: ^device, pGainDB: ^f32) -> result ---


	/*
	Called from the data callback of asynchronous backends to allow miniaudio to process the data and fire the miniaudio data callback.


	Parameters
	----------
	pDevice (in)
			A pointer to device whose processing the data callback.

	pOutput (out)
			A pointer to the buffer that will receive the output PCM frame data. On a playback device this must not be NULL. On a duplex device
			this can be NULL, in which case pInput must not be NULL.

	pInput (in)
			A pointer to the buffer containing input PCM frame data. On a capture device this must not be NULL. On a duplex device this can be
			NULL, in which case `pOutput` must not be NULL.

	frameCount (in)
			The number of frames being processed.


	Return Value
	------------
	MA_SUCCESS if successful; any other result code otherwise.


	Thread Safety
	-------------
	This function should only ever be called from the internal data callback of the backend. It is safe to call this simultaneously between a
	playback and capture device in duplex setups.


	Callback Safety
	---------------
	Do not call this from the miniaudio data callback. It should only ever be called from the internal data callback of the backend.


	Remarks
	-------
	If both `pOutput` and `pInput` are NULL, and error will be returned. In duplex scenarios, both `pOutput` and `pInput` can be non-NULL, in
	which case `pInput` will be processed first, followed by `pOutput`.

	If you are implementing a custom backend, and that backend uses a callback for data delivery, you'll need to call this from inside that
	callback.
	*/
	device_handle_backend_data_callback :: proc(pDevice: ^device, pOutput, pInput: rawptr, frameCount: u32) -> result ---


	/*
	Calculates an appropriate buffer size from a descriptor, native sample rate and performance profile.

	This function is used by backends for helping determine an appropriately sized buffer to use with
	the device depending on the values of `periodSizeInFrames` and `periodSizeInMilliseconds` in the
	`pDescriptor` object. Since buffer size calculations based on time depends on the sample rate, a
	best guess at the device's native sample rate is also required which is where `nativeSampleRate`
	comes in. In addition, the performance profile is also needed for cases where both the period size
	in frames and milliseconds are both zero.


	Parameters
	----------
	pDescriptor (in)
			A pointer to device descriptor whose `periodSizeInFrames` and `periodSizeInMilliseconds` members
			will be used for the calculation of the buffer size.

	nativeSampleRate (in)
			The device's native sample rate. This is only ever used when the `periodSizeInFrames` member of
			`pDescriptor` is zero. In this case, `periodSizeInMilliseconds` will be used instead, in which
			case a sample rate is required to convert to a size in frames.

	performanceProfile (in)
			When both the `periodSizeInFrames` and `periodSizeInMilliseconds` members of `pDescriptor` are
			zero, miniaudio will fall back to a buffer size based on the performance profile. The profile
			to use for this calculation is determine by this parameter.


	Return Value
	------------
	The calculated buffer size in frames.


	Thread Safety
	-------------
	This is safe so long as nothing modifies `pDescriptor` at the same time. However, this function
	should only ever be called from within the backend's device initialization routine and therefore
	shouldn't have any multithreading concerns.


	Callback Safety
	---------------
	This is safe to call within the data callback, but there is no reason to ever do this.


	Remarks
	-------
	If `nativeSampleRate` is zero, this function will fall back to `pDescriptor->sampleRate`. If that
	is also zero, `MA_DEFAULT_SAMPLE_RATE` will be used instead.
	*/
	calculate_buffer_size_in_frames_from_descriptor :: proc(pDescriptor: ^device_descriptor, nativeSampleRate: u32, performanceProfile: performance_profile) -> u32 ---



	/*
	Retrieves a friendly name for a backend.
	*/
	get_backend_name :: proc(backend: backend) -> cstring ---

	/*
	Retrieves the backend enum from the given name.
	*/
	get_backend_from_name :: proc(pBackendName: cstring, pBackend: ^backend) -> result ---

	/*
	Determines whether or not the given backend is available by the compilation environment.
	*/
	is_backend_enabled :: proc(backend: backend) -> b32 ---

	/*
	Retrieves compile-time enabled backends.


	Parameters
	----------
	pBackends (out, optional)
			A pointer to the buffer that will receive the enabled backends. Set to NULL to retrieve the backend count. Setting
			the capacity of the buffer to `MA_BUFFER_COUNT` will guarantee it's large enough for all backends.

	backendCap (in)
			The capacity of the `pBackends` buffer.

	pBackendCount (out)
			A pointer to the variable that will receive the enabled backend count.


	Return Value
	------------
	MA_SUCCESS if successful.
	MA_INVALID_ARGS if `pBackendCount` is NULL.
	MA_NO_SPACE if the capacity of `pBackends` is not large enough.

	If `MA_NO_SPACE` is returned, the `pBackends` buffer will be filled with `*pBackendCount` values.


	Thread Safety
	-------------
	Safe.


	Callback Safety
	---------------
	Safe.


	Remarks
	-------
	If you want to retrieve the number of backends so you can determine the capacity of `pBackends` buffer, you can call
	this function with `pBackends` set to NULL.

	This will also enumerate the null backend. If you don't want to include this you need to check for `ma_backend_null`
	when you enumerate over the returned backends and handle it appropriately. Alternatively, you can disable it at
	compile time with `MA_NO_NULL`.

	The returned backends are determined based on compile time settings, not the platform it's currently running on. For
	example, PulseAudio will be returned if it was enabled at compile time, even when the user doesn't actually have
	PulseAudio installed.


	Example 1
	---------
	The example below retrieves the enabled backend count using a fixed sized buffer allocated on the stack. The buffer is
	given a capacity of `MA_BACKEND_COUNT` which will guarantee it'll be large enough to store all available backends.
	Since `MA_BACKEND_COUNT` is always a relatively small value, this should be suitable for most scenarios.

	```
	ma_backend enabledBackends[MA_BACKEND_COUNT];
	size_t enabledBackendCount;

	result = ma_get_enabled_backends(enabledBackends, MA_BACKEND_COUNT, &enabledBackendCount);
	if (result != MA_SUCCESS) {
			// Failed to retrieve enabled backends. Should never happen in this example since all inputs are valid.
	}
	```


	See Also
	--------
	ma_is_backend_enabled()
	*/
	get_enabled_backends :: proc(pBackends: [^]backend, backendCap: c.size_t, pBackendCount: ^c.size_t) -> result ---

	/*
	Determines whether or not loopback mode is support by a backend.
	*/
	is_loopback_supported :: proc(backend: backend) -> b32 ---
}

