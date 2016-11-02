/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_callback_x86.h
 Description: Callback - Header for x86
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



#ifndef DYNCALL_CALLBACK_X86_H_
#define DYNCALL_CALLBACK_X86_H_

#include "dyncall_callback.h"

#include "dyncall_thunk.h"
#include "dyncall_args_x86.h"

struct DCCallback
{
  DCThunk            thunk;         /* offset 0,  size 16 */
  DCCallbackHandler* handler;       /* offset 16 */
  DCArgsVT*          args_vt;       /* offset 20 */
  size_t             stack_cleanup; /* offset 24 */
  void*              userdata;      /* offset 28 */
};

int dcCleanupSize_x86_cdecl   (const char* args_signature);
int dcCleanupSize_x86_std     (const char* args_signature);
int dcCleanupSize_x86_fast_ms (const char* args_signature);
int dcCleanupSize_x86_fast_gnu(const char* args_signature);

#endif /* DYNCALL_CALLBACK_X86_H_ */
