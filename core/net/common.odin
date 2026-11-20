package net

/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.

	This file collects structs, enums and settings applicable to the entire package in one handy place.
	Platform-specific ones can be found in their respective `*_windows.odin` and similar files.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/

import "base:runtime"

/*
	TUNEABLES - See also top of `dns.odin` for DNS configuration.

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

// COMMON DEFINITIONS
Maybe :: runtime.Maybe

Network_Error :: union #shared_nil {
	Create_Socket_Error,
	Dial_Error,
	Listen_Error,
	Accept_Error,
	Bind_Error,
	TCP_Send_Error,
	UDP_Send_Error,
	TCP_Recv_Error,
	UDP_Recv_Error,
	Shutdown_Error,
	Interfaces_Error,
	Socket_Info_Error,
	Socket_Option_Error,
	Set_Blocking_Error,
	Parse_Endpoint_Error,
	Resolve_Error,
	DNS_Error,
}

#assert(size_of(Network_Error) == 8)

Interfaces_Error :: enum u32 {
	None,
	Unable_To_Enumerate_Network_Interfaces,
	Allocation_Failure,
	Unknown,
}

Parse_Endpoint_Error :: enum u32 {
	None          = 0,
	Bad_Port      = 1,
	Bad_Address,
	Bad_Hostname,
}

Resolve_Error :: enum u32 {
	None = 0,
	Unable_To_Resolve = 1,
	Allocation_Failure,
}

DNS_Error :: enum u32 {
	None = 0,
	Invalid_Hostname_Error = 1,
	Invalid_Hosts_Config_Error,
	Invalid_Resolv_Config_Error,
	Connection_Error,
	Server_Error,
	System_Error,
}

// SOCKET OPTIONS & DEFINITIONS
TCP_Options :: struct {
	no_delay: bool,
}

DEFAULT_TCP_OPTIONS :: TCP_Options {
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

IP4_Address :: distinct [4]u8
IP6_Address :: distinct [8]u16be
Address :: union {IP4_Address, IP6_Address}

IP4_Loopback :: IP4_Address{127, 0, 0, 1}
IP6_Loopback :: IP6_Address{0, 0, 0, 0, 0, 0, 0, 1}

IP4_Any :: IP4_Address{}
IP6_Any :: IP6_Address{}

IP4_mDNS_Broadcast :: Endpoint{address=IP4_Address{224, 0, 0, 251}, port=5353}
IP6_mDNS_Broadcast :: Endpoint{address=IP6_Address{65282, 0, 0, 0, 0, 0, 0, 251}, port = 5353}

Endpoint :: struct {
	address: Address,
	port:    int,
}

Address_Family :: enum {
	IP4,
	IP6,
}

Netmask :: distinct Address

IP4_Prefix :: struct {
	address: IP4_Address,
	length:  u8,
}

IP6_Prefix :: struct {
	address: IP6_Address,
	length:  u8,
}

Prefix :: union {IP4_Prefix, IP6_Prefix}

IP4_Range :: struct {
	first: IP4_Address,
	last:  IP4_Address,
}

IP6_Range :: struct {
	first: IP6_Address,
	last:  IP6_Address,
}

Address_Range :: union {IP4_Range, IP6_Range}

Address_Category :: enum u8 {
	Global_Unicast,
	Unspecified,
	This_Network,
	Loopback,
	Private_Use,
	Shared_Address,
	Link_Local,
	Unique_Local,
	Documentation,
	Benchmarking,
	Protocol_Assignment,
	Translation,
	IP4_Mapped,
	Discard_Only,
	Dummy,
	Reserved,
	Limited_Broadcast,
	Multicast,
	Deprecated,
}

Registry_Flag :: enum u8 {
	False,
	True,
	Not_Applicable,
}

Special_Purpose_Entry :: struct {
	prefix:               Prefix,
	name:                 string,
	rfc:                  string,
	category:             Address_Category,
	source:               Registry_Flag,
	destination:          Registry_Flag,
	forwardable:          Registry_Flag,
	globally_reachable:   Registry_Flag,
	reserved_by_protocol: Registry_Flag,
}

Multicast_Scope :: enum u8 {
	Reserved_0         = 0x0,
	Interface_Local    = 0x1,
	Link_Local         = 0x2,
	Realm_Local        = 0x3,
	Admin_Local        = 0x4,
	Site_Local         = 0x5,
	Organization_Local = 0x8,
	Global             = 0xe,
	Reserved_F         = 0xf,
}

MAX_RANGE_PREFIXES :: 254

IP4_SPECIAL_PURPOSE_REGISTRY_UPDATED :: "2025-10-09"
IP6_SPECIAL_PURPOSE_REGISTRY_UPDATED :: "2025-10-09"

@(rodata)
IP4_SPECIAL_PURPOSE_REGISTRY := [?]Special_Purpose_Entry{
	{IP4_Prefix{{  0,   0,   0,   0},  8}, "This network",                              "RFC 791, Section 3.2",            .This_Network,        .True,           .False,          .False,          .False,          .True},
	{IP4_Prefix{{  0,   0,   0,   0}, 32}, "This host on this network",                 "RFC 1122, Section 3.2.1.3",       .Unspecified,         .True,           .False,          .False,          .False,          .True},
	{IP4_Prefix{{ 10,   0,   0,   0},  8}, "Private-Use",                               "RFC 1918",                        .Private_Use,         .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{100,  64,   0,   0}, 10}, "Shared Address Space",                      "RFC 6598",                        .Shared_Address,      .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{127,   0,   0,   0},  8}, "Loopback",                                  "RFC 1122, Section 3.2.1.3",       .Loopback,            .False,          .False,          .False,          .False,          .True},
	{IP4_Prefix{{169, 254,   0,   0}, 16}, "Link Local",                                "RFC 3927",                        .Link_Local,          .True,           .True,           .False,          .False,          .True},
	{IP4_Prefix{{172,  16,   0,   0}, 12}, "Private-Use",                               "RFC 1918",                        .Private_Use,         .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{192,   0,   0,   0}, 24}, "IETF Protocol Assignments",                 "RFC 6890, Section 2.1",           .Protocol_Assignment, .False,          .False,          .False,          .False,          .False},
	{IP4_Prefix{{192,   0,   0,   0}, 29}, "IPv4 Service Continuity Prefix",            "RFC 7335",                        .Translation,         .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{192,   0,   0,   8}, 32}, "IPv4 dummy address",                        "RFC 7600",                        .Dummy,               .True,           .False,          .False,          .False,          .False},
	{IP4_Prefix{{192,   0,   0,   9}, 32}, "Port Control Protocol Anycast",             "RFC 7723",                        .Protocol_Assignment, .True,           .True,           .True,           .True,           .False},
	{IP4_Prefix{{192,   0,   0,  10}, 32}, "Traversal Using Relays around NAT Anycast", "RFC 8155",                        .Protocol_Assignment, .True,           .True,           .True,           .True,           .False},
	{IP4_Prefix{{192,   0,   0, 170}, 32}, "NAT64/DNS64 Discovery",                     "RFC 8880; RFC 7050, Section 2.2", .Translation,         .False,          .False,          .False,          .False,          .True},
	{IP4_Prefix{{192,   0,   0, 171}, 32}, "NAT64/DNS64 Discovery",                     "RFC 8880; RFC 7050, Section 2.2", .Translation,         .False,          .False,          .False,          .False,          .True},
	{IP4_Prefix{{192,   0,   2,   0}, 24}, "Documentation (TEST-NET-1)",                "RFC 5737",                        .Documentation,       .False,          .False,          .False,          .False,          .False},
	{IP4_Prefix{{192,  31, 196,   0}, 24}, "AS112-v4",                                  "RFC 7535",                        .Protocol_Assignment, .True,           .True,           .True,           .True,           .False},
	{IP4_Prefix{{192,  52, 193,   0}, 24}, "AMT",                                       "RFC 7450",                        .Protocol_Assignment, .True,           .True,           .True,           .True,           .False},
	{IP4_Prefix{{192,  88,  99,   0}, 24}, "Deprecated (6to4 Relay Anycast)",           "RFC 7526",                        .Deprecated,          .Not_Applicable, .Not_Applicable, .Not_Applicable, .Not_Applicable, .Not_Applicable},
	{IP4_Prefix{{192,  88,  99,   2}, 32}, "6a44-relay anycast address",                "RFC 6751",                        .Translation,         .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{192, 168,   0,   0}, 16}, "Private-Use",                               "RFC 1918",                        .Private_Use,         .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{192, 175,  48,   0}, 24}, "Direct Delegation AS112 Service",           "RFC 7534",                        .Protocol_Assignment, .True,           .True,           .True,           .True,           .False},
	{IP4_Prefix{{198,  18,   0,   0}, 15}, "Benchmarking",                              "RFC 2544",                        .Benchmarking,        .True,           .True,           .True,           .False,          .False},
	{IP4_Prefix{{198,  51, 100,   0}, 24}, "Documentation (TEST-NET-2)",                "RFC 5737",                        .Documentation,       .False,          .False,          .False,          .False,          .False},
	{IP4_Prefix{{203,   0, 113,   0}, 24}, "Documentation (TEST-NET-3)",                "RFC 5737",                        .Documentation,       .False,          .False,          .False,          .False,          .False},
	{IP4_Prefix{{240,   0,   0,   0},  4}, "Reserved",                                  "RFC 1112, Section 4",             .Reserved,            .False,          .False,          .False,          .False,          .True},
	{IP4_Prefix{{255, 255, 255, 255}, 32}, "Limited Broadcast",                         "RFC 8190; RFC 919, Section 7",    .Limited_Broadcast,   .False,          .True,           .False,          .False,          .True},
}

@(rodata)
IP6_SPECIAL_PURPOSE_REGISTRY := [?]Special_Purpose_Entry{
	{IP6_Prefix{{0,      0,      0,      0, 0, 0,      0, 1}, 128}, "Loopback Address",                                   "RFC 4291",                  .Loopback,            .False, .False, .False, .False,          .True},
	{IP6_Prefix{{0,      0,      0,      0, 0, 0,      0, 0}, 128}, "Unspecified Address",                                "RFC 4291",                  .Unspecified,         .True,  .False, .False, .False,          .True},
	{IP6_Prefix{{0,      0,      0,      0, 0, 0xffff, 0, 0},  96}, "IPv4-mapped Address",                                "RFC 4291",                  .IP4_Mapped,          .False, .False, .False, .False,          .True},
	{IP6_Prefix{{0x64,   0xff9b, 0,      0, 0, 0,      0, 0},  96}, "IPv4-IPv6 Translat.",                                "RFC 6052",                  .Translation,         .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x64,   0xff9b, 1,      0, 0, 0,      0, 0},  48}, "IPv4-IPv6 Translat.",                                "RFC 8215",                  .Translation,         .True,  .True,  .True,  .False,          .False},
	{IP6_Prefix{{0x100,  0,      0,      0, 0, 0,      0, 0},  64}, "Discard-Only Address Block",                         "RFC 6666",                  .Discard_Only,        .True,  .True,  .True,  .False,          .False},
	{IP6_Prefix{{0x100,  0,      0,      1, 0, 0,      0, 0},  64}, "Dummy IPv6 Prefix",                                  "RFC 9780",                  .Dummy,               .True,  .False, .False, .False,          .False},
	{IP6_Prefix{{0x2001, 0,      0,      0, 0, 0,      0, 0},  23}, "IETF Protocol Assignments",                          "RFC 2928",                  .Protocol_Assignment, .False, .False, .False, .False,          .False},
	{IP6_Prefix{{0x2001, 0,      0,      0, 0, 0,      0, 0},  32}, "TEREDO",                                             "RFC 4380; RFC 8190",        .Translation,         .True,  .True,  .True,  .Not_Applicable, .False},
	{IP6_Prefix{{0x2001, 1,      0,      0, 0, 0,      0, 1}, 128}, "Port Control Protocol Anycast",                      "RFC 7723",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 1,      0,      0, 0, 0,      0, 2}, 128}, "Traversal Using Relays around NAT Anycast",          "RFC 8155",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 1,      0,      0, 0, 0,      0, 3}, 128}, "DNS-SD Service Registration Protocol Anycast",       "RFC 9665",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 2,      0,      0, 0, 0,      0, 0},  48}, "Benchmarking",                                       "RFC 5180; RFC Errata 1752", .Benchmarking,        .True,  .True,  .True,  .False,          .False},
	{IP6_Prefix{{0x2001, 3,      0,      0, 0, 0,      0, 0},  32}, "AMT",                                                "RFC 7450",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 4,      0x112,  0, 0, 0,      0, 0},  48}, "AS112-v6",                                           "RFC 7535",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 0x10,   0,      0, 0, 0,      0, 0},  28}, "Deprecated (previously ORCHID)",                     "RFC 4843",                  .Deprecated,          .Not_Applicable, .Not_Applicable, .Not_Applicable, .Not_Applicable, .Not_Applicable},
	{IP6_Prefix{{0x2001, 0x20,   0,      0, 0, 0,      0, 0},  28}, "ORCHIDv2",                                           "RFC 7343",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 0x30,   0,      0, 0, 0,      0, 0},  28}, "Drone Remote ID Protocol Entity Tags (DETs) Prefix", "RFC 9374",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x2001, 0xdb8,  0,      0, 0, 0,      0, 0},  32}, "Documentation",                                      "RFC 3849",                  .Documentation,       .False, .False, .False, .False,          .False},
	{IP6_Prefix{{0x2002, 0,      0,      0, 0, 0,      0, 0},  16}, "6to4",                                               "RFC 3056",                  .Translation,         .True,  .True,  .True,  .Not_Applicable, .False},
	{IP6_Prefix{{0x2620, 0x4f,   0x8000, 0, 0, 0,      0, 0},  48}, "Direct Delegation AS112 Service",                    "RFC 7534",                  .Protocol_Assignment, .True,  .True,  .True,  .True,           .False},
	{IP6_Prefix{{0x3fff, 0,      0,      0, 0, 0,      0, 0},  20}, "Documentation",                                      "RFC 9637",                  .Documentation,       .False, .False, .False, .False,          .False},
	{IP6_Prefix{{0x5f00, 0,      0,      0, 0, 0,      0, 0},  16}, "Segment Routing (SRv6) SIDs",                        "RFC 9602",                  .Protocol_Assignment, .True,  .True,  .True,  .False,          .False},
	{IP6_Prefix{{0xfc00, 0,      0,      0, 0, 0,      0, 0},   7}, "Unique-Local",                                       "RFC 4193; RFC 8190",        .Unique_Local,        .True,  .True,  .True,  .False,          .False},
	{IP6_Prefix{{0xfe80, 0,      0,      0, 0, 0,      0, 0},  10}, "Link-Local Unicast",                                 "RFC 4291",                  .Link_Local,          .True,  .True,  .False, .False,          .True},
}

/*
	INTERFACE / LINK STATE
*/
Network_Interface :: struct {
	adapter_name:     string, // On Windows this is a GUID that we could parse back into its u128 for more compact storage.
	friendly_name:    string,
	description:      string,
	dns_suffix:       string,

	physical_address: string, // MAC address, etc.
	mtu:              u32,

	unicast:          [dynamic]Lease,
	multicast:        [dynamic]Address,
	anycast:          [dynamic]Address,

	gateways:         [dynamic]Address,
	dhcp_v4:          Address,
	dhcp_v6:          Address,

	tunnel_type:      Tunnel_Type,

	link: struct {
		state:          Link_State,
		transmit_speed: u64,
		receive_speed:  u64,
	},
}

// Empty bit set is unknown state.
Link_States :: enum u32 {
	Up               = 1,
	Down             = 2,
	Testing          = 3,
	Dormant          = 4,
	Not_Present      = 5,
	Lower_Layer_Down = 6,
	Loopback         = 7,
}
Link_State :: bit_set[Link_States; u32]

Lease :: struct {
	address:  Address,
	netmask:  Netmask,
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

// DNS DEFINITIONS
DNS_Configuration :: struct {
	// Configuration files.
	resolv_conf: string,
	hosts_file:  string,

	resolv_conf_buf: [128]u8,
	hosts_file_buf:  [128]u8,

	// TODO: Allow loading these up with `reload_configuration()` call or the like,
	// so we don't have to do it each call.
	name_servers:       []Endpoint,
	hosts_file_entries: []DNS_Record,
}

DNS_Record_Type :: enum u16 {
	DNS_TYPE_A     = 0x1,  // IP4 address.
	DNS_TYPE_NS    = 0x2,  // IP6 address.
	DNS_TYPE_CNAME = 0x5,  // Another host name.
	DNS_TYPE_MX    = 0xf,  // Arbitrary binary data or text.
	DNS_TYPE_AAAA  = 0x1c, // Address of a name (DNS) server.
	DNS_TYPE_TEXT  = 0x10, // Address and preference priority of a mail exchange server.
	DNS_TYPE_SRV   = 0x21, // Address, port, priority, and weight of a host that provides a particular service.

	IP4            = DNS_TYPE_A,
	IP6            = DNS_TYPE_AAAA,
	CNAME          = DNS_TYPE_CNAME,
	TXT            = DNS_TYPE_TEXT,
	NS             = DNS_TYPE_NS,
	MX             = DNS_TYPE_MX,
	SRV            = DNS_TYPE_SRV,
}

// Base DNS Record. All DNS responses will carry a hostname and TTL (time to live) field.
DNS_Record_Base :: struct {
	record_name: string,
	ttl_seconds: u32, // The time in seconds that this service will take to update, after the record is updated.
}

// An IP4 address that the domain name maps to. There can be any number of these.
DNS_Record_IP4 :: struct {
	using base: DNS_Record_Base,
	address:    IP4_Address,
}

// An IPv6 address that the domain name maps to. There can be any number of these.
DNS_Record_IP6 :: struct {
	using base: DNS_Record_Base,
	address:    IP6_Address,
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

/*
	An endpoint for a service that is available through the domain name.
	This is the way to discover the services that a domain name provides.

	Clients MUST attempt to contact the host with the lowest priority that they can reach.
	If two hosts have the same priority, they should be contacted in the order according to their weight.
	Hosts with larger weights should have a proportionally higher chance of being contacted by clients.
	A weight of zero indicates a very low weight, or, when there is no choice (to reduce visual noise).

	The host may be "." to indicate that it is "decidedly not available" on this domain.
*/
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
	DNS_Record_IP4,
	DNS_Record_IP6,
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
