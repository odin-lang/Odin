//+build !freebsd !netbsd !openbsd
package flags

import "base:runtime"
import "core:net"

Unified_Parse_Error_Reason :: union #shared_nil {
	Parse_Error_Reason,
	runtime.Allocator_Error,
	net.Parse_Endpoint_Error,
}
