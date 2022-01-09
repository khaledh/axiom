type
  Framebuffer* = object
    buffer0: ptr UncheckedArray[uint32]
    buffer1: ptr UncheckedArray[uint32]
    currentBuffer: ptr UncheckedArray[uint32]
    width: uint32
    height: uint32
    pitch: uint32

proc initFramebuffer*(address: uint64, width, height: uint32, pitch: uint32 = 0): Framebuffer =
    var fb = Framebuffer(
        buffer0: cast[ptr UncheckedArray[uint32]](address),
        buffer1: cast[ptr UncheckedArray[uint32]](address + width*height*4),
        width: width,
        height: height,
        pitch: if pitch == 0: width else: pitch
    )
    fb.currentBuffer = fb.buffer0
    result = fb

proc swapBuffers*(fb: var Framebuffer) =
    if fb.currentBuffer == fb.buffer0:
      fb.currentBuffer = fb.buffer1
    else:
      fb.currentBuffer = fb.buffer0

proc clear*(fb: Framebuffer, color: uint32 = 0) =
  for i in 0 ..< (fb.width * fb.pitch):
    fb.currentBuffer[i] = color

# proc bltVideoToVideo*(fb: Framebuffer, srcX, srcY, dstX, dstY, width, height: int) =
#   var fromX, fromY, toX, toY, stepX, stepY: int
#   if srcX < dstX:
#     fromX = srcX + width
#     toX = dstX + width
#     stepX = -1
#   else:
#     fromX = srcX
#     toX = dstX
#     stepX = 1
  
#   if srcY < dstY:
#     fromY = srcY + height
#     toY = dstY + height
#     stepY = -1
#   else:
#     fromY = srcY
#     toY = dstY
#     stepY = 1

#   var sx = fromX
#   var sy = fromY
#   var dx = toX
#   var dy = toY
#   for i in 0 ..< height:
#     for j in 0 ..< width:
#       fb.currentBuffer[dy*fb.pitch.int + dx] = fb.currentBuffer[sy*fb.pitch.int + sx]
#       inc(sx, stepX)
#       inc(dx, stepX)
#     sx = fromX
#     dx = toX
#     inc(sy, stepY)
#     inc(dy, stepY)

proc copyBuffer*(fb: Framebuffer, buff: ptr UncheckedArray[uint32], buffStart: int) =
  let startOffset = buffStart.uint32 * fb.width
  let endOffset = (fb.height - buffStart.uint32) * fb.width

  copyMem(fb.currentBuffer, addr buff[startOffset], endOffset*4)
  copyMem(addr fb.currentBuffer[endOffset], buff, startOffset*4)
