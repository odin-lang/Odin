package ENet

when ODIN_OS == .Windows {
	when ODIN_ARCH == .amd64 {
		foreign import ENet {
			"lib/enet64.lib",
			"system:Ws2_32.lib",
			"system:Winmm.lib",
		}
	} else {
		foreign import ENet {
			"lib/enet.lib",
			"system:Ws2_32.lib",
			"system:Winmm.lib",
		}
	}
} else {
	foreign import ENet "system:enet"
}

VERSION_MAJOR :: u8(1)
VERSION_MINOR :: u8(3)
VERSION_PATCH :: u8(17)

VERSION_CREATE :: #force_inline proc "contextless" (major, minor, patch: u8) -> u32 {
	return (u32(major) << 16) | (u32(minor) << 8) | u32(patch)
}

VERSION_GET_MAJOR :: #force_inline proc "contextless" (version: u32) -> u8 {
	return u8((version >> 16) & 0xff)
}
VERSION_GET_MINOR :: #force_inline proc "contextless" (version: u32) -> u8 {
	return u8((version >> 8) & 0xff)
}
VERSION_GET_PATCH :: #force_inline proc "contextless" (version: u32) -> u8 {
	return u8(version & 0xff)
}

// Odin does not have "macros" or compile-time evaluation of functions, so the
// following is just the same as.
// VERSION :: VERSION_CREATE(VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH);
VERSION :: (u32(VERSION_MAJOR) << 16) | (u32(VERSION_MINOR) << 8) | u32(VERSION_PATCH)

// Network byte order is always Big Endian. Instead of using the method ENet
// uses (leveraging {n,h}to{n,h}{s,l}), we can just use Odin's endianess types
// to get the correct byte swaps, if any.
HOST_TO_NET_16 :: #force_inline proc "contextless" (value: u16) -> u16 {
	return transmute(u16)u16be(value)
}

HOST_TO_NET_32 :: #force_inline proc "contextless" (value: u32) -> u32 {
	return transmute(u32)u32be(value)
}

NET_TO_HOST_16 :: #force_inline proc "contextless" (value: u16) -> u16 {
	return u16(transmute(u16be)value)
}

NET_TO_HOST_32 :: #force_inline proc "contextless" (value: u32) -> u32 {
	return u32(transmute(u32be)value)
}

Version :: u32

SocketType :: enum i32 {
	STREAM   = 1,
	DATAGRAM = 2,
}

SocketWait :: enum i32 {
	NONE      = 0,
	SEND      = 1 << 0,
	RECEIVE   = 1 << 1,
	INTERRUPT = 1 << 2,
}

SocketOption :: enum i32 {
	NONBLOCK  = 1,
	BROADCAST = 2,
	RCVBUF    = 3,
	SNDBUF    = 4,
	REUSEADDR = 5,
	RCVTIMEO  = 6,
	SNDTIMEO  = 7,
	ERROR     = 8,
	NODELAY   = 9,
}

SocketShutdown :: enum i32 {
	READ       = 0,
	WRITE      = 1,
	READ_WRITE = 2,
}

HOST_ANY       :: u32(0)
HOST_BROADCAST :: u32(0xffffffff)
PORT_ANY       :: u16(0)

Address :: struct {
	host: u32,
	port: u16,
}

PacketFlags :: bit_set[PacketFlag; i32]
PacketFlag :: enum i32 {
	RELIABLE            = 0,
	UNSEQUENCED         = 1,
	NO_ALLOCATE         = 2,
	UNRELIABLE_FRAGMENT = 3,
	FLAG_SENT           = 8,
}

PacketFreeCallback :: proc "c" (packet: ^Packet)

Packet :: struct {
	referenceCount: uint,
	flags:          u32,
	data:           [^]u8 `fmt:"v,dataLength"`,
	dataLength:     uint,
	freeCallback:   PacketFreeCallback,
	userData:       rawptr,
}

Acknowledgment :: struct {
	acknowledgementList: ListNode,
	sentTime:            u32,
	command:             Protocol,
}

OutgoingCommand :: struct {
	outgoingCommandList:      ListNode,
	reliableSequenceNumber:   u16,
	unreliableSequenceNumber: u16,
	sentTime:                 u32,
	roundTripTimeout:         u32,
	roundTripTimeoutLimit:    u32,
	fragmentOffset:           u32,
	fragmentLength:           u16,
	sendAttempts:             u16,
	command:                  Protocol,
	packet:                   ^Packet,
}

IncomingCommand :: struct {
	incomingCommandList:      ListNode,
	reliableSequenceNumber:   u16,
	unreliableSequenceNumber: u16,
	command:                  Protocol,
	fragmentCount:            u32,
	fragmentsRemaining:       u32,
	fragments:                [^]u32 `fmt:"v,fragmentCount"`,
	packet:                   ^Packet,
}

PeerState :: enum i32 {
	DISCONNECTED,
	CONNECTING,
	ACKNOWLEDGING_CONNECT,
	CONNECTION_PENDING,
	CONNECTION_SUCCEEDED,
	CONNECTED,
	DISCONNECT_LATER,
	DISCONNECTING,
	ACKNOWLEDGING_DISCONNECT,
	ZOMBIE,
}

BUFFER_MAXIMUM                    :: (1 + 2 * PROTOCOL_MAXIMUM_PACKET_COMMANDS)

HOST_RECEIVE_BUFFER_SIZE          :: 256 * 1024
HOST_SEND_BUFFER_SIZE             :: 256 * 1024
HOST_BANDWIDTH_THROTTLE_INTERVAL  :: 1000
HOST_DEFAULT_MTU                  :: 1400
HOST_DEFAULT_MAXIMUM_PACKET_SIZE  :: 32 * 1024 * 1024
HOST_DEFAULT_MAXIMUM_WAITING_DATA :: 32 * 1024 * 1024

PEER_DEFAULT_ROUND_TRIP_TIME      :: 500
PEER_DEFAULT_PACKET_THROTTLE      :: 32
PEER_PACKET_THROTTLE_SCALE        :: 32
PEER_PACKET_THROTTLE_COUNTER      :: 7
PEER_PACKET_THROTTLE_ACCELERATION :: 2
PEER_PACKET_THROTTLE_DECELERATION :: 2
PEER_PACKET_THROTTLE_INTERVAL     :: 5000
PEER_PACKET_LOSS_SCALE            :: 1 << 16
PEER_PACKET_LOSS_INTERVAL         :: 10000
PEER_WINDOW_SIZE_SCALE            :: 64 * 1024
PEER_TIMEOUT_LIMIT                :: 32
PEER_TIMEOUT_MINIMUM              :: 5000
PEER_TIMEOUT_MAXIMUM              :: 30000
PEER_PING_INTERVAL                :: 500
PEER_UNSEQUENCED_WINDOWS          :: 64
PEER_UNSEQUENCED_WINDOW_SIZE      :: 1024
PEER_FREE_UNSEQUENCED_WINDOWS     :: 32
PEER_RELIABLE_WINDOWS             :: 16
PEER_RELIABLE_WINDOW_SIZE         :: 0x1000
PEER_FREE_RELIABLE_WINDOWS        :: 8

Channel :: struct {
	outgoingReliableSequenceNumber:   u16,
	outgoingUnreliableSequenceNumber: u16,
	usedReliableWindows:              u16,
	reliableWindows:                  [PEER_RELIABLE_WINDOWS]u16,
	incomingReliableSequenceNumber:   u16,
	incomingUnreliableSequenceNumber: u16,
	incomingReliableCommands:         List,
	incomingUnreliableCommands:       List,
}

PeerFlag :: enum i32 {
	NEEDS_DISPATCH,
}

Peer :: struct {
	dispatchList:                   ListNode,
	host:                           ^Host,
	outgoingPeerID:                 u16,
	incomingPeerID:                 u16,
	connectID:                      u32,
	outgoingSessionID:              u8,
	incomingSessionID:              u8,
	address:                        Address,
	data:                           rawptr,
	state:                          PeerState,
	channels:                       [^]Channel `fmt:"v,channelCount"`,
	channelCount:                   uint,
	incomingBandwidth:              u32,
	outgoingBandwidth:              u32,
	incomingBandwidthThrottleEpoch: u32,
	outgoingBandwidthThrottleEpoch: u32,
	incomingDataTotal:              u32,
	outgoingDataTotal:              u32,
	lastSendTime:                   u32,
	lastReceiveTime:                u32,
	nextTimeout:                    u32,
	earliestTimeout:                u32,
	packetLossEpoch:                u32,
	packetsSent:                    u32,
	packetsLost:                    u32,
	packetLoss:                     u32,
	packetLossVariance:             u32,
	packetThrottle:                 u32,
	packetThrottleLimit:            u32,
	packetThrottleCounter:          u32,
	packetThrottleEpoch:            u32,
	packetThrottleAcceleration:     u32,
	packetThrottleDeceleration:     u32,
	packetThrottleInterval:         u32,
	pingInterval:                   u32,
	timeoutLimit:                   u32,
	timeoutMinimum:                 u32,
	timeoutMaximum:                 u32,
	lastRoundTripTime:              u32,
	lowestRoundTripTime:            u32,
	lastRoundTripTimeVariance:      u32,
	highestRoundTripTimeVariance:   u32,
	roundTripTime:                  u32,
	roundTripTimeVariance:          u32,
	mtu:                            u32,
	windowSize:                     u32,
	reliableDataInTransit:          u32,
	outgoingReliableSequenceNumber: u16,
	acknowledgements:               List,
	sentReliableCommands:           List,
	sentUnreliableCommands:         List,
	outgoingCommands:               List,
	dispatchedCommands:             List,
	flags:                          u16,
	reserved:                       u16,
	incomingUnsequencedGroup:       u16,
	outgoingUnsequencedGroup:       u16,
	unsequencedWindow:              [PEER_UNSEQUENCED_WINDOW_SIZE / 32]u32,
	eventData:                      u32,
	totalWaitingData:               uint,
}

Compressor :: struct {
	context_:   rawptr,
	compress:   proc "c" (context_: rawptr, inBuffers: [^]Buffer, inBufferCount: uint, inLimit: uint, outData: [^]u8, outLimit: uint) -> uint,
	decompress: proc "c" (context_: rawptr, inData: [^]u8, inLimit: uint, outData: [^]u8, outLimit: uint) -> uint,
	destroy:    proc "c" (context_: rawptr),
}

ChecksumCallback  :: proc "c" (buffers: [^]Buffer, bufferCount: uint) -> u32
InterceptCallback :: proc "c" (host: ^Host, event: ^Event) -> i32

Host :: struct {
	socket:                     Socket,
	address:                    Address,
	incomingBandwidth:          u32,
	outgoingBandwidth:          u32,
	bandwidthThrottleEpoch:     u32,
	mtu:                        u32,
	randomSeed:                 u32,
	recalculateBandwidthLimits: i32,
	peers:                      [^]Peer `fmt:"v,peerCount"`,
	peerCount:                  uint,
	channelLimit:               uint,
	serviceTime:                u32,
	dispatchQueue:              List,
	continueSending:            i32,
	packetSize:                 uint,
	headerFlags:                u16,
	commands:                   [PROTOCOL_MAXIMUM_PACKET_COMMANDS]Protocol,
	commandCount:               uint,
	buffers:                    [BUFFER_MAXIMUM]Buffer,
	bufferCount:                uint,
	checksum:                   ChecksumCallback,
	compressor:                 Compressor,
	packetData:                 [2][PROTOCOL_MAXIMUM_MTU]u8,
	receivedAddress:            Address,
	receivedData:               [^]u8 `fmt:"v,receivedDataLength"`,
	receivedDataLength:         uint,
	totalSentData:              u32,
	totalSentPackets:           u32,
	totalReceivedData:          u32,
	totalReceivedPackets:       u32,
	intercept:                  InterceptCallback,
	connectedPeers:             uint,
	bandwidthLimitedPeers:      uint,
	duplicatePeers:             uint,
	maximumPacketSize:          uint,
	maximumWaitingData:         uint,
}

EventType :: enum i32 {
	NONE       = 0,
	CONNECT    = 1,
	DISCONNECT = 2,
	RECEIVE    = 3,
}

Event :: struct {
	type:      EventType,
	peer:      ^Peer,
	channelID: u8,
	data:      u32,
	packet:    ^Packet,
}

@(default_calling_convention="c", link_prefix="enet_")
foreign ENet {
	initialize                     :: proc() -> i32 ---
	initialize_with_callbacks      :: proc(version: Version, inits: ^Callbacks) -> i32 ---
	deinitialize                   :: proc() ---
	linked_version                 :: proc() -> Version ---
	time_get                       :: proc() -> u32 ---
	time_set                       :: proc(newTimeBase: u32) ---

	socket_create                  :: proc(SocketType) -> Socket ---
	socket_bind                    :: proc(socket: Socket, address: ^Address) -> i32 ---
	socket_get_address             :: proc(socket: Socket, address: ^Address) -> i32 ---
	socket_listen                  :: proc(socket: Socket, backlog: i32) -> i32 ---
	socket_accept                  :: proc(socket: Socket, address: ^Address) -> Socket ---
	socket_connect                 :: proc(socket: Socket, address: ^Address) -> i32 ---
	socket_send                    :: proc(socket: Socket, address: ^Address, buffers: [^]Buffer, bufferCount: uint) -> i32 ---
	socket_receive                 :: proc(socket: Socket, address: ^Address, buffers: [^]Buffer, bufferCount: uint) -> i32 ---
	socket_wait                    :: proc(socket: Socket, condition: ^u32, timeout: u32) -> i32 ---
	socket_set_option              :: proc(socket: Socket, option: SocketOption, value: i32) -> i32 ---
	socket_get_option              :: proc(socket: Socket, option: SocketOption, value: ^i32) -> i32 ---
	socket_shutdown                :: proc(socket: Socket, how: SocketShutdown) -> i32 ---
	socket_destroy                 :: proc(socket: Socket) ---
	socketset_select               :: proc(socket: Socket, readSet: ^SocketSet, writeSet: ^SocketSet, timeout: u32) -> i32 ---

	address_set_host_ip            :: proc(address: ^Address, hostName: cstring) -> i32 ---
	address_set_host               :: proc(address: ^Address, hostName: cstring) -> i32 ---
	address_get_host_ip            :: proc(address: ^Address, hostName: [^]u8, nameLength: uint) -> i32 ---
	address_get_host               :: proc(address: ^Address, hostName: [^]u8, nameLength: uint) -> i32 ---

	packet_create                  :: proc(data: rawptr, dataLength: uint, flags: PacketFlags) -> ^Packet ---
	packet_destroy                 :: proc(packet: ^Packet) ---
	packet_resize                  :: proc(packet: ^Packet, dataLength: uint) -> i32 ---
	crc32                          :: proc(buffers: [^]Buffer, bufferCount: uint) -> u32 ---

	host_create                    :: proc(address: ^Address, peerCount: uint, channelLimit: uint, incomingBandwidth: u32, outgoingBandwidth: u32) -> ^Host ---
	host_destroy                   :: proc(host: ^Host) ---
	host_connect                   :: proc(host: ^Host, address: ^Address, channelCount: uint, data: u32) -> ^Peer ---
	host_check_events              :: proc(host: ^Host, event: ^Event) -> i32 ---
	host_service                   :: proc(host: ^Host, event: ^Event, timeout: u32) -> i32 ---
	host_flush                     :: proc(host: ^Host) ---
	host_broadcast                 :: proc(host: ^Host, channelID: u8, packet: ^Packet) ---
	host_compress                  :: proc(host: ^Host, compressor: ^Compressor) ---
	host_compress_with_range_coder :: proc(host: ^Host) -> i32 ---
	host_channel_limit             :: proc(host: ^Host, channelLimit: uint) ---
	host_bandwidth_limit           :: proc(host: ^Host, incomingBandwidth: u32, outgoingBandwidth: u32) ---

	peer_send                      :: proc(peer: ^Peer, channelID: u8, packet: ^Packet) -> i32 ---
	peer_receive                   :: proc(peer: ^Peer, channelID: ^u8) -> ^Packet ---
	peer_ping                      :: proc(peer: ^Peer) ---
	peer_ping_interval             :: proc(peer: ^Peer, pingInterval: u32) ---
	peer_timeout                   :: proc(peer: ^Peer, timoutLimit: u32, timeoutMinimum: u32, timeoutMaximum: u32) ---
	peer_reset                     :: proc(peer: ^Peer) ---
	peer_disconnect                :: proc(peer: ^Peer, data: u32) ---
	peer_disconnect_now            :: proc(peer: ^Peer, data: u32) ---
	peer_disconnect_later          :: proc(peer: ^Peer, data: u32) ---
	peer_throttle_configure        :: proc(peer: ^Peer, interval: u32, acceleration: u32, deceleration: u32) ---

	range_coder_create             :: proc() -> rawptr ---
	range_coder_destroy            :: proc(ctx: rawptr) ---
	range_coder_compress           :: proc(ctx: rawptr, inBuffers: [^]Buffer, inBufferCount: uint, inLimit: uint, outData: [^]u8, outLimit: uint) -> uint ---
	range_coder_decompress         :: proc(ctx: rawptr, inData: [^]u8, inLimit: uint, outData: [^]u8, outLimit: uint) -> uint ---
}
