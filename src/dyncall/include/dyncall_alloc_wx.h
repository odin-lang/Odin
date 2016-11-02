/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_alloc_wx.h
 Description: Allocate write/executable memory - Interface
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


#ifndef DYNCALL_ALLOC_WX_HPP
#define DYNCALL_ALLOC_WX_HPP

#include "dyncall_types.h"

typedef int DCerror;

#ifdef __cplusplus
extern "C" {
#endif

DCerror dcAllocWX(DCsize size, void** p);
void    dcFreeWX (void* p, DCsize size);

#ifdef __cplusplus
}
#endif


#endif /* DYNCALL_ALLOC_WX_HPP */

