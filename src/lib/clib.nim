import ../cpu

{.compile: "libc.c".}

proc memset*(p: pointer, value: cint, size: csize_t): pointer {.exportc.} =
  let pp = cast[ptr UncheckedArray[byte]](p)
  let v = cast[byte](value)
  for i in 0..<size:
    pp[i] = v
  return p

# proc memcpy*(dst: pointer, src: pointer, size: csize_t): pointer {.exportc, codegenDecl: "$# $#(void * restrict dst,  const void * restrict src,  size_t size)".} =
#   let d = cast[ptr UncheckedArray[byte]](dst)
#   let s = cast[ptr UncheckedArray[byte]](src)
#   for i in 0..<size:
#     d[i] = s[i]
#   return dst

proc memcmp*(lhs: pointer, rhs: pointer, count: csize_t): cint {.exportc, codegenDecl: "$# $#(const void* lhs, const void* rhs, size_t count)".} =
  let l = cast[ptr UncheckedArray[byte]](lhs)
  let r = cast[ptr UncheckedArray[byte]](rhs)
  for i in 0..<count:
    if l[i] != r[i]:
      return cint(l[i] - r[i])
  return 0

proc strstr*(str: cstring, substr: cstring): cstring {.exportc, codegenDecl: "$# $#(const char* str, const char* substr)".} =
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


###########################################
# misc libc stuff that may be needed

# type
#   CFile {.importc: "FILE", header: "<stdio.h>", incompleteStruct.} = object
#   CFilePtr* = ptr CFile ## The type representing a file handle.

# proc fwrite*(buf: pointer, size, n: csize_t, f: CFilePtr): csize_t 
#   {.exportc, codegenDecl: "$# $#(const void * restrict,  size_t,  size_t,  FILE * restrict)".} = 0
# proc fflush*(f: CFilePtr): cint {.exportc.} = 0
