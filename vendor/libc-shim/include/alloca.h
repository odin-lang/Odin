#ifdef __cplusplus
extern "C" {
#endif

#pragma once

#include <stddef.h>

void	*alloca(size_t);		/* built-in for gcc */

#if defined(__GNUC__) && __GNUC__ >= 3
/* built-in for gcc 3 */
#undef	alloca
#undef	__alloca
#define	alloca(size)	__alloca(size)
#define	__alloca(size)	__builtin_alloca(size)
#endif

#ifdef __cplusplus
}
#endif
