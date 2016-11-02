/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_thunk_ppc64.h
 Description: Thunk - Header for ppc64
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

#ifndef DYNCALL_THUNK_PPC64_H
#define DYNCALL_THUNK_PPC64_H

#if DC__ABI_PPC64_ELF_V != 2
struct DCThunk_              /* v1 */
{
  void          (*thunk_entry)();                 /* offset:  0 */
  long           toc_thunk;                       /* offset:  8 */
  unsigned short code_load_hi, addr_self_hi;      /* offset: 16 */
  unsigned short code_load_lo, addr_self_lo;      /* offset: 20 */
  unsigned int   code_jump[6];                    /* offset: 24 */
  void          (*addr_entry)();                  /* offset: 48 */
  long           toc_entry;                       /* offset: 56 */
};
#define DCTHUNK_SIZE_PPC64 64
#else
struct DCThunk_              /* v2 */
{
  unsigned short addr_self_hist, code_load_hist;  /* offset:  0 */
  unsigned short addr_self_hier, code_load_hier;  /* offset:  4 */
  unsigned int   code_rot;                        /* offset:  8 */
  unsigned short addr_self_hi, code_load_hi;      /* offset: 12 */
  unsigned short addr_self_lo, code_load_lo;      /* offset: 16 */
  unsigned int   code_jump[5];                    /* offset: 20 */
  void          (*addr_entry)();                  /* offset: 40 */
};
#define DCTHUNK_SIZE_PPC64 48
#endif

#endif /* DYNCALL_THUNK_PPC64_H */

