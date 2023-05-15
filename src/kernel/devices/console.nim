import bitops
import std/strformat

import ../queues
import ../thread
import ../timer
import ../../kernel/debug
import ../../graphics/font
import ../../graphics/framebuffer
import keyboard


const
  DefaultBackground* = 0x26486B'u32
  DefaultForeground* = 0xd4dae7'u32
  DarkGrey* = 0x222629'u32
  DarkGreyBlue* = 0x353d45'u32
  DarkerGreyBlue* = 0x252d35'u32
  Orange* = 0xf57956'u32
  DarkOrange* = 0xc46c00'u32
  Green* = 0x8ebb8a'u32
  LightBlue* = 0x90badf'u32
  LighterBlue* = 0xd4ebf2'u32
  Blue* = 0x608aaf'u32
  Blueish* = 0x4a8e97'u32
  White* = 0xffffff'u32
  Black* = 0x000000'u32

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
    bgColor: uint32
    fgColor: uint32

var
  conOut*: Console
  # circular buffer
  backbuffer {.align(16).}: array[1024*1280, uint32]
  backbufferStart: int

proc onTimer() {.cdecl.}

proc init*(fb: Framebuffer, left, top: int, font: Font, maxCols, maxRows: int,
           currCol = 0, currRow = 0, fgColor = DefaultForeground, bgColor = DefaultBackground) =
  backbufferStart = 0
  for i in 0 ..< 1024*1280:
      backbuffer[i] = bgColor
  conOut = Console(fb: fb, left: left, top: top, font: font, maxCols: maxCols, maxRows: maxRows,
                   currCol: currCol, currRow: currRow, bgColor: bgColor, fgColor: fgColor)
  timer.registerTimerCallback(onTimer)

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
      backbuffer[i] = con.bgColor

  dec(con.currRow)
  # flush(con)

proc putCharAt*(con: Console, ch: char, row, col: int, fgColor = con.fgColor, bgColor = con.bgColor) =
  var xpos = con.left + col * con.font.width
  var ypos = con.top + row * con.font.height

  # bitblt the glyph
  let glyph = con.font.glyphs[ch.uint8]
  for yoff, row in glyph:
    for xoff in 1..8:
      let clr = if (rotateLeftBits(row, xoff) and 1) == 1: fgColor else: bgColor
      backbuffer[(((backbufferStart + ypos + yoff) mod 1024) * 1280) + xpos + xoff - 1] = clr

  # flush(con)

proc putCharAt*(ch: char, row, col: int, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  conOut.putCharAt(ch, row, col, fgColor, bgColor)

proc putChar*(con: Console, ch: char, fgColor = con.fgColor, bgColor = con.bgColor) =
  putCharAt(con, ch, con.currRow, con.currCol, fgColor, bgColor)

proc putChar*(ch: char, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  putCharAt(conOut, ch, conOut.currRow, conOut.currCol, fgColor, bgColor)

proc newLine(con: var Console) =
  con.currCol = 0
  inc(con.currRow)
  if con.currRow >= con.maxRows:
    con.scrollUp()

  # flush(con)

proc putTextAt*(con: var Console, str: string, row, col: int, fgColor = con.fgColor, bgColor = con.bgColor) =
  for i, ch in str:
    putCharAt(con, ch, row, col + i, fgColor, bgColor)

proc putTextAt*(str: string, row, col: int, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  for i, ch in str:
    putCharAt(conOut, ch, row, col + i, fgColor, bgColor)

proc write*(con: var Console, str: string, fgColor = con.fgColor, bgColor = con.bgColor) =
  for i, ch in str:
    if ch == '\n':
      # clear cursor
      con.putChar(' ', fgColor, bgColor)
      con.newLine()
    elif ch == '\b':
      if con.currCol > 0:
        con.putChar(' ', fgColor, bgColor)
        dec(con.currCol)
        con.putChar(' ', fgColor, bgColor)
    else:
      putChar(con, ch, fgColor, bgColor)
      inc(con.currCol)
      if con.currCol >= con.maxCols:
        con.newLine()

  # cursor
  con.putChar('_')

proc write*(str: string, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  write(conOut, str, fgColor, bgColor)

proc writeln*(con: var Console, str: string, fgColor = con.fgColor, bgColor = con.bgColor) =
  write(con, str & "\n", fgColor, bgColor)
  # flush(con)

proc writeln*(str: string, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  writeln(conOut, str, fgColor, bgColor)


proc onTimer() {.cdecl.} =
  if timerTicks mod 10 == 0:
    putTextAt(&"{getCurrentThread().name:>11}", 62, 145)
    flush()


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


const
  MaxPendingKeyEvents = 64

var
  keyEventQueue = newBlockingQueue[KeyEvent](MaxPendingKeyEvents)

proc keyEventHandler*(keyEvent: KeyEvent) =
  debugln("console: received keyEvent, enqueueing (no wait)")
  keyEventQueue.enqueueNoWait(keyEvent)

proc readKeyEvent*(): KeyEvent =
  debugln("console: reading keyEvent (wait)")
  result = keyEventQueue.dequeue
