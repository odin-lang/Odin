/*

 Package: dyncall
 Library: dynload
 File: dynload/dynload.h
 Description: public header for library dynload
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



#ifndef DYNLOAD_H
#define DYNLOAD_H

#ifdef __cplusplus
extern "C" {
#endif

#ifndef DL_API
#define DL_API
#endif

/* --- public api ---------------------------------------------------------- */

/* shared library loading and explicit symbol resolving */

typedef struct DLLib_ DLLib;

DL_API DLLib* dlLoadLibrary(const char* libpath);
DL_API void   dlFreeLibrary(DLLib* pLib);
DL_API void*  dlFindSymbol(DLLib* pLib, const char* pSymbolName);

/* symbol table enumeration - only for symbol lookup, not resolve */

typedef struct DLSyms_ DLSyms;

DL_API DLSyms*     dlSymsInit   (const char* libPath);
DL_API void        dlSymsCleanup(DLSyms* pSyms);

DL_API int         dlSymsCount        (DLSyms* pSyms);
DL_API const char* dlSymsName         (DLSyms* pSyms, int index);
DL_API const char* dlSymsNameFromValue(DLSyms* pSyms, void* value); /* symbol must be loaded */


#ifdef __cplusplus
}
#endif

#endif /* DYNLOAD_H */

