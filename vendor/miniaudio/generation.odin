package miniaudio

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else when ODIN_OS == .Linux {
	foreign import lib "lib/miniaudio.a"
} else {
	foreign import lib "system:miniaudio"
}

waveform_type :: enum c.int {
	sine,
	square,
	triangle,
	sawtooth,
}

waveform_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	type:       waveform_type,
	amplitude:  f64,
	frequency:  f64,
}


waveform :: struct {
	ds:      data_source_base,
	config:  waveform_config,
	advance: f64,
	time:    f64,
}


noise_type :: enum c. int {
	white,
	pink,
	brownian,
}

noise_config :: struct {
	format:            format,
	channels:          u32,
	type:              noise_type,
	seed:              i32,
	amplitude:         f64,
	duplicateChannels: b32,
}

noise :: struct {
	ds:     data_source_vtable,
	config: noise_config,
	lcg:    lcg,
	state: struct #raw_union {
		pink: struct {
			bin:          [MAX_CHANNELS][16]f64,
			accumulation: [MAX_CHANNELS]f64,
			counter:      [MAX_CHANNELS]u32,
		},
		brownian: struct {
			accumulation: [MAX_CHANNELS]f64,
		},
	},
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	waveform_config_init :: proc(format: format, channels: u32, sampleRate: u32, type: waveform_type, amplitude: f64, frequency: f64) -> waveform_config ---

	waveform_init              :: proc(pConfig: ^waveform_config, pWaveform: ^waveform) -> result ---
	waveform_uninit            :: proc(pWaveform: ^waveform) ---
	waveform_read_pcm_frames   :: proc(pWaveform: ^waveform, pFramesOut: rawptr, frameCount: u64) -> u64 ---
	waveform_seek_to_pcm_frame :: proc(pWaveform: ^waveform, frameIndex: u64) -> result ---
	waveform_set_amplitude     :: proc(pWaveform: ^waveform, amplitude: f64) -> result ---
	waveform_set_frequency     :: proc(pWaveform: ^waveform, frequency: f64) -> result ---
	waveform_set_type          :: proc(pWaveform: ^waveform, type: waveform_type) -> result ---
	waveform_set_sample_rate   :: proc(pWaveform: ^waveform, sampleRate: u32) -> result ---

	noise_config_init :: proc(format: format, channels: u32, type: noise_type, seed: i32, amplitude: f64) -> noise_config ---

	noise_init            :: proc(pConfig: ^noise_config, pNoise: ^noise) -> result ---
	noise_uninit          :: proc(pNoise: ^noise) ---
	noise_read_pcm_frames :: proc(pNoise: ^noise, pFramesOut: rawptr, frameCount: u64) -> u64 ---
	noise_set_amplitude   :: proc(pNoise: ^noise, amplitude: f64) -> result ---
	noise_set_seed        :: proc(pNoise: ^noise, seed: i32) -> result ---
	noise_set_type        :: proc(pNoise: ^noise, type: noise_type) -> result ---
}
