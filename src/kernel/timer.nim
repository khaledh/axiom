import devices/console
import idt, lapic, sched, threaddef


var ticks: uint64 = 0

proc timerInterruptHandler*(intFrame: pointer)
    {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =

  # if ticks mod 250 == 0 and ticks < 2000:
  #   showThreads()

  if ticks mod 10 == 0:
    # write(&"{(ticks div 10) mod 10}")
    console.flush()
  # if ticks mod 1000 == 0:
  #   showThreads()

  inc(ticks)

  lapic.eoi()

  if ticks mod 10 == 0:
    schedule(tsReady)

proc init*() =
  idt.setInterruptHandler(0x20, timerInterruptHandler)
  lapic.setTimer(0x20)
