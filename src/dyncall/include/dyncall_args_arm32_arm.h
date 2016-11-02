/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args_arm32_arm.h
 Description: Callback's Arguments VM - Header for ARM32 (ARM mode)
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


#ifndef DYNCALLBACK_ARGS_ARM32_ARM_H
#define DYNCALLBACK_ARGS_ARM32_ARM_H

#include "dyncall_args.h"

struct DCArgs
{
	/* Don't change order! */
	long  reg_data[4];
	int   reg_count;
	long* stack_ptr;
#if defined(DC__ABI_ARM_HF)
	DCfloat f[16];
	int     freg_count;
	int     dreg_count;
#endif
};

#endif /* DYNCALLBACK_ARGS_ARM32_ARM_H */

