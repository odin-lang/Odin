package build

import "core:runtime"

DEFAULT_VET :: Vet_Flags{.Unused, .Shadowing, .Using_Stmt}

_build_ctx: struct {
	projects: [dynamic]^Project,
}
_context: runtime.Context