#+private
#+build openbsd

@(default_calling_convention="c")
foreign libc {
	@(link_name="getthrid")       _unix_getthrid       :: proc() -> int ---
	@(link_name="sysconf")        _sysconf             :: proc(name: c.int) -> c.long ---
}

@(require_results)
_get_current_thread_id :: proc "contextless" () -> int {
	return _unix_getthrid()
}

_SC_NPROCESSORS_ONLN :: 503

@(private, require_results)
_get_processor_core_count :: proc() -> int {
	return int(_sysconf(_SC_NPROCESSORS_ONLN))
}