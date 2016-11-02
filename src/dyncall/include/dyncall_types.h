/*

 Package: dyncall
 Library: dyncall
 File: dyncall/dyncall_types.h
 Description: Typedefs
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

  dyncall argument- and return-types

  REVISION
  2007/12/11 initial
  
*/

#ifndef DYNCALL_TYPES_H
#define DYNCALL_TYPES_H

#include <stddef.h>

#include "dyncall_config.h"

#ifdef __cplusplus
extern "C" {
#endif 

typedef void            DCvoid;
typedef DC_BOOL         DCbool;
typedef char            DCchar;
typedef unsigned char   DCuchar;
typedef short           DCshort;
typedef unsigned short  DCushort;
typedef int             DCint;
typedef unsigned int    DCuint;
typedef long            DClong;
typedef unsigned long   DCulong;
typedef DC_LONG_LONG    DClonglong;
typedef unsigned DC_LONG_LONG DCulonglong;
typedef float           DCfloat;
typedef double          DCdouble;
typedef DC_POINTER      DCpointer;
typedef const char*     DCstring;

typedef size_t          DCsize;

#define DC_TRUE   1
#define DC_FALSE  0

#ifdef __cplusplus
}
#endif

#endif /* DYNCALL_TYPES_H */

