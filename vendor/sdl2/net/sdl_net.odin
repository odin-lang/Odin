// Bindings for [[ SDL2 Net ; https://wiki.libsdl.org/SDL2/FrontPage ]].
package sdl2_net

import "core:c"
import SDL ".."

when ODIN_OS == .Windows {
	foreign import lib "SDL2_net.lib"
} else {
	foreign import lib "system:SDL2_net"
}

bool :: SDL.bool

MAJOR_VERSION :: 2
MINOR_VERSION :: 0
PATCHLEVEL    :: 1

IPaddress :: struct {
	host: u32,            /* 32-bit IPv4 host address */
	port: u16,            /* 16-bit protocol port */
}

INADDR_ANY       :: 0x00000000
INADDR_NONE      :: 0xFFFFFFFF
INADDR_LOOPBACK  :: 0x7f000001
INADDR_BROADCAST :: 0xFFFFFFFF


@(default_calling_convention="c", link_prefix="SDLNet_")
foreign lib {
	Linked_Version :: proc() -> ^SDL.version ---

	Init :: proc() -> c.int ---
	Quit :: proc() ---

	ResolveHost       :: proc(address: ^IPaddress, host: cstring, port: u16) -> c.int ---
	ResolveIP         :: proc(ip: ^IPaddress) -> cstring ---
	GetLocalAddresses :: proc(addresses: ^IPaddress, maxcount: c.int) -> c.int ---
}


/***********************************************************************/
/* TCP network API                                                     */
/***********************************************************************/

TCPsocket :: distinct rawptr

@(default_calling_convention="c", link_prefix="SDLNet_")
foreign lib {
	TCP_Open           :: proc(ip: ^IPaddress) -> TCPsocket ---
	TCP_Accept         :: proc(server: TCPsocket) -> TCPsocket ---
	TCP_GetPeerAddress :: proc(sock: TCPsocket) -> ^IPaddress ---
	TCP_Send           :: proc(sock: TCPsocket, data: rawptr, len: c.int) -> c.int ---
	TCP_Recv           :: proc(sock: TCPsocket, data: rawptr, maxlen: c.int) -> c.int ---
	TCP_Close          :: proc(sock: TCPsocket) ---
}


/* The maximum channels on a a UDP socket */
MAX_UDPCHANNELS  :: 32
/* The maximum addresses bound to a single UDP socket channel */
MAX_UDPADDRESSES :: 4

UDPsocket :: distinct rawptr
UDPpacket :: struct {
	channel: c.int,     /* The src/dst channel of the packet */
	data:    [^]u8,     /* The packet data */
	len:     c.int,     /* The length of the packet data */
	maxlen:  c.int,     /* The size of the data buffer */
	status:  c.int,     /* packet status after sending */
	address: IPaddress, /* The source/dest address of an incoming/outgoing packet */
}


/***********************************************************************/
/* UDP network API                                                     */
/***********************************************************************/

@(default_calling_convention="c", link_prefix="SDLNet_")
foreign lib {
	AllocPacket  :: proc(size: c.int) -> ^UDPpacket ---
	ResizePacket :: proc(packet: ^UDPpacket, newsize: c.int) -> c.int ---
	FreePacket   :: proc(packet: ^UDPpacket) ---

	AllocPacketV :: proc(howmany: c.int, size: c.int) -> [^]^UDPpacket ---
	FreePacketV  :: proc(packetV: [^]^UDPpacket) ---


	UDP_Open           :: proc(port: u16) -> UDPsocket ---
	UDP_SetPacketLoss  :: proc(sock: UDPsocket, percent: c.int) ---
	UDP_Bind           :: proc(sock: UDPsocket, channel: c.int, address: ^IPaddress) -> c.int ---
	UDP_Unbind         :: proc(sock: UDPsocket, channel: c.int) ---
	UDP_GetPeerAddress :: proc(sock: UDPsocket, channel: c.int) -> IPaddress ---
	UDP_SendV          :: proc(sock: UDPsocket, packets: [^]^UDPpacket, npackets: c.int) -> c.int ---
	UDP_Send           :: proc(sock: UDPsocket, channel: c.int, packet: ^UDPpacket) -> c.int ---
	UDP_RecvV          :: proc(sock: UDPsocket, packets: [^]^UDPpacket) -> c.int ---
	UDP_Recv           :: proc(sock: UDPsocket, packet: ^UDPpacket) -> c.int ---
	UDP_Close          :: proc(sock: UDPsocket) ---
}

AllocPacketSlice :: proc "c" (howmany: c.int, size: c.int) -> []^UDPpacket {
	if packets := AllocPacketV(howmany, size); packets != nil {
		return packets[:howmany]
	}
	return nil
}
FreePacketSlice :: proc "c" (packets: []^UDPpacket) {
	FreePacketV(raw_data(packets))
}

UDP_SendSlice :: proc "c" (sock: UDPsocket, packets: []^UDPpacket) -> c.int {
	return UDP_SendV(sock, raw_data(packets), c.int(len(packets)))
}


/***********************************************************************/
/* Hooks for checking sockets for available data                       */
/***********************************************************************/

SocketSet :: distinct rawptr

/* Any network socket can be safely cast to this socket type */
GenericSocket :: ^struct { ready: c.int }

TCP_AddSocket :: #force_inline proc "c" (set: SocketSet, sock: TCPsocket) -> c.int {
	return AddSocket(set, (GenericSocket)(sock))
}
UDP_AddSocket :: #force_inline proc "c" (set: SocketSet, sock: UDPsocket) -> c.int {
	return AddSocket(set, (GenericSocket)(sock))
}
TCP_DelSocket :: #force_inline proc "c" (set: SocketSet, sock: TCPsocket) -> c.int {
	return DelSocket(set, (GenericSocket)(sock))
}
UDP_DelSocket :: #force_inline proc "c" (set: SocketSet, sock: UDPsocket) -> c.int {
	return DelSocket(set, (GenericSocket)(sock))
}

SocketReady :: #force_inline proc "c" (sock: rawptr) -> bool {
	s := (GenericSocket)(sock)
	return bool(s != nil && s.ready != 0)
}


@(default_calling_convention="c", link_prefix="SDLNet_")
foreign lib {
	AllocSocketSet :: proc(maxsockets: c.int) -> SocketSet ---
	AddSocket      :: proc(set: SocketSet, sock: GenericSocket) -> c.int ---
	DelSocket      :: proc(set: SocketSet, sock: GenericSocket) -> c.int ---
	CheckSockets   :: proc(set: SocketSet, timeout: u32) -> c.int ---
	FreeSocketSet  :: proc(set: SocketSet) ---
}


/***********************************************************************/
/* Error reporting functions                                           */
/***********************************************************************/

@(default_calling_convention="c", link_prefix="SDLNet_")
foreign lib {
	SetError :: proc(fmt: cstring, #c_vararg args: ..any) ---
	GetError :: proc() -> cstring ---
}


/***********************************************************************/
/* Inline functions to read/write network data                         */
/***********************************************************************/

/* Write a 16/32-bit value to network packet buffer */
Write16 :: #force_inline proc "c" (value: u16, areap: rawptr) {
	area := (^[2]u8)(areap)
	area[0] = u8((value >>  8) & 0xFF)
	area[1] = u8( value        & 0xFF)
}
Write32 :: #force_inline proc "c" (value: u32, areap: rawptr) {
	area := (^[4]u8)(areap)
	area[0] = u8((value >> 24) & 0xFF)
	area[1] = u8((value >> 16) & 0xFF)
	area[2] = u8((value >>  8) & 0xFF)
	area[3] = u8( value        & 0xFF)
}

/* Read a 16/32-bit value from network packet buffer */
Read16 :: #force_inline proc "c" (areap: rawptr) -> u16 {
	area := (^[2]u8)(areap)
	return u16(area[0])<<8 | u16(area[1])
}

Read32 :: #force_inline proc "c" (areap: rawptr) -> u32 {
	area := (^[4]u8)(areap)
	return u32(area[0])<<24 | u32(area[1])<<16 | u32(area[2])<<8 | u32(area[3])
}
