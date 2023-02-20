import std/streams

type
  MemoryStream* = ref MemoryStreamObj
  MemoryStreamObj* = object of StreamObj
    data*: ptr UncheckedArray[byte]
    pos: int
    len: int


proc msAtEnd(s: Stream): bool =
  var s = MemoryStream(s)
  result = s.pos >= s.len

proc msSetPosition(s: Stream, pos: int) =
  var s = MemoryStream(s)
  s.pos = clamp(pos, 0, s.len)

proc msGetPosition(s: Stream): int =
  var s = MemoryStream(s)
  result = s.pos

proc msReadDataStr(s: Stream, buffer: var string, slice: Slice[int]): int =
  var s = MemoryStream(s)
  when declared(prepareMutation):
    prepareMutation(buffer) # buffer might potentially be a CoW literal with ARC
  result = min(slice.b + 1 - slice.a, s.len - s.pos)
  if result > 0:
    copyMem(addr buffer[slice.a], addr s.data[s.pos], result)
    inc(s.pos, result)
  else:
    result = 0

proc msReadData(s: Stream, buffer: pointer, bufLen: int): int =
  var s = MemoryStream(s)
  result = min(bufLen, s.len - s.pos)
  if result > 0:
    copyMem(buffer, addr(s.data[s.pos]), result)
    inc(s.pos, result)
  else:
    result = 0

proc msPeekData(s: Stream, buffer: pointer, bufLen: int): int =
  var s = MemoryStream(s)
  result = min(bufLen, s.len - s.pos)
  if result > 0:
    copyMem(buffer, addr(s.data[s.pos]), result)
  else:
    result = 0

# proc msWriteData(s: Stream, buffer: pointer, bufLen: int) =
#   var s = MemoryStream(s)
#   if bufLen <= 0:
#     return
#   if s.pos + bufLen > s.len:
#     setLen(s.data, s.pos + bufLen)
#   copyMem(addr(s.data[s.pos]), buffer, bufLen)
#   inc(s.pos, bufLen)

proc msClose(s: Stream) =
  var s = MemoryStream(s)
  s.data = nil

proc newMemoryStream*(p: sink ptr UncheckedArray[byte], len: int): owned MemoryStream =
  ## Creates a new stream from the memory pointed to by `p`.
  new(result)
  result.data = p
  result.pos = 0
  result.len = len

  result.closeImpl = msClose
  result.atEndImpl = msAtEnd
  result.setPositionImpl = msSetPosition
  result.getPositionImpl = msGetPosition
  result.readDataStrImpl = msReadDataStr
  result.readDataImpl = msReadData
  result.peekDataImpl = msPeekData
  # result.writeDataImpl = msWriteData
