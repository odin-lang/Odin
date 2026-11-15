package net

special_purpose_entry :: proc(address: Address) -> (entry: Special_Purpose_Entry, ok: bool) {
	registry: []Special_Purpose_Entry
	switch _ in address {
	case IP4_Address: registry = IP4_SPECIAL_PURPOSE_REGISTRY[:]
	case IP6_Address: registry = IP6_SPECIAL_PURPOSE_REGISTRY[:]
	}
	best := -1
	for candidate in registry {
		_, length, _, _ := _prefix_value(candidate.prefix)
		if int(length) > best && prefix_contains(candidate.prefix, address) {
			best  = int(length)
			entry = candidate
			ok    = true
		}
	}
	return
}

classify_address :: proc(address: Address) -> Address_Category {
	if entry, ok := special_purpose_entry(address); ok {
		return entry.category
	}
	switch v in address {
	case IP4_Address:
		if v[0] >= 224 && v[0] <= 239 {
			return .Multicast
		}
		return .Global_Unicast
	case IP6_Address:
		switch {
		case v[0] >= 0xff00:          return .Multicast
		case v[0] & 0xffc0 == 0xfec0: return .Deprecated
		case v[0] & 0xe000 == 0x2000: return .Global_Unicast
		}
		return .Reserved
	}
	return .Unspecified
}

is_globally_reachable :: proc(address: Address) -> bool {
	if entry, ok := special_purpose_entry(address); ok {
		switch entry.globally_reachable {
		case .True:           return true
		case .False:          return false
		case .Not_Applicable: return entry.category != .Deprecated
		}
	}
	#partial switch classify_address(address) {
	case .Global_Unicast:
		return true
	case .Multicast:
		scope, _ := multicast_scope(address)
		return scope == .Global
	}
	return false
}

multicast_scope :: proc(address: Address) -> (scope: Multicast_Scope, ok: bool) {
	switch v in address {
	case IP4_Address:
		switch {
		case v[0] < 224 || v[0] > 239:              return
		case v[0] == 224 && v[1] == 0 && v[2] == 0: return .Link_Local, true
		case v[0] == 239 && v[1] == 255:            return .Site_Local, true
		case v[0] == 239 && v[1] & 0xfc == 192:     return .Organization_Local, true
		case v[0] == 239:                           return .Admin_Local, true
		}
		return .Global, true
	case IP6_Address:
		if v[0] < 0xff00 {
			return
		}
		return Multicast_Scope(u16(v[0]) & 0xf), true
	}
	return
}

is_loopback :: proc(address: Address) -> bool {
	return classify_address(address) == .Loopback
}

is_unspecified :: proc(address: Address) -> bool {
	return classify_address(address) == .Unspecified
}

is_private_use :: proc(address: Address) -> bool {
	return classify_address(address) == .Private_Use
}

is_unique_local :: proc(address: Address) -> bool {
	return classify_address(address) == .Unique_Local
}

is_shared_address :: proc(address: Address) -> bool {
	return classify_address(address) == .Shared_Address
}

is_link_local :: proc(address: Address) -> bool {
	return classify_address(address) == .Link_Local
}

is_documentation :: proc(address: Address) -> bool {
	return classify_address(address) == .Documentation
}

is_benchmarking :: proc(address: Address) -> bool {
	return classify_address(address) == .Benchmarking
}

is_multicast :: proc(address: Address) -> bool {
	return classify_address(address) == .Multicast
}

is_limited_broadcast :: proc(address: Address) -> bool {
	return classify_address(address) == .Limited_Broadcast
}

is_global_unicast :: proc(address: Address) -> bool {
	return classify_address(address) == .Global_Unicast
}
