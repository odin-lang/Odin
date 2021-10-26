package ENet

PROTOCOL_MINIMUM_MTU             :: 576
PROTOCOL_MAXIMUM_MTU             :: 4096
PROTOCOL_MAXIMUM_PACKET_COMMANDS :: 32
PROTOCOL_MINIMUM_WINDOW_SIZE     :: 4096
PROTOCOL_MAXIMUM_WINDOW_SIZE     :: 65536
PROTOCOL_MINIMUM_CHANNEL_COUNT   :: 1
PROTOCOL_MAXIMUM_CHANNEL_COUNT   :: 255
PROTOCOL_MAXIMUM_PEER_ID         :: 0xFFF
PROTOCOL_MAXIMUM_FRAGMENT_COUNT  :: 1024 * 1024

ProtocolCommand :: enum i32 {
	NONE                     = 0,
	ACKNOWLEDGE              = 1,
	CONNECT                  = 2,
	VERIFY_CONNECT           = 3,
	DISCONNECT               = 4,
	PING                     = 5,
	SEND_RELIABLE            = 6,
	SEND_UNRELIABLE          = 7,
	SEND_FRAGMENT            = 8,
	SEND_UNSEQUENCED         = 9,
	BANDWIDTH_LIMIT          = 10,
	THROTTLE_CONFIGURE       = 11,
	SEND_UNRELIABLE_FRAGMENT = 12,
	COUNT                    = 13,
	MASK                     = 0x0F,
}

ProtocolFlag :: enum i32 {
	COMMAND_ACKNOWLEDGE    = 1 << 7,
	COMMAND_UNSEQUENCED    = 1 << 6,
	HEADER_COMPRESSED      = 1 << 14,
	HEADER_SENT_TIME       = 1 << 15,
	HEADER_MASK            = HEADER_COMPRESSED | HEADER_SENT_TIME,
	HEADER_SESSION_MASK    = 3 << 12,
	HEADER_SESSION_SHIFT   = 12,
}

ProtocolHeader :: struct #packed {
	peerID:   u16,
	sentTime: u16,
}

ProtocolCommandHeader :: struct #packed {
	command:                u8,
	channelID:              u8,
	reliableSequenceNumber: u16,
}

ProtocolAcknowledge :: struct #packed {
	header:                     ProtocolCommandHeader,
	outgoingPeerID:             u16,
	incomingSessionID:          u8,
	outgoingSessionID:          u8,
	mtu:                        u32,
	windowSize:                 u32,
	channelCount:               u32,
	incomingBandwidth:          u32,
	outgoingBandwidth:          u32,
	packetThrottleInterval:     u32,
	packetThrottleAcceleration: u32,
	packetThrottleDeceleration: u32,
	connectID:                  u32,
	data:                       u32,
}

ProtocolConnect :: struct #packed {
	header:                     ProtocolCommandHeader,
	outgoingPeerID:             u16,
	incomingSessionID:          u8,
	outgoingSessionID:          u8,
	mtu:                        u32,
	windowSize:                 u32,
	channelCount:               u32,
	incomingBandwidth:          u32,
	outgoingBandwidth:          u32,
	packetThrottleInterval:     u32,
	packetThrottleAcceleration: u32,
	packetThrottleDeceleration: u32,
	connectID:                  u32,
	data:                       u32,
}

ProtocolVerifyConnect :: struct #packed {
	header:                      ProtocolCommandHeader,
	outgoingPeerID:              u16,
	incomingSessionID:           u8,
	outgoingSessionID:           u8,
	mtu:                         u32,
	windowSize:                  u32,
	channelCount:                u32,
	incomingBandwidth:           u32,
	outgoingBandwidth:           u32,
	packetThrottleInterval:      u32,
	packetThrottleAcceleration:  u32,
	packetThrottleDeceleration:  u32,
	connectID:                   u32,
}

ProtocolBandwidthLimit :: struct #packed {
	header:            ProtocolCommandHeader,
	incomingBandwidth: u32,
	outgoingBandwidth: u32,
}

ProtocolThrottleConfigure :: struct #packed {
	header:                     ProtocolCommandHeader,
	packetThrottleInterval:     u32,
	packetThrottleAcceleration: u32,
	packetThrottleDeceleration: u32,
}

ProtocolDisconnect :: struct #packed {
	header: ProtocolCommandHeader,
	data:   u32,
}

ProtocolPing :: struct #packed {
	header: ProtocolCommandHeader,
}

ProtocolSendReliable :: struct #packed {
	header:     ProtocolCommandHeader,
	dataLength: u16,
}

ProtocolSendUnreliable :: struct #packed {
	header:                   ProtocolCommandHeader,
	unreliableSequenceNumber: u16,
	dataLength:               u16,
}

ProtocolSendUnsequenced :: struct #packed {
	header:           ProtocolCommandHeader,
	unsequencedGroup: u16,
	dataLength:       u16,
}

ProtocolSendFragment :: struct #packed {
	header:              ProtocolCommandHeader,
	startSequenceNumber: u16,
	dataLength:          u16,
	fragmentCount:       u32,
	fragmentNumber:      u32,
	totalLength:         u32,
	fragmentOffset:      u32,
}

Protocol :: struct #raw_union {
	header:            ProtocolCommandHeader,
	acknowledge:       ProtocolAcknowledge,
	connect:           ProtocolConnect,
	verifyConnect:     ProtocolVerifyConnect,
	disconnect:        ProtocolDisconnect,
	ping:              ProtocolPing,
	sendReliable:      ProtocolSendReliable,
	sendUnreliable:    ProtocolSendUnreliable,
	sendUnsequenced:   ProtocolSendUnsequenced,
	sendFragment:      ProtocolSendFragment,
	bandwidthLimit:    ProtocolBandwidthLimit,
	throttleConfigure: ProtocolThrottleConfigure,
}