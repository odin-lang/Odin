package miniaudio

when ODIN_OS == .Windows { foreign import lib "lib/miniaudio.lib" }
when ODIN_OS == .Linux   { foreign import lib "lib/miniaudio.a" }

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	Adjust buffer size based on a scaling factor.

	This just multiplies the base size by the scaling factor, making sure it's a size of at least 1.
	*/
	scale_buffer_size :: proc(baseBufferSize: u32, scale: f32) -> u32 ---

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
	Clips f32 samples.
	*/
	clip_samples_f32 :: proc(p: [^]f32, sampleCount: u64) ---

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


	/*
	Helper for converting a linear factor to gain in decibels.
	*/
	factor_to_gain_db :: proc(factor: f32) -> f32 ---

	/*
	Helper for converting gain in decibels to a linear factor.
	*/
	gain_db_to_factor :: proc(gain: f32) -> f32 ---
}

zero_pcm_frames :: #force_inline proc "c" (p: rawptr, frameCount: u64, format: format, channels: u32) { 
	silence_pcm_frames(p, frameCount, format, channels)
}

offset_pcm_frames_ptr_f32 :: #force_inline proc "c" (p: [^]f32, offsetInFrames: u64, channels: u32) -> [^]f32 {
	return cast([^]f32)offset_pcm_frames_ptr(p, offsetInFrames, .f32, channels)
}
offset_pcm_frames_const_ptr_f32 :: #force_inline proc "c" (p: [^]f32, offsetInFrames: u64, channels: u32) -> [^]f32 {
	return cast([^]f32)offset_pcm_frames_ptr(p, offsetInFrames, .f32, channels)
}

clip_pcm_frames_f32 :: #force_inline proc "c" (p: [^]f32, frameCount: u64, channels: u32) { 
	clip_samples_f32(p, frameCount*u64(channels)) 
}


data_source :: struct {}

data_source_vtable :: struct {
	onRead:          proc "c" (pDataSource: ^data_source, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result,
	onSeek:          proc "c" (pDataSource: ^data_source, frameIndex: u64) -> result,
	onMap:           proc "c" (pDataSource: ^data_source, ppFramesOut: ^rawptr, pFrameCount: ^u64) -> result,   /* Returns MA_AT_END if the end has been reached. This should be considered successful. */
	onUnmap:         proc "c" (pDataSource: ^data_source, frameCount: u64) -> result,
	onGetDataFormat: proc "c" (pDataSource: ^data_source, pFormat: ^format, pChannels: ^u32, pSampleRate: ^u32) -> result,
	onGetCursor:     proc "c" (pDataSource: ^data_source, pCursor: ^u64) -> result,
	onGetLength:     proc "c" (pDataSource: ^data_source, pLength: ^u64) -> result,
} 
data_source_callbacks :: data_source_vtable  /* TODO: Remove ma_data_source_callbacks in version 0.11. */

data_source_get_next_proc :: proc "c" (pDataSource: ^data_source) -> ^data_source

data_source_config :: struct {
	vtable: ^data_source_vtable, /* Can be null, which is useful for proxies. */
}

data_source_base :: struct {
	cb: data_source_callbacks,    /* TODO: Remove this. */

	/* Variables below are placeholder and not yet used. */
	vtable:           ^data_source_vtable,
	rangeBegInFrames: u64,
	rangeEndInFrames: u64,                   /* Set to -1 for unranged (default). */
	loopBegInFrames:  u64,                   /* Relative to rangeBegInFrames. */
	loopEndInFrames:  u64,                   /* Relative to rangeBegInFrames. Set to -1 for the end of the range. */
	pCurrent:         ^data_source,                  /* When non-NULL, the data source being initialized will act as a proxy and will route all operations to pCurrent. Used in conjunction with pNext/onGetNext for seamless chaining. */
	pNext:            ^data_source,                  /* When set to NULL, onGetNext will be used. */
	onGetNext:        ^data_source_get_next_proc,   /* Will be used when pNext is NULL. If both are NULL, no next will be used. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	ma_data_source_config_init :: proc() -> data_source_config ---
	
	data_source_init                     :: proc(pConfig: ^data_source_config, pDataSource: ^data_source) -> result ---
	data_source_uninit                   :: proc(pDataSource: ^data_source) ---
	data_source_read_pcm_frames          :: proc(pDataSource: ^data_source, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64, loop: b32) -> result ---   /* Must support pFramesOut = NULL in which case a forward seek should be performed. */
	data_source_seek_pcm_frames          :: proc(pDataSource: ^data_source, frameCount: u64, pFramesSeeked: ^u64, loop: b32) -> result --- /* Can only seek forward. Equivalent to ma_data_source_read_pcm_frames(pDataSource, NULL, frameCount); */
	data_source_seek_to_pcm_frame        :: proc(pDataSource: ^data_source, frameIndex: u64) -> result ---
	data_source_map                      :: proc(pDataSource: ^data_source, ppFramesOut: ^rawptr, pFrameCount: ^u64) -> result ---   /* Returns MA_NOT_IMPLEMENTED if mapping is not supported. */
	data_source_unmap                    :: proc(pDataSource: ^data_source, frameCount: u64) -> result ---       /* Returns MA_AT_END if the end has been reached. */
	data_source_get_data_format          :: proc(pDataSource: ^data_source, pFormat: ^format, pChannels: ^u32, pSampleRate: ^u32) -> result ---
	data_source_get_cursor_in_pcm_frames :: proc(pDataSource: ^data_source, pCursor: ^u64) -> result ---
	data_source_get_length_in_pcm_frames :: proc(pDataSource: ^data_source, pLength: ^u64) -> result ---    /* Returns MA_NOT_IMPLEMENTED if the length is unknown or cannot be determined. Decoders can return this. */
	// #if defined(MA_EXPERIMENTAL__DATA_LOOPING_AND_CHAINING)
	// MA_API ma_result ma_data_source_set_range_in_pcm_frames(ma_data_source* pDataSource, ma_uint64 rangeBegInFrames, ma_uint64 rangeEndInFrames);
	// MA_API void ma_data_source_get_range_in_pcm_frames(ma_data_source* pDataSource, ma_uint64* pRangeBegInFrames, ma_uint64* pRangeEndInFrames);
	// MA_API ma_result ma_data_source_set_loop_point_in_pcm_frames(ma_data_source* pDataSource, ma_uint64 loopBegInFrames, ma_uint64 loopEndInFrames);
	// MA_API void ma_data_source_get_loop_point_in_pcm_frames(ma_data_source* pDataSource, ma_uint64* pLoopBegInFrames, ma_uint64* pLoopEndInFrames);
	// MA_API ma_result ma_data_source_set_current(ma_data_source* pDataSource, ma_data_source* pCurrentDataSource);
	// MA_API ma_data_source* ma_data_source_get_current(ma_data_source* pDataSource);
	// MA_API ma_result ma_data_source_set_next(ma_data_source* pDataSource, ma_data_source* pNextDataSource);
	// MA_API ma_data_source* ma_data_source_get_next(ma_data_source* pDataSource);
	// MA_API ma_result ma_data_source_set_next_callback(ma_data_source* pDataSource, ma_data_source_get_next_proc onGetNext);
	// MA_API ma_data_source_get_next_proc ma_data_source_get_next_callback(ma_data_source* pDataSource);
	// #endif
}


audio_buffer_ref :: struct {
	ds:           data_source_base,
	format:       format,
	channels:     u32,
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