package miniaudio

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else {
	foreign import lib "lib/miniaudio.a"
}

/************************************************************************************************************************************************************

Engine

************************************************************************************************************************************************************/

/* Sound flags. */
sound_flags :: enum c.int {
	/* Resource manager flags. */
	STREAM                = 0x00000001,   /* MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_STREAM */
	DECODE                = 0x00000002,   /* MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_DECODE */
	ASYNC                 = 0x00000004,   /* MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_ASYNC */
	WAIT_INIT             = 0x00000008,   /* MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_WAIT_INIT */
	UNKNOWN_LENGTH        = 0x00000010,   /* MA_RESOURCE_MANAGER_DATA_SOURCE_FLAG_UNKNOWN_LENGTH */
	
	/* ma_sound specific flags. */
	NO_DEFAULT_ATTACHMENT = 0x00001000,   /* Do not attach to the endpoint by default. Useful for when setting up nodes in a complex graph system. */
	NO_PITCH              = 0x00002000,   /* Disable pitch shifting with ma_sound_set_pitch() and ma_sound_group_set_pitch(). This is an optimization. */
	NO_SPATIALIZATION     = 0x00004000,   /* Disable spatialization. */
}

ENGINE_MAX_LISTENERS :: 4

LISTENER_INDEX_CLOSEST :: 255

engine_node_type :: enum c.int {
	sound,
	group,
}

engine_node_config :: struct {
	pEngine:                     ^engine,
	type:                        engine_node_type,
	channelsIn:                  u32,
	channelsOut:                 u32,
	sampleRate:                  u32,     /* Only used when the type is set to ma_engine_node_type_sound. */
	volumeSmoothTimeInPCMFrames: u32,
	monoExpansionMode:           mono_expansion_mode,
	isPitchDisabled:             b8,      /* Pitching can be explicitly disable with MA_SOUND_FLAG_NO_PITCH to optimize processing. */
	isSpatializationDisabled:    b8,      /* Spatialization can be explicitly disabled with MA_SOUND_FLAG_NO_SPATIALIZATION. */
	pinnedListenerIndex:         u8,      /* The index of the listener this node should always use for spatialization. If set to MA_LISTENER_INDEX_CLOSEST the engine will use the closest listener. */
}

/* Base node object for both ma_sound and ma_sound_group. */
engine_node :: struct {
	baseNode:                    node_base,           /* Must be the first member for compatiblity with the ma_node API. */
	pEngine:                     ^engine,             /* A pointer to the engine. Set based on the value from the config. */
	sampleRate:                  u32,                 /* The sample rate of the input data. For sounds backed by a data source, this will be the data source's sample rate. Otherwise it'll be the engine's sample rate. */
	volumeSmoothTimeInPCMFrames: u32,
	monoExpansionMode:           mono_expansion_mode,
	fader:                       fader,
	resampler:                   linear_resampler,    /* For pitch shift. */
	spatializer:                 spatializer,
	panner:                      panner,
	volumeGainer:                gainer,              /* This will only be used if volumeSmoothTimeInPCMFrames is > 0. */
	volume:                      f32, /*atomic*/      /* Defaults to 1. */
	pitch:                       f32, /*atomic*/
	oldPitch:                    f32,                 /* For determining whether or not the resampler needs to be updated to reflect the new pitch. The resampler will be updated on the mixing thread. */
	oldDopplerPitch:             f32,                 /* For determining whether or not the resampler needs to be updated to take a new doppler pitch into account. */
	isPitchDisabled:             b32, /*atomic*/      /* When set to true, pitching will be disabled which will allow the resampler to be bypassed to save some computation. */
	isSpatializationDisabled:    b32, /*atomic*/      /* Set to false by default. When set to false, will not have spatialisation applied. */
	pinnedListenerIndex:         u32, /*atomic*/      /* The index of the listener this node should always use for spatialization. If set to MA_LISTENER_INDEX_CLOSEST the engine will use the closest listener. */

	fadeSettings: struct {
		volumeBeg:                  f32, /*atomic*/
		volumeEnd:                  f32, /*atomic*/
		fadeLengthInFrames:         u64, /*atomic*/ /* <-- Defaults to (~(ma_uint64)0) which is used to indicate that no fade should be applied. */
		absoluteGlobalTimeInFrames: u64, /*atomic*/ /* <-- The time to start the fade. */
	},

	/* Memory management. */
	_ownsHeap: b8,
	_pHeap:    rawptr,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	engine_node_config_init :: proc(pEngine: ^engine, type: engine_node_type, flags: u32) -> engine_node_config ---

	engine_node_get_heap_size     :: proc(pConfig: ^engine_node_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	engine_node_init_preallocated :: proc(pConfig: ^engine_node_config, pHeap: rawptr, pEngineNode: ^engine_node) -> result ---
	engine_node_init              :: proc(pConfig: ^engine_node_config, pAllocationCallbacks: ^allocation_callbacks, pEngineNode: ^engine_node) -> result ---
	engine_node_uninit            :: proc(pEngineNode: ^engine_node, pAllocationCallbacks: ^allocation_callbacks) ---
}


SOUND_SOURCE_CHANNEL_COUNT :: 0xFFFFFFFF

/* Callback for when a sound reaches the end. */
sound_end_proc :: #type proc "c" (pUserData: rawptr, pSound: ^sound)

sound_config :: struct {
	pFilePath:                      cstring,          /* Set this to load from the resource manager. */
	pFilePathW:                     [^]c.wchar_t,     /* Set this to load from the resource manager. */
	pDataSource:                    ^data_source,     /* Set this to load from an existing data source. */
	pInitialAttachment:             ^node,            /* If set, the sound will be attached to an input of this node. This can be set to a ma_sound. If set to NULL, the sound will be attached directly to the endpoint unless MA_SOUND_FLAG_NO_DEFAULT_ATTACHMENT is set in `flags`. */
	initialAttachmentInputBusIndex: u32,              /* The index of the input bus of pInitialAttachment to attach the sound to. */
	channelsIn:                     u32,              /* Ignored if using a data source as input (the data source's channel count will be used always). Otherwise, setting to 0 will cause the engine's channel count to be used. */
	channelsOut:                    u32,              /* Set this to 0 (default) to use the engine's channel count. Set to MA_SOUND_SOURCE_CHANNEL_COUNT to use the data source's channel count (only used if using a data source as input). */
	monoExpansionMode:              mono_expansion_mode, /* Controls how the mono channel should be expanded to other channels when spatialization is disabled on a sound. */
	flags:                          u32,              /* A combination of MA_SOUND_FLAG_* flags. */
	volumeSmoothTimeInPCMFrames:    u32,              /* The number of frames to smooth over volume changes. Defaults to 0 in which case no smoothing is used. */
	initialSeekPointInPCMFrames:    u64,              /* Initializes the sound such that it's seeked to this location by default. */
	rangeBegInPCMFrames:            u64,
	rangeEndInPCMFrames:            u64,
	loopPointBegInPCMFrames:        u64,
	loopPointEndInPCMFrames:        u64,
	isLooping:                      b32,

	endCallback:          sound_end_proc, /* Fired when the sound reaches the end. Will be fired from the audio thread. Do not restart, uninitialize or otherwise change the state of the sound from here. Instead fire an event or set a variable to indicate to a different thread to change the start of the sound. Will not be fired in response to a scheduled stop with ma_sound_set_stop_time_*(). */
	pEndCallbackUserData: rawptr,
	
	initNotifications: resource_manager_pipeline_notifications,

	pDoneFence: ^fence, /* Deprecated. Use initNotifications instead. Released when the resource manager has finished decoding the entire sound. Not used with streams. */
}

sound :: struct {
	engineNode:     engine_node,       /* Must be the first member for compatibility with the ma_node API. */
	pDataSource:    ^data_source,
	seekTarget:     u64, /*atomic*/    /* The PCM frame index to seek to in the mixing thread. Set to (~(ma_uint64)0) to not perform any seeking. */
	atEnd:          b32, /*atomic*/

	endCallback:          sound_end_proc,
	pEndCallbackUserData: rawptr,

	ownsDataSource: b8,

	/*
	We're declaring a resource manager data source object here to save us a malloc when loading a
	sound via the resource manager, which I *think* will be the most common scenario.
	*/
	pResourceManagerDataSource: ^resource_manager_data_source,
}

/* Structure specifically for sounds played with ma_engine_play_sound(). Making this a separate structure to reduce overhead. */
sound_inlined :: struct {
	sound: sound,
	pNext: ^sound_inlined,
	pPrev: ^sound_inlined,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	@(deprecated="Will be removed in 0.12. Use sound_config_init2() instead.")
	sound_config_init  :: proc() -> sound_config ---
	sound_config_init2 :: proc(pEngine: ^engine) -> sound_config --- /* Will be renamed to sound_config_init() in version 0.12. */

	sound_init_from_file                     :: proc(pEngine: ^engine, pFilePath: cstring, flags: u32, pGroup: ^sound_group, pDoneFence: ^fence, pSound: ^sound) -> result ---
	sound_init_from_file_w                   :: proc(pEngine: ^engine, pFilePath: [^]c.wchar_t, flags: u32, pGroup: ^sound_group, pDoneFence: ^fence, pSound: ^sound) -> result ---
	sound_init_copy                          :: proc(pEngine: ^engine, pExistingSound: ^sound, flags: u32, pGroup: ^sound_group, pSound: ^sound) -> result ---
	sound_init_from_data_source              :: proc(pEngine: ^engine, pDataSource: ^data_source, flags: u32, pGroup: ^sound_group, pSound: ^sound) -> result ---
	sound_init_ex                            :: proc(pEngine: ^engine, pConfig: ^sound_config, pSound: ^sound) -> result ---
	sound_uninit                             :: proc(pSound: ^sound) ---
	sound_get_engine                         :: proc(pSound: ^sound) -> ^engine ---
	sound_get_data_source                    :: proc(pSound: ^sound) -> ^data_source ---
	sound_start                              :: proc(pSound: ^sound) -> result ---
	sound_stop                               :: proc(pSound: ^sound) -> result ---
	sound_stop_with_fade_in_pcm_frames       :: proc(pSound: ^sound, fadeLengthInFrames: u64) --- /* Will overwrite any scheduled stop and fade. */
	sound_stop_with_fade_in_milliseconds     :: proc(pSound: ^sound, fadeLengthInFrames: u64) --- /* Will overwrite any scheduled stop and fade. */
	sound_set_volume                         :: proc(pSound: ^sound, volume: f32) ---
	sound_get_volume                         :: proc(pSound: ^sound) -> f32 ---
	sound_set_pan                            :: proc(pSound: ^sound, pan: f32) ---
	sound_get_pan                            :: proc(pSound: ^sound) -> f32 ---
	sound_set_pan_mode                       :: proc(pSound: ^sound, panMode: pan_mode) ---
	sound_get_pan_mode                       :: proc(pSound: ^sound) -> pan_mode ---
	sound_set_pitch                          :: proc(pSound: ^sound, pitch: f32) ---
	sound_get_pitch                          :: proc(pSound: ^sound) -> f32 ---
	sound_set_spatialization_enabled         :: proc(pSound: ^sound, enabled: b32) ---
	sound_is_spatialization_enabled          :: proc(pSound: ^sound) -> b32 ---
	sound_set_pinned_listener_index          :: proc(pSound: ^sound, listenerIndex: u32) ---
	sound_get_pinned_listener_index          :: proc(pSound: ^sound) -> u32 ---
	sound_get_listener_index                 :: proc(pSound: ^sound) -> u32 ---
	sound_get_direction_to_listener          :: proc(pSound: ^sound) -> vec3f ---
	sound_set_position                       :: proc(pSound: ^sound, x, y, z: f32) ---
	sound_get_position                       :: proc(pSound: ^sound) -> vec3f ---
	sound_set_direction                      :: proc(pSound: ^sound, x, y, z: f32) ---
	sound_get_direction                      :: proc(pSound: ^sound) -> vec3f ---
	sound_set_velocity                       :: proc(pSound: ^sound, x, y, z: f32) ---
	sound_get_velocity                       :: proc(pSound: ^sound) -> vec3f ---
	sound_set_attenuation_model              :: proc(pSound: ^sound, attenuationModel: attenuation_model) ---
	sound_get_attenuation_model              :: proc(pSound: ^sound) -> attenuation_model ---
	sound_set_positioning                    :: proc(pSound: ^sound, positioning: positioning) ---
	sound_get_positioning                    :: proc(pSound: ^sound) -> positioning ---
	sound_set_rolloff                        :: proc(pSound: ^sound, rolloff: f32) ---
	sound_get_rolloff                        :: proc(pSound: ^sound) -> f32 ---
	sound_set_min_gain                       :: proc(pSound: ^sound, minGain: f32) ---
	sound_get_min_gain                       :: proc(pSound: ^sound) -> f32 ---
	sound_set_max_gain                       :: proc(pSound: ^sound, maxGain: f32) ---
	sound_get_max_gain                       :: proc(pSound: ^sound) -> f32 ---
	sound_set_min_distance                   :: proc(pSound: ^sound, minDistance: f32) ---
	sound_get_min_distance                   :: proc(pSound: ^sound) -> f32 ---
	sound_set_max_distance                   :: proc(pSound: ^sound, maxDistance: f32) ---
	sound_get_max_distance                   :: proc(pSound: ^sound) -> f32 ---
	sound_set_cone                           :: proc(pSound: ^sound, innerAngleInRadians, outerAngleInRadians, outerGain: f32) ---
	sound_get_cone                           :: proc(pSound: ^sound, pInnerAngleInRadians, pOuterAngleInRadians, pOuterGain: ^f32) ---
	sound_set_doppler_factor                 :: proc(pSound: ^sound, dopplerFactor: f32) ---
	sound_get_doppler_factor                 :: proc(pSound: ^sound) -> f32 ---
	sound_set_directional_attenuation_factor :: proc(pSound: ^sound, directionalAttenuationFactor: f32) ---
	sound_get_directional_attenuation_factor :: proc(pSound: ^sound) -> f32 ---
	sound_set_fade_in_pcm_frames             :: proc(pSound: ^sound, volumeBeg, volumeEnd: f32, fadeLengthInFrames: u64) ---
	sound_set_fade_in_milliseconds           :: proc(pSound: ^sound, volumeBeg, volumeEnd: f32, fadeLengthInMilliseconds: u64) ---
	sound_set_fade_start_in_pcm_frames       :: proc(pSound: ^sound, volumeBeg, volumeEnd: f32, fadeLengthInFrames, absoluteGlobalTimeInFrames: u64) ---
	sound_set_fade_start_in_milliseconds     :: proc(pSound: ^sound, volumeBeg, volumeEnd: f32, fadeLengthInMilliseconds, absoluteGlobalTimeInMilliseconds: u64) ---
	sound_get_current_fade_volume            :: proc(pSound: ^sound) -> f32 ---
	sound_set_start_time_in_pcm_frames       :: proc(pSound: ^sound, absoluteGlobalTimeInFrames: u64) ---
	sound_set_start_time_in_milliseconds     :: proc(pSound: ^sound, absoluteGlobalTimeInMilliseconds: u64) ---
	sound_set_stop_time_in_pcm_frames        :: proc(pSound: ^sound, absoluteGlobalTimeInFrames: u64) ---
	sound_set_stop_time_in_milliseconds      :: proc(pSound: ^sound, absoluteGlobalTimeInMilliseconds: u64) ---

	sound_set_stop_time_with_fade_in_pcm_frames   :: proc(pSound: ^sound, stopAbsoluteGlobalTimeInFrames, fadeLengthInFrames: u64) ---
	sound_set_stop_time_with_fade_in_milliseconds :: proc(pSound: ^sound, fadeAbsoluteGlobalTimeInMilliseconds, fadeLengthInMilliseconds: u64) ---

	sound_is_playing                         :: proc(pSound: ^sound) -> b32 ---
	sound_get_time_in_pcm_frames             :: proc(pSound: ^sound) -> u64 ---
	sound_get_time_in_milliseconds           :: proc(pSound: ^sound) -> u64 ---
	sound_set_looping                        :: proc(pSound: ^sound, isLooping: b32) ---
	sound_is_looping                         :: proc(pSound: ^sound) -> b32 ---
	sound_at_end                             :: proc(pSound: ^sound) -> b32 ---
	sound_seek_to_pcm_frame                  :: proc(pSound: ^sound, frameIndex: u64) -> result --- /* Just a wrapper around ma_data_source_seek_to_pcm_frame(). */
	sound_get_data_format                    :: proc(pSound: ^sound, pFormat: ^format, pChannels, pSampleRate: ^u32, pChannelMap: ^channel, channelMapCap: c.size_t) -> result ---
	sound_get_cursor_in_pcm_frames           :: proc(pSound: ^sound, pCursor: ^u64) -> result ---
	sound_get_length_in_pcm_frames           :: proc(pSound: ^sound, pLength: ^u64) -> result ---
	sound_get_cursor_in_seconds              :: proc(pSound: ^sound, pCursor: ^f32) -> result ---
	sound_get_length_in_seconds              :: proc(pSound: ^sound, pLength: ^f32) -> result ---
	sound_set_end_callback                   :: proc(pSound: ^sound, callback: sound_end_proc, pUserData: rawptr) ---
}


/* A sound group is just a sound. */
sound_group_config :: distinct sound_config
sound_group        :: distinct sound

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	@(deprecated="Will be removed in 0.12. Use sound_config_init2() instead.")
	sound_group_config_init  :: proc() -> sound_group_config ---
	sound_group_config_init2 :: proc(pEngine: ^engine) -> sound_group_config ---

	sound_group_init                               :: proc(pEngine: ^engine, flags: u32, pParentGroup, pGroup: ^sound_group) -> result ---
	sound_group_init_ex                            :: proc(pEngine: ^engine, pConfig: ^sound_group_config, pGroup: ^sound_group) -> result ---
	sound_group_uninit                             :: proc(pGroup: ^sound_group) ---
	sound_group_get_engine                         :: proc(pGroup: ^sound_group) -> ^engine ---
	sound_group_start                              :: proc(pGroup: ^sound_group) -> result ---
	sound_group_stop                               :: proc(pGroup: ^sound_group) -> result ---
	sound_group_set_volume                         :: proc(pGroup: ^sound_group, volume: f32) ---
	sound_group_get_volume                         :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_pan                            :: proc(pGroup: ^sound_group, pan: f32) ---
	sound_group_get_pan                            :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_pan_mode                       :: proc(pGroup: ^sound_group, panMode: pan_mode) ---
	sound_group_get_pan_mode                       :: proc(pGroup: ^sound_group) -> pan_mode ---
	sound_group_set_pitch                          :: proc(pGroup: ^sound_group, pitch: f32) ---
	sound_group_get_pitch                          :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_spatialization_enabled         :: proc(pGroup: ^sound_group, enabled: b32) ---
	sound_group_is_spatialization_enabled          :: proc(pGroup: ^sound_group) -> b32 ---
	sound_group_set_pinned_listener_index          :: proc(pGroup: ^sound_group, listenerIndex: u32) ---
	sound_group_get_pinned_listener_index          :: proc(pGroup: ^sound_group) -> u32 ---
	sound_group_get_listener_index                 :: proc(pGroup: ^sound_group) -> u32 ---
	sound_group_get_direction_to_listener          :: proc(pGroup: ^sound_group) -> vec3f ---
	sound_group_set_position                       :: proc(pGroup: ^sound_group, x, y, z: f32) ---
	sound_group_get_position                       :: proc(pGroup: ^sound_group) -> vec3f ---
	sound_group_set_direction                      :: proc(pGroup: ^sound_group, x, y, z: f32) ---
	sound_group_get_direction                      :: proc(pGroup: ^sound_group) -> vec3f ---
	sound_group_set_velocity                       :: proc(pGroup: ^sound_group, x, y, z: f32) ---
	sound_group_get_velocity                       :: proc(pGroup: ^sound_group) -> vec3f ---
	sound_group_set_attenuation_model              :: proc(pGroup: ^sound_group, attenuationModel: attenuation_model) ---
	sound_group_get_attenuation_model              :: proc(pGroup: ^sound_group) -> attenuation_model ---
	sound_group_set_positioning                    :: proc(pGroup: ^sound_group, positioning: positioning) ---
	sound_group_get_positioning                    :: proc(pGroup: ^sound_group) -> positioning ---
	sound_group_set_rolloff                        :: proc(pGroup: ^sound_group, rolloff: f32) ---
	sound_group_get_rolloff                        :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_min_gain                       :: proc(pGroup: ^sound_group, minGain: f32) ---
	sound_group_get_min_gain                       :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_max_gain                       :: proc(pGroup: ^sound_group, maxGain: f32) ---
	sound_group_get_max_gain                       :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_min_distance                   :: proc(pGroup: ^sound_group, minDistance: f32) ---
	sound_group_get_min_distance                   :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_max_distance                   :: proc(pGroup: ^sound_group, maxDistance: f32) ---
	sound_group_get_max_distance                   :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_cone                           :: proc(pGroup: ^sound_group, innerAngleInRadians, outerAngleInRadians, outerGain: f32) ---
	sound_group_get_cone                           :: proc(pGroup: ^sound_group, pInnerAngleInRadians, pOuterAngleInRadians, pOuterGain: ^f32) ---
	sound_group_set_doppler_factor                 :: proc(pGroup: ^sound_group, dopplerFactor: f32) ---
	sound_group_get_doppler_factor                 :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_directional_attenuation_factor :: proc(pGroup: ^sound_group, directionalAttenuationFactor: f32) ---
	sound_group_get_directional_attenuation_factor :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_fade_in_pcm_frames             :: proc(pGroup: ^sound_group, volumeBeg, volumeEnd: f32, fadeLengthInFrames: u64) ---
	sound_group_set_fade_in_milliseconds           :: proc(pGroup: ^sound_group, volumeBeg, volumeEnd: f32, fadeLengthInMilliseconds: u64) ---
	sound_group_get_current_fade_volume            :: proc(pGroup: ^sound_group) -> f32 ---
	sound_group_set_start_time_in_pcm_frames       :: proc(pGroup: ^sound_group, absoluteGlobalTimeInFrames: u64) ---
	sound_group_set_start_time_in_milliseconds     :: proc(pGroup: ^sound_group, absoluteGlobalTimeInMilliseconds: u64) ---
	sound_group_set_stop_time_in_pcm_frames        :: proc(pGroup: ^sound_group, absoluteGlobalTimeInFrames: u64) ---
	sound_group_set_stop_time_in_milliseconds      :: proc(pGroup: ^sound_group, absoluteGlobalTimeInMilliseconds: u64) ---
	sound_group_is_playing                         :: proc(pGroup: ^sound_group) -> b32 ---
	sound_group_get_time_in_pcm_frames             :: proc(pGroup: ^sound_group) -> u64 ---
}

engine_process_proc :: #type proc "c" (pUserData: rawptr, pFramesOut: [^]f32, frameCount: u64)

engine_config :: struct {
	pResourceManager:             ^resource_manager,      /* Can be null in which case a resource manager will be created for you. */
	pContext:                     ^context_type,
	pDevice:                      ^device,                /* If set, the caller is responsible for calling ma_engine_data_callback() in the device's data callback. */
	pPlaybackDeviceID:            ^device_id,             /* The ID of the playback device to use with the default listener. */

	dataCallback:         device_data_proc,               /* Can be null. Can be used to provide a custom device data callback. */
	notificationCallback: device_notification_proc,

	pLog:                         ^log,                   /* When set to NULL, will use the context's log. */
	listenerCount:                u32,                    /* Must be between 1 and MA_ENGINE_MAX_LISTENERS. */
	channels:                     u32,                    /* The number of channels to use when mixing and spatializing. When set to 0, will use the native channel count of the device. */
	sampleRate:                   u32,                    /* The sample rate. When set to 0 will use the native channel count of the device. */
	periodSizeInFrames:           u32,                    /* If set to something other than 0, updates will always be exactly this size. The underlying device may be a different size, but from the perspective of the mixer that won't matter.*/
	periodSizeInMilliseconds:     u32,                    /* Used if periodSizeInFrames is unset. */
	gainSmoothTimeInFrames:       u32,                    /* The number of frames to interpolate the gain of spatialized sounds across. If set to 0, will use gainSmoothTimeInMilliseconds. */
	gainSmoothTimeInMilliseconds: u32,                    /* When set to 0, gainSmoothTimeInFrames will be used. If both are set to 0, a default value will be used. */

	defaultVolumeSmoothTimeInPCMFrames: u32,              /* Defaults to 0. Controls the default amount of smoothing to apply to volume changes to sounds. High values means more smoothing at the expense of high latency (will take longer to reach the new volume). */

	allocationCallbacks:          allocation_callbacks,
	noAutoStart:                  b32,                    /* When set to true, requires an explicit call to ma_engine_start(). This is false by default, meaning the engine will be started automatically in ma_engine_init(). */
	noDevice:                     b32,                    /* When set to true, don't create a default device. ma_engine_read_pcm_frames() can be called manually to read data. */
	monoExpansionMode:            mono_expansion_mode,    /* Controls how the mono channel should be expanded to other channels when spatialization is disabled on a sound. */
	pResourceManagerVFS:          ^vfs,                   /* A pointer to a pre-allocated VFS object to use with the resource manager. This is ignored if pResourceManager is not NULL. */
	onProcess:                    engine_process_proc,    /* Fired at the end of each call to ma_engine_read_pcm_frames(). For engine's that manage their own internal device (the default configuration), this will be fired from the audio thread, and you do not need to call ma_engine_read_pcm_frames() manually in order to trigger this. */
	pProcessUserData:             rawptr,                 /* User data that's passed into onProcess. */
}

engine :: struct {
	nodeGraph:              node_graph,                   /* An engine is a node graph. It should be able to be plugged into any ma_node_graph API (with a cast) which means this must be the first member of this struct. */
	pResourceManager:       ^resource_manager,
	pDevice:                ^device,                      /* Optionally set via the config, otherwise allocated by the engine in ma_engine_init(). */
	pLog:                   ^log,
	sampleRate:             u32,
	listenerCount:          u32,
	listeners:              [ENGINE_MAX_LISTENERS]spatializer_listener,
	allocationCallbacks:    allocation_callbacks,
	ownsResourceManager:    b8,
	ownsDevice:             b8,
	inlinedSoundLock:       spinlock,                     /* For synchronizing access so the inlined sound list. */
	pInlinedSoundHead:      ^sound_inlined,               /* The first inlined sound. Inlined sounds are tracked in a linked list. */
	inlinedSoundCount:      u32, /*atomic*/               /* The total number of allocated inlined sound objects. Used for debugging. */
	gainSmoothTimeInFrames: u32,                          /* The number of frames to interpolate the gain of spatialized sounds across. */

	defaultVolumeSmoothTimeInPCMFrames: u32,

	monoExpansionMode: mono_expansion_mode,
	onProcess:         engine_process_proc,
	pProcessUserData:  rawptr,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	engine_config_init :: proc() -> engine_config ---

	engine_init                 :: proc(pConfig: ^engine_config, pEngine: ^engine) -> result ---
	engine_uninit               :: proc(pEngine: ^engine) ---
	engine_read_pcm_frames      :: proc(pEngine: ^engine, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---
	engine_get_node_graph       :: proc(pEngine: ^engine) -> ^node_graph ---
	engine_get_resource_manager :: proc(pEngine: ^engine) -> ^resource_manager ---
	engine_get_device           :: proc(pEngine: ^engine) -> ^device ---
	engine_get_log              :: proc(pEngine: ^engine) -> ^log ---
	engine_get_endpoint         :: proc(pEngine: ^engine) -> ^node ---

	engine_get_time_in_pcm_frames   :: proc(pEngine: ^engine) -> u64 ---
	engine_get_time_in_milliseconds :: proc(pEngine: ^engine) -> u64 ---
	engine_set_time_in_pcm_frames   :: proc(pEngine: ^engine, globalTime: u64) -> result --- 
	engine_set_time_in_milliseconds :: proc(pEngine: ^engine, globalTime: u64) -> result --- 
	
	@(deprecated="Use engine_get_time_in_pcm_frames(). Will be removed in 0.12.")
	engine_get_time :: proc(pEngine: ^engine) -> u64 ---
	@(deprecated="Use engine_set_time_in_pcm_frames(). Will be removed in 0.12.")
	engine_set_time :: proc(pEngine: ^engine, globalTime: u64) -> result ---

	engine_get_channels         :: proc(pEngine: ^engine) -> u32 ---
	engine_get_sample_rate      :: proc(pEngine: ^engine) -> u32 ---
	
	engine_start       :: proc(pEngine: ^engine) -> result ---
	engine_stop        :: proc(pEngine: ^engine) -> result ---
	engine_set_volume  :: proc(pEngine: ^engine, volume: f32) -> result ---
	engine_get_volume  :: proc(pEngine: ^engine) -> f32 ---
	engine_set_gain_db :: proc(pEngine: ^engine, gainDB: f32) -> result ---
	engine_get_gain_db :: proc(pEngine: ^engine) -> f32 ---
	
	engine_get_listener_count     :: proc(pEngine: ^engine) -> u32 ---
	engine_find_closest_listener  :: proc(pEngine: ^engine, absolutePosX, absolutePosY, absolutePosZ: f32) -> u32 ---
	engine_listener_set_position  :: proc(pEngine: ^engine, listenerIndex: u32, x, y, z: f32) ---
	engine_listener_get_position  :: proc(pEngine: ^engine, listenerIndex: u32) -> vec3f ---
	engine_listener_set_direction :: proc(pEngine: ^engine, listenerIndex: u32, x, y, z: f32) ---
	engine_listener_get_direction :: proc(pEngine: ^engine, listenerIndex: u32) -> vec3f ---
	engine_listener_set_velocity  :: proc(pEngine: ^engine, listenerIndex: u32, x, y, z: f32) ---
	engine_listener_get_velocity  :: proc(pEngine: ^engine, listenerIndex: u32) -> vec3f ---
	engine_listener_set_cone      :: proc(pEngine: ^engine, listenerIndex: u32, innerAngleInRadians, outerAngleInRadians, outerGain: f32) ---
	engine_listener_get_cone      :: proc(pEngine: ^engine, listenerIndex: u32, pInnerAngleInRadians, pOuterAngleInRadians, pOuterGain: ^f32) ---
	engine_listener_set_world_up  :: proc(pEngine: ^engine, listenerIndex: u32, x, y, z: f32) ---
	engine_listener_get_world_up  :: proc(pEngine: ^engine, listenerIndex: u32) -> vec3f ---
	engine_listener_set_enabled   :: proc(pEngine: ^engine, listenerIndex: u32, isEnabled: b32) ---
	engine_listener_is_enabled    :: proc(pEngine: ^engine, listenerIndex: u32) -> b32 ---
	
	engine_play_sound_ex :: proc(pEngine: ^engine, pFilePath: cstring, pNode: ^node, nodeInputBusIndex: u32) -> result ---
	engine_play_sound    :: proc(pEngine: ^engine, pFilePath: cstring, pGroup: ^sound_group) -> result ---   /* Fire and forget. */
}
