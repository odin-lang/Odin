/*
Created in 2009, the GGPO networking SDK pioneered the use of rollback networking in peer-to-peer games.
It's designed specifically to hide network latency in fast paced, twitch style games which require very
precise inputs and frame perfect execution.

Traditional techniques account for network transmission time by adding delay to a players input, resulting
in a sluggish, laggy game-feel.  Rollback networking uses input prediction and speculative execution to
send player inputs to the game immediately, providing the illusion of a zero-latency network. Using rollback,
the same timings, reactions visual and audio queues, and muscle memory your players build up playing offline
translate directly online.  The GGPO networking SDK is designed to make incorporating rollback networking
into new and existing games as easy as possible.
*/
package vendor_ggpo

foreign import lib "GGPO.lib"

import c "core:c/libc"

Session :: distinct rawptr

MAX_PLAYERS              ::  4
MAX_PREDICTION_FRAMES    ::  8
MAX_SPECTATORS           :: 32

SPECTATOR_INPUT_INTERVAL ::  4

PlayerHandle :: distinct c.int
PlayerType :: enum c.int {
	LOCAL,
	REMOTE,
	SPECTATOR,
}


// The Player structure used to describe players in add_player
//
// size: Should be set to the size_of(Player)
//
// type: One of the PlayerType values describing how inputs should be handled
//       Local players must have their inputs updated every frame via
//       add_local_inputs.  Remote players values will come over the
//       network.
//
// player_num: The player number.  Should be between 1 and the number of players
//       In the game (e.g. in a 2 player game, either 1 or 2).
//
// If type == PLAYERTYPE_REMOTE:
//
// remote.ip_address:  The ip address of the ggpo session which will host this
//       player.
//
// remote.port: The port where udp packets should be sent to reach this player.
//       All the local inputs for this session will be sent to this player at
//       ip_address:port.
Player :: struct {
	size:       c.int,
	type:       PlayerType,
	player_num: c.int,
	using u: struct #raw_union {
		local: struct {},
		remote: struct {
			ip_address: [32]byte,
			port: u16,
		},
	},
}

LocalEndpoint :: struct {
	player_num: c.int,
}

ErrorCode :: enum c.int {
	OK                    = 0,
	SUCCESS               = 0,
	GENERAL_FAILURE       = -1,
	INVALID_SESSION       = 1,
	INVALID_PLAYER_HANDLE = 2,
	PLAYER_OUT_OF_RANGE   = 3,
	PREDICTION_THRESHOLD  = 4,
	UNSUPPORTED           = 5,
	NOT_SYNCHRONIZED      = 6,
	IN_ROLLBACK           = 7,
	INPUT_DROPPED         = 8,
	PLAYER_DISCONNECTED   = 9,
	TOO_MANY_SPECTATORS   = 10,
	INVALID_REQUEST       = 11,
}

INVALID_HANDLE :: PlayerHandle(-1)

// The EventCode enumeration describes what type of event just happened.
//
// CONNECTED_TO_PEER - Handshake with the game running on the
// other side of the network has been completed.
//
// SYNCHRONIZING_WITH_PEER - Beginning the synchronization
// process with the client on the other end of the networking.  The count
// and total fields in the u.synchronizing struct of the Event
// object indicate progress.
//
// SYNCHRONIZED_WITH_PEER - The synchronziation with this
// peer has finished.
//
// RUNNING - All the clients have synchronized.  You may begin
// sending inputs with synchronize_inputs.
//
// DISCONNECTED_FROM_PEER - The network connection on
// the other end of the network has closed.
//
// TIMESYNC - The time synchronziation code has determined
// that this client is too far ahead of the other one and should slow
// down to ensure fairness.  The u.timesync.frames_ahead parameter in
// the Event object indicates how many frames the client is.
EventCode :: enum c.int {
	CONNECTED_TO_PEER            = 1000,
	SYNCHRONIZING_WITH_PEER      = 1001,
	SYNCHRONIZED_WITH_PEER       = 1002,
	RUNNING                      = 1003,
	DISCONNECTED_FROM_PEER       = 1004,
	TIMESYNC                     = 1005,
	CONNECTION_INTERRUPTED       = 1006,
	CONNECTION_RESUMED           = 1007,
}

// The Event structure contains an asynchronous event notification sent
// by the on_event callback.  See EventCode, above, for a detailed
// explanation of each event.
Event :: struct {
	code: EventCode,
	using u: struct #raw_union {
		connected: struct {
			player: PlayerHandle,
		},
		synchronizing: struct {
			player: PlayerHandle,
			count:  c.int,
			total:  c.int,
		},
		synchronized: struct {
			player: PlayerHandle,
		},
		disconnected: struct {
			player: PlayerHandle,
		},
		timesync: struct {
			frames_ahead: c.int,
		},
		connection_interrupted: struct {
			player:             PlayerHandle,
			disconnect_timeout: c.int,
		},
		connection_resumed: struct {
			player: PlayerHandle,
		},
	},
}

//
// The SessionCallbacks structure contains the callback functions that
// your application must implement.  GGPO.net will periodically call these
// functions during the game.  All callback functions must be implemented.
//
SessionCallbacks :: struct {
	// begin_game callback - This callback has been deprecated.  You must
	// implement it, but should ignore the 'game' parameter.
	begin_game: proc "c" (game: cstring) -> bool,

	// save_game_state - The client should allocate a buffer, copy the
	// entire contents of the current game state into it, and copy the
	// length into the len parameter.  Optionally, the client can compute
	// a checksum of the data and store it in the checksum argument.
	save_game_state: proc "c" (buffer: ^[^]byte, len: ^c.int, checksum: ^c.int, frame: c.int) -> bool,

	// load_game_state - GGPO.net will call this function at the beginning
	// of a rollback.  The buffer and len parameters contain a previously
	// saved state returned from the save_game_state function.  The client
	// should make the current game state match the state contained in the
	// buffer.
	load_game_state: proc "c" (buffer: [^]byte, len: c.int) -> bool,

	// log_game_state - Used in diagnostic testing.  The client should use
	// the log function to write the contents of the specified save
	// state in a human readible form.
	log_game_state: proc "c" (filename: cstring, buffer: [^]byte, len: c.int) -> bool,

	// free_buffer - Frees a game state allocated in save_game_state.  You
	// should deallocate the memory contained in the buffer.
	free_buffer: proc "c" (buffer: rawptr),

	// advance_frame - Called during a rollback.  You should advance your game
	// state by exactly one frame.  Before each frame, call synchronize_input
	// to retrieve the inputs you should use for that frame.  After each frame,
	// you should call advance_frame to notify GGPO.net that you're
	// finished.
	//
	// The flags parameter is reserved.  It can safely be ignored at this time.
	advance_frame: proc "c" (flags: c.int) -> bool,

	// on_event - Notification that something has happened.  See the EventCode
	// structure above for more information.
	on_event: proc "c" (info: ^Event) -> bool,
}

// The NetworkStats function contains some statistics about the current
// session.
//
// network.send_queue_len - The length of the queue containing UDP packets
// which have not yet been acknowledged by the end client.  The length of
// the send queue is a rough indication of the quality of the connection.
// The longer the send queue, the higher the round-trip time between the
// clients.  The send queue will also be longer than usual during high
// packet loss situations.
//
// network.recv_queue_len - The number of inputs currently buffered by the
// GGPO.net network layer which have yet to be validated.  The length of
// the prediction queue is roughly equal to the current frame number
// minus the frame number of the last packet in the remote queue.
//
// network.ping - The roundtrip packet transmission time as calcuated
// by GGPO.net.  This will be roughly equal to the actual round trip
// packet transmission time + 2 the interval at which you call idle
// or advance_frame.
//
// network.kbps_sent - The estimated bandwidth used between the two
// clients, in kilobits per second.
//
// timesync.local_frames_behind - The number of frames GGPO.net calculates
// that the local client is behind the remote client at this instant in
// time.  For example, if at this instant the current game client is running
// frame 1002 and the remote game client is running frame 1009, this value
// will mostly likely roughly equal 7.
//
// timesync.remote_frames_behind - The same as local_frames_behind, but
// calculated from the perspective of the remote player.
NetworkStats :: struct {
	network: struct {
		send_queue_len: c.int,
		recv_queue_len: c.int,
		ping:           c.int,
		kbps_sent:      c.int,
	},
	timesync: struct {
		local_frames_behind:  c.int,
		remote_frames_behind: c.int,
	},
}

@(default_calling_convention="c")
@(link_prefix="ggpo_")
foreign lib {
	// start_session --
	//
	// Used to being a new GGPO.net session.  The ggpo object returned by start_session
	// uniquely identifies the state for this session and should be passed to all other
	// functions.
	//
	// session - An out parameter to the new ggpo session object.
	//
	// cb - A SessionCallbacks structure which contains the callbacks you implement
	// to help GGPO.net synchronize the two games.  You must implement all functions in
	// cb, even if they do nothing but 'return true';
	//
	// game - The name of the game.  This is used internally for GGPO for logging purposes only.
	//
	// num_players - The number of players which will be in this game.  The number of players
	// per session is fixed.  If you need to change the number of players or any player
	// disconnects, you must start a new session.
	//
	// input_size - The size of the game inputs which will be passsed to add_local_input.
	//
	// local_port - The port GGPO should bind to for UDP traffic.
	start_session :: proc(session:     ^^Session,
	                      cb:          ^SessionCallbacks,
	                      game:        cstring,
	                      num_players: c.int,
	                      input_size:  c.int,
	                      localport:   u16) -> ErrorCode ---


	// add_player --
	//
	// Must be called for each player in the session (e.g. in a 3 player session, must
	// be called 3 times).
	//
	// player - A Player struct used to describe the player.
	//
	// handle - An out parameter to a handle used to identify this player in the future.
	// (e.g. in the on_event callbacks).
	add_player :: proc(session: ^Session,
	                   player:  ^Player,
	                   handle:  ^PlayerHandle) -> ErrorCode ---


	/*
	 * start_synctest --
	 *
	 * Used to being a new GGPO.net sync test session.  During a sync test, every
	 * frame of execution is run twice: once in prediction mode and once again to
	 * verify the result of the prediction.  If the checksums of your save states
	 * do not match, the test is aborted.
	 *
	 * cb - A SessionCallbacks structure which contains the callbacks you implement
	 * to help GGPO.net synchronize the two games.  You must implement all functions in
	 * cb, even if they do nothing but 'return true';
	 *
	 * game - The name of the game.  This is used internally for GGPO for logging purposes only.
	 *
	 * num_players - The number of players which will be in this game.  The number of players
	 * per session is fixed.  If you need to change the number of players or any player
	 * disconnects, you must start a new session.
	 *
	 * input_size - The size of the game inputs which will be passsed to add_local_input.
	 *
	 * frames - The number of frames to run before verifying the prediction.  The
	 * recommended value is 1.
	 *
	 */
	start_synctest :: proc(session:     ^^Session,
	                       cb:          ^SessionCallbacks,
	                       game:        cstring,
	                       num_players: c.int,
	                       input_size:  c.int,
	                       frames:      c.int) -> ErrorCode ---


	// start_spectating --
	//
	// Start a spectator session.
	//
	// cb - A SessionCallbacks structure which contains the callbacks you implement
	// to help GGPO.net synchronize the two games.  You must implement all functions in
	// cb, even if they do nothing but 'return true';
	//
	// game - The name of the game.  This is used internally for GGPO for logging purposes only.
	//
	// num_players - The number of players which will be in this game.  The number of players
	// per session is fixed.  If you need to change the number of players or any player
	// disconnects, you must start a new session.
	//
	// input_size - The size of the game inputs which will be passsed to add_local_input.
	//
	// local_port - The port GGPO should bind to for UDP traffic.
	//
	// host_ip - The IP address of the host who will serve you the inputs for the game.  Any
	// player partcipating in the session can serve as a host.
	//
	// host_port - The port of the session on the host
	start_spectating :: proc(session:     ^^Session,
	                         cb:          ^SessionCallbacks,
	                         game:        cstring,
	                         num_players: c.int,
	                         input_size:  c.int,
	                         local_port:  u16,
	                         host_ip:     cstring,
	                         host_port:   u16) -> ErrorCode ---

	// close_session --
	// Used to close a session.  You must call close_session to
	// free the resources allocated in start_session.
	close_session :: proc(session: ^Session) -> ErrorCode ---


	// set_frame_delay --
	//
	// Change the amount of frames ggpo will delay local input.  Must be called
	// before the first call to synchronize_input.
	set_frame_delay :: proc(session:     ^Session,
	                        player:      PlayerHandle,
	                        frame_delay: c.int) -> ErrorCode ---

	// idle --
	// Should be called periodically by your application to give GGPO.net
	// a chance to do some work.  Most packet transmissions and rollbacks occur
	// in idle.
	//
	// timeout - The amount of time GGPO.net is allowed to spend in this function,
	// in milliseconds.
	idle :: proc(session: ^Session,
	             timeout: c.int) -> ErrorCode ---

	// add_local_input --
	//
	// Used to notify GGPO.net of inputs that should be trasmitted to remote
	// players.  add_local_input must be called once every frame for
	// all player of type PLAYERTYPE_LOCAL.
	//
	// player - The player handle returned for this player when you called
	// add_local_player.
	//
	// values - The controller inputs for this player.
	//
	// size - The size of the controller inputs.  This must be exactly equal to the
	// size passed into start_session.
	add_local_input :: proc(session: ^Session,
	                        player:  PlayerHandle,
	                        values:  rawptr,
	                        size:    c.int) -> ErrorCode ---

	// synchronize_input --
	//
	// You should call synchronize_input before every frame of execution,
	// including those frames which happen during rollback.
	//
	// values - When the function returns, the values parameter will contain
	// inputs for this frame for all players.  The values array must be at
	// least (size * players) large.
	//
	// size - The size of the values array.
	//
	// disconnect_flags - Indicated whether the input in slot (1 << flag) is
	// valid.  If a player has disconnected, the input in the values array for
	// that player will be zeroed and the i-th flag will be set.  For example,
	// if only player 3 has disconnected, disconnect flags will be 8 (i.e. 1 << 3).
	synchronize_input :: proc(session:          ^Session,
	                          values:           rawptr,
	                          size:             c.int,
	                          disconnect_flags: ^c.int) -> ErrorCode ---

	// disconnect_player --
	//
	// Disconnects a remote player from a game.  Will return ERRORCODE_PLAYER_DISCONNECTED
	// if you try to disconnect a player who has already been disconnected.
	disconnect_player :: proc(session: ^Session,
	                          player:  PlayerHandle) -> ErrorCode ---

	// advance_frame --
	//
	// You should call advance_frame to notify GGPO.net that you have
	// advanced your gamestate by a single frame.  You should call this everytime
	// you advance the gamestate by a frame, even during rollbacks.  GGPO.net
	// may call your save_state callback before this function returns.
	advance_frame :: proc(session: ^Session) -> ErrorCode ---

	// get_network_stats --
	//
	// Used to fetch some statistics about the quality of the network connection.
	//
	// player - The player handle returned from the add_player function you used
	// to add the remote player.
	//
	// stats - Out parameter to the network statistics.
	get_network_stats :: proc(session: ^Session,
	                          player:  PlayerHandle,
	                          stats:   ^NetworkStats) -> ErrorCode ---

	// set_disconnect_timeout --
	//
	// Sets the disconnect timeout.  The session will automatically disconnect
	// from a remote peer if it has not received a packet in the timeout window.
	// You will be notified of the disconnect via a EVENTCODE_DISCONNECTED_FROM_PEER
	// event.
	//
	// Setting a timeout value of 0 will disable automatic disconnects.
	//
	// timeout - The time in milliseconds to wait before disconnecting a peer.
	set_disconnect_timeout :: proc(session: ^Session,
	                               timeout: c.int) -> ErrorCode ---

	// set_disconnect_notify_start --
	//
	// The time to wait before the first EVENTCODE_NETWORK_INTERRUPTED timeout
	// will be sent.
	//
	// timeout - The amount of time which needs to elapse without receiving a packet
	//           before the EVENTCODE_NETWORK_INTERRUPTED event is sent.
	set_disconnect_notify_start :: proc(session: ^Session,
	                                    timeout: c.int) -> ErrorCode ---

	// log --
	//
	// Used to write to the ggpo.net log.  In the current versions of the
	// SDK, a log file is only generated if the "quark.log" environment
	// variable is set to 1.  This will change in future versions of the
	// SDK.
	log :: proc(session: ^Session, fmt: cstring, #c_vararg args: ..any) ---

	// logv --
	//
	// A varargs compatible version of log.  See log for
	// more details.
	logv :: proc(session: ^Session, fmt: cstring, args: c.va_list) ---
}