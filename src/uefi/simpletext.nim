import std/strformat

import ../debug
import ../uefitypes

proc dumpSimpleText*(conOut: ptr SimpleTextOutputInterface) =
  println("")
  println("Simple Text Output Protocol")
  println(&"  Current Mode    = {conOut.mode.currentMode} (Max Mode={conOut.mode.maxMode})")

  println("")
  var cols, rows: uint
  for i in 0 ..< conOut.mode.maxMode:
    discard conOut.queryMode(conOut, i.uint, addr cols, addr rows)
    println(&"  Mode {i:>2}: {cols:>3} x {rows:>3}")
