#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(push)
	#pragma warning(disable: 4200)
	#pragma warning(disable: 4201)
	#define restrict gb_restrict
#endif

#include "tilde/tb.h"

#if defined(GB_SYSTEM_WINDOWS)
	#pragma warning(pop)
#endif


bool tb_generate_code(Checker *c) {
	gb_printf_err("TODO(bill): implement Tilde Backend\n");
	return false;
}