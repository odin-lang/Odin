package miniaudio

import "core:c"

foreign import lib { LIB }

/************************************************************************************************************************************************************

Decoding
========

Decoders are independent of the main device API. Decoding APIs can be called freely inside the device's data callback, but they are not thread safe unless
you do your own synchronization.

************************************************************************************************************************************************************/

decoding_backend_config :: struct {
	preferredFormat: format,
	seekPointCount: u32,   /* Set to > 0 to generate a seektable if the decoding backend supports it. */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	decoding_backend_config_init :: proc(preferredFormat: format, seekPointCount: u32) -> decoding_backend_config ---
}


decoding_backend_vtable :: struct {
	onInit:          proc "c" (pUserData: rawptr, onRead: decoder_read_proc, onSeek: decoder_seek_proc, onTell: decoder_tell_proc, pReadSeekTellUserData: rawptr, pConfig: ^decoding_backend_config, pAllocationCallbacks: ^allocation_callbacks, ppBackend: ^^data_source) -> result,
	onInitFile:      proc "c" (pUserData: rawptr, pFilePath: cstring, pConfig: ^decoding_backend_config, pAllocationCallbacks: ^allocation_callbacks, ppBackend: ^^data_source) -> result,               	 /* Optional. */
	onInitFileW:     proc "c" (pUserData: rawptr, pFilePath: [^]c.wchar_t, pConfig: ^decoding_backend_config, pAllocationCallbacks: ^allocation_callbacks, ppBackend: ^^data_source) -> result,            /* Optional. */
	onInitMemory:    proc "c" (pUserData: rawptr, pData: rawptr, dataSize: c.size_t, pConfig: ^decoding_backend_config, pAllocationCallbacks: ^allocation_callbacks, ppBackend: ^^data_source) -> result,  /* Optional. */
	onUninit:        proc "c" (pUserData: rawptr, pBackend: ^data_source, pAllocationCallbacks: ^allocation_callbacks),
}


decoder_read_proc :: proc "c" (pDecoder: ^decoder, pBufferOut: rawptr, bytesToRead: c.size_t, pBytesRead: ^c.size_t) -> result         /* Returns the number of bytes read. */
decoder_seek_proc :: proc "c" (pDecoder: ^decoder, byteOffset: i64, origin: seek_origin) -> result
decoder_tell_proc :: proc "c" (pDecoder: ^decoder, pCursor: ^i64) -> result

decoder_config :: struct {
	format:                 format, /* Set to 0 or ma_format_unknown to use the stream's internal format. */
	channels:               u32,    /* Set to 0 to use the stream's internal channels. */
	sampleRate:             u32,    /* Set to 0 to use the stream's internal sample rate. */
	channelMap:             [^]channel,
	channelMixMode:         channel_mix_mode,
	ditherMode:             dither_mode,
	resampling:             resampler_config,
	allocationCallbacks:    allocation_callbacks,
	encodingFormat:         encoding_format,
	seekPointCount:         u32,   /* When set to > 0, specifies the number of seek points to use for the generation of a seek table. Not all decoding backends support this. */
	ppCustomBackendVTables: ^[^]decoding_backend_vtable,
	customBackendCount:     u32,
	pCustomBackendUserData: rawptr,
}

decoder :: struct  {
	ds:                     data_source_base,
	pBackend:               ^data_source,               /* The decoding backend we'll be pulling data from. */
	pBackendVTable:         ^decoding_backend_vtable,   /* The vtable for the decoding backend. This needs to be stored so we can access the onUninit() callback. */
	pBackendUserData:       rawptr,
	onRead:                 decoder_read_proc,
	onSeek:                 decoder_seek_proc,
	onTell:                 decoder_tell_proc,
	pUserData:              rawptr,
	readPointerInPCMFrames: u64,      /* In output sample rate. Used for keeping track of how many frames are available for decoding. */
	outputFormat:           format,
	outputChannels:         u32,
	outputSampleRate:       u32,
	converter:              data_converter,    /* <-- Data conversion is achieved by running frames through this. */
	pInputCache:            rawptr,            /* In input format. Can be null if it's not needed. */
	inputCacheCap:          u64,               /* The capacity of the input cache. */
	inputCacheConsumed:     u64,               /* The number of frames that have been consumed in the cache. Used for determining the next valid frame. */
	inputCacheRemaining:    u64,               /* The number of valid frames remaining in the cahce. */
	allocationCallbacks:    allocation_callbacks,
	data: struct #raw_union {
		vfs: struct {
			pVFS: ^vfs,
			file: vfs_file,
		},
		memory: struct {
			pData: [^]u8,
			dataSize: c.size_t,
			currentReadPos: c.size_t,
		}, /* Only used for decoders that were opened against a block of memory. */
	},
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	decoder_config_init         :: proc(outputFormat: format, outputChannels, outputSampleRate: u32) -> decoder_config ---
	decoder_config_init_default :: proc() -> decoder_config ---

	decoder_init        :: proc(onRead: decoder_read_proc, onSeek: decoder_seek_proc, pUserData: rawptr, pConfig: ^decoder_config, pDecoder: ^decoder) -> result ---
	decoder_init_memory :: proc(pData: rawptr, dataSize: c.size_t,   pConfig: ^decoder_config, pDecoder: ^decoder) -> result ---
	decoder_init_vfs    :: proc(pVFS: ^vfs, pFilePath: cstring,      pConfig: ^decoder_config, pDecoder: ^decoder) -> result ---
	decoder_init_vfs_w  :: proc(pVFS: ^vfs, pFilePath: [^]c.wchar_t, pConfig: ^decoder_config, pDecoder: ^decoder) -> result ---
	decoder_init_file   :: proc(pFilePath: cstring,      pConfig: ^decoder_config, pDecoder: ^decoder) -> result ---
	decoder_init_file_w :: proc(pFilePath: [^]c.wchar_t, pConfig: ^decoder_config, pDecoder: ^decoder) -> result ---

	/*
	Uninitializes a decoder.
	*/
	decoder_uninit :: proc(pDecoder: ^decoder) -> result ---

	/*
	Reads PCM frames from the given decoder.

	This is not thread safe without your own synchronization.
	*/
	decoder_read_pcm_frames :: proc(pDecoder: ^decoder, pFramesOut: rawptr, frameCount: u64, pFramesRead: ^u64) -> result ---

	/*
	Seeks to a PCM frame based on it's absolute index.

	This is not thread safe without your own synchronization.
	*/
	decoder_seek_to_pcm_frame :: proc(pDecoder: ^decoder, frameIndex: u64) -> result ---

	/*
	Retrieves the decoder's output data format.
	*/
	decoder_get_data_format :: proc(pDecoder: ^decoder, pFormat: ^format, pChannels, pSampleRate: ^u32, pChannelMap: ^channel, channelMapCap: c.size_t) -> result ---

	/*
	Retrieves the current position of the read cursor in PCM frames.
	*/
	decoder_get_cursor_in_pcm_frames :: proc(pDecoder: ^decoder, pCursor: ^u64) -> result ---

	/*
	Retrieves the length of the decoder in PCM frames.

	Do not call this on streams of an undefined length, such as internet radio.

	If the length is unknown or an error occurs, 0 will be returned.

	This will always return 0 for Vorbis decoders. This is due to a limitation with stb_vorbis in push mode which is what miniaudio
	uses internally.

	For MP3's, this will decode the entire file. Do not call this in time critical scenarios.

	This function is not thread safe without your own synchronization.
	*/
	decoder_get_length_in_pcm_frames :: proc(pDecoder: ^decoder, pLength: ^u64) -> result ---

	/*
	Retrieves the number of frames that can be read before reaching the end.

	This calls `ma_decoder_get_length_in_pcm_frames()` so you need to be aware of the rules for that function, in
	particular ensuring you do not call it on streams of an undefined length, such as internet radio.

	If the total length of the decoder cannot be retrieved, such as with Vorbis decoders, `MA_NOT_IMPLEMENTED` will be
	returned.
	*/
	decoder_get_available_frames :: proc(pDecoder: ^decoder, pAvailableFrames: ^u64) -> result ---

	/*
	Helper for opening and decoding a file into a heap allocated block of memory. Free the returned pointer with ma_free(). On input,
	pConfig should be set to what you want. On output it will be set to what you got.
	*/
	decode_from_vfs :: proc(pVFS: ^vfs, pFilePath: cstring,    pConfig: ^decoder_config, pFrameCountOut: ^u64, ppPCMFramesOut: ^rawptr) -> result ---
	decode_file     :: proc(pFilePath: cstring,                pConfig: ^decoder_config, pFrameCountOut: ^u64, ppPCMFramesOut: ^rawptr) -> result ---
	decode_memory   :: proc(pData: rawptr, dataSize: c.size_t, pConfig: ^decoder_config, pFrameCountOut: ^u64, ppPCMFramesOut: ^rawptr) -> result ---
}
