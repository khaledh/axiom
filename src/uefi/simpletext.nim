import std/strformat

import ../console
import ../uefitypes

proc dumpSimpleText*(conOut: ptr SimpleTextOutputInterface) =
  writeln("")
  writeln("Simple Text Output Protocol")
  writeln(&"  Current Mode    = {conOut.mode.currentMode} (Max Mode={conOut.mode.maxMode})")

  writeln("")
  var cols, rows: uint
  for i in 0 ..< conOut.mode.maxMode:
    discard conOut.queryMode(conOut, i.uint, addr cols, addr rows)
    writeln(&"  Mode {i:>2}: {cols:>3} x {rows:>3}")
