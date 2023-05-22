import std/bitops
import std/strformat

import ../graphics/font as fnt
import ../graphics/framebuffer
import ../kernel/debug
import ../kernel/thread

type
  Color* = enum
    Black          = 0x000000'u32
    DarkGrey       = 0x222629'u32
    DarkerGreyBlue = 0x252d35'u32
    DarkGreyBlue   = 0x353d45'u32
    Blueish        = 0x4a8e97'u32
    Blue           = 0x608aaf'u32
    DarkRed        = 0x8b0000'u32
    Green          = 0x8ebb8a'u32
    LightBlue      = 0x90badf'u32
    DarkOrange     = 0xc46c00'u32
    LighterBlue    = 0xd4ebf2'u32
    Orange         = 0xf57956'u32
    Red            = 0xff0000'u32
    Yellow         = 0xffff00'u32
    White          = 0xffffff'u32
  Buffer = ref array[1024*1280, uint32]

var
  fb: Framebuffer
  renderCallbacks: seq[proc(): void]
  font: Font

proc registerRenderCallback*(callback: proc(): void) =
  renderCallbacks.add(callback)

proc start*() {.cdecl.} =
  while true:
    for cb in renderCallbacks:
      cb()
    fb.swapBuffers()
    sleep(10)

proc init*(framebuffer: Framebuffer) =
  debugln("[gfx] Initializing graphics")
  fb = framebuffer
  font = loadFont()

proc maxWidth*(): uint32 {.inline.} =
  result = fb.width

proc maxHeight*(): uint32 {.inline.} =
  result = fb.height

proc rect*(x, y, width, height: uint32, color: Color|uint32) =
  fb.rect(x, y, width, height, color.uint32)

proc fillrect*(x, y, width, height: uint32, color: Color|uint32) =
  fb.fillrect(x, y, width, height, color.uint32)

proc putPixelRel*(left, top, x, y: uint32, color: Color|uint32) {.inline.} =
  # debugln("[gfx] putPixelRel: left=", $left, ", top=", $top, ", x=", $x, ", y=", $y, ", color=", $color.uint32)
  fb.putPixel(left + x, top + y, color.uint32)

proc scrollUp*(left, top, width, height, amount: uint32, color: Color|uint32) =
  fb.scrollVertical(left, top, width, height, amount, color)

proc putChar*(x, y: uint32, ch: char, bgColor: Color|uint32, fgColor: Color|uint32) {.inline.} =
  let glyph = font.glyphs[ch.uint8]
  for yoff, rowBits in glyph:
    for xoff in 1..8:
      let clr = if (rotateLeftBits(rowBits, xoff) and 1) == 1: fgColor else: bgColor
      fb.putPixel(x + xoff.uint32, y + yoff.uint32, clr.uint32)

proc putText*(x, y: uint32, text: string, bgColor: Color|uint32, fgColor: Color|uint32) =
  var xstart = x
  for ch in text:
    putChar(xstart, y, ch, bgColor, fgColor)
    inc xstart, font.width.uint32

proc moveRect*(left, top, width, height, dx, dy: uint32, bgColor: Color|uint32) =
  fb.moveRect(left, top, width, height, dx, dy, bgColor.uint32)
