package vendor_jack

import "base:intrinsics"
import "core:c"
log2 :: intrinsics.constant_log2

when ODIN_OS == .Windows {

} else when ODIN_OS == .Linux {
    foreign import jack "system:jack"
} else {
    foreign import jack "system:jack"
}

JACK_MAX_FRAMES :: 4294967295
JACK_LOAD_INIT_LIMIT :: 1024
JACK_DEFAULT_AUDIO_TYPE :: "32 bit float mono audio"
JACK_DEFAULT_MIDI_TYPE :: "8 bit raw midi"

jack_uuid_t :: c.uint64_t
jack_shmsize_t :: c.int32_t
jack_nframes_t :: c.uint32_t
jack_time_t :: c.uint64_t
jack_intclient_t :: c.uint64_t
jack_port_t :: struct {}
jack_client_t :: struct {}
jack_port_id_t :: c.uint32_t
jack_port_type_id_t :: c.uint32_t
jack_default_audio_sample_t :: c.float
jack_native_thread_t :: rawptr

JackOptions :: distinct bit_set[JackOptions_;c.int]
JackOptions_ :: enum c.int {
    NullOption    = 0x00,
    NoStartServer = log2(0x01),
    UseExactName  = log2(0x02),
    ServerName    = log2(0x04),
    LoadName      = log2(0x08),
    LoadInit      = log2(0x10),
    SessionID     = log2(0x20),
}

JackOpenOptions :: JackOptions{.SessionID, .ServerName, .NoStartServer, .UseExactName}
JackLoadOptions :: JackOptions{.LoadInit, .LoadName, .UseExactName}
jack_options_t :: JackOptions

JackStatus :: distinct bit_set[JackStatus_;c.int]
JackStatus_ :: enum c.int {
    Failure       = log2(0x01),
    InvalidOption = log2(0x02),
    NameNotUnique = log2(0x04),
    ServerStarted = log2(0x08),
    ServerFailed  = log2(0x10),
    ServerError   = log2(0x20),
    NoSuchClient  = log2(0x40),
    LoadFailure   = log2(0x80),
    InitFailure   = log2(0x100),
    ShmFailure    = log2(0x200),
    VersionRrror  = log2(0x400),
    BackendError  = log2(0x800),
    ClientZombie  = log2(0x1000),
}

jack_status_t :: JackStatus

JackLatencyCallbackMode :: enum c.int {
    CaptureLatency,
    PlaybackLatency,
}

jack_latency_callback_mode_t :: JackLatencyCallbackMode
JackLatencyCallback :: proc "c" (mode: jack_latency_callback_mode_t, arg: rawptr)

_jack_latency_range :: struct #packed {
    min: jack_nframes_t,
    max: jack_nframes_t,
}
jack_latency_range_t :: _jack_latency_range

JackProcessCallback :: proc "c" (nframes: jack_nframes_t, arg: rawptr) -> c.int

JackThreadCallback :: proc "c" (arg: rawptr) -> rawptr
JackThreadInitCallback :: proc "c" (arg: rawptr)
JackGraphOrderCallback :: proc "c" (arg: rawptr) -> c.int
JackXRunCallback :: proc "c" (arg: rawptr) -> c.int
JackBufferSizeCallback :: proc "c" (nframes: jack_nframes_t, arg: rawptr) -> c.int
JackSampleRateCallback :: proc "c" (nframes: jack_nframes_t, arg: rawptr) -> c.int
JackPortRegistrationCallback :: proc "c" (port: jack_port_id_t, register: c.int, arg: rawptr)
JackClientRegistrationCallback :: proc "c" (name: cstring, register: c.int, arg: rawptr)
JackPortConnectCallback :: proc "c" (a, b: jack_port_id_t, connect: c.int, arg: rawptr)
JackPortRenameCallback :: proc "c" (
    port: jack_port_id_t,
    old_name: cstring,
    new_name: cstring,
    arg: rawptr,
)
JackFreewheelCallback :: proc "c" (starting: c.int, arg: rawptr)
JackShutdownCallback :: proc "c" (arg: rawptr)
JackInfoShutdownCallback :: proc "c" (code: jack_status_t, reason: cstring, arg: rawptr)
JackErrorCallback :: proc "c" (msg: cstring)
JackInfoCallback :: proc "c" (msg: cstring)

jack_error_callback :: ^JackErrorCallback
jack_info_callback :: ^JackInfoCallback

JackPortFlags :: distinct bit_set[JackPortFlags_;c.ulong]
JackPortFlags_ :: enum c.int {
    PortIsInput    = log2(0x1),
    PortIsOutput   = log2(0x2),
    PortIsPhysical = log2(0x4),
    PortCanMonitor = log2(0x8),
    PortIsTerminal = log2(0x10),
    PortIsCV       = log2(0x20),
    PortIsMIDI2    = log2(0x20),
}

jack_transport_state_t :: enum c.int {
    TransportStopped     = 0,
    TransportRolling     = 1,
    TransportLooping     = 2,
    TransportStarting    = 3,
    TransportNetStarting = 4,
}

jack_unique_t :: c.uint64_t

jack_position_bits_t :: bit_set[jack_position_bits_t_;c.int]
jack_position_bits_t_ :: enum c.int {
    JackPositionBBT      = log2(0x10), /**< Bar, Beat, Tick */
    JackPositionTimecode = log2(0x20), /**< External timecode */
    JackBBTFrameOffset   = log2(0x40), /**< Frame offset of BBT information */
    JackAudioVideoRatio  = log2(0x80), /**< audio frames per video frame */
    JackVideoFrameOffset = log2(0x100), /**< frame offset of first video frame */
    JackTickDouble       = log2(0x200), /**< double-resolution tick */
}

JACK_POSITION_MASK :: jack_position_bits_t{.JackPositionBBT, .JackPositionTimecode}

_jack_position :: struct #packed {
    unique_1:                     jack_unique_t,
    usecs:                        jack_time_t,
    frame_rate:                   jack_nframes_t,
    frame:                        jack_nframes_t,
    valid:                        jack_position_bits_t,
    bar:                          c.int32_t,
    beat:                         c.int32_t,
    tick:                         c.int32_t,
    bar_start_tick:               c.double,
    beats_per_bar:                c.float,
    beat_type:                    c.float,
    ticks_per_beat:               c.double,
    beats_per_minute:             c.double,
    frame_time:                   c.double,
    next_time:                    c.double,
    bbt_offset:                   jack_nframes_t,
    audio_frames_per_video_frame: c.float,
    video_offset:                 jack_nframes_t,
    tick_double:                  c.double,
    padding:                      [5]c.int32_t,
    unique_2:                     jack_unique_t,
}

jack_position_t :: _jack_position
JackSyncCallback :: proc "c" (
    state: jack_transport_state_t,
    pos: ^jack_position_t,
    arg: rawptr,
) -> c.int
JackTimebaseCallback :: proc "c" (
    state: jack_transport_state_t,
    nframes: jack_nframes_t,
    pos: ^jack_position_t,
    new_pos: c.int,
    arg: rawptr,
)

@(default_calling_convention = "c", link_prefix = "jack_")
foreign jack {
    get_version :: proc(major_ptr, minor_ptr, micro_ptr, proto_ptr: ^c.int) ---
    get_version_string :: proc() -> cstring ---
    client_open :: proc(client_name: cstring, options: jack_options_t, status: ^jack_status_t, #c_vararg args: ..any) -> ^jack_client_t ---
    client_close :: proc(client: ^jack_client_t) -> c.int ---
    client_name_size :: proc() -> c.int ---
    get_client_name :: proc(client: ^jack_client_t) -> ^c.char ---
    get_uuid_for_client_name :: proc(client: ^jack_client_t, client_name: cstring) -> ^c.char ---
    get_client_name_by_uuid :: proc(client: ^jack_client_t, client_uuid: cstring) -> ^c.char ---
    activate :: proc(client: ^jack_client_t) -> c.int ---
    eactivate :: proc(client: ^jack_client_t) -> c.int ---
    get_client_pid :: proc(name: cstring) -> c.int ---
    client_thread_id :: proc(client: ^jack_client_t) -> jack_native_thread_t ---
    is_real_time :: proc(client: ^jack_client_t) -> c.int ---
    cycle_wait :: proc(client: ^jack_client_t) -> jack_nframes_t ---
    cycle_signal :: proc(client: ^jack_client_t, status: c.int) ---
    set_process_thread :: proc(client: ^jack_client_t, thread_callback: JackThreadCallback, arg: rawptr) -> c.int ---
    set_thread_init_callback :: proc(client: ^jack_client_t, thread_init_callback: JackThreadCallback, arg: rawptr) -> c.int ---
    on_shutdown :: proc(client: ^jack_client_t, shutdown_callback: JackShutdownCallback, arg: rawptr) ---
    on_info_shutdown :: proc(client: ^jack_client_t, shutdown_callback: JackInfoShutdownCallback, arg: rawptr) ---
    set_process_callback :: proc(client: ^jack_client_t, process_callback: JackProcessCallback, arg: rawptr) -> c.int ---
    set_freewheel_callback :: proc(client: ^jack_client_t, freewheel_callback: JackFreewheelCallback, arg: rawptr) -> c.int ---
    set_buffer_size_callback :: proc(client: ^jack_client_t, bufsize_callback: JackBufferSizeCallback, arg: rawptr) -> c.int ---
    set_sample_rate_callback :: proc(client: ^jack_client_t, srate_callback: JackSampleRateCallback, arg: rawptr) -> c.int ---
    set_client_registration_callback :: proc(client: ^jack_client_t, registration_callback: JackClientRegistrationCallback, arg: rawptr) -> c.int ---
    set_port_registration_callback :: proc(client: ^jack_client_t, registration_callback: JackPortRegistrationCallback, arg: rawptr) -> c.int ---
    set_port_rename_callback :: proc(client: ^jack_client_t, rename_callback: JackPortRenameCallback, arg: rawptr) -> c.int ---
    set_graph_order_callback :: proc(client: ^jack_client_t, graph_callbback: JackGraphOrderCallback, arg: rawptr) -> c.int ---
    set_xrun_callback :: proc(client: ^jack_client_t, xrun_callback: JackXRunCallback, arg: rawptr) -> c.int ---
    set_latency_callback :: proc(client: ^jack_client_t, latency_callback: JackLatencyCallback, arg: rawptr) -> c.int ---
    set_freewheel :: proc(client: ^jack_client_t, onoff: c.int) -> c.int ---
    set_buffer_size :: proc(client: ^jack_client_t, nframes: jack_nframes_t) -> c.int ---
    get_sample_rate :: proc(client: ^jack_client_t) -> jack_nframes_t ---
    get_buffer_size :: proc(client: ^jack_client_t) -> jack_nframes_t ---
    engine_takeover_timebase :: proc(client: ^jack_client_t) -> c.int ---
    cpu_load :: proc(client: ^jack_client_t) -> c.float ---

    port_register :: proc(client: ^jack_client_t, port_name: cstring, port_type: cstring, flags: JackPortFlags, buffer_size: c.ulong) -> ^jack_port_t ---
    port_unregister :: proc(client: ^jack_client_t, port: ^jack_port_t) -> c.int ---
    port_get_buffer :: proc(port: ^jack_port_t, nframes: jack_nframes_t) -> rawptr ---
    port_uuid :: proc(port: ^jack_port_t) -> jack_uuid_t ---
    port_name :: proc(port: ^jack_port_t) -> cstring ---
    port_short_name :: proc(port: ^jack_port_t) -> cstring ---
    port_flags :: proc(port: ^jack_port_t) -> JackPortFlags ---
    port_type :: proc(port: ^jack_port_t) -> cstring ---
    port_type_id :: proc(port: ^jack_port_t) -> jack_port_type_id_t ---
    port_is_mine :: proc(client: ^jack_client_t, port: ^jack_port_t) -> c.int ---
    port_connected :: proc(port: ^jack_port_t) -> c.int ---
    port_connected_to :: proc(port: ^jack_port_t, port_name: cstring) -> ^cstring ---
    port_get_all_connections :: proc(client: ^jack_client_t, port: ^jack_port_t) -> ^cstring ---
    port_rename :: proc(client: ^jack_client_t, port: ^jack_port_t, port_name: cstring) -> c.int ---
    port_set_alias :: proc(port: ^jack_port_t, alias: cstring) -> c.int ---
    port_unset_alias :: proc(port: ^jack_port_t, alias: cstring) -> c.int ---
    port_get_aliases :: proc(port: ^jack_port_t, aliases: [2]^cstring) -> c.int ---
    port_request_monitor :: proc(port: ^jack_port_t, onoff: c.int) -> c.int ---
    port_request_monitor_by_name :: proc(client: ^jack_client_t, port_name: cstring, onoff: c.int) -> c.int ---
    port_ensure_monitor :: proc(port: ^jack_port_t, onoff: c.int) -> c.int ---
    port_monitoring_input :: proc(port: ^jack_port_t) -> c.int ---
    connect :: proc(client: ^jack_client_t, source_port: cstring, destination_port: cstring) -> c.int ---
    disconnect :: proc(client: ^jack_client_t, source_port: cstring, destination_port: cstring) -> c.int ---
    port_disconnect :: proc(client: ^jack_client_t, port: ^jack_port_t) -> c.int ---
    port_name_size :: proc() -> c.int ---
    port_type_size :: proc() -> c.int ---
    port_type_get_buffer_size :: proc(client: ^jack_client_t, port_type: cstring) -> c.size_t ---
    port_get_latency_range :: proc(port: ^jack_port_t, mode: jack_latency_callback_mode_t, range: ^jack_latency_range_t) ---
    port_set_latency_range :: proc(port: ^jack_port_t, mode: jack_latency_callback_mode_t, range: ^jack_latency_range_t) ---
    recompute_total_latencies :: proc(client: ^jack_client_t) -> c.int ---
    get_ports :: proc(client: ^jack_client_t, port_name_pattern: cstring, type_name_pattern: cstring, flags: JackPortFlags) -> [^]cstring ---
    port_by_name :: proc(client: ^jack_client_t, port_name: cstring) -> ^jack_port_t ---
    port_by_id :: proc(client: ^jack_client_t, port_id: jack_port_id_t) -> ^jack_port_t ---
    frames_since_cycle_start :: proc(client: ^jack_client_t) -> jack_nframes_t ---
    frames_time :: proc(client: ^jack_client_t) -> jack_nframes_t ---
    last_frame_time :: proc(client: ^jack_client_t) -> jack_nframes_t ---
    get_cycle_times :: proc(client: ^jack_client_t, current_frames: ^jack_nframes_t, current_usecs: ^jack_time_t, next_usecs: ^jack_time_t, period_usecs: ^c.float) -> c.int ---
    frames_to_time :: proc(client: ^jack_client_t, frames: jack_nframes_t) -> jack_time_t ---
    time_to_frames :: proc(client: ^jack_client_t, time: jack_time_t) -> jack_nframes_t ---
    get_time :: proc() -> jack_time_t ---
    set_error_function :: proc(func: jack_error_callback) ---
    set_info_function :: proc(func: jack_info_callback) ---
    free :: proc(ptr: rawptr) ---
}
