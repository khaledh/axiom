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

proc initConsole*(fb: Framebuffer, left, top: int, font: Font16, maxCols, maxRows: int, currCol, currRow: int = 0): Console =
  Console(fb: fb, left: left, top: top, font: font, maxCols: maxCols, maxRows: maxRows, currCol: currCol, currRow: currRow)

proc scrollUp(con: var Console) =
  con.fb.bltVideoToVideo(con.left, con.top + con.font.height, con.left, con.top, con.maxCols*con.font.width, con.maxRows*con.font.height)
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
          con.fb[xpos + xoff - 1, ypos + yoff] = color

    inc(con.currCol)
    if con.currCol >= con.maxCols:
      con.currCol = 0
      inc(con.currRow)

      if con.currRow >= con.maxRows:
        scrollUp(con)
