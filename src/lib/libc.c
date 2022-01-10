
// This file was copied from:
//   https://github.com/mirror/mingw-w64/blob/master/mingw-w64-crt/stdio/acrt_iob_func.c
// It was modified to return NULL from the only function in the file.
// 
// It's required so that Nim is able to access stderr for writing errors/exceptions.
// We provide our own fwrite which ignores the passed in FILE*, so it doesn't matter
// if stderr is NULL.

/**
 * This file has no copyright assigned and is placed in the Public Domain.
 * This file is part of the mingw-w64 runtime package.
 * No warranty is given; refer to the file DISCLAIMER.PD within this package.
 */

#include <stdio.h>

FILE *__cdecl __acrt_iob_func(unsigned index)
{
    return NULL;
}

typedef FILE *__cdecl (*_f__acrt_iob_func)(unsigned index);
_f__acrt_iob_func __MINGW_IMP_SYMBOL(__acrt_iob_func) = __acrt_iob_func;
