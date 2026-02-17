#+build darwin, freebsd, openbsd, netbsd, linux, windows, wasi
#+private
package net

import "core:os"

load_resolv_conf :: proc(resolv_conf_path: string, allocator := context.allocator) -> (name_servers: []Endpoint, ok: bool) {
	context.allocator = allocator

	res, err := os.read_entire_file(resolv_conf_path, allocator)
	if err != nil { return }
	defer delete(res)
	resolv_str := string(res)

	return parse_resolv_conf(resolv_str), true
}

load_hosts :: proc(hosts_file_path: string, allocator := context.allocator) -> (hosts: []DNS_Host_Entry, ok: bool) {
	handle, err := os.open(hosts_file_path)
	if err != nil { return }
	defer os.close(handle)

	return parse_hosts(os.to_stream(handle), allocator)
}