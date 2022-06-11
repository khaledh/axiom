import std/strformat

import console
import cpu
import idt
import lapic as lapic
import task

var
  ticks: uint64
  ticksSpinner: uint64

proc thread3() {.cdecl.} =
  for i in 0..<40:
    write("-")
    for i in 0..250000:
      asm "pause"

proc thread4() {.cdecl.} =
  for i in 0..<20:
    write("x")
    for i in 0..250000:
      asm "pause"

const
  spinner = ['-', '\\', '|', '/']

proc timerInterruptHandler*(intFrame: pointer)
    {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =

  if ticks mod 20 == 0:
    putCharAt(spinner[ticksSpinner mod len(spinner)], 61, 156)
    inc(ticksSpinner)

  if ticks mod 10 == 0:
    # write(&"{(ticks div 10) mod 10}")
    flush()

  inc(ticks)

  # let rsp = addr stack0[StackSize - 8]
  # writeln(&"rsp = {cast[uint64](rsp):x}")
  # writeln(&"rsp[] = {rsp[]:x}")

  lapic.eoi()

  # if ticks == 20:
  #   createThread(thread3).startThread()

  # if ticks == 22:
  #   createThread(thread4).startThread()

  if ticks mod 10 == 0:
    schedule()

proc initTimer*() =
  ticks = 0
  setInterruptHandler(0x20, timerInterruptHandler)
  lapic.setTimer(0x20)
