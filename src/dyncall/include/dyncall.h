/*

 Package: dyncall
 Library: dyncall
 File: dyncall/dyncall.h
 Description: public header for library dyncall
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

  dyncall C API

  REVISION
  2015/07/08 added SYS_PPC64 system call
  2015/01/16 added SYS_PPC32 system call
  2007/12/11 initial
  
*/

#ifndef DYNCALL_H
#define DYNCALL_H

#include "dyncall_types.h"

#ifdef __cplusplus
extern "C" {
#endif 

typedef struct DCCallVM_    DCCallVM;
typedef struct DCstruct_    DCstruct;

/* Supported Calling Convention Modes */

#define DC_CALL_C_DEFAULT               0
#define DC_CALL_C_ELLIPSIS            100
#define DC_CALL_C_ELLIPSIS_VARARGS    101
#define DC_CALL_C_X86_CDECL             1
#define DC_CALL_C_X86_WIN32_STD         2
#define DC_CALL_C_X86_WIN32_FAST_MS     3
#define DC_CALL_C_X86_WIN32_FAST_GNU    4
#define DC_CALL_C_X86_WIN32_THIS_MS     5
#define DC_CALL_C_X86_WIN32_THIS_GNU    6
#define DC_CALL_C_X64_WIN64             7
#define DC_CALL_C_X64_SYSV              8
#define DC_CALL_C_PPC32_DARWIN          9
#define DC_CALL_C_PPC32_OSX            DC_CALL_C_PPC32_DARWIN /* alias */
#define DC_CALL_C_ARM_ARM_EABI         10
#define DC_CALL_C_ARM_THUMB_EABI       11
#define DC_CALL_C_ARM_ARMHF            30
#define DC_CALL_C_MIPS32_EABI          12
#define DC_CALL_C_MIPS32_PSPSDK        DC_CALL_C_MIPS32_EABI /* alias - deprecated. */
#define DC_CALL_C_PPC32_SYSV           13
#define DC_CALL_C_PPC32_LINUX          DC_CALL_C_PPC32_SYSV /* alias */
#define DC_CALL_C_ARM_ARM              14
#define DC_CALL_C_ARM_THUMB            15
#define DC_CALL_C_MIPS32_O32           16
#define DC_CALL_C_MIPS64_N32           17
#define DC_CALL_C_MIPS64_N64           18
#define DC_CALL_C_X86_PLAN9            19
#define DC_CALL_C_SPARC32              20
#define DC_CALL_C_SPARC64              21
#define DC_CALL_C_ARM64                22
#define DC_CALL_C_PPC64                23
#define DC_CALL_C_PPC64_LINUX          DC_CALL_C_PPC64 /* alias */
#define DC_CALL_SYS_DEFAULT           200
#define DC_CALL_SYS_X86_INT80H_LINUX  201
#define DC_CALL_SYS_X86_INT80H_BSD    202
#define DC_CALL_SYS_PPC32             210
#define DC_CALL_SYS_PPC64             211

/* Error codes. */

#define DC_ERROR_NONE                0
#define DC_ERROR_UNSUPPORTED_MODE   -1

DC_API DCCallVM*  dcNewCallVM     (DCsize size);
DC_API void       dcFree          (DCCallVM* vm);
DC_API void       dcReset         (DCCallVM* vm);

DC_API void       dcMode          (DCCallVM* vm, DCint mode);

DC_API void       dcArgBool       (DCCallVM* vm, DCbool     value);
DC_API void       dcArgChar       (DCCallVM* vm, DCchar     value);
DC_API void       dcArgShort      (DCCallVM* vm, DCshort    value);
DC_API void       dcArgInt        (DCCallVM* vm, DCint      value);
DC_API void       dcArgLong       (DCCallVM* vm, DClong     value);
DC_API void       dcArgLongLong   (DCCallVM* vm, DClonglong value);
DC_API void       dcArgFloat      (DCCallVM* vm, DCfloat    value);
DC_API void       dcArgDouble     (DCCallVM* vm, DCdouble   value);
DC_API void       dcArgPointer    (DCCallVM* vm, DCpointer  value);
DC_API void       dcArgStruct     (DCCallVM* vm, DCstruct* s, DCpointer value);

DC_API void       dcCallVoid      (DCCallVM* vm, DCpointer funcptr);
DC_API DCbool     dcCallBool      (DCCallVM* vm, DCpointer funcptr);
DC_API DCchar     dcCallChar      (DCCallVM* vm, DCpointer funcptr);
DC_API DCshort    dcCallShort     (DCCallVM* vm, DCpointer funcptr);
DC_API DCint      dcCallInt       (DCCallVM* vm, DCpointer funcptr);
DC_API DClong     dcCallLong      (DCCallVM* vm, DCpointer funcptr);
DC_API DClonglong dcCallLongLong  (DCCallVM* vm, DCpointer funcptr);
DC_API DCfloat    dcCallFloat     (DCCallVM* vm, DCpointer funcptr);
DC_API DCdouble   dcCallDouble    (DCCallVM* vm, DCpointer funcptr);
DC_API DCpointer  dcCallPointer   (DCCallVM* vm, DCpointer funcptr);
DC_API void       dcCallStruct    (DCCallVM* vm, DCpointer funcptr, DCstruct* s, DCpointer returnValue);

DC_API DCint      dcGetError      (DCCallVM* vm);

#define DEFAULT_ALIGNMENT 0
DC_API DCstruct*  dcNewStruct      (DCsize fieldCount, DCint alignment);
DC_API void       dcStructField    (DCstruct* s, DCint type, DCint alignment, DCsize arrayLength);
DC_API void       dcSubStruct      (DCstruct* s, DCsize fieldCount, DCint alignment, DCsize arrayLength);  	
/* Each dcNewStruct or dcSubStruct call must be paired with a dcCloseStruct. */
DC_API void       dcCloseStruct    (DCstruct* s);  	
DC_API DCsize     dcStructSize     (DCstruct* s);  	
DC_API DCsize     dcStructAlignment(DCstruct* s);  	
DC_API void       dcFreeStruct     (DCstruct* s);

DC_API DCstruct*  dcDefineStruct  (const char* signature);


#ifdef __cplusplus
}
#endif

#endif /* DYNCALL_H */

