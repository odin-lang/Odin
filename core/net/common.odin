/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
*/

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.

	This file collects structs, enums and settings applicable to the entire package in one handy place.
	Platform-specific ones can be found in their respective `*_windows.odin` and similar files.
*/
package net

import "core:runtime"

/*
	TUNEABLES
*/

/*
	Determines the default value for whether dial_tcp() and accept_tcp() will set TCP_NODELAY on the new
	socket, and the client socket, respectively.
	This can also be set on a per-socket basis using the 'options' optional parameter to those procedures.

	When TCP_NODELAY is set, data will be sent out to the peer as quickly as possible, rather than being
	coalesced into fewer network packets.

	This makes the networking layer more eagerly send data when you ask it to,
	which can reduce latency by up to 200ms.

	This does mean that a lot of small writes will negatively effect throughput however,
	since the Nagle algorithm will be disabled, and each write becomes one
	IP packet. This will increase traffic by a factor of 40, with IP and TCP
	headers for each payload.

	However, you can avoid this by buffering things up yourself if you wish to send a lot of
	short data chunks, when TCP_NODELAY is enabled on that socket.
*/
ODIN_NET_TCP_NODELAY_DEFAULT :: #config(ODIN_NET_TCP_NODELAY_DEFAULT, true)

/*
	See also top of `dns.odin` for DNS configuration.
*/

/*
	COMMON DEFINITIONS
*/

Maybe :: runtime.Maybe

General_Error :: enum {
	Unable_To_Enumerate_Network_Interfaces,
}

/*
	`Platform_Error` is used to wrap errors returned by the different platforms that defy translation into a common error.
*/
Platform_Error :: enum u32 {}

Network_Error :: union {
	General_Error,
	Platform_Error,
	Create_Socket_Error,
	Dial_Error,
	Dial_String_Error,
	Listen_Error,
	Accept_Error,
	Bind_Error,
	TCP_Send_Error,
	UDP_Send_Error,
	TCP_Recv_Error,
	UDP_Recv_Error,
	Shutdown_Error,
	Socket_Option_Error,
}

/*
	SOCKET OPTIONS & DEFINITIONS
*/

TCP_Options :: struct {
	no_delay: bool,
}

default_tcp_options := TCP_Options {
	no_delay = ODIN_NET_TCP_NODELAY_DEFAULT,
}

/*
	To allow freely using `Socket` in your own data structures in a cross-platform manner,
	we treat it as a handle large enough to accomodate OS-specific notions of socket handles.

	The platform code will perform the cast so you don't have to.
*/
Socket     :: distinct i64

TCP_Socket :: distinct Socket
UDP_Socket :: distinct Socket

Socket_Protocol :: enum {
	TCP,
	UDP,
}

Any_Socket :: union {
	TCP_Socket,
	UDP_Socket,
}

/*
	ADDRESS DEFINITIONS
*/

IPv4_Address :: distinct [4]u8
IPv6_Address :: distinct [8]u16be
Address :: union {IPv4_Address, IPv6_Address}

IPv4_Loopback := IPv4_Address{127, 0, 0, 1}
IPv6_Loopback := IPv6_Address{0, 0, 0, 0, 0, 0, 0, 1}

IPv4_Any := IPv4_Address{}
IPv6_Any := IPv6_Address{}

Endpoint :: struct {
	address: Address,
	port:    int,
}

Address_Family :: enum {
	IPv4,
	IPv6,
}

/*
	INTERFACE / LINK STATE
*/

Network_Interface :: struct {
	adapter_name:  string, // On Windows this is a GUID that we could parse back into its u128 for more compact storage.
	friendly_name: string,

	mtu:       u32,

	unicast:   []Lease,
	multicast: []Endpoint,
	anycast:   []Endpoint,

	gateways:  []Endpoint,
	dhcp_v4:   Endpoint,
	dhcp_v6:   Endpoint,

	link: struct {
		state:          Link_State,
		transmit_speed: u64,
		receive_speed:  u64,
	},
}

Link_State :: enum i32 {
	Unknown          = 0,
	Up               = 1,
	Down             = 2,
	Testing          = 3,
	Dormant          = 4,
	Not_Present      = 5,
	Lower_Layer_Down = 6,
}

Lease :: struct {
	address:  Endpoint,
	lifetime: struct {
		valid:     u32,
		preferred: u32,
		lease:     u32,
	},
	origin: struct {
		prefix: Prefix_Origin,
		suffix: Suffix_Origin,
	},
	address_duplication: Address_Duplication,
}

Tunnel_Type :: enum i32 {
	None         = 0,
	Other        = 1,
	Direct       = 2,
	IPv4_To_IPv6 = 11,
	ISA_TAP      = 13,
	Teredo       = 14,
	IP_HTTPS     = 15,
}

Prefix_Origin :: enum i32 {
	Other                = 0,
	Manual               = 1,
	Well_Known           = 2,
	DHCP                 = 3,
	Router_Advertisement = 4,
	Unchanged            = 16,
}

Suffix_Origin :: enum i32 {
	Other                = 0,
	Manual               = 1,
	Well_Known           = 2,
	DHCP                 = 3,
	Link_Layer_Address   = 4,
	Random               = 5,
	Unchanged            = 16,
}

Address_Duplication :: enum i32 {
	Invalid    = 0,
	Tentative  = 1,
	Duplicate  = 2,
	Deprecated = 3,
	Preferred  = 4,
}

/*
	DNS DEFINITIONS
*/

DNS_Configuration :: struct {
	/*
		Configuration files.
	*/
	resolv_conf: string,
	hosts_file:  string,

	// TODO: Allow loading these up with `reload_configuration()` call or the like so we don't have to do it each call.
	name_servers:       []Endpoint,
	hosts_file_entries: []DNS_Record,
}

DNS_Record_Type :: enum u16 {
	DNS_TYPE_A     = 0x1,  // IPv4 address.
	DNS_TYPE_NS    = 0x2,  // IPv6 address.
	DNS_TYPE_CNAME = 0x5,  // Another host name.
	DNS_TYPE_MX    = 0xf,  // Arbitrary binary data or text.
	DNS_TYPE_AAAA  = 0x1c, // Address of a name (DNS) server.
	DNS_TYPE_TEXT  = 0x10, // Address and preference priority of a mail exchange server.
	DNS_TYPE_SRV   = 0x21, // Address, port, priority, and weight of a host that provides a particular service.

	IPv4           = DNS_TYPE_A,
	IPv6           = DNS_TYPE_AAAA,
	CNAME          = DNS_TYPE_CNAME,
	TXT            = DNS_TYPE_TEXT,
	NS             = DNS_TYPE_NS,
	MX             = DNS_TYPE_MX,
	SRV            = DNS_TYPE_SRV,
}

/*
	Base DNS Record. All DNS responses will carry a hostname and TTL (time to live) field.
*/
DNS_Record_Base :: struct {
	record_name: string,
	ttl_seconds: u32,    	// The time in seconds that this service will take to update, after the record is updated.
}

/*
	An IPv4 address that the domain name maps to. There can be any number of these.
*/
DNS_Record_IPv4 :: struct {
	using base: DNS_Record_Base,
	address:    IPv4_Address,
}

/*
	An IPv6 address that the domain name maps to. There can be any number of these.
*/
DNS_Record_IPv6 :: struct {
	using base: DNS_Record_Base,
	address:    IPv6_Address,
}

/*
	Another domain name that the domain name maps to.
	Domains can be pointed to another domain instead of directly to an IP address.
	`get_dns_records` will recursively follow these if you request this type of record.
*/
DNS_Record_CNAME :: struct {
	using base: DNS_Record_Base,
	host_name:  string,
}

/*
	Arbitrary string data that is associated with the domain name.
	Commonly of the form `key=value` to be parsed, though there is no specific format for them.
	These can be used for any purpose.
*/
DNS_Record_TXT :: struct {
	using base: DNS_Record_Base,
	value:      string,
}

/*
	Domain names of other DNS servers that are associated with the domain name.
	TODO(tetra): Expand on what these records are used for, and when you should use pay attention to these.
*/
DNS_Record_NS :: struct {
	using base: DNS_Record_Base,
	host_name:  string,
}

// Domain names for email servers that are associated with the domain name.
// These records also have values which ranks them in the order they should be preferred. Lower is more-preferred.
DNS_Record_MX :: struct {
	using base: DNS_Record_Base,
	host_name:  string,
	preference: int,
}

// An endpoint for a service that is available through the domain name.
// This is the way to discover the services that a domain name provides.
//
// Clients MUST attempt to contact the host with the lowest priority that they can reach.
// If two hosts have the same priority, they should be contacted in the order according to their weight.
// Hosts with larger weights should have a proportionally higher chance of being contacted by clients.
// A weight of zero indicates a very low weight, or, when there is no choice (to reduce visual noise).
//
// The host may be "." to indicate that it is "decidedly not available" on this domain.
DNS_Record_SRV :: struct {
	// base contains the full name of this record.
	// e.g: _sip._tls.example.com
	using base: DNS_Record_Base,

	// The hostname or address where this service can be found.
	target:        string,
	// The port on which this service can be found.
	port:          int,

	service_name:  string, // NOTE(tetra): These are substrings of 'record_name'
	protocol_name: string, // NOTE(tetra): These are substrings of 'record_name'

	// Lower is higher priority
	priority:      int,
	// Relative weight of this host compared to other of same priority; the chance of using this host should be proporitional to this weight.
	// The number of seconds that it will take to update the record.
	weight:        int,
}

DNS_Record :: union {
	DNS_Record_IPv4,
	DNS_Record_IPv6,
	DNS_Record_CNAME,
	DNS_Record_TXT,
	DNS_Record_NS,
	DNS_Record_MX,
	DNS_Record_SRV,
}

DNS_Response_Code :: enum u16be {
	No_Error,
	Format_Error,
	Server_Failure,
	Name_Error,
	Not_Implemented,
	Refused,
}

DNS_Query :: enum u16be {
	Host_Address              = 1,
	Authoritative_Name_Server = 2,
	Mail_Destination          = 3,
	Mail_Forwarder            = 4,
	CNAME                     = 5,
	All                       = 255,
}

DNS_Header :: struct {
	id:                     u16be,
	is_response:            bool,
	opcode:                 u16be,
	is_authoritative:       bool,
	is_truncated:           bool,
	is_recursion_desired:   bool,
	is_recursion_available: bool,
	response_code:          DNS_Response_Code,
}

DNS_Record_Header :: struct #packed {
	type:   u16be,
	class:  u16be,
	ttl:    u32be,
	length: u16be,
}

DNS_Host_Entry :: struct {
	name: string,
	addr: Address,
}