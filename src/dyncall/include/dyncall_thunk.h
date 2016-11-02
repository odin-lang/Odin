/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_thunk.h
 Description: Thunk - Interface
 License:

   Copyright (c) 2007-2015 Daniel Adler <dadler@uni-goettingen.de>,
                           Tassilo Philipp <tphilipp@potion-studios.com>

   Permission to use, copy, modify, and distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

*/


#ifndef DYNCALL_THUNK_H
#define DYNCALL_THUNK_H

/**
 ** dyncall thunks
 **
 ** thunks are small-size hybrid code/data objects, created at run-time to
 ** be used as function pointers with associated data and entry functions.
 **
 ** The header contains code, that does load its address into a designated scratch
 ** register and will jump to a thunk function.
 **
 ** Thunk entry procedures are compiled functions, that are called as a result of
 ** a thunk function.
 ** There is one thunk entry currently for supporting callbacks.
 **
 ** Thunk context register ( ::= an available scratch register in the calling convention):
 **
 ** x86:  eax
 ** x64:  rax
 ** ppc:   r2
 ** arm:  r12
 ** arm64: x9
 **
 **/

#include "dyncall_macros.h"

typedef struct DCThunk_ DCThunk;

#ifdef __cplusplus
extern "C" {
#endif

void   dcbInitThunk(DCThunk* p, void (*entry)());

#if defined(DC__Arch_Intel_x86)
#include "dyncall_thunk_x86.h"
#elif defined (DC__Arch_AMD64)
#include "dyncall_thunk_x64.h"
#elif defined (DC__Arch_PPC32)
#include "dyncall_thunk_ppc32.h"
#elif defined (DC__Arch_PPC64)
#include "dyncall_thunk_ppc64.h"
#elif defined (DC__Arch_ARM_ARM)
#include "dyncall_thunk_arm32_arm.h"
#elif defined (DC__Arch_ARM_THUMB)
#include "dyncall_thunk_arm32_thumb.h"
#elif defined (DC__Arch_MIPS)
#include "dyncall_thunk_mips.h"
#elif defined (DC__Arch_Sparc)
#include "dyncall_thunk_sparc32.h"
#elif defined (DC__Arch_Sparcv9)
#include "dyncall_thunk_sparc64.h"
#elif defined (DC__Arch_ARM64)
#include "dyncall_thunk_arm64.h"
#endif

#ifdef __cplusplus
}
#endif


#endif /* DYNCALL_THUNK_H */
