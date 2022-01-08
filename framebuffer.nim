type
  Framebuffer* = object
    buffer: ptr UncheckedArray[uint32]
    width: uint32
    height: uint32
    pitch: uint32

proc initFramebuffer*(address: uint64, width, height: uint32, pitch: uint32 = 0): Framebuffer =
    Framebuffer(
        buffer: cast[ptr UncheckedArray[uint32]](address),
        width: width,
        height: height,
        pitch: if pitch == 0: width else: pitch
    )

proc `[]=`*(fb: Framebuffer, x, y: int, color: uint32) =
    if x < fb.width.int and y < fb.height.int:
        fb.buffer[y*fb.pitch.int + x] = color

proc clear*(fb: Framebuffer, color: uint32 = 0) =
  for i in 0 ..< (fb.width * fb.pitch):
    fb.buffer[i] = color

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
#       fb.buffer[dy*fb.pitch.int + dx] = fb.buffer[sy*fb.pitch.int + sx]
#       inc(sx, stepX)
#       inc(dx, stepX)
#     sx = fromX
#     dx = toX
#     inc(sy, stepY)
#     inc(dy, stepY)

proc copyBuffer*(fb: Framebuffer, buff: ptr UncheckedArray[uint32], buffStart: int) =
    let startOffset = buffStart.uint32 * fb.width
    let endOffset = (fb.height - buffStart.uint32) * fb.width

    copyMem(fb.buffer, addr buff[startOffset], endOffset*4)
    copyMem(addr fb.buffer[endOffset], buff, startOffset*4)