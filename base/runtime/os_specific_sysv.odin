#+private
#+build linux, freebsd, netbsd, openbsd
package runtime

// See the System Five Application Binary Interface § 3.4.3 for more information.

// Figure 3.11: Auxiliary Vector Types
Auxiliary_Vector_Type :: enum i32 {
	AT_NULL   = 0,  // ignored
	AT_IGNORE = 1,  // ignored
	AT_EXECFD = 2,  // a_val
	AT_PHDR   = 3,  // a_ptr
	AT_PHENT  = 4,  // a_val
	AT_PHNUM  = 5,  // a_val
	AT_PAGESZ = 6,  // a_val
	AT_BASE   = 7,  // a_ptr
	AT_FLAGS  = 8,  // a_val
	AT_ENTRY  = 9,  // a_ptr
	AT_NOTELF = 10, // a_val
	AT_UID    = 11, // a_val
	AT_EUID   = 12, // a_val
	AT_GID    = 13, // a_val
	AT_EGID   = 14, // a_val
}

@(private="file")
c_long :: i32 when size_of(rawptr) == 4 else i64

// Figure 3.10: auxv_t Type Definition
auxv_t :: struct {
	a_type: Auxiliary_Vector_Type,
	using a_un: struct #raw_union {
		a_val: c_long,      // long
		a_ptr: rawptr,      // void*
		a_fnc: proc "c" (), // void (*)()
	},
}

auxv__: [^]auxv_t

// Mind the alphanumeric sorted naming of the files in `base:runtime`, as this
// init needs to run before the virtual memory init.
@(init)
init_auxv :: proc "contextless" () {
	// This is similar to how we get the environment on Linux.
	#no_bounds_check auxv := cast([^]rawptr)&args__[len(args__) + 1]
	for auxv[0] != nil {
		auxv = auxv[1:]
	}
	auxv__ = cast([^]auxv_t)(auxv[1:])
}

// Get a value from the auxiliary vector.
_get_auxiliary :: proc "contextless" (at: Auxiliary_Vector_Type) -> (value: auxv_t, found: bool) {
	for ap := auxv__; ap != nil && ap[0].a_type != .AT_NULL; ap = ap[1:] {
		if ap[0].a_type == at {
			return ap[0], true
		}
	}
	return
}
