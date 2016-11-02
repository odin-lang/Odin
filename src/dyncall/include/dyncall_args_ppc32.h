/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args_ppc32.h
 Description: Callback's Arguments VM - Header for ppc32
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

#ifndef DYNCALLBACK_ARGS_PPC32_H
#define DYNCALLBACK_ARGS_PPC32_H

#include "dyncall_args.h"

/* Common Args iterator for Apple and System V ABI. */

struct DCArgs
{
  int            ireg_data[8];		/* offset: 0   size: 4*8 = 32  */
  double         freg_data[13];		/* offset: 32  size: 8*13= 104 */	
  unsigned char* stackptr;		/* offset: 136 size:       4   */
  int            ireg_count;            /* offset: 140 size:       4   */
  int            freg_count;            /* offset: 144 size:       4   */
};                                      /*       total size:       148 */

#endif /* DYNCALLBACK_ARGS_PPC32_H */

