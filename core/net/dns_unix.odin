//+build linux, darwin, freebsd
package net
/*
	Package net implements cross-platform Berkeley Sockets, DNS resolution and associated procedures.
	For other protocols and their features, see subdirectories of this package.
*/

/*
	Copyright 2022 Tetralux        <tetraluxonpc@gmail.com>
	Copyright 2022 Colin Davidson  <colrdavidson@gmail.com>
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Copyright 2024 Feoramund       <rune@swevencraft.org>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Tetralux:        Initial implementation
		Colin Davidson:  Linux platform code, OSX platform code, Odin-native DNS resolver
		Jeroen van Rijn: Cross platform unification, code style, documentation
		Feoramund:       FreeBSD platform code
*/
import "core:strings"

@(private)
_get_dns_records_os :: proc(hostname: string, type: DNS_Record_Type, allocator := context.allocator) -> (records: []DNS_Record, err: DNS_Error) {
	context.allocator = allocator

	if type != .SRV {
		// NOTE(tetra): 'hostname' can contain underscores when querying SRV records
		ok := validate_hostname(hostname)
		if !ok {
			return nil, .Invalid_Hostname_Error
		}
	}

	name_servers, resolve_ok := load_resolv_conf(dns_configuration.resolv_conf)
	defer delete(name_servers)
	if !resolve_ok {
		return nil, .Invalid_Resolv_Config_Error
	}
	if len(name_servers) == 0 {
		return
	}

	hosts, hosts_ok := load_hosts(dns_configuration.hosts_file)
	defer delete(hosts)
	if !hosts_ok {
		return nil, .Invalid_Hosts_Config_Error
	}

	host_overrides := make([dynamic]DNS_Record)
	for host in hosts {
		if strings.compare(host.name, hostname) != 0 {
			continue
		}

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

	if len(host_overrides) > 0 {
		return host_overrides[:], nil
	}

	return get_dns_records_from_nameservers(hostname, type, name_servers, host_overrides[:])
}
