/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_thunk_ppc32.h
 Description: Thunk - Header for ppc32 (darwin/sysv)
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

#ifndef DYNCALL_THUNK_PPC32_H
#define DYNCALL_THUNK_PPC32_H

struct DCThunk_
{
  unsigned short code_load_hi, addr_self_hi;  /* offset:  0  size: 4  */
  unsigned short code_load_lo, addr_self_lo;  /* offset:  4  size: 4  */
  unsigned int   code_jump[3];                /* offset:  8  size: 12 */
  void          (*addr_entry)();              /* offset: 20  size:  4 */
};                                            /*       total size: 24 */

#define DCTHUNK_SIZE_PPC32 24

#endif /* DYNCALL_THUNK_PPC32_H */

