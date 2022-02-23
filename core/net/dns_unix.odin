//+build linux, darwin, freebsd, !windows
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
*/
package net

import "core:strings"

get_dns_records_unix :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, ok: bool) {
	context.allocator = allocator

	if type != .SRV {
		// NOTE(tetra): 'hostname' can contain underscores when querying SRV records
		validate_hostname(hostname) or_return
	}

	name_servers := load_resolv_conf(dns_configuration.resolv_conf) or_return
	defer delete(name_servers)
	if len(name_servers) == 0 {
		return
	}

	hosts := load_hosts(dns_configuration.hosts_file) or_return
	defer delete(hosts)
	if len(hosts) == 0 {
		return
	}

	host_overrides := make([dynamic]DNS_Record, 0)
	for host in hosts {
		if strings.compare(host.name, hostname) == 0 {
			if type == .IP4 && family_from_address(host.addr) == .IP4 {
				record := DNS_Record_IP4{
					base = {
						record_name = strings.clone(hostname),
						ttl_seconds = 0,
					},
					address = host.addr.(IP4_Address),
				}
				append(&host_overrides, record)
			} else if type == .IP6 && family_from_address(host.addr) == .IP6 {
				record := DNS_Record_IP6{
					base = {
						record_name = strings.clone(hostname),
						ttl_seconds = 0,
					},
					address = host.addr.(IP6_Address),
				}
				append(&host_overrides, record)
			}
		}
	}

	if len(host_overrides) > 0 {
		return host_overrides[:], true
	}

	return get_dns_records_from_nameservers(hostname, type, name_servers, host_overrides[:])
}