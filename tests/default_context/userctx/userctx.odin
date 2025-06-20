package userctx	

import "base:runtime"

Flag :: enum u64 {
	Main,
	Init,
	Global,

	Shared,
	Shared_Init,
	Shared_Global,
}

Flag_Set :: bit_set[Flag; u64]

Flag_Names :: [Flag]string {
	.Main          = "Main",
	.Init          = "Init",
	.Global        = "Global",
	.Shared        = "Shared",
	.Shared_Init   = "Shared_Init",
	.Shared_Global = "Shared_Global"
}

User_Context :: struct {
	flags: Flag_Set,
}

set_flag :: proc(flag: Flag) {
	@(static, rodata) names := Flag_Names

	if context.user_ptr == nil {
		runtime.print_string("User_Context missing for: ")
		runtime.print_string(names[flag])
		runtime.print_string("\n")
		return
	}

	when ODIN_DEBUG {
		runtime.print_string("((@ ")
		runtime.print_string(names[flag])
		runtime.print_string("))")
	}
	uc := cast(^User_Context)context.user_ptr
	uc.flags += {flag}
}
