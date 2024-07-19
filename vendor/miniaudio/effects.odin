package miniaudio

import "core:c"

foreign import lib { LIB }

/*
Delay
*/
delay_config :: struct {
	channels:      u32,
	sampleRate:    u32,
	delayInFrames: u32,
	delayStart:    b32,    /* Set to true to delay the start of the output; false otherwise. */
	wet:           f32,    /* 0..1. Default = 1. */
	dry:           f32,    /* 0..1. Default = 1. */
	decay:         f32,    /* 0..1. Default = 0 (no feedback). Feedback decay. Use this for echo. */
}

delay :: struct {
	config: delay_config,
	cursor: u32,               /* Feedback is written to this cursor. Always equal or in front of the read cursor. */
	bufferSizeInFrames: u32,
	pBuffer: [^]f32,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	delay_config_init :: proc(channels, sampleRate, delayInFrames: u32, decay: f32) -> delay_config ---

	delay_init               :: proc(pConfig: ^delay_config, pAllocationCallbacks: ^allocation_callbacks, pDelay: ^delay) -> result ---
	delay_uninit             :: proc(pDelay: ^delay, pAllocationCallbacks: ^allocation_callbacks) ---
	delay_process_pcm_frames :: proc(pDelay: ^delay, pFramesOut, pFramesIn: rawptr, frameCount: u32) -> result ---
	delay_set_wet            :: proc(pDelay: ^delay, value: f32) ---
	delay_get_wet            :: proc(pDelay: ^delay) -> f32 ---
	delay_set_dry            :: proc(pDelay: ^delay, value: f32) ---
	delay_get_dry            :: proc(pDelay: ^delay) -> f32 ---
	delay_set_decay          :: proc(pDelay: ^delay, value: f32) ---
	delay_get_decay          :: proc(pDelay: ^delay) -> f32 ---
}


/* Gainer for smooth volume changes. */
gainer_config :: struct {
	channels: u32,
	smoothTimeInFrames: u32,
}

gainer :: struct {
	config:       gainer_config,
	t:            u32,
	masterVolume: f32,
	pOldGains:    [^]f32,
	pNewGains:    [^]f32,

	/* Memory management. */
	_pHeap:    rawptr,
	_ownsHeap: b32,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	gainer_config_init :: proc(channels, smoothTimeInFrames: u32) -> gainer_config ---

	gainer_get_heap_size      :: proc(pConfig: ^gainer_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	gainer_init_preallocated  :: proc(pConfig: ^gainer_config, pHeap: rawptr, pGainer: ^gainer) -> result ---
	gainer_init               :: proc(pConfig: ^gainer_config, pAllocationCallbacks: ^allocation_callbacks, pGainer: ^gainer) -> result ---
	gainer_uninit             :: proc(pGainer: ^gainer, pAllocationCallbacks: ^allocation_callbacks) ---
	gainer_process_pcm_frames :: proc(pGainer: ^gainer, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	gainer_set_gain           :: proc(pGainer: ^gainer, newGain: f32) -> result ---
	gainer_set_gains          :: proc(pGainer: ^gainer, pNewGains: [^]f32) -> result ---
	gainer_set_master_volume  :: proc(pGainer: ^gainer, volume: f32) -> result ---
	gainer_get_master_volume  :: proc(pGainer: ^gainer, volume: ^f32) -> result --- 
}


/* Stereo panner. */
pan_mode :: enum c.int {
	balance = 0,    /* Does not blend one side with the other. Technically just a balance. Compatible with other popular audio engines and therefore the default. */
	pan,            /* A true pan. The sound from one side will "move" to the other side and blend with it. */
}

panner_config :: struct {
	format:   format,
	channels: u32,
	mode:     pan_mode,
	pan:      f32,
}

panner :: struct {
	format:   format,
	channels: u32,
	mode:     pan_mode,
	pan:      f32,  /* -1..1 where 0 is no pan, -1 is left side, +1 is right side. Defaults to 0. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	panner_config_init :: proc(format: format, channels: u32) -> panner_config ---

	panner_init               :: proc(pConfig: ^panner_config, pPanner: ^panner) -> result ---
	panner_process_pcm_frames :: proc(pPanner: ^panner, pFramesOut, pFramesIn: rawptr, frameCount: u64) -> result ---
	panner_set_mode           :: proc(pPanner: ^panner, mode: pan_mode) ---
	panner_get_mode           :: proc(pPanner: ^panner) -> pan_mode ---
	panner_set_pan            :: proc(pPanner: ^panner, pan: f32) ---
	panner_get_pan            :: proc(pPanner: ^panner) -> f32 ---
}


/* Fader. */
fader_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
}

fader :: struct {
	config:         fader_config,
	volumeBeg:      f32,    /* If volumeBeg and volumeEnd is equal to 1, no fading happens (ma_fader_process_pcm_frames() will run as a passthrough). */
	volumeEnd:      f32,
	lengthInFrames: u64,    /* The total length of the fade. */
	cursorInFrames: i64,    /* The current time in frames. Incremented by ma_fader_process_pcm_frames(). Signed because it'll be offset by startOffsetInFrames in set_fade_ex(). */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	fader_config_init :: proc(format: format, channels, sampleRate: u32) -> fader_config ---

	fader_init               :: proc(pConfig: ^fader_config, pFader: ^fader) -> result ---
	fader_process_pcm_frames :: proc(pFader: ^fader, pFramesOut, pFramesIn: rawptr, frameCount: u64) -> result ---
	fader_get_data_format    :: proc(pFader: ^fader, pFormat: ^format, pChannels, pSampleRate: ^u32) ---
	fader_set_fade           :: proc(pFader: ^fader, volumeBeg, volumeEnd: f32, lengthInFrames: u64) ---
	fader_set_fade_ex        :: proc(pFader: ^fader, volumeBeg, volumeEnd: f32, lengthInFrames: u64, startOffsetInFrames: i64) ---
	fader_get_current_volume :: proc(pFader: ^fader) -> f32 ---
}


/* Spatializer. */
vec3f :: struct {
	x: f32,
	y: f32,
	z: f32,
}

atomic_vec3f :: struct {
	v:    vec3f,
	lock: spinlock,
}

attenuation_model :: enum c.int {
	none,          /* No distance attenuation and no spatialization. */
	inverse,       /* Equivalent to OpenAL's AL_INVERSE_DISTANCE_CLAMPED. */
	linear,        /* Linear attenuation. Equivalent to OpenAL's AL_LINEAR_DISTANCE_CLAMPED. */
	exponential,   /* Exponential attenuation. Equivalent to OpenAL's AL_EXPONENT_DISTANCE_CLAMPED. */
}

positioning :: enum c.int {
	absolute,
	relative,
}

handedness :: enum c.int {
	right,
	left,
}

spatializer_listener_config :: struct {
	channelsOut:             u32,
	pChannelMapOut:          [^]channel,
	handedness:              handedness,   /* Defaults to right. Forward is -1 on the Z axis. In a left handed system, forward is +1 on the Z axis. */
	coneInnerAngleInRadians: f32,
	coneOuterAngleInRadians: f32,
	coneOuterGain:           f32,
	speedOfSound:            f32,
	worldUp:                 vec3f,
}

spatializer_listener :: struct {
		config:    spatializer_listener_config,
		position:  atomic_vec3f,  /* The absolute position of the listener. */
		direction: atomic_vec3f,  /* The direction the listener is facing. The world up vector is config.worldUp. */
		velocity:  atomic_vec3f,
		isEnabled: b32,

		/* Memory management. */
		_ownsHeap: b32,
		_pHeap:    rawptr,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	spatializer_listener_config_init :: proc(channelsOut: u32) -> spatializer_listener_config ---

	spatializer_listener_get_heap_size      :: proc(pConfig: ^spatializer_listener_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	spatializer_listener_init_preallocated  :: proc(pConfig: ^spatializer_listener_config, pHeap: rawptr, pListener: ^spatializer_listener) -> result ---
	spatializer_listener_init               :: proc(pConfig: ^spatializer_listener_config, pAllocationCallbacks: ^allocation_callbacks, pListener: ^spatializer_listener) -> result ---
	spatializer_listener_uninit             :: proc(pListener: ^spatializer_listener, pAllocationCallbacks: ^allocation_callbacks) ---
	spatializer_listener_get_channel_map    :: proc(pListener: ^spatializer_listener) -> ^channel ---
	spatializer_listener_set_cone           :: proc(pListener: ^spatializer_listener, innerAngleInRadians, outerAngleInRadians, outerGain: f32) ---
	spatializer_listener_get_cone           :: proc(pListener: ^spatializer_listener, pInnerAngleInRadians, pOuterAngleInRadians, pOuterGain: ^f32) ---
	spatializer_listener_set_position       :: proc(pListener: ^spatializer_listener, x, y, z: f32) ---
	spatializer_listener_get_position       :: proc(pListener: ^spatializer_listener) -> vec3f ---
	spatializer_listener_set_direction      :: proc(pListener: ^spatializer_listener, x, y, z: f32) ---
	spatializer_listener_get_direction      :: proc(pListener: ^spatializer_listener) -> vec3f ---
	spatializer_listener_set_velocity       :: proc(pListener: ^spatializer_listener, x, y, z: f32) ---
	spatializer_listener_get_velocity       :: proc(pListener: ^spatializer_listener) -> vec3f ---
	spatializer_listener_set_speed_of_sound :: proc(pListener: ^spatializer_listener, speedOfSound: f32) ---
	spatializer_listener_get_speed_of_sound :: proc(pListener: ^spatializer_listener) -> f32 ---
	spatializer_listener_set_world_up       :: proc(pListener: ^spatializer_listener, x, y, z: f32) ---
	spatializer_listener_get_world_up       :: proc(pListener: ^spatializer_listener) -> vec3f ---
	spatializer_listener_set_enabled        :: proc(pListener: ^spatializer_listener, isEnabled: b32) ---
	spatializer_listener_is_enabled         :: proc(pListener: ^spatializer_listener) -> b32 ---
}

spatializer_config :: struct {
	channelsIn:                   u32,
	channelsOut:                  u32,
	pChannelMapIn:                [^]channel,
	attenuationModel:             attenuation_model,
	positioning:                  positioning,
	handedness:                   handedness,    /* Defaults to right. Forward is -1 on the Z axis. In a left handed system, forward is +1 on the Z axis. */
	minGain:                      f32,
	maxGain:                      f32,
	minDistance:                  f32,
	maxDistance:                  f32,
	rolloff:                      f32,
	coneInnerAngleInRadians:      f32,
	coneOuterAngleInRadians:      f32,
	coneOuterGain:                f32,
	dopplerFactor:                f32,    /* Set to 0 to disable doppler effect. */
	directionalAttenuationFactor: f32,    /* Set to 0 to disable directional attenuation. */
	minSpatializationChannelGain: f32,    /* The minimal scaling factor to apply to channel gains when accounting for the direction of the sound relative to the listener. Must be in the range of 0..1. Smaller values means more aggressive directional panning, larger values means more subtle directional panning. */
	gainSmoothTimeInFrames:       u32,    /* When the gain of a channel changes during spatialization, the transition will be linearly interpolated over this number of frames. */
}

spatializer :: struct {
		channelsIn:                   u32,
		channelsOut:                  u32,
		pChannelMapIn:                [^]channel,
		attenuationModel:             attenuation_model,
		positioning:                  positioning,
		handedness:                   handedness,    /* Defaults to right. Forward is -1 on the Z axis. In a left handed system, forward is +1 on the Z axis. */
		minGain:                      f32,
		maxGain:                      f32,
		minDistance:                  f32,
		maxDistance:                  f32,
		rolloff:                      f32,
		coneInnerAngleInRadians:      f32,
		coneOuterAngleInRadians:      f32,
		coneOuterGain:                f32,
		dopplerFactor:                f32,      /* Set to 0 to disable doppler effect. */
		directionalAttenuationFactor: f32,      /* Set to 0 to disable directional attenuation. */
		gainSmoothTimeInFrames:       u32,      /* When the gain of a channel changes during spatialization, the transition will be linearly interpolated over this number of frames. */
		position:                     atomic_vec3f,
		direction:                    atomic_vec3f,
		velocity:                     atomic_vec3f,    /* For doppler effect. */
		dopplerPitch:                 f32,      /* Will be updated by ma_spatializer_process_pcm_frames() and can be used by higher level functions to apply a pitch shift for doppler effect. */
		minSpatializationChannelGain: f32,
		gainer:                       gainer,   /* For smooth gain transitions. */
		pNewChannelGainsOut:          [^]f32,     /* An offset of _pHeap. Used by ma_spatializer_process_pcm_frames() to store new channel gains. The number of elements in this array is equal to config.channelsOut. */

		/* Memory management. */
		_pHeap:    rawptr,
		_ownsHeap: b32,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	spatializer_config_init :: proc(channelsIn, channelsOut: u32) -> spatializer_config ---

	spatializer_get_heap_size                       :: proc(pConfig: ^spatializer_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	spatializer_init_preallocated                   :: proc(pConfig: ^spatializer_config, pHeap: rawptr, pSpatializer: ^spatializer) -> result ---
	spatializer_init                                :: proc(pConfig: ^spatializer_config, pAllocationCallbacks: ^allocation_callbacks, pSpatializer: ^spatializer) -> result ---
	spatializer_uninit                              :: proc(pSpatializer: ^spatializer, pAllocationCallbacks: ^allocation_callbacks) ---
	spatializer_process_pcm_frames                  :: proc(pSpatializer: ^spatializer, pListener: ^spatializer_listener, pFramesOut, pFramesIn: rawptr, frameCount: u64) -> result ---
	spatializer_set_master_volume                   :: proc(pSpatializer: ^spatializer, volume: f32) -> result ---
	spatializer_get_master_volume                   :: proc(pSpatializer: ^spatializer, pVolume: ^f32) -> result ---
	spatializer_get_input_channels                  :: proc(pSpatializer: ^spatializer) -> u32 ---
	spatializer_get_output_channels                 :: proc(pSpatializer: ^spatializer) -> u32 ---
	spatializer_set_attenuation_model               :: proc(pSpatializer: ^spatializer, attenuationModel: attenuation_model) ---
	spatializer_get_attenuation_model               :: proc(pSpatializer: ^spatializer) -> attenuation_model ---
	spatializer_set_positioning                     :: proc(pSpatializer: ^spatializer, positioning: positioning) ---
	spatializer_get_positioning                     :: proc(pSpatializer: ^spatializer) -> positioning ---
	spatializer_set_rolloff                         :: proc(pSpatializer: ^spatializer, rolloff: f32) ---
	spatializer_get_rolloff                         :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_min_gain                        :: proc(pSpatializer: ^spatializer, minGain: f32) ---
	spatializer_get_min_gain                        :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_max_gain                        :: proc(pSpatializer: ^spatializer, maxGain: f32) ---
	spatializer_get_max_gain                        :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_min_distance                    :: proc(pSpatializer: ^spatializer, minDistance: f32) ---
	spatializer_get_min_distance                    :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_max_distance                    :: proc(pSpatializer: ^spatializer, maxDistance: f32) ---
	spatializer_get_max_distance                    :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_cone                            :: proc(pSpatializer: ^spatializer, innerAngleInRadians, outerAngleInRadians, outerGain: f32) ---
	spatializer_get_cone                            :: proc(pSpatializer: ^spatializer, pInnerAngleInRadians, pOuterAngleInRadians, pOuterGain: ^f32) ---
	spatializer_set_doppler_factor                  :: proc(pSpatializer: ^spatializer, dopplerFactor: f32) ---
	spatializer_get_doppler_factor                  :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_directional_attenuation_factor  :: proc(pSpatializer: ^spatializer, directionalAttenuationFactor: f32) ---
	spatializer_get_directional_attenuation_factor  :: proc(pSpatializer: ^spatializer) -> f32 ---
	spatializer_set_position                        :: proc(pSpatializer: ^spatializer, x, y, z: f32) ---
	spatializer_get_position                        :: proc(pSpatializer: ^spatializer) -> vec3f ---
	spatializer_set_direction                       :: proc(pSpatializer: ^spatializer, x, y, z: f32) ---
	spatializer_get_direction                       :: proc(pSpatializer: ^spatializer) -> vec3f ---
	spatializer_set_velocity                        :: proc(pSpatializer: ^spatializer, x, y, z: f32) ---
	spatializer_get_velocity                        :: proc(pSpatializer: ^spatializer) -> vec3f ---
	spatializer_get_relative_position_and_direction :: proc(pSpatializer: ^spatializer, pListener: ^spatializer_listener, pRelativePos, pRelativeDir: ^vec3f) ---
}
