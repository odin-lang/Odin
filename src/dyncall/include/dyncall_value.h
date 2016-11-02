/*

 Package: dyncall
 Library: dyncall
 File: dyncall/dyncall_value.h
 Description: Value variant type
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

  dyncall value variant

  a value variant union-type that carries all supported dyncall types.

  REVISION
  2007/12/11 initial

*/

#ifndef DYNCALL_VALUE_H
#define DYNCALL_VALUE_H

#include "dyncall_types.h"

#ifdef __cplusplus
extern "C" {
#endif 

typedef union DCValue_ DCValue;

union DCValue_
{
#if defined (DC__Arch_PPC32) && defined(DC__Endian_BIG)
  DCbool        B;
  struct { DCchar  c_pad[3]; DCchar  c; };
  struct { DCuchar C_pad[3]; DCuchar C; };
  struct { DCshort s_pad;    DCshort s; };
  struct { DCshort S_pad;    DCshort S; };
  DCint         i;
  DCuint        I;
#elif defined (DC__Arch_PPC64) && defined(DC__Endian_BIG)
  struct { DCbool  B_pad;    DCbool  B; };
  struct { DCchar  c_pad[7]; DCchar  c; };
  struct { DCuchar C_pad[7]; DCuchar C; };
  struct { DCshort s_pad[3]; DCshort s; };
  struct { DCshort S_pad[3]; DCshort S; };
  struct { DCint   i_pad;    DCint   i; };
  struct { DCint   I_pad;    DCuint  I; };
#else
  DCbool        B;
  DCchar        c;
  DCuchar       C;
  DCshort       s;
  DCushort      S;
  DCint         i;
  DCuint        I;
#endif
  DClong        j;
  DCulong       J;
  DClonglong    l;
  DCulonglong   L;
  DCfloat       f;
  DCdouble      d;
  DCpointer     p;
  DCstring      Z;
};

#ifdef __cplusplus
}
#endif

#endif /* DYNCALL_VALUE_H */

