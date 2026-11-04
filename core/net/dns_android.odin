#+build linux:android
package net

import "core:strings"

foreign import libandroid "system:android"

// <android/multinetwork.h>, API level 29.
@(private="file", default_calling_convention="c")
foreign libandroid {
	android_res_nquery  :: proc(network: u64, dname: cstring, ns_class: i32, ns_type: i32, flags: u32) -> i32 ---
	android_res_nresult :: proc(fd: i32, rcode: ^i32, answer: [^]u8, anslen: uint) -> i32 ---
}

/*
	Asks netd, Android's resolver, for the `type` records of `hostname`.

	netd answers for the app's default network, with the device's private DNS and VPN settings. Its answer is
	a DNS response, parsed as the answers of name servers are.
*/
@(private)
get_dns_records_from_netd :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, err: DNS_Error) {
	context.allocator = allocator

	NETWORK_UNSPECIFIED :: 0
	CLASS_IN            :: 1

	name := strings.clone_to_cstring(hostname, context.temp_allocator)
	fd := android_res_nquery(NETWORK_UNSPECIFIED, name, CLASS_IN, i32(type), 0)
	if fd < 0 {
		return nil, .Connection_Error
	}

	// `android_res_nresult` waits for the answer, and closes `fd`.
	response := make([]u8, 65536)
	defer delete(response)
	rcode: i32
	size := android_res_nresult(fd, &rcode, raw_data(response), len(response))
	if size < 0 {
		return nil, .Connection_Error
	}

	rsp, _, ok := parse_response(response[:size], type)
	if !ok {
		return nil, .Server_Error
	}
	if len(rsp) != 0 {
		records = rsp[:]
	}
	return
}
