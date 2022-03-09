package miniaudio

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else when ODIN_OS == .Linux {
	foreign import lib "lib/miniaudio.a"
} else {
	foreign import lib "system:miniaudio"
}

/************************************************************************************************************************************************************

Encoding
========

Encoders do not perform any format conversion for you. If your target format does not support the format, and error will be returned.

************************************************************************************************************************************************************/

encoder_write_proc            :: proc "c" (pEncoder: ^encoder, pBufferIn: rawptr, bytesToWrite: c.size_t) -> c.size_t        /* Returns the number of bytes written. */
encoder_seek_proc             :: proc "c" (pEncoder: ^encoder, byteOffset: c.int, origin: seek_origin) -> b32
encoder_init_proc             :: proc "c" (pEncoder: ^encoder) -> result
encoder_uninit_proc           :: proc "c" (pEncoder: ^encoder)      
encoder_write_pcm_frames_proc :: proc "c" (pEncoder: ^encoder, pFramesIn: rawptr, frameCount: u64) -> u64

encoder_config :: struct {
	resourceFormat:      resource_format,
	format:              format,
	channels:            u32,
	sampleRate:          u32,
	allocationCallbacks: allocation_callbacks,
}

encoder :: struct {
	config:           encoder_config,
	onWrite:          encoder_write_proc,
	onSeek:           encoder_seek_proc,
	onInit:           encoder_init_proc,
	onUninit:         encoder_uninit_proc,
	onWritePCMFrames: encoder_write_pcm_frames_proc,
	pUserData:        rawptr,
	pInternalEncoder: rawptr, /* <-- The drwav/drflac/stb_vorbis/etc. objects. */
	pFile:            rawptr,    /* FILE*. Only used when initialized with ma_encoder_init_file(). */
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	encoder_config_init      :: proc(resourceFormat: resource_format, format: format, channels: u32, sampleRate: u32) -> encoder_config ---

	encoder_init             :: proc(onWrite: encoder_write_proc, onSeek: encoder_seek_proc, pUserData: rawptr, pConfig: ^encoder_config, pEncoder: ^encoder) -> result ---
	encoder_init_file        :: proc(pFilePath: cstring, pConfig: ^encoder_config, pEncoder: ^encoder) -> result ---
	encoder_init_file_w      :: proc(pFilePath: [^]c.wchar_t, pConfig: ^encoder_config, pEncoder: ^encoder) -> result ---
	encoder_uninit           :: proc(pEncoder: ^encoder) ---
	encoder_write_pcm_frames :: proc(pEncoder: ^encoder, FramesIn: rawptr, frameCount: u64) -> u64 ---
}
