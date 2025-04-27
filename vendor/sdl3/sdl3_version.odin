package sdl3

import "core:c"

MAJOR_VERSION :: 3
MINOR_VERSION :: 2
MICRO_VERSION :: 10

@(require_results) VERSIONNUM       :: #force_inline proc "c" (major, minor, patch: c.int) -> c.int { return (major * 1000000) + (minor * 1000) + patch }
@(require_results) VERSIONNUM_MAJOR :: #force_inline proc "c" (version: c.int)             -> c.int { return version / 1000000                          }
@(require_results) VERSIONNUM_MINOR :: #force_inline proc "c" (version: c.int)             -> c.int { return (version / 1000) % 1000                    }
@(require_results) VERSIONNUM_MICRO :: #force_inline proc "c" (version: c.int)             -> c.int { return version % 1000                             }

VERSION :: MAJOR_VERSION*1000000 + MINOR_VERSION*1000 + MICRO_VERSION

@(require_results) VERSION_ATLEAST :: proc "c" (X, Y, Z: c.int) -> bool { return VERSION >= VERSIONNUM(X, Y, Z) }


@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetVersion  :: proc() -> c.int ---
	GetRevision :: proc() -> cstring ---
}
