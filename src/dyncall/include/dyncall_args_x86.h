/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args_x86.h
 Description: Callback's Arguments VM - Header for x86
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



#ifndef DYNCALL_ARGS_X86_H_
#define DYNCALL_ARGS_X86_H_

#include "dyncall_args.h"

typedef struct
{
	DCint      (*i32)(DCArgs*);
	DClonglong (*i64)(DCArgs*);
	DCfloat    (*f32)(DCArgs*);
	DCdouble   (*f64)(DCArgs*);
} DCArgsVT;

extern DCArgsVT dcArgsVT_default;
extern DCArgsVT dcArgsVT_this_ms;
extern DCArgsVT dcArgsVT_fast_ms;
extern DCArgsVT dcArgsVT_fast_gnu;

struct DCArgs
{
	/* callmode */
	DCArgsVT* vt;

	/* state */
	int* stack_ptr;

	/* fast data / 'this-ptr' info */
	int  fast_data[2];
	int  fast_count;
};

#endif /* DYNCALL_ARGS_X86_H_ */
