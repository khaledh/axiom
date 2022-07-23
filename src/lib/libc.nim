import std/strformat

import ../cpu
import ../debug

{.compile: "libc.c".}
{.used.}

proc memset*(p: pointer, value: cint, size: csize_t): pointer {.exportc.} =
  let pp = cast[ptr UncheckedArray[byte]](p)
  let v = cast[byte](value)
  for i in 0..<size:
    pp[i] = v
  return p

proc memcpy*(dst: pointer, src: pointer, size: csize_t): pointer
    {.exportc, codegenDecl: "$# $#(void * restrict dst,  const void * restrict src,  size_t size)".} =
  # copy 8 bytes at a time
  let d = cast[ptr UncheckedArray[uint64]](dst)
  let s = cast[ptr UncheckedArray[uint64]](src)
  for i in 0 ..< (size.int div sizeof(uint64)):
    d[i] = s[i]

  # copy remaining bytes, if any
  let rem = size and (sizeof(uint64) - 1)
  if rem > 0:
    let d = cast[ptr UncheckedArray[byte]](dst)
    let s = cast[ptr UncheckedArray[byte]](src)
    for i in (size - rem) ..< size:
      d[i] = s[i]

  return dst

proc memcmp*(lhs: pointer, rhs: pointer, count: csize_t): cint
    {.exportc, codegenDecl: "$# $#(const void* lhs, const void* rhs, size_t count)".} =
  let l = cast[ptr UncheckedArray[byte]](lhs)
  let r = cast[ptr UncheckedArray[byte]](rhs)
  for i in 0..<count:
    if l[i] != r[i]:
      return cint(l[i] - r[i])
  return 0

proc strlen*(str: cstring): cint {.exportc.} =
  let s = cast[ptr UncheckedArray[byte]](str)
  var len = 0
  while s[len] != 0:
    inc(len)
  result = len.cint

proc strstr*(str: cstring, substr: cstring): cstring
    {.exportc, codegenDecl: "$# $#(const char* str, const char* substr)".} =
  let s = cast[ptr UncheckedArray[byte]](str)
  let ss = cast[ptr UncheckedArray[byte]](substr)
  var i = 0
  while s[i] != 0:
    var j = 0
    while ss[j] != 0 and s[i + j] != 0 and ss[j] == s[i + j]:
      inc(j)
    if ss[j] == 0:
      return cast[cstring](addr s[i])
    inc(i)
  return nil

proc exit*(code: cint) {.exportc.} =
  halt()

type
  CFile {.importc: "FILE", header: "<stdio.h>", incompleteStruct.} = object
  CFilePtr* = ptr CFile ## The type representing a file handle.

proc fwrite*(buf: pointer, size, n: csize_t, f: CFilePtr): csize_t 
    {.exportc, codegenDecl: "$# $#(const void * restrict buf,  size_t size,  size_t n,  FILE * restrict f)".} =
  let p = cast[ptr UncheckedArray[char]](buf)
  for i in 0..(n*size):
    print(&"{p[i]}")

proc fflush*(f: CFilePtr): cint {.exportc.} =
  discard
