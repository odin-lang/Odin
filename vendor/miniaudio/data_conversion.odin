package miniaudio

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else {
	foreign import lib "lib/miniaudio.a"
}

/************************************************************************************************************************************************************
*************************************************************************************************************************************************************

DATA CONVERSION
===============

This section contains the APIs for data conversion. You will find everything here for channel mapping, sample format conversion, resampling, etc.

*************************************************************************************************************************************************************
************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************

Resampling

**************************************************************************************************************************************************************/
linear_resampler_config :: struct {
	format:           format,
	channels:         u32,
	sampleRateIn:     u32,
	sampleRateOut:    u32,
	lpfOrder:         u32, /* The low-pass filter order. Setting this to 0 will disable low-pass filtering. */
	lpfNyquistFactor: f64, /* 0..1. Defaults to 1. 1 = Half the sampling frequency (Nyquist Frequency), 0.5 = Quarter the sampling frequency (half Nyquest Frequency), etc. */
}

linear_resampler :: struct {
	config:        linear_resampler_config,
	inAdvanceInt:  u32,
	inAdvanceFrac: u32,
	inTimeInt:     u32,
	inTimeFrac:    u32,
	x0: struct #raw_union {
		f32: [^]f32,
		s16: [^]i16,
	}, /* The previous input frame. */
	x1: struct #raw_union {
		f32: [^]f32,
		s16: [^]i16,
	}, /* The next input frame. */
	lpf: lpf,

	/* Memory management. */
	_pHeap:    rawptr,
	_ownsHeap: b32,
}

resampling_backend :: struct {}
resampling_backend_vtable :: struct {
	onGetHeapSize:                 proc "c" (pUserData: rawptr, pConfig: ^resampler_config, pHeapSizeInBytes: ^c.size_t) -> result,
	onInit:                        proc "c" (pUserData: rawptr, pConfig: ^resampler_config, pHeap: rawptr, ppBackend: ^^resampling_backend) -> result,
	onUninit:                      proc "c" (pUserData: rawptr, pBackend: ^resampling_backend, pAllocationCallbacks: ^allocation_callbacks),
	onProcess:                     proc "c" (pUserData: rawptr, pBackend: ^resampling_backend, pFramesIn: rawptr, pFrameCountIn: ^u64, pFramesOut: rawptr, pFrameCountOut: ^u64) -> result,
	onSetRate:                     proc "c" (pUserData: rawptr, pBackend: ^resampling_backend, sampleRateIn: u32, sampleRateOut: u32) -> result,           /* Optional. Rate changes will be disabled. */
	onGetInputLatency:             proc "c" (pUserData: rawptr, pBackend: ^resampling_backend) -> u64,                                                     /* Optional. Latency will be reported as 0. */
	onGetOutputLatency:            proc "c" (pUserData: rawptr, pBackend: ^resampling_backend) -> u64,                                                     /* Optional. Latency will be reported as 0. */
	onGetRequiredInputFrameCount:  proc "c" (pUserData: rawptr, pBackend: ^resampling_backend, outputFrameCount: u64, pInputFrameCount: ^u64) -> result,   /* Optional. Latency mitigation will be disabled. */
	onGetExpectedOutputFrameCount: proc "c" (pUserData: rawptr, pBackend: ^resampling_backend, inputFrameCount: u64, pOutputFrameCount: ^u64) -> result,   /* Optional. Latency mitigation will be disabled. */
	onReset:                       proc "c" (pUserData: rawptr, pBackend: ^resampling_backend) -> result,
}

resample_algorithm :: enum c.int {
	linear = 0,   /* Fastest, lowest quality. Optional low-pass filtering. Default. */
	custom,
}

resampler_config :: struct {
	format:           format, /* Must be either ma_format_f32 or ma_format_s16. */
	channels:         u32,
	sampleRateIn:     u32,
	sampleRateOut:    u32,
	algorithm:        resample_algorithm, /* When set to ma_resample_algorithm_custom, pBackendVTable will be used. */
	pBackendVTable:   ^resampling_backend_vtable,
	pBackendUserData: rawptr,
	linear: struct {
		lpfOrder:         u32,
	},
}

resampler :: struct {
	pBackend:         ^resampling_backend,
	pBackendVTable:   ^resampling_backend_vtable,
	pBackendUserData: rawptr,
	format:           format,
	channels:         u32,
	sampleRateIn:     u32,
	sampleRateOut:    u32,
	state: struct #raw_union {
		linear: linear_resampler,
	},    /* State for stock resamplers so we can avoid a malloc. For stock resamplers, pBackend will point here. */

	/* Memory management. */
	_pHeap:    rawptr,
	_ownsHeap: b32,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	linear_resampler_config_init :: proc(format: format, channels: u32, sampleRateIn, sampleRateOut: u32) -> linear_resampler_config ---

	linear_resampler_get_heap_size                   :: proc(pConfig: ^linear_resampler_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	linear_resampler_init_preallocated               :: proc(pConfig: ^linear_resampler_config, pHeap: rawptr, pResampler: ^linear_resampler) -> result ---
	linear_resampler_init                            :: proc(pConfig: ^linear_resampler_config, pAllocationCallbacks: ^allocation_callbacks, pResampler: ^linear_resampler) -> result ---
	linear_resampler_uninit                          :: proc(pResampler: ^linear_resampler, pAllocationCallbacks: ^allocation_callbacks) ---
	linear_resampler_process_pcm_frames              :: proc(pResampler: ^linear_resampler, pFramesIn: rawptr, pFrameCountIn: ^u64, pFramesOut: rawptr, pFrameCountOut: ^u64) -> result ---
	linear_resampler_set_rate                        :: proc(pResampler: ^linear_resampler, sampleRateIn, sampleRateOut: u32) -> result ---
	linear_resampler_set_rate_ratio                  :: proc(pResampler: ^linear_resampler, ratioInOut: f32) -> result ---
	linear_resampler_get_input_latency               :: proc(pResampler: ^linear_resampler) -> u64 ---
	linear_resampler_get_output_latency              :: proc(pResampler: ^linear_resampler) -> u64 ---
	linear_resampler_get_required_input_frame_count  :: proc(pResampler: ^linear_resampler, outputFrameCount: u64, pInputFrameCount: ^u64) -> result ---
	linear_resampler_get_expected_output_frame_count :: proc(pResampler: ^linear_resampler, inputFrameCount: u64, pOutputFrameCount: ^u64) -> result ---
	linear_resampler_reset                           :: proc(pResampler: ^linear_resampler) -> result ---

	resampler_config_init :: proc(format: format, channels: u32, sampleRateIn, sampleRateOut: u32, algorithm: resample_algorithm) -> resampler_config ---

	resampler_get_heap_size     :: proc(pConfig: ^resampler_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	resampler_init_preallocated :: proc(pConfig: ^resampler_config, pHeap: rawptr, pResampler: ^resampler) -> result ---

	/*
	Initializes a new resampler object from a config.
	*/
	resampler_init :: proc(pConfig: ^resampler_config, pAllocationCallbacks: ^allocation_callbacks, pResampler: ^resampler) -> result ---

	/*
	Uninitializes a resampler.
	*/
	resampler_uninit :: proc(pResampler: ^resampler, pAllocationCallbacks: ^allocation_callbacks) ---

	/*
	Converts the given input data.

	Both the input and output frames must be in the format specified in the config when the resampler was initialized.

	On input, [pFrameCountOut] contains the number of output frames to process. On output it contains the number of output frames that
	were actually processed, which may be less than the requested amount which will happen if there's not enough input data. You can use
	ma_resampler_get_expected_output_frame_count() to know how many output frames will be processed for a given number of input frames.

	On input, [pFrameCountIn] contains the number of input frames contained in [pFramesIn]. On output it contains the number of whole
	input frames that were actually processed. You can use ma_resampler_get_required_input_frame_count() to know how many input frames
	you should provide for a given number of output frames. [pFramesIn] can be NULL, in which case zeroes will be used instead.

	If [pFramesOut] is NULL, a seek is performed. In this case, if [pFrameCountOut] is not NULL it will seek by the specified number of
	output frames. Otherwise, if [pFramesCountOut] is NULL and [pFrameCountIn] is not NULL, it will seek by the specified number of input
	frames. When seeking, [pFramesIn] is allowed to NULL, in which case the internal timing state will be updated, but no input will be
	processed. In this case, any internal filter state will be updated as if zeroes were passed in.

	It is an error for [pFramesOut] to be non-NULL and [pFrameCountOut] to be NULL.

	It is an error for both [pFrameCountOut] and [pFrameCountIn] to be NULL.
	*/
	resampler_process_pcm_frames :: proc(pResampler: ^resampler, pFramesIn: rawptr, pFrameCountIn: ^u64, pFramesOut: rawptr, pFrameCountOut: ^u64) -> result ---


	/*
	Sets the input and output sample rate.
	*/
	resampler_set_rate :: proc(pResampler: ^resampler, sampleRateIn, sampleRateOut: u32) -> result ---

	/*
	Sets the input and output sample rate as a ratio.

	The ration is in/out.
	*/
	resampler_set_rate_ratio :: proc(pResampler: ^resampler, ratio: f32) -> result ---

	/*
	Retrieves the latency introduced by the resampler in input frames.
	*/
	resampler_get_input_latency :: proc(pResampler: ^resampler) -> u64 ---

	/*
	Retrieves the latency introduced by the resampler in output frames.
	*/
	resampler_get_output_latency :: proc(pResampler: ^resampler) -> u64 ---

	/*
	Calculates the number of whole input frames that would need to be read from the client in order to output the specified
	number of output frames.

	The returned value does not include cached input frames. It only returns the number of extra frames that would need to be
	read from the input buffer in order to output the specified number of output frames.
	*/
	resampler_get_required_input_frame_count :: proc(pResampler: ^resampler, outputFrameCount: u64, pInputFrameCount: ^u64) -> result ---

	/*
	Calculates the number of whole output frames that would be output after fully reading and consuming the specified number of
	input frames.
	*/
	resampler_get_expected_output_frame_count :: proc(pResampler: ^resampler, inputFrameCount: u64, pOutputFrameCount: ^u64) -> result ---

	/*
	Resets the resampler's timer and clears it's internal cache.
	*/
	resampler_reset :: proc(pResampler: ^resampler) -> result ---
}


/**************************************************************************************************************************************************************

Channel Conversion

**************************************************************************************************************************************************************/
channel_conversion_path :: enum c.int {
	unknown,
	passthrough,
	mono_out,    /* Converting to mono. */
	mono_in,     /* Converting from mono. */
	shuffle,     /* Simple shuffle. Will use this when all channels are present in both input and output channel maps, but just in a different order. */
	weights,     /* Blended based on weights. */
}

mono_expansion_mode :: enum c.int {
	duplicate = 0,   /* The default. */
	average,         /* Average the mono channel across all channels. */
	stereo_only,     /* Duplicate to the left and right channels only and ignore the others. */
	default = duplicate,
}

channel_converter_config :: struct {
	format:                          format,
	channelsIn:                      u32,
	channelsOut:                     u32,
	pChannelMapIn:                   [^]channel,
	pChannelMapOut:                  [^]channel,
	mixingMode:                      channel_mix_mode,
	calculateLFEFromSpatialChannels: b32, /* When an output LFE channel is present, but no input LFE, set to true to set the output LFE to the average of all spatial channels (LR, FR, etc.). Ignored when an input LFE is present. */
	ppWeights:                       ^[^]f32, /* [in][out]. Only used when mixingMode is set to ma_channel_mix_mode_custom_weights. */
}

channel_converter :: struct {
	format:         format,
	channelsIn:     u32,
	channelsOut:    u32,
	mixingMode:     channel_mix_mode,
	conversionPath: channel_conversion_path,
	pChannelMapIn:  [^]channel,
	pChannelMapOut: [^]channel,
	pShuffleTable:  [^]u8,
	weights: struct #raw_union { /* [in][out] */
		f32: ^[^]f32,
		s16: ^[^]i32,
	},

	/* Memory management. */
	_pHeap:   rawptr,
	_ownsHeap: b32,
}


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	channel_converter_config_init :: proc(format: format, channelsIn: u32, pChannelMapIn: [^]channel, channelsOut: u32, pChannelMapOut: [^]channel, mixingMode: channel_mix_mode) -> channel_converter_config ---

	channel_converter_get_heap_size          :: proc(pConfig: ^channel_converter_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	channel_converter_init_preallocated      :: proc(pConfig: ^channel_converter_config, pHeap: rawptr, pConverter: ^channel_converter) -> result ---
	channel_converter_init                   :: proc(pConfig: ^channel_converter_config, pAllocationCallbacks: ^allocation_callbacks, pConverter: ^channel_converter) -> result ---
	channel_converter_uninit                 :: proc(pConverter: ^channel_converter, pAllocationCallbacks: ^allocation_callbacks) ---
	channel_converter_process_pcm_frames     :: proc(pConverter: ^channel_converter, pFramesOut, pFramesIn: rawptr, frameCount: u64) -> result ---
	channel_converter_get_input_channel_map  :: proc(pConverter: ^channel_converter, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	channel_converter_get_output_channel_map :: proc(pConverter: ^channel_converter, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
}


/**************************************************************************************************************************************************************

Data Conversion

**************************************************************************************************************************************************************/
data_converter_config :: struct {
	formatIn:                        format,
	formatOut:                       format,
	channelsIn:                      u32,
	channelsOut:                     u32,
	sampleRateIn:                    u32,
	sampleRateOut:                   u32,
	pChannelMapIn:                   [^]channel,
	pChannelMapOut:                  [^]channel,
	ditherMode:                      dither_mode,
	channelMixMode:                  channel_mix_mode,
	calculateLFEFromSpatialChannels: b32, /* When an output LFE channel is present, but no input LFE, set to true to set the output LFE to the average of all spatial channels (LR, FR, etc.). Ignored when an input LFE is present. */
	ppChannelWeights:                ^[^]f32, /* [in][out]. Only used when channelMixMode is set to ma_channel_mix_mode_custom_weights. */
	allowDynamicSampleRate:          b32,
	resampling:                      resampler_config,
}

data_converter_execution_path :: enum c.int {
	passthrough,       /* No conversion. */
	format_only,       /* Only format conversion. */
	channels_only,     /* Only channel conversion. */
	resample_only,     /* Only resampling. */
	resample_first,    /* All conversions, but resample as the first step. */
	channels_first,    /* All conversions, but channels as the first step. */
}

data_converter :: struct {
	formatIn:                format,
	formatOut:               format,
	channelsIn:              u32,
	channelsOut:             u32,
	sampleRateIn:            u32,
	sampleRateOut:           u32,
	ditherMode:              dither_mode,
	executionPath:           data_converter_execution_path, /* The execution path the data converter will follow when processing. */
	channelConverter:        channel_converter,
	resampler:               resampler,
	hasPreFormatConversion:  b8,
	hasPostFormatConversion: b8,
	hasChannelConverter:     b8,
	hasResampler:            b8,
	isPassthrough:           b8,

	/* Memory management. */
	_ownsHeap: b8,
	_pHeap:    rawptr,
}


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	data_converter_config_init_default :: proc() -> data_converter_config ---
	data_converter_config_init :: proc(formatIn, formatOut: format, channelsIn, channelsOut: u32, sampleRateIn, sampleRateOut: u32) -> data_converter_config ---

	data_converter_get_heap_size                   :: proc(pConfig: ^data_converter_config, pHeapSizeInBytes: ^c.size_t) -> result ---
	data_converter_init_preallocated               :: proc(pConfig: ^data_converter_config, pHeap: rawptr, pConverter: ^data_converter) -> result ---
	data_converter_init                            :: proc(pConfig: ^data_converter_config, pAllocationCallbacks: ^allocation_callbacks, pConverter: ^data_converter) -> result ---
	data_converter_uninit                          :: proc(pConverter: ^data_converter, pAllocationCallbacks: ^allocation_callbacks) ---
	data_converter_process_pcm_frames              :: proc(pConverter: ^data_converter, pFramesIn: rawptr, pFrameCountIn: ^u64, pFramesOut: rawptr, pFrameCountOut: ^u64) -> result ---
	data_converter_set_rate                        :: proc(pConverter: ^data_converter, sampleRateIn, sampleRateOut: u32) -> result ---
	data_converter_set_rate_ratio                  :: proc(pConverter: ^data_converter, ratioInOut: f32) -> result ---
	data_converter_get_input_latency               :: proc(pConverter: ^data_converter) -> u64 ---
	data_converter_get_output_latency              :: proc(pConverter: ^data_converter) -> u64 ---
	data_converter_get_required_input_frame_count  :: proc(pConverter: ^data_converter, outputFrameCount: u64, pInputFrameCount: ^u64) -> result ---
	data_converter_get_expected_output_frame_count :: proc(pConverter: ^data_converter, inputFrameCount: u64, pOutputFrameCount: ^u64) -> result ---
	data_converter_get_input_channel_map           :: proc(pConverter: ^data_converter, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	data_converter_get_output_channel_map          :: proc(pConverter: ^data_converter, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	data_converter_reset                           :: proc(pConverter: ^data_converter) -> result ---
}

/************************************************************************************************************************************************************

Format Conversion

************************************************************************************************************************************************************/


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	pcm_u8_to_s16  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_u8_to_s24  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_u8_to_s32  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_u8_to_f32  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s16_to_u8  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s16_to_s24 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s16_to_s32 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s16_to_f32 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s24_to_u8  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s24_to_s16 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s24_to_s32 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s24_to_f32 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s32_to_u8  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s32_to_s16 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s32_to_s24 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_s32_to_f32 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_f32_to_u8  :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_f32_to_s16 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_f32_to_s24 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_f32_to_s32 :: proc(pOut: rawptr, pIn: rawptr, count: u64, ditherMode: dither_mode) ---
	pcm_convert    :: proc(pOut: rawptr, formatOut: format, pIn: rawptr, formatIn: format, sampleCount: u64, ditherMode: dither_mode) ---
	convert_pcm_frames_format :: proc(pOut: rawptr, formatOut: format, pIn: rawptr, formatIn: format, frameCount: u64, channels: u32, ditherMode: dither_mode) ---

	/*
	Deinterleaves an interleaved buffer.
	*/
	deinterleave_pcm_frames :: proc(format: format, channels: u32, frameCount: u64, pInterleavedPCMFrames: rawptr, ppDeinterleavedPCMFrames: ^rawptr) ---

	/*
	Interleaves a group of deinterleaved buffers.
	*/
	interleave_pcm_frames :: proc(format: format, channels: u32, frameCount: u64, ppDeinterleavedPCMFrames: ^rawptr, pInterleavedPCMFrames: rawptr) ---
}


/************************************************************************************************************************************************************

Channel Maps

************************************************************************************************************************************************************/
/*
This is used in the shuffle table to indicate that the channel index is undefined and should be ignored.
*/
CHANNEL_INDEX_NULL :: 255

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	Retrieves the channel position of the specified channel in the given channel map.

	The pChannelMap parameter can be null, in which case miniaudio's default channel map will be assumed.
	*/
	channel_map_get_channel :: proc(pChannelMap: [^]channel, channelCount: u32, channelIndex: u32) -> channel ---

	/*
	Initializes a blank channel map.

	When a blank channel map is specified anywhere it indicates that the native channel map should be used.
	*/
	channel_map_init_blank :: proc(pChannelMap: [^]channel, channels: u32) ---

	/*
	Helper for retrieving a standard channel map.

	The output channel map buffer must have a capacity of at least `channelMapCap`.
	*/
	channel_map_init_standard :: proc(standardChannelMap: standard_channel_map, pChannelMap: [^]channel, channelMapCap: c.size_t, channels: u32) ---

	/*
	Copies a channel map.

	Both input and output channel map buffers must have a capacity of at at least `channels`.
	*/
	channel_map_copy :: proc(pOut: [^]channel, pIn: [^]channel, channels: u32) ---

	/*
	Copies a channel map if one is specified, otherwise copies the default channel map.

	The output buffer must have a capacity of at least `channels`. If not NULL, the input channel map must also have a capacity of at least `channels`.
	*/
	channel_map_copy_or_default :: proc(pOut: [^]channel, channelMapCapOut: c.size_t, pIn: [^]channel, channels: u32) ---


	/*
	Determines whether or not a channel map is valid.

	A blank channel map is valid (all channels set to MA_CHANNEL_NONE). The way a blank channel map is handled is context specific, but
	is usually treated as a passthrough.

	Invalid channel maps:
		- A channel map with no channels
		- A channel map with more than one channel and a mono channel

	The channel map buffer must have a capacity of at least `channels`.
	*/
	channel_map_is_valid :: proc(pChannelMap: [^]channel, channels: u32) -> b32 ---

	/*
	Helper for comparing two channel maps for equality.

	This assumes the channel count is the same between the two.

	Both channels map buffers must have a capacity of at least `channels`.
	*/
	channel_map_is_equal :: proc(pChannelMapA, pChannelMapB: [^]channel, channels: u32) -> b32 ---

	/*
	Helper for determining if a channel map is blank (all channels set to MA_CHANNEL_NONE).

	The channel map buffer must have a capacity of at least `channels`.
	*/
	channel_map_is_blank :: proc(pChannelMap: [^]channel, channels: u32) -> b32 ---

	/*
	Helper for determining whether or not a channel is present in the given channel map.

	The channel map buffer must have a capacity of at least `channels`.
	*/
	channel_map_contains_channel_position :: proc(channels: u32, pChannelMap: [^]channel, channelPosition: channel) -> b32 ---

	/*
	Find a channel position in the given channel map. Returns MA_TRUE if the channel is found; MA_FALSE otherwise. The
	index of the channel is output to `pChannelIndex`.
	
	The channel map buffer must have a capacity of at least `channels`.
	*/
	channel_map_find_channel_position :: proc(channels: u32, pChannelMap: [^]channel, channelPosition: channel, pChannelIndex: ^u32) -> b32 ---

	/*
	Generates a string representing the given channel map.
	
	This is for printing and debugging purposes, not serialization/deserialization.
	
	Returns the length of the string, not including the null terminator.
	*/
	channel_map_to_string :: proc(pChannelMap: [^]channel, channels: u32, pBufferOut: [^]u8, bufferCap: uint) -> uint ---
	
	/*
	Retrieves a human readable version of a channel position.
	*/
	channel_position_to_string :: proc(channel: channel) -> cstring ---
}


/************************************************************************************************************************************************************

Conversion Helpers

************************************************************************************************************************************************************/

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	High-level helper for doing a full format conversion in one go. Returns the number of output frames. Call this with pOut set to NULL to
	determine the required size of the output buffer. frameCountOut should be set to the capacity of pOut. If pOut is NULL, frameCountOut is
	ignored.

	A return value of 0 indicates an error.

	This function is useful for one-off bulk conversions, but if you're streaming data you should use the ma_data_converter APIs instead.
	*/
	convert_frames    :: proc(pOut: rawptr, frameCountOut: u64, formatOut: format, channelsOut: u32, sampleRateOut: u32, pIn: rawptr, frameCountIn: u64, formatIn: format, channelsIn: u32, sampleRateIn: u32) -> u64 ---
	convert_frames_ex :: proc(pOut: rawptr, frameCountOut: u64, pIn: rawptr, frameCountIn: u64, pConfig: ^data_converter_config) -> u64 ---
}


/************************************************************************************************************************************************************

Ring Buffer

************************************************************************************************************************************************************/
rb :: struct {
	pBuffer:                rawptr,
	subbufferSizeInBytes:   u32, 
	subbufferCount:         u32, 
	subbufferStrideInBytes: u32, 
	encodedReadOffset:      u32, /*atomic*/       /* Most significant bit is the loop flag. Lower 31 bits contains the actual offset in bytes. Must be used atomically. */
	encodedWriteOffset:     u32, /*atomic*/       /* Most significant bit is the loop flag. Lower 31 bits contains the actual offset in bytes. Must be used atomically. */
	ownsBuffer:             b8,                   /* Used to know whether or not miniaudio is responsible for free()-ing the buffer. */
	clearOnWriteAcquire:    b8,                   /* When set, clears the acquired write buffer before returning from ma_rb_acquire_write(). */
	allocationCallbacks:    allocation_callbacks,
}

pcm_rb :: struct {
	ds:         data_source_base,
	rb:         rb,
	format:     format,
	channels:   u32,
	sampleRate: u32, /* Not required for the ring buffer itself, but useful for associating the data with some sample rate, particularly for data sources. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	rb_init_ex              :: proc(subbufferSizeInBytes, subbufferCount, subbufferStrideInBytes: c.size_t, pOptionalPreallocatedBuffer: rawptr, pAllocationCallbacks: ^allocation_callbacks, pRB: ^rb) -> result ---
	rb_init                 :: proc(bufferSizeInBytes: c.size_t, pOptionalPreallocatedBuffer: rawptr, pAllocationCallbacks: ^allocation_callbacks, pRB: ^rb) -> result ---
	rb_uninit               :: proc(pRB: ^rb) ---
	rb_reset                :: proc(pRB: ^rb) ---
	rb_acquire_read         :: proc(pRB: ^rb, pSizeInBytes: ^c.size_t, ppBufferOut: ^rawptr) -> result ---
	rb_commit_read          :: proc(pRB: ^rb, sizeInBytes: c.size_t) -> result ---
	rb_acquire_write        :: proc(pRB: ^rb, pSizeInBytes: ^c.size_t, ppBufferOut: ^rawptr) -> result ---
	rb_commit_write         :: proc(pRB: ^rb, sizeInBytes: c.size_t) -> result ---
	rb_seek_read            :: proc(pRB: ^rb, offsetInBytes: c.size_t) -> result ---
	rb_seek_write           :: proc(pRB: ^rb, offsetInBytes: c.size_t) -> result ---
	rb_pointer_distance     :: proc(pRB: ^rb) -> i32 ---    /* Returns the distance between the write pointer and the read pointer. Should never be negative for a correct program. Will return the number of bytes that can be read before the read pointer hits the write pointer. */
	rb_available_read       :: proc(pRB: ^rb) -> u32 ---
	rb_available_write      :: proc(pRB: ^rb) -> u32 ---
	rb_get_subbuffer_size   :: proc(pRB: ^rb) -> c.size_t ---
	rb_get_subbuffer_stride :: proc(pRB: ^rb) -> c.size_t ---
	rb_get_subbuffer_offset :: proc(pRB: ^rb, subbufferIndex: c.size_t) -> c.size_t ---
	rb_get_subbuffer_ptr    :: proc(pRB: ^rb, subbufferIndex: c.size_t, pBuffer: rawptr) -> rawptr ---

	pcm_rb_init_ex              :: proc(format: format, channels: u32, subbufferSizeInFrames, subbufferCount, subbufferStrideInFrames: u32, pOptionalPreallocatedBuffer: rawptr, pAllocationCallbacks: ^allocation_callbacks, pRB: ^pcm_rb) -> result ---
	pcm_rb_init                 :: proc(format: format, channels: u32, bufferSizeInFrames: u32, pOptionalPreallocatedBuffer: rawptr, pAllocationCallbacks: ^allocation_callbacks, pRB: ^pcm_rb) -> result ---
	pcm_rb_uninit               :: proc(pRB: ^pcm_rb) ---
	pcm_rb_reset                :: proc(pRB: ^pcm_rb) ---
	pcm_rb_acquire_read         :: proc(pRB: ^pcm_rb, pSizeInFrames: ^u32, ppBufferOut: ^rawptr) -> result ---
	pcm_rb_commit_read          :: proc(pRB: ^pcm_rb, sizeInFrames: u32, pBufferOut: rawptr) -> result ---
	pcm_rb_acquire_write        :: proc(pRB: ^pcm_rb, pSizeInFrames: ^u32, ppBufferOut: ^rawptr) -> result ---
	pcm_rb_commit_write         :: proc(pRB: ^pcm_rb, sizeInFrames: u32, pBufferOut: rawptr) -> result ---
	pcm_rb_seek_read            :: proc(pRB: ^pcm_rb, offsetInFrames: u32) -> result ---
	pcm_rb_seek_write           :: proc(pRB: ^pcm_rb, offsetInFrames: u32) -> result ---
	pcm_rb_pointer_distance     :: proc(pRB: ^pcm_rb) -> i32 --- /* Return value is in frames. */
	pcm_rb_available_read       :: proc(pRB: ^pcm_rb) -> u32 ---
	pcm_rb_available_write      :: proc(pRB: ^pcm_rb) -> u32 ---
	pcm_rb_get_subbuffer_size   :: proc(pRB: ^pcm_rb) -> u32 ---
	pcm_rb_get_subbuffer_stride :: proc(pRB: ^pcm_rb) -> u32 ---
	pcm_rb_get_subbuffer_offset :: proc(pRB: ^pcm_rb, subbufferIndex: u32) -> u32 ---
	pcm_rb_get_subbuffer_ptr    :: proc(pRB: ^pcm_rb, subbufferIndex: u32, pBuffer: rawptr) -> rawptr ---
	pcm_rb_get_format           :: proc(pRB: ^pcm_rb) -> format ---
	pcm_rb_get_channels         :: proc(pRB: ^pcm_rb) -> u32 ---
	pcm_rb_get_sample_rate      :: proc(pRB: ^pcm_rb) -> u32 ---
	pcm_rb_set_sample_rate      :: proc(pRB: ^pcm_rb, sampleRate: u32) ---
}

/*
The idea of the duplex ring buffer is to act as the intermediary buffer when running two asynchronous devices in a duplex set up. The
capture device writes to it, and then a playback device reads from it.

At the moment this is just a simple naive implementation, but in the future I want to implement some dynamic resampling to seamlessly
handle desyncs. Note that the API is work in progress and may change at any time in any version.

The size of the buffer is based on the capture side since that's what'll be written to the buffer. It is based on the capture period size
in frames. The internal sample rate of the capture device is also needed in order to calculate the size.
*/
duplex_rb :: struct {
	rb: pcm_rb,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	duplex_rb_init   :: proc(captureFormat: format, captureChannels: u32, sampleRate: u32, captureInternalSampleRate, captureInternalPeriodSizeInFrames: u32, pAllocationCallbacks: ^allocation_callbacks, pRB: ^duplex_rb) -> result ---
	duplex_rb_uninit :: proc(pRB: ^duplex_rb) -> result ---
}

