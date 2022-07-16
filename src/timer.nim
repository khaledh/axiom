import console
import cpu
import idt
import lapic
import sched
import threaddef

var ticks: uint64

proc timerInterruptHandler*(intFrame: pointer)
    {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =

  # if ticks mod 250 == 0 and ticks < 2000:
  #   showThreads()

  if ticks mod 10 == 0:
    # write(&"{(ticks div 10) mod 10}")
    flush()

  inc(ticks)

  lapic.eoi()

  # if ticks == 20:
  #   createThread(thread3).start()

  # if ticks == 22:
  #   createThread(thread4).start()

  if ticks mod 10 == 0:
    schedule(tsReady)

proc initTimer*() =
  ticks = 0
  setInterruptHandler(0x20, timerInterruptHandler)
  lapic.setTimer(0x20)
