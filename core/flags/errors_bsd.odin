//+build netbsd, openbsd
package flags

import "base:runtime"

Unified_Parse_Error_Reason :: union #shared_nil {
	Parse_Error_Reason,
	runtime.Allocator_Error,
}
