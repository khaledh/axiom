import debug
import idt
import lapic
import task

{.push stackTrace:off.}
proc timerInterruptHandler*(intFrame: pointer) {.cdecl, codegenDecl: "__attribute__ ((interrupt)) $# $#$#".} =
#   println("")
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

  schedule()

#   println("timer interrupt: end")
#   println("")
{.pop.}

proc initTimer*() =
  setInterruptHandler(0x20, timerInterruptHandler)
  lapicSetTimer(0x20)
