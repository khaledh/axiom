import cpu
import debug
import idt
import lapic
import task

var
  ticks: uint64

proc thread3() {.cdecl.} =
  for i in 0..<40:
    print("-")
    for i in 0..250000:
      asm "pause"

proc thread4() {.cdecl.} =
  for i in 0..<20:
    print("x")
    for i in 0..250000:
      asm "pause"

proc timerInterruptHandler*(intFrame: pointer)
    {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =

  print("(t)")
  inc(ticks)

  # let rsp = addr stack0[StackSize - 8]
  # println(&"rsp = {cast[uint64](rsp):x}")
  # println(&"rsp[] = {rsp[]:x}")

  lapicWrite(LapicOffset.Eoi, 0)

  if ticks == 20:
    createThread(thread3).startThread()

  if ticks == 22:
    createThread(thread4).startThread()

  schedule()

proc initTimer*() =
  ticks = 0
  setInterruptHandler(0x20, timerInterruptHandler)
  lapicSetTimer(0x20)
