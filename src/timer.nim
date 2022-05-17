import cpu
import debug
import idt
import lapic
import task

var
  ticks: uint64

proc thread3() {.cdecl.} =
  # while true:
  for i in 0..<20:
    print("-")
    for i in 0..250000:
      asm "pause"


{.push stackTrace:off.}
proc timerInterruptHandler*(intFrame: pointer) {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =
  # halt()
  print("(t)")
  inc(ticks)
  # println("\ntimer")
  # dumpThreads()
#   println("timer interrupt: start")

  # tasks[currentTask]()
  # currentTask = 1 - currentTask

  # asm """
  #   cli
  #   hlt
  # """

  # let rsp = addr stack0[StackSize - 8]
  # println(&"rsp = {cast[uint64](rsp):x}")
  # println(&"rsp[] = {rsp[]:x}")

  lapicWrite(LapicOffset.Eoi, 0)

  if ticks == 30:
    let t3 = createThread(thread3)
    t3.startThread()


  schedule()

#   println("timer interrupt: end")
#   println("")
{.pop.}

proc initTimer*() =
  ticks = 0
  setInterruptHandler(0x20, timerInterruptHandler)
  lapicSetTimer(0x20)
