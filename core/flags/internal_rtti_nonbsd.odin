//+private
//+build !freebsd !netbsd !openbsd
package flags

import "core:net"

// This proc exists purely as a workaround for import restrictions.
// Returns true if caller should return early.
try_net_parse_workaround :: #force_inline proc (
	data_type: typeid,
	str: string,
	ptr: rawptr,
	out_error: ^Error,
) -> bool {
	if data_type == net.Host_Or_Endpoint {
		addr, net_error := net.parse_hostname_or_endpoint(str)
		if net_error != nil {
			// We pass along `net.Error` here.
			out_error^ = Parse_Error {
				net_error,
				"Invalid Host/Endpoint.",
			}
			return true
		}

		(cast(^net.Host_Or_Endpoint)ptr)^ = addr
		return true
	}

	return false
}
