#+build windows
package sys_windows

foreign import "system:iphlpapi.lib"

Address_Family :: enum u32 {
	Unspecified = 0,   // Return both IPv4 and IPv6 addresses associated with adapters with them enabled.
	IPv4        = 2,   // Return only IPv4 addresses associated with adapters with it enabled.
	IPv6        = 23,  // Return only IPv6 addresses associated with adapters with it enabled.
}

GAA_Flag :: enum u32 {
	Skip_Unicast                 = 0,  // Do not return unicast addresses.
	Skip_Anycast                 = 1,  // Do not return IPv6 anycast addresses.
	Skip_Multicast               = 2,  // Do not return multicast addresses.
	Skip_DNS_Server              = 3,  // Do not return addresses of DNS servers.
	Include_Prefix               = 4,  // (XP SP1+) Return a list of IP address prefixes on this adapter. When this flag is set, IP address prefixes are returned for both IPv6 and IPv4 addresses.
	Skip_Friendly_Name           = 5,  // Do not return the adapter friendly name.
	Include_WINS_info            = 6,  // (Vista+) Return addresses of Windows Internet Name Service (WINS) servers.
	Include_Gateways             = 7,  // (Vista+) Return the addresses of default gateways.
	Include_All_Interfaces       = 8,  // (Vista+) Return addresses for all NDIS interfaces.
	Include_All_Compartments     = 9,  // (Reserved, Unsupported) Return addresses in all routing compartments.
	Include_Tunnel_Binding_Order = 10, // (Vista+) Return the adapter addresses sorted in tunnel binding order.
}
GAA_Flags :: bit_set[GAA_Flag; u32]

IP_Adapter_Addresses :: struct {
	Raw: struct #raw_union {
		Alignment: u64,
		Anonymous: struct {
			Length:  u32,
			IfIndex: u32,
		},
	},
	Next:                   ^IP_Adapter_Addresses,
	AdapterName:            cstring,
	FirstUnicastAddress:    ^IP_ADAPTER_UNICAST_ADDRESS_LH,
	FirstAnycastAddress:    ^IP_ADAPTER_ANYCAST_ADDRESS_XP,
	FirstMulticastAddress:  ^IP_ADAPTER_MULTICAST_ADDRESS_XP,
	FirstDnsServerAddress:  ^IP_ADAPTER_DNS_SERVER_ADDRESS_XP,
	DnsSuffix:              ^u16,
	Description:            ^u16,
	FriendlyName:           ^u16,
	PhysicalAddress:        [8]u8,
	PhysicalAddressLength:  u32,
	Anonymous2:             struct #raw_union {
		Flags:     u32,
		Anonymous: struct {
			_bitfield: u32,
		},
	},
	MTU:                    u32,
	IfType:                 u32,
	OperStatus:             IF_OPER_STATUS,
	Ipv6IfIndex:            u32,
	ZoneIndices:            [16]u32,
	FirstPrefix:            rawptr, // ^IP_ADAPTER_PREFIX_XP,
	TransmitLinkSpeed:      u64,
	ReceiveLinkSpeed:       u64,
	FirstWinsServerAddress: rawptr, // ^IP_ADAPTER_WINS_SERVER_ADDRESS_LH,
	FirstGatewayAddress:    ^IP_ADAPTER_GATEWAY_ADDRESS_LH,
	Ipv4Metric:             u32,
	Ipv6Metric:             u32,
	Luid:                   NET_LUID_LH,
	Dhcpv4Server:           SOCKET_ADDRESS,
	CompartmentId:          u32,
	NetworkGuid:            GUID,
	ConnectionType:         NET_IF_CONNECTION_TYPE,
	TunnelType:             TUNNEL_TYPE,
	Dhcpv6Server:           SOCKET_ADDRESS,
	Dhcpv6ClientDuid:       [130]u8,
	Dhcpv6ClientDuidLength: u32,
	Dhcpv6Iaid:             u32,
	FirstDnsSuffix:         rawptr, // ^IP_ADAPTER_DNS_SUFFIX,
}

IP_ADAPTER_UNICAST_ADDRESS_LH :: struct {
	Anonymous:          struct #raw_union {
		Alignment: u64,
		Anonymous: struct {
			Length: u32,
			Flags:  u32,
		},
	},
	Next:               ^IP_ADAPTER_UNICAST_ADDRESS_LH,
	Address:            SOCKET_ADDRESS,
	PrefixOrigin:       NL_PREFIX_ORIGIN,
	SuffixOrigin:       NL_SUFFIX_ORIGIN,
	DadState:           NL_DAD_STATE,
	ValidLifetime:      u32,
	PreferredLifetime:  u32,
	LeaseLifetime:      u32,
	OnLinkPrefixLength: u8,
}

IP_ADAPTER_ANYCAST_ADDRESS_XP :: struct {
	Anonymous: struct #raw_union {
		Alignment: u64,
		Anonymous: struct {
			Length: u32,
			Flags:  u32,
		},
	},
	Next:      ^IP_ADAPTER_ANYCAST_ADDRESS_XP,
	Address:   SOCKET_ADDRESS,
}

IP_ADAPTER_MULTICAST_ADDRESS_XP :: struct {
	Anonymous: struct #raw_union {
		Alignment: u64,
		Anonymous: struct {
			Length: u32,
			Flags:  u32,
		},
	},
	Next:      ^IP_ADAPTER_MULTICAST_ADDRESS_XP,
	Address:   SOCKET_ADDRESS,
}

IP_ADAPTER_GATEWAY_ADDRESS_LH :: struct {
	Anonymous: struct #raw_union {
		Alignment: u64,
		Anonymous: struct {
			Length:   u32,
			Reserved: u32,
		},
	},
	Next:      ^IP_ADAPTER_GATEWAY_ADDRESS_LH,
	Address:   SOCKET_ADDRESS,
}

IP_ADAPTER_DNS_SERVER_ADDRESS_XP :: struct {
	Anonymous: struct #raw_union {
		Alignment: u64,
		Anonymous: struct {
			Length:   u32,
			Reserved: u32,
		},
	},
	Next:      ^IP_ADAPTER_DNS_SERVER_ADDRESS_XP,
	Address:   SOCKET_ADDRESS,
}

IF_OPER_STATUS :: enum i32 {
	Up             = 1,
	Down           = 2,
	Testing        = 3,
	Unknown        = 4,
	Dormant        = 5,
	NotPresent     = 6,
	LowerLayerDown = 7,
}

NET_LUID_LH :: struct #raw_union {
	Value: u64,
	Info:  struct {
		_bitfield: u64,
	},
}

SOCKET_ADDRESS :: struct {
	lpSockaddr:      ^SOCKADDR,
	iSockaddrLength: i32,
}

NET_IF_CONNECTION_TYPE :: enum i32 {
	NET_IF_CONNECTION_DEDICATED = 1,
	NET_IF_CONNECTION_PASSIVE   = 2,
	NET_IF_CONNECTION_DEMAND    = 3,
	NET_IF_CONNECTION_MAXIMUM   = 4,
}

TUNNEL_TYPE :: enum i32 {
	TUNNEL_TYPE_NONE    = 0,
	TUNNEL_TYPE_OTHER   = 1,
	TUNNEL_TYPE_DIRECT  = 2,
	TUNNEL_TYPE_6TO4    = 11,
	TUNNEL_TYPE_ISATAP  = 13,
	TUNNEL_TYPE_TEREDO  = 14,
	TUNNEL_TYPE_IPHTTPS = 15,
}
NL_PREFIX_ORIGIN :: enum i32 {
	IpPrefixOriginOther               = 0,
	IpPrefixOriginManual              = 1,
	IpPrefixOriginWellKnown           = 2,
	IpPrefixOriginDhcp                = 3,
	IpPrefixOriginRouterAdvertisement = 4,
	IpPrefixOriginUnchanged           = 16,
}

NL_SUFFIX_ORIGIN :: enum i32 {
	NlsoOther                      = 0,
	NlsoManual                     = 1,
	NlsoWellKnown                  = 2,
	NlsoDhcp                       = 3,
	NlsoLinkLayerAddress           = 4,
	NlsoRandom                     = 5,
	IpSuffixOriginOther            = 0,
	IpSuffixOriginManual           = 1,
	IpSuffixOriginWellKnown        = 2,
	IpSuffixOriginDhcp             = 3,
	IpSuffixOriginLinkLayerAddress = 4,
	IpSuffixOriginRandom           = 5,
	IpSuffixOriginUnchanged        = 16,
}

NL_DAD_STATE :: enum i32 {
	NldsInvalid          = 0,
	NldsTentative        = 1,
	NldsDuplicate        = 2,
	NldsDeprecated       = 3,
	NldsPreferred        = 4,
	IpDadStateInvalid    = 0,
	IpDadStateTentative  = 1,
	IpDadStateDuplicate  = 2,
	IpDadStateDeprecated = 3,
	IpDadStatePreferred  = 4,
}

@(default_calling_convention = "system")
foreign iphlpapi {
	/*
		The GetAdaptersAddresses function retrieves the addresses associated with the adapters on the local computer.
		See: https://docs.microsoft.com/en-us/windows/win32/api/iphlpapi/nf-iphlpapi-getadaptersaddresses
	*/
	@(link_name="GetAdaptersAddresses") get_adapters_addresses :: proc(
		family:            Address_Family,
		flags:             GAA_Flags,
		_reserved:         rawptr,
		adapter_addresses: [^]IP_Adapter_Addresses,
		size:              ^u32,
	) -> ULONG ---

}
