import bitops

import font
import framebuffer

const
  DefaultForeground* = 0xd4dae7
  DarkGrey* = 0x222629
  DarkGreyBlue* = 0x353d45
  DarkerGreyBlue* = 0x252d35
  Orange* = 0xf57956
  Green* = 0x8ebb8a
  LightBlue* = 0x90badf
  Blue* = 0x608aaf
  Blueish* = 0x4a8e97

# circular buffer
var backbuffer {.align(16).}: array[1024*1280, uint32]
var backbufferStart: int

type
  Console* = object
    fb: Framebuffer
    left: int
    top: int
    font: Font16
    maxCols: int
    maxRows: int
    currCol: int
    currRow: int
    backColor: uint32

proc initConsole*(fb: Framebuffer, left, top: int, font: Font16, maxCols, maxRows: int, currCol, currRow: int = 0, color: uint32 = 0): Console =
  backbufferStart = 0
  for i in 0 ..< 1024*1280:
      backbuffer[i] = color
  Console(fb: fb, left: left, top: top, font: font, maxCols: maxCols, maxRows: maxRows, currCol: currCol, currRow: currRow, backColor: color)

proc scrollUp(con: var Console) =
  # move pointer down in the circular buffer to indicate the new start line
  backbufferStart = (backbufferStart + 16) mod 1024

  # clear the last line
  var start = ((backbufferStart + 1024) mod 1024) * 1280
  for i in start ..< start + 16*1280:
      backbuffer[i] = con.backColor

  dec(con.currRow)

proc write*(con: var Console, str: string, color: uint32 = DefaultForeground) =
  for i, ch in str:
    if ch == '\n':
      con.currCol = 0
      inc(con.currRow)
      if con.currRow >= con.maxRows:
        scrollUp(con)
      continue

    var xpos = con.left + con.currCol * con.font.width
    var ypos = con.top + con.currRow * con.font.height

    let glyph = con.font.glyphs[ch.uint8]
    for yoff, row in glyph:
      for xoff in 1..8:
        if (rotateLeftBits(row, xoff) and 1) == 1:
          backbuffer[(((backbufferStart + ypos + yoff) mod 1024) * 1280) + xpos + xoff - 1] = color

    inc(con.currCol)
    if con.currCol >= con.maxCols:
      con.currCol = 0
      inc(con.currRow)

      if con.currRow >= con.maxRows:
        scrollUp(con)

  con.fb.copyBuffer(cast [ptr UncheckedArray[uint32]](addr backbuffer), backbufferStart)
