/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args.h
 Description: Callback's Arguments VM - Interface
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


#ifndef DYNCALL_ARGS_H
#define DYNCALL_ARGS_H

/*
 * dyncall args C API
 *
 * dyncall args provides serialized access to arguments of a function call.
 * related concepts: callback
 *
 */

#include "dyncall.h"


#ifdef __cplusplus
extern "C" {
#endif

typedef struct DCArgs DCArgs;

DC_API DCbool      dcbArgBool     (DCArgs*);
DC_API DCchar      dcbArgChar     (DCArgs*);
DC_API DCshort     dcbArgShort    (DCArgs*);
DC_API DCint       dcbArgInt      (DCArgs*);
DC_API DClong      dcbArgLong     (DCArgs*);
DC_API DClonglong  dcbArgLongLong (DCArgs*);
DC_API DCuchar     dcbArgUChar    (DCArgs*);
DC_API DCushort    dcbArgUShort   (DCArgs*);
DC_API DCuint      dcbArgUInt     (DCArgs*);
DC_API DCulong     dcbArgULong    (DCArgs*);
DC_API DCulonglong dcbArgULongLong(DCArgs*);
DC_API DCfloat     dcbArgFloat    (DCArgs*);
DC_API DCdouble    dcbArgDouble   (DCArgs*);
DC_API DCpointer   dcbArgPointer  (DCArgs*);

#ifdef __cplusplus
}
#endif

#endif /* DYNCALL_ARGS_H */
