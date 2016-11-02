/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_callback_ppc64.h
 Description: Callback - Header for ppc64
 License:

   Copyright (c) 2014-2015 Masanori Mitsugi <mitsugi@linux.vnet.ibm.com>

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

#ifndef DYNCALL_CALLBACK_PPC64_H
#define DYNCALL_CALLBACK_PPC64_H

#include "dyncall_callback.h"

#include "dyncall_thunk.h"
#include "dyncall_args_ppc64.h"

/*
  ELF v2
  thunk           : offset 0,  size 48
  handler         : offset 48, size  8
  stack_cleanup   : offset 56, size  8
  userdata        : offset 64, size  8

  ELF v1
  thunk           : offset 0,  size 64
  handler         : offset 64, size  8
  stack_cleanup   : offset 72, size  8
  userdata        : offset 80, size  8
*/

struct DCCallback
{
  DCThunk            thunk;
  DCCallbackHandler* handler;
  size_t             stack_cleanup;
  void*              userdata;
};

#endif /* DYNCALL_CALLBACK_PPC64_H */

