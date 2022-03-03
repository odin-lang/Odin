package miniaudio

when ODIN_OS == .Windows {
	foreign import lib "lib/miniaudio.lib"
} else when ODIN_OS == .Linux {
	foreign import lib "lib/miniaudio.a"
} else {
	foreign import lib "system:miniaudio"
}

/**************************************************************************************************************************************************************

Biquad Filtering

**************************************************************************************************************************************************************/
biquad_coefficient :: struct #raw_union {
	f32: f32,
	s32: i32,
} 

biquad_config :: struct {
	format: format,
	channels: u32,
	b0: f64,
	b1: f64,
	b2: f64,
	a0: f64,
	a1: f64,
	a2: f64,
}

biquad :: struct {
	format:   format,
	channels: u32,
	b0:       biquad_coefficient,
	b1:       biquad_coefficient,
	b2:       biquad_coefficient,
	a1:       biquad_coefficient,
	a2:       biquad_coefficient,
	r1:       [MAX_CHANNELS]biquad_coefficient,
	r2:       [MAX_CHANNELS]biquad_coefficient,
} 

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	biquad_config_init :: proc(format: format, channels: u32, b0, b1, b2, a0, a1, a2: f64) -> biquad_config ---

	biquad_init               :: proc(pConfig: ^biquad_config, pBQ: ^biquad) -> result ---
	biquad_reinit             :: proc(pConfig: ^biquad_config, pBQ: ^biquad) -> result ---
	biquad_process_pcm_frames :: proc(pBQ: ^biquad, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	biquad_get_latency        :: proc(pBQ: ^biquad) -> u32 ---
}


/**************************************************************************************************************************************************************

Low-Pass Filtering

**************************************************************************************************************************************************************/
lpf1_config :: struct {
	format:          format,
	channels:        u32,
	sampleRate:      u32,
	cutoffFrequency: f64,
	q:               f64,
} 
lpf2_config :: lpf1_config

lpf1 :: struct {
	format:   format,
	channels: u32,
	a:        biquad_coefficient,
	r1:       [MAX_CHANNELS]biquad_coefficient,
}

lpf2 :: struct {
	bq: biquad,   /* The second order low-pass filter is implemented as a biquad filter. */
}

lpf_config :: struct {
	format:          format,
	channels:        u32,
	sampleRate:      u32,
	cutoffFrequency: f64,
	order:           u32,    /* If set to 0, will be treated as a passthrough (no filtering will be applied). */
}

lpf :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	lpf1Count:  u32,
	lpf2Count:  u32,
	lpf1:       [1]lpf1,
	lpf2:       [MAX_FILTER_ORDER/2]lpf2,
}


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	lpf1_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency: f64) -> lpf1_config ---
	lpf2_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency, q: f64) -> lpf2_config ---

	lpf1_init               :: proc(pConfig: ^lpf1_config, pLPF: ^lpf1) -> result ---
	lpf1_reinit             :: proc(pConfig: ^lpf1_config, pLPF: ^lpf1) -> result ---
	lpf1_process_pcm_frames :: proc(pLPF: ^lpf1, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	lpf1_get_latency        :: proc(pLPF: ^lpf1) -> u32 ---

	lpf2_init               :: proc(pConfig: ^lpf2_config, pLPF: ^lpf2) -> result ---
	lpf2_reinit             :: proc(pConfig: ^lpf2_config, pLPF: ^lpf2) -> result ---
	lpf2_process_pcm_frames :: proc(pLPF: ^lpf2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	lpf2_get_latency        :: proc(pLPF: ^lpf2) -> u32 ---

	lpf_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency: f64, order: u32) -> lpf_config ---

	lpf_init                :: proc(pConfig: ^lpf_config, pLPF: ^lpf) -> result ---
	lpf_reinit              :: proc(pConfig: ^lpf_config, pLPF: ^lpf) -> result ---
	lpf_process_pcm_frames  :: proc(pLPF: ^lpf, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	lpf_get_latency         :: proc(pLPF: ^lpf) -> u32 ---
}


/**************************************************************************************************************************************************************

High-Pass Filtering

**************************************************************************************************************************************************************/
hpf1_config :: struct {
	format:          format,
	channels:        u32,
	sampleRate:      u32,
	cutoffFrequency: f64,
	q:               f64,
} 
hpf2_config :: hpf1_config

hpf1 :: struct {
	format:   format,
	channels: u32,
	a:        biquad_coefficient,
	r1:       [MAX_CHANNELS]biquad_coefficient,
}

hpf2 :: struct {
	bq: biquad,   /* The second order low-pass filter is implemented as a biquad filter. */
}

hpf_config :: struct {
	format:          format,
	channels:        u32,
	sampleRate:      u32,
	cutoffFrequency: f64,
	order:           u32,    /* If set to 0, will be treated as a passthrough (no filtering will be applied). */
}

hpf :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	hpf1Count:  u32,
	hpf2Count:  u32,
	hpf1:       [1]hpf1,
	hpf2:       [MAX_FILTER_ORDER/2]hpf2,
}


@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	hpf1_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency: f64) -> hpf1_config ---
	hpf2_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency, q: f64) -> hpf2_config ---

	hpf1_init               :: proc(pConfig: ^hpf1_config, pHPF: ^hpf1) -> result ---
	hpf1_reinit             :: proc(pConfig: ^hpf1_config, pHPF: ^hpf1) -> result ---
	hpf1_process_pcm_frames :: proc(pHPF: ^hpf1, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	hpf1_get_latency        :: proc(pHPF: ^hpf1) -> u32 ---

	hpf2_init               :: proc(pConfig: ^hpf2_config, pHPF: ^hpf2) -> result ---
	hpf2_reinit             :: proc(pConfig: ^hpf2_config, pHPF: ^hpf2) -> result ---
	hpf2_process_pcm_frames :: proc(pHPF: ^hpf2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	hpf2_get_latency        :: proc(pHPF: ^hpf2) -> u32 ---

	hpf_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency: f64, order: u32) -> hpf_config ---

	hpf_init                :: proc(pConfig: ^hpf_config, pHPF: ^hpf) -> result ---
	hpf_reinit              :: proc(pConfig: ^hpf_config, pHPF: ^hpf) -> result ---
	hpf_process_pcm_frames  :: proc(pHPF: ^hpf, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	hpf_get_latency         :: proc(pHPF: ^hpf) -> u32 ---
}


/**************************************************************************************************************************************************************

Band-Pass Filtering

**************************************************************************************************************************************************************/
bpf2_config :: struct {
	format:          format,
	channels:        u32,
	sampleRate:      u32,
	cutoffFrequency: f64,
	q:               f64,
}

bpf2 :: struct {
	bq: biquad,   /* The second order band-pass filter is implemented as a biquad filter. */
}

bpf_config :: struct {
	format:          format,
	channels:        u32,
	sampleRate:      u32,
	cutoffFrequency: f64,
	order:           u32,    /* If set to 0, will be treated as a passthrough (no filtering will be applied). */
}

bpf :: struct {
	format:    format,
	channels:  u32,
	bpf2Count: u32,
	bpf2:      [MAX_FILTER_ORDER/2]bpf2,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	bpf2_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency: f64, q: f64) -> bpf2_config ---

	bpf2_init               :: proc(pConfig: ^bpf2_config, pBPF: ^bpf2) -> result ---
	bpf2_reinit             :: proc(pConfig: ^bpf2_config, pBPF: ^bpf2) -> result ---
	bpf2_process_pcm_frames :: proc(pBPF: ^bpf2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	bpf2_get_latency        :: proc(pBPF: ^bpf2) -> u32 ---

	bpf_config_init :: proc(format: format, channels: u32, sampleRate: u32, cutoffFrequency: f64, order: u32) -> bpf_config ---

	bpf_init               :: proc(pConfig: ^bpf_config, pBPF: ^bpf) -> result ---
	bpf_reinit             :: proc(pConfig: ^bpf_config, pBPF: ^bpf) -> result ---
	bpf_process_pcm_frames :: proc(pBPF: ^bpf, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	bpf_get_latency        :: proc(pBPF: ^bpf) -> u32 ---
}


/**************************************************************************************************************************************************************

Notching Filter

**************************************************************************************************************************************************************/
notch_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	q:          f64,
	frequency:  f64,
}
notch2_config :: notch_config

notch2 :: struct {
	bq: biquad,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	notch2_config_init :: proc(format: format, channels: u32, sampleRate: u32, q: f64, frequency: f64) -> notch2_config ---

	notch2_init               :: proc(pConfig: ^notch2_config, pFilter: ^notch2) -> result ---
	notch2_reinit             :: proc(pConfig: ^notch2_config, pFilter: ^notch2) -> result ---
	notch2_process_pcm_frames :: proc(pFilter: ^notch2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	notch2_get_latency        :: proc(pFilter: ^notch2) -> u32 ---
}


/**************************************************************************************************************************************************************

Peaking EQ Filter

**************************************************************************************************************************************************************/
peak_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	gainDB:     f64,
	q:          f64,
	frequency:  f64,
}
peak2_config :: peak_config

peak2 :: struct {
	bq: biquad,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	peak2_config_init :: proc(format: format, channels: u32, sampleRate: u32, gainDB, q, frequency: f64) -> peak2_config ---

	peak2_init               :: proc(pConfig: ^peak2_config, pFilter: ^peak2) -> result ---
	peak2_reinit             :: proc(pConfig: ^peak2_config, pFilter: ^peak2) -> result ---
	peak2_process_pcm_frames :: proc(pFilter: ^peak2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	peak2_get_latency        :: proc(pFilter: ^peak2) -> u32 ---
}


/**************************************************************************************************************************************************************

Low Shelf Filter

**************************************************************************************************************************************************************/
loshelf_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	gainDB:     f64,
	shelfSlope: f64,
	frequency:  f64,
} 
loshelf2_config :: loshelf_config

loshelf2 :: struct {
	bq: biquad,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	loshelf2_config_init :: proc(format: format, channels: u32, sampleRate: u32, gainDB, shelfSlope, frequency: f64) -> loshelf2_config ---

	loshelf2_init               :: proc(pConfig: ^loshelf2_config, pFilter: ^loshelf2) -> result ---
	loshelf2_reinit             :: proc(pConfig: ^loshelf2_config, pFilter: ^loshelf2) -> result ---
	loshelf2_process_pcm_frames :: proc(pFilter: ^loshelf2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	loshelf2_get_latency        :: proc(pFilter: ^loshelf2) -> u32 ---
}


/**************************************************************************************************************************************************************

High Shelf Filter

**************************************************************************************************************************************************************/
hishelf_config :: struct {
	format:     format,
	channels:   u32,
	sampleRate: u32,
	gainDB:     f64,
	shelfSlope: f64,
	frequency:  f64,
} 
hishelf2_config :: hishelf_config

hishelf2 :: struct {
	bq: biquad,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	hishelf2_config_init :: proc(format: format, channels: u32, sampleRate: u32, gainDB, shelfSlope, frequency: f64) -> hishelf2_config ---

	hishelf2_init               :: proc(pConfig: ^hishelf2_config, pFilter: ^hishelf2) -> result ---
	hishelf2_reinit             :: proc(pConfig: ^hishelf2_config, pFilter: ^hishelf2) -> result ---
	hishelf2_process_pcm_frames :: proc(pFilter: ^hishelf2, pFramesOut: rawptr, pFramesIn: rawptr, frameCount: u64) -> result ---
	hishelf2_get_latency        :: proc(pFilter: ^hishelf2) -> u32 ---
}
