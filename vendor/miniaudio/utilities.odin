package miniaudio

import "core:c"

foreign import lib { LIB }

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	Calculates a buffer size in milliseconds from the specified number of frames and sample rate.
	*/
	calculate_buffer_size_in_milliseconds_from_frames :: proc(bufferSizeInFrames: u32, sampleRate: u32) -> u32 ---

	/*
	Calculates a buffer size in frames from the specified number of milliseconds and sample rate.
	*/
	calculate_buffer_size_in_frames_from_milliseconds :: proc(bufferSizeInMilliseconds: u32, sampleRate: u32) -> u32 ---

	/*
	Copies PCM frames from one buffer to another.
	*/
	copy_pcm_frames :: proc(dst: rawptr, src: rawptr, frameCount: u64, format: format, channels: u32) ---

	/*
	Copies silent frames into the given buffer.

	Remarks
	-------
	For all formats except `ma_format_u8`, the output buffer will be filled with 0. For `ma_format_u8` it will be filled with 128. The reason for this is that it
	makes more sense for the purpose of mixing to initialize it to the center point.
	*/
	silence_pcm_frames :: proc(p: rawptr, frameCount: u64, format: format, channels: u32) ---


	/*
	Offsets a pointer by the specified number of PCM frames.
	*/
	offset_pcm_frames_ptr :: proc(p: rawptr, offsetInFrames: u64, format: format, channels: u32) -> rawptr ---
	offset_pcm_frames_const_ptr :: proc(p: rawptr, offsetInFrames: u64, format: format, channels: u32) -> rawptr ---


	/*
	Clips samples.
	*/
	clip_samples_u8  :: proc(pDst: [^]u8,  pSrc: [^]i16, count: u64) ---
	clip_samples_s16 :: proc(pDst: [^]i16, pSrc: [^]i32, count: u64) ---
	clip_samples_s24 :: proc(pDst: [^]u8,  pSrc: [^]i64, count: u64) ---
	clip_samples_s32 :: proc(pDst: [^]i32, pSrc: [^]i64, count: u64) ---
	clip_samples_f32 :: proc(pDst,         pSrc: [^]f32, count: u64) ---
	clip_pcm_frames	 :: proc(pDst,         pSrc: rawptr, frameCount: u64, format: format, channels: u32) ---

	/*
	Helper for applying a volume factor to samples.

	Note that the source and destination buffers can be the same, in which case it'll perform the operation in-place.
	*/
	copy_and_apply_volume_factor_u8  :: proc(pSamplesOut, pSamplesIn: [^]u8,  sampleCount: u64, factor: f64) ---
	copy_and_apply_volume_factor_s16 :: proc(pSamplesOut, pSamplesIn: [^]i16, sampleCount: u64, factor: f64) ---
	copy_and_apply_volume_factor_s24 :: proc(pSamplesOut, pSamplesIn: rawptr, sampleCount: u64, factor: f64) ---
	copy_and_apply_volume_factor_s32 :: proc(pSamplesOut, pSamplesIn: [^]i32, sampleCount: u64, factor: f64) ---
	copy_and_apply_volume_factor_f32 :: proc(pSamplesOut, pSamplesIn: [^]f32, sampleCount: u64, factor: f64) ---

	apply_volume_factor_u8  :: proc(pSamples: [^]u8,  sampleCount: u64, factor: f32) ---
	apply_volume_factor_s16 :: proc(pSamples: [^]i16, sampleCount: u64, factor: f32) ---
	apply_volume_factor_s24 :: proc(pSamples: rawptr, sampleCount: u64, factor: f32) ---
	apply_volume_factor_s32 :: proc(pSamples: [^]i32, sampleCount: u64, factor: f32) ---
	apply_volume_factor_f32 :: proc(pSamples: [^]f32, sampleCount: u64, factor: f32) ---

	copy_and_apply_volume_factor_pcm_frames_u8  :: proc(pPCMFramesOut, pPCMFramesIn: [^]u8,  frameCount: u64, channels: u32, factor: f32) ---
	copy_and_apply_volume_factor_pcm_frames_s16 :: proc(pPCMFramesOut, pPCMFramesIn: [^]i16, frameCount: u64, channels: u32, factor: f32) ---
	copy_and_apply_volume_factor_pcm_frames_s24 :: proc(pPCMFramesOut, pPCMFramesIn: rawptr, frameCount: u64, channels: u32, factor: f32) ---
	copy_and_apply_volume_factor_pcm_frames_s32 :: proc(pPCMFramesOut, pPCMFramesIn: [^]i32, frameCount: u64, channels: u32, factor: f32) ---
	copy_and_apply_volume_factor_pcm_frames_f32 :: proc(pPCMFramesOut, pPCMFramesIn: [^]f32, frameCount: u64, channels: u32, factor: f32) ---
	copy_and_apply_volume_factor_pcm_frames     :: proc(pFramesOut,    pFramesIn:    rawptr, frameCount: u64, format: format, channels: u32, factor: f32) ---

	apply_volume_factor_pcm_frames_u8  :: proc(pFrames: [^]u8,  frameCount: u64, channels: u32, factor: f32) ---
	apply_volume_factor_pcm_frames_s16 :: proc(pFrames: [^]i16, frameCount: u64, channels: u32, factor: f32) ---
	apply_volume_factor_pcm_frames_s24 :: proc(pFrames: rawptr, frameCount: u64, channels: u32, factor: f32) ---
	apply_volume_factor_pcm_frames_s32 :: proc(pFrames: [^]i32, frameCount: u64, channels: u32, factor: f32) ---
	apply_volume_factor_pcm_frames_f32 :: proc(pFrames: [^]f32, frameCount: u64, channels: u32, factor: f32) ---
	apply_volume_factor_pcm_frames     :: proc(pFrames: rawptr, frameCount: u64, format: format, channels: u32, factor: f32) ---

	copy_and_apply_volume_factor_per_channel_f32 :: proc(pFramesOut, pFramesIn: [^]f32, frameCount: u64, channels: u32, pChannelGains: [^]f32) ---


	ma_copy_and_apply_volume_and_clip_samples_u8  :: proc(pDst: [^]u8,  pSrc: [^]i16, count: u64, volume: f32) ---
	ma_copy_and_apply_volume_and_clip_samples_s16 :: proc(pDst: [^]i16, pSrc: [^]i32, count: u64, volume: f32) ---
	ma_copy_and_apply_volume_and_clip_samples_s24 :: proc(pDst: [^]u8,  pSrc: [^]i64, count: u64, volume: f32) ---
	ma_copy_and_apply_volume_and_clip_samples_s32 :: proc(pDst: [^]i32, pSrc: [^]i64, count: u64, volume: f32) ---
	ma_copy_and_apply_volume_and_clip_samples_f32 :: proc(pDst,         pSrc: [^]f32, count: u64, volume: f32) ---
	ma_copy_and_apply_volume_and_clip_pcm_frames 	:: proc(pDst,         pSrc: rawptr, frameCount: u64, format: format, channels: u32, volume: f32) ---


	/*
	Helper for converting a linear factor to gain in decibels.
	*/
	volume_linear_to_db :: proc(factor: f32) -> f32 ---

	/*
	Helper for converting gain in decibels to a linear factor.
	*/
	volume_db_to_linear :: proc(gain: f32) -> f32 ---

	/*
	Mixes the specified number of frames in floating point format with a volume factor.

	This will run on an optimized path when the volume is equal to 1.
	*/
	ma_mix_pcm_frames_f32 :: proc(pDst: ^f32, pSrc: ^f32, frameCount: u64, channels: u32, volume: f32) -> result ---
}

offset_pcm_frames_ptr_f32 :: #force_inline proc "c" (p: [^]f32, offsetInFrames: u64, channels: u32) -> [^]f32 {
	return cast([^]f32)offset_pcm_frames_ptr(p, offsetInFrames, .f32, channels)
}
offset_pcm_frames_const_ptr_f32 :: #force_inline proc "c" (p: [^]f32, offsetInFrames: u64, channels: u32) -> [^]f32 {
	return cast([^]f32)offset_pcm_frames_ptr(p, offsetInFrames, .f32, channels)
}


data_source :: struct {}

DATA_SOURCE_SELF_MANAGED_RANGE_AND_LOOP_POINT :: 0x00000001

data_source_vtable :: struct {
	onRead:          proc "c" (pDataSource: ^data_source, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result,
	onSeek:          proc "c" (pDataSource: ^data_source, frameIndex: u64) -> result,
	onGetDataFormat: proc "c" (pDataSource: ^data_source, pFormat: ^format, pChannels: ^u32, pSampleRate: ^u32, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result,
	onGetCursor:     proc "c" (pDataSource: ^data_source, pCursor: ^u64) -> result,
	onGetLength:     proc "c" (pDataSource: ^data_source, pLength: ^u64) -> result,
	onSetLooping:    proc "c" (pDataSource: ^data_source, isLooping: b32) -> result,
	flags:           u32,
} 

data_source_get_next_proc :: proc "c" (pDataSource: ^data_source) -> ^data_source

data_source_config :: struct {
	vtable: ^data_source_vtable, /* Can be null, which is useful for proxies. */
}

data_source_base :: struct {
	vtable:           ^data_source_vtable,
	rangeBegInFrames: u64,
	rangeEndInFrames: u64,                        /* Set to -1 for unranged (default). */
	loopBegInFrames:  u64,                        /* Relative to rangeBegInFrames. */
	loopEndInFrames:  u64,                        /* Relative to rangeBegInFrames. Set to -1 for the end of the range. */
	pCurrent:         ^data_source,               /* When non-NULL, the data source being initialized will act as a proxy and will route all operations to pCurrent. Used in conjunction with pNext/onGetNext for seamless chaining. */
	pNext:            ^data_source,               /* When set to NULL, onGetNext will be used. */
	onGetNext:        data_source_get_next_proc,  /* Will be used when pNext is NULL. If both are NULL, no next will be used. */
	isLooping:        b32, /*atomic*/
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	data_source_config_init :: proc() -> data_source_config ---
	
	data_source_init                         :: proc(pConfig: ^data_source_config, pDataSource: ^data_source) -> result ---
	data_source_uninit                       :: proc(pDataSource: ^data_source) ---
	data_source_read_pcm_frames              :: proc(pDataSource: ^data_source, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---   /* Must support pFramesOut = NULL in which case a forward seek should be performed. */
	data_source_seek_pcm_frames              :: proc(pDataSource: ^data_source, frameCount: u64, pFramesSeeked: ^u64) -> result --- /* Can only seek forward. Equivalent to ma_data_source_read_pcm_frames(pDataSource, NULL, frameCount); */
	data_source_seek_to_pcm_frame            :: proc(pDataSource: ^data_source, frameIndex: u64) -> result ---
	data_source_get_data_format              :: proc(pDataSource: ^data_source, pFormat: ^format, pChannels: ^u32, pSampleRate: ^u32, pChannelMap: [^]channel, channelMapCap: c.size_t) -> result ---
	data_source_get_cursor_in_pcm_frames     :: proc(pDataSource: ^data_source, pCursor: ^u64) -> result ---
	data_source_get_length_in_pcm_frames     :: proc(pDataSource: ^data_source, pLength: ^u64) -> result ---    /* Returns MA_NOT_IMPLEMENTED if the length is unknown or cannot be determined. Decoders can return this. */
	data_source_get_cursor_in_seconds        :: proc(pDataSource: ^data_source, pCursor: ^f32) -> result ---
	data_source_get_length_in_seconds        :: proc(pDataSource: ^data_source, pLength: ^f32) -> result ---
	data_source_set_looping                  :: proc(pDataSource: ^data_source, isLooping: b32) -> result ---
	data_source_is_looping                   :: proc(pDataSource: ^data_source) -> b32 ---
	data_source_set_range_in_pcm_frames      :: proc(pDataSource: ^data_source, rangeBegInFrames: u64, rangeEndInFrames: u64) -> result ---
	data_source_get_range_in_pcm_frames      :: proc(pDataSource: ^data_source, pRangeBegInFrames: ^u64, pRangeEndInFrames: ^u64) ---
	data_source_set_loop_point_in_pcm_frames :: proc(pDataSource: ^data_source, loopBegInFrames: u64, loopEndInFrames: u64) -> result ---
	data_source_get_loop_point_in_pcm_frames :: proc(pDataSource: ^data_source, pLoopBegInFrames: ^u64, pLoopEndInFrames: ^u64) ---
	data_source_set_current                  :: proc(pDataSource: ^data_source, pCurrentDataSource: ^data_source) -> result ---
	data_source_get_current                  :: proc(pDataSource: ^data_source) -> ^data_source ---
	data_source_set_next                     :: proc(pDataSource: ^data_source, pNextDataSource: ^data_source) -> result ---
	data_source_get_next                     :: proc(pDataSource: ^data_source) -> ^data_source ---
	data_source_set_next_callback            :: proc(pDataSource: ^data_source, onGetNext: ^data_source_get_next_proc) -> result ---
	data_source_get_next_callback            :: proc(pDataSource: ^data_source) -> ^data_source_get_next_proc ---
}


audio_buffer_ref :: struct {
	ds:           data_source_base,
	format:       format,
	channels:     u32,
	sampleRate:   u32,
	cursor:       u64,
	sizeInFrames: u64,
	pData:        rawptr,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	audio_buffer_ref_init                      :: proc(format: format, channels: u32, pData: rawptr, sizeInFrames: u64, pAudioBufferRef: ^audio_buffer_ref) -> result ---
	audio_buffer_ref_uninit                    :: proc(pAudioBufferRef: ^audio_buffer_ref) ---
	audio_buffer_ref_set_data                  :: proc(pAudioBufferRef: ^audio_buffer_ref, pData: rawptr, sizeInFrames: u64) -> result ---
	audio_buffer_ref_read_pcm_frames           :: proc(pAudioBufferRef: ^audio_buffer_ref, pFramesOut: rawptr, frameCount: u64, loop: b32) -> u64 ---
	audio_buffer_ref_seek_to_pcm_frame         :: proc(pAudioBufferRef: ^audio_buffer_ref, frameIndex: u64) -> result ---
	audio_buffer_ref_map                       :: proc(pAudioBufferRef: ^audio_buffer_ref, ppFramesOut: ^rawptr, pFrameCount: ^u64) -> result ---
	audio_buffer_ref_unmap                     :: proc(pAudioBufferRef: ^audio_buffer_ref, frameCount: u64) -> result ---    /* Returns MA_AT_END if the end has been reached. This should be considered successful. */
	audio_buffer_ref_at_end                    :: proc(pAudioBufferRef: ^audio_buffer_ref) -> b32 ---
	audio_buffer_ref_get_cursor_in_pcm_frames  :: proc(pAudioBufferRef: ^audio_buffer_ref, pCursor: ^u64) -> result ---
	audio_buffer_ref_get_length_in_pcm_frames  :: proc(pAudioBufferRef: ^audio_buffer_ref, pLength: ^u64) -> result ---
	audio_buffer_ref_get_available_frames      :: proc(pAudioBufferRef: ^audio_buffer_ref, pAvailableFrames: ^u64) -> result ---
}


audio_buffer_config :: struct {
	format:              format,
	channels:            u32,
	sampleRate:          u32,
	sizeInFrames:        u64,
	pData:               rawptr,  /* If set to NULL, will allocate a block of memory for you. */
	allocationCallbacks: allocation_callbacks,
}

audio_buffer :: struct {
	ref:                 audio_buffer_ref,
	allocationCallbacks: allocation_callbacks,
	ownsData:            b32,             /* Used to control whether or not miniaudio owns the data buffer. If set to true, pData will be freed in ma_audio_buffer_uninit(). */
	_pExtraData:         [1]u8,        /* For allocating a buffer with the memory located directly after the other memory of the structure. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	audio_buffer_config_init :: proc(format: format, channels: u32, sizeInFrames: u64, pData: rawptr, pAllocationCallbacks: ^allocation_callbacks) -> audio_buffer_config ---

	audio_buffer_init                     :: proc(pConfig: ^audio_buffer_config, pAudioBuffer: ^audio_buffer) -> result ---
	audio_buffer_init_copy                :: proc(pConfig: ^audio_buffer_config, pAudioBuffer: ^audio_buffer) -> result ---
	audio_buffer_alloc_and_init           :: proc(pConfig: ^audio_buffer_config, ppAudioBuffer: ^^audio_buffer) -> result --- /* Always copies the data. Doesn't make sense to use this otherwise. Use ma_audio_buffer_uninit_and_free() to uninit. */
	audio_buffer_uninit                   :: proc(pAudioBuffer: ^audio_buffer) ---
	audio_buffer_uninit_and_free          :: proc(pAudioBuffer: ^audio_buffer) ---
	audio_buffer_read_pcm_frames          :: proc(pAudioBuffer: ^audio_buffer, pFramesOut: rawptr, frameCount: u64, loop: b32) -> u64 ---
	audio_buffer_seek_to_pcm_frame        :: proc(pAudioBuffer: ^audio_buffer, frameIndex: u64) -> result ---
	audio_buffer_map                      :: proc(pAudioBuffer: ^audio_buffer, ppFramesOut: ^rawptr, pFrameCount: ^u64) -> result ---
	audio_buffer_unmap                    :: proc(pAudioBuffer: ^audio_buffer, frameCount: u64) -> result ---  /* Returns MA_AT_END if the end has been reached. This should be considered successful. */
	audio_buffer_at_end                   :: proc(pAudioBuffer: ^audio_buffer) -> b32 ---
	audio_buffer_get_cursor_in_pcm_frames :: proc(pAudioBuffer: ^audio_buffer, pCursor: ^u64) -> result ---
	audio_buffer_get_length_in_pcm_frames :: proc(pAudioBuffer: ^audio_buffer, pLength: ^u64) -> result ---
	audio_buffer_get_available_frames     :: proc(pAudioBuffer: ^audio_buffer, pAvailableFrames: ^u64) -> result ---
}

/*
Paged Audio Buffer
==================
A paged audio buffer is made up of a linked list of pages. It's expandable, but not shrinkable. It
can be used for cases where audio data is streamed in asynchronously while allowing data to be read
at the same time.

This is lock-free, but not 100% thread safe. You can append a page and read from the buffer across
simultaneously across different threads, however only one thread at a time can append, and only one
thread at a time can read and seek.
*/
paged_audio_buffer_page :: struct {
	pNext:        ^paged_audio_buffer_page, /*atomic*/
	sizeInFrames: u64,
	pAudioData:   [1]u8,
}

paged_audio_buffer_data :: struct {
	format:   format,
	channels: u32,
	head:     paged_audio_buffer_page,                /* Dummy head for the lock-free algorithm. Always has a size of 0. */
	pTail:    ^paged_audio_buffer_page, /*atomic*/    /* Never null. Initially set to &head. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	paged_audio_buffer_data_init                     :: proc(format: format, channels: u32, pData: ^paged_audio_buffer_data) -> result ---
	paged_audio_buffer_data_uninit                   :: proc(pData: ^paged_audio_buffer_data, pAllocationCallbacks: ^allocation_callbacks) ---
	paged_audio_buffer_data_get_head                 :: proc(pData: ^paged_audio_buffer_data) -> ^paged_audio_buffer_page ---
	paged_audio_buffer_data_get_tail                 :: proc(pData: ^paged_audio_buffer_data) -> ^paged_audio_buffer_page ---
	paged_audio_buffer_data_get_length_in_pcm_frames :: proc(pData: ^paged_audio_buffer_data, pLength: ^u64) -> result ---
	paged_audio_buffer_data_allocate_page            :: proc(pData: ^paged_audio_buffer_data, pageSizeInFrames: u64, pInitialData: rawptr, pAllocationCallbacks: ^allocation_callbacks, ppPage: ^^paged_audio_buffer_page) -> result ---
	paged_audio_buffer_data_free_page                :: proc(pData: ^paged_audio_buffer_data, pPage: ^paged_audio_buffer_page, pAllocationCallbacks: ^allocation_callbacks) -> result ---
	paged_audio_buffer_data_append_page              :: proc(pData: ^paged_audio_buffer_data, pPage: ^paged_audio_buffer_page) -> result ---
	paged_audio_buffer_data_allocate_and_append_page :: proc(pData: ^paged_audio_buffer_data, pageSizeInFrames: u32, pInitialData: rawptr, pAllocationCallbacks: ^allocation_callbacks) -> result ---
}


paged_audio_buffer_config :: struct {
	pData: ^paged_audio_buffer_data,  /* Must not be null. */
}

paged_audio_buffer :: struct {
	ds:             data_source_base,
	pData:          ^paged_audio_buffer_data,  /* Audio data is read from here. Cannot be null. */
	pCurrent:       ^paged_audio_buffer_page,
	relativeCursor: u64,                       /* Relative to the current page. */
	absoluteCursor: u64,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	paged_audio_buffer_config_init :: proc(pData: ^paged_audio_buffer_data) -> paged_audio_buffer_config ---

	paged_audio_buffer_init                     :: proc(pConfig: ^paged_audio_buffer_config, pPagedAudioBuffer: ^paged_audio_buffer) -> result ---
	paged_audio_buffer_uninit                   :: proc(pPagedAudioBuffer: ^paged_audio_buffer) ---
	paged_audio_buffer_read_pcm_frames          :: proc(pPagedAudioBuffer: ^paged_audio_buffer, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---   /* Returns MA_AT_END if no more pages available. */
	paged_audio_buffer_seek_to_pcm_frame        :: proc(pPagedAudioBuffer: ^paged_audio_buffer, frameIndex: u64) -> result ---
	paged_audio_buffer_get_cursor_in_pcm_frames :: proc(pPagedAudioBuffer: ^paged_audio_buffer, pCursor: ^u64) -> result ---
	paged_audio_buffer_get_length_in_pcm_frames :: proc(pPagedAudioBuffer: ^paged_audio_buffer, pLength: ^u64) -> result ---
}

pulsewave_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	dutyCycle:  f64,
	amplitude:  f64,
	frequency:  f64,
}

pulsewave :: struct {
	waveform: waveform,
	config:   pulsewave_config,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	pulsewave_config_init :: proc(format: format, channels: u32, sampleRate: u32, dutyCycle: f64, amplitude: f64, frequency: f64) -> pulsewave_config ---

	pulsewave_init              :: proc(pConfig: ^pulsewave_config, pWaveForm: ^pulsewave) -> result ---
	pulsewave_uninit            :: proc(pWaveForm: ^pulsewave) ---
	pulsewave_read_pcm_frames   :: proc(pWaveForm: ^pulsewave, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---
	pulsewave_seek_to_pcm_frame :: proc(pWaveForm: ^pulsewave, frameIndex: u64) -> result ---
	pulsewave_set_amplitude     :: proc(pWaveForm: ^pulsewave, amplitude: f64) -> result ---
	pulsewave_set_frequency     :: proc(pWaveForm: ^pulsewave, frequency: f64) -> result ---
	pulsewave_set_sample_rate   :: proc(pWaveForm: ^pulsewave, sampleRate: u32) -> result ---
	pulsewave_set_duty_cycle    :: proc(pWaveForm: ^pulsewave, dutyCycle: f64) -> result ---
}
