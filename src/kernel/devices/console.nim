import bitops
import std/strformat

import ../queues
import ../thread
import ../devices/rtc
import ../../gui/view
import ../../kernel/debug
import ../../graphics/font
import keyboard


const
  DefaultBackground* = 0x26486B'u32
  DefaultForeground* = 0xd4dae7'u32
  DarkGrey* = 0x222629'u32
  DarkGreyBlue* = 0x353d45'u32
  DarkerGreyBlue* = 0x252d35'u32
  Orange* = 0xf57956'u32
  DarkOrange* = 0xc46c00'u32
  Red* = 0xff0000'u32
  DarkRed* = 0x8b0000'u32
  Green* = 0x8ebb8a'u32
  LightBlue* = 0x90badf'u32
  LighterBlue* = 0xd4ebf2'u32
  Blue* = 0x608aaf'u32
  Blueish* = 0x4a8e97'u32
  White* = 0xffffff'u32
  Black* = 0x000000'u32

type
  Console* = object
    view: View
    charBuf: seq[seq[char]]
    charBufStartRow: int
    maxCols: int
    maxRows: int
    currCol: int
    currRow: int
    bgColor: uint32
    fgColor: uint32
    font: Font
    pagerLine = -1

var
  conOut*: Console  

proc clear*(con: var Console) =
  con.currCol = 0
  con.currRow = 0
  con.view.clear()

proc clear*() =
  clear(conOut)

proc flush*(con: Console) =
  # con.fb.copyBuffer(cast [ptr UncheckedArray[uint32]](addr backbuffer), backbufferStart)
  discard

proc flush*() =
  flush(conOut)

proc conRowToBufRow(con: var Console, row: int): int {.inline.} =
  return con.charBuf.len - con.maxRows + row

proc putCharAt*(con: var Console, ch: char, row, col: int, fgColor = con.fgColor, bgColor = con.bgColor) =
  # debugln("[console] putCharAt: ", $ch, " at ", $row, ", ", $col)
  let bufRow = conRowToBufRow(con, row)
  con.charBuf[bufRow][col] = ch

  var xstart = col.uint32 * con.font.width.uint32
  var ystart = row.uint32 * con.font.height.uint32

  # bitblt the glyph
  let glyph = con.font.glyphs[ch.uint8]
  for yoff, rowBits in glyph:
    for xoff in 1..8:
      let clr = if (rotateLeftBits(rowBits, xoff) and 1) == 1: fgColor else: bgColor
      con.view[xstart + xoff.uint32, ystart + yoff.uint32] = clr

proc putCharAt*(ch: char, row, col: int, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  conOut.putCharAt(ch, row, col, fgColor, bgColor)

proc putChar*(con: var Console, ch: char, fgColor = con.fgColor, bgColor = con.bgColor) =
  putCharAt(con, ch, con.currRow, con.currCol, fgColor, bgColor)

proc putChar*(ch: char, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  putCharAt(conOut, ch, conOut.currRow, conOut.currCol, fgColor, bgColor)

proc clearRow(row: int) =
  for i in 0 ..< conOut.maxCols:
    putCharAt(conOut, ' ', row, i)

proc dumpCharBuf(con: Console) =
  debugln("charBuff")
  for i in 0 ..< con.charBuf.len:
    if i < 10:
      debug(" ")
    debug($i, ": ")
    for j in 0 ..< con.charBuf[i].len:
      if con.charBuf[i][j] == '\0':
        debug(" ")
      else:
        debug($con.charBuf[i][j])
    debugln("|")

proc scrollUp(con: var Console) =
  # dumpCharBuf(con)
  con.charBuf.add(newSeq[char](con.maxCols))

  con.view.scrollUp(con.font.height.uint32)
  # re-render the visible viewport
  # for bufRow in (con.charBuf.len - con.maxRows) ..< con.charBuf.len:
  #   let conRow = bufRow - (con.charBuf.len - con.maxRows)
  #   for c in 0 ..< con.maxCols:
  #     var ch = con.charBuf[bufRow][c]
  #     if con.charBuf[bufRow][c] == '\0':
  #       ch = ' '
  #     # debugln("[console] scrolling: putCharAt: ", $ch, " at ", $conRow, ", ", $c)
  #     putCharAt(con, ch, conRow, c)

  # dumpCharBuf(con)

  # var start = ((backbufferStart + con.view.width.int) mod con.view.height.int) * con.view.width.int
  # for i in start ..< start + 16*con.view.width.int:
  #     backbuffer[i] = con.bgColor

proc readKeyEvent*(): KeyEvent

proc startPager*(con: var Console) =
  con.pagerLine = 0

proc stopPager*(con: var Console) =
  con.pagerLine = -1

proc newLine(con: var Console) =
  # if con.pagerLine >= 0:
  #   inc con.pagerLine
  #   if con.pagerLine >= con.maxRows:
  #     con.pagerLine = 0
  #     discard readKeyEvent()
  #     discard readKeyEvent()

  con.currCol = 0
  inc con.currRow
  if con.currRow >= con.maxRows:
    dec con.currRow
    con.scrollUp()

proc putTextAt*(con: var Console, str: string, row, col: int, fgColor = con.fgColor, bgColor = con.bgColor) =
  for i, ch in str:
    putCharAt(con, ch, row, col + i, fgColor, bgColor)

proc putTextAt*(str: string, row, col: int, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  for i, ch in str:
    putCharAt(conOut, ch, row, col + i, fgColor, bgColor)

proc write*(con: var Console, str: string, fgColor = con.fgColor, bgColor = con.bgColor) =
  debug(str)
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

proc writeln*(str: string, fgColor = conOut.fgColor, bgColor = conOut.bgColor) =
  writeln(conOut, str, fgColor, bgColor)


proc init*(maxCols, maxRows: int, font: Font,
           fgColor = DefaultForeground, bgColor = DefaultBackground) =
  debugln(&"[console]: Initializing with {maxCols=}, {maxRows=}")
  let viewWidth = maxCols * font.width
  let viewHeight = maxRows * font.height
  var mainView = createMainView("Console", 300.uint32, 100.uint32, viewWidth.uint32, viewHeight.uint32 + TitleHeight, bgColor)
  var charBuf = newSeq[seq[char]](maxRows)
  for i in 0 ..< maxRows:
    charBuf[i] = newSeq[char](maxCols)
  conOut = Console(view: mainView.view, maxCols: maxCols, maxRows: maxRows, charBuf: charBuf, font: font,
                   bgColor: bgColor, fgColor: fgColor)
  conOut.clear()



proc onTimer*() =
  putTextAt(&"{getCurrentThread().name:12}", 62, 0)
  putTextAt($getDateTime(), 62, 135)
  flush()


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
