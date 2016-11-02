/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args_x64.h
 Description: Callback's Arguments VM - Header for x64
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


#ifndef DYNCALLBACK_ARGS_X64_H
#define DYNCALLBACK_ARGS_X64_H

#include "dyncall_args.h"
#include "dyncall_callvm_x64.h"  /* reuse structures */


struct DCArgs
{
	/* state */
	int64*          stack_ptr;
	DCRegCount_x64  reg_count;	/* @@@ win64 version should maybe force alignment to 8 in order to be secure */

	/* reg data */
	DCRegData_x64_s reg_data;
};

#endif /* DYNCALLBACK_ARGS_X64_H */

