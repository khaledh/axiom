import bitops
import std/strformat

import ../../graphics/font
import ../../graphics/framebuffer


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
    font: Font
    maxCols: int
    maxRows: int
    currCol: int
    currRow: int
    backColor: uint32
    # tick: uint64

var
  conOut*: Console
  # circular buffer
  backbuffer {.align(16).}: array[1024*1280, uint32]
  backbufferStart: int


proc init*(fb: Framebuffer, left, top: int, font: Font, maxCols, maxRows: int, currCol, currRow: int = 0, color: uint32 = 0) =
  backbufferStart = 0
  for i in 0 ..< 1024*1280:
      backbuffer[i] = color
  conOut = Console(fb: fb, left: left, top: top, font: font, maxCols: maxCols, maxRows: maxRows, currCol: currCol, currRow: currRow, backColor: color)

proc flush*(con: Console) =
  con.fb.copyBuffer(cast [ptr UncheckedArray[uint32]](addr backbuffer), backbufferStart)

proc flush*() =
  flush(conOut)

proc scrollUp(con: var Console) =
  # move pointer down in the circular buffer to indicate the new start line
  backbufferStart = (backbufferStart + 16) mod 1024

  # clear the last line
  var start = ((backbufferStart + 1024) mod 1024) * 1280
  for i in start ..< start + 16*1280:
      backbuffer[i] = con.backColor

  dec(con.currRow)
  # flush(con)

proc putCharAt*(con: Console, ch: char, row, col: int, color: uint32 = DefaultForeground) =
  var xpos = con.left + col * con.font.width
  var ypos = con.top + row * con.font.height

  # bitblt the glyph
  let glyph = con.font.glyphs[ch.uint8]
  for yoff, row in glyph:
    for xoff in 1..8:
      let clr = if (rotateLeftBits(row, xoff) and 1) == 1: color else: con.backColor
      backbuffer[(((backbufferStart + ypos + yoff) mod 1024) * 1280) + xpos + xoff - 1] = clr

  # flush(con)

proc putCharAt*(ch: char, row, col: int, color: uint32 = DefaultForeground) =
  conOut.putCharAt(ch, row, col, color)

proc putChar*(con: Console, ch: char, color: uint32 = DefaultForeground) =
  putCharAt(con, ch, con.currRow, con.currCol, color)

proc putChar*(ch: char, color: uint32 = DefaultForeground) =
  putCharAt(conOut, ch, conOut.currRow, conOut.currCol, color)

proc newLine(con: var Console) =
  con.currCol = 0
  inc(con.currRow)
  if con.currRow >= con.maxRows:
    con.scrollUp()

  # flush(con)

proc write*(con: var Console, str: string, color: uint32 = DefaultForeground) =
  for i, ch in str:
    if ch == '\n':
      # clear cursor
      con.putChar(' ')
      con.newLine()
    elif ch == '\b':
      if con.currCol > 0:
        con.putChar(' ')
        dec(con.currCol)
        con.putChar(' ')
    else:
      putChar(con, ch, color)
      inc(con.currCol)
      if con.currCol >= con.maxCols:
        con.newLine()

  # cursor
  con.putChar('_')

proc write*(str: string, color: uint32 = DefaultForeground) =
  write(conOut, str, color)

proc writeln*(con: var Console, str: string, color: uint32 = DefaultForeground) =
  write(con, str & "\n", color)
  # flush(con)

proc writeln*(str: string, color: uint32 = DefaultForeground) =
  writeln(conOut, str, color)



proc showFont*() =
  writeln("")
  writeln(&"PSF Font: Dina 8x16")
  writeln(&"  Magic    = {dina8x16[0]:0>2x} {dina8x16[1]:0>2x} {dina8x16[2]:0>2x} {dina8x16[3]:0>2x}")
  writeln(&"  Version  = {cast[ptr uint32](addr dina8x16[4])[]}")
  writeln(&"  HdrSize  = {cast[ptr uint32](addr dina8x16[8])[]}")
  writeln(&"  Flags    = {cast[ptr uint32](addr dina8x16[12])[]}")
  writeln(&"  Length   = {cast[ptr uint32](addr dina8x16[16])[]}")
  writeln(&"  CharSize = {cast[ptr uint32](addr dina8x16[20])[]}")
  writeln(&"  Height   = {cast[ptr uint32](addr dina8x16[24])[]}")
  writeln(&"  Width    = {cast[ptr uint32](addr dina8x16[28])[]}")
