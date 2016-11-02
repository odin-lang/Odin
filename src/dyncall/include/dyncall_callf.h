/*

 Package: dyncall
 Library: dyncall
 File: dyncall/dyncall_callf.h
 Description: formatted call interface to dyncall
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



/*

  dyncall formatted calls C API

  REVISION
  2007/12/11 initial
  
*/


#ifndef DYNCALL_CALLF_H
#define DYNCALL_CALLF_H

/* dyncall formatted calls */

#include "dyncall.h"
#include "dyncall_signature.h"
#include "dyncall_value.h"

#include <stdarg.h>

void dcArgF (DCCallVM* vm, const DCsigchar* signature, ...);
void dcVArgF(DCCallVM* vm, const DCsigchar* signature, va_list args);

void dcCallF (DCCallVM* vm, DCValue* result, DCpointer funcptr, const DCsigchar* signature, ...);
void dcVCallF(DCCallVM* vm, DCValue* result, DCpointer funcptr, const DCsigchar* signature, va_list args);

#endif /* DYNCALL_CALLF_H */

