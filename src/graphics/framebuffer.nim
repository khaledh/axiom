import std/strformat

import ../kernel/debug
import ../kernel/devices/bga

type
  Framebuffer* = object
    buffer0: ptr UncheckedArray[uint32]
    buffer1: ptr UncheckedArray[uint32]
    backBuffer: ptr UncheckedArray[uint32]
    width*: uint32
    height*: uint32
    pitch: uint32

proc clear*(fb: Framebuffer, color: uint32 = 0) =
  for i in 0 ..< fb.height:
    for j in 0 ..< fb.width:
      fb.backBuffer[i * fb.pitch + j] = color

proc swapBuffers*(fb: var Framebuffer) =
  if fb.backBuffer == fb.buffer0:
    bgaSetYOffset(0)
    fb.backBuffer = fb.buffer1
    copyMem(fb.buffer1, fb.buffer0, fb.width*fb.height*4)
  else:
    bgaSetYOffset(fb.height.uint16)
    fb.backBuffer = fb.buffer0
    copyMem(fb.buffer0, fb.buffer1, fb.width*fb.height*4)

proc putPixel*(fb: Framebuffer, x, y: uint32, color: uint32) {.inline.} =
  # debugln(&"[fb] putPixel: x=", $x, ", y=", $y, ", color=", $color)
  fb.backBuffer[y * fb.pitch + x] = color

proc rect*(fb: Framebuffer, x, y, width, height, color: uint32) =
  for y in y ..< min(y + height, fb.height):
    fb.backBuffer[y * fb.pitch + x] = color
    fb.backBuffer[y * fb.pitch + (x + width - 1)] = color

  for x in x ..< min(x + width, fb.width):
    fb.backBuffer[y * fb.pitch + x] = color
    fb.backBuffer[(y + height - 1) * fb.pitch + x] = color

proc fillrect*(fb: Framebuffer, x, y, width, height, color: uint32) =
  for j in y ..< min(y + height, fb.height):
    for i in x ..< min(x + width, fb.width):
      fb.backBuffer[j * fb.pitch + i] = color

proc scrollVertical*(fb: Framebuffer, left, top, width, height, amount: uint32, color: uint32) =
  for y in top ..< top + height - amount:
    copyMem(addr fb.backBuffer[y * fb.pitch + left], addr fb.backBuffer[(y + amount) * fb.pitch + left], width*4)

  for y in top + height - amount ..< top + height:
    for x in left ..< left + width:
      fb.backBuffer[y * fb.pitch + x] = color

proc copyBuffer*(fb: Framebuffer, buff: ptr UncheckedArray[uint32], buffStart: int) =
  let startOffset = buffStart.uint32 * fb.width
  let endOffset = (fb.height - buffStart.uint32) * fb.width

  copyMem(fb.backBuffer, addr buff[startOffset], endOffset*4)
  copyMem(addr fb.backBuffer[endOffset], buff, startOffset*4)

proc init*(address: uint64, width, height: uint32, pitch: uint32 = 0): Framebuffer =
  debugln(&"[framebuffer] Initializing framebuffer at {address:0>16x}h, {width=}, {height=}, {pitch=}")
  result = Framebuffer(
    buffer0: cast[ptr UncheckedArray[uint32]](address),
    buffer1: cast[ptr UncheckedArray[uint32]](address + width*height*4),
    width: width,
    height: height,
    pitch: if pitch == 0: width else: pitch
  )
  result.backBuffer = result.buffer0
  result.clear()
  result.backBuffer = result.buffer1
